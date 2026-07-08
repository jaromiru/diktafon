/// M4 end-to-end: the first-run flow (§5.6, mockup 01 r8) on a real
/// desktop — one screen: nothing downloads on its own (the user may be on a
/// metered connection); each model row opens its picker, where choosing a
/// tier starts the download against a local HTTP server (not HuggingFace).
/// The microphone row is the CTA's only gate, START RECORDING opens the
/// first cassette empty (record armed, nothing rolling). Then the Export
/// data screen (§8) lists the new cassette.
///
/// Engine seams are overridden with fakes: the "models" this test downloads
/// are byte payloads, not runnable networks (§6.3 — that is the point of the
/// provider interfaces).
///
/// Run: flutter test integration_test/m4_first_run_test.dart -d linux
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:diktafon/app.dart';
import 'package:diktafon/application/providers.dart';
import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/files/audio_file_store.dart';
import 'package:diktafon/domain/models.dart';
import 'package:diktafon/presentation/widgets/deck.dart';
import 'package:diktafon/services/providers/llm/llm_model_manager.dart';
import 'package:diktafon/services/providers/summarization_provider.dart';
import 'package:diktafon/services/providers/transcription_provider.dart';
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

Future<void> _settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _FakeTranscription implements TranscriptionProvider {
  @override
  String get id => 'fake/transcription';

  @override
  Future<ModelStatus> modelStatus() async => ModelStatus.ready;

  @override
  Future<void> ensureModel({ProgressSink? onProgress}) async {}

  @override
  Future<Transcript> transcribe(AudioRef audio,
          {String? languageCode, CancelToken? cancel}) async =>
      const Transcript(languageCode: 'en', segments: [
        Segment(startMs: 0, endMs: 900, words: [
          Word(text: 'first', startMs: 0, endMs: 400),
          Word(text: 'memo', startMs: 450, endMs: 900),
        ]),
      ]);
}

class _FakeSummarization implements SummarizationProvider {
  @override
  String get id => 'fake/summarization';

  @override
  Future<ModelStatus> modelStatus() async => ModelStatus.ready;

  @override
  Future<void> ensureModel({ProgressSink? onProgress}) async {}

  @override
  Future<Transcript> cleanTranscript(Transcript t,
          {required String languageCode}) async =>
      t;

  @override
  Future<String> summarizeMemo(Transcript t,
          {required String languageCode}) async =>
      'A first memo.';

  @override
  Future<String> updateCassetteSummary({
    required String? previousSummary,
    required List<MemoDigest> newMemos,
    required String languageCode,
  }) async =>
      'A cassette with a first memo.';

