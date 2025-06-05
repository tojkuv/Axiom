import Foundation

// MARK: - Deep Linking Implementation

/// URL to route parser for deep linking support
/// 
/// Provides URL to route resolution with type-safe parameter extraction.
/// Invalid URLs produce structured errors, not crashes, with parser handling
/// all registered URL patterns. URL parsing is isolated from navigation execution.
public struct URLToRouteParser: Sendable {
    
    /// Expected URL scheme for the application
    private let expectedScheme: String
    
    /// Registered URL patterns for route resolution
    private let patterns: [URLPattern]
    
    /// Initialize parser with expected scheme and patterns
    public init(scheme: String = "axiom", patterns: [URLPattern] = URLPattern.defaultPatterns) {
        self.expectedScheme = scheme
        self.patterns = patterns
    }
    
    /// Parse URL to route with type-safe parameter extraction
    /// - Parameter url: The URL to parse
    /// - Returns: The parsed route
    /// - Throws: DeepLinkingError for invalid URLs or parsing failures
    public func parse(url: URL) throws -> Route {
        // Validate URL scheme
        guard let scheme = url.scheme, scheme == expectedScheme else {
            throw DeepLinkingError.invalidURLScheme(url.scheme ?? "nil")
        }
        
        // Validate URL components
        try validate(url: url)
        
        // Extract path for pattern matching - handle both path and host-based URLs
        let pathToMatch: String
        if let host = url.host, !host.isEmpty {
            // For URLs like axiom://detail/id, combine host and path
            if !url.path.isEmpty && url.path != "/" {
                pathToMatch = "/\(host)\(url.path)"
            } else {
                pathToMatch = "/\(host)"
            }
        } else if !url.path.isEmpty {
            pathToMatch = url.path
        } else {
            pathToMatch = "/"
        }
        
        // Find matching pattern
        guard let matchingPattern = patterns.first(where: { $0.matches(path: pathToMatch) }) else {
            throw DeepLinkingError.patternNotFound(pathToMatch)
        }
        
        // Extract parameters and create route
        return try matchingPattern.extractRoute(from: url, matchedPath: pathToMatch)
    }
    
    /// Validate URL structure before parsing
    /// - Parameter url: The URL to validate
    /// - Throws: DeepLinkingError for validation failures
    public func validate(url: URL) throws {
        // Check scheme
        guard let scheme = url.scheme, scheme == expectedScheme else {
            throw DeepLinkingError.urlValidationFailed("Invalid scheme: expected '\(expectedScheme)', got '\(url.scheme ?? "nil")'")
        }
        
        // For app URLs, we need either a host or a meaningful path
        if url.host == nil && (url.path.isEmpty || url.path == "/") {
            throw DeepLinkingError.urlValidationFailed("URL must have either a host or a path")
        }
        
        // Additional validation for specific patterns
        let path = url.path
        if path.hasSuffix("/") && path != "/" {
            // Check if this is an incomplete detail or custom path
            if path == "/detail/" || path == "/custom/" {
                throw DeepLinkingError.urlValidationFailed("Incomplete path: \(path)")
            }
        }
    }
    
    /// Get all registered patterns
    public func getPatterns() -> [URLPattern] {
        return patterns
    }
    
