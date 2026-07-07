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

  Future<void> seekGlobal(int globalMs) async {
    if (_tape.isEmpty) return;
    final position = _tape.locate(globalMs);
    await _player.seek(
      Duration(milliseconds: position.localMs),
      index: position.memoIndex,
    );
    _emit();
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
