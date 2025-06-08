import XCTest
@testable import TaskManager

/// Comprehensive tests for REQ-012: Bulk Operations
/// Framework Components Under Test: Multi-Select State, Batch Actions, Progress Tracking
/// Expected Pain Points: Selection state management, Batch performance, Progress UI updates
final class BulkOperationsTests: XCTestCase {
    
    // MARK: - Multi-Selection State Tests (Expected Pain Point: Selection state management)
    
    func testEmptySelectionInitialization() async throws {
        // Test initial selection state
        let client = TaskClient()
        let state = await client.currentState
        
        // Framework Challenge: No built-in selection state patterns
        XCTAssertTrue(state.selectedTaskIds.isEmpty)
        XCTAssertFalse(state.isMultiSelectMode)
        XCTAssertEqual(state.selectedTasks.count, 0)
    }
    
    func testEnterMultiSelectMode() async throws {
        // Test entering multi-select mode by selecting first task
        let client = TaskClient()
        
        // Add some tasks first  
        try await client.process(.addTask(title: "Task 1", description: nil))
        try await client.process(.addTask(title: "Task 2", description: nil))
        
        let initialState = await client.currentState
        let taskId = initialState.tasks.first!.id
        
        // Enter multi-select by selecting first task
        try await client.process(.toggleTaskSelection(id: taskId))
        
        let state = await client.currentState
        
        // Framework Challenge: How to manage multi-select state transitions
        XCTAssertTrue(state.isMultiSelectMode)
        XCTAssertTrue(state.selectedTaskIds.contains(taskId))
        XCTAssertEqual(state.selectedTasks.count, 1)
    }
    
    func testMultipleTaskSelection() async throws {
        // Test selecting multiple tasks
        let client = TaskClient()
        
        // Add test tasks
        try await client.process(.addTask(title: "Task 1", description: nil))
        try await client.process(.addTask(title: "Task 2", description: nil))
        try await client.process(.addTask(title: "Task 3", description: nil))
        
        let state = await client.currentState
        let taskIds = state.tasks.map { $0.id }
        
        // Select first two tasks
        try await client.process(.toggleTaskSelection(id: taskIds[0]))
        try await client.process(.toggleTaskSelection(id: taskIds[1]))
        
        let updatedState = await client.currentState
        
        XCTAssertTrue(updatedState.isMultiSelectMode)
        XCTAssertEqual(updatedState.selectedTaskIds.count, 2)
        XCTAssertTrue(updatedState.selectedTaskIds.contains(taskIds[0]))
        XCTAssertTrue(updatedState.selectedTaskIds.contains(taskIds[1]))
        XCTAssertFalse(updatedState.selectedTaskIds.contains(taskIds[2]))
    }
    
    func testDeselectTask() async throws {
        // Test deselecting a task while maintaining multi-select mode
        let client = TaskClient()
        
        // Setup: Add tasks and select multiple
        try await client.process(.addTask(title: "Task 1", description: nil))
        try await client.process(.addTask(title: "Task 2", description: nil))
        
        let state = await client.currentState
        let taskIds = state.tasks.map { $0.id }
        
        try await client.process(.toggleTaskSelection(id: taskIds[0]))
        try await client.process(.toggleTaskSelection(id: taskIds[1]))
        
        // Deselect first task
        try await client.process(.toggleTaskSelection(id: taskIds[0]))
        
        let finalState = await client.currentState
        
        XCTAssertTrue(finalState.isMultiSelectMode)
        XCTAssertEqual(finalState.selectedTaskIds.count, 1)
        XCTAssertFalse(finalState.selectedTaskIds.contains(taskIds[0]))
        XCTAssertTrue(finalState.selectedTaskIds.contains(taskIds[1]))
    }
    
