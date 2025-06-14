import XCTest
import SwiftUI
@testable import Axiom
@testable import AxiomTesting

/// Comprehensive tests for Context framework functionality
/// Tests context lifecycle, state management, and protocol compliance
final class ContextFrameworkTests: XCTestCase {
    
    // MARK: - Test Environment
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Context Lifecycle Tests
    
    func testContextLifecycleManagement() async throws {
        try await testEnvironment.runTest { env in
            // Create test context using framework utilities
            let context = try await env.createContext(
                TestableContext.self,
                id: "lifecycle-test"
            ) {
                TestableContext()
            }
            
            // Test lifecycle using AxiomTesting framework
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.isActive },
                description: "Context should be active after creation"
            )
            
            // Test state changes
            await context.updateState("New State")
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.currentState == "New State" },
                description: "Context state should update correctly"
            )
            
            // Test memory management
            try await TestHelpers.context.assertNoMemoryLeaks {
                let tempContext = TestableContext()
                await tempContext.onAppear()
                await tempContext.updateState("Temp State")
                await tempContext.onDisappear()
            }
        }
    }
    
    func testContextObservationPatterns() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                ObservableTestContext.self,
                id: "observation-test"
            ) {
                ObservableTestContext()
            }
            
            // Use testing framework to observe changes
            let observer = try await TestHelpers.context.observeContext(context)
            
            // Make state changes
            await context.updateState("State 1")
            await context.incrementCounter()
            await context.toggleFlag()
            
            // Assert observation count
            try await observer.assertChangeCount(3)
            
            // Assert final state
            try await observer.assertLastState { ctx in
                ctx.state == "State 1" && ctx.counter == 1 && ctx.flag
            }
        }
    }
    
    // MARK: - Context Action Processing Tests
    
    func testContextActionSequences() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                ActionableTestContext.self,
                id: "action-test"
            ) {
                ActionableTestContext()
            }
            
            // Test action sequence using framework utilities
            try await TestHelpers.context.assertActionSequence(
                in: context,
                actions: [
                    ActionableTestContext.Action.load,
                    ActionableTestContext.Action.process("data"),
                    ActionableTestContext.Action.save
                ],
                expectedStates: [
                    { $0.isLoading },
                    { $0.isProcessing && $0.data == "data" },
                    { $0.isSaved && !$0.isProcessing }
                ]
            )
        }
    }
    
    func testContextErrorHandling() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                ErrorHandlingTestContext.self,
                id: "error-test"
            ) {
                ErrorHandlingTestContext()
            }
            
            // Test error action handling
            try await TestHelpers.context.assertActionFails(
                in: context,
                action: ErrorHandlingTestContext.Action.failingAction,
                expectedError: TestContextError.processingFailed
            )
            
            // Verify error state
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.hasError },
                description: "Context should be in error state"
            )
        }
    }
    
    // MARK: - Context Hierarchy Tests
    
    func testParentChildContextRelationships() async throws {
        try await testEnvironment.runTest { env in
            let parentContext = try await env.createContext(
                ParentTestContext.self,
                id: "parent"
            ) {
                ParentTestContext()
            }
            
            let childContext = try await env.createContext(
                ChildTestContext.self,
                id: "child"
            ) {
                ChildTestContext()
            }
            
            // Establish parent-child relationship
            try await TestHelpers.context.establishParentChild(
                parent: parentContext,
                child: childContext
            )
            
            // Test child action propagation
            await childContext.process(.notifyParent("Hello from child"))
            
            try await TestHelpers.context.assertChildActionReceived(
                by: parentContext,
                action: ChildTestContext.Action.notifyParent("Hello from child"),
                from: childContext
            )
            
            // Verify parent received notification
            try await TestHelpers.context.assertState(
                in: parentContext,
                condition: { $0.receivedMessages.contains("Hello from child") },
                description: "Parent should receive child notification"
            )
        }
    }
    
    // MARK: - Context Performance Tests
    
    func testContextPerformanceRequirements() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                PerformanceTestContext.self,
                id: "performance"
            ) {
                PerformanceTestContext()
            }
            
            // Test context performance under load
            let results = try await TestHelpers.performance.testContextPerformance(
                context: context,
                actionCount: 1000,
                concurrentClients: 5
            )
            
            // Assert performance requirements
            XCTAssertGreaterThan(results.throughput, 500, "Should process >500 actions/sec")
            XCTAssertLessThan(results.averageActionDuration.timeInterval, 0.002, "Average action <2ms")
            XCTAssertLessThan(results.memoryGrowth, 10 * 1024 * 1024, "Memory growth <10MB")
        }
    }
    
    // MARK: - Client Observation Tests
    
    func testContextClientObservation() async throws {
        try await testEnvironment.runTest { env in
            let client = FrameworkMockContextClient()
            let context = try await env.createContext(
                ClientObservingTestContext.self,
                id: "client-observer"
            ) {
                ClientObservingTestContext(client: client)
            }
            
            // Process client actions
            try await client.process(.increment)
            try await client.process(.setMessage("Hello from client"))
            
            // Assert context observed changes
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.observedStates.count >= 2 },
                description: "Context should observe client state changes"
            )
            
            // Verify latest state
            try await TestHelpers.context.assertState(
                in: context,
                condition: { ctx in
                    guard let lastState = ctx.observedStates.last else { return false }
                    return lastState.value == 1 && lastState.message == "Hello from client"
                },
                description: "Context should have latest client state"
            )
        }
    }
    
    func testContextMemoryStabilityUnderLoad() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                MemoryStabilityTestContext.self,
                id: "memory-stability"
            ) {
                MemoryStabilityTestContext()
            }
            
            // Test memory stability under action load using framework utilities
            try await TestHelpers.performance.assertMemoryBounds(
                during: {
                    // Process 1000 actions
                    for i in 0..<1000 {
                        await context.processAction(.update(i))
                    }
                },
                maxGrowth: 1024 * 1024, // 1MB max growth
                maxPeak: 10 * 1024 * 1024 // 10MB max peak
            )
            
            // Verify all actions were processed
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.processedActionCount == 1000 },
                description: "All 1000 actions should be processed"
            )
        }
    }
    
    func testContextWeakReferenceManagement() async throws {
        try await testEnvironment.runTest { env in
            var client: FrameworkMockContextClient? = FrameworkMockContextClient()
            weak var weakClient = client
            
            let context = try await env.createContext(
                WeakReferenceTestContext.self,
                id: "weak-reference"
            ) {
                WeakReferenceTestContext()
            }
            
            // Attach client
            await context.attachClient(client!)
            
            // Verify client is attached
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.hasAttachedClient },
                description: "Client should be attached"
            )
            
            // Test memory leak prevention with framework utilities
            try await TestHelpers.context.assertNoMemoryLeaks {
                // Release strong reference
                client = nil
                
                // Force cleanup cycle
                try await Task.sleep(for: .milliseconds(10))
                
                // Context should clean up weak reference
                try await TestHelpers.context.assertState(
                    in: context,
                    condition: { !$0.hasAttachedClient },
                    description: "Context should clean up weak reference"
                )
            }
            
            // Verify client was deallocated
            XCTAssertNil(weakClient, "Client should be deallocated")
        }
    }
    
    func testContextMainActorCompliance() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                MainActorTestContext.self,
                id: "main-actor"
            ) {
                MainActorTestContext()
            }
            
            // Verify context operates on MainActor
            await MainActor.run {
                // Direct property access should work on MainActor
                XCTAssertNotNil(context, "Context should be accessible on MainActor")
                
                // UI-related updates should work
                context.updateUIState("UI Update Test")
            }
            
            // Verify UI state was updated
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.uiState == "UI Update Test" },
                description: "UI state should be updated on MainActor"
            )
        }
    }
    
    func testContextAdvancedErrorHandling() async throws {
        try await testEnvironment.runTest { env in
            let errorClient = ErrorThrowingContextClient()
            let context = try await env.createContext(
                AdvancedErrorHandlingTestContext.self,
                id: "advanced-error"
            ) {
                AdvancedErrorHandlingTestContext(client: errorClient)
            }
            
            // Trigger client error
            try? await errorClient.process(.throwError)
            
            // Assert error was handled by context
            try await TestHelpers.context.assertState(
                in: context,
                timeout: .seconds(2),
                condition: { $0.handledErrorCount > 0 },
                description: "Context should handle client errors"
            )
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.lastError != nil },
                description: "Context should capture error details"
            )
        }
    }
    
    // MARK: - Framework Compliance Tests
    
    func testFrameworkComplianceValidation() async throws {
        let context = TestableContext()
        
        // Use framework compliance testing
        assertFrameworkCompliance(context)
        
        // Additional context-specific compliance checks
        await context.onAppear()
        XCTAssertTrue(context.isActive, "Context should be active after onAppear")
        
        await context.onDisappear()
        XCTAssertFalse(context.isActive, "Context should be inactive after onDisappear")
    }
}

