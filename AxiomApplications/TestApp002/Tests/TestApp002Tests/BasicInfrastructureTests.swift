import XCTest
@testable import TestApp002Core

final class BasicInfrastructureTests: XCTestCase {
    
    func testBasicSetup() {
        // This test verifies our test infrastructure is working
        XCTAssertEqual(1 + 1, 2)
    }
    
    func testTaskModelCreation() {
        // Test that we can create a Task model
        let task = Task(
            id: "test-123",
            title: "Test Task",
            description: "Test Description",
            dueDate: nil,
            categoryId: nil,
            priority: .medium,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        XCTAssertEqual(task.id, "test-123")
        XCTAssertEqual(task.title, "Test Task")
        XCTAssertEqual(task.priority, .medium)
    }
}