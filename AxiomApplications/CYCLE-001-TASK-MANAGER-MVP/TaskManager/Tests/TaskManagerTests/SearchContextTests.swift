import XCTest
import Axiom
import SwiftUI
import Combine
@testable import TaskManager

@MainActor
final class SearchContextTests: XCTestCase {
    var client: TaskClient!
    var context: SearchContext!
    
    override func setUp() async throws {
        client = makeClient()
        
        // Add test data before creating context
        await client.send(.addTask(title: "First task", description: nil, categoryId: nil, priority: .medium, dueDate: nil, createdAt: nil))
        await client.send(.addTask(title: "Second task", description: nil, categoryId: nil, priority: .medium, dueDate: nil, createdAt: nil))
        await client.send(.addTask(title: "Third task", description: nil, categoryId: nil, priority: .medium, dueDate: nil, createdAt: nil))
        
        // Create context after data is added
        context = SearchContext(client: client)
        
        // Start context lifecycle (needed for observation)
        await context.onAppear()
        
        // Wait for initial sync
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
    }
    
    func testSearchContextInitialization() async throws {
        // Context should initialize with empty search
        XCTAssertEqual(context.searchQuery, "")
        XCTAssertFalse(context.isSearching)
        XCTAssertEqual(context.resultCount, 3)
    }
    
    func testSearchQueryBinding() async throws {
        // Setting search query should update results
        context.searchQuery = "first"
        
        // Wait for search to complete (debounce + action + state update)
        await context.waitForSearchCompletion()
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms to ensure debounce completes
        
        XCTAssertTrue(context.isSearching)
        XCTAssertEqual(context.resultCount, 1)
    }
    
    func testClearSearch() async throws {
        // Set a search query
        context.searchQuery = "task"
        await context.waitForSearchCompletion()
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for debounce
        
        // Clear search
        context.clearSearch()
        try await Task.sleep(nanoseconds: 100_000_000) // Wait for clear to propagate
        
        XCTAssertEqual(context.searchQuery, "")
        XCTAssertFalse(context.isSearching)
        XCTAssertEqual(context.resultCount, 3)
    }
    
    func testSearchResultsUpdate() async throws {
        // Subscribe to results
        var receivedResults: [TaskItem] = []
        let cancellable = context.$searchResults.sink { results in
            receivedResults = results
        }
        defer { cancellable.cancel() }
        
        // Perform search
        context.searchQuery = "second"
        await context.waitForSearchCompletion()
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for debounce
        
        XCTAssertEqual(receivedResults.count, 1)
        XCTAssertEqual(receivedResults.first?.title, "Second task")
    }
    
    func testSearchWithNoResults() async throws {
        context.searchQuery = "nonexistent"
        await context.waitForSearchCompletion()
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for debounce
        
        XCTAssertTrue(context.isSearching)
        XCTAssertEqual(context.resultCount, 0)
        XCTAssertTrue(context.hasNoResults)
    }
    
    func testDebouncedSearch() async throws {
        // Test that rapid changes only result in one search
        let initialQuery = await client.state.searchQuery
        XCTAssertEqual(initialQuery, "")
        
        // Simulate rapid typing
        context.searchQuery = "t"
        context.searchQuery = "ta"
        context.searchQuery = "tas"
        context.searchQuery = "task"
        
        // Query should not have been sent to client yet
        let immediateQuery = await client.state.searchQuery
        XCTAssertEqual(immediateQuery, "")
        
        // Wait for search to complete
        await context.waitForSearchCompletion()
        try await Task.sleep(nanoseconds: 500_000_000) // Wait for debounce
        
        // Now the query should be set
        let finalQuery = await client.state.searchQuery
        XCTAssertEqual(finalQuery, "task")
    }
}

// MARK: - Test Helpers
private func makeClient() -> TaskClient {
    TaskClient()
}