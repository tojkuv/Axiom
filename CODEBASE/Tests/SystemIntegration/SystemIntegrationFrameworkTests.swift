import XCTest
import SwiftUI
@testable import Axiom
@testable import AxiomTesting

/// Comprehensive tests for System Integration framework functionality
/// Tests persistence capabilities, capability protocols, and cross-system interactions using AxiomTesting framework
final class SystemIntegrationFrameworkTests: XCTestCase {
    
    // MARK: - Test Environment
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Persistence Capability Tests
    
    func testAutomaticStatePersistence() async throws {
        try await testEnvironment.runTest { env in
            let persistence = TestPersistenceCapability()
            let client = try await env.createClient(
                PersistableTestClient.self,
                id: "persistence-client"
            ) {
                PersistableTestClient(persistence: persistence)
            }
            
            // Use framework utilities to test persistence
            try await TestHelpers.persistence.assertStatePersistence(
                client: client,
                capability: persistence,
                stateKey: "test.state",
                stateValue: TestPersistableState(value: "Test Data", counter: 42)
            )
            
            // Verify persistence was triggered
            try await TestHelpers.context.assertState(
                in: persistence,
                condition: { _ in persistence.saveCount == 1 },
                description: "State should be automatically persisted"
            )
            
            // Verify data integrity
            let savedData = try await persistence.load(TestPersistableState.self, for: "test.state")
            XCTAssertEqual(savedData?.value, "Test Data")
            XCTAssertEqual(savedData?.counter, 42)
        }
    }
    
    func testCrossLaunchPersistence() async throws {
        try await testEnvironment.runTest { env in
            // Create temporary directory for testing
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("axiom-test-\(UUID().uuidString)")
            
            // Test cross-launch persistence using framework utilities
            try await TestHelpers.persistence.assertCrossLaunchPersistence(
                directory: tempDir,
                testData: TestPersistableState(value: "Persisted", counter: 123),
                stateKey: "app.state"
            ) { storage in
                AdapterBasedPersistence(adapter: storage)
            }
            
            // Cleanup
            try? FileManager.default.removeItem(at: tempDir)
        }
    }
    
    func testSelectivePersistenceWithClientIntegration() async throws {
        try await testEnvironment.runTest { env in
            let persistence = TestPersistenceCapability()
            let client = try await env.createClient(
                PersistableTestClient.self,
                id: "selective-client"
            ) {
                PersistableTestClient(persistence: persistence)
            }
            
            // Configure selective persistence rules
            await client.configurePersistence(persistOnlyOnCounterIncrement: true)
            
            // Update value (should not persist)
            try await client.process(.setValue("Important Data"))
            
            // Verify no persistence yet
            try await TestHelpers.context.assertState(
                in: persistence,
                condition: { _ in persistence.saveCount == 0 },
                description: "Value updates should not trigger persistence"
            )
            
            // Increment counter (should persist)
            try await client.process(.increment)
            
            // Verify persistence was triggered
            try await TestHelpers.context.assertState(
                in: persistence,
                timeout: .seconds(1),
                condition: { _ in persistence.saveCount == 1 },
                description: "Counter increment should trigger persistence"
            )
            
            // Verify persisted state content
            let savedState = try await persistence.load(TestPersistableState.self, for: "client.state")
            XCTAssertEqual(savedState?.value, "Important Data")
            XCTAssertEqual(savedState?.counter, 1)
        }
    }
    
    func testPersistencePerformanceUnderLoad() async throws {
        try await testEnvironment.runTest { env in
            // Test persistence performance with concurrent operations
            try await TestHelpers.performance.assertPerformanceRequirements(
                operation: {
                    let persistence = TestPersistenceCapability()
                    
                    // Concurrent saves and loads
                    await withTaskGroup(of: Void.self) { group in
                        // Save operations
                        for i in 0..<50 {
                            group.addTask {
                                let data = TestPersistableState(value: "Data-\(i)", counter: i)
                                try? await persistence.save(data, for: "key-\(i)")
                            }
                        }
                        
                        // Load operations
                        for i in 0..<50 {
                            group.addTask {
                                _ = try? await persistence.load(TestPersistableState.self, for: "key-\(i)")
                            }
                        }
                    }
                    
                    // Verify all operations completed
                    XCTAssertEqual(persistence.saveCount, 50)
                },
                maxDuration: .milliseconds(500), // Should complete quickly
                maxMemoryGrowth: 10 * 1024, // 10KB max growth
                iterations: 1
            )
        }
    }
    
