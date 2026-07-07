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

int32_t dk_whisper_transcribe(dk_whisper * dw,
                              const float * pcm,
                              int32_t n_samples,
                              const char * lang,
                              int32_t n_threads,
                              const int32_t * cancel) {
    whisper_full_params wparams =
        whisper_full_default_params(WHISPER_SAMPLING_GREEDY);

    wparams.print_realtime   = false;
    wparams.print_progress   = false;
    wparams.print_timestamps = false;
    wparams.print_special    = false;
    wparams.translate        = false;
    wparams.no_context       = true; // memos are independent recordings
    wparams.token_timestamps = true; // word-level timing is the product (§4.1)
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

int64_t dk_whisper_token_t0_ms(dk_whisper * dw, int32_t i, int32_t j) {
    return whisper_full_get_token_data(dw->ctx, i, j).t0 * 10;
}

int64_t dk_whisper_token_t1_ms(dk_whisper * dw, int32_t i, int32_t j) {
    return whisper_full_get_token_data(dw->ctx, i, j).t1 * 10;
}

int32_t dk_whisper_token_is_text(dk_whisper * dw, int32_t i, int32_t j) {
    return whisper_full_get_token_id(dw->ctx, i, j) < whisper_token_eot(dw->ctx)
        ? 1
        : 0;
}

} // extern "C"
