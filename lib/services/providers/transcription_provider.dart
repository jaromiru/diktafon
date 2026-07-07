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
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
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

/// M1 placeholder: no engine shipped yet. Jobs stay queued until a real
/// provider reports `ready` (§14 — "model missing/unavailable").
class NotInstalledTranscriptionProvider implements TranscriptionProvider {
  const NotInstalledTranscriptionProvider();

  @override
  String get id => 'none/transcription';

  @override
  Future<ModelStatus> modelStatus() async => ModelStatus.notInstalled;

  @override
  Future<void> ensureModel({ProgressSink? onProgress}) async {
    throw UnsupportedError('no transcription engine shipped yet (M2)');
  }

  @override
  Future<Transcript> transcribe(
    AudioRef audio, {
    String? languageCode,
    CancelToken? cancel,
  }) async {
    throw StateError('transcription model not installed');
  }
}
