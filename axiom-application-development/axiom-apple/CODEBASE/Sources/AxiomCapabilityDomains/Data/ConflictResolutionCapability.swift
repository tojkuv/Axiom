import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - Conflict Resolution Capability Configuration

/// Configuration for Conflict Resolution capability
public struct ConflictResolutionCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let defaultStrategy: ResolutionStrategy
    public let customStrategies: [String: ResolutionStrategy]
    public let enableAutoResolution: Bool
    public let enableUserPrompt: Bool
    public let resolutionTimeout: TimeInterval
    public let enableConflictHistory: Bool
    public let maxHistorySize: Int
    public let enableAnalytics: Bool
    public let enableDeepMerge: Bool
    public let fieldMergeStrategies: [String: FieldMergeStrategy]
    public let validationRules: [String: ValidationRule]
    
    public enum ResolutionStrategy: String, Codable, CaseIterable {
        case lastWriteWins = "last-write-wins"
        case firstWriteWins = "first-write-wins"
        case mostRecent = "most-recent"
        case highestVersion = "highest-version"
        case merge = "merge"
        case deepMerge = "deep-merge"
        case userChoice = "user-choice"
        case custom = "custom"
        case abort = "abort"
    }
    
    public enum FieldMergeStrategy: String, Codable, CaseIterable {
        case takeLocal = "take-local"
        case takeRemote = "take-remote"
        case takeNewer = "take-newer"
        case takeOlder = "take-older"
        case takeLarger = "take-larger"
        case takeSmaller = "take-smaller"
        case concatenate = "concatenate"
        case merge = "merge"
        case userChoice = "user-choice"
    }
    
    public struct ValidationRule: Codable {
        public let required: Bool
        public let dataType: String
        public let minLength: Int?
        public let maxLength: Int?
        public let pattern: String?
        public let customValidator: String?
        
        public init(
            required: Bool = false,
            dataType: String = "string",
            minLength: Int? = nil,
            maxLength: Int? = nil,
            pattern: String? = nil,
            customValidator: String? = nil
        ) {
            self.required = required
            self.dataType = dataType
            self.minLength = minLength
            self.maxLength = maxLength
            self.pattern = pattern
            self.customValidator = customValidator
        }
    }
    
    public init(
        defaultStrategy: ResolutionStrategy = .lastWriteWins,
        customStrategies: [String: ResolutionStrategy] = [:],
        enableAutoResolution: Bool = true,
        enableUserPrompt: Bool = true,
        resolutionTimeout: TimeInterval = 30,
        enableConflictHistory: Bool = true,
        maxHistorySize: Int = 1000,
        enableAnalytics: Bool = true,
        enableDeepMerge: Bool = true,
        fieldMergeStrategies: [String: FieldMergeStrategy] = [:],
        validationRules: [String: ValidationRule] = [:]
    ) {
        self.defaultStrategy = defaultStrategy
        self.customStrategies = customStrategies
        self.enableAutoResolution = enableAutoResolution
        self.enableUserPrompt = enableUserPrompt
        self.resolutionTimeout = resolutionTimeout
        self.enableConflictHistory = enableConflictHistory
        self.maxHistorySize = maxHistorySize
        self.enableAnalytics = enableAnalytics
        self.enableDeepMerge = enableDeepMerge
        self.fieldMergeStrategies = fieldMergeStrategies
        self.validationRules = validationRules
    }
    
    public var isValid: Bool {
        resolutionTimeout > 0 && maxHistorySize > 0
    }
    
    public func merged(with other: ConflictResolutionCapabilityConfiguration) -> ConflictResolutionCapabilityConfiguration {
        ConflictResolutionCapabilityConfiguration(
            defaultStrategy: other.defaultStrategy,
            customStrategies: customStrategies.merging(other.customStrategies) { _, new in new },
            enableAutoResolution: other.enableAutoResolution,
            enableUserPrompt: other.enableUserPrompt,
            resolutionTimeout: other.resolutionTimeout,
            enableConflictHistory: other.enableConflictHistory,
            maxHistorySize: other.maxHistorySize,
            enableAnalytics: other.enableAnalytics,
            enableDeepMerge: other.enableDeepMerge,
            fieldMergeStrategies: fieldMergeStrategies.merging(other.fieldMergeStrategies) { _, new in new },
            validationRules: validationRules.merging(other.validationRules) { _, new in new }
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> ConflictResolutionCapabilityConfiguration {
        var adjustedTimeout = resolutionTimeout
        var adjustedHistorySize = maxHistorySize
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(resolutionTimeout, 10) // Shorter timeout
            adjustedHistorySize = min(maxHistorySize, 100) // Smaller history
        }
        
        return ConflictResolutionCapabilityConfiguration(
            defaultStrategy: defaultStrategy,
            customStrategies: customStrategies,
            enableAutoResolution: enableAutoResolution,
            enableUserPrompt: enableUserPrompt,
            resolutionTimeout: adjustedTimeout,
            enableConflictHistory: enableConflictHistory,
            maxHistorySize: adjustedHistorySize,
            enableAnalytics: enableAnalytics,
            enableDeepMerge: enableDeepMerge,
            fieldMergeStrategies: fieldMergeStrategies,
            validationRules: validationRules
        )
    }
}

