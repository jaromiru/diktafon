import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../theme/tape_colors.dart';
import '../widgets/ink_toggle.dart';

/// Settings (§5.5, mockup 05): grouped ink-bordered cards, rectangular
/// toggles. Model & backup rows are honest about what ships in M1.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const languages = <String?, String>{
    null: 'Auto-detect (from first recording)',
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
    'pt': 'Português',
    'de': 'Deutsch',
    'pl': 'Polski',
    'cs': 'Čeština',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final repo = ref.read(settingsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('SETTINGS'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _Group(title: 'Language', rows: [
            _SettingsRow(
              title: 'Transcription language',
              value: settings.appLanguage == null
                  ? 'Auto-detect — set from your first memo (D8)'
                  : languages[settings.appLanguage] ?? settings.appLanguage!,
              onTap: () => _pickLanguage(context, repo, settings),
            ),
          ]),
          _Group(title: 'Playback', rows: [
            _SettingsRow(
              title: 'Boundary chime',
              value:
                  'A soft cue as the tape rolls into the next memo. Off = fully seamless.',
              trailing: InkToggle(
                value: settings.chimeEnabled,
                onChanged: repo.setChimeEnabled,
              ),
            ),
          ]),
          _Group(title: 'On-device intelligence', rows: [
            _SettingsRow(
              title: 'Transcription model',
              value: 'Whisper ${settings.whisperTier} — not installed yet '
                  '(arrives with the transcription update)',
              onTap: () => _modelInfo(context),
            ),
            _SettingsRow(
              title: 'Summaries',
              value: 'Memo gists & cassette overviews, generated locally',
              trailing: InkToggle(
                value: settings.summariesEnabled,
                onChanged: repo.setSummariesEnabled,
              ),
            ),
          ]),
          _Group(title: 'Appearance', rows: [
            _SettingsRow(
              title: 'Theme',
              value: switch (settings.theme) {
                'light' => 'Light',
                'dark' => 'Dark',
                _ => 'System',
              },
              onTap: () => _pickTheme(context, repo, settings),
            ),
          ]),
          _Group(title: 'Your data', rows: [
            _SettingsRow(
              title: 'Backup & export',
              value: 'Explicit, user-initiated — coming with the polish update',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Backup & export ship in a later milestone.')),
              ),
            ),
            _SettingsRow(
              title: 'About & privacy',
              value: 'Audio never leaves this device',
              onTap: () => _about(context),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _pickLanguage(
      BuildContext context, SettingsRepository repo, AppSettings s) async {
    final choice = await showDialog<Object>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('TRANSCRIPTION LANGUAGE'),
        children: [
          for (final entry in languages.entries)
            _dialogOption(
              dialogContext,
              label: entry.value,
              selected: s.appLanguage == entry.key,
              result: entry.key ?? 'auto',
            ),
        ],
      ),
    );
    if (choice != null) {
      await repo.setAppLanguage(choice == 'auto' ? null : choice as String);
    }
  }

  Future<void> _pickTheme(
      BuildContext context, SettingsRepository repo, AppSettings s) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('THEME'),
        children: [
          for (final (value, label) in const [
            ('system', 'System'),
            ('light', 'Light'),
            ('dark', 'Dark'),
          ])
            _dialogOption(
              dialogContext,
              label: label,
              selected: s.theme == value,
              result: value,
            ),
        ],
      ),
    );
    if (choice != null) await repo.setTheme(choice);
  }

  Widget _dialogOption(
    BuildContext context, {
    required String label,
    required bool selected,
    required Object result,
  }) =>
      SimpleDialogOption(
        onPressed: () => Navigator.pop(context, result),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: selected
                  ? Icon(Icons.check, size: 16, color: context.tape.ink)
                  : null,
            ),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : null,
                    color: context.tape.ink)),
          ],
        ),
      );

  void _modelInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('TRANSCRIPTION MODEL'),
        content: const Text(
          'On-device Whisper transcription arrives with the next milestone. '
          'The default tier is "small" (~180 MB, best size/quality for '
          'Czech & Polish); capable devices will also be offered '
          'large-v3-turbo (~570 MB).\n\nMemos recorded now are kept and will '
          'be transcribed once the model is installed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _about(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ABOUT & PRIVACY'),
        content: const Text(
          'Diktafon listens, writes and summarizes right here on your phone.\n\n'
          'Recordings, transcripts and summaries never leave the device. '
          'There is no account, no cloud and no analytics. The only way data '
          'leaves is a backup or export you start yourself.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});

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

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
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
