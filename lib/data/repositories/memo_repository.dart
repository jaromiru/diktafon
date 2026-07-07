import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../db/database.dart';
import 'mappers.dart';

class MemoRepository {
  MemoRepository(this._db);

  final AppDatabase _db;

  /// Tape order: chronological, append-only (§4.1, D6).
  Stream<List<Memo>> watchMemosOf(String cassetteId) {
    final query = _db.select(_db.memos)
      ..where((m) => m.cassetteId.equals(cassetteId))
      // id as tie-break keeps tape order deterministic within the same ms.
      ..orderBy([
        (m) => OrderingTerm.asc(m.createdAt),
        (m) => OrderingTerm.asc(m.id),
      ]);
    return query.watch().map((rows) => rows.map(memoFromRow).toList());
  }

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

  Future<void> delete(String id) =>
      (_db.delete(_db.memos)..where((m) => m.id.equals(id))).go();
}
