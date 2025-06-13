import Foundation
@preconcurrency import CoreData
import Combine

// MARK: - Transaction Infrastructure (W-02-003)

/// Transaction identifier for tracking operations
public struct TransactionID: Hashable, Sendable {
    public let id: UUID
    public let timestamp: Date
    
    public init() {
        self.id = UUID()
        self.timestamp = Date()
    }
    
    public init(id: UUID) {
        self.id = id
        self.timestamp = Date()
    }
}

/// Transaction state tracking
public enum TransactionState: String, CaseIterable, Sendable {
    case pending
    case active
    case committed
    case rolledBack
    case failed
}

/// Transaction isolation levels
public enum IsolationLevel: String, CaseIterable, Sendable {
    case readUncommitted
    case readCommitted
    case repeatableRead
    case serializable
    
    nonisolated public var coreDataMergePolicy: NSMergePolicy {
        switch self {
        case .readUncommitted:
            return NSMergeByPropertyStoreTrumpMergePolicy as! NSMergePolicy
        case .readCommitted:
            return NSMergePolicy.mergeByPropertyObjectTrump
        case .repeatableRead:
            return NSRollbackMergePolicy as! NSMergePolicy
        case .serializable:
            return NSErrorMergePolicy as! NSMergePolicy
        }
    }
}

/// Transaction configuration
public struct TransactionConfiguration: Sendable {
    public let isolationLevel: IsolationLevel
    public let timeout: TimeInterval
    public let allowsNestedTransactions: Bool
    public let enablesConflictResolution: Bool
    public let maxRetryAttempts: Int
    
    public init(
        isolationLevel: IsolationLevel = .readCommitted,
        timeout: TimeInterval = 30.0,
        allowsNestedTransactions: Bool = true,
        enablesConflictResolution: Bool = true,
        maxRetryAttempts: Int = 3
    ) {
        self.isolationLevel = isolationLevel
        self.timeout = timeout
        self.allowsNestedTransactions = allowsNestedTransactions
        self.enablesConflictResolution = enablesConflictResolution
        self.maxRetryAttempts = maxRetryAttempts
    }
    
    public static let `default` = TransactionConfiguration()
    public static let serializable = TransactionConfiguration(isolationLevel: .serializable)
    public static let readOnly = TransactionConfiguration(isolationLevel: .readCommitted, timeout: 10.0)
}

/// Transaction operation that can be committed or rolled back
public protocol TransactionOperation: Sendable {
    var id: UUID { get }
    var operationType: String { get }
    var affectedEntityTypes: Set<String> { get }
    
    mutating func execute(in context: NSManagedObjectContext) async throws
    func rollback(in context: NSManagedObjectContext) async throws
}

/// Transactional context for managing persistence operations
@CoreDataActor
public final class PersistenceTransaction: Sendable {
    public let id: TransactionID
    public let configuration: TransactionConfiguration
    public let parentTransaction: PersistenceTransaction?
    
    private let context: NSManagedObjectContext
    private let operations: SendableContainer<[any TransactionOperation]>
    private let state: SendableContainer<TransactionState>
    private let startTime: Date
    private let savepoints: SendableContainer<[String: NSManagedObjectContext]>
    
    public var currentState: TransactionState {
        state.value
    }
    
    public var isActive: Bool {
        state.value == .active
    }
    
    /// Get the managed object context for this transaction
    public var managedObjectContext: NSManagedObjectContext {
        context
    }
    
    public var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    init(
        configuration: TransactionConfiguration = .default,
        parent: PersistenceTransaction? = nil,
        coreDataStack: CoreDataStack = .shared
    ) {
        self.id = TransactionID()
        self.configuration = configuration
        self.parentTransaction = parent
        self.startTime = Date()
        
        // Create dedicated context for this transaction
        if let parent = parent {
            self.context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            self.context.parent = parent.context
        } else {
            self.context = coreDataStack.newBackgroundContext()
        }
        
        self.context.mergePolicy = configuration.isolationLevel.coreDataMergePolicy
        self.operations = SendableContainer([])
        self.state = SendableContainer(.pending)
        self.savepoints = SendableContainer([:])
    }
    
    /// Begin the transaction
    public func begin() async throws {
        guard state.value == .pending else {
            throw TransactionError.invalidTransactionState("Cannot begin transaction in state: \(state.value)")
        }
        
        state.value = .active
        
        // Set timeout timer
        Task {
            try await Task.sleep(for: .seconds(configuration.timeout))
            if state.value == .active {
                await forceRollback(reason: "Transaction timeout after \(configuration.timeout)s")
            }
        }
    }
    
