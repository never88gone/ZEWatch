import SwiftUI
import WatchKit
import CoreData

struct MissionView: View {
    @ObservedObject var player: PlayerProfile
    @EnvironmentObject var healthManager: HealthManager
    @StateObject private var missionEngine = MissionEngine.shared
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("【 天道降任 】")
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(Color(red: 0.8, green: 0.7, blue: 0.3))
                        Spacer()
                    }
                    
                    if missionEngine.currentMissions.isEmpty {
                        Text("今日乾坤未定，暂无天道试炼...")
                            .font(.system(size: 12, design: .serif))
                            .foregroundColor(.gray)
                    } else {
                        ForEach(missionEngine.currentMissions.indices, id: \.self) { index in
                            let mission = missionEngine.currentMissions[index]
                            let currentValue = currentValue(for: mission.targetType)
                            let isDone = currentValue >= mission.targetValue || mission.isCompleted
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("卷轴: \(mission.title)")
                                        .font(.system(size: 13, weight: .bold, design: .serif))
                                        .foregroundColor(isDone ? .green : .cyan)
                                    Spacer()
                                    if mission.isCompleted {
                                        Text("已履约").font(.system(size: 10, design: .serif)).foregroundColor(.green)
                                    }
                                }
                                
                                Text("『 \(mission.description) 』")
                                    .font(.system(size: 11, design: .serif))
                                    .foregroundColor(.gray)
                                    .italic()
                                
                                ProgressView(value: min(currentValue, mission.targetValue), total: mission.targetValue)
                                    .tint(isDone ? LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing))
                                    .background(Color.white.opacity(0.1))
                                    .scaleEffect(y: 0.5)
                                    .padding(.vertical, 2)
                                
                                if isDone && !mission.isCompleted {
                                    Button(action: { claimReward(for: index) }) {
                                        Text("汲取天道恩赐 (\(mission.rewardCultivation) 真气)")
                                            .font(.system(size: 11, design: .serif))
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Color(red: 0.1, green: 0.4, blue: 0.2))
                                } else if !mission.isCompleted {
                                    HStack {
                                        Spacer()
                                        Text("\(Int(currentValue)) / \(Int(mission.targetValue))")
                                            .font(.system(size: 9, design: .serif))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(white: 0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(red: 0.4, green: 0.3, blue: 0.1), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 6)
            }
        }
        .onAppear {
            if missionEngine.currentMissions.isEmpty {
                missionEngine.generateDailyMissions(for: player)
            }
        }
        .navigationTitle("试炼")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func currentValue(for type: CultivationMission.MissionType) -> Double {
        switch type {
        case .steps: return healthManager.todaySteps
        case .energy: return healthManager.todayEnergy
        case .mindfulness: return 0
        }
    }
    
    private func claimReward(for index: Int) {
        let mission = missionEngine.currentMissions[index]
        player.cultivationBase += mission.rewardCultivation
        missionEngine.currentMissions[index].isCompleted = true
        
        do {
            try viewContext.save()
            WKInterfaceDevice.current().play(.success)
        } catch {
            print(error)
        }
    }
}
