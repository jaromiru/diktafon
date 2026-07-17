import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:diktafon/presentation/theme/tape_colors.dart';
import 'package:diktafon/presentation/widgets/pixel_tape.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// The compositor is tested against the real bundled sprite, so a repainted
/// tape.png that moves the colour band or the window fails here instead of
/// on the shelf.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const lavender = 0xFF887999;
  const warmGrey = 0xFF8D8579;
  const brown = 0xFF44230A;
  const shell = 0xFF231E20;
  const shellLifted = 0xFF3A342E;

  late Uint8List base;

  int argbAt(Uint8List px, int x, int y) {
    final i = (y * tapeSpriteWidth + x) * 4;
    return (px[i + 3] << 24) | (px[i] << 16) | (px[i + 1] << 8) | px[i + 2];
  }

  int count(Uint8List px, int argb) {
    var n = 0;
    for (var i = 0; i < px.length; i += 4) {
      if (argbAt(px, (i ~/ 4) % tapeSpriteWidth, i ~/ 4 ~/ tapeSpriteWidth) ==
          argb) {
        n++;
      }
    }
    return n;
  }

  setUpAll(() async {
    final bytes = File('assets/images/tape.png').readAsBytesSync();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, tapeSpriteWidth);
    expect(frame.image.height, tapeSpriteHeight);
    final data =
        await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    base = data!.buffer.asUint8List();
  });

  group('tapeWindingWidth', () {
    test('empty tape keeps a visible 2-px block', () {
      expect(tapeWindingWidth(0), 2);
    });

    test('grows with fullness', () {
      expect(tapeWindingWidth(0.5), 12);
      expect(tapeWindingWidth(0.87), lessThanOrEqualTo(19));
    });

    test('snaps to the full span at >= 88 % — a 1-px sliver never renders',
        () {
      expect(tapeWindingWidth(0.88), 21);
      expect(tapeWindingWidth(1.0), 21);
      for (var f = 0.0; f < 0.88; f += 0.01) {
        expect(tapeWindingWidth(f), lessThanOrEqualTo(19));
      }
    });
  });

  group('composeTapePixels', () {
    test('swaps every lavender pixel to the accent, nothing else', () {
      final accent = TapeColors.light.hues[0];
      final out = composeTapePixels(base, accent: accent, windingWidth: 11);
      expect(count(out, lavender), 0);
      expect(count(out, accent.toARGB32()), count(base, lavender));
      // Winding at the base sprite's own 11 px: everything else identical.
      expect(count(out, brown), count(base, brown));
    });

    test('unassigned accent renders warm grey', () {
      final out = composeTapePixels(base, windingWidth: 11);
      expect(count(out, lavender), 0);
      expect(count(out, warmGrey), count(base, lavender));
    });

    test('winding block spans the requested width, transparent past it', () {
      for (final width in [2, 12, 21]) {
        final out = composeTapePixels(base, windingWidth: width);
        // 11 window rows (22–32), anchored at the left spool col 37.
        expect(count(out, brown), 11 * width, reason: 'width $width');
        expect(argbAt(out, 37, 27), brown);
        expect(argbAt(out, 37 + width - 1, 27), brown);
        if (width < 21) {
          expect(argbAt(out, 37 + width, 27), 0x00000000);
          expect(argbAt(out, 57, 27), 0x00000000);
        }
      }
    });

    test('dark lifts every shell pixel one step, nothing else (r11)', () {
      final accent = TapeColors.light.hues[2];
      final out = composeTapePixels(base,
          accent: accent, windingWidth: 11, dark: true);
      expect(count(out, shell), 0);
      expect(count(out, shellLifted), count(base, shell));
      // Depth survives: cream band, accent and wound tape keep their colors.
      expect(argbAt(out, 47, 12), argbAt(base, 47, 12));
      expect(count(out, accent.toARGB32()), count(base, lavender));
      expect(count(out, brown), count(base, brown));
    });

    test('light theme keeps the true shell ink', () {
      final out = composeTapePixels(base, windingWidth: 11);
      expect(count(out, shellLifted), 0);
      expect(count(out, shell), count(base, shell));
    });

    test('label band and inks are untouched by the swap', () {
      final out = composeTapePixels(base,
          accent: const Color(0xFF2F9C8D), windingWidth: 2);
      // Cream label band pixel and shell ink pixel keep their fixed colors.
      expect(argbAt(out, 47, 12), argbAt(base, 47, 12));
      expect(argbAt(out, 0, 5), argbAt(base, 0, 5));
    });
  });
}
