/// The shipped default `TranscriptionProvider` (D2): whisper.cpp behind the
/// dk_whisper shim. Pipeline per memo: decode `.m4a` → raw 16 kHz f32 PCM
/// file (PcmDecoder) → worker isolate runs inference → domain [Transcript].
library;

import 'dart:ffi';
import 'dart:io';
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
    this._highPassHz = 80,
  }) : _model = WhisperModel.byTier(tier);

  final WhisperModelManager _models;
  final PcmDecoder _decoder;
  final WhisperWorker _worker;
  final WhisperModel _model;

  /// Cutoff of the transcription-path high-pass (null disables it): trims
  /// wind/handling rumble below the speech band; the stored file is
  /// untouched (noise-robust-transcription.md phase 1.4).
  final double? _highPassHz;

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
      if (_highPassHz != null) {
        await highPassPcmFile(pcmPath, cutoffHz: _highPassHz);
      }
      if (cancel?.isCancelled ?? false) throw const TranscriptionCancelled();

      try {
        return await _worker.transcribe(
          modelPath: _models.fileOf(_model).path,
          pcmPath: pcmPath,
          languageCode: languageCode,
          cancelFlagAddress: cancelFlag.address,
          threads: _threads,
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
