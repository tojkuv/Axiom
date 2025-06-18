import Foundation
import AxiomCore

// MARK: - Mock Capability Registry

/// Mock capability registry for platform layer
public actor MockCapabilityRegistry {
    public static let shared = MockCapabilityRegistry()
    
    private var capabilities: [String: Bool] = [:]
    
    private init() {}
    
    public func getAllCapabilities() async -> [String: Bool] {
        return capabilities
    }
    
    public func setCapability(_ name: String, available: Bool) {
        capabilities[name] = available
    }
    
    public func restart(_ capability: String) async throws {
        capabilities[capability] = true
    }
    
    public func activateAxiomCapability(_ capability: String) async throws {
        capabilities[capability] = true
    }
}

// MARK: - Error Severity

/// Error severity levels for graceful degradation
public enum AxiomErrorSeverity: Int, Comparable, Sendable {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3
    case warning = 4
    case error = 5
    
    public static func < (lhs: AxiomErrorSeverity, rhs: AxiomErrorSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Degradation Levels

/// Service degradation levels from full functionality to minimal
public enum DegradationLevel: Int, CaseIterable, Comparable, Sendable {
    case full = 0
    case limited = 1
    case offline = 2
    case minimal = 3
    case unavailable = 4
    
    public static func < (lhs: DegradationLevel, rhs: DegradationLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public var description: String {
        switch self {
        case .full: return "Full functionality"
        case .limited: return "Limited functionality"
        case .offline: return "Offline mode"
        case .minimal: return "Minimal functionality"
        case .unavailable: return "Feature unavailable"
        }
    }
}

// MARK: - Degradation Strategy

/// Strategy for handling degraded functionality
public enum DegradationStrategy: Sendable {
    case noAction
    case applyFallback(FallbackStrategy)
    case disableFeature
    case showUserNotification(String)
    case scheduleRecovery(TimeInterval)
}

// MARK: - Fallback Strategy

/// Available fallback strategies for degraded functionality
public enum FallbackStrategy: Equatable, Sendable {
    case offline
    case minimal
    case cached
    case alternative(String)
    case readonly
    case simplified
    
    public var description: String {
        switch self {
        case .offline: return "Offline mode"
        case .minimal: return "Minimal features"
        case .cached: return "Cached data"
        case .alternative(let name): return "Alternative: \(name)"
        case .readonly: return "Read-only mode"
        case .simplified: return "Simplified interface"
        }
    }
}

// MARK: - User Notification Service

/// Service for notifying users about degraded functionality
public protocol UserNotificationService: Sendable {
    func notifyDegradation(capability: String, level: DegradationLevel) async
    func notifyRecovery(capability: String) async
    func dismissDegradationNotification(capability: String) async
}

/// Default implementation of user notification service
public actor DefaultUserNotificationService: UserNotificationService {
    private var activeNotifications: [String: DegradationLevel] = [:]
    
    public init() {}
    
    public func notifyDegradation(capability: String, level: DegradationLevel) async {
        activeNotifications[capability] = level
        
        let message = generateDegradationMessage(capability: capability, level: level)
        await showNotification(message)
    }
    
    public func notifyRecovery(capability: String) async {
        activeNotifications.removeValue(forKey: capability)
        
        let message = "The \(capability) feature has been restored."
        await showNotification(message)
    }
    
    public func dismissDegradationNotification(capability: String) async {
        activeNotifications.removeValue(forKey: capability)
        // In production, would dismiss actual notification UI
    }
    
    private func generateDegradationMessage(capability: String, level: DegradationLevel) -> String {
        switch level {
        case .limited:
            return "The \(capability) feature is running with limited functionality."
        case .offline:
            return "The \(capability) feature is running in offline mode."
        case .minimal:
            return "The \(capability) feature is running with minimal functionality."
        case .unavailable:
            return "The \(capability) feature is temporarily unavailable."
        default:
            return "The \(capability) feature status has changed."
        }
    }
    
    private func showNotification(_ message: String) async {
        // In production, would show actual user notification
        print("🔔 \(message)")
    }
    
    public func getActiveNotifications() -> [String: DegradationLevel] {
        return activeNotifications
    }
}

// MARK: - Capability Registry Integration
// Note: Uses the real AxiomCapabilityRegistry from Capabilities module

// MARK: - Graceful Degradation Service

/// Service for handling graceful degradation when capabilities or services fail
public actor GracefulDegradationService {
    private var degradationState: [String: DegradationLevel] = [:]
    private var fallbackChains: [String: [FallbackStrategy]] = [:]
    private let userNotificationService: any UserNotificationService
    private var recoveryTasks: [String: Task<Void, Never>] = [:]
    private var degradationHistory: [String: [DegradationEvent]] = [:]
    
    public init(userNotificationService: any UserNotificationService = DefaultUserNotificationService()) {
        self.userNotificationService = userNotificationService
    }
    
    /// Handles capability failure with appropriate degradation strategy
    public func handleCapabilityFailure(
        capability: String,
        error: AxiomError
    ) async -> DegradationStrategy {
        let currentLevel = degradationState[capability] ?? .full
        let newLevel = calculateDegradationLevel(for: error, currentLevel: currentLevel)
        
        // Record degradation event
        recordDegradationEvent(capability: capability, level: newLevel, error: error)
        
        degradationState[capability] = newLevel
        
        // Apply degradation strategy
        let strategy = await applyDegradation(capability: capability, level: newLevel)
        
        // Notify user of degraded functionality
        await notifyUserOfDegradation(capability: capability, level: newLevel)
        
        // Schedule recovery attempt
        await scheduleRecoveryAttempt(capability: capability)
        
        return strategy
    }
    
    /// Configures fallback chain for a specific capability
    public func configureFallbackChain(capability: String, fallbacks: [FallbackStrategy]) {
        fallbackChains[capability] = fallbacks
    }
    
    /// Gets current degradation level for a capability
    public func getDegradationLevel(for capability: String) -> DegradationLevel {
        return degradationState[capability] ?? .full
    }
    
    /// Gets all capabilities and their degradation levels
    public func getAllDegradationStates() -> [String: DegradationLevel] {
        return degradationState
    }
    
    /// Forces recovery attempt for a capability
    public func forceRecovery(capability: String) async {
        await attemptRecovery(capability: capability)
    }
    
    /// Gets degradation history for a capability
    public func getDegradationHistory(for capability: String) -> [DegradationEvent] {
        return degradationHistory[capability] ?? []
    }
    
    /// Clears degradation state for a capability
    public func clearDegradation(capability: String) async {
        degradationState.removeValue(forKey: capability)
        recoveryTasks[capability]?.cancel()
        recoveryTasks.removeValue(forKey: capability)
        await userNotificationService.dismissDegradationNotification(capability: capability)
    }
    
    // MARK: - Private Implementation
    
    private func calculateDegradationLevel(
        for error: AxiomError,
        currentLevel: DegradationLevel
    ) -> DegradationLevel {
        // Don't degrade further if already at worst level
        if currentLevel == .unavailable {
            return .unavailable
        }
        
        let errorSeverity = determineSeverity(for: error)
        
        switch errorSeverity {
        case .critical:
            return .unavailable
        case .error:
            return min(.offline, DegradationLevel(rawValue: currentLevel.rawValue + 2) ?? .unavailable)
        case .warning:
            return min(.limited, DegradationLevel(rawValue: currentLevel.rawValue + 1) ?? .unavailable)
        default:
            return currentLevel
        }
    }
    
    private func determineSeverity(for error: AxiomError) -> AxiomErrorSeverity {
        switch error {
        case .capabilityError(.unavailable), .capabilityError(.permissionDenied):
            return .critical
        case .capabilityError(.initializationFailed):
            return .error
        case .capabilityError(.operationFailed):
            return .warning
        case .infrastructureError(.resourceExhaustion):
            return .critical
        case .infrastructureError(.serviceUnavailable):
            return .error
        case .networkError:
            return .warning
        default:
            return .error
        }
    }
    
    private func applyDegradation(
        capability: String,
        level: DegradationLevel
    ) async -> DegradationStrategy {
        if fallbackChains.isEmpty {
            setupDefaultFallbackChains()
        }
        let fallbacks = fallbackChains[capability] ?? []
        
        switch level {
        case .full:
            return .noAction
        case .limited:
            if let firstFallback = fallbacks.first {
                return .applyFallback(firstFallback)
            }
            return .showUserNotification("Limited functionality for \(capability)")
        case .offline:
            return .applyFallback(.offline)
        case .minimal:
            return .applyFallback(.minimal)
        case .unavailable:
            return .disableFeature
        }
    }
    
    private func notifyUserOfDegradation(capability: String, level: DegradationLevel) async {
        if level > .full {
            await userNotificationService.notifyDegradation(capability: capability, level: level)
        }
    }
    
    private func notifyUserOfRecovery(capability: String) async {
        await userNotificationService.notifyRecovery(capability: capability)
    }
    
    private func scheduleRecoveryAttempt(capability: String) async {
        // Cancel existing recovery task
        recoveryTasks[capability]?.cancel()
        
        // Schedule new recovery attempt
        recoveryTasks[capability] = Task {
            // Wait before attempting recovery (exponential backoff)
            let baseDelay: TimeInterval = 30.0
            let currentLevel = self.getDegradationLevel(for: capability)
            let delayMultiplier = Double(currentLevel.rawValue + 1)
            let delay = baseDelay * delayMultiplier
            
            try? await Task.sleep(for: .seconds(delay))
            
            if !Task.isCancelled {
                await self.attemptRecovery(capability: capability)
            }
        }
    }
    
    private func attemptRecovery(capability: String) async {
        let capabilityManager = MockCapabilityRegistry.shared
        
        do {
            try await capabilityManager.activateAxiomCapability(capability)
            
            // If successful, restore full functionality
            let previousLevel = degradationState[capability] ?? .full
            degradationState[capability] = .full
            
            // Notify user of recovery
            if previousLevel > .full {
                await notifyUserOfRecovery(capability: capability)
            }
            
            // Record successful recovery
            await recordRecoveryEvent(capability: capability, success: true)
            
            // Cancel any pending recovery tasks
            recoveryTasks[capability]?.cancel()
            recoveryTasks.removeValue(forKey: capability)
            
        } catch {
            // Recovery failed, schedule another attempt
            await recordRecoveryEvent(capability: capability, success: false)
            await scheduleRecoveryAttempt(capability: capability)
        }
    }
    
    private func recordDegradationEvent(capability: String, level: DegradationLevel, error: AxiomError) {
        let event = DegradationEvent(
            capability: capability,
            level: level,
            error: error,
            timestamp: Date(),
            eventType: .degradation
        )
        
        if degradationHistory[capability] == nil {
            degradationHistory[capability] = []
        }
        degradationHistory[capability]?.append(event)
        
        // Keep only last 50 events per capability
        if let events = degradationHistory[capability], events.count > 50 {
            degradationHistory[capability] = Array(events.suffix(50))
        }
    }
    
    private func recordRecoveryEvent(capability: String, success: Bool) async {
        let event = DegradationEvent(
            capability: capability,
            level: .full,
            error: nil,
            timestamp: Date(),
            eventType: success ? .recovery : .recoveryFailed
        )
        
        if degradationHistory[capability] == nil {
            degradationHistory[capability] = []
        }
        degradationHistory[capability]?.append(event)
        
        // Send telemetry
        await Telemetry.shared.send(ErrorRecoveryEvent(
            error: AxiomError.capabilityError(.initializationFailed(capability)),
            option: .retry,
            success: success
        ))
    }
    
    private func setupDefaultFallbackChains() {
        // Network capability fallbacks
        fallbackChains["network"] = [.cached, .offline, .readonly]
        
        // Storage capability fallbacks
        fallbackChains["storage"] = [.readonly, .minimal]
        
        // Camera capability fallbacks
        fallbackChains["camera"] = [.alternative("file_upload"), .minimal]
        
        // Location capability fallbacks
        fallbackChains["location"] = [.alternative("manual_input"), .minimal]
        
        // Payment capability fallbacks
        fallbackChains["payment"] = [.alternative("external_payment"), .readonly]
        
        // Biometric capability fallbacks
        fallbackChains["biometric"] = [.alternative("password"), .minimal]
        
        // Push notifications fallbacks
        fallbackChains["push_notifications"] = [.alternative("in_app_notifications"), .minimal]
    }
}

// MARK: - Degradation Event

/// Event record for degradation analytics
public struct DegradationEvent {
    public let capability: String
    public let level: DegradationLevel
    public let error: AxiomError?
    public let timestamp: Date
    public let eventType: DegradationEventType
    
    public init(
        capability: String,
        level: DegradationLevel,
        error: AxiomError?,
        timestamp: Date,
        eventType: DegradationEventType
    ) {
        self.capability = capability
        self.level = level
        self.error = error
        self.timestamp = timestamp
        self.eventType = eventType
    }
}

// MARK: - Degradation Event Type

/// Types of degradation events
public enum DegradationEventType {
    case degradation
    case recovery
    case recoveryFailed
    case userNotification
}

// MARK: - Capability Status Monitor

/// Monitor for tracking capability status changes
public actor CapabilityStatusMonitor {
    private let degradationService: GracefulDegradationService
    private var isMonitoring = false
    private var monitoringTask: Task<Void, Never>?
    private var lastCapabilityStates: [String: Bool] = [:]
    
    public init(degradationService: GracefulDegradationService) {
        self.degradationService = degradationService
    }
    
    /// Starts monitoring capability status
    public func startMonitoring() async {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        let registry = MockCapabilityRegistry.shared
        lastCapabilityStates = await registry.getAllCapabilities()
        
        monitoringTask = Task {
            while self.isMonitoring {
                await self.checkCapabilityChanges()
                try? await Task.sleep(for: .seconds(10)) // Check every 10 seconds
            }
        }
    }
    
    /// Stops monitoring capability status
    public func stopMonitoring() {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    private func checkCapabilityChanges() async {
        let registry = MockCapabilityRegistry.shared
        let currentStates = await registry.getAllCapabilities()
        
        for (capability, currentState) in currentStates {
            let lastState = lastCapabilityStates[capability, default: true]
            
            if !currentState && lastState {
                // Capability became unavailable
                let error = AxiomError.capabilityError(.unavailable(capability))
                _ = await degradationService.handleCapabilityFailure(capability: capability, error: error)
            } else if currentState && !lastState {
                // Capability became available again
                await degradationService.forceRecovery(capability: capability)
            }
        }
        
        lastCapabilityStates = currentStates
    }
}

// MARK: - Extensions

extension AxiomError {
    /// Create a network error for graceful degradation compatibility
    static func networkError(_ message: String) -> AxiomError {
        return .navigationError(.invalidRoute(message))
    }
}