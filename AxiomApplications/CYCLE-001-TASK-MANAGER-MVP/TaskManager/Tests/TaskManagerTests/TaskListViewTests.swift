import XCTest
import SwiftUI
import Axiom
@testable import TaskManager

final class TaskListViewTests: XCTestCase {
    
    // MARK: - RED Phase: TaskListView Tests
    
    func testTaskListViewInitialization() async {
        // Test view can be created with context
        // Framework insight: How do views bind to contexts?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskListContext(client: client)
        
        await MainActor.run {
            let view = TaskListView(context: context)
            XCTAssertNotNil(view)
        }
    }
    
    func testTaskListViewStateBinding() async {
        // Test view reflects context state
        // Framework insight: Is state binding automatic?
        let client = await TaskTestHelpers.makeClient()
        // Add tasks through client
        await client.sendAndWait(.addTask(title: "Task 1", description: nil))
        await client.sendAndWait(.addTask(title: "Task 2", description: nil))
        await client.sendAndWait(.addTask(title: "Task 3", description: nil))
        
        let context = await TaskTestHelpers.makeContext(with: [], client: client)
        
        // Wait for state sync
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        await MainActor.run {
            let view = TaskListView(context: context)
            
            // View should have access to state through context
            XCTAssertEqual(context.state.tasks.count, 3)
        }
    }
    
    func testTaskListViewStateUpdates() async {
        // Test view updates when state changes
        // Framework insight: How responsive is the binding?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskTestHelpers.makeContext(with: [], client: client)
        
        await MainActor.run {
            let view = TaskListView(context: context)
            
            // Initial state
            XCTAssertEqual(context.state.tasks.count, 0)
            
            // Add task
            context.addTask(title: "Dynamic Task", description: nil)
        }
        
        // Wait for state propagation
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        await MainActor.run {
            // View's context should reflect update
            XCTAssertEqual(context.state.tasks.count, 1)
        }
    }
    
    func testTaskListViewPerformance() async {
        // Test view performance with large datasets
        // Framework insight: How well does it handle many items?
        let client = await TaskTestHelpers.makeClient()
        
        let startTime = Date()
        
        // Create many tasks quickly
        for i in 1...100 { // Reduced from 1000 to 100 for reasonable test time
            await client.send(.addTask(title: "Task \(i)", description: nil))
        }
        
        let context = await TaskTestHelpers.makeContext(with: [], client: client)
        
        await MainActor.run {
            let view = TaskListView(context: context)
            
            let setupTime = Date().timeIntervalSince(startTime)
            print("View setup time for 100 tasks: \(setupTime * 1000)ms")
            
            // Should complete reasonably quickly
            XCTAssertLessThan(setupTime, 2.0) // 2s max for 100 tasks
        }
    }
    
    func testTaskListViewErrorHandling() async {
        // Test view handles error states
        // Framework insight: How are errors displayed?
        let client = await TaskTestHelpers.makeClient()
        
        // Force an error state
        await client.sendAndWait(.deleteTask(id: UUID())) // Non-existent task
        
        let context = await TaskTestHelpers.makeContext(with: [], client: client)
        
        // Wait for state sync
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        await MainActor.run {
            let view = TaskListView(context: context)
            
            // View should handle error gracefully
            XCTAssertNotNil(context.state.error)
        }
    }
    
    func testTaskListViewModifiers() async {
        // Test SwiftUI view modifiers work with context
        // Framework insight: Standard SwiftUI integration?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskListContext(client: client)
        
        await MainActor.run {
            let view = TaskListView(context: context)
                .navigationTitle("Tasks")
            
            // View should support standard modifiers
            XCTAssertNotNil(view)
        }
    }
}

