import Foundation
import WatchConnectivity
import Combine

public class ConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    public static let shared = ConnectivityManager()
    
    @Published public var playerStats: [String: Any] = [:]
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // 发送修仙数据的通用接口
    public func sendSyncData(_ data: [String: Any]) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        
        if session.isReachable {
            session.sendMessage(data, replyHandler: nil) { error in
                print("[WCSession] 直传失败，降级更新 ApplicationContext: \(error.localizedDescription)")
                do {
                    try session.updateApplicationContext(data)
                } catch {
                    print("[WCSession] 上下文更新也失败: \(error)")
                }
            }
        } else {
            // 如果设备未点亮/处于后台，通过 Context 同步兜底
            do {
                try session.updateApplicationContext(data)
                print("[WCSession] 已将数据推入 ApplicationContext 挂起队列")
            } catch {
                print("[WCSession] ApplicationContext 投递错误: \(error)")
            }
        }
    }
    
    // MARK: - Delegate (双端收到实时数据)
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.playerStats = message
            print("[WCSession] 实时收到修真数据透传: \(message)")
            
            #if os(iOS)
            // 收到数据后，触发大模型生成天道意志
            Task {
                await LLMManager.shared.generateHeavenlyWill(stats: message)
            }
            #endif
        }
    }
    
    // MARK: - Delegate (收到后台 Context)
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.playerStats = applicationContext
            print("[WCSession] 从挂起队列提取了最新修真数据: \(applicationContext)")
            
            #if os(iOS)
            // 收到上下文数据后，同样触发大模型
            Task {
                await LLMManager.shared.generateHeavenlyWill(stats: applicationContext)
            }
            #endif
        }
    }
    
    // MARK: - 标准存根 (必须实现)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("[WCSession] 激活状态: \(activationState.rawValue), 错误: \(String(describing: error))")
    }
    
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) { }
    public func sessionDidDeactivate(_ session: WCSession) {
        // App 切换引发 Deactivate 时重新激活
        session.activate()
    }
    #endif
}
