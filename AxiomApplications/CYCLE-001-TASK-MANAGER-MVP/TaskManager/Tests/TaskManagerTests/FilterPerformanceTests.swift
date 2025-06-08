import XCTest
import Axiom
@testable import TaskManager

final class FilterPerformanceTests: XCTestCase {
    
    // MARK: - RED Phase: Filter Performance Tests
    
    func testFilterPerformanceWith1000Tasks() async {
        // Test filter performance with moderate dataset
        // Framework insight: How does framework handle computed properties?
        let tasks = (0..<1000).map { i in
            TaskTestHelpers.makeTask(
                title: "Task \(i)",
                description: i % 2 == 0 ? "Important meeting" : "Regular task",
                isCompleted: i % 3 == 0
            )
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        // Measure search filter performance
        let searchStart = Date()
        await client.send(.setSearchQuery("meeting"))
        let searchDuration = Date().timeIntervalSince(searchStart)
        
        // Should complete within 16ms (one frame)
        XCTAssertLessThan(searchDuration * 1000, 16, "Search filter took \(searchDuration * 1000)ms")
        
        // Verify filtered results
        let state = await client.state
        let filtered = state.filteredTasks
        XCTAssertTrue(filtered.count < tasks.count)
        XCTAssertTrue(filtered.allSatisfy { $0.description?.contains("meeting") ?? false })
    }
    
    func testFilterPerformanceWith10000Tasks() async {
        // Test filter performance with large dataset
        // Framework insight: When do we need memoization?
        let categories = Category.defaultCategories
        let tasks = (0..<10000).map { i in
            TaskTestHelpers.makeTask(
                title: "Task \(i)",
                description: "Description for task \(i)",
                categoryId: categories[i % categories.count].id,
                isCompleted: i % 5 == 0
            )
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        // Measure category filter performance
        let categoryStart = Date()
        let catId = categories[0].id
        await client.send(.toggleCategoryFilter(catId))
        let categoryDuration = Date().timeIntervalSince(categoryStart)
        
        // Should complete within 16ms for smooth UI
        XCTAssertLessThan(categoryDuration * 1000, 16, "Category filter took \(categoryDuration * 1000)ms")
        
        // Measure combined filters performance
        let combinedStart = Date()
        await client.send(.setSearchQuery("5"))
        await client.send(.toggleCategoryFilter(categories[1].id))
        await client.send(.setSortOrder(.alphabetical))
        let combinedDuration = Date().timeIntervalSince(combinedStart)
        
        // Combined filters should still be responsive
        XCTAssertLessThan(combinedDuration * 1000, 50, "Combined filters took \(combinedDuration * 1000)ms")
    }
    
    func testSortPerformance() async {
        // Test sort performance with different criteria
        // Framework insight: How efficient are sort operations?
        let tasks = (0..<5000).map { i in
            TaskTestHelpers.makeTask(
                title: "Task \(String(format: "%04d", 5000 - i))", // Reverse order
                createdAt: Date().addingTimeInterval(Double(i) * -3600) // Hours ago
            )
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        // Test each sort order
        for sortOrder in SortOrder.allCases {
            // Set ascending direction for consistent testing
            await client.send(.setSortDirection(.ascending))
            
            let sortStart = Date()
            await client.send(.setSortOrder(sortOrder))
            let sortDuration = Date().timeIntervalSince(sortStart)
            
            // Sort should be fast
            XCTAssertLessThan(sortDuration * 1000, 50, "\(sortOrder) sort took \(sortDuration * 1000)ms")
            
            // Verify sort is stable
            let state = await client.state
            let sorted = state.filteredTasks
            
            // Check first few items are in expected order (ascending)
            switch sortOrder {
            case .alphabetical:
                if sorted.count > 1 {
                    XCTAssertTrue(sorted[0].title <= sorted[1].title)
                }
            case .dateCreated:
                if sorted.count > 1 {
                    XCTAssertTrue(sorted[0].createdAt <= sorted[1].createdAt)
                }
            case .priority:
                if sorted.count > 1 {
                    XCTAssertTrue(sorted[0].priority.numericValue <= sorted[1].priority.numericValue)
                }
            default:
                break // Other sort orders need due date
            }
        }
    }
    
    func testFilterMemoryUsage() async {
        // Test memory impact of filtering
        // Framework insight: Does filtering create copies or use views?
        let tasks = (0..<10000).map { i in
            TaskTestHelpers.makeTask(title: "Task \(i)")
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        // Get baseline memory
        let baselineState = await client.state
        let baselineSize = MemoryLayout.size(ofValue: baselineState)
        
        // Apply multiple filters
        await client.send(.setSearchQuery("5"))
        await client.send(.toggleCategoryFilter(UUID()))
        await client.send(.setSortOrder(.alphabetical))
        
        // Check filtered state memory
        let filteredState = await client.state
        let filteredSize = MemoryLayout.size(ofValue: filteredState)
        
        // Memory shouldn't double with filters
        XCTAssertLessThan(
            Double(filteredSize), 
            Double(baselineSize) * 2.0,
            "Filtered state uses too much memory"
        )
    }
    
    func testLiveFilteringPerformance() async {
        // Test performance during rapid filter changes (typing)
        // Framework insight: Do we need debouncing?
        let tasks = (0..<1000).map { i in
            TaskTestHelpers.makeTask(title: "Task number \(i)")
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        // Simulate rapid typing
        let queries = ["T", "Ta", "Tas", "Task", "Task ", "Task n", "Task nu", "Task num"]
        
        let typingStart = Date()
        for query in queries {
            await client.send(.setSearchQuery(query))
            // Small delay to simulate typing speed
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        let typingDuration = Date().timeIntervalSince(typingStart)
        
        // Should handle rapid updates smoothly
        let avgUpdateTime = (typingDuration * 1000) / Double(queries.count)
        XCTAssertLessThan(avgUpdateTime, 100, "Average update time \(avgUpdateTime)ms is too slow")
        
        // Final results should be correct
        let state = await client.state
        let filtered = state.filteredTasks
        XCTAssertTrue(filtered.allSatisfy { $0.title.contains("Task num") })
    }
}