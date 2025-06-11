import Foundation

// MARK: - Error Categorization System

/// Automatic error categorization for propagation patterns
public enum ErrorCategory: String, CaseIterable, Sendable {
    case network
    case validation
    case authorization
    case dataIntegrity
    case system
    case unknown
    
    /// Automatically categorize errors based on type and content
    public static func categorize(_ error: Error) -> ErrorCategory {
        switch error {
        case let urlError as URLError:
            return .network
        case let axiomError as AxiomError:
            switch axiomError {
            case .validationError:
                return .validation
            case .navigationError(let navError):
                switch navError {
                case .unauthorized, .authenticationRequired:
                    return .authorization
                default:
                    return .system
                }
            case .persistenceError:
                return .dataIntegrity
            case .clientError:
                return .authorization
            case .capabilityError:
                return .authorization
            case .actorError:
                return .system
            case .contextError:
                return .system
            }
        case let nsError as NSError:
            if nsError.domain == NSURLErrorDomain {
                return .network
            } else if nsError.domain == NSCocoaErrorDomain {
                return .system
            }
            return .unknown
        default:
            return .unknown
        }
    }
}

/// Recovery strategies based on error category
public enum PropagationRecoveryStrategy: Equatable {
    case retry(maxAttempts: Int, delay: TimeInterval)
    case fail
    case log(level: ErrorSeverity)
}

// MARK: - Result Extensions for Error Propagation

/// Extension for mapping errors to AxiomError with proper context
public extension Result where Failure == Error {
    /// Transform any error to AxiomError, preserving existing AxiomErrors
    func mapToAxiomError(_ transform: (Error) -> AxiomError) -> Result<Success, AxiomError> {
        mapError { error in
            if let axiomError = error as? AxiomError {
                return axiomError
            }
            return transform(error)
        }
    }
}

// MARK: - Task Extensions for Error Propagation

/// Maps a Task with generic Error to one with AxiomError
public func mapTaskToAxiomError<T>(
    _ task: Task<T, Error>,
    transform: @escaping (Error) -> AxiomError
) async throws -> T {
    do {
        return try await task.value
    } catch let error as AxiomError {
        throw error
    } catch {
        throw transform(error)
    }
}

public extension Task where Failure == Error {
    /// Maps task errors to AxiomError, preserving existing AxiomError instances
    func mapToAxiomError(_ transform: @escaping (Error) -> AxiomError) async throws -> Success {
        do {
            return try await self.value
        } catch let error as AxiomError {
            throw error
        } catch {
            throw transform(error)
        }
    }
}

/// Helper for async error transformation
public func mapTaskError<T>(_ task: Task<T, Error>, transform: @escaping (Error) -> AxiomError) async throws -> T {
    do {
        return try await task.value
    } catch let error as AxiomError {
        throw error
    } catch {
        throw transform(error)
    }
}

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

// MARK: - Error Context Enhancement

/// Enhanced error wrapper that preserves original error with metadata
private struct ErrorMetadataWrapper {
    static var metadataStorage: [ObjectIdentifier: [String: String]] = [:]
    
    static func storeMetadata(for error: AxiomError, metadata: [String: String]) {
        let id = ObjectIdentifier(error as AnyObject)
        metadataStorage[id] = metadata
    }
    
    static func getMetadata(for error: AxiomError) -> [String: String] {
        let id = ObjectIdentifier(error as AnyObject)
        return metadataStorage[id] ?? [:]
    }
}

public extension AxiomError {
    /// Access metadata for this error instance
    var metadata: [String: String] {
        return ErrorMetadataWrapper.getMetadata(for: self)
    }
    
    /// Add context information to an error
    func addingContext(_ key: String, _ value: String) -> AxiomError {
        var currentMetadata = ErrorMetadataWrapper.getMetadata(for: self)
        currentMetadata[key] = value
        
        // Create enhanced error with enriched message
        let enhancedError = self.withEnhancedMessage(key: key, value: value)
        ErrorMetadataWrapper.storeMetadata(for: enhancedError, metadata: currentMetadata)
        
        return enhancedError
    }
    
