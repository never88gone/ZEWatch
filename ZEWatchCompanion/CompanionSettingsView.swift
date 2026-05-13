import SwiftUI
import UIKit

struct CompanionSettingsView: View {
    @ObservedObject var player: PlayerProfile
    @ObservedObject var llm = LLMManager.shared
    @ObservedObject var healthManager = HealthManager.shared
    
    @AppStorage("hapticFeedbackEnabled") private var hapticEnabled = true
    @AppStorage("autoSettleOfflineGains") private var autoSettle = true
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - 修行偏好
                Section {
                    Toggle(isOn: $hapticEnabled) {
                        Label("触感反馈 (共鸣)", systemImage: "waveform.path")
                    }
                    .tint(.cultivPrimary)
                    
                    Toggle(isOn: $autoSettle) {
                        Label("自动结算闭关收益", systemImage: "clock.arrow.circlepath")
                    }
                    .tint(.cultivPrimary)
                } header: {
                    Text("修行偏好")
                }
                
                // MARK: - 健康数据 (HealthKit)
                Section {
                    HStack {
                        Label("授权状态", systemImage: "heart.fill")
                            .foregroundColor(.red)
                        Spacer()
                        if healthManager.isAuthorized {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Text("已授权")
                                    .foregroundColor(.green)
                            }
                        } else {
                            Button {
                                HealthManager.shared.requestAuthorization { success, error in
                                    // 回调处理已在 HealthManager 中完成
                                }
                            } label: {
                                Text("去授权")
                                    .font(.system(size: 13, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.cultivPrimary)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .font(.callout)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("本应用通过 Apple HealthKit 读取以下健康数据，将其转化为游戏内的五行灵气。**所有数据仅在设备本地处理，绝不上传至任何服务器。**")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        companionHealthRow(icon: "figure.walk", label: "步数", element: "木灵气", color: .green)
                        companionHealthRow(icon: "flame.fill", label: "活动卡路里", element: "金灵气", color: .orange)
                        companionHealthRow(icon: "bed.double.fill", label: "睡眠分析", element: "水灵气", color: .blue)
                        companionHealthRow(icon: "heart.text.square", label: "心率数据", element: "奇遇触发", color: .red)
                        companionHealthRow(icon: "figure.run", label: "运动记录", element: "五行灵气", color: .cyan)
                        companionHealthRow(icon: "figure.stand", label: "站立小时", element: "木灵气", color: .green)
                    }
                    
                    Button {
                        if let url = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("前往「健康」管理数据权限", systemImage: "arrow.up.forward.app.fill")
                            .foregroundColor(.cultivPrimary)
                    }
                } header: {
                    Text("健康数据 (HealthKit)")
                }
                
                // MARK: - 识海阵法 (AI)
                Section {
                    HStack {
                        Label("天道模型", systemImage: "cpu")
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: llm.modelLoaded ? "checkmark.circle.fill" : "exclamationmark.circle")
                                .foregroundColor(llm.modelLoaded ? .green : .cultivAccent)
                            Text(llm.modelLoaded ? "已连接" : "待唤醒")
                                .foregroundColor(llm.modelLoaded ? .green : .cultivAccent)
                        }
                        .font(.callout)
                    }
                    
                    if llm.isGenerating {
                        HStack {
                            Label("推演中", systemImage: "sparkles")
                            Spacer()
                            ProgressView().tint(.cultivPrimary)
                        }
                    }
                } header: {
                    Text("识海阵法 (AI)")
                }
                
                // MARK: - 道途统计
                Section {
                    HStack {
                        Label("当前大境界", systemImage: "mountain.2.fill")
                        Spacer()
                        Text(CultivationEngine.shared.realmName(for: player.realm))
                            .font(.callout.bold())
                            .foregroundColor(.cultivSecondary)
                    }
                    HStack {
                        Label("累计真气", systemImage: "bolt.fill")
                        Spacer()
                        Text("\(player.cultivationBase)")
                            .font(.system(.callout, design: .monospaced).bold())
                            .foregroundColor(.cultivPrimary)
                    }
                } header: {
                    Text("道途统计")
                }
                
                // MARK: - 宗门
                Section {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        GameKitManager.shared.authenticateUser()
                    } label: {
                        Label("重新连接宗门玉牌", systemImage: "gamecontroller.fill")
                            .foregroundColor(.cultivPrimary)
                    }
                }
                
                // MARK: - 关于
                Section {
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label("隐私政策", systemImage: "hand.raised.fill")
                            .foregroundColor(.cultivPrimary)
                    }
                } header: {
                    Text("关于")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("洞府设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    @ViewBuilder
    private func companionHealthRow(icon: String, label: String, element: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
            Text(element)
                .font(.caption.bold())
                .foregroundColor(color)
        }
    }
}

struct PrivacyPolicyView: View {
    let policyText = """
    # 隐私政策 (Privacy Policy)
    
    **应用名称**: 糖葫芦修仙
    
    我们极其重视您的隐私。在此，我们做出明确声明：
    
    **本应用程序绝对不会收集、存储、传输或分享您的任何个人隐私信息。**
    
    ## 具体说明
    
    1. **零数据收集**: 我们不会收集您的设备信息、使用习惯、定位数据、面部数据或任何能够识别您个人身份的直接/间接信息。
    2. **纯本地运行**: 本应用内发生的所有数据处理和计算，完全在您的个人设备上本地完成，不会将任何信息上传至任何云端或第三方服务器。
    3. **健康与传感器数据**: 若应用请求获取您的健康数据（如心率、运动数据）或设备传感器数据（如加速度计），仅是为了在设备本地实现应用的实时功能。我们将仅在您授权的情况下来读取这些数据，承诺绝不会将其传出您的设备，也不会用于分析或追踪。
    4. **无需注册**: 您在使用各项功能时，均无需创建账户或提供个人联系方式。
    
    本隐私政策自始至终生效，若您有任何疑问，可以随时联络我们。
    """
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(policyText))
                    .padding()
            }
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }
}
