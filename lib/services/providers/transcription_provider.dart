/// The transcription seam (§6.3, D2) — the UI and domain layers only ever see
/// this interface; Whisper (or any other engine) hides behind it.
library;

import 'dart:async';

import '../../domain/models.dart';

enum ModelStatus { notInstalled, downloading, ready }

/// Reports download/preparation progress in [0..1].
typedef ProgressSink = void Function(double fraction);

class CancelToken {
  bool _cancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Runs [listener] on cancellation (immediately if already cancelled) —
  /// lets engines abort mid-inference instead of polling.
  void addListener(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }
}

/// Thrown by [TranscriptionProvider.transcribe] when the [CancelToken] fired
/// (§14 "delete during processing" — not a failure, the memo is just gone).
class TranscriptionCancelled implements Exception {
  const TranscriptionCancelled();
}

/// Reference to a memo's audio on disk.
class AudioRef {
  const AudioRef(this.filePath);
  final String filePath;
}

abstract interface class TranscriptionProvider {
  /// e.g. "whisper.cpp/small-q5"
  String get id;

  Future<ModelStatus> modelStatus();

  /// Download/prepare the model (§6.6).
  Future<void> ensureModel({ProgressSink? onProgress});

  /// [languageCode] null → auto-detect (D8).
  Future<Transcript> transcribe(
    AudioRef audio, {
    String? languageCode,
    CancelToken? cancel,
  });
}

