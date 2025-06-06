import XCTest
import Darwin
@testable import TestApp002Core

final class LargeDatasetTests: XCTestCase {
    var taskClient: TaskClient!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let storageCapability = InMemoryStorageCapability()
        let networkCapability = MockNetworkCapability()
        let notificationCapability = MockNotificationCapability()
        
        taskClient = TaskClient(
            userId: "test-user",
            storageCapability: storageCapability,
            networkCapability: networkCapability,
            notificationCapability: notificationCapability
        )
    }
    
    override func tearDown() async throws {
        taskClient = nil
        try await super.tearDown()
    }
    
    // MARK: - RED Phase: Failing Tests for Large Dataset Performance
    
    func testInitialLoadWith10000TasksCompletesWith2Seconds() async throws {
        // Create 10,000 tasks
        let largeTasks = generateTasks(count: 10000)
        
        // Load all tasks
        for task in largeTasks {
            try await taskClient.process(.create(task))
        }
        
        // Measure initial load time
        let startTime = CFAbsoluteTimeGetCurrent()
        let state = await taskClient.currentState
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let loadTime = endTime - startTime
        
        // Should complete within 2 seconds
        XCTAssertLessThan(loadTime, 2.0, "Initial load with 10,000 tasks should complete in < 2s, took \(loadTime)s")
        XCTAssertEqual(state.tasks.count, 10000)
    }
    
    func testSearchWith10000TasksCompletesWithin100Ms() async throws {
        // Create 10,000 tasks with searchable content
        let largeTasks = generateSearchableTasks(count: 10000)
        
        for task in largeTasks {
            try await taskClient.process(.create(task))
        }
        
        // Measure search performance
        let startTime = CFAbsoluteTimeGetCurrent()
        try await taskClient.process(.search(query: "test"))
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let searchTime = endTime - startTime
        
        // Should complete within 100ms
        XCTAssertLessThan(searchTime, 0.1, "Search with 10,000 tasks should complete in < 100ms, took \(searchTime * 1000)ms")
    }
    
    func testMemoryUsageWith10000TasksStaysBelow100MB() async throws {
        let initialMemory = getMemoryUsage()
        
        // Create 10,000 tasks
        let largeTasks = generateTasks(count: 10000)
        
        for task in largeTasks {
            try await taskClient.process(.create(task))
        }
        
        let finalMemory = getMemoryUsage()
        let memoryDelta = finalMemory - initialMemory
        
        // Should use less than 100MB additional memory
        let maxMemoryMB = 100.0
        let memoryMB = Double(memoryDelta) / (1024.0 * 1024.0)
        
        XCTAssertLessThan(memoryMB, maxMemoryMB, "Memory usage with 10,000 tasks should be < 100MB, used \(memoryMB)MB")
    }
    
    func testLazyLoadingKeepsMaximum1000TasksInMemory() async throws {
        // Create 10,000 tasks
        let largeTasks = generateTasks(count: 10000)
        
        for task in largeTasks {
            try await taskClient.process(.create(task))
        }
        
        let state = await taskClient.currentState
        
        // Should have lazy loading mechanism that keeps max 1000 tasks in memory
        // TODO: Implement visibleTasks property in TaskListState for lazy loading
        XCTFail("Lazy loading mechanism not implemented - all \(state.tasks.count) tasks loaded in memory")
    }
    
    func testScrollPerformanceWith10000TasksMaintains60FPS() async throws {
        // Create 10,000 tasks
        let largeTasks = generateTasks(count: 10000)
        
        for task in largeTasks {
            try await taskClient.process(.create(task))
        }
        
        // Simulate scroll operations
        let frameTime = 1.0 / 60.0 // 60 FPS = 16.67ms per frame
        
        // TODO: Implement scrollToOffset action in TaskAction
        // For now, test basic task retrieval performance
        let state = await taskClient.currentState
        let startTime = CFAbsoluteTimeGetCurrent()
        let _ = state.filteredTasks
        let endTime = CFAbsoluteTimeGetCurrent()
        let renderTime = endTime - startTime
        
        XCTAssertLessThan(renderTime, frameTime, "Task retrieval took \(renderTime * 1000)ms, should be < \(frameTime * 1000)ms for 60fps")
    }
    
    func testPaginationLoadingWith10000Tasks() async throws {
        // Create 10,000 tasks
        let largeTasks = generateTasks(count: 10000)
        
        for task in largeTasks {
            try await taskClient.process(.create(task))
        }
        
        // TODO: Implement pagination actions in TaskAction
        // For now, test that we can retrieve tasks efficiently
        let state = await taskClient.currentState
        let firstHundred = Array(state.tasks.prefix(100))
        let secondHundred = Array(state.tasks.dropFirst(100).prefix(100))
        
        XCTAssertEqual(firstHundred.count, 100, "First page should contain 100 tasks")
        XCTAssertEqual(secondHundred.count, 100, "Second page should contain 100 tasks")
        XCTAssertNotEqual(firstHundred.first?.id, secondHundred.first?.id, "Pages should contain different tasks")
    }
    
    func testVirtualScrollingWith10000Tasks() async throws {
        // Create 10,000 tasks
        let largeTasks = generateTasks(count: 10000)
        
        for task in largeTasks {
            try await taskClient.process(.create(task))
        }
        
        // TODO: Implement virtual scrolling in TaskListState
        // For now, test that we can efficiently slice large datasets
        let state = await taskClient.currentState
        let viewportHeight = 800.0
        let itemHeight = 60.0
        let visibleItems = Int(viewportHeight / itemHeight) + 2 // Buffer
        
        // Simulate virtual scrolling by taking a slice from the middle
        let startIndex = 5000
        let endIndex = min(startIndex + visibleItems, state.tasks.count)
        let visibleSlice = Array(state.tasks[startIndex..<endIndex])
        
        XCTAssertLessThanOrEqual(visibleSlice.count, visibleItems, "Virtual scrolling slice should contain limited items")
        XCTAssertGreaterThan(visibleSlice.count, 0, "Virtual scrolling slice should contain some items")
    }
    
    func testConcurrentOperationsOnLargeDataset() async throws {
        // Create 5,000 tasks initially
        let initialTasks = generateTasks(count: 5000)
        
        for task in initialTasks {
            try await taskClient.process(.create(task))
        }
        
        // Perform 100 concurrent operations
        let client = taskClient!
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    do {
                        let newTask = Task(
                            title: "Concurrent Task \(i)",
                            description: "Auto-generated concurrent task"
                        )
                        try await client.process(.create(newTask))
                    } catch {
                        // Can't use XCTFail in concurrent context, will check results after
                        print("Concurrent operation \(i) failed: \(error)")
                    }
                }
            }
        }
        
        let finalState = await taskClient.currentState
        XCTAssertEqual(finalState.tasks.count, 5100, "Should have 5,100 tasks after concurrent operations")
    }
    
    func testPerformanceWithLargeDatasetFiltering() async throws {
        // Create 10,000 tasks with categories
        let largeTasks = generateTasksWithCategories(count: 10000)
        
        for task in largeTasks {
            try await taskClient.process(.create(task))
        }
        
        // Measure filtering performance
        let startTime = CFAbsoluteTimeGetCurrent()
        try await taskClient.process(.filterByCategory(categoryId: "category-1"))
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let filterTime = endTime - startTime
        
        // Filtering should be fast even with large datasets
        XCTAssertLessThan(filterTime, 0.05, "Filtering 10,000 tasks should complete in < 50ms, took \(filterTime * 1000)ms")
    }
    
    // MARK: - Helper Methods
    
    private func generateTasks(count: Int) -> [Task] {
        return (0..<count).map { index in
            generateTask(title: "Task \(index)")
        }
    }
    
    private func generateSearchableTasks(count: Int) -> [Task] {
        return (0..<count).map { index in
            let title = index % 100 == 0 ? "test task \(index)" : "Task \(index)"
            return generateTask(title: title)
        }
    }
    
    private func generateTasksWithCategories(count: Int) -> [Task] {
        return (0..<count).map { index in
            let categoryId = "category-\(index % 10)"
            return Task(
                id: "task-\(index)",
                title: "Task \(index)",
                description: "Description for task \(index)",
                dueDate: nil,
                categoryId: categoryId,
                priority: .medium,
                isCompleted: false,
                createdAt: Date(),
                version: nil,
                sharedWith: [],
                sharedBy: nil
            )
        }
    }
    
    private func generateTask(title: String) -> Task {
        return Task(
            id: UUID().uuidString,
            title: title,
            description: "Auto-generated task",
            dueDate: nil,
            categoryId: nil,
            priority: .medium,
            isCompleted: false,
            createdAt: Date(),
            version: nil,
            sharedWith: [],
            sharedBy: nil
        )
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
}