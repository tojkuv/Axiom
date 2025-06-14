import XCTest
@testable import Axiom

final class CoreProtocolFoundationTests: XCTestCase {
    
    // MARK: - Client Protocol Tests
    
    func testClientProtocolConformance() async throws {
        // Test that Client protocol has required members
        let client = TestableClient()
        
        // Test state stream exists
        let stream = await client.stateStream
        XCTAssertNotNil(stream, "Client must provide stateStream")
        
        // Test process method exists
        try await client.process(CoreTestAction.increment)
    }
    
    func testClientStatePropagationWithin5ms() async throws {
        // Requirement: State updates must be delivered within 5ms
        let client = TestableClient()
        var receivedStates: [TestState] = []
        
        // Set up observation
        Task {
            for await state in await client.stateStream {
                receivedStates.append(state)
            }
        }
        
        // Allow stream setup
        try await Task.sleep(for: .milliseconds(1))
        
        // Measure state propagation time
        let start = ContinuousClock.now
        try await client.process(CoreTestAction.increment)
        let elapsed = ContinuousClock.now - start
        
        // Allow stream processing
        try await Task.sleep(for: .milliseconds(1))
        
        XCTAssertLessThan(elapsed, .milliseconds(5), "State propagation must complete within 5ms")
        XCTAssertGreaterThanOrEqual(receivedStates.count, 2, "Should receive initial and updated state")
    }
    
    func testClientInitialStateEmission() async throws {
        // Requirement: Must emit initial state upon subscription
        let client = TestableClient(initialState: TestState(value: 42))
        var receivedStates: [TestState] = []
        
        Task {
            for await state in await client.stateStream {
                receivedStates.append(state)
                if receivedStates.count == 1 { break }
            }
        }
        
        // Allow stream processing
        try await Task.sleep(for: .milliseconds(5))
        
        XCTAssertEqual(receivedStates.count, 1, "Should receive initial state")
        XCTAssertEqual(receivedStates.first?.value, 42, "Initial state should match")
    }
    
    func testObservableClientThreadSafety() async throws {
        // Test thread-safe state mutations
        let client = ObservableClient<TestState, CoreTestAction>(initialState: TestState(value: 0))
        
        // Concurrent state updates
        await withTaskGroup(of: Void.self) { group in
            for i in 1...100 {
                group.addTask {
                    await client.updateState(TestState(value: i))
                }
            }
        }
        
        // Verify final state is consistent
        let finalState = await client.state
        XCTAssertTrue(finalState.value >= 1 && finalState.value <= 100, "State should be from concurrent updates")
    }
    
    // MARK: - Context Protocol Tests
    
    func testContextProtocolConformance() async throws {
        // Test that Context protocol has required members
        let context = await CoreTestableContext()
        
        // Test MainActor binding
        XCTAssertTrue(Thread.isMainThread, "Context operations must run on MainActor")
        
        // Test lifecycle methods
        try await context.activate()
        await context.deactivate()
        
        // Test child action handling
        await context.handleChildAction("test", from: context)
        
        // Test ObservableObject conformance
        let _ = context.objectWillChange
    }
    
    func testContextLifecycleIdempotency() async throws {
        // Test that activate/deactivate are idempotent
        let context = await ObservableContext()
        
        // Multiple activations should be safe
        try await context.activate()
        try await context.activate()
        try await context.activate()
        
        await MainActor.run {
            XCTAssertTrue(context.isActive, "Context should be active")
        }
        
        // Multiple deactivations should be safe
        await context.deactivate()
        await context.deactivate()
        
        await MainActor.run {
            XCTAssertFalse(context.isActive, "Context should be inactive")
        }
    }
    
    func testContextMemoryStability() async throws {
        // Requirement: Memory usage must remain stable after processing actions
        let context = await ObservableContext()
        
        let baselineMemory = await context.measureMemoryUsage()
        
        // Process many actions
        for i in 0..<1000 {
            await context.processActions([i, "test", Double(i)])
        }
        
        _ = await context.measureMemoryUsage()
        let isStable = await context.isMemoryStable(baseline: baselineMemory, tolerance: 0.1)
        
        XCTAssertTrue(isStable, "Memory should remain stable (within 10% tolerance)")
    }
    
