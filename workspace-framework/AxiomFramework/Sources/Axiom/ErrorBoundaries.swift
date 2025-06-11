import Foundation

// MARK: - Error Boundary Protocol

/// Protocol for types that can handle errors from their associated components.
/// 
/// Error boundaries ensure that all errors thrown by Clients are properly
/// propagated to their associated Contexts within the same Task context.
@MainActor
public protocol ErrorBoundary: AnyObject {
    /// Handles an error thrown by a component.
    /// 
    /// - Parameters:
    ///   - error: The error that was thrown
    ///   - source: The identifier of the component that threw the error
    func handleError(_ error: Error, from source: String) async
}

// MARK: - Error Propagation

/// Manages error propagation from Clients to Contexts.
/// 
/// This class ensures that all errors thrown from Client actor methods
/// are propagated to Context error handlers within the same Task.
public final class ErrorPropagator {
    /// Shared instance for error propagation
    public static let shared = ErrorPropagator()
    
    // Track error handlers by context ID
    private var errorHandlers: [String: any ErrorBoundary] = [:]
    
    // Track client-to-context mappings
    private var clientContextMap: [String: String] = [:]
    
    private init() {}
    
    /// Registers an error boundary for a context.
    /// 
    /// - Parameters:
    ///   - boundary: The error boundary to register
    ///   - contextId: The unique identifier for the context
    public func registerErrorBoundary(_ boundary: any ErrorBoundary, for contextId: String) {
        errorHandlers[contextId] = boundary
    }
    
    /// Associates a client with a context for error propagation.
    /// 
    /// - Parameters:
    ///   - clientId: The unique identifier for the client
    ///   - contextId: The unique identifier for the context
    public func associateClient(_ clientId: String, with contextId: String) {
        clientContextMap[clientId] = contextId
    }
    
    /// Propagates an error from a client to its associated context.
    /// 
    /// - Parameters:
    ///   - error: The error to propagate
    ///   - clientId: The identifier of the client that threw the error
    ///   - metadata: Additional metadata about the error
    public func propagateError(_ error: Error, from clientId: String, metadata: [String: Any] = [:]) async {
        guard let contextId = clientContextMap[clientId],
              let boundary = errorHandlers[contextId] else {
            // No error boundary registered - error goes unhandled
            handleUnhandledError(error, from: clientId)
            return
        }
        
        // Create error context
        let context = ErrorContext(error: error, source: clientId, metadata: metadata)
        
        // Propagate to the error boundary
        await boundary.handleError(error, from: clientId)
        
        // Track metrics
        recordErrorMetrics(context)
    }
    
    /// Handles errors that have no registered error boundary.
    private func handleUnhandledError(_ error: Error, from source: String) {
        #if DEBUG
        print("⚠️ Unhandled error from '\(source)': \(error)")
        #endif
        
        // In production, these could be sent to a crash reporting service
        let context = ErrorContext(error: error, source: source, metadata: ["unhandled": true])
        recordErrorMetrics(context)
    }
    
    /// Records error metrics for monitoring.
    private func recordErrorMetrics(_ context: ErrorContext) {
        // This could integrate with analytics/monitoring services
        // For now, just track counts
    }
    
    /// Removes error boundary registration.
    /// 
    /// - Parameter contextId: The context identifier to unregister
    public func unregisterErrorBoundary(for contextId: String) {
        errorHandlers.removeValue(forKey: contextId)
        
        // Remove any client associations
        clientContextMap = clientContextMap.filter { $0.value != contextId }
    }
    
    /// Removes client association.
    /// 
    /// - Parameter clientId: The client identifier to disassociate
    public func disassociateClient(_ clientId: String) {
        clientContextMap.removeValue(forKey: clientId)
    }
}

// MARK: - Client Protocol Extension

/// Extension to support error propagation in clients.
public protocol ErrorPropagatingClient: Actor {
    /// The unique identifier for this client
    var id: String { get }
    
    /// Executes an operation with automatic error propagation.
    /// 
    /// - Parameter operation: The async throwing operation to execute
    /// - Returns: The result of the operation if successful
    func withErrorPropagation<T>(_ operation: () async throws -> T) async rethrows -> T
}

extension ErrorPropagatingClient {
    public func withErrorPropagation<T>(_ operation: () async throws -> T) async rethrows -> T {
        do {
            return try await operation()
        } catch {
            // Propagate error to context
            await ErrorPropagator.shared.propagateError(error, from: id)
            throw error
        }
    }
}

// MARK: - Context Base Class

/// Base class for contexts that provides error boundary functionality.
@MainActor
open class ErrorBoundaryContext: ErrorBoundary, Hashable {
    /// The unique identifier for this context
    public let id: String
    
    /// Error handler for processing errors
    internal let errorHandler: ErrorHandler?
    
