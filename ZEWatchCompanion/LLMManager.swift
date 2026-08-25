import Foundation

#if os(iOS)
struct LLMModelOption: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let url: String
    let sizeDesc: String
}

@MainActor
class LLMManager: ObservableObject {
    static let shared = LLMManager()
    
    static let recommendedModels: [LLMModelOption] = [
        // 中文/全能 尖端主力 (2026)
        LLMModelOption(name: "Qwen3.5 4B", description: "全新一代千问3.5小旗舰，跨时代推理能力 (需3GB以上内存)", url: "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf", sizeDesc: "约 2.4 GB"),
        LLMModelOption(name: "Qwen2.5 1.5B", description: "千问2.5代轻量能打，低配机型中文首选", url: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf", sizeDesc: "约 1.1 GB"),
        LLMModelOption(name: "Qwen2.5 0.5B", description: "千问2.5代极速版，极致省电，老机型流畅运行", url: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf", sizeDesc: "约 390 MB"),
        
        // 国际顶尖微型架构 (2026)
        LLMModelOption(name: "Gemma-4 E4B", description: "Google 2026最强E架构，媲美百亿参数巨兽", url: "https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/gemma-4-E4B-it-Q4_K_M.gguf", sizeDesc: "约 2.6 GB"),
        
        // 特色精选
        LLMModelOption(name: "Yi-Coder 1.5B", description: "代码与逻辑强化版1.5B，适合严谨分析", url: "https://huggingface.co/MaziyarPanahi/Yi-Coder-1.5B-Chat-GGUF/resolve/main/Yi-Coder-1.5B-Chat-Q4_K_M.gguf", sizeDesc: "约 1.0 GB")
    ]
    
    @Published var messages: [ChatMessage] = []
    @Published var isGenerating: Bool = false
    @Published var modelLoaded: Bool = false
    @Published var statusMessage: String = "未感应到戒灵..."
    
    // 下载相关状态
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0.0

    private var context: LlamaContext?
    private var currentDownloadTask: URLSessionDownloadTask?
    
    private init() {}
    
    /// 加载本地 Llama 模型
    func loadModel(modelPath: String? = nil) async {
        statusMessage = "正在唤醒戒灵..."
        
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelsPath = documentDirectory.appendingPathComponent("Models").path
        
        var path: String? = nil
        
        if fileManager.fileExists(atPath: modelsPath),
           let files = try? fileManager.contentsOfDirectory(atPath: modelsPath),
           let firstGGUF = files.first(where: { $0.hasSuffix(".gguf") }) {
            path = modelsPath + "/" + firstGGUF
        }
        
        guard let finalPath = path else {
            statusMessage = "戒灵沉睡，未见法器。请先下载模型。"
            print("【LLM】错误：未能发现任何 .gguf 后缀的模型文件。请在界面上触发下载。")
            return
        }
        
        do {
            // 通过 Task.detached 将底层耗时的 C 库初始化操作移至后台线程，防止阻塞主线程导致启动过慢
            let newContext = try await Task.detached(priority: .userInitiated) {
                return try await LlamaContext.create_context(path: finalPath)
            }.value
            
            self.context = newContext
            modelLoaded = true
            statusMessage = "咳咳... 谁在那吵老夫睡觉？"
            
            // 初始消息
            messages.append(ChatMessage(role: .assistant, content: "小辈，今日为何无精打采？若再不磨炼筋骨，老夫这戒指可容不下你了。"))
            
        } catch {
            statusMessage = "唤醒失败：神魂受损"
            print("【LLM】加载异常：\(error)")
        }
    }
    
    /// 发送消息并获取老爷爷的毒舌指点
    func sendUserMessage(_ text: String, stats: [String: Any], player: PlayerProfile) async {
        guard !text.isEmpty, !isGenerating else { return }
        
        // 1. 添加用户消息
        let userMsg = ChatMessage(role: .user, content: text)
        messages.append(userMsg)
        
        // 2. 准备老爷爷的消息占位
        var assistantMsg = ChatMessage(role: .assistant, content: "", isGenerating: true)
        messages.append(assistantMsg)
        let msgIndex = messages.count - 1
        
        isGenerating = true
        
        // 3. 构造沉浸式 Prompt (毒舌大能人设 + Few-shot 引导)
        let realmLevel = stats["realm"] as? Int16 ?? 0
        let realmName = CultivationEngine.shared.realmName(for: realmLevel)
        let base = stats["cultivationBase"] as? Int64 ?? 0
        let body = stats["bodyLevel"] as? Int16 ?? 1
        
        let systemPrompt = """
        你是“墨老”，寄宿在戒指中的远古上仙残魂。你性格孤高、毒舌、严厉，对后辈“恨铁不成钢”。
        对方是修仙小辈。
        
        【当前状态】：境界【\(realmName)】 | 修为【\(base) 灵气】
        
        【核心戒律】：
        1. 必须使用简体中文回复！禁止英文。
        2. 说话自称“老夫”，称对方“小辈”或“竖子”。用词古风，毒舌且傲娇。
        3. 字数严格控制在30字以内！禁止任何场景描写或括号里的动作描述。
        4. 进步（如运动、坚持）时，在对话最后加上机缘代码：[EVENT:ADD_CULTIVATION:X]（X为10-50）。
        5. 不要重复对方的话，也不要重复之前说过的内容，直接开始聊天。
        """
        
        var fullPrompt = "<|im_start|>system\n\(systemPrompt)<|im_end|>\n"
        
        // Few-shot 直接以标准格式注入上下文，防止小模型被 system 里的对话范式误导而自我生成 user 对话
        let fewShots = [
            ("user", "墨老，我今日不想练功了。"),
            ("assistant", "哼，竖子不足与谋！在这灵气枯竭的末法时代，你竟还敢如此懈怠？给老夫滚去磨炼筋骨！"),
            ("user", "墨老，我今日走了两万里路。"),
            ("assistant", "噢？虽说是凡胎，这股子韧劲倒有几分老夫当年的影子。拿着这点修为，莫折了向道之心！[EVENT:ADD_CULTIVATION:50]")
        ]
        
        for shot in fewShots {
            fullPrompt += "<|im_start|>\(shot.0)\n\(shot.1)<|im_end|>\n"
        }
        
        // 历史消息从第一条 user 消息开始取，跳过欢迎消息，跳过 system 消息（气机提示）
        // 避免 few-shot 末尾 assistant + 欢迎消息 assistant 两个连续 assistant 块导致模型错乱
        let allHistory = Array(messages.dropLast())
        let firstUserIdx = allHistory.firstIndex(where: { $0.role == .user }) ?? allHistory.startIndex
        let recentMessages = Array(allHistory[firstUserIdx...])
            .filter { $0.role != .system }   // 跳过【机缘】等 system 提示消息
            .suffix(4)                        // 保留最近 4 条，减少输入 token 给生成留更多空间
        for msg in recentMessages {
            let role = msg.role == .user ? "user" : "assistant"
            // 清理控制符、前缀、think块（防止思考过程污染下轮对话）
            let cleanedContent = msg.content
                .replacingOccurrences(of: "<\\|.*?\\|>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "^(user|assistant|system):\\s*", with: "", options: [.regularExpression, .caseInsensitive])
                .replacingOccurrences(of: "<think>[\\s\\S]*?</think>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "<思维>[\\s\\S]*?</思维>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanedContent.isEmpty else { continue }
            fullPrompt += "<|im_start|>\(role)\n\(cleanedContent)<|im_end|>\n"
        }
        // 注入 </think> 前缀：告诉推理模型"思考阶段已结束，直接输出正文"
        // 这是针对 Qwen-Thinking / DeepSeek-R1 等推理模型的标准技巧
        // 避免模型在 <think> 里用英文大量分析，耗尽 token 预算后正文被截断
        fullPrompt += "<|im_start|>assistant\n<think>\n\n</think>\n"
        
        // ===== 日志：打印完整 Prompt =====
        print("\n╔══════════════════ 【LLM Prompt 开始】 ══════════════════╗\n" + fullPrompt + "\n╚══════════════════ 【LLM Prompt 结束】 ══════════════════╝")
        
        // 4. 执行推理
        await context?.completion_init(text: fullPrompt)
        
        var rawResponse = ""
        while let context = context, await !context.is_done {
            let nextToken = await context.completion_loop()
            rawResponse += nextToken
            
            // 过滤控制符和 think 块（直接删除，不替换标签，避免污染历史）
            let filteredText = rawResponse
                .replacingOccurrences(of: "<\\|.*?\\|>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "<think>[\\s\\S]*?</think>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "<think>[\\s\\S]*", with: "", options: .regularExpression) // think未闭合时也清除
                .replacingOccurrences(of: "\\[EVENT:.*?\\]", with: "", options: .regularExpression)
                .replacingOccurrences(of: "(?i)(?:user|assistant|system)[:\\n]?", with: "", options: .regularExpression)
            
            messages[msgIndex].content = filteredText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        
        // ===== 日志：打印原始响应 =====
        print("\n╔══════════════════ 【LLM 原始响应】 ══════════════════╗\n" + rawResponse + "\n╚══════════════════ 【LLM 响应结束】 ══════════════════╝")
        
        // 5. 解析并执行事件
        parseAndExecuteEvents(rawResponse, player: player)
        
        messages[msgIndex].isGenerating = false
        isGenerating = false
    }
    
    private func parseAndExecuteEvents(_ response: String, player: PlayerProfile) {
        let pattern = "\\[EVENT:(.*?):(.*?)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        
        let nsRange = NSRange(response.startIndex..<response.endIndex, in: response)
        let matches = regex.matches(in: response, range: nsRange)
        
        for match in matches {
            if let typeRange = Range(match.range(at: 1), in: response),
               let valueRange = Range(match.range(at: 2), in: response) {
                let type = String(response[typeRange])
                let valueStr = String(response[valueRange])
                
                if type == "ADD_CULTIVATION", let value = Int64(valueStr) {
                    player.cultivationBase += value
                    // 添加一个系统提示消息
                    messages.append(ChatMessage(role: .system, content: "【机缘】老爷爷随手一指，你感觉到一股暖流涌入丹田，修为增加 \(value) 点！"))
                    
                    // 保存 CoreData (假设 player.managedObjectContext 存在)
                    try? player.managedObjectContext?.save()
                }
            }
        }
    }
    
    /// 当 WCSession 收到手表上的修真数据透传时，产生天道意志（后台触发）
    /// 用来感应并在聊天模块给出评价或者掉落机缘
    func generateHeavenlyWill(stats: [String: Any]) async {
        guard modelLoaded, !isGenerating else { return }
        print("【LLM】天道意志后台感应到修行数据变化：\(stats)")
        // TODO: 后续可以自动触发老爷爷主动发送一句聊天或掉落机缘
    }
    
    // MARK: - 下载模型
    
    func downloadModel(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        isDownloading = true
        downloadProgress = 0.0
        statusMessage = "正在接引戒灵下界..."
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: DownloadDelegate(progressHandler: { [weak self] progress in
            DispatchQueue.main.async {
                self?.downloadProgress = progress
            }
        }, completionHandler: { [weak self] localURL, error in
            DispatchQueue.main.async {
                self?.isDownloading = false
                guard let self = self else { return }
                
                if let error = error {
                    self.statusMessage = "接引失败: \(error.localizedDescription)"
                    print("下载错误:", error)
                    return
                }
                
                guard let localURL = localURL else {
                    self.statusMessage = "接引失败: 数据残缺"
                    return
                }
                
                self.saveDownloadedModel(from: localURL, filename: url.lastPathComponent)
            }
        }), delegateQueue: nil)
        
        let task = session.downloadTask(with: url)
        self.currentDownloadTask = task
        task.resume()
    }
    
    func cancelDownload() {
        currentDownloadTask?.cancel()
        currentDownloadTask = nil
        isDownloading = false
        downloadProgress = 0.0
        statusMessage = "接引已中断"
    }
    
    private func saveDownloadedModel(from tempURL: URL, filename: String) {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelsDirectory = documentDirectory.appendingPathComponent("Models")
        
        do {
            if !fileManager.fileExists(atPath: modelsDirectory.path) {
                try fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            // 清空现有的所有模型文件以释放空间 (单法器模式)
            if let files = try? fileManager.contentsOfDirectory(atPath: modelsDirectory.path) {
                for file in files where file.hasSuffix(".gguf") {
                    let oldFileURL = modelsDirectory.appendingPathComponent(file)
                    try? fileManager.removeItem(at: oldFileURL)
                    print("已清理旧模型: \(file)")
                }
            }
            
            let destinationURL = modelsDirectory.appendingPathComponent(filename)
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            
            statusMessage = "法器重铸成功，正在唤醒..."
            Task {
                await self.loadModel()
            }
        } catch {
            statusMessage = "保存法器失败"
            print("文件移动错误:", error)
        }
    }
}

// 辅助代理类，用于处理下载进度
class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    var progressHandler: (Double) -> Void
    var completionHandler: (URL?, Error?) -> Void
    
    init(progressHandler: @escaping (Double) -> Void, completionHandler: @escaping (URL?, Error?) -> Void) {
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progressHandler(progress)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        completionHandler(location, nil)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completionHandler(nil, error)
        }
    }
}
#endif
