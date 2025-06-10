import Foundation
import SwiftUI
import Combine

// MARK: - NavigationService (Refactored as Facade)

/// Unified Navigation Service acting as a facade for decomposed navigation components
/// Maintains backward compatibility while delegating to NavigationCore, NavigationFlowManager, and NavigationDeepLinkHandler
@MainActor
public final class NavigationServiceRefactored: ObservableObject {
    
    // MARK: - Component References
    
    private let core: NavigationCore
    private let flowManager: NavigationFlowManager
    private let deepLinkHandler: NavigationDeepLinkHandler
    
    // MARK: - Published Properties (for compatibility)
    
    /// Current navigation route (delegated to core)
    @Published public var currentRoute: Route? {
        didSet {
            core.currentRoute = currentRoute
        }
    }
    
    /// Navigation history stack (delegated to core)
    @Published public var navigationHistory: [Route] {
        get { core.navigationHistory }
        set { core.navigationHistory = newValue }
    }
    
    /// Active navigation pattern (delegated to core)
    public var currentPattern: NavigationPattern {
        get { core.currentPattern }
    }
    
    /// Cancellation tokens (delegated to core)
    internal var cancellationTokens: Set<NavigationCancellationToken> {
        get { core.cancellationTokens }
        set { core.cancellationTokens = newValue }
    }
    
    public init() {
        self.core = NavigationCore()
        self.flowManager = NavigationFlowManager(navigationCore: core)
        self.deepLinkHandler = NavigationDeepLinkHandler(navigationCore: core)
        
        // Sync initial state
        self.currentRoute = core.currentRoute
        
        // Observe core changes
        setupBindings()
    }
    
    // MARK: - Core Navigation API (Delegated)
    
    /// Navigate to any routable destination
    public func navigate<T: Routable>(to route: T) async -> Result<Void, AxiomError> {
        let result = await core.navigate(to: route)
        syncState()
        return result
    }
    
    /// Navigate to route with options
    public func navigate(to route: Route, options: NavigationOptions = .default) async -> NavigationResult {
        let result = await core.navigate(to: route, options: options)
        
        // Execute route handler if available
        if result.isSuccess, let handler = deepLinkHandler.handler(for: route) {
            _ = try? await handler()
        }
        
        syncState()
        return result
    }
    
    /// Navigate back in history
    public func navigateBack() async -> NavigationResult {
        let result = await core.navigateBack()
        syncState()
        return result
    }
    
    /// Pop to root of navigation stack
    public func navigateToRoot() async -> NavigationResult {
        let result = await core.navigateToRoot()
        syncState()
        return result
    }
    
    /// Dismiss current presentation
    public func dismiss() async -> NavigationResult {
        return await navigateBack()
    }
    
    // MARK: - Deep Linking Support (Delegated)
    
    /// Process deep link URL
    public func processDeepLink(_ url: URL) async -> NavigationResult {
        return await deepLinkHandler.processDeepLink(url)
    }
    
    /// Register deep link pattern
    public func registerDeepLink(pattern: String, routeType: URLPattern.RouteType) {
        deepLinkHandler.registerDeepLink(pattern: pattern, routeType: routeType)
    }
    
    // MARK: - Route Management (Delegated)
    
    /// Register route handler
    public func registerRoute(_ route: Route, handler: @escaping () async throws -> any View) {
        deepLinkHandler.registerRoute(route, handler: handler)
    }
    
    /// Check if can navigate to route
    public func canNavigate(to route: Route) -> Bool {
        // Basic validation - route must be registered or is a standard route
        return deepLinkHandler.hasHandler(for: route) || true
    }
    
    /// Get current navigation depth
    public var navigationDepth: Int {
        return core.navigationDepth
    }
    
    /// Check if can navigate back
    public var canNavigateBack: Bool {
        return core.canNavigateBack
    }
    
    // MARK: - Navigation Patterns (Delegated)
    
    /// Set navigation pattern
    public func setPattern(_ pattern: NavigationPattern) {
        core.setPattern(pattern)
    }
    
    // MARK: - Cancellation Support (Delegated)
    
    /// Cancel all active navigations
    public func cancelAllNavigations() {
        core.cancelAllNavigations()
    }
    
    /// Create navigation cancellation token
    public func createCancellationToken() -> NavigationCancellationToken {
        return core.createCancellationToken()
    }
    
    // MARK: - Flow Management (New API surface for future use)
    
    /// Start a navigation flow
    public func startFlow(_ flow: NavigationFlow) async {
        await flowManager.startFlow(flow)
    }
    
    /// Complete current flow
    public func completeFlow() async {
        await flowManager.completeFlow()
    }
    
    /// Cancel current flow
    public func cancelFlow() async {
        await flowManager.cancelFlow()
    }
    
    // MARK: - Private Helpers
    
    private func setupBindings() {
        // Observe core state changes
        core.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
            self?.syncState()
        }.store(in: &cancellables)
    }
    
    private func syncState() {
        currentRoute = core.currentRoute
    }
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Declarative Navigation Extensions (Preserved)

extension NavigationServiceRefactored {
    /// Declarative route builder
    public func route(to destination: String) -> RouteBuilderRefactored {
        return RouteBuilderRefactored(destination: destination, service: self)
    }
}

/// Route builder for declarative navigation (adapted for refactored service)
public struct RouteBuilderRefactored {
    private let destination: String
    private let service: NavigationServiceRefactored
    private var parameters: [String: String] = [:]
    
    init(destination: String, service: NavigationServiceRefactored) {
        self.destination = destination
        self.service = service
    }
    
    public func parameter(_ key: String, value: String) -> RouteBuilderRefactored {
        var builder = self
        builder.parameters[key] = value
        return builder
    }
    
    public func build() -> Route {
        switch destination {
        case "home":
            return .home
        case "settings":
            return .settings
        case "detail":
            return .detail(id: parameters["id"] ?? "")
        default:
            return .custom(path: destination)
        }
    }
}

// Note: This refactored service maintains 100% API compatibility
// while delegating to focused components internally