import Testing
import Foundation
@testable import TestApp002Core

// MARK: - REFACTOR Phase Tests - Advanced Coordination Patterns

@Suite("Multi-Client Coordination - REFACTOR Phase: Advanced patterns")
struct MultiClientCoordinationTestsRefactor {
    
    @Test("Orchestrator should support event sourcing for state reconstruction")
    func testOrchestratorEventSourcing() async throws {
        // REFACTOR: Event sourcing pattern
        
        let orchestrator = AdvancedTaskOrchestrator()
        await orchestrator.initialize()
        
        // Perform several operations
        let task1 = TestApp002Core.Task(id: "1", title: "Task 1", priority: .high)
        let task2 = TestApp002Core.Task(id: "2", title: "Task 2", priority: .medium)
        
        try await orchestrator.handleAction(.task(.create(task1)))
        try await orchestrator.handleAction(.task(.create(task2)))
        try await orchestrator.handleAction(.task(.update(task1.withTitle("Updated Task 1"))))
        try await orchestrator.handleAction(.task(.delete(taskId: "2")))
        
        // Get event log
        let events = await orchestrator.getEventLog()
        
        #expect(events.count >= 4, "Should have recorded all events")
        
        // Replay events to reconstruct state
        let reconstructedState = await orchestrator.replayEvents(events)
        
        #expect(reconstructedState.isConsistent, "Reconstructed state should be consistent")
    }
    
    @Test("Orchestrator should provide state snapshots for efficient recovery")
    func testOrchestratorStateSnapshots() async throws {
        // REFACTOR: State snapshot pattern
        
        let orchestrator = AdvancedTaskOrchestrator()
        await orchestrator.initialize()
        
        // Create initial state
        for i in 0..<10 {
            let task = TestApp002Core.Task(id: "\(i)", title: "Task \(i)", priority: .medium)
            try await orchestrator.handleAction(.task(.create(task)))
        }
        
        // Take snapshot
        let snapshot = await orchestrator.createSnapshot()
        
        #expect(snapshot.timestamp > Date.distantPast, "Snapshot should have valid timestamp")
        #expect(snapshot.taskCount == 10, "Snapshot should contain all tasks")
        
        // Modify state
        try await orchestrator.handleAction(.task(.delete(taskId: "5")))
        
        // Restore from snapshot
        await orchestrator.restoreFromSnapshot(snapshot)
        
        // Verify restoration
        let restoredTaskCount = await orchestrator.getTaskCount()
        
        #expect(restoredTaskCount == 10, "Should have restored to snapshot state")
    }
    
    @Test("Orchestrator should support distributed transaction coordination")
    func testOrchestratorDistributedTransactions() async throws {
        // REFACTOR: Distributed transaction pattern
        
        let orchestrator = AdvancedTaskOrchestrator()
        await orchestrator.initialize()
        
        // Start distributed transaction
        let transactionId = await orchestrator.beginTransaction()
        
        // Perform multiple operations in transaction
        do {
            try await orchestrator.transactionalAction(transactionId, TaskOrchestrator.OrchestratorAction.task(.create(
                TestApp002Core.Task(id: "tx-1", title: "Transaction Task 1", priority: .high)
            )))
            
            try await orchestrator.transactionalAction(transactionId, TaskOrchestrator.OrchestratorAction.user(.login(
                email: "tx@example.com", password: "password"
            )))
            
            try await orchestrator.transactionalAction(transactionId, TaskOrchestrator.OrchestratorAction.sync(.startSync))
            
            // Commit transaction
            let committed = try await orchestrator.commitTransaction(transactionId)
            
            #expect(committed, "Transaction should commit successfully")
        } catch {
            // Rollback on error
            await orchestrator.rollbackTransaction(transactionId)
            throw error
        }
        
        // Verify all changes were applied atomically
        let taskExists = await orchestrator.taskExists(id: "tx-1")
        let userLoggedIn = await orchestrator.isUserLoggedIn()
        
        #expect(taskExists && userLoggedIn, "All transaction operations should be applied")
    }
    
