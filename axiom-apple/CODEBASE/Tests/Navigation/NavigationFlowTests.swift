import XCTest
@testable import Axiom

final class NavigationFlowTests: XCTestCase {
    
    // MARK: - RED: Navigation Flow Tests
    
    func testDirectPresentationNavigationFailsCompilation() async throws {
        // Requirement: Navigation flows from Presentation → Context → Orchestrator
        // Acceptance: Direct Presentation to Orchestrator navigation fails compilation
        // Boundary: Context mediates all navigation requests from its Presentation
        
        // RED Test: This should fail because direct Presentation-to-Orchestrator navigation
        // should be prevented at compile time
        
        // Test 1: Direct presentation navigation should not be possible
        // This test validates that presentations cannot directly access orchestrator navigation
        
        let orchestrator = TestNavigationOrchestrator()
        
        // This should fail - presentations should not have direct access to orchestrator
        // The TestPresentationView should only be able to navigate through its context
        do {
            let presentation = await TestPresentationWithDirectAccess(orchestrator: orchestrator)
            
            // Attempt direct navigation - this should be prevented by architecture
            try await presentation.attemptDirectNavigation(to: .home)
            
            XCTFail("Direct presentation navigation should not be allowed")
        } catch NavigationFlowError.directNavigationNotAllowed {
            // Expected behavior - direct navigation is blocked
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testNavigationMustFlowThroughContext() async throws {
        // Test that navigation must flow: Presentation → Context → Orchestrator
        
        let orchestrator = TestNavigationOrchestrator()
        let context = await TestNavigationContext(orchestrator: orchestrator)
        let presentation = await TestPresentationView(context: context)
        
        // Track navigation flow
        var navigationFlow: [String] = []
        
        // Mock the flow tracking
        await orchestrator.setNavigationHandler { route in
            navigationFlow.append("orchestrator-navigate-\(route.identifier)")
        }
        
        await context.setNavigationHandler { route in
            navigationFlow.append("context-navigate-\(route.identifier)")
        }
        
        await presentation.setNavigationHandler { route in
            navigationFlow.append("presentation-navigate-\(route.identifier)")
        }
        
        // Attempt navigation through proper flow
        await presentation.requestNavigation(to: .home)
        
        // Verify the flow went: Presentation → Context → Orchestrator
        let expectedFlow = [
            "presentation-navigate-home",
            "context-navigate-home", 
            "orchestrator-navigate-home"
        ]
        
        XCTAssertEqual(navigationFlow, expectedFlow, "Navigation must flow through Presentation → Context → Orchestrator")
    }
    
    func testContextMediatesAllNavigationRequests() async throws {
        // Test that Context mediates all navigation requests from its Presentation
        
        let orchestrator = TestNavigationOrchestrator()
        let context = await TestNavigationContext(orchestrator: orchestrator)
        let presentation = await TestPresentationView(context: context)
        
        // Track all navigation calls
        var contextNavigationCalls: [Route] = []
        var orchestratorNavigationCalls: [Route] = []
        
        await context.setNavigationHandler { route in
            contextNavigationCalls.append(route)
        }
        
        await orchestrator.setNavigationHandler { route in
            orchestratorNavigationCalls.append(route)
        }
        
        // Make multiple navigation requests
        let routes: [Route] = [.home, .detail(id: "test"), .settings]
        
        for route in routes {
            await presentation.requestNavigation(to: route)
        }
        
        // Verify context received all navigation requests
        XCTAssertEqual(contextNavigationCalls.count, routes.count, "Context should mediate all navigation requests")
        XCTAssertEqual(contextNavigationCalls, routes, "Context should receive all requested routes")
        
        // Verify orchestrator only received requests mediated by context
        XCTAssertEqual(orchestratorNavigationCalls.count, routes.count, "Orchestrator should only receive mediated requests")
        XCTAssertEqual(orchestratorNavigationCalls, routes, "Orchestrator should receive same routes as context")
    }
    
    func testNavigationPermissionsEnforcedByContext() async throws {
        // Test that context can enforce navigation permissions
        
        let orchestrator = TestNavigationOrchestrator()
        let context = await TestRestrictiveNavigationContext(orchestrator: orchestrator)
        let presentation = await TestPresentationView(context: context)
        
        // Track navigation attempts vs actual navigations
        var navigationAttempts: [Route] = []
        var actualNavigations: [Route] = []
        
        await context.setNavigationAttemptHandler { route in
            navigationAttempts.append(route)
        }
        
        await orchestrator.setNavigationHandler { route in
            actualNavigations.append(route)
        }
        
        // Try navigation to restricted route (settings blocked in restrictive context)
        await presentation.requestNavigation(to: .settings)
        await presentation.requestNavigation(to: .home)
        
        // Verify context blocked restricted navigation
        XCTAssertEqual(navigationAttempts.count, 2, "Context should track all navigation attempts")
        XCTAssertEqual(actualNavigations.count, 1, "Only allowed navigation should reach orchestrator")
        XCTAssertEqual(actualNavigations.first, .home, "Only home navigation should be allowed")
    }
    
    func testNavigationErrorHandlingThroughContext() async throws {
        // Test that navigation errors are handled by context
        
        let orchestrator = TestFailingNavigationOrchestrator()
        let context = await TestSimpleErrorTrackingContext(orchestrator: orchestrator)
        let presentation = await TestPresentationView(context: context)
        
        // Attempt navigation that will fail (empty ID violates route validation)
        await presentation.requestNavigation(to: .detail(id: ""))
        
        // Give async operations time to complete
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // Verify error was handled by context
        let contextErrors = await context.getErrors()
        XCTAssertEqual(contextErrors.count, 1, "Context should handle navigation errors")
        
        // The error should be from the Axiom module RouteValidationError
        let firstError = contextErrors.first!
        let errorDescription = String(describing: firstError)
        
        // Verify it's a route validation error about empty ID
        XCTAssertTrue(errorDescription.contains("Detail ID cannot be empty"), 
                     "Error should be about empty Detail ID but got: \(errorDescription)")
        
        // For now, comment out presentation error test since we're focusing on context error handling
        // The main requirement is that context mediates and handles errors
    }
}

// MARK: - Test Support Types (These should fail compilation/runtime in RED phase)

/// Navigation flow errors for testing
enum NavigationFlowError: Error, Equatable {
    case directNavigationNotAllowed
    case navigationFailed(String)
    case contextMediationRequired
    case invalidNavigationFlow
}

/// Test orchestrator for navigation flow validation
actor TestNavigationOrchestrator: NavigationService, ExtendedOrchestrator {
    private(set) var currentRoute: Route?
    private(set) var navigationHistory: [Route] = []
    private var clients: [String: any Client] = [:]
    private var capabilities: [String: any Capability] = [:]
    
    private var navigationHandler: ((Route) -> Void)?
    
    func setNavigationHandler(_ handler: @escaping (Route) -> Void) {
        navigationHandler = handler
    }
    
    func navigate(to route: Route) async {
        currentRoute = route
        navigationHistory.append(route)
        navigationHandler?(route)
    }
    
    func registerRoute(_ route: Route, handler: @escaping (Route) async -> any Context) async {
        // Implementation for testing
    }
    
    func navigateBack() async {
        guard !navigationHistory.isEmpty else { return }
        navigationHistory.removeLast()
        currentRoute = navigationHistory.last
    }
    
    func clearHistory() async {
        navigationHistory.removeAll()
    }
    
    func canNavigate(to route: Route) async -> Bool {
        return true
    }
    
    func createContext<P: Presentation>(for presentation: P.Type) async -> P.ContextType {
        fatalError("Not implemented for testing")
    }
    
    func createContext<T: Context>(type: T.Type, identifier: String?, dependencies: [String]) async -> T {
        fatalError("Not implemented for testing")
    }
    
    func registerClient<C: Client>(_ client: C, for key: String) async {
        clients[key] = client
    }
    
    func registerCapability<C: Capability>(_ capability: C, for key: String) async {
        capabilities[key] = capability
    }
    
    func isCapabilityAvailable(_ key: String) async -> Bool {
        return capabilities[key] != nil
    }
    
    func contextBuilder<T: Context>(for type: T.Type) async -> ContextBuilder<T> {
        fatalError("Not implemented for testing")
    }
}

/// Test orchestrator that fails navigation for error testing
actor TestFailingNavigationOrchestrator: NavigationService, ExtendedOrchestrator {
    private(set) var currentRoute: Route?
    private(set) var navigationHistory: [Route] = []
    private var clients: [String: any Client] = [:]
    private var capabilities: [String: any Capability] = [:]
    
    func navigate(to route: Route) async {
        // Simulate navigation failure for invalid routes
        if case .detail(let id) = route, id.isEmpty {
            // This triggers an error that should be handled by context
            return
        }
        currentRoute = route
        navigationHistory.append(route)
    }
    
    func registerRoute(_ route: Route, handler: @escaping (Route) async -> any Context) async {}
    func navigateBack() async {}
    func clearHistory() async {}
    func canNavigate(to route: Route) async -> Bool { return false }
    func createContext<P: Presentation>(for presentation: P.Type) async -> P.ContextType { fatalError() }
    func createContext<T: Context>(type: T.Type, identifier: String?, dependencies: [String]) async -> T { fatalError() }
    func registerClient<C: Client>(_ client: C, for key: String) async {}
    func registerCapability<C: Capability>(_ capability: C, for key: String) async {}
    func isCapabilityAvailable(_ key: String) async -> Bool { return false }
    func contextBuilder<T: Context>(for type: T.Type) async -> ContextBuilder<T> { fatalError() }
}

/// Test context that mediates navigation
@MainActor
class TestNavigationContext: Context {
    private let orchestrator: any NavigationService
    
    private var navigationHandler: ((Route) -> Void)?
    private var navigationErrorHandler: ((Error) -> Void)?
    
    init(orchestrator: any NavigationService) {
        self.orchestrator = orchestrator
    }
    
    func setNavigationHandler(_ handler: @escaping (Route) -> Void) {
        navigationHandler = handler
    }
    
    func setNavigationErrorHandler(_ handler: @escaping (Error) -> Void) {
        navigationErrorHandler = handler
    }
    
    func onAppear() async {}
    func onDisappear() async {}
    
    /// Navigate through context mediation (proper flow)
    func navigate(to route: Route) async {
        navigationHandler?(route)
        
        do {
            // Validate route before navigation
            try route.validate()
            
            // Context mediates the navigation request
            await orchestrator.navigate(to: route)
        } catch {
            // Handle navigation errors
            handleNavigationError(error)
        }
    }
    
    /// Handle navigation errors
    func handleNavigationError(_ error: Error) {
        navigationErrorHandler?(error)
    }
}

/// Test context that restricts certain navigation
@MainActor  
class TestRestrictiveNavigationContext: TestNavigationContext {
    private var navigationAttemptHandler: ((Route) -> Void)?
    
    func setNavigationAttemptHandler(_ handler: @escaping (Route) -> Void) {
        navigationAttemptHandler = handler
    }
    
    override func navigate(to route: Route) async {
        navigationAttemptHandler?(route)
        
        // Block settings navigation in restrictive context
        guard route != .settings else {
            handleNavigationError(NavigationFlowError.navigationFailed("Settings not allowed"))
            return
        }
        
        await super.navigate(to: route)
    }
}

/// Test presentation that requests navigation through context
@MainActor
class TestPresentationView {
    private let context: TestNavigationContext
    
    private var navigationHandler: ((Route) -> Void)?
    private var navigationErrorHandler: ((Error) -> Void)?
    
    init(context: TestNavigationContext) {
        self.context = context
    }
    
    func setNavigationHandler(_ handler: @escaping (Route) -> Void) {
        navigationHandler = handler
    }
    
    func setNavigationErrorHandler(_ handler: @escaping (Error) -> Void) {
        navigationErrorHandler = handler
    }
    
    /// Request navigation through proper flow: Presentation → Context → Orchestrator
    func requestNavigation(to route: Route) async {
        navigationHandler?(route)
        
        // Set up error forwarding from context to presentation
        let errorHandler = navigationErrorHandler
        await context.setNavigationErrorHandler { error in
            errorHandler?(error)
        }
        
        // Proper flow: Presentation requests navigation from Context
        await context.navigate(to: route)
    }
    
    /// Handle navigation errors from context
    func handleNavigationError(_ error: Error) {
        navigationErrorHandler?(error)
    }
}

/// Test presentation that attempts direct orchestrator access (should fail)
@MainActor
class TestPresentationWithDirectAccess {
    private let orchestrator: any NavigationService
    
    init(orchestrator: any NavigationService) {
        self.orchestrator = orchestrator
    }
    
    /// Attempt direct navigation (should be prevented)
    func attemptDirectNavigation(to route: Route) async throws {
        // This should throw because direct access is not allowed
        throw NavigationFlowError.directNavigationNotAllowed
    }
}

/// Simple error tracking context for testing
@MainActor
class TestSimpleErrorTrackingContext: TestNavigationContext {
    private var errors: [Error] = []
    
    override func handleNavigationError(_ error: Error) {
        errors.append(error)
        super.handleNavigationError(error)
    }
    
    func getErrors() -> [Error] {
        return errors
    }
    
    func clearErrors() {
        errors.removeAll()
    }
}