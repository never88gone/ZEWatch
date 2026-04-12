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
    @NSManaged public var bodyLevel: Int16
    @NSManaged public var swordLevel: Int16
    @NSManaged public var talismanLevel: Int16
    @NSManaged public var alchemyLevel: Int16
    
    @NSManaged public var metalQi: Int64
    @NSManaged public var woodQi: Int64
    @NSManaged public var waterQi: Int64
    @NSManaged public var fireQi: Int64
    @NSManaged public var earthQi: Int64
    
    @NSManaged public var metalRoot: Int16
    @NSManaged public var woodRoot: Int16
    @NSManaged public var waterRoot: Int16
    @NSManaged public var fireRoot: Int16
    @NSManaged public var earthRoot: Int16
    
    @NSManaged public var lastSettlementDate: Date?
    @NSManaged public var grottoLevel: Int16
    @NSManaged public var pillsCount: Int16
    
    @NSManaged public var skills: NSSet?
    
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
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var skillType: Int16
    @NSManaged public var elementReq: String?
    @NSManaged public var costAmount: Int64
    @NSManaged public var isUnlocked: Bool
    @NSManaged public var level: Int16
    @NSManaged public var profile: PlayerProfile?
}
