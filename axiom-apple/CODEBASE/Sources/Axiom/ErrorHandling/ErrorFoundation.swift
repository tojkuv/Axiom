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
    public static func categorize(_ error: any Error) -> ErrorCategory {
        switch error {
        case _ as URLError:
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
            case .deviceError:
                return .system
            case .infrastructureError:
                return .system
            case .networkError:
                return .network
            case .unknownError:
                return .unknown
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
public extension Result where Failure == any Error {
    /// Transform any error to AxiomError, preserving existing AxiomErrors
    func mapToAxiomError(_ transform: (any Error) -> AxiomError) -> Result<Success, AxiomError> {
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
    _ task: Task<T, any Error>,
    transform: @escaping (any Error) -> AxiomError
) async throws -> T {
    do {
        return try await task.value
    } catch let error as AxiomError {
        throw error
    } catch {
        throw transform(error)
    }
}

public extension Task where Failure == any Error {
    /// Maps task errors to AxiomError, preserving existing AxiomError instances
    func mapToAxiomError(_ transform: @escaping (any Error) -> AxiomError) async throws -> Success {
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
public func mapTaskError<T>(_ task: Task<T, any Error>, transform: @escaping (any Error) -> AxiomError) async throws -> T {
    do {
        return try await task.value
    } catch let error as AxiomError {
        throw error
    } catch {
        throw transform(error)
    }
}

// MARK: - Error Context Enhancement

/// Enhanced error wrapper that preserves original error with metadata
private struct ErrorMetadataWrapper {
    nonisolated(unsafe) static var metadataStorage: [ObjectIdentifier: [String: String]] = [:]
    
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
    perform work: @Sendable () async throws -> T
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
public enum ErrorSeverity: Int, Comparable, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4
    
    public static func < (lhs: ErrorSeverity, rhs: ErrorSeverity) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
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