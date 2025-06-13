import XCTest
@testable import Axiom

/// Tests for REQUIREMENTS-W-02-002 Structured Concurrency Coordination Framework
final class StructuredConcurrencyCoordinationTests: XCTestCase {
    
    // MARK: - Task Hierarchy Management Tests
    
    func testTaskHierarchyTracking() async throws {
        // Test that parent-child task relationships are properly tracked
        let coordinator = StructuredTaskCoordinator()
        
        // Create parent task
        let parentTask = try await coordinator.createChildTask(
            name: "ParentTask",
            priority: .high
        ) {
            // Create child tasks within parent
            let child1 = try await coordinator.createChildTask(
                name: "ChildTask1",
                priority: .medium
            ) {
                try await Task.sleep(nanoseconds: 1_000_000) // 1ms
                return "Child1Result"
            }
            
            let child2 = try await coordinator.createChildTask(
                name: "ChildTask2",
                priority: .medium
            ) {
                try await Task.sleep(nanoseconds: 1_000_000) // 1ms
                return "Child2Result"
            }
            
            let result1 = try await child1.value
            let result2 = try await child2.value
            
            return "Parent: \(result1), \(result2)"
        }
        
        let result = try await parentTask.value
        XCTAssertEqual(result, "Parent: Child1Result, Child2Result")
        
        // Verify hierarchy was tracked
        let hierarchy = await coordinator.getTaskHierarchy()
        XCTAssertGreaterThan(hierarchy.count, 0)
    }
    
    func testCancellationPropagation() async throws {
        // Test that cancellation propagates from parent to children
        let coordinator = StructuredTaskCoordinator()
        var childCancelled = false
        
        let parentTask = try await coordinator.createChildTask(
            name: "ParentTask",
            priority: .high
        ) {
            try await coordinator.createChildTask(
                name: "ChildTask",
                priority: .medium
            ) {
                do {
                    try await Task.sleep(nanoseconds: 10_000_000_000) // 10s
                } catch {
                    childCancelled = true
                    throw error
                }
                return "Should not complete"
            }
            return "Parent"
        }
        
        // Cancel parent after short delay
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        parentTask.cancel()
        
        do {
            _ = try await parentTask.value
            XCTFail("Parent task should have been cancelled")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        
        // Wait briefly for propagation
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        XCTAssertTrue(childCancelled, "Child task should have been cancelled")
    }
    
    func testTaskCreationPerformance() async throws {
        // Test that task creation overhead is < 1μs
        let coordinator = StructuredTaskCoordinator()
        let iterations = 1000
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<iterations {
            _ = try await coordinator.createChildTask(
                name: "PerfTask\(i)",
                priority: .medium
            ) {
                return i
            }
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let averageCreationTime = duration / Double(iterations)
        
        // Assert < 1μs (0.000001s) average creation time
        XCTAssertLessThan(averageCreationTime, 0.000001, 
                          "Task creation overhead should be < 1μs, was \(averageCreationTime * 1_000_000)μs")
    }
    
    // MARK: - Concurrent Operation Coordination Tests
    
    func testCoordinatedTaskGroup() async throws {
        // Test enhanced task group with coordination
        let coordinator = StructuredTaskCoordinator()
        
        let results = try await withCoordinatedTaskGroup(
            of: Int.self,
            coordinator: coordinator,
            maxConcurrency: 3
        ) { group in
            for i in 0..<10 {
                await group.addTask(priority: .medium) {
                    try await Task.sleep(nanoseconds: 1_000_000) // 1ms
                    return i
                }
            }
            
            return try await group.waitForAll()
        }
        
        XCTAssertEqual(results.sorted(), Array(0..<10))
    }
    
    func testConcurrencyLimiter() async throws {
        // Test that concurrency limits are enforced
        let limiter = ConcurrencyLimiter(maxConcurrency: 2)
        var concurrentCount = 0
        var maxConcurrent = 0
        let lock = NSLock()
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await limiter.acquire()
                    
                    lock.lock()
                    concurrentCount += 1
                    maxConcurrent = max(maxConcurrent, concurrentCount)
                    lock.unlock()
                    
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    
                    lock.lock()
                    concurrentCount -= 1
                    lock.unlock()
                    
                    await limiter.release()
                }
            }
        }
        
