import XCTest
@testable import TaskManager

class TaskCacheTests: XCTestCase {
    var sut: TaskCacheManager!
    var mockStorage: MockCacheStorage!
    var mockClock: MockClock!
    
    override func setUp() {
        super.setUp()
        mockStorage = MockCacheStorage()
        mockClock = MockClock()
        sut = TaskCacheManager(storage: mockStorage, clock: mockClock)
    }
    
    override func tearDown() {
        sut = nil
        mockStorage = nil
        mockClock = nil
        super.tearDown()
    }
    
    // MARK: - Cache Operations
    
    func testCacheHitReturnsTasksWithoutStorageCall() async throws {
        // Given
        let tasks = [
            TaskItem(id: UUID(), title: "Cached Task 1", description: ""),
            TaskItem(id: UUID(), title: "Cached Task 2", description: "", isCompleted: true)
        ]
        await sut.setCachedTasks(tasks)
        
        // When
        let cachedTasks = try await sut.getTasks()
        
        // Then
        XCTAssertEqual(cachedTasks.count, 2)
        XCTAssertEqual(mockStorage.loadCallCount, 0, "Should not call storage on cache hit")
        XCTAssertEqual(Set(cachedTasks.map { $0.id }), Set(tasks.map { $0.id }))
    }
    
    func testCacheMissLoadsFromStorage() async throws {
        // Given
        let storageTasks = [
            TaskItem(id: UUID(), title: "Storage Task", description: "", isCompleted: false)
        ]
        mockStorage.tasksToReturn = storageTasks
        
        // When
        let tasks = try await sut.getTasks()
        
        // Then
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(mockStorage.loadCallCount, 1, "Should call storage on cache miss")
        XCTAssertEqual(tasks.first?.title, "Storage Task")
    }
    
    // MARK: - Cache Invalidation
    
    func testAddTaskInvalidatesCache() async throws {
        // Given
        let cachedTasks = [
            TaskItem(id: UUID(), title: "Cached", description: "", isCompleted: false)
        ]
        await sut.setCachedTasks(cachedTasks)
        
        let newTask = TaskItem(id: UUID(), title: "New Task", description: "", isCompleted: false)
        
        // When
        try await sut.addTask(newTask)
        
        // Then
        let isInvalid = await sut.isCacheInvalid()
        XCTAssertTrue(isInvalid)
        XCTAssertEqual(mockStorage.saveCallCount, 1)
    }
    
    func testUpdateTaskInvalidatesCache() async throws {
        // Given
        let task = TaskItem(id: UUID(), title: "Original", description: "", isCompleted: false)
        await sut.setCachedTasks([task])
        
        let updatedTask = TaskItem(
            id: task.id,
            title: "Updated",
            description: task.description,
            isCompleted: true
        )
        
        // When
        try await sut.updateTask(updatedTask)
        
        // Then
        let isInvalid = await sut.isCacheInvalid()
        XCTAssertTrue(isInvalid)
        XCTAssertEqual(mockStorage.saveCallCount, 1)
    }
    
    func testDeleteTaskInvalidatesCache() async throws {
        // Given
        let task1 = TaskItem(id: UUID(), title: "Task 1", description: "", isCompleted: false)
        let task2 = TaskItem(id: UUID(), title: "Task 2", description: "", isCompleted: false)
        await sut.setCachedTasks([task1, task2])
        mockStorage.tasksToReturn = [task1, task2] // Set initial data for load operation
        
        // When
        try await sut.deleteTask(task1)
        
        // Then
        let isInvalid = await sut.isCacheInvalid()
        XCTAssertTrue(isInvalid)
        XCTAssertEqual(mockStorage.saveCallCount, 1)
        XCTAssertEqual(mockStorage.savedTasks.count, 1)
        XCTAssertEqual(mockStorage.savedTasks.first?.id, task2.id)
    }
    
    // MARK: - Cache Expiration
    
    func testCacheExpiresAfterTimeout() async throws {
        // Given
        let tasks = [
            TaskItem(id: UUID(), title: "Expiring Task", description: "", isCompleted: false)
        ]
        await sut.setCachedTasks(tasks)
        
        // When - advance time past cache expiration
        mockClock.advance(by: 301) // Cache expires after 300 seconds
        let isExpired = await sut.isCacheExpired()
        
        // Then
        XCTAssertTrue(isExpired)
    }
    
