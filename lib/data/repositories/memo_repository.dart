import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../db/database.dart';
import 'mappers.dart';

class MemoRepository {
  MemoRepository(this._db);

  final AppDatabase _db;

  /// Tape order: chronological, append-only (§4.1, D6).
  Stream<List<Memo>> watchMemosOf(String cassetteId) =>
      _memosOfQuery(cassetteId)
          .watch()
          .map((rows) => rows.map(memoFromRow).toList());

  /// One-shot tape-order read (export, §8).
  Future<List<Memo>> memosOf(String cassetteId) async =>
      (await _memosOfQuery(cassetteId).get()).map(memoFromRow).toList();

  SimpleSelectStatement<$MemosTable, MemoRow> _memosOfQuery(
          String cassetteId) =>
      _db.select(_db.memos)
        ..where((m) => m.cassetteId.equals(cassetteId))
        // id as tie-break keeps tape order deterministic within the same ms.
        ..orderBy([
          (m) => OrderingTerm.asc(m.createdAt),
          (m) => OrderingTerm.asc(m.id),
        ]);

  Future<void> insert(Memo memo) => _db.into(_db.memos).insert(MemoRow(
        id: memo.id,
        cassetteId: memo.cassetteId,
        filePath: memo.filePath,
        durationMs: memo.durationMs,
        createdAt: memo.createdAt.millisecondsSinceEpoch,
        detectedLang: memo.detectedLang,
        transcript: memo.transcript == null
            ? null
            : jsonEncode(memo.transcript!.toJson()),
        memoSummary: memo.memoSummary,
        status: memo.status.name,
      ));

  Future<void> updateStatus(String id, MemoStatus status) =>
      (_db.update(_db.memos)..where((m) => m.id.equals(id)))
          .write(MemosCompanion(status: Value(status.name)));

  Future<void> setTranscript(
    String id,
    Transcript transcript,
    MemoStatus status,
  ) =>
      (_db.update(_db.memos)..where((m) => m.id.equals(id))).write(
        MemosCompanion(
          transcript: Value(jsonEncode(transcript.toJson())),
          detectedLang: Value(transcript.languageCode),
          status: Value(status.name),
        ),
      );

  /// Swaps in the cleaned-up transcript (§6.8), preserving the engine's
  /// original take in rawTranscript — cleanup re-estimates word timings, so
  /// the raw one must stay recoverable. detectedLang is already set and
  /// cleanup never changes the language.
  Future<void> setCleanedTranscript(
    String id,
    Transcript cleaned,
    String rawTranscriptJson,
  ) =>
      (_db.update(_db.memos)..where((m) => m.id.equals(id))).write(
        MemosCompanion(
          transcript: Value(jsonEncode(cleaned.toJson())),
          rawTranscript: Value(rawTranscriptJson),
        ),
      );

  /// [summary] null → the memo yielded no usable gist (§6.7 skip).
  Future<void> setMemoSummary(String id, String? summary, MemoStatus status) =>
      (_db.update(_db.memos)..where((m) => m.id.equals(id))).write(
        MemosCompanion(
          memoSummary: Value(summary),
          status: Value(status.name),
        ),
      );

  /// Wipes every enrichment artifact so the memo re-enters the pipeline
  /// from scratch (re-transcribe with a newly installed model): transcript,
  /// preserved raw take, gist and detected language all go; audio stays.
  Future<void> resetEnrichment(String id) =>
      (_db.update(_db.memos)..where((m) => m.id.equals(id))).write(
        MemosCompanion(
          transcript: const Value(null),
          rawTranscript: const Value(null),
          memoSummary: const Value(null),
          detectedLang: const Value(null),
          status: Value(MemoStatus.stored.name),
        ),
      );

  Future<void> delete(String id) =>
      (_db.delete(_db.memos)..where((m) => m.id.equals(id))).go();
}
