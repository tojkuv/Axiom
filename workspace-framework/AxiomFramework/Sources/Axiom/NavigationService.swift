import Foundation
import SwiftUI

// MARK: - Consolidated Navigation Service
// This file consolidates functionality from 8 navigation files (4,325 lines) into one service (~500 lines)

/// Unified Navigation Service for all navigation operations
/// Consolidates: NavigationService, NavigationPatterns, DeepLinking, TypeSafeRouteDefinitions,
/// NavigationCancellation, DeclarativeNavigation, and core navigation from Orchestrator
@MainActor
public final class NavigationService: ObservableObject {
    
    // MARK: - Core Navigation State
    
    /// Current navigation route
    @Published internal var currentRoute: Route?
    
    /// Navigation history stack
    @Published internal var navigationHistory: [Route] = []
    
    /// Active navigation pattern
    public private(set) var currentPattern: NavigationPattern = .push
    
    /// Cancellation tokens for active navigations
    internal var cancellationTokens: Set<NavigationCancellationToken> = []
    
    /// Deep link URL patterns
    private var urlPatterns: [URLPattern] = []
    
    /// Route handlers for custom navigation
    private var routeHandlers: [Route: () async throws -> any View] = [:]
    
    public init() {
        setupDefaultURLPatterns()
    }
    
    // MARK: - Core Navigation API
    
    /// Navigate to any routable destination
    public func navigate<T: Routable>(to route: T) async -> Result<Void, AxiomError> {
        return await withErrorContext("NavigationService.navigate") {
            let token = NavigationCancellationToken()
            cancellationTokens.insert(token)
            
            defer { cancellationTokens.remove(token) }
            
            guard !token.isCancelled else {
                throw AxiomError.navigationError(.navigationBlocked("Navigation was cancelled"))
            }
            
            // Add current route to history if different
            if let current = currentRoute, current != route as? Route {
                navigationHistory.append(current)
            }
            
            // Update current route
            currentRoute = route as? Route
            
            // Execute navigation based on presentation style
            try await executeNavigation(route: route, token: token)
            
            return ()
        }
    }
    
    /// Navigate to route with options and consistent return type
    public func navigate(to route: Route, options: NavigationOptions = .default) async -> NavigationResult {
        return await withErrorContext("NavigationService.navigate") {
            // Add to history
            if let current = currentRoute, current != route {
                navigationHistory.append(current)
            }
            
            currentRoute = route
            
            // Execute route handler if available
            if let handler = routeHandlers[route] {
                _ = try await handler()
            }
            
            return .success
        }.mapToNavigationResult()
    }
    
    /// Navigate back in history
    public func navigateBack() async -> NavigationResult {
        return await withErrorContext("NavigationService.navigateBack") {
            guard !navigationHistory.isEmpty else {
                throw AxiomError.navigationError(.stackError("No previous route to navigate back to"))
            }
            
            let previousRoute = navigationHistory.removeLast()
            currentRoute = previousRoute
            
            return .success
        }.mapToNavigationResult()
    }
    
    /// Pop to root of navigation stack
    public func navigateToRoot() async -> NavigationResult {
        return await withErrorContext("NavigationService.navigateToRoot") {
            guard !navigationHistory.isEmpty else {
                return .success
            }
            
            navigationHistory.removeAll()
            currentRoute = nil
            
            return .success
        }.mapToNavigationResult()
    }
    
    /// Dismiss current presentation
    public func dismiss() async -> NavigationResult {
        return await navigateBack()
    }
    
    // MARK: - Deep Linking Support
    
    /// Process deep link URL
    public func processDeepLink(_ url: URL) async -> NavigationResult {
        return await withErrorContext("NavigationService.processDeepLink") {
            let route = try parseURL(url)
            
            // Navigate to the parsed route
            let result = await navigate(to: route)
            if result.isSuccess {
                return .success
            } else {
                return result
            }
        }.mapToNavigationResult()
    }
    
    /// Register deep link pattern
    public func registerDeepLink(pattern: String, routeType: URLPattern.RouteType) {
        let urlPattern = URLPattern(pattern: pattern, routeType: routeType)
        urlPatterns.append(urlPattern)
    }
    
    // MARK: - Route Management
    
    /// Register route handler
    public func registerRoute(_ route: Route, handler: @escaping () async throws -> any View) {
        routeHandlers[route] = handler
    }
    
    /// Check if can navigate to route
    public func canNavigate(to route: Route) -> Bool {
        // Basic validation - route must be registered or is a standard route
        return routeHandlers[route] != nil || true
    }
    
