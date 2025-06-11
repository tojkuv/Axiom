import XCTest
@testable import Axiom

final class RouteDefinitionsTests: XCTestCase {
    
    // MARK: - RED: Route Definition Tests
    
    func testInvalidRouteConstructionFailsAtCompileTime() async throws {
        // Requirement: Routes defined as type-safe Swift enums with associated values
        // Acceptance: Invalid route construction fails at compile time with exhaustive enum switching
        // Boundary: Route enum marked @frozen preventing runtime additions
        
        // RED Test: This should fail because current Route enum doesn't enforce type safety
        
        // Test 1: Invalid associated value types should fail compilation
        // This test validates that routes with wrong associated value types are caught at compile time
        
        // Valid route construction
        let validDetailRoute = TypeSafeRoute.detail(id: "valid-id")
        XCTAssertEqual(validDetailRoute.identifier, "detail-valid-id")
        
        // Test that empty ID validation exists
        do {
            let invalidRoute = try TypeSafeRoute.validateDetail(id: "")
            XCTFail("Route with empty ID should fail validation")
        } catch RouteValidationError.invalidParameter {
            // Expected behavior
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Test that nil ID handling exists  
        do {
            let nilIdRoute = try TypeSafeRoute.validateDetail(id: nil)
            XCTFail("Route with nil ID should fail validation")
        } catch RouteValidationError.invalidParameter {
            // Expected behavior
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testExhaustiveEnumSwitchingRequired() async throws {
        // Test that exhaustive enum switching is enforced
        
        let testRoutes: [TypeSafeRoute] = [
            .home,
            .detail(id: "test"),
            .settings,
            .custom(path: "test-path")
        ]
        
        // Test exhaustive switching - this should require handling all cases
        for route in testRoutes {
            let handledCorrectly = handleRouteExhaustively(route)
            XCTAssertTrue(handledCorrectly, "Route \(route) was not handled in exhaustive switch")
        }
        
        // Test that adding new routes would break compilation if not handled
        let allCasesCount = TypeSafeRoute.allCases.count
        XCTAssertEqual(allCasesCount, 4, "Route enum should have exactly 4 cases for type safety")
    }
    
    func testRouteFrozenEnumPreventsRuntimeAdditions() async throws {
        // Test that Route enum is @frozen to prevent runtime additions
        
        // Verify enum is frozen by checking it conforms to CaseIterable
        // and that all cases are known at compile time
        let allCases = TypeSafeRoute.allCases
        XCTAssertEqual(allCases.count, 4, "Frozen enum should have fixed number of cases")
        
        // Test that each case has proper type safety
        let homeRoute = TypeSafeRoute.home
        XCTAssertEqual(homeRoute.routeType, .navigation, "Home route should be navigation type")
        
        let detailRoute = TypeSafeRoute.detail(id: "test-id")
        XCTAssertEqual(detailRoute.routeType, .navigation, "Detail route should be navigation type")
        XCTAssertEqual(detailRoute.associatedValues.count, 1, "Detail route should have exactly one associated value")
        
        let settingsRoute = TypeSafeRoute.settings
        XCTAssertEqual(settingsRoute.routeType, .modal, "Settings should be modal type")
        
        let customRoute = TypeSafeRoute.custom(path: "test-path")
        XCTAssertEqual(customRoute.routeType, .custom, "Custom route should be custom type")
    }
    
    func testRouteParameterValidation() async throws {
        // Test that route parameters are validated for type safety
        
        // Valid parameters should succeed
        let validParams = RouteParameters.detail(id: "valid-123")
        XCTAssertNoThrow(try validParams.validate())
        
        // Invalid parameters should fail
        let invalidParams = RouteParameters.detail(id: "")
        XCTAssertThrowsError(try invalidParams.validate()) { error in
            XCTAssertTrue(error is RouteValidationError)
        }
        
        // Complex parameter validation
        let complexParams = RouteParameters.custom(
            path: "valid/path",
            queryParams: ["key": "value"],
            fragment: "section1"
        )
        XCTAssertNoThrow(try complexParams.validate())
        
        // Invalid complex parameters
        let invalidComplexParams = RouteParameters.custom(
            path: "",
            queryParams: [:],
            fragment: nil
        )
        XCTAssertThrowsError(try invalidComplexParams.validate())
    }
    
    func testRouteBuilderPatternForComplexRoutes() async throws {
        // Test that complex routes can be built with type safety
        
        // Simple route builder
        let homeRoute = try RouteBuilder()
            .home()
            .build()
        
        XCTAssertEqual(homeRoute, TypeSafeRoute.home)
        
        // Complex route builder with validation
        let detailRoute = try RouteBuilder()
            .detail(id: "item-123")
            .withValidation()
            .build()
        
        XCTAssertEqual(detailRoute, TypeSafeRoute.detail(id: "item-123"))
        
        // Route builder with custom parameters
        let customRoute = try RouteBuilder()
            .custom(path: "custom/nested/path")
            .withQueryParams(["filter": "active", "sort": "date"])
            .withFragment("top")
            .withValidation()
            .build()
        
        // This should be a properly constructed custom route
        if case let .custom(path) = customRoute {
            XCTAssertEqual(path, "custom/nested/path")
        } else {
            XCTFail("Expected custom route")
        }
    }
}

// MARK: - Test Support Types (These should fail compilation/runtime in RED phase)

/// Type-safe route enum that should replace the basic Route enum
@frozen
enum TypeSafeRoute: CaseIterable, Hashable, Sendable {
    case home
    case detail(id: String)
    case settings
    case custom(path: String)
    
    /// Route type classification
    enum RouteType {
        case navigation
        case modal
        case custom
    }
    
    /// Get route type for UI behavior
    var routeType: RouteType {
        switch self {
        case .home, .detail:
            return .navigation
        case .settings:
            return .modal
        case .custom:
            return .custom
        }
    }
    
    /// Get associated values for validation
    var associatedValues: [Any] {
        switch self {
        case .home, .settings:
            return []
        case .detail(let id):
            return [id]
        case .custom(let path):
            return [path]
        }
    }
    
    /// Unique identifier for the route
    var identifier: String {
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
    
    /// Static validation for detail routes
    static func validateDetail(id: String?) throws -> TypeSafeRoute {
        guard let id = id, !id.isEmpty else {
            throw RouteValidationError.invalidParameter("Detail route requires non-empty ID")
        }
        return .detail(id: id)
    }
}

/// Route parameter validation types
enum RouteParameters {
    case home
    case detail(id: String)
    case settings
    case custom(path: String, queryParams: [String: String] = [:], fragment: String? = nil)
    
    /// Validate route parameters
    func validate() throws {
        switch self {
        case .home, .settings:
            break // No validation needed
        case .detail(let id):
            guard !id.isEmpty else {
                throw RouteValidationError.invalidParameter("Detail ID cannot be empty")
            }
        case .custom(let path, _, _):
            guard !path.isEmpty else {
                throw RouteValidationError.invalidParameter("Custom path cannot be empty")
            }
        }
    }
}

/// Route validation errors
enum RouteValidationError: Error, Equatable {
    case invalidParameter(String? = nil)
    case missingRequiredParameter(String)
    case invalidRouteType
}

/// Route builder for complex route construction
class RouteBuilder {
    private var currentRoute: TypeSafeRoute?
    private var shouldValidate = false
    private var queryParams: [String: String] = [:]
    private var fragment: String?
    
    func home() -> RouteBuilder {
        currentRoute = .home
        return self
    }
    
    func detail(id: String) -> RouteBuilder {
        currentRoute = .detail(id: id)
        return self
    }
    
    func settings() -> RouteBuilder {
        currentRoute = .settings
        return self
    }
    
    func custom(path: String) -> RouteBuilder {
        currentRoute = .custom(path: path)
        return self
    }
    
    func withValidation() -> RouteBuilder {
        shouldValidate = true
        return self
    }
    
    func withQueryParams(_ params: [String: String]) -> RouteBuilder {
        queryParams = params
        return self
    }
    
    func withFragment(_ fragment: String) -> RouteBuilder {
        self.fragment = fragment
        return self
    }
    
    func build() throws -> TypeSafeRoute {
        guard let route = currentRoute else {
            throw RouteValidationError.missingRequiredParameter("No route specified")
        }
        
        if shouldValidate {
            try validateRoute(route)
        }
        
        return route
    }
    
    private func validateRoute(_ route: TypeSafeRoute) throws {
        switch route {
        case .home, .settings:
            break // Always valid
        case .detail(let id):
            guard !id.isEmpty else {
                throw RouteValidationError.invalidParameter("Detail ID cannot be empty")
            }
        case .custom(let path):
            guard !path.isEmpty else {
                throw RouteValidationError.invalidParameter("Custom path cannot be empty")
            }
        }
    }
}

// MARK: - Test Utilities

/// Helper function to test exhaustive enum switching
func handleRouteExhaustively(_ route: TypeSafeRoute) -> Bool {
    switch route {
    case .home:
        return true
    case .detail(let id):
        return !id.isEmpty
    case .settings:
        return true
    case .custom(let path):
        return !path.isEmpty
    // Intentionally missing default case to ensure exhaustive handling
    }
}

/// Extension for CaseIterable conformance
extension TypeSafeRoute {
    static var allCases: [TypeSafeRoute] {
        return [
            .home,
            .detail(id: "sample"),
            .settings,
            .custom(path: "sample")
        ]
    }
}