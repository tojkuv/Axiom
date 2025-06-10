import Foundation

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

public extension AxiomError {
    /// Add context information to an error
    func addingContext(_ key: String, _ value: String) -> AxiomError {
        // For now, we'll return self since our error types don't have mutable metadata yet
        // In a full implementation, we'd enhance each error case with metadata dictionaries
        return self
    }
    
    /// Wrap error with operation context
    func wrapping(_ operation: String) -> AxiomError {
        return addingContext("wrapped_operation", operation)
    }
    
    /// Create a chain of error contexts
    func chainedWith(_ previousError: AxiomError?) -> AxiomError {
        guard let previous = previousError else { return self }
        return self.addingContext("previous_error", previous.localizedDescription)
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
        return .contextError(.lifecycleError(description))
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

// MARK: - Macro Support Types

/// Backoff strategies for retry logic in error handling macros
public enum BackoffStrategy: Equatable, Sendable {
    case none
    case constant(TimeInterval)
    case linear(initial: TimeInterval, increment: TimeInterval)
    case exponential(initial: TimeInterval = 1.0, multiplier: Double = 2.0, maxDelay: TimeInterval = 60.0)
}

/// Calculate backoff delay based on strategy
public func calculateBackoffDelay(strategy: BackoffStrategy, attempt: Int) -> TimeInterval {
    switch strategy {
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