// MARK: - Data Conflict

/// Represents a data conflict between two versions
public struct DataConflict: Sendable, Identifiable {
    public let id: UUID
    public let entityType: String
    public let entityId: String
    public let localVersion: DataVersion
    public let remoteVersion: DataVersion
    public let conflictType: ConflictType
    public let conflictFields: [String]
    public let detectedAt: Date
    public let metadata: [String: String]
    
    public enum ConflictType: String, Codable, CaseIterable {
        case update = "update"           // Both sides modified
        case delete = "delete"           // One side deleted, other modified
        case create = "create"           // Both sides created with same ID
        case schema = "schema"           // Schema version mismatch
        case dependency = "dependency"   // Dependency conflict
    }
    
    public init(
        entityType: String,
        entityId: String,
        localVersion: DataVersion,
        remoteVersion: DataVersion,
        conflictType: ConflictType = .update,
        conflictFields: [String] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.entityType = entityType
        self.entityId = entityId
        self.localVersion = localVersion
        self.remoteVersion = remoteVersion
        self.conflictType = conflictType
        self.conflictFields = conflictFields
        self.detectedAt = Date()
        self.metadata = metadata
    }
}

// MARK: - Data Version

/// Represents a version of data with metadata
public struct DataVersion: Sendable, Codable {
    public let data: Data
    public let version: String
    public let timestamp: Date
    public let author: String?
    public let checksum: String
    public let size: UInt64
    public let encoding: String
    public let metadata: [String: String]
    
    public init(
        data: Data,
        version: String,
        timestamp: Date = Date(),
        author: String? = nil,
        encoding: String = "json",
        metadata: [String: String] = [:]
    ) {
        self.data = data
        self.version = version
        self.timestamp = timestamp
        self.author = author
        self.checksum = data.sha256
        self.size = UInt64(data.count)
        self.encoding = encoding
        self.metadata = metadata
    }
    
    public var isValid: Bool {
        !data.isEmpty && !version.isEmpty && data.sha256 == checksum
    }
}

// MARK: - Resolution Result

/// Result of conflict resolution
public struct ResolutionResult: Sendable {
    public let conflict: DataConflict
    public let resolvedData: Data
    public let strategy: ConflictResolutionCapabilityConfiguration.ResolutionStrategy
    public let resolvedAt: Date
    public let resolvedBy: String?
    public let isAutoResolved: Bool
    public let validationPassed: Bool
    public let mergeDetails: MergeDetails?
    
    public struct MergeDetails: Sendable {
        public let fieldsFromLocal: [String]
        public let fieldsFromRemote: [String]
        public let mergedFields: [String]
        public let conflictedFields: [String]
        
