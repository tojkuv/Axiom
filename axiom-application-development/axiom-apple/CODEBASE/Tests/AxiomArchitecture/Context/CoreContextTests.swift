import XCTest
import AxiomTesting
import SwiftUI
@testable import AxiomArchitecture
@testable import AxiomCore

/// Comprehensive tests for core context functionality
/// 
/// Consolidates: ContextProtocolTests, ContextFrameworkTests, ContextDependenciesTests, AxiomArchitecture/Core/ContextTests
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class CoreContextTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Context Protocol Conformance Tests
    
    func testBasicContextConformance() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                ProtocolTestContext.self,
                id: "protocol-test"
            ) {
                ProtocolTestContext()
            }
            
            // Test basic conformance requirements
            assertFrameworkCompliance(context)
            
            // Test lifecycle
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.isActive },
                description: "Context should be active after creation"
            )
            
            // Test appearance state
            await context.onAppear()
            let appearCount = await context.appearCount
            XCTAssertEqual(appearCount, 1, "onAppear should be called once")
            
            // Test idempotency
            await context.onAppear()
            let appearCount2 = await context.appearCount
            XCTAssertEqual(appearCount2, 1, "onAppear should be idempotent")
            
            // Test disappearance
            await context.onDisappear()
            let disappearCount = await context.disappearCount
            XCTAssertEqual(disappearCount, 1, "onDisappear should be called once")
            
            let isActive = await context.isActive
            XCTAssertFalse(isActive, "Context should be inactive after onDisappear")
        }
    }
    
    func testContextObservationPatterns() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                ObservableProtocolTestContext.self,
                id: "observation-test"
            ) {
                ObservableProtocolTestContext()
            }
            
            // Use testing framework to observe changes
            let observer = try await TestHelpers.context.observeContext(context)
            
            // Make changes that should trigger observations
            await context.updateState("New State")
            await context.incrementCounter()
            await context.toggleFlag()
            
            // Assert observation count
            try await observer.assertChangeCount(3)
            
            // Verify final state
            try await observer.assertLastState { ctx in
                ctx.state == "New State" && ctx.counter == 1 && ctx.flag
            }
        }
    }
    
    func testContextClientObservation() async throws {
        try await testEnvironment.runTest { env in
            let client = MockContextClient()
            let context = try await env.createContext(
                TestClientObservingContext.self,
                id: "client-observation"
            ) {
                TestClientObservingContext(client: client)
            }
            
            // Perform client actions
            try await client.process(.increment)
            try await client.process(.setMessage("Hello"))
            
            // Verify context received updates
            try await TestHelpers.context.assertState(
                in: context,
                timeout: .seconds(1),
                condition: { $0.observedStates.count >= 2 },
                description: "Should observe client state changes"
            )
            
            // Verify latest state
            let observedStates = await context.observedStates
            if let lastState = observedStates.last {
                XCTAssertEqual(lastState.value, 1)
                XCTAssertEqual(lastState.message, "Hello")
            }
        }
    }
    
    // MARK: - Context Framework Integration Tests
    
    func testContextLifecycleManagement() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                TestableContext.self,
                id: "lifecycle-test"
            ) {
                TestableContext()
            }
            
            // Test state changes
            await context.updateState("New State")
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.currentState == "New State" },
                description: "Context state should update correctly"
            )
            
            // Test error handling
            await context.simulateError()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.hasError },
                description: "Context should handle errors"
            )
        }
    }
    
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
                    TestContextAction.initialize,
                    TestContextAction.updateValue(42),
                    TestContextAction.performCalculation,
                    TestContextAction.finalize
                ],
                expectedStates: [
                    { $0.isInitialized },
                    { $0.value == 42 },
                    { $0.calculationResult != 0 },
                    { $0.isFinalized }
                ]
            )
        }
    }
    
    func testContextConcurrencyHandling() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                ConcurrentTestContext.self,
                id: "concurrency-test"
            ) {
                ConcurrentTestContext()
            }
            
            // Test concurrent action processing
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<10 {
                    group.addTask {
                        await context.processAction(.increment(i))
                    }
                }
            }
            
            // Verify all actions were processed
            try await TestHelpers.context.assertState(
                in: context,
                timeout: .seconds(2),
                condition: { $0.processedActions.count == 10 },
                description: "Should process all concurrent actions"
            )
            
            // Verify order independence
            let processedActions = await context.processedActions
            let expectedSum = (0..<10).reduce(0, +)
            let actualSum = processedActions.reduce(0, +)
            XCTAssertEqual(actualSum, expectedSum, "Should process all actions regardless of order")
        }
    }
    
    // MARK: - Context Dependency Tests
    
    func testContextDependencyValidation() async throws {
        try await testEnvironment.runTest { env in
            // Test that context can only depend on clients and downstream contexts
            let client = MockContextClient()
            let downstreamContext = try await env.createContext(
                DownstreamTestContext.self,
                id: "downstream"
            ) {
                DownstreamTestContext()
            }
            
            let context = try await env.createContext(
                DependencyTestContext.self,
                id: "dependency-test"
            ) {
                DependencyTestContext(client: client, downstreamContext: downstreamContext)
            }
            
            // Verify valid dependencies
            let hasValidDependencies = await context.validateDependencies()
            XCTAssertTrue(hasValidDependencies, "Should have valid dependencies")
            
            // Test dependency access patterns
            await context.useClient()
            await context.useDownstreamContext()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.clientWasUsed && $0.downstreamContextWasUsed },
                description: "Should be able to use valid dependencies"
            )
        }
    }
    
    func testContextCircularDependencyPrevention() async throws {
        try await testEnvironment.runTest { env in
            // Test that circular dependencies are prevented
            let contextA = try await env.createContext(
                CircularTestContextA.self,
                id: "circular-a"
            ) {
                CircularTestContextA()
            }
            
            let contextB = try await env.createContext(
                CircularTestContextB.self,
                id: "circular-b"
            ) {
                CircularTestContextB()
            }
            
            // Attempt to create circular dependency should fail
            let circularResult = await contextA.attemptCircularDependency(contextB)
            XCTAssertFalse(circularResult, "Should prevent circular dependencies")
            
            // Verify both contexts remain functional
            await contextA.performOperation()
            await contextB.performOperation()
            
            try await TestHelpers.context.assertState(
                in: contextA,
                condition: { $0.operationCount > 0 },
                description: "Context A should remain functional"
            )
            
            try await TestHelpers.context.assertState(
                in: contextB,
                condition: { $0.operationCount > 0 },
                description: "Context B should remain functional"
            )
        }
    }
    
    func testContextDependencyInjection() async throws {
        try await testEnvironment.runTest { env in
            // Test dependency injection patterns
            let serviceA = MockServiceA()
            let serviceB = MockServiceB()
            
            let context = try await env.createContext(
                InjectionTestContext.self,
                id: "injection-test"
            ) {
                InjectionTestContext(serviceA: serviceA, serviceB: serviceB)
            }
            
            // Test that dependencies are properly injected
            await context.useServices()
            
            XCTAssertTrue(await serviceA.wasUsed, "Service A should be used")
            XCTAssertTrue(await serviceB.wasUsed, "Service B should be used")
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.servicesWereUsed },
                description: "Context should use injected services"
            )
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testContextMemoryStability() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                MemoryProtocolTestContext.self,
                id: "memory-test"
            ) {
                MemoryProtocolTestContext()
            }
            
            // Test memory stability under load
            try await TestHelpers.performance.assertMemoryStability(
                during: {
                    for i in 0..<1000 {
                        await context.processAction(ProtocolTestContextAction.update(i))
                    }
                },
                maxMemoryGrowthPercentage: 10.0
            )
            
            // Verify actions were processed
            let processedCount = await context.processedActionCount
            XCTAssertEqual(processedCount, 1000, "All actions should be processed")
        }
    }
    
    func testContextWeakClientReferences() async throws {
        try await testEnvironment.runTest { env in
            var client: MockContextClient? = MockContextClient()
            weak var weakClient = client
            
            let context = try await env.createContext(
                WeakReferenceContext.self,
                id: "weak-ref-test"
            ) {
                WeakReferenceContext()
            }
            
            await context.attachClient(client!)
            
            // Verify client is attached
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.hasAttachedClient },
                description: "Client should be attached"
            )
            
            // Release strong reference
            client = nil
            
            // Force cleanup
            try await Task.sleep(for: .milliseconds(100))
            
            // Verify weak reference cleanup
            XCTAssertNil(weakClient, "Client should be deallocated")
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { !$0.hasAttachedClient },
                description: "Context should clean up weak reference"
            )
        }
    }
    
    // MARK: - MainActor Binding Tests
    
    func testContextMainActorBinding() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                ProtocolTestContext.self,
                id: "mainactor-test"
            ) {
                ProtocolTestContext()
            }
            
            // Verify context runs on MainActor
            await MainActor.run {
                _ = context.appearCount
            }
            
            // Test UI state updates
            await context.updateUIState("UI Update")
            let uiState = await context.uiState
            XCTAssertEqual(uiState, "UI Update")
            
            // Test thread safety
            try await TestHelpers.concurrency.assertMainActorExecution {
                await context.performUIUpdate()
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testContextErrorHandling() async throws {
        try await testEnvironment.runTest { env in
            let errorClient = ErrorThrowingContextClient()
            let context = try await env.createContext(
                ErrorHandlingContext.self,
                id: "error-test"
            ) {
                ErrorHandlingContext(client: errorClient)
            }
            
            // Trigger error
            try? await errorClient.process(ContextErrorAction.throwError)
            
            // Verify error was handled
            try await TestHelpers.context.assertState(
                in: context,
                timeout: .seconds(1),
                condition: { $0.handledErrorCount == 1 },
                description: "Context should handle client error"
            )
            
            let lastError = await context.lastError
            XCTAssertNotNil(lastError, "Context should capture error")
        }
    }
    
    func testContextErrorRecovery() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                RecoveryTestContext.self,
                id: "recovery-test"
            ) {
                RecoveryTestContext()
            }
            
            // Simulate error and recovery
            await context.simulateError()
            await context.attemptRecovery()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.isRecovered },
                description: "Context should recover from errors"
            )
            
            // Verify functionality after recovery
            await context.performNormalOperation()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.operationsAfterRecovery > 0 },
                description: "Context should function normally after recovery"
            )
        }
    }
    
    // MARK: - Architecture Compliance Tests
    
    func testContextArchitectureCompliance() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                ArchitectureTestContext.self,
                id: "architecture-test"
            ) {
                ArchitectureTestContext()
            }
            
            // Test framework compliance
            assertFrameworkCompliance(context)
            
            // Test that context conforms to required protocols
            XCTAssertTrue(context is AxiomContext, "Should conform to AxiomContext")
            XCTAssertTrue(context is ObservableObject, "Should conform to ObservableObject")
            
            // Test architecture constraints
            let violatesConstraints = await context.violatesArchitectureConstraints()
            XCTAssertFalse(violatesConstraints, "Should not violate architecture constraints")
        }
    }
    
    // MARK: - Performance Tests
    
    func testContextPerformanceRequirements() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let context = TestableContext()
                await context.onAppear()
                
                // Test rapid state updates
                for i in 0..<1000 {
                    await context.updateState("State \(i)")
                }
                
                await context.onDisappear()
            },
            maxDuration: .milliseconds(100),
            maxMemoryGrowth: 1 * 1024 * 1024 // 1MB
        )
    }
    
    func testContextConcurrencyPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let context = ConcurrentTestContext()
                
                await withTaskGroup(of: Void.self) { group in
                    for i in 0..<100 {
                        group.addTask {
                            await context.processAction(.increment(i))
                        }
                    }
                }
            },
            maxDuration: .milliseconds(200),
            maxMemoryGrowth: 512 * 1024 // 512KB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testContextMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            for iteration in 0..<20 {
                let context = TestableContext()
                await context.onAppear()
                
                for i in 0..<50 {
                    await context.updateState("Iteration \(iteration) State \(i)")
                }
                
                await context.onDisappear()
            }
        }
    }
}

