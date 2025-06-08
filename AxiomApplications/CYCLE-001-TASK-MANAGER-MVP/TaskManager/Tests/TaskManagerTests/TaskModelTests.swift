import XCTest
import Axiom
@testable import TaskManager

final class TaskModelTests: XCTestCase {
    
    // MARK: - Refactored Task Model Tests
    
    func testTaskConformsToStateProtocol() {
        // REFACTOR: Using test helper for task creation
        let task = TaskTestHelpers.makeTask()
        
        // Verify State protocol conformance
        XCTAssertNotNil(task as any State)
    }
    
    func testTaskIsHashable() {
        // REFACTOR: Cleaner test with helpers
        let id = UUID()
        let date = Date()
        
        let task1 = TaskTestHelpers.makeTask(id: id, createdAt: date, updatedAt: date)
        let task2 = TaskTestHelpers.makeTask(id: id, createdAt: date, updatedAt: date)
        
        XCTAssertEqual(task1.hashValue, task2.hashValue)
    }
    
    func testTaskIsSendable() {
        // REFACTOR: Simplified with helper
        let task = TaskTestHelpers.makeTask(title: "Sendable Task")
        
        // This test verifies compile-time Sendable conformance
        _Concurrency.Task {
            let _ = task // Should compile without warnings
        }
    }
    
    func testTaskEquality() {
        // REFACTOR: More readable with consistent helpers
        let id = UUID()
        let date = Date()
        
        let task1 = TaskTestHelpers.makeTask(
            id: id,
            title: "Task",
            createdAt: date,
            updatedAt: date
        )
        
        let task2 = TaskTestHelpers.makeTask(
            id: id,
            title: "Task", 
            createdAt: date,
            updatedAt: date
        )
        
        XCTAssertEqual(task1, task2)
    }
    
    func testTaskInequality() {
        // REFACTOR: Clear intent with helpers
        let task1 = TaskTestHelpers.makeTask(title: "Task 1")
        let task2 = TaskTestHelpers.makeTask(title: "Task 2")
        
        XCTAssertNotEqual(task1, task2)
    }
    
    // MARK: - Additional Tests Added During Refactor
    
    func testTaskWithDescription() {
        let task = TaskTestHelpers.makeTask(
            title: "Task with description",
            description: "This is a detailed description"
        )
        
        XCTAssertEqual(task.description, "This is a detailed description")
    }
    
    func testTaskCompletionStatus() {
        let incompleteTask = TaskTestHelpers.makeTask(isCompleted: false)
        let completeTask = TaskTestHelpers.makeTask(isCompleted: true)
        
        XCTAssertFalse(incompleteTask.isCompleted)
        XCTAssertTrue(completeTask.isCompleted)
    }
}

