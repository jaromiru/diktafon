import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../application/recording_controller.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models.dart';
import '../../domain/tape.dart';
import '../../l10n/l10n.dart';
import '../../services/audio/tape_player_service.dart';
import '../../services/providers/transcription_provider.dart';
import '../../services/system/system_settings.dart';
import '../theme/tape_colors.dart';
import '../theme/theme.dart';
import '../widgets/deck.dart';
import '../widgets/level_meter.dart';
import '../widgets/timeline_bar.dart';
import '../widgets/transcript_view.dart';
import 'home_screen.dart';

/// Cassette view — the core screen (§5.3, mockups 03/04): header, LCD
/// counter, the timeline, the whole-tape transcript and the deck keys.
class CassetteScreen extends ConsumerStatefulWidget {
  const CassetteScreen({super.key, required this.cassetteId});

  final String cassetteId;

  @override
  ConsumerState<CassetteScreen> createState() => _CassetteScreenState();
}

class _CassetteScreenState extends ConsumerState<CassetteScreen> {
  String _loadedTapeSignature = '';
  bool _summaryExpanded = false;

  @override
  void initState() {
    super.initState();
    // Keep the player in sync with the tape: initial load + re-flow on
    // memo add/delete (§4.2) while preserving the global position.
    ref.listenManual(
      tapeProvider(widget.cassetteId),
      (_, tape) => _loadTape(tape),
      fireImmediately: true,
    );
  }

  Future<void> _loadTape(Tape tape) async {
    final signature = tape.memos
        .map((m) => '${m.id}:${m.durationMs}')
        .join('|');
    if (signature == _loadedTapeSignature) return;
    _loadedTapeSignature = signature;
    await ref.read(tapePlayerProvider).load(tape);
  }

