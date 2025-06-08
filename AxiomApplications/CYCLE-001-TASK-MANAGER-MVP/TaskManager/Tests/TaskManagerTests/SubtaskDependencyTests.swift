import XCTest
@testable import TaskManager

/// Comprehensive tests for REQ-010: Subtasks and Dependencies
/// 
/// Framework Components Under Test: Nested State, Recursive Updates, Circular Detection
/// Expected Pain Points: Nested state updates, dependency validation, deep nesting performance
final class SubtaskDependencyTests: XCTestCase {
    
    // MARK: - Test Setup
    
    override func setUp() async throws {
        try await super.setUp()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
    }
    
    // MARK: - RED Phase Tests - Subtask Creation
    
    func testSubtaskCreation() async throws {
        // FRAMEWORK INSIGHT: Testing nested state structure
        let client = TaskClient()
        
        // Create parent task
        try await client.process(.addTask(
            title: "Parent Task",
            description: "Main task with subtasks"
        ))
        
        let parentState = await client.state
        let parentTask = parentState.tasks.first!
        
        // Create subtask
        try await client.process(.addSubtask(
            parentId: parentTask.id,
            title: "Subtask 1",
            description: "First subtask"
        ))
        
        let updatedState = await client.state
        let parent = updatedState.tasks.first { $0.id == parentTask.id }!
        
        // Verify subtask was added
        XCTAssertEqual(parent.subtasks.count, 1)
        XCTAssertEqual(parent.subtasks.first?.title, "Subtask 1")
        XCTAssertEqual(parent.subtasks.first?.parentId, parentTask.id)
    }
    
    func testNestedSubtaskCreation() async throws {
        // FRAMEWORK INSIGHT: Testing deep hierarchy state updates
        let client = TaskClient()
        
        // Create parent task
        try await client.process(.addTask(title: "Root Task", description: nil))
        let parentId = (await client.state).tasks.first!.id
        
        // Create first-level subtask
        try await client.process(.addSubtask(parentId: parentId, title: "Level 1"))
        let level1Id = (await client.state).tasks.first!.subtasks.first!.id
        
        // Create second-level subtask
        try await client.process(.addSubtask(parentId: level1Id, title: "Level 2"))
        
        let state = await client.state
        let rootTask = state.tasks.first!
        let level1Task = rootTask.subtasks.first!
        let level2Task = level1Task.subtasks.first!
        
        XCTAssertEqual(level2Task.title, "Level 2")
        XCTAssertEqual(level2Task.parentId, level1Id)
    }
    
    func testSubtaskDeletion() async throws {
        // FRAMEWORK INSIGHT: Testing recursive state removal
        let client = TaskClient()
        
        // Setup task with subtasks
        try await client.process(.addTask(title: "Parent", description: nil))
        let parentId = (await client.state).tasks.first!.id
        
        try await client.process(.addSubtask(parentId: parentId, title: "Subtask 1"))
        try await client.process(.addSubtask(parentId: parentId, title: "Subtask 2"))
        
        let subtaskId = (await client.state).tasks.first!.subtasks.first!.id
        
        // Delete subtask
        try await client.process(.deleteSubtask(id: subtaskId))
        
        let state = await client.state
        let parent = state.tasks.first!
        
        XCTAssertEqual(parent.subtasks.count, 1)
        XCTAssertEqual(parent.subtasks.first?.title, "Subtask 2")
    }
    
    func testSubtaskCompletionPropagation() async throws {
        // FRAMEWORK INSIGHT: Testing state propagation up hierarchy
        let client = TaskClient()
        
        // Setup parent with multiple subtasks
        try await client.process(.addTask(title: "Parent", description: nil))
        let parentId = (await client.state).tasks.first!.id
        
        try await client.process(.addSubtask(parentId: parentId, title: "Subtask 1"))
        try await client.process(.addSubtask(parentId: parentId, title: "Subtask 2"))
        
        let subtasks = (await client.state).tasks.first!.subtasks
        let subtask1Id = subtasks[0].id
        let subtask2Id = subtasks[1].id
        
        // Complete first subtask
        try await client.process(.toggleSubtaskCompletion(id: subtask1Id))
        
        var state = await client.state
        var parent = state.tasks.first!
        
        // Parent should not be complete yet
        XCTAssertFalse(parent.isCompleted)
        XCTAssertEqual(parent.completionPercentage, 50.0)
        
        // Complete second subtask
        try await client.process(.toggleSubtaskCompletion(id: subtask2Id))
        
        state = await client.state
        parent = state.tasks.first!
        
        // Parent should now be complete
        XCTAssertTrue(parent.isCompleted)
        XCTAssertEqual(parent.completionPercentage, 100.0)
    }
    
