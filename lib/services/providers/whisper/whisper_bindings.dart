/// dart:ffi bindings to Diktafon's `dk_whisper` C shim (native/src/dk_whisper.h).
///
/// Only the shim's flat API is bound — whisper.cpp's own structs never cross
/// the FFI boundary, so upstream engine bumps can't break this file.
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// Where the engine lives, per platform:
/// 1. `DIKTAFON_LIBWHISPER` env override (unit tests, dev builds);
/// 2. Android: bare soname, resolved by the app's linker namespace;
/// 3. iOS: embedded dynamic framework, resolved by dyld via @rpath;
/// 4. Linux: `lib/` inside the Flutter bundle, next to the executable.
String resolveWhisperLibraryPath() {
  final override = Platform.environment['DIKTAFON_LIBWHISPER'];
  if (override != null && override.isNotEmpty) return override;
  if (Platform.isAndroid) return 'libdiktafon_whisper.so';
  if (Platform.isIOS) return 'diktafon_whisper.framework/diktafon_whisper';
  if (Platform.isLinux) {
    final executableDir = File(Platform.resolvedExecutable).parent.path;
    return '$executableDir/lib/libdiktafon_whisper.so';
  }
  throw UnsupportedError(
      'no whisper engine build for ${Platform.operatingSystem} yet');
}

class WhisperBindings {
  WhisperBindings(DynamicLibrary lib)
      : init = lib.lookupFunction<Pointer<Void> Function(Pointer<Utf8>),
            Pointer<Void> Function(Pointer<Utf8>)>('dk_whisper_init'),
        free = lib.lookupFunction<Void Function(Pointer<Void>),
            void Function(Pointer<Void>)>('dk_whisper_free'),
        setBeamSize = lib.lookupFunction<Void Function(Pointer<Void>, Int32),
            void Function(Pointer<Void>, int)>('dk_whisper_set_beam_size'),
        setVadModel = lib.lookupFunction<
            Void Function(Pointer<Void>, Pointer<Utf8>),
            void Function(
                Pointer<Void>, Pointer<Utf8>)>('dk_whisper_set_vad_model'),
        transcribe = lib.lookupFunction<
            Int32 Function(Pointer<Void>, Pointer<Float>, Int32, Pointer<Utf8>,
                Int32, Pointer<Int32>),
            int Function(Pointer<Void>, Pointer<Float>, int, Pointer<Utf8>,
                int, Pointer<Int32>)>('dk_whisper_transcribe'),
        lang = lib.lookupFunction<Pointer<Utf8> Function(Pointer<Void>),
            Pointer<Utf8> Function(Pointer<Void>)>('dk_whisper_lang'),
        nSegments = lib.lookupFunction<Int32 Function(Pointer<Void>),
            int Function(Pointer<Void>)>('dk_whisper_n_segments'),
        segmentT0Ms = lib.lookupFunction<Int64 Function(Pointer<Void>, Int32),
            int Function(Pointer<Void>, int)>('dk_whisper_segment_t0_ms'),
        segmentT1Ms = lib.lookupFunction<Int64 Function(Pointer<Void>, Int32),
            int Function(Pointer<Void>, int)>('dk_whisper_segment_t1_ms'),
        nTokens = lib.lookupFunction<Int32 Function(Pointer<Void>, Int32),
            int Function(Pointer<Void>, int)>('dk_whisper_n_tokens'),
        tokenText = lib.lookupFunction<
            Pointer<Uint8> Function(Pointer<Void>, Int32, Int32),
            Pointer<Uint8> Function(
                Pointer<Void>, int, int)>('dk_whisper_token_text'),
        tokenT0Ms = lib.lookupFunction<
            Int64 Function(Pointer<Void>, Int32, Int32),
            int Function(Pointer<Void>, int, int)>('dk_whisper_token_t0_ms'),
        tokenT1Ms = lib.lookupFunction<
            Int64 Function(Pointer<Void>, Int32, Int32),
            int Function(Pointer<Void>, int, int)>('dk_whisper_token_t1_ms'),
        tokenIsText = lib.lookupFunction<
            Int32 Function(Pointer<Void>, Int32, Int32),
            int Function(
                Pointer<Void>, int, int)>('dk_whisper_token_is_text'),
        segmentNoSpeechProb = lib.lookupFunction<
            Float Function(Pointer<Void>, Int32),
            double Function(
                Pointer<Void>, int)>('dk_whisper_segment_no_speech_prob'),
        segmentAvgTokenP = lib.lookupFunction<
            Float Function(Pointer<Void>, Int32),
            double Function(
                Pointer<Void>, int)>('dk_whisper_segment_avg_token_p');

  factory WhisperBindings.open(String libraryPath) =>
      WhisperBindings(DynamicLibrary.open(libraryPath));

  final Pointer<Void> Function(Pointer<Utf8> modelPath) init;
  final void Function(Pointer<Void>) free;

  /// > 1 = beam search with that beam size on subsequent transcribes;
  /// otherwise greedy (the default).
  final void Function(Pointer<Void>, int beamSize) setBeamSize;
  /// Silero VAD ggml model for subsequent transcribes; empty string
  /// disables VAD (the default).
  final void Function(Pointer<Void>, Pointer<Utf8> modelPath) setVadModel;
  final int Function(Pointer<Void>, Pointer<Float> pcm, int nSamples,
      Pointer<Utf8> lang, int nThreads, Pointer<Int32> cancel) transcribe;
  final Pointer<Utf8> Function(Pointer<Void>) lang;
  final int Function(Pointer<Void>) nSegments;
  final int Function(Pointer<Void>, int) segmentT0Ms;
  final int Function(Pointer<Void>, int) segmentT1Ms;
  final int Function(Pointer<Void>, int) nTokens;
  final Pointer<Uint8> Function(Pointer<Void>, int, int) tokenText;
  final int Function(Pointer<Void>, int, int) tokenT0Ms;
  final int Function(Pointer<Void>, int, int) tokenT1Ms;
  final int Function(Pointer<Void>, int, int) tokenIsText;

  /// Decoder no-speech probability / mean text-token probability per
  /// segment — the hallucination-filter signals (phase 1.3).
  final double Function(Pointer<Void>, int) segmentNoSpeechProb;
  final double Function(Pointer<Void>, int) segmentAvgTokenP;
}

/// Copies a NUL-terminated C string as raw bytes. Token text may hold a
/// *partial* UTF-8 sequence, so it must not be decoded per token
/// (word_timing.dart concatenates bytes per word first).
Uint8List copyCStringBytes(Pointer<Uint8> ptr) {
  if (ptr == nullptr) return Uint8List(0);
  var length = 0;
  while (ptr[length] != 0) {
    length++;
  }
  return Uint8List.fromList(ptr.asTypedList(length));
}
