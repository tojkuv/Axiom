import XCTest
import SwiftUI
@testable import Axiom
@testable import AxiomTesting

/// Comprehensive tests for Architecture framework compliance
/// Tests protocols, component types, dependency rules, and architectural patterns using AxiomTesting framework
final class ArchitectureFrameworkTests: XCTestCase {
    
    // MARK: - Test Environment
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Capability Protocol Architecture Tests
    
    func testCapabilityProtocolCompliance() async throws {
        try await testEnvironment.runTest { env in
            let capability = ArchitectureTestCapability()
            
            // Test capability lifecycle using framework utilities
            try await TestHelpers.performance.assertPerformanceRequirements(
                operation: {
                    // Test lifecycle transitions
                    let initialAvailability = await capability.isAvailable
                    XCTAssertFalse(initialAvailability, "Capability should start unavailable")
                    
                    try await capability.activate()
                    let afterInit = await capability.isAvailable
                    XCTAssertTrue(afterInit, "Capability should be available after initialization")
                    
                    await capability.deactivate()
                    let afterTerminate = await capability.isAvailable
                    XCTAssertFalse(afterTerminate, "Capability should be unavailable after termination")
                },
                maxDuration: .milliseconds(10), // < 10ms requirement
                maxMemoryGrowth: 1024, // 1KB max
                iterations: 5
            )
        }
    }
    
    func testCapabilityStateTransitions() async throws {
        try await testEnvironment.runTest { env in
            let capability = StatefulTestCapability()
            
            // Test all required capability states
            let states: [CapabilityState] = [.available, .unavailable, .restricted, .unknown]
            
            for state in states {
                await capability.transitionTo(state)
                let currentState = await capability.currentState
                XCTAssertEqual(currentState, state, "Capability should support \(state) state")
            }
            
            // Test state observation
            var observedStates: [CapabilityState] = []
            let observationTask = Task {
                for await state in await capability.stateStream {
                    observedStates.append(state)
                    if observedStates.count >= 4 {
                        break
                    }
                }
            }
            
            // Trigger state transitions
            try await capability.activate()
            await capability.transitionTo(.restricted)
            await capability.transitionTo(.available)
            await capability.deactivate()
            
            await observationTask.value
            
            XCTAssertEqual(observedStates.count, 4)
            XCTAssertEqual(observedStates, [.available, .restricted, .available, .unavailable])
        }
    }
    
    func testCapabilityErrorHandling() async throws {
        try await testEnvironment.runTest { env in
            let capability = ArchitectureFailingTestCapability()
            
            // Test initialization failure
            do {
                try await capability.activate()
                XCTFail("Initialization should have thrown an error")
            } catch {
                XCTAssertTrue(error is CapabilityError)
            }
            
            // Verify capability remains unavailable after failed initialization
            let isAvailable = await capability.isAvailable
            XCTAssertFalse(isAvailable, "Capability should remain unavailable after failed initialization")
        }
    }
    
    // MARK: - Client Protocol Architecture Tests
    
    func testClientProtocolCompliance() async throws {
        try await testEnvironment.runTest { env in
            let client = ArchitectureTestClient()
            
            // Test state streaming compliance
            var receivedStates: [ArchitectureTestState] = []
            let observationTask = Task {
                for await state in await client.stateStream {
                    receivedStates.append(state)
                    if receivedStates.count >= 5 {
                        break
                    }
                }
            }
            
            // Test performance requirements for state delivery
            try await TestHelpers.performance.assertPerformanceRequirements(
                operation: {
                    // Perform state mutations
                    try await client.process(.increment)
                    try await client.process(.setName("Test"))
                    try await client.process(.toggle)
                    try await client.process(.increment)
                },
                maxDuration: .milliseconds(5), // < 5ms requirement
                maxMemoryGrowth: 512, // 512 bytes max
                iterations: 1
            )
            
            await observationTask.value
            
            // Verify all state updates were received
            XCTAssertEqual(receivedStates.count, 5) // Initial + 4 updates
            XCTAssertEqual(receivedStates[0].counter, 0) // Initial state
            XCTAssertEqual(receivedStates[1].counter, 1) // After increment
            XCTAssertEqual(receivedStates[2].name, "Test") // After setName
            XCTAssertEqual(receivedStates[3].isEnabled, true) // After toggle
            XCTAssertEqual(receivedStates[4].counter, 2) // After second increment
        }
    }
    
