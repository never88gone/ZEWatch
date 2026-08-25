import SwiftUI
import CoreData
import UIKit

// MARK: - 修仙配色系统 (Retro-Futurism Dark Mystical)
// Primary:    #7C3AED (修仙紫)
// Secondary:  #A78BFA (淡紫)
// CTA/Accent: #F43F5E (玫红)
// Background: #0F0F23 (深邃暗蓝)
// Text:       #E2E8F0 (月白)
extension Color {
    static let cultivPrimary   = Color(red: 0.486, green: 0.227, blue: 0.929)  // #7C3AED
    static let cultivSecondary = Color(red: 0.655, green: 0.545, blue: 0.980)  // #A78BFA
    static let cultivAccent    = Color(red: 0.957, green: 0.247, blue: 0.369)  // #F43F5E
    static let cultivBg        = Color(red: 0.059, green: 0.059, blue: 0.137)  // #0F0F23
    static let cultivText      = Color(red: 0.886, green: 0.910, blue: 0.941)  // #E2E8F0
    static let cultivMuted     = Color(red: 0.580, green: 0.600, blue: 0.680)  // 辅助灰
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [],
        animation: .default)
    private var profiles: FetchedResults<PlayerProfile>
    
    var body: some View {
        if let player = profiles.first {
            TabView {
                DashboardView(player: player)
                    .tabItem {
                        Label("洞府", systemImage: "building.columns")
                    }
                
                AICompanionView(player: player)
                    .tabItem {
                        Label("识海", systemImage: "aqi.high")
                    }
                
                CompanionSettingsView(player: player)
                    .tabItem {
                        Label("须弥戒", systemImage: "gearshape.fill")
                    }
            }
            .tint(.cultivPrimary)
            .preferredColorScheme(.dark)
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