// MARK: - Test Support Contexts

@MainActor
class TestableContext: Context, ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var currentState = "initial"
    
    func onAppear() async {
        isActive = true
    }
    
    func onDisappear() async {
        isActive = false
    }
    
    func updateState(_ newState: String) {
        currentState = newState
    }
}

@MainActor
class ObservableTestContext: Context, ObservableObject {
    @Published private(set) var state = ""
    @Published private(set) var counter = 0
    @Published private(set) var flag = false
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func updateState(_ newState: String) {
        state = newState
    }
    
    func incrementCounter() {
        counter += 1
    }
    
    func toggleFlag() {
        flag.toggle()
    }
}

@MainActor
class ActionableTestContext: Context, ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var isProcessing = false
    @Published private(set) var isSaved = false
    @Published private(set) var data: String?
    
    enum Action {
        case load
        case process(String)
        case save
    }
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func process(_ action: Action) async {
        switch action {
        case .load:
            isLoading = true
        case .process(let newData):
            isLoading = false
            isProcessing = true
            data = newData
        case .save:
            isProcessing = false
            isSaved = true
        }
    }
}

@MainActor
class ErrorHandlingTestContext: Context, ObservableObject {
    @Published private(set) var hasError = false
    @Published private(set) var lastError: Error?
    
