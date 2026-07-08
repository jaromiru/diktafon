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

class FakeSummarizationProvider implements SummarizationProvider {
  FakeSummarizationProvider({this.status = ModelStatus.ready});

  ModelStatus status;
  int memoCalls = 0, cassetteCalls = 0, titleCalls = 0, cleanCalls = 0;
  int memoFailuresBeforeSuccess = 0;
  String memoResult = 'gist';
  String titleResult = 'Suggested Title';

  /// Rewrites applied by cleanTranscript; identity when null.
  Transcript Function(Transcript)? cleanTransform;
  bool cleanThrows = false;

  String? lastLanguageCode;
  String? lastPreviousSummary;
  List<MemoDigest>? lastDigests;

  @override
  String get id => 'fake/llm';

  @override
  Future<ModelStatus> modelStatus() async => status;

  @override
  Future<void> ensureModel({ProgressSink? onProgress}) async {}

  @override
  Future<Transcript> cleanTranscript(Transcript t,
      {required String languageCode}) async {
    cleanCalls++;
    if (cleanThrows) throw StateError('flaky cleanup');
    return cleanTransform?.call(t) ?? t;
  }

  @override
  Future<String> summarizeMemo(Transcript t,
      {required String languageCode}) async {
    memoCalls++;
    lastLanguageCode = languageCode;
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
        id,
        Transcript(languageCode: 'cs', segments: [
          Segment(startMs: 0, endMs: 900, words: [
            Word(text: 'memo', startMs: 0, endMs: 400),
            Word(text: id, startMs: 450, endMs: 900),
          ]),
        ]),
        MemoStatus.transcribed);
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
      expect((await jobs()).map((j) => j.status), everyElement('done'));
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

      engine.result = Transcript(languageCode: 'de', segments: [
        Segment(startMs: 0, endMs: 900, words: const [
          Word(text: 'hallo', startMs: 0, endMs: 400),
        ]),
      ]);
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
      expect((await jobs()).single.type, JobType.transcribe.name,
          reason: 'no summarize job for a silent memo');
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

  group('§6.8 transcript cleanup', () {
    test('cleanup slots between transcription and the gist; raw preserved',
        () async {
      llm.cleanTransform = (t) => Transcript(
            languageCode: t.languageCode,
            segments: [
              Segment(startMs: 0, endMs: 900, words: const [
                Word(text: 'Ahoj,', startMs: 0, endMs: 450),
                Word(text: 'světe!', startMs: 450, endMs: 900),
              ]),
            ],
          );
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      final memo = await memoRow('m1');
      expect(memo.status, 'ready');
      expect(llm.cleanCalls, 1);
      expect(memo.transcript, contains('světe!'),
          reason: 'the cleaned transcript is the one shown');
      expect(memo.rawTranscript, isNotNull,
          reason: 'the engine\'s original take stays recoverable');
      expect(memo.rawTranscript, isNot(contains('světe!')));
      expect(memo.memoSummary, 'gist',
          reason: 'the gist runs after (and on) the cleaned transcript');
      expect((await jobs()).map((j) => j.status), everyElement('done'));
    });

    test('toggled off → straight to the gist, transcript untouched',
        () async {
      await settings.setCleanupEnabled(false);
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      expect(llm.cleanCalls, 0);
      final memo = await memoRow('m1');
      expect(memo.status, 'ready');
      expect(memo.rawTranscript, isNull);
    });

    test('cleanup is best-effort: an engine error keeps the original and '
        'still summarizes', () async {
      llm.cleanThrows = true;
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();

      final memo = await memoRow('m1');
      expect(memo.status, 'ready');
      expect(memo.rawTranscript, isNull, reason: 'nothing was rewritten');
      expect(memo.transcript, contains('světe'));
      expect(memo.memoSummary, 'gist');
      expect((await jobs()).map((j) => j.status), everyElement('done'),
          reason: 'a cleanup hiccup never fails the pipeline');
    });

    test('cleanup waits for the LLM; toggling off releases the memo as a '
        'pass-through', () async {
      llm.status = ModelStatus.notInstalled;
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();
      expect((await memoRow('m1')).status, 'transcribed',
          reason: 'cleanup parked on the missing model (§14)');
      expect(llm.cleanCalls, 0);

      await settings.setCleanupEnabled(false);
      await queue.drain();
      expect(llm.cleanCalls, 0,
          reason: 'released as a pass-through, not run');
      expect((await memoRow('m1')).rawTranscript, isNull);

      llm.status = ModelStatus.ready;
      await queue.drain();
      expect((await memoRow('m1')).status, 'ready');
      expect((await memoRow('m1')).memoSummary, 'gist');
    });

    test('an already-cleaned memo is not cleaned twice on retry', () async {
      await seedMemo('m1');
      await queue.enqueueTranscription('m1');
      await queue.drain();
      expect(llm.cleanCalls, 1);
      expect((await memoRow('m1')).rawTranscript, isNotNull);

      await queue.retryEnrichment('m1');
      await queue.drain();
      expect(llm.cleanCalls, 1,
          reason: 'rawTranscript marks the cleanup as done');
      expect((await memoRow('m1')).status, 'ready');
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
      expect((await jobs()).map((j) => j.status), everyElement('done'));
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
      expect(llm.cassetteCalls, 0,
          reason: 'nothing to fold into the cassette summary');
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
}
