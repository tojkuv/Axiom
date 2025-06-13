import XCTest
@testable import Axiom

/// Comprehensive test suite for modular navigation service architecture
/// Tests service decomposition, component coordination, and plugin system
class NavigationServiceArchitectureTests: XCTestCase {
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Service Architecture Tests
    
    func testNavigationServiceArchitectureComponents() throws {
        // Test for modular service architecture with component separation
        let builder = NavigationServiceBuilder()
        let service = builder.build()
        
        // Verify service has separate components
        XCTAssertNotNil(service.navigationCore, "NavigationService should have NavigationCore component")
        XCTAssertNotNil(service.deepLinkHandler, "NavigationService should have DeepLinkHandler component")
        XCTAssertNotNil(service.flowManager, "NavigationService should have FlowManager component")
        
        // Verify components are properly configured
        XCTAssertEqual(service.deepLinkHandler.navigationCore, service.navigationCore, "DeepLinkHandler should reference same NavigationCore")
        XCTAssertEqual(service.flowManager.navigationCore, service.navigationCore, "FlowManager should reference same NavigationCore")
    }
    
    func testNavigationComponentProtocol() async throws {
        // Test component communication protocol
        let core = NavigationCore()
        let deepLinkHandler = NavigationDeepLinkHandler()
        
        // Verify component protocol conformance
        XCTAssertTrue(deepLinkHandler is NavigationComponent, "DeepLinkHandler should conform to NavigationComponent")
        
        // Test event handling
        let event = NavigationEvent.routeChanged(from: nil, to: StandardRoute.home)
        XCTAssertNoThrow(try await deepLinkHandler.handleNavigationEvent(event), "Component should handle navigation events")
        
        // Component ID verification
        XCTAssertEqual(deepLinkHandler.componentID, "deep-link-handler", "Component should have correct ID")
    }
    
    func testNavigationStateStore() throws {
        // Test centralized state management
        let stateStore = NavigationStateStore()
        
        // Verify initial state
        Task {
            let currentRoute = await stateStore.currentRoute
            let navigationStack = await stateStore.navigationStack
            let activeFlows = await stateStore.activeFlows
            
            XCTAssertNil(currentRoute, "Initial current route should be nil")
            XCTAssertTrue(navigationStack.isEmpty, "Initial navigation stack should be empty")
            XCTAssertTrue(activeFlows.isEmpty, "Initial active flows should be empty")
        }
    }
    
    // MARK: - Service Builder Tests
    
    func testNavigationServiceBuilder() throws {
        // Test service factory pattern
        let builder = NavigationServiceBuilder()
        let service = builder.build()
        
        XCTAssertNotNil(service, "Builder should create NavigationService")
        XCTAssertTrue(service is ModularNavigationService, "Builder should return ModularNavigationService instance")
    }
    
    func testNavigationServiceBuilderConfiguration() throws {
        // Test builder with configuration
        let config = NavigationConfiguration(
            enableDeepLinking: true,
            persistNavigationState: true,
            maxHistorySize: 100,
            defaultTransition: .push
        )
        
        let builder = NavigationServiceBuilder()
        let service = builder.withConfiguration(config).build()
        
        XCTAssertEqual(service.configuration.enableDeepLinking, true, "Service should have deep linking enabled")
        XCTAssertEqual(service.configuration.maxHistorySize, 100, "Service should have configured history size")
    }
    
    // MARK: - NavigationCore Tests
    
    func testNavigationCoreStackOperations() async throws {
        // Test basic stack management
        let core = NavigationCore()
        
        // Test push operation
        try await core.push(StandardRoute.home)
        XCTAssertEqual(core.currentRoute, StandardRoute.home, "Current route should be updated after push")
        XCTAssertEqual(core.navigationStack.count, 1, "Navigation stack should have one route")
        
        // Test pop operation
        let poppedRoute = try await core.pop()
        XCTAssertEqual(poppedRoute, StandardRoute.home, "Popped route should match pushed route")
        XCTAssertNil(core.currentRoute, "Current route should be nil after pop")
        XCTAssertTrue(core.navigationStack.isEmpty, "Navigation stack should be empty after pop")
    }
    