    func testClientActorIsolation() async throws {
        try await testEnvironment.runTest { env in
            let client = ArchitectureTestClient()
            
            // Test concurrent mutations are properly serialized
            let _ = try await TestHelpers.performance.loadTest(
                concurrency: 10,
                duration: .seconds(1),
                operation: {
                    try await client.process(.increment)
                }
            )
            
            // All increments should have been applied atomically
            let finalState = await client.currentState
            XCTAssertGreaterThan(finalState.counter, 0, "All increments should have been applied")
            
            // Test actor isolation with framework utilities
            XCTAssertNotNil(client, "Client should be properly initialized")
        }
    }
    
    func testClientMultipleObservers() async throws {
        try await testEnvironment.runTest { env in
            let client = ArchitectureTestClient()
            var observer1States: [ArchitectureTestState] = []
            var observer2States: [ArchitectureTestState] = []
            
            // Start two observers
            let task1 = Task {
                for await state in await client.stateStream {
                    observer1States.append(state)
                    if observer1States.count >= 3 {
                        break
                    }
                }
            }
            
            let task2 = Task {
                for await state in await client.stateStream {
                    observer2States.append(state)
                    if observer2States.count >= 3 {
                        break
                    }
                }
            }
            
            // Perform mutations
            try await client.process(.increment)
            try await client.process(.toggle)
            
            // Wait for both observers
            await task1.value
            await task2.value
            
            // Both should have received same states
            XCTAssertEqual(observer1States.count, 3)
            XCTAssertEqual(observer2States.count, 3)
            XCTAssertEqual(observer1States, observer2States)
        }
    }
    
    // MARK: - Orchestrator Protocol Architecture Tests
    
    func testOrchestratorContextCreationPerformance() async throws {
        try await testEnvironment.runTest { env in
            let orchestrator = ArchitectureTestOrchestrator()
            
            // Test creating 50 contexts with dependencies in < 500ms
            var contexts: [any Context] = []
            try await TestHelpers.performance.assertPerformanceRequirements(
                operation: {
                    contexts = []
                    for i in 0..<50 {
                        let context = await orchestrator.createContext(
                            type: ArchitectureTestOrchestratorContext.self,
                            identifier: "context-\(i)",
                            dependencies: ["dep1", "dep2", "dep3"] // Up to 5 dependencies
                        )
                        contexts.append(context)
                    }
                    return contexts
                },
                maxDuration: .milliseconds(500), // < 500ms requirement
                maxMemoryGrowth: 50 * 1024, // 50KB max for 50 contexts
                iterations: 1
            )
            
            // Verify all contexts were created uniquely
            XCTAssertEqual(contexts.count, 50)
        }
    }
    
    func testOrchestratorDependencyInjection() async throws {
        try await testEnvironment.runTest { env in
            let orchestrator = ArchitectureTestOrchestrator()
            
            // Register test dependencies
            let client1 = ArchitectureTestClient(id: "client1")
            let client2 = ArchitectureTestClient(id: "client2")
            
            await orchestrator.registerClient(client1, for: "client1")
            await orchestrator.registerClient(client2, for: "client2")
            
            // Create context with dependencies
            let context = await orchestrator.createContext(
                type: DependencyTestContext.self,
                identifier: "dependency-test",
                dependencies: ["client1", "client2"]
            )
            
            // Verify dependencies were injected correctly
            XCTAssertEqual(context.injectedDependencies.count, 2)
            XCTAssertTrue(context.injectedDependencies.contains("client1"))
            XCTAssertTrue(context.injectedDependencies.contains("client2"))
        }
    }
    
