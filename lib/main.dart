import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'application/providers.dart';
import 'data/files/audio_file_store.dart';
import 'l10n/gen/app_localizations.dart';
import 'services/notifications/download_notifier.dart';
import 'services/notifications/local_notifications_sink.dart';
import 'services/providers/llm/llm_model_manager.dart';
import 'services/providers/model_manager.dart';
import 'services/providers/whisper/whisper_model_manager.dart';
import 'services/system/system_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux) {
    // Desktop dev target: just_audio has no Linux backend of its own.
    // LIBMPV_PATH lets dev machines point at a locally extracted libmpv.
    JustAudioMediaKit.ensureInitialized(
      linux: true,
      windows: false,
      libmpv: Platform.environment['LIBMPV_PATH'],
    );
  }

  final fileStore = await AudioFileStore.open();
  // Models are regenerable → app-support, excluded from backup (§7.1).
  final supportDir = await getApplicationSupportDirectory();
  final modelsDir = Directory('${supportDir.path}/models')
    ..createSync(recursive: true);
  unawaited(excludeFromIosBackup(modelsDir.path));
  final whisperModels =
      WhisperModelManager(Directory('${modelsDir.path}/whisper'));
  final llmModels = LlmModelManager(Directory('${modelsDir.path}/llm'));
  final container = ProviderContainer(overrides: [
    audioFileStoreProvider.overrideWithValue(fileStore),
    whisperModelManagerProvider.overrideWithValue(whisperModels),
    llmModelManagerProvider.overrideWithValue(llmModels),
    chimeFileProvider.overrideWithValue(
        await _materializeAsset('assets/audio/chime.wav', supportDir.path)),
    vadModelFileProvider.overrideWithValue(await _materializeAsset(
        'assets/models/ggml-silero-v5.1.2.bin', modelsDir.path)),
  ]);

  // iOS moves the data container on app updates/reinstalls — repoint stored
  // audio paths at the current root before jobs or playback read them
  // (§7.1). Best-effort: a failure just leaves per-memo missing audio.
  try {
    await container
        .read(memoRepositoryProvider)
        .rebaseAudioPaths(fileStore.rootPath);
  } catch (_) {}

  // Launch hygiene, off the critical path: audio files no memo references
  // (a capture killed before its stop() ever inserted a row, §7.1) and
  // stale temp dirs stranded by a mid-job kill (decoded PCM, import/export
  // staging). Both age-gated — a job may legitimately be starting up.
  unawaited(() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 1));
      final ids = await container.read(memoRepositoryProvider).allIds();
      await fileStore.sweepOrphans(ids.contains, cutoff: cutoff);
      await _sweepStaleTempDirs(cutoff);
    } catch (_) {}
  }());

  // Model downloads mirror into the notification area while they run.
  _attachDownloadNotifications(whisperModels, llmModels);

  // Resume any jobs persisted before the last shutdown (§6.5 durability) —
  // once settings have actually loaded: the providers fall back to default
  // tiers until the settings stream's first emission, and a job resolved in
  // that cold-start window would silently transcribe with the wrong model.
  Future<void>.microtask(() async {
    try {
      await container.read(settingsProvider.future);
    } catch (_) {}
    await container.read(jobQueueProvider).drain();
  });

  // A force-close mid-download left a `.part` behind — put it back on the
  // wire without waiting for a tap (§6.6; user-paused `.paused` stashes stay
  // put). When a model lands, jobs parked on it get released.
  for (final models in <ModelManager<ModelSpec>>[whisperModels, llmModels]) {
    unawaited(models.resumeInterrupted().then((landed) async {
      if (landed) await container.read(jobQueueProvider).drain();
    }));
  }

  runApp(UncontrolledProviderScope(
    container: container,
    child: const DiktafonApp(),
  ));
}

/// Best-effort, off the critical startup path: no notification backend →
/// no notifier, downloads run exactly as before. Copy is localized through
/// the system locale (the UI follows it too, §13); the notifier lives for
/// the whole process, so it is never disposed.
Future<void> _attachDownloadNotifications(
  WhisperModelManager whisperModels,
  LlmModelManager llmModels,
) async {
  final sink = await LocalNotificationsSink.init();
  if (sink == null) return;
  AppLocalizations l10n;
  try {
    l10n = lookupAppLocalizations(ui.PlatformDispatcher.instance.locale);
  } catch (_) {
    l10n = lookupAppLocalizations(const Locale('en'));
  }
  ModelDownloadNotifier(
    sink,
    DownloadNotificationTexts(
      downloading: l10n.notifDownloading,
      installed: l10n.notifModelInstalled,
    ),
  )
    ..attach(whisperModels, idBase: 100)
    ..attach(llmModels, idBase: 200);
}

/// Neither just_audio's media_kit backend nor the native engines read
/// bundle assets — copy the asset out once (chime → app-support, Silero VAD
/// → the backup-excluded models dir). Null (asset missing) → the feature
/// quietly stays off rather than failing startup.
///
/// Write-then-rename plus a byte-length check: a process kill mid-write
/// (first launch is exactly when the OS is busiest) must not leave a
/// truncated copy that every later launch trusts — a short VAD model fails
/// natively on every small-tier transcription.
Future<String?> _materializeAsset(String assetKey, String dir) async {
  try {
    final file = File('$dir/${assetKey.split('/').last}');
    final data = await rootBundle.load(assetKey);
    if (await file.exists() && await file.length() == data.lengthInBytes) {
      return file.path;
    }
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(data.buffer.asUint8List(), flush: true);
    await tmp.rename(file.path);
    return file.path;
  } catch (_) {
    return null;
  }
}

/// Deletes stale `dk_pcm_*` / `diktafon_import_*` / `diktafon_export_*`
/// temp entries a killed process left behind. Age-gated by [cutoff]: /tmp
/// is shared on desktop and another instance may be mid-job.
Future<void> _sweepStaleTempDirs(DateTime cutoff) async {
  const prefixes = ['dk_pcm_', 'diktafon_import_', 'diktafon_export_'];
  await for (final entry in Directory.systemTemp.list()) {
    final name = entry.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    if (!prefixes.any(name.startsWith)) continue;
    try {
      if (entry.statSync().modified.isAfter(cutoff)) continue;
      entry.deleteSync(recursive: true);
    } catch (_) {
      // Best-effort hygiene.
    }
  }
}
