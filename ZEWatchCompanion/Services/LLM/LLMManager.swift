import Foundation
import UIKit

#if os(iOS)
@MainActor
class LLMManager: ObservableObject {
    static let shared = LLMManager()
    
    /// 默认精选法器（模型），不内置于应用安装包中，由用户按需挑选下载
    static let recommendedModels: [LLMModelOption] = [
        LLMModelOption(
            id: "qwen2.5-0.5b",
            name: "Qwen2.5 0.5B Instruct",
            tag: "⚡ 极速轻量 · 首选推荐",
            description: "千问2.5代极速版，内存占用极低（<600MB），不发热不掉帧，老旧机型亦能流畅秒回。",
            modelscopeUrl: "https://modelscope.cn/api/v1/models/qwen/Qwen2.5-0.5B-Instruct-GGUF/repo?Revision=master&FilePath=qwen2.5-0.5b-instruct-q4_k_m.gguf",
            mirrorUrl: "https://hf-mirror.com/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
            huggingfaceUrl: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
            filename: "qwen2.5-0.5b-instruct-q4_k_m.gguf",
            sizeDesc: "约 390 MB",
            isRecommended: true
        ),
        LLMModelOption(
            id: "qwen2.5-1.5b",
            name: "Qwen2.5 1.5B Instruct",
            tag: "🔥 综合最佳 · 中文主力",
            description: "千问2.5代小钢炮，古风语感出众，对答毒舌精辟，逻辑与文采兼备，推荐主流 iPhone 用户选择。",
            modelscopeUrl: "https://modelscope.cn/api/v1/models/qwen/Qwen2.5-1.5B-Instruct-GGUF/repo?Revision=master&FilePath=qwen2.5-1.5b-instruct-q4_k_m.gguf",
            mirrorUrl: "https://hf-mirror.com/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
            huggingfaceUrl: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
            filename: "qwen2.5-1.5b-instruct-q4_k_m.gguf",
            sizeDesc: "约 1.1 GB",
            isRecommended: true
        ),
        LLMModelOption(
            id: "qwen2.5-coder-1.5b",
            name: "Qwen2.5-Coder 1.5B",
            tag: "🧠 严谨逻辑 · 适合格物",
            description: "千问代码与推演强化版1.5B，逻辑缜密、条理分明，适合偏好推演格物致知的仙友。",
            modelscopeUrl: "https://modelscope.cn/api/v1/models/qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/repo?Revision=master&FilePath=qwen2.5-coder-1.5b-instruct-q4_k_m.gguf",
            mirrorUrl: "https://hf-mirror.com/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf",
            huggingfaceUrl: "https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf",
            filename: "qwen2.5-coder-1.5b-instruct-q4_k_m.gguf",
            sizeDesc: "约 1.1 GB",
            isRecommended: false
        ),
        LLMModelOption(
            id: "qwen2.5-3b",
            name: "Qwen2.5 3B Instruct",
            tag: "🔮 高配专属 · 深度推演",
            description: "参数翻倍，上仙大能之威严更甚，推理更深邃，推荐 6GB+ 运存机型（如 iPhone 15 Pro / 16 等）。",
            modelscopeUrl: "https://modelscope.cn/api/v1/models/qwen/Qwen2.5-3B-Instruct-GGUF/repo?Revision=master&FilePath=qwen2.5-3b-instruct-q4_k_m.gguf",
            mirrorUrl: "https://hf-mirror.com/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf",
            huggingfaceUrl: "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf",
            filename: "qwen2.5-3b-instruct-q4_k_m.gguf",
            sizeDesc: "约 2.0 GB",
            isRecommended: false
        )
    ]
    
    @Published var messages: [ChatMessage] = []
    @Published var isGenerating: Bool = false
    @Published var modelLoaded: Bool = false
    @Published var isLoadingModel: Bool = false
    @Published var loadErrorText: String? = nil
    @Published var statusMessage: String = "未感应到戒灵..."
    
    @Published var localModels: [String] = []
    @Published var currentModelFilename: String = ""
    
    // 下载相关状态
    @Published var isDownloading: Bool = false
    @Published var downloadingModelTitle: String = ""
    @Published var downloadProgress: Double = 0.0
    @Published var downloadedBytes: Int64 = 0
    @Published var totalBytes: Int64 = 0
    @Published var downloadSpeedDesc: String = ""
    @Published var hasResumeData: Bool = false
    @Published var estimatedTimeRemaining: String = ""
    @Published var downloadErrorText: String? = nil
    
    var pendingTargetFilename: String?
    var downloadStartTime: Date?
    var lastLoggedPercent: Int = -1
    
