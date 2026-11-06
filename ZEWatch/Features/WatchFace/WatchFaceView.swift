import SwiftUI
import Combine
import SpriteKit

#if os(watchOS)
import WatchKit

public struct WatchFaceView: View {
    @ObservedObject var player: PlayerProfile
    @ObservedObject var healthManager = HealthManager.shared
    
    @State private var currentTime: Date = Date()
    @State private var breathAnim = false
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public init(player: PlayerProfile) {
        self.player = player
    }
    
    public var body: some View {
        ZStack {
            // 暗黑背景，代表丹田气海
            RadialGradient(
                gradient: Gradient(colors: [Color.cultivPrimary.opacity(0.15), Color.black]),
                center: .center,
                startRadius: 10,
                endRadius: 100
            )
            .ignoresSafeArea()
            
            VStack(spacing: 8) {
                // 时间转换区域 (十二时辰 + 农历)
                HStack(alignment: .lastTextBaseline) {
                    Text(TimeTranslator.currentShiChen(date: currentTime))
                        .font(.system(size: 40, weight: .light, design: .serif))
                        .foregroundColor(.themeCyanPrimary)
                        .shadow(color: Color.themeCyanPrimary.opacity(breathAnim ? 0.8 : 0.2), radius: breathAnim ? 8 : 2)
                    
                    Text(TimeTranslator.lunarDateString(date: currentTime))
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(.cultivMuted)
                }
                .padding(.top, 4)
                
                // 现实时间
                Text(currentTime, style: .time)
                    .font(.system(size: 9, design: .serif))
                    .foregroundColor(.gray.opacity(0.4))
                
                // 天理感应
                let weatherBuff = WeatherEngine.shared.currentBuff(for: WeatherManager.shared.currentWeather)
                HStack(spacing: 4) {
                    Image(systemName: weatherBuff.iconName)
                        .font(.system(size: 10))
                        .foregroundColor(weatherBuff.color)
                    Text(weatherBuff.description)
                        .font(.system(size: 9, weight: .medium, design: .serif))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, 2)
                .onTapGesture {
                    WeatherManager.shared.startUpdating()
                }
                
                FixedDivider()
                
                // 核心健康转化指标
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 2) {
                            Text("炼体·金")
                                .font(.system(size: 9, design: .serif))
                                .foregroundColor(.themeGoldPrimary)
                            Image(systemName: "flame.fill")
                                .font(.system(size: 7))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        Text("\(Int(healthManager.todayEnergy))")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        Text("卡路里")
                            .font(.system(size: 8, design: .serif))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 2) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 7))
                                .foregroundColor(.green.opacity(0.8))
                            Text("游历·木")
                                .font(.system(size: 9, design: .serif))
                                .foregroundColor(.green)
                        }
                        Text("\(Int(healthManager.todaySteps))")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        Text("今日步数")
                            .font(.system(size: 8, design: .serif))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 14)
                
                // 五行灵气微型量条
                HStack(spacing: 7) {
                    QiGaugeCell(label: "金", value: player.metalQi, maxValue: 5000, color: .themeGoldPrimary)
                    QiGaugeCell(label: "木", value: player.woodQi, maxValue: 5000, color: .green)
                    QiGaugeCell(label: "水", value: player.waterQi, maxValue: 5000, color: .themeCyanPrimary)
                    QiGaugeCell(label: "火", value: player.fireQi, maxValue: 5000, color: .red)
                    QiGaugeCell(label: "土", value: player.earthQi, maxValue: 5000, color: .brown)
                }
                .padding(.vertical, 2)
                
                // 当前境界
                VStack(spacing: 2) {
                    Text("「 \(CultivationEngine.shared.realmName(for: player.realm)) 」")
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundColor(.themeGoldPrimary)
                        .shadow(color: Color.themeGoldPrimary.opacity(0.4), radius: 2)
                    
                    if let req = CultivationEngine.shared.requirementForNextRealm(currentLevel: player.realm) {
                        ProgressView(value: Double(player.cultivationBase), total: Double(req))
                            .tint(LinearGradient(colors: [.themeCyanPrimary, .blue], startPoint: .leading, endPoint: .trailing))
                            .background(Color.white.opacity(0.1))
                            .scaleEffect(y: 0.5)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .onReceive(timer) { input in
            currentTime = input
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                breathAnim = true
            }
        }
    }
}

// 五行灵气量条单元
struct QiGaugeCell: View {
    let label: String
    let value: Int64
    let maxValue: Int64
    let color: Color
    
    private var fillRatio: Double {
        guard maxValue > 0 else { return 0 }
        return min(1.0, Double(value) / Double(maxValue))
    }
    
    var body: some View {
        VStack(spacing: 2) {
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                    Rectangle()
                        .fill(color.opacity(0.85))
                        .frame(height: geo.size.height * fillRatio)
                }
                .cornerRadius(2)
            }
            .frame(width: 12, height: 20)
            
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .serif))
                .foregroundColor(color)
            
            Text(formatQi(value))
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private func formatQi(_ v: Int64) -> String {
        if v >= 1000 { return "\(v / 1000)k" }
        return "\(v)"
    }
}

// 优雅古典分割线
struct FixedDivider: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.clear, .gray.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing))
            .frame(height: 1)
            .padding(.horizontal, 14)
    }
}

// MARK: - ThunderboltScene (SpriteKit 雷劫动效)
class ThunderboltScene: SKScene {
    override func sceneDidLoad() {
        super.sceneDidLoad()
        backgroundColor = .clear
        createRain()
        
        let wait = SKAction.wait(forDuration: 0.4, withRange: 0.8)
        let strike = SKAction.run { [weak self] in
            self?.triggerLightning()
        }
        run(SKAction.repeatForever(SKAction.sequence([wait, strike])))
    }
    
    private func createRain() {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark") 
        emitter.particleBirthRate = 250
        emitter.particleLifetime = 0.8
        emitter.particlePositionRange = CGVector(dx: 200, dy: 50)
        emitter.particleSpeed = 600
        emitter.emissionAngle = -.pi / 2
        emitter.particleScale = 0.08
        emitter.particleAlpha = 0.3
        emitter.position = CGPoint(x: 100, y: 200)
        addChild(emitter)
    }
    
    private func triggerLightning() {
        let path = CGMutablePath()
        let startX = CGFloat.random(in: 10...190)
        path.move(to: CGPoint(x: startX, y: 200))
        
        var lastPoint = CGPoint(x: startX, y: 200)
        for _ in 0...8 {
            let nextPoint = CGPoint(
                x: lastPoint.x + CGFloat.random(in: -25...25),
                y: lastPoint.y - CGFloat.random(in: 15...40)
            )
            path.addLine(to: nextPoint)
            lastPoint = nextPoint
        }
        
        let lightning = SKShapeNode(path: path)
        lightning.strokeColor = .white
        lightning.lineWidth = 2.0
        lightning.glowWidth = 6.0
        lightning.alpha = 1.0
        addChild(lightning)
        
        WKInterfaceDevice.current().play(.failure)
        
        let fade = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        lightning.run(SKAction.sequence([fade, remove]))
    }
}
#endif
