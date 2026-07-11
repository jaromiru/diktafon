/// Store & README screenshots: boots the real app over a seeded, realistic
/// dataset and captures exactly-9:16 shots (the Play Store requirement) of
/// the key screens, each in light and dark: home grid, first-run setup,
/// cassette view (transport + highlighted word, summary collapsed),
/// Settings, and mid-recording. No ML engine runs: enrichment is pre-seeded
/// and the model files are sparse stand-ins, so Settings reads "installed"
/// (the first-run shots use a separate pristine store so its rows read
/// "choose & download"). Animations are disabled so the pulsing record
/// dot/tail capture at full red instead of a random mid-fade frame.
///
/// One run captures one device profile, picked by DIKTAFON_SHOT_PROFILE:
///   phone     360x640  @3x -> 1080x1920   (default)
///   tablet7   603x1072 @2x -> 1206x2144
///   tablet10  720x1280 @2x -> 1440x2560   (10" needs sides >= 1080)
///
///   DIKTAFON_TEST_DIR=/tmp/dk_shots_phone DIKTAFON_SHOT_PROFILE=phone \
///   flutter test integration_test/store_screenshots_test.dart -d linux
///
/// Shots land in $DIKTAFON_TEST_DIR/shots/ as raw screen captures; the
/// framing pass (`tool/screenshots/frame_screenshots.py --device phone
/// $DIKTAFON_TEST_DIR/shots`) publishes each to
/// `docs/store/screenshots/{device}/` raw (the Play upload) plus a framed
/// presentation version under `{device}/framed/`, with framed README copies
/// in media/ (phone profile only).
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:diktafon/app.dart';
import 'package:diktafon/application/providers.dart';
import 'package:diktafon/application/recording_controller.dart';
import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/files/audio_file_store.dart';
import 'package:diktafon/domain/models.dart';
import 'package:diktafon/presentation/widgets/cassette_card.dart';
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

final _boundaryKey = GlobalKey();

/// The card paints its label (§5.2 custom paint), so it is found through its
/// semantics ("{label}, {memos}").
final _kitchenCard = find.bySemanticsLabel(RegExp('^Kitchen renovation,'));
late Directory _workDir;

/// Device profiles: logical canvas + capture scale. Every output is exactly
/// 9:16 (Play requires 16:9 or 9:16; the 10" tablet also needs sides
/// 1080–7680 px).
const _profiles = <String, ({Size logical, double scale})>{
  'phone': (logical: Size(360, 640), scale: 3.0), // 1080x1920
  'tablet7': (logical: Size(603, 1072), scale: 2.0), // 1206x2144
  'tablet10': (logical: Size(720, 1280), scale: 2.0), // 1440x2560
};
final _profile = _profiles[
    testEnv('DIKTAFON_SHOT_PROFILE') ?? 'phone']!;

Future<void> _shot(WidgetTester tester, String name) async {
  await _settle(tester);
  final dir = Directory('${_workDir.path}/shots')..createSync(recursive: true);
  final boundary =
      _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: _profile.scale);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<void> _settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// ~185 words/min cadence over one segment per sentence.
Transcript _transcript(List<String> sentences) {
  var cursor = 0;
  final segments = <Segment>[];
  for (final sentence in sentences) {
    final words = sentence.split(' ');
    segments.add(Segment(
      startMs: cursor,
      endMs: cursor + words.length * 325,
      words: [
        for (final (i, w) in words.indexed)
          Word(
              text: w,
              startMs: cursor + i * 325,
              endMs: cursor + i * 325 + 300),
      ],
    ));
    cursor += words.length * 325 + 500;
  }
  return Transcript(languageCode: 'en', segments: segments);
}

/// A model file that exists with the pinned byte size but occupies no disk:
/// ModelManager treats presence as installed (§6.6), so Settings and the
/// transcript captions render the provisioned state.
void _sparseModelFile(String path, int sizeBytes) {
  final raf = File(path).openSync(mode: FileMode.write);
  raf.setPositionSync(sizeBytes - 1);
  raf.writeByteSync(0);
  raf.closeSync();
}

