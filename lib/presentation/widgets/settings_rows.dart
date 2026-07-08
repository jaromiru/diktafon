import 'package:flutter/material.dart';

import '../theme/tape_colors.dart';

/// Ink-bordered settings group (§5.5, mockup 05), shared by Settings and
/// Backup & export.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: tape.ink2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: tape.surface,
              border: Border.all(color: tape.ink, width: 1.5),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) Divider(height: 1.5, color: tape.line),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    required this.value,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontSize: 10.5, height: 1.45, color: tape.ink2)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ??
                Icon(Icons.chevron_right, size: 18, color: tape.ink2),
          ],
        ),
      ),
    );
  }
}
