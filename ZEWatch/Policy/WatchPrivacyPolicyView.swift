import SwiftUI

#if os(watchOS)
public struct WatchPrivacyPolicyView: View {
    let policyText = """
    # 隐私政策
    
    应用名称: 糖葫芦修仙
    
    我们极其重视您的隐私。
    
    本应用绝对不会收集、传输或分享您的任何个人隐私信息。所有修行、境界与个人数据均完全保留在您的设备本地。
    
    若有任何疑问，请随时联络我们。
    """
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(policyText))
                    .font(.system(size: 12))
                    .padding()
            }
        }
        .navigationTitle("隐私")
    }
}
#endif
