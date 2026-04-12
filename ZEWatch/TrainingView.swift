import SwiftUI
import CoreData
import WatchKit

struct TrainingView: View {
    @ObservedObject var player: PlayerProfile
    @StateObject private var motionManager = MotionManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedType: CultivationActionType = .body
    let targetGoal = 50 // 每次修炼阶段需达成 50 下标准体感动作
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if motionManager.isTraining {
                activeTrainingView
            } else {
                selectionView
            }
        }
        .navigationTitle("修行")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var selectionView: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text("【 择脉演武 】")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.8, green: 0.7, blue: 0.3))
                
                Text("顺应天道，选择今日修炼的法则")
                    .font(.system(size: 9, design: .serif))
                    .foregroundColor(.gray)
                    .padding(.bottom, 2)
                
                Picker("流派", selection: $selectedType) {
                    ForEach(CultivationActionType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                            .font(.system(size: 11, design: .serif))
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 50)
                
                HStack {
                    professionLevelView(for: selectedType)
                }
                .padding(.vertical, 2)
                
                Button(action: {
                    motionManager.startTraining(type: selectedType)
                    WKInterfaceDevice.current().play(.start)
                }) {
                    Text("起阵入定")
                        .font(.system(.body, design: .serif))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.8, green: 0.2, blue: 0.1))
            }
            .padding(.horizontal, 8)
        }
    }
    
    var activeTrainingView: some View {
        VStack(spacing: 6) {
            Text("「 \(selectedType.rawValue) 」")
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundColor(.cyan)
                .shadow(color: .cyan, radius: 2)
            
            Text(gettingHints(for: selectedType))
                .font(.system(size: 10, design: .serif))
                .foregroundColor(.gray)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(motionManager.currentActionCount) / CGFloat(targetGoal))
                    .stroke(LinearGradient(colors: [.yellow, .red], startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: motionManager.currentActionCount)
                
                VStack(spacing: 0) {
                    Text("\(motionManager.currentActionCount)")
                        .font(.system(size: 32, weight: .black, design: .serif))
                        .foregroundColor(.white)
                    Text("/ \(targetGoal)")
                        .font(.system(size: 10, design: .serif))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: 88, height: 88)
            .padding(.vertical, 2)
            
            if motionManager.currentActionCount >= targetGoal {
                Button("大满周天 (收功)") {
                    finishTraining()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .font(.system(size: 14, weight: .bold, design: .serif))
            } else {
                Button("中止逆流") {
                    motionManager.stopTraining()
                    WKInterfaceDevice.current().play(.failure)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .font(.system(size: 12, design: .serif))
            }
        }
    }
    
    @ViewBuilder
    private func professionLevelView(for type: CultivationActionType) -> some View {
        VStack(spacing: 1) {
            Text("道果阶段")
                .font(.system(size: 8, design: .serif))
                .foregroundColor(.gray)
            let level = getLevel(for: type)
            Text("第 \(level) 重")
                .font(.system(size: 14, weight: .black, design: .serif))
                .foregroundColor(.yellow)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.4), lineWidth: 1))
    }
    
    private func getLevel(for type: CultivationActionType) -> Int16 {
        switch type {
        case .body: return player.bodyLevel
        case .sword: return player.swordLevel
        case .talisman: return player.talismanLevel
        case .alchemy: return player.alchemyLevel
        }
    }
    
    private func gettingHints(for type: CultivationActionType) -> String {
        switch type {
        case .body: return "保持重心，向前爆发挥拳..."
        case .sword: return "感受剑风，大幅度挥劈空间..."
        case .talisman: return "屏除杂念，空中转手画印..."
        case .alchemy: return "平端手臂，匀速画圈搅拌丹炉..."
        }
    }
    
    private func finishTraining() {
        motionManager.stopTraining()
        WKInterfaceDevice.current().play(.success)
        
        switch selectedType {
        case .body: player.bodyLevel += 1; player.physique += 2
        case .sword: player.swordLevel += 1; player.boneRoot += 2
        case .talisman: player.talismanLevel += 1; player.wisdom += 2
        case .alchemy: player.alchemyLevel += 1; player.lucky += 2
        }
        
        // 增加大量基础修为 (挂钩大境界)
        let reward = 2000 * Int64(player.realm + 1)
        player.cultivationBase += reward
        
        // 通过 WCSession 实时透传至伴生 App 大模型核心
        ConnectivityManager.shared.sendSyncData([
            "bodyLevel": player.bodyLevel,
            "swordLevel": player.swordLevel,
            "talismanLevel": player.talismanLevel,
            "alchemyLevel": player.alchemyLevel,
            "realm": player.realm,
            "cultivationBase": player.cultivationBase
        ])
        
        do {
            try viewContext.save()
        } catch {
            print(error)
        }
    }
}
