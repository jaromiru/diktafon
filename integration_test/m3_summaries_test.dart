/// M3 end-to-end flow on the real desktop app with the real LLM engine:
/// a memo restored in 'transcribed' state (its summarize job persisted, as
/// after an app restart — §6.5 durability) is enriched on launch: memo gist
/// → rolling cassette overview → auto-suggested title (D10), all visible in
/// the UI.
///
/// The transcript is pre-seeded because headless E2E mics record silence
/// (M2's test covers record → transcribe); this one covers everything after.
///
/// Needs the tiny Qwen3 model on disk (unlisted test tier, §6.6):
///   DIKTAFON_LLM_MODEL=…/Qwen3-0.6B-Q8_0.gguf \
///   DIKTAFON_TEST_DIR=/tmp/dk_e2e \
///   flutter test integration_test/m3_summaries_test.dart -d linux
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:diktafon/app.dart';
import 'package:diktafon/application/providers.dart';
import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/files/audio_file_store.dart';
import 'package:diktafon/domain/models.dart';
import 'package:diktafon/presentation/widgets/cassette_card.dart';
import 'package:diktafon/services/processing/job_queue.dart';
import 'package:diktafon/services/providers/llm/llm_model_manager.dart';
import 'package:diktafon/services/providers/whisper/whisper_model_manager.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'test_env.dart';
import 'tone_wav.dart';

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

Future<void> _settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// A Czech shopping-and-errands memo, worded so a 0.6B model has real
/// content to compress (100 ms word grid, §4.2 timings stay sane).
Transcript _czechTranscript() {
  const text = 'takže nákup na víkend koupit mléko chleba máslo a vajíčka '
      'nezapomenout na granule pro psa a taky zavolat mámě '
      'jestli přijede v sobotu na oběd';
  final words = text.split(' ');
  return Transcript(languageCode: 'cs', segments: [
    Segment(startMs: 0, endMs: words.length * 100, words: [
      for (final (i, w) in words.indexed)
        Word(text: w, startMs: i * 100, endMs: i * 100 + 90),
    ]),
  ]);
}

void main() {
  final modelPath = testEnv('DIKTAFON_LLM_MODEL');

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (Platform.isLinux) {
      JustAudioMediaKit.ensureInitialized(
        linux: true,
        windows: false,
        libmpv: testEnv('LIBMPV_PATH'),
      );
    }
    final base = testEnv('DIKTAFON_TEST_DIR');
    if (base != null) {
      _workDir = Directory(base);
      if (_workDir.existsSync()) _workDir.deleteSync(recursive: true);
      _workDir.createSync(recursive: true);
    } else {
      _workDir = Directory.systemTemp.createTempSync('diktafon_m3_');
    }
  });

  testWidgets(
    'M3: restored summarize job → gist → cassette overview → suggested title',
    (tester) async {
      // — Provision the LLM the way main() would find it (§7.1 layout) —
      final llmDir = Directory('${_workDir.path}/models/llm')
        ..createSync(recursive: true);
      File(modelPath!)
          .copySync('${llmDir.path}/${LlmModel.qwen3_0_6b.fileName}');

      final db = AppDatabase.forTesting(
          NativeDatabase(File('${_workDir.path}/diktafon.db')));
      final audioDir = Directory('${_workDir.path}/audio')
        ..createSync(recursive: true);
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioFileStoreProvider.overrideWithValue(AudioFileStore(audioDir)),
        whisperModelManagerProvider.overrideWithValue(WhisperModelManager(
            Directory('${_workDir.path}/models/whisper')
              ..createSync(recursive: true))),
        llmModelManagerProvider.overrideWithValue(LlmModelManager(llmDir)),
      ]);
      addTearDown(container.dispose);

      // The unlisted test tier (§6.6) — user-facing default stays 1.7B.
      final settings = container.read(settingsRepositoryProvider);
      await settings.setLlmTier(LlmModel.qwen3_0_6b.tier);
      await settings.setAppLanguage('cs');

      // — Seed the post-M2 state: a transcribed memo whose summarize job
      //   survived shutdown (§6.5 durability). Audio = 4 s tone (the player
      //   needs a real file; the words come from the transcript) —
      final memoDir = Directory('${audioDir.path}/c-m3')
        ..createSync(recursive: true);
      final audioPath = '${memoDir.path}/m-m3.wav';
      File(audioPath).writeAsBytesSync(toneWav(hz: 440, seconds: 4));

      await db.into(db.cassettes).insert(CassetteRow(
            id: 'c-m3',
            titleIsUserSet: false,
            colorSeed: 7,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ));
      await db.into(db.memos).insert(MemoRow(
            id: 'm-m3',
            cassetteId: 'c-m3',
            filePath: audioPath,
            durationMs: 4000,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            detectedLang: 'cs',
            transcript: jsonEncode(_czechTranscript().toJson()),
            status: 'transcribed',
          ));
      await db.into(db.jobs).insert(JobRow(
            id: 'job-m3',
            type: JobType.summarizeMemo.name,
            targetId: 'm-m3',
            status: 'queued',
            attempts: 0,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ));

      // M4: skip the first-run flow — this test exercises the app proper.
      await db.into(db.settingsEntries).insert(
          const SettingRow(key: 'firstRunDone', value: '1'));

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(key: _boundaryKey, child: const DiktafonApp()),
      ));
      await _settle(tester);

      // main()'s job resume (§6.5) — the whole M3 pipeline runs from here.
      final drain = container.read(jobQueueProvider).drain();

      // — Wait for the pipeline: gist → overview + title (model load plus
      //   three generations of a 0.6B model; generous headroom) —
      MemoRow? memo;
      CassetteRow? cassette;
      final deadline = DateTime.now().add(const Duration(seconds: 180));
      while (DateTime.now().isBefore(deadline)) {
        memo = await (db.select(db.memos)
              ..where((m) => m.id.equals('m-m3')))
            .getSingleOrNull();
        cassette = await (db.select(db.cassettes)
              ..where((c) => c.id.equals('c-m3')))
            .getSingleOrNull();
        final done = memo?.status == 'ready' &&
            cassette?.summary != null &&
            cassette?.label != null;
        if (done || memo?.status == 'failed') break;
        await _settle(tester, frames: 4);
      }
      await drain;

      expect(memo?.status, 'ready',
          reason: 'the restored job must complete the §4.3 state machine');
      expect(memo!.memoSummary, isNotEmpty);
      expect(cassette!.summary, isNotEmpty);
      expect(cassette.label, isNotEmpty,
          reason: 'title auto-suggested from the overview (D10)');
      expect(cassette.titleIsUserSet, isFalse);

      // — The enrichment must be visible in the UI (the card paints its
      //   label, so the home grid is checked through its semantics) —
      await _settle(tester);
      expect(
          find.bySemanticsLabel(
              RegExp('^${RegExp.escape(cassette.label!)},')),
          findsWidgets,
          reason: 'home grid card carries the suggested title');
      await _shot(tester, '20-home-suggested-title');

      await tester.tap(find.byType(CassetteCard).first);
      await _settle(tester);
      expect(find.text(cassette.label!), findsWidgets,
          reason: 'cassette header carries the suggested title (D10)');
      expect(find.textContaining(memo.memoSummary!.substring(0, 8)),
          findsWidgets,
          reason: 'memo divider carries the gist caption (§5.3)');
      await _shot(tester, '21-cassette-overview-and-gist');
    },
    // Needs DIKTAFON_LLM_MODEL → path to a Qwen3-0.6B-Q8_0.gguf.
    skip: modelPath == null,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
