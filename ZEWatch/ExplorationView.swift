import SwiftUI

struct ExplorationView: View {
    @ObservedObject var player: PlayerProfile
    @EnvironmentObject var healthManager: HealthManager
    @StateObject private var eventEngine = EventEngine.shared
    
    var body: some View {
        ScrollView {
            VStack {
                Text("游历里程")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                // 将步数转化为“里”
                Text("\(Int(healthManager.todaySteps / 1000)) 里")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.brown)
                
                Text("“千里之行，始于足下。”\n每千步转化为一里红尘历练。")
                    .font(.system(size: 9, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("近期奇闻异事：")
                        .font(.footnote)
                        .foregroundColor(.cyan)
                    
                    if eventEngine.randomLogs.isEmpty {
                        Text("今日尚无风波，岁月静好...")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(eventEngine.randomLogs) { event in
                            HStack(alignment: .top) {
                                Text(event.tag)
                                    .font(.system(size: 11, weight: .bold, design: .serif))
                                    .foregroundColor(color(for: event.colorCode))
                                
                                Text(event.description)
                                    .font(.system(size: 11, design: .serif))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
            }
            .padding(.horizontal, 6)
        }
        .onAppear {
            eventEngine.generateEvents(forRealm: player.realm, steps: healthManager.todaySteps)
        }
        .navigationTitle("游历")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 简易 Hex #RRGGBB 颜色解析器
    private func color(for hex: String) -> Color {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") { cString.remove(at: cString.startIndex) }
        guard cString.count == 6 else { return .gray }
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        return Color(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0
        )
    }
}
