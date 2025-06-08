import XCTest
import Axiom
@testable import TaskManager

final class SortContextTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear persisted sort state before each test using utilities
        let keys = SortUtilities.Persistence.Keys(prefix: "TaskSortContext")
        SortUtilities.Persistence.clearSortState(keys: keys)
    }
    
    // MARK: - RED Phase: Sort Context Tests
    
    func testSortContextInitialization() async {
        // Test sort context setup and state sync
        // Framework insight: How to manage sort UI state alongside filter state?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskSortContext(client: client)
        
        // Start observing
        await context.onAppear()
        
        // Wait for context to sync with client state
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        await MainActor.run {
            // Should start with default sort state
            XCTAssertEqual(context.currentSortOrder, .dateCreated)
            XCTAssertEqual(context.currentSortDirection, .descending)
            XCTAssertFalse(context.isMultiCriteriaEnabled)
            
            // Should have available sort options
            XCTAssertNotNil(context.availableSortOrders)
            XCTAssertFalse(context.availableSortOrders.isEmpty)
        }
    }
    
    func testSortOrderSelection() async {
        // Test changing sort order through context
        // Framework insight: How to coordinate UI state with client actions?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskSortContext(client: client)
        
        await context.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        await MainActor.run {
            // Change sort order
            context.selectSortOrder(.priority)
        }
        
        // Wait for action to process
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Context should reflect change
        await MainActor.run {
            XCTAssertEqual(context.currentSortOrder, .priority)
        }
        
        // Client state should be updated
        let state = await client.state
        XCTAssertEqual(state.filter?.sortOrder, .priority)
    }
    
    func testSortDirectionToggle() async {
        // Test toggling sort direction
        // Framework insight: How to handle toggle actions in contexts?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskSortContext(client: client)
        
        await context.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        await MainActor.run {
            let initialDirection = context.currentSortDirection
            
            // Toggle direction
            context.toggleSortDirection()
            
            // Should immediately reflect in UI state
            XCTAssertNotEqual(context.currentSortDirection, initialDirection)
        }
        
        // Wait for action to process
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Client should reflect the change
        let state = await client.state
        let expectedDirection = await context.currentSortDirection
        XCTAssertEqual(state.filter?.sortDirection, expectedDirection)
    }
    
    func testMultiCriteriaSortConfiguration() async {
        // Test advanced multi-criteria sort setup
        // Framework insight: How to handle complex UI state scenarios?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskSortContext(client: client)
        
        await context.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        await MainActor.run {
            // Enable multi-criteria sorting
            context.enableMultiCriteriaSorting()
            XCTAssertTrue(context.isMultiCriteriaEnabled)
            
            // Set primary and secondary criteria
            context.setPrimarySortOrder(.priority)
            context.setSecondarySortOrder(.dateCreated)
            
            XCTAssertEqual(context.primarySortOrder, .priority)
            XCTAssertEqual(context.secondarySortOrder, .dateCreated)
        }
        
        // Wait for actions to process
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Client should have multi-criteria sort configured
        let state = await client.state
        XCTAssertEqual(state.filter?.primarySortOrder, .priority)
        XCTAssertEqual(state.filter?.secondarySortOrder, .dateCreated)
    }
    
    func testSortPresets() async {
        // Test predefined sort presets for common use cases
        // Framework insight: How to provide convenient UI shortcuts?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskSortContext(client: client)
        
        await context.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        await MainActor.run {
            // Test available presets
            let presets = context.availableSortPresets
            XCTAssertFalse(presets.isEmpty)
            
            // Should include common presets
            XCTAssertTrue(presets.contains { $0.name == "Priority First" })
            XCTAssertTrue(presets.contains { $0.name == "Recently Created" })
            XCTAssertTrue(presets.contains { $0.name == "Alphabetical" })
            
            // Apply a preset
            let priorityPreset = presets.first { $0.name == "Priority First" }!
            context.applySortPreset(priorityPreset)
        }
        
        // Wait for preset to apply
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Should configure sort according to preset
        await MainActor.run {
            XCTAssertEqual(context.currentSortOrder, .priority)
            XCTAssertEqual(context.currentSortDirection, .descending)
        }
    }
    
    func testSortAnimationCoordination() async {
        // Test animation coordination with sort changes
        // Framework insight: How to coordinate state changes with UI animations?
        let tasks = (0..<50).map { i in
            TaskTestHelpers.makeTask(title: "Task \(i)", priority: .medium)
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        let context = await TaskSortContext(client: client)
        
        await context.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        await MainActor.run {
            // Test animation state management
            XCTAssertFalse(context.isAnimating)
            
            // Start sort change with animation
            context.selectSortOrderWithAnimation(.priority)
            
            // Should immediately show animating state
            XCTAssertTrue(context.isAnimating)
        }
        
        // Wait for animation to complete
        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
        
        await MainActor.run {
            // Animation should be complete
            XCTAssertFalse(context.isAnimating)
            XCTAssertEqual(context.currentSortOrder, .priority)
        }
    }
    
    func testSortStateValidation() async {
        // Test validation of sort state combinations
        // Framework insight: How to handle invalid state transitions?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskSortContext(client: client)
        
        await context.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        await MainActor.run {
            // Test invalid multi-criteria combinations
            context.enableMultiCriteriaSorting()
            context.setPrimarySortOrder(.priority)
            
            // Should not allow same criteria for primary and secondary
            context.setSecondarySortOrder(.priority)
            XCTAssertNotEqual(context.secondarySortOrder, .priority, "Should not allow duplicate sort criteria")
            
            // Should provide validation feedback
            XCTAssertTrue(context.hasValidationError)
            XCTAssertFalse(context.validationMessage.isEmpty)
        }
    }
    
    func testSortStatePersistence() async {
        // Test sort state persistence across context lifecycle
        // Framework insight: How to maintain UI state across view updates?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskSortContext(client: client)
        
        await context.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        await MainActor.run {
            // Configure custom sort state
            context.selectSortOrder(.priority)
            context.toggleSortDirection()
        }
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Simulate view disappearing and reappearing (like navigation)
        await context.onDisappear()
        
        let newContext = await TaskSortContext(client: client)
        await newContext.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        await MainActor.run {
            // New context should restore previous sort state
            XCTAssertEqual(newContext.currentSortOrder, .priority)
            XCTAssertEqual(newContext.currentSortDirection, context.currentSortDirection)
        }
    }
    
    func testSortPerformanceFeedback() async {
        // Test UI feedback for sort performance
        // Framework insight: How to provide performance feedback to users?
        let tasks = (0..<1000).map { i in
            TaskTestHelpers.makeTask(title: "Task \(i)", priority: .medium)
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        let context = await TaskSortContext(client: client)
        
        await context.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        await MainActor.run {
            // Start performance-intensive sort
            context.selectSortOrder(.alphabetical) // Typically slower than priority
            
            // Should provide loading feedback for slow operations
            if context.estimatedSortTime > 0.1 { // If sort is expected to be slow
                XCTAssertTrue(context.isShowingProgressIndicator)
            }
        }
        
        // Wait for sort to complete
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await MainActor.run {
            // Progress indicator should be hidden
            XCTAssertFalse(context.isShowingProgressIndicator)
            
            // Should provide performance metrics
            XCTAssertGreaterThan(context.lastSortDuration, 0)
            XCTAssertFalse(context.performanceSummary.isEmpty)
        }
    }
}