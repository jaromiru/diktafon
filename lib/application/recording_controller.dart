import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class RecordingController extends Notifier<RecordingState> {
  Timer? _ticker;

  @override
  RecordingState build() {
    ref.onDispose(() => _ticker?.cancel());
    return RecordingState.idle;
  }

  /// Tap record → capture starts, appended to this cassette's tape (D6).
  /// A missing mic permission is requested right here (the recorder fires
  /// the OS prompt); false means the user denied it.
  Future<bool> start(String cassetteId) async {
    final recorder = ref.read(recorderServiceProvider);
    if (state.isRecording) return true;
    if (!await recorder.hasPermission()) return false;

    // One audio session: the tape pauses while the mic is open.
    await ref.read(tapePlayerProvider).pause();
    await recorder.start(cassetteId);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      state = RecordingState(
        cassetteId: state.cassetteId,
        elapsed: recorder.elapsed,
      );
    });
    state = RecordingState(cassetteId: cassetteId, elapsed: Duration.zero);
    return true;
  }

  /// Stop → the memo appears on the tape instantly in its pre-transcription
  /// state (D7); transcription is enqueued for the background queue.
  Future<void> stop() async {
    final cassetteId = state.cassetteId;
    if (cassetteId == null) return;
    _ticker?.cancel();
    _ticker = null;

    final recorder = ref.read(recorderServiceProvider);
    final result = await recorder.stop();
    state = RecordingState.idle;

    await ref.read(memoRepositoryProvider).insert(
          recorder.toMemo(result, cassetteId),
        );
    await ref.read(cassetteRepositoryProvider).touch(cassetteId);
    await ref.read(jobQueueProvider).enqueueTranscription(result.memoId);
  }
}

final recordingControllerProvider =
    NotifierProvider<RecordingController, RecordingState>(
        RecordingController.new);
