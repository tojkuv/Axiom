import Foundation

// Storage adapter protocol
public protocol StorageAdapter: Actor {
    func read(key: String) async throws -> Data?
    func write(key: String, data: Data) async throws
    func delete(key: String) async throws
    func exists(key: String) async -> Bool
}

// Built-in file storage adapter
public actor FileStorageAdapter: StorageAdapter {
    private let directory: URL
    
    public init(directory: URL) {
        self.directory = directory
    }
    
    public func read(key: String) async throws -> Data? {
        let fileURL = directory.appendingPathComponent(key)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        return try Data(contentsOf: fileURL)
    }
    
    public func write(key: String, data: Data) async throws {
        // Ensure directory exists
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        let fileURL = directory.appendingPathComponent(key)
        try data.write(to: fileURL)
    }
    
    public func delete(key: String) async throws {
        let fileURL = directory.appendingPathComponent(key)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    public func exists(key: String) async -> Bool {
        let fileURL = directory.appendingPathComponent(key)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}

// UserDefaults storage adapter
public actor UserDefaultsStorageAdapter: StorageAdapter {
    private let userDefaults: UserDefaults
    private let keyPrefix: String
    
    public init(userDefaults: UserDefaults = .standard, keyPrefix: String = "axiom.") {
        self.userDefaults = userDefaults
        self.keyPrefix = keyPrefix
    }
    
    private func prefixedKey(_ key: String) -> String {
        return keyPrefix + key
    }
    
    public func read(key: String) async throws -> Data? {
        let prefixedKey = prefixedKey(key)
        return userDefaults.data(forKey: prefixedKey)
    }
    
    public func write(key: String, data: Data) async throws {
        let prefixedKey = prefixedKey(key)
        userDefaults.set(data, forKey: prefixedKey)
    }
    
    public func delete(key: String) async throws {
        let prefixedKey = prefixedKey(key)
        userDefaults.removeObject(forKey: prefixedKey)
    }
    
    public func exists(key: String) async -> Bool {
        let prefixedKey = prefixedKey(key)
        return userDefaults.object(forKey: prefixedKey) != nil
    }
}

// Memory storage adapter
public actor MemoryStorageAdapter: StorageAdapter {
    private var storage: [String: Data] = [:]
    
    public init() {}
    
    public func read(key: String) async throws -> Data? {
        return storage[key]
    }
    
    public func write(key: String, data: Data) async throws {
        storage[key] = data
    }
    
    public func delete(key: String) async throws {
        storage.removeValue(forKey: key)
    }
    
    public func exists(key: String) async -> Bool {
        return storage[key] != nil
    }
    
    public func clear() async {
        storage.removeAll()
    }
}

// Keychain storage adapter (secure storage)
public actor KeychainStorageAdapter: StorageAdapter {
    private let service: String
    private let accessGroup: String?
    
    public init(service: String = "com.axiom.storage", accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }
    
    public func read(key: String) async throws -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.readFailed(status)
        }
        
        return result as? Data
    }
    
    public func write(key: String, data: Data) async throws {
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        var query = addQuery
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Item exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]
            
            let attributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.writeFailed(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.writeFailed(status)
        }
    }
    
    public func delete(key: String) async throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    public func exists(key: String) async -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}

// Keychain error types
public enum KeychainError: Error {
    case readFailed(OSStatus)
    case writeFailed(OSStatus)
    case deleteFailed(OSStatus)
}

// Concrete persistence capability using storage adapter
public actor AdapterBasedPersistence: PersistenceCapability {
    private let adapter: any StorageAdapter
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public nonisolated var id: String { "adapter-persistence" }
    public var isAvailable: Bool { true }
    
    public init(adapter: any StorageAdapter) {
        self.adapter = adapter
    }
    
    public func save<T: Codable>(_ value: T, for key: String) async throws {
        let data = try encoder.encode(value)
        try await adapter.write(key: key, data: data)
    }
    
    public func load<T: Codable>(_ type: T.Type, for key: String) async throws -> T? {
        guard let data = try await adapter.read(key: key) else {
            return nil
        }
        return try decoder.decode(type, from: data)
    }
    
    public func load(key: String) async throws -> Data? {
        return try await adapter.read(key: key)
    }
    
    public func delete(key: String) async throws {
        try await adapter.delete(key: key)
    }
    
    public func exists(key: String) async -> Bool {
        return await adapter.exists(key: key)
    }
    
    public func saveBatch<T: Codable>(_ items: [(key: String, value: T)]) async throws {
        for (key, value) in items {
            try await save(value, for: key)
        }
    }
    
    public func deleteBatch(keys: [String]) async throws {
        for key in keys {
            try await delete(key: key)
        }
    }
    
    public func migrate(from oldVersion: String, to newVersion: String) async throws {
        // Migration logic would go here
        // For now, this is a no-op
    }
    
    public func activate() async throws {
        // Adapter is ready to use
    }
    
    public func deactivate() async {
        // Clean up if needed
    }
    
    public func shutdown() async throws {
        // Clean up if needed
    }
}