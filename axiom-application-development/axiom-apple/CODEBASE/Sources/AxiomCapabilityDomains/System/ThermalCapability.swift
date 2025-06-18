import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - Thermal Capability Configuration

/// Configuration for Thermal capability
public struct ThermalCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableThermalMonitoring: Bool
    public let enableThermalAlerts: Bool
    public let enablePerformanceThrottling: Bool
    public let monitoringInterval: TimeInterval
    public let criticalTemperatureThreshold: Double
    public let warningTemperatureThreshold: Double
    public let enableAutomaticMitigation: Bool
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableBackgroundMonitoring: Bool
    public let performanceReductionSteps: [Double]
    public let thermalHistoryLimit: Int
    
    public init(
        enableThermalMonitoring: Bool = true,
        enableThermalAlerts: Bool = true,
        enablePerformanceThrottling: Bool = true,
        monitoringInterval: TimeInterval = 10.0, // 10 seconds
        criticalTemperatureThreshold: Double = 85.0, // Celsius
        warningTemperatureThreshold: Double = 70.0, // Celsius
        enableAutomaticMitigation: Bool = true,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableBackgroundMonitoring: Bool = true,
        performanceReductionSteps: [Double] = [1.0, 0.8, 0.6, 0.4, 0.2],
        thermalHistoryLimit: Int = 1000
    ) {
        self.enableThermalMonitoring = enableThermalMonitoring
        self.enableThermalAlerts = enableThermalAlerts
        self.enablePerformanceThrottling = enablePerformanceThrottling
        self.monitoringInterval = monitoringInterval
        self.criticalTemperatureThreshold = criticalTemperatureThreshold
        self.warningTemperatureThreshold = warningTemperatureThreshold
        self.enableAutomaticMitigation = enableAutomaticMitigation
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableBackgroundMonitoring = enableBackgroundMonitoring
        self.performanceReductionSteps = performanceReductionSteps
        self.thermalHistoryLimit = thermalHistoryLimit
    }
    
    public var isValid: Bool {
        monitoringInterval > 0 &&
        criticalTemperatureThreshold > warningTemperatureThreshold &&
        warningTemperatureThreshold > 0 &&
        thermalHistoryLimit > 0 &&
        !performanceReductionSteps.isEmpty &&
        performanceReductionSteps.allSatisfy { $0 > 0 && $0 <= 1.0 }
    }
    
    public func merged(with other: ThermalCapabilityConfiguration) -> ThermalCapabilityConfiguration {
        ThermalCapabilityConfiguration(
            enableThermalMonitoring: other.enableThermalMonitoring,
            enableThermalAlerts: other.enableThermalAlerts,
            enablePerformanceThrottling: other.enablePerformanceThrottling,
            monitoringInterval: other.monitoringInterval,
            criticalTemperatureThreshold: other.criticalTemperatureThreshold,
            warningTemperatureThreshold: other.warningTemperatureThreshold,
            enableAutomaticMitigation: other.enableAutomaticMitigation,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableBackgroundMonitoring: other.enableBackgroundMonitoring,
            performanceReductionSteps: other.performanceReductionSteps,
            thermalHistoryLimit: other.thermalHistoryLimit
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> ThermalCapabilityConfiguration {
        var adjustedInterval = monitoringInterval
        var adjustedLogging = enableLogging
        var adjustedBackgroundMonitoring = enableBackgroundMonitoring
        var adjustedHistoryLimit = thermalHistoryLimit
        
        if environment.isLowPowerMode {
            adjustedInterval = max(monitoringInterval, 30.0) // Reduce to 30 seconds minimum
            adjustedBackgroundMonitoring = false
            adjustedHistoryLimit = min(thermalHistoryLimit, 100)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return ThermalCapabilityConfiguration(
            enableThermalMonitoring: enableThermalMonitoring,
            enableThermalAlerts: enableThermalAlerts,
            enablePerformanceThrottling: enablePerformanceThrottling,
            monitoringInterval: adjustedInterval,
            criticalTemperatureThreshold: criticalTemperatureThreshold,
            warningTemperatureThreshold: warningTemperatureThreshold,
            enableAutomaticMitigation: enableAutomaticMitigation,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableBackgroundMonitoring: adjustedBackgroundMonitoring,
            performanceReductionSteps: performanceReductionSteps,
            thermalHistoryLimit: adjustedHistoryLimit
        )
    }
}

// MARK: - Thermal Types

/// Thermal state information
public struct ThermalState: Sendable, Equatable {
    public let systemState: ProcessInfo.ThermalState
    public let temperature: Double? // Celsius if available
    public let timestamp: Date
    public let performanceLevel: Double // 0.0 to 1.0
    public let mitigationActive: Bool
    public let recommendedActions: [ThermalMitigationAction]
    public let severity: ThermalSeverity
    
    public enum ThermalSeverity: String, Sendable, Codable, CaseIterable {
        case nominal = "nominal"
        case fair = "fair"
        case serious = "serious"
        case critical = "critical"
    }
    
    public enum ThermalMitigationAction: String, Sendable, Codable, CaseIterable {
        case reduceProcessing = "reduce-processing"
        case pauseBackgroundTasks = "pause-background-tasks"
        case reduceAnimations = "reduce-animations"
        case disableAdvancedFeatures = "disable-advanced-features"
        case emergencyShutdown = "emergency-shutdown"
        case increaseVentilation = "increase-ventilation"
        case closeUnusedApps = "close-unused-apps"
        case reduceBrightness = "reduce-brightness"
    }
    
    public init(
        systemState: ProcessInfo.ThermalState,
        temperature: Double? = nil,
        performanceLevel: Double = 1.0,
        mitigationActive: Bool = false,
        recommendedActions: [ThermalMitigationAction] = []
    ) {
        self.systemState = systemState
        self.temperature = temperature
        self.timestamp = Date()
        self.performanceLevel = max(0.0, min(1.0, performanceLevel))
        self.mitigationActive = mitigationActive
        self.recommendedActions = recommendedActions
        
        // Derive severity from system state
        switch systemState {
        case .nominal:
            self.severity = .nominal
        case .fair:
            self.severity = .fair
        case .serious:
            self.severity = .serious
        case .critical:
            self.severity = .critical
        @unknown default:
            self.severity = .nominal
        }
    }
    
    public var isThrottled: Bool {
        performanceLevel < 1.0
    }
    
    public var isCritical: Bool {
        severity == .critical
    }
    
    public var requiresImmediateAction: Bool {
        systemState == .critical || (temperature ?? 0) > 90.0
    }
}

/// Thermal alert information
public struct ThermalAlert: Sendable, Identifiable {
    public let id: UUID
    public let type: AlertType
    public let severity: ThermalState.ThermalSeverity
    public let message: String
    public let temperature: Double?
    public let timestamp: Date
    public let isResolved: Bool
    public let recommendedActions: [ThermalState.ThermalMitigationAction]
    public let duration: TimeInterval?
    
    public enum AlertType: String, Sendable, Codable, CaseIterable {
        case temperatureWarning = "temperature-warning"
        case temperatureCritical = "temperature-critical"
        case thermalThrottling = "thermal-throttling"
        case coolingRecommendation = "cooling-recommendation"
        case performanceReduction = "performance-reduction"
        case systemProtection = "system-protection"
    }
    
    public init(
        type: AlertType,
        severity: ThermalState.ThermalSeverity,
        message: String,
        temperature: Double? = nil,
        isResolved: Bool = false,
        recommendedActions: [ThermalState.ThermalMitigationAction] = [],
        duration: TimeInterval? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.severity = severity
        self.message = message
        self.temperature = temperature
        self.timestamp = Date()
        self.isResolved = isResolved
        self.recommendedActions = recommendedActions
        self.duration = duration
    }
}

/// Thermal performance profile
public struct ThermalPerformanceProfile: Sendable {
    public let name: String
    public let description: String
    public let thermalThresholds: [ThermalThreshold]
    public let performanceLevels: [Double]
    public let mitigationStrategies: [ThermalMitigationStrategy]
    public let isDefault: Bool
    
    public struct ThermalThreshold: Sendable {
        public let temperature: Double
        public let systemState: ProcessInfo.ThermalState
        public let action: ThermalAction
        
        public enum ThermalAction: String, Sendable, Codable {
            case monitor = "monitor"
            case warn = "warn"
            case throttle = "throttle"
            case protect = "protect"
        }
        
        public init(temperature: Double, systemState: ProcessInfo.ThermalState, action: ThermalAction) {
            self.temperature = temperature
            self.systemState = systemState
            self.action = action
        }
    }
    
    public struct ThermalMitigationStrategy: Sendable {
        public let trigger: ProcessInfo.ThermalState
        public let performanceLevel: Double
        public let actions: [ThermalState.ThermalMitigationAction]
        public let priority: Int
        
        public init(
            trigger: ProcessInfo.ThermalState,
            performanceLevel: Double,
            actions: [ThermalState.ThermalMitigationAction],
            priority: Int = 0
        ) {
            self.trigger = trigger
            self.performanceLevel = max(0.0, min(1.0, performanceLevel))
            self.actions = actions
            self.priority = priority
        }
    }
    
    public init(
        name: String,
        description: String,
        thermalThresholds: [ThermalThreshold],
        performanceLevels: [Double],
        mitigationStrategies: [ThermalMitigationStrategy],
        isDefault: Bool = false
    ) {
        self.name = name
        self.description = description
        self.thermalThresholds = thermalThresholds
        self.performanceLevels = performanceLevels
        self.mitigationStrategies = mitigationStrategies
        self.isDefault = isDefault
    }
}

/// Thermal metrics
public struct ThermalMetrics: Sendable {
    public let averageTemperature: Double
    public let maxTemperature: Double
    public let minTemperature: Double
    public let thermalEvents: Int
    public let throttlingEvents: Int
    public let criticalEvents: Int
    public let averagePerformanceLevel: Double
    public let throttlingDuration: TimeInterval
    public let coolingEfficiency: Double
    public let temperatureStability: Double
    public let systemStress: Double
    
    public init(
        averageTemperature: Double = 0,
        maxTemperature: Double = 0,
        minTemperature: Double = 0,
        thermalEvents: Int = 0,
        throttlingEvents: Int = 0,
        criticalEvents: Int = 0,
        averagePerformanceLevel: Double = 1.0,
        throttlingDuration: TimeInterval = 0,
        coolingEfficiency: Double = 1.0,
        temperatureStability: Double = 1.0,
        systemStress: Double = 0
    ) {
        self.averageTemperature = averageTemperature
        self.maxTemperature = maxTemperature
        self.minTemperature = minTemperature
        self.thermalEvents = thermalEvents
        self.throttlingEvents = throttlingEvents
        self.criticalEvents = criticalEvents
        self.averagePerformanceLevel = averagePerformanceLevel
        self.throttlingDuration = throttlingDuration
        self.coolingEfficiency = coolingEfficiency
        self.temperatureStability = temperatureStability
        self.systemStress = systemStress
    }
    
    public var healthScore: Double {
        let temperatureScore = max(0, 1.0 - (maxTemperature - 20) / 60) // Normalize temperature
        let stabilityScore = temperatureStability
        let performanceScore = averagePerformanceLevel
        let stressScore = max(0, 1.0 - systemStress)
        
        return (temperatureScore + stabilityScore + performanceScore + stressScore) / 4.0
    }
}

// MARK: - Thermal Resource

/// Thermal resource management
public actor ThermalCapabilityResource: AxiomCapabilityResource {
    private let configuration: ThermalCapabilityConfiguration
    private var currentThermalState: ThermalState?
    private var thermalHistory: [ThermalState] = []
    private var alerts: [ThermalAlert] = []
    private var metrics: ThermalMetrics = ThermalMetrics()
    private var monitoringTimer: Timer?
    private var thermalStateStreamContinuation: AsyncStream<ThermalState>.Continuation?
    private var alertStreamContinuation: AsyncStream<ThermalAlert>.Continuation?
    private var activeProfile: ThermalPerformanceProfile
    private var customProfiles: [String: ThermalPerformanceProfile] = [:]
    private var currentPerformanceLevel: Double = 1.0
    private var throttlingStartTime: Date?
    
    public init(configuration: ThermalCapabilityConfiguration) {
        self.configuration = configuration
        self.activeProfile = Self.createDefaultProfile()
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 3_000_000, // 3MB for thermal monitoring
            cpu: 0.5, // Low CPU usage for monitoring
            bandwidth: 0,
            storage: 500_000 // 500KB for thermal history
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let historyMemory = thermalHistory.count * 200
            let alertMemory = alerts.count * 150
            
            return ResourceUsage(
                memory: historyMemory + alertMemory + 100_000,
                cpu: monitoringTimer != nil ? 0.3 : 0.1,
                bandwidth: 0,
                storage: thermalHistory.count * 100
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        true // Thermal monitoring is available on all platforms
    }
    
    public func release() async {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        thermalHistory.removeAll()
        alerts.removeAll()
        customProfiles.removeAll()
        currentThermalState = nil
        
        thermalStateStreamContinuation?.finish()
        alertStreamContinuation?.finish()
        
        metrics = ThermalMetrics()
        currentPerformanceLevel = 1.0
        throttlingStartTime = nil
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize thermal monitoring
        await updateThermalState()
        
        // Start monitoring if enabled
        if configuration.enableThermalMonitoring {
            await startThermalMonitoring()
        }
        
        // Setup thermal notifications
        await setupThermalNotifications()
        
        // Load default profiles
        await loadDefaultProfiles()
    }
    
    internal func updateConfiguration(_ configuration: ThermalCapabilityConfiguration) async throws {
        // Restart monitoring if interval changed
        if configuration.monitoringInterval != self.configuration.monitoringInterval {
            await startThermalMonitoring()
        }
    }
    
    // MARK: - Thermal Monitoring
    
    public var thermalStateStream: AsyncStream<ThermalState> {
        AsyncStream { continuation in
            self.thermalStateStreamContinuation = continuation
            
            Task {
                if let currentState = await self.currentThermalState {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var alertStream: AsyncStream<ThermalAlert> {
        AsyncStream { continuation in
            self.alertStreamContinuation = continuation
        }
    }
    
    public func getCurrentThermalState() async -> ThermalState? {
        return currentThermalState
    }
    
    public func getThermalHistory(since: Date? = nil) async -> [ThermalState] {
        if let since = since {
            return thermalHistory.filter { $0.timestamp >= since }
        }
        return thermalHistory
    }
    
    public func getAlerts(since: Date? = nil) async -> [ThermalAlert] {
        if let since = since {
            return alerts.filter { $0.timestamp >= since }
        }
        return alerts
    }
    
    public func getActiveAlerts() async -> [ThermalAlert] {
        return alerts.filter { !$0.isResolved }
    }
    
    public func resolveAlert(_ alertId: UUID) async {
        if let index = alerts.firstIndex(where: { $0.id == alertId }) {
            let resolvedAlert = ThermalAlert(
                type: alerts[index].type,
                severity: alerts[index].severity,
                message: alerts[index].message,
                temperature: alerts[index].temperature,
                isResolved: true,
                recommendedActions: alerts[index].recommendedActions,
                duration: alerts[index].duration
            )
            alerts[index] = resolvedAlert
        }
    }
    
    // MARK: - Performance Management
    
    public func getCurrentPerformanceLevel() async -> Double {
        return currentPerformanceLevel
    }
    
    public func setPerformanceLevel(_ level: Double) async {
        let clampedLevel = max(0.0, min(1.0, level))
        currentPerformanceLevel = clampedLevel
        
        if clampedLevel < 1.0 && throttlingStartTime == nil {
            throttlingStartTime = Date()
        } else if clampedLevel == 1.0 && throttlingStartTime != nil {
            if let startTime = throttlingStartTime {
                let throttlingDuration = Date().timeIntervalSince(startTime)
                await updateThrottlingMetrics(duration: throttlingDuration)
            }
            throttlingStartTime = nil
        }
        
        await applyPerformanceMitigation(level: clampedLevel)
    }
    
    public func applyThermalMitigation(_ actions: [ThermalState.ThermalMitigationAction]) async {
        for action in actions {
            await executeMitigationAction(action)
        }
    }
    
    // MARK: - Profile Management
    
    public func getActiveProfile() async -> ThermalPerformanceProfile {
        return activeProfile
    }
    
    public func setActiveProfile(_ profile: ThermalPerformanceProfile) async {
        activeProfile = profile
        
        if configuration.enableLogging {
            print("[Thermal] 🎛️ Switched to profile: \(profile.name)")
        }
    }
    
    public func createCustomProfile(_ profile: ThermalPerformanceProfile) async {
        customProfiles[profile.name] = profile
    }
    
    public func getCustomProfiles() async -> [ThermalPerformanceProfile] {
        return Array(customProfiles.values)
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> ThermalMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = ThermalMetrics()
    }
    
    // MARK: - Private Methods
    
    private func startThermalMonitoring() async {
        monitoringTimer?.invalidate()
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: configuration.monitoringInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.updateThermalState()
            }
        }
    }
    
    private func setupThermalNotifications() async {
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.handleThermalStateChange()
            }
        }
    }
    
    private func updateThermalState() async {
        let processInfo = ProcessInfo.processInfo
        let systemState = processInfo.thermalState
        
        // Estimate temperature (simplified - real implementation would use thermal sensors)
        let estimatedTemperature = await estimateTemperature(from: systemState)
        
        // Determine performance level based on thermal state
        let performanceLevel = await determinePerformanceLevel(for: systemState)
        
        // Generate mitigation recommendations
        let recommendations = await generateMitigationRecommendations(for: systemState, temperature: estimatedTemperature)
        
        let newState = ThermalState(
            systemState: systemState,
            temperature: estimatedTemperature,
            performanceLevel: performanceLevel,
            mitigationActive: performanceLevel < 1.0,
            recommendedActions: recommendations
        )
        
        // Store previous state for comparison
        let previousState = currentThermalState
        currentThermalState = newState
        
        // Add to history
        thermalHistory.append(newState)
        await trimThermalHistory()
        
        // Check for alerts
        await checkForAlerts(newState, previousState: previousState)
        
        // Apply automatic mitigation if enabled
        if configuration.enableAutomaticMitigation {
            await applyAutomaticMitigation(for: newState)
        }
        
        // Update metrics
        await updateMetrics(newState)
        
        // Emit state change
        thermalStateStreamContinuation?.yield(newState)
        
        if configuration.enableLogging {
            await logThermalState(newState)
        }
    }
    
    private func estimateTemperature(from systemState: ProcessInfo.ThermalState) async -> Double? {
        // Simplified temperature estimation based on thermal state
        // Real implementation would use actual temperature sensors if available
        switch systemState {
        case .nominal:
            return Double.random(in: 20...40)
        case .fair:
            return Double.random(in: 40...60)
        case .serious:
            return Double.random(in: 60...80)
        case .critical:
            return Double.random(in: 80...95)
        @unknown default:
            return nil
        }
    }
    
    private func determinePerformanceLevel(for systemState: ProcessInfo.ThermalState) async -> Double {
        let strategy = activeProfile.mitigationStrategies.first { $0.trigger == systemState }
        return strategy?.performanceLevel ?? 1.0
    }
    
    private func generateMitigationRecommendations(for systemState: ProcessInfo.ThermalState, temperature: Double?) async -> [ThermalState.ThermalMitigationAction] {
        var recommendations: [ThermalState.ThermalMitigationAction] = []
        
        switch systemState {
        case .nominal:
            break // No recommendations needed
        case .fair:
            recommendations.append(.reduceBrightness)
            recommendations.append(.closeUnusedApps)
        case .serious:
            recommendations.append(.reduceProcessing)
            recommendations.append(.pauseBackgroundTasks)
            recommendations.append(.reduceAnimations)
        case .critical:
            recommendations.append(.disableAdvancedFeatures)
            recommendations.append(.emergencyShutdown)
            recommendations.append(.increaseVentilation)
        @unknown default:
            break
        }
        
        if let temp = temperature, temp > configuration.criticalTemperatureThreshold {
            recommendations.append(.emergencyShutdown)
        } else if let temp = temperature, temp > configuration.warningTemperatureThreshold {
            recommendations.append(.reduceProcessing)
        }
        
        return recommendations
    }
    
    private func checkForAlerts(_ state: ThermalState, previousState: ThermalState?) async {
        // Thermal state change alerts
        if let previousState = previousState, state.systemState != previousState.systemState {
            let alert = ThermalAlert(
                type: .thermalThrottling,
                severity: state.severity,
                message: "Thermal state changed from \(previousState.systemState) to \(state.systemState)",
                temperature: state.temperature,
                recommendedActions: state.recommendedActions
            )
            await addAlert(alert)
        }
        
        // Temperature threshold alerts
        if let temperature = state.temperature {
            if temperature > configuration.criticalTemperatureThreshold {
                let alert = ThermalAlert(
                    type: .temperatureCritical,
                    severity: .critical,
                    message: "Critical temperature reached: \(String(format: "%.1f", temperature))°C",
                    temperature: temperature,
                    recommendedActions: [.emergencyShutdown, .increaseVentilation]
                )
                await addAlert(alert)
            } else if temperature > configuration.warningTemperatureThreshold {
                let alert = ThermalAlert(
                    type: .temperatureWarning,
                    severity: .serious,
                    message: "High temperature detected: \(String(format: "%.1f", temperature))°C",
                    temperature: temperature,
                    recommendedActions: [.reduceProcessing, .closeUnusedApps]
                )
                await addAlert(alert)
            }
        }
        
        // Performance reduction alerts
        if state.isThrottled && !(previousState?.isThrottled ?? false) {
            let alert = ThermalAlert(
                type: .performanceReduction,
                severity: state.severity,
                message: "Performance reduced to \(Int(state.performanceLevel * 100))% due to thermal conditions",
                temperature: state.temperature,
                recommendedActions: state.recommendedActions
            )
            await addAlert(alert)
        }
    }
    
    private func addAlert(_ alert: ThermalAlert) async {
        alerts.append(alert)
        alertStreamContinuation?.yield(alert)
        
        if configuration.enableLogging {
            await logAlert(alert)
        }
    }
    
    private func applyAutomaticMitigation(for state: ThermalState) async {
        guard configuration.enablePerformanceThrottling else { return }
        
        let strategy = activeProfile.mitigationStrategies.first { $0.trigger == state.systemState }
        if let strategy = strategy {
            await setPerformanceLevel(strategy.performanceLevel)
            await applyThermalMitigation(strategy.actions)
        }
    }
    
    private func applyPerformanceMitigation(level: Double) async {
        // This would typically involve notifying other system components
        // to reduce their performance (CPU throttling, GPU throttling, etc.)
        
        if configuration.enableLogging {
            print("[Thermal] ⚡ Performance level set to \(Int(level * 100))%")
        }
    }
    
    private func executeMitigationAction(_ action: ThermalState.ThermalMitigationAction) async {
        switch action {
        case .reduceProcessing:
            await setPerformanceLevel(0.7)
        case .pauseBackgroundTasks:
            // Notify background task coordinator
            break
        case .reduceAnimations:
            // Notify UI subsystem to reduce animations
            break
        case .disableAdvancedFeatures:
            await setPerformanceLevel(0.4)
        case .emergencyShutdown:
            // This would typically trigger a graceful shutdown
            break
        case .increaseVentilation:
            // Hardware-specific cooling recommendations
            break
        case .closeUnusedApps:
            // Notify app lifecycle manager
            break
        case .reduceBrightness:
            // Notify display subsystem
            break
        }
        
        if configuration.enableLogging {
            print("[Thermal] 🛠️ Executed mitigation: \(action.rawValue)")
        }
    }
    
    private func handleThermalStateChange() async {
        await updateThermalState()
    }
    
    private func updateMetrics(_ state: ThermalState) async {
        let temperatures = thermalHistory.compactMap { $0.temperature }
        let averageTemp = temperatures.isEmpty ? 0 : temperatures.reduce(0, +) / Double(temperatures.count)
        let maxTemp = temperatures.max() ?? 0
        let minTemp = temperatures.min() ?? 0
        
        let thermalEvents = thermalHistory.filter { $0.systemState != .nominal }.count
        let throttlingEvents = thermalHistory.filter { $0.isThrottled }.count
        let criticalEvents = thermalHistory.filter { $0.isCritical }.count
        
        let performanceLevels = thermalHistory.map { $0.performanceLevel }
        let averagePerformance = performanceLevels.isEmpty ? 1.0 : performanceLevels.reduce(0, +) / Double(performanceLevels.count)
        
        // Calculate temperature stability (variance)
        let temperatureVariance = temperatures.isEmpty ? 0 : {
            let mean = averageTemp
            let squaredDiffs = temperatures.map { pow($0 - mean, 2) }
            return squaredDiffs.reduce(0, +) / Double(temperatures.count)
        }()
        let temperatureStability = max(0, 1.0 - (temperatureVariance / 100.0))
        
        metrics = ThermalMetrics(
            averageTemperature: averageTemp,
            maxTemperature: maxTemp,
            minTemperature: minTemp,
            thermalEvents: thermalEvents,
            throttlingEvents: throttlingEvents,
            criticalEvents: criticalEvents,
            averagePerformanceLevel: averagePerformance,
            throttlingDuration: metrics.throttlingDuration,
            coolingEfficiency: metrics.coolingEfficiency,
            temperatureStability: temperatureStability,
            systemStress: max(0, min(1.0, Double(criticalEvents) / max(1, thermalHistory.count)))
        )
    }
    
    private func updateThrottlingMetrics(duration: TimeInterval) async {
        let newThrottlingDuration = metrics.throttlingDuration + duration
        
        metrics = ThermalMetrics(
            averageTemperature: metrics.averageTemperature,
            maxTemperature: metrics.maxTemperature,
            minTemperature: metrics.minTemperature,
            thermalEvents: metrics.thermalEvents,
            throttlingEvents: metrics.throttlingEvents + 1,
            criticalEvents: metrics.criticalEvents,
            averagePerformanceLevel: metrics.averagePerformanceLevel,
            throttlingDuration: newThrottlingDuration,
            coolingEfficiency: metrics.coolingEfficiency,
            temperatureStability: metrics.temperatureStability,
            systemStress: metrics.systemStress
        )
    }
    
    private func trimThermalHistory() async {
        if thermalHistory.count > configuration.thermalHistoryLimit {
            thermalHistory = Array(thermalHistory.suffix(configuration.thermalHistoryLimit))
        }
        
        // Remove entries older than 24 hours
        let dayAgo = Date().addingTimeInterval(-86400)
        thermalHistory.removeAll { $0.timestamp < dayAgo }
    }
    
    private func loadDefaultProfiles() async {
        let conservativeProfile = ThermalPerformanceProfile(
            name: "Conservative",
            description: "Aggressive thermal management for maximum device longevity",
            thermalThresholds: [
                .init(temperature: 30, systemState: .nominal, action: .monitor),
                .init(temperature: 50, systemState: .fair, action: .warn),
                .init(temperature: 65, systemState: .serious, action: .throttle),
                .init(temperature: 75, systemState: .critical, action: .protect)
            ],
            performanceLevels: [1.0, 0.8, 0.5, 0.3],
            mitigationStrategies: [
                .init(trigger: .fair, performanceLevel: 0.8, actions: [.reduceBrightness]),
                .init(trigger: .serious, performanceLevel: 0.5, actions: [.reduceProcessing, .pauseBackgroundTasks]),
                .init(trigger: .critical, performanceLevel: 0.3, actions: [.disableAdvancedFeatures, .emergencyShutdown])
            ]
        )
        
        let balancedProfile = ThermalPerformanceProfile(
            name: "Balanced",
            description: "Balanced thermal management for typical usage",
            thermalThresholds: [
                .init(temperature: 35, systemState: .nominal, action: .monitor),
                .init(temperature: 60, systemState: .fair, action: .warn),
                .init(temperature: 75, systemState: .serious, action: .throttle),
                .init(temperature: 85, systemState: .critical, action: .protect)
            ],
            performanceLevels: [1.0, 0.9, 0.7, 0.4],
            mitigationStrategies: [
                .init(trigger: .fair, performanceLevel: 0.9, actions: [.closeUnusedApps]),
                .init(trigger: .serious, performanceLevel: 0.7, actions: [.reduceProcessing]),
                .init(trigger: .critical, performanceLevel: 0.4, actions: [.disableAdvancedFeatures])
            ],
            isDefault: true
        )
        
        let performanceProfile = ThermalPerformanceProfile(
            name: "Performance",
            description: "Minimal thermal management for maximum performance",
            thermalThresholds: [
                .init(temperature: 40, systemState: .nominal, action: .monitor),
                .init(temperature: 70, systemState: .fair, action: .warn),
                .init(temperature: 85, systemState: .serious, action: .throttle),
                .init(temperature: 95, systemState: .critical, action: .protect)
            ],
            performanceLevels: [1.0, 0.95, 0.8, 0.5],
            mitigationStrategies: [
                .init(trigger: .serious, performanceLevel: 0.8, actions: [.reduceAnimations]),
                .init(trigger: .critical, performanceLevel: 0.5, actions: [.reduceProcessing])
            ]
        )
        
        customProfiles = [
            conservativeProfile.name: conservativeProfile,
            balancedProfile.name: balancedProfile,
            performanceProfile.name: performanceProfile
        ]
        
        activeProfile = balancedProfile
    }
    
    private static func createDefaultProfile() -> ThermalPerformanceProfile {
        return ThermalPerformanceProfile(
            name: "Default",
            description: "Standard thermal management profile",
            thermalThresholds: [
                .init(temperature: 35, systemState: .nominal, action: .monitor),
                .init(temperature: 60, systemState: .fair, action: .warn),
                .init(temperature: 75, systemState: .serious, action: .throttle),
                .init(temperature: 85, systemState: .critical, action: .protect)
            ],
            performanceLevels: [1.0, 0.9, 0.7, 0.4],
            mitigationStrategies: [
                .init(trigger: .serious, performanceLevel: 0.7, actions: [.reduceProcessing]),
                .init(trigger: .critical, performanceLevel: 0.4, actions: [.disableAdvancedFeatures])
            ],
            isDefault: true
        )
    }
    
    private func logThermalState(_ state: ThermalState) async {
        let stateIcon = switch state.systemState {
        case .nominal: "🟢"
        case .fair: "🟡"
        case .serious: "🟠"
        case .critical: "🔴"
        @unknown default: "❓"
        }
        
        let temperatureStr = state.temperature.map { String(format: "%.1f°C", $0) } ?? "Unknown"
        let performanceStr = String(format: "%.0f%%", state.performanceLevel * 100)
        
        print("[Thermal] \(stateIcon) \(state.systemState) | \(temperatureStr) | Performance: \(performanceStr)")
    }
    
    private func logAlert(_ alert: ThermalAlert) async {
        let severityIcon = switch alert.severity {
        case .nominal: "ℹ️"
        case .fair: "⚠️"
        case .serious: "🚨"
        case .critical: "🆘"
        }
        
        print("[Thermal] \(severityIcon) \(alert.type.rawValue.uppercased()): \(alert.message)")
    }
}

// MARK: - Thermal Capability Implementation

/// Thermal capability providing comprehensive thermal state monitoring and performance management
public actor ThermalCapability: DomainCapability {
    public typealias ConfigurationType = ThermalCapabilityConfiguration
    public typealias ResourceType = ThermalCapabilityResource
    
    private var _configuration: ThermalCapabilityConfiguration
    private var _resources: ThermalCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "thermal-capability" }
    
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
    
    public var configuration: ThermalCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: ThermalCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: ThermalCapabilityConfiguration = ThermalCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = ThermalCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: ThermalCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Thermal configuration")
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
        // Thermal monitoring is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // Thermal monitoring doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Thermal Operations
    
    /// Get current thermal state
    public func getCurrentThermalState() async throws -> ThermalState? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        return await _resources.getCurrentThermalState()
    }
    
    /// Get thermal state stream
    public func getThermalStateStream() async throws -> AsyncStream<ThermalState> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        return await _resources.thermalStateStream
    }
    
    /// Get thermal history
    public func getThermalHistory(since: Date? = nil) async throws -> [ThermalState] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        return await _resources.getThermalHistory(since: since)
    }
    
    /// Get thermal alerts
    public func getAlerts(since: Date? = nil) async throws -> [ThermalAlert] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        return await _resources.getAlerts(since: since)
    }
    
    /// Get alert stream
    public func getAlertStream() async throws -> AsyncStream<ThermalAlert> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        return await _resources.alertStream
    }
    
    /// Get active alerts
    public func getActiveAlerts() async throws -> [ThermalAlert] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        return await _resources.getActiveAlerts()
    }
    
    /// Resolve alert
    public func resolveAlert(_ alertId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        await _resources.resolveAlert(alertId)
    }
    
    /// Get current performance level
    public func getCurrentPerformanceLevel() async throws -> Double {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        return await _resources.getCurrentPerformanceLevel()
    }
    
    /// Set performance level
    public func setPerformanceLevel(_ level: Double) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        await _resources.setPerformanceLevel(level)
    }
    
    /// Apply thermal mitigation
    public func applyThermalMitigation(_ actions: [ThermalState.ThermalMitigationAction]) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        await _resources.applyThermalMitigation(actions)
    }
    
    /// Get active performance profile
    public func getActiveProfile() async throws -> ThermalPerformanceProfile {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        return await _resources.getActiveProfile()
    }
    
    /// Set active performance profile
    public func setActiveProfile(_ profile: ThermalPerformanceProfile) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        await _resources.setActiveProfile(profile)
    }
    
    /// Create custom performance profile
    public func createCustomProfile(_ profile: ThermalPerformanceProfile) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        await _resources.createCustomProfile(profile)
    }
    
    /// Get custom performance profiles
    public func getCustomProfiles() async throws -> [ThermalPerformanceProfile] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        return await _resources.getCustomProfiles()
    }
    
    /// Get thermal metrics
    public func getMetrics() async throws -> ThermalMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Thermal capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Check if system is thermally throttled
    public func isThrottled() async throws -> Bool {
        guard let state = try await getCurrentThermalState() else { return false }
        return state.isThrottled
    }
    
    /// Check if thermal state is critical
    public func isCritical() async throws -> Bool {
        guard let state = try await getCurrentThermalState() else { return false }
        return state.isCritical
    }
    
    /// Get current temperature (if available)
    public func getCurrentTemperature() async throws -> Double? {
        guard let state = try await getCurrentThermalState() else { return nil }
        return state.temperature
    }
    
    /// Check if immediate action is required
    public func requiresImmediateAction() async throws -> Bool {
        guard let state = try await getCurrentThermalState() else { return false }
        return state.requiresImmediateAction
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Thermal specific errors
public enum ThermalError: Error, LocalizedError {
    case monitoringUnavailable
    case temperatureSensorUnavailable
    case invalidThreshold(String)
    case profileNotFound(String)
    case mitigationFailed(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .monitoringUnavailable:
            return "Thermal monitoring is not available"
        case .temperatureSensorUnavailable:
            return "Temperature sensors are not available"
        case .invalidThreshold(let reason):
            return "Invalid thermal threshold: \(reason)"
        case .profileNotFound(let name):
            return "Thermal profile not found: \(name)"
        case .mitigationFailed(let reason):
            return "Thermal mitigation failed: \(reason)"
        case .configurationError(let reason):
            return "Thermal configuration error: \(reason)"
        }
    }
}