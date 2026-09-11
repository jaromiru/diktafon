import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show RenderAbstractViewport, RenderParagraph;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../domain/palette.dart';
import '../../domain/script.dart';
import '../../domain/tape.dart';
import '../../l10n/l10n.dart';
import '../theme/tape_colors.dart';
import 'content_locale.dart';

/// The transcript of the whole tape (§5.3): memo boundaries as light dashed
/// dividers carrying "Memo N — date time" and the memo's gist; every word is
/// tappable to seek (§4.2); the word under the playhead carries a calm amber
/// wash (§10.3). Untranscribed regions show status instead of text.
class TranscriptView extends StatefulWidget {
  const TranscriptView({
    super.key,
    required this.tape,
    required this.colorSeed,
    required this.globalMs,
    required this.currentMemoIndex,
    required this.playing,
    this.seekCount = 0,
    this.modelReady = false,
    this.onSeekGlobalMs,
    this.onRetryMemo,
    this.onEditMemo,
    this.onDeleteMemo,
  });

  final Tape tape;
  final int colorSeed;
  final int globalMs;
  final int currentMemoIndex;
  final bool playing;

  /// Bumps on every user seek (scrub, word tap, memo jump, ±15 s): the view
  /// scrolls so the highlighted word stays visible with some context (§5.3),
  /// while plain playback ticks never yank the scroll position.
  final int seekCount;

  /// Whether the transcription model is provisioned — decides what a
  /// still-untranscribed memo says while it waits (§14).
  final bool modelReady;
  final ValueChanged<int>? onSeekGlobalMs;

  /// Failed memo tapped → re-enqueue (§14 retry affordance).
  final ValueChanged<String>? onRetryMemo;

  /// Manual correction from the divider's memo menu, by ordinal index
  /// (§6.9) — offered for any memo that already has a transcript, even an
  /// empty "no speech" one (quiet speech the engine missed can be typed in).
  final ValueChanged<int>? onEditMemo;

  /// Delete from the divider's memo menu, by ordinal index — same confirm
  /// flow as the timeline's long-press (§5.3).
  final ValueChanged<int>? onDeleteMemo;

  @override
  State<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<TranscriptView> {
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _memoKeys = {};
  final Map<String, GlobalKey<_MemoParagraphState>> _paragraphKeys = {};

  /// Invalidates queued follow passes once a newer seek supersedes them.
  int _followGeneration = 0;

  @override
  void didUpdateWidget(TranscriptView old) {
    super.didUpdateWidget(old);
    if (old.seekCount != widget.seekCount) {
      // The user navigated: keep the highlighted word in view.
      _scheduleFollowPlayhead();
    } else if (widget.playing &&
        old.currentMemoIndex != widget.currentMemoIndex) {
      // Orientation (§10.1): follow the tape into the current memo.
      _revealCurrentMemo();
    }
  }

  void _revealCurrentMemo() {
    if (widget.tape.isEmpty) return;
    final memo = widget.tape.memos[widget.currentMemoIndex];
    final targetContext = _memoKeys[memo.id]?.currentContext;
    if (targetContext == null) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Scrollable.ensureVisible(
      targetContext,
      alignment: 0.2,
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  /// The paragraphs restyle the highlight during this frame's rebuild —
  /// measure only after they have laid out.
  void _scheduleFollowPlayhead() {
    final generation = ++_followGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _followGeneration) {
        _followPlayhead(generation);
      }
    });
  }

