import XCTest
@testable import Axiom

/// Minimal tests for modular navigation service architecture (W-04-003)
class ModularNavigationServiceTests: XCTestCase {
    
    // MARK: - Service Architecture Tests
    
    func testNavigationServiceArchitectureComponents() throws {
        // Test for modular service architecture with component separation
        let builder = NavigationServiceBuilder()
        let service = builder.build()
        
        // Verify service has separate components
        XCTAssertNotNil(service.navigationCore)
        XCTAssertNotNil(service.deepLinkHandler)
        XCTAssertNotNil(service.flowManager)
        
        // Verify components are properly configured
        XCTAssertEqual(service.deepLinkHandler.navigationCore, service.navigationCore)
        XCTAssertEqual(service.flowManager.navigationCore, service.navigationCore)
    }
    
    func testNavigationComponentProtocol() async throws {
        // Test component communication protocol
        let core = NavigationCore()
        let deepLinkHandler = NavigationDeepLinkHandler()
        
        // Verify component protocol conformance
        XCTAssertTrue(deepLinkHandler is NavigationComponent)
        XCTAssertNoThrow(try await deepLinkHandler.handleNavigationEvent(.routeChanged(from: nil, to: StandardRoute.home)))
    }
    
    func testNavigationStateStore() async throws {
        // Test centralized state management
        let stateStore = NavigationStateStore()
        
        XCTAssertNil(await stateStore.currentRoute)
        XCTAssertTrue(await stateStore.navigationStack.isEmpty)
        XCTAssertTrue(await stateStore.activeFlows.isEmpty)
    }
    
    // MARK: - Plugin System Tests
    
    func testPluginSystem() async throws {
        // Test plugin architecture
        let plugin = TestNavigationPlugin()
        let service = NavigationServiceBuilder()
            .withPlugin(plugin)
            .build()
        
        // Verify plugin was initialized
        XCTAssertTrue(plugin.initialized)
        
        // Test navigation triggers plugin
        try await service.navigate(to: StandardRoute.home)
        XCTAssertTrue(plugin.didNavigateCalled)
    }
    
    func testMiddlewareSystem() async throws {
        // Test middleware support
        let middleware = TestNavigationMiddleware()
        let service = NavigationServiceBuilder()
            .withMiddleware(middleware)
            .build()
        
        // Test middleware processes routes
        try await service.navigate(to: StandardRoute.home)
        XCTAssertTrue(middleware.processCalled)
    }
    
    // MARK: - Pattern Implementation Tests
    
    func testCommandPattern() throws {
        // Test command pattern
        let command = NavigationCommand(
            execute: { print("Navigate forward") },
            undo: { print("Navigate back") }
        )
        
        XCTAssertNoThrow(try command.execute())
        XCTAssertNoThrow(try command.undo())
    }
    
    func testObserverPattern() async throws {
        // Test observer pattern
        let observer = TestNavigationObserver()
        let stateStore = NavigationStateStore()
        
        await stateStore.addObserver(observer)
        await stateStore.setCurrentRoute(StandardRoute.home)
        
        XCTAssertTrue(observer.onRouteChangedCalled)
    }
    
    func testStrategyPattern() async throws {
        // Test strategy pattern
        let strategy = TestRouteResolutionStrategy()
        let route = try await strategy.resolve(from: "/home")
        
        XCTAssertEqual(route as? StandardRoute, StandardRoute.home)
    }
    
    // MARK: - Worker Requirement Tests
    
    func testWorkerServiceComponentFunctionality() async throws {
        let service = NavigationServiceBuilder().build()
        XCTAssertNoThrow(try await service.navigate(to: StandardRoute.home))
    }
    
    func testWorkerServiceArchitectureImplemented() throws {
        // Test verifies worker's modular service enhancement
        let service = ModularNavigationService()
        XCTAssertTrue(service.supportsModularArchitecture)
        XCTAssertTrue(service.supportsPluginSystem)
    }
}

// MARK: - Test Helpers

class TestNavigationPlugin: NavigationPlugin {
    var initialized = false
    var didNavigateCalled = false
    
    func initialize(with service: ModularNavigationService) {
        initialized = true
    }
    
    func didNavigate(to route: any TypeSafeRoute) async {
        didNavigateCalled = true
    }
}

class TestNavigationMiddleware: NavigationMiddleware {
    var processCalled = false
    
    func process(route: any TypeSafeRoute, in service: ModularNavigationService) async throws -> any TypeSafeRoute {
        processCalled = true
        return route
    }
}

class TestNavigationObserver: NavigationStateObserver {
    let id = "test-observer"
    var onRouteChangedCalled = false
    
    func onRouteChanged(from: (any TypeSafeRoute)?, to: any TypeSafeRoute) async {
        onRouteChangedCalled = true
    }
}

struct TestRouteResolutionStrategy: RouteResolutionStrategy {
    func resolve(from input: Any) async throws -> (any TypeSafeRoute)? {
        if let path = input as? String, path == "/home" {
            return StandardRoute.home
        }
        return nil
    }
}