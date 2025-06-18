import SwiftUI
import NetworkClient
import SwiftUIRenderer
import Combine

// MARK: - Graceful Degradation Manager

/// Manages graceful degradation strategies when hot reload server is unavailable
@MainActor
public final class GracefulDegradationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var degradationState: DegradationState = .normal
    @Published public private(set) var fallbackStrategy: FallbackStrategy = .showOriginalContent
    @Published public private(set) var serverAvailability: ServerAvailability = .unknown
    @Published public private(set) var userNotificationLevel: NotificationLevel = .none
    @Published public private(set) var degradationHistory: [DegradationEvent] = []
    
    // MARK: - Properties
    
    private let configuration: GracefulDegradationConfiguration
    private let connectionManager: ConnectionManager
    private let renderer: SwiftUIJSONRenderer
    private var cancellables = Set<AnyCancellable>()
    private var serverCheckTimer: Timer?
    private var degradationStartTime: Date?
    
    // MARK: - Initialization
    
    public init(
        configuration: GracefulDegradationConfiguration = GracefulDegradationConfiguration(),
        connectionManager: ConnectionManager,
        renderer: SwiftUIJSONRenderer
    ) {
        self.configuration = configuration
        self.connectionManager = connectionManager
        self.renderer = renderer
        
        setupObservers()
        setupServerMonitoring()
    }
    
    deinit {
        serverCheckTimer?.invalidate()
    }
    
    // MARK: - Public API
    
    /// Check if hot reload should degrade gracefully
    public func shouldDegrade() -> Bool {
        return degradationState != .normal
    }
    
    /// Get the appropriate fallback view for current degradation state
    public func getFallbackView(originalContent: AnyView) -> AnyView {
        switch fallbackStrategy {
        case .showOriginalContent:
            return originalContent
            
        case .showOfflineIndicator:
            return createOfflineIndicatorView(with: originalContent)
            
        case .showMinimalUI:
            return createMinimalUIView()
            
        case .showErrorMessage:
            return createErrorMessageView()
            
        case .showLoadingState:
            return createLoadingStateView()
            
        case .disableFeatures:
            return createDisabledFeaturesView(with: originalContent)
        }
    }
    
    /// Manually trigger degradation check
    public func checkDegradationStatus() {
        evaluateDegradationNeeds()
    }
    
    /// Force a specific degradation state (for testing)
    public func forceDegradationState(_ state: DegradationState, strategy: FallbackStrategy) {
        updateDegradationState(state, strategy: strategy, reason: "Manually forced")
    }
    
    /// Get degradation statistics
    public func getDegradationStats() -> DegradationStats {
        return DegradationStats(
            currentState: degradationState,
            totalDegradationEvents: degradationHistory.count,
            longestDegradationDuration: calculateLongestDegradationDuration(),
            averageDegradationDuration: calculateAverageDegradationDuration(),
            serverAvailability: serverAvailability,
            lastDegradationReason: degradationHistory.last?.reason
        )
    }
    
    // MARK: - Private Setup
    
    private func setupObservers() {
        // Monitor connection state changes
        connectionManager.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleConnectionStateChange(state)
            }
            .store(in: &cancellables)
        
        // Monitor network diagnostics
        connectionManager.$networkDiagnostics
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] diagnostics in
                self?.handleNetworkDiagnosticsUpdate(diagnostics)
            }
            .store(in: &cancellables)
        
        // Monitor rendering errors
        renderer.$lastError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleRenderingError(error)
            }
            .store(in: &cancellables)
    }
    
    private func setupServerMonitoring() {
        guard configuration.enableServerMonitoring else { return }
        
        serverCheckTimer = Timer.scheduledTimer(withTimeInterval: configuration.serverCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performServerHealthCheck()
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleConnectionStateChange(_ state: ConnectionState) {
        switch state {
        case .connected:
            if degradationState != .normal {
                recoverFromDegradation()
            }
            serverAvailability = .available
            
        case .connecting, .reconnecting:
            // Don't immediately degrade, give connection time
            if configuration.enableProgressiveDegradation {
                scheduleProgressiveDegradation()
            }
            
        case .disconnected:
            evaluateDegradationNeeds()
            
        case .error:
            serverAvailability = .unavailable
            triggerDegradation(reason: "Connection error occurred", severity: .high)
        }
    }
    
    private func handleNetworkDiagnosticsUpdate(_ diagnostics: NetworkDiagnostics) {
        // Evaluate degradation based on network quality
        if !diagnostics.isNetworkAvailable {
            serverAvailability = .networkUnavailable
            triggerDegradation(reason: "Network unavailable", severity: .critical)
        } else if diagnostics.consecutiveFailures >= configuration.maxConsecutiveFailures {
            serverAvailability = .unreliable
            triggerDegradation(reason: "Multiple consecutive failures", severity: .medium)
        }
    }
    
    private func handleRenderingError(_ error: SwiftUIRenderError) {
        // Consider rendering errors for degradation decisions
        switch error {
        case .invalidJSON, .invalidMessage:
            // Server might be sending corrupt data
            triggerDegradation(reason: "Invalid server response", severity: .medium)
        case .renderingFailed:
            // Rendering issues don't necessarily require degradation
            break
        default:
            break
        }
    }
    
    // MARK: - Degradation Logic
    
    private func evaluateDegradationNeeds() {
        let connectionDuration = connectionManager.reconnectAttempts * Int(connectionManager.configuration.baseReconnectDelay)
        
        if connectionDuration >= configuration.degradationThreshold {
            let strategy = determineFallbackStrategy()
            let severity = determineSeverity(connectionDuration: connectionDuration)
            
            triggerDegradation(
                reason: "Extended disconnection (\(connectionDuration)s)",
                severity: severity,
                strategy: strategy
            )
        }
    }
    
    private func determineFallbackStrategy() -> FallbackStrategy {
        // Choose strategy based on configuration and current conditions
        if serverAvailability == .networkUnavailable {
            return configuration.networkUnavailableStrategy
        } else if connectionManager.reconnectAttempts >= configuration.maxReconnectAttempts {
            return configuration.serverUnreachableStrategy
        } else {
            return configuration.temporaryFailureStrategy
        }
    }
    
    private func determineSeverity(connectionDuration: Int) -> DegradationSeverity {
        if connectionDuration >= configuration.criticalDegradationThreshold {
            return .critical
        } else if connectionDuration >= configuration.mediumDegradationThreshold {
            return .medium
        } else {
            return .low
        }
    }
    
    private func triggerDegradation(
        reason: String,
        severity: DegradationSeverity,
        strategy: FallbackStrategy? = nil
    ) {
        let selectedStrategy = strategy ?? determineFallbackStrategy()
        let newState: DegradationState
        
        switch severity {
        case .low:
            newState = .minorDegradation
        case .medium:
            newState = .moderateDegradation
        case .high:
            newState = .severeDegradation
        case .critical:
            newState = .criticalDegradation
        }
        
        updateDegradationState(newState, strategy: selectedStrategy, reason: reason)
    }
    
    private func updateDegradationState(
        _ state: DegradationState,
        strategy: FallbackStrategy,
        reason: String
    ) {
        let previousState = degradationState
        degradationState = state
        fallbackStrategy = strategy
        
        if degradationStartTime == nil {
            degradationStartTime = Date()
        }
        
        // Record degradation event
        let event = DegradationEvent(
            timestamp: Date(),
            fromState: previousState,
            toState: state,
            strategy: strategy,
            reason: reason
        )
        degradationHistory.append(event)
        
        // Limit history size
        if degradationHistory.count > configuration.maxHistorySize {
            degradationHistory.removeFirst(degradationHistory.count - configuration.maxHistorySize)
        }
        
        // Update user notification level
        updateUserNotificationLevel(for: state)
        
        if configuration.enableDebugLogging {
            print("🔄 Degradation state changed: \(previousState) → \(state) (\(reason))")
        }
    }
    
    private func recoverFromDegradation() {
        let recoveryDuration = degradationStartTime.map { Date().timeIntervalSince($0) }
        
        updateDegradationState(.normal, strategy: .showOriginalContent, reason: "Connection restored")
        degradationStartTime = nil
        serverAvailability = .available
        userNotificationLevel = .none
        
        if let duration = recoveryDuration, configuration.enableDebugLogging {
            print("✅ Recovered from degradation after \(String(format: "%.1f", duration))s")
        }
    }
    
    private func updateUserNotificationLevel(for state: DegradationState) {
        switch state {
        case .normal:
            userNotificationLevel = .none
        case .minorDegradation:
            userNotificationLevel = .subtle
        case .moderateDegradation:
            userNotificationLevel = .informational
        case .severeDegradation:
            userNotificationLevel = .warning
        case .criticalDegradation:
            userNotificationLevel = .critical
        }
    }
    
    // MARK: - Progressive Degradation
    
    private func scheduleProgressiveDegradation() {
        guard configuration.enableProgressiveDegradation else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + configuration.progressiveDegradationDelay) {
            if self.connectionManager.connectionState != .connected {
                self.evaluateDegradationNeeds()
            }
        }
    }
    
    // MARK: - Server Health Check
    
    private func performServerHealthCheck() async {
        // This would perform a lightweight health check
        // For now, we'll use connection state as a proxy
        let isHealthy = connectionManager.connectionState == .connected
        
        serverAvailability = isHealthy ? .available : .unavailable
        
        if !isHealthy && degradationState == .normal {
            evaluateDegradationNeeds()
        }
    }
    
    // MARK: - Statistics
    
    private func calculateLongestDegradationDuration() -> TimeInterval {
        // This would calculate based on degradation history
        // For now, return a placeholder
        return 0
    }
    
    private func calculateAverageDegradationDuration() -> TimeInterval {
        // This would calculate based on degradation history
        // For now, return a placeholder
        return 0
    }
}