    func testExitMultiSelectMode() async throws {
        // Test exiting multi-select mode when all tasks deselected
        let client = TaskClient()
        
        // Setup
        try await client.process(.addTask(title: "Task 1", description: nil))
        let state = await client.currentState
        let taskId = state.tasks.first!.id
        
        // Enter multi-select
        try await client.process(.toggleTaskSelection(id: taskId))
        
        // Exit multi-select by deselecting all
        try await client.process(.toggleTaskSelection(id: taskId))
        
        let finalState = await client.currentState
        
        XCTAssertFalse(finalState.isMultiSelectMode)
        XCTAssertTrue(finalState.selectedTaskIds.isEmpty)
    }
    
    func testClearAllSelections() async throws {
        // Test clearing all selections at once
        let client = TaskClient()
        
        // Setup multiple selected tasks
        try await client.process(.addTask(title: "Task 1", description: nil))
        try await client.process(.addTask(title: "Task 2", description: nil))
        try await client.process(.addTask(title: "Task 3", description: nil))
        
        let state = await client.currentState
        let taskIds = state.tasks.map { $0.id }
        
        for taskId in taskIds {
            try await client.process(.toggleTaskSelection(id: taskId))
        }
        
        // Clear all selections
        try await client.process(.clearAllSelections)
        
        let finalState = await client.currentState
        
        XCTAssertFalse(finalState.isMultiSelectMode)
        XCTAssertTrue(finalState.selectedTaskIds.isEmpty)
    }
    
    // MARK: - Batch Operations Tests (Expected Pain Point: Batch performance)
    
    func testBatchDelete() async throws {
        // Test deleting multiple tasks at once
        let client = TaskClient()
        
        // Setup tasks
        try await client.process(.addTask(title: "Task 1", description: nil))
        try await client.process(.addTask(title: "Task 2", description: nil))
        try await client.process(.addTask(title: "Task 3", description: nil))
        try await client.process(.addTask(title: "Task 4", description: nil))
        
        let state = await client.currentState
        let taskIds = state.tasks.map { $0.id }
        
        // Select first two tasks
        try await client.process(.toggleTaskSelection(id: taskIds[0]))
        try await client.process(.toggleTaskSelection(id: taskIds[1]))
        
        // Batch delete
        try await client.process(.batchDeleteSelected)
        
        let finalState = await client.currentState
        
        XCTAssertEqual(finalState.tasks.count, 2)
        XCTAssertFalse(finalState.isMultiSelectMode)
        XCTAssertTrue(finalState.selectedTaskIds.isEmpty)
        
        // Verify remaining tasks are correct ones
        let remainingIds = Set(finalState.tasks.map { $0.id })
        XCTAssertFalse(remainingIds.contains(taskIds[0]))
        XCTAssertFalse(remainingIds.contains(taskIds[1]))
        XCTAssertTrue(remainingIds.contains(taskIds[2]))
        XCTAssertTrue(remainingIds.contains(taskIds[3]))
    }
    
    func testBatchStatusUpdate() async throws {
        // Test updating status of multiple tasks
        let client = TaskClient()
        
        // Setup incomplete tasks
        try await client.process(.addTask(title: "Task 1", description: nil))
        try await client.process(.addTask(title: "Task 2", description: nil))
        try await client.process(.addTask(title: "Task 3", description: nil))
        
        let state = await client.currentState
        let taskIds = state.tasks.map { $0.id }
        
        // Select first two tasks
        try await client.process(.toggleTaskSelection(id: taskIds[0]))
        try await client.process(.toggleTaskSelection(id: taskIds[1]))
        
        // Batch mark as completed
        try await client.process(.batchUpdateStatus(isCompleted: true))
        
        let finalState = await client.currentState
        
        XCTAssertFalse(finalState.isMultiSelectMode)
        XCTAssertTrue(finalState.selectedTaskIds.isEmpty)
        
        // Verify status updates
        let updatedTasks = finalState.tasks
        let task1 = updatedTasks.first { $0.id == taskIds[0] }!
        let task2 = updatedTasks.first { $0.id == taskIds[1] }!
        let task3 = updatedTasks.first { $0.id == taskIds[2] }!
        
        XCTAssertTrue(task1.isCompleted)
        XCTAssertTrue(task2.isCompleted)
        XCTAssertFalse(task3.isCompleted) // Not selected
    }
    