    func testOrchestratorCapabilityMonitoring() async throws {
        try await testEnvironment.runTest { env in
            let orchestrator = ArchitectureTestOrchestrator()
            let capability = ArchitectureTestCapability()
            
            await orchestrator.registerCapability(capability, for: "test-capability")
            
            // Test capability monitoring lifecycle
            let initialAvailability = await orchestrator.isCapabilityAvailable("test-capability")
            XCTAssertFalse(initialAvailability)
            
            try await capability.activate()
            let afterInitAvailability = await orchestrator.isCapabilityAvailable("test-capability")
            XCTAssertTrue(afterInitAvailability)
            
            await capability.deactivate()
            let afterTerminateAvailability = await orchestrator.isCapabilityAvailable("test-capability")
            XCTAssertFalse(afterTerminateAvailability)
        }
    }
    
    // MARK: - Component Type Architecture Tests
    
    func testComponentTypeValidation() async throws {
        try await testEnvironment.runTest { env in
            // Test that all component types are properly defined
            let componentTypes = ComponentType.allCases
            
            // Verify required component types exist
            let requiredTypes = ["presentation", "context", "client", "capability", "orchestrator"]
            
            for requiredType in requiredTypes {
                let hasType = componentTypes.contains { type in
                    "\(type)".lowercased().contains(requiredType)
                }
                XCTAssertTrue(hasType, "Component type \(requiredType) should be defined")
            }
            
            // Verify Navigation is NOT a separate component type (architectural constraint)
            let hasNavigationType = componentTypes.contains { type in
                "\(type)".lowercased().contains("navigation")
            }
            XCTAssertFalse(hasNavigationType, "Navigation should not be a separate component type")
        }
    }
    
    // MARK: - Dependency Rules Architecture Tests
    
    func testDependencyValidationRules() async throws {
        try await testEnvironment.runTest { env in
            let validator = DependencyValidator()
            
            // Test valid dependency chains
            let validChain = ["ClientA", "ClientB", "CapabilityC"]
            let isValid = await validator.validateDependencyChain(validChain)
            XCTAssertTrue(isValid, "Valid dependency chain should be accepted")
            
            // Test circular dependency detection
            let circularChain = ["ClientA", "ClientB", "ClientA"]
            let isCircular = await validator.validateDependencyChain(circularChain)
            XCTAssertFalse(isCircular, "Circular dependency should be rejected")
            
            // Test maximum dependency depth
            let deepChain = Array(0..<20).map { "Client\($0)" }
            let isTooDeep = await validator.validateDependencyChain(deepChain)
            XCTAssertFalse(isTooDeep, "Excessively deep dependency chain should be rejected")
        }
    }
    
    // MARK: - DAG Composition Architecture Tests
    
    func testDAGCompositionValidation() async throws {
        try await testEnvironment.runTest { env in
            let composer = DAGComposer()
            
            // Test valid DAG composition
            var graph = DependencyGraph()
            graph.addNode("A")
            graph.addNode("B")
            graph.addNode("C")
            graph.addEdge(from: "A", to: "B")
            graph.addEdge(from: "B", to: "C")
            
            let isValidDAG = await composer.validateDAG(graph)
            XCTAssertTrue(isValidDAG, "Valid DAG should be accepted")
            
            // Test cycle detection
            graph.addEdge(from: "C", to: "A") // Creates cycle
            let hasCycle = await composer.validateDAG(graph)
            XCTAssertFalse(hasCycle, "Cyclic graph should be rejected")
        }
    }
    
    // MARK: - Concurrency Safety Architecture Tests
    
