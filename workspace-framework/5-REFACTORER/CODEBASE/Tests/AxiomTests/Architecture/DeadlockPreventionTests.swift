import XCTest
@testable import Axiom

/// Tests for REQUIREMENTS-W-02-004 Deadlock Prevention and Detection System
final class DeadlockPreventionTests: XCTestCase {
    
    // MARK: - Resource Ordering Tests
    
    func testResourceOrdering() async throws {
        // Test that resources are assigned global ordering keys
        let resource1 = ResourceIdentifier(
            id: UUID(),
            type: .actor,
            orderingKey: 100
        )
        
        let resource2 = ResourceIdentifier(
            id: UUID(),
            type: .data,
            orderingKey: 200
        )
        
        let resource3 = ResourceIdentifier(
            id: UUID(),
            type: .io,
            orderingKey: 150
        )
        
        // Verify ordering comparison
        XCTAssertTrue(resource1 < resource3)
        XCTAssertTrue(resource3 < resource2)
        XCTAssertTrue(resource1 < resource2)
        
        // Verify ordering with same type
        let actorResource1 = ResourceIdentifier(id: UUID(), type: .actor, orderingKey: 50)
        let actorResource2 = ResourceIdentifier(id: UUID(), type: .actor, orderingKey: 75)
        XCTAssertTrue(actorResource1 < actorResource2)
    }
    
    func testResourceAcquisitionOrder() async throws {
        // Test that resources are acquired in order to prevent deadlocks
        let coordinator = DeadlockPreventionCoordinator()
        let actor = ActorIdentifier(id: UUID(), name: "TestActor", type: "Test")
        
        let resource1 = ResourceIdentifier(id: UUID(), type: .data, orderingKey: 100)
        let resource2 = ResourceIdentifier(id: UUID(), type: .io, orderingKey: 200)
        let resource3 = ResourceIdentifier(id: UUID(), type: .computation, orderingKey: 300)
        
        // Request resources in wrong order - should still acquire in correct order
        let resources: Set<ResourceIdentifier> = [resource3, resource1, resource2]
        
        let lease = try await coordinator.requestResources(
            resources,
            for: actor,
            timeout: .seconds(1)
        )
        
        XCTAssertEqual(lease.resources, resources)
        
        // Verify resources were acquired in order (lowest ordering key first)
        let acquisitionOrder = await coordinator.getAcquisitionOrder(for: actor)
        XCTAssertEqual(acquisitionOrder, [resource1, resource2, resource3])
        
        // Clean up
        await lease.release()
    }
    
    func testOrderingViolationPrevention() async throws {
        // Test that ordering violations are prevented
        let coordinator = DeadlockPreventionCoordinator()
        let actor = ActorIdentifier(id: UUID(), name: "TestActor", type: "Test")
        
        let highOrderResource = ResourceIdentifier(id: UUID(), type: .io, orderingKey: 300)
        let lowOrderResource = ResourceIdentifier(id: UUID(), type: .data, orderingKey: 100)
        
        // First acquire high-order resource
        let lease1 = try await coordinator.requestResources(
            [highOrderResource],
            for: actor,
            timeout: .seconds(1)
        )
        
        // Now try to acquire lower-order resource - should fail
        do {
            _ = try await coordinator.requestResources(
                [lowOrderResource],
                for: actor,
                timeout: .milliseconds(100)
            )
            XCTFail("Should have failed due to ordering violation")
        } catch let error as DeadlockError {
            switch error {
            case .orderingViolation:
                // Expected
                break
            default:
                XCTFail("Wrong error type: \(error)")
            }
        }
        
        await lease1.release()
    }
    
    // MARK: - Wait-For Graph Tests
    
