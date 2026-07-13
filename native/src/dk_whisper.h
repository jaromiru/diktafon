/* Diktafon's C shim over whisper.cpp (§6.3, D2).
 *
 * Dart binds only this API. It is deliberately tiny and flat: no whisper
 * structs cross the FFI boundary, timestamps are plain milliseconds, and
 * cancellation is a caller-owned int32 flag polled during inference.
 *
 * Thread-safety: one dk_whisper must be used from one thread at a time
 * (Diktafon runs it inside a single worker isolate; queue concurrency is 1).
 */
#pragma once

#include <stdint.h>

#if defined(_WIN32)
#define DK_EXPORT __declspec(dllexport)
#else
#define DK_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct dk_whisper dk_whisper;

/* Loads a ggml model file. Returns NULL on failure. */
DK_EXPORT dk_whisper * dk_whisper_init(const char * model_path);
DK_EXPORT void dk_whisper_free(dk_whisper * dw);

/* Silero VAD model (ggml) for subsequent transcribes; NULL or empty
 * disables VAD (the default). With VAD on, only detected speech regions
 * reach the encoder; segment AND token timestamps stay on the original
 * timeline (tokens via segment-bounded interpolation in the shim —
 * docs/features/noise-robust-transcription.md phase 1.1). */
DK_EXPORT void dk_whisper_set_vad_model(dk_whisper * dw,
                                        const char * model_path);

/* Transcribes 16 kHz mono float32 PCM.
 * lang    ISO-639-1 code, or NULL to auto-detect (D8).
 * cancel  optional flag; set *cancel to non-zero to abort mid-inference.
 * Returns 0 on success (also when aborted — caller checks its own flag).
 */
DK_EXPORT int32_t dk_whisper_transcribe(dk_whisper * dw,
                                        const float * pcm,
                                        int32_t n_samples,
                                        const char * lang,
                                        int32_t n_threads,
                                        const int32_t * cancel);

/* Result accessors — valid after a successful transcribe, until the next
 * transcribe/free. Token text is raw UTF-8 bytes and may be a *partial*
 * multi-byte sequence; concatenate bytes per word before decoding. */
DK_EXPORT const char * dk_whisper_lang(dk_whisper * dw);
DK_EXPORT int32_t      dk_whisper_n_segments(dk_whisper * dw);
DK_EXPORT int64_t      dk_whisper_segment_t0_ms(dk_whisper * dw, int32_t i);
DK_EXPORT int64_t      dk_whisper_segment_t1_ms(dk_whisper * dw, int32_t i);
DK_EXPORT int32_t      dk_whisper_n_tokens(dk_whisper * dw, int32_t i);
DK_EXPORT const char * dk_whisper_token_text(dk_whisper * dw, int32_t i, int32_t j);
DK_EXPORT int64_t      dk_whisper_token_t0_ms(dk_whisper * dw, int32_t i, int32_t j);
DK_EXPORT int64_t      dk_whisper_token_t1_ms(dk_whisper * dw, int32_t i, int32_t j);
/* 1 for spoken-text tokens, 0 for specials ([_BEG_], timestamps, …). */
DK_EXPORT int32_t      dk_whisper_token_is_text(dk_whisper * dw, int32_t i, int32_t j);

#ifdef __cplusplus
}
#endif