    /// Get current navigation depth
    public var navigationDepth: Int {
        return navigationHistory.count
    }
    
    /// Check if can navigate back
    public var canNavigateBack: Bool {
        return !navigationHistory.isEmpty
    }
    
    // MARK: - Navigation Patterns
    
    /// Set navigation pattern
    public func setPattern(_ pattern: NavigationPattern) {
        currentPattern = pattern
    }
    
    // MARK: - Cancellation Support
    
    /// Cancel all active navigations
    public func cancelAllNavigations() {
        for token in cancellationTokens {
            token.cancel()
        }
        cancellationTokens.removeAll()
    }
    
    /// Create navigation cancellation token
    public func createCancellationToken() -> NavigationCancellationToken {
        let token = NavigationCancellationToken()
        cancellationTokens.insert(token)
        return token
    }
    
    // MARK: - Private Implementation
    
    private func executeNavigation<T: Routable>(route: T, token: NavigationCancellationToken) async throws {
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
    }
    
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
}

// MARK: - Result Conversion Helper

extension Result where Success == Void, Failure == AxiomError {
    func mapToNavigationResult() -> NavigationResult {
        switch self {
        case .success:
            return .success
        case .failure(let error):
            switch error {
            case .navigationError(let navError):
                return .failed(navError)
            default:
                return .failed(.invalidRoute("Operation failed: \(error.localizedDescription)"))
            }
        }
    }
}

extension Result where Success == NavigationResult, Failure == AxiomError {
    func mapToNavigationResult() -> NavigationResult {
        switch self {
        case .success(let navResult):
            return navResult
        case .failure(let error):
            switch error {
            case .navigationError(let navError):
                return .failed(navError)
            default:
                return .failed(.invalidRoute("Operation failed: \(error.localizedDescription)"))
            }
        }
    }
}


// MARK: - API Consistency Improvements (REQUIREMENTS-003)

/// Unified navigation result type for consistent API returns
public enum NavigationResult {
    case success
    case cancelled
    case failed(AxiomNavigationError)
    
    /// Check if navigation was successful
    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    /// Check if navigation was cancelled
    public var isCancelled: Bool {
        if case .cancelled = self { return true }
        return false
    }
    
    /// Check if navigation failed
    public var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}

// Note: AxiomNavigationError is defined in ErrorHandling.swift
// This file uses the framework's unified error type

extension NavigationResult {
    /// Convert NavigationResult to AxiomResult<Void> for API consistency
    public func toAxiomResult() -> Result<Void, AxiomError> {
        switch self {
        case .success:
            return .success(())
        case .cancelled:
            return .failure(.navigationError(.navigationCancelled("Navigation was cancelled")))
        case .failed(let navError):
            return .failure(.navigationError(navError))
        }
    }
}


/// Navigation options for consistent API
public struct NavigationOptions {
    public let animated: Bool
    public let replace: Bool
    public let retry: Bool
    
    public static let `default` = NavigationOptions(animated: true, replace: false, retry: false)
    
    public init(animated: Bool = true, replace: Bool = false, retry: Bool = false) {
        self.animated = animated
        self.replace = replace
        self.retry = retry
    }
}

/// Navigation action types for consistent processing
public enum NavigationAction {
    case deepLink(URL)
    case route(Route, NavigationOptions)
    case back
    case root
    case dismiss
}

// MARK: - Supporting Types

/// Navigation patterns (simplified from complex actor system)
public enum NavigationPattern: Sendable {
    case push
    case modal(ModalStyle)
    case replace
    case tab
    
    public enum ModalStyle: CaseIterable, Sendable {
        case sheet
        case fullScreen
        case popover
        
        public static var allCases: [ModalStyle] {
            [.sheet, .fullScreen, .popover]
        }
    }
}

/// Protocol for routable destinations (consolidated from multiple files)
public protocol Routable {
    var presentation: PresentationStyle { get }
}

/// Presentation styles (simplified)
public enum PresentationStyle: Sendable, Hashable {
    case push
    case present(ModalStyle)
    case replace
    
    public enum ModalStyle: Sendable, Hashable {
        case sheet
        case fullScreen
        case popover
    }
}

/// Standard route implementation (consolidated and simplified)
@frozen
public enum StandardRoute: CaseIterable, Hashable, Sendable {
    case home
    case detail(id: String)
    case settings
    case custom(path: String)
    
