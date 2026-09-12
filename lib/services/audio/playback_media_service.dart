import 'dart:async';

import 'package:audio_service/audio_service.dart';

import 'tape_player_service.dart';

/// Lock-screen / notification media controls (M1): playback runs in a
/// media-type foreground session, so audio keeps going with the app
/// backgrounded or swiped away, and the system media notification (the
/// Spotify-style card) carries play/pause, the seek bar and skip-to-memo
/// buttons that drive the very same [TapePlayerService] the in-app deck
/// uses.
///
/// A pure forwarder by design: the tape player owns playback state and the
/// UI already renders its stream; this adapter mirrors that state into the
/// platform session and replays control intents back into the player, so
/// there is exactly one source of truth and zero behavior change for the
/// widget tree.
///
/// audio_service requires the session to exist before runApp, but the
/// player is created lazily by its provider — so the handler starts
/// unattached and [attach] wires the player in when the provider first
/// builds it. Controls arriving before that (shouldn't happen: nothing to
/// play yet) are ignored.
class TapePlaybackMediaHandler extends BaseAudioHandler {
  TapePlaybackMediaHandler();

  TapePlayerService? _player;
  StreamSubscription<TapePlaybackState>? _stateSub;

  /// Cached label of the loaded cassette: the notification's title.
  String? _cassetteLabel;

  /// Wires the app-wide tape player in (idempotent; a re-attach moves the
  /// subscription to the new player).
  void attach(TapePlayerService player) {
    _stateSub?.cancel();
    _player = player;
    _stateSub = player.stateStream.listen(_syncToSession);
  }

  /// Called when a tape loads so the notification names the right cassette.
  void setNowPlaying(String? label) => _cassetteLabel = label;

  @override
  Future<void> play() async => _player?.playPause();

  @override
  Future<void> pause() async => _player?.pause();

  /// The notification's seek bar reports absolute positions — exactly the
  /// tape's global timeline (§4.2).
  @override
  Future<void> seek(Duration position) async {
    final player = _player;
    if (player == null) return;
    await player.seekGlobal(
        position.inMilliseconds.clamp(0, player.tape.totalDurationMs));
  }

  /// Rewind / fast-forward: the deck's own ±15 s hops (§5.3).
  @override
  Future<void> rewind() async => _player?.skipBy(-15000);

  @override
  Future<void> fastForward() async => _player?.skipBy(15000);

  /// Skip buttons jump memo boundaries on the tape: previous = the current
  /// memo's start, next = the following memo's start.
  @override
  Future<void> skipToPrevious() async =>
      _skipToIndex(_player?.state.memoIndex ?? 0);

  @override
  Future<void> skipToNext() async =>
      _skipToIndex((_player?.state.memoIndex ?? -1) + 1);

  Future<void> _skipToIndex(int index) async {
    final player = _player;
    if (player == null || player.tape.isEmpty) return;
    await player
        .seekGlobal(player.tape.offsetsMs[index.clamp(0, player.tape.memoCount - 1)]);
  }

  @override
  Future<void> stop() async {
    await _player?.pause();
    // The session outlives the tape: drop the dead source's metadata so a
    // stale card can't resume a cassette that is no longer loaded.
    _cassetteLabel = null;
    await super.stop();
  }

  /// Maps the tape's live state onto the platform media session. Only the
  /// fields the notification shows are mirrored — no playback logic here.
  void _syncToSession(TapePlaybackState state) {
    final showControls = (_player?.tape.memoCount ?? 0) > 0;
    mediaItem.add(MediaItem(
      id: 'tape',
      // An untitled cassette reads as "Diktafon" content rather than a
      // literal "Untitled cassette" string in someone's shade.
      title: (_cassetteLabel?.trim().isNotEmpty ?? false)
          ? _cassetteLabel!
          : 'Diktafon',
      duration: Duration(milliseconds: state.totalMs),
    ));
    playbackState.add(playbackState.value.copyWith(
      controls: showControls
          ? [
              MediaControl.skipToPrevious,
              state.playing ? MediaControl.pause : MediaControl.play,
              MediaControl.skipToNext,
            ]
          : [],
      systemActions: showControls
          ? const {
              MediaAction.seek,
              MediaAction.seekForward,
              MediaAction.seekBackward,
              MediaAction.playPause,
            }
          : const {},
      androidCompactActionIndices: showControls ? const [0, 1, 2] : const [],
      processingState: AudioProcessingState.ready,
      playing: state.playing,
      updatePosition: Duration(milliseconds: state.globalMs),
      bufferedPosition: Duration(milliseconds: state.globalMs),
    ));
  }

  Future<void> dispose() async {
    await _stateSub?.cancel();
  }
}

/// Starts the platform media session. Must be called before runApp
/// (audio_service binds the engine to the platform service at init).
/// Returns null anywhere the session can't start — playback then simply
/// behaves as before, stopping when the app leaves the foreground.
Future<TapePlaybackMediaHandler?> startPlaybackMediaSession({
  required String androidNotificationChannelName,
}) async {
  try {
    return await AudioService.init(
      builder: TapePlaybackMediaHandler.new,
      config: AudioServiceConfig(
        androidNotificationChannelName: androidNotificationChannelName,
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: true,
      ),
    );
  } catch (_) {
    return null;
  }
}
