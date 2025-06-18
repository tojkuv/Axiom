import Foundation
import UIKit
import AxiomCore
import AxiomCapabilities

// MARK: - Battery Capability Configuration

/// Configuration for Battery capability
public struct BatteryCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableBatteryMonitoring: Bool
    public let enableBatteryStateNotifications: Bool
    public let enableLowBatteryWarnings: Bool
    public let lowBatteryThreshold: Float
    public let criticalBatteryThreshold: Float
    public let enablePowerModeAdaptation: Bool
    public let enableChargingStateDetection: Bool
    public let enableBatteryHealthMonitoring: Bool
    public let monitoringInterval: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableBackgroundMonitoring: Bool
    public let enableBatteryOptimization: Bool
    public let enableThermalIntegration: Bool
    
    public init(
        enableBatteryMonitoring: Bool = true,
        enableBatteryStateNotifications: Bool = true,
        enableLowBatteryWarnings: Bool = true,
        lowBatteryThreshold: Float = 0.20, // 20%
        criticalBatteryThreshold: Float = 0.05, // 5%
        enablePowerModeAdaptation: Bool = true,
        enableChargingStateDetection: Bool = true,
        enableBatteryHealthMonitoring: Bool = true,
        monitoringInterval: TimeInterval = 30.0, // 30 seconds
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableBackgroundMonitoring: Bool = true,
        enableBatteryOptimization: Bool = true,
        enableThermalIntegration: Bool = true
    ) {
        self.enableBatteryMonitoring = enableBatteryMonitoring
        self.enableBatteryStateNotifications = enableBatteryStateNotifications
        self.enableLowBatteryWarnings = enableLowBatteryWarnings
        self.lowBatteryThreshold = lowBatteryThreshold
        self.criticalBatteryThreshold = criticalBatteryThreshold
        self.enablePowerModeAdaptation = enablePowerModeAdaptation
        self.enableChargingStateDetection = enableChargingStateDetection
        self.enableBatteryHealthMonitoring = enableBatteryHealthMonitoring
        self.monitoringInterval = monitoringInterval
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableBackgroundMonitoring = enableBackgroundMonitoring
        self.enableBatteryOptimization = enableBatteryOptimization
        self.enableThermalIntegration = enableThermalIntegration
    }
    
    public var isValid: Bool {
        lowBatteryThreshold > 0 && lowBatteryThreshold <= 1.0 &&
        criticalBatteryThreshold > 0 && criticalBatteryThreshold <= 1.0 &&
        criticalBatteryThreshold < lowBatteryThreshold &&
        monitoringInterval > 0
    }
    
    public func merged(with other: BatteryCapabilityConfiguration) -> BatteryCapabilityConfiguration {
        BatteryCapabilityConfiguration(
            enableBatteryMonitoring: other.enableBatteryMonitoring,
            enableBatteryStateNotifications: other.enableBatteryStateNotifications,
            enableLowBatteryWarnings: other.enableLowBatteryWarnings,
            lowBatteryThreshold: other.lowBatteryThreshold,
            criticalBatteryThreshold: other.criticalBatteryThreshold,
            enablePowerModeAdaptation: other.enablePowerModeAdaptation,
            enableChargingStateDetection: other.enableChargingStateDetection,
            enableBatteryHealthMonitoring: other.enableBatteryHealthMonitoring,
            monitoringInterval: other.monitoringInterval,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableBackgroundMonitoring: other.enableBackgroundMonitoring,
            enableBatteryOptimization: other.enableBatteryOptimization,
            enableThermalIntegration: other.enableThermalIntegration
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> BatteryCapabilityConfiguration {
        var adjustedInterval = monitoringInterval
        var adjustedLogging = enableLogging
        var adjustedBackgroundMonitoring = enableBackgroundMonitoring
        
        if environment.isLowPowerMode {
            adjustedInterval = max(monitoringInterval, 60.0) // Increase to 1 minute minimum
            adjustedBackgroundMonitoring = false
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return BatteryCapabilityConfiguration(
            enableBatteryMonitoring: enableBatteryMonitoring,
            enableBatteryStateNotifications: enableBatteryStateNotifications,
            enableLowBatteryWarnings: enableLowBatteryWarnings,
            lowBatteryThreshold: lowBatteryThreshold,
            criticalBatteryThreshold: criticalBatteryThreshold,
            enablePowerModeAdaptation: enablePowerModeAdaptation,
            enableChargingStateDetection: enableChargingStateDetection,
            enableBatteryHealthMonitoring: enableBatteryHealthMonitoring,
            monitoringInterval: adjustedInterval,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableBackgroundMonitoring: adjustedBackgroundMonitoring,
            enableBatteryOptimization: enableBatteryOptimization,
            enableThermalIntegration: enableThermalIntegration
        )
    }
}

// MARK: - Battery Types

/// Battery state information
public struct BatteryState: Sendable, Equatable {
    public let level: Float // 0.0 to 1.0
    public let state: ChargingState
    public let isLowPowerModeEnabled: Bool
    public let timestamp: Date
    public let health: BatteryHealth?
    public let temperature: Double?
    public let voltage: Double?
    public let cycleCount: Int?
    
    public enum ChargingState: String, Sendable, Codable, CaseIterable {
        case unknown = "unknown"
        case unplugged = "unplugged"
        case charging = "charging"
        case full = "full"
    }
    
    public struct BatteryHealth: Sendable, Codable {
        public let maximumCapacityPercentage: Int // 80-100%
        public let peakPerformanceCapability: PeakPerformanceCapability
        public let degradation: DegradationLevel
        
        public enum PeakPerformanceCapability: String, Sendable, Codable, CaseIterable {
            case normal = "normal"
            case throttled = "throttled"
            case unknown = "unknown"
        }
        
        public enum DegradationLevel: String, Sendable, Codable, CaseIterable {
            case excellent = "excellent"  // 95-100%
            case good = "good"            // 85-94%
            case fair = "fair"            // 80-84%
            case poor = "poor"            // <80%
            case unknown = "unknown"
        }
        
        public init(maximumCapacityPercentage: Int, peakPerformanceCapability: PeakPerformanceCapability, degradation: DegradationLevel) {
            self.maximumCapacityPercentage = maximumCapacityPercentage
            self.peakPerformanceCapability = peakPerformanceCapability
            self.degradation = degradation
        }
    }
    
    public init(
        level: Float,
        state: ChargingState,
        isLowPowerModeEnabled: Bool,
        health: BatteryHealth? = nil,
        temperature: Double? = nil,
        voltage: Double? = nil,
        cycleCount: Int? = nil
    ) {
        self.level = level
        self.state = state
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
        self.timestamp = Date()
        self.health = health
        self.temperature = temperature
        self.voltage = voltage
        self.cycleCount = cycleCount
    }
    
    public var percentage: Int {
        Int(level * 100)
    }
    
    public var isCharging: Bool {
        state == .charging
    }
    
    public var isFull: Bool {
        state == .full
    }
    
    public var estimatedTimeRemaining: TimeInterval? {
        // Simplified estimation - would use historical data in real implementation
        if isCharging {
            return TimeInterval((1.0 - level) * 3600) // Rough estimate
        } else {
            // Battery drain estimation
            return TimeInterval(level * 28800) // 8 hours at 100%
        }
    }
}

/// Battery alert information
public struct BatteryAlert: Sendable, Identifiable {
    public let id: UUID
    public let type: AlertType
    public let severity: Severity
    public let message: String
    public let batteryLevel: Float
    public let timestamp: Date
    public let isResolved: Bool
    public let recommendedActions: [String]
    
    public enum AlertType: String, Sendable, Codable, CaseIterable {
        case lowBattery = "low-battery"
        case criticalBattery = "critical-battery"
        case batteryHealthDegraded = "battery-health-degraded"
        case chargingIssue = "charging-issue"
        case overheating = "overheating"
        case powerModeChange = "power-mode-change"
    }
    
    public enum Severity: String, Sendable, Codable, CaseIterable {
        case info = "info"
        case warning = "warning"
        case critical = "critical"
        case emergency = "emergency"
    }
    
    public init(
        type: AlertType,
        severity: Severity,
        message: String,
        batteryLevel: Float,
        isResolved: Bool = false,
        recommendedActions: [String] = []
    ) {
        self.id = UUID()
        self.type = type
        self.severity = severity
        self.message = message
        self.batteryLevel = batteryLevel
        self.timestamp = Date()
        self.isResolved = isResolved
        self.recommendedActions = recommendedActions
    }
}

/// Battery metrics
public struct BatteryMetrics: Sendable {
    public let averageBatteryLevel: Double
    public let totalChargingCycles: Int
    public let totalChargingTime: TimeInterval
    public let averageChargingTime: TimeInterval
    public let totalDischargeTime: TimeInterval
    public let averageDischargeTime: TimeInterval
    public let batteryHealthScore: Double
    public let lowBatteryEvents: Int
    public let criticalBatteryEvents: Int
    public let powerModeActivations: Int
    public let chargingEfficiency: Double
    public let temperatureHistory: [Double]
    public let degradationRate: Double
    
    public init(
        averageBatteryLevel: Double = 0,
        totalChargingCycles: Int = 0,
        totalChargingTime: TimeInterval = 0,
        averageChargingTime: TimeInterval = 0,
        totalDischargeTime: TimeInterval = 0,
        averageDischargeTime: TimeInterval = 0,
        batteryHealthScore: Double = 1.0,
        lowBatteryEvents: Int = 0,
        criticalBatteryEvents: Int = 0,
        powerModeActivations: Int = 0,
        chargingEfficiency: Double = 1.0,
        temperatureHistory: [Double] = [],
        degradationRate: Double = 0
    ) {
        self.averageBatteryLevel = averageBatteryLevel
        self.totalChargingCycles = totalChargingCycles
        self.totalChargingTime = totalChargingTime
        self.averageChargingTime = averageChargingTime
        self.totalDischargeTime = totalDischargeTime
        self.averageDischargeTime = averageDischargeTime
        self.batteryHealthScore = batteryHealthScore
        self.lowBatteryEvents = lowBatteryEvents
        self.criticalBatteryEvents = criticalBatteryEvents
        self.powerModeActivations = powerModeActivations
        self.chargingEfficiency = chargingEfficiency
        self.temperatureHistory = temperatureHistory
        self.degradationRate = degradationRate
    }
}

// MARK: - Battery Resource

/// Battery resource management
public actor BatteryCapabilityResource: AxiomCapabilityResource {
    private let configuration: BatteryCapabilityConfiguration
    private var currentBatteryState: BatteryState?
    private var batteryHistory: [BatteryState] = []
    private var alerts: [BatteryAlert] = []
    private var metrics: BatteryMetrics = BatteryMetrics()
    private var monitoringTimer: Timer?
    private var batteryStateStreamContinuation: AsyncStream<BatteryState>.Continuation?
    private var alertStreamContinuation: AsyncStream<BatteryAlert>.Continuation?
    private var lastChargingStateChange: Date?
    private var chargingSessionStart: Date?
    
    public init(configuration: BatteryCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 5_000_000, // 5MB for battery monitoring
            cpu: 1.0, // Low CPU usage for monitoring
            bandwidth: 0,
            storage: 1_000_000 // 1MB for battery history
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let historyMemory = batteryHistory.count * 500
            let alertMemory = alerts.count * 200
            
            return ResourceUsage(
                memory: historyMemory + alertMemory + 100_000,
                cpu: monitoringTimer != nil ? 0.5 : 0.1,
                bandwidth: 0,
                storage: batteryHistory.count * 250
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        true // Battery monitoring is always available on iOS devices
    }
    
    public func release() async {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        batteryHistory.removeAll()
        alerts.removeAll()
        currentBatteryState = nil
        
        batteryStateStreamContinuation?.finish()
        alertStreamContinuation?.finish()
        
        // Disable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = configuration.enableBatteryMonitoring
        
        // Get initial battery state
        await updateBatteryState()
        
        // Start monitoring if enabled
        if configuration.enableBatteryMonitoring {
            await startBatteryMonitoring()
        }
        
        // Setup notifications
        await setupBatteryNotifications()
    }
    
    internal func updateConfiguration(_ configuration: BatteryCapabilityConfiguration) async throws {
        // Restart monitoring if interval changed
        if configuration.monitoringInterval != self.configuration.monitoringInterval {
            await startBatteryMonitoring()
        }
        
        UIDevice.current.isBatteryMonitoringEnabled = configuration.enableBatteryMonitoring
    }
    
    // MARK: - Battery Monitoring
    
    public var batteryStateStream: AsyncStream<BatteryState> {
        AsyncStream { continuation in
            self.batteryStateStreamContinuation = continuation
            
            Task {
                if let currentState = await self.currentBatteryState {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var alertStream: AsyncStream<BatteryAlert> {
        AsyncStream { continuation in
            self.alertStreamContinuation = continuation
        }
    }
    
    public func getCurrentBatteryState() async -> BatteryState? {
        return currentBatteryState
    }
    
    public func getBatteryHistory(since: Date? = nil) async -> [BatteryState] {
        if let since = since {
            return batteryHistory.filter { $0.timestamp >= since }
        }
        return batteryHistory
    }
    
    public func getAlerts(since: Date? = nil) async -> [BatteryAlert] {
        if let since = since {
            return alerts.filter { $0.timestamp >= since }
        }
        return alerts
    }
    
    public func getActiveAlerts() async -> [BatteryAlert] {
        return alerts.filter { !$0.isResolved }
    }
    
    public func resolveAlert(_ alertId: UUID) async {
        if let index = alerts.firstIndex(where: { $0.id == alertId }) {
            let resolvedAlert = BatteryAlert(
                type: alerts[index].type,
                severity: alerts[index].severity,
                message: alerts[index].message,
                batteryLevel: alerts[index].batteryLevel,
                isResolved: true,
                recommendedActions: alerts[index].recommendedActions
            )
            alerts[index] = resolvedAlert
        }
    }
    
    // MARK: - Power Management
    
    public func enableLowPowerMode() async -> Bool {
        // iOS doesn't allow programmatic control of Low Power Mode
        // This would typically show a prompt to the user
        return ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    public func getBatteryOptimizationRecommendations() async -> [String] {
        guard let state = currentBatteryState else { return [] }
        
        var recommendations: [String] = []
        
        if state.level < configuration.lowBatteryThreshold {
            recommendations.append("Enable Low Power Mode to extend battery life")
            recommendations.append("Reduce screen brightness")
            recommendations.append("Close unnecessary apps")
            recommendations.append("Disable location services for non-essential apps")
        }
        
        if state.isLowPowerModeEnabled {
            recommendations.append("Battery is in Low Power Mode - some features may be limited")
        }
        
        if let health = state.health {
            if health.peakPerformanceCapability == .throttled {
                recommendations.append("Battery health is degraded - consider battery replacement")
            }
            
            if health.maximumCapacityPercentage < 80 {
                recommendations.append("Battery capacity is significantly reduced - replacement recommended")
            }
        }
        
        return recommendations
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> BatteryMetrics {
        metrics
    }
    
    public func clearMetrics() async {
        metrics = BatteryMetrics()
    }
    
    // MARK: - Private Methods
    
    private func startBatteryMonitoring() async {
        monitoringTimer?.invalidate()
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: configuration.monitoringInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.updateBatteryState()
            }
        }
    }
    
    private func setupBatteryNotifications() async {
        if configuration.enableBatteryStateNotifications {
            NotificationCenter.default.addObserver(
                forName: UIDevice.batteryStateDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { [weak self] in
                    await self?.handleBatteryStateChange()
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: UIDevice.batteryLevelDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { [weak self] in
                    await self?.handleBatteryLevelChange()
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: .NSProcessInfoPowerStateDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { [weak self] in
                    await self?.handlePowerModeChange()
                }
            }
        }
    }
    
    private func updateBatteryState() async {
        let device = UIDevice.current
        let processInfo = ProcessInfo.processInfo
        
        let chargingState: BatteryState.ChargingState
        switch device.batteryState {
        case .unknown:
            chargingState = .unknown
        case .unplugged:
            chargingState = .unplugged
        case .charging:
            chargingState = .charging
        case .full:
            chargingState = .full
        @unknown default:
            chargingState = .unknown
        }
        
        // Get battery health information (simplified - real implementation would use private APIs or estimates)
        let batteryHealth = await getBatteryHealth()
        
        let newState = BatteryState(
            level: device.batteryLevel,
            state: chargingState,
            isLowPowerModeEnabled: processInfo.isLowPowerModeEnabled,
            health: batteryHealth
        )
        
        // Store previous state for comparison
        let previousState = currentBatteryState
        currentBatteryState = newState
        
        // Add to history
        batteryHistory.append(newState)
        await trimBatteryHistory()
        
        // Check for alerts
        await checkForAlerts(newState, previousState: previousState)
        
        // Update metrics
        await updateMetrics(newState, previousState: previousState)
        
        // Emit state change
        batteryStateStreamContinuation?.yield(newState)
        
        if configuration.enableLogging {
            await logBatteryState(newState)
        }
    }
    
    private func getBatteryHealth() async -> BatteryState.BatteryHealth? {
        // Simplified battery health estimation
        // Real implementation would use more sophisticated methods
        
        let capacity = Int.random(in: 85...100) // Simulate capacity percentage
        let peakPerformance: BatteryState.BatteryHealth.PeakPerformanceCapability = capacity >= 85 ? .normal : .throttled
        
        let degradation: BatteryState.BatteryHealth.DegradationLevel
        switch capacity {
        case 95...100:
            degradation = .excellent
        case 85...94:
            degradation = .good
        case 80...84:
            degradation = .fair
        default:
            degradation = .poor
        }
        
        return BatteryState.BatteryHealth(
            maximumCapacityPercentage: capacity,
            peakPerformanceCapability: peakPerformance,
            degradation: degradation
        )
    }
    
    private func checkForAlerts(_ state: BatteryState, previousState: BatteryState?) async {
        // Low battery alert
        if configuration.enableLowBatteryWarnings {
            if state.level <= configuration.lowBatteryThreshold && state.level > configuration.criticalBatteryThreshold {
                if previousState?.level ?? 1.0 > configuration.lowBatteryThreshold {
                    let alert = BatteryAlert(
                        type: .lowBattery,
                        severity: .warning,
                        message: "Battery level is low (\(state.percentage)%)",
                        batteryLevel: state.level,
                        recommendedActions: ["Enable Low Power Mode", "Reduce screen brightness", "Close unnecessary apps"]
                    )
                    await addAlert(alert)
                }
            }
            
            // Critical battery alert
            if state.level <= configuration.criticalBatteryThreshold {
                if previousState?.level ?? 1.0 > configuration.criticalBatteryThreshold {
                    let alert = BatteryAlert(
                        type: .criticalBattery,
                        severity: .critical,
                        message: "Battery level is critically low (\(state.percentage)%)",
                        batteryLevel: state.level,
                        recommendedActions: ["Charge device immediately", "Enable Low Power Mode", "Save your work"]
                    )
                    await addAlert(alert)
                }
            }
        }
        
        // Charging state change
        if let previousState = previousState, state.state != previousState.state {
            await handleChargingStateChange(from: previousState.state, to: state.state)
        }
        
        // Power mode change
        if let previousState = previousState, state.isLowPowerModeEnabled != previousState.isLowPowerModeEnabled {
            let alert = BatteryAlert(
                type: .powerModeChange,
                severity: .info,
                message: state.isLowPowerModeEnabled ? "Low Power Mode enabled" : "Low Power Mode disabled",
                batteryLevel: state.level
            )
            await addAlert(alert)
        }
        
        // Battery health degradation
        if let health = state.health, health.degradation == .poor {
            let alert = BatteryAlert(
                type: .batteryHealthDegraded,
                severity: .warning,
                message: "Battery health is significantly degraded (\(health.maximumCapacityPercentage)%)",
                batteryLevel: state.level,
                recommendedActions: ["Consider battery replacement", "Use battery optimization features"]
            )
            await addAlert(alert)
        }
    }
    
    private func addAlert(_ alert: BatteryAlert) async {
        alerts.append(alert)
        alertStreamContinuation?.yield(alert)
        
        if configuration.enableLogging {
            await logAlert(alert)
        }
    }
    
    private func handleChargingStateChange(from oldState: BatteryState.ChargingState, to newState: BatteryState.ChargingState) async {
        lastChargingStateChange = Date()
        
        if newState == .charging && oldState != .charging {
            chargingSessionStart = Date()
        } else if oldState == .charging && newState != .charging {
            if let sessionStart = chargingSessionStart {
                let chargingDuration = Date().timeIntervalSince(sessionStart)
                await updateChargingMetrics(duration: chargingDuration)
            }
            chargingSessionStart = nil
        }
    }
    
    private func handleBatteryStateChange() async {
        await updateBatteryState()
    }
    
    private func handleBatteryLevelChange() async {
        await updateBatteryState()
    }
    
    private func handlePowerModeChange() async {
        await updateBatteryState()
    }
    
    private func updateMetrics(_ state: BatteryState, previousState: BatteryState?) async {
        let totalStates = batteryHistory.count
        let averageLevel = batteryHistory.reduce(0) { $0 + Double($1.level) } / Double(max(totalStates, 1))
        
        let lowBatteryEvents = batteryHistory.filter { $0.level <= configuration.lowBatteryThreshold }.count
        let criticalEvents = batteryHistory.filter { $0.level <= configuration.criticalBatteryThreshold }.count
        let powerModeActivations = batteryHistory.filter { $0.isLowPowerModeEnabled }.count
        
        let healthScore = state.health?.maximumCapacityPercentage != nil ? 
            Double(state.health!.maximumCapacityPercentage) / 100.0 : 1.0
        
        metrics = BatteryMetrics(
            averageBatteryLevel: averageLevel,
            totalChargingCycles: metrics.totalChargingCycles,
            totalChargingTime: metrics.totalChargingTime,
            averageChargingTime: metrics.averageChargingTime,
            totalDischargeTime: metrics.totalDischargeTime,
            averageDischargeTime: metrics.averageDischargeTime,
            batteryHealthScore: healthScore,
            lowBatteryEvents: lowBatteryEvents,
            criticalBatteryEvents: criticalEvents,
            powerModeActivations: powerModeActivations,
            chargingEfficiency: metrics.chargingEfficiency,
            temperatureHistory: metrics.temperatureHistory,
            degradationRate: metrics.degradationRate
        )
    }
    
    private func updateChargingMetrics(duration: TimeInterval) async {
        let newTotalCycles = metrics.totalChargingCycles + 1
        let newTotalTime = metrics.totalChargingTime + duration
        let newAverageTime = newTotalTime / Double(newTotalCycles)
        
        metrics = BatteryMetrics(
            averageBatteryLevel: metrics.averageBatteryLevel,
            totalChargingCycles: newTotalCycles,
            totalChargingTime: newTotalTime,
            averageChargingTime: newAverageTime,
            totalDischargeTime: metrics.totalDischargeTime,
            averageDischargeTime: metrics.averageDischargeTime,
            batteryHealthScore: metrics.batteryHealthScore,
            lowBatteryEvents: metrics.lowBatteryEvents,
            criticalBatteryEvents: metrics.criticalBatteryEvents,
            powerModeActivations: metrics.powerModeActivations,
            chargingEfficiency: metrics.chargingEfficiency,
            temperatureHistory: metrics.temperatureHistory,
            degradationRate: metrics.degradationRate
        )
    }
    
    private func trimBatteryHistory() async {
        // Keep only last 1000 entries
        if batteryHistory.count > 1000 {
            batteryHistory = Array(batteryHistory.suffix(1000))
        }
        
        // Remove entries older than 7 days
        let weekAgo = Date().addingTimeInterval(-604800)
        batteryHistory.removeAll { $0.timestamp < weekAgo }
    }
    
    private func logBatteryState(_ state: BatteryState) async {
        let chargingIcon = switch state.state {
        case .charging: "🔋"
        case .full: "🔋"
        case .unplugged: "📱"
        case .unknown: "❓"
        }
        
        let powerModeIcon = state.isLowPowerModeEnabled ? "🔋" : ""
        
        print("[Battery] \(chargingIcon) \(state.percentage)% \(state.state.rawValue) \(powerModeIcon)")
    }
    
    private func logAlert(_ alert: BatteryAlert) async {
        let severityIcon = switch alert.severity {
        case .info: "ℹ️"
        case .warning: "⚠️"
        case .critical: "🚨"
        case .emergency: "🆘"
        }
        
        print("[Battery] \(severityIcon) \(alert.type.rawValue.uppercased()): \(alert.message)")
    }
}

// MARK: - Battery Capability Implementation

/// Battery capability providing comprehensive battery monitoring and power management
public actor BatteryCapability: DomainCapability {
    public typealias ConfigurationType = BatteryCapabilityConfiguration
    public typealias ResourceType = BatteryCapabilityResource
    
    private var _configuration: BatteryCapabilityConfiguration
    private var _resources: BatteryCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "battery-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: BatteryCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: BatteryCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: BatteryCapabilityConfiguration = BatteryCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = BatteryCapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: BatteryCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Battery configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        // Battery monitoring is supported on all iOS devices
        true
    }
    
    public func requestPermission() async throws {
        // Battery monitoring doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Battery Operations
    
    /// Get current battery state
    public func getCurrentBatteryState() async throws -> BatteryState? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Battery capability not available")
        }
        
        return await _resources.getCurrentBatteryState()
    }
    
    /// Get battery state stream
    public func getBatteryStateStream() async throws -> AsyncStream<BatteryState> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Battery capability not available")
        }
        
        return await _resources.batteryStateStream
    }
    
    /// Get battery history
    public func getBatteryHistory(since: Date? = nil) async throws -> [BatteryState] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Battery capability not available")
        }
        
        return await _resources.getBatteryHistory(since: since)
    }
    
    /// Get battery alerts
    public func getAlerts(since: Date? = nil) async throws -> [BatteryAlert] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Battery capability not available")
        }
        
        return await _resources.getAlerts(since: since)
    }
    
    /// Get alert stream
    public func getAlertStream() async throws -> AsyncStream<BatteryAlert> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Battery capability not available")
        }
        
        return await _resources.alertStream
    }
    
    /// Get active alerts
    public func getActiveAlerts() async throws -> [BatteryAlert] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Battery capability not available")
        }
        
        return await _resources.getActiveAlerts()
    }
    
    /// Resolve alert
    public func resolveAlert(_ alertId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Battery capability not available")
        }
        
        await _resources.resolveAlert(alertId)
    }
    
    /// Enable low power mode
    public func enableLowPowerMode() async throws -> Bool {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Battery capability not available")
        }
        
        return await _resources.enableLowPowerMode()
    }
    
    /// Get battery optimization recommendations
    public func getBatteryOptimizationRecommendations() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Battery capability not available")
        }
        
        return await _resources.getBatteryOptimizationRecommendations()
    }
    
    /// Get metrics
    public func getMetrics() async throws -> BatteryMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Battery capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Battery capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Check if battery is low
    public func isBatteryLow() async throws -> Bool {
        guard let state = try await getCurrentBatteryState() else { return false }
        return state.level <= _configuration.lowBatteryThreshold
    }
    
    /// Check if battery is critical
    public func isBatteryCritical() async throws -> Bool {
        guard let state = try await getCurrentBatteryState() else { return false }
        return state.level <= _configuration.criticalBatteryThreshold
    }
    
    /// Get battery percentage
    public func getBatteryPercentage() async throws -> Int {
        guard let state = try await getCurrentBatteryState() else { return 0 }
        return state.percentage
    }
    
    /// Check if device is charging
    public func isCharging() async throws -> Bool {
        guard let state = try await getCurrentBatteryState() else { return false }
        return state.isCharging
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Battery specific errors
public enum BatteryError: Error, LocalizedError {
    case monitoringUnavailable
    case invalidThreshold(String)
    case batteryHealthUnavailable
    case powerModeUnavailable
    case alertNotFound(UUID)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .monitoringUnavailable:
            return "Battery monitoring is not available"
        case .invalidThreshold(let reason):
            return "Invalid battery threshold: \(reason)"
        case .batteryHealthUnavailable:
            return "Battery health information is not available"
        case .powerModeUnavailable:
            return "Power mode control is not available"
        case .alertNotFound(let alertId):
            return "Battery alert not found: \(alertId)"
        case .configurationError(let reason):
            return "Battery configuration error: \(reason)"
        }
    }
}