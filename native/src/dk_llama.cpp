#include "dk_llama.h"

#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#include "llama.h"
#include "ggml.h"

struct dk_llama {
    llama_model *   model = nullptr;
    llama_context * ctx   = nullptr;
    int32_t         n_ctx = 0;
    // Cancel flag for the generate in flight; read by the abort callback.
    const volatile int32_t * cancel = nullptr;
    std::string result;
};

namespace {

void dk_quiet_log(ggml_log_level, const char *, void *) {}

bool dk_abort_cb(void * user_data) {
    const dk_llama * dl = static_cast<const dk_llama *>(user_data);
    return dl->cancel != nullptr && *dl->cancel != 0;
}

bool dk_cancelled(const dk_llama * dl) {
    return dl->cancel != nullptr && *dl->cancel != 0;
}

// Applies the model's chat template (fallback: ChatML) to one
// [system, user] exchange, with the assistant header appended.
bool dk_apply_template(const llama_model * model,
                       const char * system_prompt,
                       const char * user_prompt,
                       std::string & out) {
    const llama_chat_message msgs[2] = {
        {"system", system_prompt},
        {"user",   user_prompt},
    };
    const char * tmpl = llama_model_chat_template(model, nullptr);
    if (tmpl == nullptr) {
        tmpl = "chatml";
    }
    std::vector<char> buf(4096);
    int32_t n = llama_chat_apply_template(tmpl, msgs, 2, true,
                                          buf.data(), (int32_t) buf.size());
    if (n < 0) {
        // Unknown template string → ChatML, which every candidate model
        // (Qwen family) speaks natively anyway.
        n = llama_chat_apply_template("chatml", msgs, 2, true,
                                      buf.data(), (int32_t) buf.size());
    }
    if (n < 0) {
        return false;
    }
    if (n > (int32_t) buf.size()) {
        buf.resize(n);
        n = llama_chat_apply_template(tmpl, msgs, 2, true,
                                      buf.data(), (int32_t) buf.size());
        if (n < 0 || n > (int32_t) buf.size()) {
            return false;
        }
    }
    out.assign(buf.data(), (size_t) n);
    return true;
}

} // namespace

extern "C" {

dk_llama * dk_llama_init(const char * model_path,
                         int32_t n_ctx,
                         int32_t n_threads) {
    // llama/ggml log every tensor to stderr; keep the app console usable
    // unless explicitly debugging the engine.
    if (std::getenv("DK_LLAMA_LOG") == nullptr) {
        llama_log_set(dk_quiet_log, nullptr);
        ggml_log_set(dk_quiet_log, nullptr);
    }

    static bool backend_ready = false;
    if (!backend_ready) {
        llama_backend_init();
        backend_ready = true;
    }

    llama_model_params mparams = llama_model_default_params();
    llama_model * model = llama_model_load_from_file(model_path, mparams);
    if (model == nullptr) {
        return nullptr;
    }

    llama_context_params cparams = llama_context_default_params();
    cparams.n_ctx           = (uint32_t) n_ctx;
    cparams.n_batch         = 512;
    cparams.n_threads       = n_threads;
    cparams.n_threads_batch = n_threads;

    llama_context * ctx = llama_init_from_model(model, cparams);
    if (ctx == nullptr) {
        llama_model_free(model);
        return nullptr;
    }

    dk_llama * dl = new dk_llama();
    dl->model = model;
    dl->ctx   = ctx;
    dl->n_ctx = n_ctx;
    llama_set_abort_callback(ctx, dk_abort_cb, dl);
    return dl;
}

void dk_llama_free(dk_llama * dl) {
    if (dl == nullptr) {
        return;
    }
    llama_free(dl->ctx);
    llama_model_free(dl->model);
    delete dl;
}

int32_t dk_llama_generate(dk_llama * dl,
                          const char * system_prompt,
                          const char * user_prompt,
                          int32_t max_tokens,
                          float temperature,
                          const int32_t * cancel) {
    dl->cancel = cancel;
    dl->result.clear();

    std::string prompt;
    if (!dk_apply_template(dl->model, system_prompt, user_prompt, prompt)) {
        return -1;
    }

    const llama_vocab * vocab = llama_model_get_vocab(dl->model);

    // Each memo/summary request is independent — start from an empty cache.
    llama_memory_clear(llama_get_memory(dl->ctx), true);

    const int32_t n_prompt = -llama_tokenize(
        vocab, prompt.c_str(), (int32_t) prompt.size(),
        nullptr, 0, /*add_special=*/true, /*parse_special=*/true);
    if (n_prompt <= 0) {
        return -1;
    }
    // Headroom of 8 tokens for EOG/template slack.
    if (n_prompt + max_tokens + 8 > dl->n_ctx) {
        return -3;
    }
    std::vector<llama_token> tokens((size_t) n_prompt);
    if (llama_tokenize(vocab, prompt.c_str(), (int32_t) prompt.size(),
                       tokens.data(), n_prompt, true, true) < 0) {
        return -1;
    }

    llama_sampler * sampler =
        llama_sampler_chain_init(llama_sampler_chain_default_params());
    if (temperature <= 0.0f) {
        llama_sampler_chain_add(sampler, llama_sampler_init_greedy());
    } else {
        // Mild anti-repetition + nucleus sampling: small models drift into
        // loops under pure greedy on repetitive dictation transcripts.
        llama_sampler_chain_add(sampler,
            llama_sampler_init_penalties(64, 1.1f, 0.0f, 0.0f));
        llama_sampler_chain_add(sampler, llama_sampler_init_top_k(40));
        llama_sampler_chain_add(sampler, llama_sampler_init_top_p(0.95f, 1));
        llama_sampler_chain_add(sampler, llama_sampler_init_temp(temperature));
        // Fixed seed: same transcript → same summary across retries.
        llama_sampler_chain_add(sampler, llama_sampler_init_dist(42));
    }

    int32_t ret = 0;

    // Prefill in n_batch chunks, then decode token by token.
    const int32_t n_batch = 512;
    for (int32_t off = 0; off < n_prompt; off += n_batch) {
        if (dk_cancelled(dl)) {
            goto done;
        }
        const int32_t n = n_prompt - off < n_batch ? n_prompt - off : n_batch;
        if (llama_decode(dl->ctx,
                         llama_batch_get_one(tokens.data() + off, n)) != 0) {
            ret = dk_cancelled(dl) ? 0 : -2;
            goto done;
        }
    }

    for (int32_t i = 0; i < max_tokens; i++) {
        if (dk_cancelled(dl)) {
            break;
        }
        llama_token tok = llama_sampler_sample(sampler, dl->ctx, -1);
        if (llama_vocab_is_eog(vocab, tok)) {
            break;
        }
        char piece[256];
        const int32_t n = llama_token_to_piece(vocab, tok, piece,
                                               (int32_t) sizeof(piece),
                                               0, /*special=*/true);
        if (n > 0) {
            dl->result.append(piece, (size_t) n);
        }
        if (llama_decode(dl->ctx, llama_batch_get_one(&tok, 1)) != 0) {
            ret = dk_cancelled(dl) ? 0 : -2;
            break;
        }
    }

done:
    llama_sampler_free(sampler);
    dl->cancel = nullptr;
    return ret;
}

const char * dk_llama_result(dk_llama * dl) {
    return dl->result.c_str();
}

} // extern "C"
