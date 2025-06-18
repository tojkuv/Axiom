import Foundation
import Security
import AxiomCore
import AxiomCapabilities

public actor KeychainStorageCapability: AxiomCapability {
    public let id = UUID()
    public let name = "KeychainStorage"
    public let version = "1.0.0"
    
    private let service: String
    private let accessGroup: String?
    
    public init(service: String = "com.axiom.studio", accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }
    
    public func activate() async throws {
    }
    
    public func deactivate() async {
    }
    
    public var isAvailable: Bool {
        return true
    }
    
    public func store(_ data: Data, forKey key: String) async throws {
        var query = baseQuery(for: key)
        query[kSecValueData] = data
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            try await update(data, forKey: key)
        } else if status != errSecSuccess {
            throw KeychainError.storeFailed(status)
        }
    }
    
    public func store<T: Codable>(_ object: T, forKey key: String) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(object)
        try await store(data, forKey: key)
    }
    
    public func retrieve(forKey key: String) async throws -> Data {
        var query = baseQuery(for: key)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound(key)
            }
            throw KeychainError.retrieveFailed(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    public func retrieve<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T {
        let data = try await retrieve(forKey: key)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }
    
    public func update(_ data: Data, forKey key: String) async throws {
        let query = baseQuery(for: key)
        let attributes: [CFString: Any] = [kSecValueData: data]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        guard status == errSecSuccess else {
            throw KeychainError.updateFailed(status)
        }
    }
    
    public func update<T: Codable>(_ object: T, forKey key: String) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(object)
        try await update(data, forKey: key)
    }
    
    public func delete(forKey key: String) async throws {
        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    public func exists(forKey key: String) async -> Bool {
        do {
            _ = try await retrieve(forKey: key)
            return true
        } catch {
            return false
        }
    }
    
    public func deleteAll() async throws {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup] = accessGroup
        }
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteAllFailed(status)
        }
    }
    
    public func getAllKeys() async throws -> [String] {
        var query = baseQuery()
        query[kSecReturnAttributes] = true
        query[kSecMatchLimit] = kSecMatchLimitAll
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return []
            }
            throw KeychainError.retrieveFailed(status)
        }
        
        guard let items = result as? [[CFString: Any]] else {
            return []
        }
        
        return items.compactMap { item in
            item[kSecAttrAccount] as? String
        }
    }
    
    private func baseQuery(for key: String? = nil) -> [CFString: Any] {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service
        ]
        
        if let key = key {
            query[kSecAttrAccount] = key
        }
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup] = accessGroup
        }
        
        return query
    }
}

public enum KeychainError: Error, LocalizedError {
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case updateFailed(OSStatus)
    case deleteFailed(OSStatus)
    case deleteAllFailed(OSStatus)
    case itemNotFound(String)
    case invalidData
    case encodingFailed
    case decodingFailed
    
    public var errorDescription: String? {
        switch self {
        case .storeFailed(let status):
            return "Failed to store item in Keychain (status: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve item from Keychain (status: \(status))"
        case .updateFailed(let status):
            return "Failed to update item in Keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete item from Keychain (status: \(status))"
        case .deleteAllFailed(let status):
            return "Failed to delete all items from Keychain (status: \(status))"
        case .itemNotFound(let key):
            return "Item not found in Keychain for key: \(key)"
        case .invalidData:
            return "Invalid data retrieved from Keychain"
        case .encodingFailed:
            return "Failed to encode object for Keychain storage"
        case .decodingFailed:
            return "Failed to decode object from Keychain data"
        }
    }
}