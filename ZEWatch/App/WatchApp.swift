import SwiftUI
import CoreData

@main
struct WatchApp: App {
    let persistenceController = PersistenceController.shared
    let connectivityManager = ConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(HealthManager.shared)
        }
    }
}
