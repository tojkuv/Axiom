import XCTest
@testable import TestApp002Core

// State Propagation Tests - REFACTOR Phase
// These tests verify advanced batching and change coalescing
class StatePropagationTestsRefactor: XCTestCase {
    var batchedUpdater: BatchedStateUpdater!
    var performanceMonitor: PerformanceMonitor!
    
    override func setUp() async throws {
        batchedUpdater = BatchedStateUpdater()
        performanceMonitor = PerformanceMonitor()
    }
    
    // MARK: - REFACTOR Phase Tests (Advanced optimization)
    
    func testChangeCoalescingEliminatesDuplicates() async throws {
        let coalescer = ChangeCoalescer<String>()
        
        // Add duplicate changes
        _ = await coalescer.addChange("update-1")
        _ = await coalescer.addChange("update-2")
        _ = await coalescer.addChange("update-1") // Duplicate
        _ = await coalescer.addChange("update-3")
        
        // Force processing by hitting batch size
        for i in 4..<20 {
            _ = await coalescer.addChange("update-\(i)")
        }
        
        let result = await coalescer.addChange("final")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.actions.count, 20) // Should have 20 unique actions
        
        // Verify no duplicates
        if let actions = result?.actions {
            let uniqueActions = Set(actions)
            XCTAssertEqual(uniqueActions.count, actions.count)
        }
    }
    
    func testTaskActionCoalescingOptimizesSequence() async throws {
        let coalescer = TaskActionCoalescer()
        
        // Add multiple updates to same task
        let task1 = Task(id: "task-1", title: "Version 1")
        let task1v2 = Task(id: "task-1", title: "Version 2")
        let task1v3 = Task(id: "task-1", title: "Version 3")
        
        _ = await coalescer.addAction(.create(task1))
        _ = await coalescer.addAction(.update(task1v2))
        _ = await coalescer.addAction(.update(task1v3))
        
        // Add search actions
        _ = await coalescer.addAction(.search(query: "test"))
        _ = await coalescer.addAction(.search(query: "final"))
        
        // Add sort actions
        _ = await coalescer.addAction(.sort(by: .createdDate))
        _ = await coalescer.addAction(.sort(by: .priority(ascending: false)))
        
        // Force processing
        for i in 0..<13 {
            _ = await coalescer.addAction(.create(Task(id: "filler-\(i)", title: "Filler")))
        }
        
        let optimized = await coalescer.addAction(.create(Task(title: "trigger")))
        
        XCTAssertNotNil(optimized)
        
        // Should have:
        // - Only latest version of task-1
        // - Only last search
        // - Only last sort
        let updateCount = optimized!.filter { action in
            if case .update(let task) = action {
                return task.id == "task-1"
            }
            return false
        }.count
        
        XCTAssertEqual(updateCount, 1, "Should only have one update for task-1")
        
        let searchCount = optimized!.filter { action in
            if case .search = action { return true }
            return false
        }.count
        
        XCTAssertEqual(searchCount, 1, "Should only have last search")
    }
    
    func testDeleteActionsRemoveCreatesAndUpdates() async throws {
        let coalescer = TaskActionCoalescer()
        
        // Create, update, then delete same task
        let task = Task(id: "doomed", title: "Will be deleted")
        _ = await coalescer.addAction(.create(task))
        _ = await coalescer.addAction(.update(task))
        _ = await coalescer.addAction(.delete(taskId: "doomed"))
        
        // Add other tasks
        for i in 0..<17 {
            _ = await coalescer.addAction(.create(Task(id: "survivor-\(i)", title: "Survives")))
        }
        
        let optimized = await coalescer.addAction(.create(Task(title: "trigger")))
        
        XCTAssertNotNil(optimized)
        
        // Should not have any create/update for "doomed"
        let doomedActions = optimized!.filter { action in
            switch action {
            case .create(let task), .update(let task):
                return task.id == "doomed"
            case .delete(let taskId):
                return taskId == "doomed"
            default:
                return false
            }
        }
        
        XCTAssertEqual(doomedActions.count, 1, "Should only have delete for doomed task")
        
        if case .delete(let taskId) = doomedActions.first {
            XCTAssertEqual(taskId, "doomed")
        } else {
            XCTFail("Expected delete action")
        }
    }
    
    func testBatchedStateUpdaterMaintains16ms() async throws {
        let storageCapability = MockStorageCapability()
        let networkCapability = MockNetworkCapability()
        let notificationCapability = MockNotificationCapability()
        
        let taskClient = TaskClient(
            userId: "test-user",
            storageCapability: storageCapability,
            networkCapability: networkCapability,
            notificationCapability: notificationCapability
        )
        
        // Rapid fire many actions
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<50 {
            try await batchedUpdater.processAction(
                .create(Task(id: "batch-\(i)", title: "Batch \(i)")),
                on: taskClient
            )
        }
        
        // Flush remaining
        try await batchedUpdater.flush(on: taskClient)
        
        let totalTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        print("Batched 50 actions in \(totalTime)ms")
        
        // Should complete quickly with batching
        XCTAssertLessThan(totalTime, 100.0, "Batched operations should be efficient")
        
        // Verify all tasks were created
        let finalState = await taskClient.currentState
        XCTAssertGreaterThanOrEqual(finalState.tasks.count, 50)
    }
    
    func testPerformanceMonitorTracksMetrics() async throws {
        // Simulate various propagation times
        await performanceMonitor.recordMetric(action: "create", duration: 5.0)
        await performanceMonitor.recordMetric(action: "update", duration: 8.0)
        await performanceMonitor.recordMetric(action: "delete", duration: 3.0)
        await performanceMonitor.recordMetric(action: "search", duration: 15.0)
        await performanceMonitor.recordMetric(action: "batch", duration: 12.0, batchSize: 10)
        
        // Add some slow operations
        await performanceMonitor.recordMetric(action: "slow", duration: 25.0)
        await performanceMonitor.recordMetric(action: "very-slow", duration: 50.0)
        
        let summary = await performanceMonitor.performanceSummary()
        
        print("Performance Summary - Avg: \(summary.average)ms, P95: \(summary.p95)ms, P99: \(summary.p99)ms")
        
        XCTAssertGreaterThan(summary.average, 0)
        XCTAssertGreaterThanOrEqual(summary.p95, summary.average)
        XCTAssertGreaterThanOrEqual(summary.p99, summary.p95)
        
        // Check metrics for specific action
        let searchMetrics = await performanceMonitor.metricsForAction("search")
        XCTAssertEqual(searchMetrics.count, 1)
        XCTAssertEqual(searchMetrics.first?.duration, 15.0)
    }
    
    func testCoalescingWindowPreventsExcessiveBatching() async throws {
        let coalescer = ChangeCoalescer<Int>(coalescingWindow: 0.001, maxBatchSize: 5)
        
        var results: [CoalescedChange<Int>] = []
        
        // Add changes that should trigger batching
        for i in 0..<5 {
            if let result = await coalescer.addChange(i) {
                results.append(result)
            }
        }
        
        XCTAssertEqual(results.count, 1, "Should batch when hitting max size")
        XCTAssertEqual(results.first?.actions.count, 5)
        
        // Add more to start new batch
        for i in 5..<8 {
            if let result = await coalescer.addChange(i) {
                results.append(result)
            }
        }
        
        // Should not have triggered yet (only 3 items)
        XCTAssertEqual(results.count, 1)
    }
    
    func testComplexWorkflowWithCoalescing() async throws {
        let storageCapability = MockStorageCapability()
        let networkCapability = MockNetworkCapability()
        let notificationCapability = MockNotificationCapability()
        
        let taskClient = TaskClient(
            userId: "test-user",
            storageCapability: storageCapability,
            networkCapability: networkCapability,
            notificationCapability: notificationCapability
        )
        
        // Simulate realistic user workflow
        let workflowStart = CFAbsoluteTimeGetCurrent()
        
        // User creates several tasks
        for i in 0..<5 {
            try await batchedUpdater.processAction(
                .create(Task(id: "new-\(i)", title: "New Task \(i)")),
                on: taskClient
            )
        }
        
        // User edits one multiple times
        let editedTask = Task(id: "new-1", title: "Edited Once")
        try await batchedUpdater.processAction(.update(editedTask), on: taskClient)
        
        let editedAgain = Task(id: "new-1", title: "Edited Twice")
        try await batchedUpdater.processAction(.update(editedAgain), on: taskClient)
        
        // User searches
        try await batchedUpdater.processAction(.search(query: "Task"), on: taskClient)
        try await batchedUpdater.processAction(.search(query: "New"), on: taskClient)
        
        // User sorts
        try await batchedUpdater.processAction(.sort(by: .priority(ascending: true)), on: taskClient)
        
        // Flush
        try await batchedUpdater.flush(on: taskClient)
        
        let workflowTime = (CFAbsoluteTimeGetCurrent() - workflowStart) * 1000
        
        print("Complex workflow completed in \(workflowTime)ms")
        
        // Should be efficient with coalescing
        XCTAssertLessThan(workflowTime, 50.0, "Workflow should complete quickly with coalescing")
        
        // Verify final state
        let finalState = await taskClient.currentState
        XCTAssertGreaterThanOrEqual(finalState.tasks.count, 5)
        
        // Check that edited task has final value
        let editedInState = finalState.tasks.first { $0.id == "new-1" }
        XCTAssertEqual(editedInState?.title, "Edited Twice")
    }
}