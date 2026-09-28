/// The queue's progress stream (issue #18): while a memo is on the engine
/// the queue says which one and how far, and says "idle" (null) the moment
/// it is off — whether the pass ended well, failed or was cancelled.
library;

import 'dart:async';

import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/repositories/cassette_repository.dart';
import 'package:diktafon/data/repositories/memo_repository.dart';
import 'package:diktafon/data/repositories/settings_repository.dart';
import 'package:diktafon/domain/models.dart';
import 'package:diktafon/services/processing/job_queue.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'job_queue_test.dart'
    show FakeSummarizationProvider, FakeTranscriptionProvider;

void main() {
  late AppDatabase db;
  late MemoRepository memos;
  late FakeTranscriptionProvider engine;
  late JobQueue queue;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    memos = MemoRepository(db);
    engine = FakeTranscriptionProvider();
    queue = JobQueue(db, memos, CassetteRepository(db),
        SettingsRepository(db), () => engine, () => FakeSummarizationProvider(),
        retryDelayUnit: Duration.zero);
    await db.into(db.cassettes).insert(CassetteRow(
          id: 'c1',
          titleIsUserSet: false,
          colorSeed: 1,
          createdAt: 0,
          updatedAt: 0,
        ));
    await memos.insert(Memo(
      id: 'm1',
      cassetteId: 'c1',
      filePath: '/audio/c1/m1.m4a',
      durationMs: 4000,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      status: MemoStatus.stored,
    ));
  });

  tearDown(() async {
    queue.dispose();
    await db.close();
  });

  test('a pass is narrated: on it at 0, each report, then idle', () async {
    engine.progressSteps = const [0.3, 0.8];
    final seen = <TranscriptionProgress?>[];
    final sub = queue.watchTranscriptionProgress().listen(seen.add);

    await queue.enqueueTranscription('m1');
    await queue.drain();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(seen.first, isNull, reason: 'idle before anything is queued');
    final reports = seen.whereType<TranscriptionProgress>().toList();
    expect(reports.map((p) => p.fraction), [0.0, 0.3, 0.8]);
    expect(reports.map((p) => p.memoId).toSet(), {'m1'});
    expect(reports.map((p) => p.cassetteId).toSet(), {'c1'});
    expect(seen.last, isNull, reason: 'idle again once the memo is off');
  });

  test('a late subscriber gets the current position at once', () async {
    engine.gate = Completer<void>();
    await queue.enqueueTranscription('m1');
    final draining = queue.drain();
    await Future<void>.delayed(Duration.zero); // the engine is now "busy"

    final first = await queue.watchTranscriptionProgress().first;
    expect(first, isNotNull);
    expect(first!.memoId, 'm1');
    expect(first.fraction, 0.0);

    engine.gate!.complete();
    await draining;
    expect(await queue.watchTranscriptionProgress().first, isNull);
  });

  test('a failed pass leaves the engine idle, not stuck on the memo',
      () async {
    engine.failuresBeforeSuccess = 1;
    await queue.enqueueTranscription('m1');
    await queue.drain();
    // The retry succeeds within the same drain; either way the stream ends
    // on idle and never reports a memo the engine is not on.
    expect(await queue.watchTranscriptionProgress().first, isNull);
  });
}
