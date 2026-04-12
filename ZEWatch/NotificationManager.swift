import Foundation
import UserNotifications

@objc(NotificationManager)
public final class NotificationManager: NSObject, ObservableObject {
    public static let shared = NotificationManager()
    
    private override init() {
        super.init()
    }
    
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("【通知】权限已授")
            } else if let error = error {
                print("【通知】权限失败: \(error.localizedDescription)")
            }
        }
    }
    
    public func sendCultivationNotice(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
