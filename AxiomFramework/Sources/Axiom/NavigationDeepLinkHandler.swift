import Foundation

// MARK: - NavigationDeepLinkHandler

/// Deep link handling functionality extracted from NavigationService
/// Focuses on URL parsing, pattern matching, and route resolution
@MainActor
public final class NavigationDeepLinkHandler {
    
    // MARK: - State
    
    /// Deep link URL patterns
    private var urlPatterns: [URLPattern] = []
    
    /// Route handlers for custom navigation
    private var routeHandlers: [Route: () async throws -> any View] = [:]
    
    /// Reference to core navigation for executing resolved routes
    private weak var navigationCore: NavigationCore?
    
    public init(navigationCore: NavigationCore? = nil) {
        self.navigationCore = navigationCore
        setupDefaultURLPatterns()
    }
    
    // MARK: - Deep Link Processing
    
    /// Process deep link URL
    public func processDeepLink(_ url: URL) async -> NavigationResult {
        return await withErrorContext("NavigationDeepLinkHandler.processDeepLink") {
            let route = try parseURL(url)
            
            // If we have a navigation core, navigate to the route
            if let core = navigationCore {
                return await core.navigate(to: route)
            } else {
                // Just validate we can parse it
                return .success
            }
        }.mapToNavigationResult()
    }
    
    /// Register deep link pattern
    public func registerDeepLink(pattern: String, routeType: URLPattern.RouteType) {
        let urlPattern = URLPattern(pattern: pattern, routeType: routeType)
        urlPatterns.append(urlPattern)
    }
    
    /// Check if URL can be handled
    public func canHandleDeepLink(_ url: URL) -> Bool {
        do {
            _ = try parseURL(url)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Route Handlers
    
    /// Register route handler
    public func registerRoute(_ route: Route, handler: @escaping () async throws -> any View) {
        routeHandlers[route] = handler
    }
    
    /// Get handler for route
    public func handler(for route: Route) -> (() async throws -> any View)? {
        return routeHandlers[route]
    }
    
    /// Check if route has handler
    public func hasHandler(for route: Route) -> Bool {
        return routeHandlers[route] != nil
    }
    
    // MARK: - URL Parsing
    
    private func parseURL(_ url: URL) throws -> Route {
        // Simple URL parsing implementation
        guard let scheme = url.scheme, scheme == "axiom" else {
            throw AxiomError.navigationError(.invalidRoute("Invalid URL scheme: \(url.scheme ?? "nil")"))
        }
        
        let path = url.path
        
        // Try registered patterns first
        for pattern in urlPatterns {
            if let route = try? pattern.match(url: url) {
                return route
            }
        }
        
        // Default route parsing
        switch path {
        case "/", "/home":
            return StandardRoute.home
        case "/settings":
            return StandardRoute.settings
        default:
            if path.hasPrefix("/detail/") {
                let id = String(path.dropFirst("/detail/".count))
                return StandardRoute.detail(id: id)
            }
            return StandardRoute.custom(path: path)
        }
    }
    
    private func setupDefaultURLPatterns() {
        // Setup default URL patterns
        registerDeepLink(pattern: "/home", routeType: .home)
        registerDeepLink(pattern: "/settings", routeType: .settings)
        registerDeepLink(pattern: "/detail", routeType: .detail)
        registerDeepLink(pattern: "/custom", routeType: .custom)
    }
    
    // MARK: - Pattern Management
    
    /// Get all registered patterns
    public var registeredPatterns: [String] {
        return urlPatterns.map { $0.pattern }
    }
    
    /// Clear all patterns
    public func clearPatterns() {
        urlPatterns.removeAll()
    }
    
    /// Clear all route handlers
    public func clearHandlers() {
        routeHandlers.removeAll()
    }
}