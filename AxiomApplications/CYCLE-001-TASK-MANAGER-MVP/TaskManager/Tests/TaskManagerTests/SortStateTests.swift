import XCTest
import Axiom
@testable import TaskManager

final class SortStateTests: XCTestCase {
    
    // MARK: - RED Phase: Sort State Tests
    
    func testSortOrderEnum() async {
        // Test SortOrder enum with priority support
        // Framework insight: How to extend existing enums for new requirements?
        
        // Test all sort orders are available
        let allOrders = SortOrder.allCases
        XCTAssertTrue(allOrders.contains(.dateCreated))
        XCTAssertTrue(allOrders.contains(.dateModified))
        XCTAssertTrue(allOrders.contains(.alphabetical))
        XCTAssertTrue(allOrders.contains(.priority)) // New for REQ-006
        XCTAssertTrue(allOrders.contains(.dueDate))
        
        // Test display names
        XCTAssertEqual(SortOrder.priority.displayName, "Priority")
        XCTAssertFalse(SortOrder.priority.displayName.isEmpty)
    }
    
    func testSortDirectionState() async {
        // Test sort direction as separate state
        // Framework insight: How to model compound sort state?
        
        let sortDirection = SortDirection.ascending
        
        // Should conform to State protocol
        XCTAssertNotNil(sortDirection as any State)
        
        // Test both directions
        XCTAssertEqual(SortDirection.ascending.displayName, "Ascending")
        XCTAssertEqual(SortDirection.descending.displayName, "Descending")
        
        // Test icons for UI
        XCTAssertFalse(SortDirection.ascending.icon.isEmpty)
        XCTAssertFalse(SortDirection.descending.icon.isEmpty)
    }
    
    func testMultiCriteriaSortState() async {
        // Test complex sort state with multiple criteria
        // Framework insight: How to model hierarchical sort preferences?
        
        let sortCriteria = SortCriteria(
            primary: .priority,
            secondary: .dateCreated,
            direction: .descending
        )
        
        // Should conform to State protocol
        XCTAssertNotNil(sortCriteria as any State)
        
        // Test state creation and modification
        let newCriteria = sortCriteria.with(
            primary: .alphabetical,
            direction: .ascending
        )
        
        XCTAssertEqual(newCriteria.primary, .alphabetical)
        XCTAssertEqual(newCriteria.secondary, .dateCreated) // Should preserve
        XCTAssertEqual(newCriteria.direction, .ascending)
        
        // Original should be unchanged (immutability)
        XCTAssertEqual(sortCriteria.primary, .priority)
        XCTAssertEqual(sortCriteria.direction, .descending)
    }
    
    func testTaskFilterSortIntegration() async {
        // Test sort state integration with existing TaskFilter
        // Framework insight: How to extend existing state models?
        
        let filter = TaskFilter(
            searchQuery: "test",
            selectedCategories: [],
            showCompleted: true,
            sortOrder: .priority,
            sortDirection: .descending
        )
        
        // Should maintain existing filter functionality
        XCTAssertEqual(filter.searchQuery, "test")
        XCTAssertTrue(filter.showCompleted)
        
        // Should support new sort properties
        XCTAssertEqual(filter.sortOrder, .priority)
        XCTAssertEqual(filter.sortDirection, .descending)
        
        // Test with() helper for sort updates
        let updatedFilter = filter.with(
            sortOrder: .alphabetical,
            sortDirection: .ascending
        )
        
        XCTAssertEqual(updatedFilter.sortOrder, .alphabetical)
        XCTAssertEqual(updatedFilter.sortDirection, .ascending)
        XCTAssertEqual(updatedFilter.searchQuery, "test") // Preserved
    }
    
    func testSortActions() async {
        // Test sort actions integration with TaskAction
        // Framework insight: How to extend action enums?
        
        let client = await TaskTestHelpers.makeClient()
        
        // Test setting sort order
        await client.send(.setSortOrder(.priority))
        
        // Test setting sort direction  
        await client.send(.setSortDirection(.descending))
        
        // Test setting multi-criteria sort
        await client.send(.setSortCriteria(.priority, secondary: .dateCreated, direction: .ascending))
        
        let state = await client.state
        XCTAssertNotNil(state.filter)
        // Will test specific values once implementation exists
    }
    
    func testStableSortBehavior() async {
        // Test that sorting is stable (preserves relative order of equal elements)
        // Framework insight: How to ensure stable sorting in computed properties?
        
        let tasks = [
            TaskTestHelpers.makeTask(title: "A Task", priority: .high),
            TaskTestHelpers.makeTask(title: "B Task", priority: .high), // Same priority
            TaskTestHelpers.makeTask(title: "C Task", priority: .low),
            TaskTestHelpers.makeTask(title: "D Task", priority: .high)  // Same priority
        ]
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        await client.send(.setSortOrder(.priority))
        await client.send(.setSortDirection(.descending))
        
        let state = await client.state
        let sortedTasks = state.filteredTasks
        
        // High priority tasks should come first
        XCTAssertEqual(sortedTasks[0].priority, .high)
        XCTAssertEqual(sortedTasks[1].priority, .high)
        XCTAssertEqual(sortedTasks[2].priority, .high)
        XCTAssertEqual(sortedTasks[3].priority, .low)
        
        // Among tasks with same priority, original order should be preserved (stable sort)
        let highPriorityTasks = sortedTasks.prefix(3)
        XCTAssertEqual(highPriorityTasks.map { $0.title }, ["A Task", "B Task", "D Task"])
    }
    
    func testMultiCriteriaSorting() async {
        // Test sorting by multiple criteria (priority + date)
        // Framework insight: How to implement multi-level sorting efficiently?
        
        let now = Date()
        let earlier = now.addingTimeInterval(-3600) // 1 hour ago
        
        let tasks = [
            TaskTestHelpers.makeTask(title: "Recent High", priority: .high, createdAt: now),
            TaskTestHelpers.makeTask(title: "Old High", priority: .high, createdAt: earlier),
            TaskTestHelpers.makeTask(title: "Recent Low", priority: .low, createdAt: now),
            TaskTestHelpers.makeTask(title: "Old Low", priority: .low, createdAt: earlier)
        ]
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        // Sort by priority (desc) then by date (desc - newest first)
        await client.send(.setSortCriteria(.priority, secondary: .dateCreated, direction: .descending))
        
        let state = await client.state
        
        let sortedTasks = state.filteredTasks.map { $0.title }
        
        // Should be: High priority first, then within each priority, newest first
        let expected = ["Recent High", "Old High", "Recent Low", "Old Low"]
        XCTAssertEqual(sortedTasks, expected)
    }
    
    func testSortStatePersistence() async {
        // Test sort state persistence across actions
        // Framework insight: How to maintain sort state during other operations?
        
        let client = await TaskTestHelpers.makeClient()
        
        // Set sort preferences
        await client.send(.setSortOrder(.priority))
        await client.send(.setSortDirection(.ascending))
        
        // Perform other operations
        await client.send(.addTask(title: "New task", description: nil, categoryId: nil))
        await client.send(.setSearchQuery("test"))
        
        // Sort preferences should be preserved
        let state = await client.state
        XCTAssertEqual(state.filter?.sortOrder, .priority)
        XCTAssertEqual(state.filter?.sortDirection, .ascending)
    }
}