    /// Add an operation to the transaction
    public func addOperation(_ operation: any TransactionOperation) async throws {
        guard isActive else {
            throw TransactionError.invalidTransactionState("Cannot add operation to inactive transaction")
        }
        
        var mutableOperation = operation
        operations.value.append(mutableOperation)
        try await mutableOperation.execute(in: context)
    }
    
    /// Create a savepoint for partial rollback
    public func createSavepoint(name: String) async throws {
        guard isActive else {
            throw TransactionError.invalidTransactionState("Cannot create savepoint in inactive transaction")
        }
        
        let savepointContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        savepointContext.parent = context
        
        let localContext = self.context
        try await context.perform { @Sendable in
            try localContext.save()
        }
        
        savepoints.value[name] = savepointContext
    }
    
    /// Rollback to a specific savepoint
    public func rollbackToSavepoint(name: String) async throws {
        guard isActive else {
            throw TransactionError.invalidTransactionState("Cannot rollback to savepoint in inactive transaction")
        }
        
        guard savepoints.value[name] != nil else {
            throw TransactionError.savepointNotFound(name)
        }
        
        let localContext = self.context
        await context.perform { @Sendable in
            localContext.rollback()
            localContext.reset()
        }
        
        // Remove savepoints created after this one
        let savepointNames = Array(savepoints.value.keys)
        for spName in savepointNames {
            if spName != name {
                savepoints.value.removeValue(forKey: spName)
            }
        }
    }
    
    /// Commit the transaction
    public func commit() async throws {
        guard isActive else {
            throw TransactionError.invalidTransactionState("Cannot commit inactive transaction")
        }
        
        do {
            let localContext = self.context
            try await context.perform { @Sendable in
                try localContext.save()
            }
            
            // If this is a nested transaction, propagate to parent
            if let parent = parentTransaction {
                let parentContext = parent.context
                try await parent.context.perform { @Sendable in
                    try parentContext.save()
                }
            }
            
            state.value = .committed
            await notifyTransactionCompleted()
            
        } catch {
            state.value = .failed
            throw TransactionError.commitFailed(error)
        }
    }
    
    /// Rollback the transaction
    public func rollback() async throws {
        guard isActive || state.value == .failed else {
            throw TransactionError.invalidTransactionState("Cannot rollback transaction in state: \(state.value)")
        }
        
        // Rollback operations in reverse order
        for operation in operations.value.reversed() {
            try await operation.rollback(in: context)
        }
        
        let localContext = self.context
        await context.perform { @Sendable in
            localContext.rollback()
        }
        
        state.value = .rolledBack
        await notifyTransactionCompleted()
    }
    
    private func forceRollback(reason: String) async {
        do {
            try await rollback()
            print("Transaction \(id.id) force-rolled back: \(reason)")
        } catch {
            print("Failed to force rollback transaction \(id.id): \(error)")
        }
    }
    
    private func notifyTransactionCompleted() async {
        NotificationCenter.default.post(
            name: .transactionCompleted,
            object: nil,
            userInfo: [
                "transactionId": id.id,
                "state": state.value.rawValue,
                "duration": duration
            ]
        )
    }
}

/// Transaction manager for coordinating persistence operations
@CoreDataActor
public final class TransactionManager: Sendable {
    public static let shared = TransactionManager()
    
    private let activeTransactions: SendableContainer<[TransactionID: PersistenceTransaction]>
    private let transactionHistory: SendableContainer<[TransactionID: TransactionState]>
    private let coreDataStack: CoreDataStack
    
    private init(coreDataStack: CoreDataStack = .shared) {
        self.activeTransactions = SendableContainer([:])
        self.transactionHistory = SendableContainer([:])
        self.coreDataStack = coreDataStack
    }
    
    /// Begin a new transaction
    public func beginTransaction(
        configuration: TransactionConfiguration = .default,
        parent: TransactionID? = nil
    ) async throws -> PersistenceTransaction {
        let parentTransaction = parent != nil ? activeTransactions.value[parent!] : nil
        
        guard parentTransaction != nil || parent == nil else {
            throw TransactionError.parentTransactionNotFound(parent!)
        }
        
        let transaction = PersistenceTransaction(
            configuration: configuration,
            parent: parentTransaction,
            coreDataStack: coreDataStack
        )
        
        try await transaction.begin()
        activeTransactions.value[transaction.id] = transaction
        
        return transaction
    }
    
    /// Execute a block within a transaction
    public func withTransaction<T: Sendable>(
        configuration: TransactionConfiguration = .default,
        operation: @Sendable (PersistenceTransaction) async throws -> T
    ) async throws -> T {
        let transaction = try await beginTransaction(configuration: configuration)
        
        defer {
            activeTransactions.value.removeValue(forKey: transaction.id)
            transactionHistory.value[transaction.id] = transaction.currentState
        }
        
        do {
            let result = try await operation(transaction)
            try await transaction.commit()
            return result
        } catch {
            try await transaction.rollback()
            throw error
        }
    }
    
