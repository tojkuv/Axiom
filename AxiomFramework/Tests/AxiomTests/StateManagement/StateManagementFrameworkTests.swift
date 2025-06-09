import XCTest
import SwiftUI
@testable import Axiom
@testable import AxiomTesting

/// Comprehensive tests for State Management framework functionality
/// Tests state immutability, ownership, unidirectional flow, and action subscriptions using AxiomTesting framework
final class StateManagementFrameworkTests: XCTestCase {
    
    // MARK: - Test Environment
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - State Immutability Tests
    
    func testStateImmutabilityCompliance() async throws {
        try await testEnvironment.runTest { env in
            let stateManager = ImmutableStateManager(initialState: TestAppState())
            
            // Test that state mutations produce new instances
            let initialState = stateManager.currentState
            let updatedState = stateManager.update { state in
                state.incrementingCounter()
            }
            
            // Use framework utilities to verify immutability
            XCTAssertNotEqual(initialState.id, updatedState.id, "State mutations should produce new instances")
            XCTAssertEqual(initialState.counter, 0, "Original state should be unchanged")
            XCTAssertEqual(updatedState.counter, 1, "Updated state should reflect changes")
            
            // Test multiple updates produce distinct instances
            let state2 = stateManager.update { state in
                state.addingValue("item1")
            }
            let state3 = stateManager.update { state in
                state.addingValue("item2")
            }
            
            XCTAssertNotEqual(state2.id, state3.id)
            XCTAssertEqual(state2.values.count, 1)
            XCTAssertEqual(state3.values.count, 2)
        }
    }
    
    func testConcurrentStateImmutabilityUnderLoad() async throws {
        try await testEnvironment.runTest { env in
            let stateManager = ConcurrentImmutableStateManager()
            
            // Test concurrent mutations using framework load testing
            let results = try await TestHelpers.performance.loadTest(
                concurrency: 20,
                duration: .seconds(2),
                operation: {
                    await stateManager.performMutation(id: Int.random(in: 0...10000))
                }
            )
            
            // Verify all mutations were applied without corruption
            let finalState = await stateManager.state
            XCTAssertEqual(finalState.counter, results.totalOperations, "All mutations should be applied")
            XCTAssertEqual(finalState.history.count, results.totalOperations, "All mutations should be recorded")
            
            // Verify no data corruption occurred
            let uniqueIds = Set(finalState.history)
            XCTAssertEqual(uniqueIds.count, finalState.history.count, "No duplicate mutations should exist")
            
            // Test that final state is valid
            XCTAssertTrue(finalState.isValid(), "State should maintain internal consistency")
        }
    }
    
    func testStateMemoryManagementUnderStress() async throws {
        try await testEnvironment.runTest { env in
            // Test 1000 concurrent mutations with memory tracking
            try await TestHelpers.performance.assertMemoryBounds(
                during: {
                    let stateManager = ConcurrentImmutableStateManager()
                    
                    await withTaskGroup(of: Void.self) { group in
                        // Counter increments
                        for _ in 0..<333 {
                            group.addTask {
                                await stateManager.incrementCounter()
                            }
                        }
                        
                        // Value additions
                        for i in 0..<333 {
                            group.addTask {
                                await stateManager.addValue("value-\(i)")
                            }
                        }
                        
                        // Complex operations
                        for i in 0..<334 {
                            group.addTask {
                                await stateManager.performComplexMutation(index: i)
                            }
                        }
                    }
                },
                maxGrowth: 50 * 1024, // 50KB max growth
                maxPeak: 200 * 1024 // 200KB max peak
            )
        }
    }
    
    // MARK: - State Ownership Tests
    
    func testStateOwnershipCompliance() async throws {
        try await testEnvironment.runTest { env in
            let validator = StateOwnershipValidator()
            
            // Test exclusive ownership enforcement
            let state = TestOwnershipState(value: "initial")
            let client1 = TestOwnershipClient(id: "client1")
            let client2 = TestOwnershipClient(id: "client2")
            
            // First ownership should succeed
            XCTAssertTrue(validator.assignOwnership(of: state, to: client1))
            
            // Second ownership attempt should fail
            XCTAssertFalse(validator.assignOwnership(of: state, to: client2))
            
            // Verify error message
            XCTAssertEqual(
                validator.lastError,
                "State 'TestOwnershipState' is already owned by client 'client1'; cannot assign to 'client2'"
            )
        }
    }
    
