import XCTest
import Axiom
@testable import TestApp002Core

// RED Phase: Task deletion tests that should fail without proper validation
final class TaskDeletionTests: XCTestCase {
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
    
    // MARK: - Single Task Deletion
    
    func testDeleteExistingTask() async throws {
        // First create a task
        let task = Task(
            id: "delete-1",
            title: "Task to be deleted",
            description: "This task will be deleted"
        )
        
        try await taskClient.process(.create(task))
        
        // Set up state collection
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 3 // Initial + create + delete
        
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
        
        // Delete the task
        try await taskClient.process(.delete(taskId: "delete-1"))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        // Verify task was removed
        let finalState = states.last!
        XCTAssertEqual(finalState.tasks.count, 0)
        XCTAssertFalse(finalState.tasks.contains { $0.id == "delete-1" })
    }
    
    func testDeleteNonExistentTask() async throws {
        // Try to delete a task that doesn't exist
        do {
            try await taskClient.process(.delete(taskId: "non-existent"))
            XCTFail("Should have thrown error for non-existent task")
        } catch TaskValidationError.taskNotFound(let id) {
            XCTAssertEqual(id, "non-existent")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Bulk Deletion
    
    func testBulkDeleteMultipleTasks() async throws {
        // Create multiple tasks
        let taskIds = ["bulk-1", "bulk-2", "bulk-3", "bulk-4", "bulk-5"]
        
        for id in taskIds {
            let task = Task(id: id, title: "Bulk task \(id)")
            try await taskClient.process(.create(task))
        }
        
        // Set up state collection
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 7 // Initial + 5 creates + 1 bulk delete
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                expectation.fulfill()
                if states.count >= 7 {
                    break
                }
            }
        }
        
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        // Bulk delete tasks
        try await taskClient.process(.bulkDelete(["bulk-1", "bulk-3", "bulk-5"]))
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Verify only the specified tasks were deleted
        let finalState = states.last!
        XCTAssertEqual(finalState.tasks.count, 2)
        XCTAssertTrue(finalState.tasks.contains { $0.id == "bulk-2" })
        XCTAssertTrue(finalState.tasks.contains { $0.id == "bulk-4" })
        XCTAssertFalse(finalState.tasks.contains { $0.id == "bulk-1" })
        XCTAssertFalse(finalState.tasks.contains { $0.id == "bulk-3" })
        XCTAssertFalse(finalState.tasks.contains { $0.id == "bulk-5" })
    }
    
