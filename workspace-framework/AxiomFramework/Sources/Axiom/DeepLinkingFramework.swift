import Foundation
import SwiftUI

#if canImport(XCTest)
import XCTest
#endif

// MARK: - Deep Linking Framework (W-04-004)

/// Comprehensive deep linking framework with pattern matching and type-safe parameter extraction
/// Supports URL-based navigation, universal links, custom URL schemes, and advanced pattern matching

// MARK: - Core Types

/// Deep link resolution result
public enum DeepLinkResolution: Equatable {
    case resolved(any TypeSafeRoute)
    case redirect(URL)
    case fallback(any TypeSafeRoute)
    case invalid(reason: String)
    
    public static func == (lhs: DeepLinkResolution, rhs: DeepLinkResolution) -> Bool {
        switch (lhs, rhs) {
        case (.resolved(let a), .resolved(let b)):
            return type(of: a) == type(of: b)
        case (.redirect(let a), .redirect(let b)):
            return a == b
        case (.fallback(let a), .fallback(let b)):
            return type(of: a) == type(of: b)
        case (.invalid(let a), .invalid(let b)):
            return a == b
        default:
            return false
        }
    }
}

/// Deep link parameters with type-safe extraction
public struct DeepLinkParameters {
    public let pathParameters: [String: String]
    public let queryParameters: [String: String]
    public let fragments: String?
    
    public init(pathParameters: [String: String], queryParameters: [String: String], fragments: String?) {
        self.pathParameters = pathParameters
        self.queryParameters = queryParameters
        self.fragments = fragments
    }
    
    /// Get parameter with type conversion
    public func get<T>(_ key: String, as type: T.Type) -> T? where T: LosslessStringConvertible {
        if let value = pathParameters[key] {
            return T(value)
        }
        if let value = queryParameters[key] {
            return T(value)
        }
        return nil
    }
}

/// Deep link context for analytics and tracking
public struct DeepLinkContext {
    public let source: DeepLinkSource
    public let timestamp: Date
    public let referrer: String?
    public let campaign: String?
    public let queryParameters: [String: String]
    
    public enum DeepLinkSource {
        case externalApp(bundleId: String)
        case webBrowser
        case pushNotification
        case qrCode
        case nfc
    }
    
    public init(source: DeepLinkSource, timestamp: Date = Date(), referrer: String? = nil, campaign: String? = nil, queryParameters: [String: String] = [:]) {
        self.source = source
        self.timestamp = timestamp
        self.referrer = referrer
        self.campaign = campaign
        self.queryParameters = queryParameters
    }
}

/// Deep link errors
public enum DeepLinkError: Error, Equatable {
    case invalidPattern(String)
    case conflictingPattern(String)
    case compilationFailure(String)
    case routeNotFound
    case invalidParameter(String)
    case unauthorized(String)
    
    public static func == (lhs: DeepLinkError, rhs: DeepLinkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidPattern(let a), .invalidPattern(let b)):
            return a == b
        case (.conflictingPattern(let a), .conflictingPattern(let b)):
            return a == b
        case (.compilationFailure(let a), .compilationFailure(let b)):
            return a == b
        case (.routeNotFound, .routeNotFound):
            return true
        case (.invalidParameter(let a), .invalidParameter(let b)):
            return a == b
        case (.unauthorized(let a), .unauthorized(let b)):
            return a == b
        default:
            return false
        }
    }
}

/// Security validation result
public enum ValidationResult: Equatable {
    case success
    case failure(String)
}

// MARK: - Pattern Compilation System

/// Compiled URL pattern for efficient matching
public struct CompiledPattern {
    public let segments: [PatternSegment]
    public let priority: Int
    
    public init(segments: [PatternSegment], priority: Int = 0) {
        self.segments = segments
        self.priority = priority
    }
}

/// Pattern segment types
public struct PatternSegment {
    public let type: SegmentType
    public let value: String
    
    public enum SegmentType {
        case `static`(String)
        case parameter(name: String, optional: Bool)
        case wildcard(greedy: Bool)
    }
    
    public var isParameter: Bool {
        if case .parameter = type { return true }
        return false
    }
    
    public var isOptional: Bool {
        if case .parameter(_, let optional) = type { return optional }
        return false
    }
    
    public var parameterName: String? {
        if case .parameter(let name, _) = type { return name }
        return nil
    }
    
    public var isWildcard: Bool {
        if case .wildcard = type { return true }
        return false
    }
    
    public var isGreedy: Bool {
        if case .wildcard(let greedy) = type { return greedy }
        return false
    }
    
