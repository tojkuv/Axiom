import XCTest
@testable import TestApp002Core

final class TaskSearchTests: XCTestCase {
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
    
    // MARK: - Basic Search Tests
    
    func testSearchByTitle() async throws {
        // Given: Tasks with different titles
        let task1 = Task(id: "1", title: "Buy groceries", description: "Milk and bread")
        let task2 = Task(id: "2", title: "Walk the dog", description: "In the park")
        let task3 = Task(id: "3", title: "Buy a new car", description: "Research models")
        
        try await client.process(.create(task1))
        try await client.process(.create(task2))
        try await client.process(.create(task3))
        
        // When: Searching for "buy"
        try await client.process(.search(query: "buy"))
        
        // Then: Only tasks with "buy" in title should be returned
        let state = await client.currentState
        XCTAssertEqual(state.searchQuery, "buy")
        XCTAssertEqual(state.filteredTasks.count, 2)
        XCTAssertTrue(state.filteredTasks.contains { $0.id == "1" })
        XCTAssertTrue(state.filteredTasks.contains { $0.id == "3" })
        XCTAssertFalse(state.filteredTasks.contains { $0.id == "2" })
    }
    
    func testSearchByDescription() async throws {
        // Given: Tasks with searchable content in descriptions
        let task1 = Task(id: "1", title: "Shopping", description: "Buy milk and bread")
        let task2 = Task(id: "2", title: "Exercise", description: "Run in the park")
        let task3 = Task(id: "3", title: "Work", description: "Review park proposal")
        
        try await client.process(.create(task1))
        try await client.process(.create(task2))
        try await client.process(.create(task3))
        
        // When: Searching for "park"
        try await client.process(.search(query: "park"))
        
        // Then: Tasks with "park" in description should be returned
        let state = await client.currentState
        XCTAssertEqual(state.filteredTasks.count, 2)
        XCTAssertTrue(state.filteredTasks.contains { $0.id == "2" })
        XCTAssertTrue(state.filteredTasks.contains { $0.id == "3" })
    }
    
    func testCaseInsensitiveSearch() async throws {
        // Given: Tasks with various capitalizations
        let task1 = Task(id: "1", title: "URGENT task", description: "Important")
        let task2 = Task(id: "2", title: "urgent meeting", description: "Today")
        let task3 = Task(id: "3", title: "Not Urgent", description: "Can wait")
        
        try await client.process(.create(task1))
        try await client.process(.create(task2))
        try await client.process(.create(task3))
        
        // When: Searching with different case
        try await client.process(.search(query: "URGENT"))
        
        // Then: All variations should be found
        let state = await client.currentState
        XCTAssertEqual(state.filteredTasks.count, 3)
    }
    
    func testEmptySearchQuery() async throws {
        // Given: Some tasks
        let tasks = [
            Task(id: "1", title: "Task 1"),
            Task(id: "2", title: "Task 2"),
            Task(id: "3", title: "Task 3")
        ]
        
        for task in tasks {
            try await client.process(.create(task))
        }
        
        // When: Setting empty search query
        try await client.process(.search(query: ""))
        
        // Then: All tasks should be visible
        let state = await client.currentState
        XCTAssertEqual(state.searchQuery, "")
        XCTAssertEqual(state.filteredTasks.count, 3)
    }
    
