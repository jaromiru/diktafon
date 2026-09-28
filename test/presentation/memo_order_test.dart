/// Reading order (the "Newest first" menu entry): the list can run either
/// way, but the tape underneath never changes — ordinals, indices handed
/// to callbacks and the seek-follow all keep speaking tape order.
library;

import 'package:diktafon/domain/models.dart';
import 'package:diktafon/domain/tape.dart';
import 'package:diktafon/l10n/l10n.dart';
import 'package:diktafon/presentation/theme/theme.dart';
import 'package:diktafon/presentation/widgets/transcript_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const wordMs = 500;
  const wordsPerMemo = 60;
  const memoDurationMs = wordsPerMemo * wordMs;
  const memoCount = 20;

  Memo makeMemo(int i) => Memo(
        id: 'memo$i',
        cassetteId: 'c1',
        filePath: '/dev/null',
        durationMs: memoDurationMs,
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000000 + i * 60000),
        status: MemoStatus.ready,
        transcript: Transcript(
          languageCode: 'en',
          segments: [
            Segment(
              startMs: 0,
              endMs: memoDurationMs,
              words: [
                for (var j = 0; j < wordsPerMemo; j++)
                  Word(
                      text: 'm${i}w$j',
                      startMs: j * wordMs,
                      endMs: (j + 1) * wordMs),
              ],
            ),
          ],
        ),
      );

  final tape = Tape([for (var i = 0; i < memoCount; i++) makeMemo(i)]);
  final edited = <int>[];

  Widget app({required bool newestFirst, int globalMs = 0, int seekCount = 0}) =>
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: TranscriptView(
            tape: tape,
            colorSeed: 0,
            globalMs: globalMs,
            currentMemoIndex: tape.locate(globalMs).memoIndex,
            playing: false,
            seekCount: seekCount,
            newestFirst: newestFirst,
            onEditMemo: edited.add,
          ),
        ),
      );

  Finder heading(int ordinal) => find.textContaining('Memo $ordinal —');

  testWidgets('tape order by default: Memo 1 at the top', (tester) async {
    await tester.pumpWidget(app(newestFirst: false));
    expect(heading(1), findsOneWidget);
    expect(heading(20), findsNothing, reason: 'virtualized away, far down');
    expect(find.textContaining('m0w0 '), findsOneWidget);
  });

  testWidgets('newest first: the last memo leads, still numbered last',
      (tester) async {
    await tester.pumpWidget(app(newestFirst: true));
    expect(heading(20), findsOneWidget);
    expect(heading(1), findsNothing, reason: 'now the one far down');
    expect(tester.getTopLeft(heading(20)).dy,
        lessThan(tester.getTopLeft(heading(19)).dy));
    expect(find.textContaining('m19w0 '), findsOneWidget);
  });

  testWidgets('menu callbacks carry the tape index, not the row',
      (tester) async {
    edited.clear();
    await tester.pumpWidget(app(newestFirst: true));
    // The first row's ⋯ menu belongs to memo 20 (tape index 19).
    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit transcription'));
    await tester.pumpAndSettle();
    expect(edited, [19]);
  });

  testWidgets('seek-follow still finds an unbuilt memo when reversed',
      (tester) async {
    Rect? wordRect(int memo, int word) {
      final paragraphs = find.byWidgetPredicate((w) =>
          w is RichText && w.text.toPlainText().startsWith('m${memo}w0 '));
      if (paragraphs.evaluate().isEmpty) return null;
      final render = tester.renderObject<RenderParagraph>(paragraphs);
      final plain =
          (tester.widget(paragraphs) as RichText).text.toPlainText();
      final start = plain.indexOf('m${memo}w$word ');
      final boxes = render.getBoxesForSelection(TextSelection(
          baseOffset: start, extentOffset: start + 'm${memo}w$word'.length));
      if (boxes.isEmpty) return null;
      return boxes.first.toRect().shift(render.localToGlobal(Offset.zero));
    }

    await tester.pumpWidget(app(newestFirst: true));
    // Memo 3 (tape index 2) sits near the bottom of a reversed list and
    // is not built yet.
    expect(wordRect(2, 30), isNull);
    final target = 2 * memoDurationMs + 30 * wordMs + wordMs ~/ 2;
    await tester.pumpWidget(
        app(newestFirst: true, globalMs: target, seekCount: 1));
    await tester.pumpAndSettle();
    final rect = wordRect(2, 30);
    expect(rect, isNotNull, reason: 'the hop lands the memo in the viewport');
    final viewport = tester.getRect(find.byType(TranscriptView));
    expect(viewport.overlaps(rect!), isTrue);
    expect(rect.top, greaterThanOrEqualTo(viewport.top));
    expect(rect.bottom, lessThanOrEqualTo(viewport.bottom));
  });
}
