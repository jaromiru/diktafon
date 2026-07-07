import 'dart:async';

import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/repositories/memo_repository.dart';
import 'package:diktafon/data/repositories/settings_repository.dart';
import 'package:diktafon/domain/models.dart';
import 'package:diktafon/services/processing/job_queue.dart';
import 'package:diktafon/services/providers/transcription_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTranscriptionProvider implements TranscriptionProvider {
  FakeTranscriptionProvider({
    this.status = ModelStatus.ready,
    this.result,
    this.failuresBeforeSuccess = 0,
    this.honourCancel = false,
  });

  ModelStatus status;
  Transcript? result;
  int failuresBeforeSuccess;
  bool honourCancel;

  int calls = 0;
  String? lastLanguageCode;

  /// Lets a test cancel a "running" transcription deterministically.
  Completer<void>? gate;

  @override
  String get id => 'fake/test';

  @override
  Future<ModelStatus> modelStatus() async => status;

  @override
  Future<void> ensureModel({ProgressSink? onProgress}) async {}

  @override
  Future<Transcript> transcribe(
    AudioRef audio, {
    String? languageCode,
    CancelToken? cancel,
  }) async {
    calls++;
    lastLanguageCode = languageCode;
    if (gate != null) await gate!.future;
    if (honourCancel && (cancel?.isCancelled ?? false)) {
      throw const TranscriptionCancelled();
    }
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw StateError('flaky engine');
    }
    return result ??
        Transcript(languageCode: 'cs', segments: [
          Segment(startMs: 0, endMs: 900, words: const [
            Word(text: 'ahoj', startMs: 0, endMs: 400),
            Word(text: 'světe', startMs: 450, endMs: 900),
          ]),
        ]);
  }
}

void main() {
  late AppDatabase db;
  late MemoRepository memos;
  late SettingsRepository settings;
  late FakeTranscriptionProvider engine;
  late JobQueue queue;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    memos = MemoRepository(db);
    settings = SettingsRepository(db);
    engine = FakeTranscriptionProvider();
    queue = JobQueue(db, memos, settings, () => engine,
        retryDelayUnit: Duration.zero);
  });

  tearDown(() => db.close());

  Future<Memo> seedMemo(String id) async {
    await db.into(db.cassettes).insert(CassetteRow(
          id: 'c1',
          titleIsUserSet: false,
          colorSeed: 1,
          createdAt: 0,
          updatedAt: 0,
        ));
    final memo = Memo(
      id: id,
      cassetteId: 'c1',
      filePath: '/audio/c1/$id.m4a',
      durationMs: 4000,
      createdAt: DateTime.now(),
      status: MemoStatus.stored,
    );
    await memos.insert(memo);
    return memo;
  }

  Future<MemoRow> memoRow(String id) =>
      (db.select(db.memos)..where((m) => m.id.equals(id))).getSingle();

  Future<List<JobRow>> jobs() => db.select(db.jobs).get();

  test('jobs wait while the model is missing; drain resumes them (§14)',
      () async {
    engine.status = ModelStatus.notInstalled;
    await seedMemo('m1');
    await queue.enqueueTranscription('m1');
    await queue.drain();

    expect((await jobs()).single.status, 'queued');
    expect((await memoRow('m1')).status, 'stored');
    expect(engine.calls, 0);

    engine.status = ModelStatus.ready; // "model provisioned" (Settings)
    await queue.drain();
    expect((await jobs()).single.status, 'done');
    expect((await memoRow('m1')).status, 'transcribed');
    expect((await memoRow('m1')).transcript, contains('světe'));
    expect((await memoRow('m1')).detectedLang, 'cs');
  });

  test('D8: unset app language adopts the first real detection', () async {
    await seedMemo('m1');
    await queue.enqueueTranscription('m1');
    await queue.drain();

    expect(engine.lastLanguageCode, isNull,
        reason: 'no app language yet → provider auto-detects');
    expect((await settings.get()).appLanguage, 'cs');
  });

  test('D8: explicit app language is passed through and never overwritten',
      () async {
    await settings.setAppLanguage('pl');
    engine.result = const Transcript(languageCode: 'pl', segments: []);
    await seedMemo('m1');
    await queue.enqueueTranscription('m1');
    await queue.drain();

    expect(engine.lastLanguageCode, 'pl');
    expect((await settings.get()).appLanguage, 'pl');
  });

  test('D8: a silent first memo does not lock in a language', () async {
    engine.result = const Transcript(languageCode: 'en', segments: []);
    await seedMemo('m1');
    await queue.enqueueTranscription('m1');
    await queue.drain();

    expect((await settings.get()).appLanguage, isNull);
    expect((await memoRow('m1')).status, 'transcribed',
        reason: 'empty transcript is still a completed transcription (§14)');
  });

  test('transient failures retry with attempts; success on 3rd try',
      () async {
    engine.failuresBeforeSuccess = 2;
    await seedMemo('m1');
    await queue.enqueueTranscription('m1');
    await queue.drain();

    expect(engine.calls, 3);
    expect((await jobs()).single.status, 'done');
    expect((await memoRow('m1')).status, 'transcribed');
  });

  test('permanent failure after 5 attempts → memo failed but present (§14)',
      () async {
    engine.failuresBeforeSuccess = 99;
    await seedMemo('m1');
    await queue.enqueueTranscription('m1');
    await queue.drain();

    expect(engine.calls, 5);
    expect((await jobs()).single.status, 'failed');
    expect((await memoRow('m1')).status, 'failed');
  });

  test('retryTranscription re-enqueues a failed memo', () async {
    engine.failuresBeforeSuccess = 99;
    await seedMemo('m1');
    await queue.enqueueTranscription('m1');
    await queue.drain();
    expect((await memoRow('m1')).status, 'failed');

    engine.failuresBeforeSuccess = 0;
    await queue.retryTranscription('m1');
    await queue.drain();
    expect((await memoRow('m1')).status, 'transcribed');
  });

  test('cancelJobsFor aborts the in-flight job without failing the memo',
      () async {
    engine.honourCancel = true;
    engine.gate = Completer<void>();
    await seedMemo('m1');

    await queue.enqueueTranscription('m1');
    // Let the job start, then delete-cancel while the engine "runs".
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await queue.cancelJobsFor('m1');
    engine.gate!.complete();
    await queue.drain();

    expect(await jobs(), isEmpty,
        reason: 'cancelled job is moot and removed, not failed');
    expect((await memoRow('m1')).status, isNot('failed'));
  });

  test('queued (not yet running) jobs are removed by cancelJobsFor',
      () async {
    engine.status = ModelStatus.notInstalled;
    await seedMemo('m1');
    await queue.enqueueTranscription('m1');
    await queue.drain();
    await queue.cancelJobsFor('m1');
    expect(await jobs(), isEmpty);
  });
}