    /// Wrap error with operation context
    func wrapping(_ operation: String) -> AxiomError {
        return addingContext("wrapped_operation", operation)
    }
    
    /// Create a chain of error contexts
    func chainedWith(_ previousError: AxiomError?) -> AxiomError {
        guard let previous = previousError else { return self }
        return self.addingContext("previous_error", previous.localizedDescription)
                  .addingContext("previous_type", String(describing: type(of: previous)))
    }
    
    /// Internal method to create enhanced error with context in message
    private func withEnhancedMessage(key: String, value: String) -> AxiomError {
        let contextInfo = "[\(key): \(value)]"
        
        switch self {
        case .contextError(let contextError):
            switch contextError {
            case .lifecycleError(let message):
                return .contextError(.lifecycleError("\(message) \(contextInfo)"))
            case .initializationFailed(let message):
                return .contextError(.initializationFailed("\(message) \(contextInfo)"))
            case .childContextError(let message):
                return .contextError(.childContextError("\(message) \(contextInfo)"))
            }
        case .validationError(let validationError):
            switch validationError {
            case .invalidInput(let field, let reason):
                return .validationError(.invalidInput(field, "\(reason) \(contextInfo)"))
            case .missingRequired(let field):
                return .validationError(.missingRequired("\(field) \(contextInfo)"))
            case .formatError(let field, let format):
                return .validationError(.formatError(field, "\(format) \(contextInfo)"))
            case .rangeError(let field, let range):
                return .validationError(.rangeError(field, "\(range) \(contextInfo)"))
            case .ruleFailed(let field, let rule, let reason):
                return .validationError(.ruleFailed(field: field, rule: rule, reason: "\(reason) \(contextInfo)"))
            case .multipleFailures(let failures):
                return .validationError(.multipleFailures(failures + [contextInfo]))
            }
        default:
            // For other error types, enhance the description
            return self
        }
    }
}

// MARK: - Error Propagation Helpers

/// Async operation with automatic error context
public func withErrorContext<T>(
    _ operation: String,
    perform work: () async throws -> T
) async -> Result<T, AxiomError> {
    do {
        let result = try await work()
        return .success(result)
    } catch let error as AxiomError {
        return .failure(error.wrapping(operation))
    } catch {
        return .failure(AxiomError(legacy: error).wrapping(operation))
    }
}

/// Execute with automatic retry on failure
public func withRetry<T>(
    maxAttempts: Int = 3,
    delay: TimeInterval = 1.0,
    operation: String,
    perform work: () async throws -> T
) async -> Result<T, AxiomError> {
    for attempt in 1...maxAttempts {
        do {
            let result = try await work()
            return .success(result)
        } catch let error as AxiomError {
            if attempt == maxAttempts {
                return .failure(error.addingContext("attempts", "\(attempt)"))
            }
            // Exponential backoff
            let backoffDelay = delay * pow(2.0, Double(attempt - 1))
            try? await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
        } catch {
            if attempt == maxAttempts {
                return .failure(AxiomError(legacy: error)
                    .wrapping(operation)
                    .addingContext("attempts", "\(attempt)"))
            }
            let backoffDelay = delay * pow(2.0, Double(attempt - 1))
            try? await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
        }
    }
    
    // Should never reach here
    return .failure(.contextError(.lifecycleError("Retry logic error")))
}

// MARK: - Error Logging and Monitoring

/// Error severity levels for logging
public enum ErrorSeverity {
    case debug
    case info
    case warning
    case error
    case critical
}

/// Protocol for error logging
public protocol ErrorLogger {
    func log(_ error: AxiomError, severity: ErrorSeverity, context: [String: Any])
}

/// Default console error logger
public struct ConsoleErrorLogger: ErrorLogger {
    public init() {}
    
    public func log(_ error: AxiomError, severity: ErrorSeverity, context: [String: Any]) {
        print("[\(severity)] \(error.localizedDescription)")
        if !context.isEmpty {
            print("Context: \(context)")
        }
    }
}

// MARK: - Global Error Handler

/// Global error handler for the framework
@MainActor
public final class GlobalErrorHandler {
    public static let shared = GlobalErrorHandler()
    
