import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - Data Migration Capability Configuration

/// Configuration for Data Migration capability
public struct DataMigrationCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableAutomaticMigration: Bool
    public let enableBackupBeforeMigration: Bool
    public let enableRollback: Bool
    public let migrationTimeout: TimeInterval
    public let maxBackupSize: UInt64
    public let batchSize: Int
    public let enableValidation: Bool
    public let enableProgressTracking: Bool
    public let enableAnalytics: Bool
    public let compressionEnabled: Bool
    public let encryptionEnabled: Bool
    public let migrationStrategies: [String: MigrationStrategy]
    public let validationRules: [String: ValidationConfig]
    public let customTransformers: [String: String]
    
    public enum MigrationStrategy: String, Codable, CaseIterable {
        case conservative = "conservative"   // Minimal changes, preserve data
        case aggressive = "aggressive"       // Optimize structure, may lose some data
        case smart = "smart"                // Analyze and choose best approach
        case custom = "custom"              // Use custom migration logic
    }
    
    public struct ValidationConfig: Codable {
        public let required: Bool
        public let dataType: String
        public let constraints: [String: Any]
        public let customValidator: String?
        
        public init(
            required: Bool = false,
            dataType: String = "any",
            constraints: [String: Any] = [:],
            customValidator: String? = nil
        ) {
            self.required = required
            self.dataType = dataType
            self.constraints = constraints
            self.customValidator = customValidator
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            required = try container.decode(Bool.self, forKey: .required)
            dataType = try container.decode(String.self, forKey: .dataType)
            
            // Handle constraints as a simple dictionary for now
            if let constraintsData = try? container.decode(Data.self, forKey: .constraints),
               let constraintsDict = try? JSONSerialization.jsonObject(with: constraintsData) as? [String: Any] {
                constraints = constraintsDict
            } else {
                constraints = [:]
            }
            
            customValidator = try container.decodeIfPresent(String.self, forKey: .customValidator)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(required, forKey: .required)
            try container.encode(dataType, forKey: .dataType)
            
            // Encode constraints as Data
            if let constraintsData = try? JSONSerialization.data(withJSONObject: constraints) {
                try container.encode(constraintsData, forKey: .constraints)
            }
            
            try container.encodeIfPresent(customValidator, forKey: .customValidator)
        }
        
        private enum CodingKeys: String, CodingKey {
            case required, dataType, constraints, customValidator
        }
    }
    
    public init(
        enableAutomaticMigration: Bool = true,
        enableBackupBeforeMigration: Bool = true,
        enableRollback: Bool = true,
        migrationTimeout: TimeInterval = 300, // 5 minutes
        maxBackupSize: UInt64 = 1024 * 1024 * 1024, // 1GB
        batchSize: Int = 1000,
        enableValidation: Bool = true,
        enableProgressTracking: Bool = true,
        enableAnalytics: Bool = true,
        compressionEnabled: Bool = true,
        encryptionEnabled: Bool = false,
        migrationStrategies: [String: MigrationStrategy] = [:],
        validationRules: [String: ValidationConfig] = [:],
        customTransformers: [String: String] = [:]
    ) {
        self.enableAutomaticMigration = enableAutomaticMigration
        self.enableBackupBeforeMigration = enableBackupBeforeMigration
        self.enableRollback = enableRollback
        self.migrationTimeout = migrationTimeout
        self.maxBackupSize = maxBackupSize
        self.batchSize = batchSize
        self.enableValidation = enableValidation
        self.enableProgressTracking = enableProgressTracking
        self.enableAnalytics = enableAnalytics
        self.compressionEnabled = compressionEnabled
        self.encryptionEnabled = encryptionEnabled
        self.migrationStrategies = migrationStrategies
        self.validationRules = validationRules
        self.customTransformers = customTransformers
    }
    
    public var isValid: Bool {
        migrationTimeout > 0 && maxBackupSize > 0 && batchSize > 0
    }
    
    public func merged(with other: DataMigrationCapabilityConfiguration) -> DataMigrationCapabilityConfiguration {
        DataMigrationCapabilityConfiguration(
            enableAutomaticMigration: other.enableAutomaticMigration,
            enableBackupBeforeMigration: other.enableBackupBeforeMigration,
            enableRollback: other.enableRollback,
            migrationTimeout: other.migrationTimeout,
            maxBackupSize: other.maxBackupSize,
            batchSize: other.batchSize,
            enableValidation: other.enableValidation,
            enableProgressTracking: other.enableProgressTracking,
            enableAnalytics: other.enableAnalytics,
            compressionEnabled: other.compressionEnabled,
            encryptionEnabled: other.encryptionEnabled,
            migrationStrategies: migrationStrategies.merging(other.migrationStrategies) { _, new in new },
            validationRules: validationRules.merging(other.validationRules) { _, new in new },
            customTransformers: customTransformers.merging(other.customTransformers) { _, new in new }
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> DataMigrationCapabilityConfiguration {
        var adjustedTimeout = migrationTimeout
        var adjustedBatchSize = batchSize
        var adjustedBackupSize = maxBackupSize
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(migrationTimeout, 60) // 1 minute max
            adjustedBatchSize = min(batchSize, 100) // Smaller batches
            adjustedBackupSize = min(maxBackupSize, 100 * 1024 * 1024) // 100MB max
        }
        
        return DataMigrationCapabilityConfiguration(
            enableAutomaticMigration: enableAutomaticMigration,
            enableBackupBeforeMigration: enableBackupBeforeMigration,
            enableRollback: enableRollback,
            migrationTimeout: adjustedTimeout,
            maxBackupSize: adjustedBackupSize,
            batchSize: adjustedBatchSize,
            enableValidation: enableValidation,
            enableProgressTracking: enableProgressTracking,
            enableAnalytics: enableAnalytics,
            compressionEnabled: compressionEnabled,
            encryptionEnabled: encryptionEnabled,
            migrationStrategies: migrationStrategies,
            validationRules: validationRules,
            customTransformers: customTransformers
        )
    }
}

