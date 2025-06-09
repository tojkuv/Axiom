import XCTest
@testable import Axiom

final class ConcurrencySafetyTests: XCTestCase {
    // Test that no deadlocks occur when Clients call other Clients
    func testNoDeadlocksWithCrossActorCalls() async {
        let timeout = 1.0 // 1 second timeout as per RFC
        
        // Create multiple clients that will call each other
        let clientA = TestConcurrentClient(id: "A")
        let clientB = TestConcurrentClient(id: "B")
        let clientC = TestConcurrentClient(id: "C")
        
        // Set up circular dependencies for potential deadlock
        await clientA.setDependency(clientB)
        await clientB.setDependency(clientC)
        await clientC.setDependency(clientA)
        
        // Attempt concurrent cross-actor calls
        let startTime = Date()
        
        await withTaskGroup(of: Void.self) { group in
            // Client A calls B which calls C which calls A
            group.addTask {
                await clientA.performCrossActorOperation()
            }
            
            // Client B calls C which calls A which calls B
            group.addTask {
                await clientB.performCrossActorOperation()
            }
            
            // Client C calls A which calls B which calls C
            group.addTask {
                await clientC.performCrossActorOperation()
            }
            
            await group.waitForAll()
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Should complete without deadlock within timeout
        XCTAssertLessThan(elapsed, timeout, "Cross-actor calls took too long, possible deadlock")
        
        // Verify all operations completed
        let countA = await clientA.operationCount
        let countB = await clientB.operationCount
        let countC = await clientC.operationCount
        
        XCTAssertGreaterThan(countA, 0)
        XCTAssertGreaterThan(countB, 0)
        XCTAssertGreaterThan(countC, 0)
    }
    
    // Test stress scenario with 10 actors making cross-actor calls
    func testStressTestWith10Actors() async {
        let actorCount = 10
        let timeout = 1.0 // 1 second timeout as per RFC
        
        // Create 10 clients
        let clients = (0..<actorCount).map { TestConcurrentClient(id: "Client-\($0)") }
        
        // Set up dependencies in a ring (each depends on the next)
        for i in 0..<actorCount {
            let nextIndex = (i + 1) % actorCount
            await clients[i].setDependency(clients[nextIndex])
        }
        
        let startTime = Date()
        
        // All actors make concurrent calls
        await withTaskGroup(of: Void.self) { group in
            for client in clients {
                group.addTask {
                    // Each client performs multiple operations
                    for _ in 0..<5 {
                        await client.performCrossActorOperation()
                    }
                }
            }
            
            await group.waitForAll()
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Should complete within 1 second
        XCTAssertLessThan(elapsed, timeout, "Stress test exceeded 1 second timeout")
        
        // Verify all actors completed their operations
        for client in clients {
            let count = await client.operationCount
            XCTAssertGreaterThanOrEqual(count, 5, "Client did not complete all operations")
        }
    }
    
    // Test that actor methods validate preconditions after await points
    func testActorReentrancyHandling() async {
        let client = TestConcurrentClient(id: "reentrancy-test")
        
        // Start a long-running operation
        let task1 = Task {
            await client.performLongOperation(duration: 0.1)
        }
        
        // Immediately try to modify state
        let task2 = Task {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            await client.modifyState()
        }
        
        // Wait for both to complete
        await task1.value
        await task2.value
        
        // Verify state remains consistent despite reentrancy
        let state = await client.currentState
        XCTAssertTrue(state.isConsistent, "State became inconsistent due to reentrancy")
        XCTAssertGreaterThan(state.version, 0, "State version should have incremented")
    }
    
    // Test task cancellation propagation
    @MainActor
    func testTaskCancellationPropagation() async {
        let context = TestConcurrentContext(id: "test-context")
        let childClients = (0..<5).map { TestConcurrentClient(id: "child-\($0)") }
        
        // Register child clients with context
        for (index, child) in childClients.enumerated() {
            context.registerClient("child-\(index)")
        }
        
        // Start context task that will be cancelled
        let contextTask = context.startTask {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            } catch {
                // Task was cancelled
            }
        }
        
        // Register and start child tasks with cancellation coordinator
        let childTasks: [Task<Void, Never>] = await withTaskGroup(of: Task<Void, Never>.self) { group in
            for (index, client) in childClients.enumerated() {
                group.addTask {
                    let task = Task {
                        await client.performCancellableOperation(duration: 1.0)
                    }
                    await TaskCancellationCoordinator.shared.registerClientTask(task, for: "child-\(index)", context: "test-context")
                    return task
                }
            }
            
            var tasks: [Task<Void, Never>] = []
            for await task in group {
                tasks.append(task)
            }
            return tasks
        }
        
        // Cancel context after short delay
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            contextTask.cancel()
        }
        
        // Wait for context task
        await contextTask.value
        
        // All child tasks should be cancelled quickly
        let startTime = Date()
        for task in childTasks {
            await task.value
        }
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Allow more time as actual cancellation propagation takes some time
        XCTAssertLessThan(elapsed, 0.1, "Child task cancellation took too long")
        
        // Verify all were cancelled
        for child in childClients {
            let cancelled = await child.wasCancelled
            XCTAssertTrue(cancelled, "Child task should have been cancelled")
        }
    }
    
