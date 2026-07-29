import 'dart:io';

import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/repositories/cassette_repository.dart';
import 'package:diktafon/data/repositories/memo_repository.dart';
import 'package:diktafon/data/repositories/settings_repository.dart';
import 'package:diktafon/domain/models.dart';
import 'package:diktafon/services/audio/audio_transcoder.dart';
import 'package:diktafon/services/processing/job_queue.dart';
import 'package:diktafon/services/providers/transcription_provider.dart'
    show ModelStatus;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'job_queue_test.dart'
    show FakeSummarizationProvider, FakeTranscriptionProvider;

class FakeTranscoder implements AudioTranscoder {
  int calls = 0;
  int failuresBeforeSuccess = 0;
  final invocations = <(String, String)>[];

  @override
  Future<void> transcode(String wavPath, String outPath) async {
    calls++;
    invocations.add((wavPath, outPath));
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw StateError('flaky codec');
    }
    await File(outPath).writeAsBytes(const [0x41, 0x41, 0x43]);
  }
}

void main() {
  late Directory work;
  late AppDatabase db;
  late MemoRepository memos;
  late CassetteRepository cassettes;
  late FakeTranscoder transcoder;
  late JobQueue queue;
  late String cassetteId;

  setUp(() async {
    work = Directory.systemTemp.createTempSync('dk_transcode_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    memos = MemoRepository(db);
    cassettes = CassetteRepository(db);
    transcoder = FakeTranscoder();
    queue = JobQueue(
      db,
      memos,
      cassettes,
      SettingsRepository(db),
      () => FakeTranscriptionProvider(status: ModelStatus.notInstalled),
      () => FakeSummarizationProvider(status: ModelStatus.notInstalled),
      transcoder: () => transcoder,
      retryDelayUnit: Duration.zero,
    );
    cassetteId = (await cassettes.create()).id;
  });

  tearDown(() async {
    await db.close();
    work.deleteSync(recursive: true);
  });

  Future<String> plantMemo(String memoId, {String extension = 'wav'}) async {
    final path = '${work.path}/$memoId.$extension';
    await File(path).writeAsBytes(List.filled(64, 7));
    await memos.insert(Memo(
      id: memoId,
      cassetteId: cassetteId,
      filePath: path,
      durationMs: 1000,
      createdAt: DateTime(2026, 7, 20, 10),
      // `ready` keeps the launch reconciles from enqueueing enrichment —
      // these tests are about the transcode stage alone.
      status: MemoStatus.ready,
    ));
    return path;
  }

  Future<List<JobRow>> jobRows() => db.select(db.jobs).get();

  Future<Memo> memoOf(String id) async =>
      (await memos.memosOf(cassetteId)).singleWhere((m) => m.id == id);

  test('WAV capture becomes archival AAC: path swapped, WAV deleted',
      () async {
    final wavPath = await plantMemo('m1');
    await queue.enqueueTranscode('m1');
    await queue.drain();

    final m4aPath = wavPath.replaceFirst('.wav', '.m4a');
    expect(transcoder.invocations, [(wavPath, m4aPath)]);
    expect((await memoOf('m1')).filePath, m4aPath);
    expect(File(m4aPath).existsSync(), isTrue);
    expect(File(wavPath).existsSync(), isFalse);
    expect(await jobRows(), isEmpty); // completed rows are deleted
  });

  test('transient codec failure retries and lands', () async {
    final wavPath = await plantMemo('m1');
    transcoder.failuresBeforeSuccess = 1;
    await queue.enqueueTranscode('m1');
    await queue.drain();

    expect(transcoder.calls, 2);
    expect((await memoOf('m1')).filePath, endsWith('.m4a'));
    expect(File(wavPath).existsSync(), isFalse);
  });

  test('permanent codec failure leaves the memo whole on its WAV', () async {
    final wavPath = await plantMemo('m1');
    transcoder.failuresBeforeSuccess = 99;
    await queue.enqueueTranscode('m1');
    await queue.drain();

    final memo = await memoOf('m1');
    expect(memo.filePath, wavPath);
    expect(memo.status, MemoStatus.ready); // never `failed` for a codec issue
    expect(File(wavPath).existsSync(), isTrue);
    expect((await jobRows()).single.status, 'failed');
  });

  test('memo deleted before the job runs → job completes as a no-op',
      () async {
    await plantMemo('m1');
    await queue.enqueueTranscode('m1');
    await memos.delete('m1');
    await queue.drain();

    expect(transcoder.calls, 0);
    expect(await jobRows(), isEmpty);
  });

  test('a memo already on AAC is left untouched', () async {
    final path = await plantMemo('m1', extension: 'm4a');
    await queue.enqueueTranscode('m1');
    await queue.drain();

    expect(transcoder.calls, 0);
    expect((await memoOf('m1')).filePath, path);
    expect(await jobRows(), isEmpty);
  });

  test('missing WAV (vanished audio, §14) completes without a swap',
      () async {
    final wavPath = await plantMemo('m1');
    File(wavPath).deleteSync();
    await queue.enqueueTranscode('m1');
    await queue.drain();

    expect(transcoder.calls, 0);
    expect((await memoOf('m1')).filePath, wavPath);
    expect(await jobRows(), isEmpty);
  });

  test('launch reconcile picks up a stranded WAV memo with no job', () async {
    final wavPath = await plantMemo('m1');
    await queue.drain(); // first drain runs the reconciles

    expect(transcoder.calls, 1);
    expect((await memoOf('m1')).filePath,
        wavPath.replaceFirst('.wav', '.m4a'));
  });

  test('launch reconcile respects an existing failed transcode row',
      () async {
    await plantMemo('m1');
    await db.into(db.jobs).insert(JobRow(
          id: 'j-dead',
          type: JobType.transcodeAudio.name,
          targetId: 'm1',
          status: 'failed',
          attempts: 5,
          createdAt: DateTime(2026, 7, 19).millisecondsSinceEpoch,
        ));
    await queue.drain();

    expect(transcoder.calls, 0);
    expect((await memoOf('m1')).filePath, endsWith('.wav'));
  });

  test('without a wired transcoder the job parks in the queue', () async {
    final bare = JobQueue(
      db,
      memos,
      cassettes,
      SettingsRepository(db),
      () => FakeTranscriptionProvider(status: ModelStatus.notInstalled),
      () => FakeSummarizationProvider(status: ModelStatus.notInstalled),
      retryDelayUnit: Duration.zero,
    );
    await plantMemo('m1');
    await bare.enqueueTranscode('m1');
    await bare.drain();

    expect((await jobRows()).single.status, 'queued');
    expect((await memoOf('m1')).filePath, endsWith('.wav'));
  });
}
