import Foundation

// MARK: - Enhanced Type-Safe Route Protocol System

// MARK: - Base Routing Protocols and Types

/// Base protocol for all routable components
public protocol AxiomRoutable {
    var presentation: PresentationStyle { get }
}

/// Generic route type alias for compatibility
public typealias AxiomRoute = any AxiomTypeSafeRoute

/// Standard route enumeration for basic navigation
public enum AxiomStandardRoute: AxiomRoutable {
    case home
    case detail(id: String)
    case settings
    case custom(path: String)
    
    public var presentation: PresentationStyle {
        switch self {
        case .home:
            return .replace
        case .detail:
            return .push
        case .settings:
            return .present(.sheet)
        case .custom:
            return .push
        }
    }
    
    /// Unique identifier for this route
    public var identifier: String {
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

/// Enhanced protocol for type-safe routing that supports any route structure
public protocol AxiomTypeSafeRoute: AxiomRoutable, Hashable, Sendable {
    /// The path components of this route (e.g., "/profile/123")
    var pathComponents: String { get }
    
    /// Query parameters for this route
    var queryParameters: [String: String] { get }
    
    /// Unique identifier for this route instance
    var routeIdentifier: String { get }
}

/// Default implementation of Routable for TypeSafeRoute
extension AxiomTypeSafeRoute {
    public var presentation: PresentationStyle {
        // Default presentation style - can be overridden
        return .push
    }
}

/// Route building utilities for type-safe routes
public struct AxiomTypeSafeRouteBuilder {
    
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
public class AxiomEnhancedRouteBuilder<Route: AxiomTypeSafeRoute> {
    private var baseRoute: Route?
    private var additionalQueryParameters: [String: String] = [:]
    
    public init() {}
    
    /// Start building with a base route
    public func route(_ route: Route) -> AxiomEnhancedRouteBuilder<Route> {
        self.baseRoute = route
        return self
    }
    
    /// Add a query parameter
    public func withQueryParameter(_ key: String, value: String) -> AxiomEnhancedRouteBuilder<Route> {
        additionalQueryParameters[key] = value
        return self
    }
    
    /// Add multiple query parameters
    public func withQueryParameters(_ parameters: [String: String]) -> AxiomEnhancedRouteBuilder<Route> {
        for (key, value) in parameters {
            additionalQueryParameters[key] = value
        }
        return self
    }
    
    /// Build the final route URL
    public func buildURL() throws -> String {
        guard let route = baseRoute else {
            throw AxiomError.navigationError(.invalidRoute("No base route set for builder"))
        }
        
        let mergedParameters = route.queryParameters.merging(additionalQueryParameters) { _, new in new }
        return AxiomTypeSafeRouteBuilder.buildURL(path: route.pathComponents, queryParameters: mergedParameters)
    }
    
    /// Get the base route (if available)
    public func getRoute() -> Route? {
        return baseRoute
    }
}

/// Use AxiomEnhancedRouteBuilder as the main implementation
// Note: AxiomTypeSafeRouteBuilder struct above provides static utility methods

/// Simple route matching for URL patterns
public struct AxiomRoutePattern {
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
        
        return AxiomTypeSafeRouteBuilder.extractParameters(from: path, pattern: pattern)
    }
}

/// Enhanced route matcher for matching URLs to routes with improved pattern support
public class AxiomRouteMatcher<Route: AxiomTypeSafeRoute> {
    private var patterns: [AxiomRoutePattern] = []
    private var routeConstructors: [String: ([String: String]) -> Route?] = [:]
    private var priority: [String: Int] = [:]
    
    public init() {}
    
    /// Register a route pattern with its constructor and optional priority
    public func register(
        pattern: String,
        priority: Int = 0,
        constructor: @escaping ([String: String]) -> Route?
    ) {
        let routePattern = AxiomRoutePattern(pattern: pattern)
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

// MARK: - AxiomTypeSafeRoute Protocol Conformance for AxiomStandardRoute

/// Extension to make the existing AxiomStandardRoute conform to AxiomTypeSafeRoute protocol
extension AxiomStandardRoute: AxiomTypeSafeRoute {
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

