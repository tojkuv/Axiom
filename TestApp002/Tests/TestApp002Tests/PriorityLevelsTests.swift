import Testing
@testable import TestApp002Core
import Foundation

@Suite("Priority Levels Tests")
struct PriorityLevelsTests {
    
    // RED: Test priority sorting fails
    @Test("Priority levels affect sort order")
    func testPrioritySorting() async throws {
        // Given: Create client and add tasks with different priorities
        let storage = InMemoryStorageCapability()
        let network = MockNetworkCapability()
        let notification = MockNotificationCapability()
        let client = TaskClient(
            userId: "test-user",
            storageCapability: storage,
            networkCapability: network,
            notificationCapability: notification
        )
        
        // Add tasks in random order
        try await client.process(TaskAction.create(Task(title: "Medium Task", priority: .medium)))
        try await client.process(TaskAction.create(Task(title: "Low Task", priority: .low)))
        try await client.process(TaskAction.create(Task(title: "Critical Task", priority: .critical)))
        try await client.process(TaskAction.create(Task(title: "High Task", priority: .high)))
        
        // When: Sort by priority
        try await client.process(TaskAction.sort(by: .priority))
        
        // Then: Tasks should be sorted by priority (critical first)
        let sortedState = await client.currentState
        #expect(sortedState.tasks.count == 4)
        #expect(sortedState.tasks[0].priority == Priority.critical)
        #expect(sortedState.tasks[1].priority == Priority.high)
        #expect(sortedState.tasks[2].priority == Priority.medium)
        #expect(sortedState.tasks[3].priority == Priority.low)
        #expect(sortedState.sortCriteria == SortCriteria.priority)
    }
    
    @Test("Priority changes trigger re-sort within 16ms")
    func testPriorityUpdatePerformance() async throws {
        // Given: Initial tasks with priority sort active
        let storage = InMemoryStorageCapability()
        let network = MockNetworkCapability()
        let notification = MockNotificationCapability()
        let client = TaskClient(
            userId: "test-user",
            storageCapability: storage,
            networkCapability: network,
            notificationCapability: notification
        )
        
        // Add 100 tasks
        for i in 1...100 {
            try await client.process(TaskAction.create(Task(title: "Task \(i)", priority: .medium)))
        }
        
        // Set priority sort
        try await client.process(TaskAction.sort(by: .priority))
        
        // When: Update a task's priority
        let currentTasks = await client.currentState.tasks
        let updatedTask = currentTasks[50].updated(priority: .critical)
        
        let startTime = DispatchTime.now()
        try await client.process(TaskAction.update(updatedTask))
        let endTime = DispatchTime.now()
        
        let elapsedTime = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
        
        // Then: Update completes within 16ms
        #expect(elapsedTime < 16.0)
        
        // And: Task is now at the top due to critical priority
        let finalState = await client.currentState
        #expect(finalState.tasks.first?.id == updatedTask.id)
        #expect(finalState.tasks.first?.priority == Priority.critical)
    }
    
    @Test("Priority sort maintains stable order for same priority")
    func testStablePrioritySort() async throws {
        // Given: Multiple tasks with same priority
        let task1 = Task(id: "1", title: "First High", priority: .high, createdAt: Date(timeIntervalSince1970: 1000))
        let task2 = Task(id: "2", title: "Second High", priority: .high, createdAt: Date(timeIntervalSince1970: 2000))
        let task3 = Task(id: "3", title: "Third High", priority: .high, createdAt: Date(timeIntervalSince1970: 3000))
        
        let storage = InMemoryStorageCapability()
        let network = MockNetworkCapability()
        let notification = MockNotificationCapability()
        let client = TaskClient(
            userId: "test-user",
            storageCapability: storage,
            networkCapability: network,
            notificationCapability: notification
        )
        
        // Add tasks in non-creation order
        try await client.process(TaskAction.create(task3))
        try await client.process(TaskAction.create(task1))
        try await client.process(TaskAction.create(task2))
        
        // When: Sort by priority
        try await client.process(TaskAction.sort(by: .priority))
        
        // Then: Tasks with same priority maintain creation order
        let sortedState = await client.currentState
        let highPriorityTasks = sortedState.tasks.filter { $0.priority == Priority.high }
        #expect(highPriorityTasks[0].id == "1")
        #expect(highPriorityTasks[1].id == "2")
        #expect(highPriorityTasks[2].id == "3")
    }
    
