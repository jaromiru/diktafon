import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../../domain/tape.dart';

/// Snapshot of playback on the global timeline (§4.2).
class TapePlaybackState {
  const TapePlaybackState({
    required this.globalMs,
    required this.totalMs,
    required this.memoIndex,
    required this.playing,
    required this.completed,
  });

  static const idle = TapePlaybackState(
    globalMs: 0,
    totalMs: 0,
    memoIndex: 0,
    playing: false,
    completed: false,
  );

  final int globalMs;
  final int totalMs;

  /// Index into the tape's memo list of the memo under the playhead.
  final int memoIndex;
  final bool playing;
  final bool completed;
}

/// Continuous playback (§6.4, D5): the tape is a concatenation of the memos'
/// files in chronological order — gapless auto-advance, one global position.
/// All seeks/scrubs/±15 s translate through Tape.locate (§4.2).
class TapePlayerService {
  TapePlayerService() {
    _positionSub = _player
        .createPositionStream(
          minPeriod: const Duration(milliseconds: 100),
          maxPeriod: const Duration(milliseconds: 200),
        )
        .listen((_) => _emit());
    _playingSub = _player.playingStream.listen((_) => _emit());
    _indexSub = _player.currentIndexStream.listen((_) => _emit());
    _stateSub = _player.processingStateStream.listen((state) {
      // NOTE(M4): natural forward advance across a memo boundary is where the
      // boundary chime hooks in (D5) — overlaid on a second player so the
      // main tape stays gapless.
      if (state == ProcessingState.completed) _player.pause();
      _emit();
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final _stateController = StreamController<TapePlaybackState>.broadcast();

  late final StreamSubscription<void> _positionSub;
  late final StreamSubscription<void> _playingSub;
  late final StreamSubscription<void> _indexSub;
  late final StreamSubscription<void> _stateSub;

  Tape _tape = Tape(const []);
  Tape get tape => _tape;

  Stream<TapePlaybackState> get stateStream => _stateController.stream;

  TapePlaybackState get state {
    if (_tape.isEmpty) return TapePlaybackState.idle;
    final index =
        (_player.currentIndex ?? 0).clamp(0, _tape.memoCount - 1);
    final localMs = _player.position.inMilliseconds
        .clamp(0, _tape.memos[index].durationMs);
    return TapePlaybackState(
      globalMs: _tape.toGlobalMs(index, localMs),
      totalMs: _tape.totalDurationMs,
      memoIndex: index,
      playing: _player.playing,
      completed: _player.processingState == ProcessingState.completed,
    );
  }

  void _emit() {
    if (!_stateController.isClosed) _stateController.add(state);
  }

  /// (Re)loads the tape. On memo add/delete the tape re-flows (§4.2); the
  /// playhead stays at the same global position when it still exists.
  Future<void> load(Tape tape, {bool preservePosition = true}) async {
    final wasPlaying = _player.playing;
    final previousGlobalMs = preservePosition ? state.globalMs : 0;
    _tape = tape;
    if (tape.isEmpty) {
      await _player.stop();
      await _player.clearAudioSources();
      _emit();
      return;
    }
    TapePosition? position;
    if (previousGlobalMs > 0 && previousGlobalMs < tape.totalDurationMs) {
      position = tape.locate(previousGlobalMs);
    }
    await _player.setAudioSources(
      [for (final memo in tape.memos) AudioSource.file(memo.filePath)],
      initialIndex: position?.memoIndex ?? 0,
      initialPosition: Duration(milliseconds: position?.localMs ?? 0),
      preload: false,
    );
    if (wasPlaying) _player.play();
    _emit();
  }

  Future<void> playPause() async {
    if (_tape.isEmpty) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      // Play again from the top once the tape has run out.
      if (_player.processingState == ProcessingState.completed ||
          state.globalMs >= _tape.totalDurationMs) {
        await seekGlobal(0);
      }
      _player.play();
    }
  }

  /// Newest requested target while a seek is in flight — scrub gestures fire
  /// faster than seeks complete, so intermediate targets are dropped.
  int? _seekTargetMs;
  bool _seekInFlight = false;

  Future<void> seekGlobal(int globalMs) async {
    if (_tape.isEmpty) return;
    _seekTargetMs = globalMs;
    if (_seekInFlight) return; // the running loop picks up the new target
    _seekInFlight = true;
    try {
      while (_seekTargetMs != null) {
        final targetMs = _seekTargetMs!;
        _seekTargetMs = null;
        await _seekTo(_tape.locate(targetMs));
      }
    } finally {
      _seekInFlight = false;
    }
    _emit();
  }

  /// Seeking with an `index:` is broken on media_kit: any indexed seek becomes
  /// an mpv `playlist-pos` write, which (re)loads that entry — even when the
  /// index is unchanged — and mpv rejects in-file seeks ("error running
  /// command") until the reloaded entry finishes its playback restart, so the
  /// seek's target position was silently lost and playback landed at 0:00.
  /// So: seek plainly within the current memo, and on a memo change jump
  /// first, wait for the new entry's restart — observable as the first
  /// buffering→ready edge reported for the new index — then seek.
  Future<void> _seekTo(TapePosition position) async {
    final localPosition = Duration(milliseconds: position.localMs);
    if (position.memoIndex == (_player.currentIndex ?? 0)) {
      await _player.seek(localPosition);
      return;
    }
    final needsLocalSeek = position.localMs > 0;
    final wasPlaying = _player.playing;
    // Pause across the jump so the new memo's first instant doesn't blip
    // out before the deferred in-file seek lands.
    if (wasPlaying && needsLocalSeek) await _player.pause();
    var sawBuffering = false;
    final restarted = _player.playbackEventStream
        .skip(1) // skip the replayed pre-jump event
        .firstWhere((e) {
          sawBuffering |= e.processingState == ProcessingState.buffering;
          return sawBuffering &&
              e.currentIndex == position.memoIndex &&
              e.processingState == ProcessingState.ready;
        })
        .then<void>((_) {}, onError: (_) {})
        .timeout(const Duration(milliseconds: 1500), onTimeout: () {});
    await _player.seek(null, index: position.memoIndex);
    if (needsLocalSeek) {
      await restarted;
      // A newer scrub target supersedes this one; the loop handles it.
      if (_seekTargetMs == null) await _player.seek(localPosition);
    }
    if (wasPlaying && needsLocalSeek) _player.play();
  }

  /// Tape-deck rewind / fast-forward: ±15 s on the global timeline, crossing
  /// memo boundaries transparently (§5.3).
  Future<void> skipBy(int deltaMs) =>
      seekGlobal((state.globalMs + deltaMs).clamp(0, _tape.totalDurationMs));

  Future<void> pause() => _player.pause();

  Future<void> dispose() async {
    await _positionSub.cancel();
    await _playingSub.cancel();
    await _indexSub.cancel();
    await _stateSub.cancel();
    await _stateController.close();
    await _player.dispose();
  }
}
