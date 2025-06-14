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
    
    // MARK: - Enhanced Actor Isolation Tests (W-02-001)
    
    func testIsolatedActorProtocolEnforcement() async {
        // Test that IsolatedActor protocol provides proper identification and validation
        let testActor = TestIsolatedActor(id: "test-actor", qos: .userInitiated)
        
        let actorID = await testActor.actorID
        XCTAssertEqual(actorID.name, "test-actor")
        XCTAssertEqual(actorID.type, "TestClient")
        
        let qos = await testActor.qualityOfService
        XCTAssertEqual(qos, .userInitiated)
        
        let policy = await testActor.reentrancyPolicy
        XCTAssertEqual(policy, .detectAndHandle)
        
        // Validate actor invariants
        do {
            try await testActor.validateActorInvariants()
        } catch {
            XCTFail("Actor invariants should be valid initially: \(error)")
        }
    }
    
    // MARK: - NEW W-02-001 Tests (RED Phase - These should initially fail)
    
    func testActorIdentifierUniqueness() async {
        // Test that each actor gets a unique identifier
        let actor1 = TestSafeActorClient(initialState: TestActorState(), actorName: "test1")
        let actor2 = TestSafeActorClient(initialState: TestActorState(), actorName: "test2")
        
        let id1 = await actor1.actorID
        let id2 = await actor2.actorID
        
        XCTAssertNotEqual(id1.id, id2.id, "Actor IDs should be unique")
        XCTAssertEqual(id1.name, "test1")
        XCTAssertEqual(id2.name, "test2")
        XCTAssertEqual(id1.type, "TestSafeActorClient")
        XCTAssertEqual(id2.type, "TestSafeActorClient")
    }
    
    func testActorMetricsCollection() async {
        // Test that actor metrics are properly collected
        let metrics = ActorMetrics()
        let actorID = ActorIdentifier(name: "test-metrics", type: "TestActor")
        
        // Record some calls
        await metrics.recordCall(actorID: actorID, duration: .milliseconds(1), wasReentrant: false)
        await metrics.recordCall(actorID: actorID, duration: .milliseconds(2), wasReentrant: true)
        await metrics.recordCall(actorID: actorID, duration: .milliseconds(3), wasReentrant: false)
        
        let snapshot = await metrics.getMetrics(for: actorID)
        
        XCTAssertEqual(snapshot.callCount, 3)
        XCTAssertEqual(snapshot.reentrancyRate, 1.0/3.0, accuracy: 0.01)
        XCTAssertGreaterThan(snapshot.averageCallDuration.components.attoseconds, 0)
    }
    
    func testMessageRouterRegistrationAndLookup() async {
        // Test that message router can register and find actors
        let router = MessageRouter()
        let actor = TestSafeActorClient(initialState: TestActorState(), actorName: "routed-actor")
        
        await router.register(actor)
        
        // Try to send a message (should find the actor)
        do {
            let result = try await router.send(
                "test-message",
                to: await actor.actorID,
                timeout: .milliseconds(100)
            )
            XCTAssertEqual(result, .delivered)
        } catch {
            XCTFail("Message delivery should succeed: \(error)")
        }
        
        // Try to send to non-existent actor
        let nonExistentID = ActorIdentifier(name: "missing", type: "Missing")
        do {
            _ = try await router.send("test", to: nonExistentID)
            XCTFail("Should throw actorNotFound error")
        } catch AxiomError.actorError(.actorNotFound(let id)) {
            XCTAssertEqual(id.name, "missing")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testReentrancyDetectionAndDenial() async {
        // Test that reentrancy is properly detected and can be denied
        let reentrancyGuard = ReentrancyGuard()
        let operation = OperationIdentifier(name: "test-operation")
        
        var firstCallCompleted = false
        var secondCallStarted = false
        
        // Start first operation
        let firstTask = Task {
            try await reentrancyGuard.executeWithGuard(
                policy: .deny,
                operation: operation
            ) {
                // Simulate some work
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                firstCallCompleted = true
            }
        }
        
        // Try to start the same operation (should be denied)
        let secondTask = Task {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
            secondCallStarted = true
            try await reentrancyGuard.executeWithGuard(
                policy: .deny,
                operation: operation
            ) {
                XCTFail("This should not execute due to reentrancy denial")
            }
        }
        
        // First task should complete
        try? await firstTask.value
        XCTAssertTrue(firstCallCompleted)
        
        // Second task should fail with reentrancy error
        do {
            try await secondTask.value
            XCTFail("Should have thrown reentrancy denied error")
        } catch AxiomError.actorError(.reentrancyDenied(let op)) {
            XCTAssertEqual(op.name, "test-operation")
            XCTAssertTrue(secondCallStarted)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testReentrancyAllowancePolicy() async {
        // Test that allow policy permits reentrancy
        let reentrancyGuard = ReentrancyGuard()
        let operation = OperationIdentifier(name: "allow-test")
        
        var executionCount = 0
        
        try await reentrancyGuard.executeWithGuard(
            policy: .allow,
            operation: operation
        ) {
            executionCount += 1
            
            // Recursive call (reentrancy)
            try await reentrancyGuard.executeWithGuard(
                policy: .allow,
                operation: operation
            ) {
                executionCount += 1
            }
        }
        
        XCTAssertEqual(executionCount, 2, "Both calls should execute with allow policy")
    }
    
    func testActorInvariantValidation() async {
        // Test that actor invariants are validated
        let actor = TestSafeActorClient(
            initialState: TestActorState(),
            actorName: "validation-test",
            stateValidator: TestStateValidator()
        )
        
        // Initial state should be valid
        do {
            try await actor.validateActorInvariants()
        } catch {
            XCTFail("Initial state should be valid: \(error)")
        }
        
        // Test with invalid state (this will require modifying the actor state)
        let invalidActor = TestSafeActorClient(
            initialState: TestActorState(counter: -1, isValid: false),
            actorName: "invalid-test",
            stateValidator: TestStateValidator()
        )
        
        do {
            try await invalidActor.validateActorInvariants()
            XCTFail("Should throw invariant violation for negative state")
        } catch AxiomError.actorError(.invariantViolation) {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testCrossActorCommunicationLatency() async {
        // Test that cross-actor communication meets performance targets
        let router = MessageRouter()
        let actor1 = TestSafeActorClient(initialState: TestActorState(), actorName: "sender")
        let actor2 = TestSafeActorClient(initialState: TestActorState(), actorName: "receiver")
        
        await router.register(actor1)
        await router.register(actor2)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Send 100 messages to measure average latency
        for i in 0..<100 {
            try await router.send(
                "message-\(i)",
                to: await actor2.actorID,
                timeout: .milliseconds(1)
            )
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let averageLatency = (endTime - startTime) / 100.0
        
        // Target: < 10μs for cross-actor communication
        XCTAssertLessThan(averageLatency, 0.00001, "Average latency should be < 10μs")
    }
    
    func testActorIsolationBoundaries() async {
        // Test that actor isolation boundaries are enforced
        let actor = TestSafeActorClient(initialState: TestActorState(counter: 42), actorName: "isolated-test")
        
        // Create isolated property
        @ActorIsolated(actor: actor)
        var isolatedValue = "test-value"
        
        // Access should be async
        let retrievedValue = await isolatedValue
        XCTAssertEqual(retrievedValue, "test-value")
        
        // Isolation info should reference the correct actor
        let isolationInfo = $isolatedValue
        XCTAssertTrue(isolationInfo.actor === actor)
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

// MARK: - Enhanced Actor Isolation Test Support (W-02-001)

actor TestIsolatedActor: IsolatedActor {
    typealias StateType = Int
    typealias ActionType = String
    typealias MessageType = TestActorMessage
    
    let actorID: ActorIdentifier
    let qualityOfService: DispatchQoS
    let reentrancyPolicy: ReentrancyPolicy = .detectAndHandle
    
    private(set) var counter: Int = 0
    
    init(id: String, qos: DispatchQoS) {
        self.actorID = ActorIdentifier(
            id: UUID(),
            name: id,
            type: "TestClient"
        )
        self.qualityOfService = qos
    }
    
    func validateActorInvariants() async throws {
        // Basic invariant validation
        guard counter >= 0 else {
            throw ActorError.invariantViolation("Counter cannot be negative")
        }
    }
    
    func handleMessage(_ message: TestActorMessage) async throws {
        // Handle test messages
    }
    
    func incrementCounter() {
        counter += 1
    }
}

struct TestActorMessage: ClientMessage {
    let source: MessageSource
    let content: String
    let timestamp: Date
    let correlationID: UUID
}

// MARK: - W-02-001 Test Support Types

/// Test state for actor testing
struct TestActorState: State {
    let counter: Int
    let isValid: Bool
    
    init(counter: Int = 0, isValid: Bool = true) {
        self.counter = counter
        self.isValid = isValid
    }
    
    func incrementCounter() -> TestActorState {
        TestActorState(counter: counter + 1, isValid: isValid)
    }
}

/// Test implementation of IsolatedActor for testing  
actor TestSafeActorClient: IsolatedActor {
    typealias StateType = TestActorState
    typealias ActionType = String
    typealias MessageType = TestActorMessage
    
    let actorID: ActorIdentifier
    let qualityOfService: DispatchQoS
    let reentrancyPolicy: ReentrancyPolicy = .detectAndHandle
    
    private var state: TestActorState
    private let stateValidator: TestStateValidator?
    
    init(
        initialState: TestActorState,
        actorName: String,
        qos: DispatchQoS = .userInitiated,
        stateValidator: TestStateValidator? = nil
    ) {
        self.state = initialState
        self.actorID = ActorIdentifier(id: UUID(), name: actorName, type: "TestSafeActorClient")
        self.qualityOfService = qos
        self.stateValidator = stateValidator
    }
    
    func handleMessage(_ message: TestActorMessage) async throws {
        // Handle test messages
    }
    
    func validateActorInvariants() async throws {
        try await stateValidator?.validate(state)
    }
    
    func getState() -> TestActorState {
        state
    }
}

/// Test state validator
struct TestStateValidator: StateValidator {
    func validate(_ state: TestActorState) async throws {
        guard state.counter >= 0 else {
            throw AxiomError.actorError(.invariantViolation("Counter cannot be negative"))
        }
        guard state.isValid else {
            throw AxiomError.actorError(.invariantViolation("State marked as invalid"))
        }
    }
    
    // MARK: - W-02-005 Client Isolation Enforcement Tests (RED Phase - These should initially fail)
    
    func testIsolatedClientProtocolEnforcement() async {
        // Test that IsolatedClient protocol provides proper isolation enforcement
        let testClient = TestIsolatedClientForW02005(
            clientID: ClientIdentifier("test-client-001", type: "TestClient"),
            allowedContexts: [ContextIdentifier("test-context")]
        )
        
        let clientID = await testClient.clientID
        XCTAssertEqual(clientID.id, "test-client-001")
        XCTAssertEqual(clientID.type, "TestClient")
        
        let isolationValidator = await testClient.isolationValidator
        XCTAssertNotNil(isolationValidator)
    }
    
    func testRuntimeIsolationVerification() async {
        // Test that runtime isolation verification detects violations
        let enforcer = IsolationEnforcer()
        let client1 = TestIsolatedClientForW02005(
            clientID: ClientIdentifier("client-001", type: "TestClient"),
            allowedContexts: [ContextIdentifier("context-A")]
        )
        let client2 = TestIsolatedClientForW02005(
            clientID: ClientIdentifier("client-002", type: "TestClient"),
            allowedContexts: [ContextIdentifier("context-B")]
        )
        
        // Register clients
        try await enforcer.registerClient(client1, allowedContexts: [ContextIdentifier("context-A")])
        try await enforcer.registerClient(client2, allowedContexts: [ContextIdentifier("context-B")])
        
        // Test authorized communication
        do {
            try await enforcer.validateCommunication(
                from: .context(ContextIdentifier("context-A")),
                to: client1.clientID
            )
            // Should succeed
        } catch {
            XCTFail("Authorized communication should not throw: \(error)")
        }
        
        // Test unauthorized communication
        do {
            try await enforcer.validateCommunication(
                from: .context(ContextIdentifier("context-A")),
                to: client2.clientID
            )
            XCTFail("Unauthorized communication should throw error")
        } catch IsolationError.unauthorizedClientContext(let context, let client) {
            XCTAssertEqual(context.id, "context-A")
            XCTAssertEqual(client.id, "client-002")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testContextMediatedCommunication() async {
        // Test that context-mediated communication routes messages properly
        let enforcer = IsolationEnforcer()
        let router = IsolatedCommunicationRouter(enforcer: enforcer)
        
        let testContext = ContextIdentifier("coordination-context")
        let client = TestIsolatedClientForW02005(
            clientID: ClientIdentifier("target-client", type: "TestClient"),
            allowedContexts: [testContext]
        )
        
        // Register client with router
        await router.registerClient(client, allowedContexts: [testContext])
        
        // Create test message
        let message = TestClientMessage(
            source: .context(testContext),
            content: "test-coordination-message",
            timestamp: Date(),
            correlationID: UUID()
        )
        
        // Route message through context
        do {
            try await router.routeMessage(
                message,
                to: client.clientID,
                from: testContext
            )
            
            // Verify message was received
            let receivedMessages = await client.getReceivedMessages()
            XCTAssertEqual(receivedMessages.count, 1)
            XCTAssertEqual(receivedMessages.first?.content, "test-coordination-message")
        } catch {
            XCTFail("Context-mediated communication should succeed: \(error)")
        }
    }
    
    func testMessageSourceValidation() async {
        // Test that message source validation works correctly
        let enforcer = IsolationEnforcer()
        let client = TestIsolatedClientForW02005(
            clientID: ClientIdentifier("validation-client", type: "TestClient"),
            allowedContexts: [ContextIdentifier("allowed-context")]
        )
        
        try await enforcer.registerClient(client, allowedContexts: [ContextIdentifier("allowed-context")])
        
        // Test allowed sources
        let allowedSources: [MessageSource] = [
            .context(ContextIdentifier("allowed-context")),
            .system,
            .test
        ]
        
        for source in allowedSources {
            do {
                try await enforcer.validateCommunication(from: source, to: client.clientID)
            } catch {
                XCTFail("Allowed source should not throw: \(source), error: \(error)")
            }
        }
        
        // Test forbidden source
        do {
            try await enforcer.validateCommunication(
                from: .context(ContextIdentifier("forbidden-context")),
                to: client.clientID
            )
            XCTFail("Forbidden context should throw error")
        } catch IsolationError.unauthorizedClientContext {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testIsolationViolationDetection() async {
        // Test that isolation violations are properly detected
        let enforcer = IsolationEnforcer()
        
        let client1 = TestIsolatedClientForW02005(
            clientID: ClientIdentifier("violating-client-1", type: "TestClient"),
            allowedContexts: []
        )
        let client2 = TestIsolatedClientForW02005(
            clientID: ClientIdentifier("violating-client-2", type: "TestClient"), 
            allowedContexts: []
        )
        
        // Set up client1 to reference client2 (violation)
        await client1.setDirectDependency(client2)
        
        try await enforcer.registerClient(client1, allowedContexts: [])
        try await enforcer.registerClient(client2, allowedContexts: [])
        
        // Detect violations
        let violations = await enforcer.detectViolations()
        
        XCTAssertGreaterThan(violations.count, 0, "Should detect client-to-client dependency violation")
        
        let directDependencyViolation = violations.first { violation in
            violation.violationType == .clientToClientDependency
        }
        XCTAssertNotNil(directDependencyViolation, "Should detect direct client dependency")
    }
    
    func testClientIsolationPerformanceTargets() async {
        // Test that isolation enforcement meets performance targets
        let enforcer = IsolationEnforcer()
        let client = TestIsolatedClientForW02005(
            clientID: ClientIdentifier("performance-client", type: "TestClient"),
            allowedContexts: [ContextIdentifier("perf-context")]
        )
        
        try await enforcer.registerClient(client, allowedContexts: [ContextIdentifier("perf-context")])
        
        // Test validation performance (target: < 1μs)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<1000 {
            try await enforcer.validateCommunication(
                from: .context(ContextIdentifier("perf-context")),
                to: client.clientID
            )
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let averageLatency = (endTime - startTime) / 1000.0
        
        // Target: < 1μs for dependency validation
        XCTAssertLessThan(averageLatency, 0.000001, "Isolation validation should be < 1μs")
    }
    
    func testClientBoundaryMacroEnforcement() async {
        // Test that ClientBoundary macro provides compile-time enforcement
        let client = TestIsolatedClientForW02005(
            clientID: ClientIdentifier("macro-client", type: "TestClient"),
            allowedContexts: []
        )
        
        // Verify client has boundary enforcement
        let hasBoundaryEnforcement = await client.hasBoundaryEnforcement
        XCTAssertTrue(hasBoundaryEnforcement, "ClientBoundary macro should provide enforcement")
        
        // Test that cross-client dependency wrapper fails
        do {
            let simpleValue = "not-a-client"
            let crossClientDep = try NoCrossClientDependency(wrappedValue: simpleValue)
            XCTAssertEqual(crossClientDep.wrappedValue, "not-a-client")
            
            // Test validation with client type would fail (but not directly testable due to generics)
        } catch {
            XCTFail("Simple values should be allowed: \(error)")
        }
    }
    
    func testIsolationTestFramework() async {
        // Test the isolation testing framework utilities
        let testContext = IsolationTestContext()
        let environment = await testContext.createIsolatedEnvironment()
        
        XCTAssertNotNil(environment.enforcer)
        XCTAssertNotNil(environment.router)
        XCTAssertNotNil(environment.violationDetector)
        
        // Test isolation between two clients
        let client1 = TestIsolatedClientForW02005(
            clientID: ClientIdentifier("iso-test-1", type: "TestClient"),
            allowedContexts: []
        )
        let client2 = TestIsolatedClientForW02005(
            clientID: ClientIdentifier("iso-test-2", type: "TestClient"),
            allowedContexts: []
        )
        
        do {
            try await testContext.testIsolation(client1: client1, client2: client2)
        } catch {
            XCTFail("Isolation test framework should work properly: \(error)")
        }
    }
}

// MARK: - W-02-005 Test Support Types (Using types from ConcurrencySafety.swift)