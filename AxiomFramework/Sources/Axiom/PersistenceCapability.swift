import Foundation

// Core persistence capability protocol
public protocol PersistenceCapability: Capability {
    /// Save state to persistent storage
    func save<T: Codable>(_ value: T, for key: String) async throws
    
    /// Load state from persistent storage
    func load<T: Codable>(_ type: T.Type, for key: String) async throws -> T?
    
    /// Delete state from persistent storage
    func delete(key: String) async throws
    
    /// Migrate data between versions
    func migrate(from oldVersion: String, to newVersion: String) async throws
}

// Persistable client protocol
public protocol Persistable: Client {
    /// Keys for persisted properties
    static var persistedKeys: [String] { get }
    
    /// Persistence capability instance
    var persistence: PersistenceCapability { get }
    
    /// Persist current state
    func persistState() async throws
}

// Extension to provide default implementation
extension Persistable {
    public func persistState() async throws {
        // This will be implemented by concrete clients
        // Each client knows how to persist its own state
    }
}

// Mock persistence for testing
public actor MockPersistenceCapability: PersistenceCapability {
    private var storage: [String: Data] = [:]
    
    public var saveCount: Int = 0
    public var loadCount: Int = 0
    
    public init() {}
    
    public func save<T: Codable>(_ value: T, for key: String) async throws {
        saveCount += 1
        let data = try JSONEncoder().encode(value)
        storage[key] = data
    }
    
    public func load<T: Codable>(_ type: T.Type, for key: String) async throws -> T? {
        loadCount += 1
        guard let data = storage[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    public func delete(key: String) async throws {
        storage.removeValue(forKey: key)
    }
    
    public func migrate(from oldVersion: String, to newVersion: String) async throws {
        // No-op for mock
    }
    
    // Capability protocol requirements
    public nonisolated var id: String { "mock-persistence" }
    
    public var isAvailable: Bool { true }
    
    public func activate() async throws {
        // No activation needed for mock
    }
    
    public func deactivate() async {
        // Clear storage on deactivation
        storage.removeAll()
    }
    
    public func shutdown() async throws {
        // Clear storage on shutdown
        storage.removeAll()
    }
}