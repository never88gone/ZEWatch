import SwiftUI
import Combine

// MARK: - 通用修仙表盘容器 (自适应 Apple Watch 与 iPhone 模拟器)
public struct CultivationWatchFaceContainer: View {
    @ObservedObject var player: PlayerProfile
    @ObservedObject var settingsManager = WatchFaceSettingsManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    // 是否处于低功耗息屏模式 (Always-On Display)
    var isLuminanceReduced: Bool = false
    // 是否为 iPhone 端预览模式
    var isPreviewMode: Bool = false
    
    @State private var currentTime: Date = Date()
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public init(player: PlayerProfile, isLuminanceReduced: Bool = false, isPreviewMode: Bool = false) {
        self.player = player
        self.isLuminanceReduced = isLuminanceReduced
        self.isPreviewMode = isPreviewMode
    }
    
    public var body: some View {
        ZStack {
            // 背景渐变
            faceBackground
            
            // 依据设置渲染不同风格的修仙表盘
            switch settingsManager.config.style {
            case .taiji:
                TaijiFaceView(player: player, config: settingsManager.config, currentTime: currentTime, isReduced: isLuminanceReduced)
            case .tribulation:
                TribulationFaceView(player: player, config: settingsManager.config, currentTime: currentTime, isReduced: isLuminanceReduced)
            case .grotto:
                GrottoFaceView(player: player, config: settingsManager.config, currentTime: currentTime, isReduced: isLuminanceReduced)
            case .sword:
                SwordFaceView(player: player, config: settingsManager.config, currentTime: currentTime, isReduced: isLuminanceReduced)
            case .astronomy:
                AstronomyFaceView(player: player, config: settingsManager.config, currentTime: currentTime, isReduced: isLuminanceReduced)
            }
        }
        .onReceive(timer) { input in
            currentTime = input
        }
    }
    