    func testExpiredCacheTriggersReload() async throws {
        // Given
        let cachedTasks = [
            TaskItem(id: UUID(), title: "Old Cached", description: "", isCompleted: false)
        ]
        await sut.setCachedTasks(cachedTasks)
        
        let newStorageTasks = [
            TaskItem(id: UUID(), title: "Fresh from Storage", description: "", isCompleted: false)
        ]
        mockStorage.tasksToReturn = newStorageTasks
        
        // When
        mockClock.advance(by: 301)
        let tasks = try await sut.getTasks()
        
        // Then
        XCTAssertEqual(mockStorage.loadCallCount, 1)
        XCTAssertEqual(tasks.first?.title, "Fresh from Storage")
    }
    
    // MARK: - Cache Consistency
    
    func testConcurrentReadsReturnSameData() async throws {
        // Given
        let tasks = [
            TaskItem(id: UUID(), title: "Concurrent Task", description: "", isCompleted: false)
        ]
        mockStorage.tasksToReturn = tasks
        
        // When - simulate concurrent reads
        async let read1 = sut.getTasks()
        async let read2 = sut.getTasks()
        async let read3 = sut.getTasks()
        
        let results = try await [read1, read2, read3]
        
        // Then
        XCTAssertEqual(mockStorage.loadCallCount, 1, "Should only load once for concurrent reads")
        for result in results {
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result.first?.title, "Concurrent Task")
        }
    }
    
    func testWriteOperationsAreSerializedProperly() async throws {
        // Given
        let initialTasks = [
            TaskItem(id: UUID(), title: "Initial", description: "", isCompleted: false)
        ]
        await sut.setCachedTasks(initialTasks)
        
        // When - simulate concurrent writes
        let task1 = TaskItem(id: UUID(), title: "Write 1", description: "", isCompleted: false)
        let task2 = TaskItem(id: UUID(), title: "Write 2", description: "", isCompleted: false)
        let task3 = TaskItem(id: UUID(), title: "Write 3", description: "", isCompleted: false)
        
        async let write1 = sut.addTask(task1)
        async let write2 = sut.addTask(task2)
        async let write3 = sut.addTask(task3)
        
        try await [write1, write2, write3]
        
        // Then
        XCTAssertEqual(mockStorage.saveCallCount, 3, "All writes should complete")
        // Note: Actual task order may vary due to concurrency
    }
    
    // MARK: - Performance Tests
    
    func testCachePerformanceWithFrequentReads() async throws {
        // Given
        let tasks = (0..<1000).map { index in
            TaskItem(id: UUID(), title: "Task \(index)", description: "", isCompleted: false)
        }
        await sut.setCachedTasks(tasks)
        
        // When - perform 100 reads
        let startTime = Date()
        for _ in 0..<100 {
            _ = try await sut.getTasks()
        }
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertLessThan(elapsedTime, 0.1, "100 cache reads should complete in less than 100ms")
        XCTAssertEqual(mockStorage.loadCallCount, 0, "Should not hit storage for cached reads")
    }
}

// MARK: - Mock Cache Storage

class MockCacheStorage: StorageProtocol {
    var savedTasks: [TaskItem] = []
    var tasksToReturn: [TaskItem] = []
    var loadCallCount = 0
    var saveCallCount = 0
    
    func save(_ tasks: [TaskItem]) async throws {
        saveCallCount += 1
        savedTasks = tasks
        tasksToReturn = tasks // Ensure load() returns the saved data
    }
    
    func save(_ task: TaskItem) async throws {
        saveCallCount += 1
        savedTasks.append(task)
        tasksToReturn = savedTasks // Ensure load() returns the saved data
    }
    
    func load() async throws -> [TaskItem] {
        loadCallCount += 1
        return tasksToReturn
    }
    
    func clear() async throws {
        savedTasks = []
        tasksToReturn = []
    }
}

// MARK: - Mock Clock

class MockClock: ClockProtocol {
    private var currentTime: TimeInterval = 0
    
    func now() -> TimeInterval {
        return currentTime
    }
    
    func advance(by seconds: TimeInterval) {
        currentTime += seconds
    }
}