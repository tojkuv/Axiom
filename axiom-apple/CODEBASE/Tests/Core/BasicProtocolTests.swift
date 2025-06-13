import XCTest
@testable import Axiom

/// Basic protocol tests that verify core functionality
final class BasicProtocolTests: XCTestCase {
    
    // MARK: - State Protocol Tests
    
    func testStateProtocolRequirements() {
        // Test that State protocol has correct requirements
        struct TestState: State {
            let value: Int
        }
        
        let state1 = TestState(value: 1)
        let state2 = TestState(value: 1)
        let state3 = TestState(value: 2)
        
        // Equatable conformance
        XCTAssertEqual(state1, state2)
        XCTAssertNotEqual(state1, state3)
        
        // Hashable conformance
        var set = Set<TestState>()
        set.insert(state1)
        set.insert(state2) // Should not increase count
        set.insert(state3)
        XCTAssertEqual(set.count, 2)
        
        // Sendable conformance (compile-time check)
        let _: any Sendable = state1
    }
    
    // MARK: - Lifecycle Protocol Tests
    
    func testLifecycleProtocolExists() async throws {
        // Define a type conforming to Lifecycle
        class TestLifecycle: Lifecycle {
            var activateCount = 0
            var deactivateCount = 0
            
            func activate() async throws {
                activateCount += 1
            }
            
            func deactivate() async {
                deactivateCount += 1
            }
        }
        
        let lifecycle = TestLifecycle()
        
        // Test activation
        try await lifecycle.activate()
        XCTAssertEqual(lifecycle.activateCount, 1)
        
        // Test deactivation
        await lifecycle.deactivate()
        XCTAssertEqual(lifecycle.deactivateCount, 1)
    }
    
    // MARK: - ObservableClient Tests
    
    func testObservableClientBasicFunctionality() async {
        struct TestState: State {
            let count: Int
        }
        
        let client = ObservableClient<TestState, String>(
            initialState: TestState(count: 0)
        )
        
        // Test initial state
        let initialState = await client.state
        XCTAssertEqual(initialState.count, 0)
        
        // Test state update
        await client.updateState(TestState(count: 5))
        let updatedState = await client.state
        XCTAssertEqual(updatedState.count, 5)
        
        // Test stream termination
        await client.terminateStreams()
    }
    
    func testObservableClientStateStream() async throws {
        struct TestState: State {
            let value: String
        }
        
        let client = ObservableClient<TestState, Void>(
            initialState: TestState(value: "initial")
        )
        
        var receivedStates: [TestState] = []
        
        // Start observing
        let observationTask = Task {
            for await state in await client.stateStream {
                receivedStates.append(state)
                if receivedStates.count >= 3 { break }
            }
        }
        
        // Allow initial state to be received
        try await Task.sleep(for: .milliseconds(10))
        
        // Update states
        await client.updateState(TestState(value: "second"))
        await client.updateState(TestState(value: "third"))
        
        // Wait for observation
        try await Task.sleep(for: .milliseconds(10))
        observationTask.cancel()
        
        // Verify we received states
        XCTAssertGreaterThanOrEqual(receivedStates.count, 3)
        XCTAssertEqual(receivedStates[0].value, "initial")
        XCTAssertEqual(receivedStates[1].value, "second")
        XCTAssertEqual(receivedStates[2].value, "third")
    }
    
    // MARK: - ObservableContext Tests
    
    func testObservableContextLifecycle() async throws {
        let context = await ObservableContext()
        
        // Test initial state
        let initialActive = await context.isActive
        XCTAssertFalse(initialActive)
        
        // Test activation
        try await context.activate()
        let afterActivate = await context.isActive
        XCTAssertTrue(afterActivate)
        
        // Test idempotent activation
        try await context.activate()
        try await context.activate()
        XCTAssertTrue(await context.isActive)
        
        // Test deactivation
        await context.deactivate()
        let afterDeactivate = await context.isActive
        XCTAssertFalse(afterDeactivate)
    }
    
    func testObservableContextChildManagement() async {
        let parent = await ObservableContext()
        let child1 = await ObservableContext()
        let child2 = await ObservableContext()
        
        // Add children
        await parent.addChild(child1)
        await parent.addChild(child2)
        
        let children = await parent.activeChildren
        XCTAssertEqual(children.count, 2)
        
        // Remove child
        await parent.removeChild(child1)
        let remainingChildren = await parent.activeChildren
        XCTAssertEqual(remainingChildren.count, 1)
    }
    
    // MARK: - StandardCapability Tests
    
    func testStandardCapabilityLifecycle() async throws {
        let capability = StandardCapability()
        
        // Test initial state
        let initialState = await capability.state
        XCTAssertEqual(initialState, .unknown)
        XCTAssertFalse(await capability.isAvailable)
        
        // Test activation
        try await capability.activate()
        let afterActivate = await capability.state
        XCTAssertEqual(afterActivate, .available)
        XCTAssertTrue(await capability.isAvailable)
        
        // Test deactivation
        await capability.deactivate()
        let afterDeactivate = await capability.state
        XCTAssertEqual(afterDeactivate, .unavailable)
        XCTAssertFalse(await capability.isAvailable)
    }
    
    func testStandardCapabilityStateTransitions() async {
        let capability = StandardCapability()
        
        // Test various state transitions
        await capability.transitionTo(.available)
        XCTAssertEqual(await capability.state, .available)
        
        await capability.transitionTo(.restricted)
        XCTAssertEqual(await capability.state, .restricted)
        
        await capability.transitionTo(.unavailable)
        XCTAssertEqual(await capability.state, .unavailable)
        
        await capability.transitionTo(.unknown)
        XCTAssertEqual(await capability.state, .unknown)
    }
    
    // MARK: - Performance Tests
    
    func testClientStateUpdatePerformance() async throws {
        struct TestState: State {
            let value: Int
        }
        
        let client = ObservableClient<TestState, Void>(
            initialState: TestState(value: 0)
        )
        
        let start = ContinuousClock.now
        
        // Perform rapid state updates
        for i in 1...100 {
            await client.updateState(TestState(value: i))
        }
        
        let elapsed = ContinuousClock.now - start
        
        // Verify performance - should handle 100 updates quickly
        XCTAssertLessThan(elapsed, .milliseconds(100), "State updates should be fast")
    }
    
    func testCapabilityStateTransitionPerformance() async {
        let capability = StandardCapability()
        
        let start = ContinuousClock.now
        await capability.transitionTo(.available)
        let elapsed = ContinuousClock.now - start
        
        // Requirement: State transitions must complete in < 10ms
        XCTAssertLessThan(elapsed, .milliseconds(10), "State transition must be fast")
    }
}