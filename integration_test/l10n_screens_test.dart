/// Locale render check for the expansion-wave languages: boots the real app
/// with the platform locale forced to tr/ru/ko and screenshots home +
/// Settings. Proves the ARB loads (a known translated string is on screen)
/// and — on a desktop with real fonts — that Cyrillic/Hangul resolve through
/// the `fontFamilyFallback` chain instead of tofu.
///
///   DIKTAFON_TEST_DIR=/tmp/dk_l10n \
///   flutter test integration_test/l10n_screens_test.dart -d linux
///
/// Shots land in $DIKTAFON_TEST_DIR/shots/.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:diktafon/app.dart';
import 'package:diktafon/application/providers.dart';
import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/files/audio_file_store.dart';
import 'package:diktafon/services/providers/llm/llm_model_manager.dart';
import 'package:diktafon/services/providers/whisper/whisper_model_manager.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

final _boundaryKey = GlobalKey();
late Directory _workDir;

Future<void> _settle(WidgetTester tester, {int frames = 20}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  await _settle(tester, frames: 5);
  final dir = Directory('${_workDir.path}/shots')..createSync(recursive: true);
  final boundary =
      _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (Platform.isLinux) {
      JustAudioMediaKit.ensureInitialized(
        linux: true,
        windows: false,
        libmpv: Platform.environment['LIBMPV_PATH'],
      );
    }
    final base = Platform.environment['DIKTAFON_TEST_DIR'];
    if (base != null) {
      _workDir = Directory(base);
      if (_workDir.existsSync()) _workDir.deleteSync(recursive: true);
      _workDir.createSync(recursive: true);
    } else {
      _workDir = Directory.systemTemp.createTempSync('diktafon_l10n_');
    }
  });

  // (locale code, Settings app-bar title from that ARB).
  for (final (code, settingsTitle) in [
    ('tr', 'AYARLAR'),
    ('ru', 'НАСТРОЙКИ'),
    ('ko', '설정'),
  ]) {
    testWidgets('the app renders localized in $code', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.localesTestValue = [Locale(code)];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      final dir = Directory('${_workDir.path}/$code')
        ..createSync(recursive: true);
      final db = AppDatabase.forTesting(
          NativeDatabase(File('${dir.path}/diktafon.db')));
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioFileStoreProvider.overrideWithValue(
            AudioFileStore(Directory('${dir.path}/audio')..createSync())),
        whisperModelManagerProvider.overrideWithValue(WhisperModelManager(
            Directory('${dir.path}/whisper')..createSync())),
        llmModelManagerProvider.overrideWithValue(
            LlmModelManager(Directory('${dir.path}/llm')..createSync())),
      ]);
      addTearDown(container.dispose);
      await db
          .into(db.settingsEntries)
          .insert(const SettingRow(key: 'firstRunDone', value: '1'));

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(key: _boundaryKey, child: const DiktafonApp()),
      ));
      await _settle(tester);
      await _shot(tester, 'l10n-$code-home');

      await tester.tap(find.byType(IconButton).last); // Settings gear
      await _settle(tester);
      expect(find.text(settingsTitle), findsOneWidget,
          reason: 'the $code ARB must be the one on screen');
      await _shot(tester, 'l10n-$code-settings');
    }, timeout: const Timeout(Duration(minutes: 2)));
  }
}