    /// Check if a URL can be parsed
    public func canParse(url: URL) -> Bool {
        do {
            _ = try parse(url: url)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - URL Pattern System

/// URL pattern for route matching and parameter extraction
public struct URLPattern: Sendable, Hashable {
    /// Pattern string (e.g., "/detail/{id}")
    public let pattern: String
    
    /// Route type this pattern maps to
    public let routeType: RouteType
    
    /// Parameter names in order
    public let parameterNames: [String]
    
    /// Create URL pattern
    public init(pattern: String, routeType: RouteType, parameterNames: [String] = []) {
        self.pattern = pattern
        self.routeType = routeType
        self.parameterNames = parameterNames
    }
    
    /// Check if this pattern matches the given path
    public func matches(path: String) -> Bool {
        switch routeType {
        case .home:
            return path == "/home" || path == "/"
        case .detail:
            return path.hasPrefix("/detail/") && path.count > "/detail/".count
        case .settings:
            return path == "/settings"
        case .custom:
            return path.hasPrefix("/custom/") && path.count > "/custom/".count
        }
    }
    
    /// Extract route from URL using this pattern
    public func extractRoute(from url: URL, matchedPath: String) throws -> Route {
        switch routeType {
        case .home:
            return .home
            
        case .detail:
            if matchedPath.hasPrefix("/detail/") {
                let idString = String(matchedPath.dropFirst("/detail/".count))
                guard !idString.isEmpty else {
                    throw DeepLinkingError.parameterExtractionFailed("id")
                }
                return .detail(id: idString)
            } else {
                throw DeepLinkingError.patternNotFound(matchedPath)
            }
            
        case .settings:
            return .settings
            
        case .custom:
            if matchedPath.hasPrefix("/custom/") {
                let customPath = String(matchedPath.dropFirst("/custom/".count))
                guard !customPath.isEmpty else {
                    throw DeepLinkingError.parameterExtractionFailed("path")
                }
                return .custom(path: customPath)
            } else {
                throw DeepLinkingError.patternNotFound(matchedPath)
            }
        }
    }
    
    /// Legacy method for backward compatibility
    public func extractRoute(from url: URL) throws -> Route {
        let path = url.path.isEmpty ? "/\(url.host ?? "")" : url.path
        return try extractRoute(from: url, matchedPath: path)
    }
    
    /// Route type enumeration
    public enum RouteType: CaseIterable, Sendable {
        case home
        case detail
        case settings
        case custom
    }
    
    /// Default URL patterns for standard routes
    public static let defaultPatterns: [URLPattern] = [
        URLPattern(pattern: "/home", routeType: .home),
        URLPattern(pattern: "/", routeType: .home),
        URLPattern(pattern: "/detail/{id}", routeType: .detail, parameterNames: ["id"]),
        URLPattern(pattern: "/settings", routeType: .settings),
        URLPattern(pattern: "/custom/{path}", routeType: .custom, parameterNames: ["path"])
    ]
}

// MARK: - Deep Linking Errors

/// Deep linking errors for structured error handling
public enum DeepLinkingError: Error, LocalizedError, Sendable {
    case invalidURLScheme(String)
    case invalidPath(String)
    case patternNotFound(String)
    case parameterExtractionFailed(String)
    case urlValidationFailed(String)
    case parsingFailed(String)
    case routeConstructionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURLScheme(let scheme):
            return "Invalid URL scheme: \(scheme). Expected 'axiom'"
        case .invalidPath(let path):
            return "Invalid URL path: \(path)"
        case .patternNotFound(let pattern):
            return "URL pattern not found: \(pattern)"
        case .parameterExtractionFailed(let parameter):
            return "Failed to extract parameter: \(parameter)"
        case .urlValidationFailed(let reason):
            return "URL validation failed: \(reason)"
        case .parsingFailed(let reason):
            return "URL parsing failed: \(reason)"
        case .routeConstructionFailed(let reason):
            return "Route construction failed: \(reason)"
        }
    }
}

// MARK: - URL Builder

/// Builder for constructing URLs from routes
public struct URLBuilder: Sendable {
    private let scheme: String
    private let host: String?
    
    /// Initialize URL builder
    public init(scheme: String = "axiom", host: String? = nil) {
        self.scheme = scheme
        self.host = host
    }
    
    /// Build URL from route
    public func buildURL(for route: Route) throws -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        
        switch route {
        case .home:
            components.path = "/home"
            
        case .detail(let id):
            guard !id.isEmpty else {
                throw DeepLinkingError.routeConstructionFailed("Detail ID cannot be empty")
            }
            components.path = "/detail/\(id)"
            
        case .settings:
            components.path = "/settings"
            
        case .custom(let path):
            guard !path.isEmpty else {
                throw DeepLinkingError.routeConstructionFailed("Custom path cannot be empty")
            }
            components.path = "/custom/\(path)"
        }
        
        guard let url = components.url else {
            throw DeepLinkingError.routeConstructionFailed("Failed to construct URL components")
        }
        
        return url
    }
    
    /// Build URLs for multiple routes
    public func buildURLs(for routes: [Route]) throws -> [URL] {
        return try routes.map { try buildURL(for: $0) }
    }
}