    enum Action {
        case normalAction
        case failingAction
    }
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func process(_ action: Action) async throws {
        switch action {
        case .normalAction:
            hasError = false
            lastError = nil
        case .failingAction:
            hasError = true
            let error = TestContextError.processingFailed
            lastError = error
            throw error
        }
    }
}

@MainActor
class ParentTestContext: ObservableContext {
    @Published private(set) var receivedMessages: [String] = []
    
    override func handleChildAction<T>(_ action: T, from child: any Context) {
        if let childAction = action as? ChildTestContext.Action {
            switch childAction {
            case .notifyParent(let message):
                receivedMessages.append(message)
            }
        }
    }
}

@MainActor
class ChildTestContext: ObservableContext {
    enum Action: Equatable {
        case notifyParent(String)
    }
    
    func process(_ action: Action) async {
        await sendToParent(action)
    }
}

@MainActor
class PerformanceTestContext: Context, ObservableObject {
    @Published private(set) var processedCount = 0
    @Published private(set) var data: [String] = []
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func process(_ value: String) async {
        data.append(value)
        processedCount += 1
    }
}

@MainActor
class ClientObservingTestContext: ObservableContext {
    private let client: FrameworkMockContextClient
    @Published private(set) var observedStates: [ContextClientState] = []
    private var observationTask: Task<Void, Never>?
    
    init(client: FrameworkMockContextClient) {
        self.client = client
        super.init()
    }
    
    override func performAppearance() async {
        await super.performAppearance()
        observationTask = Task { [weak self] in
            guard let client = self?.client else { return }
            for await state in await client.stateStream {
                await MainActor.run {
                    self?.observedStates.append(state)
                }
            }
        }
    }
    
    override func performDisappearance() async {
        await super.performDisappearance()
        observationTask?.cancel()
        observationTask = nil
    }
}

@MainActor
class MemoryStabilityTestContext: ObservableContext {
    @Published private(set) var processedActionCount = 0
    
