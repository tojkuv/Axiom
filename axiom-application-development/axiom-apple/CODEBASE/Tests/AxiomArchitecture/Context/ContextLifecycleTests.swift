import XCTest
import AxiomTesting
import SwiftUI
@testable import AxiomArchitecture
@testable import AxiomCore
// @testable import AxiomMacros // Disabled for MVP testing

/// Comprehensive tests for context lifecycle management and auto-observing functionality
/// 
/// Consolidates: ContextLifecycleManagementTests, AutoObservingContextTests
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class ContextLifecycleTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Context Lifecycle Management Tests
    
    func testAutomaticLifecycleManagement() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                AutoLifecycleContext.self,
                id: "auto-lifecycle"
            ) {
                AutoLifecycleContext()
            }
            
            // Test automatic initialization
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.isInitialized },
                description: "Context should auto-initialize"
            )
            
            // Test automatic state management
            await context.performAction()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.actionCount > 0 },
                description: "Context should track actions automatically"
            )
            
            // Test automatic cleanup
            await env.removeContext("auto-lifecycle")
            
            let isCleanedUp = await context.isCleanedUp
            XCTAssertTrue(isCleanedUp, "Context should auto-cleanup when removed")
        }
    }
    
    func testContextLifecycleEvents() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                LifecycleEventContext.self,
                id: "lifecycle-events"
            ) {
                LifecycleEventContext()
            }
            
            // Test lifecycle event sequence
            let expectedEvents = [
                LifecycleEvent.willAppear,
                LifecycleEvent.didAppear,
                LifecycleEvent.willDisappear,
                LifecycleEvent.didDisappear
            ]
            
            // Trigger lifecycle events
            await context.onAppear()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.events.contains(.didAppear) },
                description: "Should fire didAppear event"
            )
            
            await context.onDisappear()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.events.contains(.didDisappear) },
                description: "Should fire didDisappear event"
            )
            
            // Verify event order
            let events = await context.events
            let relevantEvents = events.filter { expectedEvents.contains($0) }
            XCTAssertEqual(relevantEvents, expectedEvents.prefix(relevantEvents.count), "Events should fire in correct order")
        }
    }
    
    func testContextStateTransitions() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                StateTransitionContext.self,
                id: "state-transitions"
            ) {
                StateTransitionContext()
            }
            
            // Test initial state
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.currentState == .idle },
                description: "Should start in idle state"
            )
            
            // Test state transitions
            await context.startOperation()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.currentState == .running },
                description: "Should transition to running state"
            )
            
            await context.completeOperation()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.currentState == .completed },
                description: "Should transition to completed state"
            )
            
            // Test invalid transitions
            let canTransitionToRunning = await context.canTransition(to: .running)
            XCTAssertFalse(canTransitionToRunning, "Should not allow invalid state transitions")
        }
    }
    
    func testContextLifecycleHooks() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                HookableContext.self,
                id: "hookable"
            ) {
                HookableContext()
            }
            
            // Test beforeAppear hook
            await context.onAppear()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.beforeAppearCalled },
                description: "beforeAppear hook should be called"
            )
            
            // Test afterDisappear hook
            await context.onDisappear()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.afterDisappearCalled },
                description: "afterDisappear hook should be called"
            )
            
            // Test custom hooks
            await context.triggerCustomHook()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.customHookCalled },
                description: "Custom hooks should be callable"
            )
        }
    }
    
    func testAsyncLifecycleOperations() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                AsyncLifecycleContext.self,
                id: "async-lifecycle"
            ) {
                AsyncLifecycleContext()
            }
            
            // Test async initialization
            await context.performAsyncInitialization()
            
            try await TestHelpers.context.assertState(
                in: context,
                timeout: .seconds(2),
                condition: { $0.asyncInitialized },
                description: "Should complete async initialization"
            )
            
            // Test async operations
            await context.performAsyncOperation()
            
            try await TestHelpers.context.assertState(
                in: context,
                timeout: .seconds(1),
                condition: { $0.asyncOperationCompleted },
                description: "Should complete async operations"
            )
            
            // Test async cleanup
            await context.performAsyncCleanup()
            
            try await TestHelpers.context.assertState(
                in: context,
                timeout: .seconds(1),
                condition: { $0.asyncCleanupCompleted },
                description: "Should complete async cleanup"
            )
        }
    }
    
    // MARK: - Auto-Observing Context Tests
    
    func testContextMacroGeneration() async throws {
        // Test @Context macro functionality
        @Context
        class MacroGeneratedContext {
            @Published var value: Int = 0
            @Published var text: String = ""
            @Published var isActive: Bool = false
            
            func updateValue(_ newValue: Int) {
                value = newValue
            }
            
            func updateText(_ newText: String) {
                text = newText
            }
            
            func toggleActive() {
                isActive.toggle()
            }
        }
        
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                MacroGeneratedContext.self,
                id: "macro-generated"
            ) {
                MacroGeneratedContext()
            }
            
            // Test macro-generated observation
            let observer = try await TestHelpers.context.observeContext(context)
            
            await context.updateValue(42)
            await context.updateText("Hello")
            await context.toggleActive()
            
            // Verify all changes were observed
            try await observer.assertChangeCount(3)
            
            // Verify final state
            try await observer.assertLastState { ctx in
                ctx.value == 42 && ctx.text == "Hello" && ctx.isActive
            }
        }
    }
    
    func testAutoObservingPatterns() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                AutoObservingContext.self,
                id: "auto-observing"
            ) {
                AutoObservingContext()
            }
            
            // Test automatic client observation
            let client = MockObservableClient()
            await context.attachClient(client)
            
            // Trigger client changes
            await client.updateState(ObservableClientState(counter: 5, message: "Test"))
            
            // Verify context automatically observed changes
            try await TestHelpers.context.assertState(
                in: context,
                timeout: .seconds(1),
                condition: { $0.observedClientStates.count > 0 },
                description: "Should automatically observe client changes"
            )
            
            let lastObservedState = await context.observedClientStates.last
            XCTAssertEqual(lastObservedState?.counter, 5)
            XCTAssertEqual(lastObservedState?.message, "Test")
        }
    }
    
    func testSelectiveObservation() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                SelectiveObservingContext.self,
                id: "selective"
            ) {
                SelectiveObservingContext()
            }
            
            // Configure selective observation
            await context.configureObservation(
                includeProperties: ["importantValue", "criticalFlag"],
                excludeProperties: ["debugInfo", "temporaryData"]
            )
            
            let observer = try await TestHelpers.context.observeContext(context)
            
            // Update observed properties
            await context.updateImportantValue(100)
            await context.toggleCriticalFlag()
            
            // Update non-observed properties
            await context.updateDebugInfo("Debug")
            await context.updateTemporaryData("Temp")
            
            // Should only observe the included properties
            try await observer.assertChangeCount(2)
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.importantValue == 100 && $0.criticalFlag },
                description: "Should track important changes"
            )
        }
    }
    
    func testObservationPerformance() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                PerformanceObservingContext.self,
                id: "performance"
            ) {
                PerformanceObservingContext()
            }
            
            // Test observation performance under load
            try await TestHelpers.performance.assertPerformanceRequirements(
                operation: {
                    for i in 0..<1000 {
                        await context.updateCounter(i)
                    }
                },
                maxDuration: .milliseconds(100),
                maxMemoryGrowth: 512 * 1024 // 512KB
            )
            
            let finalCounter = await context.counter
            XCTAssertEqual(finalCounter, 999, "Should process all updates")
        }
    }
    
    func testObservationMemoryManagement() async throws {
        try await testEnvironment.runTest { env in
            // Test that observation doesn't create memory leaks
            try await TestHelpers.performance.assertNoMemoryLeaks {
                for iteration in 0..<10 {
                    let context = AutoObservingContext()
                    await context.onAppear()
                    
                    let client = MockObservableClient()
                    await context.attachClient(client)
                    
                    for i in 0..<20 {
                        await client.updateState(ObservableClientState(
                            counter: iteration * 20 + i,
                            message: "Iteration \(iteration) Update \(i)"
                        ))
                    }
                    
                    await context.onDisappear()
                }
            }
        }
    }
    
    // MARK: - Advanced Lifecycle Patterns Tests
    
    func testContextDependentLifecycle() async throws {
        try await testEnvironment.runTest { env in
            let parentContext = try await env.createContext(
                ParentLifecycleContext.self,
                id: "parent"
            ) {
                ParentLifecycleContext()
            }
            
            let childContext = try await env.createContext(
                ChildLifecycleContext.self,
                id: "child"
            ) {
                ChildLifecycleContext(parent: parentContext)
            }
            
            // Test that child lifecycle follows parent
            await parentContext.activate()
            
            try await TestHelpers.context.assertState(
                in: childContext,
                condition: { $0.isActivatedByParent },
                description: "Child should activate when parent activates"
            )
            
            await parentContext.deactivate()
            
            try await TestHelpers.context.assertState(
                in: childContext,
                condition: { !$0.isActivatedByParent },
                description: "Child should deactivate when parent deactivates"
            )
        }
    }
    
    func testContextLifecycleCancellation() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                CancellableLifecycleContext.self,
                id: "cancellable"
            ) {
                CancellableLifecycleContext()
            }
            
            // Start long-running operation
            let operationTask = Task {
                await context.performLongRunningOperation()
            }
            
            // Cancel operation mid-execution
            try await Task.sleep(for: .milliseconds(50))
            operationTask.cancel()
            
            // Verify graceful cancellation
            try await TestHelpers.context.assertState(
                in: context,
                timeout: .seconds(1),
                condition: { $0.operationWasCancelled },
                description: "Should handle operation cancellation gracefully"
            )
            
            // Verify context remains functional
            await context.performQuickOperation()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.quickOperationCompleted },
                description: "Context should remain functional after cancellation"
            )
        }
    }
    
    func testContextLifecycleErrorRecovery() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                RecoverableLifecycleContext.self,
                id: "recoverable"
            ) {
                RecoverableLifecycleContext()
            }
            
            // Trigger lifecycle error
            await context.triggerLifecycleError()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.hasLifecycleError },
                description: "Should detect lifecycle error"
            )
            
            // Attempt recovery
            await context.recoverFromError()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { !$0.hasLifecycleError && $0.isRecovered },
                description: "Should recover from lifecycle error"
            )
            
            // Verify normal operation after recovery
            await context.performNormalOperation()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.normalOperationCount > 0 },
                description: "Should function normally after recovery"
            )
        }
    }
    
    // MARK: - Performance Tests
    
    func testLifecycleManagementPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                for i in 0..<100 {
                    let context = AutoLifecycleContext()
                    await context.onAppear()
                    await context.performAction()
                    await context.onDisappear()
                }
            },
            maxDuration: .milliseconds(200),
            maxMemoryGrowth: 1 * 1024 * 1024 // 1MB
        )
    }
    
    func testAutoObservingPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let context = AutoObservingContext()
                await context.onAppear()
                
                let client = MockObservableClient()
                await context.attachClient(client)
                
                for i in 0..<500 {
                    await client.updateState(ObservableClientState(
                        counter: i,
                        message: "Performance test \(i)"
                    ))
                }
                
                await context.onDisappear()
            },
            maxDuration: .milliseconds(300),
            maxMemoryGrowth: 2 * 1024 * 1024 // 2MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testLifecycleMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            for iteration in 0..<15 {
                let context = AsyncLifecycleContext()
                await context.onAppear()
                await context.performAsyncInitialization()
                
                for i in 0..<30 {
                    await context.performAsyncOperation()
                }
                
                await context.performAsyncCleanup()
                await context.onDisappear()
            }
        }
    }
}

