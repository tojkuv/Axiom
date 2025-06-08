import XCTest
import Axiom
@testable import TaskManager

final class SearchTests: XCTestCase {
    var client: TaskClient!
    var state: TaskState!
    
    override func setUp() async throws {
        client = makeClient()
        state = await client.state
        
        // Add test tasks with searchable content
        await client.send(.addTask(
            title: "Buy groceries",
            description: "Milk, bread, eggs",
            categoryId: nil,
            priority: .medium,
            dueDate: nil,
            createdAt: nil
        ))
        await client.send(.addTask(
            title: "Call dentist",
            description: "Schedule appointment",
            categoryId: nil,
            priority: .medium,
            dueDate: nil,
            createdAt: nil
        ))
        await client.send(.addTask(
            title: "Review proposal", 
            description: "Important client proposal",
            categoryId: nil,
            priority: .medium,
            dueDate: nil,
            createdAt: nil
        ))
    }
    
    func testSearchByTitle() async throws {
        // Search should find tasks by title
        await client.send(.setSearchQuery("groceries"))
        
        let results = await client.state.filteredTasks
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Buy groceries")
    }
    
    func testSearchByDescription() async throws {
        // Search should find tasks by description
        await client.send(.setSearchQuery("appointment"))
        
        let results = await client.state.filteredTasks
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Call dentist")
    }
    
    func testSearchCaseInsensitive() async throws {
        // Search should be case insensitive
        await client.send(.setSearchQuery("PROPOSAL"))
        
        let results = await client.state.filteredTasks
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Review proposal")
    }
    
    func testSearchPartialMatch() async throws {
        // Search should support partial matching
        await client.send(.setSearchQuery("call"))
        
        let results = await client.state.filteredTasks
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Call dentist")
    }
    
    func testSearchEmptyQuery() async throws {
        // Empty search should show all tasks
        await client.send(.setSearchQuery(""))
        
        let results = await client.state.filteredTasks
        XCTAssertEqual(results.count, 3)
    }
    
    func testSearchNoResults() async throws {
        // Search with no matches should return empty
        await client.send(.setSearchQuery("xyz123"))
        
        let results = await client.state.filteredTasks
        XCTAssertEqual(results.count, 0)
    }
    
    func testSearchWithOtherFilters() async throws {
        // Search should combine with other filters
        // Mark second task as complete
        let task2 = await client.state.tasks.first(where: { $0.title == "Call dentist" })!
        await client.send(.toggleTaskCompletion(id: task2.id))
        await client.send(.setShowCompleted(false))
        await client.send(.setSearchQuery("proposal"))
        
        let results = await client.state.filteredTasks
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Review proposal")
    }
    
    func testSearchQueryPersistence() async throws {
        // Search query should persist in state
        await client.send(.setSearchQuery("test query"))
        let currentQuery = await client.state.searchQuery
        XCTAssertEqual(currentQuery, "test query")
    }
}

// MARK: - Test Helpers
private func makeClient() -> TaskClient {
    TaskClient()
}