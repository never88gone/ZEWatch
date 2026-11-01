import Foundation
import UIKit

#if os(iOS)
enum ModelDownloadSource: String, CaseIterable, Identifiable {
    case modelscope = "modelscope"
    case hfMirror = "hfMirror"
    case huggingface = "huggingface"
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .modelscope: return "🚀 阿里魔搭 (国内极速 · 推荐)"
        case .hfMirror: return "⚡ HF-Mirror (国内备用镜像)"
        case .huggingface: return "🌐 HuggingFace (全球官方直连)"
        }
    }
    
    var shortName: String {
        switch self {
        case .modelscope: return "魔搭极速源"
        case .hfMirror: return "HF镜像源"
        case .huggingface: return "HF官方源"
        }
    }
}

struct LLMModelOption: Identifiable, Equatable {
    let id: String
    let name: String
    let tag: String
    let description: String
    let modelscopeUrl: String
    let mirrorUrl: String
    let huggingfaceUrl: String
    let filename: String
    let sizeDesc: String
    let isRecommended: Bool
    
    /// 默认主 URL（优先使用阿里魔搭国内极速 CDN 直链）
    var url: String { modelscopeUrl }
    
    func url(for source: ModelDownloadSource) -> String {
        switch source {
        case .modelscope: return modelscopeUrl
        case .hfMirror: return mirrorUrl
        case .huggingface: return huggingfaceUrl
        }
    }
}

@MainActor
class LLMManager: ObservableObject {
    static let shared = LLMManager()
    
    /// 默认精选法器（模型），不内置于应用安装包中，由用户按需挑选下载
    static let recommendedModels: [LLMModelOption] = [
        LLMModelOption(
            id: "qwen2.5-0.5b",
            name: "Qwen2.5 0.5B Instruct",
            tag: "⚡ 极速轻量 · 首选推荐",
            description: "千问2.5代极速版，内存占用极低（<600MB），不发热不掉帧，老旧机型亦能流畅秒回。",
            modelscopeUrl: "https://modelscope.cn/api/v1/models/qwen/Qwen2.5-0.5B-Instruct-GGUF/repo?Revision=master&FilePath=qwen2.5-0.5b-instruct-q4_k_m.gguf",
            mirrorUrl: "https://hf-mirror.com/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
            huggingfaceUrl: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
            filename: "qwen2.5-0.5b-instruct-q4_k_m.gguf",
            sizeDesc: "约 390 MB",
            isRecommended: true
        ),
        LLMModelOption(
            id: "qwen2.5-1.5b",
            name: "Qwen2.5 1.5B Instruct",
            tag: "🔥 综合最佳 · 中文主力",
            description: "千问2.5代小钢炮，古风语感出众，对答毒舌精辟，逻辑与文采兼备，推荐主流 iPhone 用户选择。",
            modelscopeUrl: "https://modelscope.cn/api/v1/models/qwen/Qwen2.5-1.5B-Instruct-GGUF/repo?Revision=master&FilePath=qwen2.5-1.5b-instruct-q4_k_m.gguf",
            mirrorUrl: "https://hf-mirror.com/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
            huggingfaceUrl: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
            filename: "qwen2.5-1.5b-instruct-q4_k_m.gguf",
            sizeDesc: "约 1.1 GB",
            isRecommended: true
        ),
        LLMModelOption(
            id: "qwen2.5-coder-1.5b",
            name: "Qwen2.5-Coder 1.5B",
            tag: "🧠 严谨逻辑 · 适合格物",
            description: "千问代码与推演强化版1.5B，逻辑缜密、条理分明，适合偏好推演格物致知的仙友。",
            modelscopeUrl: "https://modelscope.cn/api/v1/models/qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/repo?Revision=master&FilePath=qwen2.5-coder-1.5b-instruct-q4_k_m.gguf",
            mirrorUrl: "https://hf-mirror.com/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf",
            huggingfaceUrl: "https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf",
            filename: "qwen2.5-coder-1.5b-instruct-q4_k_m.gguf",
            sizeDesc: "约 1.1 GB",
            isRecommended: false
        ),
        LLMModelOption(
            id: "qwen2.5-3b",
            name: "Qwen2.5 3B Instruct",
            tag: "🔮 高配专属 · 深度推演",
            description: "参数翻倍，上仙大能之威严更甚，推理更深邃，推荐 6GB+ 运存机型（如 iPhone 15 Pro / 16 等）。",
            modelscopeUrl: "https://modelscope.cn/api/v1/models/qwen/Qwen2.5-3B-Instruct-GGUF/repo?Revision=master&FilePath=qwen2.5-3b-instruct-q4_k_m.gguf",
            mirrorUrl: "https://hf-mirror.com/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf",
            huggingfaceUrl: "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf",
            filename: "qwen2.5-3b-instruct-q4_k_m.gguf",
            sizeDesc: "约 2.0 GB",
            isRecommended: false
        )
    ]
    
