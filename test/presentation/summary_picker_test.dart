import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:diktafon/application/providers.dart';
import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/data/repositories/settings_repository.dart';
import 'package:diktafon/l10n/l10n.dart';
import 'package:diktafon/presentation/screens/settings_screen.dart';
import 'package:diktafon/presentation/theme/theme.dart';
import 'package:diktafon/presentation/widgets/ink_toggle.dart';
import 'package:diktafon/services/providers/llm/llm_model_manager.dart';
import 'package:diktafon/services/providers/whisper/whisper_model_manager.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The summaries on/off switch lives in the summary-model picker as its
/// first row (replacing the old Settings toggle): picking "No summaries"
/// parks summary work, picking any model turns it back on.
void main() {
  late Directory dir;
  late AppDatabase db;
  final payload = utf8.encode('fake gguf payload');
  // The default llmTier, so the row carries the checkmark out of the box.
  final spec = LlmModel(
    tier: 'qwen3-1.7b',
    label: 'Qwen test',
    description: 'Test tier.',
    repo: 'test/repo',
    fileName: 'qwen-test.gguf',
    sizeBytes: payload.length,
    sha256Hex: sha256.convert(payload).toString(),
    contextTokens: 4096,
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('dk_llm_picker_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Widget app({required Widget home}) => ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          whisperModelManagerProvider
              .overrideWithValue(WhisperModelManager(dir)),
          llmModelManagerProvider
              .overrideWithValue(LlmModelManager(dir, catalog: [spec])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: buildTheme(Brightness.light),
          home: home,
        ),
      );

  FontWeight? weightOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.fontWeight;

  testWidgets('off row leads the picker and drives summariesEnabled',
      (tester) async {
    // Installed model: selecting it must not try to download.
    File('${dir.path}/${spec.fileName}').writeAsBytesSync(payload);

    await tester.pumpWidget(app(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const LlmModelPickerDialog(),
              ),
              child: const Text('open picker'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open picker'));
    await tester.pump();
    await tester.pump();

    // The off row exists, sits above the model tiers, and the default
    // (summaries on) leaves the checkmark on the selected tier.
    expect(find.text('No summaries'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('No summaries')).dy,
      lessThan(tester.getTopLeft(find.text('Qwen test')).dy),
    );
    expect(weightOf(tester, 'Qwen test'), FontWeight.w700);
    expect(weightOf(tester, 'No summaries'), isNot(FontWeight.w700));

    // Picking "No summaries" persists the off state and claims the mark.
    await tester.tap(find.text('No summaries'));
    await tester.pump();
    await tester.pump();
    expect(weightOf(tester, 'No summaries'), FontWeight.w700);
    expect(weightOf(tester, 'Qwen test'), isNot(FontWeight.w700));
    var settings = await SettingsRepository(db).get();
    expect(settings.summariesEnabled, isFalse);

    // Picking a model is the way back on.
    await tester.tap(find.text('Qwen test'));
    await tester.pump();
    await tester.pump();
    expect(weightOf(tester, 'Qwen test'), FontWeight.w700);
    expect(weightOf(tester, 'No summaries'), isNot(FontWeight.w700));
    settings = await SettingsRepository(db).get();
    expect(settings.summariesEnabled, isTrue);
    expect(settings.llmTier, spec.tier);

    // Disposing the scope closes drift's stream queries; advance the fake
    // clock so their final zero-length timer fires.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('Settings has no summaries toggle; the row mirrors off',
      (tester) async {
    await tester.pumpWidget(app(home: const SettingsScreen()));
    await tester.pump();
    await tester.pump();

    // Only the chime keeps a toggle; the summary-model row shows the
    // selected tier (the static catalog's label) while summaries are on…
    expect(find.byType(InkToggle), findsOneWidget);
    expect(find.textContaining('Qwen3 1.7B'), findsOneWidget);
    expect(find.text('No summaries'), findsNothing);

    // …and mirrors the picker's off choice once summaries are disabled,
    // keeping the "tap to set up" affordance the other row states carry.
    await SettingsRepository(db).setSummariesEnabled(false);
    await tester.pump();
    await tester.pump();
    expect(find.text('No summaries · tap to set up'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
