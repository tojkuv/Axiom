import XCTest
@testable import Axiom
import SwiftUI

/// Integration tests that validate all core protocols working together
@MainActor
final class IntegrationTests: XCTestCase {
    
    // MARK: - Test Data Types
    
    /// Test domain model for integration testing
    struct TestUser: DomainModel {
        let id: String
        let name: String
        let email: String
        
        func validate() -> DomainValidationResult {
            var errors: [String] = []
            
            if name.isEmpty {
                errors.append("Name cannot be empty")
            }
            
            if !email.contains("@") {
                errors.append("Email must contain @")
            }
            
            return DomainValidationResult(isValid: errors.isEmpty, errors: errors)
        }
    }
    
    /// Test client dependencies
    struct TestClientDependencies: ClientDependencies {
        let userClient: TestUserClient
        let analyticsClient: TestAnalyticsClient
        
        init() {
            let capabilityManager = CapabilityManager()
            self.userClient = TestUserClient(capabilityManager: capabilityManager)
            self.analyticsClient = TestAnalyticsClient(capabilityManager: capabilityManager)
        }
    }
    
    /// Test domain client
    actor TestUserClient: DomainClient {
        typealias State = [String: TestUser]
        typealias DomainModelType = TestUser
        
        private var _state: State = [:]
        private var _stateVersion = StateVersion()
        
        let capabilities: CapabilityManager
        
        var stateSnapshot: State { _state }
        
        init(capabilityManager: CapabilityManager) {
            self.capabilities = capabilityManager
            
            // Add required capabilities
            Task {
                await capabilityManager.addCapability(.userDefaults)
                await capabilityManager.addCapability(.analytics)
            }
        }
        
        func updateState<T>(_ update: @Sendable (inout State) throws -> T) async rethrows -> T {
            let result = try update(&_state)
            _stateVersion = _stateVersion.incrementMinor()
            await notifyObservers()
            return result
        }
        
        func validateState() async throws {
            for user in _state.values {
                let validation = user.validate()
                if !validation.isValid {
                    throw DomainError.validationFailed(validation)
                }
            }
        }
        
        func addObserver<T: AxiomContext>(_ context: T) async {
            // Implementation would track observers
        }
        
        func removeObserver<T: AxiomContext>(_ context: T) async {
            // Implementation would remove observers
        }
        
        func notifyObservers() async {
            // Implementation would notify observers
        }
        
        func initialize() async throws {
            try await validateState()
        }
        
        func shutdown() async {
            _state.removeAll()
        }
        
        // MARK: DomainClient Implementation
        
        func create(_ model: TestUser) async throws -> TestUser {
            try await capabilities.validate(.userDefaults)
            
            let validation = model.validate()
            guard validation.isValid else {
                throw DomainError.validationFailed(validation)
            }
            
            return await updateState { state in
                state[model.id] = model
                return model
            }
        }
        
        func update(_ model: TestUser) async throws -> TestUser {
            try await capabilities.validate(.userDefaults)
            
            let validation = model.validate()
            guard validation.isValid else {
                throw DomainError.validationFailed(validation)
            }
            
            return await updateState { state in
                state[model.id] = model
                return model
            }
        }
        
        func delete(id: String) async throws {
            try await capabilities.validate(.userDefaults)
            
            await updateState { state in
                state.removeValue(forKey: id)
            }
        }
        
        func find(id: String) async -> TestUser? {
            stateSnapshot[id]
        }
        
        func query(_ criteria: QueryCriteria<TestUser>) async -> [TestUser] {
            let users = Array(stateSnapshot.values)
            return users.filter(criteria.predicate)
        }
        
        func validateBusinessRules(_ model: TestUser) async throws {
            let validation = model.validate()
            guard validation.isValid else {
                throw DomainError.validationFailed(validation)
            }
        }
        
        func applyBusinessLogic(_ operation: BusinessOperation<TestUser>) async throws -> TestUser {
            // Simplified implementation
            let user = TestUser(id: "test", name: "Test", email: "test@example.com")
            return try operation.execute(user)
        }
    }
    
