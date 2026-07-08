import 'package:diktafon/services/audio/tape_player_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// D5 / §5.4: the chime marks only *natural* forward advance — never seeks,
/// scrubs, ±15 s hops or tape (re)loads.
void main() {
  group('isNaturalAdvance', () {
    test('fires on a one-step forward advance during playback', () {
      expect(
        isNaturalAdvance(
            from: 0, to: 1, playing: true, seeking: false, loading: false),
        isTrue,
      );
      expect(
        isNaturalAdvance(
            from: 3, to: 4, playing: true, seeking: false, loading: false),
        isTrue,
      );
    });

    test('suppressed while a seek/scrub is in flight', () {
      expect(
        isNaturalAdvance(
            from: 0, to: 1, playing: true, seeking: true, loading: false),
        isFalse,
      );
    });

    test('suppressed while the tape (re)loads', () {
      expect(
        isNaturalAdvance(
            from: 0, to: 1, playing: true, seeking: false, loading: true),
        isFalse,
      );
    });

    test('suppressed when paused', () {
      expect(
        isNaturalAdvance(
            from: 0, to: 1, playing: false, seeking: false, loading: false),
        isFalse,
      );
    });

    test('suppressed on backward or multi-step index jumps', () {
      expect(
        isNaturalAdvance(
            from: 2, to: 1, playing: true, seeking: false, loading: false),
        isFalse,
      );
      expect(
        isNaturalAdvance(
            from: 0, to: 2, playing: true, seeking: false, loading: false),
        isFalse,
      );
      expect(
        isNaturalAdvance(
            from: 1, to: 1, playing: true, seeking: false, loading: false),
        isFalse,
      );
    });

    test('suppressed without a previous index (fresh load)', () {
      expect(
        isNaturalAdvance(
            from: null, to: 0, playing: true, seeking: false, loading: false),
        isFalse,
      );
      expect(
        isNaturalAdvance(
            from: 0, to: null, playing: true, seeking: false, loading: false),
        isFalse,
      );
    });
  });
}
