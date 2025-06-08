import Foundation

// MARK: - Task Persistence Service

actor TaskPersistenceService {
    private let storage: StorageProtocol
    
    init(storage: StorageProtocol) {
        self.storage = storage
    }
    
    func save(_ task: TaskItem) async throws {
        try await storage.save(task)
    }
    
    func save(_ tasks: [TaskItem]) async throws {
        try await storage.save(tasks)
    }
    
    func loadTasks() async throws -> [TaskItem] {
        do {
            return try await storage.load()
        } catch PersistenceError.readFailed {
            // Return empty array if no data exists
            return []
        }
    }
}

// MARK: - File Storage Implementation

actor FileStorage: StorageProtocol {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init(fileName: String = "tasks.json") {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentsPath.appendingPathComponent(fileName)
    }
    
    func save(_ tasks: [TaskItem]) async throws {
        do {
            let data = try encoder.encode(tasks)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw PersistenceError.writeFailed
        }
    }
    
    func save(_ task: TaskItem) async throws {
        var tasks = try await load()
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.append(task)
        }
        try await save(tasks)
    }
    
    func load() async throws -> [TaskItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([TaskItem].self, from: data)
        } catch {
            if (error as NSError).code == NSFileReadNoSuchFileError {
                return []
            }
            throw PersistenceError.dataCorrupted
        }
    }
    
    func clear() async throws {
        try FileManager.default.removeItem(at: fileURL)
    }
}