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
    @AppStorage("hasShownHealthKitOnboarding") private var hasShownHealthKitOnboarding = false
    
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
                
                // HealthKit 引导 Overlay
                if !hasShownHealthKitOnboarding {
                    healthKitOnboardingView(player: player)
                        .zIndex(200)
                }
                #endif
            }
            .onAppear {
                if hasShownHealthKitOnboarding {
                    requestAndSync(player: player)
                }
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
                if newPhase == .active && hasShownHealthKitOnboarding {
                    requestAndSync(player: player)
                }
            }
        } else {
            CreationView()
        }
    }
    
    #if os(watchOS)
    private func healthKitOnboardingView(player: PlayerProfile) -> some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 8) {
                    // HealthKit 品牌标识（满足 Guideline 2.5.1）
                    HStack(spacing: 6) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.red)
                        Text("HealthKit")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                    }
                    .padding(.top, 10)
                    
                    Text("Apple Health 数据同步")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("本应用通过 Apple HealthKit 读取以下健康数据，转化为游戏内的「五行灵气」：")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                    
                    // 数据类型列表
                    VStack(alignment: .leading, spacing: 3) {
                        Label("步数 / 运动", systemImage: "figure.walk")
                        Label("睡眠分析", systemImage: "moon.zzz")
                        Label("心率", systemImage: "waveform.path.ecg")
                        Label("消耗卡路里", systemImage: "flame")
                    }
                    .font(.system(size: 10))
                    .foregroundColor(.cyan)
                    .padding(.vertical, 4)
                    
                    Text("所有数据仅在设备本地处理，绝不上传任何服务器。")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                    
                    // 修复：先发起 HealthKit 授权请求，在回调中再关闭引导页
                    // 之前逻辑：先关闭 overlay 再请求 → watchOS 上系统弹窗触发失败
                    Button(action: {
                        HealthManager.shared.requestAuthorization { success, error in
                            DispatchQueue.main.async {
                                withAnimation {
                                    hasShownHealthKitOnboarding = true
                                }
                                if success {
                                    Task {
                                        await HealthManager.shared.syncElements(to: player, context: viewContext)
                                        GameKitManager.shared.submitScore(score: player.cultivationBase)
                                        ConnectivityManager.shared.sendSyncData(player.toDictionary())
                                    }
                                }
                            }
                        }
                    }) {
                        Text("继续")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .padding(.top, 8)
                    
                    Text("若弹窗未出现，请在「设置 > 健康 > 应用」中手动开启")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)
                }
            }
        }
    }
    #endif
    
    private func requestAndSync(player: PlayerProfile) {
        // 结算洞府收益
        _ = CultivationEngine.shared.settleOfflineGains(profile: player, context: viewContext)
        
        HealthManager.shared.requestAuthorization { success, error in
            if success {
                Task {
                    await HealthManager.shared.syncElements(to: player, context: viewContext)
                    // 同步完灵气后，上传修为至排行榜
                    GameKitManager.shared.submitScore(score: player.cultivationBase)
                    // 同步完灵气后，将最新状态发送至 iOS 端触发 AI 叙事
                    ConnectivityManager.shared.sendSyncData(player.toDictionary())
                }
            } else {
                // 如果授权失败且没有错误，可能是之前拒绝过
                print("HealthKit Authorization failed: \(String(describing: error))")
            }
        }
    }
}
