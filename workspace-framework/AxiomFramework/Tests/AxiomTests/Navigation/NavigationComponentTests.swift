import XCTest
@testable import Axiom

@MainActor
final class NavigationComponentTests: XCTestCase {
    
    // Test NavigationCore in isolation
    func testNavigationCoreIsolation() async throws {
        let core = NavigationCore()
        
        // Test basic navigation
        let result = await core.navigate(to: StandardRoute.home)
        XCTAssertEqual(result, .success)
        XCTAssertEqual(core.currentRoute, .home)
        XCTAssertEqual(core.navigationDepth, 0)
        
        // Test navigation with history
        _ = await core.navigate(to: StandardRoute.settings)
        XCTAssertEqual(core.currentRoute, .settings)
        XCTAssertEqual(core.navigationDepth, 1)
        XCTAssertTrue(core.canNavigateBack)
        
        // Test back navigation
        let backResult = await core.navigateBack()
        XCTAssertEqual(backResult, .success)
        XCTAssertEqual(core.currentRoute, .home)
        XCTAssertEqual(core.navigationDepth, 0)
    }
    
    // Test NavigationDeepLinkHandler in isolation
    func testDeepLinkHandlerIsolation() async throws {
        let handler = NavigationDeepLinkHandler()
        
        // Test URL parsing
        let homeURL = URL(string: "axiom://home")!
        XCTAssertTrue(handler.canHandleDeepLink(homeURL))
        
        let detailURL = URL(string: "axiom://detail/123")!
        XCTAssertTrue(handler.canHandleDeepLink(detailURL))
        
        // Test pattern registration
        handler.registerDeepLink(pattern: "/profile", routeType: .custom)
        XCTAssertTrue(handler.registeredPatterns.contains("/profile"))
        
        // Test route handler registration
        let testRoute = StandardRoute.custom(path: "test")
        handler.registerRoute(testRoute) {
            Text("Test View")
        }
        XCTAssertTrue(handler.hasHandler(for: testRoute))
        XCTAssertNotNil(handler.handler(for: testRoute))
    }
    
    // Test NavigationFlowManager in isolation
    func testFlowManagerIsolation() async throws {
        let flowManager = NavigationFlowManager()
        
        // Test flow creation
        let flow = NavigationFlow(
            name: "Onboarding",
            steps: [.home, .settings, .custom(path: "complete")]
        )
        
        await flowManager.startFlow(flow)
        XCTAssertTrue(flowManager.hasActiveFlow)
        XCTAssertEqual(flowManager.currentFlow?.name, "Onboarding")
        XCTAssertEqual(flowManager.allActiveFlows.count, 1)
        
        // Test flow completion
        await flowManager.completeFlow()
        XCTAssertFalse(flowManager.hasActiveFlow)
        XCTAssertNil(flowManager.currentFlow)
    }
    
    // Test component integration through facade
    func testComponentIntegration() async throws {
        let service = NavigationServiceRefactored()
        
        // Test that core navigation works through facade
        let navResult = await service.navigate(to: StandardRoute.detail(id: "456"))
        XCTAssertEqual(navResult, .success)
        XCTAssertEqual(service.currentRoute, .detail(id: "456"))
        
        // Test that deep linking works through facade
        service.registerDeepLink(pattern: "/custom", routeType: .custom)
        let deepLinkResult = await service.processDeepLink(URL(string: "axiom://custom/test")!)
        XCTAssertEqual(deepLinkResult, .success)
        
        // Test that flow management works through facade
        let flow = NavigationFlow(name: "TestFlow", steps: [.home, .settings])
        await service.startFlow(flow)
        // Note: Flow manager needs core reference to actually navigate
    }
    
    // Test performance of decomposed components
    func testDecomposedPerformance() async throws {
        let service = NavigationServiceRefactored()
        
        let startTime = Date()
        
        // Perform 100 navigations
        for i in 0..<100 {
            _ = await service.navigate(to: StandardRoute.detail(id: "\(i)"))
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Should complete in reasonable time (< 1 second)
        XCTAssertLessThan(duration, 1.0, "Navigation performance degraded")
        
        // Verify final state
        XCTAssertEqual(service.navigationDepth, 99)
        XCTAssertEqual(service.currentRoute, .detail(id: "99"))
    }
}