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
  final whisperModels =
      WhisperModelManager(Directory('${supportDir.path}/models/whisper'));
  final llmModels =
      LlmModelManager(Directory('${supportDir.path}/models/llm'));
  final container = ProviderContainer(overrides: [
    audioFileStoreProvider.overrideWithValue(fileStore),
    whisperModelManagerProvider.overrideWithValue(whisperModels),
    llmModelManagerProvider.overrideWithValue(llmModels),
    chimeFileProvider.overrideWithValue(
        await _materializeChime(supportDir.path)),
  ]);

  // Model downloads mirror into the notification area while they run.
  _attachDownloadNotifications(whisperModels, llmModels);

  // Resume any jobs persisted before the last shutdown (§6.5 durability).
  Future<void>.microtask(() => container.read(jobQueueProvider).drain());

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

/// just_audio's media_kit backend plays files, not bundle assets — copy the
/// chime out of the bundle once. Null (asset missing) → no chime, D5's "off"
/// behavior, rather than a startup failure.
Future<String?> _materializeChime(String supportDir) async {
  try {
    final file = File('$supportDir/chime.wav');
    if (!await file.exists()) {
      final data = await rootBundle.load('assets/audio/chime.wav');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return file.path;
  } catch (_) {
    return null;
  }
}
