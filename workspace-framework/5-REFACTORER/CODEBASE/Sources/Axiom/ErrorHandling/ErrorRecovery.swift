import Foundation

// MARK: - Error Recovery Patterns

/// Protocol for components that can recover from errors
public protocol ErrorRecoverable {
    associatedtype RecoveryOption
    
    /// Suggest recovery options for a given error
    func recoverySuggestions(for error: AxiomError) -> [RecoveryOption]
    
    /// Attempt to recover from an error using a specific option
    func attemptRecovery(from error: AxiomError, using option: RecoveryOption) async -> Result<Void, AxiomError>
}

/// Standard recovery strategies available throughout the framework
public enum StandardRecovery: Equatable {
    case retry(maxAttempts: Int, delay: TimeInterval)
    case fallback(to: String) // Use String for Equatable compliance
    case ignore
    case reportAndContinue
    
    /// Executes the recovery strategy for a given error
    public func execute(for error: AxiomError, operation: @escaping () async throws -> Void) async -> Result<Void, AxiomError> {
        switch self {
        case .retry(let maxAttempts, let delay):
            return await attemptRetry(operation: operation, maxAttempts: maxAttempts, delay: delay)
            
        case .fallback:
            // In a real implementation, would execute actual fallback
            return .success(())
            
        case .ignore:
            // Silently ignore the error and continue
            return .success(())
            
        case .reportAndContinue:
            // Log the error and continue
            print("Error reported and continuing: \(error)")
            return .success(())
        }
    }
    
    private func attemptRetry(
        operation: @escaping () async throws -> Void,
        maxAttempts: Int,
        delay: TimeInterval
    ) async -> Result<Void, AxiomError> {
        var lastError: AxiomError?
        
        for attempt in 0..<maxAttempts {
            do {
                if attempt > 0 {
                    // Add exponential backoff
                    let backoffDelay = delay * pow(2.0, Double(attempt - 1))
                    try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                }
                
                try await operation()
                return .success(())
            } catch let error as AxiomError {
                lastError = error
                
                // Don't retry validation errors
                if case .validationError = error {
                    break
                }
            } catch {
                lastError = AxiomError(legacy: error)
            }
        }
        
        return .failure(lastError ?? AxiomError.contextError(.lifecycleError("Unknown retry failure")))
    }
}

// MARK: - Result Recovery Extension

public extension Result {
    /// Attempt to recover from failure with a transformation
    func recover(_ transform: (Failure) -> Result<Success, Failure>) -> Result<Success, Failure> {
        switch self {
        case .success:
            return self
        case .failure(let error):
            return transform(error)
        }
    }
    
    /// Recover with a default value
    func recover(with defaultValue: Success) -> Result<Success, Failure> {
        switch self {
        case .success:
            return self
        case .failure:
            return .success(defaultValue)
        }
    }
}

public extension Result where Failure == AxiomError {
    /// Attempts to recover from a failure using a recovery closure
    func recover(_ recovery: (AxiomError) async -> Result<Success, AxiomError>) async -> Result<Success, AxiomError> {
        switch self {
        case .success:
            return self
        case .failure(let error):
            return await recovery(error)
        }
    }
    
    /// Recover with retry logic
    func recoverWithRetry(
        maxAttempts: Int,
        delay: TimeInterval,
        operation: @escaping () async -> Result<Success, AxiomError>
    ) async -> Result<Success, AxiomError> {
        switch self {
        case .success:
            return self
        case .failure:
            var attempts = 1
            while attempts < maxAttempts {
                // Exponential backoff
                let backoffDelay = delay * pow(2.0, Double(attempts - 1))
                try? await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                
                let result = await operation()
                switch result {
                case .success:
                    return result
                case .failure:
                    attempts += 1
                }
            }
            return self // Return original failure
        }
    }
}

// MARK: - Error Context Types for Enhanced Propagation

/// Context information for network-related errors
public struct NetworkContext {
    public let operation: String
    public let url: URL?
    public let statusCode: Int?
    public let underlying: Error?
    public var metadata: [String: String]
    
