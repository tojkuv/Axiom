import Foundation
import Axiom

// MARK: - Task Storage Capability Protocol

/// Capability for offline task storage and persistence
public protocol TaskStorageCapability: Capability {
    /// Load all tasks from storage
    func loadTasks() async throws -> [Task]
    
    /// Save tasks to storage
    func saveTasks(_ tasks: [Task]) async throws
    
    /// Export tasks to external format
    func exportTasks(_ tasks: [Task]) async throws
    
    /// Import tasks from external format
    func importTasks(from data: Data) async throws -> [Task]
    
    /// Delete all tasks from storage
    func clearStorage() async throws
    
    /// Get storage statistics
    func getStorageInfo() async throws -> StorageInfo
}

// MARK: - Storage Information

/// Information about storage usage and status
public struct StorageInfo: Sendable, Equatable, Codable {
    public let totalTasks: Int
    public let storageSize: Int
    public let lastModified: Date?
    public let isAvailable: Bool
    public let storageLocation: String
    
    public init(
        totalTasks: Int,
        storageSize: Int,
        lastModified: Date?,
        isAvailable: Bool,
        storageLocation: String
    ) {
        self.totalTasks = totalTasks
        self.storageSize = storageSize
        self.lastModified = lastModified
        self.isAvailable = isAvailable
        self.storageLocation = storageLocation
    }
}

// MARK: - Local File Storage Implementation

