import Foundation

// MARK: - Navigation Flow Implementation

/// Navigation request flow enforcer that ensures proper Presentation → Context → Orchestrator flow
/// 
/// This implementation prevents direct Presentation-to-Orchestrator navigation and
/// ensures all navigation requests flow through Context mediation.
public struct NavigationFlow {
    
    /// Enforce that navigation flows through proper channels
    /// - Parameter request: The navigation request
    /// - Throws: NavigationFlowError if direct navigation is attempted
    public static func validateFlow(_ request: NavigationRequest) throws {
        switch request.source {
        case .presentation:
            // Presentations must navigate through Context
            guard request.target == .context else {
                throw NavigationFlowError.directNavigationNotAllowed
            }
        case .context:
            // Contexts can navigate to Orchestrator
            guard request.target == .orchestrator else {
                throw NavigationFlowError.invalidNavigationFlow
            }
        case .orchestrator:
            // Orchestrators handle final navigation
            break
        }
    }
}

/// Navigation request structure for flow validation
public struct NavigationRequest: Hashable, Equatable {
    public let source: NavigationSource
    public let target: NavigationTarget
    public let route: Route
    
    public init(source: NavigationSource, target: NavigationTarget, route: Route) {
        self.source = source
        self.target = target
        self.route = route
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(target)
        hasher.combine(route)
    }
    
    public static func == (lhs: NavigationRequest, rhs: NavigationRequest) -> Bool {
        lhs.source == rhs.source && lhs.target == rhs.target && lhs.route == rhs.route
    }
}

/// Navigation flow sources
public enum NavigationSource: Hashable, Equatable {
    case presentation
    case context
    case orchestrator
}

/// Navigation flow targets
public enum NavigationTarget: Hashable, Equatable {
    case context
    case orchestrator
}

/// Navigation flow errors
public enum NavigationFlowError: Error, Equatable, LocalizedError {
    case directNavigationNotAllowed
    case navigationFailed(String)
    case contextMediationRequired
    case invalidNavigationFlow
    
    public var errorDescription: String? {
        switch self {
        case .directNavigationNotAllowed:
            return "Direct navigation from Presentation to Orchestrator is not allowed"
        case .navigationFailed(let message):
            return "Navigation failed: \(message)"
        case .contextMediationRequired:
            return "Navigation must be mediated through Context"
        case .invalidNavigationFlow:
            return "Invalid navigation flow detected"
        }
    }
}

// MARK: - Navigation Flow Protocols

/// Protocol for components that can initiate navigation requests
public protocol NavigationInitiator {
    /// Request navigation through proper flow
    func requestNavigation(to route: Route) async throws
}

/// Protocol for components that mediate navigation
public protocol NavigationMediator {
    /// Mediate navigation request from initiator to orchestrator
    func mediate(request: NavigationRequest) async throws
}

/// Protocol for navigation error handling
public protocol NavigationErrorHandler {
    /// Handle navigation errors
    func handleNavigationError(_ error: Error) async
}

// MARK: - Presentation Flow Implementation

/// Presentation component that enforces proper navigation flow
@MainActor
public protocol PresentationNavigationFlow: NavigationInitiator, NavigationErrorHandler {
    /// Associated context for navigation mediation
    associatedtype ContextType: ContextNavigationFlow
    
    /// Context instance for navigation
    var context: ContextType { get }
}

/// Default implementation for presentation navigation flow
@MainActor
public extension PresentationNavigationFlow {
    
    /// Request navigation through context (proper flow)
    func requestNavigation(to route: Route) async throws {
        let request = NavigationRequest(
            source: .presentation,
            target: .context,
            route: route
        )
        
        // Validate the flow
        try NavigationFlow.validateFlow(request)
        
        // Forward to context for mediation with middleware support
        try await context.mediate(request: request)
    }
}

// MARK: - Context Flow Implementation

/// Context component that mediates navigation flow
@MainActor
public protocol ContextNavigationFlow: NavigationMediator, NavigationErrorHandler {
    /// Associated orchestrator for navigation execution
    associatedtype OrchestratorType: Orchestrator
    
    /// Orchestrator instance for navigation
    var orchestrator: OrchestratorType { get }
    
    /// Navigation flow coordinator for middleware processing
    var navigationCoordinator: NavigationFlowCoordinator { get }
}

/// Default implementation for context navigation flow
@MainActor
public extension ContextNavigationFlow {
    
