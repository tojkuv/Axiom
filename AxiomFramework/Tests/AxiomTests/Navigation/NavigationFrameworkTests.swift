import XCTest
import SwiftUI
@testable import Axiom
@testable import AxiomTesting

/// Comprehensive tests for Navigation framework functionality
/// Tests navigation flows, service integration, and route management using AxiomTesting framework
final class NavigationFrameworkTests: XCTestCase {
    
    // MARK: - Test Environment
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Navigation Service Architecture Tests
    
    func testNavigationServiceMustConformToOrchestrator() async throws {
        try await testEnvironment.runTest { env in
            // Use testing framework to validate architecture compliance
            let validNavigationService = await TestNavigationOrchestrator()
            
            assertFrameworkCompliance(validNavigationService)
            
            // Verify orchestrator conformance
            XCTAssertTrue(
                validNavigationService is (any Orchestrator),
                "Navigation service must conform to Orchestrator protocol"
            )
            
            // Verify navigation service conformance
            XCTAssertTrue(
                validNavigationService is (any NavigationService),
                "Must also conform to NavigationService protocol"
            )
        }
    }
    
    func testNavigationAsStandaloneComponentTypeFails() async throws {
        try await testEnvironment.runTest { env in
            // Test architectural constraint: Navigation is not a separate component type
            let componentTypes = ComponentType.allCases
            let hasNavigationType = componentTypes.contains { type in
                "\(type)".lowercased().contains("navigation")
            }
            
            XCTAssertFalse(
                hasNavigationType,
                "Navigation should not be a separate component type - it must be an Orchestrator service"
            )
            
            // Test that standalone navigation service doesn't conform to Orchestrator
            let standaloneNavigation = StandaloneNavigationService()
            let isValidNavigationService = standaloneNavigation is (any Orchestrator)
            
            XCTAssertFalse(
                isValidNavigationService,
                "Navigation service must be implemented as Orchestrator service, not standalone component"
            )
        }
    }
    
    // MARK: - Navigation Flow Tests
    
    func testNavigationFlowMustFollowArchitecture() async throws {
        try await testEnvironment.runTest { env in
            // Test proper navigation flow: Presentation → Context → Orchestrator
            let orchestrator = TestNavigationOrchestrator()
            let context = try await env.createContext(
                TestNavigationContext.self,
                id: "navigation-context"
            ) {
                TestNavigationContext(orchestrator: orchestrator)
            }
            
            // Test navigation flow using framework utilities
            try await TestHelpers.navigation.assertNavigationFlow(
                using: orchestrator,
                sequence: [
                    .navigate(to: TestRoute.home),
                    .navigate(to: TestRoute.detail(id: "test")),
                    .navigateBack()
                ],
                expectedStack: [TestRoute.home, TestRoute.detail(id: "test"), TestRoute.home]
            )
        }
    }
    