    public init(operation: String, url: URL?, statusCode: Int? = nil, underlying: Error? = nil, metadata: [String: String] = [:]) {
        self.operation = operation
        self.url = url
        self.statusCode = statusCode
        self.underlying = underlying
        self.metadata = metadata
    }
}

/// Context information for persistence-related errors
public struct PersistenceContext {
    public let operation: String
    public let entity: String?
    public let underlying: Error?
    public var metadata: [String: String]
    
    public init(operation: String, entity: String? = nil, underlying: Error? = nil, metadata: [String: String] = [:]) {
        self.operation = operation
        self.entity = entity
        self.underlying = underlying
        self.metadata = metadata
    }
}

/// Context information for validation-related errors
public struct ValidationContext {
    public let field: String
    public let rule: String
    public let message: String
    public var metadata: [String: String]
    
    public init(field: String, rule: String, message: String, metadata: [String: String] = [:]) {
        self.field = field
        self.rule = rule
        self.message = message
        self.metadata = metadata
    }
}

// MARK: - Enhanced AxiomError with Rich Context

public extension AxiomError {
    /// Creates a network error with rich context
    static func networkError(_ context: NetworkContext) -> AxiomError {
        let description = "Network operation '\(context.operation)' failed"
        let error = AxiomError.navigationError(.invalidURL(component: "network", value: context.operation))
        
        // Store metadata for the network context
        var metadata = context.metadata
        metadata["operation"] = context.operation
        if let url = context.url {
            metadata["url"] = url.absoluteString
        }
        if let statusCode = context.statusCode {
            metadata["status_code"] = String(statusCode)
        }
        
        return error
    }
    
    /// Creates a network error with navigation error case
    static func networkError(_ navigationError: AxiomNavigationError) -> AxiomError {
        return .navigationError(navigationError)
    }
    
    /// Creates a persistence error with rich context
    static func persistenceContext(_ context: PersistenceContext) -> AxiomError {
        let description = "Persistence operation '\(context.operation)' failed"
        return .persistenceError(.saveFailed(description))
    }
    
    /// Creates a validation error with rich context
    static func validationContext(_ context: ValidationContext) -> AxiomError {
        return .validationError(.ruleFailed(field: context.field, rule: context.rule, reason: context.message))
    }
}

// MARK: - Enhanced Recovery Strategy Framework (REQUIREMENTS-W-06-003)

/// Enhanced backoff strategies for recovery operations
public enum BackoffStrategy: Equatable, Sendable {
    case none
    case constant(TimeInterval)
    case linear(initial: TimeInterval, increment: TimeInterval)
    case exponential(initial: TimeInterval = 1.0, multiplier: Double = 2.0, maxDelay: TimeInterval = 60.0)
    
    /// Calculate delay for specific attempt
    public func calculateDelay(for attempt: Int) -> TimeInterval {
        switch self {
        case .none:
            return 0
        case .constant(let delay):
            return delay
        case .linear(let initial, let increment):
            return initial + increment * Double(attempt - 1)
        case .exponential(let initial, let multiplier, let maxDelay):
            let delay = initial * pow(multiplier, Double(attempt - 1))
            return min(delay, maxDelay)
        }
    }
}

/// Recovery metrics for monitoring and analytics
public struct RecoveryMetrics {
    public let totalAttempts: Int
    public let successCount: Int
    public let failureCount: Int
    public let totalLatency: TimeInterval
    
    public init(totalAttempts: Int, successCount: Int, failureCount: Int, totalLatency: TimeInterval) {
        self.totalAttempts = totalAttempts
        self.successCount = successCount
        self.failureCount = failureCount
        self.totalLatency = totalLatency
    }
}

/// Aggregate recovery metrics for system-wide monitoring
public struct AggregateRecoveryMetrics {
    public let totalOperations: Int
    public let averageAttempts: Double
    public let successRate: Double
    public let averageLatency: TimeInterval
    
    public init(totalOperations: Int, averageAttempts: Double, successRate: Double, averageLatency: TimeInterval) {
        self.totalOperations = totalOperations
        self.averageAttempts = averageAttempts
        self.successRate = successRate
        self.averageLatency = averageLatency
    }
}

