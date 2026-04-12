import WidgetKit
import SwiftUI
import CoreData

// 1. 数据提供者
struct CultivationProvider: TimelineProvider {
    func placeholder(in context: Context) -> CultivationEntry {
        CultivationEntry(date: Date(), realmName: "炼气", current: 1500, total: 5000)
    }

    func getSnapshot(in context: Context, completion: @escaping (CultivationEntry) -> Void) {
        let entry = CultivationEntry(date: Date(), realmName: "炼气", current: 1500, total: 5000)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CultivationEntry>) -> Void) {
        // 在实际业务中可通过 AppGroup 读取 CoreData/CloudKit 共享数据
        // 这里模拟展示默认值
        let entry = CultivationEntry(date: Date(), realmName: "筑基", current: 18000, total: 20000)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// 2. 数据实体
struct CultivationEntry: TimelineEntry {
    let date: Date
    let realmName: String
    let current: Int64
    let total: Int64
}

// 3. UI 视图渲染 (针对不同尺寸的表盘组件进行适配)
struct CultivationWidgetEntryView : View {
    var entry: CultivationProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular: // 圆形表盘组建
            Gauge(value: Double(entry.current), in: 0...Double(entry.total)) {
                Text(entry.realmName.prefix(1))
                    .font(.caption)
            }
            .gaugeStyle(.circular)
            .tint(Gradient(colors: [.cyan, .purple]))
            
        case .accessoryRectangular: // 矩形大组件
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "flame.fill").foregroundColor(.orange)
                    Text("当前境界: \(entry.realmName)")
                        .font(.headline)
                }
                ProgressView(value: Double(entry.current), total: Double(entry.total))
                    .tint(.cyan)
            }
            
        case .accessoryInline: // 顶部单行文字组件
            Text("修仙进度: \(entry.realmName)")
            
        default:
            Text(entry.realmName)
        }
    }
}

// 4. Widget 入口
// @main (如需作为独立 Widget 运行，请确保此文件仅包含在 Widget Extension Target 中)
struct CultivationWidget: Widget {
    let kind: String = "CultivationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CultivationProvider()) { entry in
            CultivationWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("灵气收集簿")
        .description("在表盘直观显示你的当前修仙境界与真气积累。")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
