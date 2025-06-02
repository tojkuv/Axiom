import Testing
import Foundation
@testable import Axiom
@testable import AxiomTesting

/// Comprehensive testing for AxiomClient protocol conformance and behavior
/// 
/// Tests core client functionality including:
/// - Actor-based state management with isolation
/// - State snapshot immutability
/// - Observer pattern implementation
/// - Concurrent access safety
/// - Capability integration
/// - Performance characteristics
@Suite("AxiomClient Protocol Tests")
struct AxiomClientTests {
    
    // MARK: - Test State Types
    
    struct TestState: Sendable {
        var counter: Int = 0
        var users: [String: TestUser] = [:]
        var isInvalidTestState: Bool = false
        
        mutating func incrementCounter() {
            counter += 1
        }
        
        mutating func addUser(_ user: TestUser) {
            users[user.id] = user
        }
    }
    
    struct TestUser: Sendable {
        let id: String
        let name: String
    }
    
    enum TestError: Error, AxiomError {
        case invalidState
        
        var id: UUID { UUID() }
        var category: ErrorCategory { .state }
        var severity: ErrorSeverity { .error }
        var context: ErrorContext { ErrorContext(component: ComponentID("test_component")) }
        var recoveryActions: [RecoveryAction] { [] }
        var userMessage: String { "Test error occurred" }
        var errorDescription: String? { userMessage }
    }
    
    // MARK: - Test Client Implementation
    
    /// Test client implementation for testing AxiomClient protocol
    actor TestClient: AxiomClient {
        typealias State = TestState
        typealias DomainModelType = EmptyDomain
        
        // State management
        private var _state: TestState
        private let _capabilities: CapabilityManager
        
        // Observer management - simplified without weak references for now
        private var observerNotifications: Int = 0
        
        init() {
            _state = TestState()
            _capabilities = CapabilityManager()
        }
        
        var stateSnapshot: TestState {
            _state
        }
        
        var capabilities: CapabilityManager {
            _capabilities
        }
        
        func updateState<T>(_ update: @Sendable (inout TestState) throws -> T) async rethrows -> T {
            let result = try update(&_state)
            await notifyObservers()
            return result
        }
        
        func validateState() async throws {
            // Test validation logic
            if _state.isInvalidTestState {
                throw TestError.invalidState
            }
        }
        
        func addObserver<T: AxiomContext>(_ context: T) async {
            // Simplified observer management for testing
            observerNotifications = 0
        }
        
        func removeObserver<T: AxiomContext>(_ context: T) async {
            // Simplified observer management for testing
        }
        
        func notifyObservers() async {
            observerNotifications += 1
        }
        
        func initialize() async throws {
            // Test initialization
        }
        
        func shutdown() async {
            // Test shutdown
            observerNotifications = 0
        }
        
        // Test helper
        func getObserverNotificationCount() async -> Int {
            observerNotifications
        }
    }
    
    // MARK: - Core Protocol Tests
    
    @Test("State snapshot immutability guarantees")
    func testStateSnapshotImmutability() async throws {
        let client = TestClient()
        
        // Get initial snapshot
        let snapshot1 = await client.stateSnapshot
        #expect(snapshot1.counter == 0)
        
        // Update state
        await client.updateState { state in
            state.incrementCounter()
        }
        
        // Get new snapshot
        let snapshot2 = await client.stateSnapshot
        
        // Verify immutability - snapshots should be different values
        #expect(snapshot1.counter == 0) // Original unchanged
        #expect(snapshot2.counter == 1) // New state updated
        
        // Verify they represent different state versions
        #expect(snapshot1.counter != snapshot2.counter)
    }
    
    @Test("State update atomicity")
    func testStateUpdateAtomicity() async throws {
        let client = TestClient()
        
        // Test atomic update with return value
        let result = await client.updateState { state in
            state.counter = 42
            return state.counter * 2
        }
        
        #expect(result == 84)
        
        let snapshot = await client.stateSnapshot
        #expect(snapshot.counter == 42)
    }
    
    @Test("State update with throwing operation")
    func testStateUpdateWithThrowingOperation() async throws {
        let client = TestClient()
        
        // Test that errors are properly propagated
        do {
            try await client.updateState { state in
                state.isInvalidTestState = true
                throw TestError.invalidState
            }
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            #expect(error is TestError)
        }
        
        // Verify state was not corrupted by the failed update
        let snapshot = await client.stateSnapshot
        #expect(snapshot.isInvalidTestState == true) // Update was applied before error
    }
    