        public init(
            fieldsFromLocal: [String] = [],
            fieldsFromRemote: [String] = [],
            mergedFields: [String] = [],
            conflictedFields: [String] = []
        ) {
            self.fieldsFromLocal = fieldsFromLocal
            self.fieldsFromRemote = fieldsFromRemote
            self.mergedFields = mergedFields
            self.conflictedFields = conflictedFields
        }
    }
    
    public init(
        conflict: DataConflict,
        resolvedData: Data,
        strategy: ConflictResolutionCapabilityConfiguration.ResolutionStrategy,
        resolvedBy: String? = nil,
        isAutoResolved: Bool = true,
        validationPassed: Bool = true,
        mergeDetails: MergeDetails? = nil
    ) {
        self.conflict = conflict
        self.resolvedData = resolvedData
        self.strategy = strategy
        self.resolvedAt = Date()
        self.resolvedBy = resolvedBy
        self.isAutoResolved = isAutoResolved
        self.validationPassed = validationPassed
        self.mergeDetails = mergeDetails
    }
}

// MARK: - Conflict Analytics

/// Conflict resolution analytics and metrics
public struct ConflictAnalytics: Sendable, Codable {
    public let totalConflicts: Int
    public let resolvedConflicts: Int
    public let unresolvedConflicts: Int
    public let autoResolvedConflicts: Int
    public let userResolvedConflicts: Int
    public let resolutionRate: Double
    public let autoResolutionRate: Double
    public let averageResolutionTime: TimeInterval
    public let conflictsByType: [String: Int]
    public let strategiesUsed: [String: Int]
    public let mostConflictedEntities: [String: Int]
    public let lastUpdated: Date
    
