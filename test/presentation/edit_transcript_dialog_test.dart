import 'package:diktafon/l10n/l10n.dart';
import 'package:diktafon/presentation/theme/theme.dart';
import 'package:diktafon/presentation/widgets/edit_transcript_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The §6.9 editor dialog: SAVE returns the corrected text (and is held back
/// while it is effectively empty), CANCEL returns null.
void main() {
  // Returns the dialog's own future (unawaited — it completes on pop).
  Future<Future<String?>> open(WidgetTester tester, String initialText) async {
    late Future<String?> result;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => result =
                showEditTranscriptDialog(context, initialText: initialText),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  TextButton saveButton(WidgetTester tester) => tester.widget<TextButton>(
      find.ancestor(of: find.text('SAVE'), matching: find.byType(TextButton)));

  testWidgets('SAVE returns the edited text', (tester) async {
    final result = await open(tester, 'hello world');
    expect(find.text('hello world'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'hello there world');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();
    expect(await result, 'hello there world');
  });

  testWidgets('emptied text disables SAVE until words come back',
      (tester) async {
    await open(tester, 'hello');
    await tester.enterText(find.byType(TextField), '  \n ');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'typed back');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('CANCEL returns null', (tester) async {
    final result = await open(tester, 'hello');
    await tester.enterText(find.byType(TextField), 'discarded change');
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(await result, null);
  });
}