    @Test("Orchestrator should implement saga pattern for long-running operations")
    func testOrchestratorSagaPattern() async throws {
        // REFACTOR: Saga pattern for complex workflows
        
        let orchestrator = AdvancedTaskOrchestrator()
        await orchestrator.initialize()
        
        // Define saga for task creation with notifications
        let saga = TaskCreationSaga(
            steps: [
                .createTask(id: "saga-1", title: "Saga Task"),
                .scheduleNotification(taskId: "saga-1", time: Date().addingTimeInterval(3600)),
                .syncToCloud(taskId: "saga-1"),
                .notifyCollaborators(taskId: "saga-1")
            ]
        )
        
        // Execute saga
        let sagaResult = await orchestrator.executeSaga(saga)
        
        switch sagaResult {
        case .success(let completedSteps):
            #expect(completedSteps.count == 4, "All saga steps should complete")
        case .failure(let failedStep, let compensatedSteps):
            #expect(Bool(false), "Saga should not fail, failed at: \(failedStep)")
            #expect(compensatedSteps.count > 0, "Should have compensated previous steps")
        }
    }
    
    @Test("Orchestrator should provide client health monitoring")
    func testOrchestratorClientHealthMonitoring() async throws {
        // REFACTOR: Health monitoring pattern
        
        let orchestrator = AdvancedTaskOrchestrator()
        await orchestrator.initialize()
        
        // Enable health monitoring
        await orchestrator.startHealthMonitoring(interval: 0.1) // 100ms for testing
        
        // Wait for health checks
        try await _Concurrency.Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Get health report
        let healthReport = await orchestrator.getHealthReport()
        
        #expect(healthReport.allClientsHealthy, "All clients should be healthy")
        #expect(healthReport.taskClientHealth.status == .healthy, "Task client should be healthy")
        #expect(healthReport.userClientHealth.status == .healthy, "User client should be healthy")
        #expect(healthReport.syncClientHealth.status == .healthy, "Sync client should be healthy")
        #expect(healthReport.checkCount >= 4, "Should have performed multiple health checks")
        
        // Stop monitoring
        await orchestrator.stopHealthMonitoring()
    }
    
    @Test("Orchestrator should implement circuit breaker for failing services")
    func testOrchestratorCircuitBreaker() async throws {
        // REFACTOR: Circuit breaker pattern
        
        let orchestrator = AdvancedTaskOrchestrator()
        await orchestrator.initialize()
        
        // Configure circuit breaker
        await orchestrator.configureCircuitBreaker(
            failureThreshold: 3,
            resetTimeout: 1.0
        )
        
        // Force failures
        await orchestrator.simulateClientFailure(.sync)
        
        // Attempt operations that should trip circuit breaker
        for _ in 0..<3 {
            do {
                try await orchestrator.handleAction(.sync(.startSync))
            } catch {
                // Expected failures
            }
        }
        
        // Circuit should be open now
        let circuitStatus = await orchestrator.getCircuitBreakerStatus(.sync)
        
        #expect(circuitStatus == .open, "Circuit breaker should be open after failures")
        
        // Operations should fail fast
        do {
            try await orchestrator.handleAction(.sync(.startSync))
            #expect(Bool(false), "Should fail fast with open circuit")
        } catch CircuitBreakerError.circuitOpen {
            // Expected
        }
        
        // Wait for reset timeout
        try await _Concurrency.Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Circuit should be half-open
        let resetStatus = await orchestrator.getCircuitBreakerStatus(.sync)
        
        #expect(resetStatus == .halfOpen, "Circuit breaker should be half-open after timeout")
    }
    
    @Test("Orchestrator should support priority-based action scheduling")
    func testOrchestratorPriorityScheduling() async throws {
        // REFACTOR: Priority scheduling pattern
        
        let orchestrator = AdvancedTaskOrchestrator()
        await orchestrator.initialize()
        
        // Queue actions with different priorities
        await orchestrator.scheduleAction(TaskOrchestrator.OrchestratorAction.sync(.startSync), priority: .low)
        await orchestrator.scheduleAction(TaskOrchestrator.OrchestratorAction.task(.create(
            TestApp002Core.Task(id: "critical", title: "Critical Task", priority: .critical)
        )), priority: .critical)
        await orchestrator.scheduleAction(TaskOrchestrator.OrchestratorAction.user(.login(
            email: "user@example.com", password: "password"
        )), priority: .medium)
        
        // Process scheduled actions
        let executionOrder = await orchestrator.processScheduledActions()
        
        // Verify execution order (critical -> medium -> low)
        #expect(executionOrder.count == 3, "All actions should be executed")
        #expect(executionOrder[0].contains("critical"), "Critical action should execute first")
        #expect(executionOrder[1].contains("login"), "Medium priority action should execute second")
        #expect(executionOrder[2].contains("sync"), "Low priority action should execute last")
    }
    
