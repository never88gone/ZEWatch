import Foundation

public enum MessageRole: String, Codable {
    case user        // 小辈
    case assistant   // 老爷爷
    case system      // 系统提示/机缘
}

public struct ChatMessage: Identifiable, Equatable, Codable {
    public let id: UUID
    public let role: MessageRole
    public var content: String
    public let timestamp: Date
    public var isGenerating: Bool
    public var hasClaimedReward: Bool
    
    public init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date(), isGenerating: Bool = false, hasClaimedReward: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isGenerating = isGenerating
        self.hasClaimedReward = hasClaimedReward
    }
}
