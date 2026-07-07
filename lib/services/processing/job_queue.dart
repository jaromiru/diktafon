import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/database.dart';
import '../../data/repositories/memo_repository.dart';
import '../../domain/models.dart';
import '../providers/transcription_provider.dart';

enum JobType { transcribe, summarizeMemo, updateCassetteSummary }

/// Durable background pipeline (§6.5): jobs persist in the DB so they survive
/// restarts; ML concurrency is 1 to bound CPU/thermals/battery.
///
/// M1 ships the queue with a not-installed transcription provider, so jobs
/// simply stay `queued` until M2 provisions a real engine (§14: "enrichment
/// begins once the model is provisioned") — capture is never blocked.
class JobQueue {
  JobQueue(this._db, this._memos, this._transcription);

  final AppDatabase _db;
  final MemoRepository _memos;
  final TranscriptionProvider _transcription;
  final _uuid = const Uuid();

  bool _draining = false;
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

  /// Cancels pending work for a deleted memo (§14).
  Future<void> cancelJobsFor(String targetId) => (_db.delete(_db.jobs)
        ..where((j) => j.targetId.equals(targetId) & j.status.equals('queued')))
      .go();

  /// Processes queued jobs sequentially. Call on app start (resume after
  /// restart) and after every enqueue.
  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      // Enrichment waits for a provisioned model; jobs stay queued (§14).
      if (await _transcription.modelStatus() != ModelStatus.ready) return;

      while (true) {
        final job = await (_db.select(_db.jobs)
              ..where((j) => j.status.equals('queued'))
              ..orderBy([(j) => OrderingTerm.asc(j.createdAt)])
              ..limit(1))
            .getSingleOrNull();
        if (job == null) return;
        await _run(job);
      }
    } finally {
      _draining = false;
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
    } catch (_) {
      final permanent = job.attempts + 1 >= _maxAttempts;
      await _setJob(job.id, permanent ? 'failed' : 'queued',
          attempts: job.attempts + 1);
      if (permanent) {
        // Memo stays playable; a retry affordance is offered (§14).
        await _memos.updateStatus(job.targetId, MemoStatus.failed);
      }
    }
  }

  Future<void> _transcribe(String memoId) async {
    final row = await (_db.select(_db.memos)
          ..where((m) => m.id.equals(memoId)))
        .getSingleOrNull();
    if (row == null) return; // deleted meanwhile (§14)
    await _memos.updateStatus(memoId, MemoStatus.transcribing);
    final transcript = await _transcription.transcribe(AudioRef(row.filePath));
    await _memos.setTranscript(memoId, transcript, MemoStatus.transcribed);
  }

  Future<void> _setJob(String id, String status, {int? attempts}) =>
      (_db.update(_db.jobs)..where((j) => j.id.equals(id))).write(JobsCompanion(
        status: Value(status),
        attempts: attempts == null ? const Value.absent() : Value(attempts),
      ));
}
