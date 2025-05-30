import Foundation

// MARK: - State Transaction Protocol

/// Protocol for managing atomic state transactions
public protocol StateTransacting {
    associatedtype State: Sendable
    
    /// Begins a new transaction
    func beginTransaction() -> StateTransactionContext<State>
    
    /// Commits a transaction with validation
    func commit(_ transaction: StateTransactionContext<State>) async throws
    
    /// Rolls back a transaction
    func rollback(_ transaction: StateTransactionContext<State>) async
    
    /// Gets transaction history
    func getTransactionHistory(limit: Int) -> [CompletedStateTransaction<State>]
}

// MARK: - State Transaction Context

/// Represents an active state transaction with rollback capability
public struct StateTransactionContext<State: Sendable>: Sendable {
    // MARK: Properties
    
    /// Unique identifier for this transaction
    public let id: TransactionID
    
    /// The state before transaction began
    public let originalSnapshot: StateSnapshot<State>
    
    /// The current working state within the transaction
    private var _workingState: State
    
    /// List of operations performed in this transaction
    private var _operations: [TransactionOperation]
    
    /// Transaction metadata
    public let metadata: TransactionMetadata
    
    /// Timestamp when transaction began
    public let startTime: Date
    
    /// Current working state (mutable within transaction)
    public var workingState: State {
        get { _workingState }
        set { 
            _workingState = newValue
            recordOperation(.stateModification(description: "State updated"))
        }
    }
    
    /// All operations performed in this transaction
    public var operations: [TransactionOperation] {
        _operations
    }
    
    // MARK: Initialization
    
    public init(
        originalSnapshot: StateSnapshot<State>,
        metadata: TransactionMetadata = TransactionMetadata()
    ) {
        self.id = TransactionID()
        self.originalSnapshot = originalSnapshot
        self._workingState = originalSnapshot.state
        self._operations = []
        self.metadata = metadata
        self.startTime = Date()
    }
    
    // MARK: Transaction Operations
    
    /// Records an operation within this transaction
    public mutating func recordOperation(_ operation: TransactionOperation) {
        _operations.append(operation)
    }
    
    /// Applies a mutation to the working state
    public mutating func apply<T>(_ mutation: @Sendable (inout State) throws -> T) rethrows -> T {
        let result = try mutation(&_workingState)
        recordOperation(.stateModification(description: "Applied mutation"))
        return result
    }
    
    /// Creates a snapshot of the current working state
    public func createWorkingSnapshot() -> StateSnapshot<State> {
        StateSnapshot(
            state: _workingState,
            version: originalSnapshot.version.incrementMinor(),
            metadata: SnapshotMetadata(
                createdBy: metadata.initiator,
                purpose: .checkpoint,
                tags: ["transaction", "working"]
            )
        )
    }
    
    /// Validates that the transaction can be committed
    public func validate() throws {
        // Check transaction integrity
        guard !operations.isEmpty else {
            throw TransactionError.emptyTransaction(id: id)
        }
        
        // Check transaction timeout
        if let timeout = metadata.timeout,
           Date().timeIntervalSince(startTime) > timeout {
            throw TransactionError.transactionTimeout(id: id, elapsed: Date().timeIntervalSince(startTime))
        }
        
        // Validate state consistency
        // This is where custom validation logic would be applied
    }
    
    /// Calculates the diff that will be applied when committed
    public func calculateCommitDiff() -> StateDiff<State> {
        originalSnapshot.diff(against: createWorkingSnapshot())
    }
}

// MARK: - Completed Transaction

/// Represents a completed (committed or rolled back) state transaction
public struct CompletedStateTransaction<State: Sendable>: Sendable {
    // MARK: Properties
    
    /// Unique identifier for this transaction
    public let id: TransactionID
    
    /// The state before transaction
    public let beforeSnapshot: StateSnapshot<State>
    
    /// The state after transaction (nil for rollbacks)
    public let afterSnapshot: StateSnapshot<State>?
    
