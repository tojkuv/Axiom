import XCTest
@testable import TaskManager

final class KeyboardNavigationTests: XCTestCase {
    
    // MARK: - Focus Management Tests
    
    func testInitialFocusState() async throws {
        // Arrange
        let client = TaskClient()
        let context = await KeyboardNavigationContext(client: client)
        
        // Act
        await context.onAppear()
        
        // Assert
        let focusState = await context.currentFocusState
        XCTAssertNotNil(focusState)
        XCTAssertNil(focusState.focusedItem) // No initial focus
        XCTAssertTrue(focusState.isFocusTrackingEnabled)
    }
    
    func testFocusMovementSequence() async throws {
        // Arrange
        let client = TaskClient()
        let context = await KeyboardNavigationContext(client: client)
        
        // Add test tasks for navigation
        try await client.process(.addTask(title: "Task 1", description: nil, categoryId: nil, priority: .medium))
        try await client.process(.addTask(title: "Task 2", description: nil, categoryId: nil, priority: .high))
        try await client.process(.addTask(title: "Task 3", description: nil, categoryId: nil, priority: .low))
        
        // Act & Assert - Test sequential focus movement
        try await context.process(FocusAction.moveFocusDown)
        let state1 = await context.currentFocusState
        XCTAssertEqual(state1.focusedItem?.index, 0)
        
        try await context.process(FocusAction.moveFocusDown)
        let state2 = await context.currentFocusState
        XCTAssertEqual(state2.focusedItem?.index, 1)
        
        try await context.process(FocusAction.moveFocusUp)
        let state3 = await context.currentFocusState
        XCTAssertEqual(state3.focusedItem?.index, 0)
    }
    
    func testFocusWrapAroundBehavior() async throws {
        // Arrange
        let client = TaskClient()
        let context = await KeyboardNavigationContext(client: client)
        
        // Add test tasks
        try await client.process(.addTask(title: "First Task", description: nil, categoryId: nil, priority: .medium))
        try await client.process(.addTask(title: "Last Task", description: nil, categoryId: nil, priority: .high))
        
        // Act - Move to last item
        try await context.process(FocusAction.moveFocusDown)
        try await context.process(FocusAction.moveFocusDown)
        
        // Test wrap-around when moving down from last item
        try await context.process(FocusAction.moveFocusDown)
        let stateAfterWrap = await context.currentFocusState
        XCTAssertEqual(stateAfterWrap.focusedItem?.index, 0) // Should wrap to first
        
        // Test wrap-around when moving up from first item
        try await context.process(FocusAction.moveFocusUp)
        let stateAfterUpWrap = await context.currentFocusState
        XCTAssertEqual(stateAfterUpWrap.focusedItem?.index, 1) // Should wrap to last
    }
    
