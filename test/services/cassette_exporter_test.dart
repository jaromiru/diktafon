import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:diktafon/domain/models.dart';
import 'package:diktafon/services/export/cassette_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory work;

  setUp(() => work = Directory.systemTemp.createTempSync('dk_export_'));
  tearDown(() => work.deleteSync(recursive: true));

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

  test('writes audio + transcript.md + cassette.json (§8)', () async {
    final audio = File('${work.path}/src.m4a')
      ..writeAsBytesSync([1, 2, 3, 4]);
    final target = Directory('${work.path}/out')..createSync();

    final dir = await const CassetteExporter().exportCassette(
      cassette: cassette(label: 'Groceries', summary: 'Buy things.'),
      memos: [
        memo('m1',
            audioPath: audio.path,
            transcript: words(['milk', 'and', 'bread']),
            summary: 'Milk and bread.'),
      ],
      target: target,
    );

    expect(dir.path, '${target.path}/Groceries');
    final audioFiles =
        Directory('${dir.path}/audio').listSync().map((f) => f.path).toList();
    expect(audioFiles, hasLength(1));
    expect(audioFiles.single, endsWith('.m4a'));
    expect(File(audioFiles.single).lengthSync(), 4);

    final md = File('${dir.path}/transcript.md').readAsStringSync();
    expect(md, contains('# Groceries'));
    expect(md, contains('Buy things.'));
    expect(md, contains('> Milk and bread.'));
    expect(md, contains('milk and bread'));

    final json = jsonDecode(File('${dir.path}/cassette.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(json['formatVersion'], CassetteExporter.manifestVersion);
    expect(json['label'], 'Groceries');
    expect(json['titleIsUserSet'], isTrue);
    expect(json['colorSeed'], 7);
    expect(json['summary'], 'Buy things.');
    final memos = json['memos'] as List;
    expect((memos.single as Map)['audio'], startsWith('audio/memo-001'));
    expect((memos.single as Map)['transcript'], isNotNull);
  });

  test('exportArchive bundles every cassette into one zip (§8)', () async {
    final audio = File('${work.path}/src.m4a')
      ..writeAsBytesSync([1, 2, 3, 4]);
    final zipPath = '${work.path}/out/archive.zip';
    Directory('${work.path}/out').createSync();

    await const CassetteExporter().exportArchive(
      items: [
        (
          cassette: cassette(label: 'Groceries', summary: 'Buy things.'),
          memos: [memo('m1', audioPath: audio.path)],
        ),
        (cassette: cassette(label: 'Ideas'), memos: <Memo>[]),
      ],
      outputPath: zipPath,
    );

    final unpacked = Directory('${work.path}/unpacked')..createSync();
    await extractFileToDisk(zipPath, unpacked.path);
    expect(
        File('${unpacked.path}/Groceries/cassette.json').existsSync(), isTrue);
    expect(File('${unpacked.path}/Groceries/transcript.md').existsSync(),
        isTrue);
    expect(Directory('${unpacked.path}/Groceries/audio').listSync(),
        hasLength(1));
    expect(File('${unpacked.path}/Ideas/cassette.json').existsSync(), isTrue);
  });

  test('missing audio and absent transcript degrade, not fail', () async {
    final target = Directory('${work.path}/out')..createSync();
    final dir = await const CassetteExporter().exportCassette(
      cassette: cassette(),
      memos: [memo('m1')],
      target: target,
    );
    expect(dir.path, '${target.path}/Untitled cassette');
    final md = File('${dir.path}/transcript.md').readAsStringSync();
    expect(md, contains('(not transcribed)'));
    final json = jsonDecode(File('${dir.path}/cassette.json')
        .readAsStringSync()) as Map<String, dynamic>;
    expect(((json['memos'] as List).single as Map)['audio'], isNull);
  });

  test('never overwrites: same label claims a suffixed folder', () async {
    final target = Directory('${work.path}/out')..createSync();
    const exporter = CassetteExporter();
    final first = await exporter.exportCassette(
        cassette: cassette(label: 'Notes'), memos: [], target: target);
    final second = await exporter.exportCassette(
        cassette: cassette(label: 'Notes'), memos: [], target: target);
    expect(first.path, '${target.path}/Notes');
    expect(second.path, '${target.path}/Notes (2)');
  });

  test('hostile labels become filesystem-safe folder names', () async {
    final target = Directory('${work.path}/out')..createSync();
    final dir = await const CassetteExporter().exportCassette(
      cassette: cassette(label: 'a/b\\c: *what?* <no|way> "x"'),
      memos: [],
      target: target,
    );
    expect(dir.path, isNot(contains('/a/b')));
    expect(dir.existsSync(), isTrue);
  });
}
