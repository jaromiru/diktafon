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

/// First-run setup (§5.6, mockup 01): privacy statement → microphone →
/// model provisioning. Recording unblocks the moment the transcription
/// model is ready; the LLM keeps downloading in the background. A quiet
/// skip link keeps capture zero-friction (design pillar 3) — a memo
/// recorded without models simply waits, per §14.
class FirstRunScreen extends ConsumerStatefulWidget {
  const FirstRunScreen({super.key});

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  int _step = 0; // 0 privacy · 1 microphone · 2 models
  bool? _micGranted;
  bool _whisperFailed = false, _llmFailed = false;
  bool _finishing = false;

  Future<void> _requestMicrophone() async {
    final granted =
        await ref.read(recorderServiceProvider).hasPermission();
    if (!mounted) return;
    setState(() {
      _micGranted = granted;
      _step = 2;
    });
    unawaited(_provisionModels());
  }

  /// The selected tier out of a manager's catalog (not the static one —
  /// tests swap in local-server specs).
  static M _forTier<M extends ModelSpec>(List<M> catalog, String tier) =>
      catalog.firstWhere((m) => m.tier == tier, orElse: () => catalog.first);

  /// Sequential on purpose (§5.6): the small whisper model first so the
  /// record key goes live early; the big LLM afterwards, in the background.
  Future<void> _provisionModels() async {
    final settings = await ref.read(settingsRepositoryProvider).get();
    final whisper = ref.read(whisperModelManagerProvider);
    final llm = ref.read(llmModelManagerProvider);
    try {
      await whisper.download(_forTier(whisper.catalog, settings.whisperTier));
      if (mounted) unawaited(ref.read(jobQueueProvider).drain());
    } catch (_) {
      if (mounted) setState(() => _whisperFailed = true);
      return; // retry restarts the chain, LLM included
    }
    try {
      await llm.download(_forTier(llm.catalog, settings.llmTier));
      if (mounted) unawaited(ref.read(jobQueueProvider).drain());
    } catch (_) {
      if (mounted) setState(() => _llmFailed = true);
    }
  }

  Future<void> _retryProvisioning() async {
    setState(() {
      _whisperFailed = false;
      _llmFailed = false;
    });
    await _provisionModels();
  }

