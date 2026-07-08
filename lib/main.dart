import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'application/providers.dart';
import 'data/files/audio_file_store.dart';
import 'services/providers/llm/llm_model_manager.dart';
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

  // Resume any jobs persisted before the last shutdown (§6.5 durability).
  Future<void>.microtask(() => container.read(jobQueueProvider).drain());

  runApp(UncontrolledProviderScope(
    container: container,
    child: const DiktafonApp(),
  ));
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
