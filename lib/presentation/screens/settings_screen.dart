import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/l10n.dart';
import '../../services/providers/llm/llm_model_manager.dart';
import '../../services/providers/model_manager.dart';
import '../../services/providers/transcription_provider.dart';
import '../../services/providers/whisper/whisper_model_manager.dart';
import '../theme/tape_colors.dart';
import '../widgets/ink_progress_bar.dart';
import '../widgets/ink_toggle.dart';
import '../widgets/settings_rows.dart';
import 'backup_screen.dart';

/// Settings (§5.5, mockup 05): grouped ink-bordered cards, rectangular
/// toggles. Model & backup rows are honest about what ships in M1.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Endonyms on purpose — a language list reads best in its own words.
  static const languages = <String, String>{
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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          tooltip: l10n.back,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SettingsGroup(title: l10n.groupLanguage, rows: [
            SettingsRow(
              title: l10n.transcriptionLanguage,
              value: settings.appLanguage == null
                  ? l10n.autoDetectValue
                  : languages[settings.appLanguage] ?? settings.appLanguage!,
              onTap: () => _pickLanguage(context, repo, settings),
            ),
          ]),
          SettingsGroup(title: l10n.groupPlayback, rows: [
            SettingsRow(
              title: l10n.boundaryChime,
              value: l10n.boundaryChimeDesc,
              trailing: InkToggle(
                value: settings.chimeEnabled,
                onChanged: repo.setChimeEnabled,
              ),
            ),
          ]),
          SettingsGroup(title: l10n.groupIntelligence, rows: [
            SettingsRow(
              title: l10n.transcriptionModel,
              value: _whisperRowValue(context, ref, settings),
              onTap: () => _pickModel(context, const ModelPickerDialog()),
            ),
            SettingsRow(
              title: l10n.summaryModel,
              value: _llmRowValue(context, ref, settings),
              onTap: () => _pickModel(context, const LlmModelPickerDialog()),
            ),
            SettingsRow(
              title: l10n.summariesRow,
              value: l10n.summariesRowDesc,
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
          SettingsGroup(title: l10n.groupAppearance, rows: [
            SettingsRow(
              title: l10n.themeRow,
              value: switch (settings.theme) {
                'light' => l10n.themeLight,
                'dark' => l10n.themeDark,
                _ => l10n.themeSystem,
              },
              onTap: () => _pickTheme(context, repo, settings),
            ),
          ]),
          SettingsGroup(title: l10n.groupYourData, rows: [
            SettingsRow(
              title: l10n.backupExport,
              value: l10n.backupExportDesc,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const BackupScreen())),
            ),
            SettingsRow(
              title: l10n.aboutPrivacy,
              value: l10n.aboutPrivacyDesc,
              onTap: () => _about(context),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _pickLanguage(
      BuildContext context, SettingsRepository repo, AppSettings s) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(context.l10n.transcriptionLanguageTitle),
        children: [
          _dialogOption(
            dialogContext,
            label: context.l10n.autoDetectOption,
            selected: s.appLanguage == null,
            result: 'auto',
          ),
          for (final entry in languages.entries)
            _dialogOption(
              dialogContext,
              label: entry.value,
              selected: s.appLanguage == entry.key,
              result: entry.key,
            ),
        ],
      ),
    );
    if (choice != null) {
      await repo.setAppLanguage(choice == 'auto' ? null : choice);
    }
  }

  Future<void> _pickTheme(
      BuildContext context, SettingsRepository repo, AppSettings s) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(context.l10n.themeTitle),
        children: [
          for (final (value, label) in [
            ('system', context.l10n.themeSystem),
            ('light', context.l10n.themeLight),
            ('dark', context.l10n.themeDark),
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
    required String result,
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
  String _whisperRowValue(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    final model = WhisperModel.byTier(settings.whisperTier);
    return _modelRowValue(context, model,
        ref.watch(whisperModelStatesProvider).value, model.sizeLabel);
  }

  String _llmRowValue(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    final model = LlmModel.byTier(settings.llmTier);
    return _modelRowValue(context, model,
        ref.watch(llmModelStatesProvider).value, model.sizeLabel);
  }

  String _modelRowValue(BuildContext context, ModelSpec model,
      List<ModelState<ModelSpec>>? states, String sizeLabel) {
    final state = states
        ?.where((s) => s.model.tier == model.tier)
        .firstOrNull;
    return switch (state?.status ?? ModelStatus.notInstalled) {
      ModelStatus.ready =>
        context.l10n.modelInstalled(model.label, sizeLabel),
      ModelStatus.downloading => context.l10n
          .modelDownloading(model.label, (state!.progress * 100).round()),
      _ => context.l10n.modelNotDownloaded(model.label),
    };
  }

  void _pickModel(BuildContext context, Widget dialog) {
    showDialog<void>(context: context, builder: (_) => dialog);
  }

  void _about(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.aboutTitle),
        content: Text(context.l10n.aboutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.ok),
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
      title: context.l10n.modelPickerTranscriptionTitle,
      states: states,
      selectedTier: settings.whisperTier,
      enabledOf: (model) => deviceCanRun(model as WhisperModel),
      disabledReason: context.l10n.needsRam(5),
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
    final l10n = context.l10n;
    await repo.setWhisperTier(state.model.tier);
    manager.cancelExcept(state.model.tier);
    await downloadAndDrain(messenger, ref, state,
        download: () => manager.download(state.model as WhisperModel),
        readyMessage: l10n.modelReadyTranscribe(state.model.label),
        failedMessage: l10n.downloadFailed(state.model.label));
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
      title: context.l10n.modelPickerSummaryTitle,
      states: states,
      selectedTier: settings.llmTier,
      enabledOf: (model) => deviceHasRamGb((model as LlmModel).minRamGb),
      disabledReason: context.l10n.needsRam(LlmModel.qwen3_4b.minRamGb),
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
    final l10n = context.l10n;
    await repo.setLlmTier(state.model.tier);
    manager.cancelExcept(state.model.tier);
    await downloadAndDrain(messenger, ref, state,
        download: () => manager.download(state.model as LlmModel),
        readyMessage: l10n.modelReadySummarize(state.model.label),
        failedMessage: l10n.downloadFailed(state.model.label));
  }
}

/// Shared select flow: an installed tier just drains the queue; an absent
/// one downloads first (§14 model-missing recovery). Selecting a tier
/// cancels any other tier still downloading (§5.6) — the cancelled future
/// stays silent here, only real failures earn the snackbar.
Future<void> downloadAndDrain(
  ScaffoldMessengerState messenger,
  WidgetRef ref,
  ModelState<ModelSpec> state, {
  required Future<void> Function() download,
  required String readyMessage,
  required String failedMessage,
}) async {
  final queue = ref.read(jobQueueProvider);

  if (state.status != ModelStatus.notInstalled) {
    await queue.drain();
    return;
  }
  try {
    await download();
    messenger.showSnackBar(SnackBar(content: Text(readyMessage)));
    await queue.drain();
  } on ModelDownloadCancelled {
    // A newer tier choice aborted this one; the new download reports.
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
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
            context.l10n.storageNote(usedMb),
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
      ModelStatus.ready => context.l10n.pickerInstalled(model.sizeLabel),
      ModelStatus.downloading =>
        context.l10n.pickerDownloading((state.progress * 100).round()),
      ModelStatus.notInstalled => enabled
          ? context.l10n.pickerDownload(model.sizeLabel)
          : disabledReason,
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
                      tooltip: context.l10n.deleteModelTooltip,
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
                  child: InkProgressBar(fraction: state.progress),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