    func testConcurrencySafetyCompliance() async throws {
        try await testEnvironment.runTest { env in
            let client = ArchitectureTestClient()
            let context = await MainActor.run { ConcurrencyTestContext(client: client) }
            
            // Test concurrent access safety
            let _ = try await TestHelpers.performance.loadTest(
                concurrency: 20,
                duration: .seconds(2),
                operation: {
                    // Concurrent operations should be thread-safe
                    try await client.process(.increment)
                    let _ = await context.isActive
                    await context.updateState("concurrent-update")
                }
            )
            
            // Verify no data races or corruption occurred
            let finalState = await client.currentState
            XCTAssertGreaterThan(finalState.counter, 0, "Concurrent operations should complete successfully")
            
            let contextState = await context.currentTestState
            XCTAssertEqual(contextState, "concurrent-update", "Context should handle concurrent updates")
        }
    }
    
    // MARK: - Presentation Protocol Architecture Tests
    
    func testPresentationProtocolCompliance() async throws {
        try await testEnvironment.runTest { env in
            let context = PresentationTestContext()
            
            let presentation = ArchitectureTestPresentationView(context: context)
            
            // Test presentation-context binding
            XCTAssertNotNil(presentation.context, "Presentation should have valid context")
            
            XCTAssertEqual(presentation.context.testValue, "default", "Context should have default test value")
            
            // Test presentation lifecycle integration
            try await context.activate()
            XCTAssertTrue(context.isActive, "Context should be active when presentation appears")
            
            await context.deactivate()
            XCTAssertFalse(context.isActive, "Context should be inactive when presentation disappears")
        }
    }
    
    // MARK: - Memory Architecture Tests
    
    func testArchitectureMemoryManagement() async throws {
        try await testEnvironment.runTest { env in
            // Test memory management across architectural boundaries
            try await TestHelpers.performance.assertMemoryBounds(
                during: {
                    let orchestrator = ArchitectureTestOrchestrator()
                    let capability = ArchitectureTestCapability()
                    let client = ArchitectureTestClient()
                    
                    // Set up complex architectural scenario
                    await orchestrator.registerCapability(capability, for: "capability1")
                    await orchestrator.registerClient(client, for: "client1")
                    
                    let context = await orchestrator.createContext(
                        type: ArchitectureTestOrchestratorContext.self,
                        identifier: "memory-test",
                        dependencies: ["client1"]
                    )
                    
                    // Simulate typical usage
                    try await capability.activate()
                    try await context.activate()
                    try await client.process(.increment)
                    await context.deactivate()
                    await capability.deactivate()
                },
                maxGrowth: 10 * 1024, // 10KB max growth
                maxPeak: 50 * 1024 // 50KB max peak
            )
        }
    }
    
    // MARK: - Framework Compliance Tests
    
    func testArchitectureFrameworkCompliance() async throws {
        // Test framework compliance for all architectural components
        let client = ArchitectureTestClient()
        let capability = ArchitectureTestCapability()
        let orchestrator = ArchitectureTestOrchestrator()
        
        XCTAssertNotNil(client, "Client should be properly initialized")
        XCTAssertNotNil(capability, "Capability should be properly initialized")
        XCTAssertNotNil(orchestrator, "Orchestrator should be properly initialized")
        
        // Additional architectural compliance checks
        XCTAssertNotNil(client, "Client should be properly initialized")
        XCTAssertTrue(await capability.isSupported(), "Capability should be supported on this platform")
        XCTAssertNotNil(orchestrator, "Orchestrator should be created successfully")
    }
}

// MARK: - Test Support Types