    /// Get an active transaction by ID
    public func transaction(id: TransactionID) -> PersistenceTransaction? {
        return activeTransactions.value[id]
    }
    
    /// Get all active transactions
    public func getActiveTransactions() -> [PersistenceTransaction] {
        return Array(activeTransactions.value.values)
    }
    
    /// Force rollback all active transactions
    public func rollbackAllTransactions() async {
        for transaction in activeTransactions.value.values {
            try? await transaction.rollback()
        }
        activeTransactions.value.removeAll()
    }
    
    /// Get transaction statistics
    public func getStatistics() -> TransactionStatistics {
        let active = activeTransactions.value.count
        let total = transactionHistory.value.count + active
        let committed = transactionHistory.value.values.filter { $0 == .committed }.count
        let rolledBack = transactionHistory.value.values.filter { $0 == .rolledBack }.count
        let failed = transactionHistory.value.values.filter { $0 == .failed }.count
        
        return TransactionStatistics(
            activeTransactions: active,
            totalTransactions: total,
            committedTransactions: committed,
            rolledBackTransactions: rolledBack,
            failedTransactions: failed
        )
    }
}

/// Transaction statistics
public struct TransactionStatistics: Sendable {
    public let activeTransactions: Int
    public let totalTransactions: Int
    public let committedTransactions: Int
    public let rolledBackTransactions: Int
    public let failedTransactions: Int
    
    public var successRate: Double {
        guard totalTransactions > 0 else { return 0.0 }
        return Double(committedTransactions) / Double(totalTransactions)
    }
    
    public var failureRate: Double {
        guard totalTransactions > 0 else { return 0.0 }
        return Double(rolledBackTransactions + failedTransactions) / Double(totalTransactions)
    }
}

// MARK: - Concrete Transaction Operations

/// Core Data entity insertion operation
public struct EntityInsertOperation<T: NSManagedObject>: TransactionOperation, @unchecked Sendable {
    public let id = UUID()
    public let operationType = "insert"
    public let entityName: String
    public let entityData: [String: Any]
    public var affectedEntityTypes: Set<String> { [entityName] }
    
    private var insertedObjectID: NSManagedObjectID?
    
    public init(entityName: String, data: [String: Any]) {
        self.entityName = entityName
        self.entityData = data
    }
    
    public mutating func execute(in context: NSManagedObjectContext) async throws {
        let entityName = self.entityName
        let entityData = self.entityData
        
        let objectID: NSManagedObjectID = try await context.perform {
            guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
                throw TransactionError.entityNotFound(entityName)
            }
            
            let object = T(entity: entity, insertInto: context)
            
            for (key, value) in entityData {
                object.setValue(value, forKey: key)
            }
            
            return object.objectID
        }
        
        self.insertedObjectID = objectID
    }
    
    public func rollback(in context: NSManagedObjectContext) async throws {
        if let objectID = insertedObjectID {
            await context.perform {
                if let object = try? context.existingObject(with: objectID) {
                    context.delete(object)
                }
            }
        }
    }
}

/// Core Data entity update operation
public struct EntityUpdateOperation: TransactionOperation, @unchecked Sendable {
    public let id = UUID()
    public let operationType = "update"
    public let entityName: String
    public let predicateData: Data // Store as Data to make it Sendable
    public let updates: [String: Any]
    
    private var predicate: NSPredicate? {
        try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPredicate.self, from: predicateData)
    }
    public var affectedEntityTypes: Set<String> { [entityName] }
    
    private var originalValues: [[String: Any]] = []
    private var updatedObjectIDs: [NSManagedObjectID] = []
    
    public init(entityName: String, predicate: NSPredicate, updates: [String: Any]) {
        self.entityName = entityName
        self.predicateData = (try? NSKeyedArchiver.archivedData(withRootObject: predicate, requiringSecureCoding: true)) ?? Data()
        self.updates = updates
    }
    
    public mutating func execute(in context: NSManagedObjectContext) async throws {
        let entityName = self.entityName
        let predicate = self.predicate
        let updates = self.updates
        
        let (originalValues, updatedObjectIDs): ([[String: Any]], [NSManagedObjectID]) = try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            request.predicate = predicate
            
            let objects = try context.fetch(request)
            var originalValuesResult: [[String: Any]] = []
            var updatedObjectIDsResult: [NSManagedObjectID] = []
            
            for object in objects {
                // Store original values for rollback
                var originalValue: [String: Any] = [:]
                for key in updates.keys {
                    if let value = object.value(forKey: key) {
                        originalValue[key] = value
                    }
                }
                originalValuesResult.append(originalValue)
                
                // Apply updates
                for (key, value) in updates {
                    object.setValue(value, forKey: key)
                }
                
                updatedObjectIDsResult.append(object.objectID)
            }
            
            return (originalValuesResult, updatedObjectIDsResult)
        }
        
        self.originalValues = originalValues
        self.updatedObjectIDs = updatedObjectIDs
    }
    
    public func rollback(in context: NSManagedObjectContext) async throws {
        await context.perform {
            for (index, objectID) in self.updatedObjectIDs.enumerated() {
                guard index < self.originalValues.count else { continue }
                guard let object = try? context.existingObject(with: objectID) else { continue }
                
                let originalValue = self.originalValues[index]
                for (key, value) in originalValue {
                    object.setValue(value, forKey: key)
                }
            }
        }
    }
}

