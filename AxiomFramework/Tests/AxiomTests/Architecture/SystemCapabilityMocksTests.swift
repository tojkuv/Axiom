import XCTest
@testable import Axiom

final class SystemCapabilityMocksTests: XCTestCase {
    
    // Test base mock capability infrastructure
    func testBaseMockCapability() async throws {
        // Given: A base mock capability
        let mockCapability = BaseMockCapability()
        
        // When: Initialized
        try await mockCapability.initialize()
        
        // Then: Should be available
        let isAvailable = await mockCapability.isAvailable
        XCTAssertTrue(isAvailable)
        
        // And: Should track state transitions
        let initialState = await mockCapability.state
        XCTAssertEqual(initialState, .available)
        
        // When: Terminated
        await mockCapability.terminate()
        
        // Then: Should be unavailable
        let finalState = await mockCapability.state
        XCTAssertEqual(finalState, .unavailable)
    }
    
    // Test error simulation
    func testErrorSimulation() async throws {
        // Given: A mock capability with simulated error
        let mockCapability = BaseMockCapability()
        let testError = TestError.simulated
        await mockCapability.simulateError(testError)
        
        // When: Attempting to initialize
        // Then: Should throw the simulated error
        do {
            try await mockCapability.initialize()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, testError)
        }
    }
    
    // Test state transitions
    func testStateTransitions() async throws {
        // Given: A base mock capability
        let mockCapability = BaseMockCapability()
        
        // When: Transitioning through states
        await mockCapability.transitionTo(.unknown)
        var state = await mockCapability.state
        XCTAssertEqual(state, .unknown)
        
        await mockCapability.transitionTo(.restricted)
        state = await mockCapability.state
        XCTAssertEqual(state, .restricted)
        
        await mockCapability.transitionTo(.available)
        state = await mockCapability.state
        XCTAssertEqual(state, .available)
        
        await mockCapability.transitionTo(.unavailable)
        state = await mockCapability.state
        XCTAssertEqual(state, .unavailable)
    }
    
    // Test stream behavior
    func testStateStream() async throws {
        // Given: A mock capability
        let mockCapability = BaseMockCapability()
        
        // When: Collecting state changes
        var observedStates: [CapabilityState] = []
        let stream = await mockCapability.stateStream
        
        Task {
            for await state in stream {
                observedStates.append(state)
                if observedStates.count >= 3 {
                    break
                }
            }
        }
        
        // Give stream time to start
        try await Task.sleep(for: .milliseconds(10))
        
        // When: Transitioning states
        await mockCapability.transitionTo(.available)
        await mockCapability.transitionTo(.restricted)
        await mockCapability.transitionTo(.unavailable)
        
        // Give stream time to process
        try await Task.sleep(for: .milliseconds(10))
        
        // Then: Should observe all states
        XCTAssertEqual(observedStates.count, 3)
        XCTAssertEqual(observedStates[0], .unknown) // Initial state
        XCTAssertEqual(observedStates[1], .available)
        XCTAssertEqual(observedStates[2], .restricted)
    }
    
    // Test mock notification capability
    func testMockNotificationCapability() async throws {
        // Given: A notification capability with undetermined permission
        let notifications = MockSystemCapability.notifications(initialPermission: .notDetermined)
        
        // When: Requesting permission
        try await notifications.requestPermission()
        
        // Then: Permission should be granted
        let permission = await notifications.permission
        XCTAssertEqual(permission, .authorized)
        
        // And: Should be available
        let isAvailable = await notifications.isAvailable
        XCTAssertTrue(isAvailable)
        
        // When: Scheduling a notification
        let notification = MockNotification(
            identifier: "test-1",
            title: "Test Notification",
            body: "This is a test",
            trigger: .immediate
        )
        try await notifications.schedule(notification)
        
        // Then: Notification should be scheduled
        let hasScheduled = await notifications.hasScheduledNotification(withIdentifier: "test-1")
        XCTAssertTrue(hasScheduled)
        
        // When: Simulating delivery
        await notifications.simulateDelivery(identifier: "test-1")
        
        // Then: Should be in delivered list
        let delivered = await notifications.deliveredNotifications
        XCTAssertEqual(delivered.count, 1)
        XCTAssertEqual(delivered.first?.identifier, "test-1")
    }
    
    // Test permission denied scenario
    func testNotificationPermissionDenied() async throws {
        // Given: A notification capability with denied permission
        let notifications = MockSystemCapability.notifications(initialPermission: .denied)
        
        // When: Attempting to request permission
        do {
            try await notifications.requestPermission()
            XCTFail("Expected permission error")
        } catch {
            // Then: Should throw permission error
            if let capabilityError = error as? CapabilityError {
                XCTAssertEqual(capabilityError, .permissionRequired)
            } else {
                XCTFail("Expected CapabilityError.permissionRequired")
            }
        }
    }
    
    // Test mock shortcut capability
    func testMockShortcutCapability() async throws {
        // Given: A shortcut capability with max 4 shortcuts
        let shortcuts = MockSystemCapability.shortcuts(maxShortcuts: 4)
        
        // When: Adding shortcuts up to the limit
        let shortcut1 = MockShortcut(identifier: "create", title: "Create Task", symbolName: "plus")
        let shortcut2 = MockShortcut(identifier: "search", title: "Search", symbolName: "magnifyingglass")
        let shortcut3 = MockShortcut(identifier: "filter", title: "Filter", symbolName: "line.horizontal.3.decrease")
        let shortcut4 = MockShortcut(identifier: "sort", title: "Sort", symbolName: "arrow.up.arrow.down")
        
        try await shortcuts.addShortcut(shortcut1)
        try await shortcuts.addShortcut(shortcut2)
        try await shortcuts.addShortcut(shortcut3)
        try await shortcuts.addShortcut(shortcut4)
        
        // Then: All shortcuts should be added
        let currentShortcuts = await shortcuts.shortcuts
        XCTAssertEqual(currentShortcuts.count, 4)
        
        // When: Trying to add beyond limit
        let shortcut5 = MockShortcut(identifier: "extra", title: "Extra", symbolName: "exclamationmark")
        
        do {
            try await shortcuts.addShortcut(shortcut5)
            XCTFail("Should throw when exceeding max shortcuts")
        } catch let error as ShortcutError {
            // Then: Should throw too many shortcuts error
            if case .tooManyShortcuts(let max) = error {
                XCTAssertEqual(max, 4)
            } else {
                XCTFail("Expected tooManyShortcuts error")
            }
        }
        
        // When: Updating all shortcuts
        let newShortcuts = [shortcut1, shortcut2]
        try await shortcuts.updateShortcuts(newShortcuts)
        
        // Then: Should have new shortcuts
        let updatedShortcuts = await shortcuts.shortcuts
        XCTAssertEqual(updatedShortcuts.count, 2)
    }
    
    // Test mock widget capability
    func testMockWidgetCapability() async throws {
        // Given: A widget capability
        let widgets = MockSystemCapability.widgets()
        
        // When: Reloading widget timelines
        await widgets.reloadTimelines(ofKind: "TaskWidget")
        await widgets.reloadTimelines(ofKind: "StatsWidget")
        await widgets.reloadAllTimelines()
        
        // Then: Should track reloads
        let reloadCount = await widgets.reloadCount
        XCTAssertEqual(reloadCount, 3)
        
        let reloadedKinds = await widgets.lastReloadIdentifiers
        XCTAssertTrue(reloadedKinds.contains("TaskWidget"))
        XCTAssertTrue(reloadedKinds.contains("StatsWidget"))
        XCTAssertTrue(reloadedKinds.contains("*")) // All timelines marker
        
        // When: Resetting tracking
        await widgets.resetReloadTracking()
        
        // Then: Should clear tracking
        let resetCount = await widgets.reloadCount
        XCTAssertEqual(resetCount, 0)
        
        let resetKinds = await widgets.lastReloadIdentifiers
        XCTAssertTrue(resetKinds.isEmpty)
    }
    
    enum TestError: Error, Equatable {
        case simulated
    }
}