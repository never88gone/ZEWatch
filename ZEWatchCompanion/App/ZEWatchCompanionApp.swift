import SwiftUI

@main
struct ZEWatchCompanionApp: App {
    let connectivityManager = ConnectivityManager.shared
    let llmManager = LLMManager.shared
    @Environment(\.scenePhase) private var scenePhase  // HIG 10.6: 中断处理
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                .tint(.cyan)  // HIG 4.7: 全局统一的交互色
                .task {
                    await llmManager.loadModel()
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .background {
                        try? PersistenceController.shared.container.viewContext.save()
                    }
                }
        }
    }
}