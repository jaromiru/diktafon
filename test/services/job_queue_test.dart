import 'dart:async';

import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/repositories/cassette_repository.dart';
import 'package:diktafon/data/repositories/memo_repository.dart';
import 'package:diktafon/data/repositories/settings_repository.dart';
import 'package:diktafon/domain/models.dart';
import 'package:diktafon/services/processing/job_queue.dart';
import 'package:diktafon/services/providers/summarization_provider.dart';
import 'package:diktafon/services/providers/transcription_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plain text well past [gistTranscriptThreshold] — long enough to earn a
/// gist (§6.7 revised); the [lead] words come first so tests can keep
/// asserting on them.
Transcript longTranscript(String lang, List<String> lead) {
  final words = [...lead, for (var i = 0; i < 60; i++) 'slovo$i'];
  return Transcript(languageCode: lang, segments: [
    Segment(startMs: 0, endMs: words.length * 100, words: [
      for (final (i, w) in words.indexed)
        Word(text: w, startMs: i * 100, endMs: i * 100 + 90),
    ]),
  ]);
}

/// A transcript under the §6.7 gate — its text is its own summary.
Transcript shortTranscript(String lang, String text) {
  final words = text.split(' ');
  return Transcript(languageCode: lang, segments: [
    Segment(startMs: 0, endMs: words.length * 100, words: [
      for (final (i, w) in words.indexed)
        Word(text: w, startMs: i * 100, endMs: i * 100 + 90),
    ]),
  ]);
}

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
    // Long by default: most tests exercise the full gist pipeline; the
    // §6.7-gate group overrides [result] with short transcripts.
    return result ?? longTranscript('cs', const ['ahoj', 'světe']);
  }
}

class FakeSummarizationProvider implements SummarizationProvider {
  FakeSummarizationProvider({this.status = ModelStatus.ready});

  ModelStatus status;
  int memoCalls = 0, cassetteCalls = 0, titleCalls = 0;
  int memoFailuresBeforeSuccess = 0;
  String memoResult = 'gist';
  String titleResult = 'Suggested Title';

  String? lastLanguageCode;
  String? lastPreviousSummary;
  List<MemoDigest>? lastDigests;

  /// Lets a test act (close a gate, flip settings) mid-"inference".
  Completer<void>? gate;

  @override
  String get id => 'fake/llm';

  @override
  Future<ModelStatus> modelStatus() async => status;

  @override
  Future<void> ensureModel({ProgressSink? onProgress}) async {}

  @override
  Future<String> summarizeMemo(Transcript t,
      {required String languageCode}) async {
    memoCalls++;
    lastLanguageCode = languageCode;
    if (gate != null) await gate!.future;
    if (memoFailuresBeforeSuccess > 0) {
      memoFailuresBeforeSuccess--;
      throw StateError('flaky llm');
    }
    return memoResult;
  }

  @override
  Future<String> updateCassetteSummary({
    required String? previousSummary,
    required List<MemoDigest> newMemos,
    required String languageCode,
  }) async {
    cassetteCalls++;
    lastPreviousSummary = previousSummary;
    lastDigests = newMemos;
    final gists = newMemos.map((m) => m.memoSummary).join(' | ');
    return previousSummary == null
        ? 'overview[$gists]'
        : '$previousSummary + [$gists]';
  }

  @override
  Future<String> suggestTitle(String cassetteSummary,
      {required String languageCode}) async {
    titleCalls++;
    return titleResult;
  }
}