    func testContextParentChildRelationships() async throws {
        // Test parent-child context relationships
        let parent = await ObservableContext()
        let child = await ObservableContext()
        
        await parent.addChild(child)
        
        await MainActor.run {
            XCTAssertEqual(parent.activeChildren.count, 1, "Parent should have one child")
        }
        await MainActor.run {
            XCTAssertNotNil(child.parentContext, "Child should have parent reference")
        }
        
        // Test action propagation
        var receivedAction: String?
        let expectation = XCTestExpectation(description: "Parent receives child action")
        
        class TestParent: ObservableContext {
            var actionHandler: ((Any) -> Void)?
            override func handleChildAction<T>(_ action: T, from child: any Context) {
                actionHandler?(action)
            }
        }
        
        let testParent = await TestParent()
        await MainActor.run {
            testParent.actionHandler = { action in
                receivedAction = action as? String
                expectation.fulfill()
            }
        }
        
        let testChild = await ObservableContext()
        await testParent.addChild(testChild)
        await testChild.sendToParent("TestAction")
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedAction, "TestAction", "Parent should receive child action")
    }
    
    // MARK: - Capability Protocol Tests
    
    func testCapabilityProtocolConformance() async throws {
        // Test that Capability protocol has required members
        let capability = TestableCapability()
        
        // Test availability check
        let isAvailable = await capability.isAvailable
        XCTAssertNotNil(isAvailable, "Capability must provide isAvailable")
        
        // Test lifecycle methods
        try await capability.activate()
        await capability.deactivate()
    }
    
    func testCapabilityStateTransitions() async throws {
        // Requirement: State transitions must complete in < 10ms
        let capability = StandardCapability()
        
        let start = ContinuousClock.now
        await capability.transitionTo(.available)
        let elapsed = ContinuousClock.now - start
        
        XCTAssertLessThan(elapsed, .milliseconds(10), "State transition must complete within 10ms")
        let isAvailable = await capability.isAvailable
        XCTAssertTrue(isAvailable, "Capability should be available after transition")
    }
    
    func testCapabilityStateStream() async throws {
        // Test state observation via stream
        let capability = StandardCapability()
        var receivedStates: [CapabilityState] = []
        
        Task {
            for await state in await capability.stateStream {
                receivedStates.append(state)
                if receivedStates.count >= 3 { break }
            }
        }
        
        // Allow stream setup
        try await Task.sleep(for: .milliseconds(1))
        
        // Perform state transitions
        await capability.transitionTo(.available)
        await capability.transitionTo(.restricted)
        await capability.transitionTo(.unavailable)
        
        // Allow stream processing
        try await Task.sleep(for: .milliseconds(10))
        
        XCTAssertGreaterThanOrEqual(receivedStates.count, 3, "Should receive state updates")
        XCTAssertTrue(receivedStates.contains(.available), "Should receive available state")
        XCTAssertTrue(receivedStates.contains(.restricted), "Should receive restricted state")
    }
    
    func testCapabilityThreadSafety() async throws {
        // Test thread-safe state transitions
        let capability = StandardCapability()
        
        // Concurrent state transitions
        await withTaskGroup(of: Void.self) { group in
            for _ in 1...100 {
                group.addTask {
                    await capability.transitionTo(.available)
                }
                group.addTask {
                    await capability.transitionTo(.unavailable)
                }
            }
        }
        
        // Verify capability is in a valid state
        let finalState = await capability.state
        XCTAssertTrue([.available, .unavailable].contains(finalState), "Capability should be in valid state")
    }
    
    // MARK: - Lifecycle Protocol Tests
    
    func testLifecycleProtocolAdoption() async throws {
        // Test that all core components adopt Lifecycle protocol
        let context: any Lifecycle = await ObservableContext()
        let capability: any Lifecycle = StandardCapability()
        
        // Test activation
        try await context.activate()
        try await capability.activate()
        
        // Test deactivation
        await context.deactivate()
        await capability.deactivate()
    }
    
    // MARK: - Integration Tests
    
    func testClientContextCapabilityIntegration() async throws {
        // Test that Client, Context, and Capability work together
        let client = TestableClient()
        let context = await ClientObservingContext<TestableClient>(client: client)
        let capability = TestableCapability()
        
        // Activate components
        try await context.activate()
        try await capability.activate()
        
        // Process action through client
        try await client.process(CoreTestAction.increment)
        
        // Verify context receives update
        var contextUpdated = false
        @MainActor 
        class TestObservingContext: ClientObservingContext<TestableClient> {
            var updateHandler: (() -> Void)?
            
            override init(client: TestableClient) {
                super.init(client: client)
            }
            
            required init() {
                fatalError("TestObservingContext must be initialized with a client")
            }
            
            override func handleStateUpdate(_ state: TestState) async {
                updateHandler?()
            }
        }
        
        let testContext = await TestObservingContext(client: client)
        await MainActor.run {
            testContext.updateHandler = {
                contextUpdated = true
            }
        }
        
        try await testContext.activate()
        try await client.process(CoreTestAction.increment)
        
        // Allow async processing
        try await Task.sleep(for: .milliseconds(10))
        
        XCTAssertTrue(contextUpdated, "Context should receive client state updates")
        let isCapabilityAvailable = await capability.isAvailable
        XCTAssertTrue(isCapabilityAvailable, "Capability should remain available")
        
        // Cleanup
        await testContext.deactivate()
        await capability.deactivate()
    }
}

// MARK: - Test Helpers

// Test state conforming to State protocol
struct TestState: State {
    let value: Int
    
    init(value: Int = 0) {
        self.value = value
    }
}

// Test actions for core protocol tests
enum CoreTestAction {
    case increment
    case decrement
    case reset
}

// Testable client implementation
actor TestableClient: Client {
    typealias StateType = TestState
    typealias ActionType = CoreTestAction
    
    private var currentState: TestState
    private var continuations: [UUID: AsyncStream<TestState>.Continuation] = [:]
    
    init(initialState: TestState = TestState()) {
        self.currentState = initialState
    }
    
    var stateStream: AsyncStream<TestState> {
        AsyncStream { continuation in
            let id = UUID()
            continuations[id] = continuation
            continuation.yield(currentState)
            
            continuation.onTermination = { @Sendable _ in
                Task { [weak self] in
                    await self?.removeContinuation(id: id)
                }
            }
        }
    }
    
    func process(_ action: CoreTestAction) async throws {
        switch action {
        case .increment:
            currentState = TestState(value: currentState.value + 1)
        case .decrement:
            currentState = TestState(value: currentState.value - 1)
        case .reset:
            currentState = TestState(value: 0)
        }
        
        // Notify observers
        for (_, continuation) in continuations {
            continuation.yield(currentState)
        }
    }
    
    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }
}

// Testable context implementation for core protocol tests
@MainActor
class CoreTestableContext: ObservableContext {
    var childActionReceived = false
    
    override func handleChildAction<T>(_ action: T, from child: any Context) {
        childActionReceived = true
    }
}

// Testable capability implementation
actor TestableCapability: Capability {
    private var available = false
    
    var isAvailable: Bool {
        get async { available }
    }
    
    func activate() async throws {
        available = true
    }
    
    func deactivate() async {
        available = false
    }
}