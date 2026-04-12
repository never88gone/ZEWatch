import Foundation
import Combine

struct CultivationMission {
    let id: UUID
    let title: String
    let description: String
    let targetType: MissionType
    let targetValue: Double
    let rewardCultivation: Int64
    var isCompleted: Bool = false
    
    enum MissionType {
        case steps
        case energy
        case mindfulness
    }
}

class MissionEngine: ObservableObject {
    static let shared = MissionEngine()
    
    @Published var currentMissions: [CultivationMission] = []
    
    private let stepTitles = [
        "天道之选", "凌空虚度", "气沉丹田", "脱胎换骨", "凝结金丹", "横跨八荒",
        "缩地成寸", "夸父追日", "万里奔袭", "踏雪无痕", "御剑飞行", "游历红尘"
    ]
    
    private let energyTitles = [
        "三昧真火", "筑基阳炎", "移山填海", "焚天煮海", "锻体金身", "雷火淬骨",
        "九转玄功", "燃血遁法", "凤凰涅槃", "熔炼虚空", "星辰变", "吞噬雷劫"
    ]
    
    func generateDailyMissions(for player: PlayerProfile) {
        var missions: [CultivationMission] = []
        let realmIndex = player.realm
        let realmMultiplier = Double(max(1, realmIndex + 1))
        
        // --- 1. 流派专属每日供奉奖励 ---
        let professionSum = player.bodyLevel + player.swordLevel + player.talismanLevel + player.alchemyLevel
        if professionSum > 4 { // >4 表示玩家有主动进阶职业
            let stipendReward = Int64(professionSum) * 1500 * Int64(max(1, realmIndex))
            
            missions.append(CultivationMission(
                id: UUID(),
                title: "【流派供奉】宗门俸禄",
                description: "宗门敬仰你在四大流派上的造诣（综合考核 \(professionSum) 阶），立刻领取今日特供给你的海量真气资源！",
                targetType: .steps,
                targetValue: 0, // 0步直接可领取
                rewardCultivation: stipendReward
            ))
        }
        
        // --- 2. 随机步数目标 ---
        let stepTarget = Double(Int.random(in: 1500...4000)) * realmMultiplier
        let stepTitle = stepTitles.randomElement()!
        let stepReward = Int64(stepTarget * 3.5 * realmMultiplier)
        
        missions.append(CultivationMission(
            id: UUID(),
            title: stepTitle,
            description: "今日需完成红尘游历 \(Int(stepTarget)) 步，以肉身丈量天道轨迹。",
            targetType: .steps,
            targetValue: stepTarget,
            rewardCultivation: stepReward
        ))
        
        // --- 3. 随机爆发卡路里目标 ---
        if realmIndex >= 2 {
            let energyTarget = Double(Int.random(in: 150...400)) * realmMultiplier
            let energyTitle = energyTitles.randomElement()!
            let energyReward = Int64(energyTarget * 18 * realmMultiplier)
            
            missions.append(CultivationMission(
                id: UUID(),
                title: energyTitle,
                description: "运动爆发燃烧 \(Int(energyTarget)) 灵力/卡路里，以此高温提炼无上纯源火种。",
                targetType: .energy,
                targetValue: energyTarget,
                rewardCultivation: energyReward
            ))
        }
        
        // --- 4. 稀有悬赏与隐藏机缘 ---
        let randVal = Int.random(in: 1...100)
        if randVal > 85 {
            missions.append(CultivationMission(
                id: UUID(),
                title: "【红色通缉】击拿上古魔王",
                description: "掌教急召！强行爆燃极高灵力，接下宗门的天级诛杀令！",
                targetType: .energy,
                targetValue: 1000 * realmMultiplier,
                rewardCultivation: Int64(80000 * realmMultiplier)
            ))
        } else if randVal < 10 {
            missions.append(CultivationMission(
                id: UUID(),
                title: "【机缘天降】顿悟小天地",
                description: "运气逆天，随意散步 1000 步便可直接消化这份天地福缘！",
                targetType: .steps,
                targetValue: 1000,
                rewardCultivation: Int64(30000 * realmMultiplier)
            ))
        }
        
        self.currentMissions = missions
    }
}
