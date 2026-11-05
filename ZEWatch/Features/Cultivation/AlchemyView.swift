import SwiftUI
import CoreData
import Combine

#if os(watchOS)
import WatchKit

// MARK: - AlchemySection (高频更新隔离组件，防止污染主 ScrollView 性能)
public struct AlchemySection: View {
    @ObservedObject var player: PlayerProfile
    @Environment(\.managedObjectContext) var moc
    
    // 内部状态完全隔离，不触发父视图重绘
    @State private var crownValue: Double = 0.0
    @State private var fireIntensity: Double = 0.0
    @State private var targetRange: ClosedRange<Double> = 0.4...0.6
    @State private var purification: Double = 0.0
    @State private var isAlchemizing = false
    @State private var showResult = false
    @State private var resultMessage = ""
    @FocusState private var isFocused: Bool
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    public init(player: PlayerProfile) {
        self.player = player
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            Text("「 乾坤丹炉 」")
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundColor(.orange)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 4)
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: targetRange.lowerBound * 0.75, to: targetRange.upperBound * 0.75)
                    .stroke(Color.green.opacity(0.5), lineWidth: 8)
                    .rotationEffect(.degrees(135))
                    .frame(width: 80, height: 80)
                
                Capsule()
                    .fill(Color.red)
                    .frame(width: 4, height: 30)
                    .offset(y: -25)
                    .rotationEffect(.degrees((fireIntensity * 270) - 135))
                
                Circle()
                    .fill(RadialGradient(colors: [fireColor, .clear], center: .center, startRadius: 5, endRadius: 25))
                    .frame(width: 50, height: 50)
                    .scaleEffect(isAlchemizing ? 1.0 + (fireIntensity * 0.2) : 1.0)
            }
            .padding(.vertical, 2)
            
            VStack(spacing: 2) {
                HStack {
                    Text("提纯度")
                        .font(.system(size: 8))
                    Spacer()
                    Text("\(Int(purification * 100))%")
                        .font(.system(size: 8))
                }
                .foregroundColor(.gray)
                
                ProgressView(value: purification, total: 1.0)
                    .tint(.cyan)
                    .scaleEffect(y: 0.5)
            }
            .padding(.horizontal, 20)
            
            Button(action: {
                if isAlchemizing {
                    stopAlchemy()
                } else {
                    startAlchemy()
                }
            }) {
                Text(isAlchemizing ? "凝丹！" : "开启丹炉")
                    .font(.caption2)
            }
            .tint(isAlchemizing ? .red : .blue)
            .padding(.top, 2)
        }
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.02))
        .cornerRadius(12)
        .focusable(true)
        .focused($isFocused)
        .digitalCrownRotation($crownValue, from: 0, through: 1.0, by: 0.02, sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
        .onAppear {
            isFocused = true
        }
        .onReceive(timer) { _ in
            if isAlchemizing {
                updateAlchemy()
            }
        }
        .alert(isPresented: $showResult) {
            Alert(title: Text("炼丹告谕"), message: Text(resultMessage), dismissButton: .default(Text("知晓")))
        }
    }
    
    private var fireColor: Color {
        if fireIntensity < 0.3 { return .orange }
        if fireIntensity < 0.7 { return .red }
        return .purple
    }
    
    private func startAlchemy() {
        guard player.metalQi >= 50 && player.woodQi >= 50 && player.waterQi >= 50 && player.fireQi >= 50 && player.earthQi >= 50 else {
            resultMessage = "五行灵气不足以支撑开炉之火。"
            showResult = true
            return
        }
        
        isAlchemizing = true
        purification = 0
        targetRange = Double.random(in: 0.1...0.3)...Double.random(in: 0.7...0.9)
    }
    
    private func updateAlchemy() {
        fireIntensity += (crownValue - fireIntensity) * 0.3
        
        if targetRange.contains(fireIntensity) {
            purification += 0.005
            if purification >= 1.0 {
                stopAlchemy(success: true)
            }
        } else {
            purification = max(0, purification - 0.002)
            if fireIntensity < targetRange.lowerBound {
                WKInterfaceDevice.current().play(.directionUp)
            } else {
                WKInterfaceDevice.current().play(.directionDown)
            }
        }
    }
    
    private func stopAlchemy(success: Bool = false) {
        isAlchemizing = false
        if success {
            player.pillsCount += 1
            player.metalQi -= 50
            player.woodQi -= 50
            player.waterQi -= 50
            player.fireQi -= 50
            player.earthQi -= 50
            
            try? moc.save()
            resultMessage = "造化垂青，获得一枚「破境丹」！"
            WKInterfaceDevice.current().play(.success)
        } else if purification > 0 {
            resultMessage = "火候失准，未能成药。提纯度: \(Int(purification * 100))%"
            WKInterfaceDevice.current().play(.failure)
        }
        
        if resultMessage != "" {
            showResult = true
        }
    }
}
#endif