// MARK: - Deep Linking Service

/// Service for handling deep linking in the application
public actor DeepLinkingService {
    private let parser: URLToRouteParser
    private let urlBuilder: URLBuilder
    private var routeHandler: ((Route) async -> Void)?
    
    /// Initialize deep linking service
    public init(parser: URLToRouteParser = URLToRouteParser(), urlBuilder: URLBuilder = URLBuilder()) {
        self.parser = parser
        self.urlBuilder = urlBuilder
    }
    
    /// Handle incoming URL
    public func handleURL(_ url: URL) async throws -> Route {
        let route = try parser.parse(url: url)
        
        // Execute registered handler if available
        if let handler = routeHandler {
            await handler(route)
        }
        
        return route
    }
    
    /// Register handler for routes
    public func registerHandler(_ handler: @escaping (Route) async -> Void) {
        routeHandler = handler
    }
    
    /// Generate URL for route
    public func generateURL(for route: Route) throws -> URL {
        return try urlBuilder.buildURL(for: route)
    }
    
    /// Validate URL without parsing
    public func validateURL(_ url: URL) async throws {
        try parser.validate(url: url)
    }
    
    /// Check if URL can be handled
    public func canHandle(_ url: URL) async -> Bool {
        return parser.canParse(url: url)
    }
}

// MARK: - Pattern Matching Extensions

public extension URLPattern {
    
    /// Create pattern with parameter extraction
    static func withParameters(pattern: String, routeType: RouteType) -> URLPattern {
        // Extract parameter names from pattern (e.g., "/detail/{id}" -> ["id"])
        let parameterNames = extractParameterNames(from: pattern)
        return URLPattern(pattern: pattern, routeType: routeType, parameterNames: parameterNames)
    }
    
    /// Extract parameter names from pattern string
    private static func extractParameterNames(from pattern: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: "\\{([^}]+)\\}", options: [])
        let matches = regex.matches(in: pattern, options: [], range: NSRange(location: 0, length: pattern.count))
        
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: pattern) else { return nil }
            return String(pattern[range])
        }
    }
}

// MARK: - Regex-Based Pattern Matching (REFACTOR)

/// Enhanced URL pattern with regex-based matching
public struct RegexURLPattern: Sendable, Hashable {
    /// Pattern string with placeholders
    public let pattern: String
    
    /// Compiled regex pattern
    private let regex: NSRegularExpression
    
    /// Route type this pattern maps to
    public let routeType: URLPattern.RouteType
    
    /// Parameter names in order
    public let parameterNames: [String]
    
    /// Create regex-based URL pattern
    public init(pattern: String, routeType: URLPattern.RouteType) throws {
        self.pattern = pattern
        self.routeType = routeType
        
        // Extract parameter names
        self.parameterNames = Self.extractParameterNames(from: pattern)
        
        // Convert pattern to regex
        let regexPattern = Self.patternToRegex(pattern)
        self.regex = try NSRegularExpression(pattern: regexPattern, options: [])
    }
    
    /// Check if this pattern matches the given path
    public func matches(path: String) -> Bool {
        let range = NSRange(location: 0, length: path.count)
        return regex.firstMatch(in: path, options: [], range: range) != nil
    }
    
    /// Extract route from URL using regex pattern matching
    public func extractRoute(from url: URL, matchedPath: String) throws -> Route {
        let range = NSRange(location: 0, length: matchedPath.count)
        
        guard let match = regex.firstMatch(in: matchedPath, options: [], range: range) else {
            throw DeepLinkingError.patternNotFound(matchedPath)
        }
        
        // Extract parameters using capture groups
        var parameters: [String: String] = [:]
        for (index, paramName) in parameterNames.enumerated() {
            let captureGroupIndex = index + 1 // Capture groups start at 1
            if captureGroupIndex < match.numberOfRanges {
                let captureRange = match.range(at: captureGroupIndex)
                if let range = Range(captureRange, in: matchedPath) {
                    parameters[paramName] = String(matchedPath[range])
                }
            }
        }
        
        // Create route based on type and extracted parameters
        return try createRoute(type: routeType, parameters: parameters)
    }
    