    func testPersistenceMemoryManagement() async throws {
        try await testEnvironment.runTest { env in
            // Test memory management of persistence operations
            try await TestHelpers.context.assertNoMemoryLeaks {
                var persistence: TestPersistenceCapability? = TestPersistenceCapability()
                var client: PersistableTestClient? = PersistableTestClient(persistence: persistence!)
                
                // Perform persistence operations
                try await client?.process(.setValue("Memory test"))
                try await client?.process(.increment)
                
                // Verify persistence occurred
                XCTAssertEqual(persistence?.saveCount, 1)
                
                // Clean up references
                client = nil
                persistence = nil
                
                // Allow cleanup
                try await Task.sleep(for: .milliseconds(50))
            }
        }
    }
    
    // MARK: - Capability Protocol Tests
    
    func testCapabilityLifecycleTransitions() async throws {
        try await testEnvironment.runTest { env in
            let capability = TestSystemCapability()
            
            // Test performance requirement for capability transitions
            try await TestHelpers.performance.assertPerformanceRequirements(
                operation: {
                    // Test initial state
                    let initialAvailability = await capability.isAvailable
                    XCTAssertFalse(initialAvailability, "Capability should start unavailable")
                    
                    // Test initialization
                    try await capability.activate()
                    let afterInit = await capability.isAvailable
                    XCTAssertTrue(afterInit, "Capability should be available after initialization")
                    
                    // Test state transitions
                    await capability.transitionTo(.restricted)
                    var currentState = await capability.currentState
                    XCTAssertEqual(currentState, .restricted)
                    
                    await capability.transitionTo(.unavailable)
                    currentState = await capability.currentState
                    XCTAssertEqual(currentState, .unavailable)
                    
                    await capability.transitionTo(.unknown)
                    currentState = await capability.currentState
                    XCTAssertEqual(currentState, .unknown)
                    
                    // Test termination
                    await capability.deactivate()
                    let afterTerminate = await capability.isAvailable
                    XCTAssertFalse(afterTerminate, "Capability should be unavailable after termination")
                },
                maxDuration: .milliseconds(10), // < 10ms requirement
                maxMemoryGrowth: 512, // 512 bytes max
                iterations: 1
            )
        }
    }
    
    func testCapabilityStatesComprehensiveCoverage() async throws {
        try await testEnvironment.runTest { env in
            let capability = TestSystemCapability()
            
            // Test all required capability states
            let states: [CapabilityState] = [.available, .unavailable, .restricted, .unknown]
            
            for state in states {
                await capability.transitionTo(state)
                
                try await TestHelpers.context.assertState(
                    in: capability,
                    condition: { _ in capability.currentState == state },
                    description: "Capability should support \(state) state"
                )
            }
        }
    }
    
    func testCapabilityInitializationErrorHandling() async throws {
        try await testEnvironment.runTest { env in
            let capability = FailingTestCapability()
            
            // Test initialization failure
            do {
                try await capability.activate()
                XCTFail("Initialization should have thrown an error")
            } catch {
                XCTAssertTrue(error is CapabilityError)
            }
            
            // Verify capability remains unavailable after failed initialization
            try await TestHelpers.context.assertState(
                in: capability,
                condition: { _ in !capability.isAvailable },
                description: "Capability should remain unavailable after failed initialization"
            )
        }
    }
    
    func testConcurrentCapabilityAccess() async throws {
        try await testEnvironment.runTest { env in
            let capability = TestSystemCapability()
            try await capability.activate()
            
            // Test concurrent capability access using framework utilities
            try await TestHelpers.performance.loadTest(
                concurrency: 20,
                duration: .seconds(1),
                operation: {
                    // Mix of reads and state transitions
                    if Bool.random() {
                        _ = await capability.isAvailable
                    } else {
                        let states: [CapabilityState] = [.available, .restricted]
                        await capability.transitionTo(states.randomElement()!)
                    }
                }
            )
            
            // Verify capability is in a valid state after concurrent access
            try await TestHelpers.context.assertState(
                in: capability,
                condition: { _ in
                    [.available, .restricted].contains(capability.currentState)
                },
                description: "Capability should be in a valid state after concurrent access"
            )
        }
    }
    