    public init(type: SegmentType, value: String) {
        self.type = type
        self.value = value
    }
}

/// URL pattern compiler for efficient matching (REFACTOR: optimized with caching)
public class URLPatternCompiler {
    // REFACTOR: Pattern compilation cache for performance
    private var compilationCache: [String: CompiledPattern] = [:]
    private let cacheQueue = DispatchQueue(label: "pattern.compiler.cache", attributes: .concurrent)
    
    public init() {}
    
    /// Compile pattern string to efficient matching structure (REFACTOR: with caching)
    public func compile(_ pattern: String) -> CompiledPattern {
        // REFACTOR: Check cache first
        return cacheQueue.sync {
            if let cached = compilationCache[pattern] {
                return cached
            }
            
            let compiled = compilePattern(pattern)
            compilationCache[pattern] = compiled
            return compiled
        }
    }
    
    /// Core compilation logic (REFACTOR: optimized segment processing)
    private func compilePattern(_ pattern: String) -> CompiledPattern {
        let segments = pattern.split(separator: "/").compactMap { segment -> PatternSegment? in
            let segmentStr = String(segment)
            
            if segmentStr.hasPrefix(":") {
                // Parameter segment - REFACTOR: optimized parameter parsing
                let name = String(segmentStr.dropFirst())
                let isOptional = name.hasSuffix("?")
                let paramName = isOptional ? String(name.dropLast()) : name
                return PatternSegment(
                    type: .parameter(name: paramName, optional: isOptional),
                    value: segmentStr
                )
            } else if segmentStr == "*" {
                // Single wildcard
                return PatternSegment(
                    type: .wildcard(greedy: false),
                    value: segmentStr
                )
            } else if segmentStr == "**" {
                // Greedy wildcard
                return PatternSegment(
                    type: .wildcard(greedy: true),
                    value: segmentStr
                )
            } else {
                // Static segment
                return PatternSegment(
                    type: .`static`(segmentStr),
                    value: segmentStr
                )
            }
        }
        
        let priority = calculatePriority(for: pattern)
        return CompiledPattern(segments: segments, priority: priority)
    }
    
    /// Calculate pattern priority (higher = more specific)
    private func calculatePriority(for pattern: String) -> Int {
        var priority = 0
        priority += pattern.components(separatedBy: "/").count * 10
        priority -= pattern.components(separatedBy: ":").count * 5
        priority -= pattern.components(separatedBy: "*").count * 20
        return priority
    }
}

// MARK: - Analytics Framework (REFACTOR Enhancement)

/// Deep link analytics protocol
public protocol DeepLinkAnalytics {
    func trackDeepLink(_ url: URL, resolution: DeepLinkResolution)
    func trackConversion(from deepLink: URL, event: String)
    func generateReport() -> DeepLinkReport
}

/// Deep link analytics tracker (REFACTOR: comprehensive analytics)
public class DeepLinkAnalyticsTracker: DeepLinkAnalytics {
    private var linkEvents: [DeepLinkEvent] = []
    private var conversions: [ConversionEvent] = []
    private var patternRegistrations: [PatternRegistrationEvent] = []
    private var performanceMetrics: [PerformanceMetric] = []
    
    public init() {}
    
    public func trackDeepLink(_ url: URL, resolution: DeepLinkResolution) {
        let event = DeepLinkEvent(
            url: url,
            resolution: resolution,
            timestamp: Date()
        )
        linkEvents.append(event)
    }
    
    public func trackConversion(from deepLink: URL, event: String) {
        let conversion = ConversionEvent(
            deepLink: deepLink,
            event: event,
            timestamp: Date()
        )
        conversions.append(conversion)
    }
    
    public func trackPatternRegistration(_ pattern: String, priority: Int) {
        let event = PatternRegistrationEvent(
            pattern: pattern,
            priority: priority,
            timestamp: Date()
        )
        patternRegistrations.append(event)
    }
    
    public func trackPerformance(url: URL, duration: TimeInterval) {
        let metric = PerformanceMetric(
            url: url,
            duration: duration,
            timestamp: Date()
        )
        performanceMetrics.append(metric)
    }
    
    public func generateReport() -> DeepLinkReport {
        return DeepLinkReport(
            totalLinks: linkEvents.count,
            successfulResolutions: linkEvents.filter { 
                if case .resolved = $0.resolution { return true }
                return false
            }.count,
            averageResolutionTime: averagePerformance(),
            topPatterns: getTopPatterns(),
            conversionRate: calculateConversionRate()
        )
    }
    
