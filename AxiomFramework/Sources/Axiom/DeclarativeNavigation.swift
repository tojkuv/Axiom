import Foundation
import SwiftUI

// MARK: - Route Definition

/// Type-safe route definition for declarative navigation
public struct RouteDefinition: Hashable, Codable, Sendable {
    public let path: String
    public let parameters: [String: String]
    public let validationRules: [RouteValidationRule]
    public let routeType: RouteType
    
    public enum RouteType: String, Codable, Sendable {
        case navigation
        case modal
        case custom
    }
    
    /// Create a route with a path
    public static func path(_ path: String) -> RouteDefinition {
        RouteDefinition(
            path: path,
            parameters: [:],
            validationRules: [],
            routeType: .navigation
        )
    }
    
    /// Create a detail route with ID parameter
    public static func detail(id: String) -> RouteDefinition {
        RouteDefinition(
            path: "/detail/:id",
            parameters: ["id": id],
            validationRules: [],
            routeType: .navigation
        )
    }
    
    /// Create a list route with optional filter
    public static func list(filter: String? = nil) -> RouteDefinition {
        var params: [String: String] = [:]
        if let filter = filter {
            params["filter"] = filter
        }
        
        return RouteDefinition(
            path: "/list",
            parameters: params,
            validationRules: [],
            routeType: .navigation
        )
    }
    
    /// Add validation to route
    public func withValidation(_ rule: @escaping () async -> Bool) -> RouteDefinition {
        var newRules = validationRules
        newRules.append(RouteValidationRule(validate: rule))
        
        return RouteDefinition(
            path: path,
            parameters: parameters,
            validationRules: newRules,
            routeType: routeType
        )
    }
    
    /// Validate the route
    public func validate() async -> Bool {
        for rule in validationRules {
            if !(await rule.validate()) {
                return false
            }
        }
        return true
    }
    
    /// Check if route is valid
    public var isValid: Bool {
        !path.isEmpty
    }
}

// MARK: - Route Validation Rule

/// Validation rule for routes
public struct RouteValidationRule: Codable, Hashable, Equatable, Sendable {
    private let id: UUID
    private let validateClosure: (@Sendable () async -> Bool)?
    
    init(validate: @escaping () async -> Bool) {
        self.id = UUID()
        self.validateClosure = validate
    }
    
    func validate() async -> Bool {
        await validateClosure?() ?? true
    }
    
    // Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance
    public static func == (lhs: RouteValidationRule, rhs: RouteValidationRule) -> Bool {
        lhs.id == rhs.id
    }
    
    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case id
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.validateClosure = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
    }
}

// MARK: - Route Property Wrapper

/// Property wrapper for declarative route definitions
@propertyWrapper
public struct RouteProperty<C: Context> {
    public let route: RouteDefinition
    public let contextType: C.Type
    private let validation: (() async -> Bool)?
    
    public init(_ route: RouteDefinition, validation: (() async -> Bool)? = nil) where C: Context {
        self.route = route
        self.contextType = C.self
        self.validation = validation
    }
    
    public var wrappedValue: C.Type {
        get { contextType }
        set { /* Read-only */ }
    }
    
    public var projectedValue: RouteProperty<C> {
        self
    }
}

// MARK: - Auto Navigation Service

/// Protocol for automatic navigation service generation
public protocol AutoNavigationService: NavigationService {
    /// Get all registered routes
    var registeredRoutes: [RouteDefinition] { get async }
    
    /// Validate if navigation is possible
    func canNavigate(to route: RouteDefinition) async -> Bool
    
    /// Handle deep link
    func handleDeepLink(_ url: URL) async throws -> any Context
}

// MARK: - Navigation Extensions

/// Extensions to simplify route creation
extension RouteDefinition {
    /// Common application routes
    public static let home = RouteDefinition.path("/home")
    public static let settings = RouteDefinition.path("/settings").withType(.modal)
    public static let admin = RouteDefinition.path("/admin")
    public static let product = RouteDefinition.path("/product/:id/:variant?")
    public static let category = RouteDefinition.path("/category/:name")
    
    /// Add route type
    public func withType(_ type: RouteType) -> RouteDefinition {
        RouteDefinition(
            path: path,
            parameters: parameters,
            validationRules: validationRules,
            routeType: type
        )
    }
}

// MARK: - Navigation Errors

/// Navigation-specific errors
public enum NavigationError: Error, LocalizedError {
    case unauthorized
    case routeNotFound
    case invalidParameters
    case validationFailed
    
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized navigation attempt"
        case .routeNotFound:
            return "Route not found"
        case .invalidParameters:
            return "Invalid route parameters"
        case .validationFailed:
            return "Route validation failed"
        }
    }
}

// MARK: - Macro Declaration

// NavigationOrchestrator macro is declared in Macros.swift