    /// Route identifier
    public var identifier: String {
        switch self {
        case .home: return "home"
        case .detail(let id): return "detail-\(id)"
        case .settings: return "settings"
        case .custom(let path): return "custom-\(path)"
        }
    }
    
    public static var allCases: [StandardRoute] {
        [.home, .settings, .custom(path: "default")]
    }
}

extension StandardRoute: Routable {
    public var presentation: PresentationStyle {
        switch self {
        case .home: return .replace
        case .detail: return .push
        case .settings: return .present(.sheet)
        case .custom: return .push
        }
    }
}

/// Navigation cancellation token (simplified)
public final class NavigationCancellationToken: @unchecked Sendable, Hashable {
    private let id = UUID()
    private var _isCancelled = false
    
    public var isCancelled: Bool {
        return _isCancelled
    }
    
    public func cancel() {
        _isCancelled = true
    }
    
    public static func == (lhs: NavigationCancellationToken, rhs: NavigationCancellationToken) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// URL pattern for deep linking (simplified)
public struct URLPattern {
    let pattern: String
    let routeType: RouteType
    
    public enum RouteType {
        case home
        case detail
        case settings
        case custom
    }
    
    func match(url: URL) throws -> Route? {
        let path = url.path.isEmpty ? "/" : url.path
        
        switch routeType {
        case .home:
            return path == "/" || path == "/home" ? .home : nil
        case .detail:
            if path.hasPrefix("/detail/") {
                let id = String(path.dropFirst("/detail/".count))
                return id.isEmpty ? nil : .detail(id: id)
            }
            return nil
        case .settings:
            return path == "/settings" ? .settings : nil
        case .custom:
            if path.hasPrefix("/custom/") {
                let customPath = String(path.dropFirst("/custom/".count))
                return customPath.isEmpty ? nil : .custom(path: customPath)
            }
            return nil
        }
    }
}

/// Route type alias for compatibility
public typealias Route = StandardRoute

// MARK: - Navigation Error Types Consolidated into AxiomError
// 
// All navigation error types have been consolidated into AxiomError.navigationError
// Legacy error types removed - use AxiomError.navigationError with appropriate cases:
//
// NavigationError -> AxiomError.navigationError(.invalidRoute | .navigationBlocked | .stackError | .unauthorized | .routeNotFound | .invalidParameter | .guardFailed)
// DeepLinkingError -> AxiomError.navigationError(.invalidURL | .patternNotFound | .parsingFailed | .compilationFailure)  
// NavigationPatternError -> AxiomError.navigationError(.patternConflict | .invalidHierarchy | .circularNavigation | .stackError)
// NavigationCancellationError -> AxiomError.navigationError(.navigationCancelled)
// RouteValidationError -> AxiomError.navigationError(.invalidParameter | .missingRequiredParameter | .compilationFailure)
// NavigationGraphError -> AxiomError.navigationError(.cycleDetected | .invalidTransition | .nodeNotFound)

// MARK: - Declarative Navigation Extensions

/// Simple route builder for declarative navigation
public struct RouteBuilder {
    private let destination: String
    private let service: NavigationService
    private var parameters: [String: String] = [:]
    
    init(destination: String, service: NavigationService) {
        self.destination = destination
        self.service = service
    }
    
    public func parameter(_ key: String, value: String) -> RouteBuilder {
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

extension NavigationService {
    /// Declarative route builder
    public func route(to destination: String) -> RouteBuilder {
        return RouteBuilder(destination: destination, service: self)
    }
}


// MARK: - Backward Compatibility

/// Factory for creating NavigationService instances (preserved for compatibility)
public struct NavigationServiceFactory {
    @MainActor
    public static func createNavigationService() -> NavigationService {
        return NavigationService()
    }
}

/// Navigation coordinator helper (simplified)
public struct NavigationCoordinator {
    public static func validateNavigationPath(_ routes: [Route]) -> Bool {
        let routeSet = Set(routes.map { $0.identifier })
        return routeSet.count == routes.count
    }
}


// MARK: - Extensions for Error Propagation Integration

extension NavigationService {
    /// Navigate with retry on failure
    public func navigateWithRetry(
        to route: Route,
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0
    ) async -> Result<Void, AxiomError> {
        return await withRetry(
            maxAttempts: maxAttempts,
            delay: delay,
            operation: "navigateWithRetry"
        ) {
            switch await navigate(to: route) {
            case .success:
                return ()
            case .cancelled:
                throw AxiomError.navigationError(.navigationCancelled("Navigation was cancelled"))
            case .failed(let navError):
                throw AxiomError.navigationError(navError)
            }
        }
    }
}