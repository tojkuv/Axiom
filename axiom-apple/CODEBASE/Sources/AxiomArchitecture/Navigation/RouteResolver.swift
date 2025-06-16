import Foundation
import AxiomCore
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Route Resolver Protocol

/// Protocol for resolving routes to their corresponding implementations
public protocol RouteResolving: Actor {
    func validate<R: AxiomTypeSafeRoute>(_ route: R) async throws
    func register<R: AxiomTypeSafeRoute>(
        route: R.Type,
        factory: @escaping @Sendable (R) async throws -> Any
    ) async
    func resolve<R: AxiomTypeSafeRoute>(route: R) async throws -> Any
}

// MARK: - Route Factory Types

/// Type-erased route factory
private struct RouteFactory {
    let pattern: String
    let factory: @Sendable (Any) async throws -> Any
    let routeType: Any.Type
    let isSwiftUICompatible: Bool
    
    init<R: AxiomTypeSafeRoute>(
        pattern: String,
        routeType: R.Type,
        isSwiftUICompatible: Bool = true,
        factory: @escaping @Sendable (R) async throws -> Any
    ) {
        self.pattern = pattern
        self.routeType = routeType
        self.isSwiftUICompatible = isSwiftUICompatible
        self.factory = { data in
            guard let typedData = data as? R else {
                throw AxiomError.navigationError(.invalidRoute("Invalid route data type"))
            }
            return try await factory(typedData)
        }
    }
}

// MARK: - Permission Protocols

/// Protocol for routes that require permission checks
public protocol PermissionProtectedRoute: AxiomTypeSafeRoute {
    var requiredPermissions: Set<String> { get }
}

/// Permission validator protocol
public protocol PermissionValidator: Actor {
    func validatePermissions(for route: any PermissionProtectedRoute) async throws
}

// MARK: - Route Resolver Implementation

/// Actor that resolves routes to their corresponding view controllers or views
public actor RouteResolver: RouteResolving {
    
    // MARK: - State
    
    private var routeRegistry: [String: RouteFactory] = [:]
    private var permissionValidator: (any PermissionValidator)?
    private let routeValidator: RouteValidator
    
    // MARK: - Initialization
    
    public init(permissionValidator: (any PermissionValidator)? = nil) {
        self.permissionValidator = permissionValidator
        self.routeValidator = RouteValidator()
        
        Task {
            await registerDefaultRoutes()
        }
    }
    
    // MARK: - RouteResolving Implementation
    
    public func validate<R: AxiomTypeSafeRoute>(_ route: R) async throws {
        // Check if route is registered
        let routePattern = String(describing: type(of: route))
        guard routeRegistry[routePattern] != nil else {
            throw AxiomError.navigationError(.routeNotFound(routePattern))
        }
        
        // Validate route parameters using the route validator
        let routeDefinition = RouteDefinition(
            identifier: route.routeIdentifier,
            path: route.pathComponents,
            parameters: [], // Extract from route if needed
            presentation: route.presentation
        )
        
        do {
            try routeValidator.addRoute(routeDefinition)
        } catch {
            throw AxiomError.navigationError(.navigationFailed(error.localizedDescription))
        }
        
        // Validate permissions if route requires them
        if let permissionRoute = route as? (any PermissionProtectedRoute) {
            try await validatePermissions(for: permissionRoute)
        }
    }
    
    public func register<R: AxiomTypeSafeRoute>(
        route: R.Type,
        factory: @escaping @Sendable (R) async throws -> Any
    ) async {
        let pattern = String(describing: route)
        let routeFactory = RouteFactory(
            pattern: pattern,
            routeType: route,
            factory: factory
        )
        
        routeRegistry[pattern] = routeFactory
    }
    
    public func resolve<R: AxiomTypeSafeRoute>(route: R) async throws -> Any {
        let pattern = String(describing: type(of: route))
        
        guard let factory = routeRegistry[pattern] else {
            throw AxiomError.navigationError(.routeNotFound(pattern))
        }
        
        return try await factory.factory(route)
    }
    
    // MARK: - Permission Validation
    
    private func validatePermissions(for route: any PermissionProtectedRoute) async throws {
        guard let validator = permissionValidator else {
            // If no permission validator is set, assume permissions are granted
            return
        }
        
        try await validator.validatePermissions(for: route)
    }
    
    // MARK: - Route Information
    
    public func isSwiftUICompatible<R: AxiomTypeSafeRoute>(_ route: R) async -> Bool {
        let pattern = String(describing: type(of: route))
        return routeRegistry[pattern]?.isSwiftUICompatible ?? false
    }
    
    public func getRegisteredRoutes() async -> [String] {
        return Array(routeRegistry.keys)
    }
    
    // MARK: - Default Route Registration
    
    private func registerDefaultRoutes() async {
        // Register framework-provided routes
        await register(route: AxiomStandardRoute.self) { route in
            return await self.resolveStandardRoute(route)
        }
    }
    
    private func resolveStandardRoute(_ route: AxiomStandardRoute) async -> any Sendable {
        switch route {
        case .home:
            return "HomeView" // Placeholder - would return actual view/controller
        case .detail(let id):
            return "DetailView(id: \(id))" // Placeholder
        case .settings:
            return "SettingsView" // Placeholder
        case .custom(let path):
            return "CustomView(path: \(path))" // Placeholder
        }
    }
}

