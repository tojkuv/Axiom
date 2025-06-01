import Foundation
import Axiom

// MARK: - Data Domain State

/// Sophisticated data state demonstrating complex CRUD operations,
/// caching strategies, and repository patterns for comprehensive framework testing
public struct DataState: Sendable {
    
    // MARK: - Repository Collections
    
    public var items: [String: DataItem] = [:]
    public var collections: [String: DataCollection] = [:]
    public var queries: [String: DataQuery] = [:]
    
    // MARK: - Cache Management
    
    public var cacheMetrics: CacheMetrics
    public var cacheStrategy: CacheStrategy
    public var cachePolicies: [String: CachePolicy]
    
    // MARK: - Synchronization State
    
    public var syncStatus: SyncStatus
    public var pendingOperations: [DataOperation]
    public var conflictResolutions: [ConflictResolution]
    public var lastSyncTimestamp: Date?
    
    // MARK: - Performance Tracking
    
    public var operationMetrics: OperationMetrics
    public var queryPerformance: [String: QueryPerformance]
    public var indexUsage: [String: IndexUsage]
    
    // MARK: - Validation and Integrity
    
    public var validationRules: [DataValidationRule]
    public var integrityChecks: [IntegrityCheck]
    public var dataQualityScore: Double
    public var validationErrors: [DataValidationError]
    
    // MARK: - Transaction Management
    
    public var activeTransactions: [String: DataTransaction]
    public var transactionHistory: [TransactionRecord]
    public var rollbackPoints: [String: RollbackPoint]
    
    // MARK: - Advanced Features
    
    public var schemaVersion: String
    public var migrationStatus: MigrationStatus
    public var backupInfo: BackupInfo?
    public var compressionStats: CompressionStats
    
    // MARK: - Initialization
    
    public init(
        items: [String: DataItem] = [:],
        collections: [String: DataCollection] = [:],
        queries: [String: DataQuery] = [:],
        cacheMetrics: CacheMetrics = CacheMetrics(),
        cacheStrategy: CacheStrategy = .adaptive,
        cachePolicies: [String: CachePolicy] = [:],
        syncStatus: SyncStatus = .idle,
        pendingOperations: [DataOperation] = [],
        conflictResolutions: [ConflictResolution] = [],
        lastSyncTimestamp: Date? = nil,
        operationMetrics: OperationMetrics = OperationMetrics(),
        queryPerformance: [String: QueryPerformance] = [:],
        indexUsage: [String: IndexUsage] = [:],
        validationRules: [DataValidationRule] = [],
        integrityChecks: [IntegrityCheck] = [],
        dataQualityScore: Double = 1.0,
        validationErrors: [DataValidationError] = [],
        activeTransactions: [String: DataTransaction] = [:],
        transactionHistory: [TransactionRecord] = [],
        rollbackPoints: [String: RollbackPoint] = [:],
        schemaVersion: String = "1.0.0",
        migrationStatus: MigrationStatus = .current,
        backupInfo: BackupInfo? = nil,
        compressionStats: CompressionStats = CompressionStats()
    ) {
        self.items = items
        self.collections = collections
        self.queries = queries
        self.cacheMetrics = cacheMetrics
        self.cacheStrategy = cacheStrategy
        self.cachePolicies = cachePolicies
        self.syncStatus = syncStatus
        self.pendingOperations = pendingOperations
        self.conflictResolutions = conflictResolutions
        self.lastSyncTimestamp = lastSyncTimestamp
        self.operationMetrics = operationMetrics
        self.queryPerformance = queryPerformance
        self.indexUsage = indexUsage
        self.validationRules = validationRules
        self.integrityChecks = integrityChecks
        self.dataQualityScore = dataQualityScore
        self.validationErrors = validationErrors
        self.activeTransactions = activeTransactions
        self.transactionHistory = transactionHistory
        self.rollbackPoints = rollbackPoints
        self.schemaVersion = schemaVersion
        self.migrationStatus = migrationStatus
        self.backupInfo = backupInfo
        self.compressionStats = compressionStats
    }
    
    // MARK: - CRUD Operations
    