  /// Scrolls just enough that the word under the playhead sits at least a
  /// context margin away from both viewport edges; already-comfortable
  /// positions don't move at all, so fine scrubs read as a steady page.
  void _followPlayhead(int generation, {int attempt = 0}) {
    if (widget.tape.isEmpty || !_scrollController.hasClients) return;
    final target = widget.tape.locate(widget.globalMs);
    final memo = widget.tape.memos[target.memoIndex];
    final geometry =
        _paragraphKeys[memo.id]?.currentState?.wordGeometryAt(target.localMs);
    if (geometry == null) {
      _followFallback(generation, memo, attempt);
      return;
    }
    final (render, wordRect) = geometry;
    final viewport = RenderAbstractViewport.maybeOf(render);
    if (viewport == null) return;
    final position = _scrollController.position;
    final margin = math.min(88.0, position.viewportDimension * 0.25);
    // Scroll offsets that park the word on the top/bottom viewport edge
    // bound the comfortable window (word ≥ margin from either edge).
    final atTop = viewport.getOffsetToReveal(render, 0, rect: wordRect).offset;
    final atBottom =
        viewport.getOffsetToReveal(render, 1, rect: wordRect).offset;
    var lower = atBottom + margin;
    var upper = atTop - margin;
    if (lower > upper) lower = upper = (lower + upper) / 2;
    final targetOffset = position.pixels
        .clamp(lower, upper)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((targetOffset - position.pixels).abs() < 1) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      position.jumpTo(targetOffset);
    } else {
      position.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// No measurable word at the playhead: a memo without words (yet) is
  /// oriented by its stamp; a memo the ListView hasn't built (virtualized
  /// far off-screen) gets a proportional hop so it builds, then a precise
  /// pass next frame.
  void _followFallback(int generation, Memo memo, int attempt) {
    final memoContext = _memoKeys[memo.id]?.currentContext;
    if (memoContext != null) {
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      Scrollable.ensureVisible(
        memoContext,
        alignment: 0.2,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    final position = _scrollController.position;
    final total = widget.tape.totalDurationMs;
    if (attempt >= 3 || total <= 0 || position.maxScrollExtent <= 0) return;
    position.jumpTo((position.maxScrollExtent * widget.globalMs / total)
        .clamp(0.0, position.maxScrollExtent));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _followGeneration) {
        _followPlayhead(generation, attempt: attempt + 1);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tape = widget.tape;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: tape.memoCount,
      itemBuilder: (context, i) {
        final memo = tape.memos[i];
        final key = _memoKeys.putIfAbsent(memo.id, GlobalKey.new);
        // Each memo repaints independently: the moving word highlight in
        // one paragraph must not repaint the rest of the list.
        return RepaintBoundary(
          key: key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MemoDivider(
                memo: memo,
                ordinal: i + 1,
                hue: context.tape.hues[memoHueIndex(widget.colorSeed, i)],
                first: i == 0,
                onRetry: widget.onRetryMemo == null
                    ? null
                    : () => widget.onRetryMemo!(memo.id),
                onCopy: memo.transcript?.isEmpty == false
                    ? () => _copyTranscript(memo)
                    : null,
                onEdit: widget.onEditMemo == null || memo.transcript == null
                    ? null
                    : () => widget.onEditMemo!(i),
                onDelete: widget.onDeleteMemo == null
                    ? null
                    : () => widget.onDeleteMemo!(i),
              ),
              _memoBody(context, memo, i),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  /// The memo's words land on the clipboard as plain text (long-press on
  /// the paragraph, or the divider menu).
  Future<void> _copyTranscript(Memo memo) async {
    final text = memo.transcript?.plainText ?? '';
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.transcriptCopied)));
  }

  Widget _memoBody(BuildContext context, Memo memo, int index) {
    final transcript = memo.transcript;
    if (transcript != null) {
      if (transcript.isEmpty) {
        return _caption(context, context.l10n.noSpeech);
      }
      return _MemoParagraph(
        key: _paragraphKeys.putIfAbsent(
            memo.id, GlobalKey<_MemoParagraphState>.new),
        memo: memo,
        memoIndex: index,
        tape: widget.tape,
        globalMs: widget.globalMs,
        onSeekGlobalMs: widget.onSeekGlobalMs,
        onCopy: () => _copyTranscript(memo),
      );
    }
    return switch (memo.status) {
      MemoStatus.transcribing => const _ShimmerRows(),
      MemoStatus.failed => _caption(
          context,
          context.l10n.transcriptionFailedRetry,
          onTap: widget.onRetryMemo == null
              ? null
              : () => widget.onRetryMemo!(memo.id),
        ),
      // §14 "model missing/unavailable": captured, playable, queued —
      // enrichment starts the moment the model is provisioned.
      _ => _caption(
          context,
          widget.modelReady
              ? context.l10n.queuedForTranscription
              : context.l10n.waitingForModel,
        ),
    };
  }

  Widget _caption(BuildContext context, String text, {VoidCallback? onTap}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: context.tape.ink2,
              decoration: onTap == null ? null : TextDecoration.underline,
              decorationColor: context.tape.ink2,
            ),
          ),
        ),
      );
}

