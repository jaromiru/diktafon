import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/database.dart';
import '../../data/repositories/cassette_repository.dart';
import '../../data/repositories/memo_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models.dart';
import '../providers/summarization_provider.dart';
import '../providers/transcription_provider.dart';

/// The §6.5 job types. The cassette overview is always rebuilt from *all*
/// memo gists (§6.7 revised 2026-07-08), so `recomputeCassetteSummary` and
/// `updateCassetteSummary` run the same code — it stays, like
/// `cleanupTranscript` (the retired §6.8 LLM cleanup stage, now routed
/// straight to the gist), only so job rows persisted by older builds keep
/// draining.
enum JobType {
  transcribe,
  cleanupTranscript,
  summarizeMemo,
  updateCassetteSummary,
  recomputeCassetteSummary;

  bool get targetsMemo =>
      this == transcribe || this == cleanupTranscript || this == summarizeMemo;
}

/// Durable background pipeline (§6.5): jobs persist in the DB so they survive
/// restarts; ML concurrency is 1 to bound CPU/thermals/battery.
///
/// Providers are resolved through getters on every use so a Settings tier
/// switch takes effect without rebuilding the queue (rebuilding could let two
/// queues drain the same jobs).
class JobQueue {
  JobQueue(this._db, this._memos, this._cassettes, this._settings,
      this._transcription, this._summarization,
      {this._retryDelayUnit = const Duration(seconds: 1)});

  final AppDatabase _db;
  final MemoRepository _memos;
  final CassetteRepository _cassettes;
  final SettingsRepository _settings;
  final TranscriptionProvider Function() _transcription;
  final SummarizationProvider Function() _summarization;

  /// Backoff = attempts × this; tests inject zero.
  final Duration _retryDelayUnit;
  final _uuid = const Uuid();

  /// In-flight cancellation handles, by memo id (§14 delete-during-processing).
  final Map<String, CancelToken> _active = {};

  Future<void>? _draining;
  static const _maxAttempts = 5;

  /// Enqueued on record-stop (D7).
  Future<void> enqueueTranscription(String memoId) async {
    await _insertJob(JobType.transcribe, memoId);
    unawaited(drain());
  }

  /// Failed memo → back on the queue at the right stage (§14 retry
  /// affordance): no transcript yet → transcribe again, otherwise only the
  /// summarization is redone.
  Future<void> retryEnrichment(String memoId) async {
    final row = await _memoRow(memoId);
    if (row == null) return;
    if (row.transcript == null) {
      await _memos.updateStatus(memoId, MemoStatus.stored);
      await _insertJob(JobType.transcribe, memoId);
    } else {
      await _memos.updateStatus(memoId, MemoStatus.transcribed);
      await _insertJob(JobType.summarizeMemo, memoId);
    }
    unawaited(drain());
  }

  /// Re-runs the whole enrichment pipeline for every memo on the cassette —
  /// the user installed a more capable model and wants the texts refreshed.
  /// In-flight and queued work is cancelled, transcripts and gists wiped,
  /// and fresh transcribe jobs queued in tape order. The overview follows
  /// for free: each new gist schedules the coalesced cassette update, and
  /// the old overview stays visible until it's replaced.
  Future<void> retranscribeCassette(String cassetteId) async {
    // A queued overview rebuild would see the wiped gists and blank the
    // summary early — drop it; the new gists schedule their own.
    await cancelJobsFor(cassetteId);
    for (final memo in await _memos.memosOf(cassetteId)) {
      await cancelJobsFor(memo.id);
      await _memos.resetEnrichment(memo.id);
      await _insertJob(JobType.transcribe, memo.id);
    }
    unawaited(drain());
  }

  /// Cancels pending *and in-flight* work for a deleted memo (§14).
  Future<void> cancelJobsFor(String targetId) async {
    _active[targetId]?.cancel();
    await (_db.delete(_db.jobs)
          ..where(
              (j) => j.targetId.equals(targetId) & j.status.equals('queued')))
        .go();
  }

  /// Call after a memo's row is gone: if its gist was part of the cassette
  /// summary, schedule the rebuild (§14 "cassette summary is scheduled to
  /// update").
  Future<void> onMemoDeleted(Memo memo) async {
    if (memo.memoSummary == null) return;
    await _enqueueCassetteUpdate(memo.cassetteId);
    unawaited(drain());
  }

  /// Processes queued jobs sequentially. Called on app start (resume after
  /// restart), after every enqueue, when a model finishes downloading, and
  /// when summaries are re-enabled. Awaiting joins the drain already in
  /// flight, if any.
  Future<void> drain() => _draining ??=
      _drainLoop().whenComplete(() => _draining = null);

