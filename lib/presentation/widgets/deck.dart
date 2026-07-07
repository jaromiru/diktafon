import 'package:flutter/material.dart';

import '../theme/tape_colors.dart';

/// Tape-deck transport keys (§5.3, mockup 03): squared keys with 2 px ink
/// borders and offset cardstock shadows. Red is reserved for record.
enum DeckGlyph { rewind, play, pause, fastForward, record, stop, plus }

enum DeckKeyStyle { paper, ink, record }

class DeckKey extends StatelessWidget {
  const DeckKey({
    super.key,
    required this.glyph,
    required this.onPressed,
    this.style = DeckKeyStyle.paper,
    this.width = 54,
    this.height = 46,
    this.shadowOffset = 3,
    required this.semanticLabel,
  });

  final DeckGlyph glyph;
  final VoidCallback? onPressed;
  final DeckKeyStyle style;
  final double width;
  final double height;
  final double shadowOffset;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    final (background, foreground) = switch (style) {
      DeckKeyStyle.paper => (tape.paper, tape.ink),
      DeckKeyStyle.ink => (tape.ink, tape.paper),
      DeckKeyStyle.record => (tape.rec, Colors.white),
    };
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: tape.ink, width: 2),
            boxShadow: [
              BoxShadow(
                color: tape.line,
                offset: Offset(shadowOffset, shadowOffset),
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(22, 18),
              painter: _GlyphPainter(glyph: glyph, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square-cut transport glyphs matching the mockup SVGs.
class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.glyph, required this.color});

  final DeckGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final c = Offset(size.width / 2, size.height / 2);

    switch (glyph) {
      case DeckGlyph.rewind:
        _triangle(canvas, fill, Offset(c.dx + 1, c.dy), 10, left: true);
        _triangle(canvas, fill, Offset(c.dx - 9, c.dy), 10, left: true);
      case DeckGlyph.fastForward:
        _triangle(canvas, fill, Offset(c.dx - 11, c.dy), 10, left: false);
        _triangle(canvas, fill, Offset(c.dx - 1, c.dy), 10, left: false);
      case DeckGlyph.play:
        _triangle(canvas, fill, Offset(c.dx - 5, c.dy), 12, left: false);
      case DeckGlyph.pause:
        canvas.drawRect(
            Rect.fromLTWH(c.dx - 7, c.dy - 8, 4.4, 16), fill);
        canvas.drawRect(
            Rect.fromLTWH(c.dx + 2.6, c.dy - 8, 4.4, 16), fill);
      case DeckGlyph.record:
        // Microphone: capsule body, pickup arc, stem.
        canvas.drawRect(Rect.fromLTWH(c.dx - 3, c.dy - 9, 6, 11), fill);
        canvas.drawArc(Rect.fromCircle(center: Offset(c.dx, c.dy - 1), radius: 6),
            0, 3.14159, false, stroke);
        canvas.drawRect(Rect.fromLTWH(c.dx - 1, c.dy + 5, 2, 4), fill);
      case DeckGlyph.stop:
        canvas.drawRect(
            Rect.fromCenter(center: c, width: 20, height: 20), fill);
      case DeckGlyph.plus:
        canvas.drawRect(Rect.fromLTWH(c.dx - 1, c.dy - 9, 2, 18), fill);
        canvas.drawRect(Rect.fromLTWH(c.dx - 9, c.dy - 1, 18, 2), fill);
    }
  }

  void _triangle(Canvas canvas, Paint paint, Offset tipBase, double h,
      {required bool left}) {
    final path = Path();
    if (left) {
      path
        ..moveTo(tipBase.dx - h, tipBase.dy)
        ..lineTo(tipBase.dx, tipBase.dy - h / 2 - 1)
        ..lineTo(tipBase.dx, tipBase.dy + h / 2 + 1);
    } else {
      path
        ..moveTo(tipBase.dx + h, tipBase.dy)
        ..lineTo(tipBase.dx, tipBase.dy - h / 2 - 1)
        ..lineTo(tipBase.dx, tipBase.dy + h / 2 + 1);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}
