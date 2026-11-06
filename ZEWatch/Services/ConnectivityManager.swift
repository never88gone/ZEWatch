import Foundation
import WatchConnectivity
import Combine
#if os(watchOS)
import WatchKit
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

public class ConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    public static let shared = ConnectivityManager()
    
    @Published public var playerStats: [String: Any] = [:]
    @Published public var isWatchConnected: Bool = false
    @Published public var lastSyncDate: Date? = nil
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - 通用修仙数据同步接口
    public func sendSyncData(_ data: [String: Any]) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        
        if session.isReachable {
            session.sendMessage(data, replyHandler: nil) { error in
                print("[WCSession] 直传失败，降级 transferUserInfo 兜底: \(error.localizedDescription)")
                session.transferUserInfo(data)
            }
        } else {
            session.transferUserInfo(data)
            do {
                try session.updateApplicationContext(data)
            } catch {
                print("[WCSession] 上下文投递失败: \(error)")
            }
        }
    }
    
    // MARK: - 统一数据接收处理器
    private func handleIncomingPayload(_ payload: [String: Any], source: String) {
        DispatchQueue.main.async {
            self.playerStats = payload
            self.lastSyncDate = Date()
            print("[WCSession] 收到来自 [\(source)] 的修真数据载荷")
            
            #if os(iOS)
            // 收到数据后，触发大模型生成天道意志
            Task {
                await LLMManager.shared.generateHeavenlyWill(stats: payload)
            }
            #endif
        }
    }
    
    // MARK: - WCSessionDelegate (通道 1: 实时直连消息)
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncomingPayload(message, source: "实时 Message 直传")
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleIncomingPayload(message, source: "实时 Message(带应答)")
        replyHandler(["status": "acknowledged", "timestamp": Date().timeIntervalSince1970])
    }
    
    // MARK: - WCSessionDelegate (通道 2: 保活投递 UserInfo 队列)
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleIncomingPayload(userInfo, source: "保活 UserInfo 队列")
    }
    
    // MARK: - WCSessionDelegate (通道 3: 后台 ApplicationContext)
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        handleIncomingPayload(applicationContext, source: "后台 ApplicationContext")
    }
    
    // MARK: - 激活与状态存根
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = (activationState == .activated)
        }
        print("[WCSession] 激活完成. 状态: \(activationState.rawValue), 错误: \(String(describing: error))")
    }
    
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) { }
    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    public func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = session.isPaired && session.isWatchAppInstalled
        }
    }
    #endif
}
