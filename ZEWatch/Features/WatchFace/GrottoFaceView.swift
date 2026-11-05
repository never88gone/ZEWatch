import SwiftUI

// MARK: - 3. 洞天福地盘 (Grotto Face)
public struct GrottoFaceView: View {
    @ObservedObject var player: PlayerProfile
    let config: WatchFaceConfig
    let currentTime: Date
    let isReduced: Bool
    
    public init(player: PlayerProfile, config: WatchFaceConfig, currentTime: Date, isReduced: Bool) {
        self.player = player
        self.config = config
        self.currentTime = currentTime
        self.isReduced = isReduced
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            // 顶部仙山祥云
            HStack(spacing: 4) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 9))
                    .foregroundColor(config.themeColor.primaryColor)
                Text("洞天福地 · 灵草长青")
                    .font(.system(size: 9, weight: .medium, design: .serif))
                    .foregroundColor(config.themeColor.primaryColor)
            }
            .padding(.top, 4)
            
            // 时间展示
            VStack(spacing: 1) {
                Text(TimeTranslator.currentShiChen(date: currentTime))
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(.white)
                
                Text(TimeTranslator.lunarDateString(date: currentTime))
                    .font(.system(size: 10, design: .serif))
                    .foregroundColor(.emerald)
            }
            
            // 寿元与生机同心环
            ZStack {
                // 外环：生机
                Circle()
                    .stroke(Color.emerald.opacity(0.2), lineWidth: 4)
                    .frame(width: 76, height: 76)
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.emerald, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 76, height: 76)
                    .rotationEffect(.degrees(-90))
                
                // 内环：灵泉
                Circle()
                    .stroke(Color.themeCyanPrimary.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: 0.6)
                    .stroke(Color.themeCyanPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(45))
                
                VStack(spacing: 1) {
                    Text("三品")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    Text("灵脉")
                        .font(.system(size: 8, design: .serif))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer(minLength: 2)
            
            // 底部：药田与吐纳
            HStack {
                Text("吐纳吸纳自然灵机")
                    .font(.system(size: 9, design: .serif))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 6)
        }
    }
}