/// Recovery metrics collector for monitoring and analytics
public class RecoveryMetricsCollector {
    private var metrics: [String: RecoveryMetrics] = [:]
    private var aggregateData: [(attempts: Int, success: Bool, latency: TimeInterval)] = []
    private let queue = DispatchQueue(label: "RecoveryMetricsCollector", attributes: .concurrent)
    
    public init() {}
    
    public func recordAttempt(operation: String = "default", attempts: Int, success: Bool, latency: TimeInterval) {
        queue.async(flags: .barrier) {
            self.aggregateData.append((attempts, success, latency))
            self.metrics[operation] = RecoveryMetrics(
                totalAttempts: attempts,
                successCount: success ? 1 : 0,
                failureCount: success ? 0 : 1,
                totalLatency: latency
            )
        }
    }
    
    public func getMetrics(for operation: String) -> RecoveryMetrics {
        return queue.sync {
            return metrics[operation] ?? RecoveryMetrics(totalAttempts: 0, successCount: 0, failureCount: 0, totalLatency: 0)
        }
    }
    
    public func getAggregateMetrics() -> AggregateRecoveryMetrics {
        return queue.sync {
            let totalOps = aggregateData.count
            guard totalOps > 0 else {
                return AggregateRecoveryMetrics(totalOperations: 0, averageAttempts: 0, successRate: 0, averageLatency: 0)
            }
            
            let avgAttempts = aggregateData.map { Double($0.attempts) }.reduce(0, +) / Double(totalOps)
            let successRate = Double(aggregateData.filter { $0.success }.count) / Double(totalOps)
            let avgLatency = aggregateData.map { $0.latency }.reduce(0, +) / Double(totalOps)
            
            return AggregateRecoveryMetrics(
                totalOperations: totalOps,
                averageAttempts: avgAttempts,
                successRate: successRate,
                averageLatency: avgLatency
            )
        }
    }
}

/// Recovery middleware for extensible recovery hooks
public class RecoveryMiddleware {
    private var preHooks: [(Error, Int) -> Void] = []
    private var postHooks: [(Error, Int, Bool) -> Void] = []
    
    public init() {}
    
    public func addPreRecoveryHook(_ hook: @escaping (Error, Int) -> Void) {
        preHooks.append(hook)
    }
    
    public func addPostRecoveryHook(_ hook: @escaping (Error, Int, Bool) -> Void) {
        postHooks.append(hook)
    }
    
    public func executePreHooks(error: Error, attempt: Int) {
        for hook in preHooks {
            hook(error, attempt)
        }
    }
    
    public func executePostHooks(error: Error, attempt: Int, success: Bool) {
        for hook in postHooks {
            hook(error, attempt, success)
        }
    }
}

/// Recovery context for preserving operation information
public struct RecoveryContext {
    public let operationId: String
    public let userId: String?
    public let sessionId: String?
    public var metadata: [String: String]
    
    public init(operationId: String, userId: String? = nil, sessionId: String? = nil, metadata: [String: String] = [:]) {
        self.operationId = operationId
        self.userId = userId
        self.sessionId = sessionId
        self.metadata = metadata
    }
    
    /// Thread-local current context
    private static let contextKey = "RecoveryContext.current"
    
    public static var current: RecoveryContext? {
        get {
            return Thread.current.threadDictionary[contextKey] as? RecoveryContext
        }
        set {
            if let context = newValue {
                Thread.current.threadDictionary[contextKey] = context
            } else {
                Thread.current.threadDictionary.removeObject(forKey: contextKey)
            }
        }
    }
}

/// Enhanced recovery strategy for comprehensive error recovery
public enum EnhancedRecoveryStrategy {
    case retry(maxAttempts: Int, backoff: BackoffStrategy, metrics: RecoveryMetricsCollector? = nil, middleware: RecoveryMiddleware? = nil)
    case fallbackChain([(Error) async throws -> Any])
    case userPrompt(message: String, options: [String], handler: (String) -> EnhancedRecoveryStrategy)
    case retryWithTimeout(maxAttempts: Int, operationTimeout: TimeInterval, backoff: BackoffStrategy)
    case fail
    