    /// All operations performed in this transaction
    public let operations: [TransactionOperation]
    
    /// Transaction metadata
    public let metadata: TransactionMetadata
    
    /// Transaction result
    public let result: TransactionResult
    
    /// Time when transaction was started
    public let startTime: Date
    
    /// Time when transaction was completed
    public let completionTime: Date
    
    /// Duration of the transaction
    public var duration: TimeInterval {
        completionTime.timeIntervalSince(startTime)
    }
    
    /// Whether this transaction was committed successfully
    public var wasCommitted: Bool {
        switch result {
        case .committed: return true
        case .rolledBack, .failed: return false
        }
    }
    
    // MARK: Initialization
    
    public init(
        from context: StateTransactionContext<State>,
        result: TransactionResult,
        afterSnapshot: StateSnapshot<State>? = nil
    ) {
        self.id = context.id
        self.beforeSnapshot = context.originalSnapshot
        self.afterSnapshot = afterSnapshot
        self.operations = context.operations
        self.metadata = context.metadata
        self.result = result
        self.startTime = context.startTime
        self.completionTime = Date()
    }
}

// MARK: - Transaction Manager

/// Manages state transactions with validation and rollback capability
public actor StateTransactionManager<State: Sendable> {
    // MARK: Properties
    
    /// Transaction history (limited size with LRU eviction)
    private var transactionHistory: [CompletedStateTransaction<State>] = []
    
    /// Currently active transactions
    private var activeTransactions: [TransactionID: StateTransactionContext<State>] = [:]
    
    /// Maximum history size
    private let maxHistorySize: Int
    
    /// Transaction timeout (default 30 seconds)
    private let defaultTimeout: TimeInterval
    
    // Performance metrics
    private var commitCount: Int = 0
    private var rollbackCount: Int = 0
    private var failureCount: Int = 0
    
    // MARK: Initialization
    
    public init(maxHistorySize: Int = 1000, defaultTimeout: TimeInterval = 30.0) {
        self.maxHistorySize = maxHistorySize
        self.defaultTimeout = defaultTimeout
    }
    
    // MARK: Transaction Management
    
    /// Begins a new transaction with the given state snapshot
    public func beginTransaction(
        from snapshot: StateSnapshot<State>,
        metadata: TransactionMetadata? = nil
    ) -> StateTransactionContext<State> {
        let effectiveMetadata = metadata ?? TransactionMetadata(
            timeout: defaultTimeout,
            tags: ["auto-generated"]
        )
        
        let context = StateTransactionContext(
            originalSnapshot: snapshot,
            metadata: effectiveMetadata
        )
        
        activeTransactions[context.id] = context
        return context
    }
    
    /// Commits a transaction after validation
    public func commit(
        _ context: StateTransactionContext<State>,
        finalSnapshot: StateSnapshot<State>
    ) async throws {
        // Validate transaction
        try context.validate()
        
        // Remove from active transactions
        activeTransactions.removeValue(forKey: context.id)
        
        // Create completed transaction record
        let completed = CompletedStateTransaction(
            from: context,
            result: .committed,
            afterSnapshot: finalSnapshot
        )
        
        // Add to history
        addToHistory(completed)
        commitCount += 1
    }
    
    /// Rolls back a transaction
    public func rollback(_ context: StateTransactionContext<State>) async {
        // Remove from active transactions
        activeTransactions.removeValue(forKey: context.id)
        
        // Create completed transaction record
        let completed = CompletedStateTransaction(
            from: context,
            result: .rolledBack,
            afterSnapshot: nil
        )
        
        // Add to history
        addToHistory(completed)
        rollbackCount += 1
    }
    
    /// Records a failed transaction
    public func recordFailure(
        _ context: StateTransactionContext<State>,
        error: Error
    ) async {
        // Remove from active transactions
        activeTransactions.removeValue(forKey: context.id)
        
        // Create completed transaction record
        let completed = CompletedStateTransaction(
            from: context,
            result: .failed(error),
            afterSnapshot: nil
        )
        
        // Add to history
        addToHistory(completed)
        failureCount += 1
    }
    
    /// Gets transaction history with optional filtering
    public func getTransactionHistory(
        limit: Int = 100,
        filter: TransactionFilter? = nil
    ) -> [CompletedStateTransaction<State>] {
        var filteredHistory = transactionHistory
        
        if let filter = filter {
            filteredHistory = filteredHistory.filter { transaction in
                switch filter {
                case .byResult(let result):
                    switch (transaction.result, result) {
                    case (.committed, .committed),
                         (.rolledBack, .rolledBack):
                        return true
                    case (.failed, .failed):
                        return true
                    default:
                        return false
                    }
                case .byTimeRange(let start, let end):
                    return transaction.startTime >= start && transaction.completionTime <= end
                case .byDuration(let minDuration, let maxDuration):
                    return transaction.duration >= minDuration && transaction.duration <= maxDuration
                }
            }
        }
        
        return Array(filteredHistory.suffix(limit))
    }
    
    /// Gets currently active transactions
    public func getActiveTransactions() -> [StateTransactionContext<State>] {
        Array(activeTransactions.values)
    }
    
    /// Gets transaction statistics
    public func getStatistics() -> TransactionStatistics {
        TransactionStatistics(
            totalTransactions: commitCount + rollbackCount + failureCount,
            commitCount: commitCount,
            rollbackCount: rollbackCount,
            failureCount: failureCount,
            activeCount: activeTransactions.count,
            averageDuration: calculateAverageDuration()
        )
    }
    
    /// Cleans up expired transactions
    public func cleanupExpiredTransactions() async {
        let now = Date()
        let expiredIds = activeTransactions.compactMap { (id, context) in
            if let timeout = context.metadata.timeout,
               now.timeIntervalSince(context.startTime) > timeout {
                return id
            }
            return nil
        }
        
        for id in expiredIds {
            if let context = activeTransactions.removeValue(forKey: id) {
                let completed = CompletedStateTransaction(
                    from: context,
                    result: .failed(TransactionError.transactionTimeout(
                        id: id,
                        elapsed: now.timeIntervalSince(context.startTime)
                    )),
                    afterSnapshot: nil
                )
                addToHistory(completed)
                failureCount += 1
            }
        }
    }
    
    // MARK: Private Methods
    
    private func addToHistory(_ transaction: CompletedStateTransaction<State>) {
        transactionHistory.append(transaction)
        
        // Enforce size limit with LRU eviction
        if transactionHistory.count > maxHistorySize {
            transactionHistory.removeFirst(transactionHistory.count - maxHistorySize)
        }
    }
    
    private func calculateAverageDuration() -> TimeInterval {
        guard !transactionHistory.isEmpty else { return 0.0 }
        let totalDuration = transactionHistory.reduce(0) { $0 + $1.duration }
        return totalDuration / Double(transactionHistory.count)
    }
}