    /// Mediate navigation request to orchestrator
    func mediate(request: NavigationRequest) async throws {
        // Process request through middleware chain
        guard let processedRequest = try await navigationCoordinator.processRequest(request) else {
            // Request was cancelled by middleware
            return
        }
        
        // Validate the mediation flow
        let orchestratorRequest = NavigationRequest(
            source: .context,
            target: .orchestrator,
            route: processedRequest.route
        )
        
        try NavigationFlow.validateFlow(orchestratorRequest)
        
        do {
            // Forward to orchestrator for execution
            await orchestrator.navigate(to: orchestratorRequest.route)
            
            // Notify middleware of successful completion
            await navigationCoordinator.notifyCompletion(orchestratorRequest)
        } catch {
            // Notify middleware of error
            await navigationCoordinator.notifyError(orchestratorRequest, error: error)
            
            // Handle and propagate errors
            await handleNavigationError(error)
            throw error
        }
    }
}

// MARK: - Navigation Middleware

/// Navigation middleware for cross-cutting concerns
@MainActor
public protocol NavigationMiddleware {
    /// Process navigation request before execution
    /// - Parameter request: The navigation request
    /// - Returns: Modified request or nil to cancel
    func process(request: NavigationRequest) async throws -> NavigationRequest?
    
    /// Handle navigation completion
    /// - Parameter request: The completed navigation request
    func onComplete(request: NavigationRequest) async
    
    /// Handle navigation error
    /// - Parameters:
    ///   - request: The failed navigation request
    ///   - error: The navigation error
    func onError(request: NavigationRequest, error: Error) async
}

/// Default middleware implementation
@MainActor
public extension NavigationMiddleware {
    func process(request: NavigationRequest) async throws -> NavigationRequest? {
        return request
    }
    
    func onComplete(request: NavigationRequest) async {}
    
    func onError(request: NavigationRequest, error: Error) async {}
}

/// Authentication middleware for navigation
@MainActor
public struct AuthenticationMiddleware: NavigationMiddleware {
    private let authenticatedRoutes: Set<Route>
    private let authenticationProvider: () async -> Bool
    
    public init(authenticatedRoutes: Set<Route>, authenticationProvider: @escaping () async -> Bool) {
        self.authenticatedRoutes = authenticatedRoutes
        self.authenticationProvider = authenticationProvider
    }
    
    public func process(request: NavigationRequest) async throws -> NavigationRequest? {
        guard authenticatedRoutes.contains(request.route) else {
            return request
        }
        
        let isAuthenticated = await authenticationProvider()
        guard isAuthenticated else {
            throw NavigationMiddlewareError.authenticationRequired
        }
        
        return request
    }
}

/// Logging middleware for navigation
@MainActor
public struct LoggingMiddleware: NavigationMiddleware {
    private let logger: (String) -> Void
    
    public init(logger: @escaping (String) -> Void = { print($0) }) {
        self.logger = logger
    }
    
    public func process(request: NavigationRequest) async throws -> NavigationRequest? {
        logger("Navigation requested: \(request.source) → \(request.target) for route \(request.route)")
        return request
    }
    
    public func onComplete(request: NavigationRequest) async {
        logger("Navigation completed: \(request.route)")
    }
    
    public func onError(request: NavigationRequest, error: Error) async {
        logger("Navigation failed: \(request.route) - \(error.localizedDescription)")
    }
}

/// Analytics middleware for navigation
@MainActor
public struct AnalyticsMiddleware: NavigationMiddleware {
    private let analyticsProvider: (String, [String: Any]) async -> Void
    
    public init(analyticsProvider: @escaping (String, [String: Any]) async -> Void) {
        self.analyticsProvider = analyticsProvider
    }
    
    public func process(request: NavigationRequest) async throws -> NavigationRequest? {
        await analyticsProvider("navigation_started", [
            "source": String(describing: request.source),
            "target": String(describing: request.target),
            "route": String(describing: request.route)
        ])
        return request
    }
    
    public func onComplete(request: NavigationRequest) async {
        await analyticsProvider("navigation_completed", [
            "route": String(describing: request.route)
        ])
    }
}

/// Performance monitoring middleware
@MainActor
public class PerformanceMiddleware: NavigationMiddleware {
    private var startTimes: [NavigationRequest: Date] = [:]
    private let performanceHandler: (NavigationRequest, TimeInterval) async -> Void
    
    public init(performanceHandler: @escaping (NavigationRequest, TimeInterval) async -> Void) {
        self.performanceHandler = performanceHandler
    }
    
    public func process(request: NavigationRequest) async throws -> NavigationRequest? {
        startTimes[request] = Date()
        return request
    }
    
    public func onComplete(request: NavigationRequest) async {
        guard let startTime = startTimes.removeValue(forKey: request) else { return }
        let duration = Date().timeIntervalSince(startTime)
        await performanceHandler(request, duration)
    }
    
    public func onError(request: NavigationRequest, error: Error) async {
        startTimes.removeValue(forKey: request)
    }
}

/// Rate limiting middleware for navigation
@MainActor
public class RateLimitingMiddleware: NavigationMiddleware {
    private var lastNavigationTime: Date?
    private let minimumInterval: TimeInterval
    
