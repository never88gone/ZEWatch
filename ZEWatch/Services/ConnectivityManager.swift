import Foundation
import WatchConnectivity
import Combine
#if os(watchOS)
import WatchKit
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

public extension Notification.Name {
    static let watchFaceConfigDidSync = Notification.Name("com.nevergone.zrxx.watchface_did_sync")
}

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
    
    // MARK: - 专用表盘配置高可靠同步通道 (三通道并发)
    public func sendWatchFaceConfig(_ data: [String: Any]) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        
        if session.activationState != .activated {
            session.activate()
        }
        
        print("[WCSession] 开始分发修仙表盘配置... Reachable=\(session.isReachable)")
        
        // 通道 1：即时直连 (若手表在前台活跃，毫秒级响应)
        if session.isReachable {
            session.sendMessage(data, replyHandler: { reply in
                print("[WCSession] 实时表盘配置直传成功已应答: \(reply)")
            }, errorHandler: { error in
                print("[WCSession] 实时直传异常: \(error.localizedDescription)")
            })
        }
        
        // 通道 2：高可靠后台队列 (保证设备息屏/锁屏或后台时 100% 投递)
        session.transferUserInfo(data)
        print("[WCSession] 表盘配置已成功压入 transferUserInfo 保活投递队列")
        
        // 通道 3：最新上下文持久同步 (保障下次启动或刷新时获得最新状态)
        do {
            try session.updateApplicationContext(data)
            print("[WCSession] 表盘配置已同步更新至 ApplicationContext")
        } catch {
            print("[WCSession] ApplicationContext 刷新警告: \(error)")
        }
        
        #if os(iOS)
        // 通道 4：表盘复杂功能快速刷新通道 (若支持且有配额，立即触发高优刷新)
        if session.isPaired && session.isWatchAppInstalled && session.remainingComplicationUserInfoTransfers > 0 {
            session.transferCurrentComplicationUserInfo(data)
            print("[WCSession] 已向手表 Complication 通道下发高优刷新指令 (剩余配额: \(session.remainingComplicationUserInfoTransfers))")
        }
        #endif
        
        DispatchQueue.main.async {
            self.lastSyncDate = Date()
        }
    }
    
    // MARK: - 通用修仙数据同步接口
    public func sendSyncData(_ data: [String: Any]) {
        if data["watchFaceConfig"] != nil {
            sendWatchFaceConfig(data)
            return
        }
        
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
            
            // 1. 处理表盘配置同步
            if payload["watchFaceConfig"] != nil {
                print("[WCSession] 成功解析到修仙表盘新配置，准备触发全端变身！")
                WatchFaceSettingsManager.shared.update(from: payload)
                
                // 广播全局通知
                NotificationCenter.default.post(
                    name: .watchFaceConfigDidSync,
                    object: nil,
                    userInfo: payload
                )
                
                #if os(watchOS)
                // 灵感触感：仙道契约双连震动，让手腕立刻感受明显反馈
                WKInterfaceDevice.current().play(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                    WKInterfaceDevice.current().play(.directionUp)
                }
                
                // 刷新表盘小组件
                #if canImport(WidgetKit)
                WidgetCenter.shared.reloadAllTimelines()
                #endif
                #endif
            }
            
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