    // MARK: - RED Phase Tests - Dependencies
    
    func testTaskDependencyCreation() async throws {
        // FRAMEWORK INSIGHT: Testing relationship state management
        let client = TaskClient()
        
        // Create two tasks
        try await client.process(.addTask(title: "Task A", description: nil))
        try await client.process(.addTask(title: "Task B", description: nil))
        
        let state = await client.state
        let taskA = state.tasks[0]
        let taskB = state.tasks[1]
        
        // Create dependency: Task B depends on Task A
        try await client.process(.addDependency(
            dependentTaskId: taskB.id,
            prerequisiteTaskId: taskA.id
        ))
        
        let updatedState = await client.state
        let updatedTaskB = updatedState.tasks.first { $0.id == taskB.id }!
        
        XCTAssertTrue(updatedTaskB.dependencies.contains(taskA.id))
    }
    
    func testCircularDependencyDetection() async throws {
        // FRAMEWORK INSIGHT: Testing validation logic performance
        let client = TaskClient()
        
        // Create three tasks
        try await client.process(.addTask(title: "Task A", description: nil))
        try await client.process(.addTask(title: "Task B", description: nil))
        try await client.process(.addTask(title: "Task C", description: nil))
        
        let state = await client.state
        let taskA = state.tasks[0]
        let taskB = state.tasks[1]
        let taskC = state.tasks[2]
        
        // Create chain: A -> B -> C
        try await client.process(.addDependency(
            dependentTaskId: taskB.id,
            prerequisiteTaskId: taskA.id
        ))
        try await client.process(.addDependency(
            dependentTaskId: taskC.id,
            prerequisiteTaskId: taskB.id
        ))
        
        // Attempt to create circular dependency: C -> A
        do {
            try await client.process(.addDependency(
                dependentTaskId: taskA.id,
                prerequisiteTaskId: taskC.id
            ))
            XCTFail("Should have detected circular dependency")
        } catch TaskError.circularDependencyDetected(let cycle) {
            XCTAssertTrue(cycle.contains(taskA.id))
            XCTAssertTrue(cycle.contains(taskB.id))
            XCTAssertTrue(cycle.contains(taskC.id))
        }
    }
    
    func testCircularDependencyPerformance() async throws {
        // FRAMEWORK INSIGHT: Testing validation performance with large graphs
        let client = TaskClient()
        let taskCount = 100
        
        // Create large number of tasks
        for i in 0..<taskCount {
            try await client.process(.addTask(title: "Task \(i)", description: nil))
        }
        
        let state = await client.state
        let tasks = state.tasks
        
        // Create linear dependency chain
        for i in 1..<taskCount {
            try await client.process(.addDependency(
                dependentTaskId: tasks[i].id,
                prerequisiteTaskId: tasks[i-1].id
            ))
        }
        
        // Measure circular dependency detection time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            // Attempt to create circular dependency
            try await client.process(.addDependency(
                dependentTaskId: tasks[0].id,
                prerequisiteTaskId: tasks[taskCount-1].id
            ))
            XCTFail("Should have detected circular dependency")
        } catch TaskError.circularDependencyDetected {
            // Expected
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let detectionTime = endTime - startTime
        
        // Requirement: < 10ms for circular detection
        XCTAssertLessThan(detectionTime, 0.01, "Circular dependency detection took \(detectionTime * 1000)ms")
    }
    
    func testDependencyBlockingCompletion() async throws {
        // FRAMEWORK INSIGHT: Testing business logic with state validation
        let client = TaskClient()
        
        // Create two tasks with dependency
        try await client.process(.addTask(title: "Task A", description: nil))
        try await client.process(.addTask(title: "Task B", description: nil))
        
        let state = await client.state
        let taskA = state.tasks[0]
        let taskB = state.tasks[1]
        
        // B depends on A
        try await client.process(.addDependency(
            dependentTaskId: taskB.id,
            prerequisiteTaskId: taskA.id
        ))
        
        // Attempt to complete Task B without completing A
        do {
            try await client.process(.toggleTaskCompletion(id: taskB.id))
            XCTFail("Should not allow completion with incomplete dependencies")
        } catch TaskError.incompletePrerequisites(let prerequisites) {
            XCTAssertTrue(prerequisites.contains(taskA.id))
        }
        
        // Complete Task A first
        try await client.process(.toggleTaskCompletion(id: taskA.id))
        
        // Now Task B should be completable
        try await client.process(.toggleTaskCompletion(id: taskB.id))
        
        let finalState = await client.state
        let finalTaskB = finalState.tasks.first { $0.id == taskB.id }!
        XCTAssertTrue(finalTaskB.isCompleted)
    }
    
