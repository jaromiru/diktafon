import 'package:flutter/material.dart';

import '../theme/tape_colors.dart';

/// Retro determinate progress: an ink-bordered channel filling left→right.
/// Custom-painted — fractional-width widgets have no finite intrinsic width
/// at 0 %, which crashes inside SimpleDialog's IntrinsicWidth.
class InkProgressBar extends StatelessWidget {
  const InkProgressBar({super.key, required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 10,
        child: CustomPaint(
          painter: _InkProgressPainter(
              fraction.clamp(0.0, 1.0), context.tape.ink),
        ),
      );
}

class _InkProgressPainter extends CustomPainter {
  const _InkProgressPainter(this.fraction, this.ink);

  final double fraction;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = ink;
    canvas.drawRect(
        Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
        border);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * fraction, size.height),
        Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_InkProgressPainter old) =>
      old.fraction != fraction || old.ink != ink;
}