    @Published var messages: [ChatMessage] = []
    @Published var isGenerating: Bool = false
    @Published var modelLoaded: Bool = false
    @Published var isLoadingModel: Bool = false
    @Published var loadErrorText: String? = nil
    @Published var statusMessage: String = "未感应到戒灵..."
    
    @Published var localModels: [String] = []
    @Published var currentModelFilename: String = ""
    
    // 下载相关状态
    @Published var isDownloading: Bool = false
    @Published var downloadingModelTitle: String = ""
    @Published var downloadProgress: Double = 0.0
    @Published var downloadedBytes: Int64 = 0
    @Published var totalBytes: Int64 = 0
    @Published var downloadSpeedDesc: String = ""
    @Published var hasResumeData: Bool = false
    @Published var estimatedTimeRemaining: String = ""
    @Published var downloadErrorText: String? = nil
    
    private var pendingTargetFilename: String?
    private var downloadStartTime: Date?
    private var lastLoggedPercent: Int = -1
    
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
            let data = try Data(contentsOf: historyFileURL)
            let decoded = try JSONDecoder().decode([ChatMessage].self, from: data)
            // 过滤历史中所有内容为空的破损残差消息
            var validMessages = decoded.filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            // 若历史出现异常堆积或污染，仅保留最近2条
            if validMessages.count > 4 {
                validMessages = Array(validMessages.suffix(2))
            }
            self.messages = validMessages
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
    @discardableResult
    func fetchLocalModels() -> [String] {
        let fileManager = FileManager.default
        let modelsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Models").path
        
        if fileManager.fileExists(atPath: modelsPath),
           let files = try? fileManager.contentsOfDirectory(atPath: modelsPath) {
            let ggufFiles = files.filter { $0.hasSuffix(".gguf") }.sorted()
            self.localModels = ggufFiles
            if ggufFiles.isEmpty {
                self.modelLoaded = false
                self.isLoadingModel = false
                self.currentModelFilename = ""
                self.statusMessage = "戒灵沉睡，未感应到法器。请挑选并接引法器下界。"
            }
            return ggufFiles
        } else {
            self.localModels = []
            self.modelLoaded = false
            self.isLoadingModel = false
            self.currentModelFilename = ""
            self.statusMessage = "戒灵沉睡，未感应到法器。请挑选并接引法器下界。"
            return []
        }
    }
    