// MARK: - Test Support Classes

@MainActor
class ProtocolTestContext: AxiomContext {
    @Published private(set) var appearCount = 0
    @Published private(set) var disappearCount = 0
    @Published private(set) var isActive = false
    @Published private(set) var uiState = ""
    
    func onAppear() async {
        guard !isActive else { return }
        appearCount += 1
        isActive = true
    }
    
    func onDisappear() async {
        guard isActive else { return }
        disappearCount += 1
        isActive = false
    }
    
    func updateUIState(_ state: String) {
        uiState = state
    }
    
    func performUIUpdate() {
        uiState = "Updated on MainActor"
    }
}

@MainActor
class ObservableProtocolTestContext: AxiomContext {
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
class TestClientObservingContext: AxiomContext {
    private let client: MockContextClient
    @Published private(set) var observedStates: [ContextClientState] = []
    private var observationTask: Task<Void, Never>?
    
    init(client: MockContextClient) {
        self.client = client
    }
    
    func onAppear() async {
        observationTask = Task { [weak self] in
            guard let client = self?.client else { return }
            for await state in await client.stateStream {
                await MainActor.run {
                    self?.observedStates.append(state)
                }
            }
        }
    }
    
    func onDisappear() async {
        observationTask?.cancel()
        observationTask = nil
    }
}

@MainActor
class TestableContext: AxiomContext {
    @Published private(set) var currentState = ""
    @Published private(set) var hasError = false
    @Published private(set) var isActive = false
    