    public init(
        totalConflicts: Int = 0,
        resolvedConflicts: Int = 0,
        unresolvedConflicts: Int = 0,
        autoResolvedConflicts: Int = 0,
        userResolvedConflicts: Int = 0,
        averageResolutionTime: TimeInterval = 0,
        conflictsByType: [String: Int] = [:],
        strategiesUsed: [String: Int] = [:],
        mostConflictedEntities: [String: Int] = [:],
        lastUpdated: Date = Date()
    ) {
        self.totalConflicts = totalConflicts
        self.resolvedConflicts = resolvedConflicts
        self.unresolvedConflicts = unresolvedConflicts
        self.autoResolvedConflicts = autoResolvedConflicts
        self.userResolvedConflicts = userResolvedConflicts
        self.resolutionRate = totalConflicts > 0 ? Double(resolvedConflicts) / Double(totalConflicts) : 0
        self.autoResolutionRate = resolvedConflicts > 0 ? Double(autoResolvedConflicts) / Double(resolvedConflicts) : 0
        self.averageResolutionTime = averageResolutionTime
        self.conflictsByType = conflictsByType
        self.strategiesUsed = strategiesUsed
        self.mostConflictedEntities = mostConflictedEntities
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Conflict Resolution Resource

/// Conflict resolution resource management
public actor ConflictResolutionCapabilityResource: AxiomCapabilityResource {
    private let configuration: ConflictResolutionCapabilityConfiguration
    private var pendingConflicts: [DataConflict] = []
    private var conflictHistory: [ResolutionResult] = []
    private var analytics = ConflictAnalytics()
    private let resolutionQueue = OperationQueue()
    
    // Delegate for custom resolution strategies
    public weak var resolutionDelegate: ConflictResolutionDelegate?
    
    public init(configuration: ConflictResolutionCapabilityConfiguration) {
        self.configuration = configuration
        self.resolutionQueue.maxConcurrentOperationCount = 3
        self.resolutionQueue.qualityOfService = .userInitiated
    }
    
    public func allocate() async throws {
        // Load conflict history if enabled
        if configuration.enableConflictHistory {
            await loadConflictHistory()
        }
    }
    
    public func deallocate() async {
        resolutionQueue.cancelAllOperations()
        
        // Save conflict history
        if configuration.enableConflictHistory {
            await saveConflictHistory()
        }
        
        pendingConflicts.removeAll()
        conflictHistory.removeAll()
        analytics = ConflictAnalytics()
    }
    
    public var isAllocated: Bool {
        true // Conflict resolution is conceptually always available
    }
    
    public func updateConfiguration(_ configuration: ConflictResolutionCapabilityConfiguration) async throws {
        // Trim history if size limit reduced
        if configuration.maxHistorySize < conflictHistory.count {
            conflictHistory = Array(conflictHistory.suffix(configuration.maxHistorySize))
        }
    }
    
    // MARK: - Conflict Detection
    
    public func detectConflict(
        entityType: String,
        entityId: String,
        localData: Data,
        remoteData: Data,
        localVersion: String,
        remoteVersion: String
    ) async -> DataConflict? {
        
        // Quick check - if data is identical, no conflict
        if localData == remoteData {
            return nil
        }
        
        // Create data versions
        let localDataVersion = DataVersion(data: localData, version: localVersion)
        let remoteDataVersion = DataVersion(data: remoteData, version: remoteVersion)
        
        // Determine conflict type and fields
        let (conflictType, conflictFields) = await analyzeConflict(
            localData: localData,
            remoteData: remoteData,
            entityType: entityType
        )
        
        let conflict = DataConflict(
            entityType: entityType,
            entityId: entityId,
            localVersion: localDataVersion,
            remoteVersion: remoteDataVersion,
            conflictType: conflictType,
            conflictFields: conflictFields
        )
        
        // Add to pending conflicts
        pendingConflicts.append(conflict)
        
        // Update analytics
        if configuration.enableAnalytics {
            await updateConflictAnalytics(conflict: conflict)
        }
        
        return conflict
    }
    
    public func resolveConflict(_ conflict: DataConflict) async throws -> ResolutionResult {
        let startTime = Date()
        
        // Determine resolution strategy
        let strategy = getResolutionStrategy(for: conflict)
        
        // Perform resolution based on strategy
        let result = try await performResolution(conflict: conflict, strategy: strategy)
        
        // Validate result
        let validationPassed = await validateResolution(result: result)
        
        let finalResult = ResolutionResult(
            conflict: conflict,
            resolvedData: result.resolvedData,
            strategy: strategy,
            resolvedBy: result.resolvedBy,
            isAutoResolved: result.isAutoResolved,
            validationPassed: validationPassed,
            mergeDetails: result.mergeDetails
        )
        
        // Remove from pending conflicts
        pendingConflicts.removeAll { $0.id == conflict.id }
        
        // Add to history
        if configuration.enableConflictHistory {
            conflictHistory.append(finalResult)
            await trimConflictHistory()
        }
        
        // Update analytics
        if configuration.enableAnalytics {
            await updateResolutionAnalytics(
                result: finalResult,
                duration: Date().timeIntervalSince(startTime)
            )
        }
        
        return finalResult
    }
    
    public func resolveAllPendingConflicts() async -> [ResolutionResult] {
        var results: [ResolutionResult] = []
        
        for conflict in pendingConflicts {
            do {
                let result = try await resolveConflict(conflict)
                results.append(result)
            } catch {
                // Log error and continue with next conflict
                continue
            }
        }
        
        return results
    }
    
    public func getPendingConflicts() async -> [DataConflict] {
        pendingConflicts
    }
    
    public func getConflictHistory() async -> [ResolutionResult] {
        conflictHistory
    }
    
    public func getAnalytics() async -> ConflictAnalytics {
        if configuration.enableAnalytics {
            return analytics
        } else {
            return ConflictAnalytics()
        }
    }
    
    public func clearConflictHistory() async {
        conflictHistory.removeAll()
        analytics = ConflictAnalytics()
    }
    
    // MARK: - Private Methods
    
    private func analyzeConflict(
        localData: Data,
        remoteData: Data,
        entityType: String
    ) async -> (DataConflict.ConflictType, [String]) {
        
        // Parse data to identify conflicting fields
        do {
            if let localJson = try JSONSerialization.jsonObject(with: localData) as? [String: Any],
               let remoteJson = try JSONSerialization.jsonObject(with: remoteData) as? [String: Any] {
                
                let conflictFields = findConflictingFields(local: localJson, remote: remoteJson)
                
                // Determine conflict type based on fields
                if conflictFields.contains("deleted") || conflictFields.contains("isDeleted") {
                    return (.delete, conflictFields)
                } else {
                    return (.update, conflictFields)
                }
            }
        } catch {
            // Fallback to binary comparison
        }
        
        return (.update, [])
    }
    
    private func findConflictingFields(local: [String: Any], remote: [String: Any]) -> [String] {
        var conflictFields: [String] = []
        
        let allKeys = Set(local.keys).union(Set(remote.keys))
        
        for key in allKeys {
            let localValue = local[key]
            let remoteValue = remote[key]
            
            if !areValuesEqual(localValue, remoteValue) {
                conflictFields.append(key)
            }
        }
        
        return conflictFields
    }
    
    private func areValuesEqual(_ value1: Any?, _ value2: Any?) -> Bool {
        switch (value1, value2) {
        case (nil, nil):
            return true
        case (let v1 as String, let v2 as String):
            return v1 == v2
        case (let v1 as NSNumber, let v2 as NSNumber):
            return v1 == v2
        case (let v1 as [String: Any], let v2 as [String: Any]):
            return NSDictionary(dictionary: v1).isEqual(to: v2)
        case (let v1 as [Any], let v2 as [Any]):
            return NSArray(array: v1).isEqual(to: v2)
        default:
            return false
        }
    }
    
    private func getResolutionStrategy(for conflict: DataConflict) -> ConflictResolutionCapabilityConfiguration.ResolutionStrategy {
        // Check for entity-specific strategy
        if let strategy = configuration.customStrategies[conflict.entityType] {
            return strategy
        }
        
        // Use default strategy
        return configuration.defaultStrategy
    }
    
    private func performResolution(
        conflict: DataConflict,
        strategy: ConflictResolutionCapabilityConfiguration.ResolutionStrategy
    ) async throws -> ResolutionResult {
        
        switch strategy {
        case .lastWriteWins:
            return await resolveLastWriteWins(conflict)
        case .firstWriteWins:
            return await resolveFirstWriteWins(conflict)
        case .mostRecent:
            return await resolveMostRecent(conflict)
        case .highestVersion:
            return await resolveHighestVersion(conflict)
        case .merge:
            return try await resolveMerge(conflict)
        case .deepMerge:
            return try await resolveDeepMerge(conflict)
        case .userChoice:
            return try await resolveUserChoice(conflict)
        case .custom:
            return try await resolveCustom(conflict)
        case .abort:
            throw AxiomCapabilityError.conflictResolutionAborted(conflict.entityId)
        }
    }
    
    private func resolveLastWriteWins(_ conflict: DataConflict) async -> ResolutionResult {
        let useRemote = conflict.remoteVersion.timestamp > conflict.localVersion.timestamp
        let resolvedData = useRemote ? conflict.remoteVersion.data : conflict.localVersion.data
        
        return ResolutionResult(
            conflict: conflict,
            resolvedData: resolvedData,
            strategy: .lastWriteWins,
            isAutoResolved: true
        )
    }
    
    private func resolveFirstWriteWins(_ conflict: DataConflict) async -> ResolutionResult {
        let useRemote = conflict.remoteVersion.timestamp < conflict.localVersion.timestamp
        let resolvedData = useRemote ? conflict.remoteVersion.data : conflict.localVersion.data
        
        return ResolutionResult(
            conflict: conflict,
            resolvedData: resolvedData,
            strategy: .firstWriteWins,
            isAutoResolved: true
        )
    }
    
    private func resolveMostRecent(_ conflict: DataConflict) async -> ResolutionResult {
        // Same as lastWriteWins for now
        return await resolveLastWriteWins(conflict)
    }
    
    private func resolveHighestVersion(_ conflict: DataConflict) async -> ResolutionResult {
        let useRemote = conflict.remoteVersion.version.compare(
            conflict.localVersion.version,
            options: .numeric
        ) == .orderedDescending
        
        let resolvedData = useRemote ? conflict.remoteVersion.data : conflict.localVersion.data
        
        return ResolutionResult(
            conflict: conflict,
            resolvedData: resolvedData,
            strategy: .highestVersion,
            isAutoResolved: true
        )
    }
    
    private func resolveMerge(_ conflict: DataConflict) async throws -> ResolutionResult {
        do {
            guard let localJson = try JSONSerialization.jsonObject(with: conflict.localVersion.data) as? [String: Any],
                  let remoteJson = try JSONSerialization.jsonObject(with: conflict.remoteVersion.data) as? [String: Any] else {
                throw AxiomCapabilityError.conflictResolutionFailed("Cannot parse JSON for merge")
            }
            
            let (mergedJson, mergeDetails) = await mergeObjects(local: localJson, remote: remoteJson)
            let mergedData = try JSONSerialization.data(withJSONObject: mergedJson)
            
            return ResolutionResult(
                conflict: conflict,
                resolvedData: mergedData,
                strategy: .merge,
                isAutoResolved: true,
                mergeDetails: mergeDetails
            )
        } catch {
            throw AxiomCapabilityError.conflictResolutionFailed("Merge failed: \(error.localizedDescription)")
        }
    }
    
    private func resolveDeepMerge(_ conflict: DataConflict) async throws -> ResolutionResult {
        // Similar to merge but with recursive merging of nested objects
        do {
            guard let localJson = try JSONSerialization.jsonObject(with: conflict.localVersion.data) as? [String: Any],
                  let remoteJson = try JSONSerialization.jsonObject(with: conflict.remoteVersion.data) as? [String: Any] else {
                throw AxiomCapabilityError.conflictResolutionFailed("Cannot parse JSON for deep merge")
            }
            
            let (mergedJson, mergeDetails) = await deepMergeObjects(local: localJson, remote: remoteJson)
            let mergedData = try JSONSerialization.data(withJSONObject: mergedJson)
            
            return ResolutionResult(
                conflict: conflict,
                resolvedData: mergedData,
                strategy: .deepMerge,
                isAutoResolved: true,
                mergeDetails: mergeDetails
            )
        } catch {
            throw AxiomCapabilityError.conflictResolutionFailed("Deep merge failed: \(error.localizedDescription)")
        }
    }
    
    private func resolveUserChoice(_ conflict: DataConflict) async throws -> ResolutionResult {
        // Use delegate if available
        if let delegate = resolutionDelegate {
            return try await delegate.resolveConflict(conflict)
        } else {
            throw AxiomCapabilityError.conflictResolutionFailed("No user choice delegate available")
        }
    }
    
    private func resolveCustom(_ conflict: DataConflict) async throws -> ResolutionResult {
        // Use delegate for custom resolution
        if let delegate = resolutionDelegate {
            return try await delegate.resolveConflictCustom(conflict)
        } else {
            throw AxiomCapabilityError.conflictResolutionFailed("No custom resolution delegate available")
        }
    }
    
    private func mergeObjects(
        local: [String: Any],
        remote: [String: Any]
    ) async -> ([String: Any], ResolutionResult.MergeDetails) {
        
        var merged: [String: Any] = [:]
        var fieldsFromLocal: [String] = []
        var fieldsFromRemote: [String] = []
        var mergedFields: [String] = []
        var conflictedFields: [String] = []
        
        let allKeys = Set(local.keys).union(Set(remote.keys))
        
        for key in allKeys {
            let localValue = local[key]
            let remoteValue = remote[key]
            
            if let strategy = configuration.fieldMergeStrategies[key] {
                switch strategy {
                case .takeLocal:
                    if let value = localValue {
                        merged[key] = value
                        fieldsFromLocal.append(key)
                    }
                case .takeRemote:
                    if let value = remoteValue {
                        merged[key] = value
                        fieldsFromRemote.append(key)
                    }
                case .takeNewer:
                    // For this example, prefer remote (would need timestamp comparison in real implementation)
                    merged[key] = remoteValue ?? localValue
                    if remoteValue != nil {
                        fieldsFromRemote.append(key)
                    } else {
                        fieldsFromLocal.append(key)
                    }
                case .concatenate:
                    if let localStr = localValue as? String, let remoteStr = remoteValue as? String {
                        merged[key] = localStr + " " + remoteStr
                        mergedFields.append(key)
                    } else {
                        merged[key] = remoteValue ?? localValue
                        conflictedFields.append(key)
                    }
                default:
                    merged[key] = remoteValue ?? localValue
                    if !areValuesEqual(localValue, remoteValue) {
                        conflictedFields.append(key)
                    }
                }
            } else {
                // Default merge strategy
                if areValuesEqual(localValue, remoteValue) {
                    merged[key] = localValue ?? remoteValue
                } else {
                    // Prefer remote for conflicts (last-write-wins default)
                    merged[key] = remoteValue ?? localValue
                    if remoteValue != nil {
                        fieldsFromRemote.append(key)
                    } else {
                        fieldsFromLocal.append(key)
                    }
                    conflictedFields.append(key)
                }
            }
        }
        
        let mergeDetails = ResolutionResult.MergeDetails(
            fieldsFromLocal: fieldsFromLocal,
            fieldsFromRemote: fieldsFromRemote,
            mergedFields: mergedFields,
            conflictedFields: conflictedFields
        )
        
        return (merged, mergeDetails)
    }
    
    private func deepMergeObjects(
        local: [String: Any],
        remote: [String: Any]
    ) async -> ([String: Any], ResolutionResult.MergeDetails) {
        
        // For this implementation, same as regular merge
        // In a full implementation, this would recursively merge nested objects
        return await mergeObjects(local: local, remote: remote)
    }
    
    private func validateResolution(result: ResolutionResult) async -> Bool {
        // Validate against configured rules
        for (field, rule) in configuration.validationRules {
            if !await validateField(data: result.resolvedData, field: field, rule: rule) {
                return false
            }
        }
        
        return true
    }
    
    private func validateField(data: Data, field: String, rule: ConflictResolutionCapabilityConfiguration.ValidationRule) async -> Bool {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return false
            }
            
            let value = json[field]
            
            // Check required
            if rule.required && value == nil {
                return false
            }
            
            // Check data type and other rules
            if let stringValue = value as? String {
                if let minLength = rule.minLength, stringValue.count < minLength {
                    return false
                }
                if let maxLength = rule.maxLength, stringValue.count > maxLength {
                    return false
                }
                if let pattern = rule.pattern {
                    let regex = try NSRegularExpression(pattern: pattern)
                    let range = NSRange(location: 0, length: stringValue.utf16.count)
                    if regex.firstMatch(in: stringValue, options: [], range: range) == nil {
                        return false
                    }
                }
            }
            
            return true
        } catch {
            return false
        }
    }
    
