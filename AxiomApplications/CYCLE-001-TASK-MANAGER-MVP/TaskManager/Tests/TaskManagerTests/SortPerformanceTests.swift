import XCTest
import Axiom
@testable import TaskManager

final class SortPerformanceTests: XCTestCase {
    
    // MARK: - RED Phase: Sort Performance Tests
    
    func testSortPerformanceWith10kTasks() async {
        // Test sort performance meets requirement: < 50ms for 10k tasks
        // Framework insight: How does framework handle large computed property operations?
        
        let tasks = (0..<10_000).map { i in
            let priorities: [Priority] = [.low, .medium, .high, .critical]
            return TaskTestHelpers.makeTask(
                title: "Task \(i)",
                priority: priorities[i % 4]
            )
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        // Test priority sorting performance
        let prioritySortStart = Date()
        await client.send(.setSortOrder(.priority))
        await client.send(.setSortDirection(.descending))
        
        let state = await client.state
        let _ = state.filteredTasks // Force computation of sorted tasks
        let prioritySortDuration = Date().timeIntervalSince(prioritySortStart)
        
        // Should complete in under 50ms
        XCTAssertLessThan(prioritySortDuration * 1000, 50, "Priority sort took \(prioritySortDuration * 1000)ms, should be < 50ms")
        
        // Verify sort actually worked
        let sortedTasks = state.filteredTasks
        XCTAssertEqual(sortedTasks.count, 10_000)
        XCTAssertTrue(sortedTasks[0].priority.rawValue >= sortedTasks[sortedTasks.count - 1].priority.rawValue)
    }
    
    func testMultiCriteriaSortPerformance() async {
        // Test performance of multi-criteria sorting
        // Framework insight: How expensive are compound sort operations?
        
        let now = Date()
        let tasks = (0..<5_000).map { i in
            let priorities: [Priority] = [.low, .medium, .high, .critical]
            let createdAt = now.addingTimeInterval(TimeInterval(-i * 60)) // Different times
            return TaskTestHelpers.makeTask(
                title: "Task \(i)",
                priority: priorities[i % 4],
                createdAt: createdAt
            )
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        // Test multi-criteria sort (priority + date)
        let multiSortStart = Date()
        await client.send(.setSortCriteria(.priority, secondary: .dateCreated, direction: .descending))
        
        let state = await client.state
        let _ = state.filteredTasks // Force computation
        let multiSortDuration = Date().timeIntervalSince(multiSortStart)
        
        // Should still be reasonably fast for multi-criteria
        XCTAssertLessThan(multiSortDuration * 1000, 100, "Multi-criteria sort took \(multiSortDuration * 1000)ms, should be < 100ms")
        
        // Verify correct sorting
        let sortedTasks = state.filteredTasks
        XCTAssertEqual(sortedTasks.count, 5_000)
        
        // First task should be highest priority, most recent
        XCTAssertEqual(sortedTasks[0].priority, .critical)
    }
    
    func testSortMemoryUsage() async {
        // Test memory usage during sorting operations
        // Framework insight: Does framework create unnecessary copies during sorting?
        
        let tasks = (0..<5_000).map { i in
            TaskTestHelpers.makeTask(title: "Task \(i)", priority: .medium)
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        // Measure memory before sort
        let memoryBefore = getMemoryUsage()
        
        // Perform multiple sort operations
        await client.send(.setSortOrder(.priority))
        let _ = await client.state.filteredTasks
        
        await client.send(.setSortOrder(.alphabetical))
        let _ = await client.state.filteredTasks
        
        await client.send(.setSortOrder(.dateCreated))
        let _ = await client.state.filteredTasks
        
        let memoryAfter = getMemoryUsage()
        let memoryIncrease = memoryAfter - memoryBefore
        
        // Memory increase should be reasonable (not creating many copies)
        // This is a rough check - exact values depend on implementation
        XCTAssertLessThan(memoryIncrease, 50_000_000, "Memory increased by \(memoryIncrease) bytes, seems excessive")
    }
    
    func testLiveSortingPerformance() async {
        // Test performance of frequent sort updates (simulating UI changes)
        // Framework insight: How does framework handle rapid state changes?
        
        let tasks = (0..<1_000).map { i in
            TaskTestHelpers.makeTask(title: "Task \(i)", priority: .medium)
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        let liveUpdateStart = Date()
        
        // Simulate rapid sort changes (like user clicking sort options quickly)
        for _ in 0..<20 {
            await client.send(.setSortOrder(.priority))
            await client.send(.setSortDirection(.ascending))
            let _ = await client.state.filteredTasks
            
            await client.send(.setSortOrder(.alphabetical))
            await client.send(.setSortDirection(.descending))
            let _ = await client.state.filteredTasks
            
            try? await Task.sleep(nanoseconds: 16_000_000) // ~60fps timing
        }
        
        let liveUpdateDuration = Date().timeIntervalSince(liveUpdateStart)
        
        // Should handle rapid updates smoothly
        XCTAssertLessThan(liveUpdateDuration, 2.0, "Live sorting took \(liveUpdateDuration)s, should be < 2s for smooth UX")
    }
    
    func testSortWithFilterCombinationPerformance() async {
        // Test performance when combining sort with existing filters
        // Framework insight: How do multiple computed properties interact?
        
        let categories = Category.defaultCategories
        let tasks = (0..<3_000).map { i in
            let priorities: [Priority] = [.low, .medium, .high, .critical]
            return TaskTestHelpers.makeTask(
                title: "Task \(i)",
                categoryId: categories[i % categories.count].id,
                priority: priorities[i % 4]
            )
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        // Set up complex filter + sort scenario
        let combinedStart = Date()
        
        await client.send(.setSearchQuery("Task"))
        await client.send(.toggleCategoryFilter(categories[0].id))
        await client.send(.setShowCompleted(false))
        await client.send(.setSortOrder(.priority))
        await client.send(.setSortDirection(.descending))
        
        let state = await client.state
        let _ = state.filteredTasks // Force computation of filtered AND sorted results
        
        let combinedDuration = Date().timeIntervalSince(combinedStart)
        
        // Combined filter + sort should still be fast
        XCTAssertLessThan(combinedDuration * 1000, 75, "Combined filter+sort took \(combinedDuration * 1000)ms, should be < 75ms")
        
        // Verify results are both filtered and sorted
        let results = state.filteredTasks
        XCTAssertLessThan(results.count, 3_000) // Should be filtered
        
        if results.count > 1 {
            // Should be sorted by priority (descending)
            XCTAssertTrue(results[0].priority.rawValue >= results[1].priority.rawValue)
        }
    }
    
    func testAnimationCoordinationTiming() async {
        // Test timing for animation coordination
        // Framework insight: How to coordinate state changes with animations?
        
        let tasks = (0..<100).map { i in
            TaskTestHelpers.makeTask(title: "Task \(i)", priority: .medium)
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        // Measure time for sort change that would trigger animation
        let animationStart = Date()
        await client.send(.setSortOrder(.priority))
        let sortChangeTime = Date().timeIntervalSince(animationStart)
        
        // Sort change should be fast enough to coordinate with 60fps animations
        let frameTime = 1.0 / 60.0 // ~16.67ms per frame
        XCTAssertLessThan(sortChangeTime, frameTime, "Sort change took \(sortChangeTime * 1000)ms, should be < 16.67ms for 60fps")
        
        // Test multiple rapid changes (animation-driven updates)
        let rapidChangesStart = Date()
        for i in 0..<10 {
            if i % 2 == 0 {
                await client.send(.setSortDirection(.ascending))
            } else {
                await client.send(.setSortDirection(.descending))
            }
            try? await Task.sleep(nanoseconds: 16_000_000) // 60fps timing
        }
        let rapidChangesTime = Date().timeIntervalSince(rapidChangesStart)
        
        // Should maintain 60fps throughout animation sequence
        XCTAssertLessThan(rapidChangesTime, 0.5, "Rapid sort changes took \(rapidChangesTime)s, should maintain smooth animation")
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
}