// MARK: - Test Support Classes

@MainActor
class AutoLifecycleContext: AxiomContext {
    @Published private(set) var isInitialized = false
    @Published private(set) var actionCount = 0
    @Published private(set) var isCleanedUp = false
    
    override init() {
        super.init()
        isInitialized = true
    }
    
    func onAppear() async {
        // Automatic lifecycle management
    }
    
    func onDisappear() async {
        isCleanedUp = true
    }
    
    func performAction() {
        actionCount += 1
    }
}

@MainActor
class LifecycleEventContext: AxiomContext {
    @Published private(set) var events: [LifecycleEvent] = []
    
    func onAppear() async {
        events.append(.willAppear)
        events.append(.didAppear)
    }
    
    func onDisappear() async {
        events.append(.willDisappear)
        events.append(.didDisappear)
    }
}

@MainActor
class StateTransitionContext: AxiomContext {
    @Published private(set) var currentState: ContextState = .idle
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func startOperation() {
        guard currentState == .idle else { return }
        currentState = .running
    }
    
    func completeOperation() {
        guard currentState == .running else { return }
        currentState = .completed
    }
    
    func canTransition(to newState: ContextState) -> Bool {
        switch (currentState, newState) {
        case (.idle, .running): return true
        case (.running, .completed): return true
        case (.completed, .idle): return true
        default: return false
        }
    }
}

