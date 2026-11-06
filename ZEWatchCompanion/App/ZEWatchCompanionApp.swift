import SwiftUI

@main
struct ZEWatchCompanionApp: App {
    let connectivityManager = ConnectivityManager.shared
    let llmManager = LLMManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                .tint(.cyan)
                .task {
                    await llmManager.loadModel()
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .background {
                        try? PersistenceController.shared.container.viewContext.save()
                    }
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "zewatch" else { return }
        if url.host == "sync" {
            let styleParam = url.lastPathComponent
            if let style = WatchFaceStyle(rawValue: styleParam) {
                print("[URLScheme] 收到外部指令，触发同步修仙表盘: \(style.title)")
                var config = WatchFaceSettingsManager.shared.config
                config.style = style
                config.themeColor = style.recommendedTheme
                WatchFaceSettingsManager.shared.config = config
                WatchFaceSettingsManager.shared.broadcastConfig()
            }
        }
    }
}