    func testNavigationCoreHistoryTracking() async throws {
        // Test navigation history tracking
        let core = NavigationCore()
        
        // Navigate through several routes
        try await core.push(StandardRoute.home)
        try await core.push(StandardRoute.settings)
        try await core.push(StandardRoute.detail(id: "123"))
        
        XCTAssertEqual(core.navigationHistory.count, 2, "History should track previous routes")
        XCTAssertEqual(core.currentRoute, StandardRoute.detail(id: "123"), "Current route should be last pushed")
    }
    
    // MARK: - NavigationDeepLinkHandler Tests
    
    func testNavigationDeepLinkHandlerPatternRegistration() throws {
        // Test URL pattern registration
        let handler = NavigationDeepLinkHandler()
        
        handler.register(pattern: "/home") { _ in
            return StandardRoute.home
        }
        
        handler.register(pattern: "/detail/:id") { params in
            guard let id = params["id"] else { return nil }
            return StandardRoute.detail(id: id)
        }
        
        XCTAssertTrue(handler.hasPattern("/home"), "Handler should have registered home pattern")
        XCTAssertTrue(handler.hasPattern("/detail/:id"), "Handler should have registered detail pattern")
    }
    
    func testNavigationDeepLinkHandlerURLProcessing() throws {
        // Test deep link processing
        let handler = NavigationDeepLinkHandler()
        
        handler.register(pattern: "/detail/:id") { params in
            guard let id = params["id"] else { return nil }
            return StandardRoute.detail(id: id)
        }
        
        let url = URL(string: "myapp://detail/123")!
        let route = handler.processDeepLink(url)
        
        XCTAssertNotNil(route, "Handler should process valid deep link")
        XCTAssertEqual(route, StandardRoute.detail(id: "123"), "Handler should extract route parameters correctly")
    }
    
    // MARK: - NavigationFlowManager Tests
    
    func testNavigationFlowManagerLifecycle() async throws {
        // Test flow lifecycle management
        let manager = NavigationFlowManager()
        let testFlow = createTestFlow()
        
        // Start flow
        try await manager.startFlow(testFlow)
        XCTAssertTrue(manager.activeFlows.contains { $0.identifier == testFlow.identifier }, "Manager should track active flows")
        
        // Complete flow
        try await manager.completeFlow(testFlow.identifier)
        XCTAssertFalse(manager.activeFlows.contains { $0.identifier == testFlow.identifier }, "Manager should remove completed flows")
    }
    
    func testNavigationFlowManagerStepProgression() async throws {
        // Test step progression control
        let manager = NavigationFlowManager()
        let testFlow = createTestFlow()
        
        try await manager.startFlow(testFlow)
        
        // Progress to next step
        try await manager.progressFlow(testFlow.identifier)
        let currentStep = manager.getCurrentStep(for: testFlow.identifier)
        
        XCTAssertNotNil(currentStep, "Manager should track current step")
    }
    
    // MARK: - Plugin System Tests
    
    func testNavigationPluginSystem() async throws {
        // Test plugin architecture
        let service = NavigationServiceBuilder().build()
        let mockPlugin = MockNavigationPlugin()
        
        service.registerPlugin(mockPlugin)
        
        // Test plugin lifecycle
        await service.navigate(to: StandardRoute.home)
        
        XCTAssertTrue(mockPlugin.willNavigateCalled, "Plugin should receive willNavigate callback")
        XCTAssertTrue(mockPlugin.didNavigateCalled, "Plugin should receive didNavigate callback")
    }
    
    func testNavigationMiddlewareSupport() async throws {
        // Test middleware support
        let service = NavigationServiceBuilder().build()
        var middlewareExecuted = false
        
        service.use { request in
            middlewareExecuted = true
            return request
        }
        
        await service.navigate(to: StandardRoute.home)
        
        XCTAssertTrue(middlewareExecuted, "Middleware should be executed during navigation")
    }
    
    // MARK: - Command Pattern Tests
    
    func testNavigationCommandPattern() async throws {
        // Test command pattern for navigation
        let context = NavigationContext()
        let command = NavigateCommand(route: StandardRoute.home, options: NavigationOptions())
        
        let result = try await command.execute(with: context)
        
        XCTAssertNotNil(result, "Command should return navigation result")
        XCTAssertEqual(result.route, StandardRoute.home, "Command should navigate to specified route")
    }
    
