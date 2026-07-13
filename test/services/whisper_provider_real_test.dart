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

  // The bundled Silero model ships in the repo — no extra env needed.
  final vadModel =
      '${Directory.current.path}/assets/models/ggml-silero-v5.1.2.bin';

  test(
    'full VAD path (§6.3a small/tiny mode): speech is transcribed with '
    'original-timeline word timings',
    () async {
      final dir = Directory.systemTemp.createTempSync('dk_whisper_vad_');
      addTearDown(() => dir.deleteSync(recursive: true));
      File(model!).copySync('${dir.path}/${WhisperModel.tiny.fileName}');

      final worker = WhisperWorker(lib!);
      addTearDown(worker.dispose);
      final provider = WhisperCppTranscriptionProvider(
        models: WhisperModelManager(dir),
        decoder: FfmpegPcmDecoder(),
        worker: worker,
        tier: 'tiny',
        vadModelPath: vadModel,
      );

      final transcript = await provider.transcribe(AudioRef(sample!));
      final words = [
        for (final segment in transcript.segments) ...segment.words
      ];
      final text = words.map((w) => w.text).join(' ').toLowerCase();
      expect(text, contains('ask not what your country'),
          reason: 'VAD must not eat real speech');
      // Token times are interpolated back from the VAD-collapsed stream
      // onto the original timeline — they must stay usable for tap-to-seek.
      for (final word in words) {
        expect(word.startMs, greaterThanOrEqualTo(0));
        expect(word.endMs, greaterThanOrEqualTo(word.startMs));
        expect(word.endMs, lessThanOrEqualTo(12_000));
      }
      for (var i = 1; i < words.length; i++) {
        expect(words[i].startMs, greaterThanOrEqualTo(words[i - 1].startMs),
            reason: 'word starts are monotonic after VAD re-mapping');
      }
    },
    skip: available
        ? false
        : 'set DIKTAFON_LIBWHISPER / DIKTAFON_WHISPER_MODEL / '
            'DIKTAFON_WHISPER_SAMPLE to run the real engine test',
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'gate-only VAD (§6.3a large mode): speech detected, silence skipped',
    () async {
      final worker = WhisperWorker(lib!);
      addTearDown(worker.dispose);

      final dir = Directory.systemTemp.createTempSync('dk_vad_gate_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final speechPcm = '${dir.path}/speech.f32';
      await FfmpegPcmDecoder().decodeToF32(sample!, speechPcm);
      expect(
        await worker.detectSpeech(
            vadModelPath: vadModel, pcmPath: speechPcm, threads: 4),
        isTrue,
      );

      // 5 s of pure silence — the gate must say "skip whisper".
      final silencePcm = '${dir.path}/silence.f32';
      File(silencePcm).writeAsBytesSync(List.filled(16000 * 5 * 4, 0));
      expect(
        await worker.detectSpeech(
            vadModelPath: vadModel, pcmPath: silencePcm, threads: 4),
        isFalse,
      );

      // A bad model path surfaces as an exception (the provider fails open).
      expect(
        () => worker.detectSpeech(
            vadModelPath: '${dir.path}/missing.bin',
            pcmPath: silencePcm,
            threads: 4),
        throwsA(isA<WhisperWorkerException>()),
      );
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

  // Per-language probes for the tr/ru/ko wave: auto-detect (D8) must land
  // on the right code and word-level timing must survive (all three are
  // space-separated — the CJK word-timing break is a ja/zh problem). Each
  // probe needs its own speech sample env var next to the shared lib/model.
  for (final (code, envKey) in [
    ('tr', 'DIKTAFON_WHISPER_SAMPLE_TR'),
    ('ru', 'DIKTAFON_WHISPER_SAMPLE_RU'),
    ('ko', 'DIKTAFON_WHISPER_SAMPLE_KO'),
  ]) {
    final langSample = Platform.environment[envKey];
    test(
      'whisper.cpp auto-detects $code and yields word-level timings',
      () async {
        final dir = Directory.systemTemp.createTempSync('dk_whisper_$code');
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

        final transcript = await provider.transcribe(AudioRef(langSample!));
        expect(transcript.languageCode, code, reason: 'auto-detected (D8)');
        final words = [
          for (final segment in transcript.segments) ...segment.words
        ];
        expect(words.length, greaterThan(1),
            reason: 'transcript must split into words, not one blob');
        for (var i = 1; i < words.length; i++) {
          expect(words[i].startMs, greaterThanOrEqualTo(words[i - 1].startMs),
              reason: 'word starts are monotonic');
        }
      },
      skip: lib != null && model != null && langSample != null
          ? false
          : 'set DIKTAFON_LIBWHISPER / DIKTAFON_WHISPER_MODEL / $envKey '
              'to run the $code probe',
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }
}