  Future<void> _drainLoop() async {
    while (true) {
      // Enrichment waits for a provisioned model (§14) — and summarization
      // additionally for the Settings toggle; blocked jobs stay queued.
      // Re-checked every iteration: models/settings can change mid-drain.
      final settings = await _settings.get();
      final llmReady =
          await _summarization().modelStatus() == ModelStatus.ready;
      final runnable = <String>[];
      if (await _transcription().modelStatus() == ModelStatus.ready) {
        runnable.add(JobType.transcribe.name);
      }
      // Legacy cleanup rows only hand over to the gist — no LLM involved,
      // so they are always runnable.
      runnable.add(JobType.cleanupTranscript.name);
      if (settings.summariesEnabled && llmReady) {
        runnable.addAll([
          JobType.summarizeMemo.name,
          JobType.updateCassetteSummary.name,
          JobType.recomputeCassetteSummary.name,
        ]);
      }

      final job = await (_db.select(_db.jobs)
            ..where((j) => j.status.equals('queued') & j.type.isIn(runnable))
            ..orderBy([(j) => OrderingTerm.asc(j.createdAt)])
            ..limit(1))
          .getSingleOrNull();
      if (job == null) return;
      await _run(job);
    }
  }

  Future<void> _run(JobRow job) async {
    final type = JobType.values.byName(job.type);
    await _setJob(job.id, 'running', attempts: job.attempts + 1);
    try {
      switch (type) {
        case JobType.transcribe:
          await _transcribe(job.targetId);
        case JobType.cleanupTranscript:
          await _legacyCleanupPassthrough(job.targetId);
        case JobType.summarizeMemo:
          await _summarizeMemo(job.targetId);
        case JobType.updateCassetteSummary:
        case JobType.recomputeCassetteSummary:
          await _updateCassetteSummary(job.targetId);
      }
      await _setJob(job.id, 'done');
    } on TranscriptionCancelled {
      // Memo deleted while transcribing — the job is moot, not failed.
      await (_db.delete(_db.jobs)..where((j) => j.id.equals(job.id))).go();
    } catch (_) {
      final attempts = job.attempts + 1;
      final permanent = attempts >= _maxAttempts;
      await _setJob(job.id, permanent ? 'failed' : 'queued',
          attempts: attempts);
      if (permanent) {
        // Memo stays playable; a retry affordance is offered (§14). Cassette
        // jobs leave no failed memo — their digests stay unfolded and ride
        // along with the next successful update.
        if (type.targetsMemo) {
          await _memos.updateStatus(job.targetId, MemoStatus.failed);
        }
      } else {
        // Brief backoff so transient failures don't hot-loop (§6.5).
        await Future<void>.delayed(_retryDelayUnit * attempts);
      }
    }
  }

  Future<void> _transcribe(String memoId) async {
    final row = await _memoRow(memoId);
    if (row == null) return; // deleted meanwhile (§14)

    final cancel = CancelToken();
    _active[memoId] = cancel;
    try {
      await _memos.updateStatus(memoId, MemoStatus.transcribing);
      final settings = await _settings.get();
      final transcript = await _transcription().transcribe(
        AudioRef(row.filePath),
        languageCode: settings.appLanguage,
        cancel: cancel,
      );

      if (transcript.isEmpty) {
        // Empty/near-silent memo: kept playable, summary skipped (§14, §6.7)
        // — nothing left to enrich.
        await _memos.setTranscript(memoId, transcript, MemoStatus.ready);
      } else {
        await _memos.setTranscript(memoId, transcript, MemoStatus.transcribed);
        // The gist job waits in the queue while its model is missing or
        // summaries are disabled — the drain gate holds it, never the memo.
        await _insertJob(JobType.summarizeMemo, memoId);
      }
    } finally {
      _active.remove(memoId);
    }
  }

  /// A cleanup row persisted by a pre-removal build (§6.8, retired
  /// 2026-07-13: the phase-0 bench showed LLM cleanup is accuracy-inert at
  /// ~1.2× the ASR's runtime): hand the memo to the gist stage unchanged.
  Future<void> _legacyCleanupPassthrough(String memoId) async {
    final row = await _memoRow(memoId);
    if (row == null || row.transcript == null) return;
    await _insertJob(JobType.summarizeMemo, memoId);
  }

