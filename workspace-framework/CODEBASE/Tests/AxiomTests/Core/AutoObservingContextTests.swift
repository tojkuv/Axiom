import XCTest
import SwiftUI
@testable import Axiom

/// Tests for AutoObservingContext and @Context macro integration
final class AutoObservingContextTests: XCTestCase {
    
    // MARK: - Test Client
    
    /// Mock client for testing
    @MainActor
    final class TestClient: Client {
        typealias StateType = TestState
        typealias ActionType = TestAction
        
        struct TestState: Equatable {
            var value: String = "initial"
            var count: Int = 0
        }
        
        enum TestAction: Sendable {
            case updateValue(String)
            case increment
        }
        
        @Published private(set) var state = TestState()
        
        var stateStream: AsyncStream<TestState> {
            AsyncStream { continuation in
                let cancellable = $state.sink { state in
                    continuation.yield(state)
                }
                continuation.onTermination = { _ in
                    _ = cancellable
                }
            }
        }
        
        func dispatch(_ action: TestAction) async {
            switch action {
            case .updateValue(let value):
                state.value = value
            case .increment:
                state.count += 1
            }
        }
    }
    
    // MARK: - Test Context
    
    /// Example context using @Context macro
    @MainActor
    @Context(observing: TestClient.self)
    final class TestContext: AutoObservingContext<TestClient> {
        private(set) var stateUpdateCount = 0
        private(set) var lastState: TestClient.TestState?
        
        override func handleStateUpdate(_ state: TestClient.TestState) async {
            stateUpdateCount += 1
            lastState = state
            triggerUpdate()
        }
    }
    
    // MARK: - Tests
    
    @MainActor
    func testAutoObservingContextLifecycle() async throws {
        // Create client and context
        let client = TestClient()
        let context = TestContext(client: client)
        
        // Verify initial state
        XCTAssertFalse(context.isActive)
        XCTAssertEqual(context.stateUpdateCount, 0)
        
        // Activate context
        await context.onAppear()
        
        // Verify activation
        XCTAssertTrue(context.isActive)
        
        // Update client state
        await client.dispatch(.updateValue("updated"))
        
        // Allow time for async observation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify state was observed
        XCTAssertEqual(context.stateUpdateCount, 1)
        XCTAssertEqual(context.lastState?.value, "updated")
        
        // Deactivate context
        await context.onDisappear()
        
        // Verify deactivation
        XCTAssertFalse(context.isActive)
        
        // Update client state again
        await client.dispatch(.updateValue("after disappear"))
        
        // Allow time for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify no more updates after deactivation
        XCTAssertEqual(context.stateUpdateCount, 1) // Should not increase
    }
    
    @MainActor
    func testContextBuilder() async throws {
        // Create context using builder
        let client = TestClient()
        var errorHandled = false
        
        let context = ContextBuilder<TestClient>()
            .observing(client)
            .withErrorHandling { error in
                errorHandled = true
                print("Error handled: \(error)")
            }
            .withPerformanceMonitoring(true)
            .build(TestContext.self)
        
        // Verify context was created
        XCTAssertNotNil(context)
        XCTAssertTrue(context.client === client)
        
        // Test context functionality
        await context.onAppear()
        await client.dispatch(.increment)
        
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(context.lastState?.count, 1)
    }
    
    @MainActor
    func testMultipleStateUpdates() async throws {
        let client = TestClient()
        let context = TestContext(client: client)
        
        await context.onAppear()
        
        // Perform multiple updates
        for i in 1...5 {
            await client.dispatch(.updateValue("update \(i)"))
            await client.dispatch(.increment)
        }
        
        // Allow time for all updates
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Verify all updates were observed
        XCTAssertGreaterThanOrEqual(context.stateUpdateCount, 10) // 5 value updates + 5 increments
        XCTAssertEqual(context.lastState?.value, "update 5")
        XCTAssertEqual(context.lastState?.count, 5)
    }
    
    @MainActor
    func testIdempotentActivation() async throws {
        let client = TestClient()
        let context = TestContext(client: client)
        
        // Activate multiple times
        await context.onAppear()
        await context.onAppear()
        await context.onAppear()
        
        // Update state once
        await client.dispatch(.updateValue("single update"))
        
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Should only observe once despite multiple appearances
        XCTAssertEqual(context.stateUpdateCount, 1)
    }
}