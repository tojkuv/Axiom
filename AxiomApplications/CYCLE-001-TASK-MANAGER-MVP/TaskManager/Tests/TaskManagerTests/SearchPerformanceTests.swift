import XCTest
import Axiom
@testable import TaskManager

final class SearchPerformanceTests: XCTestCase {
    var client: TaskClient!
    
    override func setUp() async throws {
        client = makeClient()
    }
    
    func testSearchPerformanceWith100Tasks() async throws {
        // Generate 100 tasks
        for i in 1...100 {
            await client.send(.addTask(
                title: "Task \(i) - \(randomTitle(i))",
                description: "Description for task \(i) with \(randomContent(i))",
                categoryId: nil,
                priority: .medium,
                dueDate: nil,
                createdAt: nil
            ))
        }
        
        // Measure search performance
        let start = Date()
        await client.send(.setSearchQuery("important"))
        let duration = Date().timeIntervalSince(start)
        
        // Should complete within 5ms
        XCTAssertLessThan(duration, 0.005, "Search took \(duration * 1000)ms")
        
        // Verify search works
        let resultCount = await client.state.filteredTasks.count
        XCTAssertGreaterThan(resultCount, 0)
    }
    
    func testSearchPerformanceWith1000Tasks() async throws {
        // Generate 1000 tasks
        for i in 1...1000 {
            await client.send(.addTask(
                title: "Task \(i) - \(randomTitle(i))",
                description: "Description for task \(i) with \(randomContent(i))",
                categoryId: nil,
                priority: .medium,
                dueDate: nil,
                createdAt: nil
            ))
        }
        
        // Measure search performance
        let start = Date()
        await client.send(.setSearchQuery("meeting"))
        let duration = Date().timeIntervalSince(start)
        
        // Should complete within 50ms
        XCTAssertLessThan(duration, 0.050, "Search took \(duration * 1000)ms")
    }
    
    func testEmptySearchPerformance() async throws {
        // Generate 1000 tasks
        for i in 1...1000 {
            await client.send(.addTask(
                title: "Task \(i)",
                description: "Description \(i)",
                categoryId: nil,
                priority: .medium,
                dueDate: nil,
                createdAt: nil
            ))
        }
        
        // Set a search query first
        await client.send(.setSearchQuery("test"))
        
        // Measure clearing search
        let start = Date()
        await client.send(.setSearchQuery(""))
        let duration = Date().timeIntervalSince(start)
        
        // Clearing should be fast
        XCTAssertLessThan(duration, 0.010, "Clear search took \(duration * 1000)ms")
        let clearedCount = await client.state.filteredTasks.count
        XCTAssertEqual(clearedCount, 1000)
    }
    
    func testIncrementalSearchPerformance() async throws {
        // Generate 500 tasks
        for i in 1...500 {
            await client.send(.addTask(
                title: randomTitle(i),
                description: randomContent(i),
                categoryId: nil,
                priority: .medium,
                dueDate: nil,
                createdAt: nil
            ))
        }
        
        // Simulate incremental typing
        let queries = ["m", "me", "mee", "meet", "meeti", "meetin", "meeting"]
        var totalDuration: TimeInterval = 0
        
        for query in queries {
            let start = Date()
            await client.send(.setSearchQuery(query))
            totalDuration += Date().timeIntervalSince(start)
        }
        
        // Average search time should be reasonable
        let avgDuration = totalDuration / Double(queries.count)
        XCTAssertLessThan(avgDuration, 0.020, "Average search took \(avgDuration * 1000)ms")
    }
}

// MARK: - Test Helpers
private func makeClient() -> TaskClient {
    TaskClient()
}

private func randomTitle(_ seed: Int) -> String {
    let titles = ["Meeting", "Review", "Important", "Urgent", "Project", "Task", "Work", "Personal"]
    return titles[seed % titles.count]
}

private func randomContent(_ seed: Int) -> String {
    let contents = ["meeting notes", "important deadline", "review document", "urgent matter", "project planning", "task details", "work items", "personal reminder"]
    return contents[seed % contents.count]
}