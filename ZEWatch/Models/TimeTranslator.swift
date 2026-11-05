import Foundation

public struct TimeTranslator {
    public static let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    public static let heavenlyStems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    public static let bagua = ["☰ 乾", "☱ 兑", "☲ 离", "☳ 震", "☴ 巽", "☵ 坎", "☶ 艮", "☷ 坤"]
    public static let constellations28 = [
        "角木蛟", "亢金龙", "氐土貉", "房日兔", "心月狐", "尾火虎", "箕水豹",
        "斗木獬", "牛金牛", "女土蝠", "虚日鼠", "危月燕", "室火猪", "壁水貐",
        "奎木狼", "娄金狗", "胃土雉", "昴日鸡", "毕月乌", "觜火猴", "参水猿",
        "井木犴", "鬼金羊", "柳土獐", "星日马", "张月鹿", "翼火蛇", "轸水蚓"
    ]
    
    /// 将当前时间的小时转换为十二时辰 (子时: 23:00-01:00, 丑时: 01:00-03:00 ...)
    public static func currentShiChen(date: Date = Date()) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let branchIndex = ((hour + 23) % 24) / 2
        return earthlyBranches[branchIndex] + "时"
    }
    
    /// 获取当前时辰与细分刻度 (例如: "午时三刻", "子时初刻", "卯时正刻")
    public static func currentDetailedShiChen(date: Date = Date()) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        let branchIndex = ((hour + 23) % 24) / 2
        let branch = earthlyBranches[branchIndex]
        
        // 每个时辰为2小时(120分钟)。前60分钟为“初”，后60分钟为“正”；每15分钟为一刻
        let minuteInShiChen = (hour % 2 == 1 ? minute : minute + 60)
        let keIndex = (minuteInShiChen / 15) % 8
        let keNames = ["初刻", "一刻", "二刻", "三刻", "正刻", "五刻", "六刻", "七刻"]
        let ke = keNames[keIndex]
        
        return "\(branch)时\(ke)"
    }
    
    /// 获取当前时辰的卦象象征
    public static func currentBagua(date: Date = Date()) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let index = ((hour + 23) % 24) / 3
        return bagua[index % bagua.count]
    }
    
    /// 获取中国传统农历日期字符串 (例如: "甲辰年五月初五")
    public static func lunarDateString(date: Date = Date()) -> String {
        let lunarCalendar = Calendar(identifier: .chinese)
        let formatter = DateFormatter()
        formatter.calendar = lunarCalendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        
        let dateString = formatter.string(from: date)
        return dateString.replacingOccurrences(of: " ", with: "")
    }
    
    /// 获取当前适逢的二十八星宿之一 (依据一年中的天数流转)
    public static func currentConstellation(date: Date = Date()) -> String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % constellations28.count
        return constellations28[index]
    }
    
    /// 现代数字时间格式 (HH:mm:ss)
    public static func modernTimeString(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    /// 简略现代数字时间 (HH:mm)
    public static func modernShortTimeString(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
