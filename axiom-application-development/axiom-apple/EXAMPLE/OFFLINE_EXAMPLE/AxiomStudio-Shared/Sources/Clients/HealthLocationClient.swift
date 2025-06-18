import Foundation
import AxiomCore
import AxiomArchitecture

public actor HealthLocationClient: AxiomClient {
    public typealias StateType = HealthLocationState
    public typealias ActionType = HealthLocationAction
    
    private var _state: HealthLocationState
    private let storageCapability: LocalFileStorageCapability
    private var stateStreamContinuation: AsyncStream<HealthLocationState>.Continuation?
    
    private var stateHistory: [HealthLocationState] = []
    private var currentHistoryIndex: Int = -1
    private let maxHistorySize: Int = 50
    
    private var actionCount: Int = 0
    private var lastActionTime: Date?
    private var isLocationTracking: Bool = false
    
    public init(
        storageCapability: LocalFileStorageCapability,
        initialState: HealthLocationState = HealthLocationState()
    ) {
        self._state = initialState
        self.storageCapability = storageCapability
        
        self.stateHistory = [initialState]
        self.currentHistoryIndex = 0
    }
    
    public var stateStream: AsyncStream<HealthLocationState> {
        AsyncStream { continuation in
            self.stateStreamContinuation = continuation
            continuation.yield(self._state)
            
            continuation.onTermination = { _ in
                Task { [weak self] in
                    await self?.setStreamContinuation(nil)
                }
            }
        }
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<HealthLocationState>.Continuation?) {
        self.stateStreamContinuation = continuation
    }
    
    public func process(_ action: HealthLocationAction) async throws {
        actionCount += 1
        lastActionTime = Date()
        
        let oldState = _state
        let newState = try await processAction(action, currentState: _state)
        
        guard newState != oldState else { return }
        
        await stateWillUpdate(from: oldState, to: newState)
        
        _state = newState
        saveStateToHistory(newState)
        
        stateStreamContinuation?.yield(newState)
        await stateDidUpdate(from: oldState, to: newState)
        
        if shouldAutoSave(action) {
            try await autoSave()
        }
    }
    
    public func getCurrentState() async -> HealthLocationState {
        return _state
    }
    
    public func rollbackToState(_ state: HealthLocationState) async {
        let oldState = _state
        _state = state
        stateStreamContinuation?.yield(state)
        await stateDidUpdate(from: oldState, to: state)
    }
    
    private func processAction(_ action: HealthLocationAction, currentState: HealthLocationState) async throws -> HealthLocationState {
        switch action {
        case .loadHealthMetrics:
            return try await loadHealthMetrics(in: currentState)
            
        case .loadLocationData:
            return try await loadLocationData(in: currentState)
            
        case .loadMovementPatterns:
            return try await loadMovementPatterns(in: currentState)
            
        case .requestHealthPermission:
            return try await requestHealthPermission(in: currentState)
            
        case .requestLocationPermission:
            return try await requestLocationPermission(in: currentState)
            
        case .startLocationTracking:
            return try await startLocationTracking(in: currentState)
            
        case .stopLocationTracking:
            return try await stopLocationTracking(in: currentState)
            
        case .addHealthMetric(let metric):
            return addHealthMetric(metric, in: currentState)
            
        case .addLocationData(let locationData):
            return addLocationData(locationData, in: currentState)
            
        case .addMovementPattern(let pattern):
            return addMovementPattern(pattern, in: currentState)
            
        case .setHealthAvailable(let isAvailable):
            return HealthLocationState(
                healthMetrics: currentState.healthMetrics,
                locationData: currentState.locationData,
                movementPatterns: currentState.movementPatterns,
                isHealthAvailable: isAvailable,
                isLocationAvailable: currentState.isLocationAvailable,
                error: currentState.error
            )
            
        case .setLocationAvailable(let isAvailable):
            return HealthLocationState(
                healthMetrics: currentState.healthMetrics,
                locationData: currentState.locationData,
                movementPatterns: currentState.movementPatterns,
                isHealthAvailable: currentState.isHealthAvailable,
                isLocationAvailable: isAvailable,
                error: currentState.error
            )
            
        case .setError(let error):
            return HealthLocationState(
                healthMetrics: currentState.healthMetrics,
                locationData: currentState.locationData,
                movementPatterns: currentState.movementPatterns,
                isHealthAvailable: currentState.isHealthAvailable,
                isLocationAvailable: currentState.isLocationAvailable,
                error: error
            )
        }
    }
    
    // MARK: - Health Operations
    
    private func loadHealthMetrics(in state: HealthLocationState) async throws -> HealthLocationState {
        do {
            let metrics = try await storageCapability.loadArray(HealthMetric.self, from: "health/metrics.json")
            return HealthLocationState(
                healthMetrics: metrics,
                locationData: state.locationData,
                movementPatterns: state.movementPatterns,
                isHealthAvailable: state.isHealthAvailable,
                isLocationAvailable: state.isLocationAvailable,
                error: nil
            )
        } catch {
            return HealthLocationState(
                healthMetrics: state.healthMetrics,
                locationData: state.locationData,
                movementPatterns: state.movementPatterns,
                isHealthAvailable: state.isHealthAvailable,
                isLocationAvailable: state.isLocationAvailable,
                error: .storageError(error.localizedDescription)
            )
        }
    }
    
    private func requestHealthPermission(in state: HealthLocationState) async throws -> HealthLocationState {
        #if os(iOS)
        // Simulate HealthKit permission request
        // In real implementation, this would use HealthKit APIs
        let isGranted = true // Simulated success
        
        return HealthLocationState(
            healthMetrics: state.healthMetrics,
            locationData: state.locationData,
            movementPatterns: state.movementPatterns,
            isHealthAvailable: isGranted,
            isLocationAvailable: state.isLocationAvailable,
            error: isGranted ? nil : .healthAccessDenied
        )
        #else
        // HealthKit not available on macOS
        return HealthLocationState(
            healthMetrics: state.healthMetrics,
            locationData: state.locationData,
            movementPatterns: state.movementPatterns,
            isHealthAvailable: false,
            isLocationAvailable: state.isLocationAvailable,
            error: .healthKitNotAvailable
        )
        #endif
    }
    
    private func addHealthMetric(_ metric: HealthMetric, in state: HealthLocationState) -> HealthLocationState {
        var newMetrics = state.healthMetrics
        newMetrics.append(metric)
        
        // Keep only recent metrics (last 1000)
        if newMetrics.count > 1000 {
            newMetrics.removeFirst(newMetrics.count - 1000)
        }
        
        return HealthLocationState(
            healthMetrics: newMetrics,
            locationData: state.locationData,
            movementPatterns: state.movementPatterns,
            isHealthAvailable: state.isHealthAvailable,
            isLocationAvailable: state.isLocationAvailable,
            error: nil
        )
    }
    
    // MARK: - Location Operations
    
    private func loadLocationData(in state: HealthLocationState) async throws -> HealthLocationState {
        do {
            let locationData = try await storageCapability.loadArray(LocationData.self, from: "location/data.json")
            return HealthLocationState(
                healthMetrics: state.healthMetrics,
                locationData: locationData,
                movementPatterns: state.movementPatterns,
                isHealthAvailable: state.isHealthAvailable,
                isLocationAvailable: state.isLocationAvailable,
                error: nil
            )
        } catch {
            return HealthLocationState(
                healthMetrics: state.healthMetrics,
                locationData: state.locationData,
                movementPatterns: state.movementPatterns,
                isHealthAvailable: state.isHealthAvailable,
                isLocationAvailable: state.isLocationAvailable,
                error: .storageError(error.localizedDescription)
            )
        }
    }
    
    private func loadMovementPatterns(in state: HealthLocationState) async throws -> HealthLocationState {
        do {
            let patterns = try await storageCapability.loadArray(MovementPattern.self, from: "location/patterns.json")
            return HealthLocationState(
                healthMetrics: state.healthMetrics,
                locationData: state.locationData,
                movementPatterns: patterns,
                isHealthAvailable: state.isHealthAvailable,
                isLocationAvailable: state.isLocationAvailable,
                error: nil
            )
        } catch {
            return HealthLocationState(
                healthMetrics: state.healthMetrics,
                locationData: state.locationData,
                movementPatterns: state.movementPatterns,
                isHealthAvailable: state.isHealthAvailable,
                isLocationAvailable: state.isLocationAvailable,
                error: .storageError(error.localizedDescription)
            )
        }
    }
    
    private func requestLocationPermission(in state: HealthLocationState) async throws -> HealthLocationState {
        // Simulate location permission request
        // In real implementation, this would use CoreLocation APIs
        let isGranted = true // Simulated success
        
        return HealthLocationState(
            healthMetrics: state.healthMetrics,
            locationData: state.locationData,
            movementPatterns: state.movementPatterns,
            isHealthAvailable: state.isHealthAvailable,
            isLocationAvailable: isGranted,
            error: isGranted ? nil : .locationAccessDenied
        )
    }
    
    private func startLocationTracking(in state: HealthLocationState) async throws -> HealthLocationState {
        guard state.isLocationAvailable else {
            throw HealthLocationError.locationAccessDenied
        }
        
        isLocationTracking = true
        
        // Simulate starting location tracking
        // In real implementation, this would start CLLocationManager
        
        return HealthLocationState(
            healthMetrics: state.healthMetrics,
            locationData: state.locationData,
            movementPatterns: state.movementPatterns,
            isHealthAvailable: state.isHealthAvailable,
            isLocationAvailable: state.isLocationAvailable,
            error: nil
        )
    }
    
    private func stopLocationTracking(in state: HealthLocationState) async throws -> HealthLocationState {
        isLocationTracking = false
        
        // Simulate stopping location tracking
        // In real implementation, this would stop CLLocationManager
        
        return state
    }
    
    private func addLocationData(_ locationData: LocationData, in state: HealthLocationState) -> HealthLocationState {
        var newLocationData = state.locationData
        newLocationData.append(locationData)
        
        // Keep only recent location data (last 500 points)
        if newLocationData.count > 500 {
            newLocationData.removeFirst(newLocationData.count - 500)
        }
        
        return HealthLocationState(
            healthMetrics: state.healthMetrics,
            locationData: newLocationData,
            movementPatterns: state.movementPatterns,
            isHealthAvailable: state.isHealthAvailable,
            isLocationAvailable: state.isLocationAvailable,
            error: nil
        )
    }
    
    private func addMovementPattern(_ pattern: MovementPattern, in state: HealthLocationState) -> HealthLocationState {
        var newPatterns = state.movementPatterns
        newPatterns.append(pattern)
        
        // Keep only recent patterns (last 100)
        if newPatterns.count > 100 {
            newPatterns.removeFirst(newPatterns.count - 100)
        }
        
        return HealthLocationState(
            healthMetrics: state.healthMetrics,
            locationData: state.locationData,
            movementPatterns: newPatterns,
            isHealthAvailable: state.isHealthAvailable,
            isLocationAvailable: state.isLocationAvailable,
            error: nil
        )
    }
    
    // MARK: - Helper Methods
    
    private func shouldAutoSave(_ action: HealthLocationAction) -> Bool {
        switch action {
        case .addHealthMetric, .addLocationData, .addMovementPattern:
            return true
        default:
            return false
        }
    }
    
    private func autoSave() async throws {
        try await storageCapability.saveArray(_state.healthMetrics, to: "health/metrics.json")
        try await storageCapability.saveArray(_state.locationData, to: "location/data.json")
        try await storageCapability.saveArray(_state.movementPatterns, to: "location/patterns.json")
    }
    
    private func saveStateToHistory(_ state: HealthLocationState) {
        if currentHistoryIndex < stateHistory.count - 1 {
            stateHistory.removeSubrange((currentHistoryIndex + 1)...)
        }
        
        stateHistory.append(state)
        currentHistoryIndex += 1
        
        if stateHistory.count > maxHistorySize {
            stateHistory.removeFirst()
            currentHistoryIndex -= 1
        }
    }
    
    // MARK: - Public Query Methods
    
    public func getRecentHealthMetrics(for type: HealthMetricType, limit: Int = 10) async -> [HealthMetric] {
        return _state.healthMetrics
            .filter { $0.type == type }
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }
    
    public func getLocationHistory(since date: Date) async -> [LocationData] {
        return _state.locationData.filter { $0.timestamp >= date }
    }
    
    public func getMovementPatterns(for activityType: ActivityType) async -> [MovementPattern] {
        return _state.movementPatterns.filter { $0.activityType == activityType }
    }
    
    public func getCurrentLocation() async -> LocationData? {
        return _state.locationData.max { $0.timestamp < $1.timestamp }
    }
    
    public func isCurrentlyTracking() async -> Bool {
        return isLocationTracking
    }
    
    public func getDailyStepCount(for date: Date) async -> Double? {
        let calendar = Calendar.current
        let steps = _state.healthMetrics.filter { metric in
            metric.type == .stepCount &&
            calendar.isDate(metric.date, inSameDayAs: date)
        }
        return steps.reduce(0) { $0 + $1.value }
    }
    
    public func getAverageHeartRate(for date: Date) async -> Double? {
        let calendar = Calendar.current
        let heartRates = _state.healthMetrics.filter { metric in
            metric.type == .heartRate &&
            calendar.isDate(metric.date, inSameDayAs: date)
        }
        
        guard !heartRates.isEmpty else { return nil }
        
        let total = heartRates.reduce(0) { $0 + $1.value }
        return total / Double(heartRates.count)
    }
    
    public func getDistanceTraveled(for date: Date) async -> Double? {
        let calendar = Calendar.current
        let distances = _state.healthMetrics.filter { metric in
            metric.type == .distanceWalking &&
            calendar.isDate(metric.date, inSameDayAs: date)
        }
        return distances.reduce(0) { $0 + $1.value }
    }
    
    public func getPerformanceMetrics() async -> HealthLocationClientMetrics {
        return HealthLocationClientMetrics(
            actionCount: actionCount,
            lastActionTime: lastActionTime,
            stateHistorySize: stateHistory.count,
            currentHistoryIndex: currentHistoryIndex,
            healthMetricCount: _state.healthMetrics.count,
            locationDataCount: _state.locationData.count,
            movementPatternCount: _state.movementPatterns.count,
            isTrackingLocation: isLocationTracking
        )
    }
}

public struct HealthLocationClientMetrics: Sendable, Equatable {
    public let actionCount: Int
    public let lastActionTime: Date?
    public let stateHistorySize: Int
    public let currentHistoryIndex: Int
    public let healthMetricCount: Int
    public let locationDataCount: Int
    public let movementPatternCount: Int
    public let isTrackingLocation: Bool
    
    public init(
        actionCount: Int,
        lastActionTime: Date?,
        stateHistorySize: Int,
        currentHistoryIndex: Int,
        healthMetricCount: Int,
        locationDataCount: Int,
        movementPatternCount: Int,
        isTrackingLocation: Bool
    ) {
        self.actionCount = actionCount
        self.lastActionTime = lastActionTime
        self.stateHistorySize = stateHistorySize
        self.currentHistoryIndex = currentHistoryIndex
        self.healthMetricCount = healthMetricCount
        self.locationDataCount = locationDataCount
        self.movementPatternCount = movementPatternCount
        self.isTrackingLocation = isTrackingLocation
    }
}