    /// Test infrastructure client
    actor TestAnalyticsClient: InfrastructureClient {
        typealias State = [String: Any]
        typealias DomainModelType = EmptyDomain
        
        private var _state: State = [:]
        private var _stateVersion = StateVersion()
        
        let capabilities: CapabilityManager
        
        var stateSnapshot: State { _state }
        
        init(capabilityManager: CapabilityManager) {
            self.capabilities = capabilityManager
        }
        
        func updateState<T>(_ update: @Sendable (inout State) throws -> T) async rethrows -> T {
            let result = try update(&_state)
            _stateVersion = _stateVersion.incrementMinor()
            await notifyObservers()
            return result
        }
        
        func validateState() async throws {
            // Analytics state is always valid
        }
        
        func addObserver<T: AxiomContext>(_ context: T) async {}
        func removeObserver<T: AxiomContext>(_ context: T) async {}
        func notifyObservers() async {}
        
        func initialize() async throws {
            try await validateState()
        }
        
        func shutdown() async {
            _state.removeAll()
        }
        
        // MARK: InfrastructureClient Implementation
        
        func healthCheck() async -> HealthStatus {
            .healthy
        }
        
        func configure(_ configuration: Configuration) async throws {
            try await capabilities.validate(.analytics)
            
            await updateState { state in
                state["configuration"] = configuration.settings
            }
        }
    }
    
    /// Test context
    @MainActor
    final class TestContext: ObservableObject, AxiomContext {
        typealias View = TestView
        typealias Clients = TestClientDependencies
        
        let clients: TestClientDependencies
        let intelligence: AxiomIntelligence
        
        init(clients: TestClientDependencies, intelligence: AxiomIntelligence) {
            self.clients = clients
            self.intelligence = intelligence
        }
        
        func onAppear() async {
            // Initialize clients
            try? await clients.userClient.initialize()
            try? await clients.analyticsClient.initialize()
        }
        
        func onDisappear() async {
            await clients.userClient.shutdown()
            await clients.analyticsClient.shutdown()
        }
        
        func onClientStateChange<T: AxiomClient>(_ client: T) async {
            // Custom handling for state changes
            objectWillChange.send()
        }
        
        func handleError(_ error: any AxiomError) async {
            // Custom error handling
            print("Error handled: \(error)")
        }
    }
    
    /// Test view
    struct TestView: AxiomView {
        let context: TestContext
        
        nonisolated init(context: TestContext) {
            self.context = context
        }
        