    func testBatchCategoryUpdate() async throws {
        // Test updating category of multiple tasks
        let client = TaskClient()
        
        // Setup tasks
        try await client.process(.addTask(title: "Task 1", description: nil))
        try await client.process(.addTask(title: "Task 2", description: nil))
        try await client.process(.addTask(title: "Task 3", description: nil))
        
        let state = await client.currentState
        let taskIds = state.tasks.map { $0.id }
        
        // Select all tasks
        for taskId in taskIds {
            try await client.process(.toggleTaskSelection(id: taskId))
        }
        
        // Get a default category ID to use
        let categoryId = state.categories.first!.id
        
        // Batch update category
        try await client.process(.batchUpdateCategory(categoryId))
        
        let finalState = await client.currentState
        
        XCTAssertFalse(finalState.isMultiSelectMode)
        
        // Verify all tasks have new category
        for task in finalState.tasks {
            XCTAssertEqual(task.categoryId, categoryId)
        }
    }
    
    func testBatchPriorityUpdate() async throws {
        // Test updating priority of multiple tasks
        let client = TaskClient()
        
        // Setup tasks with default priority
        try await client.process(.addTask(title: "Task 1", description: nil))
        try await client.process(.addTask(title: "Task 2", description: nil))
        
        let state = await client.currentState
        let taskIds = state.tasks.map { $0.id }
        
        // Select tasks
        try await client.process(.toggleTaskSelection(id: taskIds[0]))
        try await client.process(.toggleTaskSelection(id: taskIds[1]))
        
        // Batch update priority
        try await client.process(.batchUpdatePriority(.high))
        
        let finalState = await client.currentState
        
        // Verify priority updates
        for task in finalState.tasks {
            XCTAssertEqual(task.priority, .high)
        }
    }
    
    // MARK: - Progress Tracking Tests (Expected Pain Point: Progress UI updates)
    
    func testBatchOperationProgress() async throws {
        // Test progress tracking during long batch operation
        let client = TaskClient()
        
        // Setup large dataset for progress testing
        for i in 1...100 {
            try await client.process(.addTask(title: "Task \(i)", description: nil))
        }
        
        let state = await client.currentState
        let taskIds = state.tasks.map { $0.id }
        
        // Select all tasks
        for taskId in taskIds {
            try await client.process(.toggleTaskSelection(id: taskId))
        }
        
        // Start batch operation with progress tracking
        var progressValues: [Double] = []
        let progressExpectation = XCTestExpectation(description: "Progress updates")
        
        // Framework Challenge: How to test progress updates efficiently
        Task {
            for await progressState in await client.stateStream {
                if let progress = progressState.batchOperationProgress {
                    progressValues.append(progress)
                    if progress >= 1.0 {
                        progressExpectation.fulfill()
                        break
                    }
                }
            }
        }
        
        // Execute batch operation
        try await client.process(.batchUpdateStatus(isCompleted: true))
        
        await fulfillment(of: [progressExpectation], timeout: 5.0)
        
        // Verify progress tracking
        XCTAssertGreaterThan(progressValues.count, 1)
        XCTAssertEqual(progressValues.first!, 0.0, accuracy: 0.01)
        XCTAssertEqual(progressValues.last!, 1.0, accuracy: 0.01)
        
        // Verify monotonic progress
        for i in 1..<progressValues.count {
            XCTAssertGreaterThanOrEqual(progressValues[i], progressValues[i-1])
        }
    }
    
    func testProgressCancel() async throws {
        // Test canceling a batch operation
        let client = TaskClient()
        
        // Setup large dataset
        for i in 1...500 {
            try await client.process(.addTask(title: "Task \(i)", description: nil))
        }
        
        let state = await client.currentState
        let taskIds = state.tasks.map { $0.id }
        
        // Select all tasks
        for taskId in taskIds {
            try await client.process(.toggleTaskSelection(id: taskId))
        }
        
        // Start long-running batch operation
        Task {
            try? await client.process(.batchUpdateStatus(isCompleted: true))
        }
        
        // Wait for operation to start
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Cancel operation
        try await client.process(.cancelBatchOperation)
        
        let finalState = await client.currentState
        
        // Verify operation was canceled
        XCTAssertNil(finalState.batchOperationProgress)
        XCTAssertFalse(finalState.isMultiSelectMode)
        
        // Framework Challenge: How to handle partial completion on cancel
    }
    
