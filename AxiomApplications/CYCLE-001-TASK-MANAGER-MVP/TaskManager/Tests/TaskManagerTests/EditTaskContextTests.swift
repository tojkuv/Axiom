import XCTest
import Axiom
@testable import TaskManager

final class EditTaskContextTests: XCTestCase {
    
    // MARK: - RED Phase: EditTaskContext Tests
    
    func testEditTaskContextInitialization() async {
        // Testing context initialization with existing task
        // Framework insight: How to pass initial data to contexts?
        let task = TaskTestHelpers.makeTask(
            title: "Original Title",
            description: "Original Description",
            isCompleted: false
        )
        let client = await TaskTestHelpers.makeClient(with: [task])
        let mockNavigation = await MockNavigationService()
        
        let context = await EditTaskContext(
            client: client,
            task: task,
            navigationService: mockNavigation
        )
        
        await MainActor.run {
            // Should load task data
            XCTAssertEqual(context.title, "Original Title")
            XCTAssertEqual(context.description, "Original Description")
            XCTAssertEqual(context.isCompleted, false)
            XCTAssertEqual(context.taskId, task.id)
        }
    }
    
    func testEditTaskValidation() async {
        // Test validation for edited task
        // Framework insight: Same validation patterns as create?
        let task = TaskTestHelpers.makeTask(title: "Task")
        let client = await TaskTestHelpers.makeClient(with: [task])
        let context = await EditTaskContext(client: client, task: task)
        
        await MainActor.run {
            // Empty title should fail
            context.title = ""
            XCTAssertFalse(context.isValid)
            
            // Valid title should pass
            context.title = "Updated Title"
            XCTAssertTrue(context.isValid)
        }
    }
    
    func testEditTaskSubmission() async {
        // Test task update through context
        // Framework insight: How to handle optimistic updates?
        let client = await TaskTestHelpers.makeClient()
        
        // Add task through client to get actual ID
        await client.sendAndWait(.addTask(
            title: "Original",
            description: "Description"
        ))
        
        // Get the actual task from state
        let state = await client.state
        guard let task = state.tasks.first else {
            XCTFail("Task not created")
            return
        }
        
        let mockNavigation = await MockNavigationService()
        let context = await EditTaskContext(
            client: client,
            task: task,
            navigationService: mockNavigation
        )
        
        await MainActor.run {
            // Update task data
            context.title = "Updated Title"
            context.description = "Updated Description"
            context.isCompleted = true
        }
        
        // Submit changes
        await context.submit()
        
        // Verify task was updated in client
        let updatedState = await client.state
        let updatedTask = updatedState.tasks.first { $0.id == task.id }
        XCTAssertNotNil(updatedTask)
        XCTAssertEqual(updatedTask?.title, "Updated Title")
        XCTAssertEqual(updatedTask?.description, "Updated Description")
        XCTAssertEqual(updatedTask?.isCompleted, true)
        
        // Verify navigation was dismissed
        await MainActor.run {
            XCTAssertTrue(mockNavigation.dismissCalled)
        }
    }
    
    func testEditTaskWithNoChanges() async {
        // Test submitting without changes
        // Framework insight: Should we track dirty state?
        let task = TaskTestHelpers.makeTask(title: "Original")
        let client = await TaskTestHelpers.makeClient(with: [task])
        let mockNavigation = await MockNavigationService()
        let context = await EditTaskContext(
            client: client,
            task: task,
            navigationService: mockNavigation
        )
        
        // Submit without changes
        await context.submit()
        
        // Should still dismiss
        await MainActor.run {
            XCTAssertTrue(mockNavigation.dismissCalled)
        }
    }
    
    func testEditNonExistentTask() async {
        // Test editing a task that doesn't exist
        // Framework insight: Error handling for missing data?
        let task = TaskTestHelpers.makeTask(title: "Ghost Task")
        let client = await TaskTestHelpers.makeClient() // Empty client
        let context = await EditTaskContext(client: client, task: task)
        
        await context.submit()
        
        // Should handle gracefully
        let state = await client.state
        XCTAssertTrue(state.tasks.isEmpty)
    }
    
    func testTaskDeletionFromEditView() async {
        // Test delete action from edit context
        // Framework insight: How to handle deletion with confirmation?
        let client = await TaskTestHelpers.makeClient()
        
        // Add task through client to get actual ID
        await client.sendAndWait(.addTask(title: "To Delete", description: nil))
        
        // Get the actual task from state
        let state = await client.state
        guard let task = state.tasks.first else {
            XCTFail("Task not created")
            return
        }
        
        let mockNavigation = await MockNavigationService()
        let context = await EditTaskContext(
            client: client,
            task: task,
            navigationService: mockNavigation
        )
        
        // Delete the task
        await context.deleteTask()
        
        // Verify task was deleted
        let deletedState = await client.state
        XCTAssertTrue(deletedState.tasks.isEmpty)
        
        // Verify navigation was dismissed
        await MainActor.run {
            XCTAssertTrue(mockNavigation.dismissCalled)
        }
    }
    
    func testDeleteConfirmationState() async {
        // Test confirmation dialog state
        // Framework insight: How to manage confirmation state?
        let task = TaskTestHelpers.makeTask(title: "Task")
        let client = await TaskTestHelpers.makeClient(with: [task])
        let context = await EditTaskContext(client: client, task: task)
        
        await MainActor.run {
            // Initially not showing confirmation
            XCTAssertFalse(context.showDeleteConfirmation)
            
            // Request deletion
            context.confirmDelete()
            
            // Should show confirmation
            XCTAssertTrue(context.showDeleteConfirmation)
            
            // Cancel deletion
            context.cancelDelete()
            
            // Should hide confirmation
            XCTAssertFalse(context.showDeleteConfirmation)
        }
    }
}