    func testWaitForGraphConstruction() async throws {
        // Test that wait-for graph is constructed correctly
        let graph = WaitForGraph()
        
        let actor1 = ActorIdentifier(id: UUID(), name: "Actor1", type: "Test")
        let actor2 = ActorIdentifier(id: UUID(), name: "Actor2", type: "Test")
        let actor3 = ActorIdentifier(id: UUID(), name: "Actor3", type: "Test")
        
        let resource1 = ResourceIdentifier(id: UUID(), type: .data, orderingKey: 100)
        let resource2 = ResourceIdentifier(id: UUID(), type: .io, orderingKey: 200)
        
        // Actor2 owns resource1
        await graph.setOwnership(resource: resource1, owner: actor2)
        
        // Actor3 owns resource2  
        await graph.setOwnership(resource: resource2, owner: actor3)
        
        // Actor1 waits for resource1 (owned by actor2)
        await graph.addWaitingFor(actor: actor1, resources: [resource1])
        
        // Actor2 waits for resource2 (owned by actor3)
        await graph.addWaitingFor(actor: actor2, resources: [resource2])
        
        let graphEdges = await graph.getGraph()
        
        // Verify edges: actor1 -> actor2, actor2 -> actor3
        XCTAssertTrue(graphEdges[actor1]?.contains(actor2) == true)
        XCTAssertTrue(graphEdges[actor2]?.contains(actor3) == true)
        XCTAssertNil(graphEdges[actor3]) // actor3 doesn't wait for anyone
    }
    
    func testCycleDetection() async throws {
        // Test that cycles in wait-for graph are detected
        let detector = DeadlockDetector()
        let graph = WaitForGraph()
        
        let actor1 = ActorIdentifier(id: UUID(), name: "Actor1", type: "Test")
        let actor2 = ActorIdentifier(id: UUID(), name: "Actor2", type: "Test")
        let actor3 = ActorIdentifier(id: UUID(), name: "Actor3", type: "Test")
        
        let resource1 = ResourceIdentifier(id: UUID(), type: .data, orderingKey: 100)
        let resource2 = ResourceIdentifier(id: UUID(), type: .io, orderingKey: 200)
        let resource3 = ResourceIdentifier(id: UUID(), type: .computation, orderingKey: 300)
        
        // Create circular dependency:
        // actor1 owns resource1, waits for resource2
        // actor2 owns resource2, waits for resource3
        // actor3 owns resource3, waits for resource1
        await graph.setOwnership(resource: resource1, owner: actor1)
        await graph.setOwnership(resource: resource2, owner: actor2)
        await graph.setOwnership(resource: resource3, owner: actor3)
        
        await graph.addWaitingFor(actor: actor1, resources: [resource2])
        await graph.addWaitingFor(actor: actor2, resources: [resource3])
        await graph.addWaitingFor(actor: actor3, resources: [resource1])
        
        let cycle = await detector.detectCycle(in: graph)
        
        XCTAssertNotNil(cycle)
        XCTAssertEqual(cycle?.actors.count, 3)
        XCTAssertTrue(cycle?.actors.contains(actor1) == true)
        XCTAssertTrue(cycle?.actors.contains(actor2) == true)
        XCTAssertTrue(cycle?.actors.contains(actor3) == true)
    }
    
