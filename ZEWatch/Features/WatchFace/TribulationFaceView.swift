import SwiftUI

// MARK: - 2. 紫霄天劫盘 (Tribulation Face)
public struct TribulationFaceView: View {
    @ObservedObject var player: PlayerProfile
    let config: WatchFaceConfig
    let currentTime: Date
    let isReduced: Bool
    
    @State private var lightningPulse = false
    
    public init(player: PlayerProfile, config: WatchFaceConfig, currentTime: Date, isReduced: Bool) {
        self.player = player
        self.config = config
        self.currentTime = currentTime
        self.isReduced = isReduced
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            // 顶部雷威报警标
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.yellow)
                Text("天道雷威 · 劫云汇聚")
                    .font(.system(size: 9, weight: .bold, design: .serif))
                    .foregroundColor(Color.themePurplePrimary)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.yellow)
            }
            .padding(.top, 4)
            
            // 主时间
            VStack(spacing: 0) {
                if config.timeMode != .modern {
                    Text(TimeTranslator.currentDetailedShiChen(date: currentTime))
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundColor(config.themeColor.primaryColor)
                        .shadow(color: config.themeColor.glowColor, radius: lightningPulse ? 8 : 2)
                }
                
                Text(TimeTranslator.modernTimeString(date: currentTime))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            // 中央天劫刻度盘
            ZStack {
                Circle()
                    .stroke(config.themeColor.primaryColor.opacity(0.2), lineWidth: 5)
                    .frame(width: 82, height: 82)
                
                // 渡劫进度环
                if let req = CultivationEngine.shared.requirementForNextRealm(currentLevel: player.realm) {
                    let ratio = min(1.0, Double(player.cultivationBase) / Double(req))
                    Circle()
                        .trim(from: 0, to: CGFloat(ratio))
                        .stroke(
                            AngularGradient(
                                colors: [.cultivPrimary, config.themeColor.primaryColor, .yellow],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 82, height: 82)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(Int(ratio * 100))%")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundColor(.yellow)
                        Text("降劫临界")
                            .font(.system(size: 8, design: .serif))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer(minLength: 2)
            
            // 底部天理与炼体提示
            HStack(spacing: 12) {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill").font(.system(size: 8)).foregroundColor(.qiFire)
                    Text("九天罡风")
                        .font(.system(size: 9, design: .serif))
                        .foregroundColor(.gray)
                }
                HStack(spacing: 2) {
                    Image(systemName: "shield.lefthalf.filled").font(.system(size: 8)).foregroundColor(.cyan)
                    Text(CultivationEngine.shared.realmName(for: player.realm))
                        .font(.system(size: 9, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 6)
        }
        .onAppear {
            guard !isReduced else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                lightningPulse = true
            }
        }
    }
}