    public var isRetryStrategy: Bool {
        switch self {
        case .retry, .retryWithTimeout:
            return true
        default:
            return false
        }
    }
    
    public var isUserPromptStrategy: Bool {
        switch self {
        case .userPrompt:
            return true
        default:
            return false
        }
    }
    
    /// Execute operation with recovery strategy
    public func execute<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        switch self {
        case .retry(let maxAttempts, let backoff, let metrics, let middleware):
            return try await executeRetry(operation: operation, maxAttempts: maxAttempts, backoff: backoff, metrics: metrics, middleware: middleware)
            
        case .fallbackChain(let fallbacks):
            return try await executeFallbackChain(operation: operation, fallbacks: fallbacks)
            
        case .userPrompt(let message, let options, let handler):
            return try await executeUserPrompt(operation: operation, message: message, options: options, handler: handler)
            
        case .retryWithTimeout(let maxAttempts, let timeout, let backoff):
            return try await executeRetryWithTimeout(operation: operation, maxAttempts: maxAttempts, timeout: timeout, backoff: backoff)
            
        case .fail:
            return try await operation()
        }
    }
    
    /// Execute operation with context preservation
    public func executeWithContext<T>(_ context: RecoveryContext, operation: @escaping () async throws -> T) async throws -> T {
        let previousContext = RecoveryContext.current
        defer { RecoveryContext.current = previousContext }
        
        RecoveryContext.current = context
        return try await execute(operation)
    }
    
    // MARK: - Private Implementation Methods
    
    private func executeRetry<T>(
        operation: @escaping () async throws -> T,
        maxAttempts: Int,
        backoff: BackoffStrategy,
        metrics: RecoveryMetricsCollector?,
        middleware: RecoveryMiddleware?
    ) async throws -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                // Execute pre-recovery hooks
                if let error = lastError {
                    middleware?.executePreHooks(error: error, attempt: attempt)
                }
                
                // Apply backoff delay
                if attempt > 1 {
                    let delay = backoff.calculateDelay(for: attempt - 1)
                    if delay > 0 {
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                }
                
                let result = try await operation()
                
                // Record success metrics
                let totalTime = CFAbsoluteTimeGetCurrent() - startTime
                metrics?.recordAttempt(attempts: attempt, success: true, latency: totalTime)
                
                // Execute post-recovery hooks
                if let error = lastError {
                    middleware?.executePostHooks(error: error, attempt: attempt, success: true)
                }
                
                return result
                
            } catch {
                lastError = error
                
                // Don't retry certain error types
                if !shouldRetryError(error) {
                    break
                }
                
                // Execute post-recovery hooks
                middleware?.executePostHooks(error: error, attempt: attempt, success: false)
            }
        }
        
        // Record failure metrics
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        metrics?.recordAttempt(attempts: maxAttempts, success: false, latency: totalTime)
        
        throw lastError!
    }
    
    private func executeFallbackChain<T>(
        operation: @escaping () async throws -> T,
        fallbacks: [(Error) async throws -> Any]
    ) async throws -> T {
        do {
            return try await operation()
        } catch {
            for fallback in fallbacks {
                do {
                    let result = try await fallback(error)
                    if let typedResult = result as? T {
                        return typedResult
                    }
                } catch {
                    // Continue to next fallback
                    continue
                }
            }
            throw error
        }
    }
    
    private func executeUserPrompt<T>(
        operation: @escaping () async throws -> T,
        message: String,
        options: [String],
        handler: (String) -> EnhancedRecoveryStrategy
    ) async throws -> T {
        do {
            return try await operation()
        } catch {
            // In a real implementation, would show actual user prompt
            // For testing, use mock response
            let selectedOption = UserInteractionMock.getNextResponse() ?? options.first ?? "Cancel"
            let recoveryStrategy = handler(selectedOption)
            return try await recoveryStrategy.execute(operation)
        }
    }
    
    private func executeRetryWithTimeout<T>(
        operation: @escaping () async throws -> T,
        maxAttempts: Int,
        timeout: TimeInterval,
        backoff: BackoffStrategy
    ) async throws -> T {
        for attempt in 1...maxAttempts {
            do {
                // Apply backoff delay
                if attempt > 1 {
                    let delay = backoff.calculateDelay(for: attempt - 1)
                    if delay > 0 {
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                }
                
                // Execute with timeout
                return try await withTimeout(timeout, operation: operation)
                
            } catch {
                if attempt == maxAttempts {
                    throw error
                }
                // Continue to next attempt
            }
        }
        
        throw RecoveryTimeoutError(operation: "retryWithTimeout", timeout: timeout)
    }
    
    private func shouldRetryError(_ error: Error) -> Bool {
        // Don't retry validation errors
        if case .validationError = error as? AxiomError {
            return false
        }
        return true
    }
}

