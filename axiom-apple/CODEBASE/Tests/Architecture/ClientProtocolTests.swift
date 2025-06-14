import XCTest
@testable import Axiom

final class ClientProtocolTests: XCTestCase {
    
    // MARK: - Basic Conformance Tests
    
    func testBasicClientConformance() async throws {
        // Basic test to verify client protocol conformance
        let client = MockClient()
        
        // Test initial state
        let initialState = await client.state
        XCTAssertEqual(initialState.counter, 0)
        XCTAssertEqual(initialState.name, "")
        XCTAssertFalse(initialState.isEnabled)
        
        // Test action processing
        try await client.process(.increment)
        let updatedState = await client.state
        XCTAssertEqual(updatedState.counter, 1)
    }
    
    // MARK: - State Streaming Tests
    
    func testClientStateStreamDelivery() async throws {
        // Requirement: Test harness receives all state updates within 5ms
        let client = MockClient()
        var receivedStates: [ClientTestState] = []
        
        // Set up state observation
        Task {
            for await state in await client.stateStream {
                receivedStates.append(state)
            }
        }
        
        // Give the stream time to setup
        try await Task.sleep(for: .milliseconds(1))
        
        // Perform state mutations
        let start = ContinuousClock.now
        try await client.process(.increment)
        try await client.process(.setName("Test"))
        try await client.process(.toggle)
        try await client.process(.increment)
        let elapsed = ContinuousClock.now - start
        
        // Give time for stream to process
        try await Task.sleep(for: .milliseconds(1))
        
        // Verify timing requirement
        XCTAssertLessThan(elapsed, .milliseconds(5), "State updates should be delivered within 5ms")
        
        // Verify all state updates were received
        XCTAssertEqual(receivedStates.count, 5) // Initial + 4 updates
        XCTAssertEqual(receivedStates[0].counter, 0) // Initial state
        XCTAssertEqual(receivedStates[1].counter, 1) // After increment
        XCTAssertEqual(receivedStates[2].name, "Test") // After setName
        XCTAssertEqual(receivedStates[3].isEnabled, true) // After toggle
        XCTAssertEqual(receivedStates[4].counter, 2) // After second increment
    }
    
    func testClientInitialStateInStream() async throws {
        // Test receives initial state + all subsequent mutations in order
        let client = MockClient(initialState: ClientTestState(counter: 10, name: "Initial", isEnabled: false))
        var receivedStates: [ClientTestState] = []
        
        // Start observing
        let task = Task {
            for await state in await client.stateStream {
                receivedStates.append(state)
                if receivedStates.count >= 3 {
                    break
                }
            }
        }
        
        // Perform mutations
        try? await client.process(.increment)
        try? await client.process(.setName("Updated"))
        
        // Wait for observations
        await task.value
        
        // Verify initial state is first
        XCTAssertEqual(receivedStates[0].counter, 10)
        XCTAssertEqual(receivedStates[0].name, "Initial")
        XCTAssertEqual(receivedStates[0].isEnabled, false)
        
        // Verify mutations in order
        XCTAssertEqual(receivedStates[1].counter, 11)
        XCTAssertEqual(receivedStates[2].name, "Updated")
    }
    
    func testClientActionProcessing() async throws {
        // Test that actions are processed correctly
        let client = MockClient()
        
        // Process various actions
        try await client.process(.increment)
        var state = await client.currentState
        XCTAssertEqual(state.counter, 1)
        
        try await client.process(.decrement)
        state = await client.currentState
        XCTAssertEqual(state.counter, 0)
        
        try await client.process(.setName("Test Name"))
        state = await client.currentState
        XCTAssertEqual(state.name, "Test Name")
        
        try await client.process(.toggle)
        state = await client.currentState
        XCTAssertTrue(state.isEnabled)
    }
    
