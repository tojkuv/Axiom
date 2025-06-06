import XCTest
import Axiom
@testable import TestApp002Core

// RED Phase: Task editing tests that should fail without proper validation
final class TaskEditTests: XCTestCase {
    private var taskClient: TaskClient!
    
    override func setUp() async throws {
        try await super.setUp()
        let storageCapability = InMemoryStorageCapability()
        let networkCapability = MockNetworkCapability()
        let notificationCapability = MockNotificationCapability()
        
        taskClient = TaskClient(
            userId: "test-user",
            storageCapability: storageCapability,
            networkCapability: networkCapability,
            notificationCapability: notificationCapability
        )
    }
    
    override func tearDown() async throws {
        taskClient = nil
        try await super.tearDown()
    }
    
    // MARK: - Valid Task Updates
    
    func testUpdateExistingTask() async throws {
        // First create a task
        let originalTask = Task(
            id: "update-1",
            title: "Original Title",
            description: "Original Description",
            priority: .low
        )
        
        try await taskClient.process(.create(originalTask))
        
        // Set up state collection
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 3 // Initial + create + update
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                expectation.fulfill()
                if states.count >= 3 {
                    break
                }
            }
        }
        
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        // Update the task
        let updatedTask = Task(
            id: "update-1",
            title: "Updated Title",
            description: "Updated Description",
            priority: .high,
            isCompleted: true
        )
        
        try await taskClient.process(.update(updatedTask))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        // Verify update
        let finalState = states.last!
        XCTAssertEqual(finalState.tasks.count, 1)
        
        let task = finalState.tasks.first!
        XCTAssertEqual(task.title, "Updated Title")
        XCTAssertEqual(task.description, "Updated Description")
        XCTAssertEqual(task.priority, .high)
        XCTAssertEqual(task.isCompleted, true)
    }
    
    // MARK: - Invalid Updates
    
    func testUpdateNonExistentTask() async throws {
        let nonExistentTask = Task(
            id: "non-existent",
            title: "Ghost Task"
        )
        
        // Should throw error or handle gracefully
        do {
            try await taskClient.process(.update(nonExistentTask))
            XCTFail("Should have thrown error for non-existent task")
        } catch TaskValidationError.taskNotFound(let id) {
            XCTAssertEqual(id, "non-existent")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUpdateTaskWithEmptyTitle() async throws {
        // First create a task
        let originalTask = Task(id: "update-2", title: "Valid Title")
        try await taskClient.process(.create(originalTask))
        
        // Try to update with empty title
        let invalidUpdate = Task(id: "update-2", title: "")
        
        do {
            try await taskClient.process(.update(invalidUpdate))
            XCTFail("Should have thrown validation error for empty title")
        } catch TaskValidationError.missingTitle {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUpdateTaskWithTooLongDescription() async throws {
        // First create a task
        let originalTask = Task(id: "update-3", title: "Valid Title")
        try await taskClient.process(.create(originalTask))
        
        // Try to update with description over 500 chars
        let longDescription = String(repeating: "a", count: 501)
        let invalidUpdate = Task(
            id: "update-3",
            title: "Valid Title",
            description: longDescription
        )
        
        do {
            try await taskClient.process(.update(invalidUpdate))
            XCTFail("Should have thrown validation error for description over 500 characters")
        } catch TaskValidationError.descriptionTooLong(let maxLength) {
            XCTAssertEqual(maxLength, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Complete Field Updates
    
    func testUpdateAllTaskFields() async throws {
        // Create initial task with minimal fields
        let originalTask = Task(
            id: "update-4",
            title: "Original",
            description: "",
            dueDate: nil,
            categoryId: nil,
            priority: .low,
            isCompleted: false
        )
        
        try await taskClient.process(.create(originalTask))
        
        // Set up state collection
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 3
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                expectation.fulfill()
                if states.count >= 3 {
                    break
                }
            }
        }
        
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        // Update all fields
        let tomorrow = Date().addingTimeInterval(86400)
        let completeUpdate = Task(
            id: "update-4",
            title: "Completely Updated",
            description: "This task has been completely updated with all new values",
            dueDate: tomorrow,
            categoryId: "work",
            priority: .critical,
            isCompleted: true
        )
        
        try await taskClient.process(.update(completeUpdate))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        let task = states.last!.tasks.first!
        XCTAssertEqual(task.title, "Completely Updated")
        XCTAssertEqual(task.description, "This task has been completely updated with all new values")
        XCTAssertEqual(task.dueDate, tomorrow)
        XCTAssertEqual(task.categoryId, "work")
        XCTAssertEqual(task.priority, .critical)
        XCTAssertEqual(task.isCompleted, true)
    }
    
    // MARK: - Performance Requirements
    
    func testUpdateTaskPerformance() async throws {
        // Create initial task
        let task = Task(id: "perf-update", title: "Performance Test")
        try await taskClient.process(.create(task))
        
        // Measure update time
        let updatedTask = Task(
            id: "perf-update",
            title: "Updated Performance Test",
            priority: .high
        )
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try await taskClient.process(.update(updatedTask))
        
        // Give minimal time for state to propagate
        try await SwiftTask.sleep(nanoseconds: 1_000_000) // 1ms
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let elapsedMs = (endTime - startTime) * 1000
        
        // Should complete within 16ms
        XCTAssertLessThan(elapsedMs, 16, "Task update should complete within 16ms")
    }
    
    // MARK: - Partial Updates
    
    func testUpdateTaskTitle() async throws {
        let original = Task(
            id: "partial-1",
            title: "Original Title",
            description: "Keep this description",
            priority: .medium
        )
        
        try await taskClient.process(.create(original))
        
        // Update only the title
        let titleUpdate = Task(
            id: "partial-1",
            title: "New Title",
            description: original.description,
            priority: original.priority
        )
        
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 3
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                expectation.fulfill()
                if states.count >= 3 {
                    break
                }
            }
        }
        
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        try await taskClient.process(.update(titleUpdate))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        let task = states.last!.tasks.first!
        XCTAssertEqual(task.title, "New Title")
        XCTAssertEqual(task.description, "Keep this description")
        XCTAssertEqual(task.priority, .medium)
    }
    
    // MARK: - Multiple Updates
    
    func testMultipleUpdatesToSameTask() async throws {
        let task = Task(id: "multi-update", title: "Version 1")
        try await taskClient.process(.create(task))
        
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 5 // Initial + create + 3 updates
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                expectation.fulfill()
                if states.count >= 5 {
                    break
                }
            }
        }
        
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        // Update 1
        try await taskClient.process(.update(Task(id: "multi-update", title: "Version 2")))
        
        // Update 2
        try await taskClient.process(.update(Task(id: "multi-update", title: "Version 3", priority: .high)))
        
        // Update 3 - preserve priority from previous update
        try await taskClient.process(.update(Task(id: "multi-update", title: "Final Version", priority: .high, isCompleted: true)))
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        let finalTask = states.last!.tasks.first!
        XCTAssertEqual(finalTask.title, "Final Version")
        XCTAssertEqual(finalTask.priority, .high)
        XCTAssertEqual(finalTask.isCompleted, true)
    }
    
    // MARK: - Edge Cases
    
    func testUpdateTaskToMatchExistingTask() async throws {
        // Create two different tasks
        let task1 = Task(id: "task-1", title: "Task One")
        let task2 = Task(id: "task-2", title: "Task Two")
        
        try await taskClient.process(.create(task1))
        try await taskClient.process(.create(task2))
        
        // Update task2 to have same title as task1 (should be allowed)
        let update = Task(id: "task-2", title: "Task One")
        
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 4
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                expectation.fulfill()
                if states.count >= 4 {
                    break
                }
            }
        }
        
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        try await taskClient.process(.update(update))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        let finalState = states.last!
        XCTAssertEqual(finalState.tasks.count, 2)
        
        // Both tasks should have same title but different IDs
        let titles = finalState.tasks.map { $0.title }
        XCTAssertEqual(titles, ["Task One", "Task One"])
    }
    
    // MARK: - Version Conflict Detection
    
    func testVersionConflictDetection() async throws {
        // Create initial task
        let task = Task(id: "version-test", title: "Version 1")
        try await taskClient.process(.create(task))
        
        // First update (simulating another client)
        let firstUpdate = Task(
            id: "version-test",
            title: "Version 2 - Updated by another client"
        )
        try await taskClient.process(.update(firstUpdate))
        
        // Try to update with stale version (should fail)
        // This simulates a client that loaded the task before the first update
        let staleUpdate = Task(
            id: "version-test",
            title: "Version 2 - Stale update",
            version: 1  // Still has version 1, unaware of the update
        )
        
        do {
            try await taskClient.process(.update(staleUpdate))
            XCTFail("Should have thrown version conflict error")
        } catch TaskValidationError.versionConflict(let expectedVersion, let actualVersion) {
            XCTAssertEqual(expectedVersion, 1)
            XCTAssertEqual(actualVersion, 2)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testVersionAutoIncrement() async throws {
        // Create task and track version changes
        let task = Task(id: "version-increment", title: "Initial")
        try await taskClient.process(.create(task))
        
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 4 // Initial + create + 2 updates
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                expectation.fulfill()
                if states.count >= 4 {
                    break
                }
            }
        }
        
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        // First update
        try await taskClient.process(.update(Task(id: "version-increment", title: "Update 1")))
        
        // Second update
        try await taskClient.process(.update(Task(id: "version-increment", title: "Update 2")))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        let finalTask = states.last!.tasks.first!
        XCTAssertEqual(finalTask.version, 3) // Should be version 3 after 2 updates
        XCTAssertEqual(finalTask.title, "Update 2")
    }
}

// Note: TaskValidationError.taskNotFound will need to be added to the implementation