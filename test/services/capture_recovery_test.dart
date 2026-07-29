import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/files/audio_file_store.dart';
import 'package:diktafon/data/repositories/cassette_repository.dart';
import 'package:diktafon/data/repositories/memo_repository.dart';
import 'package:diktafon/domain/models.dart';
import 'package:diktafon/services/audio/capture_recovery.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'wav_repair_test.dart' show buildWav;

void main() {
  late Directory work;
  late AppDatabase db;
  late CassetteRepository cassettes;
  late MemoRepository memos;
  late AudioFileStore files;
  late List<String> transcriptionQueue;
  late List<String> transcodeQueue;
  late CaptureRecovery recovery;

  setUp(() {
    work = Directory.systemTemp.createTempSync('dk_recover_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cassettes = CassetteRepository(db);
    memos = MemoRepository(db);
    files = AudioFileStore(Directory('${work.path}/audio'));
    transcriptionQueue = [];
    transcodeQueue = [];
    recovery = CaptureRecovery(
      files: files,
      memos: memos,
      cassettes: cassettes,
      enqueueTranscription: (id) async => transcriptionQueue.add(id),
      enqueueTranscode: (id) async => transcodeQueue.add(id),
    );
  });

  tearDown(() async {
    await db.close();
    work.deleteSync(recursive: true);
  });

  final startedAt = DateTime(2026, 7, 20, 9, 30);

  /// A capture as a kill leaves it: WAV with stale header sizes + marker.
  Future<String> plantCapture(
    String cassetteId,
    String memoId, {
    int dataBytes = 32000,
    bool withWav = true,
    String? markerJson,
  }) async {
    final wavPath =
        await files.pathFor(cassetteId, memoId, extension: 'wav');
    if (withWav) {
      await File(wavPath).writeAsBytes(
          buildWav(dataBytes, riffSize: 0, dataSize: 0));
    }
    await File(captureMarkerPath(wavPath)).writeAsString(markerJson ??
        jsonEncode({
          'memoId': memoId,
          'cassetteId': cassetteId,
          'startedAt': startedAt.millisecondsSinceEpoch,
        }));
    return wavPath;
  }

  test('salvageable capture becomes a memo and re-enters the pipeline',
      () async {
    final cassette = await cassettes.create();
    final wavPath = await plantCapture(cassette.id, 'm-lost');

    expect(await recovery.recover(), 1);

    final row = (await memos.memosOf(cassette.id)).single;
    expect(row.id, 'm-lost');
    expect(row.filePath, wavPath);
    expect(row.status, MemoStatus.stored);
    expect(row.durationMs, 1000); // 32 KB at 16 kHz mono s16
    // createdAt mirrors a normal stop: start + captured audio.
    expect(row.createdAt,
        startedAt.add(const Duration(milliseconds: 1000)));
    expect(transcriptionQueue, ['m-lost']);
    expect(transcodeQueue, ['m-lost']);
    expect(File(captureMarkerPath(wavPath)).existsSync(), isFalse);

    // The WAV header was repaired in place — sizes match the file now.
    final bytes = await File(wavPath).readAsBytes();
    expect(
        ByteData.sublistView(bytes).getUint32(40, Endian.little), 32000);
  });

  test('marker whose memo row already exists is just cleaned up', () async {
    final cassette = await cassettes.create();
    final wavPath = await plantCapture(cassette.id, 'm-done');
    await memos.insert(Memo(
      id: 'm-done',
      cassetteId: cassette.id,
      filePath: wavPath,
      durationMs: 1000,
      createdAt: startedAt,
      status: MemoStatus.stored,
    ));

    expect(await recovery.recover(), 0);
    expect((await memos.memosOf(cassette.id)).length, 1);
    expect(transcriptionQueue, isEmpty);
    expect(transcodeQueue, isEmpty);
    expect(File(captureMarkerPath(wavPath)).existsSync(), isFalse);
  });

  test('marker without a WAV is dropped', () async {
    final cassette = await cassettes.create();
    final wavPath =
        await plantCapture(cassette.id, 'm-gone', withWav: false);

    expect(await recovery.recover(), 0);
    expect(await memos.allIds(), isEmpty);
    expect(File(captureMarkerPath(wavPath)).existsSync(), isFalse);
  });

  test('a blink of a capture (under ~100 ms) is discarded', () async {
    final cassette = await cassettes.create();
    final wavPath =
        await plantCapture(cassette.id, 'm-blip', dataBytes: 640);

    expect(await recovery.recover(), 0);
    expect(await memos.allIds(), isEmpty);
    expect(File(wavPath).existsSync(), isFalse);
    expect(File(captureMarkerPath(wavPath)).existsSync(), isFalse);
  });

  test('unreadable marker is dropped without touching the audio', () async {
    final cassette = await cassettes.create();
    final wavPath = await plantCapture(cassette.id, 'm-noise',
        markerJson: 'not json at all');

    expect(await recovery.recover(), 0);
    expect(await memos.allIds(), isEmpty);
    expect(File(captureMarkerPath(wavPath)).existsSync(), isFalse);
    // The audio stays for the age-gated orphan sweep — recovery cannot
    // know whose it was.
    expect(File(wavPath).existsSync(), isTrue);
  });

  test('capture for a deleted cassette is discarded', () async {
    final wavPath = await plantCapture('c-ghost', 'm-orphan');

    expect(await recovery.recover(), 0);
    expect(await memos.allIds(), isEmpty);
    expect(File(wavPath).existsSync(), isFalse);
    expect(File(captureMarkerPath(wavPath)).existsSync(), isFalse);
  });

  test('quiet launch: no markers, nothing recovered', () async {
    await cassettes.create();
    expect(await recovery.recover(), 0);
  });

  test('one bad capture never sinks the batch', () async {
    final cassette = await cassettes.create();
    await plantCapture(cassette.id, 'm-bad', markerJson: '{"memoId": 7}');
    await plantCapture(cassette.id, 'm-good');

    expect(await recovery.recover(), 1);
    expect((await memos.memosOf(cassette.id)).single.id, 'm-good');
  });
}
