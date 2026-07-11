import 'package:flutter/material.dart';

/// Reading-type screens (§5.7) keep their content column at most this wide —
/// transcript lines and settings rows hold a readable measure on tablets and
/// desktop windows. Phone-sized screens are untouched (the cap doesn't bite).
const double kContentMaxWidth = 640;

/// Centers [child] in a column capped at [kContentMaxWidth] logical px.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
          child: child,
        ),
      );
}