// MARK: - Schema Version

/// Represents a schema version with metadata
public struct SchemaVersion: Sendable, Codable, Comparable {
    public let version: String
    public let timestamp: Date
    public let description: String
    public let changes: [SchemaChange]
    public let metadata: [String: String]
    
    public init(
        version: String,
        description: String = "",
        changes: [SchemaChange] = [],
        metadata: [String: String] = [:]
    ) {
        self.version = version
        self.timestamp = Date()
        self.description = description
        self.changes = changes
        self.metadata = metadata
    }
    
    public static func < (lhs: SchemaVersion, rhs: SchemaVersion) -> Bool {
        lhs.version.compare(rhs.version, options: .numeric) == .orderedAscending
    }
    
    public static func == (lhs: SchemaVersion, rhs: SchemaVersion) -> Bool {
        lhs.version == rhs.version
    }
}

// MARK: - Schema Change

/// Represents a change in schema
public struct SchemaChange: Sendable, Codable {
    public let type: ChangeType
    public let entity: String
    public let field: String?
    public let oldValue: String?
    public let newValue: String?
    public let transformer: String?
    public let isBreaking: Bool
    public let description: String
    
    public enum ChangeType: String, Codable, CaseIterable {
        case addEntity = "add-entity"
        case removeEntity = "remove-entity"
        case renameEntity = "rename-entity"
        case addField = "add-field"
        case removeField = "remove-field"
        case renameField = "rename-field"
        case changeFieldType = "change-field-type"
        case addConstraint = "add-constraint"
        case removeConstraint = "remove-constraint"
        case addIndex = "add-index"
        case removeIndex = "remove-index"
    }
    
    public init(
        type: ChangeType,
        entity: String,
        field: String? = nil,
        oldValue: String? = nil,
        newValue: String? = nil,
        transformer: String? = nil,
        isBreaking: Bool = false,
        description: String = ""
    ) {
        self.type = type
        self.entity = entity
        self.field = field
        self.oldValue = oldValue
        self.newValue = newValue
        self.transformer = transformer
        self.isBreaking = isBreaking
        self.description = description
    }
}

// MARK: - Migration Plan