    @Test("Priority sort works with other filters")
    func testPrioritySortWithFilters() async throws {
        // Given: Tasks with different categories and priorities
        let workCategory = Category(id: "work", name: "Work", color: "#FF0000")
        let personalCategory = Category(id: "personal", name: "Personal", color: "#00FF00")
        
        let storage = InMemoryStorageCapability()
        let network = MockNetworkCapability()
        let notification = MockNotificationCapability()
        let client = TaskClient(
            userId: "test-user",
            storageCapability: storage,
            networkCapability: network,
            notificationCapability: notification
        )
        
        // Add categories
        try await client.process(TaskAction.createCategory(workCategory))
        try await client.process(TaskAction.createCategory(personalCategory))
        
        // Add tasks
        try await client.process(TaskAction.create(Task(title: "Work Critical", categoryId: "work", priority: .critical)))
        try await client.process(TaskAction.create(Task(title: "Work Low", categoryId: "work", priority: .low)))
        try await client.process(TaskAction.create(Task(title: "Personal High", categoryId: "personal", priority: .high)))
        try await client.process(TaskAction.create(Task(title: "Personal Medium", categoryId: "personal", priority: .medium)))
        try await client.process(TaskAction.create(Task(title: "No Category Critical", priority: .critical)))
        
        // When: Apply category filter and priority sort
        try await client.process(TaskAction.filterByCategory(categoryId: "work"))
        try await client.process(TaskAction.sort(by: .priority))
        
        // Then: Only work tasks are shown, sorted by priority
        let filteredState = await client.currentState
        let visibleTasks = filteredState.filteredTasks
        #expect(visibleTasks.count == 2)
        #expect(visibleTasks[0].title == "Work Critical")
        #expect(visibleTasks[1].title == "Work Low")
    }
    
    @Test("Priority enum has correct order values")
    func testPriorityEnumOrder() {
        // Verify all priority levels exist
        #expect(Priority.allCases.count == 4)
        #expect(Priority.allCases.contains(Priority.critical))
        #expect(Priority.allCases.contains(Priority.high))
        #expect(Priority.allCases.contains(Priority.medium))
        #expect(Priority.allCases.contains(Priority.low))
    }
    
    @Test("Tasks default to medium priority")
    func testDefaultPriority() {
        // Given: Task created without explicit priority
        let task = Task(title: "Default Priority Task")
        
        // Then: Priority should be medium
        #expect(task.priority == Priority.medium)
    }
    
    @Test("Priority sorting works with search")
    func testPrioritySortWithSearch() async throws {
        // Given: Tasks with different priorities and search query
        let storage = InMemoryStorageCapability()
        let network = MockNetworkCapability()
        let notification = MockNotificationCapability()
        let client = TaskClient(
            userId: "test-user",
            storageCapability: storage,
            networkCapability: network,
            notificationCapability: notification
        )
        
        // Add tasks
        try await client.process(TaskAction.create(Task(title: "Fix critical bug", priority: .critical)))
        try await client.process(TaskAction.create(Task(title: "Fix minor issue", priority: .low)))
        try await client.process(TaskAction.create(Task(title: "Fix high priority", priority: .high)))
        try await client.process(TaskAction.create(Task(title: "Unrelated task", priority: .critical)))
        
        // When: Apply search and priority sort
        try await client.process(TaskAction.search(query: "fix"))
        try await client.process(TaskAction.sort(by: .priority))
        
        // Then: Only "fix" tasks shown, sorted by priority
        let filteredState = await client.currentState
        let visibleTasks = filteredState.filteredTasks
        #expect(visibleTasks.count == 3)
        #expect(visibleTasks[0].title == "Fix critical bug")
        #expect(visibleTasks[1].title == "Fix high priority")
        #expect(visibleTasks[2].title == "Fix minor issue")
    }
    
    @Test("Bulk priority update maintains sort order")
    func testBulkPriorityUpdate() async throws {
        // Given: Multiple tasks to update
        let storage = InMemoryStorageCapability()
        let network = MockNetworkCapability()
        let notification = MockNotificationCapability()
        let client = TaskClient(
            userId: "test-user",
            storageCapability: storage,
            networkCapability: network,
            notificationCapability: notification
        )
        
        // Add tasks
        try await client.process(TaskAction.create(Task(id: "1", title: "Task 1", priority: .low)))
        try await client.process(TaskAction.create(Task(id: "2", title: "Task 2", priority: .medium)))
        try await client.process(TaskAction.create(Task(id: "3", title: "Task 3", priority: .low)))
        try await client.process(TaskAction.create(Task(id: "4", title: "Task 4", priority: .high)))
        
        // Set priority sort
        try await client.process(TaskAction.sort(by: .priority))
        
        // When: Update multiple tasks to critical priority
        let currentTasks = await client.currentState.tasks
        let task1 = currentTasks.first { $0.id == "1" }!
        let task3 = currentTasks.first { $0.id == "3" }!
        
        let updatedTask1 = task1.updated(priority: .critical)
        let updatedTask3 = task3.updated(priority: .critical)
        
        try await client.process(TaskAction.update(updatedTask1))
        try await client.process(TaskAction.update(updatedTask3))
        
        // Then: Both updated tasks should be at the top
        let finalState = await client.currentState
        let criticalTasks = finalState.tasks.prefix(2)
        #expect(criticalTasks.allSatisfy { $0.priority == Priority.critical })
        #expect(Set(criticalTasks.map { $0.id }) == Set(["1", "3"]))
    }
    
