/// Runs one quality-bench variant (see quality_harness.dart) as a test.
/// Opt-in — without the env config the test skips cleanly:
///
///   DIKTAFON_QUALITY_VARIANT=small \
///   DIKTAFON_QUALITY_DIR=/abs/path/to/quality_test \
///   DIKTAFON_LIBWHISPER=/abs/path/libdiktafon_whisper.so \
///   DIKTAFON_WHISPER_MODEL=/abs/path/ggml-small-q5_1.bin \
///   flutter test test/quality/transcription_quality_test.dart
///
/// Optional: DIKTAFON_QUALITY_OUT, DIKTAFON_QUALITY_FILTER (ffmpeg -af),
/// DIKTAFON_QUALITY_LANG=file, DIKTAFON_LIBLLAMA + DIKTAFON_LLM_MODEL +
/// DIKTAFON_LLM_TIER (cleanup), DIKTAFON_QUALITY_SOURCE (reuse another
/// variant's raw transcripts), DIKTAFON_QUALITY_NOTE (provenance).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'quality_harness.dart';

void main() {
  final config = QualityConfig.fromEnv(Platform.environment);

  test(
    'quality bench: variant ${config?.variant ?? '(unconfigured)'}',
    () async {
      await runVariant(config!);
    },
    skip: config == null
        ? 'set DIKTAFON_QUALITY_VARIANT / DIKTAFON_QUALITY_DIR (and engine '
            'paths) to run the quality bench'
        : false,
    timeout: const Timeout(Duration(minutes: 120)),
  );
}
