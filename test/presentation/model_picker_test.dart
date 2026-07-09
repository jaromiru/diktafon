import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:diktafon/application/providers.dart';
import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/l10n/l10n.dart';
import 'package:diktafon/presentation/screens/settings_screen.dart';
import 'package:diktafon/presentation/theme/theme.dart';
import 'package:diktafon/services/providers/llm/llm_model_manager.dart';
import 'package:diktafon/services/providers/transcription_provider.dart'
    show ModelStatus;
import 'package:diktafon/services/providers/whisper/whisper_model_manager.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The model picker against a real (local) HTTP download: select a tier →
/// progress → installed → tier persisted; delete → back to downloadable.
void main() {
  late HttpServer server;
  late Directory dir;
  late AppDatabase db;
  final payload = utf8.encode('tiny fake ggml payload for the picker test');
  final chunkGate = StreamController<void>.broadcast();

  setUp(() async {
    // flutter_test mocks HttpClient with 400s; this test talks to a real
    // local server.
    HttpOverrides.global = null;
    dir = Directory.systemTemp.createTempSync('dk_picker_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      // Two chunks with a hold in between so the test can observe the
      // "downloading" state deterministically.
      try {
        request.response.add(payload.sublist(0, 10));
        await request.response.flush();
        await chunkGate.stream.first;
        request.response.add(payload.sublist(10));
        await request.response.close();
      } catch (_) {
        // The pause step aborts its connection mid-response.
      }
    });
  });

  tearDown(() async {
    await server.close(force: true);
    await db.close();
    dir.deleteSync(recursive: true);
  });

  testWidgets('select → download with progress → installed → delete',
      (tester) async {
    final spec = WhisperModel(
      tier: 'small',
      label: 'Whisper small',
      description: 'Recommended tier.',
      fileName: 'ggml-small-q5_1.bin',
      sizeBytes: payload.length,
      sha256Hex: sha256.convert(payload).toString(),
      urlOverride: Uri.parse('http://127.0.0.1:${server.port}/model.bin'),
    );
    final manager = WhisperModelManager(dir, catalog: [spec]);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        whisperModelManagerProvider.overrideWithValue(manager),
        // Selecting a tier drains the job queue, which consults the
        // summarization seam — give it a real (empty) store.
        llmModelManagerProvider.overrideWithValue(LlmModelManager(dir)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: buildTheme(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const ModelPickerDialog(),
                ),
                child: const Text('open picker'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open picker'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Whisper small'), findsOneWidget);
    expect(find.textContaining('download ·'), findsOneWidget);

    // Start the download on the real event loop (widget-test zones freeze
    // real IO); the dialog follows along through the manager's stream.
    late Future<void> download;
    await tester.runAsync(() async {
      download = manager.download(spec);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('downloading'), findsOneWidget,
        reason: 'first chunk landed, second is gated — mid-download UI');

    // Tapping the tier on the wire pauses it: the transfer aborts quietly,
    // the partial is stashed and the row offers resume + discard.
    await tester.tap(find.text('Whisper small'));
    await tester.runAsync(() async {
      await expectLater(download, throwsA(isA<ModelDownloadPaused>()));
    });
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('paused at'), findsOneWidget);
    expect(find.byTooltip('Delete model file'), findsOneWidget,
        reason: 'a paused partial can be discarded');
    expect(File('${manager.fileOf(spec).path}.paused').existsSync(), isTrue);

    // Tapping again routes the paused tier back into a download.
    await tester.tap(find.text('Whisper small'));
    await tester.pump();
    await tester.pump();
    expect(manager.statusOf(spec), ModelStatus.downloading,
        reason: 'tap on a paused tier resumes');

    // The tap-started transfer awaits in the widget zone: alternate real-IO
    // windows (runAsync) with microtask flushes (pump) until the dialog
    // shows it installed, releasing the server's held chunk each round.
    for (var i = 0;
        i < 100 && find.textContaining('installed').evaluate().isEmpty;
        i++) {
      await tester.runAsync(() async {
        chunkGate.add(null);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pump();
    }
    expect(find.textContaining('installed'), findsOneWidget);
    expect(manager.fileOf(spec).existsSync(), isTrue);

    // Selecting an installed tier persists the choice (§5.5), no download.
    await tester.tap(find.text('Whisper small'));
    await tester.pump();
    await tester.pump();
    final settings = await (db.select(db.settingsEntries)).get();
    expect(
      settings.any((s) => s.key == 'whisperTier' && s.value == 'small'),
      isTrue,
      reason: 'selecting a tier persists it (§5.5)',
    );

    // Manage: delete returns the tier to a downloadable state.
    await tester.tap(find.byTooltip('Delete model file'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('download ·'), findsOneWidget);
    expect(manager.fileOf(spec).existsSync(), isFalse);

    // Unmount while pumps still run: disposing the ProviderScope closes
    // drift's stream queries, which schedule one last zero-length timer —
    // the pump must advance the (fake) clock for that timer to fire.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
