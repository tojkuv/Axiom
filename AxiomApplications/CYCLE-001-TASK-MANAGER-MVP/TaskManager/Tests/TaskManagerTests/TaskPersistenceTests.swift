import XCTest
@testable import TaskManager

class TaskPersistenceTests: XCTestCase {
    var sut: TaskPersistenceService!
    var mockStorage: MockStorage!
    
    override func setUp() {
        super.setUp()
        mockStorage = MockStorage()
        sut = TaskPersistenceService(storage: mockStorage)
    }
    
    override func tearDown() {
        sut = nil
        mockStorage = nil
        super.tearDown()
    }
    
    // MARK: - Save Operations
    
    func testSaveSingleTaskItem() async throws {
        // Given
        let task = TaskItem(
            id: UUID(),
            title: "Test Task",
            description: "Test Description",
            categoryId: nil,
            priority: .medium,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date(),
            dueDate: Date().addingTimeInterval(86400)
        )
        
        // When
        try await sut.save(task)
        
        // Then
        XCTAssertEqual(mockStorage.savedTasks.count, 1)
        XCTAssertEqual(mockStorage.savedTasks.first?.id, task.id)
        XCTAssertEqual(mockStorage.savedTasks.first?.title, task.title)
    }
    
    func testSaveMultipleTasks() async throws {
        // Given
        let tasks = [
            TaskItem(id: UUID(), title: "Task 1", description: "", priority: .high, isCompleted: false),
            TaskItem(id: UUID(), title: "Task 2", description: "", priority: .low, isCompleted: true),
            TaskItem(id: UUID(), title: "Task 3", description: "", priority: .medium, isCompleted: false)
        ]
        
        // When
        try await sut.save(tasks)
        
        // Then
        XCTAssertEqual(mockStorage.savedTasks.count, 3)
        XCTAssertEqual(Set(mockStorage.savedTasks.map { $0.id }), Set(tasks.map { $0.id }))
    }
    
    func testSaveEmptyTaskList() async throws {
        // Given
        let tasks: [TaskItem] = []
        
        // When
        try await sut.save(tasks)
        
        // Then
        XCTAssertEqual(mockStorage.savedTasks.count, 0)
    }
    
    // MARK: - Load Operations
    
    func testLoadTasks() async throws {
        // Given
        let tasks = [
            TaskItem(id: UUID(), title: "Task 1", description: "", priority: .high, isCompleted: false),
            TaskItem(id: UUID(), title: "Task 2", description: "", priority: .low, isCompleted: true)
        ]
        mockStorage.tasksToReturn = tasks
        
        // When
        let loadedTasks = try await sut.loadTasks()
        
        // Then
        XCTAssertEqual(loadedTasks.count, 2)
        XCTAssertEqual(Set(loadedTasks.map { $0.id }), Set(tasks.map { $0.id }))
    }
    
    func testLoadEmptyTaskList() async throws {
        // Given
        mockStorage.tasksToReturn = []
        
        // When
        let loadedTasks = try await sut.loadTasks()
        
        // Then
        XCTAssertEqual(loadedTasks.count, 0)
    }
    
    func testLoadTasksWhenNoDataExists() async throws {
        // Given
        mockStorage.shouldThrowError = .noData
        
        // When
        let loadedTasks = try await sut.loadTasks()
        
        // Then
        XCTAssertEqual(loadedTasks.count, 0)
    }
    
    // MARK: - Data Integrity
    