    private func averagePerformance() -> TimeInterval {
        guard !performanceMetrics.isEmpty else { return 0 }
        let total = performanceMetrics.reduce(0) { $0 + $1.duration }
        return total / Double(performanceMetrics.count)
    }
    
    private func getTopPatterns() -> [String] {
        let patternCounts = patternRegistrations.reduce(into: [String: Int]()) { counts, event in
            counts[event.pattern, default: 0] += 1
        }
        return patternCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
    }
    
    private func calculateConversionRate() -> Double {
        guard !linkEvents.isEmpty else { return 0 }
        return Double(conversions.count) / Double(linkEvents.count)
    }
}

/// Analytics event types
private struct DeepLinkEvent {
    let url: URL
    let resolution: DeepLinkResolution
    let timestamp: Date
}

private struct ConversionEvent {
    let deepLink: URL
    let event: String
    let timestamp: Date
}

private struct PatternRegistrationEvent {
    let pattern: String
    let priority: Int
    let timestamp: Date
}

private struct PerformanceMetric {
    let url: URL
    let duration: TimeInterval
    let timestamp: Date
}

/// Deep link analytics report
public struct DeepLinkReport {
    public let totalLinks: Int
    public let successfulResolutions: Int
    public let averageResolutionTime: TimeInterval
    public let topPatterns: [String]
    public let conversionRate: Double
    
    public var successRate: Double {
        guard totalLinks > 0 else { return 0 }
        return Double(successfulResolutions) / Double(totalLinks)
    }
}

// MARK: - Pattern Handler

/// Registered pattern with handler
private struct RegisteredPattern {
    let pattern: CompiledPattern
    let handler: ([String: String]) -> (any TypeSafeRoute)?
    
    init(pattern: CompiledPattern, handler: @escaping ([String: String]) -> (any TypeSafeRoute)?) {
        self.pattern = pattern
        self.handler = handler
    }
}

/// Deep link pattern handler for registration and matching
public class DeepLinkPatternHandler {
    private var patterns: [RegisteredPattern] = []
    private let compiler = URLPatternCompiler()
    public private(set) var lastResolutionContext: DeepLinkContext?
    
    // REFACTOR Phase optimizations
    private var patternCache: [String: CompiledPattern] = [:]
    private let analytics = DeepLinkAnalyticsTracker()
    private let securityValidator = DeepLinkSecurity()
    
    public init() {}
    
    /// Register URL pattern with handler (REFACTOR: with caching optimization)
    public func register(pattern: String, handler: @escaping ([String: String]) -> (any TypeSafeRoute)?) {
        // Check cache first for performance
        let compiled: CompiledPattern
        if let cached = patternCache[pattern] {
            compiled = cached
        } else {
            compiled = compiler.compile(pattern)
            patternCache[pattern] = compiled
        }
        
        let registered = RegisteredPattern(pattern: compiled, handler: handler)
        
        // Insert in priority order (highest priority first) - REFACTOR: optimized insertion
        if let insertIndex = patterns.firstIndex(where: { $0.pattern.priority < compiled.priority }) {
            patterns.insert(registered, at: insertIndex)
        } else {
            patterns.append(registered)
        }
        
        // Analytics tracking
        analytics.trackPatternRegistration(pattern, priority: compiled.priority)
    }
    
    /// Register pattern with error handling
    public func registerUnsafe(pattern: String) throws {
        guard !pattern.isEmpty else {
            throw DeepLinkError.invalidPattern("Empty pattern")
        }
        
        // Check for conflicting patterns
        let compiled = compiler.compile(pattern)
        for existing in patterns {
            if patternsConflict(compiled, existing.pattern) {
                throw DeepLinkError.conflictingPattern("Pattern conflicts with existing")
            }
        }
        
        register(pattern: pattern) { _ in nil as (any TypeSafeRoute)? }
    }
    
    /// Check if patterns conflict
    private func patternsConflict(_ pattern1: CompiledPattern, _ pattern2: CompiledPattern) -> Bool {
        // Simplified conflict detection - same number of segments with similar parameter structure
        guard pattern1.segments.count == pattern2.segments.count else { return false }
        
        for (seg1, seg2) in zip(pattern1.segments, pattern2.segments) {
            switch (seg1.type, seg2.type) {
            case (.parameter, .parameter):
                continue // Parameters can conflict
            case (.`static`(let a), .`static`(let b)):
                if a != b { return false }
            default:
                continue
            }
        }
        
        return true
    }
    
