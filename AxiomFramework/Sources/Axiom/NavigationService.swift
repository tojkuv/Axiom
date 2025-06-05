import Foundation

// MARK: - Navigation Service Protocol

/// Navigation service protocol that extends Orchestrator capabilities
/// 
/// This protocol defines navigation as an Orchestrator service, not a separate component type.
/// All navigation must be implemented through Orchestrator services to maintain architecture constraints.
public protocol NavigationService: Orchestrator {
    /// Current navigation route
    var currentRoute: Route? { get async }
    
    /// Navigation history stack
    var navigationHistory: [Route] { get async }
    
    /// Register a route handler for navigation
    func registerRoute(_ route: Route, handler: @escaping (Route) async -> any Context) async
    
    /// Navigate back in history
    func navigateBack() async
    
    /// Clear navigation history
    func clearHistory() async
    
    /// Check if navigation is possible to a route
    func canNavigate(to route: Route) async -> Bool
}

// MARK: - Navigation Orchestrator Implementation

/// Valid NavigationOrchestrator that implements navigation as an Orchestrator service
public actor ValidNavigationOrchestrator: NavigationService, ExtendedOrchestrator {
    
    // MARK: - Navigation State
    
    /// Current navigation route
    public private(set) var currentRoute: Route?
    
    /// Navigation history stack
    public private(set) var navigationHistory: [Route] = []
    
    /// Route handlers for navigation
    private var routeHandlers: [Route: (Route) async -> any Context] = [:]
    
    // MARK: - Orchestrator State
    
    /// Registered contexts
    private var contexts: [String: any Context] = [:]
    
    /// Registered clients for dependency injection
    private var clients: [String: any Client] = [:]
    
    /// Registered capabilities
    private var capabilities: [String: any Capability] = [:]
    
    /// Error handlers for context creation
    private var errorHandlers: [(Error) async -> Void] = []
    
    public init() {
        // Initialize navigation orchestrator
    }
    
    // MARK: - Navigation Service Implementation
    
    /// Register a route handler for navigation
    public func registerRoute(_ route: Route, handler: @escaping (Route) async -> any Context) async {
        routeHandlers[route] = handler
    }
    
    /// Navigate to a route
    public func navigate(to route: Route) async {
        guard await canNavigate(to: route) else {
            // TODO: Handle navigation error
            return
        }
        
        // Add to history if not the same as current route
        if let current = currentRoute, current != route {
            navigationHistory.append(current)
        }
        
        // Update current route
        currentRoute = route
        
        // Execute route handler if available
        if let handler = routeHandlers[route] {
            let context = await handler(route)
            let contextId = UUID().uuidString
            contexts[contextId] = context
        }
    }
    
    /// Navigate back in history
    public func navigateBack() async {
        guard !navigationHistory.isEmpty else { return }
        
        let previousRoute = navigationHistory.removeLast()
        currentRoute = previousRoute
        
        // Execute route handler for back navigation
        if let handler = routeHandlers[previousRoute] {
            let context = await handler(previousRoute)
            let contextId = UUID().uuidString
            contexts[contextId] = context
        }
    }
    
    /// Clear navigation history
    public func clearHistory() async {
        navigationHistory.removeAll()
    }
    
    /// Check if navigation is possible to a route
    public func canNavigate(to route: Route) async -> Bool {
        // Basic validation - can be extended with more complex rules
        return routeHandlers[route] != nil
    }
    
    // MARK: - Orchestrator Implementation
    
    /// Create context for presentation
    public func createContext<P: Presentation>(for presentation: P.Type) async -> P.ContextType {
        // This is a simplified implementation
        // In production, would use proper context factory with dependency injection
        fatalError("Context creation for presentations not implemented in ValidNavigationOrchestrator")
    }
    
    /// Create context with configuration
    public func createContext<T: Context>(
        type: T.Type,
        identifier: String? = nil,
        dependencies: [String] = []
    ) async -> T {
        let contextId = identifier ?? UUID().uuidString
        
        // Simplified context creation - in production would use proper factory
        // For now, this validates that navigation can be implemented as Orchestrator service
        fatalError("Context creation not fully implemented in ValidNavigationOrchestrator")
    }
    
    /// Register a client for dependency injection
    public func registerClient<C: Client>(_ client: C, for key: String) async {
        clients[key] = client
    }
    
    /// Register a capability for monitoring
    public func registerCapability<C: Capability>(_ capability: C, for key: String) async {
        capabilities[key] = capability
    }
    
    /// Check if a capability is available
    public func isCapabilityAvailable(_ key: String) async -> Bool {
        guard let capability = capabilities[key] else { return false }
        return await capability.isAvailable
    }
    
    /// Get a context builder for fluent configuration
    public func contextBuilder<T: Context>(for type: T.Type) async -> ContextBuilder<T> {
        return ContextBuilder<T>(orchestrator: self, contextType: type)
    }
    
    /// Get a client by key
    public func client<C: Client>(for key: String, as type: C.Type) async -> C? {
        return clients[key] as? C
    }
    
    /// Execute route handler for a given route (internal method for navigation coordination)
    internal func executeRouteHandler(for route: Route) async {
        if let handler = routeHandlers[route] {
            let context = await handler(route)
            let contextId = UUID().uuidString
            contexts[contextId] = context
        }
    }
    
    /// Replace current route without adding to history (internal method)
    internal func replaceRoute(with route: Route) async {
        currentRoute = route
        await executeRouteHandler(for: route)
    }
}

