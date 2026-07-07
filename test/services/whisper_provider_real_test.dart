/// Full-stack engine test: real libdiktafon_whisper.so, real ggml model,
/// real ffmpeg decode, worker isolate and word assembly — the whole
/// TranscriptionProvider seam end to end.
///
/// Opt-in (needs artefacts that don't live in the repo):
///   DIKTAFON_LIBWHISPER=path/to/libdiktafon_whisper.so \
///   DIKTAFON_WHISPER_MODEL=path/to/ggml-tiny-q5_1.bin \
///   DIKTAFON_WHISPER_SAMPLE=path/to/jfk.wav \
///   flutter test test/services/whisper_provider_real_test.dart
library;

import 'dart:io';

import 'package:diktafon/services/audio/pcm_decoder.dart';
import 'package:diktafon/services/providers/transcription_provider.dart';
import 'package:diktafon/services/providers/whisper/whisper_model_manager.dart';
import 'package:diktafon/services/providers/whisper/whisper_transcription_provider.dart';
import 'package:diktafon/services/providers/whisper/whisper_worker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final lib = Platform.environment['DIKTAFON_LIBWHISPER'];
  final model = Platform.environment['DIKTAFON_WHISPER_MODEL'];
  final sample = Platform.environment['DIKTAFON_WHISPER_SAMPLE'];
  final available = lib != null && model != null && sample != null;

  test(
    'whisper.cpp transcribes JFK sample with sane word timings',
    () async {
      final dir = Directory.systemTemp.createTempSync('dk_whisper_real_');
      addTearDown(() => dir.deleteSync(recursive: true));
      // The manager resolves tiers by canonical file name.
      File(model!).copySync('${dir.path}/${WhisperModel.tiny.fileName}');

      final worker = WhisperWorker(lib!);
      addTearDown(worker.dispose);
      final provider = WhisperCppTranscriptionProvider(
        models: WhisperModelManager(dir),
        decoder: FfmpegPcmDecoder(),
        worker: worker,
        tier: 'tiny',
      );

      expect(await provider.modelStatus(), ModelStatus.ready);

      final transcript = await provider.transcribe(AudioRef(sample!));

      expect(transcript.languageCode, 'en', reason: 'auto-detected (D8)');
      final words = [
        for (final segment in transcript.segments) ...segment.words
      ];
      final text = words.map((w) => w.text).join(' ').toLowerCase();
      expect(text, contains('ask not what your country'));

      // Word-level timing is the product (§4.1/§4.2) — timestamps must be
      // usable for tap-to-seek: ordered, non-negative, within the clip.
      for (final word in words) {
        expect(word.startMs, greaterThanOrEqualTo(0));
        expect(word.endMs, greaterThanOrEqualTo(word.startMs));
        expect(word.endMs, lessThanOrEqualTo(12_000));
      }
      for (var i = 1; i < words.length; i++) {
        expect(words[i].startMs, greaterThanOrEqualTo(words[i - 1].startMs),
            reason: 'word starts are monotonic');
      }

      // Second run reuses the warm context (same worker, same model).
      final again = await provider.transcribe(AudioRef(sample));
      expect(again.segments, isNotEmpty);
    },
    skip: available
        ? false
        : 'set DIKTAFON_LIBWHISPER / DIKTAFON_WHISPER_MODEL / '
            'DIKTAFON_WHISPER_SAMPLE to run the real engine test',
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'cancellation mid-inference surfaces as TranscriptionCancelled',
    () async {
      final dir = Directory.systemTemp.createTempSync('dk_whisper_cancel_');
      addTearDown(() => dir.deleteSync(recursive: true));
      File(model!).copySync('${dir.path}/${WhisperModel.tiny.fileName}');

      final worker = WhisperWorker(lib!);
      addTearDown(worker.dispose);
      final provider = WhisperCppTranscriptionProvider(
        models: WhisperModelManager(dir),
        decoder: FfmpegPcmDecoder(),
        worker: worker,
        tier: 'tiny',
      );

      final cancel = CancelToken();
      final pending = provider.transcribe(AudioRef(sample!), cancel: cancel);
      // Give decode a moment so the abort lands mid-inference.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      cancel.cancel();

      await expectLater(pending, throwsA(isA<TranscriptionCancelled>()));
    },
    skip: available
        ? false
        : 'set DIKTAFON_LIBWHISPER / DIKTAFON_WHISPER_MODEL / '
            'DIKTAFON_WHISPER_SAMPLE to run the real engine test',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
