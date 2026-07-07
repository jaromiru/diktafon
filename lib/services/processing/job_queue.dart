import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/database.dart';
import '../../data/repositories/memo_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models.dart';
import '../providers/transcription_provider.dart';

enum JobType { transcribe, summarizeMemo, updateCassetteSummary }

/// Durable background pipeline (§6.5): jobs persist in the DB so they survive
/// restarts; ML concurrency is 1 to bound CPU/thermals/battery.
///
/// The provider is resolved through a getter on every use so a Settings tier
/// switch takes effect without rebuilding the queue (rebuilding could let two
/// queues drain the same jobs).
class JobQueue {
  JobQueue(this._db, this._memos, this._settings, this._transcription,
      {this._retryDelayUnit = const Duration(seconds: 1)});

  final AppDatabase _db;
  final MemoRepository _memos;
  final SettingsRepository _settings;
  final TranscriptionProvider Function() _transcription;

  /// Backoff = attempts × this; tests inject zero.
  final Duration _retryDelayUnit;
  final _uuid = const Uuid();

  /// In-flight cancellation handles, by memo id (§14 delete-during-processing).
  final Map<String, CancelToken> _active = {};

  Future<void>? _draining;
  static const _maxAttempts = 5;

  /// Enqueued on record-stop (D7).
  Future<void> enqueueTranscription(String memoId) async {
    await _db.into(_db.jobs).insert(JobRow(
          id: _uuid.v4(),
          type: JobType.transcribe.name,
          targetId: memoId,
          status: 'queued',
          attempts: 0,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
    unawaited(drain());
  }

  /// Failed memo → back on the queue (§14 retry affordance).
  Future<void> retryTranscription(String memoId) async {
    await _memos.updateStatus(memoId, MemoStatus.stored);
    await enqueueTranscription(memoId);
  }

  /// Cancels pending *and in-flight* work for a deleted memo (§14).
  Future<void> cancelJobsFor(String targetId) async {
    _active[targetId]?.cancel();
    await (_db.delete(_db.jobs)
          ..where(
              (j) => j.targetId.equals(targetId) & j.status.equals('queued')))
        .go();
  }

  /// Processes queued jobs sequentially. Called on app start (resume after
  /// restart), after every enqueue, and when a model finishes downloading.
  /// Awaiting joins the drain already in flight, if any.
  Future<void> drain() => _draining ??=
      _drainLoop().whenComplete(() => _draining = null);

  Future<void> _drainLoop() async {
    while (true) {
      // Enrichment waits for a provisioned model; jobs stay queued (§14).
      // Re-checked every iteration — the model can change mid-drain.
      if (await _transcription().modelStatus() != ModelStatus.ready) return;

      final job = await (_db.select(_db.jobs)
            ..where((j) => j.status.equals('queued'))
            ..orderBy([(j) => OrderingTerm.asc(j.createdAt)])
            ..limit(1))
          .getSingleOrNull();
      if (job == null) return;
      await _run(job);
    }
  }

  Future<void> _run(JobRow job) async {
    await _setJob(job.id, 'running', attempts: job.attempts + 1);
    try {
      switch (JobType.values.byName(job.type)) {
        case JobType.transcribe:
          await _transcribe(job.targetId);
        case JobType.summarizeMemo:
        case JobType.updateCassetteSummary:
          // M3 wires the summarization provider in.
          break;
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
        // Memo stays playable; a retry affordance is offered (§14).
        await _memos.updateStatus(job.targetId, MemoStatus.failed);
      } else {
        // Brief backoff so transient failures don't hot-loop (§6.5).
        await Future<void>.delayed(_retryDelayUnit * attempts);
      }
    }
  }

  Future<void> _transcribe(String memoId) async {
    final row = await (_db.select(_db.memos)
          ..where((m) => m.id.equals(memoId)))
        .getSingleOrNull();
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
      await _memos.setTranscript(memoId, transcript, MemoStatus.transcribed);

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

  Future<void> _setJob(String id, String status, {int? attempts}) =>
      (_db.update(_db.jobs)..where((j) => j.id.equals(id))).write(JobsCompanion(
        status: Value(status),
        attempts: attempts == null ? const Value.absent() : Value(attempts),
      ));
}
