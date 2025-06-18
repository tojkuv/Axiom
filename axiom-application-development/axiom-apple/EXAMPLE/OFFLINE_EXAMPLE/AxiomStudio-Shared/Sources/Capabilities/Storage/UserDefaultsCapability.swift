import Foundation
import AxiomCore
import AxiomCapabilities

public actor UserDefaultsCapability: AxiomCapability {
    public let id = UUID()
    public let name = "UserDefaults"
    public let version = "1.0.0"
    
    private let userDefaults: UserDefaults
    private let suiteName: String?
    private let keyPrefix: String
    
    public init(suiteName: String? = nil, keyPrefix: String = "axiom.studio.") {
        self.suiteName = suiteName
        self.keyPrefix = keyPrefix
        
        if let suiteName = suiteName {
            self.userDefaults = UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
        } else {
            self.userDefaults = UserDefaults.standard
        }
    }
    
    public func activate() async throws {
    }
    
    public func deactivate() async {
    }
    
    public var isAvailable: Bool {
        return true
    }
    
    private func prefixedKey(_ key: String) -> String {
        return keyPrefix + key
    }
    
    public func set<T: Codable>(_ value: T, forKey key: String) async throws {
        let prefixed = prefixedKey(key)
        
        if let stringValue = value as? String {
            userDefaults.set(stringValue, forKey: prefixed)
        } else if let intValue = value as? Int {
            userDefaults.set(intValue, forKey: prefixed)
        } else if let doubleValue = value as? Double {
            userDefaults.set(doubleValue, forKey: prefixed)
        } else if let boolValue = value as? Bool {
            userDefaults.set(boolValue, forKey: prefixed)
        } else if let dataValue = value as? Data {
            userDefaults.set(dataValue, forKey: prefixed)
        } else if let urlValue = value as? URL {
            userDefaults.set(urlValue, forKey: prefixed)
        } else if let dateValue = value as? Date {
            userDefaults.set(dateValue, forKey: prefixed)
        } else {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(value)
            userDefaults.set(data, forKey: prefixed)
        }
    }
    
    public func get<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T? {
        let prefixed = prefixedKey(key)
        
        if type == String.self {
            return userDefaults.string(forKey: prefixed) as? T
        } else if type == Int.self {
            let value = userDefaults.object(forKey: prefixed)
            return value != nil ? userDefaults.integer(forKey: prefixed) as? T : nil
        } else if type == Double.self {
            let value = userDefaults.object(forKey: prefixed)
            return value != nil ? userDefaults.double(forKey: prefixed) as? T : nil
        } else if type == Bool.self {
            let value = userDefaults.object(forKey: prefixed)
            return value != nil ? userDefaults.bool(forKey: prefixed) as? T : nil
        } else if type == Data.self {
            return userDefaults.data(forKey: prefixed) as? T
        } else if type == URL.self {
            return userDefaults.url(forKey: prefixed) as? T
        } else if type == Date.self {
            return userDefaults.object(forKey: prefixed) as? T
        } else {
            guard let data = userDefaults.data(forKey: prefixed) else {
                return nil
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        }
    }
    
    public func get<T: Codable>(_ type: T.Type, forKey key: String, defaultValue: T) async throws -> T {
        return try await get(type, forKey: key) ?? defaultValue
    }
    
    public func remove(forKey key: String) async {
        let prefixed = prefixedKey(key)
        userDefaults.removeObject(forKey: prefixed)
    }
    
    public func exists(forKey key: String) async -> Bool {
        let prefixed = prefixedKey(key)
        return userDefaults.object(forKey: prefixed) != nil
    }
    
    public func getAllKeys() async -> [String] {
        return userDefaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(keyPrefix) }
            .map { String($0.dropFirst(keyPrefix.count)) }
    }
    
    public func removeAll() async {
        let keys = await getAllKeys()
        for key in keys {
            await remove(forKey: key)
        }
    }
    
    public func synchronize() async -> Bool {
        return userDefaults.synchronize()
    }
    
    public func setArray<T: Codable>(_ array: [T], forKey key: String) async throws {
        try await set(array, forKey: key)
    }
    
    public func getArray<T: Codable>(_ type: T.Type, forKey key: String) async throws -> [T]? {
        return try await get([T].self, forKey: key)
    }
    
    public func appendToArray<T: Codable>(_ item: T, forKey key: String, type: T.Type) async throws {
        var array = try await getArray(type, forKey: key) ?? []
        array.append(item)
        try await setArray(array, forKey: key)
    }
    
    public func removeFromArray<T: Codable & Equatable>(_ item: T, forKey key: String, type: T.Type) async throws {
        var array = try await getArray(type, forKey: key) ?? []
        array.removeAll { $0 == item }
        try await setArray(array, forKey: key)
    }
    
    public func setDictionary<K: Codable & Hashable, V: Codable>(_ dictionary: [K: V], forKey key: String) async throws {
        try await set(dictionary, forKey: key)
    }
    
    public func getDictionary<K: Codable & Hashable, V: Codable>(_ keyType: K.Type, _ valueType: V.Type, forKey key: String) async throws -> [K: V]? {
        return try await get([K: V].self, forKey: key)
    }
    
    public func incrementInteger(forKey key: String, by amount: Int = 1) async throws {
        let current = try await get(Int.self, forKey: key) ?? 0
        try await set(current + amount, forKey: key)
    }
    
    public func incrementDouble(forKey key: String, by amount: Double = 1.0) async throws {
        let current = try await get(Double.self, forKey: key) ?? 0.0
        try await set(current + amount, forKey: key)
    }
    
    public func toggle(forKey key: String) async throws {
        let current = try await get(Bool.self, forKey: key) ?? false
        try await set(!current, forKey: key)
    }
}

public enum UserDefaultsError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case invalidType
    case synchronizationFailed
    
    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode value for UserDefaults"
        case .decodingFailed:
            return "Failed to decode value from UserDefaults"
        case .invalidType:
            return "Invalid type for UserDefaults operation"
        case .synchronizationFailed:
            return "Failed to synchronize UserDefaults"
        }
    }
}