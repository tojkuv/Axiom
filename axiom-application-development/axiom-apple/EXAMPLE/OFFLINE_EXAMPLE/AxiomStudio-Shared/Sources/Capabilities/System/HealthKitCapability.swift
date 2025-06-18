import Foundation
import AxiomCore
import AxiomCapabilities

#if os(iOS)
import HealthKit

public actor HealthKitCapability: AxiomCapability {
    public let id = UUID()
    public let name = "HealthKit"
    public let version = "1.0.0"
    
    private let healthStore = HKHealthStore()
    private var isAuthorized: Bool = false
    
    public init() {}
    
    public func activate() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        try await requestHealthKitPermissions()
    }
    
    public func deactivate() async {
        // HealthKit doesn't require explicit deactivation
    }
    
    public var isAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable() && isAuthorized
    }
    
    private func requestHealthKitPermissions() async throws {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType(),
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if success {
                    self?.isAuthorized = true
                    continuation.resume()
                } else {
                    self?.isAuthorized = false
                    continuation.resume(throwing: HealthKitError.authorizationDenied)
                }
            }
        }
    }
    
    // MARK: - Data Fetching
    
    public func getStepCount(for date: Date) async throws -> Double {
        guard isAvailable else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.invalidDataType
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result, let sum = result.sumQuantity() {
                    let steps = sum.doubleValue(for: HKUnit.count())
                    continuation.resume(returning: steps)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    public func getHeartRate(for date: Date) async throws -> [Double] {
        guard isAvailable else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.invalidDataType
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let samples = samples as? [HKQuantitySample] {
                    let heartRates = samples.map { sample in
                        sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    }
                    continuation.resume(returning: heartRates)
                } else {
                    continuation.resume(returning: [])
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    public func getActiveEnergy(for date: Date) async throws -> Double {
        guard isAvailable else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.invalidDataType
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result, let sum = result.sumQuantity() {
                    let energy = sum.doubleValue(for: HKUnit.kilocalorie())
                    continuation.resume(returning: energy)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    public func getWalkingDistance(for date: Date) async throws -> Double {
        guard isAvailable else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            throw HealthKitError.invalidDataType
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result, let sum = result.sumQuantity() {
                    let distance = sum.doubleValue(for: HKUnit.meter())
                    continuation.resume(returning: distance)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    public func getFlightsClimbed(for date: Date) async throws -> Double {
        guard isAvailable else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        guard let flightsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else {
            throw HealthKitError.invalidDataType
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: flightsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result, let sum = result.sumQuantity() {
                    let flights = sum.doubleValue(for: HKUnit.count())
                    continuation.resume(returning: flights)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    public func getWorkouts(for date: Date) async throws -> [HKWorkout] {
        guard isAvailable else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKWorkoutType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let workouts = samples as? [HKWorkout] {
                    continuation.resume(returning: workouts)
                } else {
                    continuation.resume(returning: [])
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Conversion Methods
    
    public func convertToHealthMetric(stepCount: Double, date: Date) -> HealthMetric {
        return HealthMetric(
            type: .stepCount,
            value: stepCount,
            unit: "steps",
            date: date,
            source: "HealthKit"
        )
    }
    
    public func convertToHealthMetric(heartRate: Double, date: Date) -> HealthMetric {
        return HealthMetric(
            type: .heartRate,
            value: heartRate,
            unit: "bpm",
            date: date,
            source: "HealthKit"
        )
    }
    
    public func convertToHealthMetric(activeEnergy: Double, date: Date) -> HealthMetric {
        return HealthMetric(
            type: .activeEnergy,
            value: activeEnergy,
            unit: "kcal",
            date: date,
            source: "HealthKit"
        )
    }
    
    public func convertToHealthMetric(walkingDistance: Double, date: Date) -> HealthMetric {
        return HealthMetric(
            type: .distanceWalking,
            value: walkingDistance,
            unit: "meters",
            date: date,
            source: "HealthKit"
        )
    }
    
    public func convertToHealthMetric(flightsClimbed: Double, date: Date) -> HealthMetric {
        return HealthMetric(
            type: .flightsClimbed,
            value: flightsClimbed,
            unit: "flights",
            date: date,
            source: "HealthKit"
        )
    }
    
    public func convertToHealthMetric(workout: HKWorkout) -> HealthMetric {
        return HealthMetric(
            type: .workoutTime,
            value: workout.duration,
            unit: "seconds",
            date: workout.startDate,
            source: "HealthKit",
            metadata: [
                "workoutType": workout.workoutActivityType.name,
                "totalEnergyBurned": "\(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)",
                "totalDistance": "\(workout.totalDistance?.doubleValue(for: .meter()) ?? 0)"
            ]
        )
    }
    
    // MARK: - Batch Operations
    
    public func getDailyHealthMetrics(for date: Date) async throws -> [HealthMetric] {
        var metrics: [HealthMetric] = []
        
        do {
            let stepCount = try await getStepCount(for: date)
            metrics.append(convertToHealthMetric(stepCount: stepCount, date: date))
        } catch {
            print("Failed to get step count: \(error)")
        }
        
        do {
            let activeEnergy = try await getActiveEnergy(for: date)
            metrics.append(convertToHealthMetric(activeEnergy: activeEnergy, date: date))
        } catch {
            print("Failed to get active energy: \(error)")
        }
        
        do {
            let walkingDistance = try await getWalkingDistance(for: date)
            metrics.append(convertToHealthMetric(walkingDistance: walkingDistance, date: date))
        } catch {
            print("Failed to get walking distance: \(error)")
        }
        
        do {
            let flightsClimbed = try await getFlightsClimbed(for: date)
            metrics.append(convertToHealthMetric(flightsClimbed: flightsClimbed, date: date))
        } catch {
            print("Failed to get flights climbed: \(error)")
        }
        
        do {
            let workouts = try await getWorkouts(for: date)
            let workoutMetrics = workouts.map { convertToHealthMetric(workout: $0) }
            metrics.append(contentsOf: workoutMetrics)
        } catch {
            print("Failed to get workouts: \(error)")
        }
        
        return metrics
    }
    
    public func getWeeklyStepCounts(endingOn date: Date) async throws -> [HealthMetric] {
        var metrics: [HealthMetric] = []
        let calendar = Calendar.current
        
        for i in 0..<7 {
            if let dayDate = calendar.date(byAdding: .day, value: -i, to: date) {
                do {
                    let stepCount = try await getStepCount(for: dayDate)
                    metrics.append(convertToHealthMetric(stepCount: stepCount, date: dayDate))
                } catch {
                    print("Failed to get step count for \(dayDate): \(error)")
                }
            }
        }
        
        return metrics.reversed()
    }
    
    // MARK: - Authorization Status
    
    public func getAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return healthStore.authorizationStatus(for: type)
    }
    
    public func isAuthorizedToRead(_ type: HKObjectType) -> Bool {
        return getAuthorizationStatus(for: type) == .sharingAuthorized
    }
}

// MARK: - HKWorkoutActivityType Extension

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .strength: return "Strength Training"
        case .crossTraining: return "Cross Training"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .hiking: return "Hiking"
        case .dance: return "Dance"
        case .basketball: return "Basketball"
        case .tennis: return "Tennis"
        case .golf: return "Golf"
        case .soccer: return "Soccer"
        default: return "Other"
        }
    }
}

#else

// macOS stub implementation
public actor HealthKitCapability: AxiomCapability {
    public let id = UUID()
    public let name = "HealthKit"
    public let version = "1.0.0"
    
    public init() {}
    
    public func activate() async throws {
        throw HealthKitError.healthDataNotAvailable
    }
    
    public func deactivate() async {
        // No-op on macOS
    }
    
    public var isAvailable: Bool {
        return false
    }
}

#endif

public enum HealthKitError: Error, LocalizedError {
    case healthDataNotAvailable
    case authorizationDenied
    case invalidDataType
    case queryFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .healthDataNotAvailable:
            return "HealthKit data is not available on this device"
        case .authorizationDenied:
            return "Authorization to access HealthKit data was denied"
        case .invalidDataType:
            return "Invalid HealthKit data type specified"
        case .queryFailed(let error):
            return "HealthKit query failed: \(error.localizedDescription)"
        }
    }
}