    // MARK: - RED Phase Tests - Deep Hierarchy Performance
    
    func testDeepHierarchyPerformance() async throws {
        // FRAMEWORK INSIGHT: Testing framework with nested state depth
        let client = TaskClient()
        let depth = 50
        
        // Create deep hierarchy
        try await client.process(.addTask(title: "Root", description: nil))
        var currentParentId = (await client.state).tasks.first!.id
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for level in 1...depth {
            try await client.process(.addSubtask(
                parentId: currentParentId,
                title: "Level \(level)"
            ))
            
            // Get the newly created subtask ID for next iteration
            let state = await client.state
            currentParentId = findSubtaskByTitle(in: state.tasks.first!, title: "Level \(level)")!.id
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let creationTime = endTime - startTime
        
        // Performance requirement: O(n) for n subtasks
        XCTAssertLessThan(creationTime, 1.0, "Deep hierarchy creation took \(creationTime)s")
        
        // Test update performance
        let updateStartTime = CFAbsoluteTimeGetCurrent()
        
        try await client.process(.toggleTaskCompletion(id: currentParentId))
        
        let updateEndTime = CFAbsoluteTimeGetCurrent()
        let updateTime = updateEndTime - updateStartTime
        
        // Update should be fast even for deep hierarchies
        XCTAssertLessThan(updateTime, 0.1, "Deep hierarchy update took \(updateTime)s")
    }
    
    func testLargeSubtaskSetPerformance() async throws {
        // FRAMEWORK INSIGHT: Testing breadth performance with many siblings
        let client = TaskClient()
        let subtaskCount = 1000
        
        // Create parent task
        try await client.process(.addTask(title: "Parent with many subtasks", description: nil))
        let parentId = (await client.state).tasks.first!.id
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create many subtasks
        for i in 0..<subtaskCount {
            try await client.process(.addSubtask(
                parentId: parentId,
                title: "Subtask \(i)"
            ))
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let creationTime = endTime - startTime
        
        // Should handle large sets efficiently
        XCTAssertLessThan(creationTime, 2.0, "Large subtask set creation took \(creationTime)s")
        
        // Test completion percentage calculation performance
        let calcStartTime = CFAbsoluteTimeGetCurrent()
        
        let state = await client.state
        let parent = state.tasks.first!
        let percentage = parent.completionPercentage
        
        let calcEndTime = CFAbsoluteTimeGetCurrent()
        let calcTime = calcEndTime - calcStartTime
        
        XCTAssertEqual(percentage, 0.0)
        XCTAssertLessThan(calcTime, 0.01, "Completion percentage calculation took \(calcTime)s")
    }
    
    func testComplexDependencyGraphPerformance() async throws {
        // FRAMEWORK INSIGHT: Testing complex relationship validation performance
        let client = TaskClient()
        let taskCount = 50
        
        // Create tasks
        for i in 0..<taskCount {
            try await client.process(.addTask(title: "Task \(i)", description: nil))
        }
        
        let state = await client.state
        let tasks = state.tasks
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create complex dependency graph (each task depends on previous 3)
        for i in 3..<taskCount {
            for j in max(0, i-3)..<i {
                try await client.process(.addDependency(
                    dependentTaskId: tasks[i].id,
                    prerequisiteTaskId: tasks[j].id
                ))
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let graphTime = endTime - startTime
        
        XCTAssertLessThan(graphTime, 1.0, "Complex dependency graph creation took \(graphTime)s")
    }
    
    // MARK: - Helper Methods
    
    private func findSubtaskByTitle(in task: TaskItem, title: String) -> TaskItem? {
        if let subtask = task.subtasks.first(where: { $0.title == title }) {
            return subtask
        }
        
        for subtask in task.subtasks {
            if let found = findSubtaskByTitle(in: subtask, title: title) {
                return found
            }
        }
        
        return nil
    }
}

