import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/files/audio_file_store.dart';
import 'package:diktafon/data/repositories/cassette_repository.dart';
import 'package:diktafon/data/repositories/memo_repository.dart';
import 'package:diktafon/domain/models.dart';
import 'package:diktafon/services/export/cassette_exporter.dart';
import 'package:diktafon/services/import/cassette_importer.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The §8 archive round trip and its degraded paths: everything the
/// exporter writes must come back in, under fresh ids, without touching
/// what is already on the device (D14).
void main() {
  late Directory work;
  late AppDatabase db;
  late CassetteRepository cassettes;
  late MemoRepository memos;
  late List<String> transcriptionQueue;
  late List<String> enrichmentQueue;
  late CassetteImporter importer;

  setUp(() {
    work = Directory.systemTemp.createTempSync('dk_import_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cassettes = CassetteRepository(db);
    memos = MemoRepository(db);
    transcriptionQueue = [];
    enrichmentQueue = [];
    importer = CassetteImporter(
      cassettes: cassettes,
      memos: memos,
      files: AudioFileStore(Directory('${work.path}/store')),
      enqueueTranscription: (id) async => transcriptionQueue.add(id),
      retryEnrichment: (id) async => enrichmentQueue.add(id),
    );
  });

  tearDown(() async {
    await db.close();
    work.deleteSync(recursive: true);
  });

  Cassette cassette({String? label, String? summary}) => Cassette(
        id: 'c1',
        label: label,
        titleIsUserSet: label != null,
        colorSeed: 7,
        summary: summary,
        summaryUpdatedAt: null,
        createdAt: DateTime(2026, 7, 1, 9),
        updatedAt: DateTime(2026, 7, 8, 14, 30),
      );

  Memo memo(
    String id, {
    String? audioPath,
    Transcript? transcript,
    String? summary,
  }) =>
      Memo(
        id: id,
        cassetteId: 'c1',
        filePath: audioPath ?? '${work.path}/missing/$id.m4a',
        durationMs: 1500,
        createdAt: DateTime(2026, 7, 2, 10, 15, 30),
        status: MemoStatus.ready,
        detectedLang: 'en',
        transcript: transcript,
        memoSummary: summary,
      );

  Transcript words(List<String> texts) => Transcript(
        languageCode: 'en',
        segments: [
          Segment(
            startMs: 0,
            endMs: 1000,
            words: [
              for (final (i, t) in texts.indexed)
                Word(text: t, startMs: i * 100, endMs: i * 100 + 90),
            ],
          ),
        ],
      );

  File makeAudio(String name) =>
      File('${work.path}/$name')..writeAsBytesSync([1, 2, 3, 4]);

  Future<String> exportZip(
      List<({Cassette cassette, List<Memo> memos})> items) async {
    final zipPath =
        '${work.path}/archive-${DateTime.now().microsecondsSinceEpoch}.zip';
    await const CassetteExporter()
        .exportArchive(items: items, outputPath: zipPath);
    return zipPath;
  }

  test('a zero-duration memo with audio gets probed (hand-edited manifest) '
      '— never an invisible sliver on the timeline', () async {
    final dir = Directory('${work.path}/export')..createSync();
    Directory('${dir.path}/audio').createSync();
    File('${dir.path}/audio/clip.m4a').writeAsBytesSync([1, 2, 3, 4]);
    File('${dir.path}/cassette.json').writeAsStringSync(jsonEncode({
      'formatVersion': 1,
      'label': 'Probe me',
      'createdAt': '2026-07-01T09:00:00.000',
      'updatedAt': '2026-07-01T09:00:00.000',
      'memos': [
        {
          'id': 'x',
          'createdAt': '2026-07-01T09:00:00.000',
          'durationMs': 0,
          'audio': 'audio/clip.m4a',
        },
      ],
    }));

    final probed = <String>[];
    final probingImporter = CassetteImporter(
      cassettes: cassettes,
      memos: memos,
      files: AudioFileStore(Directory('${work.path}/store')),
      enqueueTranscription: (id) async => transcriptionQueue.add(id),
      retryEnrichment: (id) async => enrichmentQueue.add(id),
      probeDurationMs: (path) async {
        probed.add(path);
        return 4321;
      },
    );
    final result = await probingImporter.importDirectory(dir);

    expect(result.memos, 1);
    expect(probed, hasLength(1));
    final row = (await db.select(db.memos).get()).single;
    expect(row.durationMs, 4321);
  });

  test('zip round trip: rows, audio, enrichment and timestamps survive',
      () async {
    final audio = makeAudio('src.m4a');
    final zip = await exportZip([
      (
        cassette: cassette(label: 'Groceries', summary: 'Buy things.'),
        memos: [
          memo('m1',
              audioPath: audio.path,
              transcript: words(['milk', 'and', 'bread']),
              summary: 'Milk and bread.'),
        ],
      ),
      (cassette: cassette(label: 'Ideas'), memos: <Memo>[]),
    ]);

    final result = await importer.importArchive(File(zip));
    expect(result.cassettes, 2);
    expect(result.memos, 1);
    expect(result.reEnqueued, 0);
    expect(result.skippedMemos, 0);
    expect(result.failures, isEmpty);

    final rows = await db.select(db.cassettes).get();
    expect(rows, hasLength(2));
    expect({for (final r in rows) r.label}, {'Groceries', 'Ideas'});
    expect({for (final r in rows) r.id}.contains('c1'), isFalse); // fresh ids

    final groceries = rows.singleWhere((r) => r.label == 'Groceries');
    expect(groceries.colorSeed, 7);
    expect(groceries.titleIsUserSet, isTrue);
    expect(groceries.summary, 'Buy things.');
    expect(groceries.createdAt,
        DateTime(2026, 7, 1, 9).millisecondsSinceEpoch);
    expect(groceries.updatedAt,
        DateTime(2026, 7, 8, 14, 30).millisecondsSinceEpoch);

    final imported = (await memos.memosOf(groceries.id)).single;
    expect(imported.id, isNot('m1'));
    expect(imported.status, MemoStatus.ready);
    expect(imported.durationMs, 1500);
    expect(imported.detectedLang, 'en');
    expect(imported.transcript!.plainText, 'milk and bread');
    expect(imported.memoSummary, 'Milk and bread.');
    expect(imported.createdAt,
        DateTime(2026, 7, 2, 10, 15, 30));
    expect(File(imported.filePath).readAsBytesSync(), [1, 2, 3, 4]);
    expect(transcriptionQueue, isEmpty);
    expect(enrichmentQueue, isEmpty);
  });

  test('missing enrichment re-enters the pipeline at the right stage',
      () async {
    final audio = makeAudio('src.m4a');
    final zip = await exportZip([
      (
        cassette: cassette(label: 'Mixed'),
        memos: [
          memo('raw', audioPath: audio.path), // no transcript yet
          memo('half',
              audioPath: audio.path, transcript: words(['hello'])), // no gist
        ],
      ),
    ]);

    final result = await importer.importArchive(File(zip));
    expect(result.memos, 2);
    expect(result.reEnqueued, 2);

    final imported =
        await memos.memosOf((await db.select(db.cassettes).get()).single.id);
    final raw = imported.singleWhere((m) => m.transcript == null);
    final half = imported.singleWhere((m) => m.transcript != null);
    expect(raw.status, MemoStatus.stored);
    expect(half.status, MemoStatus.transcribed);
    expect(transcriptionQueue, [raw.id]);
    expect(enrichmentQueue, [half.id]);
  });

  test('audio-less memo keeps its transcript; empty shells are skipped',
      () async {
    final zip = await exportZip([
      (
        cassette: cassette(label: 'Damaged'),
        memos: [
          memo('kept', transcript: words(['survived']), summary: 'Gist.'),
          memo('shell'), // no audio, no transcript — nothing to restore
        ],
      ),
    ]);

    final result = await importer.importArchive(File(zip));
    expect(result.memos, 1);
    expect(result.skippedMemos, 1);

    final imported =
        await memos.memosOf((await db.select(db.cassettes).get()).single.id);
    final kept = imported.single;
    expect(kept.status, MemoStatus.ready);
    expect(kept.transcript!.plainText, 'survived');
    expect(File(kept.filePath).existsSync(), isFalse); // dead canonical path
    expect(transcriptionQueue, isEmpty); // no audio → nothing to transcribe
  });

  test('importing the same archive twice duplicates, never merges (D14)',
      () async {
    final zip = await exportZip([
      (cassette: cassette(label: 'Twice'), memos: <Memo>[]),
    ]);
    await importer.importArchive(File(zip));
    await importer.importArchive(File(zip));

    final rows = await db.select(db.cassettes).get();
    expect(rows, hasLength(2));
    expect(rows.first.id, isNot(rows.last.id));
    expect({for (final r in rows) r.label}, {'Twice'});
  });

  test('pre-versioned manifest imports; label implies user-set (D10)',
      () async {
    final dir = Directory('${work.path}/legacy/Old tape')
      ..createSync(recursive: true);
    Directory('${dir.path}/audio').createSync();
    File('${dir.path}/audio/a.m4a').writeAsBytesSync([9, 9]);
    File('${dir.path}/cassette.json').writeAsStringSync(jsonEncode({
      // no formatVersion / colorSeed / titleIsUserSet — the first cut
      'label': 'Old tape',
      'summary': null,
      'createdAt': '2026-07-01T09:00:00.000',
      'updatedAt': '2026-07-02T09:00:00.000',
      'exportedAt': '2026-07-03T09:00:00.000',
      'memos': [
        {
          'id': 'x',
          'createdAt': '2026-07-01T10:00:00.000',
          'durationMs': 1000,
          'language': 'cs',
          'summary': null,
          'audio': 'audio/a.m4a',
          'transcript': null,
        },
      ],
    }));

    final result =
        await importer.importDirectory(Directory('${work.path}/legacy'));
    expect(result.cassettes, 1);
    expect(result.failures, isEmpty);

    final row = (await db.select(db.cassettes).get()).single;
    expect(row.label, 'Old tape');
    expect(row.titleIsUserSet, isTrue);
    final imported = (await memos.memosOf(row.id)).single;
    expect(imported.status, MemoStatus.stored);
    expect(transcriptionQueue, [imported.id]);
  });

  test('one corrupt cassette fails alone and rolls back its rows', () async {
    final good = Directory('${work.path}/batch/Good')
      ..createSync(recursive: true);
    File('${good.path}/cassette.json').writeAsStringSync(jsonEncode({
      'label': 'Good',
      'createdAt': '2026-07-01T09:00:00.000',
      'updatedAt': '2026-07-01T09:00:00.000',
      'memos': <Object>[],
    }));
    final bad = Directory('${work.path}/batch/Bad')
      ..createSync(recursive: true);
    // The cassette header parses, so a row is inserted — then the memo list
    // blows up, which must roll the cassette back out.
    File('${bad.path}/cassette.json').writeAsStringSync(jsonEncode({
      'label': 'Bad',
      'createdAt': '2026-07-01T09:00:00.000',
      'updatedAt': '2026-07-01T09:00:00.000',
      'memos': 'not a list',
    }));

    final result =
        await importer.importDirectory(Directory('${work.path}/batch'));
    expect(result.cassettes, 1);
    expect(result.failures, hasLength(1));
    expect(result.failures.single, contains('Bad'));

    final rows = await db.select(db.cassettes).get();
    expect(rows.single.label, 'Good');
  });

  test('escaping audio paths are ignored, the memo still imports', () async {
    File('${work.path}/outside.m4a').writeAsBytesSync([6, 6, 6]);
    final dir = Directory('${work.path}/hostile/Tape')
      ..createSync(recursive: true);
    File('${dir.path}/cassette.json').writeAsStringSync(jsonEncode({
      'formatVersion': 1,
      'label': 'Tape',
      'createdAt': '2026-07-01T09:00:00.000',
      'updatedAt': '2026-07-01T09:00:00.000',
      'memos': [
        {
          'createdAt': '2026-07-01T10:00:00.000',
          'durationMs': 1000,
          'audio': '../../outside.m4a',
          'transcript': words(['safe']).toJson(),
        },
      ],
    }));

    final result =
        await importer.importDirectory(Directory('${work.path}/hostile'));
    expect(result.failures, isEmpty);
    final imported =
        (await memos.memosOf((await db.select(db.cassettes).get()).single.id))
            .single;
    expect(imported.transcript!.plainText, 'safe');
    expect(File(imported.filePath).existsSync(), isFalse); // audio refused
  });

  test('archives from a newer app are refused, not half-read', () async {
    final dir = Directory('${work.path}/future/Tape')
      ..createSync(recursive: true);
    File('${dir.path}/cassette.json').writeAsStringSync(jsonEncode({
      'formatVersion': 99,
      'label': 'Tape',
      'memos': <Object>[],
    }));

    final result =
        await importer.importDirectory(Directory('${work.path}/future'));
    expect(result.cassettes, 0);
    expect(result.failures, hasLength(1));
    expect(await db.select(db.cassettes).get(), isEmpty);
  });

  test('a hand-zipped single export (manifest at zip root) imports too',
      () async {
    final audio = makeAudio('src.m4a');
    final staged = Directory('${work.path}/staged')..createSync();
    await const CassetteExporter().exportCassette(
      cassette: cassette(label: 'Solo'),
      memos: [memo('m1', audioPath: audio.path)],
      target: staged,
    );
    final zipPath = '${work.path}/solo.zip';
    final encoder = ZipFileEncoder()..create(zipPath);
    await encoder.addDirectory(Directory('${staged.path}/Solo'),
        includeDirName: false);
    await encoder.close();

    final result = await importer.importArchive(File(zipPath));
    expect(result.cassettes, 1);
    expect(result.memos, 1);
    expect((await db.select(db.cassettes).get()).single.label, 'Solo');
  });
}
