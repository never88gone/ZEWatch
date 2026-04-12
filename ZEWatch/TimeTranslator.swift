import Foundation

struct TimeTranslator {
    static let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    
    /// 将当前时间的小时转换为十二时辰 (子时: 23:00-01:00, 丑时: 01:00-03:00 ...)
    static func currentShiChen(date: Date = Date()) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        // 23, 0 -> 0 (子)
        // 1, 2 -> 1 (丑)
        let branchIndex = ((hour + 23) % 24) / 2
        return earthlyBranches[branchIndex] + "时"
    }
    
    /// 获取中国传统农历日期字符串 (例如: "甲辰年五月初五")
    static func lunarDateString(date: Date = Date()) -> String {
        let lunarCalendar = Calendar(identifier: .chinese)
        let formatter = DateFormatter()
        formatter.calendar = lunarCalendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        
        let dateString = formatter.string(from: date)
        return dateString.replacingOccurrences(of: " ", with: "")
    }
}
