import Foundation

#if os(iOS)
// MARK: - LLMManager 模型下载与文件转存扩展
extension LLMManager {
    /// 下载推荐的大模型（默认优先使用阿里魔搭国内极速直连源）
    public func downloadModel(_ model: LLMModelOption, source: ModelDownloadSource = .modelscope) {
        let urlString = model.url(for: source)
        guard let url = URL(string: urlString) else {
            self.downloadErrorText = "无效的下载法阵地址"
            return
        }
        
        self.downloadingModelTitle = model.name
        self.downloadErrorText = nil
        self.pendingTargetFilename = model.filename
        self.resumeData = nil
        startDownload(with: url, expectedFilename: model.filename)
    }
    
    /// 兼容旧方法：根据镜像开关映射对应源
    public func downloadModel(_ model: LLMModelOption, useMirror: Bool) {
        let source: ModelDownloadSource = useMirror ? .hfMirror : .modelscope
        downloadModel(model, source: source)
    }
    
    /// 根据自定义 URL 下载模型
    public func downloadModel(from urlString: String, filename: String? = nil) {
        guard let url = URL(string: urlString) else {
            self.downloadErrorText = "无效的接引地址"
            return
        }
        
        let resolvedFilename = filename ?? url.lastPathComponent
        self.downloadingModelTitle = resolvedFilename
        self.downloadErrorText = nil
        self.pendingTargetFilename = resolvedFilename
        self.resumeData = nil
        startDownload(with: url, expectedFilename: resolvedFilename)
    }
    
    public func resumeDownload() {
        guard let resumeData = resumeData else { return }
        isDownloading = true
        downloadErrorText = nil
        statusMessage = "正在接续阵纹..."
        downloadStartTime = Date()
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 7200
        config.waitsForConnectivity = true
        
        let session = URLSession(configuration: config, delegate: DownloadDelegate(progressHandler: { [weak self] progress, downloaded, total in
            self?.updateDownloadProgress(progress: progress, downloaded: downloaded, total: total)
        }, completionHandler: { [weak self] localURL, error in
            self?.handleDownloadCompletion(localURL: localURL, error: error, originalURL: nil)
        }), delegateQueue: nil)
        
        let task = session.downloadTask(withResumeData: resumeData)
        self.currentDownloadTask = task
        task.resume()
    }
    
    func startDownload(with url: URL, expectedFilename: String? = nil) {
        isDownloading = true
        downloadProgress = 0.0
        downloadedBytes = 0
        totalBytes = 0
        downloadSpeedDesc = ""
        estimatedTimeRemaining = ""
        downloadErrorText = nil
        statusMessage = "正在接引戒灵法器下界..."
        downloadStartTime = Date()
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 7200
        config.waitsForConnectivity = true
        
        let session = URLSession(configuration: config, delegate: DownloadDelegate(progressHandler: { [weak self] progress, downloaded, total in
            self?.updateDownloadProgress(progress: progress, downloaded: downloaded, total: total)
        }, completionHandler: { [weak self] localURL, error in
            self?.handleDownloadCompletion(localURL: localURL, error: error, originalURL: url)
        }), delegateQueue: nil)
        
        let task = session.downloadTask(with: url)
        self.currentDownloadTask = task
        task.resume()
    }
    
    func updateDownloadProgress(progress: Double, downloaded: Int64, total: Int64) {
        DispatchQueue.main.async {
            self.downloadProgress = progress
            self.downloadedBytes = downloaded
            self.totalBytes = total
            
            if let startTime = self.downloadStartTime {
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed > 0.5 && downloaded > 0 {
                    let bytesPerSecond = Double(downloaded) / elapsed
                    let mbps = bytesPerSecond / (1024 * 1024)
                    self.downloadSpeedDesc = String(format: "%.1f MB/s", mbps)
                    
                    let remainingBytes = Double(max(0, total - downloaded))
                    let remainingSeconds = remainingBytes / bytesPerSecond
                    
                    if remainingSeconds.isFinite && remainingSeconds > 0 {
                        let formatter = DateComponentsFormatter()
                        formatter.allowedUnits = [.hour, .minute, .second]
                        formatter.unitsStyle = .abbreviated
                        self.estimatedTimeRemaining = "预计剩余 " + (formatter.string(from: remainingSeconds) ?? "--")
                    }
                    
                    let curPercent = Int(progress * 100)
                    if curPercent % 10 == 0 && curPercent != self.lastLoggedPercent {
                        self.lastLoggedPercent = curPercent
                        print("【真机接引中】\(curPercent)% (\(self.formatBytes(downloaded)) / \(self.formatBytes(total))) | 速度: \(self.downloadSpeedDesc) | \(self.estimatedTimeRemaining)")
                    }
                }
            }
        }
    }
    
