import SwiftUI

// MARK: - 5. 周天星斗盘 (Astronomy Face)
public struct AstronomyFaceView: View {
    @ObservedObject var player: PlayerProfile
    let config: WatchFaceConfig
    let currentTime: Date
    let isReduced: Bool
    
    @State private var starRotation: Double = 0
    
    public init(player: PlayerProfile, config: WatchFaceConfig, currentTime: Date, isReduced: Bool) {
        self.player = player
        self.config = config
        self.currentTime = currentTime
        self.isReduced = isReduced
    }
    
    public var body: some View {
        VStack(spacing: 5) {
            // 当前星宿
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 8))
                    .foregroundColor(config.themeColor.primaryColor)
                Text("值日宿位 · \(TimeTranslator.currentConstellation(date: currentTime))")
                    .font(.system(size: 9, weight: .bold, design: .serif))
                    .foregroundColor(config.themeColor.primaryColor)
            }
            .padding(.top, 4)
            
            // 时辰与农历
            VStack(spacing: 2) {
                Text(TimeTranslator.currentDetailedShiChen(date: currentTime))
                    .font(.system(size: 22, weight: .light, design: .serif))
                    .foregroundColor(.white)
                
                Text(TimeTranslator.lunarDateString(date: currentTime))
                    .font(.system(size: 10, design: .serif))
                    .foregroundColor(.gray.opacity(0.8))
            }
            
            // 星盘核心
            ZStack {
                // 外圈星宿罗盘微点
                Circle()
                    .stroke(config.themeColor.primaryColor.opacity(0.2), lineWidth: 1)
                    .frame(width: 82, height: 82)
                
                // 模拟二十八星宿微光点
                ForEach(0..<28) { i in
                    Circle()
                        .fill(config.themeColor.primaryColor.opacity(i % 7 == 0 ? 0.9 : 0.3))
                        .frame(width: i % 7 == 0 ? 3 : 1.5, height: i % 7 == 0 ? 3 : 1.5)
                        .offset(y: -40)
                        .rotationEffect(.degrees(Double(i) * (360.0 / 28.0) + starRotation))
                }
                
                // 月相圆环
                VStack(spacing: 2) {
                    Image(systemName: "moonphase.waxing.gibbous")
                        .font(.system(size: 20))
                        .foregroundColor(config.themeColor.primaryColor)
                        .shadow(color: config.themeColor.glowColor, radius: 4)
                    
                    Text(CultivationEngine.shared.realmName(for: player.realm))
                        .font(.system(size: 9, weight: .bold, design: .serif))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            
            Spacer(minLength: 2)
            
            Text("参悟周天造化 · 日月玄机")
                .font(.system(size: 8, design: .serif))
                .foregroundColor(.gray.opacity(0.7))
                .padding(.bottom, 6)
        }
        .onAppear {
            guard !isReduced else { return }
            withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                starRotation = 360
            }
        }
    }
}