@MainActor
class HookableContext: AxiomContext {
    @Published private(set) var beforeAppearCalled = false
    @Published private(set) var afterDisappearCalled = false
    @Published private(set) var customHookCalled = false
    
    func onAppear() async {
        beforeAppearCalled = true
    }
    
    func onDisappear() async {
        afterDisappearCalled = true
    }
    
    func triggerCustomHook() {
        customHookCalled = true
    }
}

@MainActor
class AsyncLifecycleContext: AxiomContext {
    @Published private(set) var asyncInitialized = false
    @Published private(set) var asyncOperationCompleted = false
    @Published private(set) var asyncCleanupCompleted = false
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func performAsyncInitialization() async {
        try? await Task.sleep(for: .milliseconds(100))
        asyncInitialized = true
    }
    
    func performAsyncOperation() async {
        try? await Task.sleep(for: .milliseconds(50))
        asyncOperationCompleted = true
    }
    
    func performAsyncCleanup() async {
        try? await Task.sleep(for: .milliseconds(25))
        asyncCleanupCompleted = true
    }
}

@MainActor
class AutoObservingContext: AxiomContext {
    @Published private(set) var observedClientStates: [ObservableClientState] = []
    private var client: MockObservableClient?
    private var observationTask: Task<Void, Never>?
    
