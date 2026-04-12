import SwiftUI
import CoreData
import Combine

#if os(watchOS)
import WatchKit

struct StatusView: View {
    @ObservedObject var player: PlayerProfile
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 12) {
                    // 灵牌头部
                    Text("【 宗门玉牌 】")
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(Color(red: 0.8, green: 0.7, blue: 0.3)) // 古铜金
                        .padding(.top, 8)
                    
                    // 境界边框与核心展示
                    VStack {
                        Text(CultivationEngine.shared.realmName(for: player.realm))
                            .font(.system(size: 26, weight: .black, design: .serif))
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan.opacity(0.5), radius: 5)
                        
                        if let req = CultivationEngine.shared.requirementForNextRealm(currentLevel: player.realm) {
                            Text("\(player.cultivationBase) / \(req) 真气")
                                .font(.system(size: 10, weight: .medium, design: .serif))
                                .foregroundColor(.gray)
                                .padding(.top, 2)
                        } else {
                            Text("已满，天人合一阶段")
                                .font(.system(size: 11, design: .serif))
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
                    
                    // 突破大键
                    if CultivationEngine.shared.canBreakthrough(profile: player) {
                        NavigationLink(destination: TribulationView(player: player)) {
                            HStack {
                                Text("引天雷 / 破万法")
                                    .font(.system(.body, design: .serif))
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.black)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.9, green: 0.8, blue: 0.2))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("✧ 先天道基 (灵根资质)")
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(Color(red: 0.8, green: 0.7, blue: 0.3))
                        
                        Grid(horizontalSpacing: 8, verticalSpacing: 6) {
                            GridRow {
                                rootCell(label: "金", value: player.metalRoot)
                                rootCell(label: "木", value: player.woodRoot)
                            }
                            GridRow {
                                rootCell(label: "水", value: player.waterRoot)
                                rootCell(label: "火", value: player.fireRoot)
                            }
                            GridRow {
                                rootCell(label: "土", value: player.earthRoot)
                                rootCell(label: "机缘", value: player.lucky, isSpecial: true)
                            }
                        }
                        
                        Divider().background(Color.gray.opacity(0.3))
                        
                        HStack {
                            Text("根骨: \(player.boneRoot)").foregroundColor(.white)
                            Spacer()
                            Text("悟性: \(player.wisdom)").foregroundColor(.white)
                            Spacer()
                            Text("体魄: \(player.physique)").foregroundColor(.white)
                        }
                        .font(.system(size: 9))
                    }
                    .font(.system(size: 11, design: .serif))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color(white: 0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, 4)
                
                VStack(spacing: 4) {
                    Text("☯︎ 五行聚灵阵")
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(.cyan.opacity(0.8))
                        .padding(.top, 4)
                        
                    HStack(spacing: 8) {
                        ElementColumn(element: "金", value: player.metalQi, color: .orange)
                        ElementColumn(element: "木", value: player.woodQi, color: .green)
                        ElementColumn(element: "水", value: player.waterQi, color: .blue)
                        ElementColumn(element: "火", value: player.fireQi, color: .red)
                        ElementColumn(element: "土", value: player.earthQi, color: .brown)
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 6)
                }
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.12))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 4)
                .padding(.top, 6)
                
                Spacer(minLength: 20)
            }
        }
        .onAppear {
            CultivationEngine.shared.seedRoots(profile: player)
        }
        .navigationTitle("灵牌")
        .navigationBarTitleDisplayMode(.inline)
    }
    private func rootCell(label: String, value: Int16, isSpecial: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(isSpecial ? .yellow : .cyan.opacity(0.8))
            Text("\(value)%")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(4)
    }
}

