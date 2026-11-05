import Foundation
import HealthKit
import Combine
import CoreData

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
        
        let readTypes: Set<HKObjectType> = [stepType, energyType, heartRateType, mindfulnessType, sleepType, standType, HKObjectType.workoutType()]
        
        // 在 watchOS 上，必须在主线程发起请求
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
        guard isAuthorized else { return }
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
    
    // MARK: - The Elements Engine Sync
    @MainActor
    func syncElements(to profile: PlayerProfile, context: NSManagedObjectContext) async {
        guard isAuthorized else { return }
        
        let lastSyncKey = "EngineLastSyncDate"
        let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date ?? Date().addingTimeInterval(-86400 * 3) // 最多回溯3天
        let now = Date()
        let predicate = HKQuery.predicateForSamples(withStart: lastSync, end: now, options: .strictStartDate)
        
        var totalRewards: [QiReward] = []
        
        // 1. 获取 Workouts
        if let workouts = try? await fetchWorkouts(predicate: predicate) {
            for w in workouts {
                totalRewards.append(ElementEngine.calculateWorkoutQi(workout: w))
            }
        }
        
        // 2. 获取睡眠
        if let sleepSamples = try? await fetchCategorySamples(identifier: .sleepAnalysis, predicate: predicate) {
            let sleepReward = ElementEngine.calculateSleepQi(samples: sleepSamples)
            if sleepReward.amount > 0 {
                totalRewards.append(sleepReward)
            }
        }
        
        // 3. 获取站立
        if let standSamples = try? await fetchCategorySamples(identifier: .appleStandHour, predicate: predicate) {
            let standReward = ElementEngine.calculateStandQi(samples: standSamples)
            if standReward.amount > 0 {
                totalRewards.append(standReward)
            }
        }
        
        // 4. 心率激增检测 (奇遇触发)
        checkHeartRateSpike()
        
        // 若没有新灵气，则返回
        if totalRewards.isEmpty { return }
        
        // 5. 结算所有灵气奖励
        for reward in totalRewards {
            profile.addQi(reward)
        }
        
        // 更新同步日期
        UserDefaults.standard.set(now, forKey: lastSyncKey)
        
        try? context.save()
    }
    
    private func checkHeartRateSpike() {
        guard isAuthorized else { return }
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
            guard let sample = results?.first as? HKQuantitySample else { return }
            let hr = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            
            // 如果心率超过 120 (进入高强度状态)，模拟遭遇妖兽
            if hr > 120 {
                DispatchQueue.main.async {
                    NotificationManager.shared.triggerEncounter(
                        title: "【 警！妖兽气息 】",
                        body: "感受到道友血气翻涌 (HR: \(Int(hr)))，似有高阶妖兽在侧，速速决断！"
                    )
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchWorkouts(predicate: NSPredicate) async throws -> [HKWorkout] {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (results as? [HKWorkout]) ?? [])
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchCategorySamples(identifier: HKCategoryTypeIdentifier, predicate: NSPredicate) async throws -> [HKCategorySample] {
        guard let type = HKCategoryType.categoryType(forIdentifier: identifier) else { return [] }
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (results as? [HKCategorySample]) ?? [])
                }
            }
            healthStore.execute(query)
        }
    }
}

