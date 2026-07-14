/// The shipped default `TranscriptionProvider` (D2): whisper.cpp behind the
/// dk_whisper shim. Pipeline per memo: decode `.m4a` → raw 16 kHz f32 PCM
/// file (PcmDecoder) → worker isolate runs inference → domain [Transcript].
///
/// Noise robustness (design.md §6.3a) is tier-dependent, per the phase-0
/// bench: the small/tiny tiers get an 80 Hz high-pass plus full Silero VAD
/// (only speech regions reach the encoder — −3.7 pts pooled WER and zero
/// hallucinations on noise); large-v3-turbo already handles rumble and
/// pauses better on its own, so it keeps its audio untouched and uses VAD
/// only as a *gate* — skip inference entirely when a memo has no speech.
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart';

import '../../../domain/models.dart';
import '../../audio/pcm_decoder.dart';
import '../../audio/pcm_highpass.dart';
import '../transcription_provider.dart';
import 'whisper_model_manager.dart';
import 'whisper_worker.dart';

class WhisperCppTranscriptionProvider implements TranscriptionProvider {
  WhisperCppTranscriptionProvider({
    required this._models,
    required this._decoder,
    required this._worker,
    required String tier,
    this._vadModelPath,
    this._highPassHz = 80,
  }) : _model = WhisperModel.byTier(tier);

  final WhisperModelManager _models;
  final PcmDecoder _decoder;
  final WhisperWorker _worker;
  final WhisperModel _model;

  /// Silero VAD ggml file (null — tests, missing asset — disables VAD and
  /// the large-tier gate alike).
  final String? _vadModelPath;

  /// Cutoff of the transcription-path high-pass (null disables it): trims
  /// wind/handling rumble below the speech band; the stored file is
  /// untouched. Applied to the small/tiny tiers only.
  final double? _highPassHz;

  bool get _isLarge => _model.tier == WhisperModel.largeV3Turbo.tier;

  /// Leave headroom for the UI/OS; whisper gains little beyond 8 threads.
  static final int _threads =
      max(1, min(Platform.numberOfProcessors - 2, 8));

  @override
  String get id => 'whisper.cpp/${_model.tier}';

  @override
  Future<ModelStatus> modelStatus() async => _models.statusOf(_model);

  @override
  Future<void> ensureModel({ProgressSink? onProgress}) =>
      _models.download(_model, onProgress: onProgress);

  @override
  Future<Transcript> transcribe(
    AudioRef audio, {
    String? languageCode,
    CancelToken? cancel,
  }) async {
    if (_models.statusOf(_model) != ModelStatus.ready) {
      throw StateError('whisper model ${_model.tier} is not installed');
    }
    if (cancel?.isCancelled ?? false) throw const TranscriptionCancelled();

    final tmpDir = await Directory.systemTemp.createTemp('dk_pcm_');
    final cancelFlag = calloc<Int32>();
    // The token may fire long after this job (memo deleted later) — never
    // touch the flag once freed. Single event loop ⇒ no data race.
    var flagFreed = false;
    cancel?.addListener(() {
      if (!flagFreed) cancelFlag.value = 1;
    });
    try {
      final pcmPath = '${tmpDir.path}/audio.f32';
      await _decoder.decodeToF32(audio.filePath, pcmPath);
      if (!_isLarge && _highPassHz != null) {
        // Whole-file read + a ~57 M-sample loop per hour of audio — never
        // in the UI isolate (it froze frames for seconds on phones).
        final cutoffHz = _highPassHz;
        await Isolate.run(() => highPassPcmFile(pcmPath, cutoffHz: cutoffHz));
      }
      if (cancel?.isCancelled ?? false) throw const TranscriptionCancelled();

      if (_isLarge && _vadModelPath != null) {
        // Gate only: a memo with no detected speech skips inference — the
        // engine would otherwise spend minutes hallucinating text onto
        // noise. Gate trouble fails open into a normal transcription.
        try {
          final hasSpeech = await _worker.detectSpeech(
            vadModelPath: _vadModelPath,
            pcmPath: pcmPath,
            threads: _threads,
          );
          if (!hasSpeech) {
            return Transcript(
                languageCode: languageCode ?? '', segments: const []);
          }
        } on WhisperWorkerException {
          // fall through to whisper
        }
      }
      if (cancel?.isCancelled ?? false) throw const TranscriptionCancelled();

      try {
        return await _worker.transcribe(
          modelPath: _models.fileOf(_model).path,
          pcmPath: pcmPath,
          languageCode: languageCode,
          cancelFlagAddress: cancelFlag.address,
          threads: _threads,
          vadModelPath: _isLarge ? null : _vadModelPath,
        );
      } on WhisperWorkerException {
        // An abort surfaces as a whisper_full error; tell them apart here.
        if (cancel?.isCancelled ?? false) throw const TranscriptionCancelled();
        rethrow;
      }
    } finally {
      flagFreed = true;
      calloc.free(cancelFlag);
      await tmpDir.delete(recursive: true);
    }
  }
}
