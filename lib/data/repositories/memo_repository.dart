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

  /// [summary] null → the memo yielded no usable gist (§6.7 skip).
  Future<void> setMemoSummary(String id, String? summary, MemoStatus status) =>
      (_db.update(_db.memos)..where((m) => m.id.equals(id))).write(
        MemosCompanion(
          memoSummary: Value(summary),
          status: Value(status.name),
        ),
      );

  /// Marks memos whose gists are now part of the cassette summary (§6.7).
  Future<void> markFolded(List<String> ids, DateTime at) =>
      (_db.update(_db.memos)..where((m) => m.id.isIn(ids))).write(
          MemosCompanion(foldedAt: Value(at.millisecondsSinceEpoch)));

  Future<void> delete(String id) =>
      (_db.delete(_db.memos)..where((m) => m.id.equals(id))).go();
}