  /// START RECORDING: first cassette opens with the mic already rolling.
  /// The route is pushed before firstRunDone flips so the home swap
  /// (FirstRunScreen → HomeScreen) happens underneath it.
  Future<void> _startRecording() async {
    if (_finishing) return;
    _finishing = true;
    final cassette = await ref.read(cassetteRepositoryProvider).create();
    if (!mounted) return;
    unawaited(Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            CassetteScreen(cassetteId: cassette.id, autoRecord: true))));
    await ref.read(settingsRepositoryProvider).setFirstRunDone();
  }

  Future<void> _skip() async {
    if (_finishing) return;
    _finishing = true;
    await ref.read(settingsRepositoryProvider).setFirstRunDone();
  }

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
              children: [
                _StepDots(current: _step),
                const SizedBox(height: 26),
                ...switch (_step) {
                  0 => _privacyStep(tape),
                  1 => _microphoneStep(tape),
                  _ => _modelsStep(tape),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _privacyStep(TapeColors tape) => [
        _headline(context.l10n.firstRunWelcome),
        _sub(tape, context.l10n.firstRunTagline),
        const SizedBox(height: 22),
        _PrivacyCard(
          title: context.l10n.privacyCardTitle,
          body: context.l10n.privacyCardBody,
        ),
        const SizedBox(height: 30),
        _CtaKey(
          label: context.l10n.continueKey,
          onPressed: () => setState(() => _step = 1),
        ),
      ];

  List<Widget> _microphoneStep(TapeColors tape) => [
        _headline(context.l10n.micHeadline),
        _sub(tape, context.l10n.micBody),
        const SizedBox(height: 30),
        _CtaKey(
          icon: Icons.mic_none,
          label: context.l10n.allowMicrophone,
          onPressed: _requestMicrophone,
        ),
      ];

  List<Widget> _modelsStep(TapeColors tape) {
    final settings =
        ref.watch(settingsProvider).value ?? const AppSettings();
    final whisperModel = _forTier(
        ref.read(whisperModelManagerProvider).catalog, settings.whisperTier);
    final llmModel = _forTier(
        ref.read(llmModelManagerProvider).catalog, settings.llmTier);
    final whisper = _stateOf(
        ref.watch(whisperModelStatesProvider).value, whisperModel.tier);
    final llm =
        _stateOf(ref.watch(llmModelStatesProvider).value, llmModel.tier);
    final whisperReady = whisper?.status == ModelStatus.ready;
    final l10n = context.l10n;

    return [
      _headline(l10n.modelsHeadline),
      _sub(tape, l10n.firstRunTagline),
      const SizedBox(height: 22),
      _ProvisionRow(
        ok: _micGranted == true,
        title: l10n.rowMicrophone,
        caption: _micGranted == true
            ? l10n.accessGranted
            : l10n.micNotGranted,
      ),
      _ProvisionRow(
        ok: whisperReady,
        title: l10n.rowTranscription,
        caption: _whisperFailed
            ? l10n.provisionFailedRetry
            : switch (whisper?.status) {
                ModelStatus.ready => l10n.provisionReady(
                    whisperModel.label, whisperModel.sizeLabel),
                ModelStatus.downloading => l10n.provisionDownloading(
                    whisperModel.sizeLabel,
                    ((whisper?.progress ?? 0) * 100).round()),
                _ => l10n.provisionWaiting,
              },
        progress: whisper?.status == ModelStatus.downloading
            ? whisper?.progress
            : null,
        onTap: _whisperFailed ? _retryProvisioning : null,
      ),
      _ProvisionRow(
        ok: llm?.status == ModelStatus.ready,
        title: l10n.rowSummaries,
        caption: _llmFailed
            ? l10n.provisionFailedRetry
            : switch (llm?.status) {
                ModelStatus.ready =>
                  l10n.provisionReady(llmModel.label, llmModel.sizeLabel),
                ModelStatus.downloading => l10n.provisionDownloading(
                    llmModel.sizeLabel,
                    ((llm?.progress ?? 0) * 100).round()),
                _ => l10n.provisionWaiting,
              },
        progress:
            llm?.status == ModelStatus.downloading ? llm?.progress : null,
        note: llm?.status == ModelStatus.downloading
            ? l10n.finishesInBackground
            : null,
        onTap: _llmFailed ? _retryProvisioning : null,
      ),
      const SizedBox(height: 30),
      _CtaKey(
        icon: Icons.mic_none,
        label: l10n.startRecordingKey,
        onPressed: whisperReady ? _startRecording : null,
      ),
      const SizedBox(height: 14),
      Center(
        child: TextButton(
          onPressed: _skip,
          child: Text(
            l10n.setUpLater,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: context.tape.ink2,
                decoration: TextDecoration.underline,
                decorationColor: context.tape.ink2),
          ),
        ),
      ),
    ];
  }

  ModelState<ModelSpec>? _stateOf(
          List<ModelState<ModelSpec>>? states, String tier) =>
      states?.where((s) => s.model.tier == tier).firstOrNull;

  Widget _headline(String text) => Text(
        text,
        style: TextStyle(
            fontFamily: displayFont,
            fontSize: 34,
            height: 1.05,
            color: context.tape.ink),
      );

  Widget _sub(TapeColors tape, String text) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          text,
          style: TextStyle(fontSize: 12.5, height: 1.55, color: tape.ink2),
        ),
      );
}

/// The three step markers (mockup 01) — squares, current one in ink.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    return Row(
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(right: 7),
            decoration: BoxDecoration(
              color: i == current ? tape.ink : null,
              border: Border.all(color: tape.ink, width: 1.5),
            ),
          ),
      ],
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tape.surface,
        border: Border.all(color: tape.ink, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 12),
            child: Icon(Icons.lock_outline, size: 24, color: tape.ink),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(body,
                    style: TextStyle(
                        fontSize: 11, height: 1.5, color: tape.ink2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One provision row (mockup 01): ok-mark / download-mark, bold title,
/// status caption, optional progress channel and helper note.
class _ProvisionRow extends StatelessWidget {
  const _ProvisionRow({
    required this.ok,
    required this.title,
    required this.caption,
    this.progress,
    this.note,
    this.onTap,
  });

  final bool ok;
  final String title;
  final String caption;
  final double? progress;
  final String? note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tape = context.tape;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1, right: 12),
              child: Icon(
                ok ? Icons.check : Icons.south,
                size: 20,
                color: ok ? tape.ink : tape.ink2,
              ),
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
                          fontSize: 10.5,
                          height: 1.45,
                          color: tape.ink2,
                          decoration:
                              onTap == null ? null : TextDecoration.underline,
                          decorationColor: tape.ink2)),
                  if (progress != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: InkProgressBar(fraction: progress!),
                    ),
                  if (note != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(note!,
                          style:
                              TextStyle(fontSize: 10.5, color: tape.ink2)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The single primary action per screen (mockup 01 note 4): a wide ink key
/// in the display face with the cardstock shadow.
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
          opacity: enabled ? 1 : 0.45,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: tape.ink,
              border: Border.all(color: tape.ink, width: 2),
              boxShadow: [
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