    private var logger: ErrorLogger = ConsoleErrorLogger()
    private var errorHandlers: [(AxiomError) -> Bool] = []
    
    private init() {}
    
    /// Set custom error logger
    public func setLogger(_ logger: ErrorLogger) {
        self.logger = logger
    }
    
    /// Register error handler (returns true if handled)
    public func registerHandler(_ handler: @escaping (AxiomError) -> Bool) {
        errorHandlers.append(handler)
    }
    
    /// Handle an error with logging and registered handlers
    public func handle(_ error: AxiomError, severity: ErrorSeverity = .error, context: [String: Any] = [:]) {
        // Log the error
        logger.log(error, severity: severity, context: context)
        
        // Try registered handlers
        for handler in errorHandlers {
            if handler(error) {
                return // Error was handled
            }
        }
        
        // Default handling based on recovery strategy
        switch error.recoveryStrategy {
        case .silent:
            // Already logged, nothing more to do
            break
        case .userPrompt(let message):
            // In a real app, would show alert
            print("User Alert: \(message)")
        case .retry(let attempts):
            print("Retry suggested with \(attempts) attempts")
        case .propagate:
            // Error should be propagated up
            print("Error propagated: \(error)")
        case .fallback:
            print("Fallback recovery attempted")
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
        
        ErrorMetadataWrapper.storeMetadata(for: error, metadata: metadata)
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

// MARK: - Macro Support Types

/// Existing BackoffStrategy moved above - using enhanced version from recovery framework

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
            throw AxiomError.clientError(.timeout(duration: timeout))
        }
        
        guard let result = try await group.next() else {
            throw AxiomError.clientError(.timeout(duration: timeout))
        }
        
        group.cancelAll()
        return result
    }
}

// MARK: - Error Telemetry and Monitoring Infrastructure (REQUIREMENTS-W-06-004)

/// Comprehensive error context for telemetry logging
public struct ErrorContext {
    public let error: AxiomError
    public let source: String
    public let timestamp: Date
    public var metadata: [String: Any]
    
    public init(error: AxiomError, source: String = "unknown", metadata: [String: Any] = [:]) {
        self.error = error
        self.source = source
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var category: ErrorCategory {
        return ErrorCategory.categorize(error)
    }
}

/// Structured telemetry logging with comprehensive context capture
public class TelemetryLogger: ErrorLogger {
    private var loggedEvents: [TelemetryEvent] = []
    private let queue = DispatchQueue(label: "TelemetryLogger", attributes: .concurrent)
    
    public init() {}
    
    public func log(_ error: AxiomError, severity: ErrorSeverity, context: [String: Any]) {
        let event = TelemetryEvent(
            error: error,
            severity: severity,
            source: context["source"] as? String ?? "unknown",
            metadata: context,
            timestamp: Date()
        )
        
        queue.async(flags: .barrier) {
            self.loggedEvents.append(event)
        }
    }
    
    public func getLoggedEvents() -> [TelemetryEvent] {
        return queue.sync {
            return loggedEvents
        }
    }
    
    public func clearEvents() {
        queue.async(flags: .barrier) {
            self.loggedEvents.removeAll()
        }
    }
}

/// Telemetry event structure for logged errors
public struct TelemetryEvent {
    public let error: AxiomError
    public let severity: ErrorSeverity
    public let source: String
    public let metadata: [String: Any]
    public let timestamp: Date
    
    public init(error: AxiomError, severity: ErrorSeverity, source: String, metadata: [String: Any], timestamp: Date) {
        self.error = error
        self.severity = severity
        self.source = source
        self.metadata = metadata
        self.timestamp = timestamp
    }
}

/// Error metrics collection for comprehensive analytics (optimized for performance)
public class ErrorMetricsCollector {
    private var errorCounts: [String: Int] = [:]
    private var errorCategories: [ErrorCategory: Int] = [:]
    private var sourceCategories: [String: [ErrorCategory: Int]] = [:]
    private var errorHistory: [ErrorContext] = []
    private let queue = DispatchQueue(label: "ErrorMetricsCollector", attributes: .concurrent)
    
