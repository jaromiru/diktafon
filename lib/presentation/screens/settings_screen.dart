import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../services/providers/llm/llm_model_manager.dart';
import '../../services/providers/model_manager.dart';
import '../../services/providers/transcription_provider.dart';
import '../../services/providers/whisper/whisper_model_manager.dart';
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
              value: _whisperRowValue(ref, settings),
              onTap: () => _pickModel(context, const ModelPickerDialog()),
            ),
            _SettingsRow(
              title: 'Summary model',
              value: _llmRowValue(ref, settings),
              onTap: () => _pickModel(context, const LlmModelPickerDialog()),
            ),
            _SettingsRow(
              title: 'Summaries',
              value: 'Memo gists & cassette overviews, generated locally',
              trailing: InkToggle(
                value: settings.summariesEnabled,
                onChanged: (on) async {
                  await repo.setSummariesEnabled(on);
                  // Re-enabling releases summary jobs parked in the queue.
                  if (on) await ref.read(jobQueueProvider).drain();
                },
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

  /// "Whisper small · 181 MB — installed", "… downloading 42 %", or a nudge
  /// to set it up (§14 guides the user here while memos wait).
  String _whisperRowValue(WidgetRef ref, AppSettings settings) {
    final model = WhisperModel.byTier(settings.whisperTier);
    return _modelRowValue(
        model, ref.watch(whisperModelStatesProvider).value, model.sizeLabel);
  }

  String _llmRowValue(WidgetRef ref, AppSettings settings) {
    final model = LlmModel.byTier(settings.llmTier);
    return _modelRowValue(
        model, ref.watch(llmModelStatesProvider).value, model.sizeLabel);
  }

  String _modelRowValue(ModelSpec model,
      List<ModelState<ModelSpec>>? states, String sizeLabel) {
    final state = states
        ?.where((s) => s.model.tier == model.tier)
        .firstOrNull;
    return switch (state?.status ?? ModelStatus.notInstalled) {
      ModelStatus.ready =>
        '${model.label} · $sizeLabel — installed, tap to manage',
      ModelStatus.downloading =>
        '${model.label} — downloading ${(state!.progress * 100).round()} %',
      _ => '${model.label} — not downloaded yet · tap to set up',
    };
  }

  void _pickModel(BuildContext context, Widget dialog) {
    showDialog<void>(context: context, builder: (_) => dialog);
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

/// Soft device gate for heavyweight tiers (§6.6): total RAM where
/// /proc/meminfo exists (Linux/Android); unknown platforms don't block.
bool deviceHasRamGb(int gb) {
  if (gb <= 0) return true;
  try {
    final meminfo = File('/proc/meminfo').readAsLinesSync();
    final total = meminfo.firstWhere((l) => l.startsWith('MemTotal:'));
    final kb = int.parse(RegExp(r'\d+').firstMatch(total)!.group(0)!);
    return kb >= gb * 1024 * 1024;
  } catch (_) {
    return true;
  }
}

/// The transcription-model picker (§5.5, mockup 05 note 3): choose the tier,
/// download with progress, manage storage. Selecting an uninstalled tier
/// starts its download immediately; when it lands, queued memos transcribe.
class ModelPickerDialog extends ConsumerWidget {
  const ModelPickerDialog({super.key});

  /// large-v3-turbo needs ~2.5 GB free while transcribing (§6.6).
  static bool deviceCanRun(WhisperModel model) =>
      model.tier != WhisperModel.largeV3Turbo.tier || deviceHasRamGb(5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final states = ref.watch(whisperModelStatesProvider).value ?? const [];
    final manager = ref.read(whisperModelManagerProvider);

    return _EnginePickerDialog(
      title: 'TRANSCRIPTION MODEL',
      states: states,
      selectedTier: settings.whisperTier,
      enabledOf: (model) => deviceCanRun(model as WhisperModel),
      disabledReason: 'needs ≥ 5 GB RAM',
      installedBytes: manager.installedBytes(),
      onSelect: (state) => _select(context, ref, state),
      onDelete: (state) => manager.delete(state.model as WhisperModel),
    );
  }

  Future<void> _select(BuildContext context, WidgetRef ref,
      ModelState<ModelSpec> state) async {
    final repo = ref.read(settingsRepositoryProvider);
    final manager = ref.read(whisperModelManagerProvider);
    final messenger = ScaffoldMessenger.of(context);
    await repo.setWhisperTier(state.model.tier);
    await downloadAndDrain(messenger, ref, state,
        download: () => manager.download(state.model as WhisperModel),
        readyNote: 'transcribing waiting memos');
  }
}

/// The summary-model picker (§5.5 Summaries): same mechanics over the LLM
/// catalog; when a model lands, parked summary jobs resume.
class LlmModelPickerDialog extends ConsumerWidget {
  const LlmModelPickerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final states = ref.watch(llmModelStatesProvider).value ?? const [];
    final manager = ref.read(llmModelManagerProvider);

    return _EnginePickerDialog(
      title: 'SUMMARY MODEL',
      states: states,
      selectedTier: settings.llmTier,
      enabledOf: (model) => deviceHasRamGb((model as LlmModel).minRamGb),
      disabledReason: 'needs ≥ ${LlmModel.qwen3_4b.minRamGb} GB RAM',
      installedBytes: manager.installedBytes(),
      onSelect: (state) => _select(context, ref, state),
      onDelete: (state) => manager.delete(state.model as LlmModel),
    );
  }

  Future<void> _select(BuildContext context, WidgetRef ref,
      ModelState<ModelSpec> state) async {
    final repo = ref.read(settingsRepositoryProvider);
    final manager = ref.read(llmModelManagerProvider);
    final messenger = ScaffoldMessenger.of(context);
    await repo.setLlmTier(state.model.tier);
    await downloadAndDrain(messenger, ref, state,
        download: () => manager.download(state.model as LlmModel),
        readyNote: 'summarizing waiting memos');
  }
}

/// Shared select flow: an installed tier just drains the queue; an absent
/// one downloads first (§14 model-missing recovery).
Future<void> downloadAndDrain(
  ScaffoldMessengerState messenger,
  WidgetRef ref,
  ModelState<ModelSpec> state, {
  required Future<void> Function() download,
  required String readyNote,
}) async {
  final queue = ref.read(jobQueueProvider);

  if (state.status != ModelStatus.notInstalled) {
    await queue.drain();
    return;
  }
  try {
    await download();
    messenger.showSnackBar(SnackBar(
        content: Text('${state.model.label} is ready — $readyNote.')));
    await queue.drain();
  } catch (_) {
    messenger.showSnackBar(SnackBar(
        content: Text('Download of ${state.model.label} failed — '
            'check your connection and try again.')));
  }
}

class _EnginePickerDialog extends ConsumerWidget {
  const _EnginePickerDialog({
    required this.title,
    required this.states,
    required this.selectedTier,
    required this.enabledOf,
    required this.disabledReason,
    required this.installedBytes,
    required this.onSelect,
    required this.onDelete,
  });

  final String title;
  final List<ModelState<ModelSpec>> states;
  final String selectedTier;
  final bool Function(ModelSpec) enabledOf;
  final String disabledReason;
  final int installedBytes;
  final void Function(ModelState<ModelSpec>) onSelect;
  final void Function(ModelState<ModelSpec>) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tape = context.tape;
    // Listed tiers always; unlisted (tiny, tests) only when present.
    final visible = states
        .where((s) => s.model.listed || s.status != ModelStatus.notInstalled)
        .toList();
    final usedMb = (installedBytes / (1024 * 1024)).round();

    return SimpleDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      children: [
        for (final state in visible)
          _ModelOption(
            state: state,
            selected: selectedTier == state.model.tier,
            enabled: enabledOf(state.model),
            disabledReason: disabledReason,
            onSelect: () => onSelect(state),
            onDelete: state.status == ModelStatus.ready
                ? () => onDelete(state)
                : null,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
          child: Text(
            'Runs on this device only. Storage used by models: $usedMb MB.',
            style: TextStyle(fontSize: 10, color: tape.ink2),
          ),
        ),
      ],
    );
  }
}