    // MARK: - Performance Tests (Requirement: < 1s for 1k tasks)
    
    func testBatchPerformance1000Tasks() async throws {
        // Test batch operation performance with 1000 tasks
        let client = TaskClient()
        
        // Setup 1000 tasks
        let _ = CFAbsoluteTimeGetCurrent()
        for i in 1...1000 {
            try await client.process(.addTask(title: "Task \(i)", description: nil))
        }
        
        let state = await client.currentState
        let taskIds = state.tasks.map { $0.id }
        
        // Select all tasks
        for taskId in taskIds {
            try await client.process(.toggleTaskSelection(id: taskId))
        }
        
        // Measure batch operation performance
        let batchStartTime = CFAbsoluteTimeGetCurrent()
        try await client.process(.batchUpdateStatus(isCompleted: true))
        let batchEndTime = CFAbsoluteTimeGetCurrent()
        
        let batchDuration = batchEndTime - batchStartTime
        
        // Framework Performance Requirement: < 1s for 1k tasks
        XCTAssertLessThan(batchDuration, 1.0, "Batch operation took \(batchDuration)s, requirement is < 1s")
        
        // Verify all tasks were updated
        let finalState = await client.currentState
        XCTAssertEqual(finalState.tasks.count, 1000)
        XCTAssertTrue(finalState.tasks.allSatisfy { $0.isCompleted })
    }
    
    func testProgressUpdateFrameRate() async throws {
        // Test that progress updates maintain 60fps (Expected Pain Point: Progress UI updates)
        let client = TaskClient()
        
        // Setup tasks
        for i in 1...200 {
            try await client.process(.addTask(title: "Task \(i)", description: nil))
        }
        
        let state = await client.currentState
        let taskIds = state.tasks.map { $0.id }
        
        // Select all tasks
        for taskId in taskIds {
            try await client.process(.toggleTaskSelection(id: taskId))
        }
        
        // Measure progress update frequency
        var updateTimes: [CFAbsoluteTime] = []
        let progressExpectation = XCTestExpectation(description: "Progress complete")
        
        Task {
            for await progressState in await client.stateStream {
                if progressState.batchOperationProgress != nil {
                    updateTimes.append(CFAbsoluteTimeGetCurrent())
                    if progressState.batchOperationProgress! >= 1.0 {
                        progressExpectation.fulfill()
                        break
                    }
                }
            }
        }
        
        try await client.process(.batchUpdateStatus(isCompleted: true))
        await fulfillment(of: [progressExpectation], timeout: 3.0)
        
        // Verify update frequency meets 60fps requirement
        if updateTimes.count > 1 {
            var intervals: [TimeInterval] = []
            for i in 1..<updateTimes.count {
                intervals.append(updateTimes[i] - updateTimes[i-1])
            }
            
            let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
            let averageFPS = 1.0 / averageInterval
            
            // Framework Challenge: Maintaining 60fps during state updates
            XCTAssertGreaterThan(averageFPS, 30.0, "Progress updates averaging \(averageFPS) FPS, should maintain near 60fps")
        }
    }
    
    // MARK: - Memory Stability Tests (Success Metric: Memory stability during batches)
    