    func testDataIntegrityAfterSaveAndLoad() async throws {
        // Given
        let originalTask = TaskItem(
            id: UUID(),
            title: "Data Integrity Test",
            description: "Testing all fields persist correctly",
            priority: .high,
            isCompleted: true,
            dueDate: Date().addingTimeInterval(172800)
        )
        
        // When
        try await sut.save(originalTask)
        mockStorage.tasksToReturn = mockStorage.savedTasks
        let loadedTasks = try await sut.loadTasks()
        
        // Then
        XCTAssertEqual(loadedTasks.count, 1)
        let loadedTask = loadedTasks.first!
        XCTAssertEqual(loadedTask.id, originalTask.id)
        XCTAssertEqual(loadedTask.title, originalTask.title)
        XCTAssertEqual(loadedTask.description, originalTask.description)
        XCTAssertEqual(loadedTask.isCompleted, originalTask.isCompleted)
        XCTAssertEqual(loadedTask.priority, originalTask.priority)
        XCTAssertEqual(loadedTask.categoryId, originalTask.categoryId)
        XCTAssertEqual(loadedTask.dueDate?.timeIntervalSince1970, originalTask.dueDate?.timeIntervalSince1970)
        XCTAssertEqual(loadedTask.createdAt.timeIntervalSince1970, originalTask.createdAt.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(loadedTask.updatedAt.timeIntervalSince1970, originalTask.updatedAt.timeIntervalSince1970, accuracy: 1.0)
    }
    
    // MARK: - Error Handling
    
    func testSaveHandlesStorageError() async throws {
        // Given
        let task = TaskItem(id: UUID(), title: "Test", description: "")
        mockStorage.shouldThrowError = .writeError
        
        // When/Then
        do {
            try await sut.save(task)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? PersistenceError, .writeFailed)
        }
    }
    
    func testLoadHandlesCorruptedData() async throws {
        // Given
        mockStorage.shouldThrowError = .corruptedData
        
        // When/Then
        do {
            _ = try await sut.loadTasks()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? PersistenceError, .dataCorrupted)
        }
    }
    
    // MARK: - Performance Tests
    
    func testSavePerformanceWith1000Tasks() async throws {
        // Given
        let tasks = (0..<1000).map { index in
            TaskItem(
                id: UUID(),
                title: "Task \(index)",
                description: "Description \(index)",
                priority: Priority.allCases[index % Priority.allCases.count],
                isCompleted: index % 2 == 0
            )
        }
        
        // When
        let startTime = Date()
        try await sut.save(tasks)
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertLessThan(elapsedTime, 0.1, "Save operation should complete in less than 100ms for 1000 tasks")
        XCTAssertEqual(mockStorage.savedTasks.count, 1000)
    }
    
    func testLoadPerformanceWith10000Tasks() async throws {
        // Given
        let tasks = (0..<10000).map { index in
            TaskItem(
                id: UUID(),
                title: "Task \(index)",
                description: "Description \(index)",
                isCompleted: index % 2 == 0
            )
        }
        mockStorage.tasksToReturn = tasks
        
        // When
        let startTime = Date()
        let loadedTasks = try await sut.loadTasks()
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertLessThan(elapsedTime, 0.2, "Load operation should complete in less than 200ms for 10000 tasks")
        XCTAssertEqual(loadedTasks.count, 10000)
    }
}

// MARK: - Mock Storage

class MockStorage: StorageProtocol {
    var savedTasks: [TaskItem] = []
    var tasksToReturn: [TaskItem] = []
    var shouldThrowError: MockStorageError?
    
    enum MockStorageError {
        case noData
        case writeError
        case corruptedData
    }
    
    func save(_ tasks: [TaskItem]) async throws {
        if let error = shouldThrowError {
            switch error {
            case .writeError:
                throw PersistenceError.writeFailed
            default:
                break
            }
        }
        savedTasks = tasks
    }
    
    func save(_ task: TaskItem) async throws {
        try await save([task])
    }
    
    func load() async throws -> [TaskItem] {
        if let error = shouldThrowError {
            switch error {
            case .noData:
                return []
            case .corruptedData:
                throw PersistenceError.dataCorrupted
            default:
                break
            }
        }
        return tasksToReturn
    }
    
    func clear() async throws {
        savedTasks = []
        tasksToReturn = []
    }
}

// MARK: - Persistence Error

enum PersistenceError: Error, Equatable {
    case writeFailed
    case readFailed
    case dataCorrupted
    case migrationFailed
}