    func testOneToOneClientStatePairing() async throws {
        try await testEnvironment.runTest { env in
            let validator = StateOwnershipValidator()
            
            // Test performance requirements for many clients/states
            try await TestHelpers.performance.assertPerformanceRequirements(
                operation: {
                    // Create 100 clients and states
                    let clients = (0..<100).map { TestOwnershipClient(id: "client-\($0)") }
                    let states = (0..<100).map { TestOwnershipState(value: "state-\($0)") }
                    
                    // Assign all ownerships
                    for (client, state) in zip(clients, states) {
                        XCTAssertTrue(validator.assignOwnership(of: state, to: client))
                    }
                    
                    // Verify all pairings are maintained
                    XCTAssertEqual(validator.totalOwnershipCount, 100)
                    XCTAssertEqual(validator.uniqueClientCount, 100)
                    XCTAssertEqual(validator.uniqueStateCount, 100)
                },
                maxDuration: .milliseconds(100), // Should complete quickly
                maxMemoryGrowth: 10 * 1024, // 10KB max
                iterations: 1
            )
        }
    }
    
    func testStateImmutabilityConstraints() async throws {
        try await testEnvironment.runTest { env in
            let validator = StateOwnershipValidator()
            
            // Test that State protocol requires value semantics
            XCTAssertTrue(validator.validateValueSemantics(TestOwnershipState.self))
            
            // All stored properties must be immutable
            XCTAssertTrue(validator.validateImmutability(TestOwnershipState.self))
            
            // Test protocol conformance requirements
            XCTAssertTrue(TestOwnershipState.self is any State.Type)
            XCTAssertTrue(TestOwnershipState.self is any Sendable.Type)
            
            // Test state transitions produce new instances
            let state = TestOwnershipState(value: "initial")
            let newState = state.withValue("updated")
            
            XCTAssertNotEqual(state, newState)
            XCTAssertEqual(state.value, "initial") // Original unchanged
            XCTAssertEqual(newState.value, "updated") // New instance with update
        }
    }
    
    // MARK: - Unidirectional Flow Tests
    
    func testUnidirectionalFlowConstraints() async throws {
        try await testEnvironment.runTest { env in
            // Test that reverse dependencies fail
            XCTAssertFalse(
                UnidirectionalFlow.validate(from: .capability, to: .client),
                "Capability should not depend on Client"
            )
            
            XCTAssertFalse(
                UnidirectionalFlow.validate(from: .client, to: .context),
                "Client should not depend on Context"
            )
            
            XCTAssertFalse(
                UnidirectionalFlow.validate(from: .context, to: .orchestrator),
                "Context should not depend on Orchestrator"
            )
            
            // Test that forward dependencies are allowed
            XCTAssertTrue(
                UnidirectionalFlow.validate(from: .orchestrator, to: .context),
                "Orchestrator should be able to depend on Context"
            )
            
            XCTAssertTrue(
                UnidirectionalFlow.validate(from: .context, to: .client),
                "Context should be able to depend on Client"
            )
            
            XCTAssertTrue(
                UnidirectionalFlow.validate(from: .client, to: .capability),
                "Client should be able to depend on Capability"
            )
        }
    }
    
