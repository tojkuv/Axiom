import Foundation

// MARK: - Enhanced Type-Safe Route Protocol System

/// Enhanced protocol for type-safe routing that supports any route structure
public protocol TypeSafeRoute: Routable, Hashable, Sendable {
    /// The path components of this route (e.g., "/profile/123")
    var pathComponents: String { get }
    
    /// Query parameters for this route
    var queryParameters: [String: String] { get }
    
    /// Unique identifier for this route instance
    var routeIdentifier: String { get }
}

/// Default implementation of Routable for TypeSafeRoute
extension TypeSafeRoute {
    public var presentation: PresentationStyle {
        // Default presentation style - can be overridden
        return .push
    }
}

/// Route building utilities for type-safe routes
public struct TypeSafeRouteBuilder {
    
    /// Build a full URL string from path and query parameters
    public static func buildURL(path: String, queryParameters: [String: String] = [:]) -> String {
        var url = path
        
        if !queryParameters.isEmpty {
            let queryString = queryParameters
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
            url += "?" + queryString
        }
        
        return url
    }
    
    /// Extract parameters from a path pattern
    public static func extractParameters(from path: String, pattern: String) -> [String: String] {
        // Enhanced parameter extraction with better pattern matching
        var parameters: [String: String] = [:]
        
        let pathComponents = path.split(separator: "/")
        let patternComponents = pattern.split(separator: "/")
        
        guard pathComponents.count == patternComponents.count else {
            return parameters
        }
        
        for (index, patternComponent) in patternComponents.enumerated() {
            if patternComponent.hasPrefix(":") {
                let parameterName = String(patternComponent.dropFirst().replacingOccurrences(of: "?", with: ""))
                let parameterValue = String(pathComponents[index])
                parameters[parameterName] = parameterValue
            }
        }
        
        return parameters
    }
}

/// Enhanced route builder for declarative route construction with type safety
public class EnhancedRouteBuilder<Route: TypeSafeRoute> {
    private var baseRoute: Route?
    private var additionalQueryParameters: [String: String] = [:]
    
    public init() {}
    
    /// Start building with a base route
    public func route(_ route: Route) -> EnhancedRouteBuilder<Route> {
        self.baseRoute = route
        return self
    }
    
    /// Add a query parameter
    public func withQueryParameter(_ key: String, value: String) -> EnhancedRouteBuilder<Route> {
        additionalQueryParameters[key] = value
        return self
    }
    
    /// Add multiple query parameters
    public func withQueryParameters(_ parameters: [String: String]) -> EnhancedRouteBuilder<Route> {
        for (key, value) in parameters {
            additionalQueryParameters[key] = value
        }
        return self
    }
    
    /// Build the final route URL
    public func buildURL() -> String {
        guard let route = baseRoute else {
            fatalError("No base route set for builder")
        }
        
        let mergedParameters = route.queryParameters.merging(additionalQueryParameters) { _, new in new }
        return TypeSafeRouteBuilder.buildURL(path: route.pathComponents, queryParameters: mergedParameters)
    }
    
    /// Get the base route (if available)
    public func getRoute() -> Route? {
        return baseRoute
    }
}

/// Use EnhancedRouteBuilder as the main implementation
// Note: TypeSafeRouteBuilder struct above provides static utility methods

/// Simple route matching for URL patterns
public struct RoutePattern {
    public let pattern: String
    public let parameterNames: [String]
    
    public init(pattern: String) {
        self.pattern = pattern
        
        // Extract parameter names from pattern (e.g., "/profile/:userId" -> ["userId"])
        self.parameterNames = pattern
            .split(separator: "/")
            .compactMap { component in
                component.hasPrefix(":") ? String(component.dropFirst()) : nil
            }
    }
    
    /// Check if a path matches this pattern
    public func matches(path: String) -> Bool {
        let pathComponents = path.split(separator: "/")
        let patternComponents = pattern.split(separator: "/")
        
        guard pathComponents.count == patternComponents.count else {
            return false
        }
        
        for (pathComponent, patternComponent) in zip(pathComponents, patternComponents) {
            if !patternComponent.hasPrefix(":") && pathComponent != patternComponent {
                return false
            }
        }
        
        return true
    }
    
    /// Extract parameters from a matching path
    public func extractParameters(from path: String) -> [String: String]? {
        guard matches(path: path) else { return nil }
        
        return TypeSafeRouteBuilder.extractParameters(from: path, pattern: pattern)
    }
}

/// Enhanced route matcher for matching URLs to routes with improved pattern support
public class RouteMatcher<Route: TypeSafeRoute> {
    private var patterns: [RoutePattern] = []
    private var routeConstructors: [String: ([String: String]) -> Route?] = [:]
    private var priority: [String: Int] = [:]
    
