import 'dart:async';
import 'dart:io';

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
    this.seekCount = 0,
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

  /// Bumped on every user seek (scrub, word tap, memo jump, ±15 s) — lets
  /// the transcript follow the playhead on navigation without also chasing
  /// it on every position tick of normal playback.
  final int seekCount;
}

/// The chime fires only when the tape rolls forward into the next memo by
/// itself (§5.4): playing, one step ahead, and not because a seek/scrub/±15 s
/// or a tape (re)load moved the index.
bool isNaturalAdvance({
  required int? from,
  required int? to,
  required bool playing,
  required bool seeking,
  required bool loading,
}) =>
    playing && !seeking && !loading && from != null && to == from + 1;

/// Continuous playback (§6.4, D5): the tape is a concatenation of the memos'
/// files in chronological order — gapless auto-advance, one global position.
/// All seeks/scrubs/±15 s translate through Tape.locate (§4.2).
class TapePlayerService {
  TapePlayerService({this.chimeFilePath}) {
    _positionSub = _player
        .createPositionStream(
          minPeriod: const Duration(milliseconds: 100),
          maxPeriod: const Duration(milliseconds: 200),
        )
        .listen((_) => _emit());
    _playingSub = _player.playingStream.listen((_) => _emit());
    _indexSub = _player.currentIndexStream.listen((index) {
      final from = _lastIndex;
      _lastIndex = index;
      if (isNaturalAdvance(
        from: from,
        to: index,
        playing: _player.playing,
        seeking: _seekInFlight,
        loading: _loading,
      )) {
        _playChime();
      }
      _emit();
    });
    _stateSub = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _player.pause();
      _emit();
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final _stateController = StreamController<TapePlaybackState>.broadcast();

  /// D5: a short cue as the tape rolls into the next memo, overlaid on a
  /// second player so the main tape stays gapless. Off → fully seamless.
  bool chimeEnabled = true;

  /// Materialized by main(); null (tests, missing asset) → no chime.
  final String? chimeFilePath;
  AudioPlayer? _chimePlayer;
  int? _lastIndex;
  bool _loading = false;

  Future<void> _playChime() async {
    final path = chimeFilePath;
    if (!chimeEnabled || path == null) return;
    try {
      final chime = _chimePlayer ??= AudioPlayer();
      if (chime.audioSource == null) {
        await chime.setAudioSource(AudioSource.file(path));
      }
      await chime.seek(Duration.zero);
      unawaited(chime.play());
    } catch (_) {
      // Best-effort orientation cue — never disturb playback over it.
    }
  }

  late final StreamSubscription<void> _positionSub;
  late final StreamSubscription<void> _playingSub;
  late final StreamSubscription<void> _indexSub;
  late final StreamSubscription<void> _stateSub;

  Tape _tape = Tape(const []);
  Tape get tape => _tape;

  Stream<TapePlaybackState> get stateStream => _stateController.stream;

  TapePlaybackState get state {
    if (_tape.isEmpty) return TapePlaybackState.idle;
    // While a seek is in flight, report its target: crossing a memo boundary
    // the player transiently sits at the new memo's 0:00 (the deferred
    // in-file seek hasn't landed yet) — showing that would flick the cursor
    // to the memo start mid-scrub.
    final seekMs = _seekDisplayMs;
    if (seekMs != null) {
      final clamped = seekMs.clamp(0, _tape.totalDurationMs);
      return TapePlaybackState(
        globalMs: clamped,
        totalMs: _tape.totalDurationMs,
        memoIndex: _tape.locate(clamped).memoIndex,
        playing: _player.playing,
        completed: false,
        seekCount: _seekCount,
      );
    }
    // A seek before the first playback only re-arms the initial position
    // (see _seekTo) — the inactive player still reports 0:00, so answer
    // from the pending position until playback actually starts.
    final pending = _pendingIdleSeek;
    if (pending != null && _player.processingState == ProcessingState.idle) {
      final index = pending.memoIndex.clamp(0, _tape.memoCount - 1);
      return TapePlaybackState(
        globalMs: _tape.toGlobalMs(index, pending.localMs),
        totalMs: _tape.totalDurationMs,
        memoIndex: index,
        playing: _player.playing,
        completed: false,
        seekCount: _seekCount,
      );
    }
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
      seekCount: _seekCount,
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
    _pendingIdleSeek = null;
    _loading = true;
    try {
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
      await _setSources(position);
      if (wasPlaying) _player.play();
    } finally {
      _lastIndex = _player.currentIndex;
      _loading = false;
    }
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

  /// The tape's files handed to the player without preloading; [position]
  /// becomes the initial playhead when playback first starts.
  Future<void> _setSources(TapePosition? position) => _player.setAudioSources(
        [for (final memo in _tape.memos) AudioSource.file(memo.filePath)],
        initialIndex: position?.memoIndex ?? 0,
        initialPosition: Duration(milliseconds: position?.localMs ?? 0),
        preload: false,
      );

  /// Newest requested target while a seek is in flight — scrub gestures fire
  /// faster than seeks complete, so intermediate targets are dropped.
  int? _seekTargetMs;
  bool _seekInFlight = false;

  /// The target the UI should report while a seek is in flight (see [state]).
  int? _seekDisplayMs;

  /// See [TapePlaybackState.seekCount].
  int _seekCount = 0;

  /// Where playback should start when the user seeks before ever pressing
  /// play — the inactive player can't be seeked, only re-armed (see [state]
  /// and [_seekTo]).
  TapePosition? _pendingIdleSeek;

  Future<void> seekGlobal(int globalMs) async {
    if (_tape.isEmpty) return;
    _seekCount++;
    _seekTargetMs = globalMs;
    _seekDisplayMs = globalMs;
    _emit(); // reflect the newest target right away
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
      _seekDisplayMs = null;
    }
    _emit();
  }

  /// just_audio_media_kit (mpv) backs playback only on desktop Linux/Windows;
  /// the indexed-seek restart dance in [_seekTo] compensates for its playlist
  /// reload and must not run on ExoPlayer/AVPlayer (see below).
  static final bool _mpvBackend = Platform.isLinux || Platform.isWindows;

  /// Seeking with an `index:` is broken on media_kit: any indexed seek becomes
  /// an mpv `playlist-pos` write, which (re)loads that entry — even when the
  /// index is unchanged — and mpv rejects in-file seeks ("error running
  /// command") until the reloaded entry finishes its playback restart, so the
  /// seek's target position was silently lost and playback landed at 0:00.
  /// So: seek plainly within the current memo, and on a memo change jump
  /// first, wait for the new entry's restart — observable as the first
  /// buffering→ready edge reported for the new index — then seek.
  Future<void> _seekTo(TapePosition position) async {
    // Two just_audio traps around an inactive player (preload: false):
    //  - while loading, seek() is silently dropped — wait the load out;
    //  - while idle (nothing played yet), seek() *resets* the pending
    //    initial position, so a later play() would start at 0:00 instead of
    //    the sought spot. Reissue the sources with the target as the
    //    initial position — cheap while inactive — and let play() load there.
    if (_player.processingState == ProcessingState.loading) {
      await _player.processingStateStream
          .firstWhere((s) => s != ProcessingState.loading)
          .timeout(const Duration(seconds: 3),
              onTimeout: () => _player.processingState);
    }
    if (_player.processingState == ProcessingState.idle) {
      _pendingIdleSeek = position;
      await _setSources(position);
      return;
    }
    final localPosition = Duration(milliseconds: position.localMs);
    if (position.memoIndex == (_player.currentIndex ?? 0)) {
      await _player.seek(localPosition);
      return;
    }
    if (!_mpvBackend) {
      // ExoPlayer/AVPlayer take the index+position jump atomically. Never
      // pass a null position here: just_audio's darwin impl maps null to
      // kCMTimePositiveInfinity, i.e. AVPlayer seeks to the item's *end*.
      await _player.seek(localPosition, index: position.memoIndex);
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
    await _chimePlayer?.dispose();
    await _player.dispose();
  }
}
