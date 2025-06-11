import XCTest
import SwiftUI
@testable import Axiom

final class ContextProtocolTests: XCTestCase {
    
    // MARK: - Lifecycle Tests
    
    func testContextLifecycleMethods() async throws {
        // Test that context lifecycle methods are called appropriately
        let context = await ProtocolTestContext()
        
        // Test onAppear
        await context.onAppear()
        let appearCount = await context.appearCount
        XCTAssertEqual(appearCount, 1, "onAppear should be called once")
        
        // Test multiple onAppear calls (should be idempotent)
        await context.onAppear()
        let appearCount2 = await context.appearCount
        XCTAssertEqual(appearCount2, 1, "onAppear should be idempotent")
        
        // Test onDisappear
        await context.onDisappear()
        let disappearCount = await context.disappearCount
        XCTAssertEqual(disappearCount, 1, "onDisappear should be called once")
        
        // Test lifecycle state
        let isActive = await context.isActive
        XCTAssertFalse(isActive, "Context should be inactive after onDisappear")
    }
    
    // MARK: - Observation Tests
    
    func testContextObservationPatterns() async throws {
        // Requirement: MainActor-bound coordinator with observation
        let context = await ObservableProtocolTestContext()
        
        // Set up observation
        var observedChanges = 0
        let cancellable = context.objectWillChange.sink { _ in
            observedChanges += 1
        }
        
        // Make changes that should trigger observations
        await context.updateState("New State")
        await context.incrementCounter()
        await context.toggleFlag()
        
        // Give time for observations to propagate
        try await Task.sleep(for: .milliseconds(10))
        
        // Verify observations
        XCTAssertEqual(observedChanges, 3, "Should observe 3 changes")
        
        // Verify state
        let state = await context.state
        let counter = await context.counter
        let flag = await context.flag
        
        XCTAssertEqual(state, "New State")
        XCTAssertEqual(counter, 1)
        XCTAssertTrue(flag)
        
        cancellable.cancel()
    }
    
    // MARK: - Client Observation Tests
    
    func testContextClientObservation() async throws {
        // Test that context can observe client state changes
        let client = MockContextClient()
        let context = await ClientObservingContext(client: client)
        
        await context.onAppear()
        
        // Perform client actions
        try await client.process(.increment)
        try await client.process(.setMessage("Hello"))
        
        // Give time for state propagation
        try await Task.sleep(for: .milliseconds(10))
        
        // Verify context received updates
        let observedStates = await context.observedStates
        XCTAssertGreaterThanOrEqual(observedStates.count, 2, "Should observe at least 2 state changes")
        
        // Verify latest state
        if let lastState = observedStates.last {
            XCTAssertEqual(lastState.value, 1)
            XCTAssertEqual(lastState.message, "Hello")
        }
        
        await context.onDisappear()
    }
    
    // MARK: - Memory Management Tests
    
    func testContextMemoryStability() async throws {
        // Requirement: Memory usage remains stable (±10%) after processing 1000 actions
        let context = await MemoryProtocolTestContext()
        
        // Measure initial memory
        let initialMemory = await context.currentMemoryUsage()
        
        // Process 1000 actions
        for i in 0..<1000 {
            await context.processAction(ProtocolTestContextAction.update(i))
        }
        
        // Measure final memory
        let finalMemory = await context.currentMemoryUsage()
        
        // Calculate percentage change
        let percentageChange = abs(Double(finalMemory - initialMemory)) / Double(initialMemory) * 100
        
        XCTAssertLessThanOrEqual(percentageChange, 10.0, "Memory usage should remain stable within 10%")
        
        // Verify actions were processed
        let processedCount = await context.processedActionCount
        XCTAssertEqual(processedCount, 1000, "All actions should be processed")
    }
    
    // MARK: - Weak Reference Tests
    
    func testContextWeakClientReferences() async throws {
        // Test that context holds weak references to prevent retain cycles
        var client: MockContextClient? = MockContextClient()
        weak var weakClient = client
        
        let context = await WeakReferenceContext()
        await context.attachClient(client!)
        
        // Verify client is attached
        let hasClient = await context.hasAttachedClient
        XCTAssertTrue(hasClient, "Client should be attached")
        
        // Release strong reference
        client = nil
        
        // Force cleanup
        try await Task.sleep(for: .milliseconds(10))
        
        // Verify weak reference is nil
        XCTAssertNil(weakClient, "Client should be deallocated")
        
        // Verify context cleaned up
        let hasClientAfter = await context.hasAttachedClient
        XCTAssertFalse(hasClientAfter, "Context should clean up weak reference")
    }
    
    // MARK: - MainActor Binding Tests
    
    func testContextMainActorBinding() async throws {
        // Verify context runs on MainActor
        let context = await ProtocolTestContext()
        
        // This should compile and run on MainActor
        await MainActor.run {
            // Direct property access should work on MainActor
            _ = context.appearCount
        }
        
        // Verify we can update UI-related properties
        await context.updateUIState("UI Update")
        let uiState = await context.uiState
        XCTAssertEqual(uiState, "UI Update")
    }
    
    // MARK: - Error Handling Tests
    
    func testContextErrorHandling() async throws {
        // Test that context handles client errors appropriately
        let errorClient = ErrorThrowingContextClient()
        let context = await ErrorHandlingContext(client: errorClient)
        
        await context.onAppear()
        
        // Trigger error
        try? await errorClient.process(ContextErrorAction.throwError)
        
        // Give time for error propagation
        try await Task.sleep(for: .milliseconds(10))
        
        // Verify error was handled
        let errorCount = await context.handledErrorCount
        XCTAssertEqual(errorCount, 1, "Context should handle client error")
        
        let lastError = await context.lastError
        XCTAssertNotNil(lastError, "Context should capture error")
    }
}

// MARK: - Test Support Types

// Basic test context
@MainActor
class ProtocolTestContext: Context {
    private(set) var appearCount = 0
    private(set) var disappearCount = 0
    private(set) var isActive = false
    private(set) var uiState = ""
    
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
}

// Observable context for testing observation
@MainActor
class ObservableProtocolTestContext: Context {
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

// Context that observes a client
@MainActor
class ClientObservingContext: Context {
    private let client: MockContextClient
    private(set) var observedStates: [ContextClientState] = []
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

// Memory test context
@MainActor
class MemoryProtocolTestContext: Context {
    private var actions: [ProtocolTestContextAction] = []
    private(set) var processedActionCount = 0
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func processAction(_ action: ProtocolTestContextAction) {
        // Process but don't store to test memory stability
        processedActionCount += 1
        
        // Simulate some work
        switch action {
        case .update(let value):
            _ = value * 2
        }
    }
    
    func currentMemoryUsage() -> Int {
        // Simplified memory measurement
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
}

// Weak reference test context
@MainActor
class WeakReferenceContext: Context {
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

// Error handling context
@MainActor
class ErrorHandlingContext: Context {
    private let client: ErrorThrowingContextClient
    private(set) var handledErrorCount = 0
    private(set) var lastError: Error?
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

// Test client for context observation
actor MockContextClient: Client {
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

// Error throwing client
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

// Supporting types
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

enum ContextError: Error {
    case clientError
    case processingFailed
}