        XCTAssertLessThanOrEqual(maxConcurrent, 2, 
                                 "Max concurrent tasks should not exceed limit")
    }
    
    func testTaskGroupWithTimeout() async throws {
        // Test task group with timeout functionality
        let coordinator = StructuredTaskCoordinator()
        
        do {
            _ = try await withCoordinatedTaskGroup(
                of: Int.self,
                coordinator: coordinator,
                timeout: Duration.milliseconds(50)
            ) { group in
                // Add task that takes too long
                await group.addTask {
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    return 1
                }
                
                return try await group.waitForAll()
            }
            
            XCTFail("Should have timed out")
        } catch {
            XCTAssertTrue(error is TimeoutError)
        }
    }
    
    // MARK: - Resource Management Tests
    
    func testResourceAwareExecution() async throws {
        // Test resource-aware task execution
        let executor = ResourceAwareExecutor()
        
        let resources: Set<ResourceRequirement> = [
            .memory(megabytes: 100),
            .cpu(cores: 2)
        ]
        
        let result = try await executor.executeWithResources(
            resources: resources,
            priority: .high
        ) {
            // Simulate work
            try await Task.sleep(nanoseconds: 1_000_000) // 1ms
            return "Completed with resources"
        }
        
        XCTAssertEqual(result, "Completed with resources")
    }
    
    func testResourceCleanupOnCancellation() async throws {
        // Test that resources are cleaned up when task is cancelled
        let executor = ResourceAwareExecutor()
        var resourcesReleased = false
        
        let task = Task {
            try await executor.executeWithResources(
                resources: [.memory(megabytes: 50)],
                onRelease: { resourcesReleased = true }
            ) {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                return "Should not complete"
            }
        }
        
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        task.cancel()
        
        do {
            _ = try await task.value
        } catch {
            // Expected cancellation
        }
        
        // Wait for cleanup
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        XCTAssertTrue(resourcesReleased, "Resources should be released on cancellation")
    }
    
    // MARK: - Error Coordination Tests
    
    func testErrorAggregation() async throws {
        // Test structured error aggregation
        let coordinator = StructuredTaskCoordinator()
        
        do {
            _ = try await withCoordinatedTaskGroup(
                of: Int.self,
                coordinator: coordinator
            ) { group in
                // Add tasks that will fail
                await group.addTask {
                    throw TestError.task1Failed
                }
                
                await group.addTask {
                    throw TestError.task2Failed
                }
                
                await group.addTask {
                    return 42 // One success
                }
                
                return try await group.waitForAll()
            }
            
            XCTFail("Should have thrown aggregated errors")
        } catch let error as ConcurrentErrors {
            XCTAssertEqual(error.errors.count, 2)
            XCTAssertTrue(error.errors.contains { $0.error is TestError })
        }
    }
    
    func testPartialFailureHandling() async throws {
        // Test handling of partial failures in concurrent operations
        let coordinator = StructuredTaskCoordinator()
        
        let results = try await withCoordinatedTaskGroup(
            of: Result<Int, Error>.self,
            coordinator: coordinator,
            failureMode: .partial
        ) { group in
            for i in 0..<5 {
                await group.addTask {
                    if i % 2 == 0 {
                        return .success(i)
                    } else {
                        return .failure(TestError.taskFailed(index: i))
                    }
                }
            }
            
            return await group.collectResults()
        }
        
        let successes = results.compactMap { try? $0.get() }
        let failures = results.compactMap { 
            if case .failure(let error) = $0 { return error }
            return nil
        }
        
        XCTAssertEqual(successes.sorted(), [0, 2, 4])
        XCTAssertEqual(failures.count, 2)
    }
    
    // MARK: - Lifecycle Management Tests
    
    func testTaskLifecycleEvents() async throws {
        // Test that lifecycle events are properly tracked
        let coordinator = StructuredTaskCoordinator()
        let observer = TestLifecycleObserver()
        
        await coordinator.addLifecycleObserver(observer)
        
        let task = try await coordinator.createChildTask(
            name: "LifecycleTest",
            priority: .medium
        ) {
            try await Task.sleep(nanoseconds: 1_000_000) // 1ms
            return "Done"
        }
        
        _ = try await task.value
        
        // Wait for events to be processed
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        let events = await observer.recordedEvents
        
        XCTAssertTrue(events.contains { 
            if case .created = $0 { return true }
            return false
        })
        
        XCTAssertTrue(events.contains {
            if case .completed = $0 { return true }
            return false
        })
    }
    
    func testGlobalTaskRegistry() async throws {
        // Test global task registry functionality
        let registry = GlobalTaskRegistry.shared
        let startCount = await registry.getActiveTaskCount()
        
        let coordinator = StructuredTaskCoordinator()
        
        let task = try await coordinator.createChildTask(
            name: "RegistryTest",
            priority: .medium
        ) {
            let midCount = await registry.getActiveTaskCount()
            XCTAssertGreaterThan(midCount, startCount)
            return "Registered"
        }
        
        _ = try await task.value
        
        // Wait for cleanup
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        let endCount = await registry.getActiveTaskCount()
        XCTAssertEqual(endCount, startCount)
    }
    
    // MARK: - Integration Tests
    
    func testIntegrationWithActorIsolation() async throws {
        // Test integration with existing actor isolation patterns
        let coordinator = StructuredTaskCoordinator()
        let router = MessageRouter()
        
        let actorID = ActorIdentifier(
            id: UUID(),
            name: "TestActor",
            type: "TestType"
        )
        
        let result = try await coordinator.createChildTask(
            name: "ActorIntegration",
            priority: .high
        ) {
            // Use existing actor patterns
            try await router.send(
                TestMessage(content: "Hello"),
                to: actorID,
                timeout: .seconds(1)
            )
            return "Integration successful"
        }
        
        XCTAssertEqual(try await result.value, "Integration successful")
    }
}

// MARK: - Test Support Types

private enum TestError: Error {
    case task1Failed
    case task2Failed
    case taskFailed(index: Int)
}

private actor TestLifecycleObserver: TaskLifecycleObserver {
    private(set) var recordedEvents: [TaskLifecycleEvent] = []
    
    func handleEvent(_ event: TaskLifecycleEvent) async {
        recordedEvents.append(event)
    }
}

private struct TestMessage: Sendable {
    let content: String
}

// MARK: - Expected Types (To be implemented)

// These types are expected to exist after implementation:
// - StructuredTaskCoordinator
// - CoordinatedTaskGroup  
// - ConcurrencyLimiter
// - ResourceAwareExecutor
// - ResourceRequirement
// - ConcurrentErrors
// - TaskLifecycleEvent
// - TaskLifecycleObserver
// - GlobalTaskRegistry
// - TimeoutError
// - withCoordinatedTaskGroup function
// - Additional coordination utilities