import XCTest
@testable import TestApp002Core

// RED Phase: Task creation tests that should fail without proper validation
final class TaskCreationTests: XCTestCase {
    private var taskClient: TaskClient!
    
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
    
    // MARK: - Valid Task Creation
    
    func testCreateTaskWithAllFields() async throws {
        // Set up state collection
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 2 // Initial + after create
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                expectation.fulfill()
                if states.count >= 2 {
                    break
                }
            }
        }
        
        // Give time for stream to start
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        let dueDate = Date().addingTimeInterval(86400) // Tomorrow
        let task = Task(
            id: "test-1",
            title: "Complete project",
            description: "Finish the iOS app implementation",
            dueDate: dueDate,
            categoryId: "work",
            priority: .high,
            isCompleted: false
        )
        
        // Process create action
        try await taskClient.process(.create(task))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        // Verify task was added
        XCTAssertEqual(states.count, 2)
        XCTAssertEqual(states[1].tasks.count, 1)
        
        let createdTask = states[1].tasks.first
        XCTAssertEqual(createdTask?.id, "test-1")
        XCTAssertEqual(createdTask?.title, "Complete project")
        XCTAssertEqual(createdTask?.description, "Finish the iOS app implementation")
        XCTAssertEqual(createdTask?.dueDate, dueDate)
        XCTAssertEqual(createdTask?.categoryId, "work")
        XCTAssertEqual(createdTask?.priority, .high)
        XCTAssertEqual(createdTask?.isCompleted, false)
    }
    
    // MARK: - Title Validation
    
    func testCreateTaskWithoutTitle() async throws {
        let task = Task(
            id: "test-2",
            title: "", // Empty title
            description: "Some description"
        )
        
        // Should throw validation error
        do {
            try await taskClient.process(.create(task))
            XCTFail("Should have thrown validation error for empty title")
        } catch TaskValidationError.missingTitle {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testCreateTaskWithWhitespaceOnlyTitle() async throws {
        let task = Task(
            id: "test-3",
            title: "   ", // Whitespace only
            description: "Some description"
        )
        
        // Should throw validation error
        do {
            try await taskClient.process(.create(task))
            XCTFail("Should have thrown validation error for whitespace-only title")
        } catch TaskValidationError.missingTitle {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Description Validation
    
    func testCreateTaskWithTooLongDescription() async throws {
        let longDescription = String(repeating: "a", count: 501) // 501 characters
        let task = Task(
            id: "test-4",
            title: "Valid title",
            description: longDescription
        )
        
        // Should throw validation error
        do {
            try await taskClient.process(.create(task))
            XCTFail("Should have thrown validation error for description over 500 characters")
        } catch TaskValidationError.descriptionTooLong(let maxLength) {
            XCTAssertEqual(maxLength, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testCreateTaskWithMaxLengthDescription() async throws {
        // Set up state collection
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 2
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                expectation.fulfill()
                if states.count >= 2 {
                    break
                }
            }
        }
        
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        let maxDescription = String(repeating: "a", count: 500) // Exactly 500 characters
        let task = Task(
            id: "test-5",
            title: "Valid title",
            description: maxDescription
        )
        
        // Should succeed
        try await taskClient.process(.create(task))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        XCTAssertEqual(states[1].tasks.count, 1)
        XCTAssertEqual(states[1].tasks.first?.description, maxDescription)
    }
    
    // MARK: - Default Values
    
    func testCreateTaskWithMinimalFields() async throws {
        // Set up state collection
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 2
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                expectation.fulfill()
                if states.count >= 2 {
                    break
                }
            }
        }
        
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        let task = Task(
            id: "test-6",
            title: "Minimal task"
            // All other fields should get defaults
        )
        
        try await taskClient.process(.create(task))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        let createdTask = states[1].tasks.first
        XCTAssertEqual(createdTask?.title, "Minimal task")
        XCTAssertEqual(createdTask?.description, "") // Default empty
        XCTAssertNil(createdTask?.dueDate) // Default nil
        XCTAssertNil(createdTask?.categoryId) // Default nil
        XCTAssertEqual(createdTask?.priority, .medium) // Default medium
        XCTAssertEqual(createdTask?.isCompleted, false) // Default false
        XCTAssertNotNil(createdTask?.createdAt) // Should be set
        XCTAssertNotNil(createdTask?.updatedAt) // Should be set
    }
    
    // MARK: - Performance Requirements
    
    func testCreateTaskPerformance() async throws {
        let task = Task(
            id: "perf-test",
            title: "Performance test task"
        )
        
        // Measure time to process and receive state update
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try await taskClient.process(.create(task))
        
        // Give minimal time for state to propagate
        try await SwiftTask.sleep(nanoseconds: 1_000_000) // 1ms
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let elapsedMs = (endTime - startTime) * 1000
        
        // Should complete within 16ms
        XCTAssertLessThan(elapsedMs, 16, "Task creation should complete within 16ms")
    }
    
    // MARK: - Duplicate ID Handling
    
    func testCreateTaskWithDuplicateId() async throws {
        let task1 = Task(id: "duplicate-id", title: "First task")
        let task2 = Task(id: "duplicate-id", title: "Second task")
        
        // Create first task
        try await taskClient.process(.create(task1))
        
        // Try to create second task with same ID
        do {
            try await taskClient.process(.create(task2))
            XCTFail("Should have thrown error for duplicate task ID")
        } catch TaskValidationError.duplicateId(let id) {
            XCTAssertEqual(id, "duplicate-id")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Batch Creation
    
    func testCreateMultipleTasksSequentially() async throws {
        // Set up state collection
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 6 // Initial + 5 creates
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                expectation.fulfill()
                if states.count >= 6 {
                    break
                }
            }
        }
        
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        let tasks = (0..<5).map { i in
            Task(
                id: "batch-\(i)",
                title: "Task \(i)",
                priority: i % 2 == 0 ? .high : .low
            )
        }
        
        // Create tasks sequentially
        for task in tasks {
            try await taskClient.process(.create(task))
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        let finalState = states.last!
        XCTAssertEqual(finalState.tasks.count, 5)
        
        // Verify all tasks were created
        for (index, _) in tasks.enumerated() {
            XCTAssertTrue(finalState.tasks.contains { $0.id == "batch-\(index)" })
        }
    }
}

// TaskValidationError is imported from TestApp002Core