        var body: some View {
            VStack {
                Text("Test Axiom View")
                Button("Create User") {
                    Task {
                        let user = TestUser(id: "1", name: "John", email: "john@example.com")
                        try? await context.clients.userClient.create(user)
                    }
                }
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testBasicIntegration() async throws {
        // Create clients
        let dependencies = TestClientDependencies()
        
        // Create context
        let intelligence = DefaultAxiomIntelligence()
        let context = TestContext(
            clients: dependencies,
            intelligence: intelligence
        )
        
        // Test context lifecycle
        await context.onAppear()
        
        // Test capability validation
        let capabilityContext = CapabilityContext(
            component: ComponentID("TestComponent"),
            operation: "create"
        )
        
        let validationResult = try await dependencies.userClient.capabilities.validateWithContext(
            .userDefaults,
            context: capabilityContext
        )
        
        XCTAssertTrue(validationResult.isValid, "User defaults capability should be valid")
        
        // Test domain operations
        let user = TestUser(id: "1", name: "Alice", email: "alice@example.com")
        let createdUser = try await dependencies.userClient.create(user)
        
        XCTAssertEqual(createdUser.id, user.id)
        XCTAssertEqual(createdUser.name, user.name)
        XCTAssertEqual(createdUser.email, user.email)
        
        // Test retrieval
        let foundUser = await dependencies.userClient.find(id: "1")
        XCTAssertNotNil(foundUser)
        XCTAssertEqual(foundUser?.name, "Alice")
        
        // Test infrastructure client
        let config = Configuration(settings: ["key": "value"])
        try await dependencies.analyticsClient.configure(config)
        
        let healthStatus = await dependencies.analyticsClient.healthCheck()
        XCTAssertEqual(healthStatus, .healthy)
        
        // Test context cleanup
        await context.onDisappear()
    }
    
    func testCapabilityDegradation() async throws {
        let dependencies = TestClientDependencies()
        
        // Remove capability to test degradation
        await dependencies.userClient.capabilities.removeCapability(.userDefaults)
        
        let capabilityContext = CapabilityContext(
            component: ComponentID("TestComponent"),
            operation: "create"
        )
        
        let degradationResult = await dependencies.userClient.capabilities.validateWithDegradation(
            .userDefaults,
            context: capabilityContext
        )
        
        XCTAssertFalse(degradationResult.isUsable, "Should fail gracefully when capability unavailable")
    }
    
    func testDomainValidation() async throws {
        let dependencies = TestClientDependencies()
        
        // Test valid user
        let validUser = TestUser(id: "1", name: "Bob", email: "bob@example.com")
        let validation = validUser.validate()
        XCTAssertTrue(validation.isValid)
        
        // Test invalid user
        let invalidUser = TestUser(id: "2", name: "", email: "invalid")
        let invalidValidation = invalidUser.validate()
        XCTAssertFalse(invalidValidation.isValid)
        XCTAssertEqual(invalidValidation.errors.count, 2)
        
        // Test creation with invalid user should fail
        do {
            _ = try await dependencies.userClient.create(invalidUser)
            XCTFail("Should have thrown validation error")
        } catch DomainError.validationFailed {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testStateManagement() async throws {
        let dependencies = TestClientDependencies()
        
        // Initial state should be empty
        let initialState = await dependencies.userClient.stateSnapshot
        XCTAssertTrue(initialState.isEmpty)
        
        // Add users
        let user1 = TestUser(id: "1", name: "User1", email: "user1@example.com")
        let user2 = TestUser(id: "2", name: "User2", email: "user2@example.com")
        
        _ = try await dependencies.userClient.create(user1)
        _ = try await dependencies.userClient.create(user2)
        
        // State should contain both users
        let updatedState = await dependencies.userClient.stateSnapshot
        XCTAssertEqual(updatedState.count, 2)
        XCTAssertNotNil(updatedState["1"])
        XCTAssertNotNil(updatedState["2"])
        
        // Delete one user
        try await dependencies.userClient.delete(id: "1")
        
        // State should contain only one user
        let finalState = await dependencies.userClient.stateSnapshot
        XCTAssertEqual(finalState.count, 1)
        XCTAssertNil(finalState["1"])
        XCTAssertNotNil(finalState["2"])
    }
    
    func testQueryOperations() async throws {
        let dependencies = TestClientDependencies()
        
        // Add test data
        let users = [
            TestUser(id: "1", name: "Alice", email: "alice@example.com"),
            TestUser(id: "2", name: "Bob", email: "bob@test.com"),
            TestUser(id: "3", name: "Charlie", email: "charlie@example.com")
        ]
        
        for user in users {
            _ = try await dependencies.userClient.create(user)
        }
        
        // Query by email domain
        let exampleUsers = await dependencies.userClient.query(
            QueryCriteria<TestUser>(predicate: { $0.email.contains("example.com") })
        )
        
        XCTAssertEqual(exampleUsers.count, 2)
        XCTAssertTrue(exampleUsers.contains { $0.name == "Alice" })
        XCTAssertTrue(exampleUsers.contains { $0.name == "Charlie" })
        
        // Query by name prefix
        let bUsers = await dependencies.userClient.query(
            QueryCriteria<TestUser>(predicate: { $0.name.hasPrefix("B") })
        )
        
        XCTAssertEqual(bUsers.count, 1)
        XCTAssertEqual(bUsers.first?.name, "Bob")
    }
}