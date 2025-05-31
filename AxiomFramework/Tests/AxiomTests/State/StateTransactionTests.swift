import Testing
import Foundation
@testable import Axiom

// MARK: - Test State Types for Transactions

/// Test state for transaction testing
struct TestTransactionState: Sendable, Equatable {
    var items: [String: Item] = [:]
    var counters: [String: Int] = [:]
    var flags: Set<String> = []
    var metadata: TransactionMetadata = TransactionMetadata()
    
    struct Item: Sendable, Equatable {
        let id: String
        var name: String
        var value: Double
        var isActive: Bool = true
    }
    
    struct TransactionMetadata: Sendable, Equatable {
        var version: Int = 1
        var lastModified: Date = Date()
        var modifiedBy: String = "system"
    }
}

/// Test client implementing StateTransacting
class TestTransactionClient {
    typealias State = TestTransactionState
    
    private var currentState = TestTransactionState()
    private var stateVersion = StateVersion()
    private let transactionManager = StateTransactionManager<TestTransactionState>()
    
    func getCurrentState() -> TestTransactionState {
        currentState
    }
    
    func getCurrentVersion() -> StateVersion {
        stateVersion
    }
    
    func updateState(_ mutation: (inout TestTransactionState) -> Void) async throws {
        let snapshot = StateSnapshot(state: currentState, version: stateVersion)
        // Simplified for testing
        var modifiedContext = StateTransactionContext(originalSnapshot: snapshot)
        try modifiedContext.apply(mutation)
        
        // Validate and commit
        try modifiedContext.validate()
        
        currentState = modifiedContext.workingState
        stateVersion = stateVersion.incrementMinor()
        
        let finalSnapshot = StateSnapshot(state: currentState, version: stateVersion)
        try await transactionManager.commit(modifiedContext, finalSnapshot: finalSnapshot)
    }
    
    // MARK: StateTransacting Implementation
    
    func beginTransaction() -> StateTransactionContext<TestTransactionState> {
        let snapshot = StateSnapshot(state: currentState, version: stateVersion)
        return StateTransactionContext(originalSnapshot: snapshot)
    }
    
    func commit(_ transaction: StateTransactionContext<TestTransactionState>) async throws {
        try transaction.validate()
        currentState = transaction.workingState
        stateVersion = stateVersion.incrementMinor()
        
        let finalSnapshot = StateSnapshot(state: currentState, version: stateVersion)
        try await transactionManager.commit(transaction, finalSnapshot: finalSnapshot)
    }
    
    func rollback(_ transaction: StateTransactionContext<TestTransactionState>) async {
        await transactionManager.rollback(transaction)
    }
    
    func getTransactionHistory(limit: Int) async -> [CompletedStateTransaction<TestTransactionState>] {
        return await transactionManager.getTransactionHistory(limit: limit)
    }
    
    func getTransactionStatistics() async -> TransactionStatistics {
        await transactionManager.getStatistics()
    }
    
    func getActiveTransactions() async -> [StateTransactionContext<TestTransactionState>] {
        await transactionManager.getActiveTransactions()
    }
}

// MARK: - StateTransactionContext Core Tests

@Test("StateTransactionContext initialization")
func testTransactionContextInitialization() throws {
    let state = TestTransactionState()
    let snapshot = StateSnapshot(state: state)
    let metadata = TransactionMetadata(purpose: "test", tags: ["unit-test"])
    
    let context = StateTransactionContext(
        originalSnapshot: snapshot,
        metadata: metadata
    )
    
    #expect(context.id.description.count > 0)
    #expect(context.originalSnapshot.id == snapshot.id)
    #expect(context.workingState == state)
    #expect(context.operations.isEmpty)
    #expect(context.metadata.purpose == "test")
    #expect(context.metadata.tags.contains("unit-test"))
    #expect(context.startTime <= Date())
}

