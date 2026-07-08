import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/l10n.dart';
import '../../services/providers/model_manager.dart';
import '../../services/providers/transcription_provider.dart';
import '../theme/tape_colors.dart';
import '../theme/theme.dart';
import '../widgets/ink_progress_bar.dart';
import 'cassette_screen.dart';
import 'settings_screen.dart';

/// First-run setup (§5.6, mockup 01 r8): a single screen. The intro and the
/// privacy promise are one plain paragraph; a setup card holds the
/// microphone row (tapping it fires the OS prompt — the CTA's only gate)
/// and the two model rows. Nothing downloads on its own — the user may be
/// on a metered connection, so a row's picker (the exact one from Settings)
/// is where a model is chosen and its download starts. Downloads finish in
/// the background and never block the CTA. START RECORDING opens the first
/// cassette *empty* — the record key is armed, nothing rolls until pressed.
class FirstRunScreen extends ConsumerStatefulWidget {
  const FirstRunScreen({super.key});

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  bool? _micGranted; // null → not asked yet
  bool _finishing = false;

  /// The selected tier out of a manager's catalog (not the static one —
  /// tests swap in local-server specs). A plain loop on purpose: the
  /// catalogs are covariantly typed here, and firstWhere's orElse closure
  /// would trip the runtime check.
  static M _forTier<M extends ModelSpec>(List<M> catalog, String tier) {
    for (final model in catalog) {
      if (model.tier == tier) return model;
    }
    return catalog.first;
  }

  Future<void> _requestMicrophone() async {
    final granted = await ref.read(recorderServiceProvider).hasPermission();
    if (!mounted) return;
    setState(() => _micGranted = granted);
  }

