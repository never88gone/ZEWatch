import Foundation
import CoreData
import HealthKit
import Combine
import SwiftUI

// MARK: - 静态功法典籍数据库 (Skill Catalog)
struct SkillTemplate {
    let name: String
    let type: Int16       // 0=被动心法, 1=主动真诀
    let element: String
    let cost: Int64
    let desc: String      // 供 UI 展示时的简介
}

let skillCatalog: [SkillTemplate] = [
    // 被动心法
    SkillTemplate(name: "青木长生诀",  type: 0, element: "木", cost: 500,   desc: "木系灵气结算效率永久 +25%。"),
    SkillTemplate(name: "太白金煞诀",  type: 0, element: "金", cost: 500,   desc: "金系灵气结算效率永久 +25%。"),
    SkillTemplate(name: "玄冥水府经",  type: 0, element: "水", cost: 500,   desc: "水系灵气（梦道）结算效率永久 +30%。"),
    SkillTemplate(name: "赤焰烈日操",  type: 0, element: "火", cost: 500,   desc: "火系灵气结算效率永久 +25%。"),
    SkillTemplate(name: "厚土玄黄功",  type: 0, element: "土", cost: 500,   desc: "土系灵气结算效率永久 +25%。"),
    SkillTemplate(name: "混元五行心诀",type: 0, element: "土", cost: 2000,  desc: "修炼任何运动时，各属性灵气各额外获得 10%。"),
    // 主动真诀
    SkillTemplate(name: "燃血遁法",    type: 1, element: "火", cost: 3000,  desc: "激活后需在 5 分钟内将心率维持于燃脂区（>140 bpm）。成功：+5000 修为。失败：扣除 1000 修为反噬。"),
    SkillTemplate(name: "疾风剑罡",    type: 1, element: "金", cost: 2000,  desc: "激活后百步冲刺（30 秒高强度跑），完成后斩获大量金系灵气。"),
    SkillTemplate(name: "归元打坐",    type: 0, element: "水", cost: 800,   desc: "检测到 10 分钟以上正念冥想时，水系灵气加倍入账。"),
]

// MARK: - 技能播种器 (首次安装时调用)
class SkillActionEngine: ObservableObject {
    static let shared = SkillActionEngine()
    
    // 是否有主动功法正在燃烧
    @Published var activeSkillName: String? = nil
    @Published var activeSkillResult: String = ""
    
    private var heartRateObserver: HKObserverQuery?
    private var workoutDetectionTimer: Timer?
    private var heartRateBuffer: [Double] = []
    private var activationTime: Date?
    private let requiredDuration: TimeInterval = 300 // 5分钟
    private let heartRateThreshold: Double = 140.0
    
    private init() {}
    
    // MARK: - 播种初始功法典库
    func seedSkillsIfNeeded(for profile: PlayerProfile, context: NSManagedObjectContext) {
        let existingSkills = (profile.skills as? Set<SkillManual>) ?? []
        guard existingSkills.isEmpty else { return }
        
        for template in skillCatalog {
            let skill = SkillManual(context: context)
            skill.id = UUID().uuidString
            skill.name = template.name
            skill.skillType = template.type
            skill.elementReq = template.element
            skill.costAmount = template.cost
            skill.isUnlocked = false
            skill.level = 1
            skill.profile = profile
        }
        
        try? context.save()
        print("功法典籍已落库！共收录 \(skillCatalog.count) 项秘传功法！")
    }
    
    // MARK: - 解锁功法 (灵气交易)
    func unlockSkill(_ skill: SkillManual, profile: PlayerProfile, context: NSManagedObjectContext) -> String {
        guard !skill.isUnlocked else { return "你早已习得此功法，无需重修。" }
        guard let elementReq = skill.elementReq else { return "功法数据残缺，无法习得。" }
        
        // 检查是否有足够的对应五行灵气
        let currentQi = getQi(element: elementReq, from: profile)
        guard currentQi >= skill.costAmount else {
            return "【\(elementReq)】系灵气不足！需 \(skill.costAmount) 点，现有 \(currentQi) 点。"
        }
        
        // 扣除灵气
        deductQi(amount: skill.costAmount, element: elementReq, from: profile)
        skill.isUnlocked = true
        
        try? context.save()
        return "【\(skill.name ?? "")】习得成功！感悟一门天地奇功！"
    }
    