    private var faceBackground: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if settingsManager.config.showAuraEffect && !isLuminanceReduced {
                RadialGradient(
                    gradient: Gradient(colors: [
                        settingsManager.config.themeColor.secondaryColor.opacity(0.35),
                        Color.black
                    ]),
                    center: .center,
                    startRadius: 20,
                    endRadius: 130
                )
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

// MARK: - 1. 太极乾坤盘 (Taiji Face)
public struct TaijiFaceView: View {
    @ObservedObject var player: PlayerProfile
    let config: WatchFaceConfig
    let currentTime: Date
    let isReduced: Bool
    
    @State private var rotateAngle: Double = 0
    @State private var pulseGlow: Bool = false
    
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
            
            // 底部：五行灵气微量条 (若开启)
            if config.showGauges {
                let maxQi = max(1, player.metalQi, player.woodQi, player.waterQi, player.fireQi, player.earthQi)
                HStack(spacing: 5) {
                    MiniQiCell(label: "金", value: player.metalQi, maxVal: maxQi, color: Color(red: 1.0, green: 0.65, blue: 0.0))
                    MiniQiCell(label: "木", value: player.woodQi,  maxVal: maxQi, color: .green)
                    MiniQiCell(label: "水", value: player.waterQi, maxVal: maxQi, color: .blue)
                    MiniQiCell(label: "火", value: player.fireQi,  maxVal: maxQi, color: .red)
                    MiniQiCell(label: "土", value: player.earthQi, maxVal: maxQi, color: Color(red: 0.6, green: 0.4, blue: 0.2))
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

// MARK: - 2. 紫霄天劫盘 (Tribulation Face)
public struct TribulationFaceView: View {
    @ObservedObject var player: PlayerProfile
    let config: WatchFaceConfig
    let currentTime: Date
    let isReduced: Bool
    
    @State private var lightningPulse = false
    
    public var body: some View {
        VStack(spacing: 6) {
            // 顶部雷威报警标
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.yellow)
                Text("天道雷威 · 劫云汇聚")
                    .font(.system(size: 9, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.9, green: 0.7, blue: 1.0))
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
                
                // 渡劫进度环 (当前修为与下一境界比例)
                if let req = CultivationEngine.shared.requirementForNextRealm(currentLevel: player.realm) {
                    let ratio = min(1.0, Double(player.cultivationBase) / Double(req))
                    Circle()
                        .trim(from: 0, to: CGFloat(ratio))
                        .stroke(
                            AngularGradient(
                                colors: [.purple, config.themeColor.primaryColor, .yellow],
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
                    Image(systemName: "flame.fill").font(.system(size: 8)).foregroundColor(.orange)
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

// MARK: - 3. 洞天福地盘 (Grotto Face)
public struct GrottoFaceView: View {
    @ObservedObject var player: PlayerProfile
    let config: WatchFaceConfig
    let currentTime: Date
    let isReduced: Bool
    
    public var body: some View {
        VStack(spacing: 6) {
            // 顶部仙山祥云
            HStack(spacing: 4) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 9))
                    .foregroundColor(config.themeColor.primaryColor)
                Text("洞天福地 · 灵草长青")
                    .font(.system(size: 9, weight: .medium, design: .serif))
                    .foregroundColor(config.themeColor.primaryColor)
            }
            .padding(.top, 4)
            
            // 时间展示
            VStack(spacing: 1) {
                Text(TimeTranslator.currentShiChen(date: currentTime))
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(.white)
                
                Text(TimeTranslator.lunarDateString(date: currentTime))
                    .font(.system(size: 10, design: .serif))
                    .foregroundColor(.green.opacity(0.8))
            }
            
            // 寿元与生机同心环
            ZStack {
                // 外环：生机
                Circle()
                    .stroke(Color.green.opacity(0.2), lineWidth: 4)
                    .frame(width: 76, height: 76)
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 76, height: 76)
                    .rotationEffect(.degrees(-90))
                
                // 内环：灵泉
                Circle()
                    .stroke(Color.cyan.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: 0.6)
                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(45))
                
                VStack(spacing: 1) {
                    Text("三品")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    Text("灵脉")
                        .font(.system(size: 8, design: .serif))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer(minLength: 2)
            
            // 底部：药田与吐纳
            HStack {
                Text("吐纳吸纳自然灵机")
                    .font(.system(size: 9, design: .serif))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 6)
        }
    }
}

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
        return s * 6.0 // 360 / 60
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
struct SwordHand: View {
    let length: CGFloat
    let width: CGFloat
    let color: Color
    
    var body: some View {
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

struct SwordSecondHand: View {
    let length: CGFloat
    let color: Color
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 12))
            path.addLine(to: CGPoint(x: 0, y: -length))
        }
        .stroke(color, lineWidth: 1.2)
        .shadow(color: color, radius: 2)
    }
}

// MARK: - 5. 周天星斗盘 (Astronomy Face)
public struct AstronomyFaceView: View {
    @ObservedObject var player: PlayerProfile
    let config: WatchFaceConfig
    let currentTime: Date
    let isReduced: Bool
    
    @State private var starRotation: Double = 0
    
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

// MARK: - 辅助组件：太极双鱼几何图形
struct TaijiSymbol: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.addArc(center: center, radius: radius, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
        path.addArc(center: CGPoint(x: center.x, y: center.y - radius / 2), radius: radius / 2, startAngle: .degrees(270), endAngle: .degrees(90), clockwise: false)
        path.addArc(center: CGPoint(x: center.x, y: center.y + radius / 2), radius: radius / 2, startAngle: .degrees(270), endAngle: .degrees(90), clockwise: true)
        
        return path
    }
}

// MARK: - 辅助组件：微型五行指示条
struct MiniQiCell: View {
    let label: String
    let value: Int64
    let maxVal: Int64
    let color: Color
    
    private var fillRatio: Double {
        guard maxVal > 0 else { return 0 }
        return min(1.0, Double(value) / Double(maxVal))
    }
    
    var body: some View {
        VStack(spacing: 1) {
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    Rectangle().fill(Color.white.opacity(0.08))
                    Rectangle().fill(color.opacity(0.85))
                        .frame(height: geo.size.height * fillRatio)
                }
                .cornerRadius(1.5)
            }
            .frame(width: 9, height: 16)
            
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .serif))
                .foregroundColor(color)
        }
    }
}
