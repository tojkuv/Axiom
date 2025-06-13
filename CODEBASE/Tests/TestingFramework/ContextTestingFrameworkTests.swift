import XCTest
@testable import Axiom
@testable import AxiomTesting

/// Tests for the comprehensive Context Testing Framework
/// This validates that applications can easily test all aspects of their contexts
final class ContextTestingFrameworkTests: XCTestCase {
    
    // MARK: - Context State Testing
    
    func testContextStateAssertion() async throws {
        // RED Test: Context state testing utilities should make it easy to assert state changes
        let context = TestableTaskContext()
        
        // Should be able to assert initial state
        try await ContextTestHelpers.assertState(
            in: context,
            condition: { state in state.tasks.isEmpty },
            description: "Initial state should have no tasks"
        )
        
        // Should be able to assert state changes after actions
        await context.process(.addTask("Test Task"))
        
        try await ContextTestHelpers.assertState(
            in: context,
            condition: { state in state.tasks.count == 1 },
            description: "Should have one task after adding"
        )
        
        // Should be able to assert specific state values
        try await ContextTestHelpers.assertStateEquals(
            in: context,
            expected: TaskState(tasks: ["Test Task"], isLoading: false),
            description: "State should match expected after adding task"
        )
    }
    
    func testContextActionTesting() async throws {
        // RED Test: Action testing should validate action processing and state transitions
        let context = TestableTaskContext()
        
        // Should be able to test action sequences
        try await ContextTestHelpers.assertActionSequence(
            in: context,
            actions: [
                .addTask("Task 1"),
                .addTask("Task 2"), 
                .completeTask(0)
            ],
            expectedStates: [
                { state in state.tasks.count == 1 },
                { state in state.tasks.count == 2 },
                { state in state.tasks[0].isCompleted }
            ]
        )
        
        // Should be able to test action failures
        try await ContextTestHelpers.assertActionFails(
            in: context,
            action: .completeTask(999), // Invalid index
            expectedError: TaskError.invalidIndex
        )
    }
    
    func testContextLifecycleTesting() async throws {
        // RED Test: Lifecycle testing should validate appear/disappear behavior
        let context = TestableTaskContext()
        
        // Should track lifecycle events
        let lifecycleTracker = ContextLifecycleTracker(for: context)
        
        await context.onAppear()
        XCTAssertEqual(lifecycleTracker.appearCount, 1)
        XCTAssertTrue(lifecycleTracker.isActive)
        
        await context.onDisappear()
        XCTAssertEqual(lifecycleTracker.disappearCount, 1)
        XCTAssertFalse(lifecycleTracker.isActive)
        
        // Should validate lifecycle balance
        lifecycleTracker.assertBalanced()
    }
    
    // MARK: - Context Dependency Testing
    
    func testContextDependencyInjection() async throws {
        // RED Test: Should easily test dependency injection in contexts
        let mockClient = MockTaskClient()
        let mockPersistence = MockPersistenceCapability()
        
        let context = try await ContextTestHelpers.createContextWithDependencies(
            TestableTaskContext.self,
            dependencies: [
                .client(mockClient),
                .persistence(mockPersistence)
            ]
        )
        
        // Should be able to verify dependencies were injected
        try await ContextTestHelpers.assertDependency(
            in: context,
            type: TaskClient.self,
            matches: mockClient
        )
        
        // Should be able to test dependency interactions
        await context.process(.loadTasks)
        
        try await ContextTestHelpers.assertDependencyWasCalled(
            mockClient,
            method: "loadTasks"
        )
    }
    
    func testContextParentChildRelations() async throws {
        // RED Test: Should easily test parent-child context relationships
        let parentContext = TestableTaskListContext()
        let childContext = TestableTaskContext()
        
        // Should be able to establish parent-child relationship for testing
        try await ContextTestHelpers.establishParentChild(
            parent: parentContext,
            child: childContext
        )
        
        // Should be able to test child action propagation to parent
        await childContext.process(.deleteTask)
        
        try await ContextTestHelpers.assertChildActionReceived(
            by: parentContext,
            action: TaskContext.Action.deleteTask,
            from: childContext
        )
    }
    
    // MARK: - Context Memory Testing
    
