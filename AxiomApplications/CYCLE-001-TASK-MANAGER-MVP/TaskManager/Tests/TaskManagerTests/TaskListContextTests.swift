import XCTest
import Axiom
@testable import TaskManager

final class TaskListContextTests: XCTestCase {
    
    // MARK: - RED Phase: TaskListContext Tests
    
    func testTaskListContextConformsToProtocols() async {
        // Testing context protocol conformance
        // Framework insight: What protocols must contexts implement?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskListContext(client: client)
        
        // Should conform to Context protocol
        XCTAssertNotNil(context as any Context)
        
        // Should be MainActor-bound
        await MainActor.run {
            // Context operations should be on MainActor
            XCTAssertNotNil(context)
        }
    }
    
    func testTaskListContextClientBinding() async throws {
        // Test ClientObservingContext binds to client properly
        // Framework insight: How does auto-observation work?
        let tasks = [
            TaskTestHelpers.makeTask(title: "Task 1"),
            TaskTestHelpers.makeTask(title: "Task 2")
        ]
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        let context = await TaskListContext(client: client)
        
        // Use withContext helper to ensure proper lifecycle
        try await TaskTestHelpers.withContext(context) { ctx in
            // Wait for initial state sync
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            // Context should automatically observe client state
            await MainActor.run {
                XCTAssertEqual(ctx.state.tasks.count, 2)
            }
        }
    }
    
    func testTaskListContextStateUpdates() async throws {
        // Test automatic state updates through ClientObservingContext
        // Framework insight: Does state sync automatically?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskListContext(client: client)
        
        try await TaskTestHelpers.withContext(context) { ctx in
            // Add task through client
            await client.send(.addTask(title: "New Task", description: nil))
            
            // Context state should update automatically
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms for propagation
            
            await MainActor.run {
                XCTAssertEqual(ctx.state.tasks.count, 1)
                XCTAssertEqual(ctx.state.tasks.first?.title, "New Task")
            }
        }
    }
    
    func testTaskListContextActions() async {
        // Test context can send actions to client
        // Framework insight: How do contexts interact with clients?
        let client = await TaskTestHelpers.makeClient()
        let context = await TaskListContext(client: client)
        
        // Send action through context
        await MainActor.run {
            context.addTask(title: "Context Task", description: "Added via context")
        }
        
        // Verify client received action
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms for propagation
        
        let clientState = await client.state
        XCTAssertEqual(clientState.tasks.count, 1)
        XCTAssertEqual(clientState.tasks.first?.title, "Context Task")
    }
    
    func testTaskListContextNavigation() async {
        // Test navigation service integration
        // Framework insight: How do contexts handle navigation?
        let client = await TaskTestHelpers.makeClient()
        let mockNavigation = await MockNavigationService()
        let context = await TaskListContext(
            client: client,
            navigationService: mockNavigation
        )
        
        // Trigger navigation action
        await MainActor.run {
            context.showCreateTask()
        }
        
        // Verify navigation was triggered
        await MainActor.run {
            XCTAssertEqual(mockNavigation.presentedRoutes.count, 1)
            XCTAssertEqual(mockNavigation.presentedRoutes.first, TaskRoute.createTask)
        }
    }
    
    func testTaskListContextLifecycle() async {
        // Test context lifecycle management
        // Framework insight: How are contexts created/destroyed?
        let client = await TaskTestHelpers.makeClient()
        var context: TaskListContext? = await TaskListContext(client: client)
        
        // Verify context is active
        await MainActor.run {
            XCTAssertNotNil(context?.state)
        }
        
        // Simulate context destruction
        context = nil
        
        // Client should continue to exist independently
        let clientState = await client.state
        XCTAssertNotNil(clientState)
    }
}

// MARK: - Mock Navigation Service

@MainActor
final class MockNavigationService: TaskManager.NavigationService {
    var presentedRoutes: [TaskRoute] = []
    private(set) var dismissCallCount = 0
    
    func navigate(to route: TaskRoute) {
        presentedRoutes.append(route)
    }
    
    func dismiss() {
        dismissCallCount += 1
        _ = presentedRoutes.popLast()
    }
    
    var dismissCalled: Bool {
        dismissCallCount > 0
    }
}