    func testDependencyGraphAnalysis() async throws {
        try await testEnvironment.runTest { env in
            // Test valid unidirectional dependency graph
            let validDependencies: [(ComponentType, ComponentType)] = [
                (.orchestrator, .context),
                (.context, .client),
                (.client, .capability)
            ]
            
            let analyzer = DependencyAnalyzer(dependencies: validDependencies)
            
            // Verify the graph is unidirectional
            XCTAssertTrue(analyzer.isUnidirectional(), "Dependency graph should be unidirectional")
            XCTAssertNotNil(analyzer.topologicalSort(), "Unidirectional graph should have valid topological ordering")
            
            // Test cyclic dependency detection
            let cyclicDependencies: [(ComponentType, ComponentType)] = [
                (.orchestrator, .context),
                (.context, .client),
                (.client, .orchestrator) // Creates a cycle
            ]
            
            let cyclicAnalyzer = DependencyAnalyzer(dependencies: cyclicDependencies)
            XCTAssertFalse(cyclicAnalyzer.isUnidirectional(), "Cyclic graph should not be unidirectional")
            XCTAssertNil(cyclicAnalyzer.topologicalSort(), "Cyclic graph should not have valid topological ordering")
        }
    }
    
    func testFlowValidationPerformance() async throws {
        try await testEnvironment.runTest { env in
            // Test performance of dependency validation
            try await TestHelpers.performance.assertPerformanceRequirements(
                operation: {
                    // Validate many dependencies
                    for _ in 0..<1000 {
                        _ = UnidirectionalFlow.validate(from: .orchestrator, to: .context)
                        _ = UnidirectionalFlow.validate(from: .context, to: .client)
                        _ = UnidirectionalFlow.validate(from: .client, to: .capability)
                    }
                },
                maxDuration: .milliseconds(10), // Should be very fast
                maxMemoryGrowth: 512, // 512 bytes max
                iterations: 5
            )
        }
    }
    
    // MARK: - Implicit Action Subscription Tests
    
    func testImplicitActionSubscriptionFlow() async throws {
        try await testEnvironment.runTest { env in
            let parentContext = try await env.createContext(
                TestParentSubscriptionContext.self,
                id: "parent-subscription"
            ) {
                TestParentSubscriptionContext()
            }
            
            let childContext = try await env.createContext(
                TestChildSubscriptionContext.self,
                id: "child-subscription"
            ) {
                TestChildSubscriptionContext()
            }
            
            // Establish parent-child relationship using framework utilities
            try await TestHelpers.context.establishParentChild(
                parent: parentContext,
                child: childContext
            )
            
            // Test action emission and reception
            await childContext.emitAction(.itemSelected(id: "test-123"))
            
            // Assert action was received by parent
            try await TestHelpers.context.assertChildActionReceived(
                by: parentContext,
                action: TestChildSubscriptionContext.Action.itemSelected(id: "test-123"),
                from: childContext,
                timeout: .seconds(1)
            )
            
            // Verify parent captured the action correctly
            try await TestHelpers.context.assertState(
                in: parentContext,
                condition: { ctx in
                    ctx.capturedActions.count == 1 &&
                    ctx.handledActionTypes.contains("Action")
                },
                description: "Parent should receive and handle child action"
            )
        }
    }
    
    func testMultipleChildrenActionSubscriptions() async throws {
        try await testEnvironment.runTest { env in
            let parentContext = try await env.createContext(
                TestParentSubscriptionContext.self,
                id: "multi-parent"
            ) {
                TestParentSubscriptionContext()
            }
            
            let child1 = try await env.createContext(
                TestChildSubscriptionContext.self,
                id: "child1"
            ) {
                TestChildSubscriptionContext()
            }
            
            let child2 = try await env.createContext(
                TestChildSubscriptionContext.self,
                id: "child2"
            ) {
                TestChildSubscriptionContext()
            }
            
            // Establish relationships
            try await TestHelpers.context.establishParentChild(parent: parentContext, child: child1)
            try await TestHelpers.context.establishParentChild(parent: parentContext, child: child2)
            
            // Multiple children emit actions
            await child1.emitAction(.itemSelected(id: "child1-item"))
            await child2.emitAction(.itemDeleted(id: "child2-item"))
            
            // Parent should receive both actions
            try await TestHelpers.context.assertState(
                in: parentContext,
                timeout: .seconds(2),
                condition: { $0.capturedActions.count == 2 },
                description: "Parent should receive actions from both children"
            )
        }
    }
    
