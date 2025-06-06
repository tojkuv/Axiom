import XCTest
@testable import TestApp002Core

final class TabNavigationRefactorTests: XCTestCase {
    
    // MARK: - REFACTOR Phase: Enhanced tab navigation features
    
    func testCustomizableTabOrder() async throws {
        // RFC Refactoring: Add customizable tab order
        let navigationController = TabNavigationController()
        
        // Default order should be [tasks, categories, settings, profile]
        let defaultOrder = await navigationController.getTabOrder()
        XCTAssertEqual(defaultOrder, [.tasks, .categories, .settings, .profile], "Default tab order should match RFC specification")
        
        // Customize tab order
        let customOrder: [TabType] = [.profile, .tasks, .settings, .categories]
        try await navigationController.setTabOrder(customOrder)
        
        let updatedOrder = await navigationController.getTabOrder()
        XCTAssertEqual(updatedOrder, customOrder, "Tab order should be customizable")
        
        // Available tabs should still include all tabs
        let availableTabs = await navigationController.getAvailableTabs()
        XCTAssertEqual(Set(availableTabs), Set(TabType.allCases), "All tabs should still be available")
    }
    
    func testTabOrderPersistence() async throws {
        // Custom tab order should persist across controller recreation
        let navigationController = TabNavigationController()
        
        let customOrder: [TabType] = [.settings, .profile, .tasks, .categories]
        try await navigationController.setTabOrder(customOrder)
        
        // Save navigation state
        let savedState = try await navigationController.saveNavigationState()
        
        // Create new controller and restore
        let newController = TabNavigationController()
        try await newController.restoreNavigationState(savedState)
        
        let restoredOrder = await newController.getTabOrder()
        XCTAssertEqual(restoredOrder, customOrder, "Custom tab order should persist across recreation")
    }
    
    func testInvalidTabOrderHandling() async throws {
        // Test handling of invalid tab orders
        let navigationController = TabNavigationController()
        
        // Test empty order
        do {
            try await navigationController.setTabOrder([])
            XCTFail("Should not accept empty tab order")
        } catch TabNavigationError.invalidTabOrder {
            // Expected error
        }
        
        // Test incomplete order (missing tabs)
        do {
            try await navigationController.setTabOrder([.tasks, .settings])
            XCTFail("Should not accept incomplete tab order")
        } catch TabNavigationError.invalidTabOrder {
            // Expected error
        }
        
        // Test duplicate tabs
        do {
            try await navigationController.setTabOrder([.tasks, .categories, .tasks, .profile])
            XCTFail("Should not accept duplicate tabs")
        } catch TabNavigationError.invalidTabOrder {
            // Expected error
        }
    }
    
    func testEnhancedStatePersistence() async throws {
        // Test enhanced state persistence beyond basic save/restore
        let navigationController = TabNavigationController()
        
        // Set up complex state across multiple tabs
        try await navigationController.switchToTab(.tasks)
        let tasksContext = try await navigationController.getCurrentContext()
        await tasksContext.updateState([
            "searchQuery": "urgent",
            "sortBy": "priority",
            "filterCategory": "work",
            "selectedTaskId": "task-123"
        ])
        
        try await navigationController.switchToTab(.settings)
        let settingsContext = try await navigationController.getCurrentContext()
        await settingsContext.updateState([
            "theme": "dark",
            "notifications": true,
            "autoSync": false,
            "fontSize": "large"
        ])
        
        // Customize tab order
        let customOrder: [TabType] = [.profile, .settings, .tasks, .categories]
        try await navigationController.setTabOrder(customOrder)
        
        // Save enhanced state
        let savedState = try await navigationController.saveNavigationState()
        
        // Verify saved state contains all information
        XCTAssertEqual(savedState.currentTab, .settings, "Current tab should be saved")
        XCTAssertEqual(savedState.tabOrder, customOrder, "Custom tab order should be saved")
        XCTAssertEqual(savedState.tabStates.count, 2, "Should save state for 2 tabs")
        
        // Create new controller and restore everything
        let newController = TabNavigationController()
        try await newController.restoreNavigationState(savedState)
        
        // Verify tab order restoration
        let restoredOrder = await newController.getTabOrder()
        XCTAssertEqual(restoredOrder, customOrder, "Tab order should be restored")
        
        // Verify current tab restoration
        let restoredCurrentTab = await newController.getCurrentTab()
        XCTAssertEqual(restoredCurrentTab, .settings, "Current tab should be restored")
        
        // Verify tasks tab state restoration
        try await newController.switchToTab(.tasks)
        let restoredTasksContext = try await newController.getCurrentContext()
        let restoredTasksState = await restoredTasksContext.getState()
        XCTAssertEqual(restoredTasksState["searchQuery"], "urgent", "Tasks search query should be restored")
        XCTAssertEqual(restoredTasksState["sortBy"], "priority", "Tasks sort option should be restored")
        XCTAssertEqual(restoredTasksState["selectedTaskId"], "task-123", "Selected task should be restored")
        
        // Verify settings tab state restoration
        try await newController.switchToTab(.settings)
        let restoredSettingsContext = try await newController.getCurrentContext()
        let restoredSettingsState = await restoredSettingsContext.getState()
        XCTAssertEqual(restoredSettingsState["theme"], "dark", "Theme setting should be restored")
        XCTAssertEqual(restoredSettingsState["notifications"], "true", "Notification setting should be restored")
        XCTAssertEqual(restoredSettingsState["autoSync"], "false", "Auto-sync setting should be restored")
    }
    
