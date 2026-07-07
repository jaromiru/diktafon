import 'package:flutter/material.dart';

import 'tape_colors.dart';

/// Retro tape-recorder identity (§10.1): hard corners everywhere, 2 px ink
/// borders, offset cardstock shadows; Jersey 10 for display/counters,
/// Space Mono for body.
const displayFont = 'Jersey 10';
const bodyFont = 'Space Mono';

ThemeData buildTheme(Brightness brightness) {
  final tape =
      brightness == Brightness.light ? TapeColors.light : TapeColors.dark;

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: bodyFont,
    scaffoldBackgroundColor: tape.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: tape.accent,
      brightness: brightness,
      surface: tape.paper,
      onSurface: tape.ink,
      primary: tape.ink,
      onPrimary: tape.paper,
      error: tape.rec,
    ),
    splashFactory: InkSparkle.splashFactory,
  );

  // No rounded chrome anywhere (§10.1).
  const hard = RoundedRectangleBorder(borderRadius: BorderRadius.zero);

  return base.copyWith(
    extensions: [tape],
    appBarTheme: AppBarTheme(
      backgroundColor: tape.paper,
      foregroundColor: tape.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: displayFont,
        fontSize: 30,
        height: 1,
        letterSpacing: 0.6,
        color: tape.ink,
      ),
    ),
    dividerTheme: DividerThemeData(color: tape.line, thickness: 1.5),
    dialogTheme: DialogThemeData(
      shape: hard.copyWith(side: BorderSide(color: tape.ink, width: 2)),
      backgroundColor: tape.surface,
      titleTextStyle: TextStyle(
        fontFamily: displayFont,
        fontSize: 26,
        color: tape.ink,
      ),
      contentTextStyle:
          TextStyle(fontFamily: bodyFont, fontSize: 13, color: tape.ink2),
    ),
    popupMenuTheme: PopupMenuThemeData(
      shape: hard.copyWith(side: BorderSide(color: tape.ink, width: 2)),
      color: tape.surface,
      textStyle:
          TextStyle(fontFamily: bodyFont, fontSize: 13, color: tape.ink),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: hard,
        foregroundColor: tape.ink,
        textStyle: const TextStyle(
            fontFamily: bodyFont, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    ),
    switchTheme: SwitchThemeData(
      // Rectangular ink switches (mockup 05): squared track, paper thumb.
      thumbColor: WidgetStatePropertyAll(tape.paper),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? tape.ink : tape.line),
      trackOutlineColor: WidgetStatePropertyAll(tape.ink),
      trackOutlineWidth: const WidgetStatePropertyAll(2),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tape.ink,
      contentTextStyle: TextStyle(
          fontFamily: bodyFont, fontSize: 12.5, color: tape.paper),
      shape: hard,
      behavior: SnackBarBehavior.floating,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: tape.ink,
      selectionColor: tape.highlight,
      selectionHandleColor: tape.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: tape.ink, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: tape.ink, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: tape.accent, width: 2),
      ),
      hintStyle: TextStyle(
          fontFamily: bodyFont, fontStyle: FontStyle.italic, color: tape.ink2),
    ),
  );
}

/// LCD-style display text (counters, titles) — Jersey 10 (§10.1).
TextStyle lcdStyle(BuildContext context,
        {double size = 22, Color? color}) =>
    TextStyle(
      fontFamily: displayFont,
      fontSize: size,
      height: 1,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