    /// 格式化字节大小
    func formatBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 MB" }
        let mb = Double(bytes) / (1024 * 1024)
        if mb >= 1024 {
            let gb = mb / 1024
            return String(format: "%.2f GB", gb)
        }
        return String(format: "%.1f MB", mb)
    }
    
    /// 获取指定沙盒模型的实际字节大小
    func getModelFileSize(filename: String) -> Int64 {
        let fileManager = FileManager.default
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Models").appendingPathComponent(filename).path
        if let attrs = try? fileManager.attributesOfItem(atPath: path),
           let size = attrs[.size] as? Int64 {
            return size
        }
        return 0
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
            let importedFilename = url.lastPathComponent
            UserDefaults.standard.set(importedFilename, forKey: "selectedModelName")
            Task {
                await self.loadModel(filename: importedFilename)
            }
        } catch {
            print("模型导入失败: \(error)")
        }
    }
    
    /// 卸载当前模型并清理内存
    func unloadModel() {
        self.context = nil
        self.modelLoaded = false
        self.isLoadingModel = false
        self.loadErrorText = nil
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
            if currentModelFilename == filename {
                unloadModel()
                if let nextModel = localModels.first(where: { $0 != filename }) {
                    Task {
                        await loadModel(filename: nextModel)
                    }
                }
            }
        } catch {
            print("删除模型失败: \(error)")
        }
    }
    
    /// 加载本地 Llama 模型
    func loadModel(filename: String? = nil) async {
        let available = fetchLocalModels()
        
        var target: String? = filename
        if target == nil {
            target = UserDefaults.standard.string(forKey: "selectedModelName")
        }
        if target == nil || !available.contains(target!) {
            target = available.first
        }
        
        guard let finalTarget = target, !finalTarget.isEmpty else {
            self.statusMessage = "戒灵沉睡，未感应到法器。请挑选并接引法器下界。"
            self.modelLoaded = false
            self.isLoadingModel = false
            self.currentModelFilename = ""
            return
        }
        
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let finalPath = documentDirectory.appendingPathComponent("Models").appendingPathComponent(finalTarget).path
        
        guard fileManager.fileExists(atPath: finalPath) else {
            self.statusMessage = "法器不存在，请挑选并接引法器下界。"
            self.modelLoaded = false
            self.isLoadingModel = false
            self.currentModelFilename = ""
            return
        }
        
        let fileSize = getModelFileSize(filename: finalTarget)
        print("【LLM】准备载入法器: \(finalTarget), 字节大小: \(fileSize) (\(formatBytes(fileSize)))")
        
        // 校验文件完整性：任何有效的量化 GGUF 模型至少应大于 50MB（0.5B 为 ~390MB）
        if fileSize < 50 * 1024 * 1024 {
            self.isLoadingModel = false
            self.modelLoaded = false
            let err = "法器残破不全（仅 \(formatBytes(fileSize))，可能接引中断），请清除后重新接引。"
            self.loadErrorText = err
            self.statusMessage = "唤醒失败：法器残损"
            print("【LLM】\(err)")
            return
        }
        
        self.isLoadingModel = true
        self.loadErrorText = nil
        self.statusMessage = "正在唤醒戒灵..."
        
        do {
            // 通过 Task.detached 将底层耗时的 C 库初始化操作移至后台线程，防止阻塞主线程导致启动过慢
            let newContext = try await Task.detached(priority: .userInitiated) {
                return try await LlamaContext.create_context(path: finalPath)
            }.value
            
            self.context = newContext
            self.currentModelFilename = finalTarget
            UserDefaults.standard.set(finalTarget, forKey: "selectedModelName")
            self.modelLoaded = true
            self.isLoadingModel = false
            self.loadErrorText = nil
            self.statusMessage = "咳咳... 谁在那吵老夫睡觉？"
            print("【LLM】戒灵唤醒成功！当前法器: \(finalTarget)")
            
            // 初始消息
            if messages.isEmpty {
                messages.append(ChatMessage(role: .assistant, content: "小辈，今日为何无精打采？若再不磨炼筋骨，老夫这戒指可容不下你了。"))
                saveHistory()
            }
            
        } catch {
            self.isLoadingModel = false
            self.modelLoaded = false
            self.loadErrorText = "唤醒失败：\(error.localizedDescription)"
            self.statusMessage = "唤醒失败：神魂受损"
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
        
        // 历史消息从第一条有效对话开始取，截取过去规范轮次
        let pastMessages = Array(messages.dropLast(2)) // 排除刚刚追加的 userMsg 和 assistant 占位
        let firstUserIdx = pastMessages.firstIndex(where: { $0.role == .user }) ?? pastMessages.startIndex
        let validPast = Array(pastMessages[firstUserIdx...])
            .filter { $0.role != .system && !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .suffix(2) // 保留最近至多 1 轮历史，保证极速响应且防发散
            
        // 清理消息内容里的控制符，防止污染模型，并确保历史严格交替
        var cleanedHistory: [ChatMessage] = []
        for msg in validPast {
            let cleanedContent = msg.content
                .replacingOccurrences(of: "<\\|.*?\\|>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "^(user|assistant|system):\\s*", with: "", options: [.regularExpression, .caseInsensitive])
                .replacingOccurrences(of: "<think>[\\s\\S]*?</think>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "<思维>[\\s\\S]*?</思维>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanedContent.isEmpty {
                // 若连续两个同角色，移除前一个以维持严格对话交替
                if let last = cleanedHistory.last, last.role == msg.role {
                    cleanedHistory.removeLast()
                }
                cleanedHistory.append(ChatMessage(role: msg.role, content: cleanedContent))
            }
        }
        
        // 保证历史记录以 assistant 结尾（以便紧接着衔接当前新用户的提问）
        if let last = cleanedHistory.last, last.role == .user {
            cleanedHistory.removeLast()
        }
        
        // 最后加入当前的用户消息
        cleanedHistory.append(userMsg)
        
        fullPrompt = PromptBuilder.build(
            systemPrompt: systemPrompt,
            history: cleanedHistory,
            modelFilename: currentModelFilename,
            fewShots: fewShots
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
            
            let curContent = filteredText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !curContent.isEmpty {
                messages[msgIndex].content = curContent
            }
            
            // 将延时从 5ms 调到 20ms (20_000_000 纳秒)，防止震动马达和 UI 线程被过度阻塞，达到丝滑的打字机震动效果
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        
        // 兜底保障：若模型生成因网络或早停完全为空，给出仙家威严台词
        let finalTrimmed = messages[msgIndex].content.trimmingCharacters(in: .whitespacesAndNewlines)
        if finalTrimmed.isEmpty {
            messages[msgIndex].content = "墨老双目微阖，拂了拂衣袖：“小辈，天地灵气变化万千，休得在此嬉皮笑脸，速去吐纳炼体！”"
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
    
    /// 下载推荐的大模型（默认优先使用阿里魔搭国内极速直连源）
    func downloadModel(_ model: LLMModelOption, source: ModelDownloadSource = .modelscope) {
        let urlString = model.url(for: source)
        guard let url = URL(string: urlString) else {
            self.downloadErrorText = "无效的下载法阵地址"
            return
        }
        
        self.downloadingModelTitle = model.name
        self.downloadErrorText = nil
        self.pendingTargetFilename = model.filename
        self.resumeData = nil
        startDownload(with: url, expectedFilename: model.filename)
    }
    
    /// 兼容旧方法：根据镜像开关映射对应源
    func downloadModel(_ model: LLMModelOption, useMirror: Bool) {
        let source: ModelDownloadSource = useMirror ? .hfMirror : .modelscope
        downloadModel(model, source: source)
    }
    
    /// 根据自定义 URL 下载模型
    func downloadModel(from urlString: String, filename: String? = nil) {
        guard let url = URL(string: urlString) else {
            self.downloadErrorText = "无效的接引地址"
            return
        }
        
        let resolvedFilename = filename ?? url.lastPathComponent
        self.downloadingModelTitle = resolvedFilename
        self.downloadErrorText = nil
        self.pendingTargetFilename = resolvedFilename
        self.resumeData = nil
        startDownload(with: url, expectedFilename: resolvedFilename)
    }
    
    func resumeDownload() {
        guard let resumeData = resumeData else { return }
        isDownloading = true
        downloadErrorText = nil
        statusMessage = "正在接续阵纹..."
        downloadStartTime = Date()
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 7200
        config.waitsForConnectivity = true
        
        let session = URLSession(configuration: config, delegate: DownloadDelegate(progressHandler: { [weak self] progress, downloaded, total in
            self?.updateDownloadProgress(progress: progress, downloaded: downloaded, total: total)
        }, completionHandler: { [weak self] localURL, error in
            self?.handleDownloadCompletion(localURL: localURL, error: error, originalURL: nil)
        }), delegateQueue: nil)
        
        let task = session.downloadTask(withResumeData: resumeData)
        self.currentDownloadTask = task
        task.resume()
    }
    
    private func startDownload(with url: URL, expectedFilename: String? = nil) {
        isDownloading = true
        downloadProgress = 0.0
        downloadedBytes = 0
        totalBytes = 0
        downloadSpeedDesc = ""
        estimatedTimeRemaining = ""
        downloadErrorText = nil
        statusMessage = "正在接引戒灵法器下界..."
        downloadStartTime = Date()
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 7200
        config.waitsForConnectivity = true
        
        let session = URLSession(configuration: config, delegate: DownloadDelegate(progressHandler: { [weak self] progress, downloaded, total in
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
                if elapsed > 0.5 && downloaded > 0 {
                    let bytesPerSecond = Double(downloaded) / elapsed
                    let mbps = bytesPerSecond / (1024 * 1024)
                    self.downloadSpeedDesc = String(format: "%.1f MB/s", mbps)
                    
                    let remainingBytes = Double(max(0, total - downloaded))
                    let remainingSeconds = remainingBytes / bytesPerSecond
                    
                    if remainingSeconds.isFinite && remainingSeconds > 0 {
                        let formatter = DateComponentsFormatter()
                        formatter.allowedUnits = [.hour, .minute, .second]
                        formatter.unitsStyle = .abbreviated
                        self.estimatedTimeRemaining = "预计剩余 " + (formatter.string(from: remainingSeconds) ?? "--")
                    }
                    
                    let curPercent = Int(progress * 100)
                    if curPercent % 10 == 0 && curPercent != self.lastLoggedPercent {
                        self.lastLoggedPercent = curPercent
                        print("【真机接引中】\(curPercent)% (\(self.formatBytes(downloaded)) / \(self.formatBytes(total))) | 速度: \(self.downloadSpeedDesc) | \(self.estimatedTimeRemaining)")
                    }
                }
            }
        }
    }
    
    private func handleDownloadCompletion(localURL: URL?, error: Error?, originalURL: URL?) {
        DispatchQueue.main.async {
            if let error = error as NSError? {
                if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    self.resumeData = resumeData
                    self.statusMessage = "接引已中断 (可恢复)"
                } else {
                    self.downloadErrorText = error.localizedDescription
                    self.statusMessage = "接引失败: \(error.localizedDescription)"
                }
                self.isDownloading = false
                print("下载错误:", error)
                return
            }
            
            guard let localURL = localURL else {
                self.downloadErrorText = "数据残缺，未能成功获取法器"
                self.statusMessage = "接引失败: 数据残缺"
                self.isDownloading = false
                return
            }
            
            // 优先使用预设的文件名，其次使用 URL 建议文件名
            var filename = self.pendingTargetFilename
            if filename == nil || filename!.isEmpty {
                filename = self.currentDownloadTask?.response?.suggestedFilename ?? originalURL?.lastPathComponent ?? "model.gguf"
            }
            if !filename!.hasSuffix(".gguf") {
                filename! += ".gguf"
            }
            
            self.resumeData = nil
            self.saveDownloadedModel(from: localURL, filename: filename!)
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
        downloadedBytes = 0
        totalBytes = 0
        downloadSpeedDesc = ""
        downloadingModelTitle = ""
        resumeData = nil
        downloadErrorText = nil
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
            
            self.isDownloading = false
            self.downloadingModelTitle = ""
            self.downloadSpeedDesc = ""
            self.estimatedTimeRemaining = ""
            self.downloadErrorText = nil
            self.statusMessage = "法器接引成功，戒灵已唤醒！"
            
            fetchLocalModels()
            UserDefaults.standard.set(filename, forKey: "selectedModelName")
            
            Task {
                await self.loadModel(filename: filename)
            }
        } catch {
            self.isDownloading = false
            self.downloadErrorText = "保存法器失败: \(error.localizedDescription)"
            self.statusMessage = "保存法器失败"
            print("文件移动错误:", error)
            try? fileManager.removeItem(at: tempURL)
        }
    }
}

// 辅助代理类，用于处理下载进度与安全转存
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
        // 1. 严格检查 HTTP 状态码
        if let httpResponse = downloadTask.response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let error = NSError(
                domain: "LLMDownloadError",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "下载服务器响应异常 (HTTP \(httpResponse.statusCode))，建议在设置中切换下载线路重试。"]
            )
            completionHandler(nil, error)
            return
        }
        
        // 2. ⚠️ 解决系统时序销毁临时文件 Bug：必须在代理方法返回前同步复制/移动到安全临时目录
        let fileManager = FileManager.default
        let safeTempDir = fileManager.temporaryDirectory.appendingPathComponent("ModelDownloads", isDirectory: true)
        let safeTempURL = safeTempDir.appendingPathComponent("dl_\(UUID().uuidString).gguf")
        
        do {
            if !fileManager.fileExists(atPath: safeTempDir.path) {
                try fileManager.createDirectory(at: safeTempDir, withIntermediateDirectories: true)
            }
            if fileManager.fileExists(atPath: safeTempURL.path) {
                try fileManager.removeItem(at: safeTempURL)
            }
            try fileManager.moveItem(at: location, to: safeTempURL)
            completionHandler(safeTempURL, nil)
        } catch {
            print("【LLM】移动临时下载文件失败: \(error)")
            completionHandler(nil, error)
        }
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
    
    static func build(systemPrompt: String, history: [ChatMessage], modelFilename: String, fewShots: [(String, String)] = []) -> String {
        let template = detectTemplate(from: modelFilename)
        var fullPrompt = ""
        
        switch template {
        case .chatML:
            fullPrompt += "<|im_start|>system\n\(systemPrompt)<|im_end|>\n"
            for shot in fewShots {
                fullPrompt += "<|im_start|>\(shot.0)\n\(shot.1)<|im_end|>\n"
            }
            for msg in history {
                let role = msg.role == .user ? "user" : "assistant"
                fullPrompt += "<|im_start|>\(role)\n\(msg.content)<|im_end|>\n"
            }
            if modelFilename.lowercased().contains("r1") {
                fullPrompt += "<|im_start|>assistant\n<think>\n\n</think>\n"
            } else {
                fullPrompt += "<|im_start|>assistant\n"
            }
            
        case .gemma:
            // Gemma 的特殊格式：不建议显式声明 system，通常合并到第一次 user prompt 中
            let systemContext = systemPrompt + "\n\n"
            var isFirstUser = true
            
            for shot in fewShots {
                fullPrompt += "<start_of_turn>\(shot.0)\n\(shot.1)<end_of_turn>\n"
            }
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
            for shot in fewShots {
                fullPrompt += "<|start_header_id|>\(shot.0)<|end_header_id|>\n\n\(shot.1)<|eot_id|>"
            }
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
