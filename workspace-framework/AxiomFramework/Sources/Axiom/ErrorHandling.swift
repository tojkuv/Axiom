import Foundation

// MARK: - Unified Error Types

/// Unified error hierarchy for the Axiom framework
public enum AxiomError: Error, Codable, Equatable {
    case contextError(AxiomContextError)
    case clientError(AxiomClientError)
    case navigationError(AxiomNavigationError)
    case persistenceError(PersistenceError)
    case validationError(AxiomValidationError)
    case capabilityError(CapabilityError)
    case actorError(ActorError)
    
    /// Human-readable error description
    public var localizedDescription: String {
        switch self {
        case .contextError(let error):
            return "Context Error: \(error.localizedDescription)"
        case .clientError(let error):
            return "Client Error: \(error.localizedDescription)"
        case .navigationError(let error):
            return "Navigation Error: \(error.localizedDescription)"
        case .persistenceError(let error):
            return "Persistence Error: \(error.localizedDescription)"
        case .validationError(let error):
            return "Validation Error: \(error.localizedDescription)"
        case .capabilityError(let error):
            return "Capability Error: \(error.localizedDescription)"
        case .actorError(let error):
            return "Actor Error: \(error.localizedDescription)"
        }
    }
    
    /// Recommended recovery strategy for this error
    public var recoveryStrategy: ErrorRecoveryStrategy {
        switch self {
        case .contextError:
            return .propagate
        case .clientError(let error):
            return error.recoveryStrategy
        case .navigationError:
            return .userPrompt(message: "Navigation failed. Please try again.")
        case .persistenceError:
            return .retry(attempts: 3)
        case .validationError:
            return .userPrompt(message: "Please correct the input")
        case .capabilityError:
            return .silent
        case .actorError:
            return .propagate
        }
    }
}

// MARK: - Specific Error Types

/// Context-related errors
public enum AxiomContextError: Error, Codable, Equatable {
    case lifecycleError(String)
    case initializationFailed(String)
    case childContextError(String)
    
    public var localizedDescription: String {
        switch self {
        case .lifecycleError(let message):
            return message
        case .initializationFailed(let message):
            return "Initialization failed: \(message)"
        case .childContextError(let message):
            return "Child context error: \(message)"
        }
    }
}

/// Client-related errors
public enum AxiomClientError: Error, Codable, Equatable {
    case invalidAction(String)
    case stateUpdateFailed(String)
    case timeout(duration: TimeInterval)
    case notInitialized
    
    public var localizedDescription: String {
        switch self {
        case .invalidAction(let action):
            return "Invalid action: \(action)"
        case .stateUpdateFailed(let reason):
            return "State update failed: \(reason)"
        case .timeout(let duration):
            return "Operation timed out after \(duration)s"
        case .notInitialized:
            return "Client not initialized"
        }
    }
    
    public var recoveryStrategy: ErrorRecoveryStrategy {
        switch self {
        case .timeout:
            return .retry(attempts: 2)
        default:
            return .propagate
        }
    }
}

/// Navigation-related errors
public enum AxiomNavigationError: Error, Codable, Equatable {
    // Route errors
    case invalidRoute(String)
    case routeNotFound(String)
    case invalidParameter(field: String?, reason: String)
    case missingRequiredParameter(String)
    case compilationFailure(String)
    
    // Deep linking
    case invalidURL(component: String, value: String)
    case patternNotFound(String)
    case parsingFailed(String)
    
    // Navigation flow
    case navigationBlocked(String)
    case guardFailed(String) 
    case directNavigationNotAllowed(String)
    case contextMediationRequired(String)
    
    // Auth errors
    case unauthorized(String)
    case authenticationRequired(String)
    
    // Navigation patterns
    case patternConflict(String)
    case invalidHierarchy(String)
    case circularNavigation(String)
    case stackError(String) // empty stack, no modal, etc
    case tabError(String) // tab not found, insufficient tabs
    case depthLimitExceeded(limit: Int)
    
    // Navigation graph
    case cycleDetected(path: String)
    case invalidTransition(from: String, to: String)
    case nodeNotFound(String)
    