/// Represents a migration plan from one version to another
public struct MigrationPlan: Sendable, Identifiable {
    public let id: UUID
    public let fromVersion: SchemaVersion
    public let toVersion: SchemaVersion
    public let migrations: [Migration]
    public let estimatedDuration: TimeInterval
    public let isBreaking: Bool
    public let requiresBackup: Bool
    public let createdAt: Date
    
    public init(
        fromVersion: SchemaVersion,
        toVersion: SchemaVersion,
        migrations: [Migration] = [],
        estimatedDuration: TimeInterval = 0
    ) {
        self.id = UUID()
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.migrations = migrations
        self.estimatedDuration = estimatedDuration
        self.isBreaking = migrations.contains { $0.isBreaking }
        self.requiresBackup = isBreaking || migrations.count > 5
        self.createdAt = Date()
    }
}

// MARK: - Migration

/// Represents a single migration step
public struct Migration: Sendable, Identifiable {
    public let id: UUID
    public let order: Int
    public let type: MigrationType
    public let entityType: String
    public let transformer: DataTransformer?
    public let validation: ValidationStep?
    public let isBreaking: Bool
    public let description: String
    public let metadata: [String: String]
    
    public enum MigrationType: String, Codable, CaseIterable {
        case transform = "transform"         // Transform data
        case copy = "copy"                  // Copy data as-is
        case delete = "delete"              // Delete data
        case validate = "validate"          // Validate data
        case index = "index"                // Create/update indexes
        case cleanup = "cleanup"            // Cleanup after migration
    }
    
    public init(
        order: Int,
        type: MigrationType,
        entityType: String,
        transformer: DataTransformer? = nil,
        validation: ValidationStep? = nil,
        isBreaking: Bool = false,
        description: String = "",
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.order = order
        self.type = type
        self.entityType = entityType
        self.transformer = transformer
        self.validation = validation
        self.isBreaking = isBreaking
        self.description = description
        self.metadata = metadata
    }
}

// MARK: - Data Transformer

/// Represents a data transformation function
public struct DataTransformer: Sendable {
    public let name: String
    public let version: String
    public let transform: @Sendable (Data) async throws -> Data
    
    public init(
        name: String,
        version: String = "1.0",
        transform: @escaping @Sendable (Data) async throws -> Data
    ) {
        self.name = name
        self.version = version
        self.transform = transform
    }
}

// MARK: - Validation Step

/// Represents a validation step in migration
public struct ValidationStep: Sendable {
    public let name: String
    public let rules: [ValidationRule]
    public let validate: @Sendable (Data) async throws -> ValidationResult
    
    public struct ValidationRule: Sendable {
        public let field: String
        public let constraint: String
        public let errorMessage: String
        
        public init(field: String, constraint: String, errorMessage: String) {
            self.field = field
            self.constraint = constraint
            self.errorMessage = errorMessage
        }
    }
    
    public struct ValidationResult: Sendable {
        public let isValid: Bool
        public let errors: [String]
        
        public init(isValid: Bool, errors: [String] = []) {
            self.isValid = isValid
            self.errors = errors
        }
    }
    
    public init(
        name: String,
        rules: [ValidationRule] = [],
        validate: @escaping @Sendable (Data) async throws -> ValidationResult
    ) {
        self.name = name
        self.rules = rules
        self.validate = validate
    }
}

// MARK: - Migration Result

/// Result of a migration execution
public struct MigrationResult: Sendable {
    public let plan: MigrationPlan
    public let status: Status
    public let startTime: Date
    public let endTime: Date
    public let duration: TimeInterval
    public let migratedRecords: Int
    public let failedRecords: Int
    public let errors: [String]
    public let warnings: [String]
    public let backupLocation: URL?
    public let progress: MigrationProgress
    
    public enum Status: String, Codable, CaseIterable {
        case success = "success"
        case failed = "failed"
        case partialSuccess = "partial-success"
        case rolledBack = "rolled-back"
        case cancelled = "cancelled"
    }
    
