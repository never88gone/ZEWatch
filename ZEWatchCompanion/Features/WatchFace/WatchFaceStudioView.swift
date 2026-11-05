import SwiftUI
import UIKit

// MARK: - iPhone 端：修仙表盘工坊 (Watch Face Studio)
public struct WatchFaceStudioView: View {
    @ObservedObject var player: PlayerProfile
    @ObservedObject var settingsManager = WatchFaceSettingsManager.shared
    
    @State private var previewStyle: WatchFaceStyle
    @State private var previewTheme: WatchFaceThemeColor
    @State private var previewTimeMode: TimeDisplayMode
    @State private var showGauges: Bool
    @State private var showWeatherBuff: Bool
    @State private var showAuraEffect: Bool
    
    @State private var showSyncSuccessAlert: Bool = false
    @State private var showComplicationGuide: Bool = false
    
    public init(player: PlayerProfile) {
        self.player = player
        let current = WatchFaceSettingsManager.shared.config
        _previewStyle = State(initialValue: current.style)
        _previewTheme = State(initialValue: current.themeColor)
        _previewTimeMode = State(initialValue: current.timeMode)
        _showGauges = State(initialValue: current.showGauges)
        _showWeatherBuff = State(initialValue: current.showWeatherBuff)
        _showAuraEffect = State(initialValue: current.showAuraEffect)
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. 拟真 Apple Watch 实时全屏预览机身
                appleWatchMockupPreview
                    .padding(.top, 12)
                
                // 2. 表盘风格选择库
                styleSelectionSection
                
                // 3. 灵蕴色相定制
                themeColorSection
                
                // 4. 时间制式与数据显示细节
                detailCustomizationSection
                
                // 5. 核心同步按钮
                syncActionButton
                
                // 6. 系统表盘复杂功能添加指引
                complicationGuideCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.cultivBg.ignoresSafeArea())
        .navigationTitle("修仙表盘工坊")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("表盘已同步", isPresented: $showSyncSuccessAlert) {
            Button("好", role: .cancel) { }
        } message: {
            Text("修仙表盘样式已成功同步至 Apple Watch！抬腕即可感受灵气流转。")
        }
    }
    
    // MARK: - 1. 拟真 Apple Watch 预览模型
    private var appleWatchMockupPreview: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .trailing) {
                // 手表表体外框
                RoundedRectangle(cornerRadius: 44, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.22), Color(white: 0.1), Color(white: 0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 220, height: 268)
                    .overlay(
                        RoundedRectangle(cornerRadius: 44, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.clear, Color.white.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: previewTheme.primaryColor.opacity(0.25), radius: 18, x: 0, y: 8)
                
                // 右侧数码表冠 (Digital Crown)
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: [Color(white: 0.35), Color(white: 0.18)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 8, height: 42)
                    .offset(x: 5, y: -40)
                
                // 右侧侧边按键 (Side Button)
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [Color(white: 0.3), Color(white: 0.15)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 5, height: 38)
                    .offset(x: 3, y: 32)
                
                // 屏幕内嵌区域 (Apple Watch 真实屏幕比例)
                ZStack {
                    Color.black
                    
                    // 模拟实时表盘容器
                    let previewConfig = WatchFaceConfig(
                        style: previewStyle,
                        timeMode: previewTimeMode,
                        themeColor: previewTheme,
                        showGauges: showGauges,
                        showWeatherBuff: showWeatherBuff,
                        showAuraEffect: showAuraEffect,
                        enableHaptic: true
                    )
                    
                    // 渲染对应表盘
                    Group {
                        switch previewStyle {
                        case .taiji:
                            TaijiFaceView(player: player, config: previewConfig, currentTime: Date(), isReduced: false)
                        case .tribulation:
                            TribulationFaceView(player: player, config: previewConfig, currentTime: Date(), isReduced: false)
                        case .grotto:
                            GrottoFaceView(player: player, config: previewConfig, currentTime: Date(), isReduced: false)
                        case .sword:
                            SwordFaceView(player: player, config: previewConfig, currentTime: Date(), isReduced: false)
                        case .astronomy:
                            AstronomyFaceView(player: player, config: previewConfig, currentTime: Date(), isReduced: false)
                        }
                    }
                    .padding(8)
                }
                .frame(width: 198, height: 242)
                .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                .padding(.trailing, 11) // 保持居中
            }
            .frame(width: 240, height: 275)
            
            Text("实时预览")
                .font(.system(size: 11, design: .serif))
                .foregroundColor(.cultivMuted)
        }
    }
    
    // MARK: - 2. 表盘风格选择
    private var styleSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("选择修仙灵盘", systemImage: "sparkles")
                .font(.headline)
                .foregroundColor(.cultivText)
            
            VStack(spacing: 10) {
                ForEach(WatchFaceStyle.allCases) { style in
                    Button(action: {
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            previewStyle = style
                            previewTheme = style.recommendedTheme
                        }
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(previewStyle == style ? previewTheme.primaryColor.opacity(0.2) : Color.white.opacity(0.05))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: style.iconSystemName)
                                    .font(.system(size: 20))
                                    .foregroundColor(previewStyle == style ? previewTheme.primaryColor : .gray)
                            }
                            
                            Text(style.title)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if previewStyle == style {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(previewTheme.primaryColor)
                                    .font(.title3)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(previewStyle == style ? Color(white: 0.12) : Color(white: 0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(previewStyle == style ? previewTheme.primaryColor : Color.white.opacity(0.08), lineWidth: previewStyle == style ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - 3. 灵蕴色相定制
    private var themeColorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("灵蕴色泽", systemImage: "paintpalette.fill")
                .font(.headline)
                .foregroundColor(.cultivText)
            
            HStack(spacing: 14) {
                ForEach(WatchFaceThemeColor.allCases) { theme in
                    Button(action: {
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                        withAnimation {
                            previewTheme = theme
                        }
                    }) {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(theme.primaryColor)
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: previewTheme == theme ? 2.5 : 0)
                                )
                                .shadow(color: theme.glowColor, radius: previewTheme == theme ? 6 : 0)
                            
                            Text(theme.title)
                                .font(.caption2)
                                .foregroundColor(previewTheme == theme ? .white : .cultivMuted)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(white: 0.06))
            )
        }
    }
    
    // MARK: - 4. 细节微调
    private var detailCustomizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("表盘细节微调", systemImage: "slider.horizontal.3")
                .font(.headline)
                .foregroundColor(.cultivText)
            
            VStack(spacing: 12) {
                // 时间制式
                VStack(alignment: .leading, spacing: 8) {
                    Text("时间显示制式")
                        .font(.caption.bold())
                        .foregroundColor(.cultivMuted)
                    
                    Picker("时间制式", selection: $previewTimeMode) {
                        ForEach(TimeDisplayMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // 开关项
                Toggle(isOn: $showGauges) {
                    Label("五行灵气微量条", systemImage: "chart.bar.fill")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .tint(previewTheme.primaryColor)
                
                Toggle(isOn: $showWeatherBuff) {
                    Label("天理感应 (天气气象)", systemImage: "cloud.sun.fill")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .tint(previewTheme.primaryColor)
                
                Toggle(isOn: $showAuraEffect) {
                    Label("背景灵光光晕 (呼吸动画)", systemImage: "waveform.path")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .tint(previewTheme.primaryColor)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(white: 0.06))
            )
        }
    }
    
    // MARK: - 5. 核心同步按钮
    private var syncActionButton: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            
            var newConfig = settingsManager.config
            newConfig.style = previewStyle
            newConfig.themeColor = previewTheme
            newConfig.timeMode = previewTimeMode
            newConfig.showGauges = showGauges
            newConfig.showWeatherBuff = showWeatherBuff
            newConfig.showAuraEffect = showAuraEffect
            
            settingsManager.config = newConfig
            settingsManager.broadcastConfig()
            
            showSyncSuccessAlert = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "applewatch.radiowaves.left.and.right")
                    .font(.headline)
                Text("同步到 Apple Watch")
                    .font(.headline.bold())
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [previewTheme.primaryColor, previewTheme.primaryColor.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: previewTheme.glowColor, radius: 8, x: 0, y: 4)
        }
        .padding(.top, 8)
    }
    
    // MARK: - 6. 复杂功能设置指引卡片
    private var complicationGuideCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation {
                    showComplicationGuide.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.cultivSecondary)
                    Text("如何在 Apple Watch 官方表盘中添加修仙组件？")
                        .font(.caption.bold())
                        .foregroundColor(.cultivSecondary)
                    Spacer()
                    Image(systemName: showComplicationGuide ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.cultivMuted)
                }
            }
            .buttonStyle(.plain)
            
            if showComplicationGuide {
                VStack(alignment: .leading, spacing: 8) {
                    Text("您可以将【ZEWatch 修仙】添加到苹果官方表盘（如模块、加州、大文字等）作为复杂功能：")
                        .font(.caption2)
                        .foregroundColor(.cultivMuted)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("1. 在 Apple Watch 上长按表盘，点击【编辑】；")
                        Text("2. 左右轻扫至【复杂功能 (Complications)】槽位；")
                        Text("3. 点击任意槽位，上下滚动找到【ZEWatch】；")
                        Text("4. 选择【当前境界】或【灵气收集簿】，即可随时在官方表盘上直观查看修仙进度！")
                    }
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.leading, 4)
                }
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
