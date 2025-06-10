import XCTest
@testable import Axiom

@MainActor
final class StateOptimizationTests: XCTestCase {
    
    // Test state stream property wrapper functionality
    func testStateStreamablePropertyWrapper() async throws {
        // Test that property wrapper eliminates boilerplate
        class TestClient: ObservableObject {
            @StateStreamable
            var stateStream: StateStream<TestState>
            
            private(set) var currentState = TestState()
            
            func updateState(_ newState: TestState) async {
                await stateStream.update(newState)
                currentState = newState
            }
        }
        
        let client = TestClient()
        var receivedStates: [TestState] = []
        
        // Subscribe to state stream
        let task = Task {
            for await state in client.stateStream.stream {
                receivedStates.append(state)
            }
        }
        
        // Update state
        let newState = TestState(value: 42, message: "Updated")
        await client.updateState(newState)
        
        // Allow propagation
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        task.cancel()
        
        XCTAssertEqual(receivedStates.count, 1)
        XCTAssertEqual(receivedStates.first?.value, 42)
    }
    
    // Test error context automation
    func testErrorContextPropertyWrapper() async throws {
        class TestService {
            func performOperationInternal() async throws -> Int {
                throw TestError.operationFailed
            }
            
            @ErrorContext("TestService.performOperation")
            var performOperation: (@escaping () async throws -> Any) -> () async throws -> Any
            
            func performOperationWrapped() async throws -> Int {
                let wrapped = performOperation(performOperationInternal)
                return try await wrapped() as! Int
            }
            
            func safeOperationInternal() async throws -> Int {
                return 42
            }
            
            @ErrorContext("TestService.safeOperation")
            var safeOperation: (@escaping () async throws -> Any) -> () async throws -> Any
            
            func safeOperationWrapped() async throws -> Int {
                let wrapped = safeOperation(safeOperationInternal)
                return try await wrapped() as! Int
            }
        }
        
        let service = TestService()
        
        // Test error wrapping
        do {
            _ = try await service.performOperationWrapped()
            XCTFail("Expected error")
        } catch let error as AxiomError {
            switch error {
            case .generalError(let message):
                XCTAssertTrue(message.contains("TestService.performOperation"))
            default:
                XCTFail("Expected general error with context")
            }
        }
        
        // Test successful operation
        let result = try await service.safeOperationWrapped()
        XCTAssertEqual(result, 42)
    }
    
    // Test high-performance state propagation
    func testHighThroughputStatePropagation() async throws {
        class HighPerformanceClient {
            @StateStreamable(bufferSize: 1000, conflation: .keepLatest)
            var stateStream: StateStream<TestState>
            
            private(set) var updateCount = 0
            
            func rapidUpdate(count: Int) async {
                for i in 0..<count {
                    await stateStream.update(TestState(value: i))
                    updateCount += 1
                }
            }
        }
        
        let client = HighPerformanceClient()
        var receivedCount = 0
        let expectation = XCTestExpectation(description: "High throughput updates")
        
        // Subscribe and count updates
        let task = Task {
            for await _ in client.stateStream.stream {
                receivedCount += 1
                if receivedCount >= 9000 { // Expect some conflation
                    expectation.fulfill()
                    break
                }
            }
        }
        
        // Measure performance
        let start = Date()
        await client.rapidUpdate(count: 10_000)
        let duration = Date().timeIntervalSince(start)
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        task.cancel()
        
        // Performance assertions
        XCTAssertLessThan(duration, 1.0, "Should process 10k updates in <1s")
        XCTAssertEqual(client.updateCount, 10_000)
        XCTAssertGreaterThan(receivedCount, 9000) // Some conflation expected
        
        let throughput = Double(client.updateCount) / duration
        XCTAssertGreaterThan(throughput, 10_000, "Should achieve >10k updates/sec")
    }
    
    // Test state diffing
    func testStateDiffing() async throws {
        struct DiffableTestState: DiffableState, Equatable {
            var value: Int
            var message: String
            
            func diff(from previous: DiffableTestState) -> StateDiff {
                var changes: [String: Any] = [:]
                if value != previous.value {
                    changes["value"] = value
                }
                if message != previous.message {
                    changes["message"] = message
                }
                return StateDiff(changes: changes)
            }
        }
        
        class DiffingClient: Client {
            typealias StateType = DiffableTestState
            typealias Action = TestAction
            
            @Published private(set) var state = DiffableTestState(value: 0, message: "")
            var updateCount = 0
            
            func process(_ action: TestAction) async {
                // Not used in this test
            }
            
            func updateWithDiff(_ newState: DiffableTestState) async {
                let diff = newState.diff(from: state)
                guard !diff.isEmpty else { return }
                state = newState
                updateCount += 1
            }
        }
        
        let client = DiffingClient()
        
        // Test that identical updates are skipped
        let state1 = DiffableTestState(value: 42, message: "Hello")
        await client.updateWithDiff(state1)
        XCTAssertEqual(client.updateCount, 1)
        
        // Same state should not trigger update
        await client.updateWithDiff(state1)
        XCTAssertEqual(client.updateCount, 1)
        
        // Changed state should trigger update
        let state2 = DiffableTestState(value: 42, message: "World")
        await client.updateWithDiff(state2)
        XCTAssertEqual(client.updateCount, 2)
    }
    
    // Test memory efficiency with circular buffer
    func testCircularBufferMemoryEfficiency() async throws {
        let buffer = AsyncStreamBuffer<TestState>(
            capacity: 100,
            strategy: .keepLatest
        )
        
        // Send more items than capacity
        for i in 0..<1000 {
            await buffer.send(TestState(value: i))
        }
        
        // Buffer should only contain last 100 items
        let items = await buffer.drain()
        XCTAssertEqual(items.count, 100)
        XCTAssertEqual(items.first?.value, 900)
        XCTAssertEqual(items.last?.value, 999)
    }
}

// Test helpers
private struct TestState: Equatable {
    var value: Int = 0
    var message: String = ""
}

private enum TestAction {
    case update(Int)
}

private enum TestError: Error {
    case operationFailed
}