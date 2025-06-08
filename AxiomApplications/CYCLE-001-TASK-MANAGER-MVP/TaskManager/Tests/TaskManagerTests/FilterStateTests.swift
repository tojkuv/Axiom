import XCTest
import Axiom
@testable import TaskManager

final class FilterStateTests: XCTestCase {
    
    // MARK: - RED Phase: Filter State Tests
    
    func testFilterStateModel() async {
        // Testing filter state composition
        // Framework insight: How to model complex filter state?
        let filter = TaskFilter(
            searchQuery: "meeting",
            selectedCategories: Set([UUID()]),
            showCompleted: false,
            sortOrder: .dateCreated
        )
        
        // Should conform to State protocol
        XCTAssertNotNil(filter as any State)
        
        // Should be Equatable
        let sameFilter = TaskFilter(
            searchQuery: "meeting",
            selectedCategories: filter.selectedCategories,
            showCompleted: false,
            sortOrder: .dateCreated
        )
        XCTAssertEqual(filter, sameFilter)
        
        // Should be immutable
        let updated = filter.with(searchQuery: "project")
        XCTAssertNotEqual(filter.searchQuery, updated.searchQuery)
        XCTAssertEqual(filter.selectedCategories, updated.selectedCategories)
    }
    
    func testFilterActions() async {
        // Test filter-related actions
        // Framework insight: How granular should actions be?
        let client = await TaskTestHelpers.makeClient()
        
        // Set search query
        await client.send(.setSearchQuery("meeting"))
        
        // Toggle category filter
        let catId = UUID()
        await client.send(.toggleCategoryFilter(catId))
        
        // Set sort order
        await client.send(.setSortOrder(.priority))
        
        // Clear all filters
        await client.send(.clearFilters)
        
        let state = await client.state
        XCTAssertNotNil(state.filter)
    }
    
    func testFilterPersistence() async {
        // Test filter state persistence across sessions
        // Framework insight: Should filters be part of main state or separate?
        let filter = TaskFilter(
            searchQuery: "urgent",
            selectedCategories: Set([UUID(), UUID()]),
            showCompleted: true,
            sortOrder: .priority
        )
        
        // Filters should be codable for persistence
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(filter)
            let decoded = try decoder.decode(TaskFilter.self, from: data)
            
            XCTAssertEqual(filter.searchQuery, decoded.searchQuery)
            XCTAssertEqual(filter.selectedCategories, decoded.selectedCategories)
            XCTAssertEqual(filter.showCompleted, decoded.showCompleted)
            XCTAssertEqual(filter.sortOrder, decoded.sortOrder)
        } catch {
            XCTFail("Filter should be codable: \(error)")
        }
    }
    
    func testEmptyFilterState() async {
        // Test default/empty filter behavior
        // Framework insight: How to handle "no filter" state?
        let emptyFilter = TaskFilter()
        
        XCTAssertTrue(emptyFilter.searchQuery.isEmpty)
        XCTAssertTrue(emptyFilter.selectedCategories.isEmpty)
        XCTAssertTrue(emptyFilter.showCompleted)
        XCTAssertEqual(emptyFilter.sortOrder, .dateCreated)
        
        // Empty filter should show all tasks
        XCTAssertTrue(emptyFilter.isShowingAll)
    }
    
    func testFilterComposition() async {
        // Test combining multiple filter criteria
        // Framework insight: How to compose complex predicates?
        var filter = TaskFilter()
        
        // Add search query
        filter = filter.with(searchQuery: "project")
        XCTAssertFalse(filter.isShowingAll)
        
        // Add category filter
        let catId = UUID()
        filter = filter.with(selectedCategories: Set([catId]))
        
        // Hide completed
        filter = filter.with(showCompleted: false)
        
        // Should have all three filters active
        XCTAssertFalse(filter.searchQuery.isEmpty)
        XCTAssertFalse(filter.selectedCategories.isEmpty)
        XCTAssertFalse(filter.showCompleted)
    }
}