import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/tape_colors.dart';

/// Live input-level meter (§5.3, mockup 04): square bars, red when hot.
/// Renders a rolling history of dBFS amplitudes, newest in the middle-out
/// style of the mockup is decorative — here newest is rightmost (honest).
class LevelMeter extends StatelessWidget {
  const LevelMeter({super.key, required this.levelsDb, this.barCount = 30});

  /// Rolling window of recent amplitudes in dBFS (≤0, silence ≈ -45 and below).
  final List<double> levelsDb;
  final int barCount;

  static const _height = 44.0;
  static const _hotThresholdDb = -18.0;

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    final bars = List<double>.filled(barCount, -60)
      ..setRange(max(0, barCount - levelsDb.length), barCount,
          levelsDb.sublist(max(0, levelsDb.length - barCount)));
    return SizedBox(
      height: _height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final db in bars)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Container(
                width: 4,
                height: _heightFor(db),
                color: db >= _hotThresholdDb ? tape.rec : tape.line,
              ),
            ),
        ],
      ),
    );
  }

  /// Map [-45..0] dBFS → [4..44] px.
  double _heightFor(double db) =>
      4 + 40 * ((db.clamp(-45.0, 0.0) + 45.0) / 45.0);
}