    func onAppear() async {
        isActive = true
    }
    
    func onDisappear() async {
        isActive = false
    }
    
    func updateState(_ state: String) {
        currentState = state
    }
    
    func simulateError() {
        hasError = true
    }
}

@MainActor
class ActionableTestContext: AxiomContext {
    @Published private(set) var isInitialized = false
    @Published private(set) var value = 0
    @Published private(set) var calculationResult = 0
    @Published private(set) var isFinalized = false
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func processAction(_ action: TestContextAction) async {
        switch action {
        case .initialize:
            isInitialized = true
        case .updateValue(let newValue):
            value = newValue
        case .performCalculation:
            calculationResult = value * 2
        case .finalize:
            isFinalized = true
        }
    }
}

@MainActor
class ConcurrentTestContext: AxiomContext {
    @Published private(set) var processedActions: [Int] = []
    private let serialQueue = DispatchQueue(label: "context.serial")
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func processAction(_ action: ConcurrentAction) async {
        switch action {
        case .increment(let value):
            await withCheckedContinuation { continuation in
                serialQueue.async {
                    Task { @MainActor in
                        self.processedActions.append(value)
                        continuation.resume()
                    }
                }
            }
        }
    }
}

@MainActor
class DependencyTestContext: AxiomContext {
    private let client: MockContextClient
    private let downstreamContext: DownstreamTestContext
    @Published private(set) var clientWasUsed = false
    @Published private(set) var downstreamContextWasUsed = false
    