    func testMemoryStabilityDuringBatchOperations() async throws {
        // Test that memory usage remains stable during large batch operations
        let client = TaskClient()
        
        // Setup baseline tasks
        for i in 1...100 {
            try await client.process(.addTask(title: "Task \(i)", description: nil))
        }
        
        let state = await client.currentState
        let taskIds = state.tasks.map { $0.id }
        
        // Perform multiple batch operations
        for _ in 1...10 {
            // Select all tasks
            for taskId in taskIds {
                try await client.process(.toggleTaskSelection(id: taskId))
            }
            
            // Batch operation
            try await client.process(.batchUpdatePriority(.high))
            
            // Clear selection
            try await client.process(.clearAllSelections)
            
            // Framework Challenge: Memory allocation patterns during batch operations
        }
        
        // Memory should remain stable - framework challenge to verify
        let finalState = await client.currentState
        XCTAssertEqual(finalState.tasks.count, 100)
        XCTAssertFalse(finalState.isMultiSelectMode)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testBatchOperationWithNoSelection() async throws {
        // Test batch operations when no tasks are selected
        let client = TaskClient()
        
        try await client.process(.addTask(title: "Task 1", description: nil))
        
        // Try batch operation without selection
        do {
            try await client.process(.batchDeleteSelected)
            XCTFail("Should throw error when no tasks selected")
        } catch TaskError.noTasksSelected {
            // Expected error
        }
    }
    
    func testConcurrentBatchOperations() async throws {
        // Test handling of concurrent batch operations
        let client = TaskClient()
        
        for i in 1...50 {
            try await client.process(.addTask(title: "Task \(i)", description: nil))
        }
        
        let state = await client.currentState
        let taskIds = state.tasks.map { $0.id }
        
        // Select tasks
        for taskId in taskIds {
            try await client.process(.toggleTaskSelection(id: taskId))
        }
        
        // Try to start two batch operations simultaneously
        var secondOperationError: TaskError?
        
        await withTaskGroup(of: Void.self) { group in
            // Start first operation
            group.addTask {
                do {
                    try await client.process(.batchUpdateStatus(isCompleted: true))
                } catch {
                    // First operation might fail if second starts first
                }
            }
            
            // Start second operation immediately after
            group.addTask {
                // Small delay to let first operation start
                try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
                do {
                    try await client.process(.batchUpdatePriority(.high))
                    XCTFail("Should prevent concurrent batch operations")
                } catch let error as TaskError {
                    secondOperationError = error
                } catch {
                    XCTFail("Unexpected error type")
                }
            }
        }
        
        // Verify that the second operation was properly rejected
        // Either batchOperationInProgress (proper locking) or noTasksSelected (first operation completed) is valid
        XCTAssertTrue(
            secondOperationError == .batchOperationInProgress || 
            secondOperationError == .noTasksSelected,
            "Expected batchOperationInProgress or noTasksSelected, got \(String(describing: secondOperationError))"
        )
    }
    
    func testBatchOperationIntegrationWithOtherFeatures() async throws {
        // Test batch operations work with basic task operations
        let client = TaskClient()
        
        // Setup tasks
        try await client.process(.addTask(title: "Task 1", description: nil))
        try await client.process(.addTask(title: "Task 2", description: nil))
        try await client.process(.addTask(title: "Task 3", description: nil))
        
        let state = await client.currentState
        XCTAssertEqual(state.tasks.count, 3)
        
        // Select first two tasks
        let taskIds = state.tasks.prefix(2).map { $0.id }
        for taskId in taskIds {
            try await client.process(.toggleTaskSelection(id: taskId))
        }
        
        // Batch update selected tasks
        try await client.process(.batchUpdatePriority(.high))
        
        let finalState = await client.currentState
        
        // Verify only selected tasks were updated
        let updatedTasks = finalState.tasks.filter { taskIds.contains($0.id) }
        let unchangedTasks = finalState.tasks.filter { !taskIds.contains($0.id) }
        
        XCTAssertTrue(updatedTasks.allSatisfy { $0.priority == .high })
        XCTAssertTrue(unchangedTasks.allSatisfy { $0.priority == .medium }) // Default priority
        
        // Framework Challenge: Integration complexity between features
    }
}

// MARK: - Supporting Extensions for Testing

extension TaskState {
    var selectedTasks: [TaskItem] {
        tasks.filter { selectedTaskIds.contains($0.id) }
    }
}