    /// Parent error boundary for hierarchical propagation
    weak var parentErrorBoundary: ErrorBoundaryContext?
    
    /// Child error boundaries
    private var childBoundaries: Set<ErrorBoundaryContext> = []
    
    /// Attached clients
    private var attachedClients: Set<String> = []
    
    /// Error boundary composition handlers
    private var compositionHandlers: [ErrorHandler] = []
    
    /// Initializes a new error boundary context.
    /// 
    /// - Parameters:
    ///   - id: The unique identifier for the context
    ///   - errorHandler: Optional error handler for processing errors
    ///   - parent: Optional parent context for hierarchical error propagation
    public init(id: String, errorHandler: ErrorHandler? = nil, parent: ErrorBoundaryContext? = nil) {
        self.id = id
        self.errorHandler = errorHandler
        self.parentErrorBoundary = parent
        
        // Register with parent if provided
        if let parent = parent {
            parent.addChildBoundary(self)
        }
        
        // Register as error boundary
        ErrorPropagator.shared.registerErrorBoundary(self, for: id)
    }
    
    deinit {
        ErrorPropagator.shared.unregisterErrorBoundary(for: id)
        
        // Note: Cannot call async method in deinit
        // Parent cleanup will happen when parent is deallocated
        // or through explicit cleanup methods
    }
    
    /// Adds a child error boundary
    internal func addChildBoundary(_ child: ErrorBoundaryContext) {
        childBoundaries.insert(child)
    }
    
    /// Removes a child error boundary
    internal func removeChildBoundary(_ child: ErrorBoundaryContext) {
        childBoundaries.remove(child)
    }
    
    /// Explicit cleanup method for proper boundary hierarchy management
    public func cleanup() {
        if let parent = parentErrorBoundary {
            parent.removeChildBoundary(self)
        }
        childBoundaries.removeAll()
        compositionHandlers.removeAll()
    }
    
    /// Adds a composition handler to the error boundary chain
    /// 
    /// - Parameter handler: The error handler to add to the composition
    public func addCompositionHandler(_ handler: ErrorHandler) {
        compositionHandlers.append(handler)
    }
    
    /// Removes a composition handler from the chain
    /// 
    /// - Parameter handler: The error handler to remove
    public func removeCompositionHandler(_ handler: ErrorHandler) {
        compositionHandlers.removeAll { ObjectIdentifier($0) == ObjectIdentifier(handler) }
    }
    
    /// Attaches a client to this context for error handling.
    /// 
    /// - Parameter clientId: The identifier of the client to attach
    public func attachClient(id clientId: String) {
        attachedClients.insert(clientId)
        ErrorPropagator.shared.associateClient(clientId, with: id)
    }
    
    /// Detaches a client from this context.
    /// 
    /// - Parameter clientId: The identifier of the client to detach
    public func detachClient(id clientId: String) {
        attachedClients.remove(clientId)
        ErrorPropagator.shared.disassociateClient(clientId)
    }
    
    /// Handles an error from an attached client.
    /// 
    /// - Parameters:
    ///   - error: The error that was thrown
    ///   - source: The identifier of the client that threw the error
    public func handleError(_ error: Error, from source: String) async {
        // Process through composition handlers first
        for handler in compositionHandlers {
            handler.processError(error, from: source)
        }
        
        // Forward to primary error handler if available
        errorHandler?.processError(error, from: source)
        
        // Subclasses can override for custom handling
        let handled = await handleClientError(error, from: source)
        
        // If not handled and we have a parent, propagate up the hierarchy
        if !handled, let parent = parentErrorBoundary {
            await parent.handleError(error, from: source)
        }
    }
    
    /// Override point for custom error handling.
    /// 
    /// - Parameters:
    ///   - error: The error that was thrown
    ///   - source: The identifier of the client that threw the error
    /// - Returns: True if the error was handled, false if it should propagate
    open func handleClientError(_ error: Error, from source: String) async -> Bool {
        // Default implementation applies basic recovery strategies
        if let recoverableHandler = errorHandler as? RecoverableErrorHandler {
            let strategy = recoverableHandler.recoveryStrategy(for: error)
            await recoverableHandler.applyRecovery(strategy, for: error, from: source)
            
            // Check if the strategy indicates the error was handled
            switch strategy {
            case .ignore, .log:
                return true // These strategies handle the error
            case .retry, .fail:
                return false // These strategies indicate further handling needed
            case .custom:
                return true // Assume custom handlers handle the error
            }
        }
        
        // Default behavior - error is handled at this level
        return true
    }
    