    func testBulkDeleteWithSomeNonExistentTasks() async throws {
        // Create some tasks
        let task1 = Task(id: "exists-1", title: "Existing task 1")
        let task2 = Task(id: "exists-2", title: "Existing task 2")
        
        try await taskClient.process(.create(task1))
        try await taskClient.process(.create(task2))
        
        // Try bulk delete with mix of existing and non-existing IDs
        do {
            try await taskClient.process(.bulkDelete(["exists-1", "non-existent-1", "exists-2", "non-existent-2"]))
            XCTFail("Should have thrown error for non-existent tasks")
        } catch TaskValidationError.bulkDeletePartialFailure(let failedIds) {
            XCTAssertEqual(Set(failedIds), Set(["non-existent-1", "non-existent-2"]))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testBulkDeleteEmptyList() async throws {
        // Try to bulk delete with empty array
        do {
            try await taskClient.process(.bulkDelete([]))
            XCTFail("Should have thrown error for empty bulk delete")
        } catch TaskValidationError.emptyBulkOperation {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testDeleteSingleTaskPerformance() async throws {
        // Create a task
        let task = Task(id: "perf-delete", title: "Performance test task")
        try await taskClient.process(.create(task))
        
        // Measure deletion time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try await taskClient.process(.delete(taskId: "perf-delete"))
        
        // Give minimal time for state to propagate
        try await SwiftTask.sleep(nanoseconds: 1_000_000) // 1ms
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let elapsedMs = (endTime - startTime) * 1000
        
        // Should complete within 16ms
        XCTAssertLessThan(elapsedMs, 16, "Task deletion should complete within 16ms")
    }
    
    func testBulkDelete100TasksPerformance() async throws {
        // Create 100 tasks
        let taskIds = (0..<100).map { "perf-bulk-\($0)" }
        
        for id in taskIds {
            let task = Task(id: id, title: "Bulk perf task \(id)")
            try await taskClient.process(.create(task))
        }
        
        // Measure bulk deletion time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try await taskClient.process(.bulkDelete(taskIds))
        
        // Give time for state to propagate
        try await SwiftTask.sleep(nanoseconds: 10_000_000) // 10ms
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let elapsedMs = (endTime - startTime) * 1000
        
        // Should complete within 100ms
        XCTAssertLessThan(elapsedMs, 100, "Bulk deletion of 100 tasks should complete within 100ms")
    }
    
    // MARK: - Soft Delete Functionality
    
    func testSoftDeleteTask() async throws {
        // Create a task
        let task = Task(
            id: "soft-delete-1",
            title: "Task for soft delete",
            description: "This task will be soft deleted"
        )
        
        try await taskClient.process(.create(task))
        
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
        
        // Soft delete the task
        try await taskClient.process(.softDelete("soft-delete-1"))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        // Verify task is marked as deleted but still exists
        let finalState = states.last!
        XCTAssertEqual(finalState.tasks.count, 1)
        
        let deletedTask = finalState.tasks.first!
        XCTAssertEqual(deletedTask.id, "soft-delete-1")
        XCTAssertTrue(deletedTask.isDeleted)
        XCTAssertNotNil(deletedTask.deletedAt)
    }
    
    func testSoftDeletePreservesTaskData() async throws {
        // Create a complete task
        let dueDate = Date().addingTimeInterval(86400)
        let task = Task(
            id: "soft-delete-2",
            title: "Complete task",
            description: "Task with all fields",
            dueDate: dueDate,
            categoryId: "work",
            priority: .critical,
            isCompleted: true
        )
        
        try await taskClient.process(.create(task))
        
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
        
        // Soft delete
        try await taskClient.process(.softDelete("soft-delete-2"))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        // Verify all data is preserved
        let deletedTask = states.last!.tasks.first!
        XCTAssertEqual(deletedTask.title, "Complete task")
        XCTAssertEqual(deletedTask.description, "Task with all fields")
        XCTAssertEqual(deletedTask.dueDate, dueDate)
        XCTAssertEqual(deletedTask.categoryId, "work")
        XCTAssertEqual(deletedTask.priority, .critical)
        XCTAssertEqual(deletedTask.isCompleted, true)
        XCTAssertTrue(deletedTask.isDeleted)
    }
    
    // MARK: - Undo Deletion
    
    func testUndoDeleteTask() async throws {
        // Create and soft delete a task
        let task = Task(id: "undo-1", title: "Task to undo delete")
        try await taskClient.process(.create(task))
        try await taskClient.process(.softDelete("undo-1"))
        
        // Set up state collection
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 4 // Initial + create + soft delete + undo
        
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
        
        // Undo deletion
        try await taskClient.process(.undoDelete("undo-1"))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        // Verify task is restored
        let restoredTask = states.last!.tasks.first!
        XCTAssertEqual(restoredTask.id, "undo-1")
        XCTAssertFalse(restoredTask.isDeleted)
        XCTAssertNil(restoredTask.deletedAt)
    }
    
    func testUndoDeleteNonDeletedTask() async throws {
        // Create a task that's not deleted
        let task = Task(id: "not-deleted", title: "Active task")
        try await taskClient.process(.create(task))
        
        // Try to undo delete on non-deleted task
        do {
            try await taskClient.process(.undoDelete("not-deleted"))
            XCTFail("Should have thrown error for non-deleted task")
        } catch TaskValidationError.taskNotDeleted(let id) {
            XCTAssertEqual(id, "not-deleted")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUndoDeleteAfterHardDelete() async throws {
        // Create and hard delete a task
        let task = Task(id: "hard-deleted", title: "Permanently deleted")
        try await taskClient.process(.create(task))
        try await taskClient.process(.delete(taskId: "hard-deleted"))
        
        // Try to undo delete
        do {
            try await taskClient.process(.undoDelete("hard-deleted"))
            XCTFail("Should have thrown error for hard deleted task")
        } catch TaskValidationError.taskNotFound(let id) {
            XCTAssertEqual(id, "hard-deleted")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Permanent Deletion After Soft Delete
    
    func testPermanentDeleteAfterSoftDelete() async throws {
        // Create and soft delete a task
        let task = Task(id: "perm-delete-1", title: "To be permanently deleted")
        try await taskClient.process(.create(task))
        try await taskClient.process(.softDelete("perm-delete-1"))
        
        // Set up state collection
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 4 // Initial + create + soft delete + permanent delete
        
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
        
        // Permanently delete
        try await taskClient.process(.permanentDelete("perm-delete-1"))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        // Verify task is completely removed
        let finalState = states.last!
        XCTAssertEqual(finalState.tasks.count, 0)
        XCTAssertFalse(finalState.tasks.contains { $0.id == "perm-delete-1" })
    }
    
    func testPermanentDeleteNonSoftDeletedTask() async throws {
        // Create an active task
        let task = Task(id: "active-task", title: "Active task")
        try await taskClient.process(.create(task))
        
        // Try to permanently delete without soft delete first
        do {
            try await taskClient.process(.permanentDelete("active-task"))
            XCTFail("Should have thrown error for non-soft-deleted task")
        } catch TaskValidationError.taskNotDeleted(let id) {
            XCTAssertEqual(id, "active-task")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Deletion with Retention Period
    
    func testDeletionWithRetentionPeriod() async throws {
        // Create a task with retention period
        let task = Task(id: "retention-1", title: "Task with retention")
        try await taskClient.process(.create(task))
        
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
        
        // Soft delete with 30-day retention
        let retentionDays = 30
        try await taskClient.process(.softDeleteWithRetention("retention-1", retentionDays: retentionDays))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        // Verify retention period is set
        let deletedTask = states.last!.tasks.first!
        XCTAssertTrue(deletedTask.isDeleted)
        XCTAssertNotNil(deletedTask.deletedAt)
        XCTAssertEqual(deletedTask.retentionDays, retentionDays)
        
        // Calculate expected purge date
        if let deletedAt = deletedTask.deletedAt {
            let expectedPurgeDate = deletedAt.addingTimeInterval(TimeInterval(retentionDays * 24 * 60 * 60))
            XCTAssertEqual(deletedTask.scheduledPurgeDate, expectedPurgeDate)
        }
    }
    
    func testBulkSoftDeleteWithRetention() async throws {
        // Create multiple tasks
        let taskIds = ["retention-bulk-1", "retention-bulk-2", "retention-bulk-3"]
        
        for id in taskIds {
            let task = Task(id: id, title: "Bulk retention task \(id)")
            try await taskClient.process(.create(task))
        }
        
        // Set up state collection
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 5 // Initial + 3 creates + 1 bulk soft delete
        
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
        
        // Bulk soft delete with retention
        let retentionDays = 7
        try await taskClient.process(.bulkSoftDeleteWithRetention(taskIds, retentionDays: retentionDays))
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Verify all tasks have retention set
        let finalState = states.last!
        XCTAssertEqual(finalState.tasks.count, 3)
        
        for task in finalState.tasks {
            XCTAssertTrue(task.isDeleted)
            XCTAssertNotNil(task.deletedAt)
            XCTAssertEqual(task.retentionDays, retentionDays)
            XCTAssertNotNil(task.scheduledPurgeDate)
        }
    }
    
    // MARK: - Error Cases
    
    func testDeleteTaskTwice() async throws {
        // Create and delete a task
        let task = Task(id: "delete-twice", title: "Delete twice test")
        try await taskClient.process(.create(task))
        try await taskClient.process(.delete(taskId: "delete-twice"))
        
        // Try to delete again
        do {
            try await taskClient.process(.delete(taskId: "delete-twice"))
            XCTFail("Should have thrown error for already deleted task")
        } catch TaskValidationError.taskNotFound(let id) {
            XCTAssertEqual(id, "delete-twice")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testSoftDeleteTaskTwice() async throws {
        // Create and soft delete a task
        let task = Task(id: "soft-delete-twice", title: "Soft delete twice test")
        try await taskClient.process(.create(task))
        try await taskClient.process(.softDelete("soft-delete-twice"))
        
        // Try to soft delete again
        do {
            try await taskClient.process(.softDelete("soft-delete-twice"))
            XCTFail("Should have thrown error for already soft deleted task")
        } catch TaskValidationError.taskAlreadyDeleted(let id) {
            XCTAssertEqual(id, "soft-delete-twice")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Complex Scenarios
    
    func testDeleteAndRecreateWithSameId() async throws {
        // Create, delete, then recreate with same ID
        let originalTask = Task(id: "recreate-1", title: "Original task")
        try await taskClient.process(.create(originalTask))
        try await taskClient.process(.delete(taskId: "recreate-1"))
        
        // Should be able to create new task with same ID
        let newTask = Task(id: "recreate-1", title: "New task with same ID")
        
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 4 // Initial + create + delete + recreate
        
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
        
        try await taskClient.process(.create(newTask))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        let finalTask = states.last!.tasks.first!
        XCTAssertEqual(finalTask.id, "recreate-1")
        XCTAssertEqual(finalTask.title, "New task with same ID")
        XCTAssertFalse(finalTask.isDeleted)
    }
    
    func testMixedBulkOperations() async throws {
        // Create tasks with different states
        let activeTask1 = Task(id: "mixed-active-1", title: "Active 1")
        let activeTask2 = Task(id: "mixed-active-2", title: "Active 2")
        let toDelete = Task(id: "mixed-delete", title: "To delete")
        let toSoftDelete = Task(id: "mixed-soft", title: "To soft delete")
        
        try await taskClient.process(.create(activeTask1))
        try await taskClient.process(.create(activeTask2))
        try await taskClient.process(.create(toDelete))
        try await taskClient.process(.create(toSoftDelete))
        
        // Perform mixed operations
        try await taskClient.process(.delete(taskId: "mixed-delete"))
        try await taskClient.process(.softDelete("mixed-soft"))
        
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 7 // Initial + 4 creates + delete + soft delete
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                expectation.fulfill()
                if states.count >= 7 {
                    break
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Verify final state
        let finalState = states.last!
        XCTAssertEqual(finalState.tasks.count, 3) // 2 active + 1 soft deleted
        
        // Check active tasks
        XCTAssertTrue(finalState.tasks.contains(where: { $0.id == "mixed-active-1" && !$0.isDeleted }))
        XCTAssertTrue(finalState.tasks.contains(where: { $0.id == "mixed-active-2" && !$0.isDeleted }))
        
        // Check soft deleted task
        XCTAssertTrue(finalState.tasks.contains(where: { $0.id == "mixed-soft" && $0.isDeleted }))
        
        // Hard deleted task should not exist
        XCTAssertFalse(finalState.tasks.contains(where: { $0.id == "mixed-delete" }))
    }
}

// Note: The following errors need to be added to TaskValidationError:
// - bulkDeletePartialFailure(failedIds: [String])
// - emptyBulkOperation
// - taskNotDeleted(id: String)
// - taskAlreadyDeleted(id: String)