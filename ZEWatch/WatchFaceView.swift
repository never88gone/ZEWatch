import SwiftUI
import Combine
import SpriteKit

#if os(watchOS)
import WatchKit

public struct WatchFaceView: View {
    @ObservedObject var player: PlayerProfile
    @ObservedObject var settingsManager = WatchFaceSettingsManager.shared
    @EnvironmentObject var healthManager: HealthManager
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var showingStylePicker = false
    
    // 是否处于微光熄屏节能状态
    private var isLuminanceReduced: Bool {
        scenePhase != .active
    }
    
    public init(player: PlayerProfile) {
        self.player = player
    }
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            // 核心修仙表盘容器
            CultivationWatchFaceContainer(
                player: player,
                isLuminanceReduced: isLuminanceReduced,
                isPreviewMode: false
            )
            .contentShape(Rectangle())
            // 长按表盘触发样式参悟/切换
            .onLongPressGesture(minimumDuration: 0.6) {
                triggerHapticSelection()
                showingStylePicker = true
            }
            
            // 右上角极简“灵盘”切换快捷按钮
            if !isLuminanceReduced {
                Button(action: {
                    triggerHapticSelection()
                    showingStylePicker = true
                }) {
                    Image(systemName: "slider.horizontal.2.square")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(settingsManager.config.themeColor.primaryColor.opacity(0.8))
                        .padding(6)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                .padding(.trailing, 4)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingStylePicker) {
            WatchFacePickerSheet(player: player, settingsManager: settingsManager)
        }
    }
    
    private func triggerHapticSelection() {
        WKInterfaceDevice.current().play(.click)
    }
}

// MARK: - Watch 端表盘参悟与切换面板
struct WatchFacePickerSheet: View {
    @ObservedObject var player: PlayerProfile
    @ObservedObject var settingsManager: WatchFaceSettingsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStyle: WatchFaceStyle
    @State private var selectedTheme: WatchFaceThemeColor
    @State private var selectedTimeMode: TimeDisplayMode
    
    init(player: PlayerProfile, settingsManager: WatchFaceSettingsManager) {
        self.player = player
        self.settingsManager = settingsManager
        _selectedStyle = State(initialValue: settingsManager.config.style)
        _selectedTheme = State(initialValue: settingsManager.config.themeColor)
        _selectedTimeMode = State(initialValue: settingsManager.config.timeMode)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("参悟修仙表盘")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(selectedTheme.primaryColor)
                    .padding(.top, 4)
                
                // 表盘样式列表
                VStack(spacing: 8) {
                    ForEach(WatchFaceStyle.allCases) { style in
                        Button(action: {
                            WKInterfaceDevice.current().play(.click)
                            selectedStyle = style
                            selectedTheme = style.recommendedTheme
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: style.iconSystemName)
                                    .font(.system(size: 14))
                                    .foregroundColor(selectedStyle == style ? selectedTheme.primaryColor : .gray)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(style.title)
                                        .font(.system(size: 12, weight: .semibold, design: .serif))
                                        .foregroundColor(.white)
                                    Text(style.subtitle)
                                        .font(.system(size: 8, design: .serif))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                if selectedStyle == style {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(selectedTheme.primaryColor)
                                        .font(.system(size: 12))
                                }
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedStyle == style ? selectedTheme.primaryColor.opacity(0.15) : Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedStyle == style ? selectedTheme.primaryColor : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Divider().background(Color.white.opacity(0.15))
                
                // 灵蕴主色切换
                VStack(alignment: .leading, spacing: 6) {
                    Text("灵蕴法相")
                        .font(.system(size: 10, weight: .medium, design: .serif))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        ForEach(WatchFaceThemeColor.allCases) { theme in
                            Circle()
                                .fill(theme.primaryColor)
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedTheme == theme ? 2 : 0)
                                )
                                .onTapGesture {
                                    WKInterfaceDevice.current().play(.click)
                                    selectedTheme = theme
                                }
                        }
                    }
                }
                
                // 确认应用按钮
                Button(action: {
                    var newConfig = settingsManager.config
                    newConfig.style = selectedStyle
                    newConfig.themeColor = selectedTheme
                    newConfig.timeMode = selectedTimeMode
                    
                    settingsManager.config = newConfig
                    settingsManager.broadcastConfig()
                    
                    WKInterfaceDevice.current().play(.success)
                    dismiss()
                }) {
                    Text("契约此表盘")
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedTheme.primaryColor)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 6)
        }
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