class _MemoDivider extends StatelessWidget {
  const _MemoDivider({
    required this.memo,
    required this.ordinal,
    required this.hue,
    required this.first,
    this.onRetry,
    this.onCopy,
    this.onEdit,
    this.onDelete,
  });

  final Memo memo;
  final int ordinal;
  final Color hue;
  final bool first;
  final VoidCallback? onRetry;

  /// The quiet per-memo menu at the stamp's right edge; entries appear only
  /// when their action is possible (copy needs words on the clipboard's
  /// side, edit an existing transcript, delete a wired-up confirm flow).
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// The gist line under the stamp (§5.3): the memo summary once it exists,
  /// a quiet progress note while the LLM works, a retry affordance when
  /// summarization permanently failed (§14). Null → no second line.
  (String, VoidCallback?)? _caption(BuildContext context) {
    if (memo.memoSummary != null) return (memo.memoSummary!, null);
    if (memo.status == MemoStatus.summarizing) {
      return (context.l10n.summarizing, null);
    }
    if (memo.status == MemoStatus.failed && memo.transcript != null) {
      return (context.l10n.summaryFailedRetry, onRetry);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    final locale = Localizations.localeOf(context).toString();
    final stamp =
        DateFormat('dd. MM. yyyy HH:mm', locale).format(memo.createdAt);
    final caption = _caption(context);
    return Container(
      margin: EdgeInsets.only(top: first ? 0 : 13, bottom: 11),
      padding: const EdgeInsets.only(top: 10),
      decoration: first
          ? null
          : BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: tape.line,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 10, height: 10, color: hue,
              margin: const EdgeInsetsDirectional.only(top: 2, end: 9)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.memoDivider(ordinal, stamp),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: tape.ink,
                  ),
                ),
                if (caption != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: GestureDetector(
                      onTap: caption.$2,
                      child: Text(
                        caption.$1,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: tape.ink2,
                          decoration: caption.$2 == null
                              ? null
                              : TextDecoration.underline,
                          decorationColor: tape.ink2,
                          // The gist is content in the memo's language;
                          // progress/retry notes are UI chrome.
                          locale: caption.$1 == memo.memoSummary
                              ? contentLocale(memo.detectedLang)
                              : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onCopy != null || onEdit != null || onDelete != null)
            _menu(context),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context) => SizedBox(
        width: 26,
        height: 18,
        child: PopupMenuButton<String>(
          tooltip: context.l10n.memoActions,
          padding: EdgeInsets.zero,
          icon: Icon(Icons.more_horiz, size: 16, color: context.tape.ink2),
          onSelected: (action) => switch (action) {
            'copy' => onCopy!(),
            'edit' => onEdit!(),
            _ => onDelete!(),
          },
          itemBuilder: (menuContext) => [
            if (onCopy != null)
              PopupMenuItem(
                value: 'copy',
                height: 38,
                child: Text(menuContext.l10n.copyTranscript,
                    style: const TextStyle(fontSize: 12.5)),
              ),
            if (onEdit != null)
              PopupMenuItem(
                value: 'edit',
                height: 38,
                child: Text(menuContext.l10n.editTranscript,
                    style: const TextStyle(fontSize: 12.5)),
              ),
            if (onDelete != null)
              PopupMenuItem(
                value: 'delete',
                height: 38,
                child: Text(menuContext.l10n.deleteMemo,
                    style: const TextStyle(fontSize: 12.5)),
              ),
          ],
        ),
      );
}

/// One memo's words as tappable spans with the current word highlighted;
/// a long-press anywhere in the paragraph copies the memo's transcription.
class _MemoParagraph extends StatefulWidget {
  const _MemoParagraph({
    super.key,
    required this.memo,
    required this.memoIndex,
    required this.tape,
    required this.globalMs,
    required this.onSeekGlobalMs,
    required this.onCopy,
  });

  final Memo memo;
  final int memoIndex;
  final Tape tape;
  final int globalMs;
  final ValueChanged<int>? onSeekGlobalMs;
  final VoidCallback onCopy;

  @override
  State<_MemoParagraph> createState() => _MemoParagraphState();
}

class _MemoParagraphState extends State<_MemoParagraph> {
  final _textKey = GlobalKey();

  /// Global [start, end) of each word on the tape and its plain-text char
  /// range, built once per word set — the highlight search runs on every
  /// playback tick and tap-to-seek hit-testing maps a tap to a word; both
  /// must not re-derive offsets per call.
  List<({int start, int end})> _wordGlobalMs = const [];
  List<({int start, int end})> _wordChars = const [];

  /// The word the amber wash sits on, painted by [_WordHighlightPainter]
  /// over the (static) text. A ValueNotifier so a highlight move repaints
  /// only the small overlay layer — styling the word through its TextSpan
  /// rebuilt every span and, with the old bold face, re-wrapped the whole
  /// paragraph on every word crossing (2×/s during playback, per paragraph
  /// — measurable heat on phones).
  final ValueNotifier<int> _highlight = ValueNotifier(-1);

  Brightness? _builtBrightness;
  Widget? _builtBody;

  @override
  void dispose() {
    _highlight.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_MemoParagraph old) {
    super.didUpdateWidget(old);
    if (!identical(old.memo.transcript, widget.memo.transcript) ||
        !identical(old.tape, widget.tape) ||
        old.memoIndex != widget.memoIndex) {
      _buildWords();
    }
  }

  /// Word ranges are per word set (memo identity × tape offsets): rebuilt
  /// on transcript edits, memo re-flow and index shifts, reused across the
  /// playback ticks in between. No per-word gesture recognizers — tapping
  /// is hit-tested at the paragraph level (see [_seekAtLocalOffset]);
  /// one recognizer object per word made scrolling a long transcript an
  /// allocation storm on phones (thousands of objects per paragraph every
  /// time it scrolled into the list's build cache).
  void _buildWords() {
    final words = _allWords;
    final tape = widget.tape;
    final memoIndex = widget.memoIndex;
    _wordGlobalMs = [
      for (final word in words)
        (
          start: tape.toGlobalMs(memoIndex, word.startMs),
          end: tape.toGlobalMs(memoIndex, word.endMs),
        )
    ];
    final chars = <({int start, int end})>[];
    var offset = 0;
    for (var i = 0; i < words.length; i++) {
      final text = words[i].text;
      chars.add((start: offset, end: offset + text.length));
      offset += text.length;
      if (i + 1 < words.length) {
        offset += wordSeparator(text, words[i + 1].text).length;
      }
    }
    _wordChars = chars;
    _highlight.value = -1;
    _builtBody = null;
  }

  List<Word> get _allWords => [
        for (final segment in widget.memo.transcript!.segments) ...segment.words
      ];

  /// Index of the word under [globalMs] (start ≤ ms < end), or -1 in gaps
  /// and when no word is live. Binary search: ticks arrive at 5–10 Hz.
  int _indexOfWordAt(int globalMs) {
    var lo = 0, hi = _wordGlobalMs.length - 1, result = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_wordGlobalMs[mid].start <= globalMs) {
        result = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    if (result >= 0 && globalMs < _wordGlobalMs[result].end) return result;
    return -1;
  }

  /// Tap-to-seek (§4.2): translate the tap's text position to a word and
  /// seek to its start. Taps between words resolve to the nearest word —
  /// the position the engine's own span hit-testing answered before.
  void _seekAtLocalOffset(Offset local) {
    final render = _textKey.currentContext?.findRenderObject();
    if (render is! RenderParagraph || !render.hasSize) return;
    final charOffset = render.getPositionForOffset(local).offset;
    if (charOffset < 0) return;
    var lo = 0, hi = _wordChars.length - 1, result = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_wordChars[mid].start <= charOffset) {
        result = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    if (result >= 0 && result < _wordGlobalMs.length) {
      widget.onSeekGlobalMs?.call(_wordGlobalMs[result].start);
    }
  }

  /// The paragraph's render object plus the local rect of the word under
  /// [localMs] — between words the upcoming word answers, past the last
  /// word the last one does. Null before layout or with no words at all.
  /// Character offsets mirror [build]: words separated by [wordSeparator]
  /// (a space, or nothing between CJK neighbours).
  (RenderParagraph, Rect)? wordGeometryAt(int localMs) {
    final render = _textKey.currentContext?.findRenderObject();
    if (render is! RenderParagraph || !render.hasSize) return null;
    var offset = 0;
    var start = -1, end = -1;
    var found = false;
    final words = [
      for (final segment in widget.memo.transcript!.segments) ...segment.words
    ];
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      if (!found) {
        start = offset;
        end = offset + word.text.length;
        found = word.endMs > localMs;
      }
      offset += word.text.length;
      if (i + 1 < words.length) {
        offset += wordSeparator(word.text, words[i + 1].text).length;
      }
    }
    if (start < 0) return null;
    final boxes = render.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end));
    if (boxes.isEmpty) return null;
    var rect = boxes.first.toRect();
    for (final box in boxes.skip(1)) {
      rect = rect.expandToInclude(box.toRect());
    }
    return (render, rect);
  }

  @override
  Widget build(BuildContext context) {
    if (_wordGlobalMs.isEmpty && _allWords.isNotEmpty) _buildWords();
    final highlight = _indexOfWordAt(widget.globalMs);
    if (_highlight.value != highlight) _highlight.value = highlight;
    final brightness = Theme.of(context).brightness;
    if (_builtBody != null && brightness == _builtBrightness) {
      return _builtBody!;
    }
    _builtBrightness = brightness;

    final tape = context.tape;
    final spans = <InlineSpan>[];
    final words = _allWords;
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      spans.add(TextSpan(text: word.text));
      if (i + 1 < words.length) {
        final separator = wordSeparator(word.text, words[i + 1].text);
        if (separator.isNotEmpty) spans.add(TextSpan(text: separator));
      }
    }
    _builtBody = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onLongPress: widget.onCopy,
        onTapUp: widget.onSeekGlobalMs == null
            ? null
            : (details) => _seekAtLocalOffset(details.localPosition),
        child: Stack(
          children: [
            // §10.3: the playhead's amber wash paints *behind* the static
            // text (the old span backgroundColor's z-order) — moving it
            // never relayouts (let alone re-wraps) the paragraph.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _WordHighlightPainter(
                    words: _highlightBoxes,
                    color: tape.highlight,
                    index: _highlight,
                  ),
                ),
              ),
            ),
            Text.rich(
              key: _textKey,
              TextSpan(children: spans),
              style: TextStyle(
                fontSize: 12.5,
                height: 1.75,
                color: tape.ink,
                // Han unification: kanji vs hanzi glyph variants follow the
                // memo's language, not the app locale.
                locale: contentLocale(widget.memo.transcript!.languageCode),
              ),
            ),
          ],
        ),
      ),
    );
    return _builtBody!;
  }

  /// Glyph-run boxes of word [index] in paragraph coordinates — null before
  /// layout or when the paragraph is gone.
  List<TextBox>? _highlightBoxes(int index) {
    if (index < 0 || index >= _wordChars.length) return null;
    final render = _textKey.currentContext?.findRenderObject();
    if (render is! RenderParagraph || !render.hasSize) return null;
    final range = _wordChars[index];
    return render.getBoxesForSelection(TextSelection(
      baseOffset: range.start,
      extentOffset: range.end,
    ));
  }
}

