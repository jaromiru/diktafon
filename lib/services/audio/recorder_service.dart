import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../data/files/audio_file_store.dart';
import '../../domain/models.dart';

/// The real duration of an audio file in ms, via a throwaway player; null
/// when probing fails (unfinalized/corrupt file). Shared by the recorder
/// (tape offsets, §4.2) and the importer (manifests with a missing or zero
/// duration).
Future<int?> probeAudioDurationMs(String path) async {
  final probe = AudioPlayer();
  try {
    final duration = await probe.setFilePath(path);
    return duration?.inMilliseconds;
  } catch (_) {
    return null;
  } finally {
    await probe.dispose();
  }
}

/// A finished capture, ready to be persisted as a memo.
class RecordingResult {
  const RecordingResult({
    required this.memoId,
    required this.filePath,
    required this.durationMs,
  });

  final String memoId;
  final String filePath;
  final int durationMs;
}

/// Capture (§6.4): mono AAC-LC `.m4a`, 16 kHz, ~48 kbps — one file per memo,
/// never re-encoded. Recording never blocks on anything (design pillar #3).
class RecorderService {
  RecorderService(this._files);

  final AudioFileStore _files;
  final AudioRecorder _recorder = AudioRecorder();
  final _uuid = const Uuid();

  String? _activeMemoId;
  String? _activePath;
  DateTime? _startedAt;
  Stopwatch? _stopwatch;

  bool get isRecording => _activeMemoId != null;
  DateTime? get startedAt => _startedAt;
  String? get activeMemoId => _activeMemoId;
  Duration get elapsed => _stopwatch?.elapsed ?? Duration.zero;

  /// dBFS amplitude for the live level meter (§5.3).
  Stream<Amplitude> amplitudeStream(
          {Duration interval = const Duration(milliseconds: 120)}) =>
      _recorder.onAmplitudeChanged(interval);

  /// Fires when the platform recorder stops — including stops the app never
  /// asked for (phone call, Siri, another app claiming the mic). The
  /// controller reconciles: a live UI over a dead capture finalizes.
  Stream<void> get captureStops =>
      _recorder.onStateChanged().where((s) => s == RecordState.stop);

  /// Asks the OS for the mic permission when it's missing (the plugin shows
  /// the prompt); false → denied, or silenced after repeated denials.
  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start(String cassetteId) async {
    if (isRecording) throw StateError('already recording');
    final memoId = _uuid.v4();
    final path = await _files.pathFor(cassetteId, memoId);
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 48000,
        // VOICE_RECOGNITION is the CDD-mandated clean feed (flat ±3 dB,
        // OEM noise-suppression/AGC off) — closest to whisper's training
        // distribution (§6.4; noise-robust-transcription.md §3.5).
        androidConfig: AndroidRecordConfig(
            audioSource: AndroidAudioSource.voiceRecognition),
      ),
      path: path,
    );
    _activeMemoId = memoId;
    _activePath = path;
    _startedAt = DateTime.now();
    _stopwatch = Stopwatch()..start();
  }

  /// Stops and returns the capture. The memo appears on the tape instantly
  /// (D7); enrichment is someone else's job.
  Future<RecordingResult> stop() async {
    final memoId = _activeMemoId;
    final path = _activePath;
    final stopwatch = _stopwatch;
    if (memoId == null || path == null || stopwatch == null) {
      throw StateError('not recording');
    }
    stopwatch.stop();
    String recordedPath;
    try {
      recordedPath = await _recorder.stop() ?? path;
    } catch (_) {
      // Plugin failure mid-stop (interruption, backend error): the capture
      // file may still be playable — keep the memo rather than lose it;
      // the duration probe below falls back to wall clock.
      recordedPath = path;
    }
    _activeMemoId = null;
    _activePath = null;
    _startedAt = null;
    _stopwatch = null;

    // Prefer the file's real duration (drives tape offsets, §4.2); fall back
    // to wall-clock elapsed if probing fails.
    final durationMs =
        await probeAudioDurationMs(recordedPath) ??
            stopwatch.elapsedMilliseconds;
    return RecordingResult(
      memoId: memoId,
      filePath: recordedPath,
      durationMs: durationMs,
    );
  }

  /// Cancels and discards the in-flight capture.
  Future<void> discard() async {
    final path = _activePath;
    _activeMemoId = null;
    _activePath = null;
    _startedAt = null;
    _stopwatch = null;
    await _recorder.stop();
    if (path != null) await _files.deleteMemoFile(path);
  }

  Memo toMemo(RecordingResult result, String cassetteId) => Memo(
        id: result.memoId,
        cassetteId: cassetteId,
        filePath: result.filePath,
        durationMs: result.durationMs,
        createdAt: DateTime.now(),
        status: MemoStatus.stored,
      );

  Future<void> dispose() => _recorder.dispose();
}
