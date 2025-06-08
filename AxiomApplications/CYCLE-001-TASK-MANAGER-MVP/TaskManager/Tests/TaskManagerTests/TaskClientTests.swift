import XCTest
import Axiom
@testable import TaskManager

final class TaskClientTests: XCTestCase {
    
    // MARK: - Refactored TaskClient Tests
    
    func testTaskClientInitialization() async {
        // REFACTOR: Using test helpers for cleaner setup
        let client = await TaskTestHelpers.makeClient()
        
        // Verify initial state
        await TaskTestHelpers.assertTasks(in: client, expectedCount: 0)
    }
    
    func testTaskClientStateProtocol() async {
        // REFACTOR: Simplified with helpers
        let client = await TaskTestHelpers.makeClient()
        let state = await client.state
        
        // State protocol conformance
        XCTAssertNotNil(state as any State)
    }
    
    func testTaskClientActionProcessing() async {
        // REFACTOR: Using sendAndWait helper
        let client = await TaskTestHelpers.makeClient()
        
        await client.sendAndWait(.addTask(
            title: "Test Task",
            description: nil
        ))
        
        // Verify using helper assertions
        await TaskTestHelpers.assertTasks(in: client, expectedCount: 1)
        
        let state = await client.state
        XCTAssertEqual(state.task(withTitle: "Test Task")?.title, "Test Task")
    }
    
    func testTaskClientConcurrentActions() async {
        // REFACTOR: Cleaner concurrent test
        let client = await TaskTestHelpers.makeClient()
        
        // Send multiple actions concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask {
                    await client.send(.addTask(
                        title: "Task \(i)",
                        description: nil
                    ))
                }
            }
        }
        
        await TaskTestHelpers.assertTasks(in: client, expectedCount: 10)
    }
    
    func testTaskClientStateStreamWithoutObservation() async throws {
        // REFACTOR: Using stream helper
        let client = await TaskTestHelpers.makeClient()
        
        // Start listening for updates
        async let updates = TaskTestHelpers.waitForStateUpdates(
            from: client,
            updateCount: 2
        )
        
        // Send action
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        await client.send(.addTask(title: "Stream Test", description: nil))
        
        // Verify updates
        let states = try await updates
        XCTAssertGreaterThanOrEqual(states.count, 2, "Expected at least 2 state updates")
        if states.count >= 2 {
            XCTAssertEqual(states[0].tasks.count, 0)
            XCTAssertEqual(states[1].tasks.count, 1)
        }
    }
    
    // MARK: - Additional Tests Added During Refactor
    
    func testTaskDeletion() async {
        // REFACTOR: New test for delete functionality
        let client = await TaskTestHelpers.makeClient()
        
        // Add a task
        await client.sendAndWait(.addTask(title: "To Delete", description: nil))
        
        // Get the task from state to get actual ID
        let state = await client.state
        guard let task = state.tasks.first else {
            XCTFail("No task found after adding")
            return
        }
        
        // Delete using actual ID
        await client.sendAndWait(.deleteTask(id: task.id))
        
        await TaskTestHelpers.assertTasks(in: client, expectedCount: 0)
    }
    
    func testTaskUpdate() async {
        // REFACTOR: New test for update functionality
        let client = await TaskTestHelpers.makeClient()
        
        // Add a task
        await client.sendAndWait(.addTask(title: "Original", description: nil))
        
        // Get the task from state to get actual ID
        let state = await client.state
        guard let task = state.tasks.first else {
            XCTFail("No task found after adding")
            return
        }
        
        // Update using actual ID
        await client.sendAndWait(.updateTask(
            id: task.id,
            title: "Updated",
            description: nil,
            categoryId: nil,
            priority: nil,
            dueDate: nil,
            isCompleted: true
        ))
        
        let updatedState = await client.state
        let updatedTask = updatedState.task(withTitle: "Updated")
        
        XCTAssertNotNil(updatedTask)
        XCTAssertTrue(updatedTask?.isCompleted ?? false)
    }
    
    func testTaskNotFoundError() async {
        // REFACTOR: New test for error handling
        let client = await TaskTestHelpers.makeClient()
        let invalidId = UUID()
        
        await client.sendAndWait(.deleteTask(id: invalidId))
        
        let state = await client.state
        XCTAssertTrue(state.hasError(.taskNotFound(invalidId)))
    }
}