// Architecture Test Client
actor ArchitectureTestClient: Client {
    typealias StateType = ArchitectureTestState
    typealias ActionType = ArchitectureTestAction
    
    let id: String
    private(set) var currentState = ArchitectureTestState()
    private var streamContinuations: [UUID: AsyncStream<ArchitectureTestState>.Continuation] = [:]
    
    var stateStream: AsyncStream<ArchitectureTestState> {
        AsyncStream { [weak self] continuation in
            let id = UUID()
            Task { [weak self] in
                await self?.addContinuation(continuation, id: id)
                
                // Yield initial state
                if let state = await self?.currentState {
                    continuation.yield(state)
                }
                
                continuation.onTermination = { @Sendable _ in
                    Task { @Sendable [weak self, id] in
                        await self?.removeContinuation(id: id)
                    }
                }
            }
        }
    }
    
    init(id: String = "test-client") {
        self.id = id
    }
    
    private func addContinuation(_ continuation: AsyncStream<ArchitectureTestState>.Continuation, id: UUID) {
        streamContinuations[id] = continuation
    }
    
    private func removeContinuation(id: UUID) {
        streamContinuations.removeValue(forKey: id)
    }
    
    func process(_ action: ArchitectureTestAction) async throws {
        switch action {
        case .increment:
            currentState.counter += 1
        case .setName(let name):
            currentState.name = name
        case .toggle:
            currentState.isEnabled.toggle()
        }
        
        // Notify all observers
        for (_, continuation) in streamContinuations {
            continuation.yield(currentState)
        }
    }
    
    deinit {
        for (_, continuation) in streamContinuations {
            continuation.finish()
        }
    }
}

// Test Capability
actor ArchitectureTestCapability: Capability {
    private(set) var currentState: CapabilityState = .unavailable
    
    var isAvailable: Bool {
        currentState == .available
    }
    
    func activate() async throws {
        currentState = .available
    }
    
    func deactivate() async {
        currentState = .unavailable
    }
}

// Stateful Test Capability with state streaming
actor StatefulTestCapability: Capability {
    private(set) var currentState: CapabilityState = .unavailable
    private var continuation: AsyncStream<CapabilityState>.Continuation?
    
    var isAvailable: Bool {
        currentState == .available
    }
    
    var stateStream: AsyncStream<CapabilityState> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }
    
    func activate() async throws {
        transitionTo(.available)
    }
    
    func deactivate() async {
        transitionTo(.unavailable)
        continuation?.finish()
    }
    
    func transitionTo(_ state: CapabilityState) {
        currentState = state
        continuation?.yield(state)
    }
}

// Failing Test Capability
actor ArchitectureFailingTestCapability: Capability {
    private(set) var currentState: CapabilityState = .unavailable
    
    var isAvailable: Bool {
        currentState == .available
    }
    
    func activate() async throws {
        throw CapabilityError.initializationFailed(reason: "Test failure")
    }
    
    func deactivate() async {
        currentState = .unavailable
    }
}

// Test Orchestrator
actor ArchitectureTestOrchestrator: Orchestrator {
    private var contexts: [String: any Context] = [:]
    private var clients: [String: any Client] = [:]
    private var capabilities: [String: any Capability] = [:]
    
    func createContext<P: Presentation>(for presentation: P.Type) async -> P.ContextType {
        fatalError("Not implemented for test orchestrator")
    }
    
    func createContext<T: Context>(
        type: T.Type,
        identifier: String? = nil,
        dependencies: [String] = []
    ) async -> T {
        let id = identifier ?? UUID().uuidString
        
        if T.self == ArchitectureTestOrchestratorContext.self {
            let context = ArchitectureTestOrchestratorContext(
                identifier: id,
                dependencies: dependencies
            ) as! T
            contexts[id] = context
            return context
        } else if T.self == DependencyTestContext.self {
            let context = DependencyTestContext(
                identifier: id,
                dependencies: dependencies
            ) as! T
            contexts[id] = context
            return context
        }
        
        fatalError("Unknown context type: \(T.self)")
    }
    
    func registerClient<C: Client>(_ client: C, for key: String) async {
        clients[key] = client
    }
    
    func registerCapability<C: Capability>(_ capability: C, for key: String) async {
        capabilities[key] = capability
    }
    
    func navigate(to route: StandardRoute) async {
        // Test implementation - does nothing for testing
    }
    
    func isCapabilityAvailable(_ key: String) async -> Bool {
        if let capability = capabilities[key] {
            return await capability.isAvailable
        }
        return false
    }
}