    public init(minimumInterval: TimeInterval = 0.5) {
        self.minimumInterval = minimumInterval
    }
    
    public func process(request: NavigationRequest) async throws -> NavigationRequest? {
        let now = Date()
        
        if let lastTime = lastNavigationTime {
            let timeSinceLastNavigation = now.timeIntervalSince(lastTime)
            if timeSinceLastNavigation < minimumInterval {
                throw NavigationMiddlewareError.rateLimitExceeded
            }
        }
        
        lastNavigationTime = now
        return request
    }
}

/// Route validation middleware
@MainActor
public struct RouteValidationMiddleware: NavigationMiddleware {
    private let validator: (Route) async throws -> Bool
    
    public init(validator: @escaping (Route) async throws -> Bool) {
        self.validator = validator
    }
    
    public func process(request: NavigationRequest) async throws -> NavigationRequest? {
        let isValid = try await validator(request.route)
        guard isValid else {
            throw NavigationMiddlewareError.middlewareRejected("Route validation failed")
        }
        return request
    }
}

/// Navigation middleware errors
public enum NavigationMiddlewareError: Error, LocalizedError {
    case authenticationRequired
    case authorizationFailed
    case rateLimitExceeded
    case middlewareRejected(String)
    
    public var errorDescription: String? {
        switch self {
        case .authenticationRequired:
            return "Authentication required for navigation"
        case .authorizationFailed:
            return "Not authorized to navigate to this route"
        case .rateLimitExceeded:
            return "Navigation rate limit exceeded"
        case .middlewareRejected(let reason):
            return "Navigation rejected by middleware: \(reason)"
        }
    }
}

// MARK: - Navigation Flow Coordinator

/// Enhanced coordinator for managing navigation flow and middleware
public actor NavigationFlowCoordinator {
    private var errorHandlers: [(Error) async -> Void] = []
    private var middleware: [NavigationMiddleware] = []
    
    /// Register an error handler
    public func registerErrorHandler(_ handler: @escaping (Error) async -> Void) {
        errorHandlers.append(handler)
    }
    
    /// Register navigation middleware
    public func registerMiddleware(_ middleware: NavigationMiddleware) {
        self.middleware.append(middleware)
    }
    
    /// Process navigation request through middleware chain
    public func processRequest(_ request: NavigationRequest) async throws -> NavigationRequest? {
        var currentRequest: NavigationRequest? = request
        
        for middleware in middleware {
            guard let req = currentRequest else { break }
            
            do {
                currentRequest = try await middleware.process(request: req)
            } catch {
                await middleware.onError(request: req, error: error)
                throw error
            }
        }
        
        return currentRequest
    }
    
    /// Notify middleware of navigation completion
    public func notifyCompletion(_ request: NavigationRequest) async {
        for middleware in middleware {
            await middleware.onComplete(request: request)
        }
    }
    
    /// Notify middleware of navigation error
    public func notifyError(_ request: NavigationRequest, error: Error) async {
        for middleware in middleware {
            await middleware.onError(request: request, error: error)
        }
    }
    
    /// Handle navigation error and notify all handlers
    public func handleError(_ error: Error) async {
        for handler in errorHandlers {
            await handler(error)
        }
    }
    
    /// Validate navigation request flow
    public func validateRequest(_ request: NavigationRequest) throws {
        try NavigationFlow.validateFlow(request)
    }
}

// MARK: - Middleware Chain Builder

/// Builder for creating navigation middleware chains
@MainActor
public struct NavigationMiddlewareChainBuilder {
    private var middleware: [NavigationMiddleware] = []
    
    public init() {}
    
    /// Add middleware to the chain
    public func add(_ middleware: NavigationMiddleware) -> NavigationMiddlewareChainBuilder {
        var builder = self
        builder.middleware.append(middleware)
        return builder
    }
    
    /// Add authentication middleware
    public func withAuthentication(
        authenticatedRoutes: Set<Route>,
        authenticationProvider: @escaping () async -> Bool
    ) -> NavigationMiddlewareChainBuilder {
        return add(AuthenticationMiddleware(
            authenticatedRoutes: authenticatedRoutes,
            authenticationProvider: authenticationProvider
        ))
    }
    
    /// Add logging middleware
    public func withLogging(logger: @escaping (String) -> Void = { print($0) }) -> NavigationMiddlewareChainBuilder {
        return add(LoggingMiddleware(logger: logger))
    }
    
    /// Add analytics middleware
    public func withAnalytics(
        analyticsProvider: @escaping (String, [String: Any]) async -> Void
    ) -> NavigationMiddlewareChainBuilder {
        return add(AnalyticsMiddleware(analyticsProvider: analyticsProvider))
    }
    
    /// Add performance monitoring middleware
    public func withPerformanceMonitoring(
        performanceHandler: @escaping (NavigationRequest, TimeInterval) async -> Void
    ) -> NavigationMiddlewareChainBuilder {
        return add(PerformanceMiddleware(performanceHandler: performanceHandler))
    }
    