  @override
  Future<String> suggestTitle(String cassetteSummary,
          {required String languageCode}) async =>
      'First tape';
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
      _workDir = Directory('$base/m4');
      if (_workDir.existsSync()) _workDir.deleteSync(recursive: true);
      _workDir.createSync(recursive: true);
    } else {
      _workDir = Directory.systemTemp.createTempSync('diktafon_m4_');
    }
  });

  testWidgets('M4: first-run → provision → record; backup screen',
      (tester) async {
    // Local "HuggingFace": each request streams a tiny payload.
    final whisperBytes = utf8.encode('fake whisper model payload');
    final llmBytes = utf8.encode('fake llm gguf payload, a bit longer');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response
          .add(request.uri.path.contains('whisper') ? whisperBytes : llmBytes);
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    final whisperSpec = WhisperModel(
      tier: 'small',
      label: 'Whisper small',
      description: 'Recommended tier.',
      fileName: 'ggml-small-q5_1.bin',
      sizeBytes: whisperBytes.length,
      sha256Hex: sha256.convert(whisperBytes).toString(),
      urlOverride:
          Uri.parse('http://127.0.0.1:${server.port}/whisper.bin'),
    );
    final llmSpec = LlmModel(
      tier: 'qwen3-1.7b',
      label: 'Qwen3 1.7B',
      description: 'Default summary model.',
      repo: 'local/test',
      fileName: 'qwen3.gguf',
      sizeBytes: llmBytes.length,
      sha256Hex: sha256.convert(llmBytes).toString(),
      contextTokens: 4096,
      urlOverride: Uri.parse('http://127.0.0.1:${server.port}/llm.gguf'),
    );

    final db = AppDatabase.forTesting(
        NativeDatabase(File('${_workDir.path}/diktafon.db')));
    final audioDir = Directory('${_workDir.path}/audio')
      ..createSync(recursive: true);
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      audioFileStoreProvider.overrideWithValue(AudioFileStore(audioDir)),
      whisperModelManagerProvider.overrideWithValue(WhisperModelManager(
          Directory('${_workDir.path}/models/whisper'),
          catalog: [whisperSpec])),
      llmModelManagerProvider.overrideWithValue(LlmModelManager(
          Directory('${_workDir.path}/models/llm'),
          catalog: [llmSpec])),
      // The fake "models" aren't runnable — enrich through fake engines
      // (the §6.3 seam the whole architecture exists for).
      transcriptionProvider.overrideWithValue(_FakeTranscription()),
      summarizationProvider.overrideWithValue(_FakeSummarization()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(key: _boundaryKey, child: const DiktafonApp()),
    ));
    await _settle(tester);

    // — One screen (mockup 01 note 1): intro paragraph + setup card —
    expect(find.text('Welcome to Diktafon'), findsOneWidget);
    expect(find.text('Allow microphone'), findsOneWidget);
    expect(find.text('Transcription'), findsOneWidget);
    expect(find.text('Summaries'), findsOneWidget);
    expect(find.text('Downloads finish in the background.'), findsOneWidget);
    await _shot(tester, '01-first-run-open');

    // The CTA is gated on the mic alone (note 2) — a tap before the grant
    // must not leave the screen.
    await tester.tap(find.text('START RECORDING'));
    await _settle(tester);
    expect(find.text('Welcome to Diktafon'), findsOneWidget,
        reason: 'START RECORDING stays dimmed until the mic is granted');

    // — Nothing downloads on its own (note 3, r8): both rows wait for an
    //   explicit choice — the user may be on a metered connection —
    await _settle(tester);
    expect(find.text('tap to choose a model to download'), findsNWidgets(2),
        reason: 'downloads must not start without the user choosing a model');

    // Choosing a tier inside a row's picker is what starts its download.
    Future<void> provision(String row, String option) async {
      await tester.tap(find.text(row));
      await _settle(tester);
      await tester.tap(find.text(option));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.textContaining('installed ·').evaluate().isNotEmpty) break;
      }
      expect(find.textContaining('installed ·'), findsOneWidget,
          reason: '$option downloaded once chosen');
      await tester.tapAt(const Offset(5, 5)); // dismiss the picker
      await _settle(tester);
    }

    await provision('Transcription', 'Whisper small');
    await provision('Summaries', 'Qwen3 1.7B');
    expect(find.textContaining('· ready'), findsNWidgets(2),
        reason: 'both rows reflect the finished downloads');
    // The pickers' "ready" snackbars would otherwise still hover over the
    // deck keys when the cassette opens below.
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
        .clearSnackBars();
    await _settle(tester);

    // — The mic row itself fires the permission prompt (note 2) —
    await tester.tap(find.text('Allow microphone'));
    await _settle(tester);
    expect(find.text('Access granted'), findsOneWidget);
    await _shot(tester, '02-first-run-granted');

    // — START RECORDING arms the deck, it doesn't press record (note 4) —
    await tester.tap(find.text('START RECORDING'));
    await _settle(tester);
    expect(find.textContaining('RECORDING MEMO'), findsNothing,
        reason: 'the first cassette opens empty — nothing rolls on its own');
    final recordKey = find
        .byWidgetPredicate((w) => w is DeckKey && w.glyph == DeckGlyph.record);
    expect(recordKey, findsOneWidget, reason: 'the record key is armed');
    await _shot(tester, '03-first-run-cassette-empty');

    await tester.tap(recordKey);
    await _settle(tester);
    expect(find.textContaining('RECORDING MEMO 1'), findsOneWidget);
    await _shot(tester, '04-first-run-recording');
    await Future<void>.delayed(const Duration(seconds: 2));
    await _settle(tester, frames: 4);

    await tester.tap(find
        .byWidgetPredicate((w) => w is DeckKey && w.glyph == DeckGlyph.stop));
    // Encoder finalization + duration probe + stream propagation.
    await Future<void>.delayed(const Duration(seconds: 2));
    await _settle(tester);

    // firstRunDone persisted; the memo landed on the tape.
    final settings = await db.select(db.settingsEntries).get();
    expect(
        settings.any((s) => s.key == 'firstRunDone' && s.value == '1'), isTrue);
    final memos = await db.select(db.memos).get();
    expect(memos, hasLength(1), reason: 'the first memo was captured');

    // — Back out: home shows the new cassette (first-run swapped away) —
    await tester.tap(find.byTooltip('Back'));
    await _settle(tester);
    expect(find.text('DIKTAFON'), findsOneWidget);
    expect(find.text('Welcome to Diktafon'), findsNothing,
        reason: 'first-run never comes back');

    // — Export data (§8): the cassette is offered for export —
    await tester.tap(find.byTooltip('Settings'));
    await _settle(tester);
    await tester.tap(find.text('Export data'));
    await _settle(tester);
    expect(find.text('Export all cassettes'), findsOneWidget);
    expect(find.textContaining('1 memo'), findsWidgets,
        reason: 'the recorded cassette is listed for export');
    await _shot(tester, '05-backup-export');
  });
}