    func testCapabilityResourceManagement() async throws {
        try await testEnvironment.runTest { env in
            let capability = ResourceTestCapability()
            
            // Initialize and allocate resources
            try await capability.activate()
            await capability.allocateResources()
            
            let resourcesBeforeTermination = await capability.activeResources
            XCTAssertGreaterThan(resourcesBeforeTermination, 0, "Should have active resources")
            
            // Test resource cleanup on termination
            await capability.deactivate()
            
            try await TestHelpers.context.assertState(
                in: capability,
                condition: { _ in
                    capability.activeResources == 0 &&
                    capability.currentState == .unavailable
                },
                description: "All resources should be cleaned up and capability unavailable after termination"
            )
        }
    }
    
    func testCapabilityStateObservation() async throws {
        try await testEnvironment.runTest { env in
            let capability = ObservableTestCapability()
            var observedStates: [CapabilityState] = []
            
            // Set up state observation using framework utilities
            let observationTask = Task {
                await TestHelpers.context.observeContext(capability) { _ in
                    let state = await capability.currentState
                    observedStates.append(state)
                    return observedStates.count >= 4
                }
            }
            
            // Perform state transitions
            try await capability.activate()
            await capability.transitionTo(.restricted)
            await capability.transitionTo(.available)
            await capability.deactivate()
            
            // Wait for observations to complete
            _ = await observationTask.value
            
            // Verify all transitions were observed
            XCTAssertEqual(observedStates.count, 4)
            XCTAssertEqual(observedStates, [.available, .restricted, .available, .unavailable])
        }
    }
    
    // MARK: - Cross-System Integration Tests
    
    func testPersistenceCapabilityIntegration() async throws {
        try await testEnvironment.runTest { env in
            let capability = TestSystemCapability()
            let persistence = TestPersistenceCapability()
            
            // Create client that uses both capability and persistence
            let client = try await env.createClient(
                IntegratedTestClient.self,
                id: "integrated-client"
            ) {
                IntegratedTestClient(capability: capability, persistence: persistence)
            }
            
            // Initialize capability
            try await capability.activate()
            
            // Test integrated operations
            try await client.process(.performOperationAndPersist("Integration Test"))
            
            // Verify both systems worked together
            try await TestHelpers.context.assertState(
                in: capability,
                condition: { _ in capability.operationCount > 0 },
                description: "Capability should have processed operations"
            )
            
            try await TestHelpers.context.assertState(
                in: persistence,
                condition: { _ in persistence.saveCount > 0 },
                description: "Persistence should have saved state"
            )
            
            // Verify data consistency across systems
            let savedState = try await persistence.load(IntegratedTestState.self, for: "integrated.state")
            XCTAssertNotNil(savedState)
            XCTAssertEqual(savedState?.operationResult, "Integration Test")
        }
    }
    
    func testSystemRecoveryFromCapabilityFailure() async throws {
        try await testEnvironment.runTest { env in
            let capability = FailingTestCapability()
            let persistence = TestPersistenceCapability()
            
            let client = try await env.createClient(
                IntegratedTestClient.self,
                id: "recovery-client"
            ) {
                IntegratedTestClient(capability: capability, persistence: persistence)
            }
            
            // Attempt operation with failed capability
            do {
                try await client.process(.performOperationAndPersist("Recovery Test"))
                XCTFail("Operation should have failed due to capability failure")
            } catch {
                // Expected failure
            }
            
            // Verify system handled failure gracefully
            try await TestHelpers.context.assertState(
                in: client,
                condition: { _ in client.hasRecoveredFromFailure },
                description: "Client should recover gracefully from capability failure"
            )
            
            // Verify persistence still works independently
            let fallbackState = IntegratedTestState(operationResult: "Fallback", timestamp: Date())
            try await persistence.save(fallbackState, for: "fallback.state")
            
            let savedFallback = try await persistence.load(IntegratedTestState.self, for: "fallback.state")
            XCTAssertEqual(savedFallback?.operationResult, "Fallback")
        }
    }
    
