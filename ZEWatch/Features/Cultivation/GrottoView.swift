import SwiftUI
import CoreData

#if os(watchOS)
import WatchKit

// MARK: - 洞府系统 (Grotto)
public struct GrottoView: View {
    @ObservedObject var player: PlayerProfile
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingGains = false
    @State private var lastGains: [String: Int64] = [:]
    
    public init(player: PlayerProfile) {
        self.player = player
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 洞府主视觉
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(LinearGradient(colors: [.black, Color(white: 0.15)], startPoint: .top, endPoint: .bottom))
                        .frame(height: 80)
                    
                    VStack {
                        Text("【 洞 府 】")
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(.gray)
                        Text(grottoName)
                            .font(.system(size: 20, weight: .black, design: .serif))
                            .foregroundColor(.emerald)
                            .shadow(color: .emerald.opacity(0.5), radius: 5)
                        Text("等级: \(player.grottoLevel)")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // 效率面板
                VStack(alignment: .leading, spacing: 6) {
                    Text("✧ 灵气汇聚效率")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                    
                    let efficiency = calculateEfficiency()
                    HStack {
                        Text("\(String(format: "%.1f", efficiency))")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                        Text("灵气 / 分钟")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    
                    Text("受 境界(x\(player.realm + 1))、资质(x\(String(format: "%.1f", Double(player.boneRoot + player.wisdom)/200.0))) 影响")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
                
                // 升级逻辑
                let upgradeCost = Int64(pow(2.0, Double(player.grottoLevel)) * 500)
                Button(action: upgradeGrotto) {
                    VStack {
                        Text("扩建聚灵阵")
                            .font(.system(size: 14, weight: .bold))
                        Text("需消耗五行灵气各 \(upgradeCost)")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.emerald)
                .disabled(!canUpgrade(cost: upgradeCost))
                
                Spacer(minLength: 10)
                
                Text("“闭关修炼，乃逆天而行，需戒骄戒躁。”")
                    .font(.system(size: 9, design: .serif))
                    .italic()
                    .foregroundColor(.gray)
                    .padding(.top, 10)
            }
            .padding()
        }
        .onAppear {
            autoSettle()
        }
        .alert("出关大吉", isPresented: $showingGains) {
            Button("善") { showingGains = false }
        } message: {
            if !lastGains.isEmpty {
                let total = lastGains.values.reduce(0, +)
                Text("本次闭关收益总计：\(total) 灵气\n(五行均匀分配)")
            } else {
                Text("道友刚刚才出过关，灵气尚未汇聚。")
            }
        }
    }
    
    private var grottoName: String {
        switch player.grottoLevel {
        case 1...3: return "简朴石室"
        case 4...6: return "聚灵宝塔"
        case 7...9: return "洞天福地"
        default: return "太虚仙径"
        }
    }
    
    private func calculateEfficiency() -> Double {
        let base = Double(player.realm + 1) * 2.0
        let grottoMult = 1.0 + Double(max(0, player.grottoLevel - 1)) * 0.1
        let rootMult = Double(player.boneRoot + player.wisdom) / 200.0
        return base * grottoMult * rootMult
    }
    
    private func canUpgrade(cost: Int64) -> Bool {
        return player.metalQi >= cost &&
               player.woodQi >= cost &&
               player.waterQi >= cost &&
               player.fireQi >= cost &&
               player.earthQi >= cost
    }
    
    private func upgradeGrotto() {
        let cost = Int64(pow(2.0, Double(player.grottoLevel)) * 500)
        guard canUpgrade(cost: cost) else { return }
        
        player.metalQi -= cost
        player.woodQi -= cost
        player.waterQi -= cost
        player.fireQi -= cost
        player.earthQi -= cost
        player.grottoLevel += 1
        
        try? viewContext.save()
        WKInterfaceDevice.current().play(.success)
    }
    
    private func autoSettle() {
        let gains = CultivationEngine.shared.settleOfflineGains(profile: player, context: viewContext)
        if (gains["metal"] ?? 0) > 0 {
            lastGains = gains
            showingGains = true
        }
    }
}
#endif
