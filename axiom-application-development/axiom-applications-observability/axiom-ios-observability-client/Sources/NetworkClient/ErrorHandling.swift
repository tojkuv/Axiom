import Foundation
import Network
import Combine

// MARK: - Comprehensive Error Handling System

/// Enhanced error handling manager for network failures and recovery
@MainActor
public final class NetworkErrorHandler: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var currentError: NetworkError?
    @Published public private(set) var errorHistory: [NetworkErrorEvent] = []
    @Published public private(set) var connectionQuality: ConnectionQuality = .unknown
    @Published public private(set) var isNetworkAvailable: Bool = true
    @Published public private(set) var lastRecoveryAttempt: Date?
    @Published public private(set) var consecutiveFailures: Int = 0
    
    // MARK: - Properties
    
    private let configuration: ErrorHandlingConfiguration
    private let networkMonitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "NetworkErrorHandler.Monitor")
    private var cancellables = Set<AnyCancellable>()
    private var retryTimer: Timer?
    private var qualityMonitorTimer: Timer?
    
    // Recovery strategies
    private var recoveryStrategies: [ErrorType: RecoveryStrategy] = [:]
    
    public init(configuration: ErrorHandlingConfiguration = ErrorHandlingConfiguration()) {
        self.configuration = configuration
        self.networkMonitor = NWPathMonitor()
        
        setupNetworkMonitoring()
        setupRecoveryStrategies()
        startConnectionQualityMonitoring()
    }
    
    deinit {
        networkMonitor.cancel()
        retryTimer?.invalidate()
        qualityMonitorTimer?.invalidate()
    }
    
    // MARK: - Public API
    
    /// Handle a network error with automatic recovery
    public func handleError(_ error: Error, context: ErrorContext? = nil) {
        let networkError = categorizeError(error, context: context)
        recordError(networkError)
        
        if configuration.enableAutoRecovery {
            attemptRecovery(for: networkError)
        }
    }
    
    /// Manually trigger recovery for the current error
    public func triggerRecovery() {
        guard let error = currentError else { return }
        attemptRecovery(for: error)
    }
    
    /// Clear current error state
    public func clearError() {
        currentError = nil
        consecutiveFailures = 0
        retryTimer?.invalidate()
    }
    
    /// Get user-friendly error message with recovery suggestions
    public func getUserFriendlyMessage(for error: NetworkError) -> ErrorMessage {
        return ErrorMessage(
            title: getErrorTitle(for: error),
            description: getErrorDescription(for: error),
            suggestion: getRecoverySuggestion(for: error),
            severity: error.severity,
            isRecoverable: error.isRecoverable
        )
    }
    
    /// Get network diagnostics information
    public func getNetworkDiagnostics() -> NetworkDiagnostics {
        return NetworkDiagnostics(
            isNetworkAvailable: isNetworkAvailable,
            connectionQuality: connectionQuality,
            currentError: currentError,
            consecutiveFailures: consecutiveFailures,
            lastRecoveryAttempt: lastRecoveryAttempt,
            errorHistory: Array(errorHistory.suffix(10)) // Last 10 errors
        )
    }
    
    // MARK: - Error Categorization
    
    private func categorizeError(_ error: Error, context: ErrorContext?) -> NetworkError {
        let errorType = determineErrorType(error)
        let severity = determineSeverity(for: errorType, error: error)
        let isRecoverable = determineRecoverability(for: errorType, error: error)
        
        return NetworkError(
            type: errorType,
            underlyingError: error,
            severity: severity,
            isRecoverable: isRecoverable,
            timestamp: Date(),
            context: context
        )
    }
    
    private func determineErrorType(_ error: Error) -> ErrorType {
        // Check for specific error types
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .timedOut:
                return .timeout
            case .cannotFindHost, .cannotConnectToHost:
                return .serverUnreachable
            case .badServerResponse:
                return .serverError
            default:
                return .connectionFailed
            }
        }
        
        let nsError = error as NSError
        switch nsError.domain {
        case NSURLErrorDomain:
            return .connectionFailed
        case "WebSocketErrorDomain":
            return .websocketError
        default:
            return .unknown
        }
        
        // Check for custom error types
        if error is ConnectionManagerError {
            return .connectionManagerError
        }
        
        return .unknown
    }
    
    private func determineSeverity(for type: ErrorType, error: Error) -> ErrorSeverity {
        switch type {
        case .networkUnavailable:
            return .critical
        case .serverUnreachable, .timeout:
            return .high
        case .connectionFailed, .websocketError:
            return .medium
        case .serverError, .connectionManagerError:
            return .medium
        case .unknown:
            return .low
        }
    }
    
    private func determineRecoverability(for type: ErrorType, error: Error) -> Bool {
        switch type {
        case .networkUnavailable:
            return true // Can recover when network comes back
        case .serverUnreachable, .timeout, .connectionFailed, .websocketError:
            return true // Can retry connection
        case .serverError:
            // Check if it's a recoverable server error
            if let connectionError = error as? ConnectionManagerError {
                return connectionError.isRecoverable
            }
            return true
        case .connectionManagerError:
            if let connectionError = error as? ConnectionManagerError {
                return connectionError.isRecoverable
            }
            return true
        case .unknown:
            return false
        }
    }
    
    // MARK: - Recovery Implementation
    
    private func setupRecoveryStrategies() {
        recoveryStrategies = [
            .networkUnavailable: .waitForNetwork,
            .serverUnreachable: .exponentialBackoff,
            .timeout: .immediateRetry,
            .connectionFailed: .exponentialBackoff,
            .websocketError: .exponentialBackoff,
            .serverError: .exponentialBackoff,
            .connectionManagerError: .exponentialBackoff,
            .unknown: .none
        ]
    }
    
    private func attemptRecovery(for error: NetworkError) {
        guard error.isRecoverable else { return }
        
        let strategy = recoveryStrategies[error.type] ?? .none
        lastRecoveryAttempt = Date()
        
        switch strategy {
        case .none:
            break
            
        case .immediateRetry:
            if consecutiveFailures < configuration.maxRetryAttempts {
                performImmediateRetry()
            }
            
        case .exponentialBackoff:
            if consecutiveFailures < configuration.maxRetryAttempts {
                performExponentialBackoffRetry()
            }
            
        case .waitForNetwork:
            waitForNetworkRecovery()
        }
    }
    
    private func performImmediateRetry() {
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.executeRecovery()
            }
        }
    }
    
    private func performExponentialBackoffRetry() {
        let delay = calculateExponentialDelay()
        
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.executeRecovery()
            }
        }
    }
    
    private func waitForNetworkRecovery() {
        // Recovery will be triggered automatically when network becomes available
        // through the network monitor
    }
    
    private func calculateExponentialDelay() -> TimeInterval {
        let baseDelay = configuration.baseRetryDelay
        let maxDelay = configuration.maxRetryDelay
        let factor = configuration.backoffFactor
        
        let delay = baseDelay * pow(factor, Double(consecutiveFailures))
        return min(delay, maxDelay)
    }
    
    private func executeRecovery() {
        // This would trigger the actual recovery action
        // For now, we'll just clear the error and notify that recovery was attempted
        clearError()
        
        // In a real implementation, this would call back to the ConnectionManager
        // to retry the connection
        NotificationCenter.default.post(
            name: .networkErrorRecoveryAttempted,
            object: self
        )
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handleNetworkPathUpdate(path)
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    private func stopNetworkMonitoring() {
        networkMonitor.cancel()
    }
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        let wasAvailable = isNetworkAvailable
        isNetworkAvailable = path.status == .satisfied
        
        // Update connection quality
        updateConnectionQuality(from: path)
        
        // If network became available and we have a network-related error, attempt recovery
        if !wasAvailable && isNetworkAvailable && currentError?.type == .networkUnavailable {
            executeRecovery()
        }
    }
    
    private func updateConnectionQuality(from path: NWPath) {
        if path.status != .satisfied {
            connectionQuality = .unavailable
            return
        }
        
        if path.isExpensive {
            connectionQuality = .poor
        } else if path.isConstrained {
            connectionQuality = .fair
        } else {
            connectionQuality = .good
        }
    }
    
    // MARK: - Connection Quality Monitoring
    
    private func startConnectionQualityMonitoring() {
        qualityMonitorTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.monitorConnectionQuality()
            }
        }
    }
    
    private func stopConnectionQualityMonitoring() {
        qualityMonitorTimer?.invalidate()
        qualityMonitorTimer = nil
    }
    
    private func monitorConnectionQuality() {
        // This could include ping tests, latency measurements, etc.
        // For now, we'll just maintain the current quality based on network path
    }
    
    // MARK: - Error Recording
    
    private func recordError(_ error: NetworkError) {
        currentError = error
        consecutiveFailures += 1
        
        let event = NetworkErrorEvent(
            error: error,
            timestamp: Date(),
            attemptNumber: consecutiveFailures
        )
        
        errorHistory.append(event)
        
        // Limit history size
        if errorHistory.count > configuration.maxErrorHistorySize {
            errorHistory.removeFirst(errorHistory.count - configuration.maxErrorHistorySize)
        }
    }
    
    // MARK: - User-Friendly Messages
    
    private func getErrorTitle(for error: NetworkError) -> String {
        switch error.type {
        case .networkUnavailable:
            return "No Internet Connection"
        case .serverUnreachable:
            return "Server Unavailable"
        case .timeout:
            return "Connection Timeout"
        case .connectionFailed:
            return "Connection Failed"
        case .websocketError:
            return "Real-time Connection Lost"
        case .serverError:
            return "Server Error"
        case .connectionManagerError:
            return "Connection Error"
        case .unknown:
            return "Unknown Error"
        }
    }
    
    private func getErrorDescription(for error: NetworkError) -> String {
        switch error.type {
        case .networkUnavailable:
            return "Please check your internet connection and try again."
        case .serverUnreachable:
            return "Unable to reach the hot reload server. Make sure the server is running."
        case .timeout:
            return "The connection took too long to respond. This might be due to slow network or server issues."
        case .connectionFailed:
            return "Failed to establish connection to the server."
        case .websocketError:
            return "The real-time connection was interrupted. Hot reload functionality may be limited."
        case .serverError:
            return "The server encountered an error while processing your request."
        case .connectionManagerError:
            return "An error occurred in the connection management system."
        case .unknown:
            return "An unexpected error occurred."
        }
    }
    
    private func getRecoverySuggestion(for error: NetworkError) -> String {
        switch error.type {
        case .networkUnavailable:
            return "Check your WiFi or cellular connection and try again."
        case .serverUnreachable:
            return "Ensure the hot reload server is running on your development machine."
        case .timeout:
            return "Try connecting again, or check your network speed."
        case .connectionFailed:
            return "Verify the server address and port settings, then retry."
        case .websocketError:
            return "The connection will automatically retry. You can also manually reconnect."
        case .serverError:
            return "Check the server logs for more details, or restart the server."
        case .connectionManagerError:
            return "Try disconnecting and reconnecting to resolve the issue."
        case .unknown:
            return "Try restarting the app or checking your connection settings."
        }
    }
}