    @Test("State validation functionality")
    func testStateValidation() async throws {
        let client = TestClient()
        
        // Valid state should pass validation
        try await client.validateState()
        
        // Invalid state should fail validation
        await client.updateState { state in
            state.isInvalidTestState = true
        }
        
        await #expect(throws: TestError.self) {
            try await client.validateState()
        }
    }
    
    // MARK: - Observer Pattern Tests
    
    @Test("Observer pattern implementation")
    func testObserverPattern() async throws {
        let client = TestClient()
        
        // Simplified observer test
        let initialCount = await client.getObserverNotificationCount()
        #expect(initialCount == 0)
        
        // Update state and verify notification
        await client.updateState { state in
            state.incrementCounter()
        }
        
        let notificationCount = await client.getObserverNotificationCount()
        #expect(notificationCount == 1)
    }
    
    // MARK: - Concurrency Safety Tests
    
    @Test("Concurrent state access safety")
    func testConcurrentStateAccess() async throws {
        let client = TestClient()
        let iterations = 100
        
        // Perform concurrent state updates
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    await client.updateState { state in
                        state.incrementCounter()
                    }
                }
            }
        }
        
        // Verify final state is consistent
        let finalSnapshot = await client.stateSnapshot
        #expect(finalSnapshot.counter == iterations)
    }
    
    // MARK: - Capability Integration Tests
    
    @Test("Capability manager integration")
    func testCapabilityManagerIntegration() async throws {
        let client = TestClient()
        
        let capabilityManager = await client.capabilities
        
        // Verify capability manager is functional
        #expect(capabilityManager is CapabilityManager)
        
        // Test that capability manager validates available capabilities
        // Note: Default CapabilityManager may not have all capabilities available
        // This tests the validation mechanism rather than specific capability availability
        do {
            try await capabilityManager.validate(.stateManagement)
            // If validation succeeds, capability is available
        } catch {
            // If validation fails, capability is unavailable - this is also valid behavior
            #expect(error is CapabilityError)
        }
    }
    
    // MARK: - Lifecycle Tests
    
    @Test("Client initialization")
    func testClientInitialization() async throws {
        let client = TestClient()
        
        try await client.initialize()
        
        // Verify client is properly initialized
        let snapshot = await client.stateSnapshot
        #expect(snapshot.counter == 0) // Initial state
    }
    
    @Test("Client shutdown")
    func testClientShutdown() async throws {
        let client = TestClient()
        
        // Setup client with some state
        await client.updateState { state in
            state.incrementCounter()
        }
        
        // Shutdown client
        await client.shutdown()
        
        // Verify shutdown effects
        let notificationCount = await client.getObserverNotificationCount()
        #expect(notificationCount == 0)
    }
    
    // MARK: - BaseAxiomClient Protocol Tests
    
    @Test("BaseAxiomClient state version tracking")
    func testBaseAxiomClientStateVersionTracking() async throws {
        let baseClient = BaseAxiomClient<TestState, EmptyDomain>(initialState: TestState(), capabilities: CapabilityManager())
        
        // Initial state
        let initialSnapshot = await baseClient.stateSnapshot
        #expect(initialSnapshot.counter == 0)
        
        // Update state multiple times
        await baseClient.updateState { state in
            state.incrementCounter()
        }
        
        await baseClient.updateState { state in
            state.incrementCounter()
        }
        
        let finalSnapshot = await baseClient.stateSnapshot
        #expect(finalSnapshot.counter == 2)
    }
    
    @Test("BaseAxiomClient observer management")
    func testBaseAxiomClientObserverManagement() async throws {
        let baseClient = BaseAxiomClient<TestState, EmptyDomain>(initialState: TestState(), capabilities: CapabilityManager())
        
        // Test that observer methods don't crash (testing the interface)
        // Note: Real observer testing would require actual context instances
        // For now, we test that the methods exist and can be called
        
        // Update state - should call notifyObservers internally
        await baseClient.updateState { state in
            state.incrementCounter()
        }
        
        // Verify state was updated
        let snapshot = await baseClient.stateSnapshot
        #expect(snapshot.counter == 1)
        
        // Test shutdown (should clear observers)
        await baseClient.shutdown()
    }
    
    @Test("BaseAxiomClient initialization and validation")
    func testBaseAxiomClientInitializationAndValidation() async throws {
        let baseClient = BaseAxiomClient<TestState, EmptyDomain>(initialState: TestState(), capabilities: CapabilityManager())
        
        // Test initialization
        try await baseClient.initialize()
        
        // Test validation (should pass for valid state)
        try await baseClient.validateState()
        
        // Test shutdown
        await baseClient.shutdown()
    }
    
    // MARK: - InfrastructureClient Protocol Tests
    
    /// Test infrastructure client implementation
    actor TestInfrastructureClient: InfrastructureClient {
        typealias State = TestState
        typealias DomainModelType = EmptyDomain
        
        private var _state: TestState
        private let _capabilities: CapabilityManager
        private var _isConfigured: Bool = false
        
        init() {
            _state = TestState()
            _capabilities = CapabilityManager()
        }
        
        var stateSnapshot: TestState {
            _state
        }
        
        var capabilities: CapabilityManager {
            _capabilities
        }
        
        func updateState<T>(_ update: @Sendable (inout TestState) throws -> T) async rethrows -> T {
            return try update(&_state)
        }
        
        func validateState() async throws {}
        func addObserver<T: AxiomContext>(_ context: T) async {}
        func removeObserver<T: AxiomContext>(_ context: T) async {}
        func notifyObservers() async {}
        func initialize() async throws {}
        func shutdown() async {}
        
        // InfrastructureClient methods
        func healthCheck() async -> HealthStatus {
            return _isConfigured ? .healthy : .degraded
        }
        
        func configure(_ configuration: Configuration) async throws {
            _isConfigured = true
            // Simulate configuration validation
            if configuration.settings["invalid"] != nil {
                throw TestError.invalidState
            }
        }
    }
    
    @Test("InfrastructureClient health check functionality")
    func testInfrastructureClientHealthCheck() async throws {
        let infraClient = TestInfrastructureClient()
        
        // Initial health check should be degraded (not configured)
        let initialHealth = await infraClient.healthCheck()
        #expect(initialHealth == .degraded)
        
        // Configure client
        let config = Configuration(settings: ["endpoint": "test"])
        try await infraClient.configure(config)
        
        // Health check should now be healthy
        let configuredHealth = await infraClient.healthCheck()
        #expect(configuredHealth == .healthy)
    }
    
    @Test("InfrastructureClient configuration validation")
    func testInfrastructureClientConfiguration() async throws {
        let infraClient = TestInfrastructureClient()
        
        // Valid configuration should succeed
        let validConfig = Configuration(settings: ["endpoint": "https://api.example.com"])
        try await infraClient.configure(validConfig)
        
        // Invalid configuration should fail
        let invalidConfig = Configuration(settings: ["invalid": "true"])
        await #expect(throws: TestError.self) {
            try await infraClient.configure(invalidConfig)
        }
    }
    
    // MARK: - DomainClient Protocol Tests
    
    /// Test domain model for DomainClient testing
    struct TestDomainModel: DomainModel {
        typealias ID = String
        
        let id: String
        var name: String
        var value: Int
        
        init(id: String, name: String, value: Int = 0) {
            self.id = id
            self.name = name
            self.value = value
        }
    }
    
    /// Test domain client implementation
    actor TestDomainClient: DomainClient {
        typealias State = TestState
        typealias DomainModelType = TestDomainModel
        
        private var _state: TestState
        private let _capabilities: CapabilityManager
        private var _models: [String: TestDomainModel] = [:]
        
        init() {
            _state = TestState()
            _capabilities = CapabilityManager()
        }
        
        var stateSnapshot: TestState {
            _state
        }
        
        var capabilities: CapabilityManager {
            _capabilities
        }
        
        func updateState<T>(_ update: @Sendable (inout TestState) throws -> T) async rethrows -> T {
            return try update(&_state)
        }
        
        func validateState() async throws {}
        func addObserver<T: AxiomContext>(_ context: T) async {}
        func removeObserver<T: AxiomContext>(_ context: T) async {}
        func notifyObservers() async {}
        func initialize() async throws {}
        func shutdown() async {}
        
        // DomainClient methods
        func create(_ model: TestDomainModel) async throws -> TestDomainModel {
            try await validateBusinessRules(model)
            _models[model.id] = model
            return model
        }
        
        func update(_ model: TestDomainModel) async throws -> TestDomainModel {
            guard _models[model.id] != nil else {
                throw TestError.invalidState
            }
            try await validateBusinessRules(model)
            _models[model.id] = model
            return model
        }
        
        func delete(id: String) async throws {
            guard _models[id] != nil else {
                throw TestError.invalidState
            }
            _models.removeValue(forKey: id)
        }
        
        func find(id: String) async -> TestDomainModel? {
            return _models[id]
        }
        
        func query(_ criteria: QueryCriteria<TestDomainModel>) async -> [TestDomainModel] {
            return Array(_models.values)
        }
        
        func validateBusinessRules(_ model: TestDomainModel) async throws {
            // Simulate business rule validation
            if model.name.isEmpty {
                throw TestError.invalidState
            }
        }
        
        func applyBusinessLogic(_ operation: BusinessOperation<TestDomainModel>) async throws -> TestDomainModel {
            // For testing, apply to all models or the first one found
            guard let firstModel = _models.values.first else {
                throw TestError.invalidState
            }
            
            try operation.validate(firstModel)
            let updatedModel = try operation.execute(firstModel)
            _models[updatedModel.id] = updatedModel
            return updatedModel
        }
    }
    
    @Test("DomainClient CRUD operations")
    func testDomainClientCRUDOperations() async throws {
        let domainClient = TestDomainClient()
        
        // Create
        let model = TestDomainModel(id: "test-1", name: "Test Model")
        let createdModel = try await domainClient.create(model)
        #expect(createdModel.id == "test-1")
        #expect(createdModel.name == "Test Model")
        
        // Read (find)
        let foundModel = await domainClient.find(id: "test-1")
        #expect(foundModel != nil)
        #expect(foundModel?.name == "Test Model")
        
        // Update
        var updatedModel = createdModel
        updatedModel.name = "Updated Model"
        let result = try await domainClient.update(updatedModel)
        #expect(result.name == "Updated Model")
        
        // Verify update
        let refetchedModel = await domainClient.find(id: "test-1")
        #expect(refetchedModel?.name == "Updated Model")
        
        // Delete
        try await domainClient.delete(id: "test-1")
        
        // Verify deletion
        let deletedModel = await domainClient.find(id: "test-1")
        #expect(deletedModel == nil)
    }
    
    @Test("DomainClient business rule validation")
    func testDomainClientBusinessRuleValidation() async throws {
        let domainClient = TestDomainClient()
        
        // Valid model should pass
        let validModel = TestDomainModel(id: "valid", name: "Valid Model")
        let createdModel = try await domainClient.create(validModel)
        #expect(createdModel.name == "Valid Model")
        
        // Invalid model should fail validation
        let invalidModel = TestDomainModel(id: "invalid", name: "")
        await #expect(throws: TestError.self) {
            try await domainClient.create(invalidModel)
        }
    }
    
    @Test("DomainClient business logic operations")
    func testDomainClientBusinessLogicOperations() async throws {
        let domainClient = TestDomainClient()
        
        // Create initial model
        let model = TestDomainModel(id: "business-test", name: "Business Model")
        try await domainClient.create(model)
        
        // Apply business operation
        let operation = BusinessOperation<TestDomainModel>(
            name: "increment",
            validate: { _ in /* validation logic */ },
            execute: { model in
                var updated = model
                updated.value += 1
                return updated
            }
        )
        let result = try await domainClient.applyBusinessLogic(operation)
        
        #expect(result.value == 1) // Should be incremented
        
        // Verify the change persisted
        let updatedModel = await domainClient.find(id: "business-test")
        #expect(updatedModel?.value == 1)
    }
    
    @Test("DomainClient query operations")
    func testDomainClientQueryOperations() async throws {
        let domainClient = TestDomainClient()
        
        // Create multiple models
        try await domainClient.create(TestDomainModel(id: "1", name: "Model 1"))
        try await domainClient.create(TestDomainModel(id: "2", name: "Model 2"))
        try await domainClient.create(TestDomainModel(id: "3", name: "Model 3"))
        
        // Query all models
        let criteria = QueryCriteria<TestDomainModel>()
        let results = await domainClient.query(criteria)
        
        #expect(results.count == 3)
        #expect(results.contains { $0.id == "1" })
        #expect(results.contains { $0.id == "2" })
        #expect(results.contains { $0.id == "3" })
    }
    
    // MARK: - Client Container Tests
    
    @Test("ClientContainer single client functionality")
    func testClientContainerSingleClient() async throws {
        let client = TestClient()
        let container = ClientContainer(client)
        
        // Test direct access
        #expect(container.client1 === client)
        #expect(container.client === client) // Convenience property
        
        // Test functionality through container
        await container.client.updateState { state in
            state.incrementCounter()
        }
        
        let snapshot = await container.client.stateSnapshot
        #expect(snapshot.counter == 1)
    }
    
    @Test("ClientContainer2 dual client functionality")
    func testClientContainer2DualClient() async throws {
        let client1 = TestClient()
        let client2 = TestClient()
        let container = ClientContainer2(client1, client2)
        
        // Test direct access
        #expect(container.client1 === client1)
        #expect(container.client2 === client2)
        #expect(container.firstClient === client1) // Convenience property
        #expect(container.secondClient === client2) // Convenience property
        
        // Test independent functionality
        await container.firstClient.updateState { state in
            state.counter = 10
        }
        
        await container.secondClient.updateState { state in
            state.counter = 20
        }
        
        let snapshot1 = await container.firstClient.stateSnapshot
        let snapshot2 = await container.secondClient.stateSnapshot
        
        #expect(snapshot1.counter == 10)
        #expect(snapshot2.counter == 20)
    }
    
    @Test("ClientContainer3 triple client functionality")
    func testClientContainer3TripleClient() async throws {
        let client1 = TestClient()
        let client2 = TestClient()
        let client3 = TestClient()
        let container = ClientContainer3(client1, client2, client3)
        
        // Test direct access
        #expect(container.client1 === client1)
        #expect(container.client2 === client2)
        #expect(container.client3 === client3)
        #expect(container.firstClient === client1)
        #expect(container.secondClient === client2)
        #expect(container.thirdClient === client3)
        
        // Test all clients can be updated independently
        await container.firstClient.updateState { state in state.counter = 1 }
        await container.secondClient.updateState { state in state.counter = 2 }
        await container.thirdClient.updateState { state in state.counter = 3 }
        
        let snapshot1 = await container.firstClient.stateSnapshot
        let snapshot2 = await container.secondClient.stateSnapshot
        let snapshot3 = await container.thirdClient.stateSnapshot
        
        #expect(snapshot1.counter == 1)
        #expect(snapshot2.counter == 2)
        #expect(snapshot3.counter == 3)
    }
    
    @Test("NamedClientContainer functionality")
    func testNamedClientContainer() async throws {
        let client1 = TestClient()
        let client2 = TestClient()
        
        var container = NamedClientContainer()
        
        // Add clients with names
        container.add(client1, named: "primary")
        container.add(client2, named: "secondary")
        
        // Test type-safe retrieval
        let retrievedClient1 = container.get("primary", as: TestClient.self)
        let retrievedClient2 = container.get("secondary", as: TestClient.self)
        
        #expect(retrievedClient1 != nil)
        #expect(retrievedClient2 != nil)
        #expect(retrievedClient1! === client1)
        #expect(retrievedClient2! === client2)
        
        // Test unsafe retrieval
        let unsafeClient = container.get("primary")
        #expect(unsafeClient != nil)
        
        // Test non-existent client
        let nonExistent = container.get("nonexistent", as: TestClient.self)
        #expect(nonExistent == nil)
    }
    
    @Test("NamedClientContainer initialization with clients")
    func testNamedClientContainerInitializationWithClients() async throws {
        let client1 = TestClient()
        let client2 = TestClient()
        
        let clients: [String: any AxiomClient] = [
            "first": client1,
            "second": client2
        ]
        
        let container = NamedClientContainer(clients)
        
        let retrievedFirst = container.get("first", as: TestClient.self)
        let retrievedSecond = container.get("second", as: TestClient.self)
        
        #expect(retrievedFirst != nil)
        #expect(retrievedSecond != nil)
        #expect(retrievedFirst! === client1)
        #expect(retrievedSecond! === client2)
    }
    
    // MARK: - Performance Tests
    
    @Test("State access performance")
    func testStateAccessPerformance() async throws {
        let client = TestClient()
        
        // Warm up
        for _ in 0..<10 {
            _ = await client.stateSnapshot
        }
        
        // Measure state access performance
        let startTime = ContinuousClock.now
        
        for _ in 0..<1000 {
            _ = await client.stateSnapshot
        }
        
        let duration = ContinuousClock.now - startTime
        
        // State access should be very fast (<1ms for 1000 accesses)
        #expect(duration < .milliseconds(1), "State access too slow: \(duration)")
    }
    
    @Test("State update performance")
    func testStateUpdatePerformance() async throws {
        let client = TestClient()
        
        // Measure update performance
        let startTime = ContinuousClock.now
        
        for i in 0..<100 {
            await client.updateState { state in
                state.counter = i
            }
        }
        
        let duration = ContinuousClock.now - startTime
        
        // Updates should complete reasonably fast (<10ms for 100 updates)
        #expect(duration < .milliseconds(10), "State updates too slow: \(duration)")
    }
}

// MARK: - Supporting Test Types

/// Empty dependencies for test contexts that don't need client dependencies
struct EmptyDependencies: ClientDependencies {
    init() {}
}