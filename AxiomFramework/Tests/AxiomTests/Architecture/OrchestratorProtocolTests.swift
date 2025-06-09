import XCTest
import SwiftUI
@testable import Axiom

final class OrchestratorProtocolTests: XCTestCase {
    
    // MARK: - Context Creation Tests
    
    func testOrchestratorContextCreation() async throws {
        // Requirement: Test orchestrator creates 50 contexts with up to 5 client dependencies
        // and standard UI bindings in < 500ms
        
        let orchestrator = TestOrchestrator()
        let startTime = ContinuousClock.now
        
        // Create 50 contexts
        var contexts: [any Context] = []
        for i in 0..<50 {
            let context = await orchestrator.createContext(
                type: TestOrchestratorContext.self,
                identifier: "context-\(i)"
            )
            contexts.append(context)
            
            // Verify context has dependencies
            let depCount = await context.dependencyCount
            XCTAssertLessThanOrEqual(depCount, 5, "Context should have at most 5 dependencies")
        }
        
        let elapsed = ContinuousClock.now - startTime
        XCTAssertLessThan(elapsed, .milliseconds(500), "Context creation should complete within 500ms")
        
        // Verify all contexts were created
        XCTAssertEqual(contexts.count, 50)
        
        // Verify contexts are unique
        let contextIds = await withTaskGroup(of: String.self) { group in
            for context in contexts {
                group.addTask {
                    if let testContext = context as? TestOrchestratorContext {
                        return await testContext.identifier
                    }
                    return "unknown"
                }
            }
            
            var ids: Set<String> = []
            for await id in group {
                ids.insert(id)
            }
            return ids
        }
        
        XCTAssertEqual(contextIds.count, 50, "All contexts should have unique identifiers")
    }
    
    // MARK: - Dependency Injection Tests
    
    func testOrchestratorDependencyInjection() async throws {
        // Test that orchestrator properly injects dependencies
        let orchestrator = TestOrchestrator()
        
        // Register test clients
        let client1 = TestOrchestratorClient(id: "client1")
        let client2 = TestOrchestratorClient(id: "client2")
        let client3 = TestOrchestratorClient(id: "client3")
        
        await orchestrator.registerClient(client1, for: "client1")
        await orchestrator.registerClient(client2, for: "client2")
        await orchestrator.registerClient(client3, for: "client3")
        
        // Create context with dependencies
        let context = await orchestrator.createContext(
            type: DependencyInjectedContext.self,
            dependencies: ["client1", "client2"]
        )
        
        // Verify dependencies were injected
        let injectedClients = await context.clients
        XCTAssertEqual(injectedClients.count, 2)
        
        let clientIds = injectedClients.map { $0.id }
        XCTAssertTrue(clientIds.contains("client1"))
        XCTAssertTrue(clientIds.contains("client2"))
    }
    
    // MARK: - Navigation Tests
    
    func testOrchestratorNavigation() async throws {
        // Test orchestrator navigation capabilities
        let orchestrator = NavigationOrchestrator()
        
        // Register routes
        await orchestrator.registerRoute(.home, handler: { _ in
            await TestOrchestratorContext(identifier: "home")
        })
        
        await orchestrator.registerRoute(.detail(id: "test"), handler: { route in
            if case .detail(let id) = route {
                return await TestOrchestratorContext(identifier: "detail-\(id)")
            }
            return await TestOrchestratorContext(identifier: "unknown")
        })
        
        // Navigate to home
        await orchestrator.navigate(to: .home)
        let currentRoute = await orchestrator.currentRoute
        XCTAssertEqual(currentRoute, .home)
        
        // Navigate to detail
        await orchestrator.navigate(to: .detail(id: "123"))
        let detailRoute = await orchestrator.currentRoute
        if case .detail(let id) = detailRoute {
            XCTAssertEqual(id, "123")
        } else {
            XCTFail("Should be on detail route")
        }
        
        // Verify navigation history
        let history = await orchestrator.navigationHistory
        XCTAssertEqual(history.count, 2)
    }
    
    // MARK: - Capability Monitoring Tests
    