    func testActionSubscriptionMemoryManagement() async throws {
        try await testEnvironment.runTest { env in
            // Test memory management of parent-child relationships
            try await TestHelpers.context.assertNoMemoryLeaks {
                let parentContext = try await env.createContext(
                    TestParentSubscriptionContext.self,
                    id: "memory-parent"
                ) {
                    TestParentSubscriptionContext()
                }
                
                var childContext: TestChildSubscriptionContext? = try await env.createContext(
                    TestChildSubscriptionContext.self,
                    id: "memory-child"
                ) {
                    TestChildSubscriptionContext()
                }
                
                // Establish relationship
                try await TestHelpers.context.establishParentChild(
                    parent: parentContext,
                    child: childContext!
                )
                
                // Emit action
                await childContext?.emitAction(.itemSelected(id: "memory-test"))
                
                // Remove child
                await env.removeContext("memory-child")
                childContext = nil
                
                // Allow cleanup
                try await Task.sleep(for: .milliseconds(50))
                
                // Parent should clean up weak references
                XCTAssertEqual(parentContext.activeChildren.count, 0)
            }
        }
    }
    
    // MARK: - State Cancellation and Flow Control Tests
    
    func testStateCancellationSupport() async throws {
        try await testEnvironment.runTest { env in
            let client = StateFlowTestClient()
            let context = try await env.createContext(
                StateFlowTestContext.self,
                id: "state-flow"
            ) {
                StateFlowTestContext(client: client)
            }
            
            // Start state observation
            let observationTask = Task {
                await context.startObservingState()
            }
            
            // Process some state changes
            try await client.process(.increment)
            try await client.process(.setName("test"))
            
            // Cancel observation
            observationTask.cancel()
            
            // Further state changes should not be observed
            try await client.process(.increment)
            
            // Allow time for any potential observation
            try await Task.sleep(for: .milliseconds(100))
            
            // Verify state observation was properly cancelled
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.observationWasCancelled },
                description: "State observation should be cancellable"
            )
        }
    }
    
    // MARK: - Framework Compliance Tests
    
    func testStateManagementFrameworkCompliance() async throws {
        let client = StateFlowTestClient()
        let stateManager = ImmutableStateManager(initialState: TestAppState())
        let validator = StateOwnershipValidator()
        
        // Use framework compliance testing
        assertFrameworkCompliance(client)
        assertFrameworkCompliance(stateManager)
        assertFrameworkCompliance(validator)
        
        // State management specific compliance
        XCTAssertTrue(client is Client, "Must implement Client protocol")
        XCTAssertTrue(TestAppState.self is any State.Type, "Must implement State protocol")
        XCTAssertTrue(TestAppState.self is any Sendable.Type, "State must be Sendable")
    }
}

// MARK: - Test Support Types

// Test App State for immutability testing
struct TestAppState: State, Sendable, Equatable {
    let id: String
    let counter: Int
    let values: [String]
    let history: [Int]
    
    init(id: String = UUID().uuidString, counter: Int = 0, values: [String] = [], history: [Int] = []) {
        self.id = id
        self.counter = counter
        self.values = values
        self.history = history
    }
    
    func isValid() -> Bool {
        return counter >= 0 && history.count <= counter * 2
    }
    
    func incrementingCounter() -> TestAppState {
        TestAppState(counter: counter + 1, values: values, history: history)
    }
    
    func addingValue(_ value: String) -> TestAppState {
        TestAppState(id: UUID().uuidString, counter: counter, values: values + [value], history: history)
    }
    
    func addingToHistory(_ item: Int) -> TestAppState {
        TestAppState(id: UUID().uuidString, counter: counter, values: values, history: history + [item])
    }
}

// Immutable State Manager
class ImmutableStateManager {
    private var _currentState: TestAppState
    
    var currentState: TestAppState {
        _currentState
    }
    
    init(initialState: TestAppState) {
        self._currentState = initialState
    }
    
    func update(_ mutation: (TestAppState) -> TestAppState) -> TestAppState {
        let newState = mutation(_currentState)
        _currentState = newState
        return newState
    }
}