  @override
  void deactivate() {
    // M1 has no lock-screen controls yet: leaving the cassette stops the
    // session. An in-flight recording is finalized, never lost (§14).
    final recording = ref.read(recordingControllerProvider);
    if (recording.isRecordingIn(widget.cassetteId)) {
      unawaited(ref.read(recordingControllerProvider.notifier).stop());
    }
    unawaited(ref.read(tapePlayerProvider).pause());
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final tapeColors = context.tape;
    final cassette = ref.watch(cassetteProvider(widget.cassetteId)).value;
    final tape = ref.watch(tapeProvider(widget.cassetteId));
    final playback = ref.watch(playbackProvider).value ??
        ref.read(tapePlayerProvider).state;
    final recording = ref.watch(recordingControllerProvider);
    final isRecordingHere = recording.isRecordingIn(widget.cassetteId);
    final player = ref.read(tapePlayerProvider);

    if (cassette == null) {
      // Deleted while open (e.g. from a dialog) — nothing to show.
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          tooltip: context.l10n.back,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: GestureDetector(
          onTap: () => _rename(cassette),
          child: Text(
            cassette.label ?? context.l10n.untitledCassette,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: cassette.label == null
                ? TextStyle(
                    fontFamily: bodyFont,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: tapeColors.ink2,
                  )
                : const TextStyle(fontSize: 24),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 22),
            onSelected: (action) => switch (action) {
              'rename' => _rename(cassette),
              'color' => showCassetteColorDialog(
                  context,
                  ref,
                  cassetteId: cassette.id,
                  currentSeed: cassette.colorSeed,
                ),
              'retranscribe' => _retranscribe(cassette, tape.memoCount),
              _ => _deleteCassette(cassette, tape.memoCount),
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'rename', child: Text(context.l10n.rename)),
              PopupMenuItem(
                  value: 'color', child: Text(context.l10n.changeColor)),
              PopupMenuItem(
                  value: 'retranscribe',
                  enabled: !tape.isEmpty,
                  child: Text(context.l10n.retranscribe)),
              PopupMenuItem(
                  value: 'delete', child: Text(context.l10n.deleteCassette)),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isRecordingHere) _summaryLine(cassette),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: _tapeTop(playback, tape, recording, isRecordingHere),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: TimelineBar(
              tape: tape,
              colorSeed: cassette.colorSeed,
              globalMs: playback.globalMs,
              recordingElapsed: isRecordingHere ? recording.elapsed : null,
              onScrub: (ms) => player.seekGlobal(ms),
              onJumpToMemo: (i) =>
                  player.seekGlobal(tape.offsetsMs[i]),
              onDeleteMemo: (i) => _deleteMemo(tape.memos[i], i),
            ),
          ),
          Expanded(
            child: tape.isEmpty && !isRecordingHere
                ? Center(
                    child: Text(
                      context.l10n.blankTape,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: tapeColors.ink2),
                    ),
                  )
                : AnimatedOpacity(
                    // Context dims while capture takes over (mockup 04).
                    opacity: isRecordingHere ? 0.55 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TranscriptView(
                      tape: tape,
                      colorSeed: cassette.colorSeed,
                      globalMs: playback.globalMs,
                      currentMemoIndex: playback.memoIndex,
                      playing: playback.playing,
                      modelReady: _modelReady(),
                      onSeekGlobalMs: (ms) => player.seekGlobal(ms),
                      onRetryMemo: (memoId) => ref
                          .read(jobQueueProvider)
                          .retryEnrichment(memoId),
                      onDeleteMemo: (i) => _deleteMemo(tape.memos[i], i),
                    ),
                  ),
          ),
          if (isRecordingHere)
            _RecordingPanel(elapsed: recording.elapsed)
          else
            _deck(playback, tape),
        ],
      ),
    );
  }

  /// Is the selected transcription tier provisioned? Decides the caption an
  /// untranscribed memo shows (§14 guides the user to Settings → Models).
  bool _modelReady() {
    final tier =
        (ref.watch(settingsProvider).value ?? const AppSettings()).whisperTier;
    final states = ref.watch(whisperModelStatesProvider).value;
    return states
            ?.any((s) => s.model.tier == tier && s.status == ModelStatus.ready) ??
        false;
  }

  Widget _summaryLine(Cassette cassette) {
    final tapeColors = context.tape;
    final summary =
        cassette.summary ?? context.l10n.summaryPlaceholder;
    return Semantics(
      button: true,
      expanded: _summaryExpanded,
      child: GestureDetector(
        onTap: () => setState(() => _summaryExpanded = !_summaryExpanded),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  summary,
                  maxLines: _summaryExpanded ? null : 2,
                  overflow: _summaryExpanded ? null : TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: tapeColors.ink2,
                    fontStyle:
                        cassette.summary == null ? FontStyle.italic : null,
                  ),
                ),
              ),
              Icon(
                _summaryExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 16,
                color: tapeColors.ink2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "MEMO 7 / 8    18:22 / 21:47" — the LCD counter row (mockup 03), turning
  /// red with a pulsing dot while recording (mockup 04).
  Widget _tapeTop(TapePlaybackState playback, Tape tape,
      RecordingState recording, bool isRecordingHere) {
    final tapeColors = context.tape;
    if (isRecordingHere) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _RecDot(color: tapeColors.rec),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              context.l10n.recordingMemo(tape.memoCount + 1),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: tapeColors.rec,
              ),
            ),
          ),
          Text(
            formatMs(recording.elapsed.inMilliseconds),
            style: lcdStyle(context, color: tapeColors.rec),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            tape.isEmpty
                ? context.l10n.emptyTape
                : context.l10n
                    .memoCounter(playback.memoIndex + 1, tape.memoCount),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: tapeColors.ink2,
            ),
          ),
        ),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: formatMs(playback.globalMs)),
            TextSpan(
              text: ' / ${formatMs(tape.totalDurationMs)}',
              style: TextStyle(color: tapeColors.ink2),
            ),
          ]),
          style: lcdStyle(context, color: tapeColors.ink),
        ),
      ],
    );
  }

  /// Transport (§5.3): rewind / play–pause / fast-forward, record at the
  /// right end. All hops are global across memo boundaries (D5).
  Widget _deck(TapePlaybackState playback, Tape tape) {
    final tapeColors = context.tape;
    final player = ref.read(tapePlayerProvider);
    return Container(
      decoration: BoxDecoration(
        color: tapeColors.surface,
        border: Border(top: BorderSide(color: tapeColors.ink, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            DeckKey(
              glyph: DeckGlyph.rewind,
              semanticLabel: context.l10n.back15,
              onPressed: tape.isEmpty ? null : () => player.skipBy(-15000),
            ),
            const SizedBox(width: 10),
            DeckKey(
              glyph: playback.playing ? DeckGlyph.pause : DeckGlyph.play,
              style: DeckKeyStyle.ink,
              width: 64,
              semanticLabel: playback.playing
                  ? context.l10n.pause
                  : context.l10n.play,
              onPressed: tape.isEmpty ? null : player.playPause,
            ),
            const SizedBox(width: 10),
            DeckKey(
              glyph: DeckGlyph.fastForward,
              semanticLabel: context.l10n.forward15,
              onPressed: tape.isEmpty ? null : () => player.skipBy(15000),
            ),
            const Spacer(),
            DeckKey(
              glyph: DeckGlyph.record,
              style: DeckKeyStyle.record,
              semanticLabel: context.l10n.recordNewMemo,
              onPressed: _startRecording,
            ),
          ],
        ),
      ),
    );
  }

  /// The record tap itself asks for the mic permission (the recorder fires
  /// the OS prompt when it's missing) — the bubble appears only after a
  /// denial, with a road back for the "don't ask again" case.
  Future<void> _startRecording() async {
    final ok = await ref
        .read(recordingControllerProvider.notifier)
        .start(widget.cassetteId);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.micPermissionNeeded),
        action: !Platform.isAndroid
            ? null
            : SnackBarAction(
                label: context.l10n.openSystemSettings,
                onPressed: openAppSystemSettings,
              ),
      ));
    }
  }

  Future<void> _rename(Cassette cassette) => showRenameCassetteDialog(
        context,
        ref,
        cassetteId: cassette.id,
        currentLabel: cassette.label,
      );

  /// Re-transcribe the whole cassette — for when a more capable model was
  /// installed after the fact. Destructive to the existing texts, so it
  /// confirms with a note before the queue wipes and re-enriches.
  Future<void> _retranscribe(Cassette cassette, int memoCount) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.retranscribeTitle),
            content: Text(l10n.retranscribeBody(memoCount)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.retranscribeAction),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await ref.read(jobQueueProvider).retranscribeCassette(cassette.id);
  }

  Future<void> _deleteCassette(Cassette cassette, int memoCount) async {
    final deleted = await confirmDeleteCassette(
      context,
      ref,
      cassetteId: cassette.id,
      label: cassette.label,
      memoCount: memoCount,
    );
    if (deleted && mounted) Navigator.of(context).pop();
  }

  /// Long-press a segment → delete memo (§5.3); the tape re-flows (§4.2).
  Future<void> _deleteMemo(Memo memo, int ordinalIndex) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.deleteMemoTitle),
            content: Text(l10n.deleteMemoBody(ordinalIndex + 1)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(
                    foregroundColor: dialogContext.tape.rec),
                child: Text(l10n.deleteAction),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    // §14 "delete during processing": cancel jobs, remove row + audio, then
    // let the queue schedule the cassette-summary recompute.
    await ref.read(jobQueueProvider).cancelJobsFor(memo.id);
    await ref.read(memoRepositoryProvider).delete(memo.id);
    await ref.read(audioFileStoreProvider).deleteMemoFile(memo.filePath);
    await ref.read(cassetteRepositoryProvider).touch(memo.cassetteId);
    await ref.read(jobQueueProvider).onMemoDeleted(memo);
  }
}

