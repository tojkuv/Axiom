import XCTest
@testable import Axiom

@MainActor
final class NavigationServiceDecompositionTests: XCTestCase {
    
    // Test that core navigation behavior is preserved
    func testCoreNavigationBehaviorPreserved() async throws {
        // Original service behavior
        let originalService = NavigationService()
        let route = StandardRoute.detail(id: "123")
        
        let result = await originalService.navigate(to: route)
        XCTAssertEqual(result, .success)
        XCTAssertEqual(originalService.currentRoute, route)
        XCTAssertEqual(originalService.navigationHistory.count, 0) // First navigation doesn't add to history
        
        // Navigate to another route
        let settingsRoute = StandardRoute.settings
        let result2 = await originalService.navigate(to: settingsRoute)
        XCTAssertEqual(result2, .success)
        XCTAssertEqual(originalService.currentRoute, settingsRoute)
        XCTAssertEqual(originalService.navigationHistory.count, 1)
        XCTAssertEqual(originalService.navigationHistory.first, route)
        
        // Test back navigation
        let backResult = await originalService.navigateBack()
        XCTAssertEqual(backResult, .success)
        XCTAssertEqual(originalService.currentRoute, route)
        XCTAssertEqual(originalService.navigationHistory.count, 0)
    }
    
    // Test that deep link behavior is preserved
    func testDeepLinkBehaviorPreserved() async throws {
        let service = NavigationService()
        
        // Test URL parsing and navigation
        let url = URL(string: "axiom://detail/456")!
        let result = await service.processDeepLink(url)
        XCTAssertEqual(result, .success)
        XCTAssertEqual(service.currentRoute, StandardRoute.detail(id: "456"))
        
        // Test custom deep link registration
        service.registerDeepLink(pattern: "/profile", routeType: .custom)
        
        // Verify pattern is registered (through navigation)
        let profileURL = URL(string: "axiom://custom/profile")!
        let profileResult = await service.processDeepLink(profileURL)
        XCTAssertEqual(profileResult, .success)
    }
    
    // Test route management behavior
    func testRouteManagementBehaviorPreserved() async throws {
        let service = NavigationService()
        
        // Test route registration
        let customRoute = StandardRoute.custom(path: "test")
        service.registerRoute(customRoute) {
            Text("Test View")
        }
        
        // Verify can navigate check
        XCTAssertTrue(service.canNavigate(to: customRoute))
        XCTAssertTrue(service.canNavigate(to: .home)) // Standard routes always allowed
        
        // Test navigation depth
        _ = await service.navigate(to: .home)
        _ = await service.navigate(to: .settings)
        _ = await service.navigate(to: customRoute)
        
        XCTAssertEqual(service.navigationDepth, 2) // home -> settings -> custom (2 in history)
        XCTAssertTrue(service.canNavigateBack)
        
        // Test navigate to root
        let rootResult = await service.navigateToRoot()
        XCTAssertEqual(rootResult, .success)
        XCTAssertEqual(service.navigationDepth, 0)
        XCTAssertFalse(service.canNavigateBack)
    }
    
    // Test cancellation behavior
    func testCancellationBehaviorPreserved() async throws {
        let service = NavigationService()
        
        // Create cancellation token
        let token = service.createCancellationToken()
        XCTAssertFalse(token.isCancelled)
        
        // Cancel all navigations
        service.cancelAllNavigations()
        XCTAssertTrue(token.isCancelled)
    }
    
    // Test API surface compatibility
    func testAPICompatibilityMaintained() async throws {
        let service = NavigationService()
        
        // Verify all public methods exist and work
        _ = await service.navigate(to: .home)
        _ = await service.navigate(to: .settings, options: .default)
        _ = await service.navigateBack()
        _ = await service.navigateToRoot()
        _ = await service.dismiss()
        _ = await service.processDeepLink(URL(string: "axiom://home")!)
        
        service.registerDeepLink(pattern: "/test", routeType: .custom)
        service.registerRoute(.home) { AnyView(Text("Home")) }
        _ = service.canNavigate(to: .home)
        _ = service.navigationDepth
        _ = service.canNavigateBack
        service.setPattern(.push)
        service.cancelAllNavigations()
        _ = service.createCancellationToken()
        
        // Verify route builder
        let builder = service.route(to: "detail")
            .parameter("id", value: "789")
        let route = builder.build()
        XCTAssertEqual(route, StandardRoute.detail(id: "789"))
    }
}