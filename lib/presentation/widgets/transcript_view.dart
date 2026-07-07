import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../domain/palette.dart';
import '../../domain/tape.dart';
import '../theme/tape_colors.dart';

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
    this.modelReady = false,
    this.onSeekGlobalMs,
    this.onRetryMemo,
  });

  final Tape tape;
  final int colorSeed;
  final int globalMs;
  final int currentMemoIndex;
  final bool playing;

  /// Whether the transcription model is provisioned — decides what a
  /// still-untranscribed memo says while it waits (§14).
  final bool modelReady;
  final ValueChanged<int>? onSeekGlobalMs;

  /// Failed memo tapped → re-enqueue (§14 retry affordance).
  final ValueChanged<String>? onRetryMemo;

  @override
  State<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<TranscriptView> {
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _memoKeys = {};

  @override
  void didUpdateWidget(TranscriptView old) {
    super.didUpdateWidget(old);
    // Orientation (§10.1): follow the tape into the current memo.
    if (widget.playing && old.currentMemoIndex != widget.currentMemoIndex) {
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
        return Column(
          key: key,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MemoDivider(
              memo: memo,
              ordinal: i + 1,
              hue: context.tape.hues[memoHueIndex(widget.colorSeed, i)],
              first: i == 0,
            ),
            _memoBody(context, memo, i),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  Widget _memoBody(BuildContext context, Memo memo, int index) {
    final transcript = memo.transcript;
    if (transcript != null) {
      if (transcript.isEmpty) {
        return _caption(context, '(no speech)');
      }
      return _MemoParagraph(
        memo: memo,
        memoIndex: index,
        tape: widget.tape,
        globalMs: widget.globalMs,
        onSeekGlobalMs: widget.onSeekGlobalMs,
      );
    }
    return switch (memo.status) {
      MemoStatus.transcribing => const _ShimmerRows(),
      MemoStatus.failed => _caption(
          context,
          'transcription failed — tap to retry (the audio still plays)',
          onTap: widget.onRetryMemo == null
              ? null
              : () => widget.onRetryMemo!(memo.id),
        ),
      // §14 "model missing/unavailable": captured, playable, queued —
      // enrichment starts the moment the model is provisioned.
      _ => _caption(
          context,
          widget.modelReady
              ? 'queued for transcription…'
              : 'waiting for the transcription model — '
                  'download it in Settings',
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
  });

  final Memo memo;
  final int ordinal;
  final Color hue;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    final stamp = DateFormat('dd. MM. yyyy HH:mm').format(memo.createdAt);
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
              margin: const EdgeInsets.only(top: 2, right: 9)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Memo $ordinal — $stamp',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: tape.ink,
                  ),
                ),
                if (memo.memoSummary != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      memo.memoSummary!,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: tape.ink2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One memo's words as tappable spans with the current word highlighted.
class _MemoParagraph extends StatefulWidget {
  const _MemoParagraph({
    required this.memo,
    required this.memoIndex,
    required this.tape,
    required this.globalMs,
    required this.onSeekGlobalMs,
  });

  final Memo memo;
  final int memoIndex;
  final Tape tape;
  final int globalMs;
  final ValueChanged<int>? onSeekGlobalMs;

  @override
  State<_MemoParagraph> createState() => _MemoParagraphState();
}

class _MemoParagraphState extends State<_MemoParagraph> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final tape = context.tape;
    final spans = <InlineSpan>[];
    for (final segment in widget.memo.transcript!.segments) {
      for (final word in segment.words) {
        final wordGlobalStart =
            widget.tape.toGlobalMs(widget.memoIndex, word.startMs);
        final wordGlobalEnd =
            widget.tape.toGlobalMs(widget.memoIndex, word.endMs);
        final isCurrent = widget.globalMs >= wordGlobalStart &&
            widget.globalMs < wordGlobalEnd;
        final recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onSeekGlobalMs?.call(wordGlobalStart);
        _recognizers.add(recognizer);
        spans.add(TextSpan(
          text: word.text,
          recognizer: recognizer,
          style: isCurrent
              ? TextStyle(
                  backgroundColor: tape.highlight,
                  fontWeight: FontWeight.w700,
                )
              : null,
        ));
        spans.add(const TextSpan(text: ' '));
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        TextSpan(children: spans),
        style: TextStyle(fontSize: 12.5, height: 1.75, color: tape.ink),
      ),
    );
  }
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
    return Column(
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
    );
  }
}
