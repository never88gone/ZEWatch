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
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .background {
                        try? PersistenceController.shared.container.viewContext.save()
                    }
                }
        }
    }
}
