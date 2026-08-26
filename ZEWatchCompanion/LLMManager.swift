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
    
    @Published var localModels: [String] = []
    @Published var currentModelFilename: String = ""
    
    // 下载相关状态
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadedBytes: Int64 = 0
    @Published var totalBytes: Int64 = 0
    @Published var hasResumeData: Bool = false
    @Published var estimatedTimeRemaining: String = ""
    
    private var downloadStartTime: Date?
    
    private var currentDownloadTask: URLSessionDownloadTask?
    private var resumeData: Data? {
        didSet { hasResumeData = resumeData != nil }
    }

    private var context: LlamaContext?
    
    private init() {
        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        fetchLocalModels()
        loadHistory()
        checkOOMRecovery()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 历史消息持久化
    private var historyFileURL: URL {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent("chat_history.json")
    }
    
    func saveHistory() {
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: historyFileURL, options: .atomic)
        } catch {
            print("保存对话历史失败: \(error)")
        }
    }
    
    private func loadHistory() {
        do {
            guard FileManager.default.fileExists(atPath: historyFileURL.path) else { return }
            let data = try Data(contents: historyFileURL)
            let decoded = try JSONDecoder().decode([ChatMessage].self, from: data)
            DispatchQueue.main.async {
                self.messages = decoded
            }
        } catch {
            print("加载对话历史失败: \(error)")
        }
    }
    
    @Published var isConversingDisabled: Bool = false
    
    private func handleMemoryWarning() {
        print("【LLMManager】收到内存警告！正在清空对话记录以防 OOM...")
        // 清空历史记忆，仅保留最后一条和模型加载状态
        if messages.count > 2 {
            let lastMessages = Array(messages.suffix(2))
            messages = lastMessages
        }
        messages.append(ChatMessage(role: .system, content: "【神魂受创】因天道反噬（内存告警），墨老神魂激荡，暂时遗忘了先前的对话。"))
        saveHistory()
        UserDefaults.standard.set(Date(), forKey: "lastOOMDate")
    }
    
    func checkOOMRecovery() {
        if let lastOOM = UserDefaults.standard.object(forKey: "lastOOMDate") as? Date {
            let elapsed = Date().timeIntervalSince(lastOOM)
            if elapsed < 300 {
                // 5 分钟内
                DispatchQueue.main.async {
                    self.isConversingDisabled = true
                    if self.messages.last?.content.contains("神魂受创") == false {
                        self.messages.append(ChatMessage(role: .system, content: "【神魂受创】墨老因强行推演反噬，神魂虚弱，需静养 5 分钟。"))
                        self.saveHistory()
                    }
                }
                
                // 设置定时器解禁
                DispatchQueue.main.asyncAfter(deadline: .now() + (300 - elapsed)) {
                    self.isConversingDisabled = false
                    self.messages.append(ChatMessage(role: .system, content: "【神魂归位】墨老长舒一口气：‘总算缓过来了...’"))
                    self.saveHistory()
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "lastOOMDate")
            }
        }
    }
    
    /// 刷新并获取沙盒中的模型列表
    func fetchLocalModels() {
        let fileManager = FileManager.default
        let modelsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Models").path
        
        if fileManager.fileExists(atPath: modelsPath),
           let files = try? fileManager.contentsOfDirectory(atPath: modelsPath) {
            DispatchQueue.main.async {
                self.localModels = files.filter { $0.hasSuffix(".gguf") }.sorted()
            }
        } else {
            DispatchQueue.main.async {
                self.localModels = []
            }
        }
    }
    
    /// 导入外部模型文件
    func importModel(from url: URL) {
        let fileManager = FileManager.default
        let modelsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Models")
        
        do {
            if !fileManager.fileExists(atPath: modelsDir.path) {
                try fileManager.createDirectory(at: modelsDir, withIntermediateDirectories: true, attributes: nil)
            }
            
            // 因为系统选择器返回的可能是安全书签，必须调用 startAccessingSecurityScopedResource
            let startAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if startAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            let destURL = modelsDir.appendingPathComponent(url.lastPathComponent)
            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }
            try fileManager.copyItem(at: url, to: destURL)
            
            print("模型导入成功: \(url.lastPathComponent)")
            fetchLocalModels()
        } catch {
            print("模型导入失败: \(error)")
        }
    }
    
    /// 卸载当前模型并清理内存
    func unloadModel() {
        self.context = nil
        self.modelLoaded = false
        self.statusMessage = "戒灵沉睡..."
        self.currentModelFilename = ""
    }
    
    /// 删除指定本地模型
    func deleteModel(filename: String) {
        let fileManager = FileManager.default
        let fileURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Models").appendingPathComponent(filename)
        do {
            try fileManager.removeItem(at: fileURL)
            fetchLocalModels()
        } catch {
            print("删除模型失败: \(error)")
        }
    }
    
    /// 加载本地 Llama 模型
    func loadModel(filename: String? = nil) async {
        statusMessage = "正在唤醒戒灵..."
        
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelsPath = documentDirectory.appendingPathComponent("Models").path
        
        var path: String? = nil
        
        if let target = filename {
            path = modelsPath + "/" + target
        } else {
            // 回退到查找第一个模型
            if fileManager.fileExists(atPath: modelsPath),
               let files = try? fileManager.contentsOfDirectory(atPath: modelsPath),
               let firstGGUF = files.first(where: { $0.hasSuffix(".gguf") }) {
                path = modelsPath + "/" + firstGGUF
            }
        }
        
        guard let finalPath = path, fileManager.fileExists(atPath: finalPath) else {
            DispatchQueue.main.async {
                self.statusMessage = "戒灵沉睡，未见指定法器。请检查文件是否存在。"
                self.modelLoaded = false
            }
            return
        }
        
        do {
            // 通过 Task.detached 将底层耗时的 C 库初始化操作移至后台线程，防止阻塞主线程导致启动过慢
            let newContext = try await Task.detached(priority: .userInitiated) {
                return try await LlamaContext.create_context(path: finalPath)
            }.value
            
            self.context = newContext
            self.currentModelFilename = URL(fileURLWithPath: finalPath).lastPathComponent
            self.modelLoaded = true
            self.statusMessage = "咳咳... 谁在那吵老夫睡觉？"
            
            // 初始消息
            if messages.isEmpty {
                messages.append(ChatMessage(role: .assistant, content: "小辈，今日为何无精打采？若再不磨炼筋骨，老夫这戒指可容不下你了。"))
                saveHistory()
            }
            
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
        
        // 3. 构造沉浸式 Prompt (毒舌大能人设 + 动态状态)
        let realmLevel = stats["realm"] as? Int16 ?? 0
        let realmName = CultivationEngine.shared.realmName(for: realmLevel)
        let base = stats["cultivationBase"] as? Int64 ?? 0
        
        // 此处可通过 HealthManager 获取，为简化演示，使用伪造数值或从 stats 取
        let steps = stats["todaySteps"] as? Int ?? 10500 
        
        let systemPrompt = """
        你是“墨老”，寄宿在戒指中的远古上仙残魂。你性格孤高、毒舌、严厉，对后辈“恨铁不成钢”。
        对方是修仙小辈。
        
        【当前状态】：境界【\(realmName)】 | 修为【\(base) 灵气】 | 今日步数【\(steps)步】
        
        【核心戒律】：
        1. 必须使用简体中文回复！禁止英文。
        2. 说话自称“老夫”，称对方“小辈”或“竖子”。用词古风，毒舌且傲娇。
        3. 字数严格控制在30字以内！禁止任何场景描写。
        4. 若玩家今日步数大于 10000 步，你必须在回复的末尾精确加上【天降机缘】四个字作为奖励。
        5. 不要重复对方的话，直接开始聊天。
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
        let allHistory = Array(messages.dropLast())
        let firstUserIdx = allHistory.firstIndex(where: { $0.role == .user }) ?? allHistory.startIndex
        let recentMessages = Array(allHistory[firstUserIdx...])
            .filter { $0.role != .system }   // 跳过【机缘】等 system 提示消息
            .suffix(6)                        // 保留最近 6 条
            
        // 清理消息内容里的控制符，防止污染模型
        var cleanedHistory: [ChatMessage] = []
        for msg in recentMessages {
            let cleanedContent = msg.content
                .replacingOccurrences(of: "<\\|.*?\\|>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "^(user|assistant|system):\\s*", with: "", options: [.regularExpression, .caseInsensitive])
                .replacingOccurrences(of: "<think>[\\s\\S]*?</think>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "<思维>[\\s\\S]*?</思维>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanedContent.isEmpty {
                cleanedHistory.append(ChatMessage(role: msg.role, content: cleanedContent))
            }
        }
        
        let fullPrompt = PromptBuilder.build(
            systemPrompt: systemPrompt,
            history: cleanedHistory,
            modelFilename: currentModelFilename
        )
        
        // ===== 日志：打印完整 Prompt =====
        print("\n╔══════════════════ 【LLM Prompt 开始 (\(PromptBuilder.detectTemplate(from: currentModelFilename)))】 ══════════════════╗\n" + fullPrompt + "\n╚══════════════════ 【LLM Prompt 结束】 ══════════════════╝")
        
        // 4. 执行推理
        await context?.completion_init(text: fullPrompt)
        
        var rawResponse = ""
        while let context = context, await !context.is_done {
            let nextToken = await context.completion_loop()
            rawResponse += nextToken
            
            // 过滤控制符和 think 块（直接删除，不替换标签，避免污染历史）
            let filteredText = rawResponse
                .replacingOccurrences(of: "<\\|.*?\\|>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "<start_of_turn>|<end_of_turn>|<\\|start_header_id\\|>|<\\|end_header_id\\|>|<\\|eot_id\\|>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "<think>[\\s\\S]*?</think>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "<think>[\\s\\S]*", with: "", options: .regularExpression) // think未闭合时也清除
                .replacingOccurrences(of: "\\[EVENT:.*?\\]", with: "", options: .regularExpression)
                .replacingOccurrences(of: "(?i)(?:user|assistant|system|model)[:\\n]?", with: "", options: .regularExpression)
            
            messages[msgIndex].content = filteredText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 将延时从 5ms 调到 20ms (20_000_000 纳秒)，防止震动马达和 UI 线程被过度阻塞，达到丝滑的打字机震动效果
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        
        // ===== 日志：打印原始响应 =====
        print("\n╔══════════════════ 【LLM 原始响应】 ══════════════════╗\n" + rawResponse + "\n╚══════════════════ 【LLM 响应结束】 ══════════════════╝")
        
        // 5. 解析并执行事件
        parseAndExecuteEvents(rawResponse, player: player)
        
        messages[msgIndex].isGenerating = false
        isGenerating = false
        saveHistory()
    }
    
    private func parseAndExecuteEvents(_ response: String, player: PlayerProfile) {
        var hasTriggeredEvent = false
        
        let pattern = "\\[EVENT:(.*?):(.*?)\\]"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsRange = NSRange(response.startIndex..<response.endIndex, in: response)
            let matches = regex.matches(in: response, range: nsRange)
            
            for match in matches {
                if let typeRange = Range(match.range(at: 1), in: response),
                   let valueRange = Range(match.range(at: 2), in: response) {
                    let type = String(response[typeRange])
                    let valueStr = String(response[valueRange])
                    
                    if type == "ADD_CULTIVATION", let value = Int64(valueStr) {
                        player.cultivationBase += value
                        messages.append(ChatMessage(role: .system, content: "【机缘】老爷爷随手一指，修为增加 \(value) 点！"))
                        hasTriggeredEvent = true
                    }
                }
            }
        }
        
        if hasTriggeredEvent {
            try? player.managedObjectContext?.save()
            saveHistory()
        }
    }
    
    func claimReward(for messageId: UUID, player: PlayerProfile) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            guard !messages[index].hasClaimedReward else { return }
            messages[index].hasClaimedReward = true
            
            let randomValue = Int64.random(in: 10...100)
            player.cultivationBase += randomValue
            try? player.managedObjectContext?.save()
            
            // 发送系统回执
            messages.append(ChatMessage(role: .system, content: "【机缘开启】你打开了墨老随手抛下的盲盒，获得 \(randomValue) 点修为！"))
            saveHistory()
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
        
        // 只有重新开始下载时才清空 resumeData
        resumeData = nil
        startDownload(with: url)
    }
    
    func resumeDownload() {
        guard let resumeData = resumeData else { return }
        isDownloading = true
        statusMessage = "正在接续阵纹..."
        downloadStartTime = Date()
        
        let session = URLSession(configuration: .default, delegate: DownloadDelegate(progressHandler: { [weak self] progress, downloaded, total in
            self?.updateDownloadProgress(progress: progress, downloaded: downloaded, total: total)
        }, completionHandler: { [weak self] localURL, error in
            self?.handleDownloadCompletion(localURL: localURL, error: error, originalURL: nil)
        }), delegateQueue: nil)
        
        let task = session.downloadTask(withResumeData: resumeData)
        self.currentDownloadTask = task
        task.resume()
    }
    
    private func startDownload(with url: URL) {
        isDownloading = true
        downloadProgress = 0.0
        downloadedBytes = 0
        totalBytes = 0
        estimatedTimeRemaining = ""
        statusMessage = "正在接引戒灵下界..."
        downloadStartTime = Date()
        
        let session = URLSession(configuration: .default, delegate: DownloadDelegate(progressHandler: { [weak self] progress, downloaded, total in
            self?.updateDownloadProgress(progress: progress, downloaded: downloaded, total: total)
        }, completionHandler: { [weak self] localURL, error in
            self?.handleDownloadCompletion(localURL: localURL, error: error, originalURL: url)
        }), delegateQueue: nil)
        
        let task = session.downloadTask(with: url)
        self.currentDownloadTask = task
        task.resume()
    }
    
    private func updateDownloadProgress(progress: Double, downloaded: Int64, total: Int64) {
        DispatchQueue.main.async {
            self.downloadProgress = progress
            self.downloadedBytes = downloaded
            self.totalBytes = total
            
            if let startTime = self.downloadStartTime {
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed > 1.0 && downloaded > 0 { // 避免除以0，且至少等1秒才算
                    let bytesPerSecond = Double(downloaded) / elapsed
                    let remainingBytes = Double(total - downloaded)
                    let remainingSeconds = remainingBytes / bytesPerSecond
                    
                    if remainingSeconds.isFinite && remainingSeconds > 0 {
                        let formatter = DateComponentsFormatter()
                        formatter.allowedUnits = [.hour, .minute, .second]
                        formatter.unitsStyle = .abbreviated
                        self.estimatedTimeRemaining = "预计剩余: " + (formatter.string(from: remainingSeconds) ?? "--")
                    }
                }
            }
        }
    }
        self.currentDownloadTask = task
        task.resume()
    }
    
    private func handleDownloadCompletion(localURL: URL?, error: Error?, originalURL: URL?) {
        DispatchQueue.main.async {
            if let error = error as NSError? {
                if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    self.resumeData = resumeData
                    self.statusMessage = "接引已中断 (可恢复)"
                } else {
                    self.statusMessage = "接引失败: \(error.localizedDescription)"
                }
                print("下载错误:", error)
                return
            }
            
            guard let localURL = localURL else {
                self.statusMessage = "接引失败: 数据残缺"
                return
            }
            
            // 尝试通过 URLResponse 获取建议文件名，或者使用 originalURL
            let filename = self.currentDownloadTask?.response?.suggestedFilename ?? originalURL?.lastPathComponent ?? "model.gguf"
            self.resumeData = nil
            self.saveDownloadedModel(from: localURL, filename: filename)
        }
    }
    
    func pauseDownload() {
        currentDownloadTask?.cancel(byProducingResumeData: { [weak self] data in
            DispatchQueue.main.async {
                self?.resumeData = data
                self?.isDownloading = false
                self?.statusMessage = "接引已暂停"
            }
        })
    }
    
    func cancelDownload() {
        currentDownloadTask?.cancel()
        currentDownloadTask = nil
        isDownloading = false
        downloadProgress = 0.0
        resumeData = nil
        statusMessage = "接引已取消"
    }
    
    private func saveDownloadedModel(from tempURL: URL, filename: String) {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelsDirectory = documentDirectory.appendingPathComponent("Models")
        
        do {
            if !fileManager.fileExists(atPath: modelsDirectory.path) {
                try fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            let destinationURL = modelsDirectory.appendingPathComponent(filename)
            // 覆盖同名文件
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            
            fetchLocalModels()
            statusMessage = "法器重铸成功，正在唤醒..."
            Task {
                await self.loadModel(filename: filename)
            }
        } catch {
            statusMessage = "保存法器失败"
            print("文件移动错误:", error)
        }
    }
}

// 辅助代理类，用于处理下载进度
class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    var progressHandler: (Double, Int64, Int64) -> Void
    var completionHandler: (URL?, Error?) -> Void
    
    init(progressHandler: @escaping (Double, Int64, Int64) -> Void, completionHandler: @escaping (URL?, Error?) -> Void) {
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        progressHandler(progress, totalBytesWritten, totalBytesExpectedToWrite)
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

// MARK: - 动态提示词模版
struct PromptBuilder {
    enum ModelTemplate {
        case chatML     // Qwen, Yi, DeepSeek
        case gemma      // Gemma 2/4
        case llama3     // Llama 3
    }
    
    static func detectTemplate(from filename: String) -> ModelTemplate {
        let name = filename.lowercased()
        if name.contains("gemma") { return .gemma }
        if name.contains("llama-3") || name.contains("llama3") { return .llama3 }
        return .chatML // 默认兼容度最好的 ChatML
    }
    
    static func build(systemPrompt: String, history: [ChatMessage], modelFilename: String) -> String {
        let template = detectTemplate(from: modelFilename)
        var fullPrompt = ""
        
        switch template {
        case .chatML:
            fullPrompt += "<|im_start|>system\n\(systemPrompt)<|im_end|>\n"
            for msg in history {
                let role = msg.role == .user ? "user" : "assistant"
                fullPrompt += "<|im_start|>\(role)\n\(msg.content)<|im_end|>\n"
            }
            fullPrompt += "<|im_start|>assistant\n<think>\n\n</think>\n" // 为推理模型加入逃逸符
            
        case .gemma:
            // Gemma 的特殊格式：不建议显式声明 system，通常合并到第一次 user prompt 中
            let systemContext = systemPrompt + "\n\n"
            var isFirstUser = true
            
            for msg in history {
                let role = msg.role == .user ? "user" : "model"
                fullPrompt += "<start_of_turn>\(role)\n"
                if isFirstUser && msg.role == .user {
                    fullPrompt += systemContext
                    isFirstUser = false
                }
                fullPrompt += "\(msg.content)<end_of_turn>\n"
            }
            // 如果历史全是 assistant，补充一下
            if isFirstUser {
                fullPrompt = "<start_of_turn>user\n\(systemContext)<end_of_turn>\n" + fullPrompt
            }
            fullPrompt += "<start_of_turn>model\n"
            
        case .llama3:
            fullPrompt += "<|start_header_id|>system<|end_header_id|>\n\n\(systemPrompt)<|eot_id|>"
            for msg in history {
                let role = msg.role == .user ? "user" : "assistant"
                fullPrompt += "<|start_header_id|>\(role)<|end_header_id|>\n\n\(msg.content)<|eot_id|>"
            }
            fullPrompt += "<|start_header_id|>assistant<|end_header_id|>\n\n"
        }
        
        return fullPrompt
    }
}
#endif
