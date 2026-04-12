import Foundation
import Combine
import SwiftUI

public struct CultivationEvent: Identifiable {
    public let id = UUID()
    public let tag: String
    public let description: String
    public let colorCode: String
}

public class EventEngine: ObservableObject {
    public static let shared = EventEngine()
    
    @Published public var randomLogs: [CultivationEvent] = []
    
    private let lowRealmEvents = [
        ("【奇遇】", "在后山瀑布下发现一株百年灵芝，气血翻涌。", "#34C759"),
        ("【险阻】", "遭遇三只一阶妖兽雪狼，边打边退险象环生。", "#FF3B30"),
        ("【顿悟】", "看云卷云舒，心境微动，似乎摸到了练气门槛。", "#00C7BE"),
        ("【坊市】", "在修仙坊市花光了盘缠，却只买到了假功法。", "#8E8E93"),
        ("【偶遇】", "遇到同门师出行的绝色师姐，你却低头匆匆走过。", "#AF52DE"),
        ("【日常】", "在杂役处劈柴挑水，虽然辛苦但筋骨越发结实。", "#8E8E93"),
        ("【灵植】", "自己种下的聚气草终于发芽了，开心了一整天。", "#34C759"),
        ("【争吵】", "和外门弟子发生了口角，忍一时风平浪静。", "#FF9F0A"),
        ("【捡漏】", "在后山草丛里捡到一个破旧的储物袋，里面有几块碎灵石。", "#FFD60A"),
        ("【风寒】", "修仙者也会感冒？夜里受了风寒，修为运转稍显迟滞。", "#FF3B30")
    ]
    
    private let midRealmEvents = [
        ("【斗法】", "路见魔修残杀凡人，果断拔剑，大战三百回合将其斩杀！", "#FF3B30"),
        ("【秘境】", "误入上古大能的洞府遗迹，虽九死一生但满载而归。", "#FFD60A"),
        ("【心魔】", "闭关时险些走火入魔，幸有清心咒护体，总算平息乱刃。", "#5E5CE6"),
        ("【坊市】", "在地下黑市重金淘到了一本残破的玄阶功法秘籍。", "#FF9F0A"),
        ("【炼器】", "拜访了器宗长老，求得一把趁手的飞剑，战力大增！", "#00C7BE"),
        ("【宗门】", "参加宗门大比，虽然止步六十四强，但也算崭露头角。", "#AF52DE"),
        ("【结怨】", "在秘境中为了夺宝，得罪了一个修仙世家的少主。", "#FF3B30"),
        ("【论道】", "与几位散修在悬崖边饮茶论道，对天地法则有了新感悟。", "#34C759"),
        ("【寻宝】", "根据一张破旧羊皮纸的指引，挖出了一座微型灵脉。", "#FFD60A"),
        ("【传音】", "收到了远方道友的万里传音符，邀请你去探寻洞府。", "#00C7BE")
    ]
    
    private let highRealmEvents = [
        ("【天劫】", "乌云压顶，似乎天道已察觉了你的逆天行径...", "#FF3B30"),
        ("【开宗】", "随手点化了一位凡界少年，他日后竟成为开派祖师。", "#34C759"),
        ("【虚空】", "撕裂空间屏障，前往域外战场猎杀星空异族！", "#AF52DE"),
        ("【化神】", "神游太虚，俯瞰整座修仙界，山川河流皆为蝼蚁。", "#00C7BE"),
        ("【斗法】", "与其他大能争夺天地异火，打得方圆百里山崩地裂。", "#FF3B30"),
        ("【炼虚】", "炼制了一具身外化身，代替自己巡视名山大川。", "#FF9F0A"),
        ("【讲道】", "在宗门主峰开坛讲道，引得万兽朝宗，天花乱坠。", "#FFD60A"),
        ("【法则】", "枯坐百年，终于触摸到了哪怕一丝的时间法则。", "#5E5CE6"),
        ("【飞升】", "隐隐感受到了上界的接引神光，飞升之日不远矣。", "#34C759"),
        ("【斩业】", "跨越大洲，一剑斩灭了一个作恶多端的万年魔宗。", "#FF3B30")
    ]
    
    public func generateEvents(forRealm realm: Int16, steps: Double) {
        var pool: [(String, String, String)] = []
        
        if realm <= 2 {
            pool = lowRealmEvents
        } else if realm <= 4 {
            pool = lowRealmEvents + midRealmEvents + midRealmEvents
        } else {
            pool = midRealmEvents + highRealmEvents + highRealmEvents
        }
        
        let eventCount = max(1, min(Int(steps / 1500), 8)) 
        
        var generated: [CultivationEvent] = []
        let shuffledPool = pool.shuffled()
        
        for i in 0..<min(eventCount, shuffledPool.count) {
            let item = shuffledPool[i]
            generated.append(CultivationEvent(tag: item.0, description: item.1, colorCode: item.2))
        }
        
        if steps < 500 {
            generated = [CultivationEvent(tag: "【闭关】", description: "终日闭关不出，洞府中仿佛结上了蛛网，岁月静好。", colorCode: "#8E8E93")]
        }
        
        self.randomLogs = generated
    }
}
