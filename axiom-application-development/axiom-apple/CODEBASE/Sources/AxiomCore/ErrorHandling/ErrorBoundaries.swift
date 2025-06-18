import Foundation

// MARK: - LogLevel

/// Simple log level enumeration for error handling
public enum LogLevel: String, CaseIterable {
    case debug
    case info  
    case warning
    case error
    case critical
}

// MARK: - Error Boundary Severity Levels

/// Error severity levels for error boundary hierarchy
public enum ErrorBoundarySeverity: Int, Comparable, CaseIterable, Sendable {
    case debug = 0
    case info = 1  
    case warning = 2
    case error = 3
    case critical = 4
    
    public static func < (lhs: ErrorBoundarySeverity, rhs: ErrorBoundarySeverity) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public var description: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning" 
        case .error: return "Error"
        case .critical: return "Critical"
        }
    }
}

// MARK: - Error Boundary Actions

/// Actions that can be taken when an error boundary is violated
public enum ErrorBoundaryAction: Equatable, Sendable {
    case halt
    case retry
    case `continue`
    case escalate
    case fallback
}

// MARK: - Production User Interaction Service

/// Production-grade user interaction service for error boundaries
public protocol ProductionUserInteractionService: Sendable {
    func showErrorBoundary(for error: AxiomError) async -> ErrorBoundaryAction
    func presentFallbackUI(for boundary: any ErrorBoundary) async
    func dismissErrorUI(for boundary: any ErrorBoundary) async
}

/// Default implementation of user interaction service
public actor DefaultUserInteractionService: ProductionUserInteractionService {
    private var activeErrorPresentations: [String: Bool] = [:]
    
    public init() {}
    
    public func showErrorBoundary(for error: AxiomError) async -> ErrorBoundaryAction {
        // In production, would show actual UI and wait for user response
        // For now, return action based on error severity
        switch error {
        case .validationError:
            return .retry
        case .navigationError:
            return .retry
        case .contextError, .actorError:
            return .halt
        case .capabilityError:
            return .fallback
        case .persistenceError:
            return .retry
        case .clientError:
            return .continue
        case .deviceError, .infrastructureError:
            return .halt
        case .networkError:
            return .retry
        case .unknownError:
            return .halt
        }
    }
    
    public func presentFallbackUI(for boundary: any ErrorBoundary) async {
        let boundaryId = ObjectIdentifier(boundary).debugDescription
        activeErrorPresentations[boundaryId] = true
        // In production, would present actual fallback UI
    }
    
    public func dismissErrorUI(for boundary: any ErrorBoundary) async {
        let boundaryId = ObjectIdentifier(boundary).debugDescription
        activeErrorPresentations.removeValue(forKey: boundaryId)
        // In production, would dismiss error UI
    }
}

// MARK: - Error Boundary Protocol

/// Protocol for types that can handle errors from their associated components.
/// 
/// Error boundaries ensure that all errors thrown by Clients are properly
/// propagated to their associated Contexts within the same Task context.
@MainActor
public protocol ErrorBoundary: AnyObject, Sendable {
    /// Handles an error thrown by a component.
    /// 
    /// - Parameters:
    ///   - error: The error that was thrown
    ///   - source: The identifier of the component that threw the error
    func handleError(_ error: any Error, from source: String) async
    
    /// The unique identifier for this boundary
    var identifier: String { get }
    
    /// The severity level this boundary handles
    var severity: ErrorBoundarySeverity { get }
    
    /// Fallback action to execute when boundary is violated
    var fallbackAction: @Sendable @MainActor () async -> Void { get }
}

// MARK: - Error Propagation

/// Manages error propagation from Clients to Contexts.
/// 
/// This class ensures that all errors thrown from Client actor methods
/// are propagated to Context error handlers within the same Task.
@MainActor
public final class ErrorPropagator: @unchecked Sendable {
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
    public func propagateError(_ error: any Error, from clientId: String, metadata: [String: String] = [:]) async {
        guard let contextId = clientContextMap[clientId],
              let boundary = errorHandlers[contextId] else {
            // No error boundary registered - error goes unhandled
            handleUnhandledError(error, from: clientId)
            return
        }
        
        // Create error context
        _ = ErrorContext(operationId: clientId, metadata: metadata)
        
        // Propagate to the error boundary
        await boundary.handleError(error, from: clientId)
        
        // Track metrics
        recordErrorMetrics(error, source: clientId)
    }
    