    func testContextMediatesAllNavigationRequests() async throws {
        try await testEnvironment.runTest { env in
            let orchestrator = TestNavigationOrchestrator()
            let context = try await env.createContext(
                NavigationMediationTestContext.self,
                id: "mediation-context"
            ) {
                NavigationMediationTestContext(orchestrator: orchestrator)
            }
            
            let routes: [TestRoute] = [.home, .detail(id: "test"), .settings]
            
            // Process navigation requests through context
            for route in routes {
                await context.requestNavigation(to: route)
            }
            
            // Verify context mediated all requests
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.mediatedRequests.count == routes.count },
                description: "Context should mediate all navigation requests"
            )
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.mediatedRequests == routes },
                description: "Context should mediate exact routes requested"
            )
        }
    }
    
    func testNavigationPermissionsEnforcedByContext() async throws {
        try await testEnvironment.runTest { env in
            let orchestrator = TestNavigationOrchestrator()
            let context = try await env.createContext(
                RestrictiveNavigationContext.self,
                id: "restrictive-context"
            ) {
                RestrictiveNavigationContext(orchestrator: orchestrator)
            }
            
            // Attempt navigation to both allowed and restricted routes
            await context.requestNavigation(to: .home)
            await context.requestNavigation(to: .settings) // This should be blocked
            
            // Verify permissions were enforced
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.allowedNavigations.count == 1 },
                description: "Only allowed navigation should pass through"
            )
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.blockedNavigations.count == 1 },
                description: "Restricted navigation should be blocked"
            )
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.allowedNavigations.first == .home },
                description: "Home navigation should be allowed"
            )
        }
    }
    
    // MARK: - Route Management Tests
    
    func testRouteValidationAndProcessing() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                RouteValidationTestContext.self,
                id: "route-validation"
            ) {
                RouteValidationTestContext()
            }
            
            // Test valid route
            await context.processRoute(.home)
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.validRoutes.contains(.home) },
                description: "Valid route should be processed"
            )
            
            // Test invalid route (empty detail ID)
            await context.processRoute(.detail(id: ""))
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.invalidRoutes.count == 1 },
                description: "Invalid route should be rejected"
            )
        }
    }
    
    // MARK: - Navigation Error Handling Tests
    
    func testNavigationErrorHandlingThroughContext() async throws {
        try await testEnvironment.runTest { env in
            let failingOrchestrator = FailingNavigationOrchestrator()
            let context = try await env.createContext(
                ErrorHandlingNavigationContext.self,
                id: "error-handling"
            ) {
                ErrorHandlingNavigationContext(orchestrator: failingOrchestrator)
            }
            
            // Trigger navigation error
            await context.requestNavigation(to: .detail(id: "invalid"))
            
            // Assert error was handled by context
            try await TestHelpers.context.assertState(
                in: context,
                timeout: .seconds(2),
                condition: { $0.handledErrors.count > 0 },
                description: "Context should handle navigation errors"
            )
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.lastError != nil },
                description: "Context should capture error details"
            )
        }
    }
    
    // MARK: - Navigation Performance Tests
    
    func testNavigationPerformanceRequirements() async throws {
        try await testEnvironment.runTest { env in
            let orchestrator = TestNavigationOrchestrator()
            let context = try await env.createContext(
                PerformanceNavigationContext.self,
                id: "navigation-performance"
            ) {
                PerformanceNavigationContext(orchestrator: orchestrator)
            }
            
            // Test navigation performance under load
            let results = try await TestHelpers.performance.testContextPerformance(
                context: context,
                actionCount: 500,
                concurrentClients: 3
            )
            
            // Assert performance requirements
            XCTAssertGreaterThan(results.throughput, 100, "Should process >100 navigation actions/sec")
            XCTAssertLessThan(results.averageActionDuration.timeInterval, 0.01, "Average navigation <10ms")
            XCTAssertLessThan(results.memoryGrowth, 5 * 1024 * 1024, "Memory growth <5MB")
        }
    }
    
    // MARK: - Navigation Memory Management Tests
    
    func testNavigationMemoryManagement() async throws {
        try await testEnvironment.runTest { env in
            let orchestrator = TestNavigationOrchestrator()
            
            // Test memory management with navigation context lifecycle
            try await TestHelpers.context.assertNoMemoryLeaks {
                let context = try await env.createContext(
                    MemoryTestNavigationContext.self,
                    id: "memory-test"
                ) {
                    MemoryTestNavigationContext(orchestrator: orchestrator)
                }
                
                // Perform multiple navigation operations
                for i in 0..<100 {
                    await context.requestNavigation(to: .detail(id: "item-\(i)"))
                }
                
                // Context should clean up properly
                await env.removeContext("memory-test")
            }
        }
    }
    
    // MARK: - Deep Linking Tests
    
    func testDeepLinkHandling() async throws {
        try await testEnvironment.runTest { env in
            let orchestrator = TestNavigationOrchestrator()
            let context = try await env.createContext(
                DeepLinkNavigationContext.self,
                id: "deep-link"
            ) {
                DeepLinkNavigationContext(orchestrator: orchestrator)
            }
            
            // Test deep link processing
            let deepLink = "app://detail/test-123"
            await context.processDeepLink(deepLink)
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.processedDeepLinks.count == 1 },
                description: "Deep link should be processed"
            )
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { ctx in
                    guard let parsedRoute = ctx.parsedRoutes.first else { return false }
                    return parsedRoute == .detail(id: "test-123")
                },
                description: "Deep link should be parsed to correct route"
            )
        }
    }
    
    // MARK: - Framework Compliance Tests
    
    func testNavigationFrameworkCompliance() async throws {
        let orchestrator = TestNavigationOrchestrator()
        
        // Use framework compliance testing
        assertFrameworkCompliance(orchestrator)
        
        // Navigation-specific compliance checks
        XCTAssertTrue(orchestrator is NavigationService, "Must implement NavigationService")
        XCTAssertTrue(orchestrator is Orchestrator, "Must implement Orchestrator")
    }
}

