import SwiftUI
import UIKit

#if os(iOS)
struct AICompanionView: View {
    @ObservedObject var player: PlayerProfile
    @State private var chatText: String = ""
    @ObservedObject var llm = LLMManager.shared
    @Namespace private var bottomID
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部：墨老魂影与境界
                elderHeader
                
                // 识海对话区
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            if llm.messages.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(llm.messages) { msg in
                                    MessageBubble(message: msg)
                                }
                            }
                            Color.clear
                                .frame(height: 1)
                                .id(bottomID)
                        }
                        .padding()
                    }
                    .onChange(of: llm.messages.count) { _ in
                        withAnimation { proxy.scrollTo(bottomID) }
                    }
                    .onChange(of: llm.messages.last?.content) { _ in
                        proxy.scrollTo(bottomID)
                    }
                }
                
                // 底部：快捷灵咒与输入
                VStack(spacing: 12) {
                    if llm.modelLoaded {
                        quickActionsBar
                    }
                    
                    inputArea
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
                .background(Color.black.opacity(0.4).blur(radius: 10))
            }
            .background(
                ZStack {
                    Color.cultivBg.ignoresSafeArea()
                    // 背景装饰：幽暗的法阵气息
                    Circle()
                        .fill(Color.cultivAccent.opacity(0.05))
                        .frame(width: 400, height: 400)
                        .blur(radius: 80)
                        .offset(y: -200)
                }
            )
            .navigationTitle("戒指里的老爷爷")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !llm.modelLoaded {
                        Button {
                            Task { await llm.loadModel() }
                        } label: {
                            Label("唤醒戒灵", systemImage: "bolt.ring.closed")
                                .foregroundColor(.cultivAccent)
                        }
                    } else {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green.opacity(0.6))
                    }
                }
            }
        }
    }
    
    private var elderHeader: some View {
        HStack(spacing: 15) {
            // 老爷爷头像（虚幻感）
            ZStack {
                Circle()
                    .stroke(LinearGradient(colors: [.cultivAccent, .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                    .frame(width: 60, height: 60)
                
                if #available(iOS 17.0, *) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 30))
                        .foregroundColor(.cultivAccent)
                        .opacity(0.8)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                } else {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 30))
                        .foregroundColor(.cultivAccent)
                        .opacity(0.8)
                }
            }
            .background(
                Circle()
                    .fill(Color.cultivAccent.opacity(0.1))
                    .blur(radius: 5)
            )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("墨老")
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(.cultivAccent)
                    Text("（残魂状态）")
                        .font(.caption2)
                        .foregroundColor(.cultivMuted)
                }
                
                Text(CultivationEngine.shared.realmName(for: player.realm))
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.cultivPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.cultivPrimary.opacity(0.15)))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("修为: \(player.cultivationBase)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.cultivText)
                
                ProgressView(value: Double(player.cultivationBase % 1000), total: 1000)
                    .tint(.cultivAccent)
                    .frame(width: 80)
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.05)), alignment: .bottom)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)
            Image(systemName: "ellipsis.bubble")
                .font(.system(size: 50))
                .foregroundColor(.cultivMuted.opacity(0.3))
            Text("纹章黯淡，戒灵沉睡中...")
                .font(.system(.body, design: .serif))
                .italic()
                .foregroundColor(.cultivMuted.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
    
    private var quickActionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                quickActionButton(label: "请墨老指点", icon: "sparkles") {
                    sendMessage("墨老，请指教！")
                }
                quickActionButton(label: "窥探机缘", icon: "eye.circle") {
                    sendMessage("墨老，不知今日可有机缘降下？")
                }
                quickActionButton(label: "我偷懒了...", icon: "zzz") {
                    sendMessage("墨老，我有罪，我今日想偷懒...")
                }
            }
        }
    }
    
    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("向墨老祈告...", text: $chatText)
                .textFieldStyle(.plain)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.05)))
                .foregroundColor(.white)
            
            Button {
                sendMessage(chatText)
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.black)
                    .padding(10)
                    .background(Circle().fill(chatText.isEmpty ? Color.cultivMuted : Color.cultivAccent))
            }
            .disabled(chatText.isEmpty || llm.isGenerating)
        }
    }
    
    private func quickActionButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().stroke(Color.cultivAccent.opacity(0.4), lineWidth: 1))
            .foregroundColor(.cultivAccent)
        }
        .disabled(llm.isGenerating)
    }
    
    private func sendMessage(_ text: String) {
        let content = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        chatText = ""
        
        Task {
            await llm.sendUserMessage(content, stats: player.toDictionary(), player: player)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
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
                    Text(message.content)
                        .font(.system(.body, design: .serif))
                        .textSelection(.enabled)
                        .padding(12)
                        .background(
                            BubbleShape(role: message.role)
                                .fill(message.role == .user ? Color.cultivAccent.opacity(0.2) : Color.white.opacity(0.08))
                        )
                        .foregroundColor(.white)
                    
                    if message.isGenerating {
                        ProgressView()
                            .scaleEffect(0.7)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.role == .user ? .trailing : .leading)
            }
            
            if message.role == .assistant { Spacer() }
        }
    }
}

struct BubbleShape: Shape {
    let role: MessageRole
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: role == .user ? [.topLeft, .bottomLeft, .bottomRight] : [.topRight, .bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: 14, height: 14)
        )
        return Path(path.cgPath)
    }
}
#endif
