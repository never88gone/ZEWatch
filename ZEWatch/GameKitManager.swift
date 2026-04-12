import Foundation
import GameKit
import Combine

@objc(GameKitManager)
public final class GameKitManager: NSObject, ObservableObject, GKLocalPlayerListener {
    public static let shared = GameKitManager()
    
    @Published public var isAuthenticated = false
    @Published public var lastError: String?
    
    private override init() {
        super.init()
    }
    
    public func authenticateUser() {
        let localPlayer = GKLocalPlayer.local
        
        localPlayer.authenticateHandler = { [weak self] (vc, error) in
            if let error = error {
                self?.lastError = error.localizedDescription
                return
            }
            
            if localPlayer.isAuthenticated {
                self?.isAuthenticated = true
                localPlayer.register(self!)
                print("【GameCenter】认证成功: \(localPlayer.displayName)")
            } else if let vc = vc as? UIViewController {
                // 对于 iOS，这里可以弹出登录界面
                // 对于 watchOS，通常不需要在这里处理 VC 弹出，因为 authenticateHandler(vc:error:) 在 watch 上有不同表现
                print("【GameCenter】需在 iOS 端完成认证")
            }
        }
    }
    
    public func submitScore(score: Int64) {
        guard isAuthenticated else { return }
        GKLeaderboard.submitScore(Int(score), context: 0, player: GKLocalPlayer.local, leaderboardIDs: ["cultivation_rank"]) { error in
            if let error = error {
                print("【GameCenter】上榜失败: \(error.localizedDescription)")
            }
        }
    }
}
