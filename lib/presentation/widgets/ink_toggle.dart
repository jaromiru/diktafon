import 'package:flutter/material.dart';

import '../theme/tape_colors.dart';

/// Rectangular ink switch (mockup 05): 46×24, 2 px ink border; on = ink fill
/// with a paper square at the right, off = surface with an ink square left.
class InkToggle extends StatelessWidget {
  const InkToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 46,
          height: 24,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: value ? tape.ink : tape.surface,
            border: Border.all(color: tape.ink, width: 2),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 120),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 16,
              height: 16,
              color: value ? tape.paper : tape.ink,
            ),
          ),
        ),
      ),
    );
  }
}
