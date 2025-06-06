import XCTest
@testable import TestApp002Core

final class CategoryManagementTests: XCTestCase {
    var client: TaskClient!
    
    override func setUp() async throws {
        try await super.setUp()
        let storageCapability = InMemoryStorageCapability()
        let networkCapability = MockNetworkCapability()
        let notificationCapability = MockNotificationCapability()
        
        client = TaskClient(
            userId: "test-user",
            storageCapability: storageCapability,
            networkCapability: networkCapability,
            notificationCapability: notificationCapability
        )
    }
    
    override func tearDown() async throws {
        client = nil
        try await super.tearDown()
    }
    
    // MARK: - Category CRUD Tests
    
    func testCreateCategory() async throws {
        // Given: A new category to create
        let category = Category(id: "1", name: "Personal", color: "#FF5733")
        
        // When: Creating the category
        try await client.process(.createCategory(category))
        
        // Then: Category should exist in state
        let state = await client.currentState
        XCTAssertEqual(state.categories.count, 1)
        XCTAssertEqual(state.categories.first?.id, "1")
        XCTAssertEqual(state.categories.first?.name, "Personal")
        XCTAssertEqual(state.categories.first?.color, "#FF5733")
    }
    
    func testUpdateCategory() async throws {
        // Given: An existing category
        let original = Category(id: "1", name: "Work", color: "#0000FF")
        try await client.process(.createCategory(original))
        
        // When: Updating the category
        let updated = Category(id: "1", name: "Office", color: "#0080FF")
        try await client.process(.updateCategory(updated))
        
        // Then: Category should be updated
        let state = await client.currentState
        XCTAssertEqual(state.categories.count, 1)
        XCTAssertEqual(state.categories.first?.name, "Office")
        XCTAssertEqual(state.categories.first?.color, "#0080FF")
    }
    
    func testDeleteCategory() async throws {
        // Given: Multiple categories
        let category1 = Category(id: "1", name: "Personal", color: "#FF5733")
        let category2 = Category(id: "2", name: "Work", color: "#0000FF")
        try await client.process(.createCategory(category1))
        try await client.process(.createCategory(category2))
        
        // When: Deleting a category
        try await client.process(.deleteCategory(categoryId: "1"))
        
        // Then: Only one category should remain
        let state = await client.currentState
        XCTAssertEqual(state.categories.count, 1)
        XCTAssertEqual(state.categories.first?.id, "2")
    }
    
