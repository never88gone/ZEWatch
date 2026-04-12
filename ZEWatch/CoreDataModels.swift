import Foundation
import CoreData

@objc(PlayerProfile)
public class PlayerProfile: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var realm: Int16
    @NSManaged public var cultivationBase: Int64
    @NSManaged public var boneRoot: Int16
    @NSManaged public var wisdom: Int16
    @NSManaged public var physique: Int16
    @NSManaged public var lucky: Int16
    @NSManaged public var bodyLevel: Int16     // 体修流派等级
    @NSManaged public var swordLevel: Int16    // 剑修流派等级
    @NSManaged public var talismanLevel: Int16 // 符箓流派等级
    @NSManaged public var alchemyLevel: Int16  // 炼丹流派等级
    
    // 五行灵根真气池 (The Elements Engine)
    @NSManaged public var metalQi: Int64       // 金
    @NSManaged public var woodQi: Int64        // 木
    @NSManaged public var waterQi: Int64       // 水
    @NSManaged public var fireQi: Int64        // 火
    @NSManaged public var earthQi: Int64       // 土
    
    @NSManaged public var metalRoot: Int16     // 金灵根 (资质百分比)
    @NSManaged public var woodRoot: Int16      // 木灵根
    @NSManaged public var waterRoot: Int16     // 水灵根
    @NSManaged public var fireRoot: Int16      // 火灵根
    @NSManaged public var earthRoot: Int16     // 土灵根
    
    @NSManaged public var lastSettlementDate: Date? // 上次结算时间
    @NSManaged public var grottoLevel: Int16         // 洞府等级
    @NSManaged public var pillsCount: Int16          // 拥有的破境丹数量
    
    @NSManaged public var skills: NSSet?       // 功法关联 (One-to-Many)
    
    // 转换为字典以便 WCSession 发送
    public func toDictionary() -> [String: Any] {
        return [
            "realm": realm,
            "cultivationBase": cultivationBase,
            "boneRoot": boneRoot,
            "wisdom": wisdom,
            "physique": physique,
            "lucky": lucky,
            "bodyLevel": bodyLevel,
            "swordLevel": swordLevel,
            "talismanLevel": talismanLevel,
            "metalQi": metalQi,
            "woodQi": woodQi,
            "waterQi": waterQi,
            "fireQi": fireQi,
            "earthQi": earthQi,
            "grottoLevel": grottoLevel
        ]
    }
}

@objc(SkillManual)
public class SkillManual: NSManagedObject {
    @NSManaged public var id: String?        // 功法唯一ID (String for CoreData compatibility)
    @NSManaged public var name: String?        // 功法名称，如“燃血遁法”
    @NSManaged public var skillType: Int16     // 0 = 被动加成, 1 = 主动真诀
    @NSManaged public var elementReq: String?  // 属性标识，如“火”
    @NSManaged public var costAmount: Int64    // 兑换花费灵气
    @NSManaged public var isUnlocked: Bool     // 是否已习得
    @NSManaged public var level: Int16         // 功法层级
    
    @NSManaged public var profile: PlayerProfile? // 回溯关联
}

@objc(CultivationLog)
public class CultivationLog: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var gains: Int64
    @NSManaged public var eventDesc: String?
}
