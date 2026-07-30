import 'dart:io';

import 'package:diktafon/application/providers.dart';
import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/repositories/settings_repository.dart';
import 'package:diktafon/l10n/l10n.dart';
import 'package:diktafon/presentation/screens/settings_screen.dart';
import 'package:diktafon/presentation/theme/theme.dart';
import 'package:diktafon/services/providers/llm/llm_model_manager.dart';
import 'package:diktafon/services/providers/whisper/whisper_model_manager.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory modelDir;
  late AppDatabase db;

  setUp(() {
    modelDir = Directory.systemTemp.createTempSync('dk_language_picker_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    modelDir.deleteSync(recursive: true);
  });

  Widget app() => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      whisperModelManagerProvider.overrideWithValue(
        WhisperModelManager(modelDir),
      ),
      llmModelManagerProvider.overrideWithValue(LlmModelManager(modelDir)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: buildTheme(Brightness.light),
      home: const SettingsScreen(),
    ),
  );

  testWidgets('long language picker scrolls to and selects Italian', (
    tester,
  ) async {
    // Short phone viewport: Italian begins below the first visible choices,
    // reproducing the language-wave-2 picker regression.
    tester.view.physicalSize = const Size(360, 520);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Transcription language'));
    await tester.pump();
    await tester.pump();

    final scrollbar = tester.widget<Scrollbar>(
      find.byKey(const Key('language-picker-scrollbar')),
    );
    expect(
      scrollbar.thumbVisibility,
      isTrue,
      reason: 'the dialog must advertise that more languages follow',
    );
    expect(scrollbar.trackVisibility, isTrue);

    final list = find.byKey(const Key('language-picker-list'));
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
      greaterThan(0),
    );

    await tester.scrollUntilVisible(
      find.text('Italiano'),
      180,
      scrollable: scrollable,
    );
    await tester.tap(find.text('Italiano'));
    await tester.pumpAndSettle();

    expect((await SettingsRepository(db).get()).appLanguage, 'it');
    expect(
      find.text('Italiano'),
      findsOneWidget,
      reason: 'the Settings row mirrors the persisted Whisper override',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