    // Test priority inversion scenarios
    func testPriorityInversionMitigation() async {
        let highPriorityClient = TestConcurrentClient(id: "high-priority")
        let lowPriorityClient = TestConcurrentClient(id: "low-priority")
        let sharedResource = SharedResourceActor()
        
        // Low priority client acquires resource first
        let lowPriorityTask = Task(priority: .low) {
            await lowPriorityClient.acquireResource(sharedResource, holdDuration: 0.2)
        }
        
        // High priority client tries to acquire same resource
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
        
        let highPriorityStart = Date()
        let highPriorityTask = Task(priority: .high) {
            await highPriorityClient.acquireResource(sharedResource, holdDuration: 0.05)
        }
        
        await lowPriorityTask.value
        await highPriorityTask.value
        
        let highPriorityWaitTime = Date().timeIntervalSince(highPriorityStart)
        
        // High priority task should not be blocked excessively
        // With priority inheritance, wait time should be reasonable
        XCTAssertLessThan(highPriorityWaitTime, 0.3, "High priority task waited too long due to priority inversion")
        
        // Verify both completed successfully
        let lowCompleted = await lowPriorityClient.operationCount
        let highCompleted = await highPriorityClient.operationCount
        
        XCTAssertEqual(lowCompleted, 1)
        XCTAssertEqual(highCompleted, 1)
    }
    
    // Test concurrent state mutations produce consistent final state
    func testConcurrentStateMutationsConsistency() async {
        let client = TestConcurrentClient(id: "mutation-test")
        let mutationCount = 1000
        
        // Perform 1000 concurrent mutations
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<mutationCount {
                group.addTask {
                    await client.incrementCounter(by: 1)
                }
            }
            
            await group.waitForAll()
        }
        
        // Verify final state is consistent
        let state = await client.currentState
        XCTAssertEqual(state.counter, mutationCount, "Concurrent mutations resulted in inconsistent state")
        XCTAssertEqual(state.version, mutationCount, "Version count doesn't match mutation count")
        XCTAssertTrue(state.isConsistent, "State marked as inconsistent")
    }
}

// MARK: - Test Support Types

actor TestConcurrentClient {
    let id: String
    private(set) var operationCount = 0
    private(set) var wasCancelled = false
    private var dependency: TestConcurrentClient?
    private var children: [TestConcurrentClient] = []
    private var state = ConcurrentState()
    
    var currentState: ConcurrentState {
        state
    }
    
    init(id: String) {
        self.id = id
    }
    
    func setDependency(_ client: TestConcurrentClient) {
        self.dependency = client
    }
    
    func addChild(_ client: TestConcurrentClient) {
        children.append(client)
    }
    
    func performCrossActorOperation() async {
        operationCount += 1
        
        // Call dependency if exists
        if let dependency = dependency {
            // Add small delay to increase chance of contention
            try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
            await dependency.receiveCall(from: id)
        }
    }
    
    func receiveCall(from callerId: String) async {
        // Simulate some work
        operationCount += 1
    }
    
    func performLongOperation(duration: TimeInterval) async {
        let startState = state.version
        
        // Simulate long operation with await point
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        
        // Validate state after await
        if state.version != startState {
            // State changed during operation, handle gracefully
            state.isConsistent = state.counter == state.version
        }
        
        operationCount += 1
    }
    
    func modifyState() async {
        state.version += 1
        state.counter += 1
        state.isConsistent = true
    }
    
    func performCancellableOperation(duration: TimeInterval) async {
        do {
            try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            operationCount += 1
        } catch {
            wasCancelled = true
            // Propagate cancellation to children
            await withTaskGroup(of: Void.self) { group in
                for child in children {
                    group.addTask {
                        await child.cancelOperation()
                    }
                }
            }
        }
    }
    
    func cancelOperation() {
        wasCancelled = true
    }
    
    func acquireResource(_ resource: SharedResourceActor, holdDuration: TimeInterval) async {
        await resource.acquire(clientId: id)
        
        // Hold resource for specified duration
        try? await Task.sleep(nanoseconds: UInt64(holdDuration * 1_000_000_000))
        
        await resource.release(clientId: id)
        operationCount += 1
    }
    
    func incrementCounter(by value: Int) async {
        // Validate precondition
        precondition(state.isConsistent, "State must be consistent before mutation")
        
        state.counter += value
        state.version += 1
        
        // Ensure consistency after mutation
        state.isConsistent = state.counter <= state.version
    }
}

struct ConcurrentState {
    var version: Int = 0
    var counter: Int = 0
    var isConsistent: Bool = true
}

actor SharedResourceActor {
    private var currentHolder: String?
    private var waitingQueue: [String] = []
    
    func acquire(clientId: String) async {
        if currentHolder != nil {
            waitingQueue.append(clientId)
            
            // Wait until resource is available
            while currentHolder != nil && currentHolder != clientId {
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }
        
        currentHolder = clientId
    }
    
    func release(clientId: String) {
        guard currentHolder == clientId else { return }
        
        currentHolder = nil
        
        // Grant to next waiter if any
        if !waitingQueue.isEmpty {
            currentHolder = waitingQueue.removeFirst()
        }
    }
}

// Test concurrent context using framework's base class
@MainActor
class TestConcurrentContext: ConcurrentContext {
    // Inherits all functionality from ConcurrentContext
}