// MARK: - Navigation Service Factory

/// Factory for creating NavigationService instances
public struct NavigationServiceFactory {
    
    /// Create a new NavigationService (as Orchestrator service)
    public static func createNavigationService() async -> any NavigationService {
        return await ValidNavigationOrchestrator()
    }
    
    /// Validate that a service conforms to NavigationService protocol
    public static func validateNavigationService<T>(_ service: T) -> Bool {
        return service is (any NavigationService) && service is (any Orchestrator)
    }
}

// MARK: - Navigation Coordination Extension

/// Navigation coordination extension for any Orchestrator
/// 
/// This extension provides reusable navigation coordination logic that can be
/// mixed into any Orchestrator implementation, promoting separation of concerns.
extension Orchestrator {
    
    /// Navigate to home route with error handling
    public func navigateToHome() async {
        await navigate(to: .home)
    }
    
    /// Navigate to settings with error handling
    public func navigateToSettings() async {
        await navigate(to: .settings)
    }
    
    /// Navigate to detail with ID validation
    public func navigateToDetail(id: String) async {
        guard !id.isEmpty else {
            // TODO: Handle invalid ID error
            return
        }
        await navigate(to: .detail(id: id))
    }
    
    /// Navigate to custom path with validation
    public func navigateToCustomPath(_ path: String) async {
        guard !path.isEmpty else {
            // TODO: Handle invalid path error
            return
        }
        await navigate(to: .custom(path: path))
    }
}

// MARK: - Navigation Service Extensions

extension NavigationService {
    
    /// Get navigation depth (history count)
    public func navigationDepth() async -> Int {
        let history = await navigationHistory
        return history.count
    }
    
    /// Check if can navigate back
    public func canNavigateBack() async -> Bool {
        let depth = await navigationDepth()
        return depth > 0
    }
    
    /// Navigate with validation
    public func navigateWithValidation(to route: Route) async -> Bool {
        guard await canNavigate(to: route) else {
            return false
        }
        
        await navigate(to: route)
        return true
    }
    
    /// Get current route safely
    public func getCurrentRoute() async -> Route? {
        return await currentRoute
    }
    
    /// Replace current route (without adding to history)
    public func replaceCurrentRoute(with route: Route) async {
        guard await canNavigate(to: route) else { return }
        
        // Execute route handler if available
        if let orchestrator = self as? ValidNavigationOrchestrator {
            await orchestrator.replaceRoute(with: route)
        }
    }
}

// MARK: - Navigation Coordination Helper

/// Navigation coordination helper for complex navigation scenarios
public struct NavigationCoordinator {
    
    /// Validate a navigation path
    public static func validateNavigationPath(_ routes: [Route]) -> Bool {
        // Ensure no cycles in navigation path
        let routeSet = Set(routes)
        return routeSet.count == routes.count
    }
    
    /// Build navigation breadcrumbs
    public static func buildBreadcrumbs(for history: [Route], current: Route?) -> [Route] {
        var breadcrumbs = history
        if let current = current {
            breadcrumbs.append(current)
        }
        return breadcrumbs
    }
    
    /// Calculate navigation distance between routes
    public static func navigationDistance(from: Route, to: Route) -> Int {
        // Simple implementation - can be enhanced with more complex logic
        return from == to ? 0 : 1
    }
}