// MARK: - Test Support Contexts

@MainActor
class TestNavigationContext: BaseContext {
    private let orchestrator: TestNavigationOrchestrator
    
    init(orchestrator: TestNavigationOrchestrator) {
        self.orchestrator = orchestrator
        super.init()
    }
    
    func requestNavigation(to route: TestRoute) async {
        await orchestrator.navigate(to: route)
    }
}

@MainActor
class NavigationMediationTestContext: BaseContext {
    private let orchestrator: TestNavigationOrchestrator
    @Published private(set) var mediatedRequests: [TestRoute] = []
    
    init(orchestrator: TestNavigationOrchestrator) {
        self.orchestrator = orchestrator
        super.init()
    }
    
    func requestNavigation(to route: TestRoute) async {
        mediatedRequests.append(route)
        await orchestrator.navigate(to: route)
    }
}

@MainActor
class RestrictiveNavigationContext: BaseContext {
    private let orchestrator: TestNavigationOrchestrator
    @Published private(set) var allowedNavigations: [TestRoute] = []
    @Published private(set) var blockedNavigations: [TestRoute] = []
    
    init(orchestrator: TestNavigationOrchestrator) {
        self.orchestrator = orchestrator
        super.init()
    }
    
    func requestNavigation(to route: TestRoute) async {
        // Block settings navigation
        if route == .settings {
            blockedNavigations.append(route)
            return
        }
        
        allowedNavigations.append(route)
        await orchestrator.navigate(to: route)
    }
}

@MainActor
class RouteValidationTestContext: BaseContext {
    @Published private(set) var validRoutes: [TestRoute] = []
    @Published private(set) var invalidRoutes: [TestRoute] = []
    
    func processRoute(_ route: TestRoute) async {
        do {
            try route.validate()
            validRoutes.append(route)
        } catch {
            invalidRoutes.append(route)
        }
    }
}

@MainActor
class ErrorHandlingNavigationContext: BaseContext {
    private let orchestrator: FailingNavigationOrchestrator
    @Published private(set) var handledErrors: [Error] = []
    @Published private(set) var lastError: Error?
    
    init(orchestrator: FailingNavigationOrchestrator) {
        self.orchestrator = orchestrator
        super.init()
    }
    
    func requestNavigation(to route: TestRoute) async {
        do {
            await orchestrator.navigate(to: route)
        } catch {
            handledErrors.append(error)
            lastError = error
        }
    }
}

@MainActor
class PerformanceNavigationContext: BaseContext {
    private let orchestrator: TestNavigationOrchestrator
    @Published private(set) var navigationCount = 0
    
    init(orchestrator: TestNavigationOrchestrator) {
        self.orchestrator = orchestrator
        super.init()
    }
    
    func performNavigation() async {
        let route = TestRoute.detail(id: "perf-\(navigationCount)")
        await orchestrator.navigate(to: route)
        navigationCount += 1
    }
}

@MainActor
class MemoryTestNavigationContext: BaseContext {
    private let orchestrator: TestNavigationOrchestrator
    @Published private(set) var processedRoutes: [TestRoute] = []
    