    public init(
        plan: MigrationPlan,
        status: Status,
        startTime: Date,
        migratedRecords: Int = 0,
        failedRecords: Int = 0,
        errors: [String] = [],
        warnings: [String] = [],
        backupLocation: URL? = nil,
        progress: MigrationProgress = MigrationProgress()
    ) {
        self.plan = plan
        self.status = status
        self.startTime = startTime
        self.endTime = Date()
        self.duration = Date().timeIntervalSince(startTime)
        self.migratedRecords = migratedRecords
        self.failedRecords = failedRecords
        self.errors = errors
        self.warnings = warnings
        self.backupLocation = backupLocation
        self.progress = progress
    }
}

// MARK: - Migration Progress

/// Tracks migration progress
public struct MigrationProgress: Sendable {
    public let totalSteps: Int
    public let completedSteps: Int
    public let currentStep: String
    public let percentComplete: Double
    public let estimatedTimeRemaining: TimeInterval
    
    public init(
        totalSteps: Int = 0,
        completedSteps: Int = 0,
        currentStep: String = "",
        estimatedTimeRemaining: TimeInterval = 0
    ) {
        self.totalSteps = totalSteps
        self.completedSteps = completedSteps
        self.currentStep = currentStep
        self.percentComplete = totalSteps > 0 ? Double(completedSteps) / Double(totalSteps) * 100 : 0
        self.estimatedTimeRemaining = estimatedTimeRemaining
    }
}

// MARK: - Migration Analytics

/// Migration analytics and metrics
public struct MigrationAnalytics: Sendable, Codable {
    public let totalMigrations: Int
    public let successfulMigrations: Int
    public let failedMigrations: Int
    public let totalRecordsMigrated: Int
    public let averageMigrationTime: TimeInterval
    public let successRate: Double
    public let mostCommonErrors: [String: Int]
    public let migrationsByType: [String: Int]
    public let performanceMetrics: PerformanceMetrics
    public let lastUpdated: Date
    
    public struct PerformanceMetrics: Sendable, Codable {
        public let averageRecordsPerSecond: Double
        public let averageMemoryUsage: UInt64
        public let peakMemoryUsage: UInt64
        public let averageCPUUsage: Double
        
        public init(
            averageRecordsPerSecond: Double = 0,
            averageMemoryUsage: UInt64 = 0,
            peakMemoryUsage: UInt64 = 0,
            averageCPUUsage: Double = 0
        ) {
            self.averageRecordsPerSecond = averageRecordsPerSecond
            self.averageMemoryUsage = averageMemoryUsage
            self.peakMemoryUsage = peakMemoryUsage
            self.averageCPUUsage = averageCPUUsage
        }
    }
    