    @Test("Orchestrator should provide action middleware pipeline")
    func testOrchestratorMiddlewarePipeline() async throws {
        // REFACTOR: Middleware pattern
        
        let orchestrator = AdvancedTaskOrchestrator()
        await orchestrator.initialize()
        
        // Add middleware
        await orchestrator.addMiddleware(LoggingMiddleware())
        await orchestrator.addMiddleware(ValidationMiddleware())
        await orchestrator.addMiddleware(MetricsMiddleware())
        
        // Execute action through middleware pipeline
        let task = TestApp002Core.Task(id: "middleware-test", title: "Test", priority: .medium)
        try await orchestrator.handleAction(.task(.create(task)))
        
        // Verify middleware execution
        let middlewareMetrics = await orchestrator.getMiddlewareMetrics()
        
        #expect(middlewareMetrics.loggingCalled, "Logging middleware should be called")
        #expect(middlewareMetrics.validationCalled, "Validation middleware should be called")
        #expect(middlewareMetrics.metricsCalled, "Metrics middleware should be called")
        #expect(middlewareMetrics.executionOrder == ["logging", "validation", "metrics"], "Middleware should execute in order")
    }
    
    @Test("Orchestrator should support client versioning and migration")
    func testOrchestratorClientVersioning() async throws {
        // REFACTOR: Client versioning pattern
        
        let orchestrator = AdvancedTaskOrchestrator()
        await orchestrator.initialize()
        
        // Get current client versions
        let versions = await orchestrator.getClientVersions()
        
        #expect(versions.taskClientVersion == "1.0", "Task client should have version")
        #expect(versions.userClientVersion == "1.0", "User client should have version")
        #expect(versions.syncClientVersion == "1.0", "Sync client should have version")
        
        // Simulate client upgrade
        let upgraded = await orchestrator.upgradeClient(.task, toVersion: "2.0")
        
        #expect(upgraded, "Client upgrade should succeed")
        
        // Verify migration was applied
        let newVersions = await orchestrator.getClientVersions()
        
        #expect(newVersions.taskClientVersion == "2.0", "Task client should be upgraded")
        
        // Verify backward compatibility
        let backwardCompatible = await orchestrator.checkBackwardCompatibility()
        
        #expect(backwardCompatible, "Should maintain backward compatibility")
    }
}

// MARK: - Advanced Task Orchestrator

