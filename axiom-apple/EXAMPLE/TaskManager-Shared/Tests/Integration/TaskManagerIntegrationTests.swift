import XCTest
@testable import TaskManager_Shared
import Axiom

// MARK: - Task Manager Integration Tests

/// Comprehensive integration tests for the TaskManager shared components
/// These tests validate the complete flow from UI actions through the client to storage
@MainActor
final class TaskManagerIntegrationTests: XCTestCase {
    
    private var taskClient: TaskClient!
    private var storageCapability: MockTaskStorageCapability!
    
    override func setUp() async throws {
        try await super.setUp()
        
        storageCapability = MockTaskStorageCapability()
        taskClient = TaskClient(storage: storageCapability)
        
        // Activate storage
        try await storageCapability.activate()
    }
    
    override func tearDown() async throws {
        await storageCapability.deactivate()
        taskClient = nil
        storageCapability = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Complete Task Lifecycle Tests
    
    func testCompleteTaskLifecycle() async throws {
        // Test the complete lifecycle: create -> update -> complete -> delete
        
        // 1. Initial state should be empty
        let initialState = await taskClient.getCurrentState()
        XCTAssertEqual(initialState.tasks.count, 0, "Initial state should have no tasks")
        
        // 2. Create a task
        let createData = CreateTaskData(
            title: "Integration Test Task",
            taskDescription: "This is a test task for integration testing",
            priority: .high,
            category: .work,
            dueDate: Date().addingTimeInterval(86400) // Tomorrow
        )
        
        try await taskClient.process(.createTask(createData))
        
        let stateAfterCreate = await taskClient.getCurrentState()
        XCTAssertEqual(stateAfterCreate.tasks.count, 1, "Should have one task after creation")
        
        let createdTask = stateAfterCreate.tasks.first!
        XCTAssertEqual(createdTask.title, "Integration Test Task")
        XCTAssertEqual(createdTask.priority, .high)
        XCTAssertEqual(createdTask.category, .work)
        XCTAssertFalse(createdTask.isCompleted)
        
        // 3. Update the task
        try await taskClient.process(.updateTask(
            taskId: createdTask.id,
            title: "Updated Integration Test Task",
            description: "Updated description",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: "Added some notes"
        ))
        
        let stateAfterUpdate = await taskClient.getCurrentState()
        let updatedTask = stateAfterUpdate.task(withId: createdTask.id)!
        XCTAssertEqual(updatedTask.title, "Updated Integration Test Task")
        XCTAssertEqual(updatedTask.priority, .medium)
        XCTAssertEqual(updatedTask.category, .personal)
        XCTAssertNil(updatedTask.dueDate)
        XCTAssertEqual(updatedTask.notes, "Added some notes")
        
        // 4. Complete the task
        try await taskClient.process(.toggleTaskCompletion(taskId: createdTask.id))
        
        let stateAfterComplete = await taskClient.getCurrentState()
        let completedTask = stateAfterComplete.task(withId: createdTask.id)!
        XCTAssertTrue(completedTask.isCompleted)
        XCTAssertNotNil(completedTask.completedAt)
        
        // 5. Verify statistics
        let statistics = stateAfterComplete.statistics
        XCTAssertEqual(statistics.totalTasks, 1)
        XCTAssertEqual(statistics.completedTasks, 1)
        XCTAssertEqual(statistics.pendingTasks, 0)
        XCTAssertEqual(statistics.completionPercentage, 1.0, accuracy: 0.001)
        
        // 6. Delete the task
        try await taskClient.process(.deleteTask(taskId: createdTask.id))
        
        let finalState = await taskClient.getCurrentState()
        XCTAssertEqual(finalState.tasks.count, 0, "Should have no tasks after deletion")
    }
    
    func testMultipleTasksWithFiltering() async throws {
        // Test creating multiple tasks and filtering functionality
        
        let tasks = [
            CreateTaskData(title: "Work Task 1", taskDescription: "", priority: .high, category: .work, dueDate: nil),
            CreateTaskData(title: "Personal Task 1", taskDescription: "", priority: .medium, category: .personal, dueDate: nil),
            CreateTaskData(title: "Work Task 2", taskDescription: "", priority: .low, category: .work, dueDate: Date().addingTimeInterval(-86400)), // Yesterday (overdue)
            CreateTaskData(title: "Shopping Task", taskDescription: "", priority: .medium, category: .shopping, dueDate: Date().addingTimeInterval(86400)), // Tomorrow
        ]
        
        // Create all tasks
        for taskData in tasks {
            try await taskClient.process(.createTask(taskData))
        }
        
        let allTasksState = await taskClient.getCurrentState()
        XCTAssertEqual(allTasksState.tasks.count, 4, "Should have 4 tasks")
        
        // Test category filtering
        try await taskClient.process(.setCategoryFilter(.work))
        let workFilterState = await taskClient.getCurrentState()
        let workTasks = workFilterState.filteredAndSortedTasks
        XCTAssertEqual(workTasks.count, 2, "Should have 2 work tasks")
        XCTAssertTrue(workTasks.allSatisfy { $0.category == .work })
        
        // Test priority filtering by setting a different filter
        try await taskClient.process(.setFilter(.completed))
        try await taskClient.process(.setCategoryFilter(nil))
        let completedFilterState = await taskClient.getCurrentState()
        XCTAssertEqual(completedFilterState.filteredAndSortedTasks.count, 0, "Should have no completed tasks")
        
        // Complete one task and test completed filter
        let taskToComplete = allTasksState.tasks.first!
        try await taskClient.process(.toggleTaskCompletion(taskId: taskToComplete.id))
        
        let afterCompletionState = await taskClient.getCurrentState()
        let completedTasks = afterCompletionState.filteredAndSortedTasks
        XCTAssertEqual(completedTasks.count, 1, "Should have one completed task")
        XCTAssertTrue(completedTasks.first!.isCompleted)
        
        // Test overdue filter
        try await taskClient.process(.setFilter(.overdue))
        let overdueState = await taskClient.getCurrentState()
        let overdueTasks = overdueState.filteredAndSortedTasks
        XCTAssertEqual(overdueTasks.count, 1, "Should have one overdue task")
        XCTAssertTrue(overdueTasks.first!.isOverdue)
    }
    
    func testSearchFunctionality() async throws {
        // Test search across task titles and descriptions
        
        let searchTasks = [
            CreateTaskData(title: "Important Meeting", taskDescription: "Discuss project roadmap", priority: .high, category: .work, dueDate: nil),
            CreateTaskData(title: "Buy Groceries", taskDescription: "Important items for dinner", priority: .medium, category: .shopping, dueDate: nil),
            CreateTaskData(title: "Doctor Appointment", taskDescription: "Annual checkup", priority: .medium, category: .health, dueDate: nil),
            CreateTaskData(title: "Project Review", taskDescription: "Review the important milestones", priority: .low, category: .work, dueDate: nil),
        ]
        
        for taskData in searchTasks {
            try await taskClient.process(.createTask(taskData))
        }
        
        // Search by title
        try await taskClient.process(.setSearchQuery("Meeting"))
        let meetingSearchState = await taskClient.getCurrentState()
        let meetingResults = meetingSearchState.filteredAndSortedTasks
        XCTAssertEqual(meetingResults.count, 1, "Should find one task with 'Meeting' in title")
        XCTAssertEqual(meetingResults.first!.title, "Important Meeting")
        
        // Search by description
        try await taskClient.process(.setSearchQuery("important"))
        let importantSearchState = await taskClient.getCurrentState()
        let importantResults = importantSearchState.filteredAndSortedTasks
        XCTAssertEqual(importantResults.count, 3, "Should find 3 tasks with 'important' in title or description")
        
        // Search with no results
        try await taskClient.process(.setSearchQuery("nonexistent"))
        let noResultsState = await taskClient.getCurrentState()
        XCTAssertEqual(noResultsState.filteredAndSortedTasks.count, 0, "Should find no tasks")
        
        // Clear search
        try await taskClient.process(.setSearchQuery(""))
        let clearedSearchState = await taskClient.getCurrentState()
        XCTAssertEqual(clearedSearchState.filteredAndSortedTasks.count, 4, "Should show all tasks when search is cleared")
    }
    
    func testSortingFunctionality() async throws {
        // Test different sorting options
        
        let now = Date()
        let sortingTasks = [
            CreateTaskData(title: "Z Task", taskDescription: "", priority: .low, category: .work, dueDate: now.addingTimeInterval(86400 * 3)), // 3 days
            CreateTaskData(title: "A Task", taskDescription: "", priority: .high, category: .personal, dueDate: now.addingTimeInterval(86400)), // 1 day
            CreateTaskData(title: "M Task", taskDescription: "", priority: .medium, category: .shopping, dueDate: now.addingTimeInterval(86400 * 2)), // 2 days
        ]
        
        for taskData in sortingTasks {
            try await taskClient.process(.createTask(taskData))
            // Add small delay to ensure different creation times
            try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        }
        
        // Test sorting by title (ascending)
        try await taskClient.process(.setSortOrder(.title, ascending: true))
        let titleAscState = await taskClient.getCurrentState()
        let titleAscTasks = titleAscState.filteredAndSortedTasks
        XCTAssertEqual(titleAscTasks[0].title, "A Task")
        XCTAssertEqual(titleAscTasks[1].title, "M Task")
        XCTAssertEqual(titleAscTasks[2].title, "Z Task")
        
        // Test sorting by title (descending)
        try await taskClient.process(.setSortOrder(.title, ascending: false))
        let titleDescState = await taskClient.getCurrentState()
        let titleDescTasks = titleDescState.filteredAndSortedTasks
        XCTAssertEqual(titleDescTasks[0].title, "Z Task")
        XCTAssertEqual(titleDescTasks[1].title, "M Task")
        XCTAssertEqual(titleDescTasks[2].title, "A Task")
        
        // Test sorting by priority (high to low)
        try await taskClient.process(.setSortOrder(.priority, ascending: false))
        let priorityDescState = await taskClient.getCurrentState()
        let priorityDescTasks = priorityDescState.filteredAndSortedTasks
        XCTAssertEqual(priorityDescTasks[0].priority, .high)
        XCTAssertEqual(priorityDescTasks[1].priority, .medium)
        XCTAssertEqual(priorityDescTasks[2].priority, .low)
        
        // Test sorting by due date (earliest first)
        try await taskClient.process(.setSortOrder(.dueDate, ascending: true))
        let dueDateAscState = await taskClient.getCurrentState()
        let dueDateAscTasks = dueDateAscState.filteredAndSortedTasks
        XCTAssertEqual(dueDateAscTasks[0].title, "A Task") // 1 day
        XCTAssertEqual(dueDateAscTasks[1].title, "M Task") // 2 days
        XCTAssertEqual(dueDateAscTasks[2].title, "Z Task") // 3 days
    }
    
    func testBulkOperations() async throws {
        // Test bulk operations on multiple tasks
        
        let bulkTasks = [
            CreateTaskData(title: "Bulk Task 1", taskDescription: "", priority: .high, category: .work, dueDate: nil),
            CreateTaskData(title: "Bulk Task 2", taskDescription: "", priority: .medium, category: .work, dueDate: nil),
            CreateTaskData(title: "Bulk Task 3", taskDescription: "", priority: .low, category: .personal, dueDate: nil),
        ]
        
        for taskData in bulkTasks {
            try await taskClient.process(.createTask(taskData))
        }
        
        let initialState = await taskClient.getCurrentState()
        let taskIds = initialState.tasks.map { $0.id }
        
        // Test bulk completion
        try await taskClient.process(.markTasksAsCompleted(taskIds: Array(taskIds[0...1]))) // Complete first two
        
        let afterBulkCompleteState = await taskClient.getCurrentState()
        let completedCount = afterBulkCompleteState.tasks.filter { $0.isCompleted }.count
        XCTAssertEqual(completedCount, 2, "Should have 2 completed tasks")
        
        // Test bulk category update
        try await taskClient.process(.updateTasksCategory(taskIds: Array(taskIds[0...1]), category: .shopping))
        
        let afterCategoryUpdateState = await taskClient.getCurrentState()
        let shoppingTasks = afterCategoryUpdateState.tasks.filter { $0.category == .shopping }
        XCTAssertEqual(shoppingTasks.count, 2, "Should have 2 shopping tasks")
        
        // Test bulk priority update
        try await taskClient.process(.updateTasksPriority(taskIds: taskIds, priority: .high))
        
        let afterPriorityUpdateState = await taskClient.getCurrentState()
        let highPriorityTasks = afterPriorityUpdateState.tasks.filter { $0.priority == .high }
        XCTAssertEqual(highPriorityTasks.count, 3, "Should have 3 high priority tasks")
        
        // Test bulk deletion
        try await taskClient.process(.deleteTasks(taskIds: Array(taskIds[0...1])))
        
        let afterBulkDeleteState = await taskClient.getCurrentState()
        XCTAssertEqual(afterBulkDeleteState.tasks.count, 1, "Should have 1 task remaining")
    }
    
    func testTaskDuplication() async throws {
        // Test task duplication functionality
        
        let originalTaskData = CreateTaskData(
            title: "Original Task",
            taskDescription: "This is the original task",
            priority: .high,
            category: .work,
            dueDate: Date().addingTimeInterval(86400),
            notes: "Original notes"
        )
        
        try await taskClient.process(.createTask(originalTaskData))
        
        let afterCreateState = await taskClient.getCurrentState()
        let originalTask = afterCreateState.tasks.first!
        
        // Duplicate the task
        try await taskClient.process(.duplicateTask(taskId: originalTask.id))
        
        let afterDuplicateState = await taskClient.getCurrentState()
        XCTAssertEqual(afterDuplicateState.tasks.count, 2, "Should have 2 tasks after duplication")
        
        let duplicatedTask = afterDuplicateState.tasks.first { $0.id != originalTask.id }!
        
        // Verify duplicated task has same content but different ID
        XCTAssertNotEqual(duplicatedTask.id, originalTask.id)
        XCTAssertEqual(duplicatedTask.title, originalTask.title)
        XCTAssertEqual(duplicatedTask.taskDescription, originalTask.taskDescription)
        XCTAssertEqual(duplicatedTask.priority, originalTask.priority)
        XCTAssertEqual(duplicatedTask.category, originalTask.category)
        XCTAssertEqual(duplicatedTask.notes, originalTask.notes)
        XCTAssertFalse(duplicatedTask.isCompleted) // Should always be incomplete
        XCTAssertNotEqual(duplicatedTask.createdAt, originalTask.createdAt)
    }
    
    func testStatisticsAccuracy() async throws {
        // Test that statistics are calculated correctly
        
        let now = Date()
        let testTasks = [
            CreateTaskData(title: "Completed Work", taskDescription: "", priority: .high, category: .work, dueDate: nil),
            CreateTaskData(title: "Pending Personal", taskDescription: "", priority: .medium, category: .personal, dueDate: now.addingTimeInterval(86400)),
            CreateTaskData(title: "Overdue Shopping", taskDescription: "", priority: .low, category: .shopping, dueDate: now.addingTimeInterval(-86400)),
            CreateTaskData(title: "Due Today", taskDescription: "", priority: .high, category: .work, dueDate: now),
        ]
        
        var createdTaskIds: [UUID] = []
        for taskData in testTasks {
            try await taskClient.process(.createTask(taskData))
            let state = await taskClient.getCurrentState()
            createdTaskIds.append(state.tasks.last!.id)
        }
        
        // Complete the first task
        try await taskClient.process(.toggleTaskCompletion(taskId: createdTaskIds[0]))
        
        let finalState = await taskClient.getCurrentState()
        let stats = finalState.statistics
        
        XCTAssertEqual(stats.totalTasks, 4)
        XCTAssertEqual(stats.completedTasks, 1)
        XCTAssertEqual(stats.pendingTasks, 3)
        XCTAssertEqual(stats.overdueTasks, 1) // One overdue task
        XCTAssertEqual(stats.dueTodayTasks, 1) // One due today
        XCTAssertEqual(stats.completionPercentage, 0.25, accuracy: 0.001)
        
        // Verify category breakdown
        XCTAssertEqual(stats.tasksByCategory[.work], 2)
        XCTAssertEqual(stats.tasksByCategory[.personal], 1)
        XCTAssertEqual(stats.tasksByCategory[.shopping], 1)
        
        // Verify priority breakdown
        XCTAssertEqual(stats.tasksByPriority[.high], 2)
        XCTAssertEqual(stats.tasksByPriority[.medium], 1)
        XCTAssertEqual(stats.tasksByPriority[.low], 1)
    }
    
    func testStoragePersistence() async throws {
        // Test that tasks are properly saved and loaded from storage
        
        let persistenceTask = CreateTaskData(
            title: "Persistence Test",
            taskDescription: "Testing storage persistence",
            priority: .medium,
            category: .work,
            dueDate: nil
        )
        
        try await taskClient.process(.createTask(persistenceTask))
        
        let beforeState = await taskClient.getCurrentState()
        XCTAssertEqual(beforeState.tasks.count, 1)
        
        // Verify save was called
        XCTAssertTrue(storageCapability.saveTasksCalled, "Save should have been called")
        XCTAssertEqual(storageCapability.lastSavedTasks?.count, 1)
        
        // Create a new client with the same storage to simulate app restart
        let newClient = TaskClient(storage: storageCapability)
        try await newClient.process(.loadTasks)
        
        let afterLoadState = await newClient.getCurrentState()
        XCTAssertEqual(afterLoadState.tasks.count, 1, "Should load saved tasks")
        
        let loadedTask = afterLoadState.tasks.first!
        XCTAssertEqual(loadedTask.title, "Persistence Test")
        XCTAssertEqual(loadedTask.taskDescription, "Testing storage persistence")
        XCTAssertEqual(loadedTask.priority, .medium)
        XCTAssertEqual(loadedTask.category, .work)
    }
    
    func testErrorHandling() async throws {
        // Test error handling for various scenarios
        
        // Test updating non-existent task
        let nonExistentId = UUID()
        
        do {
            try await taskClient.process(.updateTask(
                taskId: nonExistentId,
                title: "Updated",
                description: "",
                priority: .medium,
                category: .personal,
                dueDate: nil,
                notes: ""
            ))
            XCTFail("Should throw error for non-existent task")
        } catch {
            // Expected error
        }
        
        // Test deleting non-existent task
        do {
            try await taskClient.process(.deleteTask(taskId: nonExistentId))
            XCTFail("Should throw error for non-existent task")
        } catch {
            // Expected error
        }
        
        // Test completing non-existent task
        do {
            try await taskClient.process(.toggleTaskCompletion(taskId: nonExistentId))
            XCTFail("Should throw error for non-existent task")
        } catch {
            // Expected error
        }
        
        // Test storage failure scenario
        storageCapability.shouldFailSave = true
        
        do {
            try await taskClient.process(.createTask(CreateTaskData(
                title: "Should Fail",
                taskDescription: "",
                priority: .medium,
                category: .personal,
                dueDate: nil
            )))
            XCTFail("Should throw error when storage fails")
        } catch {
            // Expected error
        }
    }
    
    func testConcurrentOperations() async throws {
        // Test concurrent operations to ensure thread safety
        
        let concurrentTasks = (0..<10).map { index in
            CreateTaskData(
                title: "Concurrent Task \(index)",
                taskDescription: "Task created concurrently",
                priority: Priority.allCases[index % 3],
                category: Category.allCases[index % Category.allCases.count],
                dueDate: nil
            )
        }
        
        // Create tasks concurrently
        await withTaskGroup(of: Void.self) { group in
            for taskData in concurrentTasks {
                group.addTask {
                    do {
                        try await self.taskClient.process(.createTask(taskData))
                    } catch {
                        XCTFail("Concurrent task creation failed: \(error)")
                    }
                }
            }
        }
        
        let finalState = await taskClient.getCurrentState()
        XCTAssertEqual(finalState.tasks.count, 10, "All concurrent tasks should be created")
        
        // Verify all tasks have unique IDs
        let uniqueIds = Set(finalState.tasks.map { $0.id })
        XCTAssertEqual(uniqueIds.count, 10, "All tasks should have unique IDs")
    }
}

// MARK: - Mock Storage Capability

/// Mock storage capability for testing
private actor MockTaskStorageCapability: TaskStorageCapability {
    
    var isActive: Bool = false
    var isAvailable: Bool = true
    var saveTasksCalled = false
    var lastSavedTasks: [Task]?
    var shouldFailSave = false
    var shouldFailLoad = false
    
    private var storedTasks: [Task] = []
    
    func activate() async throws {
        isActive = true
    }
    
    func deactivate() async {
        isActive = false
    }
    
    func loadTasks() async throws -> [Task] {
        if shouldFailLoad {
            throw TaskStorageError.loadFailed("Mock load failure")
        }
        return storedTasks
    }
    
    func saveTasks(_ tasks: [Task]) async throws {
        if shouldFailSave {
            throw TaskStorageError.saveFailed("Mock save failure")
        }
        
        saveTasksCalled = true
        lastSavedTasks = tasks
        storedTasks = tasks
    }
    
    func getStorageInfo() async throws -> StorageInfo {
        return StorageInfo(
            isAvailable: isAvailable,
            sizeInBytes: Int64(storedTasks.count * 1024), // Mock size
            lastModified: Date()
        )
    }
    
    func createBackup() async throws {
        // Mock backup creation
    }
}

// MARK: - Task Storage Error

enum TaskStorageError: Error {
    case loadFailed(String)
    case saveFailed(String)
}