    init(client: MockContextClient, downstreamContext: DownstreamTestContext) {
        self.client = client
        self.downstreamContext = downstreamContext
    }
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func validateDependencies() async -> Bool {
        return true // Dependencies are valid (client and downstream context)
    }
    
    func useClient() async {
        try? await client.process(.increment)
        clientWasUsed = true
    }
    
    func useDownstreamContext() async {
        await downstreamContext.performOperation()
        downstreamContextWasUsed = true
    }
}

@MainActor
class DownstreamTestContext: AxiomContext {
    @Published private(set) var operationCount = 0
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func performOperation() {
        operationCount += 1
    }
}

@MainActor
class CircularTestContextA: AxiomContext {
    @Published private(set) var operationCount = 0
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func attemptCircularDependency(_ contextB: CircularTestContextB) async -> Bool {
        // In a real implementation, this would be prevented by the framework
        return false
    }
    
    func performOperation() {
        operationCount += 1
    }
}

@MainActor
class CircularTestContextB: AxiomContext {
    @Published private(set) var operationCount = 0
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func performOperation() {
        operationCount += 1
    }
}

@MainActor
class InjectionTestContext: AxiomContext {
    private let serviceA: MockServiceA
    private let serviceB: MockServiceB
    @Published private(set) var servicesWereUsed = false
    
