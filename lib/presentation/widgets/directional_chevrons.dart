import 'package:flutter/material.dart';

/// Direction-aware chevrons (§13 wave 2): the retro chrome draws bare
/// chevron glyphs rather than Material's auto-mirroring back arrow, so RTL
/// locales flip them here — back points along the reading direction, the
/// row affordance points against it.
IconData backChevron(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_right
        : Icons.chevron_left;

IconData forwardChevron(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left
        : Icons.chevron_right;
