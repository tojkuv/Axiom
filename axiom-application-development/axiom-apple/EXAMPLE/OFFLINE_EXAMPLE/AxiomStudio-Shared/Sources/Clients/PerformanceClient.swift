import Foundation
import AxiomCore
import AxiomArchitecture

public actor PerformanceClient: AxiomClient {
    public typealias StateType = PerformanceState
    public typealias ActionType = PerformanceAction
    
    private var _state: PerformanceState
    private let storageCapability: LocalFileStorageCapability
    private var stateStreamContinuation: AsyncStream<PerformanceState>.Continuation?
    
    private var stateHistory: [PerformanceState] = []
    private var currentHistoryIndex: Int = -1
    private let maxHistorySize: Int = 50
    
    private var actionCount: Int = 0
    private var lastActionTime: Date?
    private var isMonitoring: Bool = false
    private var monitoringTask: Task<Void, Never>?
    
    public init(
        storageCapability: LocalFileStorageCapability,
        initialState: PerformanceState = PerformanceState()
    ) {
        self._state = initialState
        self.storageCapability = storageCapability
        
        self.stateHistory = [initialState]
        self.currentHistoryIndex = 0
    }
    
    public var stateStream: AsyncStream<PerformanceState> {
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
    
    private func setStreamContinuation(_ continuation: AsyncStream<PerformanceState>.Continuation?) {
        self.stateStreamContinuation = continuation
    }
    
    public func process(_ action: PerformanceAction) async throws {
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
    
    public func getCurrentState() async -> PerformanceState {
        return _state
    }
    
    public func rollbackToState(_ state: PerformanceState) async {
        let oldState = _state
        _state = state
        stateStreamContinuation?.yield(state)
        await stateDidUpdate(from: oldState, to: state)
    }
    
    private func processAction(_ action: PerformanceAction, currentState: PerformanceState) async throws -> PerformanceState {
        switch action {
        case .startMonitoring:
            return try await startMonitoring(in: currentState)
            
        case .stopMonitoring:
            return try await stopMonitoring(in: currentState)
            
        case .updateMemoryUsage(let memoryUsage):
            return updateMemoryUsage(memoryUsage, in: currentState)
            
        case .addPerformanceMetric(let metric):
            return addPerformanceMetric(metric, in: currentState)
            
        case .updateCapabilityStatus(let capabilityStatus):
            return updateCapabilityStatus(capabilityStatus, in: currentState)
            
        case .updateBatteryImpact(let batteryImpact):
            return updateBatteryImpact(batteryImpact, in: currentState)
            
        case .updateThermalState(let thermalState):
            return updateThermalState(thermalState, in: currentState)
            
        case .setError(let error):
            return PerformanceState(
                memoryUsage: currentState.memoryUsage,
                performanceMetrics: currentState.performanceMetrics,
                capabilityStatus: currentState.capabilityStatus,
                batteryImpact: currentState.batteryImpact,
                thermalState: currentState.thermalState,
                error: error
            )
        }
    }
    
    // MARK: - Monitoring Operations
    
    private func startMonitoring(in state: PerformanceState) async throws -> PerformanceState {
        guard !isMonitoring else {
            return state
        }
        
        isMonitoring = true
        
        // Start background monitoring task
        monitoringTask = Task { [weak self] in
            while await self?.isMonitoring == true {
                await self?.collectMetrics()
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            }
        }
        
        return state
    }
    
    private func stopMonitoring(in state: PerformanceState) async throws -> PerformanceState {
        guard isMonitoring else {
            return state
        }
        
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
        
        return state
    }
    
    private func collectMetrics() async {
        do {
            // Collect current memory usage
            let memoryUsage = await getCurrentMemoryUsage()
            try await process(.updateMemoryUsage(memoryUsage))
            
            // Collect performance metrics
            let cpuMetric = PerformanceMetric(
                metricType: .cpuUsage,
                value: Double.random(in: 10...80),
                unit: "%"
            )
            try await process(.addPerformanceMetric(cpuMetric))
            
            // Collect battery info (iOS only)
            #if os(iOS)
            let batteryLevel = PerformanceMetric(
                metricType: .batteryLevel,
                value: Double.random(in: 20...100),
                unit: "%"
            )
            try await process(.addPerformanceMetric(batteryLevel))
            #endif
            
        } catch {
            try? await process(.setError(.metricCollectionFailed("Auto-collection failed")))
        }
    }
    
    // MARK: - Memory Operations
    
    private func updateMemoryUsage(_ memoryUsage: MemoryUsage, in state: PerformanceState) -> PerformanceState {
        return PerformanceState(
            memoryUsage: memoryUsage,
            performanceMetrics: state.performanceMetrics,
            capabilityStatus: state.capabilityStatus,
            batteryImpact: state.batteryImpact,
            thermalState: state.thermalState,
            error: nil
        )
    }
    
    private func getCurrentMemoryUsage() async -> MemoryUsage {
        // Simulate memory usage collection
        let totalMemory = UInt64.random(in: 2_000_000_000...16_000_000_000) // 2-16 GB
        let usedMemory = UInt64.random(in: totalMemory/4...totalMemory*3/4)
        let appMemoryUsage = UInt64.random(in: 50_000_000...500_000_000) // 50-500 MB
        
        let pressureLevel: MemoryPressureLevel
        let usagePercentage = Double(usedMemory) / Double(totalMemory)
        
        if usagePercentage > 0.9 {
            pressureLevel = .critical
        } else if usagePercentage > 0.7 {
            pressureLevel = .warning
        } else {
            pressureLevel = .normal
        }
        
        return MemoryUsage(
            totalMemory: totalMemory,
            usedMemory: usedMemory,
            freeMemory: totalMemory - usedMemory,
            appMemoryUsage: appMemoryUsage,
            memoryPressure: pressureLevel
        )
    }
    
    // MARK: - Performance Metric Operations
    
    private func addPerformanceMetric(_ metric: PerformanceMetric, in state: PerformanceState) -> PerformanceState {
        var newMetrics = state.performanceMetrics
        newMetrics.append(metric)
        
        // Keep only recent metrics (last 1000)
        if newMetrics.count > 1000 {
            newMetrics.removeFirst(newMetrics.count - 1000)
        }
        
        return PerformanceState(
            memoryUsage: state.memoryUsage,
            performanceMetrics: newMetrics,
            capabilityStatus: state.capabilityStatus,
            batteryImpact: state.batteryImpact,
            thermalState: state.thermalState,
            error: nil
        )
    }
    
    // MARK: - Capability Status Operations
    
    private func updateCapabilityStatus(_ capabilityStatus: CapabilityStatus, in state: PerformanceState) -> PerformanceState {
        var newStatuses = state.capabilityStatus
        
        if let index = newStatuses.firstIndex(where: { $0.capabilityName == capabilityStatus.capabilityName }) {
            newStatuses[index] = capabilityStatus
        } else {
            newStatuses.append(capabilityStatus)
        }
        
        return PerformanceState(
            memoryUsage: state.memoryUsage,
            performanceMetrics: state.performanceMetrics,
            capabilityStatus: newStatuses,
            batteryImpact: state.batteryImpact,
            thermalState: state.thermalState,
            error: nil
        )
    }
    
    // MARK: - Battery Operations
    
    private func updateBatteryImpact(_ batteryImpact: BatteryImpact, in state: PerformanceState) -> PerformanceState {
        return PerformanceState(
            memoryUsage: state.memoryUsage,
            performanceMetrics: state.performanceMetrics,
            capabilityStatus: state.capabilityStatus,
            batteryImpact: batteryImpact,
            thermalState: state.thermalState,
            error: nil
        )
    }
    
    // MARK: - Thermal Operations
    
    private func updateThermalState(_ thermalState: ThermalState, in state: PerformanceState) -> PerformanceState {
        return PerformanceState(
            memoryUsage: state.memoryUsage,
            performanceMetrics: state.performanceMetrics,
            capabilityStatus: state.capabilityStatus,
            batteryImpact: state.batteryImpact,
            thermalState: thermalState,
            error: nil
        )
    }
    
    // MARK: - Helper Methods
    
    private func shouldAutoSave(_ action: PerformanceAction) -> Bool {
        switch action {
        case .addPerformanceMetric, .updateCapabilityStatus:
            return true
        default:
            return false
        }
    }
    
    private func autoSave() async throws {
        try await storageCapability.saveArray(_state.performanceMetrics, to: "performance/metrics.json")
        try await storageCapability.saveArray(_state.capabilityStatus, to: "performance/capability_status.json")
        
        if let batteryImpact = _state.batteryImpact {
            try await storageCapability.save(batteryImpact, to: "performance/battery_impact.json")
        }
        
        if let thermalState = _state.thermalState {
            try await storageCapability.save(thermalState, to: "performance/thermal_state.json")
        }
    }
    
    private func saveStateToHistory(_ state: PerformanceState) {
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
    
    public func getRecentMetrics(for type: PerformanceMetricType, limit: Int = 10) async -> [PerformanceMetric] {
        return _state.performanceMetrics
            .filter { $0.metricType == type }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }
    
    public func getCapabilityStatus(for capabilityName: String) async -> CapabilityStatus? {
        return _state.capabilityStatus.first { $0.capabilityName == capabilityName }
    }
    
    public func getAllCapabilityStatuses() async -> [CapabilityStatus] {
        return _state.capabilityStatus
    }
    
    public func getActiveCapabilities() async -> [CapabilityStatus] {
        return _state.capabilityStatus.filter { $0.status == .active }
    }
    
    public func getFailedCapabilities() async -> [CapabilityStatus] {
        return _state.capabilityStatus.filter { $0.status == .error }
    }
    
    public func getCurrentMemoryPressure() async -> MemoryPressureLevel {
        return _state.memoryUsage.memoryPressure
    }
    
    public func getAverageCPUUsage(since date: Date) async -> Double? {
        let cpuMetrics = _state.performanceMetrics.filter { metric in
            metric.metricType == .cpuUsage && metric.timestamp >= date
        }
        
        guard !cpuMetrics.isEmpty else { return nil }
        
        let total = cpuMetrics.reduce(0) { $0 + $1.value }
        return total / Double(cpuMetrics.count)
    }
    
    public func getMemoryUsageHistory(limit: Int = 100) async -> [MemoryUsage] {
        return stateHistory
            .suffix(limit)
            .map { $0.memoryUsage }
    }
    
    public func getBatteryLevel() async -> Double? {
        return _state.performanceMetrics
            .filter { $0.metricType == .batteryLevel }
            .max { $0.timestamp < $1.timestamp }?
            .value
    }
    
    public func getCurrentThermalState() async -> ThermalState? {
        return _state.thermalState
    }
    
    public func isCurrentlyMonitoring() async -> Bool {
        return isMonitoring
    }
    
    public func getSystemHealthSummary() async -> SystemHealthSummary {
        let memoryHealth = _state.memoryUsage.memoryPressure == .normal
        let thermalHealth = _state.thermalState?.level != .critical && _state.thermalState?.level != .serious
        let capabilityHealth = _state.capabilityStatus.allSatisfy { $0.status != .error }
        
        return SystemHealthSummary(
            memoryHealth: memoryHealth,
            thermalHealth: thermalHealth ?? true,
            capabilityHealth: capabilityHealth,
            overallHealth: memoryHealth && (thermalHealth ?? true) && capabilityHealth
        )
    }
    
    public func getPerformanceMetrics() async -> PerformanceClientMetrics {
        return PerformanceClientMetrics(
            actionCount: actionCount,
            lastActionTime: lastActionTime,
            stateHistorySize: stateHistory.count,
            currentHistoryIndex: currentHistoryIndex,
            isMonitoring: isMonitoring,
            totalMetricCount: _state.performanceMetrics.count,
            activeCapabilityCount: _state.capabilityStatus.filter { $0.status == .active }.count,
            totalCapabilityCount: _state.capabilityStatus.count,
            memoryPressure: _state.memoryUsage.memoryPressure,
            currentMemoryUsage: _state.memoryUsage.appUsagePercentage
        )
    }
}

public struct SystemHealthSummary: Sendable, Equatable {
    public let memoryHealth: Bool
    public let thermalHealth: Bool
    public let capabilityHealth: Bool
    public let overallHealth: Bool
    
    public init(memoryHealth: Bool, thermalHealth: Bool, capabilityHealth: Bool, overallHealth: Bool) {
        self.memoryHealth = memoryHealth
        self.thermalHealth = thermalHealth
        self.capabilityHealth = capabilityHealth
        self.overallHealth = overallHealth
    }
}

public struct PerformanceClientMetrics: Sendable, Equatable {
    public let actionCount: Int
    public let lastActionTime: Date?
    public let stateHistorySize: Int
    public let currentHistoryIndex: Int
    public let isMonitoring: Bool
    public let totalMetricCount: Int
    public let activeCapabilityCount: Int
    public let totalCapabilityCount: Int
    public let memoryPressure: MemoryPressureLevel
    public let currentMemoryUsage: Double
    
    public init(
        actionCount: Int,
        lastActionTime: Date?,
        stateHistorySize: Int,
        currentHistoryIndex: Int,
        isMonitoring: Bool,
        totalMetricCount: Int,
        activeCapabilityCount: Int,
        totalCapabilityCount: Int,
        memoryPressure: MemoryPressureLevel,
        currentMemoryUsage: Double
    ) {
        self.actionCount = actionCount
        self.lastActionTime = lastActionTime
        self.stateHistorySize = stateHistorySize
        self.currentHistoryIndex = currentHistoryIndex
        self.isMonitoring = isMonitoring
        self.totalMetricCount = totalMetricCount
        self.activeCapabilityCount = activeCapabilityCount
        self.totalCapabilityCount = totalCapabilityCount
        self.memoryPressure = memoryPressure
        self.currentMemoryUsage = currentMemoryUsage
    }
}