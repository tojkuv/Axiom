import XCTest
@testable import Axiom

/// Tests for REQUIREMENTS-W-01-005: State Propagation Framework
final class StatePropagationTests: XCTestCase {
    
    // MARK: - Test Types
    
    struct TestState: State, Equatable {
        var id = UUID().uuidString
        var counter: Int = 0
        var message: String = ""
        var timestamp: Date = Date()
    }
    
    // MARK: - High-Performance State Streams Tests
    
    func testStatePropagationEngineCreation() async {
        let engine = StatePropagationEngine()
        
        let stream = await engine.createStream(
            for: TestClient.self,
            initialState: TestState(),
            priority: .normal
        )
        
        XCTAssertNotNil(stream)
        XCTAssertNotNil(stream.id)
    }
    
    func testGuaranteedStateStreamPropagationLatency() async {
        let engine = StatePropagationEngine()
        let stream = await engine.createStream(
            for: TestClient.self,
            initialState: TestState(),
            priority: .normal
        )
        
        var receivedStates: [TestState] = []
        var latencies: [TimeInterval] = []
        
        // Add observer with latency tracking
        let token = await stream.observe(priority: .normal) { state in
            receivedStates.append(state)
        }
        
        // Propagate multiple states and measure latency
        let testState = TestState(counter: 42, message: "test")
        let start = CFAbsoluteTimeGetCurrent()
        
        await stream.propagate(testState)
        
        let latency = CFAbsoluteTimeGetCurrent() - start
        latencies.append(latency)
        
        // Wait for propagation
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        XCTAssertEqual(receivedStates.count, 1)
        XCTAssertEqual(receivedStates.first?.counter, 42)
        XCTAssertLessThan(latency, 0.016) // < 16ms SLA
        
        token.cancel()
    }
    
    func testMulticastStateStreamOptimization() async {
        let engine = StatePropagationEngine()
        
        // Create source stream
        let (sourceStream, sourceContinuation) = AsyncStream.makeStream(of: TestState.self)
        
        // Create multicast stream for multiple subscribers
        let multicast = await engine.createMulticastStream(
            source: sourceStream,
            subscribers: 3
        )
        
        var subscriber1States: [TestState] = []
        var subscriber2States: [TestState] = []
        var subscriber3States: [TestState] = []
        
        // Subscribe multiple observers
        let stream1 = multicast.subscribe()
        let stream2 = multicast.subscribe()
        let stream3 = multicast.subscribe()
        
        // Start consuming
        Task {
            for await state in stream1 {
                subscriber1States.append(state)
            }
        }
        
        Task {
            for await state in stream2 {
                subscriber2States.append(state)
            }
        }
        
        Task {
            for await state in stream3 {
                subscriber3States.append(state)
            }
        }
        
        // Send test state
        let testState = TestState(counter: 100, message: "multicast")
        sourceContinuation.yield(testState)
        
        // Wait for propagation
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        XCTAssertEqual(subscriber1States.count, 1)
        XCTAssertEqual(subscriber2States.count, 1)
        XCTAssertEqual(subscriber3States.count, 1)
        
        XCTAssertEqual(subscriber1States.first?.counter, 100)
        XCTAssertEqual(subscriber2States.first?.counter, 100)
        XCTAssertEqual(subscriber3States.first?.counter, 100)
        
        sourceContinuation.finish()
    }
    
    // MARK: - Observer Lifecycle Management Tests
    
    func testObserverRegistryLifecycleManagement() async {
        let registry = ObserverRegistry<TestState>(maxObservers: 100)
        
        var receivedStates: [TestState] = []
        
        // Add observer
        let observer = Observer<TestState>(priority: .normal) { state in
            receivedStates.append(state)
        }
        
        let token = await registry.add(observer: observer)
        XCTAssertNotNil(token)
        
        // Notify observers
        let testState = TestState(counter: 5, message: "lifecycle")
        await registry.notifyByPriority(testState, priority: .normal)
        
        // Wait for notification
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        XCTAssertEqual(receivedStates.count, 1)
        XCTAssertEqual(receivedStates.first?.counter, 5)
        
        // Cancel observer
        token.cancel()
        
        // Notify again - should not receive
        await registry.notifyByPriority(TestState(counter: 10), priority: .normal)
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        XCTAssertEqual(receivedStates.count, 1) // Still only 1
    }
    
    func testObserverPriorityOrdering() async {
        let registry = ObserverRegistry<TestState>(maxObservers: 100)
        
        var executionOrder: [String] = []
        
        // Add observers with different priorities
        let highPriorityObserver = Observer<TestState>(priority: .high) { _ in
            executionOrder.append("high")
        }
        
        let normalPriorityObserver = Observer<TestState>(priority: .normal) { _ in
            executionOrder.append("normal")
        }
        
        let lowPriorityObserver = Observer<TestState>(priority: .low) { _ in
            executionOrder.append("low")
        }
        
        // Add in reverse order
        let token1 = await registry.add(observer: lowPriorityObserver)
        let token2 = await registry.add(observer: normalPriorityObserver)
        let token3 = await registry.add(observer: highPriorityObserver)
        
        // Notify all
        await registry.notifyByPriority(TestState(), priority: .normal)
        
        // Wait for notifications
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // Should execute in priority order: high, normal, low
        XCTAssertEqual(executionOrder, ["high", "normal", "low"])
        
        token1.cancel()
        token2.cancel()
        token3.cancel()
    }
    
