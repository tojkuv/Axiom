import XCTest
@testable import Axiom

final class EnhancedTypeSafeRoutingTests: XCTestCase {
    
    // MARK: - RED Phase Tests for Enhanced TypeSafeRoute Protocol
    
    func testEnhancedTypeSafeRouteWithCompileTimeSafety() throws {
        // Test enhanced route enum with associated values and compile-time safety
        enum AppRoute: AxiomTypeSafeRoute {
            case profile(userId: String)
            case post(id: String, authorId: String? = nil)
            case search(query: String, filters: SearchFilters = .default)
            case settings(section: SettingsSection = .general)
            
            var pathComponents: String {
                switch self {
                case .profile(let userId):
                    return "/profile/\(userId)"
                case .post(let id, _):
                    return "/post/\(id)"
                case .search:
                    return "/search"
                case .settings:
                    return "/settings"
                }
            }
            
            var queryParameters: [String: String] {
                switch self {
                case .post(_, let authorId):
                    return authorId.map { ["authorId": $0] } ?? [:]
                case .search(let query, let filters):
                    return ["q": query] + filters.asQueryParameters()
                case .settings(let section):
                    return ["section": section.rawValue]
                default:
                    return [:]
                }
            }
            
            var routeIdentifier: String {
                switch self {
                case .profile(let userId):
                    return "profile-\(userId)"
                case .post(let id, let authorId):
                    return "post-\(id)-\(authorId ?? "nil")"
                case .search(let query, _):
                    return "search-\(query)"
                case .settings(let section):
                    return "settings-\(section.rawValue)"
                }
            }
        }
        
        // These should compile and work correctly
        let profileRoute = AppRoute.profile(userId: "user123")
        XCTAssertEqual(profileRoute.pathComponents, "/profile/user123")
        XCTAssertEqual(profileRoute.routeIdentifier, "profile-user123")
        XCTAssertTrue(profileRoute.queryParameters.isEmpty)
        
        // Test with optional parameters
        let postRoute = AppRoute.post(id: "post456")
        XCTAssertEqual(postRoute.pathComponents, "/post/post456")
        XCTAssertTrue(postRoute.queryParameters.isEmpty)
        
        let postWithAuthor = AppRoute.post(id: "post456", authorId: "author789")
        XCTAssertEqual(postWithAuthor.pathComponents, "/post/post456")
        XCTAssertEqual(postWithAuthor.queryParameters["authorId"], "author789")
        
        // Test with complex default parameters
        let searchRoute = AppRoute.search(query: "swift")
        XCTAssertEqual(searchRoute.pathComponents, "/search")
        XCTAssertEqual(searchRoute.queryParameters["q"], "swift")
        XCTAssertEqual(searchRoute.queryParameters["category"], "all")
        
        let settingsRoute = AppRoute.settings()
        XCTAssertEqual(settingsRoute.pathComponents, "/settings")
        XCTAssertEqual(settingsRoute.queryParameters["section"], "general")
    }
    
    func testRouteBuilderDSLPattern() throws {
        // Test declarative route building pattern
        enum TestRoute: AxiomTypeSafeRoute {
            case detail(id: String, tab: String? = nil)
            
            var pathComponents: String {
                switch self {
                case .detail(let id, _):
                    return "/detail/\(id)"
                }
            }
            
            var queryParameters: [String: String] {
                switch self {
                case .detail(_, let tab):
                    return tab.map { ["tab": $0] } ?? [:]
                }
            }
            
            var routeIdentifier: String {
                switch self {
                case .detail(let id, let tab):
                    return "detail-\(id)-\(tab ?? "nil")"
                }
            }
        }
        
        // Test route builder pattern
        let routeBuilder = AxiomTypeSafeRouteBuilder<TestRoute>()
        
        // This should be possible with the enhanced system
        let route = routeBuilder
            .route(.detail(id: "123"))
            .withQueryParameter("tab", value: "posts")
            .build()
        
        XCTAssertEqual(route.pathComponents, "/detail/123")
        XCTAssertEqual(route.queryParameters["tab"], "posts")
    }
    
