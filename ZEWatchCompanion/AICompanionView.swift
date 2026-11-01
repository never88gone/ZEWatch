import SwiftUI
import UIKit

#if os(iOS)
struct AICompanionView: View {
    @ObservedObject var player: PlayerProfile
    var onGoToSettings: (() -> Void)? = nil
    
    @State private var chatText: String = ""
    @ObservedObject var llm = LLMManager.shared
    @Namespace private var bottomID
    @State private var showingModelSelection = false
    @State private var showingFileImporter = false
    @AppStorage("useHFMirror") private var useHFMirror = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部：墨老魂影与境界
                elderHeader
                
                if llm.modelLoaded {
                    // 已就绪：识海对话区
                    conversationView
                    
                    // 底部：快捷灵咒与输入
                    VStack(spacing: 12) {
                        quickActionsBar
                        inputArea
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .background(Color.black.opacity(0.4).blur(radius: 10))
                } else {
                    // 未就绪：模型选择与接引指引
                    modelSetupGuideView
                }
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingModelSelection = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "cpu")
                            Text("法器阁")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.cultivAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.cultivAccent.opacity(0.15)))
                    }
                    .accessibilityLabel("法器阁，管理与下载大模型")
                }
            }
            .sheet(isPresented: $showingModelSelection) {
                ModelSelectionView(llm: llm)
            }
            .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        llm.importModel(from: url)
                    }
                case .failure(let error):
                    print("选择模型文件失败: \(error)")
                }
            }
            .onAppear {
                let models = llm.fetchLocalModels()
                // 自动唤醒：若本地已有完整模型，且当前未就绪且未在下载/加载中，自动触发唤醒
                if !llm.modelLoaded && !llm.isLoadingModel && !llm.isDownloading && !models.isEmpty {
                    Task {
                        await llm.loadModel()
                    }
                }
            }
        }
    }
    
    // MARK: - 对话主视图
    private var conversationView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if llm.messages.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(llm.messages) { msg in
                            MessageBubble(message: msg, llm: llm, player: player)
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
                if llm.isGenerating {
                    let generator = UIImpactFeedbackGenerator(style: .rigid)
                    generator.impactOccurred(intensity: 0.3)
                }
            }
        }
    }
    
    // MARK: - 未加载模型时的接引中枢
    private var modelSetupGuideView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if llm.isDownloading || llm.hasResumeData {
                    downloadingProgressCard
                } else if !llm.localModels.isEmpty {
                    localModelReadyCard
                } else {
                    initialDownloadGuideCard
                }
            }
            .padding()
        }
    }
    
    // MARK: - 实时接引中卡片
    private var downloadingProgressCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.cultivAccent.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.cultivAccent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("天道引灵中 · 接引法器")
                        .font(.headline)
                        .foregroundColor(.cultivText)
                    Text(llm.downloadingModelTitle.isEmpty ? "正在下载大模型..." : llm.downloadingModelTitle)
                        .font(.subheadline)
                        .foregroundColor(.cultivAccent)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: llm.downloadProgress)
                    .tint(.cultivAccent)
                
                HStack {
                    Text("\(formatBytes(llm.downloadedBytes)) / \(formatBytes(llm.totalBytes))")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.cultivMuted)
                    Spacer()
                    if !llm.downloadSpeedDesc.isEmpty {
                        Text(llm.downloadSpeedDesc)
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.cultivAccent)
                    }
                    Text("\(Int(llm.downloadProgress * 100))%")
                        .font(.caption.monospacedDigit().bold())
                        .foregroundColor(.cultivText)
                }
                
                if !llm.estimatedTimeRemaining.isEmpty && llm.isDownloading {
                    HStack {
                        Image(systemName: "clock")
                        Text(llm.estimatedTimeRemaining)
                    }
                    .font(.caption2)
                    .foregroundColor(.cultivMuted)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
            
            if let err = llm.downloadErrorText {
                Text("接引异常：\(err)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack(spacing: 12) {
                if llm.isDownloading {
                    Button {
                        llm.pauseDownload()
                    } label: {
                        Label("暂停", systemImage: "pause.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .accessibilityIdentifier("pause_download_button")
                } else if llm.hasResumeData {
                    Button {
                        llm.resumeDownload()
                    } label: {
                        Label("继续接引", systemImage: "play.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.cultivAccent)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .accessibilityIdentifier("resume_download_button")
                }
                
                Button(role: .destructive) {
                    llm.cancelDownload()
                } label: {
                    Label("取消", systemImage: "xmark")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
                .accessibilityIdentifier("cancel_download_button")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cultivAccent.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 本地已有法器但未激活
    private var localModelReadyCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.cultivAccent.opacity(0.15))
                    .frame(width: 64, height: 64)
                
                if llm.isLoadingModel {
                    ProgressView()
                        .tint(.cultivAccent)
                        .scaleEffect(1.3)
                } else {
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.cultivAccent)
                }
            }
            .padding(.top, 6)
            
            Text(llm.isLoadingModel ? "正在沟通灵脉唤醒戒灵..." : "识海已有法器凝聚")
                .font(.title3.bold())
                .foregroundColor(.cultivText)
            
            Text("当前预选法器：\(llm.currentModelFilename.isEmpty ? (llm.localModels.first ?? "") : llm.currentModelFilename)")
                .font(.caption)
                .foregroundColor(.cultivMuted)
                .multilineTextAlignment(.center)
            
            if let err = llm.loadErrorText {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(10)
                .background(Color.red.opacity(0.12))
                .cornerRadius(8)
            }
            
            Button {
                Task {
                    let target = llm.currentModelFilename.isEmpty ? llm.localModels.first : llm.currentModelFilename
                    await llm.loadModel(filename: target)
                }
            } label: {
                HStack {
                    if llm.isLoadingModel {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 4)
                        Text("唤醒中...")
                    } else {
                        Image(systemName: "bolt.fill")
                        Text("立即唤醒戒灵")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(llm.isLoadingModel ? Color.gray.opacity(0.6) : Color.cultivAccent)
                .cornerRadius(10)
            }
            .disabled(llm.isLoadingModel)
            .accessibilityIdentifier("wake_model_button")
            
            if llm.loadErrorText != nil {
                Button(role: .destructive) {
                    if let target = llm.localModels.first {
                        llm.deleteModel(filename: target)
                        llm.loadErrorText = nil
                    }
                } label: {
                    Label("清除残缺法器并重新接引", systemImage: "trash")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                        .padding(.vertical, 4)
                }
            }
            
            Button {
                showingModelSelection = true
            } label: {
                Text("切换或接引其他法器")
                    .font(.subheadline)
                    .foregroundColor(.cultivSecondary)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 首次空状态引导：提示前往设置页面下载
    private var initialDownloadGuideCard: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Color.cultivAccent.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundColor(.cultivAccent)
            }
            .padding(.top, 16)
            
            VStack(spacing: 10) {
                Text("识海空明 · 戒灵未凝")
                    .font(.title2.bold())
                    .foregroundColor(.cultivText)
                
                Text("本法宝遵循极简轻灵原则，**安装包未内置大模型**。")
                    .font(.subheadline)
                    .foregroundColor(.cultivSecondary)
                    .multilineTextAlignment(.center)
                
                Text("请前往「须弥戒 (设置)」挑选并接引心法法器。下载后将长驻本地沙盒，无需联网即可与墨老神念传音。")
                    .font(.footnote)
                    .foregroundColor(.cultivMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
            }
            
            Button {
                if let onGo = onGoToSettings {
                    onGo()
                } else {
                    showingModelSelection = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                    Text("前往设置挑选并接引法器")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.cultivPrimary, Color.cultivAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.cultivAccent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .accessibilityIdentifier("goto_settings_download_button")
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            Button {
                showingFileImporter = true
            } label: {
                Label("从本地导入已有法器 (.gguf)", systemImage: "folder.badge.plus")
                    .font(.caption)
                    .foregroundColor(.cultivSecondary)
            }
            .padding(.bottom, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 MB" }
        let mb = Double(bytes) / (1024 * 1024)
        if mb >= 1024 {
            let gb = mb / 1024
            return String(format: "%.2f GB", gb)
        } else {
            return String(format: "%.1f MB", mb)
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
            
            Text(llm.statusMessage)
                .font(.system(.body, design: .serif))
                .italic()
                .foregroundColor(.cultivMuted.opacity(0.8))
                
            if !llm.modelLoaded {
                Text("请前往「须弥戒」接引法器 (下载模型)")
                    .font(.subheadline)
                    .foregroundColor(.cultivAccent)
                    .padding(.top, 10)
            }
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
        .overlay(
            // 生成中显示半透明递色遮罩，让用户明确知道在等待
            Group {
                if llm.isGenerating {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.cultivAccent)
                            .scaleEffect(0.8)
                        Text("墨老思念中...西勿打扰")
                            .font(.caption)
                            .foregroundColor(.cultivMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(20)
                }
            }
        )
    }
    
    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField(llm.isGenerating ? "墨老思念中，请稍候..." : (llm.isConversingDisabled ? "神魂受损，需静养..." : "向墨老祈告..."), text: $chatText)
                .textFieldStyle(.plain)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.05)))
                .foregroundColor(.white)
                .disabled(llm.isGenerating || llm.isConversingDisabled)
                .accessibilityIdentifier("chat_text_field")
            
            Button {
                sendMessage(chatText)
            } label: {
                ZStack {
                    if llm.isGenerating {
                        ProgressView()
                            .tint(.cultivAccent)
                            .scaleEffect(0.8)
                            .padding(10)
                            .background(Circle().fill(Color.cultivMuted.opacity(0.3)))
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Circle().fill(chatText.isEmpty || llm.isConversingDisabled ? Color.cultivMuted : Color.cultivAccent))
                    }
                }
            }
            .disabled(chatText.isEmpty || llm.isGenerating || llm.isConversingDisabled)
            .accessibilityIdentifier("send_message_button")
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
        .disabled(llm.isGenerating || llm.isConversingDisabled)
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
    @ObservedObject var llm: LLMManager
    @ObservedObject var player: PlayerProfile
    
    // 用于呼吸灯动画
    @State private var isBreathing = false
    
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

struct ModelSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var llm: LLMManager
    @State private var repoID: String = ""
    @State private var filename: String = ""
    @State private var showingFileImporter = false
    @AppStorage("useHFMirror") private var useHFMirror = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("轻量纯净 · 无内置大模型")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text("本法宝绝不内置笨重大模型，占用零安装包体积。仙友可根据手机性能挑选默认模型下载，或从本地导入已有的 .gguf 文件。所有数据仅在手机本地运算，安全且保护隐私。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: - 已在法器囊中的模型
                if !llm.localModels.isEmpty {
                    Section(header: Text("已在法器囊中 (已下载)")) {
                        ForEach(llm.localModels, id: \.self) { modelName in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(modelName)
                                        .font(.subheadline)
                                        .foregroundColor(llm.currentModelFilename == modelName ? .cultivPrimary : .primary)
                                    
                                    if llm.currentModelFilename == modelName {
                                        Text(llm.modelLoaded ? "当前激活 · 神念相连" : "预选法器 · 待唤醒")
                                            .font(.caption2.bold())
                                            .foregroundColor(llm.modelLoaded ? .green : .orange)
                                    }
                                }
                                
                                Spacer()
                                
                                if llm.currentModelFilename != modelName {
                                    Button("激活") {
                                        llm.unloadModel()
                                        Task {
                                            await llm.loadModel(filename: modelName)
                                            dismiss()
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.cultivPrimary)
                                    .font(.caption.bold())
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    llm.deleteModel(filename: modelName)
                                } label: {
                                    Label("销毁", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                // MARK: - 官方默认精选模型
                Section(header: Text("官方精选默认模型 (点击下载)"), footer: Text("所有模型均适配手机移动端。建议首选 Qwen2.5 0.5B (极速省电) 或 1.5B (综合最佳)。")) {
                    
                    Toggle("国内网络镜像加速 (hf-mirror.com)", isOn: $useHFMirror)
                        .font(.subheadline)
                    
                    ForEach(LLMManager.recommendedModels) { model in
                        let isDownloaded = llm.localModels.contains(model.filename)
                        let isCurrent = (llm.currentModelFilename == model.filename) && llm.modelLoaded
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(model.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        if model.isRecommended {
                                            Text("推荐")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 1.5)
                                                .background(Capsule().fill(Color.cultivAccent))
                                        }
                                    }
                                    Text(model.tag)
                                        .font(.caption.bold())
                                        .foregroundColor(.cultivPrimary)
                                }
                                
                                Spacer()
                                
                                Text(model.sizeDesc)
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(model.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                            
                            if isCurrent {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                    Text("当前正在使用此法器")
                                        .font(.caption.bold())
                                        .foregroundColor(.green)
                                }
                                .padding(.top, 2)
                            } else if isDownloaded {
                                Button {
                                    llm.unloadModel()
                                    Task {
                                        await llm.loadModel(filename: model.filename)
                                        dismiss()
                                    }
                                } label: {
                                    Text("已在本地 · 点击立即切换")
                                        .font(.caption.bold())
                                        .foregroundColor(.cultivPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(Capsule().stroke(Color.cultivPrimary, lineWidth: 1))
                                }
                                .padding(.top, 2)
                            } else {
                                Button {
                                    llm.downloadModel(model, useMirror: useHFMirror)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.down.circle.fill")
                                        Text("下载接引 (\(model.sizeDesc))")
                                    }
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                                    .background(Color.cultivAccent)
                                    .cornerRadius(6)
                                }
                                .padding(.top, 2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // MARK: - 自定义与本地导入
                Section(header: Text("从本地导入已有法器")) {
                    Button {
                        showingFileImporter = true
                    } label: {
                        Label("选取本地 .gguf 文件导入", systemImage: "folder.badge.plus")
                            .foregroundColor(.cultivPrimary)
                    }
                }
                
                Section(header: Text("从 HuggingFace 自由下载"), footer: Text("输入仓库ID与文件名即可直接接引。")) {
                    TextField("仓库ID (例如 Qwen/Qwen2.5-0.5B-Instruct-GGUF)", text: $repoID)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("文件名 (例如 qwen2.5-0.5b-instruct-q4_k_m.gguf)", text: $filename)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button("开始接引下载") {
                        if !repoID.isEmpty && !filename.isEmpty {
                            let domain = useHFMirror ? "hf-mirror.com" : "huggingface.co"
                            let cleanRepo = repoID.trimmingCharacters(in: .whitespacesAndNewlines)
                            let cleanFile = filename.trimmingCharacters(in: .whitespacesAndNewlines)
                            let downloadURL = "https://\(domain)/\(cleanRepo)/resolve/main/\(cleanFile)"
                            
                            llm.downloadModel(from: downloadURL, filename: cleanFile)
                            dismiss()
                        }
                    }
                    .disabled(repoID.isEmpty || filename.isEmpty)
                }
            }
            .navigationTitle("法器宝阁 (大模型)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        llm.importModel(from: url)
                        dismiss()
                    }
                case .failure(let error):
                    print("选择模型文件失败: \(error)")
                }
            }
        }
    }
}
#endif
