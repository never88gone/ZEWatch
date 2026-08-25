import Foundation
import HealthKit
import Combine

class HealthManager: ObservableObject {
    static let shared = HealthManager()
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var todaySteps: Double = 0
    @Published var todayEnergy: Double = 0
    
    @Published var todayDeepSleepMinutes: Double = 0
    @Published var isActiveWorkout: Bool = false
    
    // 防作弊硬顶：每日最高转化灵气上限
    let dailyQiCap: Int64 = 10_000
    
    // PRD v2.0 转化规则
    var convertedWoodQi: Int64 {
        // 每 100 步 = 1 木灵气，如果正在运动基础效率翻倍
        let multiplier = isActiveWorkout ? 2.0 : 1.0
        let qi = Int64((todaySteps / 100.0) * multiplier)
        return min(qi, dailyQiCap)
    }
    
    var convertedMetalQi: Int64 {
        // 每 10 Kcal = 1 金灵气，如果正在运动基础效率翻倍
        let multiplier = isActiveWorkout ? 2.0 : 1.0
        let qi = Int64((todayEnergy / 10.0) * multiplier)
        return min(qi, dailyQiCap)
    }
    
    var convertedWaterQi: Int64 {
        // 每深度睡眠 10 分钟 = 5 点水灵气
        let qi = Int64(todayDeepSleepMinutes / 10.0) * 5
        return min(qi, dailyQiCap)
    }
    
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
                        self.fetchAllData()
                    }
                    completion(success, error)
                }
            }
        }
    }
    
    func fetchAllData() {
        guard isAuthorized else { return }
        fetchTodaySteps()
        fetchTodayEnergy()
        fetchTodayDeepSleep()
        checkActiveWorkout()
    }
    
    func fetchTodaySteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let predicate = currentDayPredicate()
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let sum = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            DispatchQueue.main.async { self.todaySteps = sum }
        }
        healthStore.execute(query)
    }
    
    func fetchTodayEnergy() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let predicate = currentDayPredicate()
        
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let sum = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
            DispatchQueue.main.async { self.todayEnergy = sum }
        }
        healthStore.execute(query)
    }
    
    func fetchTodayDeepSleep() {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let predicate = currentDayPredicate()
        
        // Apple Health 中深度睡眠的值为 HKCategoryValueSleepAnalysis.asleepDeep
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let categorySamples = samples as? [HKCategorySample] else { return }
            
            var totalDeepSleep: TimeInterval = 0
            for sample in categorySamples {
                // iOS 16.0 之后才支持 asleepDeep
                if #available(iOS 16.0, watchOS 9.0, *) {
                    if sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue {
                        totalDeepSleep += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.todayDeepSleepMinutes = totalDeepSleep / 60.0
            }
        }
        healthStore.execute(query)
    }
    
    func checkActiveWorkout() {
        let predicate = HKQuery.predicateForWorkouts(with: .notApplicable)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // 查询最近一次 workout
        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let workout = samples?.first as? HKWorkout else { return }
            // 如果结束时间是在未来，或者没有结束时间（某些状态下），则视作活跃
            // 通常活跃的 Workout 其 endDate = .distantFuture，或者我们可以直接通过 HKWorkoutSession 判断，
            // 但 HKWorkoutSession 仅支持在 Watch 上。
            // 对于 iOS 端读取 HealthKit，我们只能依赖最近一次已结束或未结束的 Workout 时差。
            // 简单处理：如果有一个在1小时内开始且尚未结束的，或者时长异常长的。
            let now = Date()
            let isActive = (workout.endDate > now || (now.timeIntervalSince(workout.endDate) < 10)) // 这里是个简单的启发式检测
            DispatchQueue.main.async {
                self.isActiveWorkout = isActive
            }
        }
        healthStore.execute(query)
    }
    
    private func currentDayPredicate() -> NSPredicate {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        return HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
    }
}
