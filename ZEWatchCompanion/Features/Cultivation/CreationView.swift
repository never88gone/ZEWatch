import SwiftUI

struct CreationView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Text("【 待 缘 】")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(.gray)
                Text("请先于灵表 (watchOS) 开启修仙之路。")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
    }
}
