import XCTest
@testable import Axiom

/// Tests for REQUIREMENTS-W-02-003 Task Cancellation and Priority Handling Framework
final class TaskCancellationFrameworkTests: XCTestCase {
    
    // MARK: - Cancellation Token Tests
    
    func testCancellationTokenBasics() async throws {
        // Test basic cancellation token functionality
        let token = CancellationToken()
        
        var handlerExecuted = false
        let handlerID = await token.onCancellation {
            handlerExecuted = true
        }
        
        XCTAssertNotNil(handlerID)
        XCTAssertFalse(await token.isCancelled)
        XCTAssertFalse(handlerExecuted)
        
        // Cancel token
        await token.cancel()
        
        XCTAssertTrue(await token.isCancelled)
        
        // Wait briefly for handler execution
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        XCTAssertTrue(handlerExecuted)
    }
    
    func testFastCancellationPropagation() async throws {
        // Test that cancellation propagation meets < 10ms guarantee
        let token = CancellationToken()
        let handlerCount = 100
        var executedHandlers: [UUID] = []
        let executionLock = NSLock()
        
        // Register multiple handlers
        var handlerIDs: [UUID] = []
        for i in 0..<handlerCount {
            let id = await token.onCancellation(priority: .medium) {
                try? await Task.sleep(nanoseconds: 1_000_000) // 1ms each
                executionLock.lock()
                executedHandlers.append(UUID()) // Just track execution
                executionLock.unlock()
            }
            handlerIDs.append(id)
        }
        
        // Measure cancellation time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await token.cancel()
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert < 10ms (0.01s) cancellation time
        XCTAssertLessThan(duration, 0.01,
                          "Cancellation should complete within 10ms, took \(duration * 1000)ms")
        
        // Wait for all handlers to potentially complete
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // All handlers should have been started (some may timeout)
        let stats = await token.getCancellationStats()
        XCTAssertEqual(stats.totalHandlers, handlerCount)
        XCTAssertGreaterThan(stats.handlersExecuted, 0)
    }
    
