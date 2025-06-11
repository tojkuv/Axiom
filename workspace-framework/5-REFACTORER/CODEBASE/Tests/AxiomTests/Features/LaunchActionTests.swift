import XCTest
import SwiftUI
@testable import Axiom
import AxiomTesting

// Test action type for launch scenarios
struct TestQuickAction: QuickAction, Equatable {
    let identifier: String
    let value: String
    
    func toRoute() -> Route? {
        nil
    }
}

final class LaunchActionTests: XCTestCase {
    
    // MARK: - Property Wrapper Tests
    
    @MainActor
    func testLaunchActionPropertyWrapper() async throws {
        // Given: A launch action property wrapper
        @LaunchAction var pendingAction: TestQuickAction?
        
        // When: Setting an action before app is ready
        let testAction = TestQuickAction(identifier: "test.action", value: "test")
        pendingAction = testAction
        
        // Then: Action should be queued, not immediately available
        XCTAssertNil($pendingAction.currentAction)
        
        // When: Marking app as ready
        $pendingAction.markReady()
        
        // Then: Action should become available
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual($pendingAction.currentAction, testAction)
    }
    
    @MainActor
    func testMultipleActionsQueuing() async throws {
        // Given: A launch action storage
        let storage = LaunchActionStorage<TestQuickAction>()
        
        // When: Queuing multiple actions before ready
        let action1 = TestQuickAction(identifier: "test.1", value: "first")
        let action2 = TestQuickAction(identifier: "test.2", value: "second")
        let action3 = TestQuickAction(identifier: "test.3", value: "third")
        
        storage.queueAction(action1)
        storage.queueAction(action2)
        storage.queueAction(action3)
        
        // Then: No action should be current yet
        XCTAssertNil(storage.currentAction)
        
        // When: Marking ready
        storage.markReady()
        
        // Then: First action should be processed immediately
        XCTAssertEqual(storage.currentAction, action1)
        
        // And: Subsequent actions should be processed with delay
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(storage.currentAction, action2)
        
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(storage.currentAction, action3)
    }
    
    @MainActor
    func testActionProcessingWhenAlreadyReady() async throws {
        // Given: A ready launch action storage
        let storage = LaunchActionStorage<TestQuickAction>()
        storage.markReady()
        
        // When: Queueing an action after ready
        let action = TestQuickAction(identifier: "test.immediate", value: "now")
        storage.queueAction(action)
        
        // Then: Action should be immediately available
        XCTAssertEqual(storage.currentAction, action)
    }
    
    @MainActor
    func testClearAction() async throws {
        // Given: A storage with current action
        let storage = LaunchActionStorage<TestQuickAction>()
        storage.markReady()
        
        let action = TestQuickAction(identifier: "test.clear", value: "clear")
        storage.queueAction(action)
        
        XCTAssertNotNil(storage.currentAction)
        
        // When: Clearing the action
        storage.clearAction()
        
        // Then: Current action should be nil
        XCTAssertNil(storage.currentAction)
    }
    
    // MARK: - Cold Launch Tests
    
    @MainActor
    func testColdLaunchSimulation() async throws {
        // Given: A cold launch scenario with action
        let storage = LaunchActionStorage<TestQuickAction>()
        let launchAction = TestQuickAction(identifier: "test.cold", value: "cold-launch")
        
        // When: Action is queued before app is ready (simulating cold launch)
        storage.queueAction(launchAction)
        
        // Then: Action should not be processed yet
        XCTAssertNil(storage.currentAction)
        
        // When: Simulating app initialization delay
        try await Task.sleep(for: .milliseconds(200))
        storage.markReady()
        
        // Then: Action should be processed after marking ready
        XCTAssertEqual(storage.currentAction, launchAction)
    }
    
    @MainActor
    func testURLLaunchAction() async throws {
        // Given: A URL launch action
        let url = URL(string: "myapp://task/123")!
        let urlAction = URLLaunchAction(url: url)
        
        // Then: Should have correct properties
        XCTAssertEqual(urlAction.identifier, "com.app.url")
        XCTAssertEqual(urlAction.url, url)
        XCTAssertNil(urlAction.toRoute()) // No parser implemented yet
    }
    
    // MARK: - Test Helpers
    
    @MainActor
    func testLaunchActionTestHelpers() async throws {
        // Given: A storage for testing
        let storage = LaunchActionStorage<TestQuickAction>()
        let action = TestQuickAction(identifier: "test.helper", value: "helper")
        
        // When: Using test helper to simulate cold launch
        await LaunchActionTestHelpers.simulateColdLaunch(
            action: action,
            storage: storage,
            readyAfter: .milliseconds(50)
        )
        
        // Then: Action should be processed
        await LaunchActionTestHelpers.assertActionProcessed(
            expected: action,
            in: storage,
            timeout: .seconds(1)
        )
    }
    
    // MARK: - Quick Action Tests
    
    func testCommonQuickActions() async throws {
        // Given: Common quick action types
        let createAction = CommonQuickAction.create
        let searchAction = CommonQuickAction.search
        let recentAction = CommonQuickAction.recent
        
        // Then: Should have correct identifiers
        XCTAssertEqual(createAction.identifier, "com.app.create")
        XCTAssertEqual(searchAction.identifier, "com.app.search")
        XCTAssertEqual(recentAction.identifier, "com.app.recent")
        
        // And: Should return nil routes by default
        XCTAssertNil(createAction.toRoute())
        XCTAssertNil(searchAction.toRoute())
        XCTAssertNil(recentAction.toRoute())
    }
    
    #if canImport(UIKit)
    @MainActor
    func testUIApplicationDelegateIntegration() async throws {
        // Given: A mock app delegate
        let delegate = MockAppDelegate()
        let storage = LaunchActionStorage<CommonQuickAction>()
        
        // When: Processing a shortcut item
        let shortcut = UIApplicationShortcutItem(
            type: "com.app.create",
            localizedTitle: "Create"
        )
        delegate.processShortcutItem(shortcut, with: storage)
        
        // Then: Action should be queued
        storage.markReady()
        XCTAssertEqual(storage.currentAction, CommonQuickAction.create)
    }
    #endif
}

#if canImport(UIKit)
import UIKit

// Mock app delegate for testing
private class MockAppDelegate: NSObject, UIApplicationDelegate {}
#endif