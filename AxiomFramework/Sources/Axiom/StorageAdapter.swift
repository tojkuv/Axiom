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

// Concrete persistence capability using storage adapter
public actor AdapterBasedPersistence: PersistenceCapability {
    private let adapter: StorageAdapter
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public nonisolated var id: String { "adapter-persistence" }
    public var isAvailable: Bool { true }
    
    public init(adapter: StorageAdapter) {
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
    
    public func delete(key: String) async throws {
        try await adapter.delete(key: key)
    }
    
    public func migrate(from oldVersion: String, to newVersion: String) async throws {
        // Migration logic would go here
        // For now, this is a no-op
    }
    
    public func initialize() async throws {
        // Adapter is ready to use
    }
    
    public func terminate() async {
        // Clean up if needed
    }
    
    public func shutdown() async throws {
        // Clean up if needed
    }
}