    func testCancellationAcknowledgment() async throws {
        // Test cancellation acknowledgment protocol
        let token = CancellationToken()
        
        let handlerID = await token.onCancellation(requiresAcknowledgment: true) {
            // Simulate work that requires acknowledgment
            try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
        }
        
        // Cancel and wait for acknowledgment
        await token.cancel()
        
        // Should timeout if acknowledgment not received
        do {
            try await token.awaitAcknowledgments(timeout: .milliseconds(100))
            XCTFail("Should have timed out waiting for acknowledgment")
        } catch let error as CancellationError {
            switch error {
            case .acknowledgmentTimeout(let missing):
                XCTAssertTrue(missing.contains(handlerID))
            default:
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    // MARK: - Priority Task Tests
    
    func testPriorityTaskInheritance() async throws {
        // Test automatic priority boost and restore
        let task = PriorityTask(priority: .low) {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            return "completed"
        }
        
        // Boost priority
        await task.boostPriority(to: .high)
        
        let currentPriority = await task.getCurrentPriority()
        XCTAssertEqual(currentPriority, .high)
        
        // Restore priority
        await task.restorePriority()
        
        let restoredPriority = await task.getCurrentPriority()
        XCTAssertEqual(restoredPriority, .low)
        
        // Complete task
        let result = try await task.value
        XCTAssertEqual(result, "completed")
    }
    
    func testPriorityCoordination() async throws {
        // Test priority coordinator integration
        let coordinator = PriorityCoordinator.shared
        
        let task1 = PriorityTask(priority: .medium) {
            return 1
        }
        
        let task2 = PriorityTask(priority: .low) {
            return 2
        }
        
        // Boost task2 to prevent priority inversion
        await task2.boostPriority(to: .high)
        
        let stats = await coordinator.getPriorityStats()
        XCTAssertGreaterThan(stats.totalBoosts, 0)
        
        // Complete tasks
        let result1 = try await task1.value
        let result2 = try await task2.value
        
        XCTAssertEqual(result1, 1)
        XCTAssertEqual(result2, 2)
    }
    
    // MARK: - Checkpoint-Based Cancellation Tests
    
    func testCheckpointBasedCancellation() async throws {
        // Test checkpoint context for long operations
        let token = CancellationToken()
        var checkpointReached = false
        var operationCancelled = false
        
        let operation = CancellableOperation(token: token) { context in
            // Simulate long operation with checkpoints
            for i in 0..<10 {
                try await context.checkpoint("step_\(i)", saveState: i)
                checkpointReached = true
                
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms per step
            }
            
            return "completed"
        }
        
        // Start operation and cancel after short time
        let operationTask = Task {
            do {
                return try await operation.execute()
            } catch {
                operationCancelled = true
                throw error
            }
        }
        
        // Cancel after 25ms (should hit checkpoint)
        try await Task.sleep(nanoseconds: 25_000_000)
        await token.cancel()
        
        do {
            _ = try await operationTask.value
            XCTFail("Operation should have been cancelled")
        } catch {
            XCTAssertTrue(operationCancelled)
            XCTAssertTrue(checkpointReached)
        }
    }
    
    func testCheckpointRecovery() async throws {
        // Test state preservation and recovery at checkpoints
        let token = CancellationToken()
        var savedState: [String: Any] = [:]
        
        let operation = CancellableOperation(token: token) { context in
            // Save state at multiple checkpoints
            try await context.checkpoint("init", saveState: "initialized")
            try await context.checkpoint("progress", saveState: 50)
            try await context.checkpoint("final", saveState: ["key": "value"])
            
            return "completed"
        }
        
        do {
            _ = try await operation.execute()
        } catch let error as CancellationError {
            if case .cancelledAtCheckpoint(_, let state) = error {
                savedState = state
            }
        }
        
        // Verify state was preserved
        XCTAssertEqual(savedState["init"] as? String, "initialized")
        XCTAssertEqual(savedState["progress"] as? Int, 50)
        XCTAssertNotNil(savedState["final"])
    }
    
    func testCheckpointPerformance() async throws {
        // Test that checkpoint overhead is < 100ns
        let token = CancellationToken()
        let context = CheckpointContext(token: token)
        
        let iterations = 10000
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<iterations {
            try await context.checkpoint("perf_\(i)")
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let averageCheckpointTime = duration / Double(iterations)
        
        // Assert < 100ns (0.0000001s) average checkpoint time
        XCTAssertLessThan(averageCheckpointTime, 0.0000001,
                          "Checkpoint overhead should be < 100ns, was \(averageCheckpointTime * 1_000_000_000)ns")
    }
    
    // MARK: - Timeout Management Tests
    
    func testTimeoutManagement() async throws {
        // Test timeout manager with cancellation
        let timeoutManager = TimeoutManager()
        
        do {
            _ = try await timeoutManager.withTimeout(.milliseconds(50)) {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                return "should not complete"
            }
            XCTFail("Operation should have timed out")
        } catch let error as TimeoutError {
            XCTAssertEqual(error.duration, .milliseconds(50))
        }
    }
    
    func testTimeoutExtension() async throws {
        // Test dynamic timeout extension
        let timeoutManager = TimeoutManager()
        var operationCompleted = false
        
        let timeoutID = UUID()
        
        // Start operation with short timeout
        let operationTask = Task {
            try await timeoutManager.withTimeout(.milliseconds(30)) {
                try await Task.sleep(nanoseconds: 20_000_000) // 20ms
                
                // Extend timeout mid-operation
                try await timeoutManager.extendTimeout(for: timeoutID, by: .milliseconds(50))
                
                try await Task.sleep(nanoseconds: 40_000_000) // 40ms more
                operationCompleted = true
                return "completed with extension"
            }
        }
        
        let result = try await operationTask.value
        XCTAssertEqual(result, "completed with extension")
        XCTAssertTrue(operationCompleted)
    }
    
    func testTimeoutAccuracy() async throws {
        // Test timeout accuracy within 1ms tolerance
        let timeoutManager = TimeoutManager()
        let expectedTimeout: Duration = .milliseconds(100)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            _ = try await timeoutManager.withTimeout(expectedTimeout) {
                try await Task.sleep(nanoseconds: 200_000_000) // 200ms
                return "should timeout"
            }
            XCTFail("Should have timed out")
        } catch is TimeoutError {
            let actualTimeout = CFAbsoluteTimeGetCurrent() - startTime
            let tolerance = 0.001 // 1ms
            
            XCTAssertEqual(actualTimeout, expectedTimeout.seconds, accuracy: tolerance,
                           "Timeout should be accurate within 1ms")
        }
    }
    
    // MARK: - Cleanup Coordination Tests
    
    func testCleanupCoordination() async throws {
        // Test ordered cleanup execution
        let coordinator = CleanupCoordinator()
        var cleanupOrder: [String] = []
        let orderLock = NSLock()
        
        // Register cleanup handlers with different priorities
        _ = await coordinator.registerCleanup(name: "low", priority: 1) {
            orderLock.lock()
            cleanupOrder.append("low")
            orderLock.unlock()
        }
        
        _ = await coordinator.registerCleanup(name: "high", priority: 10) {
            orderLock.lock()
            cleanupOrder.append("high")
            orderLock.unlock()
        }
        
        _ = await coordinator.registerCleanup(name: "medium", priority: 5) {
            orderLock.lock()
            cleanupOrder.append("medium")
            orderLock.unlock()
        }
        
        // Execute cleanup
        await coordinator.executeCleanup()
        
        // Verify order (highest priority first)
        XCTAssertEqual(cleanupOrder, ["high", "medium", "low"])
    }
    
    func testGracefulCleanup() async throws {
        // Test error-safe cleanup execution
        let coordinator = CleanupCoordinator()
        var successfulCleanups: [String] = []
        let cleanupLock = NSLock()
        
        // Register cleanup handlers, some that will fail
        _ = await coordinator.registerCleanup(name: "success1", priority: 3) {
            cleanupLock.lock()
            successfulCleanups.append("success1")
            cleanupLock.unlock()
        }
        
        _ = await coordinator.registerCleanup(name: "failure", priority: 2) {
            throw TestError.cleanupFailed
        }
        
        _ = await coordinator.registerCleanup(name: "success2", priority: 1) {
            cleanupLock.lock()
            successfulCleanups.append("success2")
            cleanupLock.unlock()
        }
        
        // Execute cleanup - should continue despite failure
        await coordinator.executeCleanup()
        
        // Both successful cleanups should have executed
        XCTAssertTrue(successfulCleanups.contains("success1"))
        XCTAssertTrue(successfulCleanups.contains("success2"))
    }
    
    func testCleanupPerformance() async throws {
        // Test that cleanup completes within 50ms
        let coordinator = CleanupCoordinator()
        let handlerCount = 100
        
        // Register many cleanup handlers
        for i in 0..<handlerCount {
            _ = await coordinator.registerCleanup(name: "handler_\(i)") {
                try? await Task.sleep(nanoseconds: 100_000) // 0.1ms each
            }
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await coordinator.executeCleanup()
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert < 50ms (0.05s) cleanup time
        XCTAssertLessThan(duration, 0.05,
                          "Cleanup should complete within 50ms, took \(duration * 1000)ms")
    }
    
    // MARK: - Cancellable Operations Tests
    
    func testCancellableOperations() async throws {
        // Test CancellableOperation with checkpoints
        let token = CancellationToken()
        var stepsCompleted = 0
        
        let operation = CancellableOperation(token: token) { context in
            for step in 1...5 {
                try await context.checkpoint("step_\(step)")
                stepsCompleted = step
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms per step
            }
            return stepsCompleted
        }
        
        // Start operation and let it complete
        let result = try await operation.execute()
        
        XCTAssertEqual(result, 5)
        XCTAssertEqual(stepsCompleted, 5)
    }
    
    func testCancellableOperationCancellation() async throws {
        // Test cancellation of CancellableOperation
        let token = CancellationToken()
        var operationCancelled = false
        
        let operation = CancellableOperation(token: token) { context in
            for step in 1...10 {
                try await context.checkpoint("step_\(step)")
                try await Task.sleep(nanoseconds: 20_000_000) // 20ms per step
            }
            return "completed"
        }
        
        // Start operation
        let operationTask = Task {
            do {
                return try await operation.execute()
            } catch {
                operationCancelled = true
                throw error
            }
        }
        
        // Cancel after 50ms
        try await Task.sleep(nanoseconds: 50_000_000)
        await token.cancel()
        
        do {
            _ = try await operationTask.value
            XCTFail("Operation should have been cancelled")
        } catch {
            XCTAssertTrue(operationCancelled)
        }
    }
    
    // MARK: - Integration Tests
    
    func testIntegrationWithStructuredConcurrency() async throws {
        // Test integration with existing structured concurrency (W-02-002)
        let structuredCoordinator = StructuredTaskCoordinator()
        let cancellationToken = CancellationToken()
        
        // Create a structured task that uses cancellation
        let task = try await structuredCoordinator.createChildTask(
            name: "CancellableStructuredTask",
            priority: .medium
        ) {
            let operation = CancellableOperation(token: cancellationToken) { context in
                try await context.checkpoint("structured_start")
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                return "structured_completed"
            }
            
            return try await operation.execute()
        }
        
        // Cancel after short delay
        try await Task.sleep(nanoseconds: 30_000_000) // 30ms
        await cancellationToken.cancel()
        
        do {
            _ = try await task.value
            XCTFail("Task should have been cancelled")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        
        // Verify structured concurrency stats
        let stats = await structuredCoordinator.getPerformanceStats()
        XCTAssertGreaterThan(stats.totalTasksCreated, 0)
    }
    
    func testCancellationMetrics() async throws {
        // Test performance metrics collection
        let token = CancellationToken()
        
        // Register handlers and cancel
        for i in 0..<10 {
            _ = await token.onCancellation(priority: .medium) {
                try? await Task.sleep(nanoseconds: UInt64(i * 1_000_000)) // Variable delay
            }
        }
        
        await token.cancel()
        
        // Wait for completion
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        let stats = await token.getCancellationStats()
        XCTAssertEqual(stats.totalHandlers, 10)
        XCTAssertGreaterThan(stats.handlersExecuted, 0)
        XCTAssertLessThan(stats.averageCancellationTime.seconds, 0.01) // < 10ms
    }
    
    func testPriorityTaskPerformance() async throws {
        // Test priority switching performance < 1μs
        let task = PriorityTask(priority: .low) {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            return "completed"
        }
        
        let iterations = 1000
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<iterations {
            await task.boostPriority(to: .high)
            await task.restorePriority()
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let averageSwitchTime = duration / Double(iterations * 2) // boost + restore
        
        // Assert < 1μs (0.000001s) average switch time
        XCTAssertLessThan(averageSwitchTime, 0.000001,
                          "Priority switching should be < 1μs, was \(averageSwitchTime * 1_000_000)μs")
        
        task.cancel()
    }
    
    func testCancellationPropagationDepth() async throws {
        // Test cancellation propagation through task hierarchy
        let rootToken = CancellationToken()
        var cancelledTokens: [UUID] = []
        let cancelLock = NSLock()
        
        // Create nested cancellation hierarchy
        func createNestedCancellation(depth: Int, parentToken: CancellationToken) async -> CancellationToken {
            let childToken = CancellationToken()
            
            _ = await parentToken.onCancellation {
                await childToken.cancel()
                cancelLock.lock()
                cancelledTokens.append(childToken.id)
                cancelLock.unlock()
            }
            
            if depth > 0 {
                _ = await createNestedCancellation(depth: depth - 1, parentToken: childToken)
            }
            
            return childToken
        }
        
        // Create 5 levels of nesting
        _ = await createNestedCancellation(depth: 5, parentToken: rootToken)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Cancel root token
        await rootToken.cancel()
        
        // Wait for propagation
        try await Task.sleep(nanoseconds: 20_000_000) // 20ms
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should propagate through all levels within 10ms
        XCTAssertLessThan(duration, 0.01, "Hierarchical cancellation should complete within 10ms")
        XCTAssertGreaterThan(cancelledTokens.count, 0, "Child tokens should have been cancelled")
    }
}

// MARK: - Test Support Types

private enum TestError: Error {
    case cleanupFailed
    case operationFailed
}

// MARK: - Expected Types (To be implemented)

// These types are expected to exist after implementation:
// - CancellationToken
// - PriorityTask
// - CancellableOperation
// - CheckpointContext
// - TimeoutManager
// - CleanupCoordinator
// - CancellationError
// - TimeoutError
// - PriorityCoordinator
// - CancellationMetrics
// - CancellationStats
// - TaskPriority extensions