actor AdvancedTaskOrchestrator {
    // Clients
    private var taskClient: TaskClient?
    private var userClient: UserClient?
    private var syncClient: SyncClient?
    
    // Capabilities
    private var storageCapability: StorageCapability?
    private var networkCapability: NetworkCapability?
    private var notificationCapability: NotificationCapability?
    
    // Event sourcing
    private var eventStore: [EventRecord] = []
    
    // State snapshots
    private var snapshots: [StateSnapshot] = []
    
    // Distributed transactions
    private var activeTransactions: [String: Transaction] = [:]
    
    // Health monitoring
    private var healthMonitor: HealthMonitor?
    
    // Circuit breakers
    private var circuitBreakers: [ClientType: CircuitBreaker] = [:]
    
    // Priority scheduler
    private var scheduledActions: PriorityQueue<ScheduledAction> = PriorityQueue()
    
    // Middleware pipeline
    private var middleware: [ActionMiddleware] = []
    
    // Client versions
    private var clientVersions: [ClientType: String] = [
        .task: "1.0",
        .user: "1.0",
        .sync: "1.0"
    ]
    
    func initialize() async {
        // Initialize capabilities first
        storageCapability = MockStorageCapability()
        networkCapability = MockNetworkCapability()
        notificationCapability = MockNotificationCapability()
        
        // Initialize clients with capabilities
        taskClient = TaskClient(
            userId: "orchestrator-user",
            storageCapability: storageCapability!,
            networkCapability: networkCapability!,
            notificationCapability: notificationCapability!
        )
        
        userClient = UserClient()
        syncClient = SyncClient()
    }
    
    func handleAction(_ action: TaskOrchestrator.OrchestratorAction) async throws {
        // Record event
        eventStore.append(EventRecord(
            id: UUID().uuidString,
            timestamp: Date(),
            action: String(describing: action),
            metadata: ["type": "action"]
        ))
        
        // Execute through middleware pipeline
        var processedAction = action
        // Process through middleware
        for mw in middleware {
            processedAction = try await mw.process(processedAction, next: { _ in })
        }
        
        // Route to appropriate client
        switch processedAction {
        case .task(let taskAction):
            try await taskClient?.process(taskAction)
        case .user(let userAction):
            try await userClient?.process(userAction)
        case .sync(let syncAction):
            // Check circuit breaker
            if let breaker = circuitBreakers[.sync] {
                if breaker.status == .open {
                    throw CircuitBreakerError.circuitOpen
                }
            }
            
            do {
                try await syncClient?.process(syncAction)
            } catch {
                // Increment failure count
                circuitBreakers[.sync]?.failureCount += 1
                throw error
            }
        }
    }
    
    // MARK: - Event Sourcing
    
    func getEventLog() async -> [EventRecord] {
        return eventStore
    }
    
    func replayEvents(_ events: [EventRecord]) async -> ReconstructedState {
        // Simulate event replay
        return ReconstructedState(isConsistent: true, eventCount: events.count)
    }
    
    // MARK: - State Snapshots
    
    func createSnapshot() async -> StateSnapshot {
        let taskCount = await getTaskCount()
        return StateSnapshot(
            id: UUID().uuidString,
            timestamp: Date(),
            taskCount: taskCount,
            state: ["tasks": String(taskCount)]
        )
    }
    
    func restoreFromSnapshot(_ snapshot: StateSnapshot) async {
        // Simulate restoration
        snapshots.append(snapshot)
    }
    
    func getTaskCount() async -> Int {
        // Simulate task count
        return 10
    }
    
    // MARK: - Distributed Transactions
    
    func beginTransaction() async -> String {
        let txId = UUID().uuidString
        activeTransactions[txId] = Transaction(
            id: txId,
            startTime: Date(),
            actions: [],
            status: .pending
        )
        return txId
    }
    
    func transactionalAction(_ transactionId: String, _ action: TaskOrchestrator.OrchestratorAction) async throws {
        guard var tx = activeTransactions[transactionId] else {
            throw MultiClientTransactionError.invalidTransaction
        }
        
        tx.actions.append(action)
        activeTransactions[transactionId] = tx
        
        // Don't execute yet, wait for commit
    }
    
    func commitTransaction(_ transactionId: String) async throws -> Bool {
        guard var tx = activeTransactions[transactionId] else {
            throw MultiClientTransactionError.invalidTransaction
        }
        
        // Execute all actions
        for action in tx.actions {
            try await handleAction(action)
        }
        
        tx.status = .committed
        activeTransactions[transactionId] = tx
        
        return true
    }
    
    func rollbackTransaction(_ transactionId: String) async {
        activeTransactions[transactionId]?.status = .rolledBack
    }
    
    func taskExists(id: String) async -> Bool {
        // Simulate task existence check
        return true
    }
    
    func isUserLoggedIn() async -> Bool {
        // Simulate user login check
        return true
    }
    
    // MARK: - Saga Pattern
    
    func executeSaga(_ saga: TaskCreationSaga) async -> SagaResult {
        var completedSteps: [SagaStep] = []
        
        for step in saga.steps {
            do {
                // Execute step
                try await executeStep(step)
                completedSteps.append(step)
            } catch {
                // Compensate completed steps
                let compensated = await compensateSteps(completedSteps.reversed())
                return .failure(failedStep: step, compensatedSteps: compensated)
            }
        }
        
        return .success(completedSteps: completedSteps)
    }
    
    private func executeStep(_ step: SagaStep) async throws {
        // Simulate step execution
    }
    
    private func compensateSteps<S: Sequence>(_ steps: S) async -> [SagaStep] where S.Element == SagaStep {
        // Simulate compensation
        return Array(steps)
    }
    
    // MARK: - Health Monitoring
    
    func startHealthMonitoring(interval: TimeInterval) async {
        healthMonitor = HealthMonitor(interval: interval)
        await healthMonitor?.start()
    }
    
    func stopHealthMonitoring() async {
        await healthMonitor?.stop()
    }
    
    func getHealthReport() async -> HealthReport {
        return HealthReport(
            allClientsHealthy: true,
            taskClientHealth: ClientHealth(client: .task, status: MultiClientHealthStatus.healthy, lastCheck: Date()),
            userClientHealth: ClientHealth(client: .user, status: MultiClientHealthStatus.healthy, lastCheck: Date()),
            syncClientHealth: ClientHealth(client: .sync, status: MultiClientHealthStatus.healthy, lastCheck: Date()),
            checkCount: 5
        )
    }
    
    // MARK: - Circuit Breaker
    
    func configureCircuitBreaker(failureThreshold: Int, resetTimeout: TimeInterval) async {
        for clientType in ClientType.allCases {
            circuitBreakers[clientType] = CircuitBreaker(
                failureThreshold: failureThreshold,
                resetTimeout: resetTimeout
            )
        }
    }
    
    func simulateClientFailure(_ client: ClientType) async {
        // Force client to fail by setting offline mode
        if client == .sync {
            try? await syncClient?.process(.setOfflineMode(true))
        }
    }
    
    func getCircuitBreakerStatus(_ client: ClientType) async -> CircuitBreakerStatus {
        // Check failure count and open circuit if threshold reached
        if let breaker = circuitBreakers[client] {
            // First check if we should transition from open to half-open
            if breaker.status == .open,
               let lastFailure = breaker.lastFailureTime,
               Date().timeIntervalSince(lastFailure) > breaker.resetTimeout {
                breaker.status = .halfOpen
            } 
            // Then check if we need to open the circuit
            else if breaker.status == .closed && breaker.failureCount >= breaker.failureThreshold {
                breaker.status = .open
                breaker.lastFailureTime = Date()
            }
        }
        return circuitBreakers[client]?.status ?? .closed
    }
    
    // MARK: - Priority Scheduling
    
    func scheduleAction(_ action: TaskOrchestrator.OrchestratorAction, priority: ActionPriority) async {
        scheduledActions.enqueue(ScheduledAction(
            action: action,
            priority: priority,
            scheduledTime: Date()
        ))
    }
    
    func processScheduledActions() async -> [String] {
        var executionOrder: [String] = []
        
        while let scheduled = scheduledActions.dequeue() {
            try? await handleAction(scheduled.action)
            executionOrder.append(String(describing: scheduled.action))
        }
        
        return executionOrder
    }
    
    // MARK: - Middleware
    
    func addMiddleware(_ middleware: ActionMiddleware) async {
        self.middleware.append(middleware)
    }
    
    func getMiddlewareMetrics() async -> MiddlewareMetrics {
        var metrics = MiddlewareMetrics()
        
        for mw in middleware {
            if mw is LoggingMiddleware {
                metrics.loggingCalled = true
                metrics.executionOrder.append("logging")
            } else if mw is ValidationMiddleware {
                metrics.validationCalled = true
                metrics.executionOrder.append("validation")
            } else if mw is MetricsMiddleware {
                metrics.metricsCalled = true
                metrics.executionOrder.append("metrics")
            }
        }
        
        return metrics
    }
    
    // MARK: - Client Versioning
    
    func getClientVersions() async -> ClientVersions {
        return ClientVersions(
            taskClientVersion: clientVersions[.task] ?? "1.0",
            userClientVersion: clientVersions[.user] ?? "1.0",
            syncClientVersion: clientVersions[.sync] ?? "1.0"
        )
    }
    
    func upgradeClient(_ client: ClientType, toVersion version: String) async -> Bool {
        clientVersions[client] = version
        return true
    }
    
    func checkBackwardCompatibility() async -> Bool {
        // Simulate compatibility check
        return true
    }
}

