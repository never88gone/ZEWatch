import Foundation
import GameKit

@objc(GameKitManager)
public final class GameKitManager: NSObject, ObservableObject {
    public static let shared = GameKitManager()
    @Published public var isAuthenticated = false
    
    private override init() { super.init() }
    
    public func authenticateUser() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] (vc, error) in
            if GKLocalPlayer.local.isAuthenticated {
                self?.isAuthenticated = true
            }
        }
    }
    
    public func submitScore(score: Int64) {
        guard isAuthenticated else { return }
        GKLeaderboard.submitScore(Int(score), context: 0, player: GKLocalPlayer.local, leaderboardIDs: ["cultivation_rank"]) { _ in }
    }
}
