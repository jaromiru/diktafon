import 'package:diktafon/domain/models.dart';
import 'package:diktafon/domain/palette.dart';
import 'package:diktafon/domain/tape.dart';
import 'package:flutter_test/flutter_test.dart';

Memo memo(String id, int durationMs, {int t = 0}) => Memo(
      id: id,
      cassetteId: 'c1',
      filePath: '$id.m4a',
      durationMs: durationMs,
      createdAt: DateTime.fromMillisecondsSinceEpoch(t),
      status: MemoStatus.stored,
    );

void main() {
  group('Tape offsets (§4.2)', () {
    test('empty tape has zero length', () {
      final tape = Tape(const []);
      expect(tape.isEmpty, isTrue);
      expect(tape.totalDurationMs, 0);
      expect(() => tape.locate(0), throwsStateError);
    });

    test('offsets are prefix sums of durations', () {
      final tape = Tape([memo('a', 1000), memo('b', 2500), memo('c', 500)]);
      expect(tape.offsetsMs, [0, 1000, 3500]);
      expect(tape.totalDurationMs, 4000);
    });

    test('locate maps global → (memo, local) with Oᵢ ≤ p < Oᵢ + dᵢ', () {
      final tape = Tape([memo('a', 1000), memo('b', 2500), memo('c', 500)]);

      var p = tape.locate(0);
      expect((p.memoIndex, p.localMs), (0, 0));

      p = tape.locate(999);
      expect((p.memoIndex, p.localMs), (0, 999));

      // Boundary belongs to the *next* memo.
      p = tape.locate(1000);
      expect((p.memoIndex, p.localMs), (1, 0));

      p = tape.locate(3600);
      expect((p.memoIndex, p.localMs), (2, 100));
    });

    test('locate clamps beyond the ends', () {
      final tape = Tape([memo('a', 1000), memo('b', 2000)]);

      var p = tape.locate(-50);
      expect((p.memoIndex, p.localMs), (0, 0));

      // p == T resolves to the very end of the last memo.
      p = tape.locate(3000);
      expect((p.memoIndex, p.localMs), (1, 2000));

      p = tape.locate(99999);
      expect((p.memoIndex, p.localMs), (1, 2000));
    });

    test('word timing maps to global (§4.2)', () {
      final tape = Tape([memo('a', 1000), memo('b', 2500)]);
      // A word at local [200, 450] in memo 1 → global [1200, 1450].
      expect(tape.toGlobalMs(1, 200), 1200);
      expect(tape.toGlobalMs(1, 450), 1450);
    });

    test('deleting a memo re-flows the tape (offsets recompute)', () {
      final memos = [memo('a', 1000), memo('b', 2500), memo('c', 500)];
      final reflowed = Tape([memos[0], memos[2]]);
      expect(reflowed.offsetsMs, [0, 1000]);
      expect(reflowed.totalDurationMs, 1500);
      final p = reflowed.locate(1200);
      expect((p.memoIndex, p.localMs), (1, 200));
    });

    test('timeline fractions', () {
      final tape = Tape([memo('a', 1000), memo('b', 3000)]);
      expect(tape.startFraction(1), 0.25);
      expect(tape.durationFraction(1), 0.75);
    });
  });

  group('Palette (§10.2)', () {
    test('adjacent memos never share a hue', () {
      for (var seed = 0; seed < tapeHueCount; seed++) {
        for (var i = 0; i < 40; i++) {
          expect(memoHueIndex(seed, i), isNot(memoHueIndex(seed, i + 1)));
        }
      }
    });

    test('hue assignment is stable for a given seed', () {
      expect(memoHueIndex(3, 7), memoHueIndex(3, 7));
      expect(cassetteHueIndex(9), 3);
    });

    test('seeds rotate the cycle so cassettes differ', () {
      expect(memoHueIndex(0, 0), isNot(memoHueIndex(1, 0)));
    });
  });

  group('Transcript JSON round-trip', () {
    test('serializes and parses', () {
      const t = Transcript(languageCode: 'cs', segments: [
        Segment(startMs: 0, endMs: 1200, words: [
          Word(text: 'Napadá', startMs: 0, endMs: 400),
          Word(text: 'mě', startMs: 410, endMs: 600),
        ]),
      ]);
      final parsed = Transcript.fromJson(t.toJson());
      expect(parsed.languageCode, 'cs');
      expect(parsed.segments.single.words.first.text, 'Napadá');
      expect(parsed.segments.single.words.last.endMs, 600);
      expect(parsed.isEmpty, isFalse);
    });
  });
}
