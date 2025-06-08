import Foundation
import XCTest
import SwiftUI
import Axiom
@testable import TaskManager

// MARK: - Test Helpers extracted during REFACTOR phase

enum TaskTestHelpers {
    
    /// Creates a test task with default values
    static func makeTask(
        id: UUID = UUID(),
        title: String = "Test Task",
        description: String? = nil,
        categoryId: UUID? = nil,
        priority: Priority = .medium,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        dueDate: Date? = nil
    ) -> TaskItem {
        TaskItem(
            id: id,
            title: title,
            description: description,
            categoryId: categoryId,
            priority: priority,
            isCompleted: isCompleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            dueDate: dueDate
        )
    }
    
    /// Creates a test client with optional initial tasks
    static func makeClient(with tasks: [TaskItem] = []) async -> TaskClient {
        let client = TaskClient()
        
        // Populate with initial tasks if provided
        for task in tasks {
            await client.send(.addTask(
                title: task.title,
                description: task.description,
                categoryId: task.categoryId,
                priority: task.priority,
                dueDate: task.dueDate,
                createdAt: task.createdAt
            ))
            // Wait for state to propagate
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        return client
    }
    
    /// Asserts that a client's state contains expected tasks
    static func assertTasks(
        in client: TaskClient,
        expectedCount: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let state = await client.state
        XCTAssertEqual(
            state.tasks.count,
            expectedCount,
            "Expected \(expectedCount) tasks, found \(state.tasks.count)",
            file: file,
            line: line
        )
    }
    
    /// Waits for state stream updates with timeout
    static func waitForStateUpdates(
        from client: TaskClient,
        updateCount: Int,
        timeout: TimeInterval = 1.0,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> [TaskState] {
        var receivedStates: [TaskState] = []
        let expectation = XCTestExpectation(description: "Received \(updateCount) state updates")
        
        Task {
            for await state in await client.stateStream {
                receivedStates.append(state)
                if receivedStates.count >= updateCount {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        let result = await XCTWaiter.fulfillment(of: [expectation], timeout: timeout)
        
        XCTAssertEqual(
            result,
            .completed,
            "Timeout waiting for \(updateCount) state updates",
            file: file,
            line: line
        )
        
        return receivedStates
    }
}

// MARK: - Client Test Extensions

// sendAndWait is now provided by TaskClient in DEBUG builds

// MARK: - State Test Extensions

extension TaskState {
    /// Test helper to find task by title
    func task(withTitle title: String) -> TaskItem? {
        tasks.first { $0.title == title }
    }
    
    /// Test helper to check if error matches expected type
    func hasError(_ expectedError: TaskError) -> Bool {
        guard let error = error else { return false }
        return error == expectedError
    }
}

// MARK: - Context Test Helpers (Added during REFACTOR)

extension TaskTestHelpers {
    /// Creates a test context with optional initial state
    @MainActor
    static func makeContext(
        with tasks: [TaskItem] = [],
        navigationService: TaskManager.NavigationService? = nil,
        client: TaskClient? = nil
    ) async -> TaskListContext {
        let taskClient: TaskClient
        if let client = client {
            taskClient = client
        } else {
            taskClient = await makeClient(with: tasks)
        }
        let context = TaskListContext(client: taskClient, navigationService: navigationService)
        // Ensure context lifecycle is started
        await context.onAppear()
        return context
    }
    
    /// Waits for context lifecycle to complete
    @MainActor
    static func withContext<T>(
        _ context: T,
        test: @escaping (T) async throws -> Void
    ) async throws where T: Context {
        await context.onAppear()
        defer {
            Task { await context.onDisappear() }
        }
        try await test(context)
    }
}

// MARK: - View Test Helpers

@MainActor
struct TestView<T: Context>: View {
    let context: T
    let content: (T) -> AnyView
    
    var body: some View {
        content(context)
            .contextLifecycle(context)
    }
}