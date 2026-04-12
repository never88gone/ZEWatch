import SwiftUI
import CoreData
import SpriteKit

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase
    
    @FetchRequest(
        entity: PlayerProfile.entity(),
        sortDescriptors: [],
        animation: .default)
    private var profiles: FetchedResults<PlayerProfile>
    
    @State private var showThunderstorm = false
    
    var body: some View {
        if let player = profiles.first {
            ZStack {
                #if os(watchOS)
                // 已有角色，进入主游戏界面，遵守表腕界面的横滑 TabView 原则
                TabView {
                    NavigationStack {
                        WatchFaceView(player: player)
                    }
                    .tabItem { Label("本命", systemImage: "clock.badge.eye") }
                    
                    NavigationStack {
                        AlchemySection(player: player)
                    }
                    .tabItem { Label("丹房", systemImage: "laurel.leading") }
                    
                    NavigationStack {
                        StatusView(player: player)
                    }
                    .tabItem { Label("灵牌", systemImage: "person.crop.circle") }
                    
                    NavigationStack {
                        GrottoView(player: player)
                    }
                    .tabItem { Label("洞府", systemImage: "house.fill") }
                    
                    NavigationStack {
                        MissionView(player: player)
                    }
                    .tabItem { Label("试炼", systemImage: "scroll.fill") }
                    
                    NavigationStack {
                        TrainingView(player: player)
                    }
                    .tabItem { Label("修行", systemImage: "flame.fill") }
                    
                    NavigationStack {
                        ExplorationView(player: player)
                    }
                    .tabItem { Label("游历", systemImage: "map.fill") }
                    
                    NavigationStack {
                        SkillLibraryView(player: player)
                    }
                    .tabItem { Label("藏经阁", systemImage: "books.vertical.fill") }
                }
                
                // 全屏雷劫 Overlay
                if showThunderstorm {
                    SpriteView(scene: ThunderboltScene(size: CGSize(width: 200, height: 200)))
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(100)
                }
                #endif
            }
            .onAppear {
                requestAndSync(player: player)
                // 初始化社交与通知
                GameKitManager.shared.authenticateUser()
                NotificationManager.shared.requestAuthorization()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowThunderTribulation"))) { _ in
                #if os(watchOS)
                withAnimation {
                    showThunderstorm = true
                }
                // 3秒后自动消失
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        showThunderstorm = false
                    }
                }
                #endif
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    requestAndSync(player: player)
                }
            }
        } else {
            CreationView()
        }
    }
    
    private func requestAndSync(player: PlayerProfile) {
        // 结算洞府收益
        _ = CultivationEngine.shared.settleOfflineGains(profile: player, context: viewContext)
        
        HealthManager.shared.requestAuthorization { success in
            if success {
                Task {
                    await HealthManager.shared.syncElements(to: player, context: viewContext)
                    // 同步完灵气后，上传修为至排行榜
                    GameKitManager.shared.submitScore(score: player.cultivationBase)
                    // 同步完灵气后，将最新状态发送至 iOS 端触发 AI 叙事
                    ConnectivityManager.shared.sendSyncData(player.toDictionary())
                }
            }
        }
    }
}