    func processAction(_ action: ProtocolTestContextAction) {
        // Process but don't store to test memory stability
        processedActionCount += 1
        
        // Simulate some work without retaining data
        switch action {
        case .update(let value):
            _ = value * 2 // Process but don't store
        }
    }
}

@MainActor
class WeakReferenceTestContext: ObservableContext {
    private weak var client: FrameworkMockContextClient?
    
    var hasAttachedClient: Bool {
        client != nil
    }
    
    func attachClient(_ client: FrameworkMockContextClient) {
        self.client = client
    }
}

@MainActor
class MainActorTestContext: ObservableContext {
    @Published private(set) var uiState = ""
    
    func updateUIState(_ state: String) {
        uiState = state
    }
}

@MainActor
class AdvancedErrorHandlingTestContext: ObservableContext {
    private let client: ErrorThrowingContextClient
    @Published private(set) var handledErrorCount = 0
    @Published private(set) var lastError: Error?
    private var observationTask: Task<Void, Never>?
    
    init(client: ErrorThrowingContextClient) {
        self.client = client
        super.init()
    }
    
    override func performAppearance() async {
        await super.performAppearance()
        observationTask = Task { [weak self] in
            guard let client = self?.client else { return }
            for await _ in await client.errorStream {
                await MainActor.run {
                    self?.handledErrorCount += 1
                    self?.lastError = TestContextError.processingFailed
                }
            }
        }
    }
    
    override func performDisappearance() async {
        await super.performDisappearance()
        observationTask?.cancel()
        observationTask = nil
    }
}

// MARK: - Test Support Types

struct ContextClientState: Axiom.State {
    var value: Int = 0
    var message: String = ""
}

enum ContextClientAction {
    case increment
    case setMessage(String)
}

enum ProtocolTestContextAction {
    case update(Int)
}

enum ContextErrorAction {
    case throwError
}

actor FrameworkFrameworkMockContextClient: Client {
    typealias StateType = ContextClientState
    typealias ActionType = ContextClientAction
    
    private(set) var state = ContextClientState()
    private var continuations: [UUID: AsyncStream<ContextClientState>.Continuation] = [:]
    
    var stateStream: AsyncStream<ContextClientState> {
        AsyncStream { [weak self] continuation in
            let id = UUID()
            Task { [weak self] in
                await self?.addContinuation(continuation, id: id)
                if let currentState = await self?.state {
                    continuation.yield(currentState)
                }
                continuation.onTermination = { @Sendable _ in
                    Task { @Sendable [weak self, id] in
                        await self?.removeContinuation(id: id)
                    }
                }
            }
        }
    }
    
    private func addContinuation(_ continuation: AsyncStream<ContextClientState>.Continuation, id: UUID) {
        continuations[id] = continuation
    }
    
    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }
    
    func process(_ action: ContextClientAction) async throws {
        switch action {
        case .increment:
            state.value += 1
        case .setMessage(let message):
            state.message = message
        }
        
        for (_, continuation) in continuations {
            continuation.yield(state)
        }
    }
}

actor ErrorThrowingContextClient {
    private var errorContinuations: [UUID: AsyncStream<Error>.Continuation] = [:]
    
    var errorStream: AsyncStream<Error> {
        AsyncStream { [weak self] continuation in
            let id = UUID()
            Task { [weak self] in
                await self?.addErrorContinuation(continuation, id: id)
                continuation.onTermination = { @Sendable _ in
                    Task { @Sendable [weak self, id] in
                        await self?.removeErrorContinuation(id: id)
                    }
                }
            }
        }
    }
    
    private func addErrorContinuation(_ continuation: AsyncStream<Error>.Continuation, id: UUID) {
        errorContinuations[id] = continuation
    }
    
    private func removeErrorContinuation(id: UUID) {
        errorContinuations.removeValue(forKey: id)
    }
    
    func process(_ action: ContextErrorAction) async throws {
        switch action {
        case .throwError:
            let error = TestContextError.processingFailed
            for (_, continuation) in errorContinuations {
                continuation.yield(error)
            }
            throw error
        }
    }
}

// MARK: - Test Errors

enum TestContextError: Error, Equatable {
    case processingFailed
    case invalidState
    case timeout
}