void main() {
  late AppDatabase db;
  late MemoRepository memos;
  late CassetteRepository cassettes;
  late SettingsRepository settings;
  late FakeTranscriptionProvider engine;
  late FakeSummarizationProvider llm;
  late JobQueue queue;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    memos = MemoRepository(db);
    cassettes = CassetteRepository(db);
    settings = SettingsRepository(db);
    engine = FakeTranscriptionProvider();
    llm = FakeSummarizationProvider();
    queue = JobQueue(db, memos, cassettes, settings, () => engine, () => llm,
        retryDelayUnit: Duration.zero);
    await db.into(db.cassettes).insert(CassetteRow(
          id: 'c1',
          titleIsUserSet: false,
          colorSeed: 1,
          createdAt: 0,
          updatedAt: 0,
        ));
  });

  tearDown(() => db.close());

  var seeded = 0;
  Future<Memo> seedMemo(String id) async {
    final memo = Memo(
      id: id,
      cassetteId: 'c1',
      filePath: '/audio/c1/$id.m4a',
      durationMs: 4000,
      // Distinct stamps keep the tape (and job assertions) deterministic.
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000 + seeded++),
      status: MemoStatus.stored,
    );
    await memos.insert(memo);
    return memo;
  }

  Future<MemoRow> memoRow(String id) =>
      (db.select(db.memos)..where((m) => m.id.equals(id))).getSingle();

  Future<CassetteRow> cassetteRow() =>
      (db.select(db.cassettes)..where((c) => c.id.equals('c1'))).getSingle();

  Future<List<JobRow>> jobs() => db.select(db.jobs).get();

  /// Seeds a memo that already carries a transcript (post-M2 state) plus its
  /// queued summarize job with a controlled timestamp.
  Future<void> seedTranscribed(String id, {required int jobCreatedAt}) async {
    await seedMemo(id);
    await memos.setTranscript(
        id, longTranscript('cs', ['memo', id]), MemoStatus.transcribed);
    await db.into(db.jobs).insert(JobRow(
          id: 'job-$id',
          type: JobType.summarizeMemo.name,
          targetId: id,
          status: 'queued',
          attempts: 0,
          createdAt: jobCreatedAt,
        ));
  }

  group('M2 pipeline (transcription)', () {
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
      expect((await memoRow('m1')).status, 'ready',
          reason: 'M3: the full enrichment now runs through to ready (§4.3)');
      expect((await memoRow('m1')).transcript, contains('světe'));
      expect((await memoRow('m1')).detectedLang, 'cs');
      expect(await jobs(), isEmpty, reason: 'completed jobs are pruned');
    });

    test('D8: no override → per-memo auto-detect; nothing adopted globally',
        () async {
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      expect(engine.lastLanguageCode, isNull,
          reason: 'no override → provider auto-detects per memo');
      expect((await settings.get()).appLanguage, isNull,
          reason: 'detection stays per memo — never adopted app-wide');
      expect(llm.lastLanguageCode, 'cs',
          reason: 'summaries follow the memo\'s own detection (D8)');
    });

    test('D8: memos keep their own language — a tape can mix languages',
        () async {
      await seedMemo('m1');
      await queue.enqueueTranscription('m1'); // detected 'cs'
      await queue.drain();
      expect(llm.lastLanguageCode, 'cs');

      engine.result = longTranscript('de', const ['hallo']);
      await seedMemo('m2');
      await queue.enqueueTranscription('m2');
      await queue.drain();

      expect(engine.lastLanguageCode, isNull,
          reason: 'the second memo auto-detects too');
      expect(llm.lastLanguageCode, 'de',
          reason: 'its summary follows its own detection');
    });

    test('D8: the Settings override is forced onto every transcription',
        () async {
      await settings.setAppLanguage('pl');
      engine.result = const Transcript(languageCode: 'pl', segments: []);
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      expect(engine.lastLanguageCode, 'pl');
      expect((await settings.get()).appLanguage, 'pl');
    });

    test('a silent memo completes without summarization', () async {
      engine.result = const Transcript(languageCode: 'en', segments: []);
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      expect((await settings.get()).appLanguage, isNull);
      expect((await memoRow('m1')).status, 'ready',
          reason: 'empty transcript completes enrichment; summary skipped '
              '(§6.7/§14)');
      expect(llm.memoCalls, 0);
      expect(await jobs(), isEmpty,
          reason: 'no summarize job for a silent memo; done rows are pruned');
    });

    test('transient failures retry with attempts; success on 3rd try',
        () async {
      engine.failuresBeforeSuccess = 2;
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      expect(engine.calls, 3);
      expect((await memoRow('m1')).status, 'ready');
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
  });

  group('§6.5 orphan recovery (process killed mid-run)', () {
    /// A job exactly as a dead process leaves it: 'running', with the
    /// interrupted run's attempt already counted.
    Future<void> seedOrphan(String id, JobType type, String targetId,
            {int attempts = 1}) =>
        db.into(db.jobs).insert(JobRow(
              id: id,
              type: type.name,
              targetId: targetId,
              status: 'running',
              attempts: attempts,
              createdAt: 100,
            ));

    test('an interrupted transcription is requeued; the memo reads as '
        'queued — not stuck "transcribing" — until the rerun', () async {
      await seedMemo('m1');
      await memos.updateStatus('m1', MemoStatus.transcribing);
      await seedOrphan('job-m1', JobType.transcribe, 'm1');

      // Gate the engine so the requeued job parks: this is what the user
      // sees right after relaunch, before the rerun gets to finish.
      engine.status = ModelStatus.notInstalled;
      await queue.drain();
      expect((await jobs()).single.status, 'queued');
      expect((await memoRow('m1')).status, 'stored',
          reason: 'the stale "transcribing…" shimmer is reset');

      engine.status = ModelStatus.ready;
      await queue.drain();
      expect((await memoRow('m1')).status, 'ready');
      expect(engine.calls, 1);
      expect(await jobs(), isEmpty, reason: 'completed jobs are pruned');
    });

    test('an interrupted summarization resumes at the summarize stage',
        () async {
      await seedMemo('m1');
      await memos.setTranscript(
          'm1', longTranscript('cs', const ['ahoj']), MemoStatus.summarizing);
      await seedOrphan('job-m1', JobType.summarizeMemo, 'm1');

      llm.status = ModelStatus.notInstalled;
      await queue.drain();
      expect((await memoRow('m1')).status, 'transcribed',
          reason: 'waiting on the LLM — not stuck "summarizing…"');

      llm.status = ModelStatus.ready;
      await queue.drain();
      expect((await memoRow('m1')).status, 'ready');
      expect((await memoRow('m1')).memoSummary, 'gist');
      expect(engine.calls, 0, reason: 'the transcript is never redone');
    });

    test('attempts survive recovery: a job that kept killing the process '
        'fails permanently instead of crash-looping every launch', () async {
      await seedMemo('m1');
      await memos.updateStatus('m1', MemoStatus.transcribing);
      await seedOrphan('job-m1', JobType.transcribe, 'm1', attempts: 5);

      await queue.drain();
      expect((await jobs()).single.status, 'failed');
      expect((await memoRow('m1')).status, 'failed',
          reason: 'the §14 retry affordance is offered');
      expect(engine.calls, 0);
    });

    test('an interrupted cassette update is requeued and reruns', () async {
      await seedTranscribed('m1', jobCreatedAt: 1);
      await queue.drain();
      expect(llm.cassetteCalls, 1);

      await seedOrphan('job-c1', JobType.updateCassetteSummary, 'c1');
      final fresh = JobQueue(
          db, memos, cassettes, settings, () => engine, () => llm,
          retryDelayUnit: Duration.zero);
      await fresh.drain();

      expect(llm.cassetteCalls, 2, reason: 'the rebuild ran again');
      expect(await jobs(), isEmpty, reason: 'completed jobs are pruned');
    });

    test('an orphan whose memo was deleted is requeued and drains as a '
        'no-op', () async {
      await seedOrphan('job-gone', JobType.transcribe, 'gone');
      await queue.drain();
      expect(await jobs(), isEmpty);
      expect(engine.calls, 0);
    });

    test('recovery runs once per queue instance', () async {
      await seedMemo('m1');
      await memos.updateStatus('m1', MemoStatus.transcribing);
      await seedOrphan('job-m1', JobType.transcribe, 'm1');

      engine.status = ModelStatus.notInstalled;
      await queue.drain();
      expect((await memoRow('m1')).status, 'stored');

      // A later in-process drain must not touch a job this instance is
      // legitimately running — simulate by hand-marking it running again.
      await db.customStatement(
          "UPDATE jobs SET status = 'running' WHERE id = 'job-m1'");
      await queue.drain();
      expect((await jobs()).single.status, 'running',
          reason: 'no second sweep within the same process');
    });
  });

  group('§6.5 self-heal: transient failures, stranded memos, dead rows', () {
    test('a transient failure resets the shimmer: the memo waits as '
        '"stored", not "transcribing", while its job parks behind a '
        'closed gate', () async {
      engine.failuresBeforeSuccess = 99;
      engine.gate = Completer<void>();
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      final draining = queue.drain();
      // Let the attempt start, then close the gate (model deleted / tier
      // switched) before it fails — the requeued job now parks.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      engine.status = ModelStatus.notInstalled;
      engine.gate!.complete();
      await draining;

      expect((await jobs()).single.status, 'queued');
      expect((await memoRow('m1')).status, 'stored',
          reason: 'the failed attempt must not leave a stale shimmer');

      engine.failuresBeforeSuccess = 0;
      engine.status = ModelStatus.ready;
      await queue.drain();
      expect((await memoRow('m1')).status, 'ready');
    });

    test('a transient summarize failure resets the memo to transcribed',
        () async {
      llm.memoFailuresBeforeSuccess = 99;
      llm.gate = Completer<void>();
      await seedTranscribed('m1', jobCreatedAt: 1);
      // One failed attempt, then the summaries switch turns off mid-drain.
      final draining = queue.drain();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await settings.setSummariesEnabled(false);
      llm.gate!.complete();
      await draining;

      expect((await jobs()).single.status, 'queued');
      expect((await memoRow('m1')).status, 'transcribed',
          reason: 'not stuck "summarizing…" while the job parks');
    });

    test('a stranded stored memo with no job is re-enqueued at launch '
        '(kill between insert and enqueue)', () async {
      await seedMemo('m1'); // no job — the enqueue never happened
      await queue.drain();

      expect(engine.calls, 1);
      expect((await memoRow('m1')).status, 'ready');
    });

    test('a stranded transcribing memo resets and requeues', () async {
      await seedMemo('m1');
      await memos.updateStatus('m1', MemoStatus.transcribing);
      engine.status = ModelStatus.notInstalled;
      await queue.drain();

      expect((await memoRow('m1')).status, 'stored');
      expect((await jobs()).single.type, JobType.transcribe.name);
    });

    test('a stranded transcribed memo re-enters at the summarize stage',
        () async {
      await seedMemo('m1');
      await memos.setTranscript(
          'm1', longTranscript('cs', const ['ahoj']), MemoStatus.summarizing);
      llm.status = ModelStatus.notInstalled;
      await queue.drain();

      expect((await memoRow('m1')).status, 'transcribed');
      expect((await jobs()).single.type, JobType.summarizeMemo.name);

      llm.status = ModelStatus.ready;
      await queue.drain();
      expect((await memoRow('m1')).status, 'ready');
      expect(engine.calls, 0, reason: 'the transcript is never redone');
    });

    test('memos with live jobs, and terminal memos, are left alone',
        () async {
      engine.status = ModelStatus.notInstalled;
      await seedMemo('m1');
      await queue.enqueueTranscription('m1'); // covered by its queued job
      await seedMemo('m2');
      await memos.updateStatus('m2', MemoStatus.failed); // terminal (§14)
      await queue.drain();

      expect((await jobs()).single.targetId, 'm1',
          reason: 'no duplicate for m1, nothing for failed m2');
      expect((await memoRow('m2')).status, 'failed');
    });

    test('reconciliation runs once per queue instance', () async {
      await queue.drain(); // consumes the once-guard
      await seedMemo('m1'); // stranded after the sweep
      engine.status = ModelStatus.notInstalled;
      await queue.drain();
      expect(await jobs(), isEmpty,
          reason: 'no second sweep within the same process');
    });

    test('legacy done rows are pruned at the first drain', () async {
      await db.into(db.jobs).insert(JobRow(
            id: 'job-old',
            type: JobType.transcribe.name,
            targetId: 'gone',
            status: 'done',
            attempts: 1,
            createdAt: 1,
          ));
      await queue.drain();
      expect(await jobs(), isEmpty);
    });

    test('cancelCassetteJobs clears memo-level and cassette-level jobs '
        '(cassette delete, §14)', () async {
      engine.status = ModelStatus.notInstalled;
      llm.status = ModelStatus.notInstalled;
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await seedTranscribed('m2', jobCreatedAt: 2);
      await db.into(db.jobs).insert(JobRow(
            id: 'job-c1-update',
            type: JobType.updateCassetteSummary.name,
            targetId: 'c1',
            status: 'queued',
            attempts: 0,
            createdAt: 3,
          ));
      await queue.drain(); // everything parks behind the closed gates

      await queue.cancelCassetteJobs('c1');
      expect(await jobs(), isEmpty);
    });
  });

  group('§6.8 legacy cleanup rows (feature retired 2026-07-13)', () {
    /// A `cleanupTranscript` row as persisted by a pre-removal build.
    Future<void> seedLegacyCleanupJob(String memoId) =>
        db.into(db.jobs).insert(JobRow(
              id: 'legacy-$memoId',
              type: JobType.cleanupTranscript.name,
              targetId: memoId,
              status: 'queued',
              attempts: 0,
              createdAt: 500,
            ));

    test('a persisted cleanup job passes the memo through to the gist',
        () async {
      await seedMemo('m1');
      await memos.setTranscript('m1', longTranscript('cs', const ['ahoj']),
          MemoStatus.transcribed);
      await seedLegacyCleanupJob('m1');
      await queue.drain();

      final memo = await memoRow('m1');
      expect(memo.status, 'ready');
      expect(memo.memoSummary, 'gist');
      expect(memo.rawTranscript, isNull, reason: 'nothing is rewritten');
      expect(await jobs(), isEmpty, reason: 'completed jobs are pruned');
    });

    test('a cleanup row whose memo vanished (or never transcribed) is a no-op',
        () async {
      await seedLegacyCleanupJob('gone');
      await seedMemo('m2'); // stored, no transcript
      await seedLegacyCleanupJob('m2');
      await queue.drain();

      expect(await jobs(), isEmpty, reason: 'completed jobs are pruned');
      expect((await memoRow('m2')).memoSummary, isNull);
    });

    test('legacy rows drain even while the LLM is missing', () async {
      llm.status = ModelStatus.notInstalled;
      await seedMemo('m1');
      await memos.setTranscript('m1', longTranscript('cs', const ['ahoj']),
          MemoStatus.transcribed);
      await seedLegacyCleanupJob('m1');
      await queue.drain();

      final handed = await jobs();
      expect(handed.where((j) => j.type == JobType.cleanupTranscript.name),
          isEmpty,
          reason: 'the passthrough needs no model and completes (pruned)');
      expect(
          handed.where((j) => j.type == JobType.summarizeMemo.name).length, 1,
          reason: 'the gist job parks on the missing model instead');

      llm.status = ModelStatus.ready;
      await queue.drain();
      expect((await memoRow('m1')).status, 'ready');
      expect((await memoRow('m1')).memoSummary, 'gist');
    });
  });

  group('M3 pipeline (summaries)', () {
    test('record-stop → transcribed → summarized → cassette overview + title',
        () async {
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      final memo = await memoRow('m1');
      expect(memo.status, 'ready');
      expect(memo.memoSummary, 'gist');

      final cassette = await cassetteRow();
      expect(cassette.summary, 'overview[gist]');
      expect(cassette.summaryUpdatedAt, isNotNull);
      expect(cassette.label, 'Suggested Title',
          reason: 'auto-suggested from the overview (D10)');
      expect(cassette.titleIsUserSet, isFalse,
          reason: 'suggestion must not lock the label (D10)');
      expect(llm.lastPreviousSummary, isNull);
      expect(await jobs(), isEmpty, reason: 'completed jobs are pruned');
    });

    test('summarize jobs wait while the LLM is missing; transcription flows',
        () async {
      llm.status = ModelStatus.notInstalled;
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      expect((await memoRow('m1')).status, 'transcribed',
          reason: 'transcript done, gist parked (§14 model missing)');
      expect(llm.memoCalls, 0);

      llm.status = ModelStatus.ready; // "model provisioned" (Settings)
      await queue.drain();
      expect((await memoRow('m1')).status, 'ready');
      expect((await cassetteRow()).summary, isNotNull);
    });

    test('summaries toggle off parks the jobs; re-enable releases them (§5.5)',
        () async {
      await settings.setSummariesEnabled(false);
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      expect((await memoRow('m1')).status, 'transcribed');
      expect(llm.memoCalls, 0);

      await settings.setSummariesEnabled(true);
      await queue.drain();
      expect((await memoRow('m1')).status, 'ready');
      expect((await memoRow('m1')).memoSummary, 'gist');
    });

    test('a burst of memos coalesces into one cassette update (§6.5)',
        () async {
      await seedTranscribed('m1', jobCreatedAt: 1);
      await seedTranscribed('m2', jobCreatedAt: 2);
      await queue.drain();

      expect(llm.memoCalls, 2);
      expect(llm.cassetteCalls, 1,
          reason: 'second gist landed before the queued update ran');
      expect(llm.lastDigests, hasLength(2));
      expect(llm.lastDigests!.map((d) => d.memoSummary),
          everyElement('gist'));
      expect((await cassetteRow()).summary, 'overview[gist | gist]');
    });

    test('the overview is rebuilt from every gist on each update (§6.7)',
        () async {
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();
      expect((await cassetteRow()).summary, 'overview[gist]');

      llm.memoResult = 'gist2';
      await seedMemo('m2');
      await queue.enqueueTranscription('m2');
      await queue.drain();

      expect(llm.cassetteCalls, 2);
      expect(llm.lastPreviousSummary, isNull,
          reason: 'rebuilt from scratch — no rolling summary to fold into');
      expect(llm.lastDigests!.map((d) => d.memoSummary), ['gist', 'gist2'],
          reason: 'every memo\'s gist contributes, in tape order');
      expect((await cassetteRow()).summary, 'overview[gist | gist2]');
    });

    test('D10: a title is suggested only while the label is blank', () async {
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();
      expect((await cassetteRow()).label, 'Suggested Title');
      expect(llm.titleCalls, 1);

      llm.titleResult = 'A Better Title';
      await seedMemo('m2');
      await queue.enqueueTranscription('m2');
      await queue.drain();

      expect(llm.titleCalls, 1,
          reason: 'the label is set — no further suggestions');
      expect((await cassetteRow()).label, 'Suggested Title');
      expect((await cassetteRow()).summary, 'overview[gist | gist]',
          reason: 'only the title is frozen; the overview still updates');
    });

    test('D10: user-set titles are never overwritten by suggestions',
        () async {
      await cassettes.rename('c1', 'My Cassette');
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      expect(llm.titleCalls, 0);
      expect((await cassetteRow()).label, 'My Cassette');
      expect((await cassetteRow()).summary, isNotNull,
          reason: 'the overview still updates; only the title is locked');
    });

    test('an empty gist means "no summary", not failure (§6.7)', () async {
      llm.memoResult = '   ';
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      final memo = await memoRow('m1');
      expect(memo.status, 'ready');
      expect(memo.memoSummary, isNull);
      expect(llm.cassetteCalls, 1,
          reason: 'the gistless memo still contributes its transcript');
      expect(llm.lastDigests!.single.memoSummary, startsWith('ahoj světe'));
    });

    test('transient summarize failures retry; transcript is never redone',
        () async {
      llm.memoFailuresBeforeSuccess = 2;
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      expect(engine.calls, 1);
      expect(llm.memoCalls, 3);
      expect((await memoRow('m1')).status, 'ready');
    });

    test('permanent summarize failure → failed but playable; retry resumes '
        'at the summarize stage (§14)', () async {
      llm.memoFailuresBeforeSuccess = 99;
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      final failed = await memoRow('m1');
      expect(failed.status, 'failed');
      expect(failed.transcript, isNotNull,
          reason: 'the transcript survives the failed summarization');

      llm.memoFailuresBeforeSuccess = 0;
      await queue.retryEnrichment('m1');
      await queue.drain();

      expect(engine.calls, 1, reason: 'no re-transcription');
      expect((await memoRow('m1')).status, 'ready');
      expect((await memoRow('m1')).memoSummary, 'gist');
    });

    test('deleting a summarized memo schedules the overview rebuild (§14)',
        () async {
      final m1 = await seedMemo('m1');
      await seedMemo('m2');
      await queue.enqueueTranscription('m1');
      await queue.enqueueTranscription('m2');
      await queue.drain();

      // The screen's delete flow: cancel, remove row, notify the queue.
      final deleted = Memo(
        id: m1.id,
        cassetteId: m1.cassetteId,
        filePath: m1.filePath,
        durationMs: m1.durationMs,
        createdAt: m1.createdAt,
        status: MemoStatus.ready,
        memoSummary: (await memoRow('m1')).memoSummary,
      );
      await queue.cancelJobsFor('m1');
      await memos.delete('m1');
      await queue.onMemoDeleted(deleted);
      await queue.drain();

      expect(llm.lastPreviousSummary, isNull,
          reason: 'the rebuild starts from scratch — the deleted memo\'s '
              'content simply is not among the inputs');
      expect(llm.lastDigests!.map((d) => d.memoSummary), ['gist'],
          reason: 'only the surviving memo contributes');
    });

    test('deleting the last summarized memo clears the cassette summary',
        () async {
      final m1 = await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();
      expect((await cassetteRow()).summary, isNotNull);

      final deleted = Memo(
        id: m1.id,
        cassetteId: m1.cassetteId,
        filePath: m1.filePath,
        durationMs: m1.durationMs,
        createdAt: m1.createdAt,
        status: MemoStatus.ready,
        memoSummary: 'gist',
      );
      await queue.cancelJobsFor('m1');
      await memos.delete('m1');
      await queue.onMemoDeleted(deleted);
      await queue.drain();

      expect((await cassetteRow()).summary, isNull);
    });

    test('retryEnrichment on a silent memo completes without the LLM',
        () async {
      await seedMemo('m1');
      await memos.setTranscript(
          'm1',
          const Transcript(languageCode: 'en', segments: []),
          MemoStatus.failed);
      await queue.retryEnrichment('m1');
      await queue.drain();

      expect((await memoRow('m1')).status, 'ready');
      expect(llm.memoCalls, 0, reason: 'nothing to summarize (§6.7)');
    });

    test('retranscribeCassette wipes enrichment and re-runs the pipeline',
        () async {
      await seedMemo('m1');
      await seedMemo('m2');
      await queue.enqueueTranscription('m1');
      await queue.enqueueTranscription('m2');
      await queue.drain();
      expect(engine.calls, 2);
      expect((await memoRow('m1')).transcript, isNotNull);
      expect((await memoRow('m1')).memoSummary, 'gist');

      // "A better model was installed": the engine now hears more.
      engine.result = longTranscript('cs', const ['lepší', 'přepis']);
      llm.memoResult = 'better gist';
      await queue.retranscribeCassette('c1');
      await queue.drain();

      expect(engine.calls, 4, reason: 'both memos transcribed again');
      for (final id in ['m1', 'm2']) {
        final memo = await memoRow(id);
        expect(memo.status, 'ready');
        expect(memo.transcript, contains('lepší'));
        expect(memo.memoSummary, 'better gist');
      }
      expect((await cassetteRow()).summary,
          'overview[better gist | better gist]',
          reason: 'the overview is rebuilt from the fresh gists');
      expect(await jobs(), isEmpty, reason: 'completed jobs are pruned');
    });

    test('retranscribe keeps the old overview until the new gists land, and '
        'never re-suggests a title over an existing label', () async {
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();
      expect((await cassetteRow()).summary, 'overview[gist]');
      expect((await cassetteRow()).label, 'Suggested Title');
      expect(llm.titleCalls, 1);

      // Park the LLM: transcription reruns, but gists (and the overview
      // rebuild) wait — the stale overview must survive the wipe.
      llm.status = ModelStatus.notInstalled;
      await queue.retranscribeCassette('c1');
      await queue.drain();
      expect((await memoRow('m1')).status, 'transcribed');
      expect((await memoRow('m1')).memoSummary, isNull);
      expect((await cassetteRow()).summary, 'overview[gist]',
          reason: 'no premature blanking while the rebuild is parked');

      llm.status = ModelStatus.ready;
      await queue.drain();
      expect((await memoRow('m1')).status, 'ready');
      expect(llm.titleCalls, 1,
          reason: 'the label is set — retranscribe never renames (D10)');
    });

    test('retranscribe drops a parked overview rebuild that would see the '
        'wiped gists', () async {
      // Gist landed but its cassette update is still queued (LLM gone).
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();
      llm.status = ModelStatus.notInstalled;
      await db.into(db.jobs).insert(JobRow(
            id: 'job-stale-update',
            type: JobType.updateCassetteSummary.name,
            targetId: 'c1',
            status: 'queued',
            attempts: 0,
            createdAt: 99,
          ));

      await queue.retranscribeCassette('c1');
      await queue.drain();

      final staleUpdates = (await jobs())
          .where((j) => j.targetId == 'c1' && j.status == 'queued')
          .toList();
      expect(staleUpdates, isEmpty,
          reason: 'the stale rebuild is cancelled; fresh gists queue theirs');
      expect((await cassetteRow()).summary, 'overview[gist]',
          reason: 'the overview was not blanked by a stale rebuild');
    });

    test('a delete coalesces with an already-queued cassette update', () async {
      // Gate the LLM so the queue can't drain the jobs we assert on.
      llm.status = ModelStatus.notInstalled;
      await seedTranscribed('m1', jobCreatedAt: 1);
      // Park an update as if a gist had landed earlier.
      await db.into(db.jobs).insert(JobRow(
            id: 'job-update',
            type: JobType.updateCassetteSummary.name,
            targetId: 'c1',
            status: 'queued',
            attempts: 0,
            createdAt: 2,
          ));
      final m0 = Memo(
        id: 'm0',
        cassetteId: 'c1',
        filePath: '/audio/c1/m0.m4a',
        durationMs: 1000,
        createdAt: DateTime.fromMillisecondsSinceEpoch(999),
        status: MemoStatus.ready,
        memoSummary: 'old gist',
      );
      await queue.onMemoDeleted(m0);
      // Join the internal drain (gated, so it parks the jobs) before the
      // teardown closes the database under it.
      await queue.drain();

      final queued = (await jobs())
          .where((j) =>
              j.status == 'queued' &&
              (j.type == JobType.updateCassetteSummary.name ||
                  j.type == JobType.recomputeCassetteSummary.name))
          .toList();
      expect(queued, hasLength(1),
          reason: 'the rebuild reads the tape at run time, so the queued '
              'update already covers the deletion — nothing new to add');
    });
  });

  group('§6.7 revised: the $gistTranscriptThreshold-char gist gate', () {
    test('a short transcript completes without the LLM; the overview reads '
        'the transcript directly', () async {
      engine.result = shortTranscript('cs', 'koupit mléko a chleba');
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      final memo = await memoRow('m1');
      expect(memo.status, 'ready');
      expect(memo.memoSummary, isNull, reason: 'no gist under the gate');
      expect(llm.memoCalls, 0, reason: 'the gist LLM pass is skipped');
      expect(llm.cassetteCalls, 1);
      expect(llm.lastDigests!.single.memoSummary, 'koupit mléko a chleba');
      expect((await cassetteRow()).summary,
          'overview[koupit mléko a chleba]');
      expect((await cassetteRow()).label, 'Suggested Title',
          reason: 'a transcript-only overview still suggests a title (D10)');
    });

    test('the gate is strict: at the threshold no gist, one char past it '
        'a gist', () async {
      engine.result = shortTranscript('cs', 'a' * gistTranscriptThreshold);
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();
      expect((await memoRow('m1')).memoSummary, isNull);
      expect(llm.memoCalls, 0);

      engine.result =
          shortTranscript('cs', 'a' * (gistTranscriptThreshold + 1));
      await seedMemo('m2');
      await queue.enqueueTranscription('m2');
      await queue.drain();
      expect((await memoRow('m2')).memoSummary, 'gist');
      expect(llm.memoCalls, 1);
    });

    test('a short memo never waits on the LLM — only its overview job parks',
        () async {
      llm.status = ModelStatus.notInstalled;
      engine.result = shortTranscript('cs', 'zavolat mámě');
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      expect((await memoRow('m1')).status, 'ready',
          reason: 'the memo is fully enriched without the LLM');
      final parked = (await jobs()).where((j) => j.status == 'queued');
      expect(parked.single.type, JobType.updateCassetteSummary.name);

      llm.status = ModelStatus.ready;
      await queue.drain();
      expect((await cassetteRow()).summary, 'overview[zavolat mámě]');
    });

    test('mixed tape: gists and short transcripts feed the overview in '
        'tape order', () async {
      await seedMemo('m1'); // long default → gist
      await queue.enqueueTranscription('m1');
      await queue.drain();

      engine.result = shortTranscript('cs', 'zavolat mámě');
      await seedMemo('m2');
      await queue.enqueueTranscription('m2');
      await queue.drain();

      expect(llm.lastDigests!.map((d) => d.memoSummary),
          ['gist', 'zavolat mámě']);
      expect((await cassetteRow()).summary,
          'overview[gist | zavolat mámě]');
    });

    test('a multi-segment short transcript is flattened to one digest line',
        () async {
      engine.result = Transcript(languageCode: 'cs', segments: [
        Segment(startMs: 0, endMs: 400, words: const [
          Word(text: 'první', startMs: 0, endMs: 400),
        ]),
        Segment(startMs: 500, endMs: 900, words: const [
          Word(text: 'druhá', startMs: 500, endMs: 900),
        ]),
      ]);
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      expect(llm.lastDigests!.single.memoSummary, 'první druhá',
          reason: 'newlines would break the prompt\'s bullet list');
    });

    test('retryEnrichment on a short-transcript memo completes without '
        'the LLM', () async {
      await seedMemo('m1');
      await memos.setTranscript(
          'm1', shortTranscript('cs', 'krátká poznámka'), MemoStatus.failed);
      await queue.retryEnrichment('m1');
      await queue.drain();

      expect((await memoRow('m1')).status, 'ready');
      expect((await memoRow('m1')).memoSummary, isNull);
      expect(llm.memoCalls, 0);
      expect((await cassetteRow()).summary, 'overview[krátká poznámka]');
    });

    test('deleting a gistless short memo schedules the overview rebuild',
        () async {
      engine.result = shortTranscript('cs', 'první poznámka');
      final m1 = await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();
      engine.result = shortTranscript('cs', 'druhá poznámka');
      await seedMemo('m2');
      await queue.enqueueTranscription('m2');
      await queue.drain();

      final deleted = Memo(
        id: m1.id,
        cassetteId: m1.cassetteId,
        filePath: m1.filePath,
        durationMs: m1.durationMs,
        createdAt: m1.createdAt,
        status: MemoStatus.ready,
        transcript: shortTranscript('cs', 'první poznámka'),
      );
      await queue.cancelJobsFor('m1');
      await memos.delete('m1');
      await queue.onMemoDeleted(deleted);
      await queue.drain();

      expect(llm.lastDigests!.map((d) => d.memoSummary), ['druhá poznámka'],
          reason: 'the deleted memo\'s transcript left the overview');
    });

    test('deleting the last short memo clears the cassette summary',
        () async {
      engine.result = shortTranscript('cs', 'jediná poznámka');
      final m1 = await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();
      expect((await cassetteRow()).summary, isNotNull);

      final deleted = Memo(
        id: m1.id,
        cassetteId: m1.cassetteId,
        filePath: m1.filePath,
        durationMs: m1.durationMs,
        createdAt: m1.createdAt,
        status: MemoStatus.ready,
        transcript: shortTranscript('cs', 'jediná poznámka'),
      );
      await queue.cancelJobsFor('m1');
      await memos.delete('m1');
      await queue.onMemoDeleted(deleted);
      await queue.drain();

      expect((await cassetteRow()).summary, isNull);
    });

    test('deleting a memo that contributed nothing is a no-op', () async {
      final m1 = await seedMemo('m1'); // stored — never transcribed
      await memos.delete('m1');
      await queue.onMemoDeleted(m1);
      await queue.drain();

      expect(await jobs(), isEmpty);
      expect(llm.cassetteCalls, 0);
    });
  });
}