    init(orchestrator: TestNavigationOrchestrator) {
        self.orchestrator = orchestrator
        super.init()
    }
    
    func requestNavigation(to route: TestRoute) async {
        // Don't retain routes to test memory management
        await orchestrator.navigate(to: route)
        // Only count, don't store
        processedRoutes = [route] // Keep only latest to avoid memory accumulation
    }
}

@MainActor
class DeepLinkNavigationContext: BaseContext {
    private let orchestrator: TestNavigationOrchestrator
    @Published private(set) var processedDeepLinks: [String] = []
    @Published private(set) var parsedRoutes: [TestRoute] = []
    
    init(orchestrator: TestNavigationOrchestrator) {
        self.orchestrator = orchestrator
        super.init()
    }
    
    func processDeepLink(_ deepLink: String) async {
        processedDeepLinks.append(deepLink)
        
        if let route = parseDeepLink(deepLink) {
            parsedRoutes.append(route)
            await orchestrator.navigate(to: route)
        }
    }
    
    private func parseDeepLink(_ deepLink: String) -> TestRoute? {
        guard deepLink.hasPrefix("app://") else { return nil }
        
        let path = String(deepLink.dropFirst(6)) // Remove "app://"
        let components = path.split(separator: "/")
        
        guard let first = components.first else { return nil }
        
        switch first {
        case "home":
            return .home
        case "detail":
            if components.count > 1 {
                return .detail(id: String(components[1]))
            }
        case "settings":
            return .settings
        default:
            break
        }
        
        return nil
    }
}

// MARK: - Test Support Types

actor TestNavigationOrchestrator: NavigationService, Orchestrator {
    private(set) var currentRoute: TestRoute?
    private(set) var navigationHistory: [TestRoute] = []
    
    func navigate(to route: TestRoute) async {
        currentRoute = route
        navigationHistory.append(route)
    }
    
    func navigateBack() async {
        guard navigationHistory.count > 1 else { return }
        navigationHistory.removeLast()
        currentRoute = navigationHistory.last
    }
    
    func canNavigate(to route: TestRoute) async -> Bool {
        return true
    }
    
    func clearHistory() async {
        navigationHistory.removeAll()
        currentRoute = nil
    }
    
    // Orchestrator conformance
    func createContext<P: Presentation>(for presentation: P.Type) async -> P.ContextType {
        fatalError("Not implemented for testing")
    }
}

actor FailingNavigationOrchestrator: NavigationService, Orchestrator {
    private(set) var currentRoute: TestRoute?
    
    func navigate(to route: TestRoute) async throws {
        // Simulate navigation failure for certain routes
        if case .detail(let id) = route, id == "invalid" {
            throw NavigationTestError.invalidRoute(id)
        }
        currentRoute = route
    }
    
    func navigateBack() async {}
    func canNavigate(to route: TestRoute) async -> Bool { return false }
    func clearHistory() async {}
    
    // Orchestrator conformance
    func createContext<P: Presentation>(for presentation: P.Type) async -> P.ContextType {
        fatalError("Not implemented for testing")
    }
}

class StandaloneNavigationService {
    func navigate(to route: TestRoute) async throws {
        throw NavigationTestError.invalidImplementation("Navigation must be Orchestrator service")
    }
}

// MARK: - Test Support Types

enum TestRoute: Equatable, Route {
    case home
    case detail(id: String)
    case settings
    
    var identifier: String {
        switch self {
        case .home:
            return "home"
        case .detail(let id):
            return "detail-\(id)"
        case .settings:
            return "settings"
        }
    }
    
    func validate() throws {
        switch self {
        case .detail(let id):
            if id.isEmpty {
                throw NavigationTestError.emptyDetailId
            }
        default:
            break
        }
    }
}

enum NavigationAction {
    case navigate(to: TestRoute)
    case navigateBack()
}

enum NavigationTestError: Error, Equatable {
    case invalidImplementation(String)
    case invalidRoute(String)
    case emptyDetailId
    case routeValidationFailed
}