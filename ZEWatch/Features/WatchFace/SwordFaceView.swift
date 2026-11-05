import SwiftUI

// MARK: - 4. 万剑归宗盘 (Sword Face - 飞剑时分秒指针表盘)
public struct SwordFaceView: View {
    @ObservedObject var player: PlayerProfile
    let config: WatchFaceConfig
    let currentTime: Date
    let isReduced: Bool
    
    private var calendar: Calendar { Calendar.current }
    
    private var secondAngle: Double {
        let sec = calendar.component(.second, from: currentTime)
        let nsec = calendar.component(.nanosecond, from: currentTime)
        let s = Double(sec) + Double(nsec) / 1_000_000_000
        return s * 6.0
    }
    
    private var minuteAngle: Double {
        let min = calendar.component(.minute, from: currentTime)
        let sec = calendar.component(.second, from: currentTime)
        return (Double(min) + Double(sec) / 60.0) * 6.0
    }
    
    private var hourAngle: Double {
        let hr = calendar.component(.hour, from: currentTime)
        let min = calendar.component(.minute, from: currentTime)
        return (Double(hr % 12) + Double(min) / 60.0) * 30.0
    }
    
    public init(player: PlayerProfile, config: WatchFaceConfig, currentTime: Date, isReduced: Bool) {
        self.player = player
        self.config = config
        self.currentTime = currentTime
        self.isReduced = isReduced
    }
    
    public var body: some View {
        ZStack {
            // 剑阵刻度圆环
            Circle()
                .stroke(config.themeColor.primaryColor.opacity(0.25), lineWidth: 1)
                .frame(width: 140, height: 140)
            
            // 12 剑位刻度
            ForEach(0..<12) { i in
                Rectangle()
                    .fill(i % 3 == 0 ? config.themeColor.primaryColor : Color.gray.opacity(0.4))
                    .frame(width: i % 3 == 0 ? 2 : 1, height: i % 3 == 0 ? 8 : 4)
                    .offset(y: -65)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            
            // 剑心中央文字
            VStack(spacing: 2) {
                Text("万剑归宗")
                    .font(.system(size: 8, weight: .bold, design: .serif))
                    .foregroundColor(config.themeColor.primaryColor.opacity(0.7))
                Text(CultivationEngine.shared.realmName(for: player.realm))
                    .font(.system(size: 8, design: .serif))
                    .foregroundColor(.white.opacity(0.6))
            }
            .offset(y: -24)
            
            // 时针飞剑 (重剑)
            SwordHand(length: 36, width: 4, color: config.themeColor.primaryColor)
                .rotationEffect(.degrees(hourAngle))
            
            // 分针飞剑 (长剑)
            SwordHand(length: 52, width: 3, color: .white.opacity(0.9))
                .rotationEffect(.degrees(minuteAngle))
            
            // 秒针飞剑 (青索剑气)
            if !isReduced {
                SwordSecondHand(length: 62, color: config.themeColor.primaryColor)
                    .rotationEffect(.degrees(secondAngle))
            }
            
            // 剑心中心法印
            Circle()
                .fill(config.themeColor.primaryColor)
                .frame(width: 6, height: 6)
                .shadow(color: config.themeColor.glowColor, radius: 3)
            
            // 底部细微时辰显示
            VStack {
                Spacer()
                Text(TimeTranslator.currentShiChen(date: currentTime))
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .foregroundColor(config.themeColor.primaryColor)
                    .padding(.bottom, 6)
            }
        }
    }
}

// 飞剑指针形状
public struct SwordHand: View {
    let length: CGFloat
    let width: CGFloat
    let color: Color
    
    public init(length: CGFloat, width: CGFloat, color: Color) {
        self.length = length
        self.width = width
        self.color = color
    }
    
    public var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 8))
            path.addLine(to: CGPoint(x: -width / 2, y: 0))
            path.addLine(to: CGPoint(x: -width / 2, y: -length + 8))
            path.addLine(to: CGPoint(x: 0, y: -length))
            path.addLine(to: CGPoint(x: width / 2, y: -length + 8))
            path.addLine(to: CGPoint(x: width / 2, y: 0))
            path.closeSubpath()
        }
        .fill(color)
        .shadow(color: color.opacity(0.5), radius: 2)
    }
}

public struct SwordSecondHand: View {
    let length: CGFloat
    let color: Color
    
    public init(length: CGFloat, color: Color) {
        self.length = length
        self.color = color
    }
    
    public var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 12))
            path.addLine(to: CGPoint(x: 0, y: -length))
        }
        .stroke(color, lineWidth: 1.2)
        .shadow(color: color, radius: 2)
    }
}
