import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../theme/tape_colors.dart';

/// The home-grid cassette sprite (§5.2, mockups r10/r11): the app icon's
/// pixel art (`assets/images/tape.png`, 94×59), palette-swapped and re-wound
/// per cassette. One sprite serves both themes — the cassette is a physical
/// object; its inks don't follow the theme — with a single deliberate
/// exception: in dark theme the shell ink lifts one step (r11), because the
/// true shell all but vanishes on dark paper. Scaling is the card's job and
/// must be nearest-neighbour only.

const int tapeSpriteWidth = 94;
const int tapeSpriteHeight = 59;

/// Sprite-space rects the card overlays text on, in fractions of the sprite:
/// the cream label band (rows 6–19) and the colour strip under the window
/// (rows 36–41), both inset past the 6-px shell border.
const Rect tapeNameBand = Rect.fromLTWH(6 / 94, 6 / 59, 82 / 94, 14 / 59);
const Rect tapeMetaStrip = Rect.fromLTWH(6 / 94, 36 / 59, 82 / 94, 6 / 59);

/// Fixed label inks — printed on the object, not theme tokens (§5.2).
const Color tapeNameInk = Color(0xFF231E20);
const Color tapePlaceholderInk = Color(0xFF6F6A5E);

/// The sprite's lavender colour band, swapped to the cassette accent.
const int _lavender = 0xFF887999;

/// Accent while the cassette has no colour yet: warm grey.
const int _warmGrey = 0xFF8D8579;

/// The wound tape.
const int _brown = 0xFF44230A;

/// The shell/outline ink, and its lifted dark-theme tone (mockups r11): on
/// dark paper `#131210` the true shell sits at 1.14:1 — invisible — so dark
/// theme swaps it to `#3A342E` (1.52:1), the same tape under warmer light.
/// Window holes and the wound tape stay dark, so depth survives; the printed
/// label inks stay fixed.
const int _shell = 0xFF231E20;
const int _shellLifted = 0xFF3A342E;

/// Winding space in the window: the base sprite's 11-px spool + 10-px
/// transparent gap (rows 22–32, cols 37–57) that the wound-tape block grows
/// into.
const int _windingTop = 22, _windingBottom = 32; // inclusive
const int _windingLeft = 37, _windingRight = 57; // inclusive

/// Wound-tape block width in sprite pixels for a fullness of 0..1 — the
/// glanceable how-much-is-on-the-tape cue (§5.2). 2 px when empty; ≥ 88 %
/// snaps to the full 21-px span so no 1-px transparent sliver ever splits
/// the block from the hub.
int tapeWindingWidth(double fullness) {
  final f = fullness.clamp(0.0, 1.0);
  return f >= 0.88 ? 21 : 2 + (19 * f).round();
}

/// Pure pixel composition (RGBA, 94×59): every lavender pixel becomes
/// [accent] (warm grey when null — no colour assigned yet), the winding
/// space is refilled with a [windingWidth]-px block anchored at the left
/// spool, transparent past it, and [dark] lifts the shell ink one step
/// (r11).
Uint8List composeTapePixels(
  Uint8List base, {
  Color? accent,
  required int windingWidth,
  bool dark = false,
}) {
  final argb = accent?.toARGB32() ?? _warmGrey;
  final ar = (argb >> 16) & 0xff, ag = (argb >> 8) & 0xff, ab = argb & 0xff;
  const lr = (_lavender >> 16) & 0xff,
      lg = (_lavender >> 8) & 0xff,
      lb = _lavender & 0xff;
  const br = (_brown >> 16) & 0xff,
      bg = (_brown >> 8) & 0xff,
      bb = _brown & 0xff;
  const sr = (_shell >> 16) & 0xff,
      sg = (_shell >> 8) & 0xff,
      sb = _shell & 0xff;
  const tr = (_shellLifted >> 16) & 0xff,
      tg = (_shellLifted >> 8) & 0xff,
      tb = _shellLifted & 0xff;

  final out = Uint8List.fromList(base);
  for (var i = 0; i < out.length; i += 4) {
    if (out[i] == lr && out[i + 1] == lg && out[i + 2] == lb &&
        out[i + 3] == 0xff) {
      out[i] = ar;
      out[i + 1] = ag;
      out[i + 2] = ab;
    } else if (dark &&
        out[i] == sr &&
        out[i + 1] == sg &&
        out[i + 2] == sb &&
        out[i + 3] == 0xff) {
      out[i] = tr;
      out[i + 1] = tg;
      out[i + 2] = tb;
    }
  }
  for (var y = _windingTop; y <= _windingBottom; y++) {
    for (var x = _windingLeft; x <= _windingRight; x++) {
      final i = (y * tapeSpriteWidth + x) * 4;
      final wound = x - _windingLeft < windingWidth;
      out[i] = wound ? br : 0;
      out[i + 1] = wound ? bg : 0;
      out[i + 2] = wound ? bb : 0;
      out[i + 3] = wound ? 0xff : 0;
    }
  }
  return out;
}

/// Raw RGBA of the bundled sprite, decoded once per process.
Future<Uint8List>? _basePixels;

Future<Uint8List> _loadBasePixels() async {
  final data = await rootBundle.load('assets/images/tape.png');
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final bytes =
      await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  frame.image.dispose();
  codec.dispose();
  return bytes!.buffer.asUint8List();
}

/// Composed variants live for the process — at most 7 accents × 12 winding
/// widths × 2 themes of a 94×59 image. Never disposed: cards share them
/// freely.
final _variants = <int, Future<ui.Image>>{};

/// The composed sprite for [hue] (index into the light-theme tape hues;
/// null → warm grey) at [windingWidth]. Accents always use the light-theme
/// tokens — one sprite serves both themes (§5.2); [dark] only lifts the
/// shell ink (r11).
Future<ui.Image> tapeSpriteImage(
        {int? hue, required int windingWidth, bool dark = false}) =>
    _variants[((hue ?? -1) * 64 + windingWidth) * 2 + (dark ? 1 : 0)] ??=
        _composeImage(hue, windingWidth, dark);

Future<ui.Image> _composeImage(int? hue, int windingWidth, bool dark) async {
  final base = await (_basePixels ??= _loadBasePixels());
  final pixels = composeTapePixels(
    base,
    accent: hue == null ? null : TapeColors.light.hues[hue],
    windingWidth: windingWidth,
    dark: dark,
  );
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(pixels, tapeSpriteWidth, tapeSpriteHeight,
      ui.PixelFormat.rgba8888, completer.complete);
  return completer.future;
}
