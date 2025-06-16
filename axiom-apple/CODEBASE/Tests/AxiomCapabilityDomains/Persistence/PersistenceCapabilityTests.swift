import XCTest
import AxiomTesting
@testable import AxiomApple

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
        try await persistence.activate()
        let isAvailable = await persistence.isAvailable
        XCTAssertTrue(isAvailable)
        
        // Save some data
        try await persistence.save(TestData(value: "Test", count: 1), for: "lifecycle")
        
        // Terminate
        await persistence.deactivate()
        
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
        await persistence1.deactivate()
        
        // Second "launch" - load data
        let storage2 = FileStorageAdapter(directory: tempDir)
        let persistence2 = AdapterBasedPersistence(adapter: storage2)
        try await persistence2.activate()
        
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
    
    // Test persistable client for WORKER-05 CB-SESSION-003 integration tests
    actor TestPersistableClient: Client, Persistable {
        typealias StateType = TestIntegrationState
        typealias ActionType = TestAction
        
        static let persistedKeys: [String] = ["test.value", "test.count"]
        let persistence: PersistenceCapability
        
        private var currentValue: String = ""
        private var currentCount: Int = 0
        
        private(set) var state: TestIntegrationState {
            didSet {
                continuation?.yield(state)
            }
        }
        
        var stateStream: AsyncStream<TestIntegrationState> {
            AsyncStream { continuation in
                self.continuation = continuation
                continuation.yield(state)
            }
        }
        
        private var continuation: AsyncStream<TestIntegrationState>.Continuation?
        
        nonisolated var id: String { "test-persistable-client" }
        
        init() {
            self.persistence = MockPersistenceCapability()
            self.state = TestIntegrationState(value: "", count: 0)
        }
        
        func updateValue(_ value: String) async {
            currentValue = value
            state = TestIntegrationState(value: currentValue, count: currentCount)
        }
        
        func updateCount(_ count: Int) async {
            currentCount = count
            state = TestIntegrationState(value: currentValue, count: currentCount)
        }
        
        func getValue() async -> String {
            return currentValue
        }
        
        func getCount() async -> Int {
            return currentCount
        }
        
        func persistState() async throws {
            try await persistence.save(currentValue, for: "test.value")
            try await persistence.save(currentCount, for: "test.count")
        }
        
        func restoreState() async throws {
            if let value = try await persistence.load(String.self, for: "test.value") {
                currentValue = value
            }
            if let count = try await persistence.load(Int.self, for: "test.count") {
                currentCount = count
            }
            state = TestIntegrationState(value: currentValue, count: currentCount)
        }
        
        func process(_ action: TestAction) async throws {
            // Basic action processing
        }
        
        enum TestAction {
            case updateValue(String)
            case updateCount(Int)
        }
    }
    
    struct TestIntegrationState: State, Codable, Equatable {
        var value: String
        var count: Int
    }
}

// MARK: - Mock Domain Capability Implementations for Testing

public struct MockNetworkConfiguration: CapabilityConfiguration {
    public let baseURL: URL
    public let timeout: TimeInterval
    public let maxRetries: Int
    public let enableLogging: Bool
    
    public init(
        baseURL: URL,
        timeout: TimeInterval = 15.0,
        maxRetries: Int = 3,
        enableLogging: Bool = false
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.enableLogging = enableLogging
    }
    
    public var isValid: Bool {
        return timeout > 0 && maxRetries >= 0
    }
    
    public func merged(with other: MockNetworkConfiguration) -> MockNetworkConfiguration {
        return MockNetworkConfiguration(
            baseURL: other.baseURL,
            timeout: other.timeout,
            maxRetries: other.maxRetries,
            enableLogging: other.enableLogging
        )
    }
    
    public func adjusted(for environment: CapabilityEnvironment) -> MockNetworkConfiguration {
        switch environment {
        case .development:
            return MockNetworkConfiguration(
                baseURL: baseURL,
                timeout: timeout * 2,
                maxRetries: maxRetries,
                enableLogging: true
            )
        case .production:
            return MockNetworkConfiguration(
                baseURL: baseURL,
                timeout: timeout,
                maxRetries: maxRetries,
                enableLogging: false
            )
        default:
            return self
        }
    }
}

public actor MockNetworkResource: CapabilityResource {
    private var _isAvailable: Bool = true
    private var allocatedCount: Int = 0
    
    public init() {}
    
    public var currentUsage: ResourceUsage {
        get async {
            return ResourceUsage(
                memory: Int64(allocatedCount * 1_000_000),
                cpu: Double(allocatedCount * 5),
                network: Int64(allocatedCount * 10_000),
                disk: 0
            )
        }
    }
    
    public var isAvailable: Bool {
        get async { _isAvailable }
    }
    
    public func allocate() async throws {
        guard _isAvailable else {
            throw CapabilityError.resourceAllocationFailed("Resource not available")
        }
        allocatedCount += 1
    }
    
    public func release() async {
        if allocatedCount > 0 {
            allocatedCount -= 1
        }
    }
    
    public func checkAvailability() async -> Bool {
        return _isAvailable
    }
    
    public func setAvailable(_ available: Bool) async {
        _isAvailable = available
    }
}

public actor MockNetworkCapability: DomainCapability {
    public typealias ConfigurationType = MockNetworkConfiguration
    public typealias ResourceType = MockNetworkResource
    
    private var _configuration: MockNetworkConfiguration
    private var _resources: MockNetworkResource
    private var _environment: CapabilityEnvironment
    private var _state: CapabilityState = .unknown
    private var _activationTimeout: Duration = .milliseconds(10)
    
    public nonisolated var id: String { "mock-network-capability" }
    
    public var isAvailable: Bool {
        get async { await _resources.isAvailable }
    }
    
    public var state: CapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
        AsyncStream { continuation in
            continuation.yield(_state)
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: MockNetworkConfiguration {
        get async { _configuration }
    }
    
    public var resources: MockNetworkResource {
        get async { _resources }
    }
    
    public var environment: CapabilityEnvironment {
        get async { _environment }
    }
    
    public init() {
        let config = MockNetworkConfiguration(
            baseURL: URL(string: "https://test.example.com")!
        )
        self._configuration = config.adjusted(for: .development)
        self._resources = MockNetworkResource()
        self._environment = .development
    }
    
    public func activate() async throws {
        guard await _resources.checkAvailability() else {
            throw CapabilityError.initializationFailed("Mock network resources not available")
        }
        
        _state = .available
        try await _resources.allocate()
    }
    
    public func deactivate() async {
        _state = .unavailable
        await _resources.release()
    }
    
    public func shutdown() async throws {
        await deactivate()
    }
    
    public func isSupported() async -> Bool {
        return await _resources.checkAvailability()
    }
    
    public func requestPermission() async throws {
        // Mock implementation - no permission needed
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    public func updateConfiguration(_ configuration: MockNetworkConfiguration) async throws {
        guard configuration.isValid else {
            throw CapabilityError.initializationFailed("Invalid mock network configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
    }
    
    public func handleEnvironmentChange(_ environment: CapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
}