    public init() {}
    
    /// Register a route pattern with its constructor and optional priority
    public func register(
        pattern: String,
        priority: Int = 0,
        constructor: @escaping ([String: String]) -> Route?
    ) {
        let routePattern = RoutePattern(pattern: pattern)
        patterns.append(routePattern)
        routeConstructors[pattern] = constructor
        self.priority[pattern] = priority
        
        // Sort patterns by priority (higher priority first)
        patterns.sort { first, second in
            let firstPriority = self.priority[first.pattern] ?? 0
            let secondPriority = self.priority[second.pattern] ?? 0
            return firstPriority > secondPriority
        }
    }
    
    /// Match a URL to a route with query parameter extraction
    public func match(url: URL) -> Route? {
        let path = url.path.isEmpty ? "/" : url.path
        
        // Extract query parameters from URL
        var queryParameters: [String: String] = [:]
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            for item in queryItems {
                queryParameters[item.name] = item.value ?? ""
            }
        }
        
        for pattern in patterns {
            if let pathParameters = pattern.extractParameters(from: path) {
                if let constructor = routeConstructors[pattern.pattern] {
                    // Merge path and query parameters
                    let allParameters = pathParameters.merging(queryParameters) { path, _ in path }
                    if let route = constructor(allParameters) {
                        return route
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Match a path string to a route
    public func match(path: String) -> Route? {
        guard let url = URL(string: "https://example.com" + path) else { return nil }
        return match(url: url)
    }
    
    /// Get all registered patterns (for debugging)
    public func getRegisteredPatterns() -> [String] {
        return patterns.map { $0.pattern }
    }
    
    /// Check if a pattern is registered
    public func hasPattern(_ pattern: String) -> Bool {
        return routeConstructors[pattern] != nil
    }
}

// MARK: - TypeSafeRoute Protocol Conformance for StandardRoute

/// Extension to make the existing StandardRoute conform to TypeSafeRoute protocol
extension StandardRoute: TypeSafeRoute {
    public var pathComponents: String {
        switch self {
        case .home:
            return "/"
        case .detail(let id):
            return "/detail/\(id)"
        case .settings:
            return "/settings"
        case .custom(let path):
            return path
        }
    }
    
    public var queryParameters: [String: String] {
        return [:]
    }
    
    public var routeIdentifier: String {
        switch self {
        case .home:
            return "home"
        case .detail(let id):
            return "detail-\(id)"
        case .settings:
            return "settings"
        case .custom(let path):
            return "custom-\(path)"
        }
    }
}

// MARK: - Integration with Existing NavigationService

extension NavigationService {
    
    /// Navigate to any TypeSafeRoute route
    public func navigate<T: TypeSafeRoute>(to route: T) async -> Result<Void, AxiomError> {
        return await withErrorContext("NavigationService.navigateToTypeSafeRoute") {
            let token = NavigationCancellationToken()
            cancellationTokens.insert(token)
            
            defer { cancellationTokens.remove(token) }
            
            guard !token.isCancelled else {
                throw AxiomError.navigationError(.navigationBlocked("Navigation was cancelled"))
            }
            
            // Convert to internal Route type for compatibility
            let internalRoute = convertToInternalRoute(route)
            
            // Add current route to history if different
            if let current = currentRoute, current.identifier != route.routeIdentifier {
                navigationHistory.append(current)
            }
            
            // Update current route
            currentRoute = internalRoute
            
            // Execute navigation based on presentation style
            try await executeNavigation(route: route, token: token)
            
            return ()
        }
    }
    
    /// Convert TypeSafeRoute to internal Route type
    private func convertToInternalRoute<T: TypeSafeRoute>(_ route: T) -> Route {
        // Check if it's already a StandardRoute
        if let standardRoute = route as? StandardRoute {
            return standardRoute
        }
        
        // Convert other TypeSafeRoute implementations to custom path
        return StandardRoute.custom(path: route.pathComponents)
    }
    
    /// Execute navigation for TypeSafeRoute routes
    private func executeNavigation<T: TypeSafeRoute>(
        route: T, 
        token: NavigationCancellationToken
    ) async throws {
        guard !token.isCancelled else {
            throw AxiomError.navigationError(.navigationBlocked("Navigation cancelled"))
        }
        
        // Execute based on presentation style
        switch route.presentation {
        case .push:
            // Handle push navigation
            break
        case .present(_):
            // Handle modal presentation
            break
        case .replace:
            // Handle replacement navigation
            break
        }
        
        // Add any route-specific navigation logic here
    }
}