    func testFocusUpdateLatency() async throws {
        // Arrange
        let client = TaskClient()
        let context = await KeyboardNavigationContext(client: client)
        
        // Add tasks for testing
        for i in 0..<10 {
            try await client.process(.addTask(title: "Task \(i)", description: nil, categoryId: nil, priority: .medium))
        }
        
        // Act & Assert - Measure focus update performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<10 {
            try await context.process(FocusAction.moveFocusDown)
        }
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should meet < 16ms requirement for each focus change
        let averageLatency = elapsed / 10.0
        XCTAssertLessThan(averageLatency, 0.016, "Focus response time should be < 16ms")
    }
    
    // MARK: - Keyboard Shortcut Tests
    
    func testBasicShortcutRegistration() async throws {
        // Arrange
        let client = TaskClient()
        let context = await KeyboardNavigationContext(client: client)
        let shortcutRegistry = KeyboardShortcutRegistry()
        
        // Act - Register basic shortcuts
        try await shortcutRegistry.register(.createTask, key: "n", modifiers: [.command])
        try await shortcutRegistry.register(.deleteTask, key: "Backspace", modifiers: [])
        try await shortcutRegistry.register(.editTask, key: "Return", modifiers: [])
        
        // Assert
        let registeredShortcuts = await shortcutRegistry.allShortcuts
        XCTAssertEqual(registeredShortcuts.count, 3)
        
        let createShortcut = registeredShortcuts.first { $0.action == .createTask }
        XCTAssertNotNil(createShortcut)
        XCTAssertEqual(createShortcut?.key, "n")
        XCTAssertEqual(createShortcut?.modifiers, [.command])
    }
    
    func testShortcutConflictDetection() async throws {
        // Arrange
        let shortcutRegistry = KeyboardShortcutRegistry()
        
        // Act - Register initial shortcut
        try await shortcutRegistry.register(.createTask, key: "n", modifiers: [.command])
        
        // Assert - Conflict detection when registering duplicate
        do {
            try await shortcutRegistry.register(.deleteTask, key: "n", modifiers: [.command])
            XCTFail("Should detect shortcut conflict")
        } catch KeyboardShortcutError.conflictDetected(let existing) {
            XCTAssertEqual(existing.action, .createTask)
        }
    }
    
    func testShortcutExecution() async throws {
        // Arrange
        let client = TaskClient()
        let context = await KeyboardNavigationContext(client: client)
        let shortcutRegistry = KeyboardShortcutRegistry()
        
        await context.setShortcutRegistry(shortcutRegistry)
        
        // Register shortcuts
        try await shortcutRegistry.register(.createTask, key: "n", modifiers: [.command])
        try await shortcutRegistry.register(.deleteTask, key: "Backspace", modifiers: [])
        
        // Add a task to test deletion
        try await client.process(.addTask(title: "Test Task", description: nil, categoryId: nil, priority: .medium))
        try await context.process(FocusAction.moveFocusDown) // Focus on task
        
        // Act - Execute shortcuts
        try await context.handleKeyboardInput(key: "n", modifiers: [.command])
        
        // Verify create task shortcut triggered
        let stateAfterCreate = await client.currentState
        XCTAssertTrue(stateAfterCreate.isCreateTaskModalPresented)
        
        // Test delete shortcut
        try await context.handleKeyboardInput(key: "Backspace", modifiers: [])
        let stateAfterDelete = await client.currentState
        XCTAssertTrue(stateAfterDelete.showingDeleteConfirmation)
    }
    
    func testShortcutReliability() async throws {
        // Arrange
        let client = TaskClient()
        let context = await KeyboardNavigationContext(client: client)
        let shortcutRegistry = KeyboardShortcutRegistry()
        await context.setShortcutRegistry(shortcutRegistry)
        
        try await shortcutRegistry.register(.toggleComplete, key: "Space", modifiers: [])
        
        var executionCount = 0
        await MainActor.run {
            context.onShortcutExecuted = { action in
                if action == .toggleComplete {
                    executionCount += 1
                }
            }
        }
        
        // Act - Execute shortcut multiple times
        for _ in 0..<100 {
            try await context.handleKeyboardInput(key: "Space", modifiers: [])
        }
        
        // Assert - 100% reliability
        XCTAssertEqual(executionCount, 100, "Shortcut reliability should be 100%")
    }
    
    // MARK: - Cross-Platform Tests
    
    func testPlatformSpecificShortcuts() async throws {
        // Arrange
        let shortcutRegistry = KeyboardShortcutRegistry()
        
        // Act - Register platform-specific shortcuts
        #if os(macOS)
        try await shortcutRegistry.register(.selectAll, key: "a", modifiers: [.command])
        try await shortcutRegistry.register(.find, key: "f", modifiers: [.command])
        #elseif os(iOS)
        try await shortcutRegistry.register(.selectAll, key: "a", modifiers: [.command])
        try await shortcutRegistry.register(.find, key: "f", modifiers: [.command])
        #endif
        
        // Assert
        let shortcuts = await shortcutRegistry.allShortcuts
        XCTAssertGreaterThan(shortcuts.count, 0)
        
        // Verify platform-appropriate modifier handling
        let selectAllShortcut = shortcuts.first { $0.action == .selectAll }
        XCTAssertNotNil(selectAllShortcut)
        XCTAssertTrue(selectAllShortcut!.modifiers.contains(.command))
    }
    
    func testKeyCodeMapping() async throws {
        // Arrange
        let keyMapper = PlatformKeyMapper()
        
        // Act & Assert - Test key code conversions
        #if os(macOS)
        XCTAssertEqual(keyMapper.mapKeyCode(36), "Return") // macOS return key
        XCTAssertEqual(keyMapper.mapKeyCode(51), "Backspace") // macOS delete key
        XCTAssertEqual(keyMapper.mapKeyCode(49), "Space") // macOS space key
        #elseif os(iOS)
        // iOS uses different key mapping approach
        XCTAssertEqual(keyMapper.mapKeyString("UIKeyInputEscape"), "Escape")
        XCTAssertEqual(keyMapper.mapKeyString("UIKeyInputUpArrow"), "UpArrow")
        #endif
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityCompliance() async throws {
        // Arrange
        let client = TaskClient()
        let context = await KeyboardNavigationContext(client: client)
        let accessibilityValidator = AccessibilityValidator()
        
        // Add tasks for testing
        try await client.process(.addTask(title: "Accessible Task", description: nil, categoryId: nil, priority: .high))
        
        // Set focus to task to enable proper label testing
        try await context.process(FocusAction.moveFocusDown)
        
        // Act - Validate accessibility
        let compliance = try await accessibilityValidator.validateKeyboardNavigation(context: context)
        
        // Assert - 100% accessibility score requirement
        XCTAssertEqual(compliance.score, 100, "Accessibility score should be 100%")
        XCTAssertTrue(compliance.supportsFocusManagement)
        XCTAssertTrue(compliance.supportsVoiceOver)
        XCTAssertTrue(compliance.supportsKeyboardNavigation)
        XCTAssertTrue(compliance.hasProperLabels)
    }
    
    func testVoiceOverIntegration() async throws {
        // Arrange
        let client = TaskClient()
        let context = await KeyboardNavigationContext(client: client)
        let voiceOverTester = VoiceOverTester()
        
        // Add a task for testing
        try await client.process(.addTask(title: "Test Task", description: nil, categoryId: nil, priority: .high))
        
        // Act - Test VoiceOver announcements
        try await context.process(FocusAction.moveFocusDown)
        
        let announcements = await voiceOverTester.captureAnnouncements()
        
        // Assert
        XCTAssertFalse(announcements.isEmpty)
        XCTAssertTrue(announcements.contains { $0.contains("Focus moved to") })
    }
    
    func testKeyboardNavigationLabels() async throws {
        // Arrange
        let client = TaskClient()
        let context = await KeyboardNavigationContext(client: client)
        try await client.process(.addTask(title: "Test Task", description: nil, categoryId: nil, priority: .high))
        
        // Act
        try await context.process(FocusAction.moveFocusDown)
        let focusState = await context.currentFocusState
        
        // Assert - Proper accessibility labels
        XCTAssertNotNil(focusState.focusedItem?.accessibilityLabel)
        XCTAssertTrue(focusState.focusedItem!.accessibilityLabel.contains("Test Task"))
        XCTAssertTrue(focusState.focusedItem!.accessibilityLabel.contains("High priority"))
        XCTAssertNotNil(focusState.focusedItem?.accessibilityHint)
    }
    
    // MARK: - Performance Tests
    
    func testFocusPerformanceWithLargeDataset() async throws {
        // Arrange
        let client = TaskClient()
        let context = await KeyboardNavigationContext(client: client)
        
        // Add large dataset
        for i in 0..<1000 {
            try await client.process(.addTask(title: "Task \(i)", description: nil, categoryId: nil, priority: .medium))
        }
        
        // Act - Measure focus navigation performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Navigate through 50 items
        for _ in 0..<50 {
            try await context.process(FocusAction.moveFocusDown)
        }
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert - Should maintain performance with large datasets
        let averageTime = elapsed / 50.0
        XCTAssertLessThan(averageTime, 0.016, "Focus navigation should stay under 16ms even with 1000 tasks")
    }
    
    func testMemoryUsageDuringFocusTracking() async throws {
        // Arrange
        let memoryProfiler = MemoryProfiler()
        let client = TaskClient()
        let context = await KeyboardNavigationContext(client: client)
        
        await memoryProfiler.start()
        
        // Act - Simulate intensive focus usage
        for _ in 0..<100 {
            try await context.process(FocusAction.moveFocusDown)
            try await context.process(FocusAction.moveFocusUp)
        }
        
        let memoryUsed = await memoryProfiler.stop()
        
        // Assert - Memory usage should be reasonable
        XCTAssertLessThan(memoryUsed, 1_048_576, "Memory usage should be less than 1MB during focus tracking")
    }
    
    // MARK: - Integration Tests
    
    func testKeyboardNavigationWithSearch() async throws {
        // Arrange
        let client = TaskClient()
        let searchContext = await SearchContext(client: client)
        let keyboardContext = await KeyboardNavigationContext(client: client)
        
        // Add test data
        try await client.process(.addTask(title: "Important Task", description: nil, categoryId: nil, priority: .high))
        try await client.process(.addTask(title: "Regular Task", description: nil, categoryId: nil, priority: .medium))
        
        // Act - Search and then navigate
        await searchContext.client.send(.setSearchQuery("Important"))
        try await keyboardContext.process(FocusAction.moveFocusDown)
        
        // Assert - Focus should work with filtered results
        let focusState = await keyboardContext.currentFocusState
        let searchState = await searchContext.client.currentState
        
        XCTAssertEqual(searchState.filteredTasks.count, 1)
        XCTAssertEqual(focusState.focusedItem?.index, 0)
        XCTAssertEqual(focusState.focusedItem?.taskId, searchState.filteredTasks.first?.id)
    }
    
    func testKeyboardNavigationWithBulkOperations() async throws {
        // Arrange
        let client = TaskClient()
        let keyboardContext = await KeyboardNavigationContext(client: client)
        
        // Add test tasks
        for i in 0..<5 {
            try await client.process(.addTask(title: "Task \(i)", description: nil, categoryId: nil, priority: .medium))
        }
        
        // Act - Use keyboard to select multiple items
        try await keyboardContext.process(FocusAction.moveFocusDown) // Focus first
        try await keyboardContext.handleKeyboardInput(key: "Space", modifiers: [KeyModifier.shift]) // Multi-select
        try await keyboardContext.process(FocusAction.moveFocusDown) // Focus second
        try await keyboardContext.handleKeyboardInput(key: "Space", modifiers: [KeyModifier.shift]) // Add to selection
        
        // Assert - Multi-selection state should be maintained
        let state = await client.currentState
        XCTAssertEqual(state.selectedTaskIds.count, 2)
        
        let focusState = await keyboardContext.currentFocusState
        XCTAssertTrue(focusState.isMultiSelectMode)
    }
}

// MARK: - Framework Pain Points to Document

/*
 Expected Framework Pain Points for REQ-013:
 
 1. Focus state tracking complexity
    - No built-in focus management utilities
    - Manual coordination between UI state and focus state
    - Performance concerns with large lists
 
 2. Keyboard shortcut conflicts
    - No framework support for conflict detection
    - Manual shortcut registry implementation required
    - Platform differences in key handling
 
 3. Cross-platform keyboard differences
    - Different key codes between iOS and macOS
    - Modifier key handling variations
    - Hardware keyboard availability detection
 
 4. Accessibility integration complexity
    - Manual VoiceOver integration
    - Focus announcement coordination
    - Accessibility label management
 
 5. Performance with keyboard navigation
    - Focus updates must be < 16ms for 60fps
    - Memory efficiency during focus tracking
    - Integration with existing state observation
 */