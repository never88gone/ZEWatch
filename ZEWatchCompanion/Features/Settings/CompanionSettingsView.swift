import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CompanionSettingsView: View {
    @ObservedObject var player: PlayerProfile
    @ObservedObject var llm = LLMManager.shared
    @ObservedObject var healthManager = HealthManager.shared
    @ObservedObject var watchFaceManager = WatchFaceSettingsManager.shared
    
    @AppStorage("hapticFeedbackEnabled") private var hapticEnabled = true
    @AppStorage("autoSettleOfflineGains") private var autoSettle = true
    @AppStorage("selectedModelName") private var selectedModelName: String = ""
    @AppStorage("modelDownloadSource") private var downloadSourceRaw = ModelDownloadSource.modelscope.rawValue
    
    private var downloadSource: ModelDownloadSource {
        get { ModelDownloadSource(rawValue: downloadSourceRaw) ?? .modelscope }
        set { downloadSourceRaw = newValue.rawValue }
    }
    
    @State private var showingModelSelection = false
    @State private var showingFileImporter = false
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                List {
                    // MARK: - Apple Watch 表盘设置
                Section {
                    NavigationLink {
                        WatchFaceStudioView(player: player)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(watchFaceManager.config.themeColor.primaryColor.opacity(0.18))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "applewatch")
                                    .font(.title2)
                                    .foregroundColor(watchFaceManager.config.themeColor.primaryColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text("修仙表盘工坊")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("仙表")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(watchFaceManager.config.themeColor.primaryColor)
                                        .foregroundColor(.black)
                                        .cornerRadius(4)
                                }
                                Text(watchFaceManager.config.style.title)
                                    .font(.caption)
                                    .foregroundColor(.cultivMuted)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Apple Watch 腕间修仙")
                }

                // MARK: - 修行偏好
                Section {
                    Toggle(isOn: $hapticEnabled) {
                        Label("触感反馈 (共鸣)", systemImage: "waveform.path")
                    }
                    .tint(.cultivPrimary)
                    
                    Toggle(isOn: $autoSettle) {
                        Label("自动结算闭关收益", systemImage: "clock.arrow.circlepath")
                    }
                    .tint(.cultivPrimary)
                } header: {
                    Text("修行偏好")
                }


                
                // MARK: - 法器库管理 (多模型支持)
                Section {
                    // 已下载的本地模型列表
                    ForEach(llm.localModels, id: \.self) { modelName in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(modelName)
                                    .font(.subheadline)
                                    .foregroundColor(llm.currentModelFilename == modelName ? .cultivPrimary : .primary)
                                
                                if llm.currentModelFilename == modelName {
                                    Text(llm.modelLoaded ? "当前激活 (已连接)" : "已就绪 (未加载)")
                                        .font(.caption2.bold())
                                        .foregroundColor(llm.modelLoaded ? .green : .orange)
                                }
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                if llm.currentModelFilename != modelName {
                                    Button("激活") {
                                        selectedModelName = modelName
                                        llm.unloadModel()
                                        Task {
                                            await llm.loadModel(filename: modelName)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.cultivPrimary)
                                    .font(.caption.bold())
                                    .accessibilityIdentifier("activate_model_\(modelName)")
                                }
                                
                                Button(role: .destructive) {
                                    llm.deleteModel(filename: modelName)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .font(.subheadline)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityIdentifier("delete_model_\(modelName)")
                            }
                        }
                        .accessibilityIdentifier("model_row_\(modelName)")
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                llm.deleteModel(filename: modelName)
                            } label: {
                                Label("销毁", systemImage: "trash")
                            }
                        }
                    }
                    
                    if llm.localModels.isEmpty {
                        Text("法器囊空空如也（安装包未内置大模型，请点击下方下载）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if llm.isDownloading || llm.hasResumeData || llm.downloadErrorText != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("天道引灵中 · " + (llm.downloadingModelTitle.isEmpty ? "接引法器" : llm.downloadingModelTitle))
                                    .font(.subheadline.bold())
                                    .foregroundColor(.cultivAccent)
                                Spacer()
                                if !llm.downloadSpeedDesc.isEmpty && llm.isDownloading {
                                    Text(llm.downloadSpeedDesc)
                                        .font(.caption2.monospacedDigit())
                                        .foregroundColor(.cultivAccent)
                                }
                                if !llm.estimatedTimeRemaining.isEmpty && llm.isDownloading {
                                    Text(llm.estimatedTimeRemaining)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if let errorText = llm.downloadErrorText {
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(errorText)
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                                .padding(.vertical, 2)
                            }
                            
                            ProgressView(value: llm.downloadProgress)
                                .tint(llm.downloadErrorText != nil ? .red : .cultivAccent)
                            
                            HStack {
                                Text("\(formatBytes(llm.downloadedBytes)) / \(formatBytes(llm.totalBytes))")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(llm.downloadProgress * 100))%")
                                    .font(.caption2.monospacedDigit().bold())
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                if llm.isDownloading {
                                    Button {
                                        llm.pauseDownload()
                                    } label: {
                                        Label("暂停", systemImage: "pause.fill")
                                    }
                                    .accessibilityIdentifier("pause_download_button")
                                } else if llm.hasResumeData {
                                    Button {
                                        llm.resumeDownload()
                                    } label: {
                                        Label("继续接引", systemImage: "play.fill")
                                    }
                                    .accessibilityIdentifier("resume_download_button")
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    llm.cancelDownload()
                                } label: {
                                    Label("取消", systemImage: "xmark")
                                }
                                .accessibilityIdentifier("cancel_download_button")
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if llm.isGenerating {
                        HStack {
                            Label("推演中", systemImage: "sparkles")
                            Spacer()
                            ProgressView().tint(.cultivPrimary)
                        }
                    }
                } header: {
                    Text("法器库管理 (大模型)")
                } footer: {
                    Text("本应用遵循轻量设计，未在安装包中内置任何大模型。所有模型均需按需从天道接引下载，或从本地导入 .gguf 文件。模型存储在手机沙盒中，可随时销毁以释放空间。")
                }
                
                // MARK: - 官方默认大模型（接引下载专区）
                Section {
                    Picker("接引网络线路", selection: Binding(
                        get: { ModelDownloadSource(rawValue: downloadSourceRaw) ?? .modelscope },
                        set: { downloadSourceRaw = $0.rawValue }
                    )) {
                        ForEach(ModelDownloadSource.allCases) { source in
                            Text(source.displayName).tag(source)
                        }
                    }
                    .font(.subheadline)
                    
                    ForEach(LLMManager.recommendedModels) { model in
                        let isDownloaded = llm.localModels.contains(model.filename)
                        let isDownloadingThis = llm.isDownloading && (llm.downloadingModelTitle == model.name || llm.downloadingModelTitle.contains(model.filename))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(model.name)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.primary)
                                        if model.isRecommended {
                                            Text("官方推荐")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 1)
                                                .background(Capsule().fill(Color.cultivAccent))
                                        }
                                    }
                                    Text(model.tag)
                                        .font(.caption2.bold())
                                        .foregroundColor(.cultivSecondary)
                                }
                                
                                Spacer()
                                
                                Text(model.sizeDesc)
                                    .font(.caption2.monospacedDigit())
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(model.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                            
                            if isDownloaded {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(llm.currentModelFilename == model.filename ? "当前激活运行中" : "已下载就绪")
                                        .font(.caption2.bold())
                                        .foregroundColor(.green)
                                }
                                .padding(.top, 2)
                            } else if isDownloadingThis {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                    Text("正在接引中 (\(Int(llm.downloadProgress * 100))%)...")
                                        .font(.caption2)
                                        .foregroundColor(.cultivAccent)
                                }
                                .padding(.top, 2)
                            } else {
                                Button {
                                    llm.downloadModel(model, source: downloadSource)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.down.circle.fill")
                                        Text("接引此法器（下载 \(model.sizeDesc)）")
                                    }
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.cultivPrimary)
                                .accessibilityIdentifier("download_button_\(model.id)")
                                .disabled(llm.isDownloading)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button {
                        showingFileImporter = true
                    } label: {
                        Label("从须弥纳子导入 (本地文件导入)", systemImage: "folder.badge.plus")
                            .font(.subheadline)
                            .foregroundColor(.cultivPrimary)
                    }
                } header: {
                    Text("天道接引 · 官方默认大模型下载")
                } footer: {
                    Text("所有模型均为手机端精选量化版。默认使用【阿里魔搭极速源】国内直连高速 CDN，下载速度达 15~30 MB/s；若受网络波动影响，亦可随时切换备用镜像或官方源。")
                }


                
                // MARK: - 健康数据 (HealthKit)
                Section {
                    HStack {
                        Label("授权状态", systemImage: "heart.fill")
                            .foregroundColor(.red)
                        Spacer()
                        if healthManager.isAuthorized {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Text("已授权")
                                    .foregroundColor(.green)
                            }
                        } else {
                            Button {
                                HealthManager.shared.requestAuthorization { success, error in
                                    // 回调处理已在 HealthManager 中完成
                                }
                            } label: {
                                Text("去授权")
                                    .font(.system(size: 13, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.cultivPrimary)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .font(.callout)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("本应用通过 Apple HealthKit 读取以下健康数据，将其转化为游戏内的五行灵气。**所有数据仅在设备本地处理，绝不上传至任何服务器。**")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        companionHealthRow(icon: "figure.walk", label: "步数", element: "木灵气", color: .green)
                        companionHealthRow(icon: "flame.fill", label: "活动卡路里", element: "金灵气", color: .orange)
                        companionHealthRow(icon: "bed.double.fill", label: "睡眠分析", element: "水灵气", color: .blue)
                        companionHealthRow(icon: "heart.text.square", label: "心率数据", element: "奇遇触发", color: .red)
                        companionHealthRow(icon: "figure.run", label: "运动记录", element: "五行灵气", color: .cyan)
                        companionHealthRow(icon: "figure.stand", label: "站立小时", element: "木灵气", color: .green)
                    }
                    
                    Button {
                        if let url = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("前往「健康」管理数据权限", systemImage: "arrow.up.forward.app.fill")
                            .foregroundColor(.cultivPrimary)
                    }
                } header: {
                    Text("健康数据 (HealthKit)")
                }
                .id("health_section")
                
                // MARK: - 道途统计
                Section {
                    HStack {
                        Label("当前大境界", systemImage: "mountain.2.fill")
                        Spacer()
                        Text(CultivationEngine.shared.realmName(for: player.realm))
                            .font(.callout.bold())
                            .foregroundColor(.cultivSecondary)
                    }
                    HStack {
                        Label("累计真气", systemImage: "bolt.fill")
                        Spacer()
                        Text("\(player.cultivationBase)")
                            .font(.system(.callout, design: .monospaced).bold())
                            .foregroundColor(.cultivPrimary)
                    }
                } header: {
                    Text("道途统计")
                }
                
                // MARK: - 宗门
                Section {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        GameKitManager.shared.authenticateUser()
                    } label: {
                        Label("重新连接宗门玉牌", systemImage: "gamecontroller.fill")
                            .foregroundColor(.cultivPrimary)
                    }
                }
                
                // MARK: - 关于
                Section {
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label("隐私政策", systemImage: "hand.raised.fill")
                            .foregroundColor(.cultivPrimary)
                    }
                } header: {
                    Text("关于")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("须弥戒 (设置)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                llm.fetchLocalModels()
                if ProcessInfo.processInfo.environment["APPSTORE_PAGE"] == "health_rules" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            scrollProxy.scrollTo("health_section", anchor: .top)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingModelSelection) {
                ModelSelectionView(llm: llm)
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    llm.importModel(from: url)
                case .failure(let error):
                    print("文件选择失败: \(error.localizedDescription)")
                }
            }
            } // ScrollViewReader
        }
    }
    
    @ViewBuilder
    private func companionHealthRow(icon: String, label: String, element: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
            Text(element)
                .font(.caption.bold())
                .foregroundColor(color)
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
