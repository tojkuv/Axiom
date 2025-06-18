import Foundation
import AxiomCore
import AxiomCapabilities

public actor MockStorageCapability: AxiomCapability {
    public let id = UUID()
    public let name = "MockStorage"
    public let version = "1.0.0"
    
    private var storage: [String: Data] = [:]
    private var shouldFailOnActivate = false
    private var shouldFailOnSave = false
    private var shouldFailOnLoad = false
    private var activationDelay: TimeInterval = 0
    private var operationDelay: TimeInterval = 0
    
    public init() {}
    
    public func activate() async throws {
        if activationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(activationDelay * 1_000_000_000))
        }
        
        if shouldFailOnActivate {
            throw MockStorageError.activationFailed
        }
    }
    
    public func deactivate() async {
        storage.removeAll()
    }
    
    public var isAvailable: Bool {
        return !shouldFailOnActivate
    }
    
    public func save<T: Codable>(_ object: T, to path: String) async throws {
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        if shouldFailOnSave {
            throw MockStorageError.saveFailed
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let data = try encoder.encode(object)
        storage[path] = data
    }
    
    public func load<T: Codable>(_ type: T.Type, from path: String) async throws -> T {
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        if shouldFailOnLoad {
            throw MockStorageError.loadFailed
        }
        
        guard let data = storage[path] else {
            throw MockStorageError.fileNotFound(path)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try decoder.decode(type, from: data)
    }
    
    public func delete(at path: String) async throws {
        storage.removeValue(forKey: path)
    }
    
    public func exists(at path: String) async -> Bool {
        return storage[path] != nil
    }
    
    public func saveArray<T: Codable>(_ objects: [T], to path: String) async throws {
        try await save(objects, to: path)
    }
    
    public func loadArray<T: Codable>(_ type: T.Type, from path: String) async throws -> [T] {
        return try await load([T].self, from: path)
    }
    
    public func listFiles() async throws -> [String] {
        return Array(storage.keys)
    }
    
    public func clear() {
        storage.removeAll()
    }
    
    public func setFailureMode(
        activate: Bool = false,
        save: Bool = false,
        load: Bool = false
    ) {
        shouldFailOnActivate = activate
        shouldFailOnSave = save
        shouldFailOnLoad = load
    }
    
    public func setDelays(
        activation: TimeInterval = 0,
        operation: TimeInterval = 0
    ) {
        activationDelay = activation
        operationDelay = operation
    }
    
    public func getStorageCount() -> Int {
        return storage.count
    }
    
    public func getStoredPaths() -> Set<String> {
        return Set(storage.keys)
    }
}

public enum MockStorageError: Error, LocalizedError {
    case activationFailed
    case saveFailed
    case loadFailed
    case fileNotFound(String)
    
    public var errorDescription: String? {
        switch self {
        case .activationFailed:
            return "Mock storage activation failed"
        case .saveFailed:
            return "Mock storage save failed"
        case .loadFailed:
            return "Mock storage load failed"
        case .fileNotFound(let path):
            return "Mock file not found at path: \(path)"
        }
    }
}