    // MARK: - Hashable Conformance
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: ErrorBoundaryContext, rhs: ErrorBoundaryContext) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// Provides default recovery strategies based on error category.
    /// 
    /// - Parameter error: The error to evaluate
    /// - Returns: A suggested recovery strategy
    open func defaultRecoveryStrategy(for error: Error) -> RecoveryStrategy {
        let category = ErrorCategory.categorize(error)
        
        switch category {
        case .network:
            return .retry(maxAttempts: 3, delay: 2.0)
        case .validation:
            return .fail
        case .authorization:
            return .log(level: .error)
        case .dataIntegrity:
            return .log(level: .critical)
        case .system:
            return .fail
        case .unknown:
            return .log(level: .warning)
        }
    }
}

// MARK: - Error Handler Protocol

/// Protocol for types that process errors.
@MainActor
public protocol ErrorHandler: AnyObject {
    /// Processes an error from a source.
    /// 
    /// - Parameters:
    ///   - error: The error to process
    ///   - source: The identifier of the error source
    func processError(_ error: Error, from source: String)
}

// MARK: - Recovery Strategy

/// Defines recovery strategies for different error types.
public enum RecoveryStrategy: Equatable {
    case retry(maxAttempts: Int = 3, delay: TimeInterval = 1.0)
    case fail
    case log(level: LogLevel = .error)
    case ignore
    case custom(id: String, handler: (Error) async -> Void)
    
    public static func == (lhs: RecoveryStrategy, rhs: RecoveryStrategy) -> Bool {
        switch (lhs, rhs) {
        case (.retry(let l1, let l2), .retry(let r1, let r2)):
            return l1 == r1 && l2 == r2
        case (.fail, .fail), (.ignore, .ignore):
            return true
        case (.log(let l), .log(let r)):
            return l == r
        case (.custom(let l, _), .custom(let r, _)):
            return l == r
        default:
            return false
        }
    }
}


/// Protocol for error handlers that support recovery strategies.
@MainActor
public protocol RecoverableErrorHandler: ErrorHandler {
    /// Determines the recovery strategy for an error.
    /// 
    /// - Parameter error: The error to evaluate
    /// - Returns: The recovery strategy to apply
    func recoveryStrategy(for error: Error) -> RecoveryStrategy
    
    /// Applies a recovery strategy to an error.
    /// 
    /// - Parameters:
    ///   - strategy: The recovery strategy to apply
    ///   - error: The error being handled
    ///   - source: The source of the error
    func applyRecovery(_ strategy: RecoveryStrategy, for error: Error, from source: String) async
}

/// Concrete implementation of RecoverableErrorHandler with a fixed recovery strategy
@MainActor
public class DefaultRecoverableErrorHandler: RecoverableErrorHandler {
    private let strategy: RecoveryStrategy
    
    public init(strategy: RecoveryStrategy) {
        self.strategy = strategy
    }
    
    public func handleError(_ error: Error, from source: String) async {
        await applyRecovery(strategy, for: error, from: source)
    }
    
    public func recoveryStrategy(for error: Error) -> RecoveryStrategy {
        return strategy
    }
    
    public func applyRecovery(_ strategy: RecoveryStrategy, for error: Error, from source: String) async {
        switch strategy {
        case .retry(let maxAttempts, let delay):
            // Retry logic would be implemented here
            // For now, just log the retry attempt
            print("Retrying \(source) after error: \(error) (max attempts: \(maxAttempts), delay: \(delay))")
        case .fail:
            // Re-throw or propagate the error
            print("Failing fast for error in \(source): \(error)")
        case .log(let level):
            // Log the error
            print("[\(level)] Error in \(source): \(error)")
        case .ignore:
            // Silently ignore the error
            break
        case .custom(let id, let handler):
            // Execute custom handler
            print("Executing custom recovery strategy '\(id)' for error in \(source)")
            await handler(error)
        }
    }
}

// MARK: - Error Categorization

/// Categories of errors for better handling and reporting
public enum ErrorCategory {
    case network
    case validation
    case authorization
    case dataIntegrity
    case system
    case unknown
    
    /// Categorizes an error based on its type and properties
    public static func categorize(_ error: Error) -> ErrorCategory {
        switch error {
        case is URLError:
            return .network
        case let nsError as NSError:
            switch nsError.domain {
            case NSCocoaErrorDomain:
                return .system
            case NSURLErrorDomain:
                return .network
            default:
                return .unknown
            }
        default:
            return .unknown
        }
    }
}

// MARK: - Enhanced Error Context

/// Provides enhanced context for error handling
public struct ErrorContext {
    public let error: Error
    public let source: String
    public let category: ErrorCategory
    public let timestamp: Date
    public let taskId: UInt8?
    public let metadata: [String: Any]
    
    public init(error: Error, source: String, metadata: [String: Any] = [:]) {
        self.error = error
        self.source = source
        self.category = ErrorCategory.categorize(error)
        self.timestamp = Date()
        self.taskId = Task.currentPriority.rawValue
        self.metadata = metadata
    }
}


