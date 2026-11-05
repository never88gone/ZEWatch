import Foundation
import CoreMotion
import Combine
import WatchKit

public enum CultivationActionType: String, CaseIterable {
    case body = "体修 (刚猛挥拳)"
    case sword = "剑修 (大开大合)"
    case talisman = "阵符 (精微转腕)"
    case alchemy = "炼丹 (水平画圆)"
}

class MotionManager: ObservableObject {
    static let shared = MotionManager()
    private let motionManager = CMMotionManager()
    
    @Published var isTraining = false
    @Published var currentActionCount: Int = 0
    @Published var targetActionType: CultivationActionType = .body
    
    private var lastActionTime: Date = Date()
    
    func startTraining(type: CultivationActionType) {
        guard motionManager.isDeviceMotionAvailable else { 
            print("设备不支持 DeviceMotion")
            return 
        }
        
        self.targetActionType = type
        self.currentActionCount = 0
        self.isTraining = true
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0 // 50 Hz
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data, self.isTraining else { return }
            self.processMotionData(data)
        }
    }
    
    func stopTraining() {
        self.isTraining = false
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func processMotionData(_ data: CMDeviceMotion) {
        let now = Date()
        guard now.timeIntervalSince(lastActionTime) > 0.4 else { return } // 最短动作冷却时间 400ms
        
        let accel = data.userAcceleration
        let gyro = data.rotationRate
        let gravity = data.gravity
        
        var actionDetected = false
        
        switch targetActionType {
        case .body:
            // 挥拳：寻找单轴爆发的 userAcceleration (> 1.5G)
            let punchForce = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)
            if punchForce > 1.5 {
                actionDetected = true
            }
            
        case .sword:
            // 练剑：大幅度挥舞，陀螺仪旋转明显 且 带有中度加速度
            let swingRotation = sqrt(gyro.x * gyro.x + gyro.y * gyro.y + gyro.z * gyro.z)
            if swingRotation > 4.0 && abs(accel.y) > 0.8 {
                actionDetected = true
            }
            
        case .talisman:
            // 阵符：轻微摇动手腕结印，陀螺仪中度波动但无剧烈位移
            let gentleRotate = sqrt(gyro.z * gyro.z + gyro.x * gyro.x)
            let staticForce = sqrt(accel.x * accel.x + accel.y * accel.y)
            if gentleRotate > 1.5 && gentleRotate < 4.5 && staticForce < 1.0 {
                actionDetected = true
            }
            
        case .alchemy:
            // 炼丹：水平面搅拌，手臂平放重力矢量倾向于 Z 轴，绕 Z 轴自旋
            let tilt = sqrt(gravity.x * gravity.x + gravity.y * gravity.y)
            if tilt > 0.1 && tilt < 0.7 && abs(gyro.z) > 1.5 {
                actionDetected = true
            }
        }
        
        if actionDetected {
            self.currentActionCount += 1
            self.lastActionTime = now
            // 物理反馈“打中一次”的手感
            WKInterfaceDevice.current().play(.click)
        }
    }
}
