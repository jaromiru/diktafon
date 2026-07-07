import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'app.dart';
import 'application/providers.dart';
import 'data/files/audio_file_store.dart';

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
  final container = ProviderContainer(overrides: [
    audioFileStoreProvider.overrideWithValue(fileStore),
  ]);

  // Resume any jobs persisted before the last shutdown (§6.5 durability).
  Future<void>.microtask(() => container.read(jobQueueProvider).drain());

  runApp(UncontrolledProviderScope(
    container: container,
    child: const DiktafonApp(),
  ));
}
