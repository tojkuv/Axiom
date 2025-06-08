import Foundation

// MARK: - Task Cache Manager

actor TaskCacheManager {
    private let storage: StorageProtocol
    private let clock: ClockProtocol
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    private var cachedTasks: [TaskItem]?
    private var cacheTimestamp: TimeInterval?
    private var isInvalidated = false
    
    init(storage: StorageProtocol, clock: ClockProtocol = SystemClock()) {
        self.storage = storage
        self.clock = clock
    }
    
    // MARK: - Cache Operations
    
    func getTasks() async throws -> [TaskItem] {
        if let cached = cachedTasks, 
           let timestamp = cacheTimestamp,
           !isInvalidated,
           clock.now() - timestamp < cacheTimeout {
            // Cache hit
            return cached
        }
        
        // Cache miss or expired
        let tasks = try await storage.load()
        cachedTasks = tasks
        cacheTimestamp = clock.now()
        isInvalidated = false
        return tasks
    }
    
    func setCachedTasks(_ tasks: [TaskItem]) async {
        cachedTasks = tasks
        cacheTimestamp = clock.now()
        isInvalidated = false
    }
    
    func isCacheInvalid() async -> Bool {
        return isInvalidated
    }
    
    func isCacheExpired() async -> Bool {
        guard let timestamp = cacheTimestamp else { return true }
        return clock.now() - timestamp >= cacheTimeout
    }
    
    // MARK: - Mutating Operations
    
    func addTask(_ task: TaskItem) async throws {
        invalidateCache()
        try await storage.save(task)
    }
    
    func updateTask(_ task: TaskItem) async throws {
        invalidateCache()
        try await storage.save(task)
    }
    
    func deleteTask(_ task: TaskItem) async throws {
        invalidateCache()
        var tasks = try await storage.load()
        tasks.removeAll { $0.id == task.id }
        try await storage.save(tasks)
    }
    
    // MARK: - Private Methods
    
    private func invalidateCache() {
        isInvalidated = true
        cachedTasks = nil
        cacheTimestamp = nil
    }
}

// MARK: - System Clock

struct SystemClock: ClockProtocol {
    func now() -> TimeInterval {
        return Date().timeIntervalSince1970
    }
}