    // MARK: - Observer Pattern Tests
    
    func testNavigationObserverPattern() async throws {
        // Test observer pattern for state changes
        let service = NavigationServiceBuilder().build()
        let observer = MockNavigationObserver()
        
        service.addObserver(observer)
        
        await service.navigate(to: StandardRoute.home)
        
        XCTAssertTrue(observer.didChangeRouteCalled, "Observer should receive route change notification")
        XCTAssertEqual(observer.lastRoute, StandardRoute.home, "Observer should receive correct route")
    }
    
    // MARK: - Strategy Pattern Tests
    
    func testTransitionStrategyPattern() async throws {
        // Test strategy pattern for transitions
        let pushStrategy = PushTransitionStrategy()
        let modalStrategy = ModalTransitionStrategy()
        let replaceStrategy = ReplaceTransitionStrategy()
        
        let context = NavigationContext()
        
        // Test different transition strategies
        await pushStrategy.performTransition(from: nil, to: StandardRoute.home, in: context)
        await modalStrategy.performTransition(from: StandardRoute.home, to: StandardRoute.settings, in: context)
        await replaceStrategy.performTransition(from: StandardRoute.settings, to: StandardRoute.detail(id: "123"), in: context)
        
        // Verify strategies can be executed without errors
        XCTAssertTrue(true, "All transition strategies should execute successfully")
    }
    
    // MARK: - Performance Tests
    
    func testNavigationPerformanceRequirements() async throws {
        // Test performance requirements
        let service = NavigationServiceBuilder().build()
        
        // Test navigation latency
        let startTime = CFAbsoluteTimeGetCurrent()
        await service.navigate(to: StandardRoute.home)
        let navigationLatency = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(navigationLatency, 0.01, "Navigation latency should be less than 10ms")
        
        // Test deep link resolution performance
        let handler = NavigationDeepLinkHandler()
        for i in 0..<1000 {
            handler.register(pattern: "/test/\\(i)") { _ in StandardRoute.home }
        }
        
        let deepLinkStart = CFAbsoluteTimeGetCurrent()
        let url = URL(string: "myapp://test/500")!
        _ = handler.processDeepLink(url)
        let deepLinkLatency = CFAbsoluteTimeGetCurrent() - deepLinkStart
        
        XCTAssertLessThan(deepLinkLatency, 0.05, "Deep link resolution should be less than 50ms for 1000 patterns")
    }
    
    // MARK: - Helper Methods
    
    private func createTestFlow() -> BusinessNavigationFlow {
        return DeclarativeFlow(
            identifier: "test-flow",
            metadata: FlowMetadata(
                title: "Test Flow",
                description: "Test flow for navigation service architecture",
                estimatedDuration: 60
            )
        ) {
            EnhancedFlowStep(identifier: "step1", order: 1)
            EnhancedFlowStep(identifier: "step2", order: 2)
            EnhancedFlowStep(identifier: "step3", order: 3)
        }
    }
}

// MARK: - Mock Classes

class MockNavigationPlugin: NavigationPlugin {
    var willNavigateCalled = false
    var didNavigateCalled = false
    var configuredService: NavigationService?
    
    func configure(with service: NavigationService) {
        configuredService = service
    }
    
    func willNavigate(to route: Route) async -> Bool {
        willNavigateCalled = true
        return true
    }
    
    func didNavigate(to route: Route) async {
        didNavigateCalled = true
    }
    
    func handleError(_ error: AxiomError) async {
        // Mock error handling
    }
}

class MockNavigationObserver: NavigationObserver {
    var didChangeRouteCalled = false
    var didStartFlowCalled = false
    var didEncounterErrorCalled = false
    var lastRoute: Route?
    var lastFlow: NavigationFlow?
    var lastError: AxiomError?
    
    func navigationService(_ service: NavigationService, didChangeTo route: Route?) {
        didChangeRouteCalled = true
        lastRoute = route
    }
    
    func navigationService(_ service: NavigationService, didStartFlow flow: NavigationFlow) {
        didStartFlowCalled = true
        lastFlow = flow
    }
    
    func navigationService(_ service: NavigationService, didEncounterError error: AxiomError) {
        didEncounterErrorCalled = true
        lastError = error
    }
}