    /// Convert pattern string to regex pattern
    private static func patternToRegex(_ pattern: String) -> String {
        // Escape regex special characters except for our placeholders
        var regexPattern = NSRegularExpression.escapedPattern(for: pattern)
        
        // Replace escaped placeholders with capture groups
        let placeholderRegex = try! NSRegularExpression(pattern: "\\\\\\{([^}]+)\\\\\\}", options: [])
        let range = NSRange(location: 0, length: regexPattern.count)
        
        regexPattern = placeholderRegex.stringByReplacingMatches(
            in: regexPattern,
            options: [],
            range: range,
            withTemplate: "([^/]+)"
        )
        
        // Anchor the pattern to match the entire string
        return "^\(regexPattern)$"
    }
    
    /// Extract parameter names from pattern
    private static func extractParameterNames(from pattern: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: "\\{([^}]+)\\}", options: [])
        let matches = regex.matches(in: pattern, options: [], range: NSRange(location: 0, length: pattern.count))
        
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: pattern) else { return nil }
            return String(pattern[range])
        }
    }
    
    /// Create route from type and parameters
    private func createRoute(type: URLPattern.RouteType, parameters: [String: String]) throws -> Route {
        switch type {
        case .home:
            return .home
            
        case .detail:
            guard let id = parameters["id"], !id.isEmpty else {
                throw DeepLinkingError.parameterExtractionFailed("id")
            }
            return .detail(id: id)
            
        case .settings:
            return .settings
            
        case .custom:
            // For custom routes, if there's a specific "path" parameter, use it
            // Otherwise, use the last parameter as the path
            if let path = parameters["path"], !path.isEmpty {
                return .custom(path: path)
            } else if let lastParam = parameterNames.last, let lastValue = parameters[lastParam], !lastValue.isEmpty {
                return .custom(path: lastValue)
            } else {
                throw DeepLinkingError.parameterExtractionFailed("path")
            }
        }
    }
    
    /// Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(pattern)
        hasher.combine(routeType)
    }
    
    public static func == (lhs: RegexURLPattern, rhs: RegexURLPattern) -> Bool {
        return lhs.pattern == rhs.pattern && lhs.routeType == rhs.routeType
    }
}

// MARK: - Enhanced URL Parser with Regex Support

/// Enhanced URL parser with regex-based pattern matching
public struct EnhancedURLToRouteParser: Sendable {
    
    /// Expected URL scheme
    private let expectedScheme: String
    
    /// Regex-based patterns for route resolution
    private let regexPatterns: [RegexURLPattern]
    
    /// Fallback to simple patterns if regex fails
    private let fallbackPatterns: [URLPattern]
    
    /// Initialize enhanced parser
    public init(
        scheme: String = "axiom",
        regexPatterns: [RegexURLPattern] = [],
        fallbackPatterns: [URLPattern] = URLPattern.defaultPatterns
    ) {
        self.expectedScheme = scheme
        self.regexPatterns = regexPatterns
        self.fallbackPatterns = fallbackPatterns
    }
    
    /// Parse URL with regex-based pattern matching
    public func parse(url: URL) throws -> Route {
        // Validate URL scheme
        guard let scheme = url.scheme, scheme == expectedScheme else {
            throw DeepLinkingError.invalidURLScheme(url.scheme ?? "nil")
        }
        
        // Extract path for pattern matching
        let pathToMatch: String
        if let host = url.host, !host.isEmpty {
            if !url.path.isEmpty && url.path != "/" {
                pathToMatch = "/\(host)\(url.path)"
            } else {
                pathToMatch = "/\(host)"
            }
        } else if !url.path.isEmpty {
            pathToMatch = url.path
        } else {
            pathToMatch = "/"
        }
        
        // Try regex patterns first
        for pattern in regexPatterns {
            if pattern.matches(path: pathToMatch) {
                return try pattern.extractRoute(from: url, matchedPath: pathToMatch)
            }
        }
        
        // Fallback to simple patterns
        for pattern in fallbackPatterns {
            if pattern.matches(path: pathToMatch) {
                return try pattern.extractRoute(from: url, matchedPath: pathToMatch)
            }
        }
        
        throw DeepLinkingError.patternNotFound(pathToMatch)
    }
    
