import XCTest
import Axiom
@testable import TestApp002Core

final class TaskClientTests: XCTestCase {
    var storageCapability: StorageCapability!
    var networkCapability: NetworkCapability!
    var notificationCapability: NotificationCapability!
    
    // MARK: - Red Phase: Test TaskClient actor initialization fails
    
    override func setUp() async throws {
        try await super.setUp()
        storageCapability = InMemoryStorageCapability()
        networkCapability = MockNetworkCapability()
        notificationCapability = MockNotificationCapability()
    }
    
    override func tearDown() async throws {
        storageCapability = nil
        networkCapability = nil
        notificationCapability = nil
        try await super.tearDown()
    }
    
    func testTaskClientInitialization() async throws {
        // This test should fail until we implement TaskClient
        let taskClient = TaskClient(
            userId: "test-user",
            storageCapability: storageCapability,
            networkCapability: networkCapability,
            notificationCapability: notificationCapability
        )
        
        // Verify it conforms to Client protocol
        XCTAssertNotNil(taskClient)
        
        // Verify state stream is available
        let stateStream = await taskClient.stateStream
        XCTAssertNotNil(stateStream)
    }
    
    func testTaskClientProcessesActions() async throws {
        // This test should fail until we implement action processing
        let taskClient = TaskClient(
            userId: "test-user",
            storageCapability: storageCapability,
            networkCapability: networkCapability,
            notificationCapability: notificationCapability
        )
        
        // Set up state observation first
        let expectation = XCTestExpectation(description: "State updated with new task")
        
        SwiftTask<Void, Never> {
            var iterator = await taskClient.stateStream.makeAsyncIterator()
            // Skip initial state
            _ = await iterator.next()
            
            // Wait for the state after task creation
            if let state = await iterator.next() {
                if state.tasks.count == 1 {
                    expectation.fulfill()
                }
            }
        }
        
        // Give the task time to start listening
        try await SwiftTask.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Try to process a create action
        let newTask = Task(
            id: UUID().uuidString,
            title: "Test Task",
            description: "Test Description",
            dueDate: nil,
            categoryId: nil,
            priority: .medium,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await taskClient.process(.create(newTask))
        
        // Wait for the expectation
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}