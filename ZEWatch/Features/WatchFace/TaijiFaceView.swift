import SwiftUI

// MARK: - 1. 太极乾坤盘 (Taiji Face)
public struct TaijiFaceView: View {
    @ObservedObject var player: PlayerProfile
    let config: WatchFaceConfig
    let currentTime: Date
    let isReduced: Bool
    
    @State private var rotateAngle: Double = 0
    @State private var pulseGlow: Bool = false
    
    public init(player: PlayerProfile, config: WatchFaceConfig, currentTime: Date, isReduced: Bool) {
        self.player = player
        self.config = config
        self.currentTime = currentTime
        self.isReduced = isReduced
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            // 顶部：时辰与天干地支
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if config.timeMode != .modern {
                    Text(TimeTranslator.currentShiChen(date: currentTime))
                        .font(.system(size: 26, weight: .light, design: .serif))
                        .foregroundColor(config.themeColor.primaryColor)
                        .shadow(color: config.themeColor.glowColor, radius: pulseGlow ? 6 : 1)
                }
                
                if config.timeMode != .shichen {
                    Text(TimeTranslator.modernTimeString(date: currentTime))
                        .font(.system(size: config.timeMode == .modern ? 24 : 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Text(TimeTranslator.lunarDateString(date: currentTime))
                    .font(.system(size: 9, design: .serif))
                    .foregroundColor(.gray.opacity(0.8))
            }
            .padding(.top, 4)
            
            // 辅助细刻
            Text(TimeTranslator.currentDetailedShiChen(date: currentTime) + " · " + TimeTranslator.currentBagua(date: currentTime))
                .font(.system(size: 9, weight: .regular, design: .serif))
                .foregroundColor(config.themeColor.primaryColor.opacity(0.8))
            
            // 中央太极图与八卦
            ZStack {
                // 外圈八卦方位小光点
                Circle()
                    .stroke(config.themeColor.primaryColor.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [2, 6]))
                    .frame(width: 86, height: 86)
                
                // 太极双鱼
                TaijiSymbol()
                    .fill(
                        LinearGradient(
                            colors: [config.themeColor.primaryColor, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(rotateAngle))
                    .shadow(color: config.themeColor.glowColor, radius: 4)
                
                // 境界居中微章
                Text(CultivationEngine.shared.realmName(for: player.realm))
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(config.themeColor.primaryColor.opacity(0.6), lineWidth: 0.8)
                    )
                    .offset(y: 38)
            }
            .frame(height: 86)
            
            Spacer(minLength: 2)
            
            // 底部：五行灵气微量条 (使用统一五行色)
            if config.showGauges {
                let maxQi = max(1, player.metalQi, player.woodQi, player.waterQi, player.fireQi, player.earthQi)
                HStack(spacing: 5) {
                    MiniQiCell(label: "金", value: player.metalQi, maxVal: maxQi, color: .qiMetal)
                    MiniQiCell(label: "木", value: player.woodQi,  maxVal: maxQi, color: .qiWood)
                    MiniQiCell(label: "水", value: player.waterQi, maxVal: maxQi, color: .qiWater)
                    MiniQiCell(label: "火", value: player.fireQi,  maxVal: maxQi, color: .qiFire)
                    MiniQiCell(label: "土", value: player.earthQi, maxVal: maxQi, color: .qiEarth)
                }
                .padding(.horizontal, 8)
            }
            
            // 境界底座进度
            if let req = CultivationEngine.shared.requirementForNextRealm(currentLevel: player.realm) {
                ProgressView(value: Double(player.cultivationBase), total: Double(req))
                    .tint(config.themeColor.primaryColor)
                    .scaleEffect(y: 0.5)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 2)
            }
        }
        .onAppear {
            guard !isReduced else { return }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotateAngle = 360
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseGlow = true
            }
        }
    }
}