    // MARK: - Selective State Propagation Tests
    
    func testSelectiveStateStreamFiltering() async {
        // Create source stream
        let (sourceStream, sourceContinuation) = AsyncStream.makeStream(of: TestState.self)
        
        let selectiveStream = SelectiveStateStream(
            source: sourceStream,
            predicates: []
        )
        
        var filteredStates: [TestState] = []
        
        // Create filtered stream for even counters only
        let evenCounterStream = selectiveStream.filtered { state in
            state.counter % 2 == 0
        }
        
        // Start consuming
        Task {
            for await state in evenCounterStream {
                filteredStates.append(state)
            }
        }
        
        // Send mix of even and odd counter states
        sourceContinuation.yield(TestState(counter: 1)) // odd - should be filtered out
        sourceContinuation.yield(TestState(counter: 2)) // even - should pass
        sourceContinuation.yield(TestState(counter: 3)) // odd - should be filtered out
        sourceContinuation.yield(TestState(counter: 4)) // even - should pass
        
        // Wait for filtering
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        XCTAssertEqual(filteredStates.count, 2)
        XCTAssertEqual(filteredStates[0].counter, 2)
        XCTAssertEqual(filteredStates[1].counter, 4)
        
        sourceContinuation.finish()
    }
    
    func testSelectiveStateStreamPropertySelection() async {
        // Create source stream
        let (sourceStream, sourceContinuation) = AsyncStream.makeStream(of: TestState.self)
        
        let selectiveStream = SelectiveStateStream(
            source: sourceStream,
            predicates: []
        )
        
        var selectedCounters: [Int] = []
        
        // Select only counter property changes
        let counterStream = selectiveStream.select(\.counter)
        
        // Start consuming
        Task {
            for await counter in counterStream {
                selectedCounters.append(counter)
            }
        }
        
        // Send states with different counter values
        sourceContinuation.yield(TestState(counter: 1, message: "a"))
        sourceContinuation.yield(TestState(counter: 1, message: "b")) // Same counter - should be filtered
        sourceContinuation.yield(TestState(counter: 2, message: "c")) // Different counter - should pass
        sourceContinuation.yield(TestState(counter: 2, message: "d")) // Same counter - should be filtered
        
        // Wait for selection
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        XCTAssertEqual(selectedCounters.count, 2)
        XCTAssertEqual(selectedCounters[0], 1)
        XCTAssertEqual(selectedCounters[1], 2)
        
        sourceContinuation.finish()
    }
    
    func testSelectiveStateStreamDebouncing() async {
        // Create source stream
        let (sourceStream, sourceContinuation) = AsyncStream.makeStream(of: TestState.self)
        
        let selectiveStream = SelectiveStateStream(
            source: sourceStream,
            predicates: []
        )
        
        var debouncedStates: [TestState] = []
        
        // Create debounced stream with 100ms debounce
        let debouncedStream = selectiveStream.debounced(for: 0.1)
        
        // Start consuming
        Task {
            for await state in debouncedStream {
                debouncedStates.append(state)
            }
        }
        
        // Send rapid updates
        sourceContinuation.yield(TestState(counter: 1))
        sourceContinuation.yield(TestState(counter: 2))
        sourceContinuation.yield(TestState(counter: 3))
        
        // Wait for debounce period
        try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
        // Should only receive the last state due to debouncing
        XCTAssertEqual(debouncedStates.count, 1)
        XCTAssertEqual(debouncedStates.first?.counter, 3)
        
        sourceContinuation.finish()
    }
    
    // MARK: - Performance Monitoring Tests
    
    func testPropagationMonitorLatencyTracking() async {
        let monitor = PropagationMonitor()
        
        // Record propagation events
        await monitor.recordPropagation(
            streamId: UUID(),
            latency: 0.005, // 5ms
            observers: 10,
            stateSize: 1024
        )
        
        await monitor.recordPropagation(
            streamId: UUID(),
            latency: 0.020, // 20ms - SLA violation
            observers: 5,
            stateSize: 512
        )
        
        // Generate dashboard
        let dashboard = await monitor.dashboard()
        
        XCTAssertNotNil(dashboard.currentMetrics)
        XCTAssertNotNil(dashboard.slaCompliance)
        
        // Should have recorded metrics
        XCTAssertGreaterThan(dashboard.currentMetrics.totalEvents, 0)
    }
    
    // MARK: - Supporting Types for Tests
    
    private class TestClient: Client {
        typealias StateType = TestState
        typealias ActionType = String
        
        var state: TestState = TestState()
        
        func process(_ action: String) async throws {
            // Test implementation
        }
        
        func receiveExternalUpdate(_ newState: TestState) async {
            self.state = newState
        }
    }
}

// MARK: - Test Helper Extensions

extension TestState {
    init(counter: Int, message: String = "") {
        self.init()
        self.counter = counter
        self.message = message
    }
}