    public init(
        totalMigrations: Int = 0,
        successfulMigrations: Int = 0,
        failedMigrations: Int = 0,
        totalRecordsMigrated: Int = 0,
        averageMigrationTime: TimeInterval = 0,
        mostCommonErrors: [String: Int] = [:],
        migrationsByType: [String: Int] = [:],
        performanceMetrics: PerformanceMetrics = PerformanceMetrics(),
        lastUpdated: Date = Date()
    ) {
        self.totalMigrations = totalMigrations
        self.successfulMigrations = successfulMigrations
        self.failedMigrations = failedMigrations
        self.totalRecordsMigrated = totalRecordsMigrated
        self.averageMigrationTime = averageMigrationTime
        self.successRate = totalMigrations > 0 ? Double(successfulMigrations) / Double(totalMigrations) : 0
        self.mostCommonErrors = mostCommonErrors
        self.migrationsByType = migrationsByType
        self.performanceMetrics = performanceMetrics
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Data Migration Resource

/// Data migration resource management
public actor DataMigrationCapabilityResource: AxiomCapabilityResource {
    private let configuration: DataMigrationCapabilityConfiguration
    private var currentVersion: SchemaVersion?
    private var availableVersions: [SchemaVersion] = []
    private var registeredTransformers: [String: DataTransformer] = [:]
    private var migrationHistory: [MigrationResult] = []
    private var analytics = MigrationAnalytics()
    private var isMigrating: Bool = false
    private let migrationQueue = OperationQueue()
    
    // Delegate for custom migration operations
    public weak var migrationDelegate: DataMigrationDelegate?
    
    public init(configuration: DataMigrationCapabilityConfiguration) {
        self.configuration = configuration
        self.migrationQueue.maxConcurrentOperationCount = 1
        self.migrationQueue.qualityOfService = .utility
    }
    
    public func allocate() async throws {
        // Load current schema version
        await loadCurrentVersion()
        
        // Load available versions
        await loadAvailableVersions()
        
        // Register built-in transformers
        await registerBuiltInTransformers()
        
        // Load migration history
        await loadMigrationHistory()
    }
    
    public func deallocate() async {
        migrationQueue.cancelAllOperations()
        
        // Save migration history
        await saveMigrationHistory()
        
        currentVersion = nil
        availableVersions.removeAll()
        registeredTransformers.removeAll()
        migrationHistory.removeAll()
        analytics = MigrationAnalytics()
        isMigrating = false
    }
    
    public var isAllocated: Bool {
        currentVersion != nil
    }
    
    public func updateConfiguration(_ configuration: DataMigrationCapabilityConfiguration) async throws {
        // Update migration settings
    }
    
    // MARK: - Schema Version Management
    
    public func getCurrentVersion() async -> SchemaVersion? {
        currentVersion
    }
    
    public func getAvailableVersions() async -> [SchemaVersion] {
        availableVersions.sorted()
    }
    
    public func addSchemaVersion(_ version: SchemaVersion) async {
        if !availableVersions.contains(where: { $0.version == version.version }) {
            availableVersions.append(version)
            availableVersions.sort()
        }
    }
    
    public func setCurrentVersion(_ version: SchemaVersion) async {
        currentVersion = version
        await saveCurrentVersion()
    }
    
    // MARK: - Migration Planning
    
    public func createMigrationPlan(to targetVersion: SchemaVersion) async throws -> MigrationPlan {
        guard let currentVersion = currentVersion else {
            throw AxiomCapabilityError.dataMigrationError("No current version set")
        }
        
        // Find path from current to target version
        let migrationPath = await findMigrationPath(from: currentVersion, to: targetVersion)
        
        if migrationPath.isEmpty && currentVersion != targetVersion {
            throw AxiomCapabilityError.dataMigrationError("No migration path found")
        }
        
        // Create migrations for each step
        var migrations: [Migration] = []
        var order = 0
        
        for step in migrationPath {
            let stepMigrations = await createMigrationsForStep(step, order: &order)
            migrations.append(contentsOf: stepMigrations)
        }
        
        // Estimate duration
        let estimatedDuration = await estimateMigrationDuration(migrations: migrations)
        
        return MigrationPlan(
            fromVersion: currentVersion,
            toVersion: targetVersion,
            migrations: migrations,
            estimatedDuration: estimatedDuration
        )
    }
    
    // MARK: - Migration Execution
    
    public func executeMigration(_ plan: MigrationPlan) async throws -> MigrationResult {
        guard !isMigrating else {
            throw AxiomCapabilityError.dataMigrationError("Migration already in progress")
        }
        
        isMigrating = true
        defer { isMigrating = false }
        
        let startTime = Date()
        var migratedRecords = 0
        var failedRecords = 0
        var errors: [String] = []
        var warnings: [String] = []
        var backupLocation: URL? = nil
        
        do {
            // Create backup if required
            if configuration.enableBackupBeforeMigration && plan.requiresBackup {
                backupLocation = try await createBackup()
            }
            
            // Execute migration steps
            for migration in plan.migrations.sorted(by: { $0.order < $1.order }) {
                let (migrated, failed, stepErrors, stepWarnings) = try await executeMigrationStep(migration)
                migratedRecords += migrated
                failedRecords += failed
                errors.append(contentsOf: stepErrors)
                warnings.append(contentsOf: stepWarnings)
                
                // Check if we should abort
                if failed > 0 && !configuration.enableAutomaticMigration {
                    throw AxiomCapabilityError.dataMigrationError("Migration failed with \(failed) failed records")
                }
            }
            
            // Update current version
            await setCurrentVersion(plan.toVersion)
            
            let result = MigrationResult(
                plan: plan,
                status: failedRecords > 0 ? .partialSuccess : .success,
                startTime: startTime,
                migratedRecords: migratedRecords,
                failedRecords: failedRecords,
                errors: errors,
                warnings: warnings,
                backupLocation: backupLocation
            )
            
            // Add to history
            migrationHistory.append(result)
            
            // Update analytics
            if configuration.enableAnalytics {
                await updateMigrationAnalytics(result: result)
            }
            
            return result
            
        } catch {
            // Rollback if enabled
            if configuration.enableRollback && backupLocation != nil {
                try await rollbackFromBackup(backupLocation!)
            }
            
            let result = MigrationResult(
                plan: plan,
                status: .failed,
                startTime: startTime,
                migratedRecords: migratedRecords,
                failedRecords: failedRecords,
                errors: errors + [error.localizedDescription],
                warnings: warnings,
                backupLocation: backupLocation
            )
            
            migrationHistory.append(result)
            
            throw error
        }
    }
    
    public func rollbackToVersion(_ version: SchemaVersion) async throws -> MigrationResult {
        guard let currentVersion = currentVersion else {
            throw AxiomCapabilityError.dataMigrationError("No current version set")
        }
        
        // Create rollback plan (reverse migration)
        let rollbackPlan = try await createRollbackPlan(from: currentVersion, to: version)
        
        // Execute rollback
        return try await executeMigration(rollbackPlan)
    }
    
    // MARK: - Data Transformers
    
    public func registerTransformer(_ transformer: DataTransformer) async {
        registeredTransformers[transformer.name] = transformer
    }
    
    public func getTransformer(named name: String) async -> DataTransformer? {
        registeredTransformers[name]
    }
    
    public func getAllTransformers() async -> [DataTransformer] {
        Array(registeredTransformers.values)
    }
    
    // MARK: - Migration History & Analytics
    
    public func getMigrationHistory() async -> [MigrationResult] {
        migrationHistory
    }
    
    public func getAnalytics() async -> MigrationAnalytics {
        if configuration.enableAnalytics {
            return analytics
        } else {
            return MigrationAnalytics()
        }
    }
    
    public func clearMigrationHistory() async {
        migrationHistory.removeAll()
        analytics = MigrationAnalytics()
    }
    
    // MARK: - Private Methods
    
    private func findMigrationPath(from: SchemaVersion, to: SchemaVersion) async -> [SchemaVersion] {
        // Simplified path finding - in reality would use graph algorithms
        let sortedVersions = availableVersions.sorted()
        
        guard let fromIndex = sortedVersions.firstIndex(of: from),
              let toIndex = sortedVersions.firstIndex(of: to) else {
            return []
        }
        
        if fromIndex < toIndex {
            return Array(sortedVersions[fromIndex + 1...toIndex])
        } else if fromIndex > toIndex {
            return Array(sortedVersions[toIndex...fromIndex - 1].reversed())
        } else {
            return []
        }
    }
    
    private func createMigrationsForStep(_ version: SchemaVersion, order: inout Int) async -> [Migration] {
        var migrations: [Migration] = []
        
        for change in version.changes {
            let migration = Migration(
                order: order,
                type: getMigrationType(for: change),
                entityType: change.entity,
                transformer: await getTransformerForChange(change),
                isBreaking: change.isBreaking,
                description: change.description
            )
            migrations.append(migration)
            order += 1
        }
        
        return migrations
    }
    
    private func getMigrationType(for change: SchemaChange) -> Migration.MigrationType {
        switch change.type {
        case .addEntity, .addField:
            return .transform
        case .removeEntity, .removeField:
            return .delete
        case .renameEntity, .renameField, .changeFieldType:
            return .transform
        case .addConstraint, .removeConstraint:
            return .validate
        case .addIndex, .removeIndex:
            return .index
        }
    }
    
    private func getTransformerForChange(_ change: SchemaChange) async -> DataTransformer? {
        if let transformerName = change.transformer {
            return registeredTransformers[transformerName]
        }
        
        // Return default transformer based on change type
        switch change.type {
        case .renameField:
            return await createRenameFieldTransformer(from: change.oldValue, to: change.newValue)
        case .changeFieldType:
            return await createTypeChangeTransformer(field: change.field, from: change.oldValue, to: change.newValue)
        default:
            return nil
        }
    }
    
    private func createRenameFieldTransformer(from oldName: String?, to newName: String?) async -> DataTransformer? {
        guard let oldName = oldName, let newName = newName else { return nil }
        
        return DataTransformer(name: "rename-field-\(oldName)-to-\(newName)") { data in
            do {
                guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return data
                }
                
                if let value = json[oldName] {
                    json[newName] = value
                    json.removeValue(forKey: oldName)
                }
                
                return try JSONSerialization.data(withJSONObject: json)
            } catch {
                return data
            }
        }
    }
    
    private func createTypeChangeTransformer(field: String?, from oldType: String?, to newType: String?) async -> DataTransformer? {
        guard let field = field, let oldType = oldType, let newType = newType else { return nil }
        
        return DataTransformer(name: "change-type-\(field)-\(oldType)-to-\(newType)") { data in
            do {
                guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return data
                }
                
                if let value = json[field] {
                    json[field] = try await self.convertValue(value, from: oldType, to: newType)
                }
                
                return try JSONSerialization.data(withJSONObject: json)
            } catch {
                return data
            }
        }
    }
    