    // Performance optimization: limit history size
    private let maxHistorySize = 10000
    private let historyCleanupThreshold = 12000
    
    public init() {}
    
    public func recordError(_ context: ErrorContext) {
        queue.async(flags: .barrier) {
            // Update counts
            self.errorCounts[context.source, default: 0] += 1
            self.errorCategories[context.category, default: 0] += 1
            
            // Update source-specific category tracking (optimization)
            if self.sourceCategories[context.source] == nil {
                self.sourceCategories[context.source] = [:]
            }
            self.sourceCategories[context.source]![context.category, default: 0] += 1
            
            // Add to history with size management
            self.errorHistory.append(context)
            
            // Cleanup old history if needed (performance optimization)
            if self.errorHistory.count > self.historyCleanupThreshold {
                let keepCount = self.maxHistorySize
                let removeCount = self.errorHistory.count - keepCount
                self.errorHistory.removeFirst(removeCount)
            }
        }
    }
    
    public func getMetrics(for source: String) -> ErrorSourceMetrics {
        return queue.sync {
            let count = errorCounts[source] ?? 0
            
            // Use cached source-specific category data for better performance
            let categoryDistribution = sourceCategories[source] ?? [:]
            
            // Calculate error rate (optimized with limited time window)
            let oneHourAgo = Date().addingTimeInterval(-3600)
            let recentErrorCount = errorHistory.lazy
                .reversed() // Start from most recent
                .prefix(while: { $0.timestamp > oneHourAgo })
                .filter { $0.source == source }
                .count
            
            let errorRate = Double(recentErrorCount) / 60.0
            
            return ErrorSourceMetrics(
                errorCount: count,
                errorCategory: categoryDistribution,
                errorRate: errorRate
            )
        }
    }
    
    public func getAllMetrics() -> [String: ErrorSourceMetrics] {
        return queue.sync {
            var result: [String: ErrorSourceMetrics] = [:]
            
            // Optimized: iterate over sources with cached data
            for source in errorCounts.keys {
                let count = errorCounts[source] ?? 0
                let categoryDistribution = sourceCategories[source] ?? [:]
                
                // Batch calculate error rates
                let oneHourAgo = Date().addingTimeInterval(-3600)
                let recentErrorCount = errorHistory.lazy
                    .reversed()
                    .prefix(while: { $0.timestamp > oneHourAgo })
                    .filter { $0.source == source }
                    .count
                
                let errorRate = Double(recentErrorCount) / 60.0
                
                result[source] = ErrorSourceMetrics(
                    errorCount: count,
                    errorCategory: categoryDistribution,
                    errorRate: errorRate
                )
            }
            return result
        }
    }
    
    // Performance monitoring method
    public func getCollectorHealth() -> CollectorHealth {
        return queue.sync {
            return CollectorHealth(
                historySize: errorHistory.count,
                totalSources: errorCounts.count,
                memoryUsageEstimate: estimateMemoryUsage()
            )
        }
    }
    
    private func estimateMemoryUsage() -> Int {
        // Rough estimate: context + overhead per error
        return errorHistory.count * 200 // ~200 bytes per error context
    }
}

/// Health metrics for the error metrics collector
public struct CollectorHealth {
    public let historySize: Int
    public let totalSources: Int
    public let memoryUsageEstimate: Int
    
    public init(historySize: Int, totalSources: Int, memoryUsageEstimate: Int) {
        self.historySize = historySize
        self.totalSources = totalSources
        self.memoryUsageEstimate = memoryUsageEstimate
    }
}

/// Error metrics for a specific source
public struct ErrorSourceMetrics {
    public let errorCount: Int
    public let errorCategory: [ErrorCategory: Int]
    public let errorRate: Double
    
    public init(errorCount: Int, errorCategory: [ErrorCategory: Int], errorRate: Double) {
        self.errorCount = errorCount
        self.errorCategory = errorCategory
        self.errorRate = errorRate
    }
}

/// Error pattern analysis and spike detection (optimized with smart caching)
public class ErrorPatternAnalyzer {
    private var errorHistory: [ErrorContext] = []
    private var categoryCache: [ErrorCategory: [ErrorContext]] = [:]
    private var sourceCache: [String: [ErrorContext]] = [:]
    private var lastCacheUpdate: Date = Date.distantPast
    private let queue = DispatchQueue(label: "ErrorPatternAnalyzer", attributes: .concurrent)
    
