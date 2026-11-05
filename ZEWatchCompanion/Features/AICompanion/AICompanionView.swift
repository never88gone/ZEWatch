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
                ElderHeaderView(player: player)
                
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
                if ProcessInfo.processInfo.environment["APPSTORE_PAGE"] == "model_selection" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showingModelSelection = true
                    }
                }
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
                    InitialDownloadGuideCard(
                        onGoToSettings: onGoToSettings,
                        onOpenModelSelection: { showingModelSelection = true },
                        onImportFile: { showingFileImporter = true }
                    )
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
    
    private func formatBytes(_ bytes: Int64) -> String {
        llm.formatBytes(bytes)
    }
}

#endif
