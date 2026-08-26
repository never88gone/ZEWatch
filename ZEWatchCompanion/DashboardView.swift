import SwiftUI

struct DashboardView: View {
    @ObservedObject var player: PlayerProfile
    
    // 进度计算
    var reqBase: Int64 {
        CultivationEngine.shared.requirementForNextRealm(currentLevel: player.realm) ?? Int64.max
    }
    
    var isFull: Bool {
        player.cultivationBase >= reqBase
    }
    
    var progressVal: Double {
        isFull ? Double(reqBase) : Double(player.cultivationBase)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.cultivBg.ignoresSafeArea()
                
                // 时辰/天气动效背景
                TimeOfDayBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 境界总览
                        VStack(spacing: 8) {
                            Text(CultivationEngine.shared.realmName(for: player.realm))
                                .font(.system(size: 32, weight: .bold, design: .serif))
                                .foregroundColor(.cultivPrimary)
                            
                            Text("当前修为: \(player.cultivationBase) / \(reqBase)")
                                .font(.subheadline)
                                .foregroundColor(.cultivMuted)
                            
                            ProgressView(value: progressVal, total: Double(reqBase))
                                .tint(isFull ? .red : .cultivAccent)
                                .padding(.horizontal, 40)
                                
                            if isFull {
                                Text("真气盈满，需在 Apple Watch 上引天雷渡劫方可突破！")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.top, 40)
                        
                        // 灵气面板
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("五行灵气转化")
                                    .font(.headline)
                                    .foregroundColor(.cultivText)
                                Spacer()
                                if HealthManager.shared.convertedWoodQi >= HealthManager.shared.dailyQiCap ||
                                   HealthManager.shared.convertedMetalQi >= HealthManager.shared.dailyQiCap ||
                                   HealthManager.shared.convertedWaterQi >= HealthManager.shared.dailyQiCap {
                                    Text("根基不稳，灵气虚浮")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                QiCard(title: "金灵气", value: player.metalQi, color: .yellow, sourceText: "卡路里燃烧")
                                QiCard(title: "木灵气", value: player.woodQi, color: .green, sourceText: "行走里程")
                                QiCard(title: "水灵气", value: player.waterQi, color: .blue, sourceText: "静息沉眠")
                                QiCard(title: "火灵气", value: player.fireQi, color: .red, sourceText: "剧烈运动")
                                QiCard(title: "土灵气", value: player.earthQi, color: .brown, sourceText: "日常沉淀")
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                }
                .refreshable {
                    HealthManager.shared.fetchAllData()
                    // 模拟网络/数据加载的短暂等待感
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    
                    // 这里假定如果原本在 App 启动时没有自动同步的话，下拉可以手动触发。
                    // 顺便把 HealthManager 算出来的今日灵气更新给 player
                    // 注意：真实逻辑中，增量同步会更复杂，这里仅为演示更新
                    player.woodQi = HealthManager.shared.convertedWoodQi
                    player.metalQi = HealthManager.shared.convertedMetalQi
                    player.waterQi = HealthManager.shared.convertedWaterQi
                    try? player.managedObjectContext?.save()
                }
            }
            .navigationTitle("洞府大盘")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct QiCard: View {
    let title: String
    let value: Int64
    let color: Color
    let sourceText: String
    
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            // 背面
            VStack(spacing: 8) {
                Text("灵力来源")
                    .font(.caption)
                    .foregroundColor(color.opacity(0.8))
                Text(sourceText)
                    .font(.subheadline)
                    .foregroundColor(.cultivText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 1.0 : 0.0)
            
            // 正面
            VStack(spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(color.opacity(0.8))
                Text("\(value)")
                    .font(.title2.monospacedDigit())
                    .foregroundColor(.cultivText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .opacity(isFlipped ? 0.0 : 1.0)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                isFlipped.toggle()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isFlipped ? "\(title) 的来源是 \(sourceText)" : "\(title), 当前拥有 \(value) 点")
        .accessibilityHint("轻点两下翻转卡片")
        .accessibilityAddTraits(.isButton)
    }
}

struct TimeOfDayBackground: View {
    @State private var hour = Calendar.current.component(.hour, from: Date())
    
    var body: some View {
        ZStack {
            if hour >= 6 && hour < 17 {
                // 白天烈日
                LinearGradient(colors: [Color.blue.opacity(0.3), Color.cultivBg], startPoint: .top, endPoint: .bottom)
                Image(systemName: "sun.max.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                    .foregroundColor(.yellow.opacity(0.15))
                    .offset(x: 100, y: -200)
            } else if hour >= 17 && hour < 19 {
                // 黄昏
                LinearGradient(colors: [Color.orange.opacity(0.2), Color.cultivBg], startPoint: .top, endPoint: .bottom)
            } else {
                // 夜晚星空
                LinearGradient(colors: [Color.black.opacity(0.8), Color.cultivBg], startPoint: .top, endPoint: .bottom)
                // 简单的粒子特效示意
                ForEach(0..<15, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: CGFloat.random(in: 10...20)))
                        .foregroundColor(.white.opacity(Double.random(in: 0.1...0.5)))
                        .offset(
                            x: CGFloat.random(in: -180...180),
                            y: CGFloat.random(in: -350...50)
                        )
                }
            }
        }
        .ignoresSafeArea()
    }
}
