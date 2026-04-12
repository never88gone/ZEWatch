import SwiftUI
import UIKit

struct CompanionSettingsView: View {
    @ObservedObject var player: PlayerProfile
    @ObservedObject var llm = LLMManager.shared
    
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
            }
            .listStyle(.insetGrouped)
            .navigationTitle("洞府设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
