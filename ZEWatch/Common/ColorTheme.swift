import SwiftUI

// MARK: - 统一修仙配色系统 (Unified Cultivation Color System)
// 所有视图与模块中的色彩统一在此定义，禁止在其他文件中私自扩展或零散硬编码颜色
public extension Color {
    // MARK: - 基础主题色 (Theme Primaries & Background)
    static let cultivPrimary   = Color(red: 0.486, green: 0.227, blue: 0.929) // #7C3AED (修仙紫)
    static let cultivSecondary = Color(red: 0.655, green: 0.545, blue: 0.980) // #A78BFA (淡紫)
    static let cultivAccent    = Color(red: 0.957, green: 0.247, blue: 0.369) // #F43F5E (玫红)
    static let cultivBg        = Color(red: 0.059, green: 0.059, blue: 0.137) // #0F0F23 (深邃暗蓝)
    static let cultivText      = Color(red: 0.886, green: 0.910, blue: 0.941) // #E2E8F0 (月白)
    static let cultivMuted     = Color(red: 0.580, green: 0.600, blue: 0.680) // 辅助灰
    static let emerald         = Color(red: 0.1,   green: 0.7,   blue: 0.4)   // 翡翠青
    
    // MARK: - 五行灵气专属色 (Five Elements Qi Colors)
    static let qiMetal = Color(red: 1.00, green: 0.75, blue: 0.10) // 金 - 橙黄纯金
    static let qiWood  = Color(red: 0.20, green: 0.80, blue: 0.35) // 木 - 生机碧翠
    static let qiWater = Color(red: 0.15, green: 0.60, blue: 1.00) // 水 - 浩渺湛蓝
    static let qiFire  = Color(red: 0.95, green: 0.30, blue: 0.25) // 火 - 炽烈赤红
    static let qiEarth = Color(red: 0.65, green: 0.45, blue: 0.25) // 土 - 厚重赭褐
    
    // MARK: - 修仙表盘灵蕴主题色 (Watch Face Theme Colors)
    static let themeCyanPrimary    = Color(red: 0.20, green: 0.85, blue: 0.95)
    static let themeCyanSecondary  = Color(red: 0.05, green: 0.45, blue: 0.60)
    
    static let themeGoldPrimary    = Color(red: 1.00, green: 0.80, blue: 0.20)
    static let themeGoldSecondary  = Color(red: 0.70, green: 0.50, blue: 0.10)
    
    static let themePurplePrimary  = Color(red: 0.75, green: 0.45, blue: 1.00)
    static let themePurpleSecondary = Color(red: 0.45, green: 0.20, blue: 0.70)
    
    static let themeRedPrimary     = Color(red: 1.00, green: 0.35, blue: 0.35)
    static let themeRedSecondary   = Color(red: 0.70, green: 0.15, blue: 0.20)
    
    static let themeGreenPrimary   = Color(red: 0.30, green: 0.90, blue: 0.50)
    static let themeGreenSecondary = Color(red: 0.10, green: 0.50, blue: 0.25)
}
