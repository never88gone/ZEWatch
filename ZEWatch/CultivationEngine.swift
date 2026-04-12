import Foundation
import CoreData
import GameKit
import UserNotifications
import Combine

#if os(watchOS)
import WatchKit
#endif

// MARK: - GameKit Manager (宗门排行榜)
@objc(GameKitManager)
public final class GameKitManager: NSObject, ObservableObject {
    public static let shared = GameKitManager()
    
    @Published public var isAuthenticated = false
    
    private let leaderboardID = "com.zewatch.cultivation.base"
    
    private override init() {
        super.init()
    }
    
    public func authenticateUser() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] (error) in
            self?.processAuthentication(error: error)
        }
    }
    
    private func processAuthentication(error: Error?) {
        if let error = error {
            print("GameCenter 验证失败: \(error.localizedDescription)")
            return
        }
        
        if GKLocalPlayer.local.isAuthenticated {
            DispatchQueue.main.async {
                self.isAuthenticated = true
            }
            print("GameCenter 验证成功")
        }
    }
    
    public func submitScore(score: Int64) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        GKLeaderboard.submitScore(Int(score), context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("分数提交失败: \(error.localizedDescription)")
            } else {
                print("修为已同步至宗门排行榜: \(score)")
            }
        }
    }
}

// MARK: - Notification Manager (生理奇遇)
@objc(NotificationManager)
public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    public static let shared = NotificationManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                self.setupNotificationCategories()
            }
        }
    }
    
    private func setupNotificationCategories() {
        let actionFight = UNNotificationAction(identifier: "ACTION_FIGHT", title: "仗剑迎敌", options: .foreground)
        let actionRun = UNNotificationAction(identifier: "ACTION_RUN", title: "暂避锋芒", options: .destructive)
        
        let categoryEncounter = UNNotificationCategory(
            identifier: "ENCOUNTER_CATEGORY",
            actions: [actionFight, actionRun],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([categoryEncounter])
    }
    
    public func triggerEncounter(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "ENCOUNTER_CATEGORY"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        
        #if os(watchOS)
        DispatchQueue.main.async {
            WKInterfaceDevice.current().play(.notification)
        }
        #endif
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == "ACTION_FIGHT" {
            NotificationCenter.default.post(name: NSNotification.Name("TriggerRandomEncounter"), object: nil)
        }
        completionHandler()
    }
}

// MARK: - Cultivation Engine (核心逻辑)
public class CultivationEngine {
    public static let shared = CultivationEngine()
    
    // 境界名称
    public let realms = ["凡人", "炼气", "筑基", "金丹", "元婴", "化神", "渡劫"]
    
    // 每个阶段突破所需真气 (修为)
    public let requirements: [Int64] = [
        1000,      // 凡人 -> 炼气
        5000,      // 炼气 -> 筑基
        20000,     // 筑基 -> 金丹
        100000,    // 金丹 -> 元婴
        500000,    // 元婴 -> 化神
        2000000    // 化神 -> 渡劫
    ]
    
    private init() {}
    
    // MARK: - 属性生成
    public func generateInitialProfile(context: NSManagedObjectContext) -> PlayerProfile {
        let profile = PlayerProfile(context: context)
        // 核心属性
        profile.boneRoot = Int16.random(in: 40...100)
        profile.wisdom = Int16.random(in: 40...100)
        profile.lucky = Int16.random(in: 10...100)
        profile.physique = Int16.random(in: 40...100)
        
        // 五行灵根随机 (10~150% 资质)
        profile.metalRoot = Int16.random(in: 10...150)
        profile.woodRoot = Int16.random(in: 10...150)
        profile.waterRoot = Int16.random(in: 10...150)
        profile.fireRoot = Int16.random(in: 10...150)
        profile.earthRoot = Int16.random(in: 10...150)
        
        profile.realm = 0 // 凡人
        profile.cultivationBase = 0
        profile.lastSettlementDate = Date()
        profile.grottoLevel = 1
        return profile
    }
    
    /// 给存量老玩家补全灵根资质与洞府属性 (默认 100 代表 100%)
    public func seedRoots(profile: PlayerProfile) {
        if profile.metalRoot == 0 { profile.metalRoot = 100 }
        if profile.woodRoot == 0 { profile.woodRoot = 100 }
        if profile.waterRoot == 0 { profile.waterRoot = 100 }
        if profile.fireRoot == 0 { profile.fireRoot = 100 }
        if profile.earthRoot == 0 { profile.earthRoot = 100 }
        
        if profile.grottoLevel == 0 { profile.grottoLevel = 1 }
        if profile.lastSettlementDate == nil { profile.lastSettlementDate = Date() }
    }
    
    // MARK: - 洞府闭关 (离线收益)
    
    /// 计算预计离线收益
    public func calculateOfflineGains(profile: PlayerProfile) -> [String: Int64] {
        guard let lastDate = profile.lastSettlementDate else {
            return [:]
        }
        
        let interval = Date().timeIntervalSince(lastDate)
        let minutes = max(0, interval / 60.0)
        
        // 基础效率：每分钟收益 = (境界 + 1) * 2.0
        let baseEfficiency = Double(profile.realm + 1) * 2.0
        
        // 洞府加成：每级增加 10%
        let grottoMult = 1.0 + Double(max(0, profile.grottoLevel - 1)) * 0.1
        
        // 资质加成 (取根骨与悟性的均值)
        let rootMult = Double(profile.boneRoot + profile.wisdom) / 200.0
        
        let totalQi = Int64(minutes * baseEfficiency * grottoMult * rootMult)
        
        // 平均分配到五行 (简单起见)
        let share = totalQi / 5
        return [
            "metal": share, "wood": share, "water": share, "fire": share, "earth": share
        ]
    }
    
