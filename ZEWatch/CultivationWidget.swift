import WidgetKit
import SwiftUI
import CoreData

// 1. 数据提供者
struct CultivationProvider: TimelineProvider {
    func placeholder(in context: Context) -> CultivationEntry {
        CultivationEntry(date: Date(), realmName: "筑基", current: 1500, total: 5000)
    }

    func getSnapshot(in context: Context, completion: @escaping (CultivationEntry) -> Void) {
        let entry = currentCultivationData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CultivationEntry>) -> Void) {
        let entry = currentCultivationData()
        // 建议每 30 分钟刷新一次
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func currentCultivationData() -> CultivationEntry {
        // 尝试从持久化中读取真实玩家数据
        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<PlayerProfile>(entityName: "PlayerProfile")
        request.fetchLimit = 1
        
        if let player = try? context.fetch(request).first {
            let realmName = CultivationEngine.shared.realmName(for: player.realm)
            let req = CultivationEngine.shared.requirementForNextRealm(currentLevel: player.realm) ?? 10000
            return CultivationEntry(
                date: Date(),
                realmName: realmName,
                current: player.cultivationBase,
                total: req
            )
        }
        
        return CultivationEntry(date: Date(), realmName: "炼气", current: 1200, total: 3000)
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
        case .accessoryCircular: // 圆形表盘组件 (例如：加州表盘小圆圈、信息图)
            ZStack {
                Gauge(value: Double(entry.current), in: 0...Double(max(1, entry.total))) {
                    Text(entry.realmName.prefix(1))
                        .font(.system(size: 11, weight: .bold, design: .serif))
                }
                .gaugeStyle(.circular)
                .tint(Gradient(colors: [.cyan, .purple]))
            }
            
        case .accessoryRectangular: // 矩形大组件 (例如：模块表盘中间)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("当前境界: \(entry.realmName)")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                }
                
                ProgressView(value: Double(entry.current), total: Double(max(1, entry.total)))
                    .tint(.cyan)
                    .scaleEffect(y: 0.6)
                
                HStack {
                    Text("\(entry.current)/\(entry.total)")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("真气盈满渡劫")
                        .font(.system(size: 8, design: .serif))
                        .foregroundColor(.yellow.opacity(0.8))
                }
            }
            .padding(.horizontal, 2)
            
        case .accessoryInline: // 顶部单行文字组件 (例如：时钟上方)
            HStack(spacing: 2) {
                Image(systemName: "sparkles")
                Text("修仙: \(entry.realmName) (\(Int(Double(entry.current) / Double(max(1, entry.total)) * 100))%)")
            }
            
        #if os(watchOS)
        case .accessoryCorner: // 表盘四角弧度组件
            Text(entry.realmName)
                .font(.system(size: 10, weight: .bold, design: .serif))
                .widgetLabel {
                    ProgressView(value: Double(entry.current), total: Double(max(1, entry.total)))
                        .tint(.cyan)
                }
        #endif
            
        default:
            Text(entry.realmName)
        }
    }
}

// 4. Widget 入口
struct CultivationWidget: Widget {
    let kind: String = "CultivationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CultivationProvider()) { entry in
            CultivationWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("灵气收集簿")
        .description("在表盘直观显示你的当前修仙境界与真气积累。")
        #if os(watchOS)
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
        #else
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
        #endif
    }
}