    func testContextMemoryManagement() async throws {
        // RED Test: Should detect memory leaks in context usage
        try await ContextTestHelpers.assertNoMemoryLeaks {
            let context = TestableTaskContext()
            await context.onAppear()
            
            // Simulate heavy usage
            for i in 0..<1000 {
                await context.process(.addTask("Task \(i)"))
            }
            
            await context.onDisappear()
            // Context should be deallocated when this closure ends
        }
    }
    
    func testContextPerformanceBenchmarks() async throws {
        // RED Test: Should benchmark context performance
        let context = TestableTaskContext()
        
        let benchmark = try await ContextTestHelpers.benchmarkContext(context) {
            // Simulate typical usage pattern
            for i in 0..<100 {
                await context.process(.addTask("Task \(i)"))
            }
        }
        
        // Should meet performance requirements
        XCTAssertLessThan(benchmark.averageActionTime, 0.001) // 1ms per action
        XCTAssertLessThan(benchmark.memoryGrowth, 1024 * 1024) // 1MB growth max
    }
    
    // MARK: - Context Observation Testing
    
    func testContextObservationTesting() async throws {
        // RED Test: Should easily test context observation patterns
        let context = TestableTaskContext()
        
        // Should track published property changes
        let observer = try await ContextTestHelpers.observeContext(context)
        
        await context.process(.addTask("Test Task"))
        await context.process(.toggleLoading)
        
        // Should assert observation counts and values
        try await observer.assertChangeCount(2)
        try await observer.assertLastState { state in
            state.tasks.count == 1 && state.isLoading
        }
    }
    
    // MARK: - Context Mock Creation
    
    func testContextMockCreation() async throws {
        // RED Test: Should easily create context mocks for testing
        let mockContext = try await ContextTestHelpers.createMockContext(
            type: TaskContext.self,
            initialState: TaskState(tasks: ["Mock Task"], isLoading: false)
        )
        
        // Should be able to program mock behavior
        try await ContextTestHelpers.programMockContext(mockContext) {
            when(.addTask(any())).thenDo { action in
                // Custom mock behavior
            }
            when(.loadTasks).thenThrow(TaskError.networkError)
        }
        
        // Should be able to verify mock interactions
        await mockContext.process(.addTask("New Task"))
        
        try await ContextTestHelpers.assertMockWasCalled(
            mockContext,
            method: .addTask("New Task")
        )
    }
}

// MARK: - Test Support Types

struct TaskState: State, Equatable {
    var tasks: [String] = []
    var isLoading: Bool = false
}

enum TaskError: Error, Equatable {
    case invalidIndex
    case networkError
}

// Test context for validation
@MainActor
class TestableTaskContext: Context {
    @Published private(set) var state = TaskState()
    
    enum Action {
        case addTask(String)
        case completeTask(Int)
        case deleteTask
        case loadTasks
        case toggleLoading
    }
    
    func process(_ action: Action) async {
        switch action {
        case .addTask(let task):
            state.tasks.append(task)
        case .completeTask(let index):
            guard index < state.tasks.count else {
                // Should throw TaskError.invalidIndex in real implementation
                return
            }
        case .deleteTask:
            if !state.tasks.isEmpty {
                state.tasks.removeLast()
            }
        case .loadTasks:
            state.isLoading = true
            // Mock async operation
            try? await Task.sleep(for: .milliseconds(10))
            state.isLoading = false
        case .toggleLoading:
            state.isLoading.toggle()
        }
    }
    
    func onAppear() async {}
    func onDisappear() async {}
}

@MainActor
class TestableTaskListContext: Context {
    private(set) var receivedChildActions: [Any] = []
    
    func onAppear() async {}
    func onDisappear() async {}
    
    override func handleChildAction<T>(_ action: T, from child: Context) {
        receivedChildActions.append(action)
    }
}

// Mock types for dependency testing
actor MockTaskClient {
    private(set) var calledMethods: [String] = []
    
    func loadTasks() async throws -> [String] {
        calledMethods.append("loadTasks")
        return ["Mock Task 1", "Mock Task 2"]
    }
}

class MockPersistenceCapability: PersistenceCapability {
    func save<T: Codable>(_ value: T, for key: String) async throws {}
    func load<T: Codable>(_ type: T.Type, for key: String) async throws -> T? { nil }
    func delete(for key: String) async throws {}
}

protocol TaskClient {
    func loadTasks() async throws -> [String]
}