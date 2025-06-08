import XCTest
import Axiom
@testable import TaskManager

final class TaskListContextDeleteTests: XCTestCase {
    
    // MARK: - RED Phase: Task Deletion Tests
    
    func testTaskDeletionFromList() async {
        // Test direct deletion from list
        // Framework insight: Immediate vs confirmed deletion?
        let client = await TaskTestHelpers.makeClient()
        // Add tasks through client to get actual IDs
        await client.sendAndWait(.addTask(title: "Task 1", description: nil))
        await client.sendAndWait(.addTask(title: "Task 2", description: nil))
        await client.sendAndWait(.addTask(title: "Task 3", description: nil))
        
        let context = await TaskTestHelpers.makeContext(with: [], client: client)
        
        // Get task to delete from state
        let state = await client.state
        guard let taskToDelete = state.task(withTitle: "Task 2") else {
            XCTFail("Task 2 not found")
            return
        }
        
        // Delete the middle task
        await MainActor.run {
            context.deleteTask(id: taskToDelete.id)
        }
        
        // Wait for state update
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // Verify task was deleted
        await TaskTestHelpers.assertTasks(in: client, expectedCount: 2)
        let finalState = await client.state
        XCTAssertNil(finalState.task(withTitle: "Task 2"))
        XCTAssertNotNil(finalState.task(withTitle: "Task 1"))
        XCTAssertNotNil(finalState.task(withTitle: "Task 3"))
    }
    
    func testBulkTaskDeletion() async {
        // Test deleting multiple tasks
        // Framework insight: Batch operations support?
        let client = await TaskTestHelpers.makeClient()
        // Add tasks through client
        await client.sendAndWait(.addTask(title: "Task 1", description: nil))
        await client.sendAndWait(.addTask(title: "Task 2", description: nil))
        await client.sendAndWait(.addTask(title: "Task 3", description: nil))
        await client.sendAndWait(.addTask(title: "Task 4", description: nil))
        
        let context = await TaskTestHelpers.makeContext(with: [], client: client)
        
        // Get tasks to delete from state
        let state = await client.state
        let task1 = state.task(withTitle: "Task 1")
        let task3 = state.task(withTitle: "Task 3")
        guard let task1, let task3 else {
            XCTFail("Tasks not found")
            return
        }
        
        // Delete multiple tasks
        let tasksToDelete = [task1.id, task3.id]
        await MainActor.run {
            context.deleteTasks(ids: tasksToDelete)
        }
        
        // Wait for state updates
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Verify correct tasks were deleted
        await TaskTestHelpers.assertTasks(in: client, expectedCount: 2)
        let finalState = await client.state
        XCTAssertNil(finalState.task(withTitle: "Task 1"))
        XCTAssertNotNil(finalState.task(withTitle: "Task 2"))
        XCTAssertNil(finalState.task(withTitle: "Task 3"))
        XCTAssertNotNil(finalState.task(withTitle: "Task 4"))
    }
    
    func testDeleteConfirmationDialog() async {
        // Test confirmation dialog state management
        // Framework insight: Dialog state patterns?
        let client = await TaskTestHelpers.makeClient()
        await client.sendAndWait(.addTask(title: "Task to Delete", description: nil))
        
        let context = await TaskTestHelpers.makeContext(with: [], client: client)
        
        // Get the task from state
        let state = await client.state
        guard let task = state.tasks.first else {
            XCTFail("Task not found")
            return
        }
        
        await MainActor.run {
            // Initially no task selected for deletion
            XCTAssertNil(context.taskToDelete)
            XCTAssertFalse(context.showDeleteConfirmation)
            
            // Request deletion with confirmation
            context.requestDelete(task: task)
            
            // Should show confirmation
            XCTAssertEqual(context.taskToDelete?.id, task.id)
            XCTAssertTrue(context.showDeleteConfirmation)
            
            // Confirm deletion
            context.confirmDelete()
        }
        
        // Wait for deletion
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // Task should be deleted
        await TaskTestHelpers.assertTasks(in: client, expectedCount: 0)
        
        await MainActor.run {
            // Confirmation should be dismissed
            XCTAssertNil(context.taskToDelete)
            XCTAssertFalse(context.showDeleteConfirmation)
        }
    }
    
    func testCancelDeleteConfirmation() async {
        // Test canceling deletion
        // Framework insight: State restoration after cancel?
        let client = await TaskTestHelpers.makeClient()
        await client.sendAndWait(.addTask(title: "Task to Keep", description: nil))
        
        let context = await TaskTestHelpers.makeContext(with: [], client: client)
        
        // Get the task from state
        let state = await client.state
        guard let task = state.tasks.first else {
            XCTFail("Task not found")
            return
        }
        
        await MainActor.run {
            // Request deletion
            context.requestDelete(task: task)
            XCTAssertTrue(context.showDeleteConfirmation)
            
            // Cancel deletion
            context.cancelDelete()
            
            // Confirmation should be dismissed
            XCTAssertNil(context.taskToDelete)
            XCTAssertFalse(context.showDeleteConfirmation)
        }
        
        // Task should still exist
        await TaskTestHelpers.assertTasks(in: client, expectedCount: 1)
    }
    
    func testOptimisticDeletion() async {
        // Test optimistic UI updates during deletion
        // Framework insight: Optimistic update patterns?
        let client = await TaskTestHelpers.makeClient()
        await client.sendAndWait(.addTask(title: "Task", description: nil))
        
        let context = await TaskTestHelpers.makeContext(with: [], client: client)
        
        // Get the task from state
        let state = await client.state
        guard let task = state.tasks.first else {
            XCTFail("Task not found")
            return
        }
        
        await MainActor.run {
            // Enable optimistic updates
            context.useOptimisticUpdates = true
            
            // Delete should update UI immediately
            context.deleteTask(id: task.id)
            
            // UI state should reflect deletion immediately
            XCTAssertTrue(context.deletingTaskIds.contains(task.id))
        }
    }
}