/// Draws the current word's wash ([_MemoParagraphState._highlight] drives
/// repaints); the text beneath is never touched.
class _WordHighlightPainter extends CustomPainter {
  _WordHighlightPainter({
    required this.words,
    required this.color,
    required this.index,
  }) : super(repaint: index);

  final List<TextBox>? Function(int index) words;
  final Color color;
  final ValueNotifier<int> index;

  @override
  void paint(Canvas canvas, Size size) {
    final boxes = words(index.value);
    if (boxes == null) return;
    final paint = Paint()..color = color;
    for (final box in boxes) {
      canvas.drawRect(box.toRect(), paint);
    }
  }

  @override
  bool shouldRepaint(_WordHighlightPainter old) => false;
}

/// Gentle "transcribing…" placeholder (§5.3) — three sliding-sheen rows.
class _ShimmerRows extends StatefulWidget {
  const _ShimmerRows();

  @override
  State<_ShimmerRows> createState() => _ShimmerRowsState();
}

class _ShimmerRowsState extends State<_ShimmerRows>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    // §13: the sheen is decoration; a screen reader hears the status.
    return Semantics(
      label: context.l10n.transcribing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final width in const [0.88, 0.72, 0.81])
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Container(
                height: 11,
                margin: const EdgeInsets.symmetric(vertical: 4.5),
                width: width * 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tape.line, tape.highlight, tape.line],
                    stops: const [0.3, 0.5, 0.7],
                    begin: Alignment(-2 + 4 * _controller.value, 0),
                    end: Alignment(-1 + 4 * _controller.value, 0),
                    tileMode: TileMode.clamp,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
