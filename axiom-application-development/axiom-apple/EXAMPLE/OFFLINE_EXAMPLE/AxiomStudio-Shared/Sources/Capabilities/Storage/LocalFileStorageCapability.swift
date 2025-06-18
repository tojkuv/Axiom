import Foundation
import AxiomCore
import AxiomCapabilities

public actor LocalFileStorageCapability: AxiomCapability {
    public let id = UUID()
    public let name = "LocalFileStorage"
    public let version = "1.0.0"
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init() throws {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw LocalFileStorageError.documentsDirectoryNotFound
        }
        self.documentsDirectory = documentsPath
        
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    public func activate() async throws {
        try await createDirectoryStructure()
    }
    
    public func deactivate() async {
    }
    
    public var isAvailable: Bool {
        return fileManager.fileExists(atPath: documentsDirectory.path)
    }
    
    private func createDirectoryStructure() async throws {
        let subdirectories = [
            "tasks",
            "contacts",
            "calendar",
            "reminders",
            "health",
            "location",
            "documents",
            "photos",
            "audio",
            "models",
            "cache"
        ]
        
        for subdirectory in subdirectories {
            let url = documentsDirectory.appendingPathComponent(subdirectory)
            if !fileManager.fileExists(atPath: url.path) {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            }
        }
    }
    
    public func save<T: Codable>(_ object: T, to path: String) async throws {
        let url = documentsDirectory.appendingPathComponent(path)
        let data = try encoder.encode(object)
        try data.write(to: url)
    }
    
    public func load<T: Codable>(_ type: T.Type, from path: String) async throws -> T {
        let url = documentsDirectory.appendingPathComponent(path)
        let data = try Data(contentsOf: url)
        return try decoder.decode(type, from: data)
    }
    
    public func delete(at path: String) async throws {
        let url = documentsDirectory.appendingPathComponent(path)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
    
    public func exists(at path: String) async -> Bool {
        let url = documentsDirectory.appendingPathComponent(path)
        return fileManager.fileExists(atPath: url.path)
    }
    
    public func saveArray<T: Codable>(_ objects: [T], to path: String) async throws {
        try await save(objects, to: path)
    }
    
    public func loadArray<T: Codable>(_ type: T.Type, from path: String) async throws -> [T] {
        return try await load([T].self, from: path)
    }
    
    public func appendToArray<T: Codable>(_ object: T, at path: String, type: T.Type) async throws {
        var array: [T] = []
        if await exists(at: path) {
            array = try await loadArray(type, from: path)
        }
        array.append(object)
        try await saveArray(array, to: path)
    }
    
    public func removeFromArray<T: Codable & Identifiable>(withId id: T.ID, at path: String, type: T.Type) async throws where T.ID: Equatable {
        var array = try await loadArray(type, from: path)
        array.removeAll { $0.id == id }
        try await saveArray(array, to: path)
    }
    
    public func updateInArray<T: Codable & Identifiable>(_ object: T, at path: String, type: T.Type) async throws where T.ID: Equatable {
        var array = try await loadArray(type, from: path)
        if let index = array.firstIndex(where: { $0.id == object.id }) {
            array[index] = object
            try await saveArray(array, to: path)
        } else {
            throw LocalFileStorageError.objectNotFound
        }
    }
    
    public func listFiles(in directory: String = "") async throws -> [String] {
        let url = directory.isEmpty ? documentsDirectory : documentsDirectory.appendingPathComponent(directory)
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        return contents.map { $0.lastPathComponent }
    }
    
    public func fileSize(at path: String) async throws -> Int64 {
        let url = documentsDirectory.appendingPathComponent(path)
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }
    
    public func creationDate(at path: String) async throws -> Date {
        let url = documentsDirectory.appendingPathComponent(path)
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        return attributes[.creationDate] as? Date ?? Date()
    }
    
    public func modificationDate(at path: String) async throws -> Date {
        let url = documentsDirectory.appendingPathComponent(path)
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        return attributes[.modificationDate] as? Date ?? Date()
    }
}

public enum LocalFileStorageError: Error, LocalizedError {
    case documentsDirectoryNotFound
    case fileNotFound(String)
    case objectNotFound
    case encodingFailed
    case decodingFailed
    case writePermissionDenied
    case diskSpaceInsufficient
    
    public var errorDescription: String? {
        switch self {
        case .documentsDirectoryNotFound:
            return "Documents directory not found"
        case .fileNotFound(let path):
            return "File not found at path: \(path)"
        case .objectNotFound:
            return "Object not found in array"
        case .encodingFailed:
            return "Failed to encode object"
        case .decodingFailed:
            return "Failed to decode object"
        case .writePermissionDenied:
            return "Write permission denied"
        case .diskSpaceInsufficient:
            return "Insufficient disk space"
        }
    }
}