    public mutating func createItem(_ item: DataItem) throws -> String {
        // Validate item before creation
        try validateItem(item)
        
        let id = item.id
        
        // Check for duplicates
        if items[id] != nil {
            throw DataStateError.duplicateItem(id)
        }
        
        // Apply any creation transformations
        var processedItem = item
        processedItem.createdAt = Date()
        processedItem.updatedAt = Date()
        processedItem.version = 1
        
        // Store item
        items[id] = processedItem
        
        // Update metrics
        operationMetrics.createOperations += 1
        operationMetrics.totalItems = items.count
        
        // Add to pending operations for sync
        pendingOperations.append(DataOperation(
            type: .create,
            itemId: id,
            timestamp: Date(),
            data: processedItem.data
        ))
        
        return id
    }
    
    public func readItem(id: String) -> DataItem? {
        let item = items[id]
        
        // Update access metrics
        if let existingItem = item {
            var updatedMetrics = operationMetrics
            updatedMetrics.readOperations += 1
            updatedMetrics.lastAccessTime = Date()
        }
        
        return item
    }
    
    public mutating func updateItem(id: String, data: [String: Any]) throws {
        guard var item = items[id] else {
            throw DataStateError.itemNotFound(id)
        }
        
        // Validate update
        let updatedItem = DataItem(
            id: item.id,
            type: item.type,
            data: data,
            metadata: item.metadata,
            createdAt: item.createdAt,
            updatedAt: Date(),
            version: item.version + 1
        )
        
        try validateItem(updatedItem)
        
        // Store updated item
        items[id] = updatedItem
        
        // Update metrics
        operationMetrics.updateOperations += 1
        
        // Add to pending operations
        pendingOperations.append(DataOperation(
            type: .update,
            itemId: id,
            timestamp: Date(),
            data: data
        ))
    }
    
    public mutating func deleteItem(id: String) throws {
        guard items[id] != nil else {
            throw DataStateError.itemNotFound(id)
        }
        
        // Soft delete by default
        if var item = items[id] {
            item.metadata["deleted"] = true
            item.metadata["deletedAt"] = Date().timeIntervalSince1970
            item.updatedAt = Date()
            items[id] = item
        }
        
        // Update metrics
        operationMetrics.deleteOperations += 1
        
        // Add to pending operations
        pendingOperations.append(DataOperation(
            type: .delete,
            itemId: id,
            timestamp: Date(),
            data: [:]
        ))
    }
    
    public mutating func hardDeleteItem(id: String) throws {
        guard items[id] != nil else {
            throw DataStateError.itemNotFound(id)
        }
        
        items.removeValue(forKey: id)
        operationMetrics.totalItems = items.count
        operationMetrics.deleteOperations += 1
        
        // Add to pending operations
        pendingOperations.append(DataOperation(
            type: .hardDelete,
            itemId: id,
            timestamp: Date(),
            data: [:]
        ))
    }
    
    // MARK: - Collection Operations
    
    public mutating func createCollection(_ collection: DataCollection) throws {
        let id = collection.id
        
        if collections[id] != nil {
            throw DataStateError.duplicateCollection(id)
        }
        
        collections[id] = collection
        operationMetrics.collectionOperations += 1
    }
    
    public func getCollection(id: String) -> DataCollection? {
        return collections[id]
    }
    
    public func queryCollection(id: String, query: DataQuery) -> [DataItem] {
        guard let collection = collections[id] else { return [] }
        
        let results = collection.itemIds.compactMap { items[$0] }
            .filter { query.matches($0) }
        
        // Update query performance metrics
        var queryMetrics = queryPerformance[query.id] ?? QueryPerformance(queryId: query.id)
        queryMetrics.executionCount += 1
        queryMetrics.lastExecutionTime = Date()
        queryMetrics.averageResultCount = (queryMetrics.averageResultCount + Double(results.count)) / 2.0
        
        return results
    }
    
    // MARK: - Cache Management
    
    public mutating func updateCacheMetrics(hitCount: Int, missCount: Int, evictionCount: Int) {
        cacheMetrics.hitCount += hitCount
        cacheMetrics.missCount += missCount
        cacheMetrics.evictionCount += evictionCount
        cacheMetrics.lastUpdated = Date()
        
        // Calculate hit rate
        let totalRequests = cacheMetrics.hitCount + cacheMetrics.missCount
        cacheMetrics.hitRate = totalRequests > 0 ? Double(cacheMetrics.hitCount) / Double(totalRequests) : 0.0
    }
    
    public mutating func setCachePolicy(forType type: String, policy: CachePolicy) {
        cachePolicies[type] = policy
    }
    
    public func getCachePolicy(forType type: String) -> CachePolicy {
        return cachePolicies[type] ?? CachePolicy.default
    }
    
