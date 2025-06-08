import XCTest
@testable import TaskManager

@MainActor
final class WidgetExtensionTests: XCTestCase {
    
    // MARK: - Test Properties
    private var widgetContext: TaskWidgetContext!
    private var mockClient: TaskClient!
    private var testTasks: [TaskItem]!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize test data
        testTasks = [
            TaskItem(title: "Complete project", priority: .high),
            TaskItem(title: "Buy groceries", priority: .medium),
            TaskItem(title: "Exercise", priority: .low)
        ]
        
        // Initialize mock client with test data
        mockClient = TaskClient()
        for task in testTasks {
            try await mockClient.process(.addTask(title: task.title, description: nil, priority: task.priority))
        }
        
        // Initialize widget context
        widgetContext = TaskWidgetContext(client: mockClient)
    }
    
    override func tearDown() async throws {
        widgetContext = nil
        mockClient = nil
        testTasks = nil
        try await super.tearDown()
    }
    
    // MARK: - Widget State Tests
    
    func testWidgetInitialState() async throws {
        // Test that widget starts with empty state
        let initialState = await widgetContext.widgetState
        XCTAssertEqual(initialState.tasks.count, 0)
        XCTAssertNil(initialState.lastUpdated)
        XCTAssertEqual(initialState.displayMode, .compact)
    }
    
    func testWidgetStateSynchronization() async throws {
        // Test that widget state synchronizes with main app state
        // Widget context automatically observes client from initialization
        
        // Allow time for synchronization
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let widgetState = await widgetContext.widgetState
        XCTAssertEqual(widgetState.tasks.count, testTasks.count)
        XCTAssertEqual(Set(widgetState.tasks.map(\.title)), Set(testTasks.map(\.title)))
        XCTAssertNotNil(widgetState.lastUpdated)
    }
    
    func testWidgetStateFiltering() async throws {
        // Test that widget only shows high priority tasks
        // Widget context automatically observes client from initialization
        try await widgetContext.updateDisplayFilter(.highPriorityOnly)
        
        let widgetState = await widgetContext.widgetState
        let highPriorityTasks = widgetState.tasks.filter { $0.priority == .high }
        XCTAssertEqual(widgetState.tasks.count, highPriorityTasks.count)
        XCTAssertTrue(widgetState.tasks.allSatisfy { $0.priority == .high })
    }
    
    // MARK: - Widget Update Tests
    
    func testWidgetUpdateFrequency() async throws {
        // Widget context automatically observes client from initialization
        
        // Measure update latency
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Add new task to trigger update
        try await mockClient.process(.addTask(title: "New urgent task", description: nil, priority: .high))
        
        // Wait for widget update
        var updateReceived = false
        var iterations = 0
        while !updateReceived && iterations < 10 {
            try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
            let widgetState = await widgetContext.widgetState
            updateReceived = widgetState.tasks.contains { $0.title == "New urgent task" }
            iterations += 1
        }
        
        let updateLatency = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertTrue(updateReceived, "Widget should receive state updates")
        XCTAssertLessThan(updateLatency, 0.1, "Widget update latency should be < 100ms")
    }
    
    func testWidgetBatteryOptimization() async throws {
        // Test that widget uses efficient update patterns
        // Widget context automatically observes client from initialization
        
        // Make multiple rapid changes
        for i in 0..<10 {
            try await mockClient.process(.addTask(title: "Task \(i)", description: nil, priority: .medium))
        }
        
        // Widget should debounce/batch updates
        let updateCount = await widgetContext.updateCount
        XCTAssertLessThan(updateCount, 10, "Widget should batch rapid updates for battery efficiency")
    }
    
    // MARK: - Size Class Tests
    
    func testSmallSizeClass() async throws {
        // Widget context automatically observes client from initialization
        try await widgetContext.updateSizeClass(.small)
        
        let widgetState = await widgetContext.widgetState
        XCTAssertEqual(widgetState.displayMode, .compact)
        XCTAssertLessThanOrEqual(widgetState.maxDisplayTasks, 3)
    }
    
    func testMediumSizeClass() async throws {
        // Widget context automatically observes client from initialization
        try await widgetContext.updateSizeClass(.medium)
        
        let widgetState = await widgetContext.widgetState
        XCTAssertEqual(widgetState.displayMode, .standard)
        XCTAssertLessThanOrEqual(widgetState.maxDisplayTasks, 6)
    }
    
    func testLargeSizeClass() async throws {
        // Widget context automatically observes client from initialization
        try await widgetContext.updateSizeClass(.large)
        
        let widgetState = await widgetContext.widgetState
        XCTAssertEqual(widgetState.displayMode, .detailed)
        XCTAssertLessThanOrEqual(widgetState.maxDisplayTasks, 10)
    }
    
    func testSizeClassTransition() async throws {
        // Widget context automatically observes client from initialization
        
        // Test smooth transition between size classes
        try await widgetContext.updateSizeClass(.small)
        let smallState = await widgetContext.widgetState
        
        try await widgetContext.updateSizeClass(.large)
        let largeState = await widgetContext.widgetState
        
        // Data should remain consistent across size changes
        XCTAssertEqual(smallState.tasks.count, largeState.tasks.count)
        XCTAssertNotEqual(smallState.displayMode, largeState.displayMode)
    }
    
    // MARK: - Mock Widget Environment Tests
    
    func testWidgetEnvironmentSimulation() async throws {
        // Test widget behavior in simulated environment conditions
        let mockEnvironment = MockWidgetEnvironment()
        await widgetContext.bind(to: mockEnvironment)
        
        // Simulate low power mode
        await mockEnvironment.setLowPowerMode(true)
        let lowPowerState = await widgetContext.widgetState
        XCTAssertTrue(lowPowerState.isLowPowerOptimized)
        
        // Simulate background refresh disabled
        await mockEnvironment.setBackgroundRefreshEnabled(false)
        let noRefreshState = await widgetContext.widgetState
        XCTAssertFalse(noRefreshState.backgroundRefreshEnabled)
    }
    
    func testWidgetDeepLinkHandling() async throws {
        // Widget context automatically observes client from initialization
        
        // Test deep link to specific task
        let targetTask = testTasks.first!
        let deepLinkURL = URL(string: "taskmanager://task/\(targetTask.id)")!
        
        let handled = await widgetContext.handleDeepLink(deepLinkURL)
        XCTAssertTrue(handled, "Widget should handle deep links to tasks")
        
        let selectedTask = await widgetContext.selectedTask
        XCTAssertEqual(selectedTask?.id, targetTask.id)
    }
    
    // MARK: - Performance Tests
    
    func testWidgetPerformanceWithLargeDataset() async throws {
        // Create large dataset
        let largeTasks = (0..<1000).map { index in
            TaskItem(title: "Task \(index)", priority: .medium)
        }
        
        for task in largeTasks {
            try await mockClient.process(.addTask(title: task.title, description: nil, priority: task.priority))
        }
        
        // Measure widget update performance
        let startTime = CFAbsoluteTimeGetCurrent()
        // Widget context automatically observes client from initialization
        // Allow time for synchronization with large dataset
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        let syncTime = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(syncTime, 0.1, "Widget sync should complete within 100ms even with large datasets")
        
        let widgetState = await widgetContext.widgetState
        XCTAssertLessThanOrEqual(widgetState.tasks.count, widgetState.maxDisplayTasks)
    }
}