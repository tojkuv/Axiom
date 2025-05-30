import XCTest
import SwiftUI
@testable import Axiom

/// Comprehensive integration tests for the Foundation Example
/// Validates all components working together in realistic scenarios
@MainActor
final class FoundationIntegrationTests: XCTestCase {
    
    // MARK: - Test Configuration
    
    private var application: TaskManagerApplication!
    private var dashboardContext: DashboardContext!
    private var performanceBenchmarks: PerformanceBenchmarks!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize test application
        application = await TaskManagerApplication()
        try await application.onLaunch()
        
        // Create dashboard context
        dashboardContext = try await application.createDashboardContext()
        
        // Initialize performance benchmarks
        performanceBenchmarks = await PerformanceBenchmarks()
    }
    
    override func tearDown() async throws {
        await application.onTerminate()
        application = nil
        dashboardContext = nil
        performanceBenchmarks = nil
        try await super.tearDown()
    }
    
    // MARK: - Complete Application Flow Tests
    
    func testCompleteTaskManagementFlow() async throws {
        // Test complete flow: Create user, create project, create tasks, update tasks, complete tasks
        
        // 1. Create and authenticate user
        let user = try await dashboardContext.userClient.createUser(
            username: "testuser",
            email: "test@example.com",
            fullName: "Test User"
        )
        
        let authenticatedUser = try await dashboardContext.userClient.authenticateUser(
            username: "testuser",
            password: "password"
        )
        
        XCTAssertEqual(user.id, authenticatedUser.id)
        
        // 2. Create project
        await dashboardContext.createProject(
            name: "Test Project",
            description: "Integration test project",
            deadline: Calendar.current.date(byAdding: .month, value: 1, to: Date())
        )
        
        let projects = await dashboardContext.projectClient.getProjects()
        XCTAssertEqual(projects.count, 3) // 2 sample + 1 created
        
        let testProject = projects.first { $0.name == "Test Project" }
        XCTAssertNotNil(testProject)
        
        // 3. Create multiple tasks
        for i in 1...5 {
            await dashboardContext.createTask(
                title: "Test Task \\(i)",
                description: "Integration test task \\(i)",
                priority: i <= 2 ? .high : .medium,
                dueDate: Calendar.current.date(byAdding: .day, value: i, to: Date())
            )
        }
        
        // 4. Verify tasks were created
        let tasks = await dashboardContext.taskClient.getTasks()
        let testTasks = tasks.filter { $0.title.hasPrefix("Test Task") }
        XCTAssertEqual(testTasks.count, 5)
        
        // 5. Update task status
        guard let firstTask = testTasks.first else {
            XCTFail("No test task found")
            return
        }
        
        let updatedTask = try await dashboardContext.taskClient.updateTask(
            firstTask.id,
            with: TaskUpdates(status: .completed)
        )
        
        XCTAssertEqual(updatedTask.status, .completed)
        
        // 6. Verify dashboard data reflects changes
        await dashboardContext.refreshDashboard()
        
        let dashboardData = dashboardContext.dashboardData
        XCTAssertGreaterThan(dashboardData.taskSummary.total, 0)
        XCTAssertGreaterThan(dashboardData.projectSummary.total, 0)
        XCTAssertNotNil(dashboardData.currentUser)
        
        // 7. Test analytics tracking
        let analyticsMetrics = await dashboardContext.analyticsClient.getMetrics()
        XCTAssertGreaterThan(analyticsMetrics.totalEvents, 0)
        XCTAssertGreaterThan(analyticsMetrics.eventsByType.count, 0)
    }
    
    func testReactiveUpdatesAcrossClients() async throws {
        // Test that changes in one client properly notify all observers
        
        var contextNotifications = 0
        let originalOnClientStateChange = dashboardContext.onClientStateChange
        
        // Override context state change handler to count notifications
        dashboardContext.onClientStateChange = { client in
            contextNotifications += 1
            await originalOnClientStateChange(client)
        }
        
        // Make changes that should trigger notifications
        try await dashboardContext.taskClient.createTask(title: "Reactive Test Task")
        try await dashboardContext.userClient.createUser(
            username: "reactiveuser",
            email: "reactive@test.com",
            fullName: "Reactive User"
        )
        try await dashboardContext.projectClient.createProject(
            name: "Reactive Project",
            ownerId: User.ID("testuser")
        )
        
        // Allow time for async notifications
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify notifications were received
        XCTAssertGreaterThan(contextNotifications, 0)
    }
    
    func testCrossClientDataConsistency() async throws {
        // Test that data remains consistent across all clients
        
        // Create user and authenticate
        let user = try await dashboardContext.userClient.createUser(
            username: "consistencyuser",
            email: "consistency@test.com",
            fullName: "Consistency User"
        )
        
        try await dashboardContext.userClient.authenticateUser(
            username: "consistencyuser",
            password: "password"
        )
        
        // Create project owned by user
        try await dashboardContext.projectClient.createProject(
            name: "Consistency Project",
            ownerId: user.id
        )
        
        // Create task assigned to user
        try await dashboardContext.taskClient.createTask(
            title: "Consistency Task",
            assigneeId: user.id
        )
        
        // Verify cross-client consistency
        let projects = await dashboardContext.projectClient.getProjectsForUser(user.id)
        XCTAssertTrue(projects.contains { $0.name == "Consistency Project" })
        
        let tasks = await dashboardContext.taskClient.getTasks(assigneeId: user.id)
        XCTAssertTrue(tasks.contains { $0.title == "Consistency Task" })
        
        let currentUser = await dashboardContext.userClient.getCurrentUser()
        XCTAssertEqual(currentUser?.id, user.id)
    }
    
    // MARK: - Domain Model Integration Tests
    
    func testDomainModelValidationIntegration() async throws {
        // Test that domain model validation works across the entire system
        
        // Attempt to create invalid task (empty title)
        do {
            try await dashboardContext.taskClient.createTask(title: "")
            XCTFail("Should have failed validation for empty title")
        } catch {
            // Expected to fail
            XCTAssertTrue(error is DomainError)
        }
        
        // Attempt to create invalid user (invalid email)
        do {
            try await dashboardContext.userClient.createUser(
                username: "testuser2",
                email: "invalid-email",
                fullName: "Test User 2"
            )
            XCTFail("Should have failed validation for invalid email")
        } catch {
            // Expected to fail
            XCTAssertTrue(error is DomainError)
        }
        
        // Test business rule validation
        let task = Task(
            title: "Business Rule Test",
            priority: .high,
            dueDate: nil // High priority task without due date should trigger business rule
        )
        
        let validation = task.validate()
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.contains("due date") })
    }
    
    func testImmutableUpdateIntegration() async throws {
        // Test that immutable updates work correctly throughout the system
        
        // Create initial task
        let originalTask = try await dashboardContext.taskClient.createTask(
            title: "Immutable Test",
            description: "Original description"
        )
        
        // Update task through client
        let updatedTask = try await dashboardContext.taskClient.updateTask(
            originalTask.id,
            with: TaskUpdates(description: "Updated description")
        )
        
        // Verify original task is unchanged (immutable)
        XCTAssertEqual(originalTask.description, "Original description")
        XCTAssertEqual(updatedTask.description, "Updated description")
        XCTAssertEqual(originalTask.id, updatedTask.id)
        XCTAssertNotEqual(originalTask.updatedAt, updatedTask.updatedAt)
        
        // Verify state contains updated version
        let tasks = await dashboardContext.taskClient.getTasks()
        let taskInState = tasks.first { $0.id == originalTask.id }
        XCTAssertEqual(taskInState?.description, "Updated description")
    }
    
    // MARK: - Capability System Integration Tests
    
    func testCapabilityValidationIntegration() async throws {
        // Test that capability system works correctly across all clients
        
        // Test that clients validate required capabilities
        let taskClient = try await TaskClient()
        
        // This should work because storage and businessLogic are available
        try await taskClient.createTask(title: "Capability Test")
        
        // Test capability validation performance
        let startTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<1000 {
            try await dashboardContext.capabilityManager.validate(.businessLogic)
        }
        let endTime = CFAbsoluteTimeGetCurrent()
        let averageTime = (endTime - startTime) / 1000.0
        
        // Should be very fast due to caching
        XCTAssertLessThan(averageTime, 0.001) // Less than 1ms average
    }
    
    func testCapabilityCaching() async throws {
        // Test that capability caching works correctly
        
        let capabilityManager = dashboardContext.capabilityManager
        
        // Clear any existing cache
        await capabilityManager.refreshCapabilities()
        
        // First validation (should be cache miss)
        let startTime1 = CFAbsoluteTimeGetCurrent()
        try await capabilityManager.validate(.network)
        let endTime1 = CFAbsoluteTimeGetCurrent()
        let firstValidationTime = endTime1 - startTime1
        
        // Second validation (should be cache hit)
        let startTime2 = CFAbsoluteTimeGetCurrent()
        try await capabilityManager.validate(.network)
        let endTime2 = CFAbsoluteTimeGetCurrent()
        let secondValidationTime = endTime2 - startTime2
        
        // Cache hit should be significantly faster
        XCTAssertLessThan(secondValidationTime, firstValidationTime)
    }
    
    // MARK: - Intelligence System Integration Tests
    
    func testIntelligenceIntegration() async throws {
        // Test that intelligence system integrates correctly
        
        let intelligence = dashboardContext.intelligence
        
        // Test metrics collection
        let metrics = await intelligence.getMetrics()
        XCTAssertNotNil(metrics)
        
        // Test that application events are recorded
        await intelligence.recordApplicationEvent(.contextCreated)
        
        // Test component registration
        await intelligence.registerComponent(dashboardContext)
        
        // Verify intelligence features are working
        let enabledFeatures = await intelligence.enabledFeatures
        XCTAssertFalse(enabledFeatures.isEmpty)
    }
    
    // MARK: - Performance Integration Tests
    
    func testPerformanceTargets() async throws {
        // Run performance benchmarks and verify targets are met
        
        let benchmarkResults = await performanceBenchmarks.runCompleteBenchmarkSuite()
        
        // Verify overall performance score
        XCTAssertGreaterThan(benchmarkResults.overallScore, 0.8) // 80% of tests should pass
        
        // Verify specific performance targets
        XCTAssertTrue(benchmarkResults.passedTargets.stateAccess50xTCA)
        XCTAssertTrue(benchmarkResults.passedTargets.capabilityValidationUnder1ms)
        XCTAssertTrue(benchmarkResults.passedTargets.intelligenceQueriesUnder100ms)
        
        // Check that critical performance benchmarks passed
        let criticalBenchmarks = benchmarkResults.results.filter { 
            $0.name.contains("State Access") || $0.name.contains("Capability Validation")
        }
        
        for benchmark in criticalBenchmarks {
            XCTAssertTrue(benchmark.passed, "Critical benchmark '\\(benchmark.name)' failed")
        }
    }
    
    func testConcurrentOperations() async throws {
        // Test that the system handles concurrent operations correctly
        
        let concurrentOperations = 100
        
        // Run concurrent task creation
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<concurrentOperations {
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    try! await self.dashboardContext.taskClient.createTask(title: "Concurrent Task \\(i)")
                }
            }
        }
        
        // Verify all tasks were created
        let tasks = await dashboardContext.taskClient.getTasks()
        let concurrentTasks = tasks.filter { $0.title.hasPrefix("Concurrent Task") }
        XCTAssertEqual(concurrentTasks.count, concurrentOperations)
        
        // Verify state consistency
        let metrics = await dashboardContext.taskClient.getMetrics()
        XCTAssertGreaterThanOrEqual(metrics.totalTasks, concurrentOperations)
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandlingIntegration() async throws {
        // Test that errors are properly handled across the system
        
        var capturedErrors: [any AxiomError] = []
        
        // Override error handler to capture errors
        let originalHandleError = dashboardContext.handleError
        dashboardContext.handleError = { error in
            capturedErrors.append(error)
            await originalHandleError(error)
        }
        
        // Trigger various errors
        do {
            try await dashboardContext.taskClient.createTask(title: "") // Validation error
        } catch {
            // Expected
        }
        
        do {
            try await dashboardContext.userClient.createUser(
                username: "",
                email: "invalid",
                fullName: ""
            ) // Multiple validation errors
        } catch {
            // Expected
        }
        
        // Allow time for error handling
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify errors were captured and handled
        XCTAssertGreaterThan(capturedErrors.count, 0)
        
        // Verify error reporting worked
        let analyticsMetrics = await dashboardContext.analyticsClient.getMetrics()
        XCTAssertGreaterThan(analyticsMetrics.errorEvents, 0)
    }
    
    // MARK: - SwiftUI Integration Tests
    
    func testSwiftUIIntegration() async throws {
        // Test that SwiftUI integration works correctly
        
        // Create dashboard view
        let dashboardView = DashboardView(context: dashboardContext)
        
        // Test that view can access context
        XCTAssertNotNil(dashboardView.context)
        XCTAssertTrue(dashboardView.context === dashboardContext)
        
        // Test reactive updates
        let initialTaskCount = dashboardContext.dashboardData.taskSummary.total
        
        await dashboardContext.createTask(title: "SwiftUI Integration Test")
        await dashboardContext.refreshDashboard()
        
        let updatedTaskCount = dashboardContext.dashboardData.taskSummary.total
        XCTAssertGreaterThan(updatedTaskCount, initialTaskCount)
    }
    
    // MARK: - Data Persistence Integration Tests
    
    func testDataPersistenceIntegration() async throws {
        // Test that data persists correctly across operations
        
        // Create data
        let user = try await dashboardContext.userClient.createUser(
            username: "persistuser",
            email: "persist@test.com",
            fullName: "Persist User"
        )
        
        let project = try await dashboardContext.projectClient.createProject(
            name: "Persist Project",
            ownerId: user.id
        )
        
        let task = try await dashboardContext.taskClient.createTask(
            title: "Persist Task",
            assigneeId: user.id,
            projectId: project.id
        )
        
        // Verify data relationships
        let userProjects = await dashboardContext.projectClient.getProjectsForUser(user.id)
        XCTAssertTrue(userProjects.contains { $0.id == project.id })
        
        let userTasks = await dashboardContext.taskClient.getTasks(assigneeId: user.id)
        XCTAssertTrue(userTasks.contains { $0.id == task.id })
        
        let projectTasks = await dashboardContext.taskClient.getTasks(projectId: project.id)
        XCTAssertTrue(projectTasks.contains { $0.id == task.id })
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() async throws {
        // Test that the system manages memory correctly
        
        let initialMemory = getMemoryUsage()
        
        // Create many objects
        var clients: [TaskClient] = []
        for _ in 0..<50 {
            let client = try await TaskClient()
            for i in 0..<20 {
                try await client.createTask(title: "Memory Test \\(i)")
            }
            clients.append(client)
        }
        
        let peakMemory = getMemoryUsage()
        let memoryIncrease = peakMemory - initialMemory
        
        // Clear references
        clients.removeAll()
        
        // Force garbage collection
        for _ in 0..<10 {
            autoreleasepool {
                // Create and release objects to trigger cleanup
                let _ = Array(0..<1000).map { String($0) }
            }
        }
        
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let finalMemory = getMemoryUsage()
        let memoryReduction = peakMemory - finalMemory
        
        // Verify reasonable memory usage
        XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024) // Less than 100MB increase
        XCTAssertGreaterThan(memoryReduction, 0) // Some memory should be reclaimed
        
        print("Memory usage: Initial=\\(initialMemory/1024/1024)MB, Peak=\\(peakMemory/1024/1024)MB, Final=\\(finalMemory/1024/1024)MB")
    }
    
    // MARK: - Utility Methods
    
    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0 }
        return Int(info.resident_size)
    }
}

// MARK: - Additional Test Utilities

extension XCTestCase {
    /// Helper to run async tests with proper error handling
    func asyncTest<T>(_ test: () async throws -> T) async rethrows -> T {
        return try await test()
    }
    
    /// Helper to measure async operation performance
    func measureAsync<T>(_ operation: () async throws -> T) async rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        return (result, endTime - startTime)
    }
}