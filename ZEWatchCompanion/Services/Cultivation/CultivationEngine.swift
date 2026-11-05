import Foundation
import CoreData

public final class CultivationEngine: ObservableObject {
    public static let shared = CultivationEngine()
    
    private init() {}
    
    public func realmName(for level: Int16) -> String {
        let names = ["筑基", "开光", "融合", "心动", "金丹", "元婴", "出窍", "分神", "合体", "洞虚", "大乘", "渡劫"]
        let index = Int(level)
        return (index >= 0 && index < names.count) ? names[index] : "未知境界"
    }
    
    public func requirementForNextRealm(currentLevel: Int16) -> Int64? {
        if currentLevel >= 11 { return nil }
        return Int64(pow(10.0, Double(currentLevel + 2)))
    }
}
