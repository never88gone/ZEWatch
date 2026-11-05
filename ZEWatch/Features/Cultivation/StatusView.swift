import SwiftUI
import CoreData
import Combine

#if os(watchOS)
import WatchKit

struct StatusView: View {
    @ObservedObject var player: PlayerProfile
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 12) {
                    // 灵牌头部
                    Text("【 宗门玉牌 】")
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(Color(red: 0.8, green: 0.7, blue: 0.3)) // 古铜金
                        .padding(.top, 8)
                    
                    // 境界边框与核心展示
                    VStack {
                        Text(CultivationEngine.shared.realmName(for: player.realm))
                            .font(.system(size: 26, weight: .black, design: .serif))
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan.opacity(0.5), radius: 5)
                        
                        if let req = CultivationEngine.shared.requirementForNextRealm(currentLevel: player.realm) {
                            Text("\(player.cultivationBase) / \(req) 真气")
                                .font(.system(size: 10, weight: .medium, design: .serif))
                                .foregroundColor(.gray)
                                .padding(.top, 2)
                        } else {
                            Text("已满，天人合一阶段")
                                .font(.system(size: 11, design: .serif))
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
                    
                    // 新增：明确标识数据来源
                    HStack(spacing: 4) {
                        Image(systemName: "heart.text.square.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 8))
                        Text("数据源自 Apple HealthKit")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, -4)
                    
                    // 突破大键
                    if CultivationEngine.shared.canBreakthrough(profile: player) {
                        NavigationLink(destination: TribulationView(player: player)) {
                            HStack {
                                Text("引天雷 / 破万法")
                                    .font(.system(.body, design: .serif))
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.black)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.9, green: 0.8, blue: 0.2))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("✧ 先天道基 (灵根资质)")
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(Color(red: 0.8, green: 0.7, blue: 0.3))
                        
                        Grid(horizontalSpacing: 8, verticalSpacing: 6) {
                            GridRow {
                                rootCell(label: "金", value: player.metalRoot)
                                rootCell(label: "木", value: player.woodRoot)
                            }
                            GridRow {
                                rootCell(label: "水", value: player.waterRoot)
                                rootCell(label: "火", value: player.fireRoot)
                            }
                            GridRow {
                                rootCell(label: "土", value: player.earthRoot)
                                rootCell(label: "机缘", value: player.lucky, isSpecial: true)
                            }
                        }
                        
                        Divider().background(Color.gray.opacity(0.3))
                        
                        HStack {
                            Text("根骨: \(player.boneRoot)").foregroundColor(.white)
                            Spacer()
                            Text("悟性: \(player.wisdom)").foregroundColor(.white)
                            Spacer()
                            Text("体魄: \(player.physique)").foregroundColor(.white)
                        }
                        .font(.system(size: 9))
                    }
                    .font(.system(size: 11, design: .serif))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color(white: 0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, 4)
                
                VStack(spacing: 4) {
                    Text("☯︎ 五行聚灵阵")
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(.cyan.opacity(0.8))
                        .padding(.top, 4)
                        
                    HStack(spacing: 8) {
                        ElementColumn(element: "金", value: player.metalQi, color: .orange)
                        ElementColumn(element: "木", value: player.woodQi, color: .green)
                        ElementColumn(element: "水", value: player.waterQi, color: .blue)
                        ElementColumn(element: "火", value: player.fireQi, color: .red)
                        ElementColumn(element: "土", value: player.earthQi, color: .brown)
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 6)
                }
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.12))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 4)
                .padding(.top, 6)
                
                // MARK: - 健康数据 (HealthKit) 标识面板
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                        Text("健康数据 (HealthKit)")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: HealthManager.shared.isAuthorized ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(HealthManager.shared.isAuthorized ? .green : .orange)
                            .font(.system(size: 9))
                        Text(HealthManager.shared.isAuthorized ? "已连接 Apple Health" : "未连接健康应用")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(HealthManager.shared.isAuthorized ? .green : .orange)
                        
                        if !HealthManager.shared.isAuthorized {
                            Button(action: {
                                // 引导用户去设置
                                if let url = URL(string: "ms-apple-health://") { // Watch 端的健康 URL
                                    WKExtension.shared().openSystemURL(url)
                                }
                            }) {
                                Text("去开启")
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("本应用通过 Apple HealthKit 读取以下数据，全部在设备本地处理：")
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                        
                        healthDataRow(icon: "figure.walk", label: "步数", purpose: "→ 木灵气")
                        healthDataRow(icon: "flame.fill", label: "活动卡路里", purpose: "→ 金灵气")
                        healthDataRow(icon: "bed.double.fill", label: "睡眠时长", purpose: "→ 水灵气")
                        healthDataRow(icon: "heart.text.square", label: "心率", purpose: "→ 奇遇触发")
                        healthDataRow(icon: "figure.run", label: "运动记录", purpose: "→ 五行灵气")
                        healthDataRow(icon: "figure.stand", label: "站立小时", purpose: "→ 木灵气")
                    }
                    
                    Text("管理权限：系统设置 → 健康 → 数据访问")
                        .font(.system(size: 7))
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.top, 2)
                }
                .padding(8)
                .background(Color(white: 0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red.opacity(0.2), lineWidth: 0.5)
                )
                .padding(.horizontal, 4)
                .padding(.top, 8)
                
                NavigationLink(destination: WatchPrivacyPolicyView()) {
                    Text("隐私政策")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .underline()
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                
                Spacer(minLength: 20)
            }
        }
        .onAppear {
            CultivationEngine.shared.seedRoots(profile: player)
        }
        .navigationTitle("灵牌")
        .navigationBarTitleDisplayMode(.inline)
    }
    private func healthDataRow(icon: String, label: String, purpose: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(.cyan.opacity(0.7))
                .frame(width: 12)
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            Spacer()
            Text(purpose)
                .font(.system(size: 8, weight: .bold, design: .serif))
                .foregroundColor(.cyan)
        }
    }
    
    private func rootCell(label: String, value: Int16, isSpecial: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(isSpecial ? .yellow : .cyan.opacity(0.8))
            Text("\(value)%")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(4)
    }
}

struct ElementColumn: View {
    let element: String
    let value: Int64
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(element)
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(color)
            Text("\(value)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

#endif
