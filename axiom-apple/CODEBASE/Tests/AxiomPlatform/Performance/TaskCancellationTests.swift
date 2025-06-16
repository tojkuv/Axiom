import XCTest
import AxiomTesting
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomPlatform task cancellation functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class TaskCancellationTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testTaskCancellationInitialization() async throws {
        let cancellation = TaskCancellation()
        XCTAssertNotNil(cancellation, "TaskCancellation should initialize correctly")
    }
    
    func testIndividualTaskCancellation() async throws {
        let cancellation = TaskCancellation()
        
        // Create a long-running task
        let task = Task {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            return "completed"
        }
        
        // Register task for cancellation
        await cancellation.registerTask(task, identifier: "test-task")
        
        // Cancel the task
        await cancellation.cancelTask(identifier: "test-task")
        
        let isCancelled = await cancellation.isTaskCancelled(identifier: "test-task")
        XCTAssertTrue(isCancelled, "Task should be marked as cancelled")
        
        // Verify task is actually cancelled
        do {
            _ = try await task.value
            XCTFail("Task should have been cancelled")
        } catch {
            XCTAssertTrue(error is CancellationError, "Should throw CancellationError")
        }
    }
    
    func testBulkTaskCancellation() async throws {
        let cancellation = TaskCancellation()
        
        // Create multiple tasks
        var tasks: [Task<String, Error>] = []
        for i in 0..<5 {
            let task = Task {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                return "task-\(i)"
            }
            tasks.append(task)
            await cancellation.registerTask(task, identifier: "bulk-task-\(i)")
        }
        
        // Cancel all tasks with prefix
        await cancellation.cancelTasksWithPrefix("bulk-task")
        
        let cancelledCount = await cancellation.getCancelledTaskCount(withPrefix: "bulk-task")
        XCTAssertEqual(cancelledCount, 5, "Should cancel all 5 tasks")
        
        // Verify all tasks are cancelled
        for task in tasks {
            do {
                _ = try await task.value
                XCTFail("Task should have been cancelled")
            } catch {
                XCTAssertTrue(error is CancellationError, "Should throw CancellationError")
            }
        }
    }
    
    func testCancellationWithTimeouts() async throws {
        let cancellation = TaskCancellation()
        
        // Create task with timeout
        let task = Task {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            return "completed"
        }
        
        await cancellation.registerTask(task, identifier: "timeout-task", timeout: .milliseconds(100))
        
        // Wait for timeout to trigger cancellation
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        let isTimedOut = await cancellation.isTaskTimedOut(identifier: "timeout-task")
        XCTAssertTrue(isTimedOut, "Task should have timed out and been cancelled")
        
        do {
            _ = try await task.value
            XCTFail("Task should have been cancelled due to timeout")
        } catch {
            XCTAssertTrue(error is CancellationError, "Should throw CancellationError")
        }
    }
    
    func testCancellationCallbacks() async throws {
        let cancellation = TaskCancellation()
        let expectation = expectation(description: "Cancellation callback")
        
        let task = Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return "completed"
        }
        
        await cancellation.registerTask(task, identifier: "callback-task") {
            expectation.fulfill()
        }
        
        await cancellation.cancelTask(identifier: "callback-task")
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Performance Tests
    
    func testTaskCancellationPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let cancellation = TaskCancellation()
                
                // Test rapid task registration and cancellation
                var tasks: [Task<Void, Error>] = []
                
                for i in 0..<100 {
                    let task = Task {
                        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    }
                    tasks.append(task)
                    await cancellation.registerTask(task, identifier: "perf-task-\(i)")
                }
                
                // Cancel all tasks
                await cancellation.cancelAllTasks()
                
                // Wait for cancellations to process
                for task in tasks {
                    do {
                        try await task.value
                    } catch {
                        // Expected cancellation errors
                    }
                }
            },
            maxDuration: .milliseconds(200),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testTaskCancellationMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let cancellation = TaskCancellation()
            
            // Simulate task lifecycle with cancellation
            for i in 0..<50 {
                let task = Task {
                    try await Task.sleep(nanoseconds: 1_000_000) // 1ms
                    return i
                }
                
                await cancellation.registerTask(task, identifier: "memory-task-\(i)")
                
                if i % 10 == 0 {
                    await cancellation.cancelTask(identifier: "memory-task-\(i)")
                }
                
                do {
                    _ = try await task.value
                } catch {
                    // Handle cancellation
                }
            }
            
            await cancellation.cleanup()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testTaskCancellationErrorHandling() async throws {
        let cancellation = TaskCancellation()
        
        // Test cancelling non-existent task
        await cancellation.cancelTask(identifier: "non-existent")
        let isNonExistentCancelled = await cancellation.isTaskCancelled(identifier: "non-existent")
        XCTAssertFalse(isNonExistentCancelled, "Non-existent task should not be marked as cancelled")
        
        // Test registering task with duplicate identifier
        let task1 = Task { return "task1" }
        let task2 = Task { return "task2" }
        
        await cancellation.registerTask(task1, identifier: "duplicate")
        
        do {
            try await cancellation.registerTaskStrict(task2, identifier: "duplicate")
            XCTFail("Should throw error for duplicate identifier")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for duplicate identifier")
        }
        
        // Clean up
        await cancellation.cancelTask(identifier: "duplicate")
        try await task1.value
    }
}