    private func convertValue(_ value: Any, from oldType: String, to newType: String) async throws -> Any {
        // Simplified type conversion
        switch (oldType, newType) {
        case ("string", "int"):
            if let stringValue = value as? String {
                return Int(stringValue) ?? 0
            }
        case ("int", "string"):
            if let intValue = value as? Int {
                return String(intValue)
            }
        case ("string", "double"):
            if let stringValue = value as? String {
                return Double(stringValue) ?? 0.0
            }
        case ("double", "string"):
            if let doubleValue = value as? Double {
                return String(doubleValue)
            }
        default:
            break
        }
        
        return value
    }
    
    private func estimateMigrationDuration(migrations: [Migration]) async -> TimeInterval {
        // Simplified estimation - in reality would be more sophisticated
        let baseTimePerMigration: TimeInterval = 1.0
        return Double(migrations.count) * baseTimePerMigration
    }
    
    private func executeMigrationStep(_ migration: Migration) async throws -> (migrated: Int, failed: Int, errors: [String], warnings: [String]) {
        // Use delegate if available
        if let delegate = migrationDelegate {
            return try await delegate.executeMigrationStep(migration)
        }
        
        // Default implementation (placeholder)
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        return (migrated: 100, failed: 0, errors: [], warnings: [])
    }
    