/// Core Data entity deletion operation
public struct EntityDeleteOperation: TransactionOperation, @unchecked Sendable {
    public let id = UUID()
    public let operationType = "delete"
    public let entityName: String
    public let predicateData: Data // Store as Data to make it Sendable
    public var affectedEntityTypes: Set<String> { [entityName] }
    
    private var predicate: NSPredicate? {
        try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPredicate.self, from: predicateData)
    }
    
    private var deletedObjectsData: [(objectID: NSManagedObjectID, data: [String: Any])] = []
    
    public init(entityName: String, predicate: NSPredicate) {
        self.entityName = entityName
        self.predicateData = (try? NSKeyedArchiver.archivedData(withRootObject: predicate, requiringSecureCoding: true)) ?? Data()
    }
    
    public mutating func execute(in context: NSManagedObjectContext) async throws {
        let entityName = self.entityName
        let predicate = self.predicate
        
        let deletedData: [(objectID: NSManagedObjectID, data: [String: Any])] = try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            request.predicate = predicate
            
            let objects = try context.fetch(request)
            var results: [(objectID: NSManagedObjectID, data: [String: Any])] = []
            
            for object in objects {
                // Store object data for rollback
                var objectData: [String: Any] = [:]
                let attributes = object.entity.attributesByName
                for (key, _) in attributes {
                    if let value = object.value(forKey: key) {
                        objectData[key] = value
                    }
                }
                
                results.append((object.objectID, objectData))
                context.delete(object)
            }
            
            return results
        }
        
        self.deletedObjectsData = deletedData
    }
    
    public func rollback(in context: NSManagedObjectContext) async throws {
        try await context.perform {
            for (_, data) in self.deletedObjectsData {
                guard let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: context) else {
                    throw TransactionError.entityNotFound(self.entityName)
                }
                
                let restoredObject = NSManagedObject(entity: entity, insertInto: context)
                for (key, value) in data {
                    restoredObject.setValue(value, forKey: key)
                }
            }
        }
    }
}

// MARK: - Error Types

public enum TransactionError: LocalizedError, Sendable {
    case invalidTransactionState(String)
    case commitFailed(any Error)
    case parentTransactionNotFound(TransactionID)
    case savepointNotFound(String)
    case entityNotFound(String)
    case conflictResolutionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidTransactionState(let message):
            return "Invalid transaction state: \(message)"
        case .commitFailed(let error):
            return "Transaction commit failed: \(error.localizedDescription)"
        case .parentTransactionNotFound(let id):
            return "Parent transaction not found: \(id.id)"
        case .savepointNotFound(let name):
            return "Savepoint not found: \(name)"
        case .entityNotFound(let name):
            return "Entity not found: \(name)"
        case .conflictResolutionFailed(let message):
            return "Conflict resolution failed: \(message)"
        }
    }
}

// MARK: - Sendable Container

private final class SendableContainer<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T
    
    init(_ value: T) {
        self._value = value
    }
    
    var value: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }
}

// MARK: - Extensions

extension CoreDataStack {
    /// Create a new background context for transactions
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }
}

extension Notification.Name {
    static let transactionCompleted = Notification.Name("TransactionCompleted")
}

// MARK: - High-Level API

/// Convenient transaction execution functions
public extension TransactionManager {
    /// Execute a read-only operation
    func read<T: Sendable>(_ operation: @Sendable (NSManagedObjectContext) async throws -> T) async throws -> T {
        return try await withTransaction(configuration: .readOnly) { transaction in
            return try await operation(transaction.managedObjectContext)
        }
    }
    
    /// Execute a write operation
    func write<T: Sendable>(_ operation: @Sendable (PersistenceTransaction) async throws -> T) async throws -> T {
        return try await withTransaction { transaction in
            return try await operation(transaction)
        }
    }
    
    /// Execute a serializable transaction
    func serializable<T: Sendable>(_ operation: @Sendable (PersistenceTransaction) async throws -> T) async throws -> T {
        return try await withTransaction(configuration: .serializable) { transaction in
            return try await operation(transaction)
        }
    }
}