    /// Handles errors that have no registered error boundary.
    private func handleUnhandledError(_ error: any Error, from source: String) {
        #if DEBUG
        print("⚠️ Unhandled error from '\(source)': \(error)")
        #endif
        
        // In production, these could be sent to a crash reporting service
        recordErrorMetrics(error, source: source)
    }
    
    /// Records error metrics for monitoring.
    private func recordErrorMetrics(_ error: any Error, source: String) {
        // This could integrate with analytics/monitoring services
        // For now, just track counts
        // Note: ErrorContext from ErrorTelemetry.swift would be used in a real implementation
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

// MARK: - Error Boundary Manager

/// Production-grade error boundary manager with hierarchical error handling
public actor ErrorBoundaryManager {
    private var errorBoundaries: [String: any ErrorBoundary] = [:]
    private let userInteractionService: any ProductionUserInteractionService
    private var boundaryHierarchy: [ErrorBoundarySeverity: [String]] = [:]
    private var violationHistory: [String: [ErrorBoundaryViolation]] = [:]
    
    public init(userInteractionService: any ProductionUserInteractionService = DefaultUserInteractionService()) {
        self.userInteractionService = userInteractionService
    }
    
    /// Creates a new error boundary with specified configuration
    public func createErrorBoundary(
        identifier: String,
        severity: ErrorBoundarySeverity,
        fallbackAction: @escaping @Sendable () async -> Void
    ) async -> any ErrorBoundary {
        let boundary = await ConcreteErrorBoundary(
            identifier: identifier,
            severity: severity,
            fallbackAction: fallbackAction,
            manager: self
        )
        
        errorBoundaries[identifier] = boundary
        
        // Add to hierarchy
        if boundaryHierarchy[severity] == nil {
            boundaryHierarchy[severity] = []
        }
        boundaryHierarchy[severity]?.append(identifier)
        
        return boundary
    }
    
    /// Handles a boundary violation with automatic containment and recovery
    public func handleBoundaryViolation(
        boundary: any ErrorBoundary,
        error: AxiomError
    ) async -> ErrorBoundaryAction {
        // Record violation for analytics
        let boundaryId = await boundary.identifier
        let boundarySeverity = await boundary.severity
        let violation = ErrorBoundaryViolation(
            boundaryId: boundaryId,
            error: error,
            severity: boundarySeverity,
            timestamp: Date()
        )
        
        if violationHistory[boundaryId] == nil {
            violationHistory[boundaryId] = []
        }
        violationHistory[boundaryId]?.append(violation)
        
        // Log boundary violation (telemetry integration available in Platform layer)
        print("Error boundary violation: \(error)")
        
        // Determine action based on error severity and boundary configuration
        let action = await determineErrorAction(for: error, boundary: boundary)
        
        // Execute the determined action
        await executeErrorAction(action, boundary: boundary, error: error)
        
        return action
    }
    
    /// Removes an error boundary from management
    public func removeBoundary(identifier: String) {
        errorBoundaries.removeValue(forKey: identifier)
        violationHistory.removeValue(forKey: identifier)
        
        // Remove from hierarchy
        for severity in ErrorBoundarySeverity.allCases {
            boundaryHierarchy[severity]?.removeAll { $0 == identifier }
        }
    }
    
    /// Gets violation history for a specific boundary
    public func getViolationHistory(for boundaryId: String) -> [ErrorBoundaryViolation] {
        return violationHistory[boundaryId] ?? []
    }
    
    /// Gets all boundaries at a specific severity level
    public func getBoundaries(at severity: ErrorBoundarySeverity) -> [String] {
        return boundaryHierarchy[severity] ?? []
    }
    
    // MARK: - Private Implementation
    
    private func determineErrorAction(for error: AxiomError, boundary: any ErrorBoundary) async -> ErrorBoundaryAction {
        // Check violation frequency for this boundary
        let boundaryId = await boundary.identifier
        let recentViolations = getRecentViolations(for: boundaryId)
        
        // If too many recent violations, escalate or halt
        if recentViolations.count > 5 {
            return await boundary.severity >= .error ? .halt : .escalate
        }
        
        // Get user interaction decision
        let userAction = await userInteractionService.showErrorBoundary(for: error)
        
        // Apply boundary-specific logic
        switch await boundary.severity {
        case .debug, .info:
            return .continue
        case .warning:
            return userAction == .halt ? .fallback : userAction
        case .error:
            return userAction == .continue ? .retry : userAction
        case .critical:
            return .halt
        }
    }
    
    private func executeErrorAction(
        _ action: ErrorBoundaryAction,
        boundary: any ErrorBoundary,
        error: AxiomError
    ) async {
        switch action {
        case .halt:
            await boundary.fallbackAction()
            await userInteractionService.presentFallbackUI(for: boundary)
            
        case .retry:
            // In production, would trigger retry of the failed operation
            break
            
        case .continue:
            // Allow normal execution to continue
            break
            
        case .escalate:
            await escalateToParentBoundary(boundary: boundary, error: error)
            
        case .fallback:
            await boundary.fallbackAction()
            await userInteractionService.presentFallbackUI(for: boundary)
        }
    }
    
    private func escalateToParentBoundary(boundary: any ErrorBoundary, error: AxiomError) async {
        // Find parent boundary (next higher severity level)
        let currentSeverity = await boundary.severity
        let higherSeverities = ErrorBoundarySeverity.allCases.filter { $0 > currentSeverity }
        
        for severity in higherSeverities.sorted() {
            if let parentBoundaries = boundaryHierarchy[severity],
               let parentId = parentBoundaries.first,
               let parentBoundary = errorBoundaries[parentId] {
                _ = await handleBoundaryViolation(boundary: parentBoundary, error: error)
                return
            }
        }
        
        // No parent found, halt this boundary
        await boundary.fallbackAction()
    }
    
    private func getRecentViolations(for boundaryId: String) -> [ErrorBoundaryViolation] {
        let tenMinutesAgo = Date().addingTimeInterval(-600)
        return violationHistory[boundaryId]?.filter { $0.timestamp > tenMinutesAgo } ?? []
    }
}

// MARK: - Error Boundary Violation

/// Record of an error boundary violation for analytics
public struct ErrorBoundaryViolation {
    public let boundaryId: String
    public let error: AxiomError
    public let severity: ErrorBoundarySeverity
    public let timestamp: Date
    
    public init(boundaryId: String, error: AxiomError, severity: ErrorBoundarySeverity, timestamp: Date) {
        self.boundaryId = boundaryId
        self.error = error
        self.severity = severity
        self.timestamp = timestamp
    }
}

// MARK: - Concrete Error Boundary

/// Concrete implementation of ErrorBoundary protocol
public class ConcreteErrorBoundary: ErrorBoundary {
    public let identifier: String
    public let severity: ErrorBoundarySeverity
    public let fallbackAction: @Sendable @MainActor () async -> Void
    private weak var manager: ErrorBoundaryManager?
    
    init(
        identifier: String,
        severity: ErrorBoundarySeverity,
        fallbackAction: @escaping @Sendable @MainActor () async -> Void,
        manager: ErrorBoundaryManager
    ) {
        self.identifier = identifier
        self.severity = severity
        self.fallbackAction = fallbackAction
        self.manager = manager
    }
    
    public func handleError(_ error: any Error, from source: String) async {
        guard let axiomError = error as? AxiomError else {
            // Convert non-AxiomError to AxiomError
            let convertedError = AxiomError.unknownError
            await handleAxiomError(convertedError, from: source)
            return
        }
        
        await handleAxiomError(axiomError, from: source)
    }
    
    private func handleAxiomError(_ error: AxiomError, from source: String) async {
        guard let manager = manager else {
            // No manager available, execute fallback
            await fallbackAction()
            return
        }
        
        _ = await manager.handleBoundaryViolation(boundary: self, error: error)
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
    public func withErrorPropagation<T: Sendable>(_ operation: @Sendable () async throws -> T) async rethrows -> T {
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
    internal let errorHandler: (any ErrorHandler)?
    
    /// The unique identifier for this boundary (ErrorBoundary protocol requirement)
    public var identifier: String { return id }
    
    /// The severity level this boundary handles
    public let severity: ErrorBoundarySeverity
    
    /// Fallback action to execute when boundary is violated
    public let fallbackAction: @Sendable @MainActor () async -> Void
    
    /// Parent error boundary for hierarchical propagation
    weak var parentErrorBoundary: ErrorBoundaryContext?
    
    /// Child error boundaries
    private var childBoundaries: Set<ErrorBoundaryContext> = []
    
    /// Attached clients
    private var attachedClients: Set<String> = []
    
    /// Error boundary composition handlers
    private var compositionHandlers: [any ErrorHandler] = []
    
    /// Initializes a new error boundary context.
    /// 
    /// - Parameters:
    ///   - id: The unique identifier for the context
    ///   - severity: The severity level this boundary handles
    ///   - fallbackAction: Fallback action when boundary is violated
    ///   - errorHandler: Optional error handler for processing errors
    ///   - parent: Optional parent context for hierarchical error propagation
    public init(id: String, severity: ErrorBoundarySeverity = .error, fallbackAction: @escaping @Sendable @MainActor () async -> Void = {}, errorHandler: (any ErrorHandler)? = nil, parent: ErrorBoundaryContext? = nil) {
        self.id = id
        self.severity = severity
        self.fallbackAction = fallbackAction
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
        // Note: Cannot call async method in deinit
        // Error propagator cleanup will happen when the context is deallocated
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
    public func addCompositionHandler(_ handler: any ErrorHandler) {
        compositionHandlers.append(handler)
    }
    
    /// Removes a composition handler from the chain
    /// 
    /// - Parameter handler: The error handler to remove
    public func removeCompositionHandler(_ handler: any ErrorHandler) {
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
    public func handleError(_ error: any Error, from source: String) async {
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
    open func handleClientError(_ error: any Error, from source: String) async -> Bool {
        // Default implementation applies basic recovery strategies
        if let recoverableHandler = errorHandler as? (any RecoverableErrorHandler) {
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
    
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    nonisolated public static func == (lhs: ErrorBoundaryContext, rhs: ErrorBoundaryContext) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// Provides default recovery strategies based on error category.
    /// 
    /// - Parameter error: The error to evaluate
    /// - Returns: A suggested recovery strategy
    open func defaultRecoveryStrategy(for error: any Error) -> RecoveryStrategy {
        let category = AxiomErrorCategory.categorize(error)
        
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
    func processError(_ error: any Error, from source: String)
}

// MARK: - Recovery Strategy

/// Defines recovery strategies for different error types.
public enum RecoveryStrategy: Equatable {
    case retry(maxAttempts: Int = 3, delay: TimeInterval = 1.0)
    case fail
    case log(level: LogLevel = .error)
    case ignore
    case custom(id: String, handler: (any Error) async -> Void)
    
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
    func recoveryStrategy(for error: any Error) -> RecoveryStrategy
    
    /// Applies a recovery strategy to an error.
    /// 
    /// - Parameters:
    ///   - strategy: The recovery strategy to apply
    ///   - error: The error being handled
    ///   - source: The source of the error
    func applyRecovery(_ strategy: RecoveryStrategy, for error: any Error, from source: String) async
}

/// Concrete implementation of RecoverableErrorHandler with a fixed recovery strategy
@MainActor
public class DefaultRecoverableErrorHandler: RecoverableErrorHandler {
    private let strategy: RecoveryStrategy
    
    public init(strategy: RecoveryStrategy) {
        self.strategy = strategy
    }
    
    public func processError(_ error: any Error, from source: String) {
        // Process error synchronously
        Task {
            await applyRecovery(strategy, for: error, from: source)
        }
    }
    
    public func handleError(_ error: any Error, from source: String) async {
        await applyRecovery(strategy, for: error, from: source)
    }
    
    public func recoveryStrategy(for error: any Error) -> RecoveryStrategy {
        return strategy
    }
    
    public func applyRecovery(_ strategy: RecoveryStrategy, for error: any Error, from source: String) async {
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
// Note: ErrorCategory is defined in ErrorFoundation.swift

// MARK: - Enhanced Error Context
// Note: ErrorContext is defined in ErrorTelemetry.swift