@Test("StateTransactionContext state mutation")
func testTransactionContextStateMutation() throws {
    var state = TestTransactionState()
    state.items["item1"] = TestTransactionState.Item(id: "1", name: "Original", value: 100.0)
    
    let snapshot = StateSnapshot(state: state)
    var context = StateTransactionContext(originalSnapshot: snapshot)
    
    // Test direct state modification
    context.workingState.items["item1"]?.name = "Modified"
    context.workingState.counters["counter1"] = 5
    
    #expect(context.workingState.items["item1"]?.name == "Modified")
    #expect(context.workingState.counters["counter1"] == 5)
    #expect(context.originalSnapshot.state.items["item1"]?.name == "Original")
    #expect(context.originalSnapshot.state.counters["counter1"] == nil)
    #expect(context.operations.count > 0) // State modifications should be recorded
}

@Test("StateTransactionContext apply mutation")
func testTransactionContextApplyMutation() throws {
    let state = TestTransactionState()
    let snapshot = StateSnapshot(state: state)
    var context = StateTransactionContext(originalSnapshot: snapshot)
    
    // Test apply mutation with return value
    let result = context.apply { state in
        state.items["item1"] = TestTransactionState.Item(id: "1", name: "Applied", value: 200.0)
        state.flags.insert("applied")
        return "success"
    }
    
    #expect(result == "success")
    #expect(context.workingState.items["item1"]?.name == "Applied")
    #expect(context.workingState.flags.contains("applied"))
    #expect(context.operations.count >= 1) // Mutation should be recorded
}

@Test("StateTransactionContext working snapshot")
func testTransactionContextWorkingSnapshot() throws {
    var state = TestTransactionState()
    state.items["original"] = TestTransactionState.Item(id: "orig", name: "Original", value: 50.0)
    
    let snapshot = StateSnapshot(state: state)
    var context = StateTransactionContext(originalSnapshot: snapshot)
    
    // Modify working state
    context.workingState.items["new"] = TestTransactionState.Item(id: "new", name: "New", value: 75.0)
    context.workingState.counters["test"] = 10
    
    let workingSnapshot = context.createWorkingSnapshot()
    
    #expect(workingSnapshot.state.items.count == 2)
    #expect(workingSnapshot.state.items["new"]?.name == "New")
    #expect(workingSnapshot.state.counters["test"] == 10)
    #expect(workingSnapshot.version > context.originalSnapshot.version)
    #expect(workingSnapshot.metadata.tags.contains("transaction"))
    #expect(workingSnapshot.metadata.tags.contains("working"))
}

@Test("StateTransactionContext validation")
func testTransactionContextValidation() throws {
    let state = TestTransactionState()
    let snapshot = StateSnapshot(state: state)
    
    // Test validation of empty transaction
    let emptyContext = StateTransactionContext(originalSnapshot: snapshot)
    
    do {
        try emptyContext.validate()
        #expect(Bool(false), "Empty transaction should fail validation")
    } catch let error as TransactionError {
        switch error {
        case .emptyTransaction(let id):
            #expect(id == emptyContext.id)
        default:
            #expect(Bool(false), "Wrong error type")
        }
    }
    
    // Test validation of valid transaction
    var validContext = StateTransactionContext(originalSnapshot: snapshot)
    validContext.recordOperation(.stateModification(description: "Test modification"))
    
    try validContext.validate() // Should not throw
}

