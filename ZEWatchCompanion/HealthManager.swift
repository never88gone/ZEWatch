import Foundation
import HealthKit
import Combine

class HealthManager: ObservableObject {
    static let shared = HealthManager()
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var todaySteps: Double = 0
    @Published var todayEnergy: Double = 0
    
    init() {
        checkCurrentAuthorizationStatus()
    }
    
    func checkCurrentAuthorizationStatus() {
        // 对于只读权限，很难直接从系统获取“是否已授权”的具体状态（除非返回了数据）
        // 但我们可以检查是否已经询问过（基于 UserDefaults 记录）
        let hasRequested = UserDefaults.standard.bool(forKey: "hasRequestedHealthKitAuth")
        DispatchQueue.main.async {
            self.isAuthorized = hasRequested
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let mindfulnessType = HKCategoryType.categoryType(forIdentifier: .mindfulSession),
              let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis),
              let standType = HKCategoryType.categoryType(forIdentifier: .appleStandHour) else {
            completion(false, nil)
            return
        }
        
        let readTypes: Set<HKObjectType> = [
            stepType, energyType, heartRateType, mindfulnessType, sleepType, standType,
            HKObjectType.workoutType()
        ]
        
        // 关键：在主线程发起请求（尤其对 iOS/watchOS 弹窗很重要）
        DispatchQueue.main.async {
            self.healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
                DispatchQueue.main.async {
                    if success {
                        UserDefaults.standard.set(true, forKey: "hasRequestedHealthKitAuth")
                        self.isAuthorized = true
                        self.fetchTodaySteps()
                    }
                    completion(success, error)
                }
            }
        }
    }
    
    func fetchTodaySteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }
            DispatchQueue.main.async {
                self.todaySteps = sum.doubleValue(for: HKUnit.count())
            }
        }
        
        healthStore.execute(query)
    }
}