// MARK: - Supporting Types

/// Unique identifier for transactions
public struct TransactionID: Hashable, Sendable, CustomStringConvertible {
    private let value: String
    
    public init() {
        self.value = UUID().uuidString
    }
    
    public var description: String { value }
}

/// Metadata associated with a transaction
public struct TransactionMetadata: Sendable {
    public let initiator: ComponentID
    public let purpose: String
    public let timeout: TimeInterval?
    public let tags: Set<String>
    public let context: [String: String]
    
    public init(
        initiator: ComponentID = ComponentID("Unknown"),
        purpose: String = "State modification",
        timeout: TimeInterval? = nil,
        tags: Set<String> = [],
        context: [String: String] = [:]
    ) {
        self.initiator = initiator
        self.purpose = purpose
        self.timeout = timeout
        self.tags = tags
        self.context = context
    }
}

/// Represents an operation performed within a transaction
public enum TransactionOperation: Sendable {
    case stateModification(description: String)
    case validation(description: String)
    case rollbackPoint(description: String)
    case customOperation(name: String, details: [String: String])
    
    public var description: String {
        switch self {
        case .stateModification(let desc):
            return "State: \(desc)"
        case .validation(let desc):
            return "Validation: \(desc)"
        case .rollbackPoint(let desc):
            return "Rollback: \(desc)"
        case .customOperation(let name, _):
            return "Custom: \(name)"
        }
    }
}