// MARK: - Fallback View Creation

extension GracefulDegradationManager {
    
    private func createOfflineIndicatorView(with originalContent: AnyView) -> AnyView {
        return AnyView(
            ZStack {
                originalContent
                    .disabled(true)
                    .opacity(0.6)
                
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.orange)
                            Text("Offline")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.regularMaterial)
                        .cornerRadius(16)
                        .padding()
                    }
                    Spacer()
                }
            }
        )
    }
    
    private func createMinimalUIView() -> AnyView {
        return AnyView(
            VStack(spacing: 20) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                
                Text("Minimal Mode")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Hot reload is temporarily unavailable")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        )
    }
    
    private func createErrorMessageView() -> AnyView {
        return AnyView(
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                
                Text("Service Unavailable")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("The hot reload service is currently unavailable. Please check your development server.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Retry Connection") {
                    connectionManager.connect()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        )
    }
    
    private func createLoadingStateView() -> AnyView {
        return AnyView(
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Reconnecting...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Attempting to restore hot reload connection")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        )
    }
    
    private func createDisabledFeaturesView(with originalContent: AnyView) -> AnyView {
        return AnyView(
            originalContent
                .disabled(true)
                .overlay(
                    Rectangle()
                        .fill(Color.black.opacity(0.1))
                        .allowsHitTesting(false)
                )
        )
    }
}

// MARK: - Supporting Types

public enum DegradationState: String, CaseIterable {
    case normal = "normal"
    case minorDegradation = "minor"
    case moderateDegradation = "moderate"
    case severeDegradation = "severe"
    case criticalDegradation = "critical"
}

public enum FallbackStrategy: String, CaseIterable {
    case showOriginalContent = "original"
    case showOfflineIndicator = "offline_indicator"
    case showMinimalUI = "minimal_ui"
    case showErrorMessage = "error_message"
    case showLoadingState = "loading"
    case disableFeatures = "disable_features"
}

public enum ServerAvailability: String {
    case unknown = "unknown"
    case available = "available"
    case unavailable = "unavailable"
    case unreliable = "unreliable"
    case networkUnavailable = "network_unavailable"
}

public enum DegradationSeverity: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

public enum NotificationLevel: String {
    case none = "none"
    case subtle = "subtle"
    case informational = "informational"
    case warning = "warning"
    case critical = "critical"
}

public struct DegradationEvent {
    public let timestamp: Date
    public let fromState: DegradationState
    public let toState: DegradationState
    public let strategy: FallbackStrategy
    public let reason: String
}

public struct DegradationStats {
    public let currentState: DegradationState
    public let totalDegradationEvents: Int
    public let longestDegradationDuration: TimeInterval
    public let averageDegradationDuration: TimeInterval
    public let serverAvailability: ServerAvailability
    public let lastDegradationReason: String?
}

// MARK: - Configuration

public struct GracefulDegradationConfiguration {
    public let enableProgressiveDegradation: Bool
    public let enableServerMonitoring: Bool
    public let enableDebugLogging: Bool
    
    public let degradationThreshold: TimeInterval
    public let mediumDegradationThreshold: TimeInterval
    public let criticalDegradationThreshold: TimeInterval
    public let progressiveDegradationDelay: TimeInterval
    public let serverCheckInterval: TimeInterval
    
    public let maxConsecutiveFailures: Int
    public let maxReconnectAttempts: Int
    public let maxHistorySize: Int
    
    public let networkUnavailableStrategy: FallbackStrategy
    public let serverUnreachableStrategy: FallbackStrategy
    public let temporaryFailureStrategy: FallbackStrategy
    
    public init(
        enableProgressiveDegradation: Bool = true,
        enableServerMonitoring: Bool = true,
        enableDebugLogging: Bool = false,
        degradationThreshold: TimeInterval = 10.0,
        mediumDegradationThreshold: TimeInterval = 30.0,
        criticalDegradationThreshold: TimeInterval = 60.0,
        progressiveDegradationDelay: TimeInterval = 5.0,
        serverCheckInterval: TimeInterval = 15.0,
        maxConsecutiveFailures: Int = 3,
        maxReconnectAttempts: Int = 5,
        maxHistorySize: Int = 50,
        networkUnavailableStrategy: FallbackStrategy = .showOfflineIndicator,
        serverUnreachableStrategy: FallbackStrategy = .showErrorMessage,
        temporaryFailureStrategy: FallbackStrategy = .showLoadingState
    ) {
        self.enableProgressiveDegradation = enableProgressiveDegradation
        self.enableServerMonitoring = enableServerMonitoring
        self.enableDebugLogging = enableDebugLogging
        self.degradationThreshold = degradationThreshold
        self.mediumDegradationThreshold = mediumDegradationThreshold
        self.criticalDegradationThreshold = criticalDegradationThreshold
        self.progressiveDegradationDelay = progressiveDegradationDelay
        self.serverCheckInterval = serverCheckInterval
        self.maxConsecutiveFailures = maxConsecutiveFailures
        self.maxReconnectAttempts = maxReconnectAttempts
        self.maxHistorySize = maxHistorySize
        self.networkUnavailableStrategy = networkUnavailableStrategy
        self.serverUnreachableStrategy = serverUnreachableStrategy
        self.temporaryFailureStrategy = temporaryFailureStrategy
    }
    
    public static func development() -> GracefulDegradationConfiguration {
        return GracefulDegradationConfiguration(
            enableDebugLogging: true,
            degradationThreshold: 5.0,
            progressiveDegradationDelay: 2.0,
            serverCheckInterval: 10.0
        )
    }
    
    public static func production() -> GracefulDegradationConfiguration {
        return GracefulDegradationConfiguration(
            enableDebugLogging: false,
            degradationThreshold: 15.0,
            mediumDegradationThreshold: 45.0,
            criticalDegradationThreshold: 120.0,
            serverCheckInterval: 30.0
        )
    }
}