    // MARK: - Transaction Management
    
    public mutating func beginTransaction(id: String) throws {
        if activeTransactions[id] != nil {
            throw DataStateError.transactionAlreadyActive(id)
        }
        
        let transaction = DataTransaction(
            id: id,
            startTime: Date(),
            operations: [],
            status: .active
        )
        
        activeTransactions[id] = transaction
        
        // Create rollback point
        rollbackPoints[id] = RollbackPoint(
            transactionId: id,
            timestamp: Date(),
            snapshot: self
        )
    }
    
    public mutating func commitTransaction(id: String) throws {
        guard let transaction = activeTransactions[id] else {
            throw DataStateError.transactionNotFound(id)
        }
        
        // Mark transaction as committed
        var committedTransaction = transaction
        committedTransaction.status = .committed
        committedTransaction.endTime = Date()
        
        // Move to history
        transactionHistory.append(TransactionRecord(
            transactionId: id,
            startTime: transaction.startTime,
            endTime: Date(),
            operationCount: transaction.operations.count,
            status: .committed
        ))
        
        // Clean up
        activeTransactions.removeValue(forKey: id)
        rollbackPoints.removeValue(forKey: id)
    }
    
    public mutating func rollbackTransaction(id: String) throws {
        guard let rollbackPoint = rollbackPoints[id] else {
            throw DataStateError.rollbackPointNotFound(id)
        }
        
        // Restore state from rollback point
        self = rollbackPoint.snapshot
        
        // Update transaction history
        if let transaction = activeTransactions[id] {
            transactionHistory.append(TransactionRecord(
                transactionId: id,
                startTime: transaction.startTime,
                endTime: Date(),
                operationCount: transaction.operations.count,
                status: .rolledBack
            ))
        }
        
        // Clean up
        activeTransactions.removeValue(forKey: id)
        rollbackPoints.removeValue(forKey: id)
    }
    
    // MARK: - Validation
    
    public mutating func validate() {
        validationErrors.removeAll()
        
        // Validate all items
        for (id, item) in items {
            do {
                try validateItem(item)
            } catch let error as DataStateError {
                validationErrors.append(DataValidationError(
                    itemId: id,
                    errorType: .itemValidation,
                    message: error.localizedDescription
                ))
            } catch {
                validationErrors.append(DataValidationError(
                    itemId: id,
                    errorType: .unknown,
                    message: error.localizedDescription
                ))
            }
        }
        
        // Run integrity checks
        for check in integrityChecks {
            if !check.isValid(for: self) {
                validationErrors.append(DataValidationError(
                    itemId: nil,
                    errorType: .integrityViolation,
                    message: check.description
                ))
            }
        }
        
        // Calculate data quality score
        calculateDataQualityScore()
    }
    
    private func validateItem(_ item: DataItem) throws {
        // Check required fields
        if item.id.isEmpty {
            throw DataStateError.missingRequiredField("id")
        }
        
        if item.type.isEmpty {
            throw DataStateError.missingRequiredField("type")
        }
        
        // Apply validation rules
        for rule in validationRules {
            if !rule.validate(item) {
                throw DataStateError.validationRuleViolation(rule.description)
            }
        }
        
        // Type-specific validation
        switch item.type {
        case "user":
            try validateUserItem(item)
        case "document":
            try validateDocumentItem(item)
        case "media":
            try validateMediaItem(item)
        default:
            break
        }
    }
    
    private func validateUserItem(_ item: DataItem) throws {
        guard let email = item.data["email"] as? String, !email.isEmpty else {
            throw DataStateError.missingRequiredField("email")
        }
        
        // Email format validation
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        if email.range(of: emailRegex, options: .regularExpression) == nil {
            throw DataStateError.invalidFieldFormat("email")
        }
    }
    
    private func validateDocumentItem(_ item: DataItem) throws {
        guard let content = item.data["content"] as? String, !content.isEmpty else {
            throw DataStateError.missingRequiredField("content")
        }
        
        guard let title = item.data["title"] as? String, !title.isEmpty else {
            throw DataStateError.missingRequiredField("title")
        }
    }
    
    private func validateMediaItem(_ item: DataItem) throws {
        guard let url = item.data["url"] as? String, !url.isEmpty else {
            throw DataStateError.missingRequiredField("url")
        }
        
        guard let fileSize = item.data["fileSize"] as? Int, fileSize > 0 else {
            throw DataStateError.invalidFieldFormat("fileSize")
        }
    }
    