// MARK: - Default Permission Validator

/// Default permission validator that always grants access
public actor DefaultPermissionValidator: PermissionValidator {
    public init() {}
    
    public func validatePermissions(for route: any PermissionProtectedRoute) async throws {
        // Default implementation - grants all permissions
        // In a real app, this would check actual permissions
        for permission in route.requiredPermissions {
            // Log permission check
            print("Checking permission: \(permission)")
        }
    }
}

// MARK: - Route Registration DSL

/// Declarative route registration builder
public struct RouteRegistration {
    private let resolver: RouteResolver
    
    public init(resolver: RouteResolver) {
        self.resolver = resolver
    }
    
    /// Register a SwiftUI view route
    public func view<R: AxiomTypeSafeRoute, V: View & Sendable>(
        _ routeType: R.Type,
        @ViewBuilder builder: @escaping @Sendable (R) -> V
    ) async {
        await resolver.register(route: routeType) { route in
            return builder(route)
        }
    }
    
    #if canImport(UIKit)
    /// Register a UIKit view controller route
    public func viewController<R: AxiomTypeSafeRoute, VC: UIViewController>(
        _ routeType: R.Type,
        factory: @escaping @Sendable (R) async throws -> VC
    ) async {
        await resolver.register(route: routeType, factory: factory)
    }
    #endif
    
    /// Register a data route (for non-UI navigation)
    public func data<R: AxiomTypeSafeRoute, T>(
        _ routeType: R.Type,
        factory: @escaping @Sendable (R) async throws -> T
    ) async {
        await resolver.register(route: routeType, factory: factory)
    }
}

// MARK: - Convenience Extensions

public extension RouteResolver {
    /// Configure routes using the registration DSL
    func configureRoutes(_ configuration: (RouteRegistration) async -> Void) async {
        let registration = RouteRegistration(resolver: self)
        await configuration(registration)
    }
}

// MARK: - Route Validation Extensions

extension RouteResolver {
    /// Validate multiple routes in batch
    public func validateBatch<S: Sequence>(_ routes: S) async throws where S.Element: AxiomTypeSafeRoute {
        for route in routes {
            try await validate(route)
        }
    }
    
    /// Check if a route pattern is registered
    public func isRegistered<R: AxiomTypeSafeRoute>(_ routeType: R.Type) async -> Bool {
        let pattern = String(describing: routeType)
        return routeRegistry[pattern] != nil
    }
}

// MARK: - Example Route Definitions

/// Example of a permission-protected route
public struct ProfileRoute: AxiomTypeSafeRoute, PermissionProtectedRoute {
    public let userId: String
    
    public var pathComponents: String {
        return "/profile/\(userId)"
    }
    
    public var queryParameters: [String: String] {
        return [:]
    }
    
    public var routeIdentifier: String {
        return "profile-\(userId)"
    }
    
    public var requiredPermissions: Set<String> {
        return ["user.profile.read"]
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
    }
    
    public static func == (lhs: ProfileRoute, rhs: ProfileRoute) -> Bool {
        return lhs.userId == rhs.userId
    }
}

/// Example of a simple route
public struct HomeRoute: AxiomTypeSafeRoute {
    public var pathComponents: String {
        return "/"
    }
    
    public var queryParameters: [String: String] {
        return [:]
    }
    
    public var routeIdentifier: String {
        return "home"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine("home")
    }
    
    public static func == (lhs: HomeRoute, rhs: HomeRoute) -> Bool {
        return true
    }
}

/// Example of a parameterized route
public struct DetailRoute: AxiomTypeSafeRoute {
    public let itemId: String
    public let section: String?
    
    public var pathComponents: String {
        return "/detail/\(itemId)"
    }
    
    public var queryParameters: [String: String] {
        var params: [String: String] = [:]
        if let section = section {
            params["section"] = section
        }
        return params
    }
    
    public var routeIdentifier: String {
        return "detail-\(itemId)" + (section.map { "-\($0)" } ?? "")
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(itemId)
        hasher.combine(section)
    }
    
    public static func == (lhs: DetailRoute, rhs: DetailRoute) -> Bool {
        return lhs.itemId == rhs.itemId && lhs.section == rhs.section
    }
}

/// Example of a settings route
public struct SettingsRoute: AxiomTypeSafeRoute {
    public let section: String?
    
    public var pathComponents: String {
        if let section = section {
            return "/settings/\(section)"
        }
        return "/settings"
    }
    
    public var queryParameters: [String: String] {
        return [:]
    }
    
    public var routeIdentifier: String {
        return "settings" + (section.map { "-\($0)" } ?? "")
    }
    
    public var presentation: PresentationStyle {
        return .present(.sheet)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(section)
    }
    
    public static func == (lhs: SettingsRoute, rhs: SettingsRoute) -> Bool {
        return lhs.section == rhs.section
    }
}