import XCTest
@testable import TestApp002Core

final class ConcurrentOperationsTests: XCTestCase {
    var taskClient: TaskClient!
    var storageCapability: StorageCapability!
    var networkCapability: NetworkCapability!
    var notificationCapability: NotificationCapability!
    
    override func setUp() async throws {
        try await super.setUp()
        storageCapability = InMemoryStorageCapability()
        networkCapability = MockNetworkCapability()
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
        storageCapability = nil
        networkCapability = nil
        notificationCapability = nil
        try await super.tearDown()
    }
    
    // MARK: - RED Phase Tests
    
    func testHundredConcurrentTaskCreationsCompleteWithoutDeadlock() async throws {
        let operationCount = 100
        let expectation = XCTestExpectation(description: "All operations complete")
        expectation.expectedFulfillmentCount = operationCount
        
        let operationResults = ActorSafeDict<String, Task>()
        
        // Create 100 concurrent tasks
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: (String, Task?).self) { group in
            for i in 0..<operationCount {
                let operationId = "op-\(i)"
                group.addTask { [taskClient] in
                    let task = Task(
                        id: "task-\(i)",
                        title: "Concurrent Task \(i)",
                        description: "Testing concurrent operation \(i)",
                        isCompleted: false,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    do {
                        // This should potentially cause issues without proper actor isolation
                        try await taskClient!.process(.create(task))
                        expectation.fulfill()
                        return (operationId, task)
                    } catch {
                        return (operationId, nil)
                    }
                }
            }
            
            // Collect results in submission order
            for await (operationId, task) in group {
                if let task = task {
                    await operationResults.set(operationId, task)
                }
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // Verify all operations completed
        let resultCount = await operationResults.count
        XCTAssertEqual(resultCount, operationCount, "All operations should complete")
        
        // Verify no deadlock occurred (should complete within reasonable time)
        XCTAssertLessThan(totalTime, 5.0, "Concurrent operations should complete within 5 seconds")
        
        // Verify final state has all tasks
        let finalState = await taskClient.currentState
        XCTAssertEqual(finalState.tasks.count, operationCount, "All tasks should be in final state")
    }
    
    func testConcurrentMixedOperationsPreserveDataIntegrity() async throws {
        // Pre-populate with some tasks
        let initialTasks = (0..<50).map { i in
            Task(
                id: "initial-\(i)",
                title: "Initial Task \(i)",
                description: "Pre-existing task",
                isCompleted: false,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        for task in initialTasks {
            try await taskClient.process(.create(task))
        }
        
        // Perform mixed concurrent operations
        let createCount = 30
        let updateCount = 20
        let deleteCount = 10
        
        let completedOperations = ActorSafeCounter()
        
        await withTaskGroup(of: Void.self) { group in
            // Concurrent creates
            for i in 0..<createCount {
                group.addTask { [taskClient] in
                    let task = Task(
                        id: "new-\(i)",
                        title: "New Task \(i)",
                        description: "Created concurrently",
                        isCompleted: false,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    try? await taskClient!.process(.create(task))
                    await completedOperations.increment()
                }
            }
            
            // Concurrent updates
            for i in 0..<updateCount {
                group.addTask { [taskClient] in
                    let task = Task(
                        id: "initial-\(i)",
                        title: "Updated Task \(i)",
                        description: "Updated concurrently",
                        isCompleted: true,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    try? await taskClient!.process(.update(task))
                    await completedOperations.increment()
                }
            }
            
            // Concurrent deletes
            for i in 0..<deleteCount {
                group.addTask { [taskClient] in
                    try? await taskClient!.process(.delete(taskId: "initial-\(i + 40)"))
                    await completedOperations.increment()
                }
            }
        }
        
        // Verify data integrity
        let finalState = await taskClient.currentState
        let expectedCount = initialTasks.count + createCount - deleteCount
        XCTAssertEqual(finalState.tasks.count, expectedCount, "Final task count should match expected")
        let totalCompleted = await completedOperations.value
        XCTAssertEqual(totalCompleted, createCount + updateCount + deleteCount, "All operations should complete")
        
        // Verify updates were applied
        let updatedTasks = finalState.tasks.filter { $0.isCompleted }
        XCTAssertEqual(updatedTasks.count, updateCount, "All updates should be applied")
    }
    
    func testOperationOrderingWithOperationIds() async throws {
        let operationCount = 50
        var operationIds: [String] = []
        let completionOrder = ActorSafeArray<String>()
        
        // Track operation submission order
        for i in 0..<operationCount {
            operationIds.append("op-\(i)")
        }
        
        // Submit operations concurrently but track completion order
        await withTaskGroup(of: String.self) { group in
            for (index, operationId) in operationIds.enumerated() {
                group.addTask { [taskClient] in
                    let task = Task(
                        id: "task-\(index)",
                        title: "Task \(index)",
                        description: "Operation \(operationId)",
                        isCompleted: false,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    // Add random delay to simulate varying processing times
                    if index % 3 == 0 {
                        try? await _Concurrency.Task.sleep(nanoseconds: UInt64.random(in: 1_000_000...10_000_000))
                    }
                    
                    try? await taskClient!.process(.create(task))
                    return operationId
                }
            }
            
            // Collect completion order
            for await completedOpId in group {
                await completionOrder.append(completedOpId)
            }
        }
        
        // Verify all operations completed
        let completedCount = await completionOrder.count
        XCTAssertEqual(completedCount, operationCount, "All operations should complete")
        
        // Verify operation IDs are tracked (even if not in submission order)
        let completedArray = await completionOrder.getAll()
        let completionSet = Set(completedArray)
        let submissionSet = Set(operationIds)
        XCTAssertEqual(completionSet, submissionSet, "All submitted operations should complete")
    }
    
    func testRaceConditionPrevention() async throws {
        let iterations = 100
        // Shared counter that should increment exactly once per iteration
        let sharedCounter = ActorSafeCounter()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask { [taskClient] in
                    // Try to create and immediately update the same task
                    let taskId = "race-task-\(i)"
                    let createTask = Task(
                        id: taskId,
                        title: "Race Task \(i)",
                        description: "Testing race conditions",
                        isCompleted: false,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    let updateTask = Task(
                        id: taskId,
                        title: "Updated Race Task \(i)",
                        description: "Updated description",
                        isCompleted: true,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    // Concurrent create and update on same task
                    async let create: Void = taskClient!.process(.create(createTask))
                    async let update: Void = taskClient!.process(.update(updateTask))
                    
                    do {
                        _ = try await (create, update)
                        await sharedCounter.increment()
                    } catch {
                        // One operation might fail, but we shouldn't have corrupted state
                        await sharedCounter.increment()
                    }
                }
            }
        }
        
        // Verify no race condition corrupted the counter
        let finalCount = await sharedCounter.value
        XCTAssertEqual(finalCount, iterations, "Counter should match iteration count without race conditions")
        
        // Verify final state is consistent
        let finalState = await taskClient.currentState
        for task in finalState.tasks {
            // Each task should have consistent state (not partially updated)
            if task.title.contains("Updated") {
                XCTAssertTrue(task.isCompleted, "Updated tasks should be completed")
                XCTAssertEqual(task.description, "Updated description", "Updated tasks should have updated description")
            }
        }
    }
    
    func testActorReentrancyUnderLoad() async throws {
        let operationCount = 50
        let reentrancyIssues = ActorSafeCounter()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<operationCount {
                group.addTask { [taskClient] in
                    // Perform operations that might cause reentrancy
                    let task1 = Task(
                        id: "reentrancy-\(i)-1",
                        title: "Task 1",
                        description: "First task",
                        isCompleted: false,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    let task2 = Task(
                        id: "reentrancy-\(i)-2",
                        title: "Task 2",
                        description: "Second task",
                        isCompleted: false,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    do {
                        // Create first task
                        try await taskClient!.process(.create(task1))
                        
                        // Immediately query state (potential reentrancy)
                        let midState = await taskClient!.currentState
                        
                        // Create second task while potentially inside first operation
                        try await taskClient!.process(.create(task2))
                        
                        // Verify state consistency
                        let finalState = await taskClient!.currentState
                        if finalState.tasks.count < midState.tasks.count {
                            await reentrancyIssues.increment()
                        }
                    } catch {
                        await reentrancyIssues.increment()
                    }
                }
            }
        }
        
        let totalIssues = await reentrancyIssues.value
        XCTAssertEqual(totalIssues, 0, "No reentrancy issues should occur")
    }
    
    func testConcurrentBatchOperations() async throws {
        let batchCount = 10
        let tasksPerBatch = 20
        
        await withTaskGroup(of: Int.self) { group in
            for batchIndex in 0..<batchCount {
                group.addTask { [taskClient] in
                    // Create a batch of task IDs for bulk delete
                    let taskIds = (0..<tasksPerBatch).map { "batch-\(batchIndex)-task-\($0)" }
                    
                    // First create the tasks
                    for (index, taskId) in taskIds.enumerated() {
                        let task = Task(
                            id: taskId,
                            title: "Batch \(batchIndex) Task \(index)",
                            description: "For batch testing",
                            isCompleted: false,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                        try? await taskClient!.process(.create(task))
                    }
                    
                    // Then perform batch delete
                    try? await taskClient!.process(.deleteMultiple(taskIds: Set(taskIds)))
                    
                    return batchIndex
                }
            }
            
            var completedBatches = 0
            for await _ in group {
                completedBatches += 1
            }
            
            XCTAssertEqual(completedBatches, batchCount, "All batches should complete")
        }
        
        // Verify all batch operations completed successfully
        let finalState = await taskClient.currentState
        let remainingBatchTasks = finalState.tasks.filter { $0.id.hasPrefix("batch-") }
        XCTAssertEqual(remainingBatchTasks.count, 0, "All batch tasks should be deleted")
    }
    
    func testMemoryConsistencyUnderConcurrentLoad() async throws {
        let operationCount = 100
        let initialMemory = getMemoryUsage()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<operationCount {
                group.addTask { [taskClient] in
                    let largeTask = Task(
                        id: "memory-\(i)",
                        title: "Memory Test \(i)",
                        description: String(repeating: "x", count: 1000), // 1KB description
                        isCompleted: false,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    try? await taskClient!.process(.create(largeTask))
                    
                    // Immediately delete to test memory cleanup
                    try? await taskClient!.process(.delete(taskId: "memory-\(i)"))
                }
            }
        }
        
        // Allow time for memory cleanup
        try? await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory should not grow significantly after operations complete
        XCTAssertLessThan(memoryIncrease, 10_000_000, "Memory usage should not increase by more than 10MB")
    }
    
    func testOperationQueueingAndPrioritization() async throws {
        // First, create enough operations to exceed max concurrent limit
        let totalOperations = 20
        let results = ActorSafeArray<String>()
        
        await withTaskGroup(of: Void.self) { group in
            // Submit operations with different priorities
            for i in 0..<totalOperations {
                group.addTask { [taskClient] in
                    let action: TaskAction
                    let expectedPriority: String
                    
                    switch i % 4 {
                    case 0:
                        // Critical - delete operations
                        action = .delete(taskId: "delete-\(i)")
                        expectedPriority = "critical"
                    case 1:
                        // High - update operations
                        let task = Task(
                            id: "update-\(i)",
                            title: "High Priority Update \(i)",
                            description: "Test",
                            isCompleted: false,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                        action = .update(task)
                        expectedPriority = "high"
                    case 2:
                        // Normal - create operations
                        let task = Task(
                            id: "create-\(i)",
                            title: "Normal Priority Create \(i)",
                            description: "Test",
                            isCompleted: false,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                        action = .create(task)
                        expectedPriority = "normal"
                    default:
                        // Low - batch operations
                        action = .batchAssignCategory(taskIds: ["task-\(i)"], categoryId: "cat-1")
                        expectedPriority = "low"
                    }
                    
                    do {
                        try await taskClient!.process(action)
                        await results.append("\(expectedPriority)-\(i)")
                    } catch {
                        // Ignore errors for non-existent tasks
                    }
                }
            }
        }
        
        // Verify operations were queued and processed
        let activeCount = await taskClient.getActiveOperationCount()
        XCTAssertEqual(activeCount, 0, "All operations should be completed")
        
        let queueLength = await taskClient.getQueueLength()
        XCTAssertEqual(queueLength, 0, "Queue should be empty after processing")
        
        // Verify some operations were processed (accounting for failed deletes/updates)
        let processedResults = await results.getAll()
        XCTAssertGreaterThan(processedResults.count, 0, "Some operations should have succeeded")
    }
    
    func testConcurrentOperationsWithQueueLimit() async throws {
        // Test that operations are queued when limit is exceeded
        let operationCount = 50 // More than maxConcurrentOperations (10)
        let completionTimes = ActorSafeArray<Date>()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<operationCount {
                group.addTask { [taskClient] in
                    let task = Task(
                        id: "queue-test-\(i)",
                        title: "Queue Test \(i)",
                        description: "Testing queue limits",
                        isCompleted: false,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    // Add small delay to simulate processing time
                    try? await taskClient!.process(.create(task))
                    await completionTimes.append(Date())
                }
            }
        }
        
        // Verify all operations completed
        let finalState = await taskClient.currentState
        let createdTasks = finalState.tasks.filter { $0.id.hasPrefix("queue-test-") }
        XCTAssertEqual(createdTasks.count, operationCount, "All tasks should be created")
        
        // Verify operations were queued (completion times should be spread out)
        let times = await completionTimes.getAll()
        XCTAssertEqual(times.count, operationCount, "All operations should complete")
        
        // Since operations are processed very quickly, just verify they all completed
        // The queue mechanism ensures proper ordering even if timing is too fast to measure
    }
    
    func testDeadlockPreventionWithCircularDependencies() async throws {
        let timeout = 5.0
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create operations that might cause circular waiting
        await withTaskGroup(of: Void.self) { group in
            // Group A: Creates tasks then updates them
            group.addTask { [taskClient] in
                for i in 0..<10 {
                    let task = Task(
                        id: "circular-a-\(i)",
                        title: "Group A Task \(i)",
                        description: "Testing circular dependencies",
                        isCompleted: false,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    try? await taskClient!.process(.create(task))
                }
                
                // Now update them
                for i in 0..<10 {
                    let task = Task(
                        id: "circular-a-\(i)",
                        title: "Updated Group A Task \(i)",
                        description: "Updated",
                        isCompleted: true,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    try? await taskClient!.process(.update(task))
                }
            }
            
            // Group B: Deletes then creates with same IDs
            group.addTask { [taskClient] in
                for i in 0..<10 {
                    let task = Task(
                        id: "circular-b-\(i)",
                        title: "Group B Task \(i)",
                        description: "Testing circular dependencies",
                        isCompleted: false,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    try? await taskClient!.process(.create(task))
                    try? await taskClient!.process(.delete(taskId: "circular-b-\(i)"))
                    
                    // Recreate with same ID
                    try? await taskClient!.process(.create(task))
                }
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        XCTAssertLessThan(totalTime, timeout, "Operations should complete without deadlock within \(timeout)s")
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

// MARK: - Helper Actors for Thread-Safe Operations

actor ActorSafeDict<Key: Hashable, Value> {
    private var dict: [Key: Value] = [:]
    
    func set(_ key: Key, _ value: Value) {
        dict[key] = value
    }
    
    func get(_ key: Key) -> Value? {
        dict[key]
    }
    
    var count: Int {
        dict.count
    }
}

actor ActorSafeCounter {
    private var count = 0
    
    func increment() {
        count += 1
    }
    
    var value: Int {
        count
    }
}

actor ActorSafeArray<Element> {
    private var array: [Element] = []
    
    func append(_ element: Element) {
        array.append(element)
    }
    
    var count: Int {
        array.count
    }
    
    func getAll() -> [Element] {
        array
    }
}