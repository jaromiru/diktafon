/// M2 end-to-end flow on the real desktop app: with a provisioned whisper
/// model, a freshly recorded memo moves stored → transcribing (shimmer) →
/// transcribed, and the transcript region shows words or "(no speech)" —
/// never a stuck state (D7, §14).
///
/// Needs the tiny model on disk (headless mics record silence, so assertions
/// are about the *state machine*, not the words):
///   DIKTAFON_WHISPER_MODEL=…/ggml-tiny-q5_1.bin \
///   DIKTAFON_TEST_DIR=/tmp/dk_e2e \
///   flutter test integration_test/m2_transcription_test.dart -d linux
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:diktafon/app.dart';
import 'package:diktafon/application/providers.dart';
import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/files/audio_file_store.dart';
import 'package:diktafon/presentation/widgets/deck.dart';
import 'package:diktafon/services/providers/llm/llm_model_manager.dart';
import 'package:diktafon/services/providers/whisper/whisper_model_manager.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

final _boundaryKey = GlobalKey();
late Directory _workDir;

Future<void> _shot(WidgetTester tester, String name) async {
  await _settle(tester);
  final dir = Directory('${_workDir.path}/shots')..createSync(recursive: true);
  final boundary =
      _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// Bounded frame pumps — pumpAndSettle never settles while the shimmer loops.
Future<void> _settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Finder _key(DeckGlyph glyph) =>
    find.byWidgetPredicate((w) => w is DeckKey && w.glyph == glyph);

void main() {
  final modelPath = Platform.environment['DIKTAFON_WHISPER_MODEL'];

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
      _workDir = Directory.systemTemp.createTempSync('diktafon_m2_');
    }
  });

  testWidgets(
    'M2: record → transcribing shimmer → transcribed on the real engine',
    (tester) async {
      // Provision the model the way main() would find it, inside the
      // isolated work dir (§7.1 layout).
      final modelDir = Directory('${_workDir.path}/models/whisper')
        ..createSync(recursive: true);
      File(modelPath!)
          .copySync('${modelDir.path}/${WhisperModel.tiny.fileName}');

      final db = AppDatabase.forTesting(
          NativeDatabase(File('${_workDir.path}/diktafon.db')));
      final audioDir = Directory('${_workDir.path}/audio')
        ..createSync(recursive: true);
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioFileStoreProvider.overrideWithValue(AudioFileStore(audioDir)),
        whisperModelManagerProvider
            .overrideWithValue(WhisperModelManager(modelDir)),
        // No LLM installed: with a silent (headless-mic) memo the transcript
        // is empty and enrichment completes at 'ready' without it; a memo
        // with real words parks at 'transcribed' until the model lands.
        llmModelManagerProvider.overrideWithValue(LlmModelManager(
            Directory('${_workDir.path}/models/llm')
              ..createSync(recursive: true))),
      ]);
      addTearDown(container.dispose);

      // The unlisted test tier (§6.6) — user-facing default stays 'small'.
      await container.read(settingsRepositoryProvider).setWhisperTier('tiny');

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(key: _boundaryKey, child: const DiktafonApp()),
      ));
      await _settle(tester);

      // — Create a cassette, record ~4 s through the real microphone —
      await tester.tap(_key(DeckGlyph.plus));
      await _settle(tester);
      await tester.tap(_key(DeckGlyph.record));
      await _settle(tester);
      expect(find.textContaining('RECORDING MEMO 1'), findsOneWidget);
      await Future<void>.delayed(const Duration(seconds: 4));
      await _settle(tester, frames: 4);
      await tester.tap(_key(DeckGlyph.stop));
      await Future<void>.delayed(const Duration(seconds: 1));
      await _settle(tester);

      // — The memo must land in a terminal transcription state (D7): the
      //   tiny model on 4 s of audio takes a few seconds incl. model load.
      //   Silence (headless mic) → empty transcript → 'ready' (§6.7 summary
      //   skipped); real words → 'transcribed', gist parked (no LLM here) —
      MemoRow? memo;
      final deadline = DateTime.now().add(const Duration(seconds: 90));
      var sawTranscribing = false;
      const terminal = {'ready', 'transcribed', 'failed'};
      while (DateTime.now().isBefore(deadline)) {
        memo = await (db.select(db.memos)
              ..orderBy([(m) => drift.OrderingTerm.asc(m.createdAt)])
              ..limit(1))
            .getSingleOrNull();
        if (memo?.status == 'transcribing') {
          sawTranscribing = true;
          await _shot(tester, '10-transcribing-shimmer');
        }
        if (terminal.contains(memo?.status)) break;
        await _settle(tester, frames: 4);
      }

      expect(memo, isNotNull);
      expect(memo!.status, isIn(['ready', 'transcribed']),
          reason: 'memo must reach a good terminal state '
              '(sawTranscribing=$sawTranscribing, now=${memo.status})');
      await _settle(tester, frames: 8);

      // Headless mics record silence → "(no speech)"; a real voice → words.
      // Both are transcribed outcomes; a stuck caption/shimmer is a failure.
      expect(
        find.textContaining('waiting for the transcription model'),
        findsNothing,
      );
      await _shot(tester, '11-transcribed');

      // — Settings: the model row reports the installed tier (§5.5) —
      await tester.tap(find.byTooltip('Back'));
      await _settle(tester);
      await tester.tap(find.byTooltip('Settings'));
      await _settle(tester);
      expect(find.textContaining('installed'), findsWidgets);
      await _shot(tester, '12-settings-model-installed');
    },
    // Needs DIKTAFON_WHISPER_MODEL → path to a ggml-tiny-q5_1.bin.
    skip: modelPath == null,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
