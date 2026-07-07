import 'package:flutter/material.dart';

import '../../domain/palette.dart';
import '../../domain/tape.dart';
import '../theme/tape_colors.dart';

/// The timeline — the hero of the cassette view (D11, mockup 03): one clean
/// bar of per-memo colored segments with 2 px boundary gaps, an ink playhead,
/// and a pulsing red tail while recording.
///
/// Drag scrubs, tap jumps to a memo's start, long-press deletes (§5.3).
class TimelineBar extends StatefulWidget {
  const TimelineBar({
    super.key,
    required this.tape,
    required this.colorSeed,
    required this.globalMs,
    this.recordingElapsed,
    this.onScrub,
    this.onJumpToMemo,
    this.onDeleteMemo,
  });

  final Tape tape;
  final int colorSeed;
  final int globalMs;

  /// Non-null while recording: the red tail grows with elapsed time (D6).
  final Duration? recordingElapsed;

  final ValueChanged<int>? onScrub;
  final ValueChanged<int>? onJumpToMemo;
  final ValueChanged<int>? onDeleteMemo;

  @override
  State<TimelineBar> createState() => _TimelineBarState();
}

class _TimelineBarState extends State<TimelineBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didUpdateWidget(TimelineBar old) {
    super.didUpdateWidget(old);
    _syncPulse();
  }

  @override
  void didChangeDependencies() {
    // MediaQuery isn't available in initState; this runs right after.
    super.didChangeDependencies();
    _syncPulse();
  }

  void _syncPulse() {
    final recording = widget.recordingElapsed != null;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (recording && !reduceMotion && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!recording && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Recording tail: elapsed time rendered at the same ms-per-pixel scale as
  /// the rest of the tape, with a visible minimum.
  int get _tailMs => widget.recordingElapsed?.inMilliseconds ?? 0;

  int _totalWithTailMs() {
    final tail = _tailMs;
    final total = widget.tape.totalDurationMs + tail;
    return total == 0 ? 1 : total;
  }

  double _fractionAt(Offset local, double width) =>
      (local.dx / width).clamp(0.0, 1.0);

  int? _memoIndexAt(double fraction) {
    if (widget.tape.isEmpty) return null;
    final tapeFraction =
        widget.tape.totalDurationMs / _totalWithTailMs();
    if (fraction >= tapeFraction && _tailMs > 0) return null; // in the tail
    final globalMs =
        (fraction / (tapeFraction == 0 ? 1 : tapeFraction).clamp(1e-9, 1.0) *
                widget.tape.totalDurationMs)
            .round();
    return widget.tape.locate(globalMs).memoIndex;
  }

  int _globalMsAt(double fraction) =>
      (fraction * _totalWithTailMs()).round().clamp(0, widget.tape.totalDurationMs);

  @override
  Widget build(BuildContext context) {
    final interactive = widget.recordingElapsed == null && !widget.tape.isEmpty;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: interactive
            ? (d) {
                final index = _memoIndexAt(_fractionAt(d.localPosition, width));
                if (index != null) widget.onJumpToMemo?.call(index);
              }
            : null,
        onHorizontalDragUpdate: interactive
            ? (d) => widget.onScrub
                ?.call(_globalMsAt(_fractionAt(d.localPosition, width)))
            : null,
        onLongPressStart: interactive
            ? (d) {
                final index = _memoIndexAt(_fractionAt(d.localPosition, width));
                if (index != null) widget.onDeleteMemo?.call(index);
              }
            : null,
        child: Padding(
          // Breathing room so the playhead cap and hit target fit.
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 26,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => CustomPaint(
                painter: _TimelinePainter(
                  colors: context.tape,
                  tape: widget.tape,
                  colorSeed: widget.colorSeed,
                  globalMs: widget.globalMs,
                  tailMs: _tailMs,
                  // CSS pulse: opacity dips to .45 mid-cycle.
                  tailOpacity: 1 - 0.55 * _pulseWave(_pulse.value),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  static double _pulseWave(double t) =>
      t < 0.5 ? t * 2 : (1 - t) * 2;
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.colors,
    required this.tape,
    required this.colorSeed,
    required this.globalMs,
    required this.tailMs,
    required this.tailOpacity,
  });

  final TapeColors colors;
  final Tape tape;
  final int colorSeed;
  final int globalMs;
  final int tailMs;
  final double tailOpacity;

  static const _barHeight = 14.0;
  static const _gap = 2.0;
  static const _minTailPx = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final barTop = (size.height - _barHeight) / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    final totalMs = tape.totalDurationMs + tailMs;
    if (totalMs == 0) {
      // Empty tape: a quiet line-colored slot.
      paint.color = colors.line;
      canvas.drawRect(
          Rect.fromLTWH(0, barTop, size.width, _barHeight), paint);
      return;
    }

    final segmentCount = tape.memoCount + (tailMs > 0 ? 1 : 0);
    final gaps = (segmentCount - 1).clamp(0, 1 << 30) * _gap;
    var tailPx = tailMs > 0
        ? (tailMs / totalMs * (size.width - gaps)).clamp(_minTailPx, size.width - gaps)
        : 0.0;
    final tapePx = size.width - gaps - tailPx;

    var x = 0.0;
    for (var i = 0; i < tape.memoCount; i++) {
      final w = tape.totalDurationMs == 0
          ? 0.0
          : tape.memos[i].durationMs / tape.totalDurationMs * tapePx;
      paint.color = colors.hues[memoHueIndex(colorSeed, i)];
      canvas.drawRect(Rect.fromLTWH(x, barTop, w, _barHeight), paint);
      x += w + _gap;
    }

    if (tailMs > 0) {
      paint.color = colors.rec.withValues(alpha: tailOpacity);
      canvas.drawRect(Rect.fromLTWH(x, barTop, tailPx, _barHeight), paint);
    } else if (!tape.isEmpty) {
      // Playhead: 2 px ink line overshooting the bar, square cap on top.
      final fraction =
          (globalMs / tape.totalDurationMs).clamp(0.0, 1.0);
      final px = fraction * tapePx +
          tape.locate(globalMs).memoIndex * _gap;
      paint.color = colors.ink;
      canvas.drawRect(
          Rect.fromLTWH(px - 1, barTop - 6, 2, _barHeight + 12), paint);
      canvas.drawRect(Rect.fromLTWH(px - 4.5, barTop - 12, 9, 9), paint);
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.colors != colors ||
      old.tape != tape ||
      old.colorSeed != colorSeed ||
      old.globalMs != globalMs ||
      old.tailMs != tailMs ||
      old.tailOpacity != tailOpacity;
}
