import SwiftUI
import CoreData
import UIKit

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab: Int = 0
    
    @FetchRequest(
        sortDescriptors: [],
        animation: .default)
    private var profiles: FetchedResults<PlayerProfile>
    
    var body: some View {
        if let player = profiles.first {
            TabView(selection: $selectedTab) {
                DashboardView(player: player)
                    .tabItem {
                        Label("洞府", systemImage: "building.columns")
                    }
                    .tag(0)
                    .accessibilityIdentifier("tab_dashboard")

                AICompanionView(player: player, onGoToSettings: {
                    selectedTab = 2
                })
                .tabItem {
                    Label("识海", systemImage: "aqi.high")
                }
                .tag(1)
                .accessibilityIdentifier("tab_companion")
                
                CompanionSettingsView(player: player)
                    .tabItem {
                        Label("须弥戒", systemImage: "gearshape.fill")
                    }
                    .tag(2)
                    .accessibilityIdentifier("tab_settings")
            }
            .tint(.cultivPrimary)
            .preferredColorScheme(.dark)
            .onAppear {
                if let page = ProcessInfo.processInfo.environment["APPSTORE_PAGE"] {
                    switch page {
                    case "dongfu": selectedTab = 0
                    case "companion": selectedTab = 1
                    case "model_selection": selectedTab = 1
                    case "settings": selectedTab = 2
                    case "health_rules": selectedTab = 2
                    default: break
                    }
                }
            }
        } else {
            ZStack {
                Color.cultivBg.ignoresSafeArea()
                VStack(spacing: 20) {
                    ProgressView().tint(.cultivPrimary)
                    Text("开辟识海中...")
                        .font(.body)
                        .foregroundColor(.cultivMuted)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                createDefaultProfile()
            }
        }
    }
    
    private func createDefaultProfile() {
        let newProfile = PlayerProfile(context: viewContext)
        newProfile.realm = 1
        newProfile.cultivationBase = 0
        newProfile.boneRoot = 10
        newProfile.wisdom = 10
        newProfile.physique = 10
        newProfile.lucky = 10
        newProfile.bodyLevel = 1
        newProfile.swordLevel = 1
        newProfile.talismanLevel = 1
        newProfile.alchemyLevel = 1
        newProfile.metalQi = 0
        newProfile.woodQi = 0
        newProfile.waterQi = 0
        newProfile.fireQi = 0
        newProfile.earthQi = 0
        newProfile.metalRoot = 100
        newProfile.woodRoot = 100
        newProfile.waterRoot = 100
        newProfile.fireRoot = 100
        newProfile.earthRoot = 100
        newProfile.grottoLevel = 1
        newProfile.lastSettlementDate = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("创建初始修仙者档案失败: \(error)")
        }
    }
}