    // Performance optimization: limit analysis window
    private let maxAnalysisHistorySize = 5000
    private let cacheInvalidationInterval: TimeInterval = 300 // 5 minutes
    
    public init() {}
    
    public func addError(_ context: ErrorContext) {
        queue.async(flags: .barrier) {
            self.errorHistory.append(context)
            
            // Maintain reasonable history size for performance
            if self.errorHistory.count > self.maxAnalysisHistorySize * 2 {
                let keepCount = self.maxAnalysisHistorySize
                let removeCount = self.errorHistory.count - keepCount
                self.errorHistory.removeFirst(removeCount)
                self.invalidateCache()
            }
            
            // Update caches incrementally for better performance
            self.updateCachesIncremental(with: context)
        }
    }
    
    public func analyzePatterns() -> [ErrorPattern] {
        return queue.sync {
            updateCachesIfNeeded()
            
            return categoryCache.compactMap { category, errors in
                guard errors.count > 0 else { return nil }
                
                // Use cached data for faster analysis
                let timeWindow = calculateTimeWindow(for: errors)
                let commonSources = findCommonSourcesOptimized(in: errors)
                
                return ErrorPattern(
                    category: category,
                    frequency: errors.count,
                    timeWindow: timeWindow,
                    commonSources: commonSources,
                    correlationScore: calculateCorrelationScore(for: errors)
                )
            }
        }
    }
    
    public func detectSpike(in timeWindow: TimeInterval, 
                           category: ErrorCategory? = nil,
                           source: String? = nil) -> SpikeDetectionResult {
        return queue.sync {
            let now = Date()
            let windowStart = now.addingTimeInterval(-timeWindow)
            
            // Optimized filtering using lazy evaluation
            var relevantErrors = errorHistory.lazy
                .reversed() // Start from most recent
                .prefix(while: { $0.timestamp >= windowStart })
            
            if let category = category {
                relevantErrors = relevantErrors.filter { $0.category == category }
            }
            
            if let source = source {
                relevantErrors = relevantErrors.filter { $0.source == source }
            }
            
            let recentCount = relevantErrors.count
            let recentRate = Double(recentCount) / (timeWindow / 60.0)
            
            // Enhanced historical analysis with better window handling
            let historicalStart = now.addingTimeInterval(-86400) // 24 hours
            let historicalErrors = errorHistory.lazy
                .filter { $0.timestamp >= historicalStart && $0.timestamp < windowStart }
                .filter { context in
                    if let category = category, context.category != category { return false }
                    if let source = source, context.source != source { return false }
                    return true
                }
            
            let historicalCount = historicalErrors.count
            let historicalRate = Double(historicalCount) / (86400.0 / 60.0)
            
            // Enhanced spike detection with adaptive thresholds
            let adaptiveThreshold = max(historicalRate * 3.0, 5.0)
            let isSpike = recentRate > adaptiveThreshold
            
            return SpikeDetectionResult(
                isSpike: isSpike,
                currentRate: recentRate,
                historicalRate: historicalRate,
                threshold: adaptiveThreshold,
                recentCount: recentCount,
                timeWindow: timeWindow
            )
        }
    }
    
    // Enhanced pattern correlation analysis
    public func findCorrelatedPatterns(category: ErrorCategory, 
                                     timeWindow: TimeInterval = 3600) -> [PatternCorrelation] {
        return queue.sync {
            let now = Date()
            let windowStart = now.addingTimeInterval(-timeWindow)
            
            let categoryErrors = errorHistory.filter { 
                $0.category == category && $0.timestamp >= windowStart 
            }
            
            guard !categoryErrors.isEmpty else { return [] }
            
            var correlations: [PatternCorrelation] = []
            
            // Analyze temporal correlations with other categories
            for otherCategory in ErrorCategory.allCases where otherCategory != category {
                let otherErrors = errorHistory.filter { 
                    $0.category == otherCategory && $0.timestamp >= windowStart 
                }
                
                let correlation = calculateTemporalCorrelation(
                    primary: categoryErrors,
                    secondary: otherErrors,
                    timeWindow: timeWindow
                )
                
                if correlation.strength > 0.3 { // Significant correlation threshold
                    correlations.append(PatternCorrelation(
                        primaryCategory: category,
                        correlatedCategory: otherCategory,
                        strength: correlation.strength,
                        timeOffset: correlation.offset
                    ))
                }
            }
            
            return correlations.sorted { $0.strength > $1.strength }
        }
    }
    
