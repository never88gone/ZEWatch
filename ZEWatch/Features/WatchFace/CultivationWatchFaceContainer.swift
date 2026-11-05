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

// MARK: - 辅助组件：太极双鱼几何图形
public struct TaijiSymbol: Shape {
    public init() {}
    
    public func path(in rect: CGRect) -> Path {
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
public struct MiniQiCell: View {
    let label: String
    let value: Int64
    let maxVal: Int64
    let color: Color
    
    public init(label: String, value: Int64, maxVal: Int64, color: Color) {
        self.label = label
        self.value = value
        self.maxVal = maxVal
        self.color = color
    }
    
    private var fillRatio: Double {
        guard maxVal > 0 else { return 0 }
        return min(1.0, Double(value) / Double(maxVal))
    }
    
    public var body: some View {
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
