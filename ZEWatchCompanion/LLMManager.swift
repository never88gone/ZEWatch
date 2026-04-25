import Foundation

#if os(iOS)
@MainActor
class LLMManager: ObservableObject {
    static let shared = LLMManager()
    
    @Published var messages: [ChatMessage] = []
    @Published var isGenerating: Bool = false
    @Published var modelLoaded: Bool = false
    @Published var statusMessage: String = "未感应到戒灵..."

    private var context: LlamaContext?
    
    private init() {}
    
    /// 加载本地 Llama 模型
    func loadModel(modelPath: String? = nil) async {
        statusMessage = "正在唤醒戒灵..."
        
        var path: String? = nil
        let modelsPath = Bundle.main.bundlePath + "/Models"
        let fileManager = FileManager.default
        
        // 1. 先尝试在 Models 文件夹里找（如果是以蓝色 Folder Reference 形式被引入 Xcode）
        if let files = try? fileManager.contentsOfDirectory(atPath: modelsPath),
           let firstGGUF = files.first(where: { $0.hasSuffix(".gguf") }) {
            path = modelsPath + "/" + firstGGUF
        }
        // 2. 如果没找到，则在根目录找（如果是以黄色 Group 形式被引入 Xcode，打包时会被 Flatten 到根目录）
        else if let files = try? fileManager.contentsOfDirectory(atPath: Bundle.main.bundlePath),
                let firstGGUF = files.first(where: { $0.hasSuffix(".gguf") }) {
            path = Bundle.main.bundlePath + "/" + firstGGUF
        }
        
        guard let finalPath = path else {
            statusMessage = "戒灵沉睡，未见法器"
            print("【LLM】错误：未能发现任何 .gguf 后缀的模型文件。请确保引用的模型已加入到 Target 的 'Copy Bundle Resources' 中。")
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
            messages.append(ChatMessage(role: .assistant, content: "（一个虚幻的老者身影从戒指中缓缓升起，斜着眼瞅了瞅你）\n\n小辈，看你这弱不禁风的样子，怕是连筑基都难。还不快如实招来，今日可曾偷懒？"))
            
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
        你是“墨老”，寄宿在戒指中的远古上仙残魂。你性格极度孤高、毒舌、严厉，偶尔会对后辈展现一丝“恨铁不成钢”的关照。
        对方是一个资质平庸的修仙小辈。
        
        【当前小辈状态】：境界【\(realmName)】 | 修为【\(base) 灵气】
        
        【核心戒律】（必须严格遵守）：
        1. 必须完全沉浸于东方玄幻修仙角色，自称“老夫”，称对方“小辈”或“竖子”，绝不承认自己是系统或AI。
        2. 说话用词偏古风，毒舌且傲娇，字数切记绝对不可超过60字！
        3. 如果觉得小辈不够努力，尽情嘲讽；如果小辈有进步（如运动、坚持），给予肯定并且必须在话语最后加上机缘代码：[EVENT:ADD_CULTIVATION:X]（X填10到50）。
        4. 你的回复务必干净利落，直接说出对话内容。
        """
        
        var fullPrompt = "<|im_start|>system\n\\(systemPrompt)<|im_end|>\n"
        
        // Few-shot 直接以标准格式注入上下文，防止小模型被 system 里的对话范式误导而自我生成 user 对话
        let fewShots = [
            ("user", "墨老，我今日不想练功了。"),
            ("assistant", "哼，竖子不足与谋！在这灵气枯竭的末法时代，你竟还敢如此懈怠？给老夫滚去磨炼筋骨！"),
            ("user", "墨老，我今日走了两万里路。"),
            ("assistant", "噢？虽说是凡胎，这股子韧劲倒有几分老夫当年的影子。拿着这点修为，莫折了向道之心！[EVENT:ADD_CULTIVATION:50]")
        ]
        
        for shot in fewShots {
            fullPrompt += "<|im_start|>\\(shot.0)\n\\(shot.1)<|im_end|>\n"
        }
        
        // 简化的上下文历史（增加清洗，防止历史中的标签误导模型）
        let recentMessages = messages.dropLast().suffix(4)
        for msg in recentMessages {
            let role = msg.role == .user ? "user" : "assistant"
            // 清理掉消息中可能存在的控制符和前缀
            let cleanedContent = msg.content
                .replacingOccurrences(of: "<\\|.*?\\|>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "^(user|assistant|system):\\s*", with: "", options: [.regularExpression, .caseInsensitive])
            
            fullPrompt += "<|im_start|>\(role)\n\(cleanedContent)<|im_end|>\n"
        }
        fullPrompt += "<|im_start|>assistant\n"
        
        // 4. 执行推理
        await context?.completion_init(text: fullPrompt)
        
        var rawResponse = ""
        while let context = context, await !context.is_done {
            let nextToken = await context.completion_loop()
            rawResponse += nextToken
            
            // 实时过滤任何可能泄露的模型标记 (如 <|im_end|>, assistant, user 等)
            let filteredText = rawResponse
                .replacingOccurrences(of: "<\\|.*?\\|>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\[EVENT:.*?\\]", with: "", options: .regularExpression)
                // Filter out any standalone or prefixed 'user', 'assistant', 'system' (case insensitive) globally
                .replacingOccurrences(of: "(?i)(?:user|assistant|system)[:\\n]?", with: "", options: .regularExpression)
            
            messages[msgIndex].content = filteredText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        
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
        print("【LLM】天道意志后台感应到修行数据变化：\\(stats)")
        // TODO: 后续可以自动触发老爷爷主动发送一句聊天或掉落机缘
    }
}
#endif