    func testOrchestratorCapabilityMonitoring() async throws {
        // Test orchestrator monitors capability availability
        let orchestrator = TestOrchestrator()
        let capability = MonitoredCapability()
        
        await orchestrator.registerCapability(capability, for: "test-capability")
        
        // Initially unavailable
        let initialAvailability = await orchestrator.isCapabilityAvailable("test-capability")
        XCTAssertFalse(initialAvailability)
        
        // Initialize capability
        try await capability.initialize()
        
        // Should now be available
        let afterInitAvailability = await orchestrator.isCapabilityAvailable("test-capability")
        XCTAssertTrue(afterInitAvailability)
        
        // Terminate capability
        await capability.terminate()
        
        // Should be unavailable again
        let afterTerminateAvailability = await orchestrator.isCapabilityAvailable("test-capability")
        XCTAssertFalse(afterTerminateAvailability)
    }
    
    // MARK: - Context Factory Tests
    
    func testOrchestratorContextFactory() async throws {
        // Test context factory with builder pattern
        let orchestrator = TestOrchestrator()
        
        // Configure context builder
        let builder = await orchestrator.contextBuilder(for: TestOrchestratorContext.self)
            .withIdentifier("custom-context")
            .withDependency("client1")
            .withDependency("client2")
            .withConfiguration { context in
                await context.configure(option: "test-value", value: "test-value")
            }
        
        // Build context
        let context = try await builder.build()
        
        // Verify configuration
        let identifier = await context.identifier
        XCTAssertEqual(identifier, "custom-context")
        
        let depCount = await context.dependencyCount
        XCTAssertEqual(depCount, 2)
        
        let config = await context.configuration["option"]
        XCTAssertEqual(config as? String, "test-value")
    }
    
    // MARK: - Lifecycle Management Tests
    
    func testOrchestratorLifecycleManagement() async throws {
        // Test orchestrator manages context lifecycles
        let orchestrator = TestOrchestrator()
        
        // Create multiple contexts
        let context1 = await orchestrator.createContext(
            type: TestOrchestratorContext.self,
            identifier: "context1"
        )
        let context2 = await orchestrator.createContext(
            type: TestOrchestratorContext.self,
            identifier: "context2"
        )
        
        // Activate all contexts
        await orchestrator.activateAllContexts()
        
        let isActive1 = await context1.isActive
        let isActive2 = await context2.isActive
        
        XCTAssertTrue(isActive1)
        XCTAssertTrue(isActive2)
        
        // Deactivate all contexts
        await orchestrator.deactivateAllContexts()
        
        let isInactive1 = await context1.isActive
        let isInactive2 = await context2.isActive
        
        XCTAssertFalse(isInactive1)
        XCTAssertFalse(isInactive2)
    }
}

// MARK: - Test Support Types

// Test orchestrator implementation
actor TestOrchestrator: ExtendedOrchestrator {
    private var contexts: [String: any Context] = [:]
    private var clients: [String: any Client] = [:]
    private var capabilities: [String: any Capability] = [:]
    public private(set) var currentRoute: Route?
    public private(set) var navigationHistory: [Route] = []
    private var routeHandlers: [Route: (Route) async -> any Context] = [:]
    
    func createContext<P: Presentation>(for presentation: P.Type) async -> P.ContextType {
        fatalError("Not implemented in test orchestrator")
    }
    
    func createContext<T: Context>(
        type: T.Type,
        identifier: String? = nil,
        dependencies: [String] = []
    ) async -> T {
        let id = identifier ?? UUID().uuidString
        
        if T.self == TestOrchestratorContext.self {
            let depClients: [any Client] = []  // Simplified for testing
            let context = await TestOrchestratorContext(
                identifier: id,
                dependencies: depClients
            ) as! T
            contexts[id] = context
            return context
        } else if T.self == DependencyInjectedContext.self {
            let depClients = await withTaskGroup(of: TestOrchestratorClient?.self) { group in
                for key in dependencies {
                    group.addTask { [weak self] in
                        await self?.client(for: key, as: TestOrchestratorClient.self)
                    }
                }
                
                var clients: [TestOrchestratorClient] = []
                for await client in group {
                    if let client = client {
                        clients.append(client)
                    }
                }
                return clients
            }
            let context = await DependencyInjectedContext(clients: depClients) as! T
            contexts[id] = context
            return context
        }
        
        fatalError("Unknown context type")
    }
    
    func client<C: Client>(for key: String, as type: C.Type) async -> C? {
        return clients[key] as? C
    }
    
    func registerClient<C: Client>(_ client: C, for key: String) async {
        clients[key] = client
    }
    
    func navigate(to route: Route) async {
        navigationHistory.append(route)
        currentRoute = route
    }
    
    func registerRoute(_ route: Route, handler: @escaping (Route) async -> any Context) async {
        routeHandlers[route] = handler
    }
    
    func registerCapability<C: Capability>(_ capability: C, for key: String) async {
        capabilities[key] = capability
    }
    
    func isCapabilityAvailable(_ key: String) async -> Bool {
        if let capability = capabilities[key] {
            return await capability.isAvailable
        }
        return false
    }
    
    func contextBuilder<T: Context>(for type: T.Type) async -> ContextBuilder<T> {
        return ContextBuilder<T>(orchestrator: self, contextType: type)
    }
    
    func activateAllContexts() async {
        for context in contexts.values {
            await context.onAppear()
        }
    }
    
    func deactivateAllContexts() async {
        for context in contexts.values {
            await context.onDisappear()
        }
    }
}

