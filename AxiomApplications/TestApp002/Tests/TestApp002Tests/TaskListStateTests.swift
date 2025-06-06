import XCTest
@testable import TestApp002Core

final class TaskListStateTests: XCTestCase {
    
    // MARK: - Red Phase: Test TaskListState immutability fails
    
    func testTaskListStateImmutability() throws {
        // Test that TaskListState is truly immutable
        let initialTasks = [
            Task(id: "1", title: "Task 1", description: "Desc 1", dueDate: nil, categoryId: nil, priority: .high, isCompleted: false, createdAt: Date(), updatedAt: Date()),
            Task(id: "2", title: "Task 2", description: "Desc 2", dueDate: nil, categoryId: nil, priority: .medium, isCompleted: true, createdAt: Date(), updatedAt: Date())
        ]
        
        let state1 = TaskListState(
            tasks: initialTasks,
            categories: [],
            searchQuery: "test",
            sortCriteria: .priority
        )
        
        // Create a new state by modifying tasks - original should be unchanged
        var newTasks = initialTasks
        newTasks.append(Task(id: "3", title: "Task 3", description: "Desc 3", dueDate: nil, categoryId: nil, priority: .low, isCompleted: false, createdAt: Date(), updatedAt: Date()))
        
        let state2 = TaskListState(
            tasks: newTasks,
            categories: state1.categories,
            searchQuery: state1.searchQuery,
            sortCriteria: state1.sortCriteria
        )
        
        // Original state should be unchanged
        XCTAssertEqual(state1.tasks.count, 2)
        XCTAssertEqual(state2.tasks.count, 3)
        XCTAssertNotEqual(state1, state2)
    }
    
    func testTaskListStateEquatable() throws {
        let task1 = Task(id: "1", title: "Task 1", description: "Desc 1", dueDate: nil, categoryId: nil, priority: .high, isCompleted: false, createdAt: Date(), updatedAt: Date())
        let task2 = Task(id: "2", title: "Task 2", description: "Desc 2", dueDate: nil, categoryId: nil, priority: .medium, isCompleted: true, createdAt: Date(), updatedAt: Date())
        
        let category1 = Category(id: "cat1", name: "Work", color: "#FF0000")
        
        let state1 = TaskListState(
            tasks: [task1, task2],
            categories: [category1],
            searchQuery: "test",
            sortCriteria: .priority
        )
        
        let state2 = TaskListState(
            tasks: [task1, task2],
            categories: [category1],
            searchQuery: "test",
            sortCriteria: .priority
        )
        
        // Should be equal with same content
        XCTAssertEqual(state1, state2)
        
        // Should be different with different content
        let state3 = TaskListState(
            tasks: [task1], // Different tasks
            categories: [category1],
            searchQuery: "test",
            sortCriteria: .priority
        )
        
        XCTAssertNotEqual(state1, state3)
    }
    
    func testTaskListStateCustomEquatable() throws {
        // This test should verify the custom Equatable implementation
        // that compares task count and last modification timestamp
        // as specified in the RFC for performance with large arrays
        
        let now = Date()
        let tasks1 = (0..<1000).map { index in
            Task(
                id: "task-\(index)",
                title: "Task \(index)",
                description: "Description \(index)",
                dueDate: nil,
                categoryId: nil,
                priority: .medium,
                isCompleted: false,
                createdAt: now,
                updatedAt: now
            )
        }
        
        let tasks2 = (0..<1000).map { index in
            Task(
                id: "task-\(index)",
                title: "Task \(index)",
                description: "Description \(index)",
                dueDate: nil,
                categoryId: nil,
                priority: .medium,
                isCompleted: false,
                createdAt: now,
                updatedAt: now
            )
        }
        
        let state1 = TaskListState(tasks: tasks1, categories: [], searchQuery: "", sortCriteria: .createdDate)
        let state2 = TaskListState(tasks: tasks2, categories: [], searchQuery: "", sortCriteria: .createdDate)
        
        // Performance test: equality check should complete in < 50ms
        let startTime = CFAbsoluteTimeGetCurrent()
        let areEqual = state1 == state2
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertTrue(areEqual)
        XCTAssertLessThan(duration * 1000, 50, "Equality check took too long: \(duration * 1000)ms")
    }
    
    func testTaskListStateHashable() throws {
        let task1 = Task(id: "1", title: "Task 1", description: "Desc 1", dueDate: nil, categoryId: nil, priority: .high, isCompleted: false, createdAt: Date(), updatedAt: Date())
        
        let state1 = TaskListState(tasks: [task1], categories: [], searchQuery: "test", sortCriteria: .priority)
        let state2 = TaskListState(tasks: [task1], categories: [], searchQuery: "test", sortCriteria: .priority)
        
        // Equal states should have equal hash values
        XCTAssertEqual(state1.hashValue, state2.hashValue)
        
        // Different states should have different hash values (in most cases)
        let state3 = TaskListState(tasks: [], categories: [], searchQuery: "test", sortCriteria: .priority)
        XCTAssertNotEqual(state1.hashValue, state3.hashValue)
    }
    
    func testTaskArrayImmutability() throws {
        var tasks = [
            Task(id: "1", title: "Task 1", description: "Desc 1", dueDate: nil, categoryId: nil, priority: .high, isCompleted: false, createdAt: Date(), updatedAt: Date())
        ]
        
        let state = TaskListState(tasks: tasks, categories: [], searchQuery: "", sortCriteria: .createdDate)
        
        // Modifying original array should not affect state
        tasks.append(Task(id: "2", title: "Task 2", description: "Desc 2", dueDate: nil, categoryId: nil, priority: .medium, isCompleted: false, createdAt: Date(), updatedAt: Date()))
        
        XCTAssertEqual(state.tasks.count, 1, "State should not be affected by external array modification")
        XCTAssertEqual(tasks.count, 2, "Original array should be modified")
    }
    
    func testStateUpdatePerformance() throws {
        // Test that state updates complete in < 50ms as per RFC
        let tasks = (0..<100).map { index in
            Task(
                id: "task-\(index)",
                title: "Task \(index)",
                description: "Description \(index)",
                dueDate: nil,
                categoryId: nil,
                priority: .medium,
                isCompleted: false,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        let originalState = TaskListState(tasks: tasks, categories: [], searchQuery: "", sortCriteria: .createdDate)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create new state with modified tasks
        let newState = TaskListState(
            tasks: tasks + [Task(id: "new-task", title: "New Task", description: "New Description", dueDate: nil, categoryId: nil, priority: .high, isCompleted: false, createdAt: Date(), updatedAt: Date())],
            categories: originalState.categories,
            searchQuery: originalState.searchQuery,
            sortCriteria: originalState.sortCriteria
        )
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertNotEqual(originalState, newState)
        XCTAssertLessThan(duration * 1000, 50, "State update took too long: \(duration * 1000)ms")
    }
}