import 'dart:io';

import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../db/database.dart';
import 'mappers.dart';

class MemoRepository {
  MemoRepository(this._db);

  final AppDatabase _db;

  /// Tape order: chronological, append-only (§4.1, D6). Transcript JSON
  /// decodes pooled — a cassette of long memos froze frames for hundreds of
  /// ms on phones when parsed on the UI isolate per watch emission.
  Stream<List<Memo>> watchMemosOf(String cassetteId) => _memosOfQuery(
      cassetteId).watch().asyncMap((rows) => _memosFromRows(rows));

  /// One-shot tape-order read (export, §8).
  Future<List<Memo>> memosOf(String cassetteId) async =>
      _memosFromRows(await _memosOfQuery(cassetteId).get());

  Future<List<Memo>> _memosFromRows(List<MemoRow> rows) async {
    final transcripts = await transcriptsFromJsonAsync(
        [for (final row in rows) row.transcript]);
    return [
      for (var i = 0; i < rows.length; i++)
        memoFromRow(rows[i], transcript: transcripts[i]),
    ];
  }

  SimpleSelectStatement<$MemosTable, MemoRow> _memosOfQuery(
          String cassetteId) =>
      _db.select(_db.memos)
        ..where((m) => m.cassetteId.equals(cassetteId))
        // id as tie-break keeps tape order deterministic within the same ms.
        ..orderBy([
          (m) => OrderingTerm.asc(m.createdAt),
          (m) => OrderingTerm.asc(m.id),
        ]);

  Future<void> insert(Memo memo) async => _db.into(_db.memos).insert(MemoRow(
        id: memo.id,
        cassetteId: memo.cassetteId,
        filePath: memo.filePath,
        durationMs: memo.durationMs,
        createdAt: memo.createdAt.millisecondsSinceEpoch,
        detectedLang: memo.detectedLang,
        transcript: memo.transcript == null
            ? null
            : await transcriptToJsonAsync(memo.transcript!),
        memoSummary: memo.memoSummary,
        status: memo.status.name,
      ));

  /// Points the memo at its transcoded file (§6.4: capture is WAV, the
  /// archival form is AAC — the transcode job swaps once the encode landed).
  Future<void> updateFilePath(String id, String filePath) =>
      (_db.update(_db.memos)..where((m) => m.id.equals(id)))
          .write(MemosCompanion(filePath: Value(filePath)));

  Future<void> updateStatus(String id, MemoStatus status) =>
      (_db.update(_db.memos)..where((m) => m.id.equals(id)))
          .write(MemosCompanion(status: Value(status.name)));

  Future<void> setTranscript(
    String id,
    Transcript transcript,
    MemoStatus status,
  ) async =>
      (_db.update(_db.memos)..where((m) => m.id.equals(id))).write(
        MemosCompanion(
          transcript: Value(await transcriptToJsonAsync(transcript)),
          detectedLang: Value(transcript.languageCode),
          status: Value(status.name),
        ),
      );

  /// Manual correction (§6.9): the edited transcript replaces the engine's
  /// take, and the gist that described the old text goes with it — in one
  /// write. The detected language is deliberately untouched: the user fixed
  /// words, not the memo's language.
  Future<void> setEditedTranscript(
    String id,
    Transcript transcript,
    MemoStatus status,
  ) async =>
      (_db.update(_db.memos)..where((m) => m.id.equals(id))).write(
        MemosCompanion(
          transcript: Value(await transcriptToJsonAsync(transcript)),
          memoSummary: const Value(null),
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

  /// Every memo id — the launch sweep uses it to tell live audio files
  /// from orphans (§7.1).
  Future<Set<String>> allIds() async {
    final id = _db.memos.id;
    final rows = await (_db.selectOnly(_db.memos)..addColumns([id])).get();
    return {for (final row in rows) row.read(id)!};
  }

  /// Heals stale absolute audio paths (§7.1): iOS moves the app's data
  /// container on every update/reinstall — the audio files migrate with it,
  /// but paths recorded by an older install keep pointing into the dead
  /// container. A memo whose stored file is gone but whose audio sits at
  /// the canonical `<root>/<cassetteId>/<memoId>.<ext>` under the *current*
  /// root is repointed there. Idempotent, runs at every launch; genuinely
  /// missing audio is left alone.
  Future<int> rebaseAudioPaths(String audioRoot) async {
    final rows = await _db.select(_db.memos).get();
    var rebased = 0;
    for (final row in rows) {
      if (File(row.filePath).existsSync()) continue;
      final slash = row.filePath.lastIndexOf('/');
      final dot = row.filePath.lastIndexOf('.');
      final ext = dot > slash ? row.filePath.substring(dot) : '.m4a';
      final candidate = '$audioRoot/${row.cassetteId}/${row.id}$ext';
      if (candidate == row.filePath || !File(candidate).existsSync()) {
        continue;
      }
      await (_db.update(_db.memos)..where((m) => m.id.equals(row.id)))
          .write(MemosCompanion(filePath: Value(candidate)));
      rebased++;
    }
    return rebased;
  }
}
