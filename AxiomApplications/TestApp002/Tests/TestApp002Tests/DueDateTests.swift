import XCTest
@testable import TestApp002Core

// RED Phase: Due date tests that should fail without proper implementation
final class DueDateTests: XCTestCase {
    private var taskClient: TaskClient!
    private var notificationCapability: MockNotificationCapability!
    
    override func setUp() async throws {
        try await super.setUp()
        let storageCapability = InMemoryStorageCapability()
        let networkCapability = MockNetworkCapability()
        notificationCapability = MockNotificationCapability()
        
        taskClient = TaskClient(
            userId: "test-user",
            storageCapability: storageCapability,
            networkCapability: networkCapability,
            notificationCapability: notificationCapability
        )
    }
    
    override func tearDown() async throws {
        taskClient = nil
        notificationCapability = nil
        try await super.tearDown()
    }
    
    // MARK: - Due Date Setting
    
    func testCreateTaskWithDueDate() async throws {
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
        
        // Create task with due date tomorrow at 3 PM
        let tomorrow = Date().addingTimeInterval(86400)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        let dueDate = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: calendar.date(from: components)!)!
        
        let task = Task(
            id: "due-1",
            title: "Task with due date",
            description: "This task is due tomorrow at 3 PM",
            dueDate: dueDate
        )
        