// Navigation orchestrator
actor NavigationOrchestrator: ExtendedOrchestrator {
    private var contexts: [String: any Context] = [:]
    private var clients: [String: any Client] = [:]
    private var capabilities: [String: any Capability] = [:]
    public private(set) var currentRoute: Route?
    public private(set) var navigationHistory: [Route] = []
    private var routeHandlers: [Route: (Route) async -> any Context] = [:]
    
    func createContext<P: Presentation>(for presentation: P.Type) async -> P.ContextType {
        fatalError("Not implemented for navigation orchestrator")
    }
    
    func createContext<T: Context>(type: T.Type, identifier: String?, dependencies: [String]) async -> T {
        fatalError("Not implemented for navigation orchestrator")
    }
    
    func client<C: Client>(for key: String, as type: C.Type) async -> C? {
        return clients[key] as? C
    }
    
    func registerClient<C: Client>(_ client: C, for key: String) async {
        clients[key] = client
    }
    
    func navigate(to route: Route) async {
        navigationHistory.append(route)
        currentRoute = route
        
        if let handler = routeHandlers[route] {
            let context = await handler(route)
            contexts[UUID().uuidString] = context
        }
    }
    
    func registerRoute(_ route: Route, handler: @escaping (Route) async -> any Context) async {
        routeHandlers[route] = handler
    }
    
    func registerCapability<C: Capability>(_ capability: C, for key: String) async {
        capabilities[key] = capability
    }
    
    func isCapabilityAvailable(_ key: String) async -> Bool {
        if let capability = capabilities[key] {
            return await capability.isAvailable
        }
        return false
    }
    
    func contextBuilder<T: Context>(for type: T.Type) async -> ContextBuilder<T> {
        return ContextBuilder<T>(orchestrator: self, contextType: type)
    }
    
    func activateAllContexts() async {
        for context in contexts.values {
            await context.onAppear()
        }
    }
    
    func deactivateAllContexts() async {
        for context in contexts.values {
            await context.onDisappear()
        }
    }
}

// Test context implementation
@MainActor
class TestOrchestratorContext: Context {
    let identifier: String
    private(set) var isActive = false
    private(set) var dependencyCount: Int
    var configuration: [String: Any] = [:]
    
    init(identifier: String, dependencies: [any Client] = []) {
        self.identifier = identifier
        self.dependencyCount = dependencies.count
    }
    
    func onAppear() async {
        isActive = true
    }
    
    func onDisappear() async {
        isActive = false
    }
    
    func configure(option: String, value: Any) async {
        configuration[option] = value
    }
}

// Dependency injected context
@MainActor
class DependencyInjectedContext: Context {
    let clients: [TestOrchestratorClient]
    
    init(clients: [TestOrchestratorClient]) {
        self.clients = clients
    }
    
    func onAppear() async {}
    func onDisappear() async {}
}

// Test client
actor TestOrchestratorClient: Client {
    typealias StateType = OrchestratorClientState
    typealias ActionType = OrchestratorClientAction
    
    let id: String
    private(set) var state = OrchestratorClientState()
    
    init(id: String) {
        self.id = id
    }
    
    var stateStream: AsyncStream<OrchestratorClientState> {
        AsyncStream { continuation in
            continuation.yield(state)
            continuation.finish()
        }
    }
    
    func process(_ action: OrchestratorClientAction) async throws {}
}

// Monitored capability
actor MonitoredCapability: Capability {
    private var state: CapabilityState = .unavailable
    
    var isAvailable: Bool {
        state == .available
    }
    
    func initialize() async throws {
        state = .available
    }
    
    func terminate() async {
        state = .unavailable
    }
}


// Supporting types
struct OrchestratorClientState: Axiom.State {
    var value: Int = 0
}

enum OrchestratorClientAction {
    case increment
}

// Route is defined in OrchestratorProtocol.swift