    /// 执行出关结算
    public func settleOfflineGains(profile: PlayerProfile, context: NSManagedObjectContext) -> [String: Int64] {
        // 如果没有时间戳，则初始化为当前，退出
        guard let lastDate = profile.lastSettlementDate else {
            profile.lastSettlementDate = Date()
            try? context.save()
            return [:]
        }
        
        let gains = calculateOfflineGains(profile: profile)
        
        // 增加灵气
        profile.metalQi += gains["metal"] ?? 0
        profile.woodQi += gains["wood"] ?? 0
        profile.waterQi += gains["water"] ?? 0
        profile.fireQi += gains["fire"] ?? 0
        profile.earthQi += gains["earth"] ?? 0
        
        // 更新结算时间
        profile.lastSettlementDate = Date()
        
        do {
            try context.save()
            return gains
        } catch {
            print("Failed to save grotto gains: \(error)")
            return [:]
        }
    }
    
    // MARK: - 境界突破 (渡劫风险)
    public func breakthrough(profile: PlayerProfile, context: NSManagedObjectContext) -> (success: Bool, message: String) {
        guard canBreakthrough(profile: profile) else {
            return (false, "感悟不足，强行突破必遭反噬。")
        }
        
        // 成功率计算：基础 95% - (境界 * 10%) + (悟性/机缘补偿)
        var baseChance = 0.95 - (Double(profile.realm) * 0.10)
        let bonus = Double(profile.wisdom + profile.lucky) / 2000.0 // 最高 +10%
        
        // 丹药加成
        var pillMsg = ""
        if profile.pillsCount > 0 {
            profile.pillsCount -= 1
            baseChance += 0.15 // 丹药强行提升 15% 成功率
            pillMsg = "（已服用破境丹，成功率提升）"
        }
        
        // 天气影响
        let weatherBuff = WeatherEngine.shared.currentBuff(for: WeatherManager.shared.currentWeather)
        let weatherBonus = weatherBuff.breakthroughBonus
        
        let finalChance = max(0.2, min(0.99, baseChance + bonus + weatherBonus))
        
        // 触发雷劫特效通知 (UI 层监听页面展示 SpriteKit)
        NotificationCenter.default.post(name: Notification.Name("ShowThunderTribulation"), object: nil)
        
        let roll = Double.random(in: 0...1)
        let weatherMsg = weatherBonus != 0 ? "（受到天理感知影响）" : ""
        
        if roll <= finalChance {
            // 突破成功
            profile.realm += 1
            profile.cultivationBase = 0 // 破境后法力提纯，修为归零重新开始
            try? context.save()
            return (true, "【突破成功】！\(pillMsg)\(weatherMsg) 恭喜晋级 \(realmName(for: profile.realm))！")
        } else {
            // 突破失败：修为受损
            // 雷暴等极端天气下，惩罚翻倍
            let penaltyMult = weatherBonus < -0.1 ? 2.0 : 1.0
            let penalty = Int64(Double(profile.cultivationBase) * 0.2 * penaltyMult)
            profile.cultivationBase = max(0, profile.cultivationBase - penalty)
            try? context.save()
            
            let failPrefix = penaltyMult > 1.0 ? "【天劫无情】！" : "【破境失败】！"
            return (false, "\(failPrefix)\(pillMsg)\(weatherMsg) 天雷轰顶，神魂动荡，损失了 \(penalty) 点修为...")
        }
    }
    
    // MARK: - 修为转化 (步数与正念)
    public func calculateCultivation(fromSteps steps: Double, profile: PlayerProfile) -> Int64 {
        // 基础转化：10步 = 1 点修为
        let base = steps / 10.0
        
        // 根骨加成：每点根骨提升 0.5% 的转化效率
        let bonus = 1.0 + (Double(profile.boneRoot) * 0.005)
        
        return Int64(base * bonus)
    }
    
    public func calculateCultivation(fromMindfulness minutes: Double, profile: PlayerProfile) -> Int64 {
        // 打坐转化效率更高：1分钟 = 50 点修为
        let base = minutes * 50.0
        // 悟性加成
        let bonus = 1.0 + (Double(profile.wisdom) * 0.005)
        
        return Int64(base * bonus)
    }
    
    // MARK: - 境界判断
    public func realmName(for level: Int16) -> String {
        let index = Int(level)
        guard index >= 0 && index < realms.count else { return "未知境界" }
        return realms[index]
    }
    
    public func requirementForNextRealm(currentLevel: Int16) -> Int64? {
        let index = Int(currentLevel)
        guard index >= 0 && index < requirements.count else { return nil }
        return requirements[index]
    }
    
    public func canBreakthrough(profile: PlayerProfile) -> Bool {
        guard let req = requirementForNextRealm(currentLevel: profile.realm) else { return false }
        return profile.cultivationBase >= req
    }
}