  /// START RECORDING: the first cassette opens empty — record key armed,
  /// nothing rolls (mockup 01 note 4). The route is pushed before
  /// firstRunDone flips so the home swap (FirstRunScreen → HomeScreen)
  /// happens underneath it.
  Future<void> _startRecording() async {
    if (_finishing || _micGranted != true) return;
    _finishing = true;
    final cassette = await ref.read(cassetteRepositoryProvider).create();
    if (!mounted) return;
    unawaited(Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CassetteScreen(cassetteId: cassette.id))));
    await ref.read(settingsRepositoryProvider).setFirstRunDone();
  }

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
              children: [
                Text(
                  l10n.firstRunWelcome,
                  style: TextStyle(
                      fontFamily: displayFont,
                      fontSize: 34,
                      height: 1.05,
                      color: tape.ink),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _intro(tape, l10n.firstRunIntro),
                ),
                const SizedBox(height: 18),
                _setupCard(tape, l10n),
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 2, right: 2),
                  child: Text(l10n.downloadsFinishInBackground,
                      style: TextStyle(fontSize: 10.5, color: tape.ink2)),
                ),
                const SizedBox(height: 30),
                _CtaKey(
                  icon: Icons.mic,
                  label: l10n.startRecordingKey,
                  onPressed: _micGranted == true ? _startRecording : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The intro + privacy promise as one paragraph; the ARB marks the
  /// "never leave this device" span with `**…**` — rendered bold.
  Widget _intro(TapeColors tape, String text) {
    final parts = text.split('**');
    return Text.rich(
      TextSpan(children: [
        for (var i = 0; i < parts.length; i++)
          TextSpan(
              text: parts[i],
              style:
                  i.isOdd ? const TextStyle(fontWeight: FontWeight.w700) : null),
      ]),
      style: TextStyle(fontSize: 12.5, height: 1.55, color: tape.ink2),
    );
  }

  Widget _setupCard(TapeColors tape, AppLocalizations l10n) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    return Container(
      decoration: BoxDecoration(
        color: tape.surface,
        border: Border.all(color: tape.ink, width: 1.5),
      ),
      child: Column(
        children: [
          _micRow(tape, l10n),
          Divider(height: 1.5, color: tape.line),
          _modelRow(
            l10n: l10n,
            title: l10n.rowTranscription,
            model: _forTier(ref.read(whisperModelManagerProvider).catalog,
                settings.whisperTier),
            states: ref.watch(whisperModelStatesProvider).value,
            picker: const ModelPickerDialog(),
          ),
          Divider(height: 1.5, color: tape.line),
          _modelRow(
            l10n: l10n,
            title: l10n.rowSummaries,
            model: _forTier(
                ref.read(llmModelManagerProvider).catalog, settings.llmTier),
            states: ref.watch(llmModelStatesProvider).value,
            picker: const LlmModelPickerDialog(),
          ),
        ],
      ),
    );
  }

  /// Mic row (mockup 01 note 2): the row itself is the tap target for the
  /// OS prompt; once granted it flips to the green tick and goes inert.
  Widget _micRow(TapeColors tape, AppLocalizations l10n) {
    final granted = _micGranted == true;
    return _SetupRow(
      icon: granted ? Icons.check : Icons.mic,
      iconColor: granted ? tape.ok : tape.ink,
      title: granted ? l10n.rowMicrophone : l10n.allowMicRow,
      caption: switch (_micGranted) {
        true => l10n.accessGranted,
        false => l10n.micDeniedRetry,
        null => l10n.micTapToGrant,
      },
      onTap: granted ? null : _requestMicrophone,
    );
  }

  /// One engine row: a mirror of the selected tier's state. Choosing (and
  /// thereby downloading) happens in the picker — the row never starts a
  /// download by itself; failures report through the picker's snackbar and
  /// the row simply falls back to its "tap to choose" caption.
  Widget _modelRow({
    required AppLocalizations l10n,
    required String title,
    required ModelSpec model,
    required List<ModelState<ModelSpec>>? states,
    required Widget picker,
  }) {
    final tape = context.tape;
    final state =
        states?.where((s) => s.model.tier == model.tier).firstOrNull;
    final ready = state?.status == ModelStatus.ready;
    final downloading = state?.status == ModelStatus.downloading;
    void openPicker() =>
        showDialog<void>(context: context, builder: (_) => picker);
    return _SetupRow(
      icon: ready ? Icons.check : Icons.download,
      iconColor: ready ? tape.ok : tape.ink2,
      title: title,
      caption: switch (state?.status) {
        ModelStatus.ready => l10n.provisionReady(model.label, model.sizeLabel),
        ModelStatus.downloading => l10n.provisionDownloading(model.label,
            model.sizeLabel, ((state?.progress ?? 0) * 100).round()),
        _ => l10n.provisionChoose,
      },
      progress: downloading ? state?.progress : null,
      onTap: openPicker,
      onChevron: openPicker,
    );
  }
}

/// One setup-card row (mockup 01): status mark, bold title, caption,
/// optional progress channel, optional picker chevron (its own tap target).
class _SetupRow extends StatelessWidget {
  const _SetupRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.caption,
    this.progress,
    this.onTap,
    this.onChevron,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String caption;
  final double? progress;
  final VoidCallback? onTap;
  final VoidCallback? onChevron;

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1, right: 12),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(caption,
                      style: TextStyle(
                          fontSize: 10.5, height: 1.45, color: tape.ink2)),
                  if (progress != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: InkProgressBar(fraction: progress!),
                    ),
                ],
              ),
            ),
            if (onChevron != null)
              InkWell(
                onTap: onChevron,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child:
                      Icon(Icons.chevron_right, size: 18, color: tape.ink2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The single primary action (mockup 01 note 4): a wide ink key in the
/// display face with the cardstock shadow; dimmed flat while gated.
class _CtaKey extends StatelessWidget {
  const _CtaKey({required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        child: Opacity(
          opacity: enabled ? 1 : 0.35,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: tape.ink,
              border: Border.all(color: tape.ink, width: 2),
              boxShadow: [
                if (enabled)
                  BoxShadow(color: tape.line, offset: const Offset(3, 3)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 19, color: tape.paper),
                  const SizedBox(width: 9),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: displayFont,
                    fontSize: 21,
                    letterSpacing: 0.8,
                    color: tape.paper,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
