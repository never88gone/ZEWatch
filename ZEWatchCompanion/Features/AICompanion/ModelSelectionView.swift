import SwiftUI

#if os(iOS)
struct ModelSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var llm: LLMManager
    @State private var repoID: String = ""
    @State private var filename: String = ""
    @State private var showingFileImporter = false
    @AppStorage("useHFMirror") private var useHFMirror = false
    
    init(llm: LLMManager) {
        self.llm = llm
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("轻量纯净 · 无内置大模型")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text("支持按需下载推荐模型或导入本地 .gguf，数据仅在本地运算。")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
