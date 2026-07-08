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

/// The three §6.5 job types plus `recomputeCassetteSummary`: incremental
/// folding (§6.7) cannot *remove* a deleted memo's content from the rolling
/// summary, so deletions schedule a from-scratch recompute instead (§14).
enum JobType {
  transcribe,
  summarizeMemo,
  updateCassetteSummary,
  recomputeCassetteSummary;

  bool get targetsMemo => this == transcribe || this == summarizeMemo;
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
  /// affordance): no transcript yet → transcribe again; transcript already
  /// there → only the summarization is redone.
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

  /// Cancels pending *and in-flight* work for a deleted memo (§14).
  Future<void> cancelJobsFor(String targetId) async {
    _active[targetId]?.cancel();
    await (_db.delete(_db.jobs)
          ..where(
              (j) => j.targetId.equals(targetId) & j.status.equals('queued')))
        .go();
  }

  /// Call after a memo's row is gone: if its gist was part of the cassette
  /// summary, schedule the from-scratch recompute (§14 "cassette summary is
  /// scheduled to update").
  Future<void> onMemoDeleted(Memo memo) async {
    if (memo.memoSummary == null) return;
    await _enqueueCassetteUpdate(memo.cassetteId, recompute: true);
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
      final runnable = <String>[];
      if (await _transcription().modelStatus() == ModelStatus.ready) {
        runnable.add(JobType.transcribe.name);
      }
      if ((await _settings.get()).summariesEnabled &&
          await _summarization().modelStatus() == ModelStatus.ready) {
        runnable.addAll([
          JobType.summarizeMemo.name,
          JobType.updateCassetteSummary.name,
          JobType.recomputeCassetteSummary.name,
        ]);
      }
      if (runnable.isEmpty) return;

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
        case JobType.summarizeMemo:
          await _summarizeMemo(job.targetId);
        case JobType.updateCassetteSummary:
          await _updateCassetteSummary(job.targetId, recompute: false);
        case JobType.recomputeCassetteSummary:
          await _updateCassetteSummary(job.targetId, recompute: true);
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
        // The gist job waits in the queue while summaries are disabled or
        // the model is missing — the drain gate holds it, never the memo.
        await _insertJob(JobType.summarizeMemo, memoId);
      }

      // D8: no app language yet → adopt the first real detection globally.
      // Silent memos don't count — their "detection" is noise.
      if (settings.appLanguage == null &&
          !transcript.isEmpty &&
          transcript.languageCode.isNotEmpty &&
          transcript.languageCode != 'auto') {
        await _settings.setAppLanguage(transcript.languageCode);
      }
    } finally {
      _active.remove(memoId);
    }
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

  Future<void> _updateCassetteSummary(String cassetteId,
      {required bool recompute}) async {
    final cassette = await (_db.select(_db.cassettes)
          ..where((c) => c.id.equals(cassetteId)))
        .getSingleOrNull();
    if (cassette == null) return; // deleted meanwhile (§14)

    // Digests in tape order; incremental folds only what's new (§6.7).
    var rows = await (_db.select(_db.memos)
          ..where((m) =>
              m.cassetteId.equals(cassetteId) & m.memoSummary.isNotNull())
          ..orderBy([
            (m) => OrderingTerm.asc(m.createdAt),
            (m) => OrderingTerm.asc(m.id),
          ]))
        .get();
    if (!recompute) {
      rows = rows.where((r) => r.foldedAt == null).toList();
    }
    if (rows.isEmpty) {
      if (recompute) {
        // The last summarized memo was deleted — the overview no longer
        // describes anything; the (possibly user-set) label stays.
        await _cassettes.setSummary(cassetteId, null);
      }
      return;
    }

    final language = await _languageFor(rows.first.detectedLang);
    final summary = (await _summarization().updateCassetteSummary(
      previousSummary: recompute ? null : cassette.summary,
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
    await _memos.markFolded(
        [for (final row in rows) row.id], DateTime.now());

    // D10: suggest until the user renames; best-effort — a lost suggestion
    // just waits for the next summary update.
    if (!cassette.titleIsUserSet) {
      final title = await _summarization()
          .suggestTitle(summary, languageCode: language);
      if (title.trim().isNotEmpty) {
        await _cassettes.setSuggestedLabel(cassetteId, title.trim());
      }
    }
  }

  /// One app-wide language (D8), with the memo's own detection as fallback
  /// while the global setting is still unset.
  Future<String> _languageFor(String? detectedLang) async =>
      (await _settings.get()).appLanguage ?? detectedLang ?? 'en';

  /// Coalescing (§6.5 debounce): a queued cassette job already covers any
  /// digests that land before it runs, so bursts collapse into one update.
  /// A recompute supersedes queued incremental updates, never vice versa.
  Future<void> _enqueueCassetteUpdate(String cassetteId,
      {bool recompute = false}) async {
    final queued = await (_db.select(_db.jobs)
          ..where((j) =>
              j.targetId.equals(cassetteId) &
              j.status.equals('queued') &
              j.type.isIn([
                JobType.updateCassetteSummary.name,
                JobType.recomputeCassetteSummary.name,
              ])))
        .get();
    if (!recompute) {
      if (queued.isNotEmpty) return;
      await _insertJob(JobType.updateCassetteSummary, cassetteId);
      return;
    }
    if (queued.any((j) => j.type == JobType.recomputeCassetteSummary.name)) {
      return;
    }
    await (_db.delete(_db.jobs)
          ..where((j) =>
              j.targetId.equals(cassetteId) &
              j.status.equals('queued') &
              j.type.equals(JobType.updateCassetteSummary.name)))
        .go();
    await _insertJob(JobType.recomputeCassetteSummary, cassetteId);
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