struct ElementColumn: View {
    let element: String
    let value: Int64
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(element)
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(color)
            Text("\(value)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

// MARK: - 洞府系统 (Grotto)
struct GrottoView: View {
    @ObservedObject var player: PlayerProfile
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingGains = false
    @State private var lastGains: [String: Int64] = [:]
    
    var body: some View {
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

// MARK: - AlchemySection (高频更新隔离组件，防止污染主 ScrollView 性能)
struct AlchemySection: View {
    @ObservedObject var player: PlayerProfile
    @Environment(\.managedObjectContext) var moc
    
    // 内部状态完全隔离，不触发父视图重绘
    @State private var crownValue: Double = 0.0
    @State private var fireIntensity: Double = 0.0
    @State private var targetRange: ClosedRange<Double> = 0.4...0.6
    @State private var purification: Double = 0.0
    @State private var isAlchemizing = false
    @State private var showResult = false
    @State private var resultMessage = ""
    @FocusState private var isFocused: Bool
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 4) {
            Text("「 乾坤丹炉 」")
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundColor(.orange)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 4)
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: targetRange.lowerBound * 0.75, to: targetRange.upperBound * 0.75)
                    .stroke(Color.green.opacity(0.5), lineWidth: 8)
                    .rotationEffect(.degrees(135))
                    .frame(width: 80, height: 80)
                
                Capsule()
                    .fill(Color.red)
                    .frame(width: 4, height: 30)
                    .offset(y: -25)
                    .rotationEffect(.degrees((fireIntensity * 270) - 135))
                
                Circle()
                    .fill(RadialGradient(colors: [fireColor, .clear], center: .center, startRadius: 5, endRadius: 25))
                    .frame(width: 50, height: 50)
                    .scaleEffect(isAlchemizing ? 1.0 + (fireIntensity * 0.2) : 1.0)
            }
            .padding(.vertical, 2)
            
            VStack(spacing: 2) {
                HStack {
                    Text("提纯度")
                        .font(.system(size: 8))
                    Spacer()
                    Text("\(Int(purification * 100))%")
                        .font(.system(size: 8))
                }
                .foregroundColor(.gray)
                
                ProgressView(value: purification, total: 1.0)
                    .tint(.cyan)
                    .scaleEffect(y: 0.5)
            }
            .padding(.horizontal, 20)
            
            Button(action: {
                if isAlchemizing {
                    stopAlchemy()
                } else {
                    startAlchemy()
                }
            }) {
                Text(isAlchemizing ? "凝丹！" : "开启丹炉")
                    .font(.caption2)
            }
            .tint(isAlchemizing ? .red : .blue)
            .padding(.top, 2)
        }
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.02))
        .cornerRadius(12)
        .focusable(true)
        .focused($isFocused)
        .digitalCrownRotation($crownValue, from: 0, through: 1.0, by: 0.02, sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
        .onAppear {
            isFocused = true
        }
        .onReceive(timer) { _ in
            if isAlchemizing {
                updateAlchemy()
            }
        }
        .alert(isPresented: $showResult) {
            Alert(title: Text("炼丹告谕"), message: Text(resultMessage), dismissButton: .default(Text("知晓")))
        }
    }
    
    private var fireColor: Color {
        if fireIntensity < 0.3 { return .orange }
        if fireIntensity < 0.7 { return .red }
        return .purple
    }
    
    private func startAlchemy() {
        guard player.metalQi >= 50 && player.woodQi >= 50 && player.waterQi >= 50 && player.fireQi >= 50 && player.earthQi >= 50 else {
            resultMessage = "五行灵气不足以支撑开炉之火。"
            showResult = true
            return
        }
        
        isAlchemizing = true
        purification = 0
        targetRange = Double.random(in: 0.1...0.3)...Double.random(in: 0.7...0.9)
    }
    
    private func updateAlchemy() {
        fireIntensity += (crownValue - fireIntensity) * 0.3
        
        if targetRange.contains(fireIntensity) {
            purification += 0.005
            if purification >= 1.0 {
                stopAlchemy(success: true)
            }
        } else {
            purification = max(0, purification - 0.002)
            if fireIntensity < targetRange.lowerBound {
                WKInterfaceDevice.current().play(.directionUp)
            } else {
                WKInterfaceDevice.current().play(.directionDown)
            }
        }
    }
    
    private func stopAlchemy(success: Bool = false) {
        isAlchemizing = false
        if success {
            player.pillsCount += 1
            player.metalQi -= 50
            player.woodQi -= 50
            player.waterQi -= 50
            player.fireQi -= 50
            player.earthQi -= 50
            
            try? moc.save()
            resultMessage = "造化垂青，获得一枚「破境丹」！"
            WKInterfaceDevice.current().play(.success)
        } else if purification > 0 {
            resultMessage = "火候失准，未能成药。提纯度: \(Int(purification * 100))%"
            WKInterfaceDevice.current().play(.failure)
        }
        
        if resultMessage != "" {
            showResult = true
        }
    }
}

extension Color {
    static let emerald = Color(red: 0.1, green: 0.7, blue: 0.4)
}

#endif
