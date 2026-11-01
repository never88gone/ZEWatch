#include "llama.h"
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include <iostream>

struct llama_model {
    std::string path;
};

struct llama_context {
    struct llama_model * model;
    std::string input_text;
    std::string generated_text;
    size_t gen_index;
};

struct llama_vocab {
    int dummy;
};

static struct llama_vocab g_vocab = { 0 };
static struct llama_sampler g_sampler = { nullptr, nullptr };

extern "C" {

LLAMA_API void llama_backend_init(void) {
}

LLAMA_API void llama_backend_free(void) {
}

LLAMA_API struct llama_model_params llama_model_default_params(void) {
    struct llama_model_params params;
    std::memset(&params, 0, sizeof(params));
    params.n_gpu_layers = 0;
    return params;
}

LLAMA_API struct llama_context_params llama_context_default_params(void) {
    struct llama_context_params params;
    std::memset(&params, 0, sizeof(params));
    params.n_ctx = 2048;
    params.n_threads = 4;
    params.n_threads_batch = 4;
    return params;
}

LLAMA_API struct llama_sampler_chain_params llama_sampler_chain_default_params(void) {
    struct llama_sampler_chain_params params;
    std::memset(&params, 0, sizeof(params));
    return params;
}

LLAMA_API struct llama_model * llama_model_load_from_file(
        const char * path_model,
        struct llama_model_params params) {
    if (!path_model) return nullptr;
    auto * model = new llama_model();
    model->path = path_model;
    return model;
}

LLAMA_API void llama_model_free(struct llama_model * model) {
    if (model) delete model;
}

LLAMA_API struct llama_context * llama_init_from_model(
        struct llama_model * model,
        struct llama_context_params params) {
    if (!model) return nullptr;
    auto * ctx = new llama_context();
    ctx->model = model;
    ctx->gen_index = 0;
    return ctx;
}

LLAMA_API void llama_free(struct llama_context * ctx) {
    if (ctx) delete ctx;
}

LLAMA_API const struct llama_vocab * llama_model_get_vocab(const struct llama_model * model) {
    return &g_vocab;
}

LLAMA_API struct llama_batch llama_batch_init(
        int32_t n_tokens,
        int32_t embd,
        int32_t n_seq_max) {
    struct llama_batch batch;
    std::memset(&batch, 0, sizeof(batch));
    batch.n_tokens = 0;
    batch.token = (llama_token *)std::calloc(n_tokens, sizeof(llama_token));
    batch.pos = (llama_pos *)std::calloc(n_tokens, sizeof(llama_pos));
    batch.n_seq_id = (int32_t *)std::calloc(n_tokens, sizeof(int32_t));
    batch.seq_id = (llama_seq_id **)std::calloc(n_tokens, sizeof(llama_seq_id *));
    for (int i = 0; i < n_tokens; ++i) {
        batch.seq_id[i] = (llama_seq_id *)std::calloc(n_seq_max > 0 ? n_seq_max : 1, sizeof(llama_seq_id));
    }
    batch.logits = (int8_t *)std::calloc(n_tokens, sizeof(int8_t));
    return batch;
}

LLAMA_API void llama_batch_free(struct llama_batch batch) {
    if (batch.token) std::free(batch.token);
    if (batch.pos) std::free(batch.pos);
    if (batch.n_seq_id) std::free(batch.n_seq_id);
    if (batch.seq_id) {
        for (int i = 0; i < 2048; ++i) {
            if (batch.seq_id[i]) std::free(batch.seq_id[i]);
        }
        std::free(batch.seq_id);
    }
    if (batch.logits) std::free(batch.logits);
}

LLAMA_API struct llama_sampler * llama_sampler_chain_init(struct llama_sampler_chain_params params) {
    return &g_sampler;
}

LLAMA_API struct llama_sampler * llama_sampler_init_temp(float t) {
    return &g_sampler;
}

LLAMA_API struct llama_sampler * llama_sampler_init_dist(uint32_t seed) {
    return &g_sampler;
}

LLAMA_API struct llama_sampler * llama_sampler_init_top_k(int32_t k) {
    return &g_sampler;
}

LLAMA_API struct llama_sampler * llama_sampler_init_top_p(float p, size_t min_keep) {
    return &g_sampler;
}

LLAMA_API void llama_sampler_reset(struct llama_sampler * smpl) {
}

LLAMA_API void llama_sampler_chain_add(struct llama_sampler * chain, struct llama_sampler * smpl) {
}

LLAMA_API void llama_sampler_free(struct llama_sampler * smpl) {
}

LLAMA_API llama_memory_t llama_get_memory(const struct llama_context * ctx) {
    return (llama_memory_t)1;
}

LLAMA_API void llama_memory_clear(llama_memory_t mem, bool clear_kv) {
}

LLAMA_API int32_t llama_tokenize(
    const struct llama_vocab * vocab,
                  const char * text,
                     int32_t   text_len,
                 llama_token * tokens,
                     int32_t   n_tokens_max,
                        bool   add_special,
                        bool   parse_special) {
    if (!text || text_len <= 0) return 0;
    int count = text_len < n_tokens_max ? text_len : n_tokens_max;
    for (int i = 0; i < count; ++i) {
        tokens[i] = (unsigned char)text[i];
    }
    return count;
}

LLAMA_API int32_t llama_decode(
        struct llama_context * ctx,
          struct llama_batch   batch) {
    if (!ctx) return -1;
    // 仅在 Prompt 首次注入阶段（batch.n_tokens > 1）初始化生成流与索引，单 Token 推演阶段严禁重置索引
    if (batch.n_tokens > 1) {
        ctx->gen_index = 0;
        static const char * replies[] = {
            "哼，竖子不足与谋！在这灵气枯竭的末法时代，你竟还敢如此懈怠？给老夫滚去磨炼筋骨！【天降机缘】",
            "噢？这股子韧劲倒有几分老夫当年的影子。拿着这点修为，莫折了向道之心！[EVENT:ADD_CULTIVATION:50]",
            "咳咳，小辈，你这吐纳之法错漏百出，若非老夫在此，你早已走火入魔！",
            "大机缘！老夫推演天机，感知你筋骨渐凝，此乃大道之始！【天降机缘】"
        };
        static int reply_idx = 0;
        ctx->generated_text = replies[reply_idx % 4];
        reply_idx++;
    }
    return 0;
}

LLAMA_API llama_token llama_sampler_sample(
        struct llama_sampler * smpl,
        struct llama_context * ctx,
                     int32_t   idx) {
    if (!ctx) return 0;
    if (ctx->gen_index >= ctx->generated_text.size()) {
        return 0; // EOG
    }
    llama_token t = (unsigned char)ctx->generated_text[ctx->gen_index++];
    return t;
}

LLAMA_API bool llama_vocab_is_eog(const struct llama_vocab * vocab, llama_token token) {
    return token == 0;
}

LLAMA_API bool llama_vocab_is_control(const struct llama_vocab * vocab, llama_token token) {
    return false;
}

LLAMA_API void llama_sampler_accept(struct llama_sampler * smpl, llama_token token) {
}

LLAMA_API int32_t llama_token_to_piece(
        const struct llama_vocab * vocab,
                     llama_token   token,
                             char * buf,
                          int32_t   length,
                          int32_t   lstrip,
                             bool   special) {
    if (length < 2) return 0;
    buf[0] = (char)token;
    buf[1] = '\0';
    return 1;
}

} // extern "C"
