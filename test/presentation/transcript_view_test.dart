import 'package:diktafon/domain/models.dart';
import 'package:diktafon/domain/tape.dart';
import 'package:diktafon/l10n/l10n.dart';
import 'package:diktafon/presentation/theme/theme.dart';
import 'package:diktafon/presentation/widgets/transcript_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

/// Seeking must keep the highlighted word on screen (§5.3): the view follows
/// every seekCount bump — including into memos the ListView hasn't built —
/// but never stirs when the word is already comfortably visible.
void main() {
  const wordMs = 500; // every word spans 500 ms
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

  Widget app(int globalMs, int seekCount) => MaterialApp(
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
          ),
        ),
      );

  int globalMsOf(int memo, int word) =>
      memo * memoDurationMs + word * wordMs + wordMs ~/ 2;

  /// The on-screen rect of `m<memo>w<word>` — null while its paragraph
  /// isn't built (virtualized away).
  Rect? wordRect(WidgetTester tester, int memo, int word) {
    final paragraphs = find.byWidgetPredicate((w) =>
        w is RichText && w.text.toPlainText().startsWith('m${memo}w0 '));
    if (paragraphs.evaluate().isEmpty) return null;
    final render = tester.renderObject<RenderParagraph>(paragraphs);
    final plain = (tester.widget(paragraphs) as RichText).text.toPlainText();
    final start = plain.indexOf('m${memo}w$word ');
    final boxes = render.getBoxesForSelection(TextSelection(
        baseOffset: start, extentOffset: start + 'm${memo}w$word'.length));
    if (boxes.isEmpty) return null;
    return boxes.first.toRect().shift(render.localToGlobal(Offset.zero));
  }

  Future<void> settleFollow(WidgetTester tester) async {
    // Post-frame follow pass(es) + the 240 ms scroll animation.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  double scrollOffset(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

  testWidgets('seek far ahead scrolls an unbuilt memo\'s word into view',
      (tester) async {
    await tester.pumpWidget(app(0, 0));
    await tester.pump();
    expect(wordRect(tester, 15, 30), isNull); // memo 15 starts virtualized

    await tester.pumpWidget(app(globalMsOf(15, 30), 1));
    await settleFollow(tester);

    final rect = wordRect(tester, 15, 30);
    final viewport = tester.getRect(find.byType(TranscriptView));
    expect(rect, isNotNull);
    // Visible with breathing room on both sides (margin is 88, animation
    // rounding gets a little slack).
    expect(rect!.top, greaterThan(viewport.top + 60));
    expect(rect.bottom, lessThan(viewport.bottom - 60));
  });

  testWidgets('seek within the comfortable window does not move the view',
      (tester) async {
    await tester.pumpWidget(app(0, 0));
    await tester.pump();
    await tester.pumpWidget(app(globalMsOf(15, 30), 1));
    await settleFollow(tester);
    final before = scrollOffset(tester);
    expect(before, greaterThan(0)); // the first seek did scroll

    // One word onward — same neighbourhood, already visible.
    await tester.pumpWidget(app(globalMsOf(15, 31), 2));
    await settleFollow(tester);

    expect(scrollOffset(tester), closeTo(before, 1));
  });

  testWidgets('seek backwards follows too', (tester) async {
    await tester.pumpWidget(app(0, 0));
    await tester.pump();
    await tester.pumpWidget(app(globalMsOf(15, 30), 1));
    await settleFollow(tester);
    expect(scrollOffset(tester), greaterThan(0));

    await tester.pumpWidget(app(globalMsOf(2, 10), 2));
    await settleFollow(tester);

    final rect = wordRect(tester, 2, 10);
    final viewport = tester.getRect(find.byType(TranscriptView));
    expect(rect, isNotNull);
    expect(rect!.top, greaterThan(viewport.top + 60));
    expect(rect.bottom, lessThan(viewport.bottom - 60));
  });

  group('CJK paragraphs (§13 wave 2)', () {
    // Words as the wave-2 whisper assembly stores them: per-token, with
    // punctuation already re-attached; one code-switching Latin word.
    final cjkWords = ['今天', '天气', '很好。', 'Flutter', '写的'];
    final cjkMemo = Memo(
      id: 'cjk1',
      cassetteId: 'c1',
      filePath: '/dev/null',
      durationMs: cjkWords.length * wordMs,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000000),
      status: MemoStatus.ready,
      transcript: Transcript(
        languageCode: 'zh-Hans',
        segments: [
          Segment(
            startMs: 0,
            endMs: cjkWords.length * wordMs,
            words: [
              for (var j = 0; j < cjkWords.length; j++)
                Word(
                    text: cjkWords[j],
                    startMs: j * wordMs,
                    endMs: (j + 1) * wordMs),
            ],
          ),
        ],
      ),
    );
    final cjkTape = Tape([cjkMemo]);
    final seeks = <int>[];

    Widget cjkApp() => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: TranscriptView(
              tape: cjkTape,
              colorSeed: 0,
              globalMs: 0,
              currentMemoIndex: 0,
              playing: false,
              onSeekGlobalMs: seeks.add,
            ),
          ),
        );

    testWidgets('spans join flush — no spaces inside CJK, one space at the '
        'code-switch boundary; the style carries the memo locale',
        (tester) async {
      await tester.pumpWidget(cjkApp());
      await tester.pump();
      final paragraph = find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().startsWith('今天'));
      expect(paragraph, findsOneWidget);
      final rich = tester.widget<RichText>(paragraph);
      expect(rich.text.toPlainText(), '今天天气很好。 Flutter 写的');
      expect(rich.text.style?.locale,
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
    });

    testWidgets('tapping a narrow CJK word seeks to its start '
        '(geometry mirrors the flush offsets)', (tester) async {
      seeks.clear();
      await tester.pumpWidget(cjkApp());
      await tester.pump();
      final paragraph = find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().startsWith('今天'));
      final render = tester.renderObject<RenderParagraph>(paragraph);
      // '天气' sits at plain-text offset 2..4 — flush against its
      // neighbours, exactly as wordGeometryAt computes it.
      final boxes = render.getBoxesForSelection(
          const TextSelection(baseOffset: 2, extentOffset: 4));
      expect(boxes, isNotEmpty);
      final target = boxes.first
          .toRect()
          .shift(render.localToGlobal(Offset.zero))
          .center;
      await tester.tapAt(target);
      expect(seeks, [wordMs],
          reason: '天气 starts at 500 ms into the (only) memo');
    });
  });
}