    /// Get registered patterns
    public var registeredPatterns: [String] {
        return patterns.map { pattern in
            pattern.pattern.segments.map { $0.value }.joined(separator: "/")
        }
    }
    
    /// Check if URL can be handled
    public func canHandle(_ url: URL) -> Bool {
        guard url.scheme == "axiom" || url.scheme == "https" else { return false }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        for registered in patterns {
            if matches(pathComponents: pathComponents, against: registered.pattern) {
                return true
            }
        }
        
        return false
    }
    
    /// Resolve URL to route (REFACTOR: with analytics and security validation)
    public func resolve(_ url: URL) -> DeepLinkResolution {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // REFACTOR: Security validation first
        let securityResult = securityValidator.validateURL(url)
        if case .failure(let reason) = securityResult {
            let resolution = DeepLinkResolution.invalid(reason: reason)
            analytics.trackDeepLink(url, resolution: resolution)
            return resolution
        }
        
        // Extract query parameters
        let queryParams = url.queryParameters
        
        // REFACTOR: Enhanced context creation with better source detection
        let source: DeepLinkContext.DeepLinkSource
        if queryParams["source"] == "push" {
            source = .pushNotification
        } else if queryParams["source"] == "email" {
            source = .webBrowser
        } else if queryParams["source"] == "qr" {
            source = .qrCode
        } else if queryParams["source"] == "nfc" {
            source = .nfc
        } else {
            source = .externalApp(bundleId: queryParams["bundle_id"] ?? "unknown")
        }
        
        lastResolutionContext = DeepLinkContext(
            source: source,
            referrer: queryParams["referrer"],
            campaign: queryParams["campaign"],
            queryParameters: queryParams
        )
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        // REFACTOR: Optimized pattern matching with early exit
        for registered in patterns {
            if let parameters = extractParameters(
                from: pathComponents,
                using: registered.pattern
            ) {
                if let route = registered.handler(parameters) {
                    let resolution = DeepLinkResolution.resolved(route)
                    
                    // REFACTOR: Analytics tracking
                    let duration = CFAbsoluteTimeGetCurrent() - startTime
                    analytics.trackDeepLink(url, resolution: resolution)
                    analytics.trackPerformance(url: url, duration: duration)
                    
                    return resolution
                }
            }
        }
        
        let resolution = DeepLinkResolution.invalid(reason: "Route not found")
        analytics.trackDeepLink(url, resolution: resolution)
        return resolution
    }
    
    /// Check if path components match pattern
    private func matches(pathComponents: [String], against pattern: CompiledPattern) -> Bool {
        return extractParameters(from: pathComponents, using: pattern) != nil
    }
    
    /// Extract parameters from path using pattern
    private func extractParameters(from pathComponents: [String], using pattern: CompiledPattern) -> [String: String]? {
        var parameters: [String: String] = [:]
        var pathIndex = 0
        var patternIndex = 0
        
        while patternIndex < pattern.segments.count && pathIndex < pathComponents.count {
            let segment = pattern.segments[patternIndex]
            
            switch segment.type {
            case .`static`(let value):
                if pathComponents[pathIndex] != value {
                    return nil // Static segment doesn't match
                }
                pathIndex += 1
                
            case .parameter(let name, let optional):
                if pathIndex < pathComponents.count {
                    parameters[name] = pathComponents[pathIndex]
                    pathIndex += 1
                } else if !optional {
                    return nil // Required parameter missing
                }
                
            case .wildcard(let greedy):
                if greedy {
                    // Greedy wildcard consumes all remaining segments
                    pathIndex = pathComponents.count
                } else {
                    // Single wildcard consumes one segment
                    pathIndex += 1
                }
            }
            
            patternIndex += 1
        }
        
        // Check if we've consumed all required segments
        while patternIndex < pattern.segments.count {
            let segment = pattern.segments[patternIndex]
            if case .parameter(_, let optional) = segment.type, !optional {
                return nil // Required parameter missing
            }
            patternIndex += 1
        }
        
        // Success if we've processed all pattern segments
        return patternIndex == pattern.segments.count ? parameters : nil
    }
}

// MARK: - Universal Link Handler

/// Handler for Apple Universal Links
public class UniversalLinkHandler {
    private let allowedDomains = ["myapp.com"]
    private let pathPrefix = "/app"
    
    public init() {}
    
    /// Handle universal link
    public func handleUniversalLink(_ url: URL) async -> Bool {
        guard validateUniversalLink(url) else {
            return false
        }
        
        // Strip path prefix and convert to internal URL
        var path = url.path
        if path.hasPrefix(pathPrefix) {
            path = String(path.dropFirst(pathPrefix.count))
        }
        
        let internalURL = URL(string: "axiom://\(path)")!
        
        // Process as regular deep link
        // This would integrate with the navigation service
        return true
    }
    