/// Result of a completed transaction
public enum TransactionResult: Sendable {
    case committed
    case rolledBack
    case failed(Error)
    
    public var isSuccess: Bool {
        switch self {
        case .committed: return true
        case .rolledBack, .failed: return false
        }
    }
}

/// Filter for querying transaction history
public enum TransactionFilter {
    case byResult(TransactionResult)
    case byTimeRange(start: Date, end: Date)
    case byDuration(min: TimeInterval, max: TimeInterval)
}

/// Transaction performance statistics
public struct TransactionStatistics: Sendable {
    public let totalTransactions: Int
    public let commitCount: Int
    public let rollbackCount: Int
    public let failureCount: Int
    public let activeCount: Int
    public let averageDuration: TimeInterval
    
    public var commitRate: Double {
        guard totalTransactions > 0 else { return 0.0 }
        return Double(commitCount) / Double(totalTransactions)
    }
    
    public var rollbackRate: Double {
        guard totalTransactions > 0 else { return 0.0 }
        return Double(rollbackCount) / Double(totalTransactions)
    }
    
    public var failureRate: Double {
        guard totalTransactions > 0 else { return 0.0 }
        return Double(failureCount) / Double(totalTransactions)
    }
}

/// Errors that can occur during transaction processing
public enum TransactionError: Error, CustomStringConvertible {
    case emptyTransaction(id: TransactionID)
    case transactionTimeout(id: TransactionID, elapsed: TimeInterval)
    case conflictingTransaction(id: TransactionID, conflictingId: TransactionID)
    case invalidState(id: TransactionID, reason: String)
    case commitValidationFailed(id: TransactionID, errors: [String])
    
    public var description: String {
        switch self {
        case .emptyTransaction(let id):
            return "Empty transaction: \(id)"
        case .transactionTimeout(let id, let elapsed):
            return "Transaction timeout: \(id) (elapsed: \(elapsed)s)"
        case .conflictingTransaction(let id, let conflictingId):
            return "Conflicting transaction: \(id) conflicts with \(conflictingId)"
        case .invalidState(let id, let reason):
            return "Invalid state in transaction \(id): \(reason)"
        case .commitValidationFailed(let id, let errors):
            return "Commit validation failed for \(id): \(errors.joined(separator: ", "))"
        }
    }
}

// MARK: - Extensions

extension StateTransactionContext: CustomStringConvertible {
    public var description: String {
        "Transaction(id: \(id), operations: \(operations.count), duration: \(Date().timeIntervalSince(startTime))s)"
    }
}

extension CompletedStateTransaction: CustomStringConvertible {
    public var description: String {
        "CompletedTransaction(id: \(id), result: \(result), duration: \(duration)s)"
    }
}

// MARK: - Transaction Result Extensions

extension TransactionResult: CustomStringConvertible {
    public var description: String {
        switch self {
        case .committed:
            return "committed"
        case .rolledBack:
            return "rolledBack"
        case .failed(let error):
            return "failed(\(error))"
        }
    }
}

// Make TransactionResult equatable for filtering
extension TransactionResult: Equatable {
    public static func == (lhs: TransactionResult, rhs: TransactionResult) -> Bool {
        switch (lhs, rhs) {
        case (.committed, .committed), (.rolledBack, .rolledBack):
            return true
        case (.failed(let lError), .failed(let rError)):
            return "\(lError)" == "\(rError)" // Simple string comparison
        default:
            return false
        }
    }
}