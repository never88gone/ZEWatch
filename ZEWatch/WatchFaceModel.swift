import SwiftUI
import Combine
import Foundation

// MARK: - 表盘修仙样式枚举
public enum WatchFaceStyle: String, CaseIterable, Identifiable, Codable {
    case taiji        = "taiji"        // 太极乾坤盘 (经典道门，阴阳双鱼流转，五行环绕)
    case tribulation  = "tribulation"  // 紫霄天劫盘 (雷云威压，天劫倒计时，雷芒脉冲)
    case grotto       = "grotto"       // 洞天福地盘 (仙山云海，生命气血寿元环，古木灵秀)
    case sword        = "sword"        // 万剑归宗盘 (以剑指时分秒，八荒剑阵，冷峻极简)
    case astronomy    = "astronomy"    // 周天星斗盘 (二十八星宿，日月交辉，天干地支)
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .taiji:       return "太极乾坤盘"
        case .tribulation: return "紫霄天劫盘"
        case .grotto:      return "洞天福地盘"
        case .sword:       return "万剑归宗盘"
        case .astronomy:   return "周天星斗盘"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .taiji:       return "阴阳双鱼徐徐流转 · 五行灵气脉动"
        case .tribulation: return "天道神雷劫云漫卷 · 警惕心魔淬体"
        case .grotto:      return "仙家福地气血长明 · 生机草木滋养"
        case .sword:       return "本命飞剑锋芒破空 · 锐利极简剑意"
        case .astronomy:   return "二十八宿日月星辰 · 参悟周天造化"
        }
    }
    
    public var iconSystemName: String {
        switch self {
        case .taiji:       return "circle.lefthalf.filled"
        case .tribulation: return "bolt.trianglebadge.exclamationmark.fill"
        case .grotto:      return "leaf.circle.fill"
        case .sword:       return "wind"
        case .astronomy:   return "sparkles"
        }
    }
    
    public var recommendedTheme: WatchFaceThemeColor {
        switch self {
        case .taiji:       return .cyan
        case .tribulation: return .purple
        case .grotto:      return .green
        case .sword:       return .gold
        case .astronomy:   return .cyan
        }
    }
}

// MARK: - 时间显示制式
public enum TimeDisplayMode: String, CaseIterable, Identifiable, Codable {
    case shichen  = "shichen"  // 纯古法十二时辰 (如: 午时三刻)
    case modern   = "modern"   // 现代时间 (如: 14:35:28)
    case both     = "both"     // 时辰为主，时间为辅
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .shichen: return "古法时辰 (子丑寅卯)"
        case .modern:  return "标准时钟 (数字时间)"
        case .both:    return "融合双显 (时辰与数字并存)"
        }
    }
}

// MARK: - 表盘灵蕴色相
public enum WatchFaceThemeColor: String, CaseIterable, Identifiable, Codable {
    case cyan    = "cyan"    // 青虚仙气
    case gold    = "gold"    // 大日纯阳
    case purple  = "purple"  // 鸿蒙紫气
    case red     = "red"     // 朱雀离火
    case green   = "green"   // 通天长青
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .cyan:   return "青虚玄光"
        case .gold:   return "天阳纯金"
        case .purple: return "紫霄神雷"
        case .red:    return "朱雀赤霞"
        case .green:  return "碧游长青"
        }
    }
    
    public var primaryColor: Color {
        switch self {
        case .cyan:   return Color(red: 0.2, green: 0.85, blue: 0.95)
        case .gold:   return Color(red: 1.0, green: 0.8, blue: 0.2)
        case .purple: return Color(red: 0.75, green: 0.45, blue: 1.0)
        case .red:    return Color(red: 1.0, green: 0.35, blue: 0.35)
        case .green:  return Color(red: 0.3, green: 0.9, blue: 0.5)
        }
    }
    
    public var secondaryColor: Color {
        switch self {
        case .cyan:   return Color(red: 0.05, green: 0.45, blue: 0.6)
        case .gold:   return Color(red: 0.7, green: 0.5, blue: 0.1)
        case .purple: return Color(red: 0.45, green: 0.2, blue: 0.7)
        case .red:    return Color(red: 0.7, green: 0.15, blue: 0.2)
        case .green:  return Color(red: 0.1, green: 0.5, blue: 0.25)
        }
    }
    
    public var glowColor: Color {
        primaryColor.opacity(0.6)
    }
}

// MARK: - 表盘完整配置模型
public struct WatchFaceConfig: Codable, Equatable {
    public var style: WatchFaceStyle
    public var timeMode: TimeDisplayMode
    public var themeColor: WatchFaceThemeColor
    public var showGauges: Bool         // 是否显示五行微量条
    public var showWeatherBuff: Bool    // 是否显示天理感应气象
    public var showAuraEffect: Bool     // 是否显示背景灵气流光
    public var enableHaptic: Bool       // 整点/时辰交替震动提醒
    
    public init(
        style: WatchFaceStyle = .taiji,
        timeMode: TimeDisplayMode = .both,
        themeColor: WatchFaceThemeColor = .cyan,
        showGauges: Bool = true,
        showWeatherBuff: Bool = true,
        showAuraEffect: Bool = true,
        enableHaptic: Bool = true
    ) {
        self.style = style
        self.timeMode = timeMode
        self.themeColor = themeColor
        self.showGauges = showGauges
        self.showWeatherBuff = showWeatherBuff
        self.showAuraEffect = showAuraEffect
        self.enableHaptic = enableHaptic
    }
}

// MARK: - 表盘配置管理单例 (双端共享存储与通信)
public class WatchFaceSettingsManager: ObservableObject {
    public static let shared = WatchFaceSettingsManager()
    
    private let userDefaultsKey = "com.nevergone.zrxx.watchface_config"
    
    @Published public var config: WatchFaceConfig {
        didSet {
            saveToStorage()
        }
    }
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode(WatchFaceConfig.self, from: data) {
            self.config = saved
        } else {
            self.config = WatchFaceConfig()
        }
    }
    
    private func saveToStorage() {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    /// 将配置打包为字典用于 WCSession 同步
    public func dictionaryRepresentation() -> [String: Any] {
        guard let encoded = try? JSONEncoder().encode(config),
              let dict = try? JSONSerialization.jsonObject(with: encoded) as? [String: Any] else {
            return [:]
        }
        return ["watchFaceConfig": dict]
    }
    
    /// 从外部接收到的字典中更新配置
    public func update(from dictionary: [String: Any]) {
        guard let configDict = dictionary["watchFaceConfig"] as? [String: Any],
              let data = try? JSONSerialization.data(withJSONObject: configDict),
              let decoded = try? JSONDecoder().decode(WatchFaceConfig.self, from: data) else {
            return
        }
        DispatchQueue.main.async {
            self.config = decoded
        }
    }
    
    /// 发送配置同步到远端设备 (Watch 或 iPhone)
    public func broadcastConfig() {
        let payload = dictionaryRepresentation()
        ConnectivityManager.shared.sendSyncData(payload)
    }
}