  Future<void> _summarizeMemo(String memoId) async {
    final row = await _memoRow(memoId);
    if (row == null) return; // deleted meanwhile (§14)
    final transcriptJson = row.transcript;
    if (transcriptJson == null) return; // can't happen; be safe

    final transcript = Transcript.fromJson(
        (jsonDecode(transcriptJson) as Map).cast<String, dynamic>());
    if (transcript.isEmpty) {
      // Nothing to summarize (§6.7) — reachable via retryEnrichment on a
      // silent memo; complete the enrichment instead of prompting the LLM.
      await _memos.setMemoSummary(memoId, null, MemoStatus.ready);
      return;
    }
    await _memos.updateStatus(memoId, MemoStatus.summarizing);

    final language = await _languageFor(row.detectedLang);
    final summary = (await _summarization()
            .summarizeMemo(transcript, languageCode: language))
        .trim();

    // An empty gist (model produced nothing usable) is recorded as "no
    // summary", not a failure — the memo is still fully enriched (§6.7).
    await _memos.setMemoSummary(
        memoId, summary.isEmpty ? null : summary, MemoStatus.ready);
    if (summary.isNotEmpty) {
      await _enqueueCassetteUpdate(row.cassetteId);
    }
  }

  /// Rebuilds the overview from *all* memo gists, in tape order (§6.7
  /// revised): always faithful to the tape's current content — additions
  /// and deletions alike — at the cost of re-reading every digest (bounded
  /// by the prompt's char budget).
  Future<void> _updateCassetteSummary(String cassetteId) async {
    final cassette = await (_db.select(_db.cassettes)
          ..where((c) => c.id.equals(cassetteId)))
        .getSingleOrNull();
    if (cassette == null) return; // deleted meanwhile (§14)

    final rows = await (_db.select(_db.memos)
          ..where((m) =>
              m.cassetteId.equals(cassetteId) & m.memoSummary.isNotNull())
          ..orderBy([
            (m) => OrderingTerm.asc(m.createdAt),
            (m) => OrderingTerm.asc(m.id),
          ]))
        .get();
    if (rows.isEmpty) {
      // The last summarized memo was deleted — the overview no longer
      // describes anything; the (possibly user-set) label stays.
      await _cassettes.setSummary(cassetteId, null);
      return;
    }

    final language = await _languageFor(rows.first.detectedLang);
    final summary = (await _summarization().updateCassetteSummary(
      previousSummary: null,
      newMemos: [
        for (final row in rows)
          MemoDigest(
            memoSummary: row.memoSummary!,
            createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
          ),
      ],
      languageCode: language,
    ))
        .trim();
    if (summary.isEmpty) return;

    await _cassettes.setSummary(cassetteId, summary);

    // D10 (revised): a title is suggested only while the label is blank —
    // effectively once, with the first overview; after that the name stays
    // put until the user renames.
    if (cassette.label == null && !cassette.titleIsUserSet) {
      final title = await _summarization()
          .suggestTitle(summary, languageCode: language);
      if (title.trim().isNotEmpty) {
        await _cassettes.setSuggestedLabel(cassetteId, title.trim());
      }
    }
  }

  /// D8: languages are per memo — an explicit Settings override wins (for
  /// speakers whisper keeps mis-detecting), otherwise the memo's own
  /// detection; 'en' only as the last resort.
  Future<String> _languageFor(String? detectedLang) async =>
      (await _settings.get()).appLanguage ?? detectedLang ?? 'en';

  /// Coalescing (§6.5 debounce): the rebuild reads the tape's state at run
  /// time, so one queued cassette job covers every gist (or deletion) that
  /// lands before it runs — bursts collapse into a single update.
  Future<void> _enqueueCassetteUpdate(String cassetteId) async {
    final queued = await (_db.select(_db.jobs)
          ..where((j) =>
              j.targetId.equals(cassetteId) &
              j.status.equals('queued') &
              j.type.isIn([
                JobType.updateCassetteSummary.name,
                JobType.recomputeCassetteSummary.name,
              ])))
        .get();
    if (queued.isNotEmpty) return;
    await _insertJob(JobType.updateCassetteSummary, cassetteId);
  }

  Future<MemoRow?> _memoRow(String memoId) =>
      (_db.select(_db.memos)..where((m) => m.id.equals(memoId)))
          .getSingleOrNull();

  Future<void> _insertJob(JobType type, String targetId) =>
      _db.into(_db.jobs).insert(JobRow(
            id: _uuid.v4(),
            type: type.name,
            targetId: targetId,
            status: 'queued',
            attempts: 0,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ));

  Future<void> _setJob(String id, String status, {int? attempts}) =>
      (_db.update(_db.jobs)..where((j) => j.id.equals(id))).write(JobsCompanion(
        status: Value(status),
        attempts: attempts == null ? const Value.absent() : Value(attempts),
      ));
}