class _RecDot extends StatefulWidget {
  const _RecDot({required this.color});

  final Color color;

  @override
  State<_RecDot> createState() => _RecDotState();
}

class _RecDotState extends State<_RecDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final wave = t < 0.5 ? t * 2 : (1 - t) * 2;
          return Opacity(
            opacity: 1 - 0.55 * wave,
            child: Container(width: 8, height: 8, color: widget.color),
          );
        },
      );
}

/// The recording panel (mockup 04): LCD elapsed, level meter, one STOP key.
class _RecordingPanel extends ConsumerStatefulWidget {
  const _RecordingPanel({required this.elapsed});

  final Duration elapsed;

  @override
  ConsumerState<_RecordingPanel> createState() => _RecordingPanelState();
}

class _RecordingPanelState extends ConsumerState<_RecordingPanel> {
  final List<double> _levels = [];
  StreamSubscription<dynamic>? _amplitudeSub;

  @override
  void initState() {
    super.initState();
    _amplitudeSub = ref
        .read(recorderServiceProvider)
        .amplitudeStream()
        .listen((amplitude) {
      setState(() {
        _levels.add(amplitude.current.toDouble());
        if (_levels.length > 60) _levels.removeAt(0);
      });
    });
  }

  @override
  void dispose() {
    _amplitudeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tapeColors = context.tape;
    return Container(
      decoration: BoxDecoration(
        color: tapeColors.surface,
        border: Border(top: BorderSide(color: tapeColors.ink, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatMs(widget.elapsed.inMilliseconds),
              style: lcdStyle(context, size: 56, color: tapeColors.ink),
            ),
            const SizedBox(height: 13),
            LevelMeter(levelsDb: _levels),
            const SizedBox(height: 13),
            DeckKey(
              glyph: DeckGlyph.stop,
              style: DeckKeyStyle.record,
              width: 70,
              height: 56,
              semanticLabel: context.l10n.stopRecording,
              onPressed: () =>
                  ref.read(recordingControllerProvider.notifier).stop(),
            ),
          ],
        ),
      ),
    );
  }
}
