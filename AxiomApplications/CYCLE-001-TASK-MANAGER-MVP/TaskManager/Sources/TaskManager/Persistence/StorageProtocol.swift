import Foundation

// MARK: - Storage Protocol

protocol StorageProtocol {
    func save(_ tasks: [TaskItem]) async throws
    func save(_ task: TaskItem) async throws
    func load() async throws -> [TaskItem]
    func clear() async throws
}

// MARK: - Versioned Storage Protocol

protocol VersionedStorageProtocol {
    func getVersion() async throws -> Int
    func setVersion(_ version: Int) async throws
    func loadV1Tasks() async throws -> [TaskV1]
    func saveV2Tasks(_ tasks: [TaskItem]) async throws
    func loadV2Tasks() async throws -> [TaskItem]
    
    // StorageProtocol methods
    func save(_ tasks: [TaskItem]) async throws
    func save(_ task: TaskItem) async throws
    func load() async throws -> [TaskItem]
    func clear() async throws
}

// MARK: - Clock Protocol

protocol ClockProtocol {
    func now() -> TimeInterval
}