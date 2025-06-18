import Foundation
import Security
import AxiomCore
import AxiomCapabilities

// MARK: - Keychain Capability Configuration

/// Configuration for Keychain capability
public struct KeychainCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let service: String
    public let accessGroup: String?
    public let accessibility: KeychainAccessibility
    public let enableTouchID: Bool
    public let enableFaceID: Bool
    public let enablePasscode: Bool
    public let enableSynchronization: Bool
    public let keyPrefix: String
    
    public enum KeychainAccessibility: String, Codable, CaseIterable {
        case whenUnlocked = "kSecAttrAccessibleWhenUnlocked"
        case afterFirstUnlock = "kSecAttrAccessibleAfterFirstUnlock"
        case whenUnlockedThisDeviceOnly = "kSecAttrAccessibleWhenUnlockedThisDeviceOnly"
        case afterFirstUnlockThisDeviceOnly = "kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly"
        case whenPasscodeSetThisDeviceOnly = "kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly"
        
        public var secAttrValue: CFString {
            switch self {
            case .whenUnlocked:
                return kSecAttrAccessibleWhenUnlocked
            case .afterFirstUnlock:
                return kSecAttrAccessibleAfterFirstUnlock
            case .whenUnlockedThisDeviceOnly:
                return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            case .afterFirstUnlockThisDeviceOnly:
                return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            case .whenPasscodeSetThisDeviceOnly:
                return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            }
        }
    }
    
    public init(
        service: String,
        accessGroup: String? = nil,
        accessibility: KeychainAccessibility = .whenUnlocked,
        enableTouchID: Bool = false,
        enableFaceID: Bool = false,
        enablePasscode: Bool = true,
        enableSynchronization: Bool = false,
        keyPrefix: String = ""
    ) {
        self.service = service
        self.accessGroup = accessGroup
        self.accessibility = accessibility
        self.enableTouchID = enableTouchID
        self.enableFaceID = enableFaceID
        self.enablePasscode = enablePasscode
        self.enableSynchronization = enableSynchronization
        self.keyPrefix = keyPrefix
    }
    
    public var isValid: Bool {
        !service.isEmpty
    }
    
    public func merged(with other: KeychainCapabilityConfiguration) -> KeychainCapabilityConfiguration {
        KeychainCapabilityConfiguration(
            service: other.service,
            accessGroup: other.accessGroup,
            accessibility: other.accessibility,
            enableTouchID: other.enableTouchID,
            enableFaceID: other.enableFaceID,
            enablePasscode: other.enablePasscode,
            enableSynchronization: other.enableSynchronization,
            keyPrefix: other.keyPrefix
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> KeychainCapabilityConfiguration {
        var adjustedSynchronization = enableSynchronization
        var adjustedBiometrics = enableTouchID || enableFaceID
        
        if environment.isLowPowerMode {
            adjustedSynchronization = false
        }
        
        if environment.isDebug {
            adjustedBiometrics = false // Disable biometrics in debug for easier testing
        }
        
        return KeychainCapabilityConfiguration(
            service: service,
            accessGroup: accessGroup,
            accessibility: accessibility,
            enableTouchID: adjustedBiometrics && enableTouchID,
            enableFaceID: adjustedBiometrics && enableFaceID,
            enablePasscode: enablePasscode,
            enableSynchronization: adjustedSynchronization,
            keyPrefix: keyPrefix
        )
    }
}

// MARK: - Keychain Item Types

/// Keychain item data structure
public struct KeychainItem: Sendable, Codable {
    public let key: String
    public let data: Data
    public let account: String?
    public let creationDate: Date
    public let modificationDate: Date
    public let accessibility: KeychainCapabilityConfiguration.KeychainAccessibility
    
    public init(
        key: String,
        data: Data,
        account: String? = nil,
        creationDate: Date = Date(),
        modificationDate: Date = Date(),
        accessibility: KeychainCapabilityConfiguration.KeychainAccessibility = .whenUnlocked
    ) {
        self.key = key
        self.data = data
        self.account = account
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.accessibility = accessibility
    }
}

/// Keychain operation types
public enum KeychainOperation: Sendable {
    case add(String, Data)
    case read(String)
    case update(String, Data)
    case delete(String)
    case deleteAll
    case list
}

// MARK: - Keychain Query Builder

/// Helper for building Keychain queries
public struct KeychainQueryBuilder {
    private let configuration: KeychainCapabilityConfiguration
    
    public init(configuration: KeychainCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public func baseQuery() -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: configuration.service
        ]
        
        if let accessGroup = configuration.accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        if configuration.enableSynchronization {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }
        
        return query
    }
    
    public func addQuery(for key: String, data: Data, account: String? = nil) -> [String: Any] {
        var query = baseQuery()
        query[kSecAttrAccount as String] = formatKey(key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = configuration.accessibility.secAttrValue
        
        if let account = account {
            query[kSecAttrAccount as String] = account
        }
        
        // Add biometric access control if enabled
        if configuration.enableTouchID || configuration.enableFaceID {
            var accessFlags: SecAccessControlCreateFlags = []
            
            if configuration.enableTouchID {
                accessFlags.insert(.touchIDAny)
            }
            
            if configuration.enableFaceID {
                accessFlags.insert(.biometryAny)
            }
            
            if configuration.enablePasscode {
                accessFlags.insert(.devicePasscode)
            }
            
            if let accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                configuration.accessibility.secAttrValue,
                accessFlags,
                nil
            ) {
                query[kSecAttrAccessControl as String] = accessControl
                query.removeValue(forKey: kSecAttrAccessible as String)
            }
        }
        
        return query
    }
    
    public func readQuery(for key: String) -> [String: Any] {
        var query = baseQuery()
        query[kSecAttrAccount as String] = formatKey(key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        return query
    }
    
    public func updateQuery(for key: String) -> ([String: Any], [String: Any]) {
        var query = baseQuery()
        query[kSecAttrAccount as String] = formatKey(key)
        
        let attributes: [String: Any] = [
            kSecAttrModificationDate as String: Date()
        ]
        
        return (query, attributes)
    }
    
    public func deleteQuery(for key: String) -> [String: Any] {
        var query = baseQuery()
        query[kSecAttrAccount as String] = formatKey(key)
        
        return query
    }
    
    public func listQuery() -> [String: Any] {
        var query = baseQuery()
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        
        return query
    }
    
    private func formatKey(_ key: String) -> String {
        if configuration.keyPrefix.isEmpty {
            return key
        }
        return "\(configuration.keyPrefix).\(key)"
    }
}

// MARK: - Keychain Resource

/// Keychain resource management
public actor KeychainCapabilityResource: AxiomCapabilityResource {
    private let configuration: KeychainCapabilityConfiguration
    private var queryBuilder: KeychainQueryBuilder?
    private var isKeychainAvailable: Bool = false
    
    public init(configuration: KeychainCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public func allocate() async throws {
        // Test keychain availability
        let testData = "test".data(using: .utf8)!
        let testKey = "__keychain_test__"
        
        queryBuilder = KeychainQueryBuilder(configuration: configuration)
        
        // Try to write and read a test item
        let addQuery = queryBuilder!.addQuery(for: testKey, data: testData)
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        
        if addStatus == errSecSuccess || addStatus == errSecDuplicateItem {
            // Clean up test item
            let deleteQuery = queryBuilder!.deleteQuery(for: testKey)
            SecItemDelete(deleteQuery as CFDictionary)
            
            isKeychainAvailable = true
        } else {
            throw AxiomCapabilityError.initializationFailed("Keychain not available: \(addStatus)")
        }
    }
    
    public func deallocate() async {
        queryBuilder = nil
        isKeychainAvailable = false
    }
    
    public var isAllocated: Bool {
        isKeychainAvailable && queryBuilder != nil
    }
    
    public func updateConfiguration(_ configuration: KeychainCapabilityConfiguration) async throws {
        // Keychain configuration changes require reallocation
        if isAllocated {
            await deallocate()
            try await allocate()
        }
    }
    
    // MARK: - Keychain Access
    
    public func getQueryBuilder() -> KeychainQueryBuilder? {
        queryBuilder
    }
    
    public func formatKey(_ key: String) -> String {
        if configuration.keyPrefix.isEmpty {
            return key
        }
        return "\(configuration.keyPrefix).\(key)"
    }
}

// MARK: - Keychain Capability Implementation

/// Keychain capability providing secure credential storage
public actor KeychainCapability: DomainCapability {
    public typealias ConfigurationType = KeychainCapabilityConfiguration
    public typealias ResourceType = KeychainCapabilityResource
    
    private var _configuration: KeychainCapabilityConfiguration
    private var _resources: KeychainCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "keychain-capability" }
    
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
    
    public var configuration: KeychainCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: KeychainCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: KeychainCapabilityConfiguration,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = KeychainCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: KeychainCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Keychain configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func isSupported() async -> Bool {
        // Keychain is available on all Apple platforms
        true
    }
    
    public func requestPermission() async throws {
        // Keychain doesn't require special permissions, but may require biometric authorization
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Keychain Operations
    
    /// Store data in keychain
    public func store(data: Data, forKey key: String, account: String? = nil) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Keychain capability not available")
        }
        
        let queryBuilder = await _resources.getQueryBuilder()
        guard let queryBuilder = queryBuilder else {
            throw AxiomCapabilityError.resourceAllocationFailed("Keychain query builder not available")
        }
        
        let addQuery = queryBuilder.addQuery(for: key, data: data, account: account)
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let status = SecItemAdd(addQuery as CFDictionary, nil)
                
                switch status {
                case errSecSuccess:
                    continuation.resume()
                case errSecDuplicateItem:
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Keychain item already exists for key: \(key)"))
                default:
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Keychain store failed: \(status)"))
                }
            }
        }
    }
    
    /// Retrieve data from keychain
    public func retrieve(forKey key: String) async throws -> Data? {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Keychain capability not available")
        }
        
        let queryBuilder = await _resources.getQueryBuilder()
        guard let queryBuilder = queryBuilder else {
            throw AxiomCapabilityError.resourceAllocationFailed("Keychain query builder not available")
        }
        
        let readQuery = queryBuilder.readQuery(for: key)
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result: AnyObject?
                let status = SecItemCopyMatching(readQuery as CFDictionary, &result)
                
                switch status {
                case errSecSuccess:
                    if let resultDict = result as? [String: Any],
                       let data = resultDict[kSecValueData as String] as? Data {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(returning: nil)
                    }
                case errSecItemNotFound:
                    continuation.resume(returning: nil)
                default:
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Keychain retrieve failed: \(status)"))
                }
            }
        }
    }
    
    /// Update data in keychain
    public func update(data: Data, forKey key: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Keychain capability not available")
        }
        
        let queryBuilder = await _resources.getQueryBuilder()
        guard let queryBuilder = queryBuilder else {
            throw AxiomCapabilityError.resourceAllocationFailed("Keychain query builder not available")
        }
        
        let (updateQuery, attributes) = queryBuilder.updateQuery(for: key)
        var updateAttributes = attributes
        updateAttributes[kSecValueData as String] = data
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let status = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
                
                switch status {
                case errSecSuccess:
                    continuation.resume()
                case errSecItemNotFound:
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Keychain item not found for key: \(key)"))
                default:
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Keychain update failed: \(status)"))
                }
            }
        }
    }
    
    /// Delete data from keychain
    public func delete(forKey key: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Keychain capability not available")
        }
        
        let queryBuilder = await _resources.getQueryBuilder()
        guard let queryBuilder = queryBuilder else {
            throw AxiomCapabilityError.resourceAllocationFailed("Keychain query builder not available")
        }
        
        let deleteQuery = queryBuilder.deleteQuery(for: key)
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let status = SecItemDelete(deleteQuery as CFDictionary)
                
                switch status {
                case errSecSuccess:
                    continuation.resume()
                case errSecItemNotFound:
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Keychain item not found for key: \(key)"))
                default:
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Keychain delete failed: \(status)"))
                }
            }
        }
    }
    
    /// Check if key exists in keychain
    public func exists(forKey key: String) async throws -> Bool {
        let data = try await retrieve(forKey: key)
        return data != nil
    }
    
    /// List all keys in keychain
    public func getAllKeys() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Keychain capability not available")
        }
        
        let queryBuilder = await _resources.getQueryBuilder()
        guard let queryBuilder = queryBuilder else {
            throw AxiomCapabilityError.resourceAllocationFailed("Keychain query builder not available")
        }
        
        let listQuery = queryBuilder.listQuery()
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result: AnyObject?
                let status = SecItemCopyMatching(listQuery as CFDictionary, &result)
                
                switch status {
                case errSecSuccess:
                    if let items = result as? [[String: Any]] {
                        let keys = items.compactMap { item in
                            item[kSecAttrAccount as String] as? String
                        }
                        continuation.resume(returning: keys)
                    } else {
                        continuation.resume(returning: [])
                    }
                case errSecItemNotFound:
                    continuation.resume(returning: [])
                default:
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Keychain list failed: \(status)"))
                }
            }
        }
    }
    
    /// Delete all items from keychain
    public func deleteAll() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Keychain capability not available")
        }
        
        let queryBuilder = await _resources.getQueryBuilder()
        guard let queryBuilder = queryBuilder else {
            throw AxiomCapabilityError.resourceAllocationFailed("Keychain query builder not available")
        }
        
        let deleteQuery = queryBuilder.baseQuery()
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let status = SecItemDelete(deleteQuery as CFDictionary)
                
                switch status {
                case errSecSuccess, errSecItemNotFound:
                    continuation.resume()
                default:
                    continuation.resume(throwing: AxiomCapabilityError.operationFailed("Keychain delete all failed: \(status)"))
                }
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Store string in keychain
    public func storeString(_ string: String, forKey key: String, account: String? = nil) async throws {
        guard let data = string.data(using: .utf8) else {
            throw AxiomCapabilityError.operationFailed("Failed to convert string to data")
        }
        try await store(data: data, forKey: key, account: account)
    }
    
    /// Retrieve string from keychain
    public func retrieveString(forKey key: String) async throws -> String? {
        guard let data = try await retrieve(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Store credentials in keychain
    public func storeCredentials(username: String, password: String, forKey key: String) async throws {
        let credentials = ["username": username, "password": password]
        let data = try JSONSerialization.data(withJSONObject: credentials)
        try await store(data: data, forKey: key, account: username)
    }
    
    /// Retrieve credentials from keychain
    public func retrieveCredentials(forKey key: String) async throws -> (username: String, password: String)? {
        guard let data = try await retrieve(forKey: key),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: String],
              let username = json["username"],
              let password = json["password"] else {
            return nil
        }
        return (username: username, password: password)
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
    /// Keychain specific errors
    public static func keychainError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("Keychain: \(message)")
    }
    
    public static func keychainItemNotFound(_ key: String) -> AxiomCapabilityError {
        .operationFailed("Keychain item not found: \(key)")
    }
    
    public static func keychainItemExists(_ key: String) -> AxiomCapabilityError {
        .operationFailed("Keychain item already exists: \(key)")
    }
    
    public static func keychainAccessDenied() -> AxiomCapabilityError {
        .permissionDenied("Keychain access denied - biometric authentication may be required")
    }
    
    public static func keychainStatus(_ status: OSStatus) -> AxiomCapabilityError {
        .operationFailed("Keychain operation failed with status: \(status)")
    }
}