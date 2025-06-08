import Foundation

// MARK: - Task Migration Service

actor TaskMigrationService {
    private let storage: VersionedStorageProtocol
    private let currentVersion = 2
    
    init(storage: VersionedStorageProtocol) {
        self.storage = storage
    }
    
    func getCurrentVersion() async throws -> Int {
        do {
            return try await storage.getVersion()
        } catch {
            // No version means v1
            return 1
        }
    }
    
    func migrateIfNeeded() async throws {
        let version = try await getCurrentVersion()
        
        if version < currentVersion {
            try await performMigration(from: version, to: currentVersion)
        }
    }
    
    private func performMigration(from oldVersion: Int, to newVersion: Int) async throws {
        switch (oldVersion, newVersion) {
        case (1, 2):
            try await migrateV1ToV2()
        default:
            throw PersistenceError.migrationFailed
        }
    }
    
    private func migrateV1ToV2() async throws {
        do {
            // Load v1 tasks
            let v1Tasks = try await storage.loadV1Tasks()
            
            // Convert to v2 format
            let v2Tasks = v1Tasks.map { v1Task in
                TaskItem(
                    id: v1Task.id,
                    title: v1Task.title,
                    description: "", // Default value for new field
                    categoryId: nil, // No category initially
                    priority: .medium, // Default priority
                    isCompleted: v1Task.isCompleted,
                    createdAt: Date(),
                    updatedAt: Date(),
                    dueDate: nil
                )
            }
            
            // Save in v2 format
            try await storage.saveV2Tasks(v2Tasks)
            
            // Update version
            try await storage.setVersion(2)
        } catch {
            // Rollback on failure
            throw PersistenceError.migrationFailed
        }
    }
}

// MARK: - Versioned File Storage

actor VersionedFileStorage: VersionedStorageProtocol {
    private let documentsPath: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init() {
        self.documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    // MARK: - Version Management
    
    func getVersion() async throws -> Int {
        let versionURL = documentsPath.appendingPathComponent("version.txt")
        guard let data = try? Data(contentsOf: versionURL),
              let versionString = String(data: data, encoding: .utf8),
              let version = Int(versionString) else {
            return 1 // Default to v1 if no version file
        }
        return version
    }
    
    func setVersion(_ version: Int) async throws {
        let versionURL = documentsPath.appendingPathComponent("version.txt")
        let data = "\(version)".data(using: .utf8)!
        try data.write(to: versionURL, options: .atomic)
    }
    
    // MARK: - V1 Support
    
    func loadV1Tasks() async throws -> [TaskV1] {
        let v1URL = documentsPath.appendingPathComponent("tasks_v1.json")
        guard let data = try? Data(contentsOf: v1URL) else {
            return []
        }
        return try decoder.decode([TaskV1].self, from: data)
    }
    
    // MARK: - V2 Support
    
    func saveV2Tasks(_ tasks: [TaskItem]) async throws {
        let v2URL = documentsPath.appendingPathComponent("tasks.json")
        let data = try encoder.encode(tasks)
        try data.write(to: v2URL, options: .atomic)
    }
    
    func loadV2Tasks() async throws -> [TaskItem] {
        let v2URL = documentsPath.appendingPathComponent("tasks.json")
        guard let data = try? Data(contentsOf: v2URL) else {
            return []
        }
        return try decoder.decode([TaskItem].self, from: data)
    }
    
    // MARK: - StorageProtocol
    
    func save(_ tasks: [TaskItem]) async throws {
        try await saveV2Tasks(tasks)
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
        return try await loadV2Tasks()
    }
    
    func clear() async throws {
        let v2URL = documentsPath.appendingPathComponent("tasks.json")
        try FileManager.default.removeItem(at: v2URL)
    }
}