/// The tape — a computed view over a cassette's memos (§4.2, §4.1).
///
/// Never persisted: offsets recompute whenever the memo list changes, so
/// deleting a memo "re-flows" the tape with no audio rewritten.
library;

import 'models.dart';

/// A position on the global timeline, resolved to a memo.
class TapePosition {
  const TapePosition({required this.memoIndex, required this.localMs});

  final int memoIndex;
  final int localMs;
}

class Tape {
  Tape(this.memos)
      : offsetsMs = List<int>.unmodifiable(_computeOffsets(memos));

  /// Chronologically ordered memos (the caller queries ORDER BY createdAt).
  final List<Memo> memos;

  /// Global start offset Oᵢ of each memo: Oᵢ = Σⱼ<ᵢ dⱼ.
  final List<int> offsetsMs;

  static List<int> _computeOffsets(List<Memo> memos) {
    final offsets = <int>[];
    var acc = 0;
    for (final m in memos) {
      offsets.add(acc);
      acc += m.durationMs;
    }
    return offsets;
  }

  bool get isEmpty => memos.isEmpty;
  int get memoCount => memos.length;

  /// Total tape length T = Σ dᵢ.
  int get totalDurationMs =>
      memos.isEmpty ? 0 : offsetsMs.last + memos.last.durationMs;

  /// Global → local: find memo i with Oᵢ ≤ p < Oᵢ + dᵢ (§4.2).
  ///
  /// Positions are clamped to the tape, so p == T resolves to the very end of
  /// the last memo (useful when playback finishes).
  TapePosition locate(int globalMs) {
    if (memos.isEmpty) {
      throw StateError('cannot locate a position on an empty tape');
    }
    final p = globalMs.clamp(0, totalDurationMs);
    // Binary search for the last offset ≤ p.
    var lo = 0, hi = memos.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (offsetsMs[mid] <= p) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    // p == T falls past the last memo's end; clamp local to its duration.
    final local = (p - offsetsMs[lo]).clamp(0, memos[lo].durationMs);
    return TapePosition(memoIndex: lo, localMs: local);
  }

  /// Local → global for a word/time inside memo [memoIndex] (§4.2).
  int toGlobalMs(int memoIndex, int localMs) => offsetsMs[memoIndex] + localMs;

  /// Fraction [0..1] of the tape where memo i starts — timeline geometry.
  double startFraction(int memoIndex) {
    final total = totalDurationMs;
    return total == 0 ? 0 : offsetsMs[memoIndex] / total;
  }

  /// Fraction [0..1] of the tape occupied by memo i — timeline geometry.
  double durationFraction(int memoIndex) {
    final total = totalDurationMs;
    return total == 0 ? 0 : memos[memoIndex].durationMs / total;
  }
}
