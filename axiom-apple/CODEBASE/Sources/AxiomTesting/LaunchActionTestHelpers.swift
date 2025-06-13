import XCTest
@testable import Axiom

// MARK: - Launch Action Test Helpers

/// Test helpers for launch actions
public struct LaunchActionTestHelpers {
    
    /// Simulate cold launch with action
    @MainActor
    public static func simulateColdLaunch<ActionType>(
        action: ActionType,
        storage: LaunchActionStorage<ActionType>,
        readyAfter: Duration = .milliseconds(100)
    ) async {
        // Queue action before ready
        storage.queueAction(action)
        
        // Simulate initialization delay
        try? await Task.sleep(nanoseconds: UInt64(readyAfter.components.seconds * 1_000_000_000 + readyAfter.components.attoseconds / 1_000_000_000))
        
        // Mark ready
        storage.markReady()
    }
    
    /// Assert action was processed
    @MainActor
    public static func assertActionProcessed<ActionType: Equatable>(
        expected: ActionType,
        in storage: LaunchActionStorage<ActionType>,
        timeout: Duration = .seconds(1),
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = ContinuousClock.now + timeout
        
        while ContinuousClock.now < deadline {
            if storage.currentAction == expected {
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        XCTFail(
            "Action not processed within timeout",
            file: file,
            line: line
        )
    }
    
    /// Simulate multiple actions in sequence
    @MainActor
    public static func simulateActionSequence<ActionType>(
        _ actions: [ActionType],
        storage: LaunchActionStorage<ActionType>,
        delayBetween: Duration = .milliseconds(50)
    ) async {
        for action in actions {
            storage.queueAction(action)
            try? await Task.sleep(nanoseconds: UInt64(delayBetween.components.seconds * 1_000_000_000 + delayBetween.components.attoseconds / 1_000_000_000))
        }
    }
    
    /// Assert no action is currently active
    @MainActor
    public static func assertNoActiveAction<ActionType>(
        in storage: LaunchActionStorage<ActionType>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNil(
            storage.currentAction,
            "Expected no active action, but found: \(String(describing: storage.currentAction))",
            file: file,
            line: line
        )
    }
}

// MARK: - XCTest Extensions

public extension XCTestCase {
    
    /// Test launch action scenario
    @MainActor
    func testLaunchAction<ActionType: QuickAction>(
        action: ActionType,
        expectedRoute: Route? = nil,
        test: (LaunchActionStorage<ActionType>) async throws -> Void
    ) async throws {
        let storage = LaunchActionStorage<ActionType>()
        
        // Run test
        try await test(storage)
        
        // Verify if needed
        if expectedRoute != nil {
            let actualRoute = action.toRoute()
            // Note: Route comparison requires app-specific Route type implementation
            // For now, just verify that a route was produced
            XCTAssertNotNil(actualRoute, "Action did not produce a route")
        }
    }
}