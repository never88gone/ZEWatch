import SwiftUI
import Combine
import SpriteKit

#if os(watchOS)
import WatchKit

struct WatchFaceView: View {
    @ObservedObject var player: PlayerProfile
    @EnvironmentObject var healthManager: HealthManager
    
    @State private var currentTime: Date = Date()
    @State private var breathAnim = false
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // 暗黑深渊背景，代表丹田气海
            RadialGradient(gradient: Gradient(colors: [Color(red: 0, green: 0.1, blue: 0.15), .black]), center: .center, startRadius: 10, endRadius: 100)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                // 时间转换区域 (十二时辰 + 农历)
                HStack(alignment: .lastTextBaseline) {
                    Text(TimeTranslator.currentShiChen(date: currentTime))
                        .font(.system(size: 42, weight: .light, design: .serif))
                        .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.9))
                        .shadow(color: Color.cyan.opacity(breathAnim ? 0.8 : 0.0), radius: breathAnim ? 8 : 2)
                    
                    Text(TimeTranslator.lunarDateString(date: currentTime))
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(Color(white: 0.7))
                }
                .padding(.top, 4)
                
                // 辅助现实时间
                Text(currentTime, style: .time)
                    .font(.system(size: 9, design: .serif))
                    .foregroundColor(.gray.opacity(0.4))
                
                // 天理感应 (Weather Buff)
                let weatherBuff = WeatherEngine.shared.currentBuff(for: WeatherManager.shared.currentWeather)
                HStack(spacing: 4) {
                    Image(systemName: weatherBuff.iconName)
                        .font(.system(size: 10))
                        .foregroundColor(weatherBuff.color)
                    Text(weatherBuff.description)
                        .font(.system(size: 9, weight: .medium, design: .serif))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 2)
                .onTapGesture {
                    WeatherManager.shared.startUpdating()
                }
                
                HStack {
                    FixedDivider()
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.red)
                        Text("HealthKit")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    FixedDivider()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 2) {
                            Text("炼体·金")
                                .font(.system(size: 9, design: .serif))
                                .foregroundColor(.orange)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.red.opacity(0.6))
                        }
                        Text("\(Int(healthManager.todayEnergy))")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        Text("活动卡路里")
                            .font(.system(size: 8, design: .serif))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.red.opacity(0.6))
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
                .padding(.horizontal, 10)
                
                Spacer(minLength: 2)
                
                HStack(spacing: 4) {
                    let maxQi = max(1, player.metalQi, player.woodQi, player.waterQi, player.fireQi, player.earthQi)
                    QiGaugeCell(label: "金", value: player.metalQi, maxValue: maxQi, color: Color(red: 1.0, green: 0.65, blue: 0.0))
                    QiGaugeCell(label: "木", value: player.woodQi,  maxValue: maxQi, color: .green)
                    QiGaugeCell(label: "水", value: player.waterQi, maxValue: maxQi, color: .blue)
                    QiGaugeCell(label: "火", value: player.fireQi,  maxValue: maxQi, color: .red)
                    QiGaugeCell(label: "土", value: player.earthQi, maxValue: maxQi, color: Color(red: 0.6, green: 0.4, blue: 0.2))
                }
                .padding(.horizontal, 4)
                
                // 境界底座
                VStack(spacing: 2) {
                    Text("「 \(CultivationEngine.shared.realmName(for: player.realm)) 」")
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow.opacity(0.4), radius: 2)
                    
                    if let req = CultivationEngine.shared.requirementForNextRealm(currentLevel: player.realm) {
                        ProgressView(value: Double(player.cultivationBase), total: Double(req))
                            .tint(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
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
        .navigationBarHidden(true) 
    }
}

// 五行灵气竖向微型量条
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
            .frame(width: 12, height: 22)
            
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

// 古典分割线
struct FixedDivider: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.clear, .gray.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing))
            .frame(height: 1)
    }
}

// MARK: - ThunderboltScene (SpriteKit Tribulation Effects)
class ThunderboltScene: SKScene {
    override func sceneDidLoad() {
        super.sceneDidLoad()
        backgroundColor = .clear // 透明背景
        createRain()
        
        let wait = SKAction.wait(forDuration: 0.4, withRange: 0.8)
        let strike = SKAction.run { [weak self] in
            self?.triggerLightning()
        }
        run(SKAction.repeatForever(SKAction.sequence([wait, strike])))
    }
    
    // didMove(to:) 
    
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
        
        // 同步重度震动，模拟雷鸣天威
        WKInterfaceDevice.current().play(.failure)
        
        let fade = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        lightning.run(SKAction.sequence([fade, remove]))
    }
}
#endif
