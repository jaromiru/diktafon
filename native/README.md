# native/ — on-device ML engines (M2+)

## Layout

- `whisper.cpp/` — **vendored** [ggml-org/whisper.cpp](https://github.com/ggml-org/whisper.cpp)
  **v1.9.1**, trimmed to what Diktafon builds: `include/`, `src/`, `cmake/` and
  `ggml/` with only the **CPU, BLAS and Metal** backends kept (CUDA/Vulkan/SYCL/…
  sources deleted — they are gated behind `GGML_*` options that default OFF on
  our targets, so the build never references them). Upstream `LICENSE` (MIT)
  and `AUTHORS` are preserved. Do not edit files in there; to upgrade, re-fetch
  a release tarball and re-apply the same trim (see git log of this directory).
- `llama.cpp/` — **vendored** [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp)
  **b9700** (2026-06-18), trimmed the same way: `include/`, `src/`, `cmake/`,
  `ggml/` (CPU/BLAS/Metal backends only), `LICENSE`, `AUTHORS`. Chosen to pin
  the **same ggml 0.15.1** sync point as whisper.cpp v1.9.1 (released one day
  apart), because both engines share one ggml build — see CMake note below.
- `src/dk_whisper.{h,cpp}` — Diktafon's C shim over whisper. Dart binds
  **only** this small, stable API (init / transcribe / result accessors /
  cancel flag); whisper's large parameter structs never cross the FFI
  boundary, so upstream bumps can't silently break the Dart side.
- `src/dk_llama.{h,cpp}` — same idea for llama: init (model + context) /
  one-shot `[system, user]` chat generate (the model's own chat template is
  applied natively) / result accessor / cancel flag.
- `CMakeLists.txt` — builds **two shared libraries**:
  `libdiktafon_whisper.so` and `libdiktafon_llama.so`. **llama.cpp is added
  first** so it defines the `ggml` target; whisper.cpp reuses it via its
  `if (NOT TARGET ggml)` guard. When upgrading either engine, keep their ggml
  sync points close (both trees carry a `ggml/` copy; llama's wins).

## Local patches (re-apply on every engine upgrade)

The vendored trees are otherwise pristine, but carry three deliberate
Diktafon patches — all marked with a `Diktafon patch` comment at the site
and motivated by design.md §6.5 (UI-thread starvation → Android
input-dispatch ANRs; the build is OpenMP-free, see `GGML_OPENMP OFF` in
`CMakeLists.txt`, so ggml's internal threadpool is the only compute pool):

1. `llama.cpp/ggml/src/ggml-cpu/ggml-cpu.c` — the thread priority/affinity
   block compiles on Android too (`__gnu_linux__ || __ANDROID__`; bionic
   defines only `__linux__`, so upstream fell into the no-op branch), and
   `GGML_SCHED_PRIO_LOW` additionally drops nice to 10 (SCHED_BATCH alone
   keeps full CFS weight).
2. `whisper.cpp/include/whisper.h` + `whisper.cpp/src/whisper.cpp` —
   `whisper_dk_set_cpu_threadpool()`: whisper has no public threadpool API,
   so a process-global pool set by the shim is attached to the CPU backend
   in both `ggml_graph_compute_helper` variants (covers encoder/decoder
   sched, VAD, and misc computes). Without it, every non-OpenMP compute
   spawns a disposable pool at default params (hybrid busy-poll, normal
   priority) — per encoder pass and per decoded token.
3. (No llama patch needed — `llama_attach_threadpool()` is public; the shim
   uses it.)

The shims create the pools with `poll=0` (sleep between graphs, no
busy-spin) and `GGML_SCHED_PRIO_LOW`, and additionally background the
*calling* thread for the duration of each engine call on Android
(`src/dk_thread_bg.h` — thread 0 of every compute is the caller).

## Consumers

- **Linux (dev/E2E):** `linux/CMakeLists.txt` adds this directory and installs
  both libraries into the app bundle's `lib/`.
- **Android:** `android/app/build.gradle.kts` `externalNativeBuild` points at
  `native/CMakeLists.txt`; Gradle builds per-ABI `.so`s (NDK 28.2 — 16 KB page
  alignment ready).
- **iOS (later):** add an Xcode target over the same sources; the Metal/BLAS
  ggml backends are kept in the vendor trees for that purpose.

Dart-side loading order (see `whisper_bindings.dart` / `llama_bindings.dart`):
`DIKTAFON_LIBWHISPER` / `DIKTAFON_LIBLLAMA` env override → bundle `lib/` next
to the executable (Linux) → bare soname (Android linker path).