    func testNoSearchResults() async throws {
        // Given: Tasks that won't match search
        let tasks = [
            Task(id: "1", title: "Apple", description: "Fruit"),
            Task(id: "2", title: "Banana", description: "Yellow"),
            Task(id: "3", title: "Cherry", description: "Red")
        ]
        
        for task in tasks {
            try await client.process(.create(task))
        }
        
        // When: Searching for non-existent content
        try await client.process(.search(query: "xyz123"))
        
        // Then: No results should be returned
        let state = await client.currentState
        XCTAssertEqual(state.searchQuery, "xyz123")
        XCTAssertTrue(state.filteredTasks.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testSearchPerformanceWithin16ms() async throws {
        // Given: A moderate number of tasks
        for i in 1...100 {
            let task = Task(
                id: "\(i)",
                title: "Task \(i)",
                description: "Description for task \(i)"
            )
            try await client.process(.create(task))
        }
        
        // When: Measuring search performance
        let start = CFAbsoluteTimeGetCurrent()
        try await client.process(.search(query: "task"))
        let end = CFAbsoluteTimeGetCurrent()
        let elapsed = (end - start) * 1000 // Convert to milliseconds
        
        // Then: Search should complete within 16ms
        XCTAssertLessThan(elapsed, 16, "Search took \(elapsed)ms, expected < 16ms")
    }
    
    func testSearchPerformanceWith10000Tasks() async throws {
        // Given: 10,000 tasks as per requirement
        for i in 1...10_000 {
            let task = Task(
                id: "\(i)",
                title: "Task \(i % 100)", // Create some repetition for realistic search
                description: "Description for task with number \(i)"
            )
            try await client.process(.create(task))
        }
        
        // When: Searching within large dataset
        let start = CFAbsoluteTimeGetCurrent()
        try await client.process(.search(query: "task 42"))
        let end = CFAbsoluteTimeGetCurrent()
        let elapsed = (end - start) * 1000 // Convert to milliseconds
        
        // Then: Search should complete within 100ms as per requirement
        XCTAssertLessThan(elapsed, 100, "Search took \(elapsed)ms, expected < 100ms")
        
        // Verify results
        let state = await client.currentState
        XCTAssertEqual(state.filteredTasks.count, 100) // Should find all "Task 42" instances
    }
    
    // MARK: - Real-time Search Tests
    
    func testRapidSearchUpdates() async throws {
        // Given: Some tasks
        for i in 1...50 {
            let task = Task(id: "\(i)", title: "Item \(i)")
            try await client.process(.create(task))
        }
        
        // When: Rapidly changing search queries (simulating typing)
        let queries = ["i", "it", "ite", "item", "item 1", "item 10"]
        
        for query in queries {
            let start = CFAbsoluteTimeGetCurrent()
            try await client.process(.search(query: query))
            let end = CFAbsoluteTimeGetCurrent()
            let elapsed = (end - start) * 1000
            
            // Then: Each update should be within 16ms
            XCTAssertLessThan(elapsed, 16, "Search update for '\(query)' took \(elapsed)ms")
        }
    }
    
    // MARK: - Advanced Search Tests
    
    func testSearchWithSpecialCharacters() async throws {
        // Given: Tasks with special characters
        let task1 = Task(id: "1", title: "Email: john@example.com")
        let task2 = Task(id: "2", title: "Phone: +1 (555) 123-4567")
        let task3 = Task(id: "3", title: "Code: func() { return 42; }")
        
        try await client.process(.create(task1))
        try await client.process(.create(task2))
        try await client.process(.create(task3))
        
        // When: Searching with special characters
        try await client.process(.search(query: "@example"))
        var state = await client.currentState
        XCTAssertEqual(state.filteredTasks.count, 1)
        XCTAssertEqual(state.filteredTasks.first?.id, "1")
        
        try await client.process(.search(query: "(555)"))
        state = await client.currentState
        XCTAssertEqual(state.filteredTasks.count, 1)
        XCTAssertEqual(state.filteredTasks.first?.id, "2")
    }
    
    func testSearchMaintainsOtherFilters() async throws {
        // Given: Tasks with categories
        let personalTasks = [
            Task(id: "1", title: "Buy groceries", categoryId: "personal"),
            Task(id: "2", title: "Buy birthday gift", categoryId: "personal"),
            Task(id: "3", title: "Clean house", categoryId: "personal")
        ]
        
        let workTasks = [
            Task(id: "4", title: "Buy office supplies", categoryId: "work"),
            Task(id: "5", title: "Prepare presentation", categoryId: "work")
        ]
        
        for task in personalTasks + workTasks {
            try await client.process(.create(task))
        }
        
        // When: Filtering by category then searching
        try await client.process(.filterByCategory(categoryId: "personal"))
        try await client.process(.search(query: "buy"))
        
        // Then: Search should respect existing category filter
        let state = await client.currentState
        XCTAssertEqual(state.filteredTasks.count, 2) // Only personal "buy" tasks
        XCTAssertTrue(state.filteredTasks.allSatisfy { $0.categoryId == "personal" })
        XCTAssertTrue(state.filteredTasks.allSatisfy { $0.title.lowercased().contains("buy") })
    }
    
    func testSearchStateStream() async throws {
        // Given: Tasks and state observer
        let task1 = Task(id: "1", title: "First task")
        let task2 = Task(id: "2", title: "Second task")
        try await client.process(.create(task1))
        try await client.process(.create(task2))
        
        var receivedStates: [TaskListState] = []
        let expectation = XCTestExpectation(description: "Receive search state updates")
        expectation.expectedFulfillmentCount = 2
        
        SwiftTask { [weak client] in
            guard let client = client else { return }
            for await state in await client.stateStream {
                if !state.searchQuery.isEmpty {
                    receivedStates.append(state)
                    expectation.fulfill()
                    if receivedStates.count >= 2 {
                        break
                    }
                }
            }
        }
        
        // When: Performing searches
        try await client.process(.search(query: "first"))
        try await SwiftTask.sleep(nanoseconds: 10_000_000) // 10ms
        try await client.process(.search(query: "second"))
        
        // Then: State stream should emit updates
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedStates.count, 2)
        XCTAssertEqual(receivedStates[0].searchQuery, "first")
        XCTAssertEqual(receivedStates[1].searchQuery, "second")
    }
}