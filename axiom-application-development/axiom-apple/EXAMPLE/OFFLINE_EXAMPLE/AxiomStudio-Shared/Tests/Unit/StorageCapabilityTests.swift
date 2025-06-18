import XCTest
@testable import AxiomStudio_Shared

final class StorageCapabilityTests: XCTestCase {
    
    var mockStorage: MockStorageCapability!
    
    override func setUp() async throws {
        try await super.setUp()
        mockStorage = MockStorageCapability()
    }
    
    override func tearDown() async throws {
        try await mockStorage?.deactivate()
        mockStorage = nil
        try await super.tearDown()
    }
    
    func testMockStorageCapabilityActivation() async throws {
        try await TestScenarios.runCapabilityActivationTest(
            capability: mockStorage,
            expectedActivation: true
        )
    }
    
    func testMockStorageCapabilityFailedActivation() async throws {
        await mockStorage.setFailureMode(activate: true)
        
        try await TestScenarios.runCapabilityActivationTest(
            capability: mockStorage,
            expectedActivation: false
        )
    }
    
    func testBasicStorageOperations() async throws {
        let fixedDate = Date(timeIntervalSince1970: 1608542400) // Fixed date: 2020-12-21 12:00:00 UTC
        let testTask = TestDataFactory.createTestTask(
            title: "Storage Test Task",
            createdAt: fixedDate,
            updatedAt: fixedDate
        )
        
        try await TestScenarios.runStorageCapabilityTest(
            storageCapability: mockStorage,
            testObject: testTask,
            path: "test-task.json"
        )
    }
    
    func testArrayStorageOperations() async throws {
        try await mockStorage.activate()
        
        let fixedDate = Date(timeIntervalSince1970: 1608542400) // Fixed date: 2020-12-21 12:00:00 UTC
        let testTasks = [
            TestDataFactory.createTestTask(
                title: "Test Task 1",
                priority: .low,
                category: .general,
                createdAt: fixedDate,
                updatedAt: fixedDate
            ),
            TestDataFactory.createTestTask(
                title: "Test Task 2", 
                priority: .medium,
                category: .work,
                createdAt: fixedDate,
                updatedAt: fixedDate
            ),
            TestDataFactory.createTestTask(
                title: "Test Task 3",
                priority: .high,
                category: .personal,
                createdAt: fixedDate,
                updatedAt: fixedDate
            )
        ]
        let path = "test-tasks.json"
        
        try await mockStorage.saveArray(testTasks, to: path)
        
        let exists = await mockStorage.exists(at: path)
        XCTAssertTrue(exists, "Array file should exist after saving")
        
        let loadedTasks = try await mockStorage.loadArray(StudioTask.self, from: path)
        XCTAssertEqual(loadedTasks.count, testTasks.count)
        XCTAssertEqual(loadedTasks, testTasks)
    }
    
    func testStorageWithDifferentDataTypes() async throws {
        try await mockStorage.activate()
        
        let fixedDate = Date(timeIntervalSince1970: 1608542400) // Fixed date: 2020-12-21 12:00:00 UTC
        let testContact = TestDataFactory.createTestContact()
        let testEvent = TestDataFactory.createTestCalendarEvent(
            startDate: fixedDate,
            endDate: fixedDate.addingTimeInterval(3600)
        )
        let testMetric = TestDataFactory.createTestHealthMetric(date: fixedDate)
        
        try await mockStorage.save(testContact, to: "contact.json")
        try await mockStorage.save(testEvent, to: "event.json")
        try await mockStorage.save(testMetric, to: "metric.json")
        
        let loadedContact = try await mockStorage.load(Contact.self, from: "contact.json")
        let loadedEvent = try await mockStorage.load(CalendarEvent.self, from: "event.json")
        let loadedMetric = try await mockStorage.load(HealthMetric.self, from: "metric.json")
        
        XCTAssertEqual(loadedContact, testContact)
        XCTAssertEqual(loadedEvent, testEvent)
        XCTAssertEqual(loadedMetric, testMetric)
    }
    
    func testStorageOperationDelays() async throws {
        await mockStorage.setDelays(operation: 0.1)
        try await mockStorage.activate()
        
        let testTask = TestDataFactory.createTestTask()
        let path = "delayed-task.json"
        
        let durations = try await TestScenarios.runPerformanceTest(
            operation: {
                try await mockStorage.save(testTask, to: path)
            },
            expectedMaxDuration: 0.2
        )
        
        XCTAssertGreaterThanOrEqual(durations.first ?? 0, 0.1, "Operation should respect the configured delay")
    }
    