    /// Validate URL
    public func validate(url: URL) throws {
        guard let scheme = url.scheme, scheme == expectedScheme else {
            throw DeepLinkingError.urlValidationFailed("Invalid scheme: expected '\(expectedScheme)', got '\(url.scheme ?? "nil")'")
        }
        
        if url.host == nil && (url.path.isEmpty || url.path == "/") {
            throw DeepLinkingError.urlValidationFailed("URL must have either a host or a path")
        }
    }
    
    /// Check if URL can be parsed
    public func canParse(url: URL) -> Bool {
        do {
            _ = try parse(url: url)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Default Regex Patterns

public extension RegexURLPattern {
    
    /// Default regex patterns for common routes
    static let defaultPatterns: [RegexURLPattern] = {
        do {
            return [
                try RegexURLPattern(pattern: "/home", routeType: .home),
                try RegexURLPattern(pattern: "/detail/{id}", routeType: .detail),
                try RegexURLPattern(pattern: "/settings", routeType: .settings),
                try RegexURLPattern(pattern: "/custom/{path}", routeType: .custom),
                // Advanced patterns with multiple parameters
                try RegexURLPattern(pattern: "/user/{userId}/detail/{id}", routeType: .detail),
                try RegexURLPattern(pattern: "/category/{category}/item/{id}", routeType: .detail),
            ]
        } catch {
            // Fallback to empty array if pattern creation fails
            return []
        }
    }()
    
    /// Create pattern for complex routes with multiple parameters
    static func multiParameter(pattern: String, routeType: URLPattern.RouteType) throws -> RegexURLPattern {
        return try RegexURLPattern(pattern: pattern, routeType: routeType)
    }
}

// MARK: - Pattern Builder for Complex Routes

/// Builder for creating complex regex patterns
public struct RegexPatternBuilder {
    private var patterns: [RegexURLPattern] = []
    
    public init() {}
    
    /// Add a simple pattern
    public mutating func addPattern(_ pattern: String, type: URLPattern.RouteType) throws {
        let regexPattern = try RegexURLPattern(pattern: pattern, routeType: type)
        patterns.append(regexPattern)
    }
    
    /// Add multiple patterns at once
    public mutating func addPatterns(_ patternConfigs: [(String, URLPattern.RouteType)]) throws {
        for (pattern, type) in patternConfigs {
            try addPattern(pattern, type: type)
        }
    }
    
    /// Build the pattern collection
    public func build() -> [RegexURLPattern] {
        return patterns
    }
    
    /// Create builder with default patterns
    public static func withDefaults() -> RegexPatternBuilder {
        var builder = RegexPatternBuilder()
        builder.patterns = RegexURLPattern.defaultPatterns
        return builder
    }
}

// MARK: - Type Safety Extensions

public extension Route {
    
    /// Convert route to URL using default builder
    func toURL(scheme: String = "axiom") throws -> URL {
        let builder = URLBuilder(scheme: scheme)
        return try builder.buildURL(for: self)
    }
    
    /// Validate route parameters
    func validateParameters() throws {
        try validate() // Use existing validation from Route
    }
    
    /// Get parameter values as dictionary
    func parameterDictionary() -> [String: Any] {
        switch self {
        case .home, .settings:
            return [:]
        case .detail(let id):
            return ["id": id]
        case .custom(let path):
            return ["path": path]
        }
    }
}

// MARK: - Testing Support

#if DEBUG
public extension URLToRouteParser {
    
    /// Create parser for testing with custom patterns
    static func forTesting(patterns: [URLPattern] = URLPattern.defaultPatterns) -> URLToRouteParser {
        return URLToRouteParser(scheme: "axiom", patterns: patterns)
    }
    
    /// Parse URL without validation (for testing edge cases)
    func parseWithoutValidation(url: URL) throws -> Route {
        let path = url.path
        
        guard let matchingPattern = patterns.first(where: { $0.matches(path: path) }) else {
            throw DeepLinkingError.patternNotFound(path)
        }
        
        return try matchingPattern.extractRoute(from: url)
    }
}
#endif