    // MARK: - Framework Compliance Tests
    
    func testSystemIntegrationFrameworkCompliance() async throws {
        let capability = TestSystemCapability()
        let persistence = TestPersistenceCapability()
        let client = PersistableTestClient(persistence: persistence)
        
        // Use framework compliance testing
        assertFrameworkCompliance(capability)
        assertFrameworkCompliance(persistence)
        assertFrameworkCompliance(client)
        
        // System integration specific compliance
        XCTAssertTrue(capability is Capability, "Must implement Capability protocol")
        XCTAssertTrue(persistence is PersistenceCapability, "Must implement PersistenceCapability protocol")
        XCTAssertTrue(client is Client, "Must implement Client protocol")
        XCTAssertTrue(client is Persistable, "Must implement Persistable protocol")
    }
}

// MARK: - Test Support Types

// Test Persistable State
struct TestPersistableState: State, Codable, Equatable, Sendable {
    let value: String
    let counter: Int
    let timestamp: Date
    
    init(value: String, counter: Int, timestamp: Date = Date()) {
        self.value = value
        self.counter = counter
        self.timestamp = timestamp
    }
}

// Test Persistence Capability
@MainActor
class TestPersistenceCapability: PersistenceCapability {
    private var storage: [String: Data] = [:]
    private(set) var saveCount: Int = 0
    private(set) var loadCount: Int = 0
    private(set) var deleteCount: Int = 0
    private(set) var isInitialized: Bool = false
    
    var isAvailable: Bool {
        isInitialized
    }
    
    func activate() async throws {
        isInitialized = true
    }
    
    func deactivate() async {
        storage.removeAll()
        saveCount = 0
        loadCount = 0
        deleteCount = 0
        isInitialized = false
    }
    
    func save<T: Codable>(_ data: T, for key: String) async throws {
        let encoded = try JSONEncoder().encode(data)
        storage[key] = encoded
        saveCount += 1
    }
    
