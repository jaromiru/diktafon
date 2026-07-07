import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/repositories/cassette_repository.dart';
import '../../domain/palette.dart';
import '../theme/tape_colors.dart';
import '../theme/theme.dart';

/// A cassette drawn as a physical tape (§5.2), replicating the approved
/// mockup SVG (viewBox 157×92): shell, screws, label with accent stripe,
/// window with two reels — the left reel grows with recorded time.
class CassetteCard extends StatelessWidget {
  const CassetteCard({
    super.key,
    required this.overview,
    this.onTap,
    this.onLongPress,
  });

  final CassetteOverview overview;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final cassette = overview.cassette;
    final label = cassette.label;
    return Semantics(
      button: true,
      label:
          '${label ?? 'Untitled cassette'}, ${overview.memoCount} memos',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AspectRatio(
          aspectRatio: 157 / 92,
          child: CustomPaint(
            painter: _CassettePainter(
              colors: context.tape,
              name: label,
              meta: _metaLine(),
              stripeHue: cassette.titleIsUserSet || label != null
                  ? cassetteHueIndex(cassette.colorSeed)
                  : null,
              fullness: _fullness(),
            ),
          ),
        ),
      ),
    );
  }

  String _metaLine() {
    final count = overview.memoCount;
    final memoPart = count == 1 ? '1 memo' : '$count memos';
    if (count == 0) return 'empty · press to open';
    if (overview.cassette.label == null) {
      return '$memoPart · naming itself…';
    }
    return '$memoPart · ${relativeDate(overview.cassette.updatedAt)}';
  }

  /// 0..1 → left reel radius; a glanceable fullness cue (§5.2). Saturates
  /// at one hour of tape.
  double _fullness() =>
      (overview.totalDurationMs / Duration.millisecondsPerHour).clamp(0.0, 1.0);
}

/// "today 14:02" / "yesterday" / "28 Jun" — the grid meta format (mockup 02).
String relativeDate(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  if (day == today) return 'today ${DateFormat.Hm().format(t)}';
  if (day == today.subtract(const Duration(days: 1))) return 'yesterday';
  if (t.year == now.year) return DateFormat('d MMM').format(t);
  return DateFormat('d MMM yyyy').format(t);
}

class _CassettePainter extends CustomPainter {
  _CassettePainter({
    required this.colors,
    required this.name,
    required this.meta,
    required this.stripeHue,
    required this.fullness,
  });

  final TapeColors colors;
  final String? name;
  final String meta;

  /// Null → placeholder cassette (stripe in line color, italic name).
  final int? stripeHue;
  final double fullness;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 157.0;
    canvas.scale(s, s);

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()..style = PaintingStyle.stroke;

    // Shell.
    fill.color = colors.shell;
    stroke
      ..color = colors.ink
      ..strokeWidth = 2;
    final shell = const Rect.fromLTWH(1.5, 1.5, 154, 89);
    canvas.drawRect(shell, fill);
    canvas.drawRect(shell, stroke);

    // Screws.
    stroke
      ..color = colors.ink2
      ..strokeWidth = 1;
    for (final c in const [
      Offset(8, 8),
      Offset(149, 8),
      Offset(8, 84),
      Offset(149, 84),
    ]) {
      canvas.drawCircle(c, 1.8, stroke);
    }

    // Label card + accent stripe.
    fill.color = colors.surface;
    stroke
      ..color = colors.ink
      ..strokeWidth = 1.2;
    const label = Rect.fromLTWH(14, 9, 129, 42);
    canvas.drawRect(label, fill);
    canvas.drawRect(label, stroke);
    fill.color = stripeHue == null ? colors.line : colors.hues[stripeHue!];
    canvas.drawRect(const Rect.fromLTWH(15, 10, 127, 7), fill);

    // Name + meta.
    if (name != null) {
      _text(canvas, name!, 36,
          style: TextStyle(
              fontFamily: displayFont, fontSize: 15, color: colors.ink));
    } else {
      _text(canvas, 'Untitled cassette', 33,
          style: TextStyle(
              fontFamily: bodyFont,
              fontSize: 8,
              fontStyle: FontStyle.italic,
              color: colors.ink2));
    }
    _text(canvas, meta, 47,
        style: TextStyle(
            fontFamily: bodyFont, fontSize: 7, color: colors.ink2));

    // Window with reels.
    fill.color = colors.window;
    stroke
      ..color = colors.ink
      ..strokeWidth = 1.2;
    final window = RRect.fromRectAndRadius(
        const Rect.fromLTWH(40, 57, 77, 22), const Radius.circular(11));
    canvas.drawRRect(window, fill);
    canvas.drawRRect(window, stroke);

    // Reels: the left one grows with recorded time (§5.2).
    final leftR = 7.5 + 3.5 * fullness;
    fill.color = colors.reel;
    canvas.drawCircle(const Offset(59, 68), leftR, fill);
    canvas.drawCircle(const Offset(98, 68), 7.5, fill);

    // Hubs + teeth.
    fill.color = colors.paper;
    stroke
      ..color = colors.ink
      ..strokeWidth = 1.2;
    for (final c in const [Offset(59, 68), Offset(98, 68)]) {
      canvas.drawCircle(c, 6.5, fill);
      canvas.drawCircle(c, 6.5, stroke);
    }
    stroke.strokeWidth = 2;
    for (final c in const [Offset(59, 68), Offset(98, 68)]) {
      _dashedCircle(canvas, c, 4, stroke);
    }

    // Base trapezoid + holes.
    stroke
      ..color = colors.ink2
      ..strokeWidth = 1;
    final trap = Path()
      ..moveTo(46, 90)
      ..lineTo(55, 79)
      ..lineTo(102, 79)
      ..lineTo(111, 90);
    canvas.drawPath(trap, stroke);
    canvas.drawCircle(const Offset(66, 86), 1.7, stroke);
    canvas.drawCircle(const Offset(91, 86), 1.7, stroke);
  }

  void _text(Canvas canvas, String text, double baselineY,
      {required TextStyle style}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 123);
    // SVG text y is the baseline; TextPainter positions by top.
    final base = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    painter.paint(
        canvas, Offset(78.5 - painter.width / 2, baselineY - base));
  }

  void _dashedCircle(Canvas canvas, Offset center, double r, Paint paint) {
    const dash = 2.0, gap = 3.0;
    final path = Path()..addOval(Rect.fromCircle(center: center, radius: r));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_CassettePainter old) =>
      old.colors != colors ||
      old.name != name ||
      old.meta != meta ||
      old.stripeHue != stripeHue ||
      old.fullness != fullness;
}