    private func trimConflictHistory() async {
        if conflictHistory.count > configuration.maxHistorySize {
            let excessCount = conflictHistory.count - configuration.maxHistorySize
            conflictHistory.removeFirst(excessCount)
        }
    }
    
    private func loadConflictHistory() async {
        // Load conflict history from persistent storage
        // Implementation would use UserDefaults or Core Data
    }
    
    private func saveConflictHistory() async {
        // Save conflict history to persistent storage
        // Implementation would use UserDefaults or Core Data
    }
    
    private func updateConflictAnalytics(conflict: DataConflict) async {
        // Update analytics with new conflict
        // Implementation would update the analytics struct
    }
    
    private func updateResolutionAnalytics(result: ResolutionResult, duration: TimeInterval) async {
        // Update analytics with resolution result
        // Implementation would update the analytics struct
    }
}

// MARK: - Conflict Resolution Delegate

/// Delegate protocol for custom conflict resolution
public protocol ConflictResolutionDelegate: AnyObject, Sendable {
    func resolveConflict(_ conflict: DataConflict) async throws -> ResolutionResult
    func resolveConflictCustom(_ conflict: DataConflict) async throws -> ResolutionResult
}

// MARK: - Conflict Resolution Capability Implementation

/// Conflict resolution capability providing advanced data conflict resolution
public actor ConflictResolutionCapability: DomainCapability {
    public typealias ConfigurationType = ConflictResolutionCapabilityConfiguration
    public typealias ResourceType = ConflictResolutionCapabilityResource
    
    private var _configuration: ConflictResolutionCapabilityConfiguration
    private var _resources: ConflictResolutionCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "conflict-resolution-capability" }
    
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
    
    public var configuration: ConflictResolutionCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: ConflictResolutionCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: ConflictResolutionCapabilityConfiguration = ConflictResolutionCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = ConflictResolutionCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: ConflictResolutionCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid conflict resolution configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func isSupported() async -> Bool {
        // Conflict resolution is available on all Apple platforms
        true
    }
    
    public func requestPermission() async throws {
        // Conflict resolution doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Conflict Resolution Operations
    
    /// Detect conflict between local and remote data
    public func detectConflict(
        entityType: String,
        entityId: String,
        localData: Data,
        remoteData: Data,
        localVersion: String,
        remoteVersion: String
    ) async throws -> DataConflict? {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Conflict resolution capability not available")
        }
        
        return await _resources.detectConflict(
            entityType: entityType,
            entityId: entityId,
            localData: localData,
            remoteData: remoteData,
            localVersion: localVersion,
            remoteVersion: remoteVersion
        )
    }
    
    /// Resolve a specific conflict
    public func resolveConflict(_ conflict: DataConflict) async throws -> ResolutionResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Conflict resolution capability not available")
        }
        
        return try await _resources.resolveConflict(conflict)
    }
    
    /// Resolve all pending conflicts
    public func resolveAllPendingConflicts() async throws -> [ResolutionResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Conflict resolution capability not available")
        }
        
        return await _resources.resolveAllPendingConflicts()
    }
    
    /// Get pending conflicts
    public func getPendingConflicts() async throws -> [DataConflict] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Conflict resolution capability not available")
        }
        
        return await _resources.getPendingConflicts()
    }
    
    /// Get conflict resolution history
    public func getConflictHistory() async throws -> [ResolutionResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Conflict resolution capability not available")
        }
        
        return await _resources.getConflictHistory()
    }
    
    /// Get conflict analytics
    public func getAnalytics() async throws -> ConflictAnalytics {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Conflict resolution capability not available")
        }
        
        return await _resources.getAnalytics()
    }
    
    /// Clear conflict history
    public func clearConflictHistory() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Conflict resolution capability not available")
        }
        
        await _resources.clearConflictHistory()
    }
    
    /// Set resolution delegate
    public func setResolutionDelegate(_ delegate: ConflictResolutionDelegate?) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Conflict resolution capability not available")
        }
        
        _resources.resolutionDelegate = delegate
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Extensions

extension Data {
    var sha256: String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Need to import CommonCrypto for SHA256
import CommonCrypto

// MARK: - Error Extensions

extension AxiomCapabilityError {
    /// Conflict resolution specific errors
    public static func conflictResolutionError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("Conflict Resolution: \(message)")
    }
    
    public static func conflictResolutionFailed(_ reason: String) -> AxiomCapabilityError {
        .operationFailed("Conflict resolution failed: \(reason)")
    }
    
    public static func conflictResolutionAborted(_ entityId: String) -> AxiomCapabilityError {
        .operationFailed("Conflict resolution aborted for entity: \(entityId)")
    }
    
    public static func validationFailed(_ field: String) -> AxiomCapabilityError {
        .operationFailed("Validation failed for field: \(field)")
    }
}