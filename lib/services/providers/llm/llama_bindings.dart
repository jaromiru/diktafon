/// dart:ffi bindings to Diktafon's `dk_llama` C shim (native/src/dk_llama.h).
///
/// Only the shim's flat API is bound — llama.cpp's own structs never cross
/// the FFI boundary, so upstream engine bumps can't break this file.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Where the engine lives, per platform:
/// 1. `DIKTAFON_LIBLLAMA` env override (unit tests, dev builds);
/// 2. Android: bare soname, resolved by the app's linker namespace;
/// 3. Linux: `lib/` inside the Flutter bundle, next to the executable.
String resolveLlamaLibraryPath() {
  final override = Platform.environment['DIKTAFON_LIBLLAMA'];
  if (override != null && override.isNotEmpty) return override;
  if (Platform.isAndroid) return 'libdiktafon_llama.so';
  if (Platform.isLinux) {
    final executableDir = File(Platform.resolvedExecutable).parent.path;
    return '$executableDir/lib/libdiktafon_llama.so';
  }
  throw UnsupportedError(
      'no llama engine build for ${Platform.operatingSystem} yet');
}

class LlamaBindings {
  LlamaBindings(DynamicLibrary lib)
      : init = lib.lookupFunction<
            Pointer<Void> Function(Pointer<Utf8>, Int32, Int32),
            Pointer<Void> Function(
                Pointer<Utf8>, int, int)>('dk_llama_init'),
        free = lib.lookupFunction<Void Function(Pointer<Void>),
            void Function(Pointer<Void>)>('dk_llama_free'),
        generate = lib.lookupFunction<
            Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>,
                Int32, Float, Pointer<Int32>),
            int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, int,
                double, Pointer<Int32>)>('dk_llama_generate'),
        result = lib.lookupFunction<Pointer<Utf8> Function(Pointer<Void>),
            Pointer<Utf8> Function(Pointer<Void>)>('dk_llama_result');

  factory LlamaBindings.open(String libraryPath) =>
      LlamaBindings(DynamicLibrary.open(libraryPath));

  final Pointer<Void> Function(
      Pointer<Utf8> modelPath, int nCtx, int nThreads) init;
  final void Function(Pointer<Void>) free;
  final int Function(Pointer<Void>, Pointer<Utf8> system, Pointer<Utf8> user,
      int maxTokens, double temperature, Pointer<Int32> cancel) generate;
  final Pointer<Utf8> Function(Pointer<Void>) result;
}