    var currentDownloadTask: URLSessionDownloadTask?
    var resumeData: Data? {
        didSet { hasResumeData = resumeData != nil }
    }

    var context: LlamaContext?
    
    private init() {
        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        fetchLocalModels()
        loadHistory()
        checkOOMRecovery()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 历史消息持久化
    private var historyFileURL: URL {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent("chat_history.json")
    }
    
    func saveHistory() {
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: historyFileURL, options: .atomic)
        } catch {
            print("保存对话历史失败: \(error)")
        }
    }
    
    private func loadHistory() {
        do {
            guard FileManager.default.fileExists(atPath: historyFileURL.path) else { return }
            let data = try Data(contentsOf: historyFileURL)
            let decoded = try JSONDecoder().decode([ChatMessage].self, from: data)
            // 过滤历史中所有内容为空的破损残差消息
            var validMessages = decoded.filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            // 若历史出现异常堆积或污染，仅保留最近2条
            if validMessages.count > 4 {
                validMessages = Array(validMessages.suffix(2))
            }
            self.messages = validMessages
        } catch {
            print("加载对话历史失败: \(error)")
        }
    }
    
    @Published var isConversingDisabled: Bool = false
    
    private func handleMemoryWarning() {
        print("【LLMManager】收到内存警告！正在清空对话记录以防 OOM...")
        // 清空历史记忆，仅保留最后一条和模型加载状态
        if messages.count > 2 {
            let lastMessages = Array(messages.suffix(2))
            messages = lastMessages
        }
        messages.append(ChatMessage(role: .system, content: "【神魂受创】因天道反噬（内存告警），墨老神魂激荡，暂时遗忘了先前的对话。"))
        saveHistory()
        UserDefaults.standard.set(Date(), forKey: "lastOOMDate")
    }
    
    func checkOOMRecovery() {
        if let lastOOM = UserDefaults.standard.object(forKey: "lastOOMDate") as? Date {
            let elapsed = Date().timeIntervalSince(lastOOM)
            if elapsed < 300 {
                // 5 分钟内
                DispatchQueue.main.async {
                    self.isConversingDisabled = true
                    if self.messages.last?.content.contains("神魂受创") == false {
                        self.messages.append(ChatMessage(role: .system, content: "【神魂受创】墨老因强行推演反噬，神魂虚弱，需静养 5 分钟。"))
                        self.saveHistory()
                    }
                }
                
                // 设置定时器解禁
                DispatchQueue.main.asyncAfter(deadline: .now() + (300 - elapsed)) {
                    self.isConversingDisabled = false
                    self.messages.append(ChatMessage(role: .system, content: "【神魂归位】墨老长舒一口气：‘总算缓过来了...’"))
                    self.saveHistory()
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "lastOOMDate")
            }
        }
    }
    
    /// 刷新并获取沙盒中的模型列表
    @discardableResult
    func fetchLocalModels() -> [String] {
        let fileManager = FileManager.default
        let modelsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Models").path
        
        if fileManager.fileExists(atPath: modelsPath),
           let files = try? fileManager.contentsOfDirectory(atPath: modelsPath) {
            let ggufFiles = files.filter { $0.hasSuffix(".gguf") }.sorted()
            self.localModels = ggufFiles
            if ggufFiles.isEmpty {
                self.modelLoaded = false
                self.isLoadingModel = false
                self.currentModelFilename = ""
                self.statusMessage = "戒灵沉睡，未感应到法器。请挑选并接引法器下界。"
            }
            return ggufFiles
        } else {
            self.localModels = []
            self.modelLoaded = false
            self.isLoadingModel = false
            self.currentModelFilename = ""
            self.statusMessage = "戒灵沉睡，未感应到法器。请挑选并接引法器下界。"
            return []
        }
    }
    
    /// 格式化字节大小
    func formatBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 MB" }
        let mb = Double(bytes) / (1024 * 1024)
        if mb >= 1024 {
            let gb = mb / 1024
            return String(format: "%.2f GB", gb)
        }
        return String(format: "%.1f MB", mb)
    }
    
    /// 获取指定沙盒模型的实际字节大小
    func getModelFileSize(filename: String) -> Int64 {
        let fileManager = FileManager.default
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Models").appendingPathComponent(filename).path
        if let attrs = try? fileManager.attributesOfItem(atPath: path),
           let size = attrs[.size] as? Int64 {
            return size
        }
        return 0
    }
    
    /// 导入外部模型文件
    func importModel(from url: URL) {
        let fileManager = FileManager.default
        let modelsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Models")
        
        do {
            if !fileManager.fileExists(atPath: modelsDir.path) {
                try fileManager.createDirectory(at: modelsDir, withIntermediateDirectories: true, attributes: nil)
            }
            
            // 因为系统选择器返回的可能是安全书签，必须调用 startAccessingSecurityScopedResource
            let startAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if startAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            let destURL = modelsDir.appendingPathComponent(url.lastPathComponent)
            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }
            try fileManager.copyItem(at: url, to: destURL)
            
            print("模型导入成功: \(url.lastPathComponent)")
            fetchLocalModels()
            let importedFilename = url.lastPathComponent
            UserDefaults.standard.set(importedFilename, forKey: "selectedModelName")
            Task {
                await self.loadModel(filename: importedFilename)
            }
        } catch {
            print("模型导入失败: \(error)")
        }
    }
    
    /// 卸载当前模型并清理内存
    func unloadModel() {
        self.context = nil
        self.modelLoaded = false
        self.isLoadingModel = false
        self.loadErrorText = nil
        self.statusMessage = "戒灵沉睡..."
        self.currentModelFilename = ""
    }
    
    /// 删除指定本地模型
    func deleteModel(filename: String) {
        let fileManager = FileManager.default
        let fileURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Models").appendingPathComponent(filename)
        do {
            try fileManager.removeItem(at: fileURL)
            fetchLocalModels()
            if currentModelFilename == filename {
                unloadModel()
                if let nextModel = localModels.first(where: { $0 != filename }) {
                    Task {
                        await loadModel(filename: nextModel)
                    }
                }
            }
        } catch {
            print("删除模型失败: \(error)")
        }
    }
    
    /// 加载本地 Llama 模型
    func loadModel(filename: String? = nil) async {
        let available = fetchLocalModels()
        
        var target: String? = filename
        if target == nil {
            target = UserDefaults.standard.string(forKey: "selectedModelName")
        }
        if target == nil || !available.contains(target!) {
            target = available.first
        }
        
        guard let finalTarget = target, !finalTarget.isEmpty else {
            self.statusMessage = "戒灵沉睡，未感应到法器。请挑选并接引法器下界。"
            self.modelLoaded = false
            self.isLoadingModel = false
            self.currentModelFilename = ""
            return
        }
        
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let finalPath = documentDirectory.appendingPathComponent("Models").appendingPathComponent(finalTarget).path
        
        guard fileManager.fileExists(atPath: finalPath) else {
            self.statusMessage = "法器不存在，请挑选并接引法器下界。"
            self.modelLoaded = false
            self.isLoadingModel = false
            self.currentModelFilename = ""
            return
        }
        
        let fileSize = getModelFileSize(filename: finalTarget)
        print("【LLM】准备载入法器: \(finalTarget), 字节大小: \(fileSize) (\(formatBytes(fileSize)))")
        
        // 校验文件完整性：任何有效的量化 GGUF 模型至少应大于 50MB（0.5B 为 ~390MB）
        if fileSize < 50 * 1024 * 1024 {
            self.isLoadingModel = false
            self.modelLoaded = false
            let err = "法器残破不全（仅 \(formatBytes(fileSize))，可能接引中断），请清除后重新接引。"
            self.loadErrorText = err
            self.statusMessage = "唤醒失败：法器残损"
            print("【LLM】\(err)")
            return
        }
        
        self.isLoadingModel = true
        self.loadErrorText = nil
        self.statusMessage = "正在唤醒戒灵..."
        
        do {
            // 通过 Task.detached 将底层耗时的 C 库初始化操作移至后台线程，防止阻塞主线程导致启动过慢
            let newContext = try await Task.detached(priority: .userInitiated) {
                return try await LlamaContext.create_context(path: finalPath)
            }.value
            
            self.context = newContext
            self.currentModelFilename = finalTarget
            UserDefaults.standard.set(finalTarget, forKey: "selectedModelName")
            self.modelLoaded = true
            self.isLoadingModel = false
            self.loadErrorText = nil
            self.statusMessage = "咳咳... 谁在那吵老夫睡觉？"
            print("【LLM】戒灵唤醒成功！当前法器: \(finalTarget)")
            
            // 初始消息
            if messages.isEmpty {
                messages.append(ChatMessage(role: .assistant, content: "小辈，今日为何无精打采？若再不磨炼筋骨，老夫这戒指可容不下你了。"))
                saveHistory()
            }
            
        } catch {
            self.isLoadingModel = false
            self.modelLoaded = false
            self.loadErrorText = "唤醒失败：\(error.localizedDescription)"
            self.statusMessage = "唤醒失败：神魂受损"
            print("【LLM】加载异常：\(error)")
        }
    }
}
#endif

