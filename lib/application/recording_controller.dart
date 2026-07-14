import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio/recorder_service.dart';
import 'providers.dart';

/// UI-facing recording state (§5.3): elapsed drives the LCD counter and the
/// red tail growing on the timeline.
class RecordingState {
  const RecordingState({
    required this.cassetteId,
    required this.elapsed,
  });

  static const idle = RecordingState(cassetteId: null, elapsed: Duration.zero);

  final String? cassetteId;
  final Duration elapsed;

  bool get isRecording => cassetteId != null;

  bool isRecordingIn(String cassette) => cassetteId == cassette;
}

/// What a record press led to — the screen picks the snackbar from this.
enum RecordStartOutcome {
  started,

  /// Already recording, a start still in flight (double-tap), or the screen
  /// went away mid-start — nothing to tell the user.
  ignored,

  /// Mic permission denied (or silenced after repeated denials).
  denied,

  /// The recorder failed to start — mic held by telephony/another app, or a
  /// plugin error.
  failed,
}

class RecordingController extends Notifier<RecordingState> {
  Timer? _ticker;
  StreamSubscription<void>? _stopsSub;

  /// The cassette a start() is in flight for — set before the first await,
  /// so a double-tap can't start twice and deactivate can abort a start
  /// still waiting on the permission prompt.
  String? _startingIn;
  bool _abortRequested = false;
  bool _stopping = false;

  @override
  RecordingState build() {
    ref.onDispose(() {
      _stopsSub?.cancel();
      _ticker?.cancel();
    });
    return RecordingState.idle;
  }

  /// Tap record → capture starts, appended to this cassette's tape (D6).
  /// A missing mic permission is requested right here (the recorder fires
  /// the OS prompt).
  Future<RecordStartOutcome> start(String cassetteId) async {
    final recorder = ref.read(recorderServiceProvider);
    if (state.isRecording || _startingIn != null) {
      return RecordStartOutcome.ignored;
    }
    _startingIn = cassetteId;
    _abortRequested = false;
    try {
      if (!await recorder.hasPermission()) return RecordStartOutcome.denied;

      // One audio session: the tape pauses while the mic is open.
      await ref.read(tapePlayerProvider).pause();
      if (_abortRequested) return RecordStartOutcome.ignored;
      await recorder.start(cassetteId);
      if (_abortRequested) {
        // The screen went away while the permission prompt was up — never
        // record headless into a cassette nobody is looking at.
        await recorder.discard();
        return RecordStartOutcome.ignored;
      }
      _watchCaptureStops(recorder);
      _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
        state = RecordingState(
          cassetteId: state.cassetteId,
          elapsed: recorder.elapsed,
        );
      });
      state = RecordingState(cassetteId: cassetteId, elapsed: Duration.zero);
      return RecordStartOutcome.started;
    } catch (_) {
      return RecordStartOutcome.failed;
    } finally {
      _startingIn = null;
    }
  }

  /// Abandons a start() still in flight for [cassetteId] (permission prompt
  /// up, player still pausing) — called when its screen deactivates.
  void abortStartIn(String cassetteId) {
    if (_startingIn == cassetteId) _abortRequested = true;
  }

  /// The OS can end the capture behind the app's back (phone call, Siri,
  /// another app claiming the mic): the plugin reports the stop — finalize
  /// the memo instead of keeping a live counter over a dead recording.
  void _watchCaptureStops(RecorderService recorder) {
    _stopsSub ??= recorder.captureStops.listen((_) {
      // Our own stop()/discard() also land here; by then the state is
      // already idle (or _stopping guards the re-entry).
      if (state.isRecording && !_stopping) unawaited(stop());
    });
  }

  /// Stop → the memo appears on the tape instantly in its pre-transcription
  /// state (D7); transcription is enqueued for the background queue.
  Future<void> stop() async {
    final cassetteId = state.cassetteId;
    if (cassetteId == null || _stopping) return;
    _stopping = true;
    _ticker?.cancel();
    _ticker = null;
    try {
      final recorder = ref.read(recorderServiceProvider);
      final result = await recorder.stop();
      state = RecordingState.idle;

      await ref.read(memoRepositoryProvider).insert(
            recorder.toMemo(result, cassetteId),
          );
      await ref.read(cassetteRepositoryProvider).touch(cassetteId);
      await ref.read(jobQueueProvider).enqueueTranscription(result.memoId);
    } finally {
      _stopping = false;
      // Whatever failed above, the UI must never stay frozen mid-recording.
      if (state.isRecording) state = RecordingState.idle;
    }
  }
}

final recordingControllerProvider =
    NotifierProvider<RecordingController, RecordingState>(
        RecordingController.new);