    func testCycleDetectionPerformance() async throws {
        // Test that cycle detection meets < 10μs performance target
        let detector = DeadlockDetector()
        let graph = WaitForGraph()
        
        // Create a larger graph with potential cycles
        var actors: [ActorIdentifier] = []
        var resources: [ResourceIdentifier] = []
        
        for i in 0..<20 {
            actors.append(ActorIdentifier(id: UUID(), name: "Actor\(i)", type: "Test"))
            resources.append(ResourceIdentifier(id: UUID(), type: .data, orderingKey: UInt64(i * 100)))
        }
        
        // Create complex wait patterns
        for i in 0..<20 {
            await graph.setOwnership(resource: resources[i], owner: actors[i])
            if i < 19 {
                await graph.addWaitingFor(actor: actors[i], resources: [resources[i + 1]])
            }
        }
        
        // Create cycle by having last actor wait for first resource
        await graph.addWaitingFor(actor: actors[19], resources: [resources[0]])
        
        let iterations = 1000
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<iterations {
            _ = await detector.detectCycle(in: graph)
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let averageDetectionTime = duration / Double(iterations)
        
        // Assert < 10μs (0.00001s) average detection time
        XCTAssertLessThan(averageDetectionTime, 0.00001,
                          "Cycle detection should be < 10μs, was \(averageDetectionTime * 1_000_000)μs")
    }
    
    // MARK: - Deadlock Prevention Tests
    
    func testDeadlockPreventionCoordinator() async throws {
        // Test that coordinator prevents deadlocks through ordering
        let coordinator = DeadlockPreventionCoordinator()
        
        let actor1 = ActorIdentifier(id: UUID(), name: "Actor1", type: "Test")
        let actor2 = ActorIdentifier(id: UUID(), name: "Actor2", type: "Test")
        
        let resource1 = ResourceIdentifier(id: UUID(), type: .data, orderingKey: 100)
        let resource2 = ResourceIdentifier(id: UUID(), type: .io, orderingKey: 200)
        
        // Simulate potential deadlock scenario
        // Actor1 requests resource1, then resource2
        // Actor2 requests resource2, then resource1
        // Without ordering, this could deadlock
        
        async let lease1: ResourceLease = coordinator.requestResources(
            [resource1, resource2],
            for: actor1,
            timeout: .seconds(1)
        )
        
        async let lease2: ResourceLease = coordinator.requestResources(
            [resource2, resource1],
            for: actor2,
            timeout: .seconds(1)
        )
        
        // Both should succeed without deadlock due to ordering
        let (finalLease1, finalLease2) = try await (lease1, lease2)
        
        XCTAssertEqual(finalLease1.resources.count, 2)
        XCTAssertEqual(finalLease2.resources.count, 2)
        
        await finalLease1.release()
        await finalLease2.release()
    }
    
    func testResourceLeaseManagement() async throws {
        // Test automatic resource cleanup through leases
        let coordinator = DeadlockPreventionCoordinator()
        let actor = ActorIdentifier(id: UUID(), name: "TestActor", type: "Test")
        
        let resource1 = ResourceIdentifier(id: UUID(), type: .data, orderingKey: 100)
        let resource2 = ResourceIdentifier(id: UUID(), type: .io, orderingKey: 200)
        
        let lease = try await coordinator.requestResources(
            [resource1, resource2],
            for: actor,
            timeout: .seconds(1)
        )
        
        // Verify resources are held
        let heldResources = await coordinator.getHeldResources(for: actor)
        XCTAssertEqual(heldResources, [resource1, resource2])
        
        // Release lease
        await lease.release()
        
        // Verify resources are released
        let heldAfterRelease = await coordinator.getHeldResources(for: actor)
        XCTAssertTrue(heldAfterRelease.isEmpty)
    }
    
    // MARK: - Recovery Mechanism Tests
    
    func testDeadlockRecovery() async throws {
        // Test deadlock recovery mechanisms
        let recovery = DeadlockRecovery()
        
        let actor1 = ActorIdentifier(id: UUID(), name: "Actor1", type: "Test")
        let actor2 = ActorIdentifier(id: UUID(), name: "Actor2", type: "Test")
        let actor3 = ActorIdentifier(id: UUID(), name: "Actor3", type: "Test")
        
        let resource1 = ResourceIdentifier(id: UUID(), type: .data, orderingKey: 100)
        let resource2 = ResourceIdentifier(id: UUID(), type: .io, orderingKey: 200)
        let resource3 = ResourceIdentifier(id: UUID(), type: .computation, orderingKey: 300)
        
        let cycle = DeadlockCycle(
            actors: [actor1, actor2, actor3],
            resources: [resource1, resource2, resource3]
        )
        
        // Recovery should succeed
        try await recovery.recoverFromDeadlock(cycle)
        
        // Verify recovery metrics are updated
        let stats = await recovery.getRecoveryStats()
        XCTAssertEqual(stats.totalRecoveries, 1)
        XCTAssertEqual(stats.successfulRecoveries, 1)
    }
    
    func testTransactionRollback() async throws {
        // Test transaction rollback for recovery
        let transactionLog = TransactionLog()
        let actor = ActorIdentifier(id: UUID(), name: "TestActor", type: "Test")
        
        let transactionID = await transactionLog.beginTransaction(for: actor)
        
        // Add some operations
        let operation1 = TestOperation(id: 1, rollbackAction: { print("Rollback 1") })
        let operation2 = TestOperation(id: 2, rollbackAction: { print("Rollback 2") })
        
        await transactionLog.addOperation(to: transactionID, operation: operation1)
        await transactionLog.addOperation(to: transactionID, operation: operation2)
        
        // Create checkpoint
        let checkpointID = await transactionLog.checkpoint(
            transactionID: transactionID,
            state: "Checkpoint State"
        )
        
        // Add more operations after checkpoint
        let operation3 = TestOperation(id: 3, rollbackAction: { print("Rollback 3") })
        await transactionLog.addOperation(to: transactionID, operation: operation3)
        
        // Rollback to checkpoint
        try await transactionLog.rollback(transactionID: transactionID, to: checkpointID)
        
        // Verify rollback occurred (implementation would track this)
        let transaction = await transactionLog.getTransaction(transactionID)
        XCTAssertNotNil(transaction)
    }
    
    // MARK: - Performance Tests
    
    func testGraphUpdatePerformance() async throws {
        // Test that graph updates meet < 1μs performance target
        let graph = WaitForGraph()
        
        let actor = ActorIdentifier(id: UUID(), name: "TestActor", type: "Test")
        let resource = ResourceIdentifier(id: UUID(), type: .data, orderingKey: 100)
        
        let iterations = 10000
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<iterations {
            await graph.addWaitingFor(actor: actor, resources: [resource])
            await graph.removeWaitingFor(actor: actor)
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let averageUpdateTime = duration / Double(iterations)
        
        // Assert < 1μs (0.000001s) average update time
        XCTAssertLessThan(averageUpdateTime, 0.000001,
                          "Graph updates should be < 1μs, was \(averageUpdateTime * 1_000_000)μs")
    }
    
    func testOrderValidationPerformance() async throws {
        // Test that resource order validation meets < 1μs target
        let coordinator = DeadlockPreventionCoordinator()
        
        let resources = (0..<100).map { i in
            ResourceIdentifier(id: UUID(), type: .data, orderingKey: UInt64(i * 100))
        }
        
        let iterations = 10000
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<iterations {
            let randomResources = Set(resources.shuffled().prefix(5))
            try await coordinator.validateResourceOrdering(randomResources, holding: [])
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let averageValidationTime = duration / Double(iterations)
        
        // Assert < 1μs validation time
        XCTAssertLessThan(averageValidationTime, 0.000001,
                          "Order validation should be < 1μs, was \(averageValidationTime * 1_000_000)μs")
    }
    
    // MARK: - Banker's Algorithm Tests
    
    func testBankersAlgorithm() async throws {
        // Test banker's algorithm for deadlock avoidance
        let banker = BankersAlgorithm()
        
        let actor1 = ActorIdentifier(id: UUID(), name: "Actor1", type: "Test")
        let actor2 = ActorIdentifier(id: UUID(), name: "Actor2", type: "Test")
        
        // Initialize system state
        await banker.setAvailable(resources: [.data: 10, .io: 5, .computation: 7])
        await banker.setMaximum(for: actor1, resources: [.data: 7, .io: 5, .computation: 3])
        await banker.setMaximum(for: actor2, resources: [.data: 3, .io: 2, .computation: 2])
        
        // Set current allocation
        await banker.setAllocation(for: actor1, resources: [.data: 0, .io: 1, .computation: 0])
        await banker.setAllocation(for: actor2, resources: [.data: 2, .io: 0, .computation: 0])
        
        // Test safe request
        let safeRequest = ResourceRequest(
            actor: actor1,
            resources: [.data: 2, .io: 0, .computation: 2]
        )
        
        let isSafe = await banker.isSafeState(after: safeRequest)
        XCTAssertTrue(isSafe, "Safe request should be approved")
        
        // Test unsafe request
        let unsafeRequest = ResourceRequest(
            actor: actor1,
            resources: [.data: 8, .io: 4, .computation: 3]
        )
        
        let isUnsafe = await banker.isSafeState(after: unsafeRequest)
        XCTAssertFalse(isUnsafe, "Unsafe request should be denied")
    }
    
    // MARK: - Integration Tests
    
    func testIntegrationWithActorSafety() async throws {
        // Test integration with existing actor isolation patterns
        let coordinator = DeadlockPreventionCoordinator()
        let messageRouter = MessageRouter()
        
        let actor1 = ActorIdentifier(id: UUID(), name: "Actor1", type: "Test")
        let actor2 = ActorIdentifier(id: UUID(), name: "Actor2", type: "Test")
        
        let resource = ResourceIdentifier(id: UUID(), type: .actor, orderingKey: 100)
        
        // Use deadlock prevention with actor communication
        let lease = try await coordinator.requestResources(
            [resource],
            for: actor1,
            timeout: .seconds(1)
        )
        
        // Send message using existing actor patterns
        try await messageRouter.send(
            TestMessage(content: "Hello"),
            to: actor2,
            timeout: .seconds(1)
        )
        
        await lease.release()
        
        // Verify no deadlocks occurred
        let detectionStats = await coordinator.getDetectionStats()
        XCTAssertEqual(detectionStats.deadlocksDetected, 0)
    }
    
    func testConcurrentDeadlockScenarios() async throws {
        // Test multiple concurrent scenarios that could cause deadlocks
        let coordinator = DeadlockPreventionCoordinator()
        
        let actors = (0..<10).map { i in
            ActorIdentifier(id: UUID(), name: "Actor\(i)", type: "Test")
        }
        
        let resources = (0..<10).map { i in
            ResourceIdentifier(id: UUID(), type: .data, orderingKey: UInt64(i * 100))
        }
        
        // Create concurrent resource requests that could deadlock
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    do {
                        // Each actor requests resources in different order
                        let actorResources = Set([
                            resources[i],
                            resources[(i + 1) % 10],
                            resources[(i + 2) % 10]
                        ])
                        
                        let lease = try await coordinator.requestResources(
                            actorResources,
                            for: actors[i],
                            timeout: .seconds(2)
                        )
                        
                        // Hold for a short time
                        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                        
                        await lease.release()
                    } catch {
                        XCTFail("Deadlock prevention should handle concurrent requests: \(error)")
                    }
                }
            }
        }
        
        // Verify no deadlocks occurred
        let stats = await coordinator.getDetectionStats()
        XCTAssertEqual(stats.deadlocksDetected, 0)
    }
}

// MARK: - Test Support Types

private struct TestMessage: Sendable {
    let content: String
}

private struct TestOperation: Operation {
    let id: Int
    let rollbackAction: () -> Void
    
    func rollback() async throws {
        rollbackAction()
    }
}

// MARK: - Expected Types (To be implemented)

// These types are expected to exist after implementation:
// - ResourceIdentifier
// - ResourceType
// - DeadlockPreventionCoordinator
// - WaitForGraph
// - DeadlockDetector
// - DeadlockCycle
// - ResourceLease
// - DeadlockRecovery
// - TransactionLog
// - BankersAlgorithm
// - DeadlockError
// - Operation
// - ResourceRequest
// - DetectionMetrics
// - RecoveryStats