    func testClientActorIsolation() async throws {
        // Test that client maintains actor isolation
        let client = MockClient()
        
        // Concurrent mutations should be serialized
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    try? await client.process(.increment)
                }
            }
        }
        
        // All increments should have been applied
        let finalState = await client.currentState
        XCTAssertEqual(finalState.counter, 100)
    }
    
    func testClientErrorHandling() async throws {
        // Test that client handles errors appropriately
        let client = ErrorThrowingClient()
        
        // Action that succeeds
        try await client.process(.valid)
        var state = await client.currentState
        XCTAssertEqual(state.processedCount, 1)
        
        // Action that fails
        do {
            try await client.process(.invalid)
            XCTFail("Should have thrown error")
        } catch {
            // Expected error
            XCTAssertTrue(error is ClientError)
        }
        
        // State should not have changed on error
        state = await client.currentState
        XCTAssertEqual(state.processedCount, 1)
    }
    
    func testClientStateStreamCancellation() async throws {
        // Test that state stream can be cancelled
        let client = MockClient()
        var receivedCount = 0
        
        // Start observing with cancellation
        let task = Task {
            for await _ in await client.stateStream {
                receivedCount += 1
                if receivedCount >= 2 {
                    break // This should cancel the stream
                }
            }
        }
        
        // Perform multiple mutations
        try? await client.process(.increment)
        try? await client.process(.increment)
        try? await client.process(.increment)
        try? await client.process(.increment)
        
        await task.value
        
        // Should only have received 2 states (initial + 1)
        XCTAssertEqual(receivedCount, 2)
    }
    
    func testMultipleStateStreamObservers() async throws {
        // Test that multiple observers can watch state stream
        let client = MockClient()
        var observer1States: [ClientTestState] = []
        var observer2States: [ClientTestState] = []
        
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
        try? await client.process(.increment)
        try? await client.process(.toggle)
        
        // Wait for both observers
        await task1.value
        await task2.value
        
        // Both should have received same states
        XCTAssertEqual(observer1States.count, 3)
        XCTAssertEqual(observer2States.count, 3)
        XCTAssertEqual(observer1States, observer2States)
    }
}

// MARK: - Test Support Types

// Test state
struct ClientTestState: State {
    var counter: Int = 0
    var name: String = ""
    var isEnabled: Bool = false
}

// Test actions
enum TestAction {
    case increment
    case decrement
    case setName(String)
    case toggle
}

// Mock client implementation
actor MockClient: Client {
    typealias StateType = ClientTestState
    typealias ActionType = TestAction
    
    private(set) var currentState: ClientTestState
    private var streamContinuations: [UUID: AsyncStream<ClientTestState>.Continuation] = [:]
    
    var stateStream: AsyncStream<ClientTestState> {
        AsyncStream { [weak self] continuation in
            let id = UUID()
            Task { [weak self] in
                await self?.addContinuation(continuation, id: id)
                
                // Yield initial state
                if let state = await self?.currentState {
                    continuation.yield(state)
                }
                
                // Clean up on termination
                continuation.onTermination = { @Sendable _ in
                    Task { @Sendable [weak self, id] in
                        await self?.removeContinuation(id: id)
                    }
                }
            }
        }
    }
    
    init(initialState: ClientTestState = ClientTestState()) {
        self.currentState = initialState
    }
    
    private func addContinuation(_ continuation: AsyncStream<ClientTestState>.Continuation, id: UUID) {
        streamContinuations[id] = continuation
    }
    
    private func removeContinuation(id: UUID) {
        streamContinuations.removeValue(forKey: id)
    }
    
    func process(_ action: TestAction) async throws {
        switch action {
        case .increment:
            currentState.counter += 1
        case .decrement:
            currentState.counter -= 1
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
    
    func terminateStreams() {
        for (_, continuation) in streamContinuations {
            continuation.finish()
        }
        streamContinuations.removeAll()
    }
}

// Error handling test types
enum ErrorAction {
    case valid
    case invalid
}

struct ErrorState: State {
    var processedCount: Int = 0
}

enum ClientError: Error {
    case invalidAction
    case processingFailed
}

actor ErrorThrowingClient: Client {
    typealias StateType = ErrorState
    typealias ActionType = ErrorAction
    
    private(set) var currentState = ErrorState()
    private var streamContinuations: [UUID: AsyncStream<ErrorState>.Continuation] = [:]
    
    var stateStream: AsyncStream<ErrorState> {
        AsyncStream { [weak self] continuation in
            let id = UUID()
            Task { [weak self] in
                await self?.addContinuation(continuation, id: id)
                
                // Yield initial state
                if let state = await self?.currentState {
                    continuation.yield(state)
                }
                
                // Clean up on termination
                continuation.onTermination = { @Sendable _ in
                    Task { @Sendable [weak self, id] in
                        await self?.removeContinuation(id: id)
                    }
                }
            }
        }
    }
    
    private func addContinuation(_ continuation: AsyncStream<ErrorState>.Continuation, id: UUID) {
        streamContinuations[id] = continuation
    }
    
    private func removeContinuation(id: UUID) {
        streamContinuations.removeValue(forKey: id)
    }
    
    func process(_ action: ErrorAction) async throws {
        switch action {
        case .valid:
            currentState.processedCount += 1
            // Notify all observers
            for (_, continuation) in streamContinuations {
                continuation.yield(currentState)
            }
        case .invalid:
            throw ClientError.invalidAction
        }
    }
}