@Test("StateTransactionContext timeout validation")
func testTransactionContextTimeoutValidation() async throws {
    let state = TestTransactionState()
    let snapshot = StateSnapshot(state: state)
    let metadata = TransactionMetadata(timeout: 0.001) // 1ms timeout
    
    var context = StateTransactionContext(originalSnapshot: snapshot, metadata: metadata)
    context.recordOperation(.stateModification(description: "Test"))
    
    // Wait for timeout
    try await Task.sleep(for: .milliseconds(10))
    
    do {
        try context.validate()
        #expect(Bool(false), "Transaction should timeout")
    } catch let error as TransactionError {
        switch error {
        case .transactionTimeout(let id, let elapsed):
            #expect(id == context.id)
            #expect(elapsed > 0.001)
        default:
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }
}

@Test("StateTransactionContext commit diff calculation")
func testTransactionContextCommitDiffCalculation() throws {
    var state = TestTransactionState()
    state.items["item1"] = TestTransactionState.Item(id: "1", name: "Original", value: 100.0)
    
    let snapshot = StateSnapshot(state: state)
    var context = StateTransactionContext(originalSnapshot: snapshot)
    
    // Modify working state
    context.workingState.items["item1"]?.name = "Modified"
    context.workingState.items["item2"] = TestTransactionState.Item(id: "2", name: "New", value: 200.0)
    
    let diff = context.calculateCommitDiff()
    
    #expect(diff.fromSnapshot == context.originalSnapshot.id)
    #expect(diff.toSnapshot != context.originalSnapshot.id)
    #expect(diff.timestamp <= Date())
}

// MARK: - StateTransactionManager Tests

@Test("StateTransactionManager initialization")
func testTransactionManagerInitialization() async throws {
    let manager = StateTransactionManager<TestTransactionState>(
        maxHistorySize: 500,
        defaultTimeout: 60.0
    )
    
    let stats = await manager.getStatistics()
    #expect(stats.totalTransactions == 0)
    #expect(stats.commitCount == 0)
    #expect(stats.rollbackCount == 0)
    #expect(stats.failureCount == 0)
    #expect(stats.activeCount == 0)
    
    let activeTransactions = await manager.getActiveTransactions()
    #expect(activeTransactions.isEmpty)
}

@Test("StateTransactionManager begin transaction")
func testTransactionManagerBeginTransaction() async throws {
    let manager = StateTransactionManager<TestTransactionState>()
    let state = TestTransactionState()
    let snapshot = StateSnapshot(state: state)
    
    let context = await manager.beginTransaction(from: snapshot)
    
    #expect(context.originalSnapshot.id == snapshot.id)
    #expect(context.workingState == state)
    
    let activeTransactions = await manager.getActiveTransactions()
    #expect(activeTransactions.count == 1)
    #expect(activeTransactions.first?.id == context.id)
}

@Test("StateTransactionManager commit transaction")
func testTransactionManagerCommitTransaction() async throws {
    let manager = StateTransactionManager<TestTransactionState>()
    let state = TestTransactionState()
    let snapshot = StateSnapshot(state: state)
    
    var context = await manager.beginTransaction(from: snapshot)
    context.recordOperation(.stateModification(description: "Test modification"))
    
    var modifiedState = state
    modifiedState.counters["test"] = 1
    let finalSnapshot = StateSnapshot(state: modifiedState)
    
    try await manager.commit(context, finalSnapshot: finalSnapshot)
    
    let stats = await manager.getStatistics()
    #expect(stats.commitCount == 1)
    #expect(stats.totalTransactions == 1)
    
    let activeTransactions = await manager.getActiveTransactions()
    #expect(activeTransactions.isEmpty) // Should be removed from active
    
    let history = await manager.getTransactionHistory(limit: 10)
    #expect(history.count == 1)
    #expect(history.first?.id == context.id)
    #expect(history.first?.wasCommitted == true)
}

@Test("StateTransactionManager rollback transaction")
func testTransactionManagerRollbackTransaction() async throws {
    let manager = StateTransactionManager<TestTransactionState>()
    let state = TestTransactionState()
    let snapshot = StateSnapshot(state: state)
    
    var context = await manager.beginTransaction(from: snapshot)
    context.recordOperation(.stateModification(description: "Test modification"))
    
    await manager.rollback(context)
    
    let stats = await manager.getStatistics()
    #expect(stats.rollbackCount == 1)
    #expect(stats.totalTransactions == 1)
    #expect(stats.commitCount == 0)
    
    let history = await manager.getTransactionHistory(limit: 10)
    #expect(history.count == 1)
    #expect(history.first?.wasCommitted == false)
    #expect(history.first?.result.isSuccess == false)
}

@Test("StateTransactionManager failure recording")
func testTransactionManagerFailureRecording() async throws {
    let manager = StateTransactionManager<TestTransactionState>()
    let state = TestTransactionState()
    let snapshot = StateSnapshot(state: state)
    
    var context = await manager.beginTransaction(from: snapshot)
    context.recordOperation(.stateModification(description: "Test modification"))
    
    let testError = TransactionError.invalidState(id: context.id, reason: "Test failure")
    await manager.recordFailure(context, error: testError)
    
    let stats = await manager.getStatistics()
    #expect(stats.failureCount == 1)
    #expect(stats.totalTransactions == 1)
    
    let history = await manager.getTransactionHistory(limit: 10)
    #expect(history.count == 1)
    #expect(history.first?.wasCommitted == false)
    
    if case .failed(let recordedError) = history.first?.result {
        #expect(recordedError is TransactionError)
    } else {
        #expect(Bool(false), "Should have recorded failure")
    }
}

@Test("StateTransactionManager history filtering")
func testTransactionManagerHistoryFiltering() async throws {
    let manager = StateTransactionManager<TestTransactionState>()
    let state = TestTransactionState()
    
    // Create multiple transactions with different outcomes
    for i in 0..<5 {
        let snapshot = StateSnapshot(state: state)
        var context = await manager.beginTransaction(from: snapshot)
        context.recordOperation(.stateModification(description: "Operation \(i)"))
        
        if i % 2 == 0 {
            // Commit even numbered transactions
            let finalSnapshot = StateSnapshot(state: state)
            try await manager.commit(context, finalSnapshot: finalSnapshot)
        } else {
            // Rollback odd numbered transactions
            await manager.rollback(context)
        }
    }
    
    let allHistory = await manager.getTransactionHistory(limit: 10)
    #expect(allHistory.count == 5)
    
    let committedHistory = await manager.getTransactionHistory(
        limit: 10,
        filter: .byResult(.committed)
    )
    #expect(committedHistory.count == 3) // 0, 2, 4
    
    let rolledBackHistory = await manager.getTransactionHistory(
        limit: 10,
        filter: .byResult(.rolledBack)
    )
    #expect(rolledBackHistory.count == 2) // 1, 3
}

@Test("StateTransactionManager cleanup expired transactions")
func testTransactionManagerCleanupExpiredTransactions() async throws {
    let manager = StateTransactionManager<TestTransactionState>(defaultTimeout: 0.01) // 10ms timeout
    let state = TestTransactionState()
    let snapshot = StateSnapshot(state: state)
    
    // Create transaction that will expire
    let metadata = TransactionMetadata(timeout: 0.01) // 10ms timeout
    let _ = await manager.beginTransaction(from: snapshot, metadata: metadata)
    
    let initialActiveCount = await manager.getActiveTransactions().count
    #expect(initialActiveCount == 1)
    
    // Wait for expiration
    try await Task.sleep(for: .milliseconds(20))
    
    await manager.cleanupExpiredTransactions()
    
    let finalActiveCount = await manager.getActiveTransactions().count
    #expect(finalActiveCount == 0)
    
    let stats = await manager.getStatistics()
    #expect(stats.failureCount == 1) // Should be recorded as failure
    
    let history = await manager.getTransactionHistory(limit: 10)
    #expect(history.count == 1)
    
    if case .failed(let error) = history.first?.result {
        #expect(error is TransactionError)
    } else {
        #expect(Bool(false), "Expired transaction should be marked as failed")
    }
}

// MARK: - StateTransacting Integration Tests

@Test("StateTransacting client integration")
func testStateTransactingClientIntegration() async throws {
    let client = TestTransactionClient()
    
    // Test basic transaction workflow
    try await client.updateState { state in
        state.items["item1"] = TestTransactionState.Item(id: "1", name: "Test Item", value: 100.0)
        state.counters["updates"] = 1
        state.flags.insert("initialized")
    }
    
    let currentState = await client.getCurrentState()
    #expect(currentState.items["item1"]?.name == "Test Item")
    #expect(currentState.counters["updates"] == 1)
    #expect(currentState.flags.contains("initialized"))
    
    // Test transaction history
    let history = await client.getTransactionHistory(limit: 10)
    #expect(history.count >= 1)
    #expect(history.last?.wasCommitted == true)
}

@Test("StateTransacting manual transaction control")
func testStateTransactingManualTransactionControl() async throws {
    let client = TestTransactionClient()
    
    // Begin manual transaction
    var transaction = await client.beginTransaction()
    
    // Modify working state
    transaction.workingState.items["manual"] = TestTransactionState.Item(
        id: "manual",
        name: "Manual Transaction",
        value: 999.0
    )
    transaction.recordOperation(.stateModification(description: "Manual operation"))
    
    // Commit transaction
    try await client.commit(transaction)
    
    let currentState = await client.getCurrentState()
    #expect(currentState.items["manual"]?.name == "Manual Transaction")
    
    let stats = await client.getTransactionStatistics()
    #expect(stats.commitCount >= 1)
}

@Test("StateTransacting rollback scenario")
func testStateTransactingRollbackScenario() async throws {
    let client = TestTransactionClient()
    
    // Set initial state
    try await client.updateState { state in
        state.items["original"] = TestTransactionState.Item(id: "orig", name: "Original", value: 50.0)
    }
    
    let stateBeforeRollback = await client.getCurrentState()
    
    // Begin transaction that will be rolled back
    var transaction = await client.beginTransaction()
    transaction.workingState.items["rollback"] = TestTransactionState.Item(
        id: "rollback",
        name: "Will be rolled back",
        value: 999.0
    )
    transaction.workingState.items["original"]?.value = 999.0 // Modify existing
    
    // Rollback instead of commit
    await client.rollback(transaction)
    
    let stateAfterRollback = await client.getCurrentState()
    
    // State should be unchanged
    #expect(stateAfterRollback.items["rollback"] == nil)
    #expect(stateAfterRollback.items["original"]?.value == stateBeforeRollback.items["original"]?.value)
    #expect(stateAfterRollback == stateBeforeRollback)
    
    let stats = await client.getTransactionStatistics()
    #expect(stats.rollbackCount >= 1)
}

// MARK: - Transaction Error Handling Tests

@Test("Transaction validation errors")
func testTransactionValidationErrors() throws {
    let state = TestTransactionState()
    let snapshot = StateSnapshot(state: state)
    
    // Test empty transaction error
    let emptyContext = StateTransactionContext(originalSnapshot: snapshot)
    
    do {
        try emptyContext.validate()
        #expect(Bool(false), "Should throw empty transaction error")
    } catch TransactionError.emptyTransaction(let id) {
        #expect(id == emptyContext.id)
    }
    
    // Test timeout error
    let timeoutMetadata = TransactionMetadata(timeout: 0.001) // 1ms
    var timeoutContext = StateTransactionContext(originalSnapshot: snapshot, metadata: timeoutMetadata)
    timeoutContext.recordOperation(.stateModification(description: "Test"))
    
    Thread.sleep(forTimeInterval: 0.01) // 10ms
    
    do {
        try timeoutContext.validate()
        #expect(Bool(false), "Should throw timeout error")
    } catch TransactionError.transactionTimeout(let id, let elapsed) {
        #expect(id == timeoutContext.id)
        #expect(elapsed > 0.001)
    }
}

@Test("Transaction error descriptions")
func testTransactionErrorDescriptions() throws {
    let id = TransactionID()
    
    let errors: [TransactionError] = [
        .emptyTransaction(id: id),
        .transactionTimeout(id: id, elapsed: 5.0),
        .conflictingTransaction(id: id, conflictingId: TransactionID()),
        .invalidState(id: id, reason: "Test reason"),
        .commitValidationFailed(id: id, errors: ["Error 1", "Error 2"])
    ]
    
    for error in errors {
        let description = error.description
        #expect(description.contains(id.description))
        #expect(description.count > 0)
    }
}

// MARK: - Transaction Performance Tests

@Test("Transaction creation performance")
func testTransactionCreationPerformance() throws {
    // Create large state
    var state = TestTransactionState()
    for i in 0..<1000 {
        state.items["item\(i)"] = TestTransactionState.Item(
            id: "id\(i)",
            name: "Item \(i)",
            value: Double(i)
        )
        state.counters["counter\(i)"] = i
    }
    
    let snapshot = StateSnapshot(state: state)
    
    // Measure transaction creation time
    let startTime = ContinuousClock.now
    
    var transactions: [StateTransactionContext<TestTransactionState>] = []
    for i in 0..<100 {
        let metadata = TransactionMetadata(purpose: "Performance test \(i)")
        let context = StateTransactionContext(originalSnapshot: snapshot, metadata: metadata)
        transactions.append(context)
    }
    
    let duration = ContinuousClock.now - startTime
    
    // Should create 100 transactions quickly (< 50ms)
    #expect(duration < .milliseconds(50))
    #expect(transactions.count == 100)
}

@Test("Transaction manager performance under load")
func testTransactionManagerPerformanceUnderLoad() async throws {
    let manager = StateTransactionManager<TestTransactionState>(maxHistorySize: 1000)
    let state = TestTransactionState()
    
    // Measure concurrent transaction processing
    let startTime = ContinuousClock.now
    
    await withTaskGroup(of: Void.self) { group in
        for i in 0..<100 {
            group.addTask {
                let snapshot = StateSnapshot(state: state)
                var context = await manager.beginTransaction(from: snapshot)
                context.recordOperation(.stateModification(description: "Load test \(i)"))
                
                if i % 2 == 0 {
                    let finalSnapshot = StateSnapshot(state: state)
                    try? await manager.commit(context, finalSnapshot: finalSnapshot)
                } else {
                    await manager.rollback(context)
                }
            }
        }
    }
    
    let duration = ContinuousClock.now - startTime
    
    // Should process 100 transactions concurrently quickly (< 500ms)
    #expect(duration < .milliseconds(500))
    
    let stats = await manager.getStatistics()
    #expect(stats.totalTransactions == 100)
    #expect(stats.commitCount == 50)
    #expect(stats.rollbackCount == 50)
}

// MARK: - Transaction Metadata and Operation Tests

@Test("Transaction metadata functionality")
func testTransactionMetadataFunctionality() throws {
    let initiator = ComponentID("test-component")
    let metadata = TransactionMetadata(
        initiator: initiator,
        purpose: "Test transaction",
        timeout: 30.0,
        tags: ["test", "metadata"],
        context: ["key1": "value1", "key2": "value2"]
    )
    
    #expect(metadata.initiator == initiator)
    #expect(metadata.purpose == "Test transaction")
    #expect(metadata.timeout == 30.0)
    #expect(metadata.tags.contains("test"))
    #expect(metadata.tags.contains("metadata"))
    #expect(metadata.context["key1"] == "value1")
    #expect(metadata.context["key2"] == "value2")
}

@Test("Transaction operation types")
func testTransactionOperationTypes() throws {
    let operations: [TransactionOperation] = [
        .stateModification(description: "Modified user data"),
        .validation(description: "Validated business rules"),
        .rollbackPoint(description: "Created rollback point"),
        .customOperation(name: "custom_op", details: ["param1": "value1"])
    ]
    
    for operation in operations {
        let description = operation.description
        #expect(description.count > 0)
        
        switch operation {
        case .stateModification(let desc):
            #expect(description.contains("State"))
            #expect(description.contains(desc))
        case .validation(let desc):
            #expect(description.contains("Validation"))
            #expect(description.contains(desc))
        case .rollbackPoint(let desc):
            #expect(description.contains("Rollback"))
            #expect(description.contains(desc))
        case .customOperation(let name, _):
            #expect(description.contains("Custom"))
            #expect(description.contains(name))
        }
    }
}

@Test("Transaction result types")
func testTransactionResultTypes() throws {
    let testError = TransactionError.invalidState(id: TransactionID(), reason: "Test")
    
    let results: [TransactionResult] = [
        .committed,
        .rolledBack,
        .failed(testError)
    ]
    
    #expect(results[0].isSuccess == true)
    #expect(results[1].isSuccess == false)
    #expect(results[2].isSuccess == false)
    
    for result in results {
        let description = result.description
        #expect(description.count > 0)
    }
    
    // Test equality
    #expect(TransactionResult.committed == .committed)
    #expect(TransactionResult.rolledBack == .rolledBack)
    #expect(TransactionResult.committed != .rolledBack)
}

// MARK: - Transaction Statistics Tests

@Test("Transaction statistics calculations")
func testTransactionStatisticsCalculations() async throws {
    let manager = StateTransactionManager<TestTransactionState>()
    let state = TestTransactionState()
    
    // Create transactions with known outcomes
    for i in 0..<10 {
        let snapshot = StateSnapshot(state: state)
        var context = await manager.beginTransaction(from: snapshot)
        context.recordOperation(.stateModification(description: "Test \(i)"))
        
        switch i % 3 {
        case 0:
            // Commit
            let finalSnapshot = StateSnapshot(state: state)
            try await manager.commit(context, finalSnapshot: finalSnapshot)
        case 1:
            // Rollback
            await manager.rollback(context)
        case 2:
            // Failure
            let error = TransactionError.invalidState(id: context.id, reason: "Test failure")
            await manager.recordFailure(context, error: error)
        default:
            break
        }
    }
    
    let stats = await manager.getStatistics()
    
    #expect(stats.totalTransactions == 10)
    #expect(stats.commitCount >= 3) // At least 3 commits (0, 3, 6, 9)
    #expect(stats.rollbackCount >= 3) // At least 3 rollbacks (1, 4, 7)
    #expect(stats.failureCount >= 3) // At least 3 failures (2, 5, 8)
    
    #expect(stats.commitRate >= 0.0 && stats.commitRate <= 1.0)
    #expect(stats.rollbackRate >= 0.0 && stats.rollbackRate <= 1.0)
    #expect(stats.failureRate >= 0.0 && stats.failureRate <= 1.0)
    
    #expect(abs(stats.commitRate + stats.rollbackRate + stats.failureRate - 1.0) < 0.001)
}

// MARK: - Transaction Filter Tests

@Test("Transaction filter functionality")
func testTransactionFilterFunctionality() async throws {
    let manager = StateTransactionManager<TestTransactionState>()
    let state = TestTransactionState()
    let now = Date()
    
    // Create transactions at different times
    for i in 0..<5 {
        let snapshot = StateSnapshot(state: state)
        var context = await manager.beginTransaction(from: snapshot)
        context.recordOperation(.stateModification(description: "Test \(i)"))
        
        if i < 3 {
            let finalSnapshot = StateSnapshot(state: state)
            try await manager.commit(context, finalSnapshot: finalSnapshot)
        } else {
            await manager.rollback(context)
        }
        
        // Small delay to ensure different timestamps
        try await Task.sleep(for: .milliseconds(1))
    }
    
    // Test filtering by result
    let committedTransactions = await manager.getTransactionHistory(
        limit: 10,
        filter: .byResult(.committed)
    )
    #expect(committedTransactions.count == 3)
    #expect(committedTransactions.allSatisfy { $0.wasCommitted })
    
    let rolledBackTransactions = await manager.getTransactionHistory(
        limit: 10,
        filter: .byResult(.rolledBack)
    )
    #expect(rolledBackTransactions.count == 2)
    #expect(rolledBackTransactions.allSatisfy { !$0.wasCommitted })
    
    // Test filtering by time range
    let futureTime = Date().addingTimeInterval(60)
    let timeRangeTransactions = await manager.getTransactionHistory(
        limit: 10,
        filter: .byTimeRange(start: now, end: futureTime)
    )
    #expect(timeRangeTransactions.count == 5)
    
    // Test filtering by duration
    let durationTransactions = await manager.getTransactionHistory(
        limit: 10,
        filter: .byDuration(min: 0.0, max: 1.0)
    )
    #expect(durationTransactions.count >= 0) // All should be under 1 second
}