    func testRouteMatchingWithEnhancedProtocol() throws {
        // Test advanced route matching with the enhanced protocol
        enum NavigationRoute: AxiomTypeSafeRoute {
            case profile(userId: String)
            case settings(section: String? = nil)
            
            var pathComponents: String {
                switch self {
                case .profile(let userId):
                    return "/profile/\(userId)"
                case .settings:
                    return "/settings"
                }
            }
            
            var queryParameters: [String: String] {
                switch self {
                case .settings(let section):
                    return section.map { ["section": $0] } ?? [:]
                default:
                    return [:]
                }
            }
            
            var routeIdentifier: String {
                switch self {
                case .profile(let userId):
                    return "profile-\(userId)"
                case .settings(let section):
                    return "settings-\(section ?? "default")"
                }
            }
        }
        
        let matcher = RouteMatcher<NavigationRoute>()
        
        // Register route patterns
        matcher.register(pattern: "/profile/:userId") { params in
            guard let userId = params["userId"] else { return nil }
            return NavigationRoute.profile(userId: userId)
        }
        
        matcher.register(pattern: "/settings") { params in
            let section = params["section"]
            return NavigationRoute.settings(section: section)
        }
        
        // Test matching
        let profileMatch = matcher.match(path: "/profile/user123")
        XCTAssertNotNil(profileMatch)
        if case .profile(let userId) = profileMatch {
            XCTAssertEqual(userId, "user123")
        } else {
            XCTFail("Expected profile route")
        }
        
        let settingsMatch = matcher.match(path: "/settings")
        XCTAssertNotNil(settingsMatch)
        if case .settings(let section) = settingsMatch {
            XCTAssertNil(section)
        } else {
            XCTFail("Expected settings route")
        }
    }
    
    func testNavigationServiceIntegrationWithEnhancedRoutes() async throws {
        // Test integration with NavigationService using enhanced routes
        enum AppRoute: AxiomTypeSafeRoute {
            case home
            case profile(userId: String)
            
            var pathComponents: String {
                switch self {
                case .home:
                    return "/"
                case .profile(let userId):
                    return "/profile/\(userId)"
                }
            }
            
            var queryParameters: [String: String] {
                return [:]
            }
            
            var routeIdentifier: String {
                switch self {
                case .home:
                    return "home"
                case .profile(let userId):
                    return "profile-\(userId)"
                }
            }
        }
        
        let navigationService = NavigationService()
        
        // Test navigation to enhanced route
        let result = await navigationService.navigate(to: AppRoute.profile(userId: "test123"))
        
        switch result {
        case .success:
            XCTAssertNotNil(navigationService.currentRoute)
        case .failure(let error):
            XCTFail("Navigation should succeed: \(error)")
        }
    }
    
    func testCompileTimeSafetyEnforcement() throws {
        // Test that compile-time safety is enforced
        enum StrictRoute: AxiomTypeSafeRoute {
            case profile(userId: String)  // Required parameter
            case post(id: String, authorId: String? = nil)  // Optional parameter
            
            var pathComponents: String {
                switch self {
                case .profile(let userId):
                    return "/profile/\(userId)"
                case .post(let id, _):
                    return "/post/\(id)"
                }
            }
            
            var queryParameters: [String: String] {
                switch self {
                case .post(_, let authorId):
                    return authorId.map { ["authorId": $0] } ?? [:]
                default:
                    return [:]
                }
            }
            
            var routeIdentifier: String {
                switch self {
                case .profile(let userId):
                    return "profile-\(userId)"
                case .post(let id, let authorId):
                    return "post-\(id)-\(authorId ?? "nil")"
                }
            }
        }
        
        // Required parameter must be provided (this should compile)
        let profileRoute = StrictRoute.profile(userId: "required123")
        XCTAssertEqual(profileRoute.pathComponents, "/profile/required123")
        
        // Optional parameters work with defaults
        let postRoute = StrictRoute.post(id: "post456")
        XCTAssertEqual(postRoute.pathComponents, "/post/post456")
        XCTAssertTrue(postRoute.queryParameters.isEmpty)
        
        let postWithAuthor = StrictRoute.post(id: "post456", authorId: "author789")
        XCTAssertEqual(postWithAuthor.queryParameters["authorId"], "author789")
        
        // Note: StrictRoute.profile() without userId would not compile
        // This is the desired compile-time safety behavior
    }
}

// MARK: - Supporting Types for Enhanced Tests

struct SearchFilters {
    let category: String
    
    static let `default` = SearchFilters(category: "all")
    
    func asQueryParameters() -> [String: String] {
        return ["category": category]
    }
}

enum SettingsSection: String, CaseIterable {
    case general = "general"
    case privacy = "privacy"
    case notifications = "notifications"
}

// Enhanced route builder for DSL pattern
public class AxiomTypeSafeRouteBuilder<Route: AxiomTypeSafeRoute> {
    private var currentRoute: Route?
    private var additionalQueryParameters: [String: String] = [:]
    
    public init() {}
    
    public func route(_ route: Route) -> AxiomTypeSafeRouteBuilder<Route> {
        self.currentRoute = route
        return self
    }
    
    public func withQueryParameter(_ key: String, value: String) -> TypeSafeRouteBuilder<Route> {
        additionalQueryParameters[key] = value
        return self
    }
    
    public func build() -> Route {
        guard let route = currentRoute else {
            fatalError("No route set for builder")
        }
        
        // In a real implementation, this would modify the route's query parameters
        // For now, we'll return the route as-is since we can't modify enum cases
        return route
    }
}

// Dictionary extension for merging
extension Dictionary where Key == String, Value == String {
    static func + (lhs: [String: String], rhs: [String: String]) -> [String: String] {
        return lhs.merging(rhs) { _, new in new }
    }
}