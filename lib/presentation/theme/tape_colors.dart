import 'package:flutter/material.dart';

/// Design tokens from the approved mockups (docs/ui-mockups.html): studio
/// paper & ink plus six tape hues. Dark is not an inversion — paper deepens
/// to warm charcoal, hues brighten one step, record red warms up (§10).
@immutable
class TapeColors extends ThemeExtension<TapeColors> {
  const TapeColors({
    required this.paper,
    required this.surface,
    required this.ink,
    required this.ink2,
    required this.line,
    required this.accent,
    required this.rec,
    required this.highlight,
    required this.ok,
    required this.shell,
    required this.window,
    required this.reel,
    required this.hues,
  });

  final Color paper;
  final Color surface;
  final Color ink;
  final Color ink2;
  final Color line;
  final Color accent;

  /// Reserved exclusively for recording (§10.1).
  final Color rec;

  /// Calm amber wash behind the current transcript word (§10.3).
  final Color highlight;
  final Color ok;

  /// Cassette drawing (home grid): shell plastic, window, reel tape.
  final Color shell;
  final Color window;
  final Color reel;

  /// The six timeline hues: ochre, teal, indigo, rust, moss, plum (§10.2).
  final List<Color> hues;

  static const light = TapeColors(
    paper: Color(0xFFF5F4EF),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF211F1A),
    ink2: Color(0xFF6F6A5E),
    line: Color(0xFFE5E2D7),
    accent: Color(0xFFA8781F),
    rec: Color(0xFFC93A2B),
    highlight: Color(0xFFF3E5BE),
    ok: Color(0xFF3E7D4E),
    shell: Color(0xFFE6E2D5),
    window: Color(0xFFCBC6B6),
    reel: Color(0xFF4A4238),
    hues: [
      Color(0xFFCE9930),
      Color(0xFF2F9C8D),
      Color(0xFF5E6CC9),
      Color(0xFFC75B41),
      Color(0xFF7C9440),
      Color(0xFF9A5FA6),
    ],
  );

  static const dark = TapeColors(
    paper: Color(0xFF131210),
    surface: Color(0xFF1E1C18),
    ink: Color(0xFFECE8DF),
    ink2: Color(0xFF9A9384),
    line: Color(0xFF2C2A24),
    accent: Color(0xFFD9A94A),
    rec: Color(0xFFE25743),
    highlight: Color(0xFF453A20),
    ok: Color(0xFF7FB08A),
    shell: Color(0xFF242220),
    window: Color(0xFF100F0C),
    reel: Color(0xFF3E3831),
    hues: [
      Color(0xFFDFAF4C),
      Color(0xFF4FB5A6),
      Color(0xFF8290DE),
      Color(0xFFDD7A5E),
      Color(0xFF98B05A),
      Color(0xFFB47EC0),
    ],
  );

  @override
  TapeColors copyWith() => this;

  @override
  TapeColors lerp(TapeColors? other, double t) => t < 0.5 ? this : other ?? this;
}

extension TapeColorsX on BuildContext {
  TapeColors get tape => Theme.of(this).extension<TapeColors>()!;
}
