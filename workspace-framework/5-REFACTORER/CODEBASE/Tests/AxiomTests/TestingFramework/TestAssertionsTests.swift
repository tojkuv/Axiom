import XCTest
@testable import Axiom
@testable import AxiomTesting

final class TestAssertionsTests: XCTestCase {
    
    func testWaitForOperationSuccess() async throws {
        var value: String?
        
        // Simulate async operation that succeeds after delay
        Task {
            try await Task.sleep(for: .milliseconds(50))
            value = "success"
        }
        
        // Test that waitFor succeeds when operation returns a value
        let result = try await waitFor({
            return value
        }, timeout: .seconds(1))
        
        XCTAssertEqual(result, "success")
    }
    
    func testWaitForOperationTimeout() async throws {
        // Test that waitFor throws timeout error when operation never succeeds
        do {
            _ = try await waitFor({
                return nil as String?
            }, timeout: .milliseconds(100))
            XCTFail("Expected timeout error")
        } catch TestError.timeout {
            // Expected timeout
        } catch {
            XCTFail("Expected timeout error but got \(error)")
        }
    }
    
    func testObserveStatesFromClient() async throws {
        let mockClient = MockStreamClient()
        
        // Start emitting states
        Task {
            try await Task.sleep(for: .milliseconds(10))
            await mockClient.emit(MockState(value: 1))
            try await Task.sleep(for: .milliseconds(10))
            await mockClient.emit(MockState(value: 5))
        }
        
        // Test that observeStates returns first state matching condition
        let result = try await observeStates(from: mockClient) { state in
            state.value >= 5
        }
        
        XCTAssertEqual(result.value, 5)
    }
    
    func testAssertEventuallySucceeds() async throws {
        var flag = false
        
        // Set flag after delay
        Task {
            try await Task.sleep(for: .milliseconds(50))
            flag = true
        }
        
        // Test that assertEventually succeeds when condition becomes true
        try await assertEventually {
            flag
        }
    }
    
    func testAssertEventuallyTimeout() async throws {
        // Test that assertEventually throws when condition never becomes true
        do {
            try await assertEventually({
                false
            }, timeout: .milliseconds(100))
            XCTFail("Expected timeout error")
        } catch TestError.timeout {
            // Expected timeout
        } catch {
            XCTFail("Expected timeout error but got \(error)")
        }
    }
    
    func testAssertNoMemoryLeaks() async throws {
        var leakyObject: NSObject? = NSObject()
        
        // This should fail the test when object is not released
        assertNoMemoryLeaks(leakyObject!)
        
        // Release the object
        leakyObject = nil
        
        // Give teardown time to run
        try await Task.sleep(for: .milliseconds(10))
    }
    
    func testMemoryTrackingWithAutomaticRelease() async throws {
        do {
            let object = NSObject()
            assertNoMemoryLeaks(object)
            // Object goes out of scope and should be released
        }
        
        // Memory should be properly cleaned up
        try await Task.sleep(for: .milliseconds(10))
    }
}

// MARK: - Mock Types for Testing

actor MockStreamClient: Client {
    typealias StateType = MockState
    typealias ActionType = MockAction
    
    private let continuation: AsyncStream<MockState>.Continuation
    let stateStream: AsyncStream<MockState>
    
    init() {
        (stateStream, continuation) = AsyncStream.makeStream(of: MockState.self)
    }
    
    func emit(_ state: MockState) {
        continuation.yield(state)
    }
    
    func process(_ action: MockAction) async throws {
        // Process mock actions
        switch action {
        case .setValue(let value):
            emit(MockState(value: value))
        }
    }
    
    func finish() {
        continuation.finish()
    }
}

struct MockState: State, Equatable {
    let value: Int
}

enum MockAction {
    case setValue(Int)
}