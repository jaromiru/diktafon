import '../db/database.dart';

/// Typed view over the key-value settings rows (§7.2 defaults).
class AppSettings {
  const AppSettings({
    this.appLanguage,
    this.chimeEnabled = true,
    this.whisperTier = 'small',
    this.llmTier = 'qwen3-1.7b',
    this.summariesEnabled = true,
    this.theme = 'system',
    this.firstRunDone = false,
  });

  /// Null → auto-detect per memo (D8), so one tape may mix languages; set →
  /// a forced override for speakers whisper keeps mis-detecting.
  final String? appLanguage;
  final bool chimeEnabled;
  final String whisperTier;
  final String llmTier;
  final bool summariesEnabled;

  /// 'system' | 'light' | 'dark'.
  final String theme;

  /// The first-run setup (§5.6) has been walked through (or skipped).
  final bool firstRunDone;

  static AppSettings fromRows(Map<String, String> rows) => AppSettings(
        appLanguage: rows['appLanguage'],
        chimeEnabled: rows['chimeEnabled'] != '0',
        whisperTier: rows['whisperTier'] ?? 'small',
        llmTier: rows['llmTier'] ?? 'qwen3-1.7b',
        summariesEnabled: rows['summariesEnabled'] != '0',
        // A `transcriptCleanup` row may linger from pre-removal builds
        // (§6.8 retired 2026-07-13); it is simply ignored.
        theme: rows['theme'] ?? 'system',
        firstRunDone: rows['firstRunDone'] == '1',
      );
}

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Stream<AppSettings> watch() =>
      _db.select(_db.settingsEntries).watch().map((rows) => AppSettings.fromRows(
          {for (final row in rows) row.key: row.value}));

  /// One-shot read for non-UI consumers (e.g. the job queue at job time).
  Future<AppSettings> get() async {
    final rows = await _db.select(_db.settingsEntries).get();
    return AppSettings.fromRows({for (final row in rows) row.key: row.value});
  }

  Future<void> _set(String key, String? value) async {
    if (value == null) {
      await (_db.delete(_db.settingsEntries)..where((s) => s.key.equals(key)))
          .go();
    } else {
      await _db
          .into(_db.settingsEntries)
          .insertOnConflictUpdate(SettingRow(key: key, value: value));
    }
  }

  Future<void> setAppLanguage(String? code) => _set('appLanguage', code);
  Future<void> setChimeEnabled(bool on) => _set('chimeEnabled', on ? '1' : '0');
  Future<void> setWhisperTier(String tier) => _set('whisperTier', tier);
  Future<void> setLlmTier(String tier) => _set('llmTier', tier);
  Future<void> setSummariesEnabled(bool on) =>
      _set('summariesEnabled', on ? '1' : '0');
  Future<void> setTheme(String theme) => _set('theme', theme);
  Future<void> setFirstRunDone() => _set('firstRunDone', '1');
}