class _ModelOption extends StatelessWidget {
  const _ModelOption({
    required this.state,
    required this.selected,
    required this.enabled,
    required this.disabledReason,
    required this.onSelect,
    this.onDelete,
  });

  final ModelState<ModelSpec> state;
  final bool selected;
  final bool enabled;
  final String disabledReason;
  final VoidCallback onSelect;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    final model = state.model;
    final status = switch (state.status) {
      ModelStatus.ready => 'installed · ${model.sizeLabel}',
      ModelStatus.downloading =>
        'downloading ${(state.progress * 100).round()} %',
      ModelStatus.notInstalled =>
        enabled ? 'download · ${model.sizeLabel}' : disabledReason,
    };

    return InkWell(
      onTap: enabled ? onSelect : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: selected
                        ? Icon(Icons.check, size: 16, color: tape.ink)
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      model.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : null,
                        color: tape.ink,
                      ),
                    ),
                  ),
                  Text(status,
                      style: TextStyle(fontSize: 10, color: tape.ink2)),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16),
                      color: tape.ink2,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Delete model file',
                      onPressed: onDelete,
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 22, top: 1),
                child: Text(
                  model.description,
                  style: TextStyle(
                      fontSize: 9.5, height: 1.4, color: tape.ink2),
                ),
              ),
              if (state.status == ModelStatus.downloading)
                Padding(
                  padding: const EdgeInsets.only(left: 22, top: 6, bottom: 2),
                  child: _InkProgressBar(fraction: state.progress),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Retro determinate progress: an ink-bordered channel filling left→right.
/// Custom-painted — fractional-width widgets have no finite intrinsic width
/// at 0 %, which crashes inside SimpleDialog's IntrinsicWidth.
class _InkProgressBar extends StatelessWidget {
  const _InkProgressBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 10,
        child: CustomPaint(
          painter: _InkProgressPainter(
              fraction.clamp(0.0, 1.0), context.tape.ink),
        ),
      );
}

class _InkProgressPainter extends CustomPainter {
  const _InkProgressPainter(this.fraction, this.ink);

  final double fraction;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = ink;
    canvas.drawRect(
        Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
        border);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * fraction, size.height),
        Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_InkProgressPainter old) =>
      old.fraction != fraction || old.ink != ink;
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
