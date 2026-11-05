import SwiftUI
import Combine
import CoreData

#if os(watchOS)
import WatchKit

struct TribulationView: View {
    @ObservedObject var player: PlayerProfile
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    
    @State private var crownValue: Double = 50.0
    @State private var progress: CGFloat = 0.0
    @State private var result: (success: Bool, message: String)? = nil
    @FocusState private var isFocused: Bool
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 10) {
                if let res = result {
                    // 结果展示
                    Image(systemName: res.success ? "sun.max.fill" : "cloud.bolt.rain.fill")
                        .font(.system(size: 40))
                        .foregroundColor(res.success ? .yellow : .purple)
                        .symbolEffect(.pulse)
                    
                    Text(res.success ? "【 劫 云 消 散 】" : "【 功 亏 一 篑 】")
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(res.success ? .green : .red)
                    
                    Text(res.message)
                        .font(.system(size: 10, design: .serif))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: { dismiss() }) {
                        Text(res.success ? "稳固道基" : "抱憾出关")
                            .font(.system(.body, design: .serif))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(res.success ? .green : .red)
                    .padding(.top, 5)
                } else {
                    // 小游戏进行中
                    Text("以身扛天劫")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.purple)
                        .shadow(color: .purple.opacity(0.8), radius: 4)
                    
                    Text(progress > 0 ? "转动表冠，逆乱阴阳，护住心脉" : "屏息凝神，阴阳游标即将出现...")
                        .font(.system(size: 10, design: .serif))
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)
                    
                    ZStack {
                        // 护体安全阵法圈
                        Rectangle()
                            .fill(LinearGradient(colors: [.black, .green.opacity(0.3), .black], startPoint: .top, endPoint: .bottom))
                            .frame(width: 40, height: 80)
                            .border(Color.green.opacity(0.5), width: 1)
                        
                        // 游标 (奔涌的劫雷)
                        Rectangle()
                            .fill(LinearGradient(colors: [.red, .yellow, .red], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 50, height: 3)
                            .offset(y: CGFloat((crownValue - 50) * 0.7))
                            .shadow(color: .yellow, radius: 5)
                    }
                    .focusable(true)
                    .focused($isFocused)
                    .digitalCrownRotation($crownValue, from: 0, through: 100, by: 5, sensitivity: .high, isContinuous: false, isHapticFeedbackEnabled: true)
                    .onAppear {
                        isFocused = true
                    }
                    
                    ProgressView(value: progress, total: 1.0)
                        .tint(LinearGradient(colors: [.red, .purple], startPoint: .leading, endPoint: .trailing))
                        .scaleEffect(y: 1.2)
                        .padding(.horizontal, 15)
                    
                    Text("当前成功率: \(calcChance())%")
                        .font(.system(size: 8))
                        .foregroundColor(.orange.opacity(0.7))
                }
            }
        }
        .onReceive(timer) { _ in
            guard result == nil else { return }
            
            // 劫雷游移机制 (随境界提升复杂度)
            let driftRange = 5.0 + Double(player.realm) * 2.0
            let drift = Double.random(in: -driftRange...driftRange)
            crownValue = min(max(crownValue + drift, 0), 100)
            
            // 安全区停驻范围 40-60，积攒突破进度
            if crownValue > 40 && crownValue < 60 {
                progress += 0.02
                if progress >= 1.0 { triggerFinalCheck() }
            } else {
                progress = max(0, progress - 0.015)
                if progress > 0 {
                    WKInterfaceDevice.current().play(.directionDown)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func calcChance() -> Int {
        let baseChance = 0.95 - (Double(player.realm) * 0.10)
        let bonus = Double(player.wisdom + player.lucky) / 2000.0
        let finalChance = max(0.3, min(0.99, baseChance + bonus))
        return Int(finalChance * 100)
    }
    
    private func triggerFinalCheck() {
        let outcome = CultivationEngine.shared.breakthrough(profile: player, context: viewContext)
        result = outcome
        
        if outcome.success {
            WKInterfaceDevice.current().play(.success)
        } else {
            WKInterfaceDevice.current().play(.failure)
        }
    }
}
#endif
