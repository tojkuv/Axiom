import XCTest
@testable import Axiom

final class TypeSafeRoutingTests: XCTestCase {
    
    // MARK: - Existing Route System Tests
    
    func testExistingTypeSafeRouteEnum() throws {
        // Test that existing routes work as expected
        let homeRoute = StandardRoute.home
        let detailRoute = StandardRoute.detail(id: "user123")
        let settingsRoute = StandardRoute.settings
        let customRoute = StandardRoute.custom(path: "/custom/path")
        
        // These should compile without error
        XCTAssertNotNil(homeRoute)
        XCTAssertNotNil(detailRoute)
        XCTAssertNotNil(settingsRoute)
        XCTAssertNotNil(customRoute)
        
        // Test identifiers
        XCTAssertEqual(homeRoute.routeIdentifier, "home")
        XCTAssertEqual(detailRoute.routeIdentifier, "detail-user123")
        XCTAssertEqual(settingsRoute.routeIdentifier, "settings")
        XCTAssertEqual(customRoute.routeIdentifier, "custom-/custom/path")
    }
    
    func testRoutePresentationStyles() throws {
        // Test that routes have appropriate presentation styles
        let homeRoute = StandardRoute.home
        let detailRoute = StandardRoute.detail(id: "123")
        let settingsRoute = StandardRoute.settings
        let customRoute = StandardRoute.custom(path: "/test")
        
        // Verify presentation styles
        if case .replace = homeRoute.presentation {
            // Expected
        } else {
            XCTFail("Home route should use replace presentation")
        }
        
        if case .push = detailRoute.presentation {
            // Expected
        } else {
            XCTFail("Detail route should use push presentation")
        }
        
        if case .present(.sheet) = settingsRoute.presentation {
            // Expected
        } else {
            XCTFail("Settings route should use sheet presentation")
        }
        
        if case .push = customRoute.presentation {
            // Expected
        } else {
            XCTFail("Custom route should use push presentation")
        }
    }
    
    // MARK: - Enhanced Protocol System Tests
    
    func testEnhancedTypeSerfeRouteProtocol() throws {
        // Test the new protocol-based system we're implementing
        
        // Define a test route that conforms to the enhanced protocol
        struct AppRoute: RoutableProtocol {
            enum RouteType {
                case profile(userId: String)
                case post(id: String, authorId: String? = nil)
                case search(query: String, filters: SearchFilters = .default)
            }
            
            let routeType: RouteType
            
            var pathComponents: String {
                switch routeType {
                case .profile(let userId):
                    return "/profile/\(userId)"
                case .post(let id, _):
                    return "/post/\(id)"
                case .search:
                    return "/search"
                }
            }
            
            var queryParameters: [String: String] {
                switch routeType {
                case .post(_, let authorId):
                    return authorId.map { ["authorId": $0] } ?? [:]
                case .search(let query, let filters):
                    return ["q": query] + filters.queryParameters
                default:
                    return [:]
                }
            }
            
            var presentation: PresentationStyle {
                switch routeType {
                case .profile, .post:
                    return .push
                case .search:
                    return .present(.sheet)
                }
            }
            
            static func profile(userId: String) -> AppRoute {
                AppRoute(routeType: .profile(userId: userId))
            }
            
            static func post(id: String, authorId: String? = nil) -> AppRoute {
                AppRoute(routeType: .post(id: id, authorId: authorId))
            }
            
            static func search(query: String, filters: SearchFilters = .default) -> AppRoute {
                AppRoute(routeType: .search(query: query, filters: filters))
            }
        }
        
        // Test route creation and path generation
        let profileRoute = AppRoute.profile(userId: "user123")
        XCTAssertEqual(profileRoute.pathComponents, "/profile/user123")
        XCTAssertTrue(profileRoute.queryParameters.isEmpty)
        
        let postRoute = AppRoute.post(id: "post456", authorId: "author789")
        XCTAssertEqual(postRoute.pathComponents, "/post/post456")
        XCTAssertEqual(postRoute.queryParameters["authorId"], "author789")
        
        let postWithoutAuthor = AppRoute.post(id: "post456")
        XCTAssertEqual(postWithoutAuthor.pathComponents, "/post/post456")
        XCTAssertTrue(postWithoutAuthor.queryParameters.isEmpty)
        
        let searchRoute = AppRoute.search(query: "swift")
        XCTAssertEqual(searchRoute.pathComponents, "/search")
        XCTAssertEqual(searchRoute.queryParameters["q"], "swift")
        XCTAssertEqual(searchRoute.queryParameters["category"], "all")
    }
    