        try await taskClient.process(.create(task))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        // Verify task was created with due date
        let createdTask = states.last!.tasks.first!
        XCTAssertEqual(createdTask.dueDate, dueDate)
    }
    
    func testUpdateTaskDueDate() async throws {
        // Create task without due date
        let task = Task(id: "due-2", title: "Update due date test")
        try await taskClient.process(.create(task))
        
        // Update with due date
        let dueDate = Date().addingTimeInterval(7200) // 2 hours from now
        let updatedTask = Task(
            id: "due-2",
            title: "Update due date test",
            dueDate: dueDate
        )
        
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 3 // Initial + create + update
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                expectation.fulfill()
                if states.count >= 3 {
                    break
                }
            }
        }
        
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        try await taskClient.process(.update(updatedTask))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        // Verify task was updated with due date
        let finalTask = states.last!.tasks.first!
        XCTAssertEqual(finalTask.dueDate, dueDate)
    }
    
    func testRemoveDueDate() async throws {
        // Create task with due date
        let dueDate = Date().addingTimeInterval(3600)
        let task = Task(id: "due-3", title: "Remove due date", dueDate: dueDate)
        try await taskClient.process(.create(task))
        
        // Update to remove due date
        let updatedTask = Task(id: "due-3", title: "Remove due date", dueDate: nil)
        
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        expectation.expectedFulfillmentCount = 3
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                expectation.fulfill()
                if states.count >= 3 {
                    break
                }
            }
        }
        
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        try await taskClient.process(.update(updatedTask))
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        // Verify due date was removed
        let finalTask = states.last!.tasks.first!
        XCTAssertNil(finalTask.dueDate)
    }
    
    // MARK: - Overdue Task Detection
    
    func testOverdueTasksAreIdentified() async throws {
        // Create tasks with various due dates
        let now = Date()
        let pastDue = now.addingTimeInterval(-3600) // 1 hour ago
        let dueSoon = now.addingTimeInterval(1800) // 30 minutes from now
        let futureDue = now.addingTimeInterval(86400) // Tomorrow
        
        let task1 = Task(id: "overdue-1", title: "Past due task", dueDate: pastDue)
        let task2 = Task(id: "overdue-2", title: "Due soon", dueDate: dueSoon)
        let task3 = Task(id: "overdue-3", title: "Future task", dueDate: futureDue)
        let task4 = Task(id: "overdue-4", title: "No due date")
        
        try await taskClient.process(.create(task1))
        try await taskClient.process(.create(task2))
        try await taskClient.process(.create(task3))
        try await taskClient.process(.create(task4))
        
        // Get overdue tasks
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                if states.count >= 5 { // Initial + 4 creates
                    expectation.fulfill()
                    break
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        let currentState = states.last!
        
        // Find overdue tasks manually (since computed property doesn't exist yet)
        let overdueTasks = currentState.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < now
        }
        
        XCTAssertEqual(overdueTasks.count, 1)
        XCTAssertEqual(overdueTasks.first?.id, "overdue-1")
    }
    
    // MARK: - Notification Scheduling
    
    func testNotificationScheduledForDueDate() async throws {
        // Create task with due date
        let dueDate = Date().addingTimeInterval(3600) // 1 hour from now
        let task = Task(
            id: "notify-1",
            title: "Task with notification",
            dueDate: dueDate
        )
        
        try await taskClient.process(.create(task))
        
        // Verify notification was scheduled
        try await SwiftTask.sleep(nanoseconds: 50_000_000) // 50ms to allow async operations
        
        let notifications = await notificationCapability.scheduledNotifications
        XCTAssertEqual(notifications.count, 1)
        
        let notification = notifications.first!
        XCTAssertEqual(notification.id, "task-due-notify-1")
        XCTAssertEqual(notification.title, "Task Due: Task with notification")
        XCTAssertEqual(notification.scheduledDate, dueDate)
    }
    
    func testNotificationCancelledWhenDueDateRemoved() async throws {
        // Create task with due date
        let dueDate = Date().addingTimeInterval(3600)
        let task = Task(id: "cancel-1", title: "Cancel notification", dueDate: dueDate)
        try await taskClient.process(.create(task))
        
        // Wait for notification to be scheduled
        try await SwiftTask.sleep(nanoseconds: 50_000_000)
        
        // Update to remove due date
        let updatedTask = Task(id: "cancel-1", title: "Cancel notification", dueDate: nil)
        try await taskClient.process(.update(updatedTask))
        
        // Wait for cancellation
        try await SwiftTask.sleep(nanoseconds: 50_000_000)
        
        // Verify notification was cancelled
        let cancelledIds = await notificationCapability.cancelledNotificationIds
        XCTAssertEqual(cancelledIds.count, 1)
        XCTAssertEqual(cancelledIds.first, "task-due-cancel-1")
    }
    
    // MARK: - Timezone Handling
    
    func testDueDatesStoredCorrectly() async throws {
        // Create task with specific due date
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        let utcDate = formatter.date(from: "2025-06-06T15:00:00Z")! // 3 PM UTC
        
        let task = Task(id: "tz-1", title: "Timezone test", dueDate: utcDate)
        
        try await taskClient.process(.create(task))
        
        // Get state and verify storage
        var states: [TaskListState] = []
        let expectation = XCTestExpectation(description: "State updates")
        
        let client = taskClient!
        SwiftTask.detached {
            for await state in await client.stateStream {
                states.append(state)
                if states.count >= 2 {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 0.5)
        
        let storedTask = states.last!.tasks.first!
        XCTAssertNotNil(storedTask.dueDate)
        
        // Verify the UTC date is preserved
        XCTAssertEqual(storedTask.dueDate?.timeIntervalSince1970, utcDate.timeIntervalSince1970)
    }
    
    // MARK: - Performance Tests
    
    func testDueDateOperationsPerformance() async throws {
        // Create 100 tasks with due dates
        let baseDueDate = Date()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<100 {
            let dueDate = baseDueDate.addingTimeInterval(Double(i) * 3600) // Each hour
            let task = Task(
                id: "perf-due-\(i)",
                title: "Task \(i)",
                dueDate: dueDate
            )
            try await taskClient.process(.create(task))
        }
        
        let createTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should handle 100 tasks with due dates efficiently
        XCTAssertLessThan(createTime, 1.0, "Creating 100 tasks with due dates should take less than 1 second")
    }
}

// Note: The following need to be added to the implementation:
// - Task already supports dueDate
// - Need to add notification scheduling in TaskClient
// - Need to handle due date updates and cancellations
// - Consider adding overdue status tracking