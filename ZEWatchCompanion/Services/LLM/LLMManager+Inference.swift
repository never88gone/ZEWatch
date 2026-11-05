import Foundation
import UIKit
import CoreData

#if os(iOS)
extension LLMManager {
    /// 发送消息并获取老爷爷的毒舌指点
    func sendUserMessage(_ text: String, stats: [String: Any], player: PlayerProfile) async {
        guard !text.isEmpty, !isGenerating else { return }
        
        // 1. 添加用户消息
        let userMsg = ChatMessage(role: .user, content: text)
        messages.append(userMsg)
        
        // 2. 准备老爷爷的消息占位
        let assistantMsg = ChatMessage(role: .assistant, content: "", isGenerating: true)
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
        // 后续可以自动触发老爷爷主动发送一句聊天或掉落机缘
    }
}
#endif