    // REFACTOR: Test custom sort options (ascending/descending)
    @Test("Priority sort supports ascending and descending order")
    func testPrioritySortAscendingDescending() async throws {
        // Given: Tasks with different priorities
        let storage = InMemoryStorageCapability()
        let network = MockNetworkCapability()
        let notification = MockNotificationCapability()
        let client = TaskClient(
            userId: "test-user",
            storageCapability: storage,
            networkCapability: network,
            notificationCapability: notification
        )
        
        // Add tasks
        try await client.process(TaskAction.create(Task(title: "Critical", priority: .critical)))
        try await client.process(TaskAction.create(Task(title: "High", priority: .high)))
        try await client.process(TaskAction.create(Task(title: "Medium", priority: .medium)))
        try await client.process(TaskAction.create(Task(title: "Low", priority: .low)))
        
        // When: Sort by priority ascending (critical first)
        try await client.process(TaskAction.sort(by: .priority(ascending: true)))
        
        // Then: Critical tasks come first
        var state = await client.currentState
        #expect(state.tasks[0].priority == Priority.critical)
        #expect(state.tasks[1].priority == Priority.high)
        #expect(state.tasks[2].priority == Priority.medium)
        #expect(state.tasks[3].priority == Priority.low)
        
        // When: Sort by priority descending (low first)
        try await client.process(TaskAction.sort(by: .priority(ascending: false)))
        
        // Then: Low priority tasks come first
        state = await client.currentState
        #expect(state.tasks[0].priority == Priority.low)
        #expect(state.tasks[1].priority == Priority.medium)
        #expect(state.tasks[2].priority == Priority.high)
        #expect(state.tasks[3].priority == Priority.critical)
    }
    
    @Test("Multiple sort criteria can be combined")
    func testCompoundSortCriteria() async throws {
        // Given: Tasks with same priority but different due dates
        let storage = InMemoryStorageCapability()
        let network = MockNetworkCapability()
        let notification = MockNotificationCapability()
        let client = TaskClient(
            userId: "test-user",
            storageCapability: storage,
            networkCapability: network,
            notificationCapability: notification
        )
        
        let tomorrow = Date().addingTimeInterval(86400)
        let nextWeek = Date().addingTimeInterval(604800)
        
        // Add tasks with same priority but different due dates
        try await client.process(TaskAction.create(Task(title: "High Next Week", dueDate: nextWeek, priority: .high)))
        try await client.process(TaskAction.create(Task(title: "High Tomorrow", dueDate: tomorrow, priority: .high)))
        try await client.process(TaskAction.create(Task(title: "Critical Next Week", dueDate: nextWeek, priority: .critical)))
        try await client.process(TaskAction.create(Task(title: "Critical Tomorrow", dueDate: tomorrow, priority: .critical)))
        
        // When: Sort by priority (critical first)
        try await client.process(TaskAction.sort(by: .priority))
        
        // Then: Tasks are sorted by priority, with same priority maintaining creation order
        let state = await client.currentState
        #expect(state.tasks[0].title == "Critical Next Week")
        #expect(state.tasks[1].title == "Critical Tomorrow")
        #expect(state.tasks[2].title == "High Next Week")
        #expect(state.tasks[3].title == "High Tomorrow")
        
        // When: Sort by due date
        try await client.process(TaskAction.sort(by: .dueDate))
        
        // Then: Tasks are sorted by due date regardless of priority
        let dueSortedState = await client.currentState
        #expect(dueSortedState.tasks[0].title.contains("Tomorrow"))
        #expect(dueSortedState.tasks[1].title.contains("Tomorrow"))
        #expect(dueSortedState.tasks[2].title.contains("Next Week"))
        #expect(dueSortedState.tasks[3].title.contains("Next Week"))
    }
}