    /// Add rate limiting middleware
    public func withRateLimit(minimumInterval: TimeInterval = 0.5) -> NavigationMiddlewareChainBuilder {
        return add(RateLimitingMiddleware(minimumInterval: minimumInterval))
    }
    
    /// Add route validation middleware
    public func withRouteValidation(
        validator: @escaping (Route) async throws -> Bool
    ) -> NavigationMiddlewareChainBuilder {
        return add(RouteValidationMiddleware(validator: validator))
    }
    
    /// Build the middleware chain and configure the coordinator
    public func build(coordinator: NavigationFlowCoordinator) async {
        for middleware in middleware {
            await coordinator.registerMiddleware(middleware)
        }
    }
    
    /// Get the middleware array
    public func getMiddleware() -> [NavigationMiddleware] {
        return middleware
    }
}

// MARK: - Flow Enforcement Extensions

/// Extension to add flow validation to existing types
public extension Orchestrator {
    
    /// Navigate with flow validation
    func navigateWithFlowValidation(to route: Route, from source: NavigationSource) async throws {
        let request = NavigationRequest(
            source: source,
            target: .orchestrator,
            route: route
        )
        
        // Only allow navigation from Context to Orchestrator
        guard source == .context else {
            throw NavigationFlowError.directNavigationNotAllowed
        }
        
        try NavigationFlow.validateFlow(request)
        await navigate(to: route)
    }
}

// MARK: - Flow Validation Utilities

/// Utilities for navigation flow validation
public struct NavigationFlowValidator {
    
    /// Check if a navigation flow is valid
    public static func isValidFlow(from source: NavigationSource, to target: NavigationTarget) -> Bool {
        switch (source, target) {
        case (.presentation, .context):
            return true
        case (.context, .orchestrator):
            return true
        default:
            return false
        }
    }
    
    /// Get allowed targets for a navigation source
    public static func allowedTargets(for source: NavigationSource) -> [NavigationTarget] {
        switch source {
        case .presentation:
            return [.context]
        case .context:
            return [.orchestrator]
        case .orchestrator:
            return []
        }
    }
    
    /// Validate a complete navigation chain
    public static func validateChain(_ requests: [NavigationRequest]) throws {
        for request in requests {
            try NavigationFlow.validateFlow(request)
        }
        
        // Ensure proper sequence: Presentation → Context → Orchestrator
        if requests.count >= 2 {
            guard requests[0].source == .presentation && requests[0].target == .context else {
                throw NavigationFlowError.invalidNavigationFlow
            }
            
            guard requests[1].source == .context && requests[1].target == .orchestrator else {
                throw NavigationFlowError.invalidNavigationFlow
            }
        }
    }
}

// MARK: - Error Recovery

/// Navigation error recovery strategies
public struct NavigationErrorRecovery {
    
    /// Recover from navigation flow error
    public static func recover(from error: NavigationFlowError) -> NavigationRecoveryAction {
        switch error {
        case .directNavigationNotAllowed:
            return .redirectThroughContext
        case .contextMediationRequired:
            return .requireContextMediation
        case .invalidNavigationFlow:
            return .resetToValidFlow
        case .navigationFailed:
            return .retry
        }
    }
}

/// Navigation recovery actions
public enum NavigationRecoveryAction {
    case redirectThroughContext
    case requireContextMediation
    case resetToValidFlow
    case retry
    case cancel
}

// MARK: - Flow Metrics

/// Navigation flow metrics for monitoring
public struct NavigationFlowMetrics {
    public let totalNavigations: Int
    public let validFlowNavigations: Int
    public let invalidFlowAttempts: Int
    public let errorRate: Double
    
    public init(total: Int, valid: Int, invalid: Int) {
        self.totalNavigations = total
        self.validFlowNavigations = valid
        self.invalidFlowAttempts = invalid
        self.errorRate = total > 0 ? Double(invalid) / Double(total) : 0.0
    }
}

/// Navigation flow monitor for tracking flow compliance
public actor NavigationFlowMonitor {
    private var totalNavigations = 0
    private var validNavigations = 0
    private var invalidAttempts = 0
    
    /// Record a navigation attempt
    public func recordNavigation(isValid: Bool) {
        totalNavigations += 1
        if isValid {
            validNavigations += 1
        } else {
            invalidAttempts += 1
        }
    }
    
    /// Get current metrics
    public func getMetrics() -> NavigationFlowMetrics {
        NavigationFlowMetrics(
            total: totalNavigations,
            valid: validNavigations,
            invalid: invalidAttempts
        )
    }
    
    /// Reset metrics
    public func reset() {
        totalNavigations = 0
        validNavigations = 0
        invalidAttempts = 0
    }
}