    // Cancellation
    case navigationCancelled(String)
    
    // Middleware
    case middlewareRejected(reason: String)
    case rateLimitExceeded(String)
    
    public var localizedDescription: String {
        switch self {
        case .invalidRoute(let route):
            return "Invalid route: \(route)"
        case .routeNotFound(let route):
            return "Route not found: \(route)"
        case .invalidParameter(let field, let reason):
            return "Invalid parameter\(field.map { " '\($0)'" } ?? ""): \(reason)"
        case .missingRequiredParameter(let param):
            return "Missing required parameter: \(param)"
        case .compilationFailure(let details):
            return "Route compilation failed: \(details)"
        case .invalidURL(let component, let value):
            return "Invalid URL \(component): \(value)"
        case .patternNotFound(let pattern):
            return "Pattern not found: \(pattern)"
        case .parsingFailed(let details):
            return "URL parsing failed: \(details)"
        case .navigationBlocked(let reason):
            return "Navigation blocked: \(reason)"
        case .guardFailed(let reason):
            return "Navigation guard failed: \(reason)"
        case .directNavigationNotAllowed(let details):
            return "Direct navigation not allowed: \(details)"
        case .contextMediationRequired(let context):
            return "Context mediation required: \(context)"
        case .unauthorized(let resource):
            return "Unauthorized access to: \(resource)"
        case .authenticationRequired(let resource):
            return "Authentication required for: \(resource)"
        case .patternConflict(let details):
            return "Navigation pattern conflict: \(details)"
        case .invalidHierarchy(let details):
            return "Invalid navigation hierarchy: \(details)"
        case .circularNavigation(let path):
            return "Circular navigation detected: \(path)"
        case .stackError(let details):
            return "Navigation stack error: \(details)"
        case .tabError(let details):
            return "Tab navigation error: \(details)"
        case .depthLimitExceeded(let limit):
            return "Navigation depth limit exceeded: \(limit)"
        case .cycleDetected(let path):
            return "Navigation cycle detected: \(path)"
        case .invalidTransition(let from, let to):
            return "Invalid transition from \(from) to \(to)"
        case .nodeNotFound(let node):
            return "Navigation node not found: \(node)"
        case .navigationCancelled(let details):
            return "Navigation cancelled: \(details)"
        case .middlewareRejected(let reason):
            return "Navigation middleware rejected: \(reason)"
        case .rateLimitExceeded(let details):
            return "Navigation rate limit exceeded: \(details)"
        }
    }
}

/// Persistence-related errors
public enum PersistenceError: Error, Codable, Equatable {
    case saveFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    case migrationFailed(String)
    
    public var localizedDescription: String {
        switch self {
        case .saveFailed(let reason):
            return "Save failed: \(reason)"
        case .loadFailed(let reason):
            return "Load failed: \(reason)"
        case .deleteFailed(let reason):
            return "Delete failed: \(reason)"
        case .migrationFailed(let reason):
            return "Migration failed: \(reason)"
        }
    }
}

/// Validation-related errors
public enum AxiomValidationError: Error, Codable, Equatable {
    case invalidInput(String, String) // field, reason
    case missingRequired(String)
    case formatError(String, String) // field, expected format
    case rangeError(String, String) // field, valid range
    case ruleFailed(field: String, rule: String, reason: String)
    case multipleFailures([String]) // simplified from [Error] for Codable
    
    public var localizedDescription: String {
        switch self {
        case .invalidInput(let field, let reason):
            return "Invalid \(field): \(reason)"
        case .missingRequired(let field):
            return "Required field missing: \(field)"
        case .formatError(let field, let format):
            return "\(field) must be in format: \(format)"
        case .rangeError(let field, let range):
            return "\(field) must be within: \(range)"
        case .ruleFailed(let field, let rule, let reason):
            return "Validation rule '\(rule)' failed for \(field): \(reason)"
        case .multipleFailures(let failures):
            return "Multiple validation failures: \(failures.joined(separator: ", "))"
        }
    }
}

