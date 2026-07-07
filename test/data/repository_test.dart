import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/repositories/cassette_repository.dart';
import 'package:diktafon/data/repositories/memo_repository.dart';
import 'package:diktafon/data/repositories/settings_repository.dart';
import 'package:diktafon/domain/models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CassetteRepository cassettes;
  late MemoRepository memos;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cassettes = CassetteRepository(db);
    memos = MemoRepository(db);
    settings = SettingsRepository(db);
  });

  tearDown(() => db.close());

  Memo makeMemo(String cassetteId, String id, {int durationMs = 1000}) => Memo(
        id: id,
        cassetteId: cassetteId,
        filePath: '/audio/$cassetteId/$id.m4a',
        durationMs: durationMs,
        createdAt: DateTime.now(),
        status: MemoStatus.stored,
      );

  test('create → overview aggregates count and duration', () async {
    final c = await cassettes.create();
    expect(c.label, isNull);

    await memos.insert(makeMemo(c.id, 'm1', durationMs: 1500));
    await memos.insert(makeMemo(c.id, 'm2', durationMs: 2500));

    final overviews = await cassettes.watchOverviews().first;
    expect(overviews, hasLength(1));
    expect(overviews.single.memoCount, 2);
    expect(overviews.single.totalDurationMs, 4000);
  });

  test('overviews sort by updatedAt desc (recency, §5.2)', () async {
    final a = await cassettes.create();
    final b = await cassettes.create();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await cassettes.touch(a.id);

    final overviews = await cassettes.watchOverviews().first;
    expect(overviews.first.cassette.id, a.id);
    expect(overviews.last.cassette.id, b.id);
  });

  test('rename sets D10 override; empty rename reverts to placeholder',
      () async {
    final c = await cassettes.create();
    await cassettes.rename(c.id, 'Nákupy');
    var row = await cassettes.watchCassette(c.id).first;
    expect(row!.label, 'Nákupy');
    expect(row.titleIsUserSet, isTrue);

    await cassettes.rename(c.id, '  ');
    row = await cassettes.watchCassette(c.id).first;
    expect(row!.label, isNull);
    expect(row.titleIsUserSet, isFalse);
  });

  test('deleting a cassette cascades to its memos', () async {
    final c = await cassettes.create();
    await memos.insert(makeMemo(c.id, 'm1'));
    await cassettes.delete(c.id);

    final left = await memos.watchMemosOf(c.id).first;
    expect(left, isEmpty);
  });

  test('transcript JSON round-trips through the DB', () async {
    final c = await cassettes.create();
    await memos.insert(makeMemo(c.id, 'm1'));
    const t = Transcript(languageCode: 'cs', segments: [
      Segment(startMs: 0, endMs: 900, words: [
        Word(text: 'Ahoj', startMs: 0, endMs: 300),
      ]),
    ]);
    await memos.setTranscript('m1', t, MemoStatus.transcribed);

    final list = await memos.watchMemosOf(c.id).first;
    expect(list.single.transcript!.segments.single.words.single.text, 'Ahoj');
    expect(list.single.detectedLang, 'cs');
    expect(list.single.status, MemoStatus.transcribed);
  });

  test('settings defaults and persistence (§7.2)', () async {
    var s = await settings.watch().first;
    expect(s.appLanguage, isNull);
    expect(s.chimeEnabled, isTrue);
    expect(s.whisperTier, 'small');
    expect(s.theme, 'system');

    await settings.setChimeEnabled(false);
    await settings.setTheme('dark');
    await settings.setAppLanguage('cs');
    s = await settings.watch().first;
    expect(s.chimeEnabled, isFalse);
    expect(s.theme, 'dark');
    expect(s.appLanguage, 'cs');
  });
}
