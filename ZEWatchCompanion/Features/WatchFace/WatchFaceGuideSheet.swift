import SwiftUI
import UIKit

// MARK: - Apple Watch 修仙表盘与常驻模式完全指南
public struct WatchFaceGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerBanner
                    alwaysOnGuideCard
                    complicationGuideCard
                    tipsCard
                }
                .padding(16)
            }
            .background(Color.cultivBg.ignoresSafeArea())
            .navigationTitle("表盘设置指南")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.themeCyanPrimary)
                }
            }
        }
    }
    
    // MARK: - 顶部装饰
    private var headerBanner: some View {
        VStack(spacing: 8) {
            Image(systemName: "applewatch.side.right")
                .font(.system(size: 38))
                .foregroundColor(.themeCyanPrimary)
            
            Text("两种方式玩转 Apple Watch 修仙")
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.themeCyanPrimary.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 指引 1：全屏常驻修仙表盘
    private var alwaysOnGuideCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.themeCyanPrimary.opacity(0.2))
                        .frame(width: 28, height: 28)
                    Text("1")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.themeCyanPrimary)
                }
                Text("全屏沉浸【本命灵盘】常驻模式")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            
            Text("这是最极致的修仙体验：拥有十二时辰流转、太极阴阳自转、灵气波纹与微光熄屏节能。")
                .font(.caption)
                .foregroundColor(.cultivMuted)
            
            VStack(alignment: .leading, spacing: 6) {
                stepRow(num: "A", title: "打开 Apple Watch 的【系统设置】；")
                stepRow(num: "B", title: "点击【通用】 > 【返回时钟】；")
                stepRow(num: "C", title: "向下滚动找到【ZEWatch】，点击进入；")
                stepRow(num: "D", title: "勾选【自定】，并选择【1小时后】或【始终】。")
            }
            .padding(10)
            .background(Color.white.opacity(0.03))
            .cornerRadius(10)
            
            Text("设置后，打开 ZEWatch 即可将其作为常驻修仙表盘，抬腕即看！")
                .font(.caption2)
                .foregroundColor(.themeCyanPrimary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.08))
        )
    }
    
    // MARK: - 指引 2：系统表盘复杂功能 (Complication)
    private var complicationGuideCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.themeGoldPrimary.opacity(0.2))
                        .frame(width: 28, height: 28)
                    Text("2")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.themeGoldPrimary)
                }
                Text("添加修仙组件至官方系统表盘")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            
            Text("若喜欢苹果官方表盘（如模块化、加州、子午线），可将修仙境界与灵气作为复杂功能添加到表盘中：")
                .font(.caption)
                .foregroundColor(.cultivMuted)
            
            VStack(alignment: .leading, spacing: 6) {
                stepRow(num: "A", title: "在 Apple Watch 上长按当前表盘，轻点【编辑】；")
                stepRow(num: "B", title: "轻扫至【复杂功能 (Complications)】；")
                stepRow(num: "C", title: "轻点任意槽位，旋转表冠找到【ZEWatch】；")
                stepRow(num: "D", title: "选择【灵气收集簿】或【当前境界】即可实时显示。")
            }
            .padding(10)
            .background(Color.white.opacity(0.03))
            .cornerRadius(10)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.08))
        )
    }
    
    // MARK: - 贴心提示
    private var tipsCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.cultivSecondary)
                .font(.subheadline)
            Text("提示：当在手机端点击【同步到 Apple Watch】时，无论手表当前是否点亮，数据都会通过保活队列可靠投递。手表收到后会发出仙道双连震感并自动刷新样式。")
                .font(.caption2)
                .foregroundColor(.cultivMuted)
                .lineSpacing(3)
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
    
    private func stepRow(num: String, title: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("[\(num)]")
                .font(.caption.bold())
                .foregroundColor(.cultivSecondary)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}