/// Actor-related errors for enhanced isolation patterns
public enum ActorError: Error, Codable, Equatable {
    case invariantViolation(String)
    case actorNotFound(ActorIdentifier)
    case reentrancyDenied(OperationIdentifier)
    case isolationViolation(String)
    case communicationTimeout(Duration)
    case priorityInversionDetected(ActorIdentifier)
    
    public var localizedDescription: String {
        switch self {
        case .invariantViolation(let reason):
            return "Actor invariant violation: \(reason)"
        case .actorNotFound(let id):
            return "Actor not found: \(id.name)"
        case .reentrancyDenied(let operation):
            return "Reentrancy denied for operation: \(operation.name)"
        case .isolationViolation(let reason):
            return "Actor isolation violation: \(reason)"
        case .communicationTimeout(let duration):
            return "Actor communication timeout after \(duration)"
        case .priorityInversionDetected(let actorId):
            return "Priority inversion detected for actor: \(actorId.name)"
        }
    }
}

/// Capability-related errors
public enum CapabilityError: Error, Codable, Equatable {
    case initializationFailed(String)
    case resourceAllocationFailed(String)
    case invalidStateTransition(String)
    case notAvailable(String)
    case restricted(String)
    case permissionRequired(String)
    
    public var localizedDescription: String {
        switch self {
        case .initializationFailed(let reason):
            return "Capability initialization failed: \(reason)"
        case .resourceAllocationFailed(let reason):
            return "Resource allocation failed: \(reason)"
        case .invalidStateTransition(let details):
            return "Invalid state transition: \(details)"
        case .notAvailable(let capability):
            return "Capability not available: \(capability)"
        case .restricted(let capability):
            return "Capability restricted: \(capability)"
        case .permissionRequired(let capability):
            return "Permission required for: \(capability)"
        }
    }
}

// MARK: - Error Recovery Strategies

/// Strategies for recovering from errors
public enum ErrorRecoveryStrategy: Equatable {
    case propagate                    // Pass error up the chain
    case retry(attempts: Int)         // Automatic retry with backoff
    case fallback(id: String)         // Execute fallback (id for equality)
    case userPrompt(message: String)  // Show user error dialog
    case silent                       // Log error but continue
    
    public static func fallback<T>(operation: @escaping () async throws -> T) -> ErrorRecoveryStrategy {
        let container = FallbackContainer(operation: operation)
        FallbackContainer.storage[container.id] = container
        return .fallback(id: container.id)
    }
}

// MARK: - Error Boundary Protocol

/// Protocol for types that manage error boundaries
@MainActor
public protocol ErrorBoundaryManaged: AnyObject {
    var errorBoundary: AxiomErrorBoundary { get }
    func handleBoundaryError(_ error: Error) async
    func configureErrorRecovery(_ strategy: ErrorRecoveryStrategy) async
}

/// Error boundary for automatic error handling
@MainActor
public class AxiomErrorBoundary {
    private var strategy: ErrorRecoveryStrategy = .propagate
    private weak var parent: ErrorBoundaryManaged?
    private var retryCount: [String: Int] = [:]
    
    public var onError: ((Error) async -> Void)?
    
    public init(strategy: ErrorRecoveryStrategy = .propagate) {
        self.strategy = strategy
    }
    
    /// Handle an error according to the configured strategy
    public func handle(_ error: Error) async {
        // Notify error handler
        await onError?(error)
        
        switch strategy {
        case .propagate:
            await parent?.handleBoundaryError(error)
            
        case .retry(let maxAttempts):
            let errorKey = String(describing: error)
            let currentAttempts = retryCount[errorKey, default: 0]
            
            if currentAttempts < maxAttempts {
                retryCount[errorKey] = currentAttempts + 1
                // In real implementation, would retry the operation
            } else {
                // Max retries exceeded, propagate
                await parent?.handleBoundaryError(error)
            }
            
        case .fallback:
            // Execute fallback operation
            // In real implementation, would execute stored operation
            break
            
        case .userPrompt(let message):
            // In real implementation, would show user dialog
            print("Error: \(message)")
            
        case .silent:
            // Log error but continue
            print("Silent error: \(error)")
        }
    }
    
