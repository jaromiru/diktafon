/// M1 end-to-end flow on a real device/desktop: create a cassette, record a
/// real memo through the microphone, play it back over the global timeline,
/// and capture screenshots for design review against docs/ui-mockups.html.
///
/// Storage is isolated: DB + audio live under DIKTAFON_TEST_DIR (or a temp
/// dir), never in the user's real app data.
///
/// Run: flutter test integration_test -d linux
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:diktafon/app.dart';
import 'package:diktafon/application/providers.dart';
import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/files/audio_file_store.dart';
import 'package:diktafon/presentation/widgets/cassette_card.dart';
import 'package:diktafon/presentation/widgets/deck.dart';
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

Directory get _shotDir {
  final dir = Directory('${_workDir.path}/shots');
  dir.createSync(recursive: true);
  return dir;
}

Future<void> _shot(WidgetTester tester, String name) async {
  await _settle(tester);
  final boundary = _boundaryKey.currentContext!.findRenderObject()
      as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('${_shotDir.path}/$name.png')
      .writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// pumpAndSettle never settles while looping animations (shimmer, rec pulse)
/// run — pump a bounded number of frames instead.
Future<void> _settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Finder _key(DeckGlyph glyph) =>
    find.byWidgetPredicate((w) => w is DeckKey && w.glyph == glyph);

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
      // Deterministic start: wipe state left by earlier runs.
      if (_workDir.existsSync()) _workDir.deleteSync(recursive: true);
      _workDir.createSync(recursive: true);
    } else {
      _workDir = Directory.systemTemp.createTempSync('diktafon_m1_');
    }
  });

  testWidgets('M1: create cassette → record → play back → settings',
      (tester) async {
    final db = AppDatabase.forTesting(
        NativeDatabase(File('${_workDir.path}/diktafon.db')));
    final audioDir = Directory('${_workDir.path}/audio')
      ..createSync(recursive: true);
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      audioFileStoreProvider.overrideWithValue(AudioFileStore(audioDir)),
      // No models installed — this flow exercises the pre-provisioning UX.
      whisperModelManagerProvider.overrideWithValue(WhisperModelManager(
          Directory('${_workDir.path}/models/whisper')..createSync(recursive: true))),
      llmModelManagerProvider.overrideWithValue(LlmModelManager(
          Directory('${_workDir.path}/models/llm')..createSync(recursive: true))),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(key: _boundaryKey, child: const DiktafonApp()),
    ));
    await _settle(tester);

    // — Home, empty state —
    expect(find.text('DIKTAFON'), findsOneWidget);
    expect(find.textContaining('No cassettes yet'), findsOneWidget);
    await _shot(tester, '01-home-empty');

    // — New cassette opens immediately with a placeholder (§5.2) —
    await tester.tap(_key(DeckGlyph.plus));
    await _settle(tester);
    expect(find.text('Untitled cassette'), findsOneWidget);
    expect(find.text('EMPTY TAPE'), findsOneWidget);
    await _shot(tester, '02-cassette-empty');

    // — Record a real memo (~4 s through the actual microphone) —
    await tester.tap(_key(DeckGlyph.record));
    await _settle(tester);
    expect(find.textContaining('RECORDING MEMO 1'), findsOneWidget);
    await Future<void>.delayed(const Duration(seconds: 4));
    await _settle(tester, frames: 4);
    await _shot(tester, '03-recording');

    await tester.tap(_key(DeckGlyph.stop));
    // Encoder finalization + duration probe + stream propagation.
    await Future<void>.delayed(const Duration(seconds: 2));
    await _settle(tester);
    expect(find.text('MEMO 1 / 1'), findsOneWidget);
    expect(find.textContaining('waiting for the transcription model'),
        findsOneWidget);
    await _shot(tester, '04-cassette-one-memo');

    final tapeAfterRecording =
        container.read(tapePlayerProvider).tape;
    expect(tapeAfterRecording.memoCount, 1);
    expect(tapeAfterRecording.totalDurationMs, greaterThan(2000),
        reason: 'recorded ~4s of audio; duration must be probed from file');

    // — Play back over the global timeline —
    await tester.tap(_key(DeckGlyph.play));
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await _settle(tester, frames: 4);
    final playback = container.read(tapePlayerProvider).state;
    expect(playback.playing, isTrue);
    expect(playback.globalMs, greaterThan(0),
        reason: 'the playhead must advance during playback');
    await _shot(tester, '05-playing');
    await tester.tap(_key(DeckGlyph.pause));
    await _settle(tester);

    // — Back home: the cassette card shows 1 memo —
    // (label & meta are painted with TextPainter, invisible to text finders)
    await tester.tap(find.byTooltip('Back'));
    await _settle(tester);
    final card = tester.widget<CassetteCard>(find.byType(CassetteCard));
    expect(card.overview.memoCount, 1);
    expect(card.overview.cassette.label, isNull,
        reason: 'label stays a placeholder until summarization names it');
    await _shot(tester, '06-home-one-cassette');

    // — Settings, light and dark —
    await tester.tap(find.byTooltip('Settings'));
    await _settle(tester);
    expect(find.text('Boundary chime'), findsOneWidget);
    await _shot(tester, '07-settings');

    // Manual theme override (§5.5) — pick the mode opposite to the system's
    // dark default here so both palettes get exercised.
    await tester.tap(find.text('Theme'));
    await _settle(tester);
    await tester.tap(find.text('Light').last);
    await _settle(tester);
    await _shot(tester, '08-settings-light');

    await tester.tap(find.byTooltip('Back'));
    await _settle(tester);
    await _shot(tester, '09-home-light');
  });
}