    // MARK: - Route Matching Tests
    
    func testRouteMatching() throws {
        // Test URL to route matching (implementation to be added)
        let homeURL = URL(string: "https://app.com/")!
        let detailURL = URL(string: "https://app.com/detail/user123")!
        
        // For now, just test URL creation - matching implementation comes next
        XCTAssertNotNil(homeURL)
        XCTAssertNotNil(detailURL)
        XCTAssertEqual(detailURL.path, "/detail/user123")
    }
    
    // MARK: - Navigation Service Integration Tests
    
    func testNavigationServiceIntegration() async throws {
        // Test integration with existing NavigationService
        let navigationService = NavigationService()
        
        // Test with existing route types
        let result = await navigationService.navigate(to: StandardRoute.home)
        
        switch result {
        case .success:
            // Success expected
            XCTAssertNotNil(navigationService.currentRoute)
        case .failure(let error):
            XCTFail("Navigation should succeed: \(error)")
        }
        
        // Test current route is set correctly
        XCTAssertEqual(navigationService.currentRoute?.identifier, "home")
    }
    
    // MARK: - Compile-time Safety Tests
    
    func testCompileTimeSafety() throws {
        // Test that required parameters must be provided
        struct TestRoute: RoutableProtocol {
            enum RouteType {
                case profile(userId: String)  // Required parameter
                case settings(section: String? = nil)  // Optional parameter
            }
            
            let routeType: RouteType
            
            var pathComponents: String {
                switch routeType {
                case .profile(let userId):
                    return "/profile/\(userId)"
                case .settings:
                    return "/settings"
                }
            }
            
            var queryParameters: [String: String] {
                switch routeType {
                case .settings(let section):
                    return section.map { ["section": $0] } ?? [:]
                default:
                    return [:]
                }
            }
            
            var presentation: PresentationStyle {
                return .push
            }
            
            static func profile(userId: String) -> TestRoute {
                TestRoute(routeType: .profile(userId: userId))
            }
            
            static func settings(section: String? = nil) -> TestRoute {
                TestRoute(routeType: .settings(section: section))
            }
        }
        
        // Required parameter must be provided
        let profileRoute = TestRoute.profile(userId: "required123")
        XCTAssertEqual(profileRoute.pathComponents, "/profile/required123")
        
        // Optional parameters work with defaults
        let settingsDefault = TestRoute.settings()
        let settingsSpecific = TestRoute.settings(section: "privacy")
        
        XCTAssertEqual(settingsDefault.pathComponents, "/settings")
        XCTAssertTrue(settingsDefault.queryParameters.isEmpty)
        
        XCTAssertEqual(settingsSpecific.pathComponents, "/settings")
        XCTAssertEqual(settingsSpecific.queryParameters["section"], "privacy")
        
        // Note: TestRoute.profile() without userId would not compile - this is the desired behavior
    }
}

// MARK: - Enhanced Protocol Definitions

/// Enhanced protocol for type-safe routing
protocol RoutableProtocol {
    var pathComponents: String { get }
    var queryParameters: [String: String] { get }
    var presentation: PresentationStyle { get }
}

// MARK: - Supporting Types for Tests

struct SearchFilters {
    let category: String
    
    static let `default` = SearchFilters(category: "all")
    
    var queryParameters: [String: String] {
        return ["category": category]
    }
}

extension Dictionary where Key == String, Value == String {
    static func + (lhs: [String: String], rhs: [String: String]) -> [String: String] {
        return lhs.merging(rhs) { _, new in new }
    }
}