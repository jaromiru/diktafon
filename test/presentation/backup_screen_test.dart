import 'package:diktafon/application/providers.dart';
import 'package:diktafon/data/db/database.dart';
import 'package:diktafon/l10n/l10n.dart';
import 'package:diktafon/presentation/screens/backup_screen.dart';
import 'package:diktafon/presentation/theme/theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Import must be gated by the D14 explanation dialog — the user hears
/// "nothing is deleted, re-imports duplicate" before any picker opens.
void main() {
  testWidgets('import explains itself first; cancel stops everything',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: buildTheme(Brightness.light),
        home: const BackupScreen(),
      ),
    ));
    // Discrete pumps, not pumpAndSettle — see model_picker_test (ambient
    // frames keep pumpAndSettle from ever settling).
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Import an archive'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // dialog animation

    expect(find.text('IMPORT CASSETTES?'), findsOneWidget);
    expect(find.textContaining('nothing is deleted'), findsOneWidget);
    expect(find.textContaining('second copy'), findsOneWidget);

    await tester.tap(find.text('CANCEL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('IMPORT CASSETTES?'), findsNothing);
    expect(find.text('Importing…'), findsNothing); // nothing ran

    // Unmount while pumps still run: disposing the ProviderScope closes
    // drift's stream queries, which schedule one last zero-length timer —
    // the pump must advance the (fake) clock for that timer to fire.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
