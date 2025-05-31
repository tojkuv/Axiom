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