    // MARK: - Private Optimization Methods
    
    private func updateCachesIfNeeded() {
        let now = Date()
        if now.timeIntervalSince(lastCacheUpdate) > cacheInvalidationInterval {
            rebuildCaches()
            lastCacheUpdate = now
        }
    }
    
    private func updateCachesIncremental(with context: ErrorContext) {
        // Update category cache
        if categoryCache[context.category] == nil {
            categoryCache[context.category] = []
        }
        categoryCache[context.category]?.append(context)
        
        // Update source cache
        if sourceCache[context.source] == nil {
            sourceCache[context.source] = []
        }
        sourceCache[context.source]?.append(context)
    }
    
    private func rebuildCaches() {
        categoryCache = Dictionary(grouping: errorHistory) { $0.category }
        sourceCache = Dictionary(grouping: errorHistory) { $0.source }
    }
    
    private func invalidateCache() {
        categoryCache.removeAll()
        sourceCache.removeAll()
        lastCacheUpdate = Date.distantPast
    }
    
    private func calculateTimeWindow(for errors: [ErrorContext]) -> TimeInterval {
        guard errors.count > 1,
              let earliest = errors.map(\.timestamp).min(),
              let latest = errors.map(\.timestamp).max() else {
            return 0
        }
        return latest.timeIntervalSince(earliest)
    }
    
    private func findCommonSourcesOptimized(in errors: [ErrorContext]) -> [String] {
        let sourceCounts = errors.reduce(into: [String: Int]()) { result, context in
            result[context.source, default: 0] += 1
        }
        
        return sourceCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map(\.key)
    }
    
    private func calculateCorrelationScore(for errors: [ErrorContext]) -> Double {
        guard errors.count > 1 else { return 0 }
        
        // Calculate temporal clustering score
        let timestamps = errors.map { $0.timestamp.timeIntervalSince1970 }
        let sortedTimestamps = timestamps.sorted()
        
        // Measure clustering using inter-arrival times
        let intervals = zip(sortedTimestamps.dropFirst(), sortedTimestamps).map { $0 - $1 }
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - averageInterval, 2) }.reduce(0, +) / Double(intervals.count)
        
        // Higher variance indicates more random distribution (lower correlation)
        // Lower variance indicates clustering (higher correlation)
        return max(0, 1.0 - (variance / (averageInterval * averageInterval + 1)))
    }
    
    private func calculateTemporalCorrelation(primary: [ErrorContext], 
                                            secondary: [ErrorContext], 
                                            timeWindow: TimeInterval) -> (strength: Double, offset: TimeInterval) {
        guard !primary.isEmpty && !secondary.isEmpty else {
            return (strength: 0, offset: 0)
        }
        
        let primaryTimes = primary.map { $0.timestamp.timeIntervalSince1970 }
        let secondaryTimes = secondary.map { $0.timestamp.timeIntervalSince1970 }
        
        // Calculate cross-correlation at different time offsets
        var maxCorrelation: Double = 0
        var bestOffset: TimeInterval = 0
        
        let maxOffset = min(timeWindow / 4, 1800) // Max 30 minutes or 1/4 of window
        let step: TimeInterval = 60 // 1 minute steps
        
        for offset in stride(from: -maxOffset, through: maxOffset, by: step) {
            let correlation = calculateCrossCorrelation(
                primary: primaryTimes,
                secondary: secondaryTimes,
                offset: offset
            )
            
            if abs(correlation) > abs(maxCorrelation) {
                maxCorrelation = correlation
                bestOffset = offset
            }
        }
        
        return (strength: abs(maxCorrelation), offset: bestOffset)
    }
    
    private func calculateCrossCorrelation(primary: [Double], 
                                         secondary: [Double], 
                                         offset: TimeInterval) -> Double {
        // Simplified cross-correlation calculation
        let adjustedSecondary = secondary.map { $0 + offset }
        
        var matchCount = 0
        let tolerance: Double = 300 // 5 minutes tolerance
        
        for primaryTime in primary {
            if adjustedSecondary.contains(where: { abs($0 - primaryTime) <= tolerance }) {
                matchCount += 1
            }
        }
        
        return Double(matchCount) / Double(max(primary.count, secondary.count))
    }
}

