import Foundation
import HealthKit
import CoreLocation
import SwiftUI
import Combine

// MARK: - Enums & Data Structs
public enum ElementType: String, CaseIterable {
    case metal = "金"
    case wood = "木"
    case water = "水"
    case fire = "火"
    case earth = "土"
}

public struct QiReward {
    public let element: ElementType
    public let amount: Int64
}

// MARK: - Weather Manager (Environment Sensing)
public class WeatherManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    public static let shared = WeatherManager()
    private let locationManager = CLLocationManager()
    
    @Published public var currentWeather: String = "晴朗"
    @Published public var temperature: Double = 25.0
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }
    
    func startUpdating() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let lat = Int(location.coordinate.latitude)
            if lat % 2 == 0 {
                currentWeather = "雷雨"
                temperature = 18.0
            } else {
                currentWeather = "大风"
                temperature = 22.0
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置获取失败: \(error.localizedDescription)")
    }
}

// MARK: - Weather Engine (Element Buffs)
public struct WeatherBuff {
    public let description: String
    public let iconName: String
    public let color: Color
    public let breakthroughBonus: Double
    public let elementMultipliers: [ElementType: Double]
}

public class WeatherEngine {
    public static let shared = WeatherEngine()
    
    public func currentBuff(for weather: String) -> WeatherBuff {
        switch weather {
        case "雷雨":
            return WeatherBuff(
                description: "雷雨交加：水汽充盈，雷电狂暴",
                iconName: "cloud.bolt.rain.fill",
                color: .blue,
                breakthroughBonus: -0.15,
                elementMultipliers: [.water: 1.5, .metal: 1.2, .fire: 0.5]
            )
        case "大风":
            return WeatherBuff(
                description: "九天罡风：木秀于林，风助火力",
                iconName: "wind",
                color: .green,
                breakthroughBonus: 0.05,
                elementMultipliers: [.wood: 1.4, .fire: 1.3, .earth: 0.8]
            )
        default:
            return WeatherBuff(
                description: "天朗气清：万物均衡",
                iconName: "sun.max.fill",
                color: .yellow,
                breakthroughBonus: 0.0,
                elementMultipliers: [:]
            )
        }
    }
}

// MARK: - Element Engine (Health to Qi)
public class ElementEngine {
    public static func calculateWorkoutQi(workout: HKWorkout) -> QiReward {
        let durationMinutes = workout.duration / 60.0
        let baseAmount = Int64(max(1, durationMinutes))
        
        let element: ElementType
        switch workout.workoutActivityType {
        case .cycling, .traditionalStrengthTraining, .coreTraining, .highIntensityIntervalTraining:
            element = .metal
        case .swimming, .rowing, .waterPolo, .waterSports:
            element = .water
        case .running, .walking, .hiking, .crossTraining:
            element = .fire
        case .yoga, .mindAndBody, .flexibility, .pilates:
            element = .wood
        default:
            element = .earth
        }
        return QiReward(element: element, amount: baseAmount)
    }
    
    public static func calculateSleepQi(samples: [HKCategorySample]) -> QiReward {
        var totalMinutes: Double = 0
        for sample in samples {
            totalMinutes += sample.endDate.timeIntervalSince(sample.startDate) / 60.0
        }
        return QiReward(element: .water, amount: Int64(totalMinutes))
    }
    
    public static func calculateStandQi(samples: [HKCategorySample]) -> QiReward {
        let count = samples.filter { $0.value == HKCategoryValueAppleStandHour.stood.rawValue }.count
        return QiReward(element: .wood, amount: Int64(count * 60))
    }
}

// MARK: - CoreData Extensions
public extension PlayerProfile {
    func qiCap() -> Int64 {
        let baseCap: Int64 = 500
        let realmBonus = Int64(self.realm) * 200
        return baseCap + realmBonus
    }
    
    func rootMultiplier(for element: ElementType) -> Double {
        let rootValue: Int16
        switch element {
        case .metal: rootValue = self.metalRoot
        case .wood:  rootValue = self.woodRoot
        case .water: rootValue = self.waterRoot
        case .fire:  rootValue = self.fireRoot
        case .earth: rootValue = self.earthRoot
        }
        return max(0.1, Double(rootValue) / 100.0)
    }
    
    func passiveMultiplier(for element: ElementType) -> Double {
        let unlockedSkills = (self.skills as? Set<SkillManual>) ?? []
        var multiplier = 1.0
        for skill in unlockedSkills where skill.isUnlocked && skill.skillType == 0 {
            guard let elem = skill.elementReq else { continue }
            let levelBonus = 0.20 + (Double(skill.level) * 0.05)
            if skill.name == "混元五行心诀" {
                multiplier += 0.10 + (Double(skill.level) * 0.02)
                continue
            }
            guard elem == element.rawValue else { continue }
            if element == .water { multiplier += levelBonus + 0.05 }
            else { multiplier += levelBonus }
        }
        return multiplier
    }
    
    func addQi(_ reward: QiReward) {
        let rootBonus = rootMultiplier(for: reward.element)
        let skillBonus = passiveMultiplier(for: reward.element)
        let weatherBuff = WeatherEngine.shared.currentBuff(for: WeatherManager.shared.currentWeather)
        let weatherBonus = weatherBuff.elementMultipliers[reward.element] ?? 1.0
        
        let finalAmount = Int64(Double(reward.amount) * rootBonus * skillBonus * weatherBonus)
        let cap = qiCap()
        
        switch reward.element {
        case .metal: self.metalQi = min(cap, self.metalQi + finalAmount)
        case .wood:  self.woodQi  = min(cap, self.woodQi  + finalAmount)
        case .water: self.waterQi = min(cap, self.waterQi + finalAmount)
        case .fire:  self.fireQi  = min(cap, self.fireQi  + finalAmount)
        case .earth: self.earthQi = min(cap, self.earthQi + finalAmount)
        }
        self.cultivationBase += finalAmount
    }
}