    // MARK: - Quality Metrics
    
    private mutating func calculateDataQualityScore() {
        let totalItems = items.count
        guard totalItems > 0 else {
            dataQualityScore = 1.0
            return
        }
        
        var score = 0.0
        var factors = 0
        
        // Completeness factor
        let completeItems = items.values.filter { isItemComplete($0) }.count
        score += Double(completeItems) / Double(totalItems)
        factors += 1
        
        // Validity factor
        let validItems = items.values.filter { isItemValid($0) }.count
        score += Double(validItems) / Double(totalItems)
        factors += 1
        
        // Freshness factor
        let freshItems = items.values.filter { isItemFresh($0) }.count
        score += Double(freshItems) / Double(totalItems)
        factors += 1
        
        // Consistency factor (no duplicates)
        let uniqueItems = Set(items.values.map { $0.data.description }).count
        score += Double(uniqueItems) / Double(totalItems)
        factors += 1
        
        dataQualityScore = factors > 0 ? score / Double(factors) : 1.0
    }
    
    private func isItemComplete(_ item: DataItem) -> Bool {
        // Check if all required fields are present based on type
        switch item.type {
        case "user":
            return item.data["email"] != nil && item.data["name"] != nil
        case "document":
            return item.data["title"] != nil && item.data["content"] != nil
        case "media":
            return item.data["url"] != nil && item.data["fileSize"] != nil
        default:
            return !item.data.isEmpty
        }
    }
    
    private func isItemValid(_ item: DataItem) -> Bool {
        do {
            try validateItem(item)
            return true
        } catch {
            return false
        }
    }
    
    private func isItemFresh(_ item: DataItem) -> Bool {
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        return item.updatedAt > thirtyDaysAgo
    }
    
    // MARK: - Computed Properties
    
    public var isValid: Bool {
        return validationErrors.isEmpty
    }
    
    public var totalItemCount: Int {
        return items.count
    }
    
    public var activeItemCount: Int {
        return items.values.filter { !($0.metadata["deleted"] as? Bool ?? false) }.count
    }
    
    public var deletedItemCount: Int {
        return items.values.filter { $0.metadata["deleted"] as? Bool ?? false }.count
    }
    
    public var syncProgress: Double {
        guard !pendingOperations.isEmpty else { return 1.0 }
        // This would be calculated based on actual sync progress
        return 0.0
    }
    
    public var cacheEfficiency: Double {
        return cacheMetrics.hitRate
    }
}

// MARK: - Supporting Data Types

public struct DataItem: Sendable, Hashable {
    public let id: String
    public let type: String
    public var data: [String: Any]
    public var metadata: [String: Any]
    public var createdAt: Date
    public var updatedAt: Date
    public var version: Int
    