// MARK: - Supporting Types

public struct ErrorHandlingConfiguration {
    public let enableAutoRecovery: Bool
    public let maxRetryAttempts: Int
    public let baseRetryDelay: TimeInterval
    public let maxRetryDelay: TimeInterval
    public let backoffFactor: Double
    public let maxErrorHistorySize: Int
    public let enableNetworkMonitoring: Bool
    
    public init(
        enableAutoRecovery: Bool = true,
        maxRetryAttempts: Int = 5,
        baseRetryDelay: TimeInterval = 1.0,
        maxRetryDelay: TimeInterval = 30.0,
        backoffFactor: Double = 2.0,
        maxErrorHistorySize: Int = 100,
        enableNetworkMonitoring: Bool = true
    ) {
        self.enableAutoRecovery = enableAutoRecovery
        self.maxRetryAttempts = maxRetryAttempts
        self.baseRetryDelay = baseRetryDelay
        self.maxRetryDelay = maxRetryDelay
        self.backoffFactor = backoffFactor
        self.maxErrorHistorySize = maxErrorHistorySize
        self.enableNetworkMonitoring = enableNetworkMonitoring
    }
    
    public static func development() -> ErrorHandlingConfiguration {
        return ErrorHandlingConfiguration(
            enableAutoRecovery: true,
            maxRetryAttempts: 3,
            baseRetryDelay: 0.5,
            maxRetryDelay: 10.0,
            backoffFactor: 1.5
        )
    }
    
