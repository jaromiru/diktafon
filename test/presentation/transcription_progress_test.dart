/// What a memo shows while the engine is on it (issue #18): the shimmer
/// until whisper has a figure, then the figure itself — and only for the
/// memo the engine is actually on.
library;

import 'package:diktafon/domain/models.dart';
import 'package:diktafon/domain/tape.dart';
import 'package:diktafon/l10n/l10n.dart';
import 'package:diktafon/presentation/theme/theme.dart';
import 'package:diktafon/presentation/widgets/ink_progress_bar.dart';
import 'package:diktafon/presentation/widgets/transcript_view.dart';
import 'package:diktafon/services/processing/job_queue.dart'
    show TranscriptionProgress;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Memo memo(String id, MemoStatus status) => Memo(
        id: id,
        cassetteId: 'c1',
        filePath: '/dev/null',
        durationMs: 4000,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            1000000 + id.hashCode % 1000),
        status: status,
      );

  final tape = Tape([
    memo('m1', MemoStatus.transcribing),
    memo('m2', MemoStatus.stored),
  ]);

  /// The shimmer is private to the view; its Semantics label is the one
  /// public thing about it.
  Finder shimmer() => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == 'transcribing…');

  Widget app(TranscriptionProgress? progress, {String locale = 'en'}) =>
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: TranscriptView(
            tape: tape,
            colorSeed: 0,
            globalMs: 0,
            currentMemoIndex: 0,
            playing: false,
            modelReady: true,
            transcriptionProgress: progress,
          ),
        ),
      );

  testWidgets('no figure yet → the shimmer, no number', (tester) async {
    await tester.pumpWidget(app(const TranscriptionProgress(
        memoId: 'm1', cassetteId: 'c1', fraction: 0)));
    expect(shimmer(), findsOneWidget);
    expect(find.byType(InkProgressBar), findsNothing);
  });

  testWidgets('a figure → caption with the percentage and an ink bar',
      (tester) async {
    await tester.pumpWidget(app(const TranscriptionProgress(
        memoId: 'm1', cassetteId: 'c1', fraction: 0.42)));
    expect(find.text('transcribing… 42%'), findsOneWidget);
    final bar = tester.widget<InkProgressBar>(find.byType(InkProgressBar));
    expect(bar.fraction, 0.42);
    expect(shimmer(), findsNothing);
    // The memo behind it still just waits.
    expect(find.text('queued for transcription…'), findsOneWidget);
  });

  testWidgets('the percentage follows the locale', (tester) async {
    await tester.pumpWidget(app(
        const TranscriptionProgress(
            memoId: 'm1', cassetteId: 'c1', fraction: 0.42),
        locale: 'fr'));
    // French sets the sign off with a (narrow no-break) space.
    expect(find.textContaining(RegExp(r'^transcription en cours… 42.%$')),
        findsOneWidget);
  });

  testWidgets('another memo\'s figure is not this memo\'s', (tester) async {
    await tester.pumpWidget(app(const TranscriptionProgress(
        memoId: 'elsewhere', cassetteId: 'c9', fraction: 0.9)));
    expect(shimmer(), findsOneWidget);
    expect(find.byType(InkProgressBar), findsNothing);
  });
}