    func load<T: Codable>(_ type: T.Type, for key: String) async throws -> T? {
        loadCount += 1
        guard let data = storage[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    func delete(key: String) async throws {
        storage.removeValue(forKey: key)
        deleteCount += 1
    }
    
    func exists(key: String) async -> Bool {
        return storage[key] != nil
    }
}

// Test System Capability
actor TestSystemCapability: Capability {
    private(set) var currentState: CapabilityState = .unavailable
    private(set) var operationCount: Int = 0
    
    var isAvailable: Bool {
        currentState == .available
    }
    
    func activate() async throws {
        currentState = .available
    }
    
    func deactivate() async {
        currentState = .unavailable
        operationCount = 0
    }
    
    func transitionTo(_ state: CapabilityState) {
        currentState = state
    }
    
    func performOperation() async throws {
        guard isAvailable else {
            throw CapabilityError.notAvailable
        }
        operationCount += 1
    }
}

// Failing Test Capability
actor FailingTestCapability: Capability {
    private(set) var currentState: CapabilityState = .unavailable
    
    var isAvailable: Bool {
        currentState == .available
    }
    
    func activate() async throws {
        throw CapabilityError.initializationFailed(reason: "Test failure")
    }
    
    func deactivate() async {
        currentState = .unavailable
    }
}

// Resource Test Capability
actor ResourceTestCapability: Capability {
    private(set) var currentState: CapabilityState = .unavailable
    private(set) var activeResources: Int = 0
    
    var isAvailable: Bool {
        currentState == .available
    }
    
    func activate() async throws {
        currentState = .available
    }
    
    func deactivate() async {
        activeResources = 0
        currentState = .unavailable
    }
    
    func allocateResources() {
        guard currentState == .available else { return }
        activeResources += 5
    }
}

// Observable Test Capability
actor ObservableTestCapability: Capability {
    private(set) var currentState: CapabilityState = .unavailable
    private var continuation: AsyncStream<CapabilityState>.Continuation?
    
    var isAvailable: Bool {
        currentState == .available
    }
    
    var stateStream: AsyncStream<CapabilityState> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }
    
    func activate() async throws {
        transitionTo(.available)
    }
    
    func deactivate() async {
        transitionTo(.unavailable)
        continuation?.finish()
    }
    
    func transitionTo(_ state: CapabilityState) {
        currentState = state
        continuation?.yield(state)
    }
}

// Test Persistable Client
actor PersistableTestClient: Client, Persistable {
    typealias StateType = TestPersistableState
    typealias ActionType = PersistableTestAction
    
    static let persistedKeys: [String] = ["client.state"]
    let persistence: PersistenceCapability
    
    private(set) var currentState: TestPersistableState
    private let stream: AsyncStream<TestPersistableState>
    private let continuation: AsyncStream<TestPersistableState>.Continuation
    private var persistOnlyOnCounterIncrement: Bool = false
    
    var stateStream: AsyncStream<TestPersistableState> {
        stream
    }
    
    var id: String { "persistable-client" }
    
    init(persistence: PersistenceCapability) {
        self.persistence = persistence
        self.currentState = TestPersistableState(value: "", counter: 0)
        (stream, continuation) = AsyncStream.makeStream(of: TestPersistableState.self)
        continuation.yield(currentState)
    }
    
    func configurePersistence(persistOnlyOnCounterIncrement: Bool) {
        self.persistOnlyOnCounterIncrement = persistOnlyOnCounterIncrement
    }
    
    func process(_ action: PersistableTestAction) async throws {
        switch action {
        case .setValue(let value):
            currentState = TestPersistableState(
                value: value,
                counter: currentState.counter
            )
            continuation.yield(currentState)
            
            if !persistOnlyOnCounterIncrement {
                try await persistState()
            }
            
        case .increment:
            currentState = TestPersistableState(
                value: currentState.value,
                counter: currentState.counter + 1
            )
            continuation.yield(currentState)
            
            // Always persist on counter increment
            try await persistState()
        }
    }
    
    func persistState() async throws {
        try await persistence.save(currentState, for: Self.persistedKeys.first!)
    }
    
    deinit {
        continuation.finish()
    }
}

enum PersistableTestAction: Equatable {
    case setValue(String)
    case increment
}

// Integrated Test State
struct IntegratedTestState: State, Codable, Equatable, Sendable {
    let operationResult: String
    let timestamp: Date
}

// Integrated Test Client
actor IntegratedTestClient: Client {
    typealias StateType = IntegratedTestState
    typealias ActionType = IntegratedTestAction
    
    private let capability: TestSystemCapability
    private let persistence: TestPersistenceCapability
    private(set) var currentState: IntegratedTestState
    private let stream: AsyncStream<IntegratedTestState>
    private let continuation: AsyncStream<IntegratedTestState>.Continuation
    private(set) var hasRecoveredFromFailure: Bool = false
    
    var stateStream: AsyncStream<IntegratedTestState> {
        stream
    }
    
    var id: String { "integrated-client" }
    
    init(capability: TestSystemCapability, persistence: TestPersistenceCapability) {
        self.capability = capability
        self.persistence = persistence
        self.currentState = IntegratedTestState(operationResult: "", timestamp: Date())
        (stream, continuation) = AsyncStream.makeStream(of: IntegratedTestState.self)
        continuation.yield(currentState)
    }
    
    func process(_ action: IntegratedTestAction) async throws {
        switch action {
        case .performOperationAndPersist(let input):
            do {
                // Use capability to perform operation
                try await capability.performOperation()
                
                // Update state with result
                currentState = IntegratedTestState(
                    operationResult: input,
                    timestamp: Date()
                )
                continuation.yield(currentState)
                
                // Persist the result
                try await persistence.save(currentState, for: "integrated.state")
                
            } catch {
                // Handle capability failure gracefully
                hasRecoveredFromFailure = true
                throw error
            }
        }
    }
    
    deinit {
        continuation.finish()
    }
}

enum IntegratedTestAction: Equatable {
    case performOperationAndPersist(String)
}

// MARK: - Framework Extensions

// File Storage Adapter for cross-launch testing
class FileStorageAdapter: StorageAdapter {
    private let directory: URL
    
    init(directory: URL) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    
    func save(_ data: Data, for key: String) async throws {
        let fileURL = directory.appendingPathComponent(key)
        try data.write(to: fileURL)
    }
    