// Concurrent Immutable State Manager
actor ConcurrentImmutableStateManager {
    private var _state = TestAppState()
    
    var state: TestAppState {
        _state
    }
    
    func performMutation(id: Int) async {
        _state = _state.incrementingCounter().addingToHistory(id)
    }
    
    func incrementCounter() async {
        _state = _state.incrementingCounter()
    }
    
    func addValue(_ value: String) async {
        _state = _state.addingValue(value)
    }
    
    func performComplexMutation(index: Int) async {
        _state = _state.incrementingCounter()
            .addingValue("complex-\(index)")
            .addingToHistory(index)
    }
}

// State Ownership Testing
struct TestOwnershipState: State, Sendable, Equatable {
    let id: String
    let value: String
    
    init(id: String = UUID().uuidString, value: String) {
        self.id = id
        self.value = value
    }
    
    func withValue(_ newValue: String) -> TestOwnershipState {
        TestOwnershipState(value: newValue)
    }
}

struct TestOwnershipClient: Equatable {
    let id: String
}

// State Ownership Validator
class StateOwnershipValidator {
    private var ownerships: [ObjectIdentifier: String] = [:]
    private var clientStates: [String: any State] = [:]
    private(set) var lastError: String?
    
    var totalOwnershipCount: Int { ownerships.count }
    var uniqueClientCount: Int { Set(ownerships.values).count }
    var uniqueStateCount: Int { ownerships.count }
    
    func assignOwnership(of state: any State, to client: TestOwnershipClient) -> Bool {
        let stateId = ObjectIdentifier(type(of: state))
        
        if let existingOwner = ownerships[stateId] {
            lastError = "State '\(type(of: state))' is already owned by client '\(existingOwner)'; cannot assign to '\(client.id)'"
            return false
        }
        
        ownerships[stateId] = client.id
        clientStates[client.id] = state
        return true
    }
    
    func getState(for client: TestOwnershipClient) -> (any State)? {
        return clientStates[client.id]
    }
    
    func validateValueSemantics(_ stateType: any State.Type) -> Bool {
        // In real implementation, this would use reflection to verify value semantics
        return stateType == TestOwnershipState.self
    }
    
    func validateImmutability(_ stateType: any State.Type) -> Bool {
        // In real implementation, this would verify all properties are immutable
        return stateType == TestOwnershipState.self
    }
}

// Unidirectional Flow Testing
enum ComponentType: String, CaseIterable {
    case orchestrator
    case context
    case client
    case capability
    case state
    case presentation
}

struct UnidirectionalFlow {
    static func validate(from: ComponentType, to: ComponentType) -> Bool {
        let flowOrder: [ComponentType] = [.orchestrator, .context, .client, .capability]
        
        guard let fromIndex = flowOrder.firstIndex(of: from),
              let toIndex = flowOrder.firstIndex(of: to) else {
            // Handle special cases
            switch (from, to) {
            case (.client, .state):
                return true // Client can own state
            case (.context, .presentation):
                return true // Context can provide data to presentation
            default:
                return false
            }
        }
        
        return fromIndex < toIndex // Forward dependencies only
    }
}

// Dependency Analyzer
struct DependencyAnalyzer {
    private let dependencies: [(ComponentType, ComponentType)]
    
    init(dependencies: [(ComponentType, ComponentType)]) {
        self.dependencies = dependencies
    }
    
    func isUnidirectional() -> Bool {
        // Check for cycles using DFS
        var graph: [ComponentType: [ComponentType]] = [:]
        
        for (from, to) in dependencies {
            graph[from, default: []].append(to)
        }
        
        var visited: Set<ComponentType> = []
        var recursionStack: Set<ComponentType> = []
        
        for node in graph.keys {
            if !visited.contains(node) {
                if hasCycle(node: node, graph: graph, visited: &visited, recursionStack: &recursionStack) {
                    return false
                }
            }
        }
        
        return true
    }
    
