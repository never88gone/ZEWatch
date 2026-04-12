import SwiftUI
import CoreData

struct CreationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isCreating = false
    
    var body: some View {
        VStack(spacing: 12) {
            Text("仙缘已至")
                .font(.headline)
                .foregroundColor(.cyan)
            
            Text("机缘巧合下，你踏上了漫漫修仙路...")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Button(action: {
                let _ = CultivationEngine.shared.generateInitialProfile(context: viewContext)
                do {
                    try viewContext.save()
                } catch {
                    print("保存初始存档失败: \(error)")
                }
            }) {
                Text("降生此界")
                    .fontWeight(.bold)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }
}
