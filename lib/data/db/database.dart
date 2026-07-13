/// Drift schema (§7.2): metadata, transcripts and summaries in SQLite;
/// audio stays on disk as files (§7.1).
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DataClassName('CassetteRow')
class Cassettes extends Table {
  TextColumn get id => text()();
  TextColumn get label => text().nullable()();
  BoolColumn get titleIsUserSet =>
      boolean().withDefault(const Constant(false))();
  IntColumn get colorSeed => integer()();
  TextColumn get summary => text().nullable()();
  IntColumn get summaryUpdatedAt => integer().nullable()();  // epoch ms
  IntColumn get createdAt => integer()();  // epoch ms
  IntColumn get updatedAt => integer()();  // epoch ms

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MemoRow')
class Memos extends Table {
  TextColumn get id => text()();
  TextColumn get cassetteId =>
      text().references(Cassettes, #id, onDelete: KeyAction.cascade)();
  TextColumn get filePath => text()();
  IntColumn get durationMs => integer()();
  IntColumn get createdAt => integer()();  // epoch ms
  TextColumn get detectedLang => text().nullable()();

  /// Transcript stored as a JSON blob per memo (§7.2 — no search in v1).
  TextColumn get transcript => text().nullable()();

  /// Legacy LLM-cleanup bookkeeping (§6.8, retired 2026-07-13): the
  /// engine's original take from when cleanup rewrote [transcript]. No
  /// longer written — kept, like [foldedAt], so existing databases need no
  /// migration.
  TextColumn get rawTranscript => text().nullable()();
  TextColumn get memoSummary => text().nullable()();

  /// Legacy M3 fold bookkeeping — no longer written since the cassette
  /// summary is rebuilt from all gists (§6.7 revised 2026-07-08); kept so
  /// existing databases need no migration.
  IntColumn get foldedAt => integer().nullable()();  // epoch ms
  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Durable background jobs (§6.5) — survive app restart.
@DataClassName('JobRow')
class Jobs extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get targetId => text()();
  TextColumn get status => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();  // epoch ms

  @override
  Set<Column> get primaryKey => {id};
}

/// Key-value settings (single conceptual row, §7.2).
@DataClassName('SettingRow')
class SettingsEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Cassettes, Memos, Jobs, SettingsEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// In-memory database for tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // M3: cassette-summary fold bookkeeping.
            await m.addColumn(memos, memos.foldedAt);
          }
          if (from < 3) {
            // The retired transcript cleanup's raw-take column (§6.8).
            await m.addColumn(memos, memos.rawTranscript);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() {
    // §7.1: user data lives in app-documents so the OS backup captures it.
    return driftDatabase(
      name: 'diktafon',
      native: DriftNativeOptions(
        databaseDirectory: getApplicationDocumentsDirectory,
      ),
    );
  }
}