    func testStorageFailureScenarios() async throws {
        try await mockStorage.activate()
        
        await mockStorage.setFailureMode(save: true)
        
        let testTask = TestDataFactory.createTestTask()
        
        do {
            try await mockStorage.save(testTask, to: "failing-task.json")
            XCTFail("Save operation should have failed")
        } catch MockStorageError.saveFailed {
            // Expected failure
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testStorageLoadFailureScenarios() async throws {
        try await mockStorage.activate()
        
        let testTask = TestDataFactory.createTestTask()
        try await mockStorage.save(testTask, to: "test-task.json")
        
        await mockStorage.setFailureMode(load: true)
        
        do {
            _ = try await mockStorage.load(StudioTask.self, from: "test-task.json")
            XCTFail("Load operation should have failed")
        } catch MockStorageError.loadFailed {
            // Expected failure
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testStorageFileNotFound() async throws {
        try await mockStorage.activate()
        
        do {
            _ = try await mockStorage.load(StudioTask.self, from: "nonexistent.json")
            XCTFail("Load operation should have failed for nonexistent file")
        } catch MockStorageError.fileNotFound(let path) {
            XCTAssertEqual(path, "nonexistent.json")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testStorageListFiles() async throws {
        try await mockStorage.activate()
        
        let task1 = TestDataFactory.createTestTask(title: "Task 1")
        let task2 = TestDataFactory.createTestTask(title: "Task 2")
        let contact = TestDataFactory.createTestContact()
        
        try await mockStorage.save(task1, to: "task1.json")
        try await mockStorage.save(task2, to: "task2.json")
        try await mockStorage.save(contact, to: "contact.json")
        
        let files = try await mockStorage.listFiles()
        XCTAssertEqual(files.count, 3)
        XCTAssertTrue(files.contains("task1.json"))
        XCTAssertTrue(files.contains("task2.json"))
        XCTAssertTrue(files.contains("contact.json"))
    }
    
    func testStorageClearOperation() async throws {
        try await mockStorage.activate()
        
        let testTasks = TestDataFactory.createTestTasks(count: 5)
        for (index, task) in testTasks.enumerated() {
            try await mockStorage.save(task, to: "task\(index).json")
        }
        
        let filesBeforeClear = try await mockStorage.listFiles()
        XCTAssertEqual(filesBeforeClear.count, 5)
        
        await mockStorage.clear()
        
        let filesAfterClear = try await mockStorage.listFiles()
        XCTAssertEqual(filesAfterClear.count, 0)
    }
    
    func testConcurrentStorageOperations() async throws {
        try await mockStorage.activate()
        
        let testTasks = TestDataFactory.createTestTasks(count: 10)
        
        let storage = mockStorage!
        let results = try await TestScenarios.runConcurrencyTest(
            operation: {
                let randomIndex = Int.random(in: 0..<testTasks.count)
                let task = testTasks[randomIndex]
                let path = "concurrent-task-\(randomIndex).json"
                try await storage.save(task, to: path)
                return path
            },
            concurrentCount: 5
        )
        
        XCTAssertEqual(results.count, 5)
        
        for path in results {
            let exists = await mockStorage.exists(at: path)
            XCTAssertTrue(exists, "File should exist after concurrent save: \(path)")
        }
    }
    
    func testStorageMetrics() async throws {
        try await mockStorage.activate()
        
        let initialCount = await mockStorage.getStorageCount()
        let initialPaths = await mockStorage.getStoredPaths()
        XCTAssertEqual(initialCount, 0)
        XCTAssertTrue(initialPaths.isEmpty)
        
        let testTask = TestDataFactory.createTestTask()
        try await mockStorage.save(testTask, to: "metrics-task.json")
        
        let countBefore = await mockStorage.getStorageCount()
        let pathsBefore = await mockStorage.getStoredPaths()
        XCTAssertEqual(countBefore, 1)
        XCTAssertTrue(pathsBefore.contains("metrics-task.json"))
        
        try await mockStorage.delete(at: "metrics-task.json")
        
        let countAfter = await mockStorage.getStorageCount()
        let pathsAfter = await mockStorage.getStoredPaths()
        XCTAssertEqual(countAfter, 0)
        XCTAssertFalse(pathsAfter.contains("metrics-task.json"))
    }
}