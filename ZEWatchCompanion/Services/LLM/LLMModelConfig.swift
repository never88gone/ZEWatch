import Foundation

#if os(iOS)
public enum ModelDownloadSource: String, CaseIterable, Identifiable {
    case modelscope = "modelscope"
    case hfMirror = "hfMirror"
    case huggingface = "huggingface"
    
    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .modelscope: return "🚀 阿里魔搭 (国内极速 · 推荐)"
        case .hfMirror: return "⚡ HF-Mirror (国内备用镜像)"
        case .huggingface: return "🌐 HuggingFace (全球官方直连)"
        }
    }
    
    public var shortName: String {
        switch self {
        case .modelscope: return "魔搭极速源"
        case .hfMirror: return "HF镜像源"
        case .huggingface: return "HF官方源"
        }
    }
}

public struct LLMModelOption: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let tag: String
    public let description: String
    public let modelscopeUrl: String
    public let mirrorUrl: String
    public let huggingfaceUrl: String
    public let filename: String
    public let sizeDesc: String
    public let isRecommended: Bool
    
    public var url: String { modelscopeUrl }
    
    public func url(for source: ModelDownloadSource) -> String {
        switch source {
        case .modelscope: return modelscopeUrl
        case .hfMirror: return mirrorUrl
        case .huggingface: return huggingfaceUrl
        }
    }
}

// MARK: - 动态提示词模版
public struct PromptBuilder {
    public enum ModelTemplate {
        case chatML     // Qwen, Yi, DeepSeek
        case gemma      // Gemma 2/4
        case llama3     // Llama 3
    }
    
    public static func detectTemplate(from filename: String) -> ModelTemplate {
        let name = filename.lowercased()
        if name.contains("gemma") { return .gemma }
        if name.contains("llama-3") || name.contains("llama3") { return .llama3 }
        return .chatML
    }
    
    public static func build(systemPrompt: String, history: [ChatMessage], modelFilename: String, fewShots: [(String, String)] = []) -> String {
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
