import SwiftUI
import CoreData

struct SkillLibraryView: View {
    @ObservedObject var player: PlayerProfile
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest(
        entity: SkillManual.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SkillManual.elementReq, ascending: true),
                          NSSortDescriptor(keyPath: \SkillManual.skillType, ascending: true)]
    )
    private var allSkills: FetchedResults<SkillManual>
    
    @ObservedObject private var engine = SkillActionEngine.shared
    @State private var resultAlert = ""
    @State private var showingAlert = false
    @State private var selectedFilter: String? = nil
    
    private let elementFilters = ["全部", "金", "木", "水", "火", "土"]
    private let elementColors: [String: Color] = [
        "金": .orange, "木": .green, "水": .blue, "火": .red, "土": .brown
    ]
    
    var filteredSkills: [SkillManual] {
        guard let f = selectedFilter, f != "全部" else {
            return Array(allSkills)
        }
        return allSkills.filter { $0.elementReq == f }
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 10) {
                    // 标题
                    Text("【 藏经阁 】")
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(Color(red: 0.8, green: 0.7, blue: 0.3))
                        .padding(.top, 8)
                    
                    // 五行灵气资产栏 + 上限提示
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            elementAsset(em: "金", val: player.metalQi)
                            elementAsset(em: "木", val: player.woodQi)
                            elementAsset(em: "水", val: player.waterQi)
                            elementAsset(em: "火", val: player.fireQi)
                            elementAsset(em: "土", val: player.earthQi)
                        }
                        Text("属性上限：\(player.qiCap())")
                            .font(.system(size: 8))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(Color(white: 0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 6)
                    
                    // 主动功法提示
                    if let activeName = engine.activeSkillName {
                        Text("⚡ \(activeName) 运行中...")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                    
                    if !engine.activeSkillResult.isEmpty {
                        Text(engine.activeSkillResult)
                            .font(.system(size: 9, design: .serif))
                            .foregroundColor(.yellow)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                            .padding(.top, 4)
                    }
                    
                    // 功法列表
                    LazyVStack(spacing: 6) {
                        ForEach(filteredSkills, id: \.id) { skill in
                            SkillRow(skill: skill, player: player, elementColors: elementColors) {
                                handleSkillTap(skill)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .onAppear {
            SkillActionEngine.shared.seedSkillsIfNeeded(for: player, context: context)
        }
        .navigationTitle("藏经阁")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func elementAsset(em: String, val: Int64) -> some View {
        VStack(spacing: 1) {
            Text(em).font(.system(size: 10, weight: .bold, design: .serif))
                .foregroundColor(elementColors[em] ?? .white)
            Text("\(val)").font(.system(size: 8, design: .monospaced))
                .foregroundColor(.white)
        }
    }
    
    private func handleSkillTap(_ skill: SkillManual) {
        if !skill.isUnlocked {
            // 习得功法
            let result = SkillActionEngine.shared.unlockSkill(skill, profile: player, context: context)
            engine.activeSkillResult = result
        } else if skill.skillType == 1 && skill.name == "燃血遁法" {
            // 激活主动功法
            Task { @MainActor in
                SkillActionEngine.shared.activateBloodBurning(profile: player, context: context)
            }
        } else if skill.skillType == 0 {
            // 升级被动心法
            let result = SkillActionEngine.shared.upgradeSkill(skill, profile: player, context: context)
            engine.activeSkillResult = result
        }
    }
}

struct SkillRow: View {
    let skill: SkillManual
    let player: PlayerProfile
    let elementColors: [String: Color]
    let onTap: () -> Void
    
    var body: some View {
        let elem = skill.elementReq ?? "土"
        let color = elementColors[elem] ?? .gray
        let locked = !skill.isUnlocked
        let progress = Double(skill.level) / 10.0
        
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    // 属性角标
                    Text(elem)
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundColor(color)
                        .frame(width: 18)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        HStack {
                            Text(skill.name ?? "")
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .foregroundColor(locked ? .gray : .white)
                            if skill.skillType == 1 {
                                Text("主动")
                                    .font(.system(size: 8))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 3)
                                    .background(Color.red.opacity(0.2))
                                    .cornerRadius(3)
                            } else if !locked {
                                Text("Lv.\(skill.level)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.cyan)
                                    .padding(.horizontal, 3)
                                    .background(Color.cyan.opacity(0.15))
                                    .cornerRadius(3)
                            }
                        }
                        
                        // 描述/费用提示
                        if locked {
                            Text("需 \(skill.costAmount) \(elem)气")
                                .font(.system(size: 9, design: .serif))
                                .foregroundColor(color.opacity(0.7))
                        } else if skill.skillType == 0 && skill.level < 10 {
                            let nextCost = Int64(Double(skill.costAmount) * pow(1.5, Double(skill.level)))
                            Text("突破需 \(nextCost) \(elem)气")
                                .font(.system(size: 9, design: .serif))
                                .foregroundColor(.orange.opacity(0.8))
                        } else if skill.level >= 10 {
                            Text("功参造化，已臻圆满")
                                .font(.system(size: 9, design: .serif))
                                .foregroundColor(.yellow)
                        } else {
                            Text("已入定，可随时施展")
                                .font(.system(size: 9, design: .serif))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                    
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    } else if skill.skillType == 1 {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    } else if skill.level < 10 {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(locked ? Color(white: 0.08) : Color(white: 0.12))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(locked ? Color.gray.opacity(0.2) : color.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