    func testTabStateAutoSave() async throws {
        // Test automatic state saving for enhanced persistence
        let navigationController = TabNavigationController()
        
        // Enable auto-save with 500ms interval
        await navigationController.enableAutoSave(interval: 0.5)
        
        // Make state changes
        try await navigationController.switchToTab(.profile)
        let profileContext = try await navigationController.getCurrentContext()
        await profileContext.updateState(["username": "testuser", "email": "test@example.com"])
        
        // Wait for auto-save
        try await _Concurrency.Task.sleep(nanoseconds: 600_000_000) // 600ms
        
        // Verify auto-save occurred
        let hasAutoSavedState = await navigationController.hasAutoSavedState()
        XCTAssertTrue(hasAutoSavedState, "Auto-save should have occurred")
        
        // Test auto-save restoration
        let newController = TabNavigationController()
        
        // Copy auto-saved state from the first controller
        await newController.copyAutoSavedState(from: navigationController)
        
        let restored = try await newController.restoreAutoSavedState()
        XCTAssertTrue(restored, "Should be able to restore auto-saved state")
        
        let restoredTab = await newController.getCurrentTab()
        XCTAssertEqual(restoredTab, .profile, "Current tab should be auto-restored")
    }
    
    func testTabStateClearance() async throws {
        // Test clearing tab states for memory management
        let navigationController = TabNavigationController()
        
        // Create state in multiple tabs
        for tab in TabType.allCases {
            try await navigationController.switchToTab(tab)
            let context = try await navigationController.getCurrentContext()
            await context.updateState(["data": "test-data-for-\(tab.rawValue)"])
        }
        
        // Verify states exist
        let memoryUsage = await navigationController.getMemoryUsage()
        XCTAssertGreaterThan(memoryUsage, 0, "Should have memory usage from tab states")
        
        // Clear inactive tab states (keeping current tab)
        let currentTab = await navigationController.getCurrentTab()
        try await navigationController.clearInactiveTabStates()
        
        let clearedMemoryUsage = await navigationController.getMemoryUsage()
        XCTAssertLessThan(clearedMemoryUsage, memoryUsage, "Memory usage should decrease after clearing")
        
        // Current tab state should still exist
        let currentContext = try await navigationController.getCurrentContext()
        let currentState = await currentContext.getState()
        XCTAssertFalse(currentState.isEmpty, "Current tab state should be preserved")
        
        // Other tab contexts should be cleared
        for tab in TabType.allCases where tab != currentTab {
            try await navigationController.switchToTab(tab)
            let context = try await navigationController.getCurrentContext()
            let state = await context.getState()
            XCTAssertTrue(state.isEmpty, "Inactive tab \(tab) state should be cleared")
        }
    }
    
    func testTabPreloadingOptimization() async throws {
        // Test tab context preloading for performance
        let navigationController = TabNavigationController()
        
        // Enable preloading for specific tabs
        await navigationController.enablePreloading(for: [.tasks, .categories])
        
        // Preloading should create contexts in background
        try await _Concurrency.Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // Switching to preloaded tab should be fast
        let startTime = CFAbsoluteTimeGetCurrent()
        try await navigationController.switchToTab(.tasks)
        let switchTime = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(switchTime, 0.010, "Switch to preloaded tab should be under 10ms")
        
        // Non-preloaded tabs should still work but potentially slower
        let nonPreloadedStartTime = CFAbsoluteTimeGetCurrent()
        try await navigationController.switchToTab(.profile)
        let nonPreloadedSwitchTime = CFAbsoluteTimeGetCurrent() - nonPreloadedStartTime
        
        // Both should be well under the 16ms requirement, but preloaded might be faster
        XCTAssertLessThan(nonPreloadedSwitchTime, 0.016, "Non-preloaded tab should still meet 16ms requirement")
    }
}