    private func createBackup() async throws -> URL {
        // Create backup of current data
        let backupDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("AxiomMigrationBackups")
        
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        
        let backupURL = backupDirectory.appendingPathComponent("backup-\(Date().timeIntervalSince1970).backup")
        
        // Placeholder - would actually backup data
        let backupData = "backup data".data(using: .utf8)!
        try backupData.write(to: backupURL)
        
        return backupURL
    }
    
    private func rollbackFromBackup(_ backupLocation: URL) async throws {
        // Restore from backup
        // Placeholder implementation
        let _ = try Data(contentsOf: backupLocation)
        // Would restore data from backup
    }
    
    private func createRollbackPlan(from: SchemaVersion, to: SchemaVersion) async throws -> MigrationPlan {
        // Create reverse migration plan
        // Simplified implementation
        return MigrationPlan(fromVersion: from, toVersion: to)
    }
    
    private func registerBuiltInTransformers() async {
        // Register common transformers
        let identityTransformer = DataTransformer(name: "identity") { data in
            return data
        }
        
        registeredTransformers["identity"] = identityTransformer
    }
    
    private func loadCurrentVersion() async {
        // Load current version from persistent storage
        // Placeholder implementation
        currentVersion = SchemaVersion(version: "1.0.0", description: "Initial version")
    }
    
    private func saveCurrentVersion() async {
        // Save current version to persistent storage
        // Placeholder implementation
    }
    
    private func loadAvailableVersions() async {
        // Load available versions from configuration or storage
        // Placeholder implementation
        if availableVersions.isEmpty {
            availableVersions = [
                SchemaVersion(version: "1.0.0", description: "Initial version"),
                SchemaVersion(version: "1.1.0", description: "Added user preferences"),
                SchemaVersion(version: "2.0.0", description: "Major schema update")
            ]
        }
    }
    