/// Error pattern detected by analysis (enhanced with correlation metrics)
public struct ErrorPattern {
    public let category: ErrorCategory
    public let frequency: Int
    public let timeWindow: TimeInterval
    public let commonSources: [String]
    public let correlationScore: Double
    
    public init(category: ErrorCategory, frequency: Int, timeWindow: TimeInterval, commonSources: [String], correlationScore: Double = 0.0) {
        self.category = category
        self.frequency = frequency
        self.timeWindow = timeWindow
        self.commonSources = commonSources
        self.correlationScore = correlationScore
    }
}

/// Enhanced spike detection result with detailed metrics
public struct SpikeDetectionResult {
    public let isSpike: Bool
    public let currentRate: Double
    public let historicalRate: Double
    public let threshold: Double
    public let recentCount: Int
    public let timeWindow: TimeInterval
    
    public init(isSpike: Bool, currentRate: Double, historicalRate: Double, threshold: Double, recentCount: Int, timeWindow: TimeInterval) {
        self.isSpike = isSpike
        self.currentRate = currentRate
        self.historicalRate = historicalRate
        self.threshold = threshold
        self.recentCount = recentCount
        self.timeWindow = timeWindow
    }
}

/// Pattern correlation analysis between error categories
public struct PatternCorrelation {
    public let primaryCategory: ErrorCategory
    public let correlatedCategory: ErrorCategory
    public let strength: Double // 0.0 to 1.0
    public let timeOffset: TimeInterval // Offset in seconds
    
    public init(primaryCategory: ErrorCategory, correlatedCategory: ErrorCategory, strength: Double, timeOffset: TimeInterval) {
        self.primaryCategory = primaryCategory
        self.correlatedCategory = correlatedCategory
        self.strength = strength
        self.timeOffset = timeOffset
    }
}

/// Real-time error monitoring with threshold alerts
@MainActor
public class ErrorMonitor: ObservableObject {
    @Published public var recentErrors: [ErrorContext] = []
    @Published public var errorRate: Double = 0.0
    @Published public var criticalAlertTriggered: Bool = false
    
    public let criticalThreshold: Double = 10.0 // errors per minute
    private var isMonitoring = false
    private var monitoringTask: Task<Void, Never>?
    
    public init() {}
    
    public func startMonitoring() async {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // Register with global error handler
        GlobalErrorHandler.shared.registerHandler { [weak self] error in
            Task { @MainActor in
                await self?.recordError(error)
            }
            return false // Continue propagation
        }
        
        // Start monitoring task
        monitoringTask = Task { @MainActor in
            while self.isMonitoring {
                await self.updateErrorRate()
                await self.checkThresholds()
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            }
        }
    }
    
