import SwiftUI

struct DashboardView: View {
    @ObservedObject var player: PlayerProfile
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.cultivBg.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // 境界总览
                    VStack(spacing: 8) {
                        Text(CultivationEngine.shared.realmName(for: player.realm))
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundColor(.cultivPrimary)
                        
                        Text("当前修为: \(player.cultivationBase)")
                            .font(.subheadline)
                            .foregroundColor(.cultivMuted)
                        
                        ProgressView(value: Double(player.cultivationBase % 1000), total: 1000)
                            .tint(.cultivAccent)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                    
                    // 灵气面板
                    VStack(alignment: .leading, spacing: 16) {
                        Text("五行灵气转化")
                            .font(.headline)
                            .foregroundColor(.cultivText)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            QiCard(title: "金灵气", value: player.metalQi, color: .yellow)
                            QiCard(title: "木灵气", value: player.woodQi, color: .green)
                            QiCard(title: "水灵气", value: player.waterQi, color: .blue)
                            QiCard(title: "火灵气", value: player.fireQi, color: .red)
                            QiCard(title: "土灵气", value: player.earthQi, color: .brown)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
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
    
    var body: some View {
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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