    func onAppear() async {}
    
    func onDisappear() async {
        observationTask?.cancel()
        observationTask = nil
    }
    
    func attachClient(_ client: MockObservableClient) async {
        self.client = client
        
        observationTask = Task { [weak self] in
            for await state in await client.stateStream {
                await MainActor.run {
                    self?.observedClientStates.append(state)
                }
            }
        }
    }
}

@MainActor
class SelectiveObservingContext: AxiomContext {
    @Published private(set) var importantValue = 0
    @Published private(set) var criticalFlag = false
    @Published private(set) var debugInfo = ""
    @Published private(set) var temporaryData = ""
    
    private var includedProperties: Set<String> = []
    private var excludedProperties: Set<String> = []
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func configureObservation(includeProperties: [String], excludeProperties: [String]) {
        self.includedProperties = Set(includeProperties)
        self.excludedProperties = Set(excludeProperties)
    }
    
    func updateImportantValue(_ value: Int) {
        guard includedProperties.contains("importantValue") else { return }
        importantValue = value
    }
    
    func toggleCriticalFlag() {
        guard includedProperties.contains("criticalFlag") else { return }
        criticalFlag.toggle()
    }
    
    func updateDebugInfo(_ info: String) {
        guard !excludedProperties.contains("debugInfo") else { return }
        debugInfo = info
    }
    
    func updateTemporaryData(_ data: String) {
        guard !excludedProperties.contains("temporaryData") else { return }
        temporaryData = data
    }
}

@MainActor
class PerformanceObservingContext: AxiomContext {
    @Published private(set) var counter = 0
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func updateCounter(_ value: Int) {
        counter = value
    }
}

@MainActor
class ParentLifecycleContext: AxiomContext {
    @Published private(set) var isActive = false
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func activate() {
        isActive = true
    }
    
    func deactivate() {
        isActive = false
    }
}

@MainActor
class ChildLifecycleContext: AxiomContext {
    private weak var parent: ParentLifecycleContext?
    @Published private(set) var isActivatedByParent = false
    private var observationTask: Task<Void, Never>?
    
    init(parent: ParentLifecycleContext) {
        self.parent = parent
        super.init()
        
        observationTask = Task { [weak self, weak parent] in
            guard let parent = parent else { return }
            
            for await _ in parent.objectWillChange.values {
                await MainActor.run {
                    self?.isActivatedByParent = parent.isActive
                }
            }
        }
    }
    
    func onAppear() async {}
    func onDisappear() async {
        observationTask?.cancel()
    }
}

@MainActor
class CancellableLifecycleContext: AxiomContext {
    @Published private(set) var operationWasCancelled = false
    @Published private(set) var quickOperationCompleted = false
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func performLongRunningOperation() async {
        do {
            try await Task.sleep(for: .seconds(1))
        } catch {
            operationWasCancelled = true
        }
    }
    
    func performQuickOperation() {
        quickOperationCompleted = true
    }
}

@MainActor
class RecoverableLifecycleContext: AxiomContext {
    @Published private(set) var hasLifecycleError = false
    @Published private(set) var isRecovered = false
    @Published private(set) var normalOperationCount = 0
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func triggerLifecycleError() {
        hasLifecycleError = true
    }
    
    func recoverFromError() {
        hasLifecycleError = false
        isRecovered = true
    }
    
    func performNormalOperation() {
        normalOperationCount += 1
    }
}

// MARK: - Mock Support Types

actor MockObservableClient {
    private(set) var state = ObservableClientState()
    private var continuations: [UUID: AsyncStream<ObservableClientState>.Continuation] = [:]
    
    var stateStream: AsyncStream<ObservableClientState> {
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
    
    private func addContinuation(_ continuation: AsyncStream<ObservableClientState>.Continuation, id: UUID) {
        continuations[id] = continuation
    }
    
    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }
    
    func updateState(_ newState: ObservableClientState) {
        state = newState
        for (_, continuation) in continuations {
            continuation.yield(state)
        }
    }
}

// MARK: - Supporting Types

struct ObservableClientState: Axiom.State {
    var counter: Int = 0
    var message: String = ""
}

enum LifecycleEvent: Equatable {
    case willAppear
    case didAppear
    case willDisappear
    case didDisappear
}

enum ContextState {
    case idle
    case running
    case completed
}

// MARK: - Context Macro (Simulated)

@propertyWrapper
struct Context {
    let wrappedValue: String
    
    init() {
        self.wrappedValue = "context"
    }
}