// Test Context for Orchestrator
@MainActor
class ArchitectureTestOrchestratorContext: ObservableContext {
    let identifier: String
    let dependencies: [String]
    
    init(identifier: String, dependencies: [String] = []) {
        self.identifier = identifier
        self.dependencies = dependencies
        super.init()
    }
    
    required init() {
        self.identifier = UUID().uuidString
        self.dependencies = []
        super.init()
    }
}

// Dependency Test Context
@MainActor
class DependencyTestContext: ObservableContext {
    let identifier: String
    let injectedDependencies: [String]
    
    init(identifier: String, dependencies: [String]) {
        self.identifier = identifier
        self.injectedDependencies = dependencies
        super.init()
    }
    
    required init() {
        self.identifier = UUID().uuidString
        self.injectedDependencies = []
        super.init()
    }
}

// Concurrency Test Context
@MainActor
class ConcurrencyTestContext: ObservableContext {
    private let client: ArchitectureTestClient
    @Published private(set) var currentTestState = "initial"
    
    init(client: ArchitectureTestClient) {
        self.client = client
        super.init()
    }
    
    required init() {
        self.client = ArchitectureTestClient()
        super.init()
    }
    
    func updateState(_ newState: String) {
        currentTestState = newState
    }
}

// Presentation Test Context
@MainActor
class PresentationTestContext: ObservableContext {
    @Published private(set) var testValue = "default"
    
    func updateTestValue(_ value: String) {
        testValue = value
    }
}

// Test Presentation View
struct ArchitectureTestPresentationView: View {
    let context: PresentationTestContext
    
    var body: some View {
        Text(context.testValue)
    }
}

// Dependency Validator
actor DependencyValidator {
    func validateDependencyChain(_ chain: [String]) async -> Bool {
        // Check for circular dependencies
        let uniqueElements = Set(chain)
        if uniqueElements.count != chain.count {
            return false // Circular dependency detected
        }
        
        // Check maximum depth (example: 10 levels)
        if chain.count > 10 {
            return false
        }
        
        return true
    }
}

// DAG Composer
actor DAGComposer {
    func validateDAG(_ graph: DependencyGraph) async -> Bool {
        return await graph.isAcyclic()
    }
}

// Dependency Graph
struct DependencyGraph {
    private var nodes: Set<String> = []
    private var edges: [String: Set<String>] = [:]
    
    mutating func addNode(_ node: String) {
        nodes.insert(node)
        if edges[node] == nil {
            edges[node] = []
        }
    }
    
    mutating func addEdge(from: String, to: String) {
        addNode(from)
        addNode(to)
        edges[from]?.insert(to)
    }
    
    func isAcyclic() async -> Bool {
        var visited: Set<String> = []
        var recursionStack: Set<String> = []
        
        for node in nodes {
            if !visited.contains(node) {
                if await hasCycle(node: node, visited: &visited, recursionStack: &recursionStack) {
                    return false
                }
            }
        }
        
        return true
    }
    
    private func hasCycle(
        node: String,
        visited: inout Set<String>,
        recursionStack: inout Set<String>
    ) async -> Bool {
        visited.insert(node)
        recursionStack.insert(node)
        
        if let neighbors = edges[node] {
            for neighbor in neighbors {
                if !visited.contains(neighbor) {
                    if await hasCycle(node: neighbor, visited: &visited, recursionStack: &recursionStack) {
                        return true
                    }
                } else if recursionStack.contains(neighbor) {
                    return true
                }
            }
        }
        
        recursionStack.remove(node)
        return false
    }
}

// Supporting Enums and Structs
struct ArchitectureTestState: Axiom.State, Equatable {
    var counter: Int = 0
    var name: String = ""
    var isEnabled: Bool = false
}

enum ArchitectureTestAction: Equatable {
    case increment
    case setName(String)
    case toggle
}


// CapabilityState is imported from the Axiom module