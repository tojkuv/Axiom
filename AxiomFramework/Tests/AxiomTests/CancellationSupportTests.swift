import XCTest
@testable import Axiom

final class CancellationSupportTests: XCTestCase {
    
    // MARK: - RED: Cancellation Support Tests
    
    func testUncancellableNavigationLeavesStateUnchanged() async throws {
        // Requirement: In-flight navigation cancellable via Swift concurrency Task cancellation
        // Acceptance: Cancelled navigation leaves state unchanged with rapid requests cancelling previous pending navigations
        // Boundary: Task cancellation propagates to all navigation-triggered operations
        
        // RED Test: Cancelling navigation should leave state unchanged
        
        let navigator = CancellableNavigationService<TestRoute>()
        let initialRoute = TestRoute.home
        
        // Set initial state
        try await navigator.navigate(to: initialRoute)
        let initialState = await navigator.currentState
        XCTAssertEqual(initialState.currentRoute, initialRoute)
        
        // Start navigation that can be cancelled
        let navigationTask = Task {
            try await navigator.navigateWithDelay(to: TestRoute.detail(id: "test"), delay: 0.1)
        }
        
        // Cancel before completion
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        navigationTask.cancel()
        
        // Wait for cancellation to process
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // State should remain unchanged
        let finalState = await navigator.currentState
        XCTAssertEqual(finalState.currentRoute, initialRoute, "Cancelled navigation should not change state")
        XCTAssertEqual(finalState.pendingRoute, nil, "No pending route should remain after cancellation")
    }
    
