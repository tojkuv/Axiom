import XCTest
@testable import Axiom

final class PersistenceCapabilityTests: XCTestCase {
    
    // Test automatic state persistence
    func testAutomaticStatePersistence() async throws {
        // Given: A persistence capability
        let persistence = MockPersistenceCapability()
        
        // When: State is saved
        let testData = TestData(value: "Test Data", count: 42)
        try await persistence.save(testData, for: "test.state")
        
        // Then: State should be retrievable
        let savedCount = await persistence.saveCount
        XCTAssertEqual(savedCount, 1)
        
        let savedData = try await persistence.load(TestData.self, for: "test.state")
        XCTAssertEqual(savedData?.value, "Test Data")
        XCTAssertEqual(savedData?.count, 42)
    }
    
    // Test delete functionality
    func testDeletePersistedData() async throws {
        // Given: Saved data
        let persistence = MockPersistenceCapability()
        let testData = TestData(value: "Delete Me", count: 99)
        try await persistence.save(testData, for: "test.delete")
        
        // When: Data is deleted
        try await persistence.delete(key: "test.delete")
        
        // Then: Data should not be retrievable
        let deletedData = try await persistence.load(TestData.self, for: "test.delete")
        XCTAssertNil(deletedData)
    }
    
    // Test multiple keys
    func testMultipleKeyPersistence() async throws {
        let persistence = MockPersistenceCapability()
        
        // Save different data to different keys
        let data1 = TestData(value: "First", count: 1)
        let data2 = TestData(value: "Second", count: 2)
        
        try await persistence.save(data1, for: "key1")
        try await persistence.save(data2, for: "key2")
        
        // Verify both are retrievable
        let loaded1 = try await persistence.load(TestData.self, for: "key1")
        let loaded2 = try await persistence.load(TestData.self, for: "key2")
        
        XCTAssertEqual(loaded1?.value, "First")
        XCTAssertEqual(loaded2?.value, "Second")
    }
    
    // Test capability lifecycle
    func testCapabilityLifecycle() async throws {
        let persistence = MockPersistenceCapability()
        
        // Initialize
        try await persistence.initialize()
        let isAvailable = await persistence.isAvailable
        XCTAssertTrue(isAvailable)
        
        // Save some data
        try await persistence.save(TestData(value: "Test", count: 1), for: "lifecycle")
        
        // Terminate
        await persistence.terminate()
        
        // After termination, storage should be cleared
        let afterTerminate = try await persistence.load(TestData.self, for: "lifecycle")
        XCTAssertNil(afterTerminate)
    }
    
    // Test cross-launch persistence with file storage
    func testCrossLaunchPersistence() async throws {
        // Create a temporary directory for testing
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("axiom-test-\(UUID().uuidString)")
        
        // First "launch" - save data
        let storage1 = FileStorageAdapter(directory: tempDir)
        let persistence1 = AdapterBasedPersistence(adapter: storage1)
        
        let testData = TestData(value: "Persisted", count: 123)
        try await persistence1.save(testData, for: "app.state")
        
        // Simulate app termination
        await persistence1.terminate()
        
        // Second "launch" - load data
        let storage2 = FileStorageAdapter(directory: tempDir)
        let persistence2 = AdapterBasedPersistence(adapter: storage2)
        try await persistence2.initialize()
        
        let loadedData = try await persistence2.load(TestData.self, for: "app.state")
        XCTAssertNotNil(loadedData)
        XCTAssertEqual(loadedData?.value, "Persisted")
        XCTAssertEqual(loadedData?.count, 123)
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    // Test selective persistence with client integration
    func testSelectivePersistenceWithClient() async throws {
        // Given: A client with persistence capability
        let persistence = MockPersistenceCapability()
        let client = MockPersistableClient(persistence: persistence)
        
        // When: Client updates its state
        try await client.updateValue("Important Data")
        try await client.incrementCounter() // This should trigger persistence
        
        // Then: State should be persisted
        let savedCount = await persistence.saveCount
        XCTAssertEqual(savedCount, 1) // Only saved once after counter increment
        
        let savedState = try await persistence.load(TestClientState.self, for: "client.state")
        XCTAssertEqual(savedState?.value, "Important Data")
        XCTAssertEqual(savedState?.counter, 1)
    }
    
    // Test data structure
    struct TestData: Codable, Equatable {
        let value: String
        let count: Int
    }
    
    // Test client state
    struct TestClientState: State, Codable, Equatable {
        var value: String
        var counter: Int
    }
    
    // Mock persistable client
    actor MockPersistableClient: Client, Persistable {
        typealias StateType = TestClientState
        typealias ActionType = TestClientAction
        
        static let persistedKeys: [String] = ["client.state"]
        let persistence: PersistenceCapability
        
        private(set) var state: TestClientState {
            didSet {
                continuation?.yield(state)
            }
        }
        
        var stateStream: AsyncStream<TestClientState> {
            AsyncStream { continuation in
                self.continuation = continuation
                continuation.yield(state)
            }
        }
        
        private var continuation: AsyncStream<TestClientState>.Continuation?
        
        nonisolated var id: String { "mock-client" }
        
        init(persistence: PersistenceCapability) {
            self.persistence = persistence
            self.state = TestClientState(value: "", counter: 0)
        }
        
        func updateValue(_ newValue: String) async throws {
            state.value = newValue
            // Don't persist on value update
        }
        
        func incrementCounter() async throws {
            state.counter += 1
            // Persist after counter increment
            try await persistState()
        }
        
        func process(_ action: TestClientAction) async throws {
            switch action {
            case .setValue(let value):
                try await updateValue(value)
            case .increment:
                try await incrementCounter()
            }
        }
        
        func persistState() async throws {
            try await persistence.save(state, for: Self.persistedKeys.first!)
        }
        
        enum TestClientAction {
            case setValue(String)
            case increment
        }
    }
}