    func load(for key: String) async throws -> Data? {
        let fileURL = directory.appendingPathComponent(key)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try Data(contentsOf: fileURL)
    }
    
    func delete(for key: String) async throws {
        let fileURL = directory.appendingPathComponent(key)
        try FileManager.default.removeItem(at: fileURL)
    }
    
    func exists(for key: String) async -> Bool {
        let fileURL = directory.appendingPathComponent(key)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}

// Adapter-based persistence for cross-launch testing
class AdapterBasedPersistence: PersistenceCapability {
    private let adapter: StorageAdapter
    private var isInitialized: Bool = false
    
    var isAvailable: Bool {
        isInitialized
    }
    
    init(adapter: StorageAdapter) {
        self.adapter = adapter
    }
    
    func activate() async throws {
        isInitialized = true
    }
    
    func deactivate() async {
        isInitialized = false
    }
    
    func save<T: Codable>(_ data: T, for key: String) async throws {
        let encoded = try JSONEncoder().encode(data)
        try await adapter.save(encoded, for: key)
    }
    
    func load<T: Codable>(_ type: T.Type, for key: String) async throws -> T? {
        guard let data = try await adapter.load(for: key) else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    func delete(key: String) async throws {
        try await adapter.delete(for: key)
    }
    
    func exists(key: String) async -> Bool {
        return await adapter.exists(for: key)
    }
}

// TestHelpers extensions for System Integration
extension TestHelpers {
    struct Persistence {
        /// Assert that state persistence works correctly
        static func assertStatePersistence<C: Client & Persistable, S: State & Codable & Equatable>(
            client: C,
            capability: TestPersistenceCapability,
            stateKey: String,
            stateValue: S,
            file: StaticString = #file,
            line: UInt = #line
        ) async throws {
            // Trigger persistence
            try await client.persistState()
            
            // Verify data was saved
            let savedData = try await capability.load(S.self, for: stateKey)
            XCTAssertEqual(savedData, stateValue, "Persisted state should match expected value", file: file, line: line)
        }
        
        /// Assert cross-launch persistence functionality
        static func assertCrossLaunchPersistence<T: State & Codable & Equatable>(
            directory: URL,
            testData: T,
            stateKey: String,
            persistenceFactory: (StorageAdapter) -> PersistenceCapability,
            file: StaticString = #file,
            line: UInt = #line
        ) async throws {
            // First "launch" - save data
            let storage1 = FileStorageAdapter(directory: directory)
            let persistence1 = persistenceFactory(storage1)
            
            try await persistence1.activate()
            try await persistence1.save(testData, for: stateKey)
            await persistence1.deactivate()
            
            // Second "launch" - load data
            let storage2 = FileStorageAdapter(directory: directory)
            let persistence2 = persistenceFactory(storage2)
            try await persistence2.activate()
            
            let loadedData = try await persistence2.load(T.self, for: stateKey)
            XCTAssertNotNil(loadedData, "Data should persist across launches", file: file, line: line)
            XCTAssertEqual(loadedData, testData, "Loaded data should match saved data", file: file, line: line)
            
            await persistence2.deactivate()
        }
    }
}

extension TestHelpers {
    static let persistence = Persistence.self
}

// Storage Adapter Protocol
protocol StorageAdapter {
    func save(_ data: Data, for key: String) async throws
    func load(for key: String) async throws -> Data?
    func delete(for key: String) async throws
    func exists(for key: String) async -> Bool
}

// Capability Error Types
enum CapabilityError: Error {
    case initializationFailed(reason: String)
    case notAvailable
    case operationFailed(String)
}

// CapabilityState is imported from the Axiom module

// Capability Protocol
protocol Capability: AnyObject {
    var isAvailable: Bool { get async }
    var currentState: CapabilityState { get async }
    
    func activate() async throws
    func deactivate() async
}

// Persistence Capability Protocol
protocol PersistenceCapability: Capability {
    func save<T: Codable>(_ data: T, for key: String) async throws
    func load<T: Codable>(_ type: T.Type, for key: String) async throws -> T?
    func delete(key: String) async throws
    func exists(key: String) async -> Bool
}

// Persistable Protocol
protocol Persistable {
    static var persistedKeys: [String] { get }
    var persistence: PersistenceCapability { get }
    
    func persistState() async throws
}