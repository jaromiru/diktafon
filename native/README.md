# native/ — on-device ML engines (M2+)

## Layout

- `whisper.cpp/` — **vendored** [ggml-org/whisper.cpp](https://github.com/ggml-org/whisper.cpp)
  **v1.9.1**, trimmed to what Diktafon builds: `include/`, `src/`, `cmake/` and
  `ggml/` with only the **CPU, BLAS and Metal** backends kept (CUDA/Vulkan/SYCL/…
  sources deleted — they are gated behind `GGML_*` options that default OFF on
  our targets, so the build never references them). Upstream `LICENSE` (MIT)
  and `AUTHORS` are preserved. Do not edit files in there; to upgrade, re-fetch
  a release tarball and re-apply the same trim (see git log of this directory).
- `src/dk_whisper.{h,cpp}` — Diktafon's C shim. Dart binds **only** this small,
  stable API (init / transcribe / result accessors / cancel flag); whisper's
  large parameter structs never cross the FFI boundary, so upstream bumps can't
  silently break the Dart side.
- `CMakeLists.txt` — builds everything into **one shared library**
  `libdiktafon_whisper.so` (whisper + ggml linked in statically).

## Consumers

- **Linux (dev/E2E):** `linux/CMakeLists.txt` adds this directory and installs
  the library into the app bundle's `lib/`.
- **Android:** `android/app/build.gradle.kts` `externalNativeBuild` points at
  `native/CMakeLists.txt`; Gradle builds per-ABI `.so`s (NDK 28.2 — 16 KB page
  alignment ready).
- **iOS (later):** add an Xcode target over the same sources; the Metal/BLAS
  ggml backends are kept in the vendor tree for that purpose.

Dart-side loading order (see `lib/services/providers/whisper/whisper_ffi.dart`):
`DIKTAFON_LIBWHISPER` env override → bundle `lib/` next to the executable
(Linux) → bare soname (Android linker path).