/// Local file-based storage implementation for tasks
public actor LocalTaskStorageCapability: TaskStorageCapability {
    
    // MARK: - Properties
    private let fileManager = FileManager.default
    private let storageDirectory: URL
    private let tasksFileName = "tasks.json"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var _state: CapabilityState = .unknown
    private var stateStreamContinuation: AsyncStream<CapabilityState>.Continuation?
    
    // MARK: - Initialization
    
    public init(storageDirectory: URL? = nil) throws {
        // Use Documents directory by default
        if let customDirectory = storageDirectory {
            self.storageDirectory = customDirectory
        } else {
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw AxiomError.capabilityError(.initializationFailed("Could not access Documents directory"))
            }
            self.storageDirectory = documentsDirectory.appendingPathComponent("TaskManager")
        }
        
        // Configure JSON encoder/decoder
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        
        // Storage directory will be created when needed
    }
    
    // MARK: - Capability Protocol Implementation
    
    public var isAvailable: Bool {
        get async {
            return _state == .available
        }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
        AsyncStream { continuation in
            self.stateStreamContinuation = continuation
            continuation.yield(self._state)
            
            continuation.onTermination = { _ in
                _Concurrency.Task { [weak self] in
                    await self?.setStreamContinuation(nil)
                }
            }
        }
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<CapabilityState>.Continuation?) {
        self.stateStreamContinuation = continuation
    }
    
    public func activate() async throws {
        guard _state != .available else { return }
        
        await transitionTo(.unknown)
        
        do {
            // Ensure storage directory exists
            try await ensureStorageDirectoryExists()
            
            // Test read/write access
            try await testStorageAccess()
            
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw AxiomError.capabilityError(.initializationFailed("Storage activation failed: \(error)"))
        }
    }
    
    public func deactivate() async {
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
        stateStreamContinuation = nil
    }
    
    private func transitionTo(_ newState: CapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
    
    // MARK: - Task Storage Implementation
    
    public func loadTasks() async throws -> [Task] {
        guard await isAvailable else {
            throw AxiomError.capabilityError(.notAvailable("Storage not available"))
        }
        
        let tasksFileURL = storageDirectory.appendingPathComponent(tasksFileName)
        
        // Check if file exists
        guard fileManager.fileExists(atPath: tasksFileURL.path) else {
            // Return empty array if file doesn't exist
            return []
        }
        
        do {
            let data = try Data(contentsOf: tasksFileURL)
            let tasks = try decoder.decode([Task].self, from: data)
            return tasks
        } catch {
            throw AxiomError.persistenceError(.loadFailed("Failed to load tasks: \(error)"))
        }
    }
    
    public func saveTasks(_ tasks: [Task]) async throws {
        guard await isAvailable else {
            throw AxiomError.capabilityError(.notAvailable("Storage not available"))
        }
        
        let tasksFileURL = storageDirectory.appendingPathComponent(tasksFileName)
        
        do {
            let data = try encoder.encode(tasks)
            try data.write(to: tasksFileURL, options: .atomic)
        } catch {
            throw AxiomError.persistenceError(.saveFailed("Failed to save tasks: \(error)"))
        }
    }
    
    public func exportTasks(_ tasks: [Task]) async throws {
        guard await isAvailable else {
            throw AxiomError.capabilityError(.notAvailable("Storage not available"))
        }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let exportFileName = "tasks_export_\(timestamp).json"
        let exportFileURL = storageDirectory.appendingPathComponent("Exports").appendingPathComponent(exportFileName)
        
        // Ensure exports directory exists
        try fileManager.createDirectory(
            at: exportFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        do {
            let exportData = TaskExportData(
                exportDate: Date(),
                version: "1.0",
                tasks: tasks
            )
            
            let data = try encoder.encode(exportData)
            try data.write(to: exportFileURL, options: .atomic)
        } catch {
            throw AxiomError.persistenceError(.saveFailed("Failed to export tasks: \(error)"))
        }
    }
    
    public func importTasks(from data: Data) async throws -> [Task] {
        guard await isAvailable else {
            throw AxiomError.capabilityError(.notAvailable("Storage not available"))
        }
        
        do {
            // Try to decode as export format first
            if let exportData = try? decoder.decode(TaskExportData.self, from: data) {
                return exportData.tasks
            }
            
            // Fallback to direct task array format
            let tasks = try decoder.decode([Task].self, from: data)
            return tasks
        } catch {
            throw AxiomError.persistenceError(.loadFailed("Failed to import tasks: \(error)"))
        }
    }
    
    public func clearStorage() async throws {
        guard await isAvailable else {
            throw AxiomError.capabilityError(.notAvailable("Storage not available"))
        }
        
        let tasksFileURL = storageDirectory.appendingPathComponent(tasksFileName)
        
        do {
            if fileManager.fileExists(atPath: tasksFileURL.path) {
                try fileManager.removeItem(at: tasksFileURL)
            }
        } catch {
            throw AxiomError.persistenceError(.deleteFailed("Failed to clear storage: \(error)"))
        }
    }
    
    public func getStorageInfo() async throws -> StorageInfo {
        guard await isAvailable else {
            throw AxiomError.capabilityError(.notAvailable("Storage not available"))
        }
        
        let tasksFileURL = storageDirectory.appendingPathComponent(tasksFileName)
        
        var totalTasks = 0
        var storageSize = 0
        var lastModified: Date?
        
        if fileManager.fileExists(atPath: tasksFileURL.path) {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: tasksFileURL.path)
                storageSize = (attributes[.size] as? Int) ?? 0
                lastModified = attributes[.modificationDate] as? Date
                
                // Count tasks
                let data = try Data(contentsOf: tasksFileURL)
                let tasks = try decoder.decode([Task].self, from: data)
                totalTasks = tasks.count
            } catch {
                // If we can't read the file, assume it's corrupted or empty
                totalTasks = 0
                storageSize = 0
                lastModified = nil
            }
        }
        
        return StorageInfo(
            totalTasks: totalTasks,
            storageSize: storageSize,
            lastModified: lastModified,
            isAvailable: await isAvailable,
            storageLocation: storageDirectory.path
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func ensureStorageDirectoryExists() async throws {
        let directoryExists = fileManager.fileExists(atPath: storageDirectory.path)
        
        if !directoryExists {
            do {
                try fileManager.createDirectory(
                    at: storageDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw AxiomError.capabilityError(.resourceAllocationFailed("Could not create storage directory: \(error)"))
            }
        }
    }
    
    private func testStorageAccess() async throws {
        let testFileURL = storageDirectory.appendingPathComponent("test.tmp")
        let testData = "test".data(using: .utf8)!
        
        do {
            // Test write
            try testData.write(to: testFileURL)
            
            // Test read
            let readData = try Data(contentsOf: testFileURL)
            guard readData == testData else {
                throw AxiomError.capabilityError(.resourceUnavailable("Storage read/write test failed"))
            }
            
            // Clean up test file
            try fileManager.removeItem(at: testFileURL)
        } catch {
            throw AxiomError.capabilityError(.resourceUnavailable("Storage access test failed: \(error)"))
        }
    }
}

// MARK: - Export Data Format

/// Data structure for task exports
private struct TaskExportData: Codable {
    let exportDate: Date
    let version: String
    let tasks: [Task]
}

// MARK: - In-Memory Storage Implementation (for testing)

/// In-memory storage implementation for testing purposes
public actor InMemoryTaskStorageCapability: TaskStorageCapability {
    
    private var tasks: [Task] = []
    private var _state: CapabilityState = .unknown
    private var stateStreamContinuation: AsyncStream<CapabilityState>.Continuation?
    
    public init() {}
    
    // MARK: - Capability Protocol Implementation
    
    public var isAvailable: Bool {
        get async {
            return _state == .available
        }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
        AsyncStream { continuation in
            self.stateStreamContinuation = continuation
            continuation.yield(self._state)
            
            continuation.onTermination = { _ in
                _Concurrency.Task { [weak self] in
                    await self?.setStreamContinuation(nil)
                }
            }
        }
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<CapabilityState>.Continuation?) {
        self.stateStreamContinuation = continuation
    }
    
    public func activate() async throws {
        await transitionTo(.available)
    }
    
    public func deactivate() async {
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
        stateStreamContinuation = nil
    }
    
    private func transitionTo(_ newState: CapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
    
    // MARK: - Task Storage Implementation
    
    public func loadTasks() async throws -> [Task] {
        guard await isAvailable else {
            throw AxiomError.capabilityError(.notAvailable("Storage not available"))
        }
        return tasks
    }
    
    public func saveTasks(_ tasks: [Task]) async throws {
        guard await isAvailable else {
            throw AxiomError.capabilityError(.notAvailable("Storage not available"))
        }
        self.tasks = tasks
    }
    
    public func exportTasks(_ tasks: [Task]) async throws {
        guard await isAvailable else {
            throw AxiomError.capabilityError(.notAvailable("Storage not available"))
        }
        // In-memory implementation doesn't actually export to external format
        self.tasks = tasks
    }
    
    public func importTasks(from data: Data) async throws -> [Task] {
        guard await isAvailable else {
            throw AxiomError.capabilityError(.notAvailable("Storage not available"))
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode([Task].self, from: data)
        } catch {
            throw AxiomError.persistenceError(.loadFailed("Failed to import tasks: \(error)"))
        }
    }
    
    public func clearStorage() async throws {
        guard await isAvailable else {
            throw AxiomError.capabilityError(.notAvailable("Storage not available"))
        }
        tasks.removeAll()
    }
    
    public func getStorageInfo() async throws -> StorageInfo {
        guard await isAvailable else {
            throw AxiomError.capabilityError(.notAvailable("Storage not available"))
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(tasks)
        
        return StorageInfo(
            totalTasks: tasks.count,
            storageSize: data.count,
            lastModified: Date(),
            isAvailable: await isAvailable,
            storageLocation: "In-Memory"
        )
    }
}