    private func loadMigrationHistory() async {
        // Load migration history from persistent storage
        // Placeholder implementation
    }
    
    private func saveMigrationHistory() async {
        // Save migration history to persistent storage
        // Placeholder implementation
    }
    
    private func updateMigrationAnalytics(result: MigrationResult) async {
        // Update analytics with migration result
        // Implementation would update the analytics struct
    }
}

// MARK: - Data Migration Delegate

/// Delegate protocol for custom migration operations
public protocol DataMigrationDelegate: AnyObject, Sendable {
    func executeMigrationStep(_ migration: Migration) async throws -> (migrated: Int, failed: Int, errors: [String], warnings: [String])
    func validateMigrationData(_ data: Data, for version: SchemaVersion) async throws -> Bool
}

// MARK: - Data Migration Capability Implementation

/// Data migration capability providing schema and data migration
public actor DataMigrationCapability: DomainCapability {
    public typealias ConfigurationType = DataMigrationCapabilityConfiguration
    public typealias ResourceType = DataMigrationCapabilityResource
    
    private var _configuration: DataMigrationCapabilityConfiguration
    private var _resources: DataMigrationCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(30)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "data-migration-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: DataMigrationCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: DataMigrationCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: DataMigrationCapabilityConfiguration = DataMigrationCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = DataMigrationCapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.deallocate()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: DataMigrationCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid data migration configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func isSupported() async -> Bool {
        // Data migration is available on all Apple platforms
        true
    }
    
    public func requestPermission() async throws {
        // Data migration doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Migration Operations
    
    /// Get current schema version
    public func getCurrentVersion() async throws -> SchemaVersion? {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data migration capability not available")
        }
        
        return await _resources.getCurrentVersion()
    }
    
    /// Get available schema versions
    public func getAvailableVersions() async throws -> [SchemaVersion] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data migration capability not available")
        }
        
        return await _resources.getAvailableVersions()
    }
    
    /// Add a new schema version
    public func addSchemaVersion(_ version: SchemaVersion) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data migration capability not available")
        }
        
        await _resources.addSchemaVersion(version)
    }
    
    /// Create migration plan to target version
    public func createMigrationPlan(to targetVersion: SchemaVersion) async throws -> MigrationPlan {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data migration capability not available")
        }
        
        return try await _resources.createMigrationPlan(to: targetVersion)
    }
    
    /// Execute migration plan
    public func executeMigration(_ plan: MigrationPlan) async throws -> MigrationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data migration capability not available")
        }
        
        return try await _resources.executeMigration(plan)
    }
    
    /// Rollback to previous version
    public func rollbackToVersion(_ version: SchemaVersion) async throws -> MigrationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data migration capability not available")
        }
        
        return try await _resources.rollbackToVersion(version)
    }
    
    /// Register custom data transformer
    public func registerTransformer(_ transformer: DataTransformer) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data migration capability not available")
        }
        
        await _resources.registerTransformer(transformer)
    }
    
    /// Get migration history
    public func getMigrationHistory() async throws -> [MigrationResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data migration capability not available")
        }
        
        return await _resources.getMigrationHistory()
    }
    
    /// Get migration analytics
    public func getAnalytics() async throws -> MigrationAnalytics {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data migration capability not available")
        }
        
        return await _resources.getAnalytics()
    }
    
    /// Set migration delegate
    public func setMigrationDelegate(_ delegate: DataMigrationDelegate?) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Data migration capability not available")
        }
        
        _resources.migrationDelegate = delegate
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Extensions

extension AxiomCapabilityError {
    /// Data migration specific errors
    public static func dataMigrationError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("Data Migration: \(message)")
    }
    
    public static func migrationPlanningFailed(_ reason: String) -> AxiomCapabilityError {
        .operationFailed("Migration planning failed: \(reason)")
    }
    
    public static func migrationExecutionFailed(_ reason: String) -> AxiomCapabilityError {
        .operationFailed("Migration execution failed: \(reason)")
    }
    
    public static func rollbackFailed(_ reason: String) -> AxiomCapabilityError {
        .operationFailed("Migration rollback failed: \(reason)")
    }
}