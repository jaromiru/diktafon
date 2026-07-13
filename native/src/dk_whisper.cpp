#include "dk_whisper.h"

#include <cstdlib>
#include <cstring>
#include <string>

#include "whisper.h"
#include "ggml.h"

struct dk_whisper {
    whisper_context * ctx = nullptr;
    // Language actually used for the last run (explicit or detected).
    std::string lang;
    // > 1 = beam search with this beam size; otherwise greedy.
    int32_t beam_size = 0;
    // Silero VAD model path; empty = VAD off.
    std::string vad_model_path;
    // Whether the last run used VAD (token times then need mapping).
    bool vad_used = false;
};

namespace {

void dk_quiet_log(ggml_log_level, const char *, void *) {}

bool dk_abort_cb(void * user_data) {
    const volatile int32_t * cancel =
        static_cast<const volatile int32_t *>(user_data);
    return cancel != nullptr && *cancel != 0;
}

} // namespace

extern "C" {

dk_whisper * dk_whisper_init(const char * model_path) {
    // Whisper/ggml log every model layer to stderr; keep the app console
    // usable unless explicitly debugging the engine.
    if (std::getenv("DK_WHISPER_LOG") == nullptr) {
        whisper_log_set(dk_quiet_log, nullptr);
        ggml_log_set(dk_quiet_log, nullptr);
    }

    whisper_context_params cparams = whisper_context_default_params();
    cparams.use_gpu = false; // CPU backend only (§6.5: bounded, predictable)

    whisper_context * ctx =
        whisper_init_from_file_with_params(model_path, cparams);
    if (ctx == nullptr) {
        return nullptr;
    }
    dk_whisper * dw = new dk_whisper();
    dw->ctx = ctx;
    return dw;
}

void dk_whisper_free(dk_whisper * dw) {
    if (dw == nullptr) {
        return;
    }
    whisper_free(dw->ctx);
    delete dw;
}

void dk_whisper_set_beam_size(dk_whisper * dw, int32_t beam_size) {
    dw->beam_size = beam_size;
void dk_whisper_set_vad_model(dk_whisper * dw, const char * model_path) {
    dw->vad_model_path = model_path != nullptr ? model_path : "";
}

int32_t dk_whisper_transcribe(dk_whisper * dw,
                              const float * pcm,
                              int32_t n_samples,
                              const char * lang,
                              int32_t n_threads,
                              const int32_t * cancel) {
    const bool beam = dw->beam_size > 1;
    whisper_full_params wparams = whisper_full_default_params(
        beam ? WHISPER_SAMPLING_BEAM_SEARCH : WHISPER_SAMPLING_GREEDY);
    if (beam) {
        wparams.beam_search.beam_size = dw->beam_size;
    }

    // Silero VAD (docs/features/noise-robust-transcription.md phase 1.1):
    // only detected speech regions reach the whisper encoder — cuts
    // hallucinations on noise-only stretches and skips silence. Defaults
    // from whisper_vad_default_params (threshold 0.5, min speech 250 ms).
    dw->vad_used = !dw->vad_model_path.empty();
    if (dw->vad_used) {
        wparams.vad            = true;
        wparams.vad_model_path = dw->vad_model_path.c_str();
        // Bench/dev-only tuning knobs (quality bench sweeps these; a
        // production default would be baked in here once chosen).
        if (const char * t = std::getenv("DK_WHISPER_VAD_THRESHOLD")) {
            wparams.vad_params.threshold = static_cast<float>(atof(t));
        }
        if (const char * p = std::getenv("DK_WHISPER_VAD_PAD_MS")) {
            wparams.vad_params.speech_pad_ms = atoi(p);
        }
        if (const char * s = std::getenv("DK_WHISPER_VAD_MIN_SILENCE_MS")) {
            wparams.vad_params.min_silence_duration_ms = atoi(s);
        }
    }

    wparams.print_realtime   = false;
    wparams.print_progress   = false;
    wparams.print_timestamps = false;
    wparams.print_special    = false;
    wparams.translate        = false;
    wparams.no_context       = true; // memos are independent recordings
    wparams.token_timestamps = true; // word-level timing is the product (§4.1)
    // Suppress non-speech tokens (♪, bracketed stage directions) during
    // decoding: removes a class of noise-induced hallucination at zero cost
    // (docs/features/noise-robust-transcription.md phase 1.2).
    wparams.suppress_nst     = true;
    wparams.n_threads        = n_threads;
    wparams.language         = (lang != nullptr && lang[0] != '\0') ? lang : "auto";
    wparams.abort_callback   = dk_abort_cb;
    wparams.abort_callback_user_data =
        const_cast<void *>(static_cast<const void *>(cancel));

    const int ret = whisper_full(dw->ctx, wparams, pcm, n_samples);
    if (ret != 0) {
        return ret;
    }

    const char * used = (lang != nullptr && lang[0] != '\0')
        ? lang
        : whisper_lang_str(whisper_full_lang_id(dw->ctx));
    dw->lang = used != nullptr ? used : "";
    return 0;
}

const char * dk_whisper_lang(dk_whisper * dw) {
    return dw->lang.c_str();
}

int32_t dk_whisper_n_segments(dk_whisper * dw) {
    return whisper_full_n_segments(dw->ctx);
}

// whisper timestamps are in 10 ms ticks; Diktafon speaks milliseconds.
int64_t dk_whisper_segment_t0_ms(dk_whisper * dw, int32_t i) {
    return whisper_full_get_segment_t0(dw->ctx, i) * 10;
}

int64_t dk_whisper_segment_t1_ms(dk_whisper * dw, int32_t i) {
    return whisper_full_get_segment_t1(dw->ctx, i) * 10;
}

int32_t dk_whisper_n_tokens(dk_whisper * dw, int32_t i) {
    return whisper_full_n_tokens(dw->ctx, i);
}

const char * dk_whisper_token_text(dk_whisper * dw, int32_t i, int32_t j) {
    return whisper_full_get_token_text(dw->ctx, i, j);
}

namespace {

// With VAD enabled, whisper.cpp maps only *segment* timestamps back to the
// original timeline (state->vad_mapping_table, whisper.cpp:7983+); token
// getters still return times on the VAD-collapsed stream. Interpolate each
// token linearly from the segment's raw token span onto its mapped span —
// exact within one speech region, and keeps word taps/highlight usable.
int64_t dk_token_time_ms(dk_whisper * dw, int32_t i, int64_t t_raw) {
    if (!dw->vad_used) {
        return t_raw * 10;
    }
    const int32_t n = whisper_full_n_tokens(dw->ctx, i);
    if (n <= 0) {
        return whisper_full_get_segment_t0(dw->ctx, i) * 10;
    }
    const int64_t raw0 = whisper_full_get_token_data(dw->ctx, i, 0).t0;
    const int64_t raw1 = whisper_full_get_token_data(dw->ctx, i, n - 1).t1;
    const int64_t map0 = whisper_full_get_segment_t0(dw->ctx, i);
    const int64_t map1 = whisper_full_get_segment_t1(dw->ctx, i);
    if (raw1 <= raw0) {
        return map0 * 10;
    }
    const int64_t clamped = t_raw < raw0 ? raw0 : (t_raw > raw1 ? raw1 : t_raw);
    return (map0 + ((clamped - raw0) * (map1 - map0)) / (raw1 - raw0)) * 10;
}

} // namespace

int64_t dk_whisper_token_t0_ms(dk_whisper * dw, int32_t i, int32_t j) {
    return dk_token_time_ms(
        dw, i, whisper_full_get_token_data(dw->ctx, i, j).t0);
}

int64_t dk_whisper_token_t1_ms(dk_whisper * dw, int32_t i, int32_t j) {
    return dk_token_time_ms(
        dw, i, whisper_full_get_token_data(dw->ctx, i, j).t1);
}

int32_t dk_whisper_token_is_text(dk_whisper * dw, int32_t i, int32_t j) {
    return whisper_full_get_token_id(dw->ctx, i, j) < whisper_token_eot(dw->ctx)
        ? 1
        : 0;
}

// Confidence accessors (docs/features/noise-robust-transcription.md
// phase 1.3): the engine already computes these; hallucinated segments on
// noise show high no_speech_prob and low mean token probability.

float dk_whisper_segment_no_speech_prob(dk_whisper * dw, int32_t i) {
    return whisper_full_get_segment_no_speech_prob(dw->ctx, i);
}

float dk_whisper_segment_avg_token_p(dk_whisper * dw, int32_t i) {
    const int32_t n = whisper_full_n_tokens(dw->ctx, i);
    float sum = 0.0f;
    int32_t text_tokens = 0;
    for (int32_t j = 0; j < n; j++) {
        if (dk_whisper_token_is_text(dw, i, j) == 0) {
            continue;
        }
        sum += whisper_full_get_token_data(dw->ctx, i, j).p;
        text_tokens++;
    }
    return text_tokens > 0 ? sum / text_tokens : 0.0f;
}

} // extern "C"