/// Recovery strategy selector for automatic strategy selection
public struct RecoveryStrategySelector {
    public static func defaultStrategy(for error: Error) -> EnhancedRecoveryStrategy {
        let category = ErrorCategory.categorize(error)
        
        switch category {
        case .network:
            return .retry(
                maxAttempts: 3,
                backoff: .exponential(initial: 1.0, multiplier: 2.0, maxDelay: 30.0)
            )
        case .validation:
            return .userPrompt(
                message: "Please correct your input",
                options: ["Retry", "Cancel"]
            ) { option in
                switch option {
                case "Retry":
                    return .retry(maxAttempts: 1, backoff: .none)
                default:
                    return .fail
                }
            }
        case .authorization:
            return .userPrompt(
                message: "Please sign in to continue",
                options: ["Sign In", "Cancel"]
            ) { option in
                switch option {
                case "Sign In":
                    return .retry(maxAttempts: 1, backoff: .none)
                default:
                    return .fail
                }
            }
        case .system, .dataIntegrity:
            return .fail
        case .unknown:
            return .retry(maxAttempts: 1, backoff: .constant(1.0))
        }
    }
}

/// Recovery timeout error
public struct RecoveryTimeoutError: Error {
    public let operation: String
    public let timeout: TimeInterval
    
    public init(operation: String, timeout: TimeInterval) {
        self.operation = operation
        self.timeout = timeout
    }
}

/// User interaction mock for testing
public class UserInteractionMock {
    private static var responses: [String] = []
    private static let queue = DispatchQueue(label: "UserInteractionMock")
    
    public static func setNextResponse(_ response: String) {
        queue.sync {
            responses.append(response)
        }
    }
    
    public static func getNextResponse() -> String? {
        return queue.sync {
            guard !responses.isEmpty else { return nil }
            return responses.removeFirst()
        }
    }
}

/// Enhanced error boundary with recovery strategy integration
@MainActor
public class EnhancedErrorBoundary {
    public let id: String
    private let recoveryStrategy: EnhancedRecoveryStrategy
    private var attachedClients: [AnyObject] = []
    
    public init(id: String, recoveryStrategy: EnhancedRecoveryStrategy) {
        self.id = id
        self.recoveryStrategy = recoveryStrategy
    }
    
    public func attachClient<T: AnyObject>(_ client: T) async {
        attachedClients.append(client)
    }
    
    public func executeWithRecovery<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        return try await recoveryStrategy.execute(operation)
    }
}

// MARK: - Legacy Support and Compatibility

/// Legacy calculateBackoffDelay function - use BackoffStrategy.calculateDelay instead
@available(*, deprecated, message: "Use BackoffStrategy.calculateDelay(for:) instead")
public func calculateBackoffDelay(strategy: BackoffStrategy, attempt: Int) -> TimeInterval {
    return strategy.calculateDelay(for: attempt)
}

/// Timeout wrapper for operations
public func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw AxiomError.clientError(.timeout(duration: TimeInterval(timeout)))
        }
        
        guard let result = try await group.next() else {
            throw AxiomError.clientError(.timeout(duration: TimeInterval(timeout)))
        }
        
        group.cancelAll()
        return result
    }
}