    /// Execute an operation with automatic error recovery
    public func executeWithRecovery<T>(
        _ operation: () async throws -> T,
        maxRetries: Int? = nil
    ) async throws -> T {
        var lastError: Error?
        let attempts = maxRetries ?? extractRetryAttempts(from: strategy)
        
        for attempt in 0..<max(1, attempts) {
            do {
                // Add exponential backoff for retries
                if attempt > 0 {
                    let delay = pow(2.0, Double(attempt - 1))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                
                return try await operation()
            } catch {
                lastError = error
                
                // Check if we should continue retrying
                if !shouldRetry(error: error, attempt: attempt, maxAttempts: attempts) {
                    break
                }
            }
        }
        
        // If we get here, all retries failed - try fallback
        if case .fallback(let id) = strategy,
           let container = FallbackContainer.storage[id] {
            return try await container.execute() as! T
        }
        
        // No recovery possible - handle according to strategy
        await handle(lastError!)
        throw lastError!
    }
    
    private func shouldRetry(error: Error, attempt: Int, maxAttempts: Int) -> Bool {
        // Don't retry validation errors
        if case .validationError = error as? AxiomError {
            return false
        }
        
        return attempt < maxAttempts - 1
    }
    
    private func extractRetryAttempts(from strategy: ErrorRecoveryStrategy) -> Int {
        if case .retry(let attempts) = strategy {
            return attempts
        }
        return 1
    }
    
    /// Configure the recovery strategy
    public func configure(strategy: ErrorRecoveryStrategy) {
        self.strategy = strategy
    }
    
    /// Set parent boundary for error propagation
    public func setParent(_ parent: ErrorBoundaryManaged) {
        self.parent = parent
    }
}

// MARK: - Error Migration Support

/// Extension to support migration from legacy NSError types
extension AxiomError {
    /// Create AxiomError from legacy error types
    public init(legacy error: Error) {
        switch error {
        // Already AxiomError
        case let axiomError as AxiomError:
            self = axiomError
            
        // Legacy NSError types
        case let nsError as NSError:
            // Map common NSError domains to appropriate AxiomError types
            switch nsError.domain {
            case NSURLErrorDomain:
                self = .navigationError(.invalidURL(component: "network", value: nsError.localizedDescription))
            case NSCocoaErrorDomain:
                self = .persistenceError(.saveFailed(nsError.localizedDescription))
            default:
                self = .contextError(.lifecycleError("NSError: \(nsError.localizedDescription)"))
            }
            
        // Unknown
        default:
            self = .contextError(.lifecycleError("Unknown error: \(error)"))
        }
    }
    
    
    // Legacy error mapping functions removed - error types have been consolidated into AxiomError
    // ClientError and ValidationError enums no longer exist
}

// MARK: - Fallback Storage

/// Type-erased fallback container
private class FallbackContainer {
    static var storage: [String: FallbackContainer] = [:]
    
    let id: String
    private let operation: () async throws -> Any
    
    init<T>(operation: @escaping () async throws -> T) {
        self.id = UUID().uuidString
        self.operation = { try await operation() }
    }
    
    func execute() async throws -> Any {
        try await operation()
    }
}

// MARK: - Enhanced Observable Context

/// Extension to ObservableContext for error boundary support
extension ObservableContext: ErrorBoundaryManaged {
    private static var errorBoundaryKey: UInt8 = 0
    
    /// Error boundary for this context
    public var errorBoundary: AxiomErrorBoundary {
        if let boundary = objc_getAssociatedObject(self, &ObservableContext.errorBoundaryKey) as? AxiomErrorBoundary {
            return boundary
        }
        let boundary = AxiomErrorBoundary()
        objc_setAssociatedObject(self, &ObservableContext.errorBoundaryKey, boundary, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return boundary
    }
    
    /// Handle an error from the boundary
    public func handleBoundaryError(_ error: Error) async {
        // Default implementation - can be overridden
        if let parent = parentContext as? ErrorBoundaryManaged {
            await parent.handleBoundaryError(error)
        }
    }
    
    /// Configure error recovery strategy
    public func configureErrorRecovery(_ strategy: ErrorRecoveryStrategy) async {
        errorBoundary.configure(strategy: strategy)
    }
}