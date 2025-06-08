import XCTest
import Axiom
@testable import TaskManager

final class DebounceTests: XCTestCase {
    var client: TaskClient!
    var debouncer: AsyncDebouncer!
    
    override func setUp() async throws {
        client = makeClient()
        debouncer = AsyncDebouncer(delay: 0.3) // 300ms delay
    }
    
    func testDebounceSingleCall() async throws {
        // Single call should execute after delay
        var executed = false
        
        let task = await debouncer.debounce {
            executed = true
        }
        
        // Should not execute immediately
        XCTAssertFalse(executed)
        
        // Wait for the debounced operation to complete
        await task.value
        XCTAssertTrue(executed)
    }
    
    func testDebounceMultipleCalls() async throws {
        // Multiple calls should only execute the last one
        var executionCount = 0
        var lastValue = 0
        
        // Rapid fire multiple calls
        for i in 1...5 {
            _ = await debouncer.debounce {
                executionCount += 1
                lastValue = i
            }
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms between calls
        }
        
        // Should not have executed yet
        XCTAssertEqual(executionCount, 0)
        
        // Wait for the last debounced operation to complete
        await debouncer.waitForPendingOperation()
        
        // Should only execute once with last value
        XCTAssertEqual(executionCount, 1)
        XCTAssertEqual(lastValue, 5)
    }
    
    func testDebounceCancellation() async throws {
        // Previous calls should be cancelled
        var executed1 = false
        var executed2 = false
        
        _ = await debouncer.debounce {
            executed1 = true
        }
        
        // Cancel first by calling again
        let task2 = await debouncer.debounce {
            executed2 = true
        }
        
        await task2.value
        
        // Only second should execute
        XCTAssertFalse(executed1)
        XCTAssertTrue(executed2)
    }
    
    func testDebounceWithSearchAction() async throws {
        // Test debounce integration with search
        
        // Create a wrapper to count searches
        class SearchCounter {
            var count = 0
            let client: TaskClient
            
            init(client: TaskClient) {
                self.client = client
            }
            
            func send(_ action: TaskAction) async {
                if case .setSearchQuery = action {
                    count += 1
                }
                await client.send(action)
            }
        }
        
        let counter = SearchCounter(client: client)
        
        // Simulate rapid typing
        let queries = ["h", "he", "hel", "hell", "hello"]
        for query in queries {
            _ = await debouncer.debounce {
                await counter.send(.setSearchQuery(query))
            }
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms typing speed
        }
        
        // Should not have searched yet
        XCTAssertEqual(counter.count, 0)
        
        // Wait for the last debounced operation to complete
        await debouncer.waitForPendingOperation()
        
        // Should only search once with final query
        XCTAssertEqual(counter.count, 1)
        let finalQuery = await client.state.searchQuery
        XCTAssertEqual(finalQuery, "hello")
    }
}

// MARK: - Test Helpers
private func makeClient() -> TaskClient {
    TaskClient()
}