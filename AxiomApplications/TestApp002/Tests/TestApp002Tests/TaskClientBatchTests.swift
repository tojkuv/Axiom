import XCTest
@testable import TestApp002Core

final class TaskClientBatchTests: XCTestCase {
    
    // MARK: - Refactor Phase: Test batch operations performance
    
    func testBulkTaskCreation() async throws {
        let storageCapability = InMemoryStorageCapability()
        let networkCapability = MockNetworkCapability()
        let notificationCapability = MockNotificationCapability()
        
        let taskClient = TaskClient(
            userId: "test-user",
            storageCapability: storageCapability,
            networkCapability: networkCapability,
            notificationCapability: notificationCapability
        )
        let expectation = XCTestExpectation(description: "100 tasks created")
        
        // Create 100 tasks
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
        
        // Monitor state updates
        SwiftTask<Void, Never> {
            var iterator = await taskClient.stateStream.makeAsyncIterator()
            // Skip initial state
            _ = await iterator.next()
            
            // Wait for state with 100 tasks
            while let state = await iterator.next() {
                if state.tasks.count == 100 {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        // Give time for observer to start
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        // Process all tasks
        let startTime = CFAbsoluteTimeGetCurrent()
        for task in tasks {
            try await taskClient.process(.create(task))
        }
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete within reasonable time (less than 500ms for 100 tasks)
        XCTAssertLessThan(duration, 0.5, "Batch creation took too long: \(duration)s")
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testBulkTaskDeletion() async throws {
        let storageCapability = InMemoryStorageCapability()
        let networkCapability = MockNetworkCapability()
        let notificationCapability = MockNotificationCapability()
        
        let taskClient = TaskClient(
            userId: "test-user",
            storageCapability: storageCapability,
            networkCapability: networkCapability,
            notificationCapability: notificationCapability
        )
        
        // First, create 100 tasks
        let taskIds = (0..<100).map { "task-\($0)" }
        for id in taskIds {
            let task = Task(
                id: id,
                title: "Task to delete",
                description: "Will be deleted",
                dueDate: nil,
                categoryId: nil,
                priority: .low,
                isCompleted: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            try await taskClient.process(.create(task))
        }
        
        let expectation = XCTestExpectation(description: "All tasks deleted")
        
        // Monitor for empty state
        SwiftTask<Void, Never> {
            var iterator = await taskClient.stateStream.makeAsyncIterator()
            
            while let state = await iterator.next() {
                if state.tasks.isEmpty {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        // Delete all at once
        let startTime = CFAbsoluteTimeGetCurrent()
        try await taskClient.process(.deleteMultiple(taskIds: Set(taskIds)))
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete quickly (less than 100ms)
        XCTAssertLessThan(duration, 0.1, "Bulk deletion took too long: \(duration)s")
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}