    public func stopMonitoring() {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    private func recordError(_ error: AxiomError) async {
        let context = ErrorContext(error: error, source: "GlobalErrorHandler")
        recentErrors.append(context)
        
        // Keep only last 100 errors
        if recentErrors.count > 100 {
            recentErrors.removeFirst(recentErrors.count - 100)
        }
    }
    
    private func updateErrorRate() async {
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        let recentCount = recentErrors.filter { $0.timestamp > oneMinuteAgo }.count
        errorRate = Double(recentCount)
    }
    
    private func checkThresholds() async {
        if errorRate > criticalThreshold {
            criticalAlertTriggered = true
            await sendCriticalAlert()
        }
    }
    
    private func sendCriticalAlert() async {
        // In a real implementation, would send actual alerts
        print("CRITICAL ALERT: Error rate (\(errorRate)) exceeded threshold (\(criticalThreshold))")
    }
}

/// Privacy-compliant error sanitization
public extension AxiomError {
    func sanitized() -> AxiomError {
        switch self {
        case .validationError(.invalidInput(let field, _)):
            // Remove potentially sensitive field values
            return .validationError(.invalidInput(field, "***"))
            
        case .navigationError(let navError):
            // Sanitize navigation errors that might contain sensitive URLs
            switch navError {
            case .invalidURL(let component, _):
                return .navigationError(.invalidURL(component: component, value: "***"))
            default:
                return self
            }
            
        case .persistenceError(.saveFailed(let message)):
            // Sanitize persistence error messages that might contain data
            return .persistenceError(.saveFailed("Save operation failed"))
            
        case .clientError(.invalidAction(let action)):
            // Sanitize client error actions that might contain sensitive info
            return .clientError(.invalidAction("***"))
            
        default:
            return self
        }
    }
}

/// URL sanitization extension
public extension URL {
    func sanitized() -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        
        // Remove sensitive query parameters
        let sensitiveParams = ["token", "secret", "key", "password", "auth", "session"]
        components.queryItems = components.queryItems?.compactMap { item in
            if sensitiveParams.contains(where: { item.name.lowercased().contains($0) }) {
                return URLQueryItem(name: item.name, value: "***")
            }
            return item
        }
        
        return components.url ?? self
    }
}

/// External service integration - Crash reporting logger
public class CrashReportingLogger: ErrorLogger {
    private let crashReporter: CrashReporter
    
    public init(crashReporter: CrashReporter) {
        self.crashReporter = crashReporter
    }
    
    public func log(_ error: AxiomError, severity: ErrorSeverity, context: [String: Any]) {
        guard severity >= .error else { return }
        
        let crashEvent = CrashEvent(
            error: error.sanitized(),
            severity: severity,
            metadata: context,
            timestamp: Date()
        )
        
        crashReporter.recordCrash(crashEvent)
    }
}

/// External service integration - APM logger
public class APMLogger: ErrorLogger {
    private let apmService: APMService
    
    public init(apmService: APMService) {
        self.apmService = apmService
    }
    
    public func log(_ error: AxiomError, severity: ErrorSeverity, context: [String: Any]) {
        let errorEvent = APMErrorEvent(
            error: error,
            severity: severity,
            context: context,
            timestamp: Date()
        )
        
        apmService.trackError(errorEvent)
    }
}

/// Crash reporter protocol
public protocol CrashReporter {
    func recordCrash(_ event: CrashEvent)
}

/// APM service protocol
public protocol APMService {
    func trackError(_ event: APMErrorEvent)
}

/// Crash event structure
public struct CrashEvent {
    public let error: AxiomError
    public let severity: ErrorSeverity
    public let metadata: [String: Any]
    public let timestamp: Date
    
    public init(error: AxiomError, severity: ErrorSeverity, metadata: [String: Any], timestamp: Date) {
        self.error = error
        self.severity = severity
        self.metadata = metadata
        self.timestamp = timestamp
    }
}

/// APM error event structure
public struct APMErrorEvent {
    public let error: AxiomError
    public let severity: ErrorSeverity
    public let context: [String: Any]
    public let timestamp: Date
    
    public init(error: AxiomError, severity: ErrorSeverity, context: [String: Any], timestamp: Date) {
        self.error = error
        self.severity = severity
        self.context = context
        self.timestamp = timestamp
    }
}

/// Mock crash reporter for testing
public class MockCrashReporter: CrashReporter {
    public var recordedErrors: [CrashEvent] = []
    
    public init() {}
    
    public func recordCrash(_ event: CrashEvent) {
        recordedErrors.append(event)
    }
}

/// Mock APM service for testing
public class MockAPMService: APMService {
    public var trackedErrors: [APMErrorEvent] = []
    
    public init() {}
    
    public func trackError(_ event: APMErrorEvent) {
        trackedErrors.append(event)
    }
}