    public static func production() -> ErrorHandlingConfiguration {
        return ErrorHandlingConfiguration(
            enableAutoRecovery: true,
            maxRetryAttempts: 5,
            baseRetryDelay: 2.0,
            maxRetryDelay: 60.0,
            backoffFactor: 2.0
        )
    }
}

public struct NetworkError {
    public let type: ErrorType
    public let underlyingError: Error
    public let severity: ErrorSeverity
    public let isRecoverable: Bool
    public let timestamp: Date
    public let context: ErrorContext?
    
    public var localizedDescription: String {
        return underlyingError.localizedDescription
    }
}

public enum ErrorType {
    case networkUnavailable
    case serverUnreachable
    case timeout
    case connectionFailed
    case websocketError
    case serverError
    case connectionManagerError
    case unknown
}

public enum ErrorSeverity {
    case low
    case medium
    case high
    case critical
}

public enum RecoveryStrategy {
    case none
    case immediateRetry
    case exponentialBackoff
    case waitForNetwork
}

public enum ConnectionQuality: String {
    case unknown = "unknown"
    case unavailable = "unavailable"
    case poor = "poor"
    case fair = "fair"
    case good = "good"
    case excellent = "excellent"
}

public struct ErrorContext {
    public let operation: String
    public let attemptNumber: Int
    public let metadata: [String: Any]
    
    public init(operation: String, attemptNumber: Int = 1, metadata: [String: Any] = [:]) {
        self.operation = operation
        self.attemptNumber = attemptNumber
        self.metadata = metadata
    }
}

public struct ErrorMessage {
    public let title: String
    public let description: String
    public let suggestion: String
    public let severity: ErrorSeverity
    public let isRecoverable: Bool
}

public struct NetworkErrorEvent {
    public let error: NetworkError
    public let timestamp: Date
    public let attemptNumber: Int
}

public struct NetworkDiagnostics {
    public let isNetworkAvailable: Bool
    public let connectionQuality: ConnectionQuality
    public let currentError: NetworkError?
    public let consecutiveFailures: Int
    public let lastRecoveryAttempt: Date?
    public let errorHistory: [NetworkErrorEvent]
}

// MARK: - Notifications

public extension Notification.Name {
    static let networkErrorRecoveryAttempted = Notification.Name("NetworkErrorRecoveryAttempted")
}