    func testRapidNavigationRequestsCancelPrevious() async throws {
        // Test that rapid navigation requests cancel previous pending navigations
        
        let navigator = CancellableNavigationService<TestRoute>()
        let initialRoute = TestRoute.home
        
        try await navigator.navigate(to: initialRoute)
        
        // Track which navigations complete
        var completedNavigations: [TestRoute] = []
        let completionHandler: (TestRoute) -> Void = { route in
            completedNavigations.append(route)
        }
        
        // Start multiple rapid navigation requests
        let routes = [
            TestRoute.detail(id: "1"),
            TestRoute.detail(id: "2"),
            TestRoute.detail(id: "3"),
            TestRoute.settings
        ]
        
        var tasks: [Task<Void, Error>] = []
        for route in routes {
            let task = Task {
                try await navigator.navigateWithDelay(
                    to: route,
                    delay: 0.1,
                    onCompletion: completionHandler
                )
            }
            tasks.append(task)
            
            // Small delay to ensure ordering
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        // Wait for all tasks to complete or cancel
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Only the last navigation should complete
        let currentState = await navigator.currentState
        XCTAssertEqual(currentState.currentRoute, TestRoute.settings, "Only last navigation should succeed")
        XCTAssertEqual(completedNavigations.count, 1, "Only one navigation should complete")
        XCTAssertEqual(completedNavigations.first, TestRoute.settings, "Last route should be the one that completed")
        
        // Previous tasks should be cancelled
        let cancelledCount = tasks.dropLast().filter { $0.isCancelled }.count
        XCTAssertEqual(cancelledCount, 3, "All but last navigation should be cancelled")
    }
    
    func testTaskCancellationPropagatestoAllOperations() async throws {
        // Test that task cancellation propagates to all navigation-triggered operations
        
        let coordinator = TestNavigationCoordinator<TestRoute>()
        var operationsCancelled: Set<String> = []
        
        // Configure operations that track cancellation
        await coordinator.configureOperations([
            "loadData": { isCancelled in
                if await isCancelled() {
                    operationsCancelled.insert("loadData")
                    throw CancellationError()
                }
                try await Task.sleep(nanoseconds: 100_000_000)
            },
            "updateUI": { isCancelled in
                if await isCancelled() {
                    operationsCancelled.insert("updateUI")
                    throw CancellationError()
                }
                try await Task.sleep(nanoseconds: 100_000_000)
            },
            "logAnalytics": { isCancelled in
                if await isCancelled() {
                    operationsCancelled.insert("logAnalytics")
                    throw CancellationError()
                }
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        ])
        
        // Start navigation with multiple operations
        let navigationTask = Task {
            try await coordinator.navigateWithOperations(to: TestRoute.detail(id: "test"))
        }
        
        // Cancel after operations start
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        navigationTask.cancel()
        
        // Wait for cancellation to propagate
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
        // All operations should report cancellation
        XCTAssertEqual(operationsCancelled.count, 3, "All operations should detect cancellation")
        XCTAssertTrue(operationsCancelled.contains("loadData"), "Data loading should be cancelled")
        XCTAssertTrue(operationsCancelled.contains("updateUI"), "UI update should be cancelled")
        XCTAssertTrue(operationsCancelled.contains("logAnalytics"), "Analytics should be cancelled")
        
        // Navigation state should remain unchanged
        let finalState = await coordinator.currentState
        XCTAssertNotEqual(finalState.currentRoute, TestRoute.detail(id: "test"), "Navigation should not complete")
    }
    
    func testCancellationDuringStateTransition() async throws {
        // Test cancellation during critical state transitions
        
        let service = TransactionalNavigationService<TestRoute>()
        
        // Set initial state
        try await service.navigate(to: TestRoute.home)
        
        // Start transactional navigation
        let transaction = await service.beginTransaction()
        
        // Start navigation within transaction
        let navigationTask = Task {
            try await transaction.navigate(to: TestRoute.detail(id: "transactional"))
            try await transaction.commit()
        }
        
        // Cancel during transaction
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        navigationTask.cancel()
        
        // Transaction should rollback
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        let finalState = await service.currentState
        XCTAssertEqual(finalState.currentRoute, TestRoute.home, "Transaction should rollback on cancellation")
        let transactionState = await transaction.state
        XCTAssertEqual(transactionState, .rolledBack, "Transaction should be rolled back")
    }
    
    func testCancellationWithChildTasks() async throws {
        // Test that cancellation propagates to child tasks
        
        let navigator = CancellableNavigationService<TestRoute>()
        var childTasksCancelled = 0
        
        // Create navigation with child tasks
        let parentTask = Task {
            try await navigator.navigateWithChildTasks(to: TestRoute.settings) { createChildTask in
                // Create multiple child tasks
                for _ in 1...3 {
                    createChildTask {
                        do {
                            try await Task.sleep(nanoseconds: 200_000_000) // 200ms
                        } catch {
                            childTasksCancelled += 1
                            throw error
                        }
                    }
                }
            }
        }
        
        // Cancel parent task
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        parentTask.cancel()
        
        // Wait for cancellation to propagate
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        XCTAssertEqual(childTasksCancelled, 3, "All child tasks should be cancelled")
    }
    
    func testCancellationErrorHandling() async throws {
        // Test proper error handling for cancellation
        
        let navigator = CancellableNavigationService<TestRoute>()
        
        let navigationTask = Task {
            try await navigator.navigateWithDelay(to: TestRoute.detail(id: "error-test"), delay: 0.1)
        }
        
        // Cancel immediately
        navigationTask.cancel()
        
        do {
            try await navigationTask.value
            XCTFail("Cancelled task should throw error")
        } catch {
            // Should receive proper cancellation error
            XCTAssertTrue(error is CancellationError || error is NavigationCancellationError,
                         "Should receive cancellation-specific error")
        }
    }
    
    @MainActor
    func testCancellationWithPresentationUpdate() async throws {
        // Test that presentation updates are cancelled properly
        
        let context = CancellationTestContext()
        let presentation = CancellationMockPresentation(context: context)
        
        // Start navigation that updates presentation
        let updateTask = Task { @MainActor in
            try await context.navigateWithPresentationUpdate(to: TestRoute.settings) { 
                presentation.isUpdating = true
                try await Task.sleep(nanoseconds: 100_000_000)
                presentation.isUpdating = false
            }
        }
        
        // Cancel during update
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        updateTask.cancel()
        
        // Wait for cancellation
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Presentation should not be left in updating state
        XCTAssertFalse(presentation.isUpdating, "Presentation update should be cancelled cleanly")
        XCTAssertNotEqual(context.currentRoute, TestRoute.settings, "Navigation should not complete")
    }
}

// MARK: - Test Support Types

/// Mock presentation for testing cancellation
@MainActor
class CancellationMockPresentation: ObservableObject {
    @Published var isUpdating = false
    let context: CancellationTestContext
    
    init(context: CancellationTestContext) {
        self.context = context
    }
}

/// Navigation context for testing cancellation
@MainActor
class CancellationTestContext: ObservableObject {
    @Published private(set) var currentRoute: TestRoute?
    
    func navigateWithPresentationUpdate(
        to route: TestRoute,
        update: () async throws -> Void
    ) async throws {
        do {
            try await update()
            currentRoute = route
        } catch {
            // Ensure clean state on error
            throw error
        }
    }
}