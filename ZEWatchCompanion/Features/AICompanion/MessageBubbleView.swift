import SwiftUI
import UIKit

public struct MessageBubble: View {
    let message: ChatMessage
    @ObservedObject var llm: LLMManager
    @ObservedObject var player: PlayerProfile
    
    // 用于呼吸灯动画
    @State private var isBreathing = false
    
    init(message: ChatMessage, llm: LLMManager, player: PlayerProfile) {
        self.message = message
        self.llm = llm
        self.player = player
    }
    
    public var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            
            if message.role == .system {
                Text(message.content)
                    .font(.system(.caption, design: .serif))
                    .textSelection(.enabled)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.cultivAccent.opacity(0.1)))
                    .foregroundColor(.cultivAccent)
                    .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                    if message.content.contains("【天降机缘】") {
                        let cleanText = message.content.replacingOccurrences(of: "【天降机缘】", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            if !cleanText.isEmpty {
                                Text(cleanText)
                                    .font(.system(.body, design: .serif))
                                    .textSelection(.enabled)
                            }
                            
                            if !message.hasClaimedReward && !message.isGenerating {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    llm.claimReward(for: message.id, player: player)
                                }) {
                                    HStack {
                                        Image(systemName: "gift.fill")
                                        Text("开启机缘盲盒")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .cornerRadius(8)
                                    .shadow(color: .orange.opacity(0.5), radius: 5, x: 0, y: 2)
                                }
                                .accessibilityLabel("开启机缘盲盒")
                                .accessibilityHint("点击开启机缘，获取随机修为奖励")
                            } else if message.hasClaimedReward {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("机缘已收纳")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            BubbleShape(role: message.role)
                                .fill(message.role == .user ? Color.cultivAccent.opacity(0.2) : Color.white.opacity(0.08))
                        )
                        .foregroundColor(.white)
                    } else {
                        if !message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(message.content)
                                .font(.system(.body, design: .serif))
                                .textSelection(.enabled)
                                .padding(12)
                                .background(
                                    BubbleShape(role: message.role)
                                        .fill(message.role == .user ? Color.cultivAccent.opacity(0.2) : Color.white.opacity(0.08))
                                )
                                .foregroundColor(.white)
                        }
                    }
                    
                    if message.isGenerating {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.cultivAccent)
                                .scaleEffect(isBreathing ? 1.2 : 0.8)
                                .opacity(isBreathing ? 1.0 : 0.4)
                            Text("推演天机中...")
                                .font(.caption)
                                .foregroundColor(.cultivAccent.opacity(0.8))
                        }
                        .padding(.top, 4)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                isBreathing = true
                            }
                        }
                    }
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.role == .user ? .trailing : .leading)
            }
            
            if message.role == .assistant { Spacer() }
        }
    }
}

public struct BubbleShape: Shape {
    let role: MessageRole
    
    public init(role: MessageRole) {
        self.role = role
    }
    
    public func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: role == .user ? [.topLeft, .bottomLeft, .bottomRight] : [.topRight, .bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: 14, height: 14)
        )
        return Path(path.cgPath)
    }
}
