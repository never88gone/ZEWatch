import Foundation

#if os(iOS)
// import llama - Now handled by Bridging Header

enum LlamaError: Error {
    case couldNotInitializeContext
}

func llama_batch_clear(_ batch: inout llama_batch) {
    batch.n_tokens = 0
}

func llama_batch_add(_ batch: inout llama_batch, _ id: llama_token, _ pos: llama_pos, _ seq_ids: [llama_seq_id], _ logits: Bool) {
    batch.token   [Int(batch.n_tokens)] = id
    batch.pos     [Int(batch.n_tokens)] = pos
    batch.n_seq_id[Int(batch.n_tokens)] = Int32(seq_ids.count)
    if let seq_id_ptr = batch.seq_id[Int(batch.n_tokens)] {
        for i in 0..<seq_ids.count {
            seq_id_ptr[Int(i)] = seq_ids[i]
        }
    } else {
        // 安全兜底：如果底层内存分配失败或版本不匹配，打印警告但不崩溃
        print("【识海】关键警告：batch.seq_id 内存槽位为空")
    }
    batch.logits  [Int(batch.n_tokens)] = logits ? 1 : 0

    batch.n_tokens += 1
}

actor LlamaContext {
    private var model: OpaquePointer
    private var context: OpaquePointer
    private var vocab: OpaquePointer
    private var sampling: UnsafeMutablePointer<llama_sampler>
    private var batch: llama_batch
    private var tokens_list: [llama_token]
    
    var is_done: Bool = false
    var n_len: Int32 = 512
    var n_cur: Int32 = 0
    var n_decode: Int32 = 0

    private var temporary_invalid_cchars: [CChar]
    private var generatedBuffer: String = "" // 用于实时拦截的缓冲区

    init(model: OpaquePointer, context: OpaquePointer) {
        self.model = model
        self.context = context
        self.tokens_list = []
        self.batch = llama_batch_init(512, 0, 1)
        self.temporary_invalid_cchars = []
        
        let sparams = llama_sampler_chain_default_params()
        self.sampling = llama_sampler_chain_init(sparams)
        llama_sampler_chain_add(self.sampling, llama_sampler_init_temp(0.7))
        llama_sampler_chain_add(self.sampling, llama_sampler_init_dist(UInt32(Date().timeIntervalSince1970)))
        
        vocab = llama_model_get_vocab(model)
    }

    deinit {
        llama_sampler_free(sampling)
        llama_batch_free(batch)
        llama_model_free(model)
        llama_free(context)
        llama_backend_free()
    }

    static func create_context(path: String) throws -> LlamaContext {
        llama_backend_init()
        var model_params = llama_model_default_params()

        #if targetEnvironment(simulator)
        model_params.n_gpu_layers = 0
        print("【识海】检测到拟境运行，禁用灵法加速。")
        #else
        model_params.n_gpu_layers = 100 // 针对 0.5B 全部放入 GPU
        #endif

        let model = llama_model_load_from_file(path, model_params)
        guard let model = model else {
            print("【识海】未能寻得命定权重：\(path)")
            throw LlamaError.couldNotInitializeContext
        }

        let n_threads = max(1, min(8, ProcessInfo.processInfo.processorCount - 2))
        var ctx_params = llama_context_default_params()
        ctx_params.n_ctx = 2048
        ctx_params.n_threads = Int32(n_threads)
        ctx_params.n_threads_batch = Int32(n_threads)

        let context = llama_init_from_model(model, ctx_params)
        guard let context = context else {
            throw LlamaError.couldNotInitializeContext
        }

        return LlamaContext(model: model, context: context)
    }

    func completion_init(text: String) {
        is_done = false
        
        // 清理上一次对话的 KV 缓存，因为目前逻辑是每次都将包含历史的 fullPrompt 从头灌入
        let memory = llama_get_memory(context)
        llama_memory_clear(memory, true)
        
        tokens_list = tokenize(text: text, add_bos: false)
        temporary_invalid_cchars = []
        generatedBuffer = "" // 重置缓冲区

        llama_batch_clear(&batch)
        for i in 0..<tokens_list.count {
            llama_batch_add(&batch, tokens_list[i], Int32(i), [0], false)
        }
        batch.logits[Int(batch.n_tokens) - 1] = 1

        if llama_decode(context, batch) != 0 {
            print("【识海】推演中断")
        }

        n_cur = batch.n_tokens
    }

    func completion_loop() -> String {
        guard !is_done else { return "" }
        
        let new_token_id = llama_sampler_sample(sampling, context, batch.n_tokens - 1)

        // 1. 硬件级/EOG Token 检测
        if llama_vocab_is_eog(vocab, new_token_id) || n_cur >= n_len {
            is_done = true
            return ""
        }
        
        // 2. 控制 Token 直接跳过
        if llama_vocab_is_control(vocab, new_token_id) {
            decode_and_update(token_id: new_token_id)
            return ""
        }

        let new_token_cchars = token_to_piece(token: new_token_id)
        temporary_invalid_cchars.append(contentsOf: new_token_cchars)
        
        if let string = String(validatingUTF8: temporary_invalid_cchars + [0]) {
            temporary_invalid_cchars.removeAll()
            let newText = string
            generatedBuffer += newText
            
            // 3. 全局滑动窗口匹配停止词 (截断并拦截)
            let stopSequences = [
                "<|im_end|>", 
                "<|im_start|>", 
                "\nuser", 
                "\nassistant",
                "user:",
                "assistant:",
                "<|im"
            ]
            
            for stop in stopSequences {
                if let range = generatedBuffer.range(of: stop, options: .caseInsensitive) {
                    is_done = true
                    // 找到停止词，截断缓冲区并退出
                    let stopIndex = range.lowerBound
                    let validText = String(generatedBuffer[..<stopIndex])
                    // 这里的返回值需要是这一个 token 增加的有效文本（如果有的话）。
                    // 简化处理：由于 rawResponse 会追加这个函数的返回值，当遇到中止时，
                    // 只要最后返回 "" 且外层依靠 `generatedBuffer` 就更稳定。但原始方式是直接返回截断后的新文本。
                    if let stopInNewText = newText.range(of: stop, options: .caseInsensitive) {
                        return String(newText[..<stopInNewText.lowerBound])
                    } else {
                        return ""
                    }
                }
            }
            
            decode_and_update(token_id: new_token_id)
            return newText
        } else {
            // 字节补全中，暂不返回字符
            decode_and_update(token_id: new_token_id)
            return ""
        }
    }

    private func decode_and_update(token_id: llama_token) {
        llama_batch_clear(&batch)
        llama_batch_add(&batch, token_id, n_cur, [0], true)
        n_decode += 1
        n_cur += 1
        if llama_decode(context, batch) != 0 {
            print("【识海】推断崩溃")
        }
    }

    private func tokenize(text: String, add_bos: Bool) -> [llama_token] {
        let utf8Count = text.utf8.count
        let n_tokens = utf8Count + (add_bos ? 1 : 0) + 1
        let tokens = UnsafeMutablePointer<llama_token>.allocate(capacity: n_tokens)
        let tokenCount = llama_tokenize(vocab, text, Int32(utf8Count), tokens, Int32(n_tokens), add_bos, true)

        var swiftTokens: [llama_token] = []
        for i in 0..<tokenCount {
            swiftTokens.append(tokens[Int(i)])
        }
        tokens.deallocate()
        return swiftTokens
    }

    private func token_to_piece(token: llama_token) -> [CChar] {
        let result = UnsafeMutablePointer<Int8>.allocate(capacity: 8)
        result.initialize(repeating: Int8(0), count: 8)
        defer { result.deallocate() }
        let nTokens = llama_token_to_piece(vocab, token, result, 8, 0, false)

        if nTokens < 0 {
            let newResult = UnsafeMutablePointer<Int8>.allocate(capacity: Int(-nTokens))
            newResult.initialize(repeating: Int8(0), count: Int(-nTokens))
            defer { newResult.deallocate() }
            let nNewTokens = llama_token_to_piece(vocab, token, newResult, -nTokens, 0, false)
            let bufferPointer = UnsafeBufferPointer(start: newResult, count: Int(nNewTokens))
            return Array(bufferPointer)
        } else {
            let bufferPointer = UnsafeBufferPointer(start: result, count: Int(nTokens))
            return Array(bufferPointer)
        }
    }
}
#endif