    public init(
        id: String = UUID().uuidString,
        type: String,
        data: [String: Any],
        metadata: [String: Any] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        version: Int = 1
    ) {
        self.id = id
        self.type = type
        self.data = data
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.version = version
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: DataItem, rhs: DataItem) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct DataCollection: Sendable {
    public let id: String
    public let name: String
    public var itemIds: Set<String>
    public var metadata: [String: Any]
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        itemIds: Set<String> = [],
        metadata: [String: Any] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.itemIds = itemIds
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct DataQuery: Sendable {
    public let id: String
    public let predicate: String
    public let sortDescriptors: [String]
    public let limit: Int?
    public let offset: Int?
    
    public init(
        id: String = UUID().uuidString,
        predicate: String,
        sortDescriptors: [String] = [],
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.id = id
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.limit = limit
        self.offset = offset
    }
    
    public func matches(_ item: DataItem) -> Bool {
        // Simplified query matching - in production would use proper query engine
        if predicate.contains("type") {
            let typeMatch = predicate.components(separatedBy: "=").last?.trimmingCharacters(in: .whitespaces)
            return item.type == typeMatch
        }
        return true
    }
}

// MARK: - Cache Types

public struct CacheMetrics: Sendable {
    public var hitCount: Int
    public var missCount: Int
    public var evictionCount: Int
    public var hitRate: Double
    public var lastUpdated: Date
    
    public init(
        hitCount: Int = 0,
        missCount: Int = 0,
        evictionCount: Int = 0,
        hitRate: Double = 0.0,
        lastUpdated: Date = Date()
    ) {
        self.hitCount = hitCount
        self.missCount = missCount
        self.evictionCount = evictionCount
        self.hitRate = hitRate
        self.lastUpdated = lastUpdated
    }
}

public enum CacheStrategy: String, CaseIterable, Sendable {
    case none = "none"
    case lru = "lru"
    case lfu = "lfu"
    case adaptive = "adaptive"
    case writeThrough = "write_through"
    case writeBack = "write_back"
}

public struct CachePolicy: Sendable {
    public let maxSize: Int
    public let ttl: TimeInterval
    public let strategy: CacheStrategy
    public let compressionEnabled: Bool
    
    public init(
        maxSize: Int = 1000,
        ttl: TimeInterval = 3600,
        strategy: CacheStrategy = .lru,
        compressionEnabled: Bool = false
    ) {
        self.maxSize = maxSize
        self.ttl = ttl
        self.strategy = strategy
        self.compressionEnabled = compressionEnabled
    }
    
    public static let `default` = CachePolicy()
}

// MARK: - Operation Types

public enum SyncStatus: String, CaseIterable, Sendable {
    case idle = "idle"
    case syncing = "syncing"
    case error = "error"
    case completed = "completed"
}

public struct DataOperation: Sendable {
    public let type: OperationType
    public let itemId: String
    public let timestamp: Date
    public let data: [String: Any]
    
    public enum OperationType: String, CaseIterable, Sendable {
        case create = "create"
        case update = "update"
        case delete = "delete"
        case hardDelete = "hard_delete"
    }
}

public struct ConflictResolution: Sendable {
    public let itemId: String
    public let conflictType: ConflictType
    public let resolution: ResolutionStrategy
    public let timestamp: Date
    
    public enum ConflictType: String, CaseIterable, Sendable {
        case versionMismatch = "version_mismatch"
        case simultaneousEdit = "simultaneous_edit"
        case deleteConflict = "delete_conflict"
    }
    
    public enum ResolutionStrategy: String, CaseIterable, Sendable {
        case clientWins = "client_wins"
        case serverWins = "server_wins"
        case merge = "merge"
        case manual = "manual"
    }
}

// MARK: - Performance Types

public struct OperationMetrics: Sendable {
    public var createOperations: Int
    public var readOperations: Int
    public var updateOperations: Int
    public var deleteOperations: Int
    public var collectionOperations: Int
    public var totalItems: Int
    public var lastAccessTime: Date?
    
    public init(
        createOperations: Int = 0,
        readOperations: Int = 0,
        updateOperations: Int = 0,
        deleteOperations: Int = 0,
        collectionOperations: Int = 0,
        totalItems: Int = 0,
        lastAccessTime: Date? = nil
    ) {
        self.createOperations = createOperations
        self.readOperations = readOperations
        self.updateOperations = updateOperations
        self.deleteOperations = deleteOperations
        self.collectionOperations = collectionOperations
        self.totalItems = totalItems
        self.lastAccessTime = lastAccessTime
    }
    
    public var totalOperations: Int {
        return createOperations + readOperations + updateOperations + deleteOperations + collectionOperations
    }
}

public struct QueryPerformance: Sendable {
    public let queryId: String
    public var executionCount: Int
    public var averageExecutionTime: TimeInterval
    public var averageResultCount: Double
    public var lastExecutionTime: Date?
    
    public init(
        queryId: String,
        executionCount: Int = 0,
        averageExecutionTime: TimeInterval = 0,
        averageResultCount: Double = 0,
        lastExecutionTime: Date? = nil
    ) {
        self.queryId = queryId
        self.executionCount = executionCount
        self.averageExecutionTime = averageExecutionTime
        self.averageResultCount = averageResultCount
        self.lastExecutionTime = lastExecutionTime
    }
}

public struct IndexUsage: Sendable {
    public let indexName: String
    public var usageCount: Int
    public var lastUsed: Date?
    
    public init(indexName: String, usageCount: Int = 0, lastUsed: Date? = nil) {
        self.indexName = indexName
        self.usageCount = usageCount
        self.lastUsed = lastUsed
    }
}

// MARK: - Validation Types

public struct DataValidationRule: Sendable {
    public let id: String
    public let description: String
    public let validate: (DataItem) -> Bool
    
    public init(id: String, description: String, validate: @escaping (DataItem) -> Bool) {
        self.id = id
        self.description = description
        self.validate = validate
    }
}

public struct IntegrityCheck: Sendable {
    public let id: String
    public let description: String
    public let isValid: (DataState) -> Bool
    
    public init(id: String, description: String, isValid: @escaping (DataState) -> Bool) {
        self.id = id
        self.description = description
        self.isValid = isValid
    }
}

public struct DataValidationError: Sendable {
    public let itemId: String?
    public let errorType: ErrorType
    public let message: String
    
    public enum ErrorType: String, CaseIterable, Sendable {
        case itemValidation = "item_validation"
        case integrityViolation = "integrity_violation"
        case unknown = "unknown"
    }
}

// MARK: - Transaction Types

public struct DataTransaction: Sendable {
    public let id: String
    public let startTime: Date
    public var endTime: Date?
    public var operations: [DataOperation]
    public var status: TransactionStatus
    
    public enum TransactionStatus: String, CaseIterable, Sendable {
        case active = "active"
        case committed = "committed"
        case rolledBack = "rolled_back"
        case failed = "failed"
    }
}

public struct TransactionRecord: Sendable {
    public let transactionId: String
    public let startTime: Date
    public let endTime: Date
    public let operationCount: Int
    public let status: DataTransaction.TransactionStatus
}

public struct RollbackPoint: Sendable {
    public let transactionId: String
    public let timestamp: Date
    public let snapshot: DataState
}

// MARK: - Advanced Feature Types

public enum MigrationStatus: String, CaseIterable, Sendable {
    case current = "current"
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case failed = "failed"
}

public struct BackupInfo: Sendable {
    public let lastBackupTime: Date
    public let backupSize: Int
    public let backupLocation: String
    public let isAutomatic: Bool
}

public struct CompressionStats: Sendable {
    public var originalSize: Int
    public var compressedSize: Int
    public var compressionRatio: Double
    
    public init(originalSize: Int = 0, compressedSize: Int = 0) {
        self.originalSize = originalSize
        self.compressedSize = compressedSize
        self.compressionRatio = originalSize > 0 ? Double(compressedSize) / Double(originalSize) : 1.0
    }
}

// MARK: - Error Types

public enum DataStateError: Error, LocalizedError {
    case duplicateItem(String)
    case duplicateCollection(String)
    case itemNotFound(String)
    case collectionNotFound(String)
    case missingRequiredField(String)
    case invalidFieldFormat(String)
    case validationRuleViolation(String)
    case transactionAlreadyActive(String)
    case transactionNotFound(String)
    case rollbackPointNotFound(String)
    case syncError(String)
    case cacheError(String)
    
    public var errorDescription: String? {
        switch self {
        case .duplicateItem(let id):
            return "Item with ID '\(id)' already exists"
        case .duplicateCollection(let id):
            return "Collection with ID '\(id)' already exists"
        case .itemNotFound(let id):
            return "Item with ID '\(id)' not found"
        case .collectionNotFound(let id):
            return "Collection with ID '\(id)' not found"
        case .missingRequiredField(let field):
            return "Required field '\(field)' is missing"
        case .invalidFieldFormat(let field):
            return "Field '\(field)' has invalid format"
        case .validationRuleViolation(let rule):
            return "Validation rule violation: \(rule)"
        case .transactionAlreadyActive(let id):
            return "Transaction '\(id)' is already active"
        case .transactionNotFound(let id):
            return "Transaction '\(id)' not found"
        case .rollbackPointNotFound(let id):
            return "Rollback point for transaction '\(id)' not found"
        case .syncError(let message):
            return "Sync error: \(message)"
        case .cacheError(let message):
            return "Cache error: \(message)"
        }
    }
}

// MARK: - CustomStringConvertible

extension DataState: CustomStringConvertible {
    public var description: String {
        """
        DataState(items: \(items.count), collections: \(collections.count), syncStatus: \(syncStatus.rawValue), quality: \(String(format: "%.1f%%", dataQualityScore * 100)))
        """
    }
}

extension DataState: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        DataState {
            items: \(items.count)
            collections: \(collections.count)
            cacheHitRate: \(String(format: "%.1f%%", cacheMetrics.hitRate * 100))
            syncStatus: \(syncStatus.rawValue)
            pendingOperations: \(pendingOperations.count)
            dataQuality: \(String(format: "%.1f%%", dataQualityScore * 100))
            validationErrors: \(validationErrors.count)
            activeTransactions: \(activeTransactions.count)
        }
        """
    }
}