    func testMaximumCategoriesLimit() async throws {
        // Given: Creating 20 categories (the maximum)
        for i in 1...20 {
            let category = Category(
                id: "\(i)",
                name: "Category \(i)",
                color: "#\(String(format: "%06X", i * 100000))"
            )
            try await client.process(.createCategory(category))
        }
        
        // When: Attempting to create 21st category
        let extraCategory = Category(id: "21", name: "Extra", color: "#FFFFFF")
        
        // Then: Should throw an error
        do {
            try await client.process(.createCategory(extraCategory))
            XCTFail("Expected error when exceeding category limit")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
        
        // And: State should still have 20 categories
        let state = await client.currentState
        XCTAssertEqual(state.categories.count, 20)
    }
    
    // MARK: - Category Assignment Tests
    
    func testAssignCategoryToTask() async throws {
        // Given: A category and a task
        let category = Category(id: "1", name: "Work", color: "#0000FF")
        try await client.process(.createCategory(category))
        
        let task = Task(id: "task1", title: "Complete report")
        try await client.process(.create(task))
        
        // When: Assigning category to task
        let updatedTask = Task(
            id: task.id,
            title: task.title,
            description: task.description,
            dueDate: task.dueDate,
            categoryId: "1",  // Assign category
            priority: task.priority,
            isCompleted: task.isCompleted,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            version: task.version
        )
        try await client.process(.update(updatedTask))
        
        // Then: Task should have category assigned
        let state = await client.currentState
        let taskInState = state.tasks.first { $0.id == "task1" }
        XCTAssertEqual(taskInState?.categoryId, "1")
    }
    
    func testFilterByCategory() async throws {
        // Given: Multiple tasks with different categories
        let personalCategory = Category(id: "personal", name: "Personal", color: "#FF5733")
        let workCategory = Category(id: "work", name: "Work", color: "#0000FF")
        try await client.process(.createCategory(personalCategory))
        try await client.process(.createCategory(workCategory))
        
        // Create tasks with categories
        let tasks = [
            Task(id: "1", title: "Buy groceries", categoryId: "personal"),
            Task(id: "2", title: "Complete report", categoryId: "work"),
            Task(id: "3", title: "Exercise", categoryId: "personal"),
            Task(id: "4", title: "Team meeting", categoryId: "work"),
            Task(id: "5", title: "No category task", categoryId: nil)
        ]
        
        for task in tasks {
            try await client.process(.create(task))
        }
        
        // When: Filtering by personal category
        try await client.process(.filterByCategory(categoryId: "personal"))
        
        // Then: Only personal tasks should be visible
        let state = await client.currentState
        XCTAssertEqual(state.selectedCategoryId, "personal")
        XCTAssertEqual(state.filteredTasks.count, 2)
        XCTAssertTrue(state.filteredTasks.allSatisfy { $0.categoryId == "personal" })
    }
    
    func testClearCategoryFilter() async throws {
        // Given: Tasks filtered by category
        let category = Category(id: "1", name: "Work", color: "#0000FF")
        try await client.process(.createCategory(category))
        
        let task1 = Task(id: "1", title: "With category", categoryId: "1")
        let task2 = Task(id: "2", title: "Without category")
        try await client.process(.create(task1))
        try await client.process(.create(task2))
        
        try await client.process(.filterByCategory(categoryId: "1"))
        
        // When: Clearing the filter
        try await client.process(.filterByCategory(categoryId: nil))
        
        // Then: All tasks should be visible
        let state = await client.currentState
        XCTAssertNil(state.selectedCategoryId)
        XCTAssertEqual(state.filteredTasks.count, 2)
    }
    
    // MARK: - Batch Operations Tests
    
    func testBatchAssignCategory() async throws {
        // Given: A category and multiple tasks
        let category = Category(id: "urgent", name: "Urgent", color: "#FF0000")
        try await client.process(.createCategory(category))
        
        // Create 100 tasks
        for i in 1...100 {
            let task = Task(id: "\(i)", title: "Task \(i)")
            try await client.process(.create(task))
        }
        
        // When: Batch assigning category to all tasks
        let taskIds = Set((1...100).map { "\($0)" })
        let start = CFAbsoluteTimeGetCurrent()
        try await client.process(.batchAssignCategory(taskIds: taskIds, categoryId: "urgent"))
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
        
        // Then: All tasks should have the category
        let state = await client.currentState
        let tasksWithCategory = state.tasks.filter { $0.categoryId == "urgent" }
        XCTAssertEqual(tasksWithCategory.count, 100)
        
        // And: Operation should complete within 500ms
        XCTAssertLessThan(elapsed, 500, "Batch update took \(elapsed)ms, expected < 500ms")
    }
    
    func testBatchAssignCategoryPerformance() async throws {
        // Given: A category and 1000 tasks (as per requirement)
        let category = Category(id: "batch", name: "Batch", color: "#00FF00")
        try await client.process(.createCategory(category))
        
        // Create 1000 tasks
        for i in 1...1000 {
            let task = Task(id: "\(i)", title: "Task \(i)")
            try await client.process(.create(task))
        }
        
        // When: Batch assigning category to 1000 tasks
        let taskIds = Set((1...1000).map { "\($0)" })
        let start = CFAbsoluteTimeGetCurrent()
        try await client.process(.batchAssignCategory(taskIds: taskIds, categoryId: "batch"))
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
        
        // Then: Operation should complete within 500ms (RFC requirement)
        XCTAssertLessThan(elapsed, 500, "Batch update of 1000 tasks took \(elapsed)ms, expected < 500ms")
        
        // Verify all tasks updated
        let state = await client.currentState
        let tasksWithCategory = state.tasks.filter { $0.categoryId == "batch" }
        XCTAssertEqual(tasksWithCategory.count, 1000)
    }
    
    // MARK: - Category Deletion Impact Tests
    
    func testDeleteCategoryRemovesFromTasks() async throws {
        // Given: Tasks assigned to a category
        let category = Category(id: "temp", name: "Temporary", color: "#808080")
        try await client.process(.createCategory(category))
        
        let task1 = Task(id: "1", title: "Task 1", categoryId: "temp")
        let task2 = Task(id: "2", title: "Task 2", categoryId: "temp")
        let task3 = Task(id: "3", title: "Task 3", categoryId: nil)
        
        try await client.process(.create(task1))
        try await client.process(.create(task2))
        try await client.process(.create(task3))
        
        // When: Deleting the category
        try await client.process(.deleteCategory(categoryId: "temp"))
        
        // Then: Tasks should have category removed
        let state = await client.currentState
        XCTAssertEqual(state.categories.count, 0)
        
        let tasksWithCategory = state.tasks.filter { $0.categoryId == "temp" }
        XCTAssertEqual(tasksWithCategory.count, 0, "Tasks should not reference deleted category")
        
        let tasksWithoutCategory = state.tasks.filter { $0.categoryId == nil }
        XCTAssertEqual(tasksWithoutCategory.count, 3, "All tasks should have nil category")
    }
    
    // MARK: - Color Validation Tests
    
    func testValidColorFormats() async throws {
        // Given: Categories with different color formats
        let validColors = [
            "#FF5733",    // Standard hex
            "#000000",    // Black
            "#FFFFFF",    // White
            "#00FF00",    // Pure green
            "#123ABC"     // Mixed case
        ]
        
        // When: Creating categories with valid colors
        for (index, color) in validColors.enumerated() {
            let category = Category(id: "\(index)", name: "Category \(index)", color: color)
            try await client.process(.createCategory(category))
        }
        
        // Then: All should be created successfully
        let state = await client.currentState
        XCTAssertEqual(state.categories.count, validColors.count)
    }
    
    func testInvalidColorFormat() async throws {
        // Given: Invalid color formats
        let invalidColors = [
            "FF5733",     // Missing #
            "#FF57",      // Too short
            "#GGGGGG",    // Invalid hex
            "red",        // Named color
            "#FF5733FF"   // Too long
        ]
        
        // When/Then: Each should throw an error
        for (index, color) in invalidColors.enumerated() {
            let category = Category(id: "\(index)", name: "Invalid", color: color)
            
            do {
                try await client.process(.createCategory(category))
                XCTFail("Expected error for invalid color: \(color)")
            } catch {
                // Expected error
                XCTAssertNotNil(error)
            }
        }
    }
}