    /// Validate universal link
    private func validateUniversalLink(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return allowedDomains.contains(host)
    }
}

// MARK: - Custom Scheme Handler

/// Handler for custom URL schemes
public class CustomSchemeHandler {
    private var registeredSchemes: [String: (URL) -> DeepLinkResolution] = [:]
    
    public init() {}
    
    /// Register custom scheme
    public func registerScheme(_ scheme: String, handler: @escaping (URL) -> DeepLinkResolution) {
        registeredSchemes[scheme] = handler
    }
    
    /// Handle custom scheme URL
    public func handle(_ url: URL) -> DeepLinkResolution {
        guard let scheme = url.scheme,
              let handler = registeredSchemes[scheme] else {
            return .invalid(reason: "Unauthorized scheme")
        }
        
        return handler(url)
    }
}

// MARK: - Security Validation

/// Deep link security validation
public struct DeepLinkSecurity {
    private let allowedHosts = ["myapp.com", "localhost"]
    private let dangerousPatterns = ["<script>", "javascript:", "data:"]
    
    public init() {}
    
    /// Validate URL for security
    public func validateURL(_ url: URL) -> ValidationResult {
        // Check host whitelist for HTTPS URLs
        if url.scheme == "https" {
            guard let host = url.host, allowedHosts.contains(host) else {
                return .failure("Unauthorized host")
            }
        }
        
        // Check for dangerous parameters
        for (key, value) in url.queryParameters {
            if !isValidParameter(key: key, value: value) {
                return .failure("Invalid parameter: \(key)")
            }
        }
        
        return .success
    }
    
    /// Validate parameter safety
    private func isValidParameter(key: String, value: String) -> Bool {
        for pattern in dangerousPatterns {
            if value.lowercased().contains(pattern.lowercased()) {
                return false
            }
        }
        return true
    }
}

// MARK: - Deferred Deep Link Handler

/// Handler for deferred deep links
public class DeferredDeepLinkHandler {
    private var pendingLinks: [URL] = []
    
    public init() {}
    
    /// Store pending link
    public func storePendingLink(_ url: URL) {
        pendingLinks.append(url)
    }
    
    /// Process pending links
    public func processPendingLinks() async -> [any TypeSafeRoute] {
        let links = pendingLinks
        pendingLinks.removeAll()
        
        // Convert URLs to routes (simplified - would use actual pattern matching)
        return []
    }
    
    /// Clear pending links
    public func clearPendingLinks() {
        pendingLinks.removeAll()
    }
    
    /// Get pending links count
    public var pendingLinksCount: Int {
        return pendingLinks.count
    }
}

// MARK: - Testing Support

/// Deep link testing DSL
public class DeepLinkTester {
    private let handler: DeepLinkPatternHandler
    
    public init(handler: DeepLinkPatternHandler) {
        self.handler = handler
    }
    
    /// Test valid deep link
    public func test(_ urlString: String, validation: @escaping (any TypeSafeRoute) -> Void) async {
        guard let url = URL(string: urlString) else {
            #if canImport(XCTest)
            XCTFail("Invalid URL: \(urlString)")
            #endif
            return
        }
        
        let result = handler.resolve(url)
        if case .resolved(let route) = result {
            validation(route)
        } else {
            #if canImport(XCTest)
            XCTFail("Expected resolved route for \(urlString), got \(result)")
            #endif
        }
    }
    
    /// Test invalid deep link
    public func testInvalid(_ urlString: String, validation: @escaping (DeepLinkError) -> Void) async {
        guard let url = URL(string: urlString) else {
            #if canImport(XCTest)
            XCTFail("Invalid URL: \(urlString)")
            #endif
            return
        }
        
        let result = handler.resolve(url)
        if case .invalid = result {
            validation(.routeNotFound)
        } else {
            #if canImport(XCTest)
            XCTFail("Expected invalid result for \(urlString), got \(result)")
            #endif
        }
    }
}

// MARK: - Extensions

/// URL extension for query parameter extraction
extension URL {
    var queryParameters: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return [:]
        }
        
        var parameters: [String: String] = [:]
        for item in queryItems {
            parameters[item.name] = item.value ?? ""
        }
        return parameters
    }
}

// MARK: - Integration with Navigation Service

// Extension to be added to ModularNavigationService for deep linking integration
// This integration point is documented for the stabilizer