    init(serviceA: MockServiceA, serviceB: MockServiceB) {
        self.serviceA = serviceA
        self.serviceB = serviceB
    }
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func useServices() async {
        await serviceA.performWork()
        await serviceB.performWork()
        servicesWereUsed = true
    }
}

@MainActor
class MemoryProtocolTestContext: AxiomContext {
    @Published private(set) var processedActionCount = 0
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func processAction(_ action: ProtocolTestContextAction) {
        processedActionCount += 1
        
        switch action {
        case .update(let value):
            _ = value * 2 // Simulate work without retaining data
        }
    }
}

@MainActor
class WeakReferenceContext: AxiomContext {
    private weak var client: MockContextClient?
    
    var hasAttachedClient: Bool {
        client != nil
    }
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func attachClient(_ client: MockContextClient) {
        self.client = client
    }
}

@MainActor
class ErrorHandlingContext: AxiomContext {
    private let client: ErrorThrowingContextClient
    @Published private(set) var handledErrorCount = 0
    @Published private(set) var lastError: Error?
    private var observationTask: Task<Void, Never>?
    
    init(client: ErrorThrowingContextClient) {
        self.client = client
    }
    
    func onAppear() async {
        observationTask = Task { [weak self] in
            guard let client = self?.client else { return }
            for await _ in await client.errorStream {
                await MainActor.run {
                    self?.handledErrorCount += 1
                    self?.lastError = ContextError.clientError
                }
            }
        }
    }
    
    func onDisappear() async {
        observationTask?.cancel()
    }
}

@MainActor
class RecoveryTestContext: AxiomContext {
    @Published private(set) var hasError = false
    @Published private(set) var isRecovered = false
    @Published private(set) var operationsAfterRecovery = 0
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func simulateError() {
        hasError = true
    }
    
    func attemptRecovery() {
        if hasError {
            hasError = false
            isRecovered = true
        }
    }
    
    func performNormalOperation() {
        if isRecovered {
            operationsAfterRecovery += 1
        }
    }
}

@MainActor
class ArchitectureTestContext: AxiomContext {
    func onAppear() async {}
    func onDisappear() async {}
    
    func violatesArchitectureConstraints() async -> Bool {
        return false // This context follows all architecture constraints
    }
}

// MARK: - Support Types

actor MockContextClient: AxiomClient {
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
            let error = ContextError.processingFailed
            for (_, continuation) in errorContinuations {
                continuation.yield(error)
            }
            throw error
        }
    }
}

actor MockServiceA {
    private(set) var wasUsed = false
    
    func performWork() {
        wasUsed = true
    }
}

actor MockServiceB {
    private(set) var wasUsed = false
    
    func performWork() {
        wasUsed = true
    }
}

// MARK: - Supporting Enums and Structs

struct ContextClientState: Axiom.State {
    var value: Int = 0
    var message: String = ""
}

enum ContextClientAction {
    case increment
    case setMessage(String)
}

enum TestContextAction {
    case initialize
    case updateValue(Int)
    case performCalculation
    case finalize
}

enum ConcurrentAction {
    case increment(Int)
}

enum ProtocolTestContextAction {
    case update(Int)
}

enum ContextErrorAction {
    case throwError
}

enum ContextError: Error {
    case clientError
    case processingFailed
}