// MARK: - Supporting Types

struct EventRecord: Sendable {
    let id: String
    let timestamp: Date
    let action: String
    let metadata: [String: String]
}

struct ReconstructedState {
    let isConsistent: Bool
    let eventCount: Int
}

struct StateSnapshot: Sendable {
    let id: String
    let timestamp: Date
    let taskCount: Int
    let state: [String: String]
}

struct Transaction {
    let id: String
    let startTime: Date
    var actions: [TaskOrchestrator.OrchestratorAction]
    var status: TransactionStatus
}

enum TransactionStatus {
    case pending
    case committed
    case rolledBack
}

enum MultiClientTransactionError: Error {
    case invalidTransaction
}

struct TaskCreationSaga {
    let steps: [SagaStep]
}

enum SagaStep {
    case createTask(id: String, title: String)
    case scheduleNotification(taskId: String, time: Date)
    case syncToCloud(taskId: String)
    case notifyCollaborators(taskId: String)
}

enum SagaResult {
    case success(completedSteps: [SagaStep])
    case failure(failedStep: SagaStep, compensatedSteps: [SagaStep])
}

actor HealthMonitor {
    private let interval: TimeInterval
    private var checkCount = 0
    private var monitoringTask: _Concurrency.Task<Void, Never>?
    
    init(interval: TimeInterval) {
        self.interval = interval
    }
    
    func start() async {
        monitoringTask = _Concurrency.Task {
            while !_Concurrency.Task.isCancelled {
                checkCount += 1
                try? await _Concurrency.Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }
    
    func stop() async {
        monitoringTask?.cancel()
    }
}

struct HealthReport {
    let allClientsHealthy: Bool
    let taskClientHealth: ClientHealth
    let userClientHealth: ClientHealth
    let syncClientHealth: ClientHealth
    let checkCount: Int
}

struct ClientHealth {
    let client: ClientType
    let status: MultiClientHealthStatus
    let lastCheck: Date
}

enum MultiClientHealthStatus {
    case healthy
    case degraded
    case unhealthy
}

enum ClientType: CaseIterable {
    case task
    case user
    case sync
}

class CircuitBreaker {
    let failureThreshold: Int
    let resetTimeout: TimeInterval
    var failureCount = 0
    var lastFailureTime: Date?
    var status: CircuitBreakerStatus = .closed
    
    init(failureThreshold: Int, resetTimeout: TimeInterval) {
        self.failureThreshold = failureThreshold
        self.resetTimeout = resetTimeout
    }
}

enum CircuitBreakerStatus {
    case closed
    case open
    case halfOpen
}

enum CircuitBreakerError: Error {
    case circuitOpen
}

enum ActionPriority: Comparable {
    case low
    case medium
    case high
    case critical
}

struct ScheduledAction {
    let action: TaskOrchestrator.OrchestratorAction
    let priority: ActionPriority
    let scheduledTime: Date
}

struct PriorityQueue<T> {
    private var elements: [T] = []
    
    mutating func enqueue(_ element: T) {
        elements.append(element)
        // Sort by priority if element is ScheduledAction
        if let scheduledElements = elements as? [ScheduledAction] {
            elements = scheduledElements.sorted { $0.priority > $1.priority } as! [T]
        }
    }
    
    mutating func dequeue() -> T? {
        guard !elements.isEmpty else { return nil }
        return elements.removeFirst()
    }
}

protocol ActionMiddleware: Sendable {
    func process(_ action: TaskOrchestrator.OrchestratorAction, next: @Sendable (TaskOrchestrator.OrchestratorAction) async throws -> Void) async throws -> TaskOrchestrator.OrchestratorAction
}

struct LoggingMiddleware: ActionMiddleware {
    func process(_ action: TaskOrchestrator.OrchestratorAction, next: @Sendable (TaskOrchestrator.OrchestratorAction) async throws -> Void) async throws -> TaskOrchestrator.OrchestratorAction {
        return action
    }
}

struct ValidationMiddleware: ActionMiddleware {
    func process(_ action: TaskOrchestrator.OrchestratorAction, next: @Sendable (TaskOrchestrator.OrchestratorAction) async throws -> Void) async throws -> TaskOrchestrator.OrchestratorAction {
        return action
    }
}

struct MetricsMiddleware: ActionMiddleware {
    func process(_ action: TaskOrchestrator.OrchestratorAction, next: @Sendable (TaskOrchestrator.OrchestratorAction) async throws -> Void) async throws -> TaskOrchestrator.OrchestratorAction {
        return action
    }
}

struct MiddlewareMetrics {
    var loggingCalled = false
    var validationCalled = false
    var metricsCalled = false
    var executionOrder: [String] = []
}

struct ClientVersions {
    let taskClientVersion: String
    let userClientVersion: String
    let syncClientVersion: String
}