    func handleDownloadCompletion(localURL: URL?, error: Error?, originalURL: URL?) {
        DispatchQueue.main.async {
            if let error = error as NSError? {
                if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    self.resumeData = resumeData
                    self.statusMessage = "接引已中断 (可恢复)"
                } else {
                    self.downloadErrorText = error.localizedDescription
                    self.statusMessage = "接引失败: \(error.localizedDescription)"
                }
                self.isDownloading = false
                print("下载错误:", error)
                return
            }
            
            guard let localURL = localURL else {
                self.downloadErrorText = "数据残缺，未能成功获取法器"
                self.statusMessage = "接引失败: 数据残缺"
                self.isDownloading = false
                return
            }
            
            var filename = self.pendingTargetFilename
            if filename == nil || filename!.isEmpty {
                filename = self.currentDownloadTask?.response?.suggestedFilename ?? originalURL?.lastPathComponent ?? "model.gguf"
            }
            if !filename!.hasSuffix(".gguf") {
                filename! += ".gguf"
            }
            
            self.resumeData = nil
            self.saveDownloadedModel(from: localURL, filename: filename!)
        }
    }
    
    public func pauseDownload() {
        currentDownloadTask?.cancel(byProducingResumeData: { [weak self] (data: Data?) in
            DispatchQueue.main.async {
                self?.resumeData = data
                self?.isDownloading = false
                self?.statusMessage = "接引已暂停"
            }
        })
    }
    
    public func cancelDownload() {
        currentDownloadTask?.cancel()
        currentDownloadTask = nil
        isDownloading = false
        downloadProgress = 0.0
        downloadedBytes = 0
        totalBytes = 0
        downloadSpeedDesc = ""
        downloadingModelTitle = ""
        resumeData = nil
        downloadErrorText = nil
        statusMessage = "接引已取消"
    }
    
    func saveDownloadedModel(from tempURL: URL, filename: String) {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelsDirectory = documentDirectory.appendingPathComponent("Models")
        
        do {
            if !fileManager.fileExists(atPath: modelsDirectory.path) {
                try fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            let destinationURL = modelsDirectory.appendingPathComponent(filename)
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            
            self.isDownloading = false
            self.downloadingModelTitle = ""
            self.downloadSpeedDesc = ""
            self.estimatedTimeRemaining = ""
            self.downloadErrorText = nil
            self.statusMessage = "法器接引成功，戒灵已唤醒！"
            
            fetchLocalModels()
            UserDefaults.standard.set(filename, forKey: "selectedModelName")
            
            Task {
                await self.loadModel(filename: filename)
            }
        } catch {
            self.isDownloading = false
            self.downloadErrorText = "保存法器失败: \(error.localizedDescription)"
            self.statusMessage = "保存法器失败"
            print("文件移动错误:", error)
            try? fileManager.removeItem(at: tempURL)
        }
    }
}

// MARK: - 辅助代理类，用于处理下载进度与安全转存
public class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    var progressHandler: (Double, Int64, Int64) -> Void
    var completionHandler: (URL?, Error?) -> Void
    
    public init(progressHandler: @escaping (Double, Int64, Int64) -> Void, completionHandler: @escaping (URL?, Error?) -> Void) {
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        progressHandler(progress, totalBytesWritten, totalBytesExpectedToWrite)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let httpResponse = downloadTask.response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let error = NSError(
                domain: "LLMDownloadError",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "下载服务器响应异常 (HTTP \(httpResponse.statusCode))，建议在设置中切换下载线路重试。"]
            )
            completionHandler(nil, error)
            return
        }
        
        let fileManager = FileManager.default
        let safeTempDir = fileManager.temporaryDirectory.appendingPathComponent("ModelDownloads", isDirectory: true)
        let safeTempURL = safeTempDir.appendingPathComponent("dl_\(UUID().uuidString).gguf")
        
        do {
            if !fileManager.fileExists(atPath: safeTempDir.path) {
                try fileManager.createDirectory(at: safeTempDir, withIntermediateDirectories: true)
            }
            if fileManager.fileExists(atPath: safeTempURL.path) {
                try fileManager.removeItem(at: safeTempURL)
            }
            try fileManager.moveItem(at: location, to: safeTempURL)
            completionHandler(safeTempURL, nil)
        } catch {
            print("【LLM】移动临时下载文件失败: \(error)")
            completionHandler(nil, error)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completionHandler(nil, error)
        }
    }
}
#endif
