import XCTest
import Axiom
@testable import TaskManager

final class TaskFilterContextTests: XCTestCase {
    
    // MARK: - RED Phase: Filter Context Tests
    
    func testTaskFilterContextInitialization() async {
        // Test filter context setup
        // Framework insight: How to manage filter UI state?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskFilterContext(client: client)
        
        // Start observing
        await context.onAppear()
        
        // Wait for context to sync with client state
        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
        
        await MainActor.run {
            // Should start with default filter state
            XCTAssertEqual(context.searchQuery, "")
            XCTAssertTrue(context.selectedCategories.isEmpty)
            XCTAssertTrue(context.showCompleted)
            XCTAssertEqual(context.sortOrder, .dateCreated)
            
            // Should have categories available or be empty initially
            // Note: Categories may be populated asynchronously
            // so we just verify the property exists
            XCTAssertNotNil(context.availableCategories)
        }
    }
    
    func testSearchQueryBinding() async {
        // Test search query updates
        // Framework insight: How to handle text field bindings?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskFilterContext(client: client)
        
        await MainActor.run {
            // Update search query using the proper method
            context.updateSearchQuery("meeting")
        }
        
        // Should debounce before sending to client
        try? await Task.sleep(nanoseconds: 350_000_000) // 350ms for debounce
        
        // Client should receive the search action
        let state = await client.state
        XCTAssertEqual(state.filter?.searchQuery, "meeting")
    }
    
    func testCategoryToggle() async {
        // Test category selection
        // Framework insight: How to handle multi-select?
        let categories = Category.defaultCategories
        let client = await TaskTestHelpers.makeClient()
        await client.send(.setCategories(categories))
        
        let context = await TaskFilterContext(client: client)
        
        await MainActor.run {
            // Toggle category on
            let workCat = categories.first { $0.name == "Work" }!
            context.toggleCategory(workCat.id)
            
            XCTAssertTrue(context.selectedCategories.contains(workCat.id))
            XCTAssertTrue(context.isCategorySelected(workCat.id))
        }
        
        // Toggle same category off
        await MainActor.run {
            let workCat = categories.first { $0.name == "Work" }!
            context.toggleCategory(workCat.id)
            
            XCTAssertFalse(context.selectedCategories.contains(workCat.id))
            XCTAssertFalse(context.isCategorySelected(workCat.id))
        }
    }
    
    func testSortOrderChange() async {
        // Test sort order updates
        // Framework insight: How to handle picker bindings?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskFilterContext(client: client)
        
        await MainActor.run {
            // Change sort order using the proper method
            context.updateSortOrder(.alphabetical)
        }
        
        // Wait a bit for async update
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // Should update immediately (no debounce for pickers)
        let state = await client.state
        XCTAssertEqual(state.filter?.sortOrder, .alphabetical)
    }
    
    func testClearAllFilters() async {
        // Test clearing all filters at once
        // Framework insight: Batch updates vs individual?
        let categories = Category.defaultCategories
        let client = await TaskTestHelpers.makeClient()
        await client.send(.setCategories(categories))
        
        let context = await TaskFilterContext(client: client)
        
        // Set multiple filters
        await MainActor.run {
            context.updateSearchQuery("test")
            context.toggleCategory(categories[0].id)
            context.updateShowCompleted(false)
            context.updateSortOrder(.priority)
        }
        
        // Clear all
        await MainActor.run {
            context.clearAllFilters()
        }
        
        // Everything should be reset
        await MainActor.run {
            XCTAssertEqual(context.searchQuery, "")
            XCTAssertTrue(context.selectedCategories.isEmpty)
            XCTAssertTrue(context.showCompleted)
            XCTAssertEqual(context.sortOrder, .dateCreated)
        }
    }
    
    func testFilterSummary() async {
        // Test generating human-readable filter summary
        // Framework insight: Computed properties for UI?
        let categories = Category.defaultCategories
        let client = await TaskTestHelpers.makeClient()
        await client.send(.setCategories(categories))
        
        let context = await TaskFilterContext(client: client)
        
        // Start observing
        await context.onAppear()
        
        // Wait for context to sync with client state
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        await MainActor.run {
            // No filters
            XCTAssertEqual(context.filterSummary, "All tasks")
            
            // Search only
            context.searchQuery = "meeting"
            XCTAssertTrue(context.filterSummary.contains("meeting"))
            
            // Add category
            context.toggleCategory(categories[0].id)
            XCTAssertTrue(context.filterSummary.contains(categories[0].name))
            
            // Hide completed
            context.showCompleted = false
            XCTAssertTrue(context.filterSummary.contains("active"))
        }
    }
}