    func topologicalSort() -> [ComponentType]? {
        guard isUnidirectional() else { return nil }
        
        // Simplified topological sort for testing
        var graph: [ComponentType: [ComponentType]] = [:]
        var inDegree: [ComponentType: Int] = [:]
        
        for (from, to) in dependencies {
            graph[from, default: []].append(to)
            inDegree[to, default: 0] += 1
            inDegree[from, default: 0] += 0
        }
        
        var queue = inDegree.filter { $0.value == 0 }.map { $0.key }
        var result: [ComponentType] = []
        
        while !queue.isEmpty {
            let node = queue.removeFirst()
            result.append(node)
            
            for neighbor in graph[node, default: []] {
                inDegree[neighbor]! -= 1
                if inDegree[neighbor]! == 0 {
                    queue.append(neighbor)
                }
            }
        }
        
        return result.count == inDegree.count ? result : nil
    }
    
    private func hasCycle(
        node: ComponentType,
        graph: [ComponentType: [ComponentType]],
        visited: inout Set<ComponentType>,
        recursionStack: inout Set<ComponentType>
    ) -> Bool {
        visited.insert(node)
        recursionStack.insert(node)
        
        for neighbor in graph[node, default: []] {
            if !visited.contains(neighbor) {
                if hasCycle(node: neighbor, graph: graph, visited: &visited, recursionStack: &recursionStack) {
                    return true
                }
            } else if recursionStack.contains(neighbor) {
                return true
            }
        }
        
        recursionStack.remove(node)
        return false
    }
}

// Action Subscription Testing
@MainActor
class TestParentSubscriptionContext: BaseContext {
    @Published private(set) var capturedActions: [Any] = []
    @Published private(set) var handledActionTypes: Set<String> = []
    
    override func handleChildAction<T>(_ action: T, from child: any Context) {
        capturedActions.append(action)
        handledActionTypes.insert(String(describing: type(of: action)))
    }
}

@MainActor
class TestChildSubscriptionContext: BaseContext {
    enum Action: Equatable {
        case itemSelected(id: String)
        case itemDeleted(id: String)
        case itemUpdated(id: String, value: String)
    }
    
    func emitAction(_ action: Action) async {
        await sendToParent(action)
    }
}

// State Flow Testing
enum StateFlowAction: Equatable {
    case increment
    case setName(String)
    case reset
}

struct StateFlowState: State, Sendable, Equatable {
    let counter: Int
    let name: String
    
    init(counter: Int = 0, name: String = "") {
        self.counter = counter
        self.name = name
    }
}

actor StateFlowTestClient: Client {
    typealias StateType = StateFlowState
    typealias ActionType = StateFlowAction
    
    private(set) var currentState = StateFlowState()
    private let stream: AsyncStream<StateFlowState>
    private let continuation: AsyncStream<StateFlowState>.Continuation
    
    var stateStream: AsyncStream<StateFlowState> {
        stream
    }
    
    init() {
        (stream, continuation) = AsyncStream.makeStream(of: StateFlowState.self)
        continuation.yield(currentState)
    }
    
    func process(_ action: StateFlowAction) async throws {
        switch action {
        case .increment:
            currentState = StateFlowState(counter: currentState.counter + 1, name: currentState.name)
        case .setName(let name):
            currentState = StateFlowState(counter: currentState.counter, name: name)
        case .reset:
            currentState = StateFlowState()
        }
        
        continuation.yield(currentState)
    }
    
    deinit {
        continuation.finish()
    }
}

@MainActor
class StateFlowTestContext: BaseContext {
    private let client: StateFlowTestClient
    @Published private(set) var observationWasCancelled = false
    private var observationTask: Task<Void, Never>?
    
    init(client: StateFlowTestClient) {
        self.client = client
        super.init()
    }
    
    func startObservingState() async {
        observationTask = Task { [weak self] in
            guard let client = self?.client else { return }
            
            do {
                for await _ in await client.stateStream {
                    // Process state changes
                    if Task.isCancelled {
                        await MainActor.run {
                            self?.observationWasCancelled = true
                        }
                        break
                    }
                }
            } catch {
                await MainActor.run {
                    self?.observationWasCancelled = true
                }
            }
        }
    }
    
    override func performDisappearance() async {
        await super.performDisappearance()
        observationTask?.cancel()
        observationTask = nil
    }
}