    // MARK: - 升级功法 (消耗翻倍)
    func upgradeSkill(_ skill: SkillManual, profile: PlayerProfile, context: NSManagedObjectContext) -> String {
        guard skill.isUnlocked else { return "尚未习得此功法，无法升级。" }
        guard skill.level < 10 else { return "此功法已达第十层大圆满，进无可进。" }
        guard let elementReq = skill.elementReq else { return "功法属性不明，无法进阶。" }
        
        // 升级费用公式：初始费用 * (1.5 ^ (当前等级 - 1))
        let nextLevel = Double(skill.level)
        let upgradeCost = Int64(Double(skill.costAmount) * pow(1.5, nextLevel))
        
        let currentQi = getQi(element: elementReq, from: profile)
        guard currentQi >= upgradeCost else {
            return "【\(elementReq)】系灵气不足！需 \(upgradeCost) 点以突破至第 \(skill.level + 1) 层。"
        }
        
        // 扣除灵气并升级
        deductQi(amount: upgradeCost, element: elementReq, from: profile)
        skill.level += 1
        
        try? context.save()
        return "【\(skill.name ?? "")】突破成功！晋升至第 \(skill.level) 层，威能大增！"
    }
    
    private func getQi(element: String, from profile: PlayerProfile) -> Int64 {
        switch element {
        case "金": return profile.metalQi
        case "木": return profile.woodQi
        case "水": return profile.waterQi
        case "火": return profile.fireQi
        default:   return profile.earthQi
        }
    }
    
    private func deductQi(amount: Int64, element: String, from profile: PlayerProfile) {
        switch element {
        case "金": profile.metalQi = max(0, profile.metalQi - amount)
        case "木": profile.woodQi = max(0, profile.woodQi - amount)
        case "水": profile.waterQi = max(0, profile.waterQi - amount)
        case "火": profile.fireQi = max(0, profile.fireQi - amount)
        default:   profile.earthQi = max(0, profile.earthQi - amount)
        }
    }
    
    // MARK: - 主动功法激活：燃血遁法
    @MainActor
    func activateBloodBurning(profile: PlayerProfile, context: NSManagedObjectContext) {
        guard activeSkillName == nil else {
            activeSkillResult = "已有功法在运行中！"
            return
        }
        activeSkillName = "燃血遁法"
        activationTime = Date()
        heartRateBuffer = []
        activeSkillResult = "燃血遁法激活！5分钟内维持心率 >\(Int(heartRateThreshold)) bpm..."
        
        // 启动心率监听
        startHeartRateMonitoring(profile: profile, context: context)
        
        // 设置5分钟裁决计时器
        workoutDetectionTimer = Timer.scheduledTimer(withTimeInterval: requiredDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.judgeBloodBurning(profile: profile, context: context)
            }
        }
    }
    
    private func startHeartRateMonitoring(profile: PlayerProfile, context: NSManagedObjectContext) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let healthStore = HKHealthStore()
        
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] _, _, error in
            guard error == nil else { return }
            // 获取最新心率
            let hrQuery = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1,
                                        sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, _ in
                if let sample = samples?.first as? HKQuantitySample {
                    let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    DispatchQueue.main.async {
                        self?.heartRateBuffer.append(bpm)
                    }
                }
            }
            healthStore.execute(hrQuery)
        }
        heartRateObserver = query
        healthStore.execute(query)
    }
    
    @MainActor
    private func judgeBloodBurning(profile: PlayerProfile, context: NSManagedObjectContext) {
        // 停止监听
        stopHeartRateMonitoring()
        
        let avgHR = heartRateBuffer.isEmpty ? 0 : heartRateBuffer.reduce(0, +) / Double(heartRateBuffer.count)
        
        if avgHR >= heartRateThreshold {
            // 成功！
            profile.cultivationBase += 5000
            activeSkillResult = "「燃血遁法」大成！\n平均心率 \(Int(avgHR)) bpm。\n斩获 +5000 修为！"
        } else {
            // 反噬
            let penalty: Int64 = 1000
            profile.cultivationBase = max(0, profile.cultivationBase - penalty)
            activeSkillResult = "功法反噬！平均心率仅 \(Int(avgHR)) bpm，\n真气逆流，损失 \(penalty) 修为！"
        }
        
        try? context.save()
        activeSkillName = nil
    }
    
    private func stopHeartRateMonitoring() {
        workoutDetectionTimer?.invalidate()
        workoutDetectionTimer = nil
        if let q = heartRateObserver {
            HKHealthStore().stop(q)
        }
        heartRateObserver = nil
    }
}
