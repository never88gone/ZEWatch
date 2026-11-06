import SwiftUI
import Symbols

#if os(iOS)
public struct ElderHeaderView: View {
    @ObservedObject var player: PlayerProfile
    
    public init(player: PlayerProfile) {
        self.player = player
    }
    
    public var body: some View {
        HStack(spacing: 15) {
            // 老爷爷头像
            ZStack {
                Circle()
                    .stroke(LinearGradient(colors: [.cultivAccent, .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                    .frame(width: 60, height: 60)
                
                if #available(iOS 17.0, *) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 30))
                        .foregroundColor(.cultivAccent)
                        .opacity(0.8)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                } else {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 30))
                        .foregroundColor(.cultivAccent)
                        .opacity(0.8)
                }
            }
            .background(
                Circle()
                    .fill(Color.cultivAccent.opacity(0.1))
                    .blur(radius: 5)
            )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("墨老")
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(.cultivAccent)
                    Text("（残魂状态）")
                        .font(.caption2)
                        .foregroundColor(.cultivMuted)
                }
                
                Text(CultivationEngine.shared.realmName(for: player.realm))
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.cultivPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.cultivPrimary.opacity(0.15)))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("修为: \(player.cultivationBase)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.cultivText)
                
                ProgressView(value: Double(player.cultivationBase % 1000), total: 1000)
                    .tint(.cultivAccent)
                    .frame(width: 80)
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.05)), alignment: .bottom)
    }
}

public struct InitialDownloadGuideCard: View {
    var onGoToSettings: (() -> Void)?
    var onOpenModelSelection: () -> Void
    var onImportFile: () -> Void
    
    public init(onGoToSettings: (() -> Void)? = nil, onOpenModelSelection: @escaping () -> Void, onImportFile: @escaping () -> Void) {
        self.onGoToSettings = onGoToSettings
        self.onOpenModelSelection = onOpenModelSelection
        self.onImportFile = onImportFile
    }
    
    public var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Color.cultivAccent.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundColor(.cultivAccent)
            }
            .padding(.top, 16)
            
            VStack(spacing: 10) {
                Text("识海空明 · 戒灵未凝")
                    .font(.title2.bold())
                    .foregroundColor(.cultivText)
                
                Text("本法宝遵循极简轻灵原则，**安装包未内置大模型**。")
                    .font(.subheadline)
                    .foregroundColor(.cultivSecondary)
                    .multilineTextAlignment(.center)
                
                Text("请前往「须邪戒 (设置)」挑选并接引心法法器。下载后将长驻本地沙盒，无需联网即可与墨老神念传音。")
                    .font(.footnote)
                    .foregroundColor(.cultivMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
            }
            
            Button {
                if let onGo = onGoToSettings {
                    onGo()
                } else {
                    onOpenModelSelection()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                    Text("前往设置挑选并接引法器")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.cultivPrimary, Color.cultivAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.cultivAccent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .accessibilityIdentifier("goto_settings_download_button")
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            Button {
                onImportFile()
            } label: {
                Label("从本地导入已有法器 (.gguf)", systemImage: "folder.badge.plus")
                    .font(.caption)
                    .foregroundColor(.cultivSecondary)
            }
            .padding(.bottom, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
#endif
