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
        // Simple parameter extraction - can be enhanced
        var parameters: [String: String] = [:]
        
        let pathComponents = path.split(separator: "/")
        let patternComponents = pattern.split(separator: "/")
        
        for (index, patternComponent) in patternComponents.enumerated() {
            if patternComponent.hasPrefix(":"), index < pathComponents.count {
                let parameterName = String(patternComponent.dropFirst())
                let parameterValue = String(pathComponents[index])
                parameters[parameterName] = parameterValue
            }
        }
        
        return parameters
    }
}

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

/// Route matcher for matching URLs to routes
public class RouteMatcher<Route: TypeSafeRoute> {
    private var patterns: [RoutePattern] = []
    private var routeConstructors: [String: ([String: String]) -> Route?] = [:]
    
    public init() {}
    
    /// Register a route pattern with its constructor
    public func register(
        pattern: String,
        constructor: @escaping ([String: String]) -> Route?
    ) {
        let routePattern = RoutePattern(pattern: pattern)
        patterns.append(routePattern)
        routeConstructors[pattern] = constructor
    }
    
    /// Match a URL to a route
    public func match(url: URL) -> Route? {
        let path = url.path.isEmpty ? "/" : url.path
        
        for pattern in patterns {
            if let parameters = pattern.extractParameters(from: path) {
                if let constructor = routeConstructors[pattern.pattern] {
                    return constructor(parameters)
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
    private func convertToInternalRoute<T: TypeSafeRoute>(_ route: T) -> StandardRoute {
        // Simple conversion - in a real implementation this might be more sophisticated
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