void main() {
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
      _workDir = Directory.systemTemp.createTempSync('diktafon_shots_');
    }
  });

  testWidgets('store screenshots over seeded demo data', (tester) async {
    // Profile canvas regardless of the host window; shots are captured at
    // the profile's scale for full store resolution (exactly 9:16).
    tester.view.physicalSize = _profile.logical * _profile.scale;
    tester.view.devicePixelRatio = _profile.scale;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    // Reduced motion: the record dot/tail rest at full opacity instead of a
    // random pulse phase, so the recording shots are deterministic and red.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    // — 02/07: first-run setup, over its own pristine store (no models
    //   downloaded, empty DB) so the rows read "choose & download" —
    final frDir = Directory('${_workDir.path}/firstrun')
      ..createSync(recursive: true);
    final frDb = AppDatabase.forTesting(
        NativeDatabase(File('${frDir.path}/diktafon.db')));
    final frContainer = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(frDb),
      audioFileStoreProvider.overrideWithValue(
          AudioFileStore(Directory('${frDir.path}/audio')..createSync())),
      whisperModelManagerProvider.overrideWithValue(WhisperModelManager(
          Directory('${frDir.path}/whisper')..createSync())),
      llmModelManagerProvider.overrideWithValue(
          LlmModelManager(Directory('${frDir.path}/llm')..createSync())),
    ]);
    final frSettings = frContainer.read(settingsRepositoryProvider);
    await frSettings.setTheme('light');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: frContainer,
      child: RepaintBoundary(key: _boundaryKey, child: const DiktafonApp()),
    ));
    await _settle(tester, frames: 20);
    expect(find.text('START RECORDING'), findsOneWidget);
    await _shot(tester, '02-first-run');
    await frSettings.setTheme('dark');
    await _settle(tester, frames: 20);
    await _shot(tester, '07-first-run-dark');
    await tester.pumpWidget(const SizedBox());
    frContainer.dispose();

    // — Provisioned models (sparse stand-ins; nothing runs them here) —
    final whisperDir = Directory('${_workDir.path}/models/whisper')
      ..createSync(recursive: true);
    final llmDir = Directory('${_workDir.path}/models/llm')
      ..createSync(recursive: true);
    final whisperFile =
        '${whisperDir.path}/${WhisperModel.small.fileName}';
    _sparseModelFile(whisperFile, WhisperModel.small.sizeBytes);
    _sparseModelFile('${llmDir.path}/${LlmModel.qwen3_1_7b.fileName}',
        LlmModel.qwen3_1_7b.sizeBytes);

    final db = AppDatabase.forTesting(
        NativeDatabase(File('${_workDir.path}/diktafon.db')));
    final audioDir = Directory('${_workDir.path}/audio')
      ..createSync(recursive: true);
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      audioFileStoreProvider.overrideWithValue(AudioFileStore(audioDir)),
      whisperModelManagerProvider
          .overrideWithValue(WhisperModelManager(whisperDir)),
      llmModelManagerProvider.overrideWithValue(LlmModelManager(llmDir)),
    ]);
    addTearDown(container.dispose);

    final settings = container.read(settingsRepositoryProvider);
    await settings.setTheme('light');
    await db
        .into(db.settingsEntries)
        .insert(const SettingRow(key: 'firstRunDone', value: '1'));

    // — Demo data: one fully enriched hero cassette + a lived-in shelf.
    //   Times are anchored to a fixed afternoon so the metas read well —
    final today = DateTime.now();
    final now = DateTime(today.year, today.month, today.day, 17, 45);
    int ago({int days = 0, int hours = 0, int minutes = 0}) => now
        .subtract(Duration(days: days, hours: hours, minutes: minutes))
        .millisecondsSinceEpoch;

    Future<void> cassette(String id, String? label, int seed, String? summary,
        {required int createdAt, required int updatedAt}) async {
      await db.into(db.cassettes).insert(CassetteRow(
            id: id,
            label: label,
            titleIsUserSet: label != null,
            colorSeed: seed,
            summary: summary,
            summaryUpdatedAt: summary == null ? null : updatedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ));
    }

    Future<void> memo(String cassetteId, String id, int createdAt,
        {List<String>? sentences, String? gist, int? durationMs}) async {
      final transcript = sentences == null ? null : _transcript(sentences);
      await db.into(db.memos).insert(MemoRow(
            id: id,
            cassetteId: cassetteId,
            filePath: '${audioDir.path}/$cassetteId/$id.m4a',
            durationMs: durationMs ?? transcript!.segments.last.endMs + 700,
            createdAt: createdAt,
            detectedLang: transcript == null ? null : 'en',
            transcript:
                transcript == null ? null : jsonEncode(transcript.toJson()),
            memoSummary: gist,
            status: 'ready',
          ));
    }

    // Hero: the cassette that gets opened.
    await cassette(
      'c-kitchen',
      'Kitchen renovation',
      3,
      'The kitchen refit is moving: measurements are done, the contractor '
          'quote lands on Thursday, and the cabinet color is down to sage '
          'green or off-white. Every appliance stays except the oven.',
      createdAt: ago(days: 4),
      updatedAt: ago(minutes: 20),
    );
    final kitchenAudio = Directory('${audioDir.path}/c-kitchen')
      ..createSync(recursive: true);
    await memo('c-kitchen', 'm-measure', ago(days: 3, hours: 2), sentences: [
      'Measured the whole kitchen this morning.',
      'The window wall is three meters twenty and the counter run is two '
          'forty, with seventy centimeters left for the fridge.',
      'One thing to remember, the radiator pipe sticks out on the left, so '
          'the corner cabinet needs a cutout.',
    ], gist: 'Kitchen measured: window wall 3.20 m, counter 2.40 m, 70 cm '
        'left for the fridge; the corner cabinet needs a cutout for the '
        'radiator pipe.');
    await memo('c-kitchen', 'm-quote', ago(days: 2, hours: 5), sentences: [
      'Called Hanson about the quote.',
      'He can start in the second week of next month and the full number '
          'arrives by Thursday.',
      'Demolition is included but disposal is extra, roughly two hundred.',
    ], gist: 'Hanson can start in the second week of next month; the full '
        'quote arrives Thursday. Demolition included, disposal ~200 extra.');
    await memo('c-kitchen', 'm-colors', ago(minutes: 20), sentences: [
      'Cabinet colors, round three.',
      'I keep coming back to sage green, but the off-white would make the '
          'room feel bigger.',
      'Maybe green below and white above.',
      'Also decided that every appliance stays except the oven, that one '
          'is done for.',
    ], gist: 'Cabinet color is down to sage green vs. off-white, possibly '
        'split. All appliances stay except the oven.');
    // Real (tone) audio so the tape player has files to load.
    for (final f in ['m-measure', 'm-quote', 'm-colors']) {
      final r = await Process.run('ffmpeg', [
        '-y', '-f', 'lavfi', '-i', 'sine=frequency=330:duration=2',
        '-ar', '16000', '-ac', '1', '${kitchenAudio.path}/$f.m4a',
      ]);
      expect(r.exitCode, 0, reason: 'ffmpeg: ${r.stderr}');
    }

    // The rest of the shelf (never opened — rows only).
    await cassette('c-new', null, 5, null,
        createdAt: ago(hours: 1), updatedAt: ago(hours: 1));
    await cassette(
        'c-grocery',
        'Grocery runs',
        0,
        'Weekend shopping: milk, bread, eggs and dog food; pick up the dry '
            'cleaning on Saturday and swing by the pharmacy.',
        createdAt: ago(days: 9),
        updatedAt: ago(days: 1, hours: 3));
    await cassette(
        'c-book',
        'Book ideas',
        2,
        'Notes for the novel: the lighthouse chapter opens mid-storm, '
            'Mara\'s letters become the frame, and the 1930s ferry routes '
            'need research.',
        createdAt: ago(days: 21),
        updatedAt: ago(days: 3, hours: 6));
    await cassette(
        'c-standup',
        'Standup notes',
        1,
        'Sprint 12: the export bug is fixed and shipped, the migration runs '
            'Friday night, and the client demo moves to Tuesday morning.',
        createdAt: ago(days: 30),
        updatedAt: ago(days: 5, hours: 2));
    await cassette(
        'c-garden',
        'Garden plan',
        4,
        'Spring beds: tomatoes and basil along the south wall, the compost '
            'needs turning, and the apple tree wants pruning before the buds '
            'break.',
        createdAt: ago(days: 40),
        updatedAt: ago(days: 8));
    await cassette(
        'c-lisbon',
        'Trip to Lisbon',
        5,
        'Lisbon in October: fly Thursday evening, the apartment is booked in '
            'Alfama, and the day trip to Sintra needs train tickets.',
        createdAt: ago(days: 55),
        updatedAt: ago(days: 12));
    await cassette(
        'c-recipes',
        'Recipes to try',
        2,
        'To cook soon: the lemon-garlic orzo, a slow bolognese for Sunday, '
            'and grandma\'s plum dumplings before the season ends.',
        createdAt: ago(days: 70),
        updatedAt: ago(days: 15));
    var n = 0;
    for (final (id, count, start) in [
      ('c-grocery', 2, 9),
      ('c-book', 5, 21),
      ('c-standup', 8, 30),
      ('c-garden', 4, 40),
      ('c-lisbon', 6, 55),
      ('c-recipes', 3, 70),
    ]) {
      for (var i = 0; i < count; i++) {
        await memo(id, 'm-bg-${n++}', ago(days: start - i * 2, hours: i),
            durationMs: 25000 + (n * 7919) % 50000, gist: 'gist');
      }
    }

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(key: _boundaryKey, child: const DiktafonApp()),
    ));
    await _settle(tester, frames: 20);

    // Parks the playhead a quarter in: inside memo 1, whose transcript is
    // near the top on every profile, so the highlighted current word is
    // always on screen (file lengths don't matter: idle seeks report the
    // pending target).
    Future<void> seekIntoMemo1() async {
      final player = container.read(tapePlayerProvider);
      expect(player.tape.totalDurationMs, greaterThan(0));
      await player.seekGlobal((player.tape.totalDurationMs * 0.25).round());
      await _settle(tester, frames: 20);
    }

    // — 01: home grid —
    expect(find.byType(CassetteCard), findsWidgets);
    await _shot(tester, '01-home');

    // — 03: cassette view — transport, playhead mid-memo-1, highlighted
    //   word on screen, summary collapsed —
    await tester.tap(_kitchenCard);
    await _settle(tester, frames: 20);
    expect(find.textContaining('sage green'), findsWidgets);
    await seekIntoMemo1();
    await _shot(tester, '03-cassette');

    // — 04: Settings (models read "installed") —
    await tester.pageBack();
    await _settle(tester);
    await tester.tap(find.byTooltip('Settings'));
    await _settle(tester, frames: 20);
    expect(find.textContaining('installed'), findsWidgets);
    await _shot(tester, '04-settings');
    await tester.pageBack();
    await _settle(tester);

    // — 06/08/09: the dark set —
    await settings.setTheme('dark');
    await _settle(tester, frames: 20);
    await _shot(tester, '06-home-dark');
    await tester.tap(_kitchenCard);
    await _settle(tester, frames: 20);
    await seekIntoMemo1();
    await _shot(tester, '08-cassette-dark');
    await tester.pageBack();
    await _settle(tester);
    await tester.tap(find.byTooltip('Settings'));
    await _settle(tester, frames: 20);
    await _shot(tester, '09-settings-dark');
    await tester.pageBack();
    await _settle(tester);

    // — 10/05: recording, dark then light in one take (best-effort: needs a
    //   live capture source; the fake whisper file is removed first so the
    //   new memo's transcribe job parks quietly instead of feeding the real
    //   engine a sparse file) —
    File(whisperFile).deleteSync();
    await tester.tap(_kitchenCard);
    await _settle(tester, frames: 20);
    await tester.tap(find.bySemanticsLabel('Record a new memo'));
    await _settle(tester, frames: 30); // ~1.5 s of level + elapsed
    final recording = container.read(recordingControllerProvider);
    if (recording.isRecordingIn('c-kitchen')) {
      await _settle(tester, frames: 40);
      await _shot(tester, '10-recording-dark');
      await settings.setTheme('light');
      await _settle(tester, frames: 20);
      await _shot(tester, '05-recording');
      await tester.tap(find.bySemanticsLabel('Stop recording'));
      await _settle(tester, frames: 20);
    } else {
      debugPrint('recorder unavailable — skipping the recording shots');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
