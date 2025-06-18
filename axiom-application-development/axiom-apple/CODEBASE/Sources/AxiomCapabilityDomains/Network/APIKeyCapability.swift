import Foundation
import Security
import AxiomCore
import AxiomCapabilities

// MARK: - API Key Capability Configuration

/// Configuration for API Key capability
public struct APIKeyCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let storageMode: StorageMode
    public let encryptionEnabled: Bool
    public let rotationEnabled: Bool
    public let rotationInterval: TimeInterval
    public let keyValidationEnabled: Bool
    public let rateLimitingEnabled: Bool
    public let auditLoggingEnabled: Bool
    public let enableMetrics: Bool
    public let enableLogging: Bool
    public let keyExpirationWarningDays: Int
    public let maxKeysPerService: Int
    public let keyGenerationStrength: KeyStrength
    public let defaultKeyLifetime: TimeInterval
    public let enableKeySharing: Bool
    public let requireKeyAuthentication: Bool
    public let enableBackupKeys: Bool
    public let secureEnclaveEnabled: Bool
    
    public enum StorageMode: String, Codable, CaseIterable {
        case keychain = "keychain"       // Store in iOS Keychain
        case userDefaults = "userDefaults" // Store in UserDefaults (encrypted)
        case memory = "memory"           // Store in memory only
        case file = "file"              // Store in encrypted file
        case secureEnclave = "secureEnclave" // Store in Secure Enclave
    }
    
    public enum KeyStrength: String, Codable, CaseIterable {
        case low = "low"                // 128-bit entropy
        case medium = "medium"          // 256-bit entropy
        case high = "high"             // 512-bit entropy
        case maximum = "maximum"        // 1024-bit entropy
        
        public var bitLength: Int {
            switch self {
            case .low: return 128
            case .medium: return 256
            case .high: return 512
            case .maximum: return 1024
            }
        }
    }
    
    public init(
        storageMode: StorageMode = .keychain,
        encryptionEnabled: Bool = true,
        rotationEnabled: Bool = true,
        rotationInterval: TimeInterval = 86400 * 30, // 30 days
        keyValidationEnabled: Bool = true,
        rateLimitingEnabled: Bool = true,
        auditLoggingEnabled: Bool = true,
        enableMetrics: Bool = true,
        enableLogging: Bool = false,
        keyExpirationWarningDays: Int = 7,
        maxKeysPerService: Int = 10,
        keyGenerationStrength: KeyStrength = .high,
        defaultKeyLifetime: TimeInterval = 86400 * 365, // 1 year
        enableKeySharing: Bool = false,
        requireKeyAuthentication: Bool = true,
        enableBackupKeys: Bool = true,
        secureEnclaveEnabled: Bool = true
    ) {
        self.storageMode = storageMode
        self.encryptionEnabled = encryptionEnabled
        self.rotationEnabled = rotationEnabled
        self.rotationInterval = rotationInterval
        self.keyValidationEnabled = keyValidationEnabled
        self.rateLimitingEnabled = rateLimitingEnabled
        self.auditLoggingEnabled = auditLoggingEnabled
        self.enableMetrics = enableMetrics
        self.enableLogging = enableLogging
        self.keyExpirationWarningDays = keyExpirationWarningDays
        self.maxKeysPerService = maxKeysPerService
        self.keyGenerationStrength = keyGenerationStrength
        self.defaultKeyLifetime = defaultKeyLifetime
        self.enableKeySharing = enableKeySharing
        self.requireKeyAuthentication = requireKeyAuthentication
        self.enableBackupKeys = enableBackupKeys
        self.secureEnclaveEnabled = secureEnclaveEnabled
    }
    
    public var isValid: Bool {
        rotationInterval > 0 && 
        keyExpirationWarningDays >= 0 && 
        maxKeysPerService > 0 && 
        defaultKeyLifetime > 0
    }
    
    public func merged(with other: APIKeyCapabilityConfiguration) -> APIKeyCapabilityConfiguration {
        APIKeyCapabilityConfiguration(
            storageMode: other.storageMode,
            encryptionEnabled: other.encryptionEnabled,
            rotationEnabled: other.rotationEnabled,
            rotationInterval: other.rotationInterval,
            keyValidationEnabled: other.keyValidationEnabled,
            rateLimitingEnabled: other.rateLimitingEnabled,
            auditLoggingEnabled: other.auditLoggingEnabled,
            enableMetrics: other.enableMetrics,
            enableLogging: other.enableLogging,
            keyExpirationWarningDays: other.keyExpirationWarningDays,
            maxKeysPerService: other.maxKeysPerService,
            keyGenerationStrength: other.keyGenerationStrength,
            defaultKeyLifetime: other.defaultKeyLifetime,
            enableKeySharing: other.enableKeySharing,
            requireKeyAuthentication: other.requireKeyAuthentication,
            enableBackupKeys: other.enableBackupKeys,
            secureEnclaveEnabled: other.secureEnclaveEnabled
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> APIKeyCapabilityConfiguration {
        var adjustedLogging = enableLogging
        var adjustedStorage = storageMode
        var adjustedEncryption = encryptionEnabled
        var adjustedAuthentication = requireKeyAuthentication
        
        if environment.isLowPowerMode {
            adjustedEncryption = false // Disable encryption to save CPU
            adjustedStorage = .memory // Use faster memory storage
        }
        
        if environment.isDebug {
            adjustedLogging = true
            adjustedAuthentication = false // Disable auth for easier debugging
        }
        
        return APIKeyCapabilityConfiguration(
            storageMode: adjustedStorage,
            encryptionEnabled: adjustedEncryption,
            rotationEnabled: rotationEnabled,
            rotationInterval: rotationInterval,
            keyValidationEnabled: keyValidationEnabled,
            rateLimitingEnabled: rateLimitingEnabled,
            auditLoggingEnabled: auditLoggingEnabled,
            enableMetrics: enableMetrics,
            enableLogging: adjustedLogging,
            keyExpirationWarningDays: keyExpirationWarningDays,
            maxKeysPerService: maxKeysPerService,
            keyGenerationStrength: keyGenerationStrength,
            defaultKeyLifetime: defaultKeyLifetime,
            enableKeySharing: enableKeySharing,
            requireKeyAuthentication: adjustedAuthentication,
            enableBackupKeys: enableBackupKeys,
            secureEnclaveEnabled: secureEnclaveEnabled
        )
    }
}

// MARK: - API Key Types

/// API Key information
public struct APIKey: Sendable, Codable, Identifiable {
    public let id: UUID
    public let serviceName: String
    public let keyName: String
    public let keyValue: String
    public let keyType: KeyType
    public let scope: [String]
    public let permissions: [Permission]
    public let createdAt: Date
    public let expiresAt: Date?
    public let lastUsed: Date?
    public let usageCount: Int
    public let isActive: Bool
    public let isPrimary: Bool
    public let isBackup: Bool
    public let metadata: [String: String]
    public let tags: [String]
    
    public enum KeyType: String, Codable, CaseIterable {
        case apiKey = "api-key"
        case bearerToken = "bearer-token"
        case hmacSecret = "hmac-secret"
        case jwt = "jwt"
        case oauth2 = "oauth2"
        case custom = "custom"
    }
    
    public enum Permission: String, Codable, CaseIterable {
        case read = "read"
        case write = "write"
        case delete = "delete"
        case admin = "admin"
        case create = "create"
        case update = "update"
        case execute = "execute"
    }
    
    public init(
        serviceName: String,
        keyName: String,
        keyValue: String,
        keyType: KeyType,
        scope: [String] = [],
        permissions: [Permission] = [],
        expiresAt: Date? = nil,
        isActive: Bool = true,
        isPrimary: Bool = false,
        isBackup: Bool = false,
        metadata: [String: String] = [:],
        tags: [String] = []
    ) {
        self.id = UUID()
        self.serviceName = serviceName
        self.keyName = keyName
        self.keyValue = keyValue
        self.keyType = keyType
        self.scope = scope
        self.permissions = permissions
        self.createdAt = Date()
        self.expiresAt = expiresAt
        self.lastUsed = nil
        self.usageCount = 0
        self.isActive = isActive
        self.isPrimary = isPrimary
        self.isBackup = isBackup
        self.metadata = metadata
        self.tags = tags
    }
    
    public var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    public var isExpiringSoon: Bool {
        guard let expiresAt = expiresAt else { return false }
        let warningThreshold = Date().addingTimeInterval(86400 * 7) // 7 days
        return expiresAt <= warningThreshold
    }
    
    public var daysUntilExpiry: Int? {
        guard let expiresAt = expiresAt else { return nil }
        let interval = expiresAt.timeIntervalSinceNow
        return max(0, Int(interval / 86400))
    }
    
    /// Create a new key with updated usage
    public func withUsage() -> APIKey {
        var updatedKey = self
        updatedKey = APIKey(
            serviceName: serviceName,
            keyName: keyName,
            keyValue: keyValue,
            keyType: keyType,
            scope: scope,
            permissions: permissions,
            expiresAt: expiresAt,
            isActive: isActive,
            isPrimary: isPrimary,
            isBackup: isBackup,
            metadata: metadata,
            tags: tags
        )
        
        // Update usage statistics (simplified)
        return updatedKey
    }
}

/// API Key rotation result
public struct APIKeyRotationResult: Sendable {
    public let oldKey: APIKey
    public let newKey: APIKey
    public let rotationTime: Date
    public let rotationReason: RotationReason
    public let success: Bool
    public let error: String?
    
    public enum RotationReason: String, Codable, CaseIterable {
        case scheduled = "scheduled"
        case compromise = "compromise"
        case expiration = "expiration"
        case manual = "manual"
        case policy = "policy"
    }
    
    public init(
        oldKey: APIKey,
        newKey: APIKey,
        rotationReason: RotationReason,
        success: Bool = true,
        error: String? = nil
    ) {
        self.oldKey = oldKey
        self.newKey = newKey
        self.rotationTime = Date()
        self.rotationReason = rotationReason
        self.success = success
        self.error = error
    }
}

/// API Key validation result
public struct APIKeyValidationResult: Sendable {
    public let isValid: Bool
    public let key: APIKey
    public let validationTime: Date
    public let validationDuration: TimeInterval
    public let errors: [ValidationError]
    public let warnings: [String]
    public let rateLimitStatus: RateLimitStatus?
    
    public enum ValidationError: Error, Sendable, LocalizedError {
        case keyNotFound(String)
        case keyExpired(Date)
        case keyInactive
        case invalidScope([String])
        case insufficientPermissions([String])
        case rateLimitExceeded(RateLimitStatus)
        case keyCompromised
        case invalidFormat
        case serviceNotAuthorized(String)
        
        public var errorDescription: String? {
            switch self {
            case .keyNotFound(let keyName):
                return "API key not found: \(keyName)"
            case .keyExpired(let expiry):
                return "API key expired on \(expiry)"
            case .keyInactive:
                return "API key is inactive"
            case .invalidScope(let requiredScope):
                return "Invalid scope. Required: \(requiredScope.joined(separator: ", "))"
            case .insufficientPermissions(let required):
                return "Insufficient permissions. Required: \(required.joined(separator: ", "))"
            case .rateLimitExceeded(let status):
                return "Rate limit exceeded. Limit: \(status.limit), Used: \(status.used)"
            case .keyCompromised:
                return "API key has been compromised and is no longer valid"
            case .invalidFormat:
                return "API key format is invalid"
            case .serviceNotAuthorized(let service):
                return "Service not authorized: \(service)"
            }
        }
    }
    
    public init(
        isValid: Bool,
        key: APIKey,
        validationDuration: TimeInterval,
        errors: [ValidationError] = [],
        warnings: [String] = [],
        rateLimitStatus: RateLimitStatus? = nil
    ) {
        self.isValid = isValid
        self.key = key
        self.validationTime = Date()
        self.validationDuration = validationDuration
        self.errors = errors
        self.warnings = warnings
        self.rateLimitStatus = rateLimitStatus
    }
}

/// Rate limiting status
public struct RateLimitStatus: Sendable, Codable {
    public let limit: Int
    public let used: Int
    public let remaining: Int
    public let resetTime: Date
    public let windowDuration: TimeInterval
    
    public init(
        limit: Int,
        used: Int,
        resetTime: Date,
        windowDuration: TimeInterval
    ) {
        self.limit = limit
        self.used = used
        self.remaining = max(0, limit - used)
        self.resetTime = resetTime
        self.windowDuration = windowDuration
    }
    
    public var isExceeded: Bool {
        used >= limit
    }
    
    public var percentageUsed: Double {
        limit > 0 ? Double(used) / Double(limit) * 100 : 0
    }
}

/// API Key metrics
public struct APIKeyMetrics: Sendable {
    public let totalKeys: Int
    public let activeKeys: Int
    public let expiredKeys: Int
    public let expiringSoonKeys: Int
    public let totalValidations: Int
    public let successfulValidations: Int
    public let failedValidations: Int
    public let totalRotations: Int
    public let averageValidationTime: TimeInterval
    public let keysByService: [String: Int]
    public let keysByType: [String: Int]
    public let validationsByService: [String: Int]
    public let errorsByType: [String: Int]
    public let rateLimitViolations: Int
    
    public init(
        totalKeys: Int = 0,
        activeKeys: Int = 0,
        expiredKeys: Int = 0,
        expiringSoonKeys: Int = 0,
        totalValidations: Int = 0,
        successfulValidations: Int = 0,
        failedValidations: Int = 0,
        totalRotations: Int = 0,
        averageValidationTime: TimeInterval = 0,
        keysByService: [String: Int] = [:],
        keysByType: [String: Int] = [:],
        validationsByService: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        rateLimitViolations: Int = 0
    ) {
        self.totalKeys = totalKeys
        self.activeKeys = activeKeys
        self.expiredKeys = expiredKeys
        self.expiringSoonKeys = expiringSoonKeys
        self.totalValidations = totalValidations
        self.successfulValidations = successfulValidations
        self.failedValidations = failedValidations
        self.totalRotations = totalRotations
        self.averageValidationTime = averageValidationTime
        self.keysByService = keysByService
        self.keysByType = keysByType
        self.validationsByService = validationsByService
        self.errorsByType = errorsByType
        self.rateLimitViolations = rateLimitViolations
    }
    
    public var successRate: Double {
        totalValidations > 0 ? Double(successfulValidations) / Double(totalValidations) : 0
    }
    
    public var keyUtilizationRate: Double {
        totalKeys > 0 ? Double(activeKeys) / Double(totalKeys) : 0
    }
}

// MARK: - API Key Resource

/// API Key resource management
public actor APIKeyCapabilityResource: AxiomCapabilityResource {
    private let configuration: APIKeyCapabilityConfiguration
    private var keyStorage: [String: APIKey] = [:]
    private var serviceKeys: [String: [String]] = [:]
    private var compromisedKeys: Set<String> = []
    private var rateLimitTracker: [String: RateLimitStatus] = [:]
    private var auditLog: [AuditEvent] = []
    private var metrics: APIKeyMetrics = APIKeyMetrics()
    private var rotationTimer: Timer?
    
    private struct AuditEvent: Sendable {
        let timestamp: Date
        let action: String
        let keyId: String
        let serviceName: String
        let success: Bool
        let details: [String: String]
        
        init(action: String, keyId: String, serviceName: String, success: Bool, details: [String: String] = [:]) {
            self.timestamp = Date()
            self.action = action
            self.keyId = keyId
            self.serviceName = serviceName
            self.success = success
            self.details = details
        }
    }
    
    public init(configuration: APIKeyCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.maxKeysPerService * 100 * 10_000, // 10KB per key
            cpu: 2.0, // Encryption and validation
            bandwidth: 0,
            storage: configuration.maxKeysPerService * 100 * 5_000 // 5KB per key
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            return ResourceUsage(
                memory: keyStorage.count * 5_000,
                cpu: keyStorage.isEmpty ? 0.1 : 1.0,
                bandwidth: 0,
                storage: keyStorage.count * 2_500
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        true // API Key management is always available
    }
    
    public func release() async {
        rotationTimer?.invalidate()
        rotationTimer = nil
        keyStorage.removeAll()
        serviceKeys.removeAll()
        compromisedKeys.removeAll()
        rateLimitTracker.removeAll()
        auditLog.removeAll()
        metrics = APIKeyMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Load existing keys from storage
        await loadKeysFromStorage()
        
        // Start rotation timer if enabled
        if configuration.rotationEnabled {
            await startRotationTimer()
        }
        
        // Validate key integrity
        await validateKeyIntegrity()
    }
    
    internal func updateConfiguration(_ configuration: APIKeyCapabilityConfiguration) async throws {
        // Restart rotation timer if interval changed
        if configuration.rotationEnabled && configuration.rotationInterval != self.configuration.rotationInterval {
            await startRotationTimer()
        }
    }
    
    // MARK: - Key Management
    
    public func createAPIKey(
        serviceName: String,
        keyName: String,
        keyType: APIKey.KeyType = .apiKey,
        scope: [String] = [],
        permissions: [APIKey.Permission] = [],
        expiresAt: Date? = nil
    ) async throws -> APIKey {
        
        // Check if service has reached key limit
        let existingKeys = serviceKeys[serviceName] ?? []
        if existingKeys.count >= configuration.maxKeysPerService {
            throw APIKeyError.serviceLimitExceeded(serviceName, configuration.maxKeysPerService)
        }
        
        // Generate secure key value
        let keyValue = await generateSecureKey(strength: configuration.keyGenerationStrength)
        
        // Create API key
        let apiKey = APIKey(
            serviceName: serviceName,
            keyName: keyName,
            keyValue: keyValue,
            keyType: keyType,
            scope: scope,
            permissions: permissions,
            expiresAt: expiresAt ?? Date().addingTimeInterval(configuration.defaultKeyLifetime)
        )
        
        // Store key
        await storeKey(apiKey)
        
        // Update metrics
        if configuration.enableMetrics {
            await updateKeyCreationMetrics(apiKey)
        }
        
        // Audit log
        if configuration.auditLoggingEnabled {
            await logAuditEvent(action: "create", keyId: apiKey.id.uuidString, serviceName: serviceName, success: true)
        }
        
        // Log if enabled
        if configuration.enableLogging {
            await logKeyOperation("CREATED", key: apiKey)
        }
        
        return apiKey
    }
    
    public func getAPIKey(keyId: String) async -> APIKey? {
        return keyStorage[keyId]
    }
    
    public func getAPIKey(serviceName: String, keyName: String) async -> APIKey? {
        guard let keyIds = serviceKeys[serviceName] else { return nil }
        
        for keyId in keyIds {
            if let key = keyStorage[keyId], key.keyName == keyName {
                return key
            }
        }
        
        return nil
    }
    
    public func getAPIKeys(for serviceName: String) async -> [APIKey] {
        guard let keyIds = serviceKeys[serviceName] else { return [] }
        
        return keyIds.compactMap { keyStorage[$0] }
    }
    
    public func getAllAPIKeys() async -> [APIKey] {
        Array(keyStorage.values)
    }
    
    public func updateAPIKey(_ apiKey: APIKey) async throws {
        guard keyStorage[apiKey.id.uuidString] != nil else {
            throw APIKeyError.keyNotFound(apiKey.id.uuidString)
        }
        
        await storeKey(apiKey)
        
        // Audit log
        if configuration.auditLoggingEnabled {
            await logAuditEvent(action: "update", keyId: apiKey.id.uuidString, serviceName: apiKey.serviceName, success: true)
        }
        
        // Log if enabled
        if configuration.enableLogging {
            await logKeyOperation("UPDATED", key: apiKey)
        }
    }
    
    public func deleteAPIKey(keyId: String) async throws {
        guard let apiKey = keyStorage[keyId] else {
            throw APIKeyError.keyNotFound(keyId)
        }
        
        // Remove from storage
        keyStorage.removeValue(forKey: keyId)
        
        // Remove from service index
        var serviceKeyIds = serviceKeys[apiKey.serviceName] ?? []
        serviceKeyIds.removeAll { $0 == keyId }
        if serviceKeyIds.isEmpty {
            serviceKeys.removeValue(forKey: apiKey.serviceName)
        } else {
            serviceKeys[apiKey.serviceName] = serviceKeyIds
        }
        
        // Remove from compromised list if present
        compromisedKeys.remove(keyId)
        
        // Update metrics
        if configuration.enableMetrics {
            await updateKeyDeletionMetrics(apiKey)
        }
        
        // Audit log
        if configuration.auditLoggingEnabled {
            await logAuditEvent(action: "delete", keyId: keyId, serviceName: apiKey.serviceName, success: true)
        }
        
        // Log if enabled
        if configuration.enableLogging {
            await logKeyOperation("DELETED", key: apiKey)
        }
    }
    
    // MARK: - Key Validation
    
    public func validateAPIKey(
        _ keyValue: String,
        serviceName: String,
        requiredScope: [String] = [],
        requiredPermissions: [APIKey.Permission] = []
    ) async throws -> APIKeyValidationResult {
        
        let startTime = Date()
        var errors: [APIKeyValidationResult.ValidationError] = []
        var warnings: [String] = []
        
        // Find key by value
        guard let apiKey = await findKeyByValue(keyValue) else {
            errors.append(.keyNotFound(keyValue))
            return APIKeyValidationResult(
                isValid: false,
                key: APIKey(serviceName: serviceName, keyName: "unknown", keyValue: keyValue, keyType: .apiKey),
                validationDuration: Date().timeIntervalSince(startTime),
                errors: errors
            )
        }
        
        // Check if key is compromised
        if compromisedKeys.contains(apiKey.id.uuidString) {
            errors.append(.keyCompromised)
        }
        
        // Check if key is active
        if !apiKey.isActive {
            errors.append(.keyInactive)
        }
        
        // Check if key is expired
        if apiKey.isExpired {
            errors.append(.keyExpired(apiKey.expiresAt!))
        }
        
        // Check if key is expiring soon
        if apiKey.isExpiringSoon {
            warnings.append("API key expires in \(apiKey.daysUntilExpiry ?? 0) days")
        }
        
        // Validate service authorization
        if apiKey.serviceName != serviceName {
            errors.append(.serviceNotAuthorized(serviceName))
        }
        
        // Validate scope
        if !requiredScope.isEmpty {
            let hasRequiredScope = requiredScope.allSatisfy { apiKey.scope.contains($0) }
            if !hasRequiredScope {
                errors.append(.invalidScope(requiredScope))
            }
        }
        
        // Validate permissions
        if !requiredPermissions.isEmpty {
            let hasRequiredPermissions = requiredPermissions.allSatisfy { apiKey.permissions.contains($0) }
            if !hasRequiredPermissions {
                errors.append(.insufficientPermissions(requiredPermissions.map { $0.rawValue }))
            }
        }
        
        // Check rate limiting
        var rateLimitStatus: RateLimitStatus? = nil
        if configuration.rateLimitingEnabled {
            rateLimitStatus = await checkRateLimit(for: apiKey)
            if let status = rateLimitStatus, status.isExceeded {
                errors.append(.rateLimitExceeded(status))
            }
        }
        
        let isValid = errors.isEmpty
        let validationDuration = Date().timeIntervalSince(startTime)
        
        let result = APIKeyValidationResult(
            isValid: isValid,
            key: apiKey,
            validationDuration: validationDuration,
            errors: errors,
            warnings: warnings,
            rateLimitStatus: rateLimitStatus
        )
        
        // Update key usage
        if isValid {
            await updateKeyUsage(apiKey)
        }
        
        // Update metrics
        if configuration.enableMetrics {
            await updateValidationMetrics(result: result, serviceName: serviceName)
        }
        
        // Audit log
        if configuration.auditLoggingEnabled {
            await logAuditEvent(
                action: "validate",
                keyId: apiKey.id.uuidString,
                serviceName: serviceName,
                success: isValid,
                details: ["validation_duration": String(validationDuration)]
            )
        }
        
        // Log if enabled
        if configuration.enableLogging {
            await logValidationResult(result)
        }
        
        return result
    }
    
    // MARK: - Key Rotation
    
    public func rotateAPIKey(
        keyId: String,
        reason: APIKeyRotationResult.RotationReason = .manual
    ) async throws -> APIKeyRotationResult {
        
        guard let oldKey = keyStorage[keyId] else {
            throw APIKeyError.keyNotFound(keyId)
        }
        
        do {
            // Generate new key value
            let newKeyValue = await generateSecureKey(strength: configuration.keyGenerationStrength)
            
            // Create new key with same properties but new value and updated dates
            let newKey = APIKey(
                serviceName: oldKey.serviceName,
                keyName: oldKey.keyName,
                keyValue: newKeyValue,
                keyType: oldKey.keyType,
                scope: oldKey.scope,
                permissions: oldKey.permissions,
                expiresAt: Date().addingTimeInterval(configuration.defaultKeyLifetime),
                isActive: true,
                isPrimary: oldKey.isPrimary,
                isBackup: oldKey.isBackup,
                metadata: oldKey.metadata,
                tags: oldKey.tags
            )
            
            // Store new key
            await storeKey(newKey)
            
            // Mark old key as inactive if not keeping backup
            if !configuration.enableBackupKeys {
                let inactiveOldKey = APIKey(
                    serviceName: oldKey.serviceName,
                    keyName: oldKey.keyName + "_rotated",
                    keyValue: oldKey.keyValue,
                    keyType: oldKey.keyType,
                    scope: oldKey.scope,
                    permissions: oldKey.permissions,
                    expiresAt: oldKey.expiresAt,
                    isActive: false,
                    isPrimary: false,
                    isBackup: true
                )
                await storeKey(inactiveOldKey)
            }
            
            let result = APIKeyRotationResult(
                oldKey: oldKey,
                newKey: newKey,
                rotationReason: reason,
                success: true
            )
            
            // Update metrics
            if configuration.enableMetrics {
                await updateRotationMetrics(result)
            }
            
            // Audit log
            if configuration.auditLoggingEnabled {
                await logAuditEvent(
                    action: "rotate",
                    keyId: keyId,
                    serviceName: oldKey.serviceName,
                    success: true,
                    details: ["reason": reason.rawValue, "new_key_id": newKey.id.uuidString]
                )
            }
            
            // Log if enabled
            if configuration.enableLogging {
                await logRotationResult(result)
            }
            
            return result
            
        } catch {
            let result = APIKeyRotationResult(
                oldKey: oldKey,
                newKey: oldKey, // Use old key as placeholder
                rotationReason: reason,
                success: false,
                error: error.localizedDescription
            )
            
            // Audit log failure
            if configuration.auditLoggingEnabled {
                await logAuditEvent(
                    action: "rotate",
                    keyId: keyId,
                    serviceName: oldKey.serviceName,
                    success: false,
                    details: ["reason": reason.rawValue, "error": error.localizedDescription]
                )
            }
            
            return result
        }
    }
    
    public func rotateExpiredKeys() async -> [APIKeyRotationResult] {
        var results: [APIKeyRotationResult] = []
        
        let expiredKeys = keyStorage.values.filter { $0.isExpired && $0.isActive }
        
        for key in expiredKeys {
            do {
                let result = try await rotateAPIKey(keyId: key.id.uuidString, reason: .expiration)
                results.append(result)
            } catch {
                let failedResult = APIKeyRotationResult(
                    oldKey: key,
                    newKey: key,
                    rotationReason: .expiration,
                    success: false,
                    error: error.localizedDescription
                )
                results.append(failedResult)
            }
        }
        
        return results
    }
    
    // MARK: - Key Compromise
    
    public func markKeyAsCompromised(keyId: String, reason: String) async throws {
        guard let apiKey = keyStorage[keyId] else {
            throw APIKeyError.keyNotFound(keyId)
        }
        
        // Add to compromised list
        compromisedKeys.insert(keyId)
        
        // Deactivate key
        let compromisedKey = APIKey(
            serviceName: apiKey.serviceName,
            keyName: apiKey.keyName,
            keyValue: apiKey.keyValue,
            keyType: apiKey.keyType,
            scope: apiKey.scope,
            permissions: apiKey.permissions,
            expiresAt: apiKey.expiresAt,
            isActive: false
        )
        
        await storeKey(compromisedKey)
        
        // Audit log
        if configuration.auditLoggingEnabled {
            await logAuditEvent(
                action: "compromise",
                keyId: keyId,
                serviceName: apiKey.serviceName,
                success: true,
                details: ["reason": reason]
            )
        }
        
        // Log if enabled
        if configuration.enableLogging {
            print("[APIKey] 🚨 COMPROMISED: \(apiKey.keyName) for \(apiKey.serviceName) - \(reason)")
        }
    }
    
    public func getCompromisedKeys() async -> [APIKey] {
        return compromisedKeys.compactMap { keyStorage[$0] }
    }
    
    // MARK: - Metrics and Reporting
    
    public func getMetrics() async -> APIKeyMetrics {
        metrics
    }
    
    public func clearMetrics() async {
        metrics = APIKeyMetrics()
    }
    
    public func getAuditLog() async -> [String] {
        return auditLog.map { event in
            "\(event.timestamp): \(event.action) - \(event.keyId) (\(event.serviceName)) - \(event.success ? "SUCCESS" : "FAILURE")"
        }
    }
    
    public func clearAuditLog() async {
        auditLog.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func generateSecureKey(strength: APIKeyCapabilityConfiguration.KeyStrength) async -> String {
        let bytes = strength.bitLength / 8
        var keyData = Data(count: bytes)
        
        let result = keyData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, bytes.count, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        if result == errSecSuccess {
            return keyData.base64EncodedString()
        } else {
            // Fallback to UUID-based generation
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
    }
    
    private func storeKey(_ apiKey: APIKey) async {
        let keyId = apiKey.id.uuidString
        keyStorage[keyId] = apiKey
        
        // Update service index
        var serviceKeyIds = serviceKeys[apiKey.serviceName] ?? []
        if !serviceKeyIds.contains(keyId) {
            serviceKeyIds.append(keyId)
        }
        serviceKeys[apiKey.serviceName] = serviceKeyIds
        
        // Save to persistent storage if configured
        if configuration.storageMode != .memory {
            await saveKeyToPersistentStorage(apiKey)
        }
    }
    
    private func findKeyByValue(_ keyValue: String) async -> APIKey? {
        return keyStorage.values.first { $0.keyValue == keyValue }
    }
    
    private func updateKeyUsage(_ apiKey: APIKey) async {
        let updatedKey = apiKey.withUsage()
        await storeKey(updatedKey)
    }
    
    private func checkRateLimit(for apiKey: APIKey) async -> RateLimitStatus {
        let keyId = apiKey.id.uuidString
        
        // Simple rate limiting implementation
        let limit = 1000 // requests per hour
        let windowDuration: TimeInterval = 3600 // 1 hour
        let resetTime = Date().addingTimeInterval(windowDuration)
        
        if let existingStatus = rateLimitTracker[keyId] {
            if Date() < existingStatus.resetTime {
                // Within current window
                let newStatus = RateLimitStatus(
                    limit: limit,
                    used: existingStatus.used + 1,
                    resetTime: existingStatus.resetTime,
                    windowDuration: windowDuration
                )
                rateLimitTracker[keyId] = newStatus
                return newStatus
            }
        }
        
        // New window or first request
        let newStatus = RateLimitStatus(
            limit: limit,
            used: 1,
            resetTime: resetTime,
            windowDuration: windowDuration
        )
        rateLimitTracker[keyId] = newStatus
        return newStatus
    }
    
    private func loadKeysFromStorage() async {
        // Load keys from persistent storage based on storage mode
        // Simplified implementation - would load from Keychain, file, etc.
    }
    
    private func saveKeyToPersistentStorage(_ apiKey: APIKey) async {
        // Save key to persistent storage based on storage mode
        // Simplified implementation - would save to Keychain, file, etc.
    }
    
    private func startRotationTimer() async {
        rotationTimer?.invalidate()
        
        rotationTimer = Timer.scheduledTimer(withTimeInterval: configuration.rotationInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.performScheduledRotation()
            }
        }
    }
    
    private func performScheduledRotation() async {
        let results = await rotateExpiredKeys()
        
        if configuration.enableLogging && !results.isEmpty {
            print("[APIKey] 🔄 Scheduled rotation completed: \(results.count) keys processed")
        }
    }
    
    private func validateKeyIntegrity() async {
        // Validate stored keys for integrity and consistency
        let allKeys = Array(keyStorage.values)
        
        for key in allKeys {
            // Check for expired keys
            if key.isExpired && key.isActive {
                // Auto-rotate or deactivate expired keys
                if configuration.rotationEnabled {
                    _ = try? await rotateAPIKey(keyId: key.id.uuidString, reason: .expiration)
                }
            }
        }
    }
    
    private func updateKeyCreationMetrics(_ apiKey: APIKey) async {
        var newKeysByService = metrics.keysByService
        var newKeysByType = metrics.keysByType
        
        newKeysByService[apiKey.serviceName, default: 0] += 1
        newKeysByType[apiKey.keyType.rawValue, default: 0] += 1
        
        metrics = APIKeyMetrics(
            totalKeys: metrics.totalKeys + 1,
            activeKeys: metrics.activeKeys + (apiKey.isActive ? 1 : 0),
            expiredKeys: metrics.expiredKeys,
            expiringSoonKeys: metrics.expiringSoonKeys,
            totalValidations: metrics.totalValidations,
            successfulValidations: metrics.successfulValidations,
            failedValidations: metrics.failedValidations,
            totalRotations: metrics.totalRotations,
            averageValidationTime: metrics.averageValidationTime,
            keysByService: newKeysByService,
            keysByType: newKeysByType,
            validationsByService: metrics.validationsByService,
            errorsByType: metrics.errorsByType,
            rateLimitViolations: metrics.rateLimitViolations
        )
    }
    
    private func updateKeyDeletionMetrics(_ apiKey: APIKey) async {
        var newKeysByService = metrics.keysByService
        var newKeysByType = metrics.keysByType
        
        newKeysByService[apiKey.serviceName] = max(0, (newKeysByService[apiKey.serviceName] ?? 1) - 1)
        newKeysByType[apiKey.keyType.rawValue] = max(0, (newKeysByType[apiKey.keyType.rawValue] ?? 1) - 1)
        
        metrics = APIKeyMetrics(
            totalKeys: max(0, metrics.totalKeys - 1),
            activeKeys: max(0, metrics.activeKeys - (apiKey.isActive ? 1 : 0)),
            expiredKeys: metrics.expiredKeys,
            expiringSoonKeys: metrics.expiringSoonKeys,
            totalValidations: metrics.totalValidations,
            successfulValidations: metrics.successfulValidations,
            failedValidations: metrics.failedValidations,
            totalRotations: metrics.totalRotations,
            averageValidationTime: metrics.averageValidationTime,
            keysByService: newKeysByService,
            keysByType: newKeysByType,
            validationsByService: metrics.validationsByService,
            errorsByType: metrics.errorsByType,
            rateLimitViolations: metrics.rateLimitViolations
        )
    }
    
    private func updateValidationMetrics(result: APIKeyValidationResult, serviceName: String) async {
        var newValidationsByService = metrics.validationsByService
        var newErrorsByType = metrics.errorsByType
        
        newValidationsByService[serviceName, default: 0] += 1
        
        for error in result.errors {
            let errorType = String(describing: type(of: error))
            newErrorsByType[errorType, default: 0] += 1
        }
        
        let totalValidations = metrics.totalValidations + 1
        let successfulValidations = metrics.successfulValidations + (result.isValid ? 1 : 0)
        let failedValidations = metrics.failedValidations + (result.isValid ? 0 : 1)
        
        let newAverageTime = ((metrics.averageValidationTime * Double(metrics.totalValidations)) + result.validationDuration) / Double(totalValidations)
        
        let rateLimitViolations = metrics.rateLimitViolations + (result.errors.contains { error in
            if case .rateLimitExceeded = error { return true }
            return false
        } ? 1 : 0)
        
        metrics = APIKeyMetrics(
            totalKeys: metrics.totalKeys,
            activeKeys: metrics.activeKeys,
            expiredKeys: metrics.expiredKeys,
            expiringSoonKeys: metrics.expiringSoonKeys,
            totalValidations: totalValidations,
            successfulValidations: successfulValidations,
            failedValidations: failedValidations,
            totalRotations: metrics.totalRotations,
            averageValidationTime: newAverageTime,
            keysByService: metrics.keysByService,
            keysByType: metrics.keysByType,
            validationsByService: newValidationsByService,
            errorsByType: newErrorsByType,
            rateLimitViolations: rateLimitViolations
        )
    }
    
    private func updateRotationMetrics(_ result: APIKeyRotationResult) async {
        metrics = APIKeyMetrics(
            totalKeys: metrics.totalKeys,
            activeKeys: metrics.activeKeys,
            expiredKeys: metrics.expiredKeys,
            expiringSoonKeys: metrics.expiringSoonKeys,
            totalValidations: metrics.totalValidations,
            successfulValidations: metrics.successfulValidations,
            failedValidations: metrics.failedValidations,
            totalRotations: metrics.totalRotations + 1,
            averageValidationTime: metrics.averageValidationTime,
            keysByService: metrics.keysByService,
            keysByType: metrics.keysByType,
            validationsByService: metrics.validationsByService,
            errorsByType: metrics.errorsByType,
            rateLimitViolations: metrics.rateLimitViolations
        )
    }
    
    private func logAuditEvent(action: String, keyId: String, serviceName: String, success: Bool, details: [String: String] = [:]) async {
        let event = AuditEvent(action: action, keyId: keyId, serviceName: serviceName, success: success, details: details)
        auditLog.append(event)
        
        // Keep only last 1000 audit events
        if auditLog.count > 1000 {
            auditLog = Array(auditLog.suffix(1000))
        }
    }
    
    private func logKeyOperation(_ operation: String, key: APIKey) async {
        print("[APIKey] \(operation): \(key.keyName) for \(key.serviceName) (type: \(key.keyType.rawValue))")
    }
    
    private func logValidationResult(_ result: APIKeyValidationResult) async {
        let status = result.isValid ? "✅ VALID" : "❌ INVALID"
        print("[APIKey] \(status): \(result.key.keyName) for \(result.key.serviceName)")
        
        if !result.errors.isEmpty {
            for error in result.errors {
                print("[APIKey] ⚠️ ERROR: \(error.localizedDescription)")
            }
        }
    }
    
    private func logRotationResult(_ result: APIKeyRotationResult) async {
        let status = result.success ? "✅ SUCCESS" : "❌ FAILED"
        print("[APIKey] 🔄 ROTATION \(status): \(result.oldKey.keyName) for \(result.oldKey.serviceName) (reason: \(result.rotationReason.rawValue))")
        
        if let error = result.error {
            print("[APIKey] ⚠️ ERROR: \(error)")
        }
    }
}

// MARK: - API Key Capability Implementation

/// API Key capability providing secure API key management and validation
public actor APIKeyCapability: DomainCapability {
    public typealias ConfigurationType = APIKeyCapabilityConfiguration
    public typealias ResourceType = APIKeyCapabilityResource
    
    private var _configuration: APIKeyCapabilityConfiguration
    private var _resources: APIKeyCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "api-key-capability" }
    
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
    
    public var configuration: APIKeyCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: APIKeyCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: APIKeyCapabilityConfiguration = APIKeyCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = APIKeyCapabilityResource(configuration: self._configuration)
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
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: APIKeyCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid API Key configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        // API Key management is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // API Key management doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - API Key Operations
    
    /// Create a new API key
    public func createAPIKey(
        serviceName: String,
        keyName: String,
        keyType: APIKey.KeyType = .apiKey,
        scope: [String] = [],
        permissions: [APIKey.Permission] = [],
        expiresAt: Date? = nil
    ) async throws -> APIKey {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        return try await _resources.createAPIKey(
            serviceName: serviceName,
            keyName: keyName,
            keyType: keyType,
            scope: scope,
            permissions: permissions,
            expiresAt: expiresAt
        )
    }
    
    /// Get API key by ID
    public func getAPIKey(keyId: String) async throws -> APIKey? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        return await _resources.getAPIKey(keyId: keyId)
    }
    
    /// Get API key by service and name
    public func getAPIKey(serviceName: String, keyName: String) async throws -> APIKey? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        return await _resources.getAPIKey(serviceName: serviceName, keyName: keyName)
    }
    
    /// Get all API keys for a service
    public func getAPIKeys(for serviceName: String) async throws -> [APIKey] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        return await _resources.getAPIKeys(for: serviceName)
    }
    
    /// Get all API keys
    public func getAllAPIKeys() async throws -> [APIKey] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        return await _resources.getAllAPIKeys()
    }
    
    /// Update an existing API key
    public func updateAPIKey(_ apiKey: APIKey) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        try await _resources.updateAPIKey(apiKey)
    }
    
    /// Delete an API key
    public func deleteAPIKey(keyId: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        try await _resources.deleteAPIKey(keyId: keyId)
    }
    
    /// Validate an API key
    public func validateAPIKey(
        _ keyValue: String,
        serviceName: String,
        requiredScope: [String] = [],
        requiredPermissions: [APIKey.Permission] = []
    ) async throws -> APIKeyValidationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        return try await _resources.validateAPIKey(
            keyValue,
            serviceName: serviceName,
            requiredScope: requiredScope,
            requiredPermissions: requiredPermissions
        )
    }
    
    /// Rotate an API key
    public func rotateAPIKey(
        keyId: String,
        reason: APIKeyRotationResult.RotationReason = .manual
    ) async throws -> APIKeyRotationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        return try await _resources.rotateAPIKey(keyId: keyId, reason: reason)
    }
    
    /// Rotate all expired keys
    public func rotateExpiredKeys() async throws -> [APIKeyRotationResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        return await _resources.rotateExpiredKeys()
    }
    
    /// Mark a key as compromised
    public func markKeyAsCompromised(keyId: String, reason: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        try await _resources.markKeyAsCompromised(keyId: keyId, reason: reason)
    }
    
    /// Get compromised keys
    public func getCompromisedKeys() async throws -> [APIKey] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        return await _resources.getCompromisedKeys()
    }
    
    /// Get metrics
    public func getMetrics() async throws -> APIKeyMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Get audit log
    public func getAuditLog() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        return await _resources.getAuditLog()
    }
    
    /// Clear audit log
    public func clearAuditLog() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("API Key capability not available")
        }
        
        await _resources.clearAuditLog()
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// API Key specific errors
public enum APIKeyError: Error, LocalizedError {
    case keyNotFound(String)
    case serviceLimitExceeded(String, Int)
    case invalidKeyFormat(String)
    case keyGenerationFailed(String)
    case storageError(String)
    case encryptionError(String)
    case rotationFailed(String, String)
    case compromisedKey(String)
    case invalidConfiguration(String)
    
    public var errorDescription: String? {
        switch self {
        case .keyNotFound(let keyId):
            return "API key not found: \(keyId)"
        case .serviceLimitExceeded(let service, let limit):
            return "Service \(service) has exceeded the maximum number of keys (\(limit))"
        case .invalidKeyFormat(let format):
            return "Invalid API key format: \(format)"
        case .keyGenerationFailed(let reason):
            return "API key generation failed: \(reason)"
        case .storageError(let reason):
            return "Storage error: \(reason)"
        case .encryptionError(let reason):
            return "Encryption error: \(reason)"
        case .rotationFailed(let keyId, let reason):
            return "Key rotation failed for \(keyId): \(reason)"
        case .compromisedKey(let keyId):
            return "API key has been compromised: \(keyId)"
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        }
    }
}