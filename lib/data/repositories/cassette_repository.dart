import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart';
import '../db/database.dart';
import 'mappers.dart';

/// A cassette plus the aggregates the home grid needs (§5.2): memo count for
/// the label, total recorded time for the growing left reel.
class CassetteOverview {
  const CassetteOverview({
    required this.cassette,
    required this.memoCount,
    required this.totalDurationMs,
  });

  final Cassette cassette;
  final int memoCount;
  final int totalDurationMs;
}

class CassetteRepository {
  CassetteRepository(this._db, {Random? random})
      : _random = random ?? Random();

  final AppDatabase _db;
  final Random _random;
  final _uuid = const Uuid();

  /// Home grid: most-recently-updated first (§5.2).
  Stream<List<CassetteOverview>> watchOverviews() {
    final count = _db.memos.id.count();
    final total = _db.memos.durationMs.sum();
    final query = _db.select(_db.cassettes).join([
      leftOuterJoin(_db.memos, _db.memos.cassetteId.equalsExp(_db.cassettes.id)),
    ])
      ..addColumns([count, total])
      ..groupBy([_db.cassettes.id])
      ..orderBy([
        OrderingTerm.desc(_db.cassettes.updatedAt),
        OrderingTerm.desc(_db.cassettes.createdAt),
      ]);
    return query.watch().map((rows) => rows
        .map((row) => CassetteOverview(
              cassette: cassetteFromRow(row.readTable(_db.cassettes)),
              memoCount: row.read(count) ?? 0,
              totalDurationMs: row.read(total) ?? 0,
            ))
        .toList());
  }

  Stream<Cassette?> watchCassette(String id) {
    final query = _db.select(_db.cassettes)..where((c) => c.id.equals(id));
    return query.watchSingleOrNull().map(
        (row) => row == null ? null : cassetteFromRow(row));
  }

  /// New cassettes open immediately with a placeholder label (§5.2, D10).
  Future<Cassette> create() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = CassetteRow(
      id: _uuid.v4(),
      label: null,
      titleIsUserSet: false,
      colorSeed: _random.nextInt(1 << 16),
      summary: null,
      summaryUpdatedAt: null,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.cassettes).insert(row);
    return cassetteFromRow(row);
  }

  /// Rolling summary refresh (§6.7); null clears it (tape emptied out).
  Future<void> setSummary(String id, String? summary) =>
      (_db.update(_db.cassettes)..where((c) => c.id.equals(id))).write(
        CassettesCompanion(
          summary: Value(summary),
          summaryUpdatedAt: Value(
              summary == null ? null : DateTime.now().millisecondsSinceEpoch),
        ),
      );

  /// Auto-suggested title (D10 revised): only ever fills a *blank* label —
  /// the WHERE guard also keeps a rename that lands mid-suggestion safe.
  Future<void> setSuggestedLabel(String id, String label) =>
      (_db.update(_db.cassettes)
            ..where((c) =>
                c.id.equals(id) &
                c.titleIsUserSet.equals(false) &
                c.label.isNull()))
          .write(CassettesCompanion(label: Value(label)));

  /// User rename: sets the D10 override flag so auto-suggestions stop.
  Future<void> rename(String id, String label) =>
      (_db.update(_db.cassettes)..where((c) => c.id.equals(id))).write(
        CassettesCompanion(
          label: Value(label.trim().isEmpty ? null : label.trim()),
          titleIsUserSet: Value(label.trim().isNotEmpty),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

  /// User-picked cassette color: the seed is stored so `cassetteHueIndex`
  /// lands exactly on the chosen hue; the memo palette rotates with it
  /// (§10.2). Cosmetic — recency is deliberately not bumped.
  Future<void> setColorSeed(String id, int seed) =>
      (_db.update(_db.cassettes)..where((c) => c.id.equals(id)))
          .write(CassettesCompanion(colorSeed: Value(seed)));

  /// Bumps recency so the cassette floats to the top of the grid (§5.2).
  Future<void> touch(String id) =>
      (_db.update(_db.cassettes)..where((c) => c.id.equals(id))).write(
        CassettesCompanion(updatedAt: Value(DateTime.now().millisecondsSinceEpoch)),
      );

  /// Memos cascade-delete via foreign key; audio files are the caller's
  /// responsibility (see AudioFileStore.deleteCassetteDir).
  Future<void> delete(String id) =>
      (_db.delete(_db.cassettes)..where((c) => c.id.equals(id))).go();
}
