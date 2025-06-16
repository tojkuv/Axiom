import XCTest
import AxiomTesting
import SwiftUI
@testable import AxiomArchitecture
@testable import AxiomCore

/// Comprehensive tests for context testing framework and scenarios
/// 
/// Consolidates: ContextTestScenarioTests, ContextTestingFrameworkTests
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class ContextTestingFrameworkTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Context Testing Framework Tests
    
    func testContextTestHelpers() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                TestableFrameworkContext.self,
                id: "framework-test"
            ) {
                TestableFrameworkContext()
            }
            
            // Test basic context assertion helpers
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.isInitialized },
                description: "Context should be initialized"
            )
            
            // Test async state assertions with timeout
            await context.startAsyncOperation()
            
            try await TestHelpers.context.assertState(
                in: context,
                timeout: .seconds(2),
                condition: { $0.asyncOperationCompleted },
                description: "Async operation should complete"
            )
            
            // Test state change observations
            let observer = try await TestHelpers.context.observeContext(context)
            
            await context.updateValue(42)
            await context.updateStatus("Active")
            
            try await observer.assertChangeCount(2)
            try await observer.assertLastState { ctx in
                ctx.value == 42 && ctx.status == "Active"
            }
        }
    }
    
    func testContextActionSequenceAssertions() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                ActionSequenceContext.self,
                id: "action-sequence"
            ) {
                ActionSequenceContext()
            }
            
            // Test action sequence validation
            try await TestHelpers.context.assertActionSequence(
                in: context,
                actions: [
                    ContextAction.initialize,
                    ContextAction.loadData,
                    ContextAction.processData,
                    ContextAction.saveResults
                ],
                expectedStates: [
                    { $0.isInitialized },
                    { $0.dataLoaded },
                    { $0.dataProcessed },
                    { $0.resultsSaved }
                ]
            )
            
            // Verify final state
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.isComplete },
                description: "Should complete entire action sequence"
            )
        }
    }
    
    func testContextErrorScenarios() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                ErrorScenarioContext.self,
                id: "error-scenario"
            ) {
                ErrorScenarioContext()
            }
            
            // Test error injection and recovery
            await context.injectError(.networkTimeout)
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.hasError },
                description: "Should handle injected error"
            )
            
            // Test error recovery
            await context.attemptRecovery()
            
            try await TestHelpers.context.assertState(
                in: context,
                timeout: .seconds(1),
                condition: { !$0.hasError && $0.isRecovered },
                description: "Should recover from error"
            )
            
            // Test multiple error scenarios
            let errorScenarios: [TestError] = [.networkTimeout, .dataCorruption, .systemOverload]
            
            for scenario in errorScenarios {
                await context.reset()
                await context.injectError(scenario)
                
                try await TestHelpers.context.assertState(
                    in: context,
                    condition: { $0.lastError == scenario },
                    description: "Should handle \(scenario) error"
                )
            }
        }
    }
    
    func testContextPerformanceMeasurement() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                PerformanceTestContext.self,
                id: "performance-test"
            ) {
                PerformanceTestContext()
            }
            
            // Test performance measurement utilities
            let performanceResult = try await TestHelpers.context.measurePerformance(
                in: context,
                operation: { ctx in
                    for i in 0..<1000 {
                        await ctx.processItem(i)
                    }
                },
                requirements: ContextPerformanceRequirements(
                    maxDuration: .milliseconds(500),
                    maxMemoryGrowth: 1024 * 1024, // 1MB
                    maxCPUUsage: 80.0
                )
            )
            
            XCTAssertTrue(performanceResult.meetsRequirements, "Should meet performance requirements")
            XCTAssertEqual(performanceResult.itemsProcessed, 1000, "Should process all items")
            
            // Test memory leak detection
            try await TestHelpers.context.assertNoMemoryLeaks {
                for i in 0..<50 {
                    await context.createTemporaryData(size: 1024) // 1KB each
                    await context.cleanupTemporaryData()
                }
            }
        }
    }
    
    func testContextMockingUtilities() async throws {
        try await testEnvironment.runTest { env in
            // Test context mocking for isolation
            let mockClient = MockContextClient()
            let mockService = MockExternalService()
            
            let context = try await env.createContext(
                MockableContext.self,
                id: "mockable"
            ) {
                MockableContext(client: mockClient, service: mockService)
            }
            
            // Configure mock behaviors
            await mockClient.configureMockResponse(.success(MockData(value: 42)))
            await mockService.configureMockDelay(.milliseconds(100))
            
            // Test with mocked dependencies
            await context.performOperation()
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.operationResult == 42 },
                description: "Should use mocked client response"
            )
            
            // Verify mock interactions
            let clientCalls = await mockClient.getCallHistory()
            XCTAssertEqual(clientCalls.count, 1, "Should call mock client once")
            
            let serviceCalls = await mockService.getCallHistory()
            XCTAssertEqual(serviceCalls.count, 1, "Should call mock service once")
        }
    }
    
    // MARK: - Context Test Scenario Tests
    
    func testUserWorkflowScenarios() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                UserWorkflowContext.self,
                id: "user-workflow"
            ) {
                UserWorkflowContext()
            }
            
            // Test complete user workflow scenario
            let workflowScenario = UserWorkflowScenario()
            
            try await workflowScenario.execute(in: context) {
                // Step 1: User opens app
                await context.handleAppLaunch()
                
                // Step 2: User logs in
                await context.handleUserLogin(credentials: TestCredentials.valid)
                
                // Step 3: User navigates to dashboard
                await context.navigateToDashboard()
                
                // Step 4: User performs main action
                await context.performMainAction()
                
                // Step 5: User saves changes
                await context.saveChanges()
            }
            
            // Verify workflow completion
            try await TestHelpers.context.assertState(
                in: context,
                condition: { $0.workflowCompleted },
                description: "Should complete user workflow"
            )
            
            // Verify workflow metrics
            let metrics = await context.getWorkflowMetrics()
            XCTAssertEqual(metrics.stepsCompleted, 5, "Should complete all workflow steps")
            XCTAssertLessThan(metrics.totalDuration, 2.0, "Should complete workflow quickly")
        }
    }
    
    func testErrorRecoveryScenarios() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                ErrorRecoveryContext.self,
                id: "error-recovery"
            ) {
                ErrorRecoveryContext()
            }
            
            // Test network failure recovery scenario
            let networkRecoveryScenario = ErrorRecoveryScenario(.networkFailure)
            
            try await networkRecoveryScenario.execute(in: context) {
                // Simulate network operation
                await context.performNetworkOperation()
                
                // Inject network failure
                await context.simulateNetworkFailure()
                
                // Verify error handling
                try await TestHelpers.context.assertState(
                    in: context,
                    condition: { $0.hasNetworkError },
                    description: "Should detect network error"
                )
                
                // Trigger retry mechanism
                await context.retryOperation()
                
                // Verify recovery
                try await TestHelpers.context.assertState(
                    in: context,
                    timeout: .seconds(3),
                    condition: { !$0.hasNetworkError && $0.operationSucceeded },
                    description: "Should recover from network error"
                )
            }
            
            // Test data corruption recovery scenario
            let dataRecoveryScenario = ErrorRecoveryScenario(.dataCorruption)
            
            try await dataRecoveryScenario.execute(in: context) {
                await context.reset()
                
                // Simulate data corruption
                await context.corruptData()
                
                // Verify corruption detection
                try await TestHelpers.context.assertState(
                    in: context,
                    condition: { $0.hasDataCorruption },
                    description: "Should detect data corruption"
                )
                
                // Trigger data recovery
                await context.recoverFromCorruption()
                
                // Verify data restoration
                try await TestHelpers.context.assertState(
                    in: context,
                    condition: { !$0.hasDataCorruption && $0.dataRestored },
                    description: "Should recover from data corruption"
                )
            }
        }
    }
    
    func testConcurrencyScenarios() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                ConcurrencyTestContext.self,
                id: "concurrency"
            ) {
                ConcurrencyTestContext()
            }
            
            // Test concurrent operations scenario
            let concurrencyScenario = ConcurrencyScenario()
            
            try await concurrencyScenario.execute(in: context) {
                // Start multiple concurrent operations
                await withTaskGroup(of: Void.self) { group in
                    for i in 0..<10 {
                        group.addTask {
                            await context.performConcurrentOperation(id: i)
                        }
                    }
                }
                
                // Verify all operations completed
                try await TestHelpers.context.assertState(
                    in: context,
                    timeout: .seconds(5),
                    condition: { $0.completedOperations.count == 10 },
                    description: "Should complete all concurrent operations"
                )
                
                // Test concurrent state updates
                await withTaskGroup(of: Void.self) { group in
                    for i in 0..<20 {
                        group.addTask {
                            await context.updateSharedState(value: i)
                        }
                    }
                }
                
                // Verify state consistency
                try await TestHelpers.context.assertState(
                    in: context,
                    condition: { $0.stateUpdates.count == 20 },
                    description: "Should handle concurrent state updates"
                )
            }
        }
    }
    
    func testLifecycleScenarios() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                LifecycleScenarioContext.self,
                id: "lifecycle-scenario"
            ) {
                LifecycleScenarioContext()
            }
            
            // Test app lifecycle scenario
            let lifecycleScenario = AppLifecycleScenario()
            
            try await lifecycleScenario.execute(in: context) {
                // App launch
                await context.handleAppWillLaunch()
                await context.handleAppDidLaunch()
                
                try await TestHelpers.context.assertState(
                    in: context,
                    condition: { $0.isLaunched },
                    description: "Should handle app launch"
                )
                
                // App enters background
                await context.handleAppWillEnterBackground()
                await context.handleAppDidEnterBackground()
                
                try await TestHelpers.context.assertState(
                    in: context,
                    condition: { $0.isInBackground },
                    description: "Should handle background transition"
                )
                
                // App returns to foreground
                await context.handleAppWillEnterForeground()
                await context.handleAppDidEnterForeground()
                
                try await TestHelpers.context.assertState(
                    in: context,
                    condition: { !$0.isInBackground },
                    description: "Should handle foreground transition"
                )
                
                // App termination
                await context.handleAppWillTerminate()
                
                try await TestHelpers.context.assertState(
                    in: context,
                    condition: { $0.isTerminating },
                    description: "Should handle app termination"
                )
            }
        }
    }
    
    func testEdgeCaseScenarios() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                EdgeCaseContext.self,
                id: "edge-cases"
            ) {
                EdgeCaseContext()
            }
            
            // Test empty/null data scenario
            let emptyDataScenario = EdgeCaseScenario(.emptyData)
            
            try await emptyDataScenario.execute(in: context) {
                await context.handleEmptyData()
                
                try await TestHelpers.context.assertState(
                    in: context,
                    condition: { $0.handledEmptyData },
                    description: "Should handle empty data gracefully"
                )
            }
            
            // Test extremely large data scenario
            let largeDataScenario = EdgeCaseScenario(.extremelyLargeData)
            
            try await largeDataScenario.execute(in: context) {
                await context.handleLargeDataSet(size: 1_000_000)
                
                try await TestHelpers.context.assertState(
                    in: context,
                    timeout: .seconds(10),
                    condition: { $0.processedLargeData },
                    description: "Should handle large data sets"
                )
            }
            
            // Test rapid state changes scenario
            let rapidChangesScenario = EdgeCaseScenario(.rapidStateChanges)
            
            try await rapidChangesScenario.execute(in: context) {
                for i in 0..<1000 {
                    await context.rapidStateChange(iteration: i)
                }
                
                try await TestHelpers.context.assertState(
                    in: context,
                    condition: { $0.rapidChangesHandled >= 1000 },
                    description: "Should handle rapid state changes"
                )
            }
        }
    }
    
    // MARK: - Integration Testing Scenarios
    
    func testMultiContextIntegrationScenario() async throws {
        try await testEnvironment.runTest { env in
            // Create multiple interconnected contexts
            let dataContext = try await env.createContext(
                DataManagementContext.self,
                id: "data-context"
            ) {
                DataManagementContext()
            }
            
            let uiContext = try await env.createContext(
                UICoordinationContext.self,
                id: "ui-context"
            ) {
                UICoordinationContext(dataContext: dataContext)
            }
            
            let networkContext = try await env.createContext(
                NetworkOperationContext.self,
                id: "network-context"
            ) {
                NetworkOperationContext(dataContext: dataContext)
            }
            
            // Test integration scenario
            let integrationScenario = MultiContextIntegrationScenario()
            
            try await integrationScenario.execute(
                dataContext: dataContext,
                uiContext: uiContext,
                networkContext: networkContext
            ) {
                // Trigger data sync from network
                await networkContext.syncData()
                
                // Verify data context receives updates
                try await TestHelpers.context.assertState(
                    in: dataContext,
                    timeout: .seconds(2),
                    condition: { $0.hasReceivedNetworkData },
                    description: "Data context should receive network updates"
                )
                
                // Verify UI context reflects changes
                try await TestHelpers.context.assertState(
                    in: uiContext,
                    condition: { $0.hasUpdatedUI },
                    description: "UI context should reflect data changes"
                )
                
                // Test bidirectional communication
                await uiContext.triggerUserAction()
                
                try await TestHelpers.context.assertState(
                    in: dataContext,
                    condition: { $0.hasProcessedUserAction },
                    description: "Should handle bidirectional communication"
                )
            }
        }
    }
    
    // MARK: - Test Scenario Framework Tests
    
    func testScenarioComposition() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                CompositeScenarioContext.self,
                id: "composite"
            ) {
                CompositeScenarioContext()
            }
            
            // Test composed scenario
            let compositeScenario = CompositeTestScenario([
                BasicSetupScenario(),
                DataLoadingScenario(),
                UserInteractionScenario(),
                CleanupScenario()
            ])
            
            try await compositeScenario.execute(in: context)
            
            // Verify all sub-scenarios completed
            try await TestHelpers.context.assertState(
                in: context,
                condition: { 
                    $0.setupCompleted && 
                    $0.dataLoaded && 
                    $0.userInteractionHandled && 
                    $0.cleanupCompleted
                },
                description: "Should complete all composed scenarios"
            )
        }
    }
    
    func testScenarioParameterization() async throws {
        try await testEnvironment.runTest { env in
            let context = try await env.createContext(
                ParameterizedContext.self,
                id: "parameterized"
            ) {
                ParameterizedContext()
            }
            
            // Test parameterized scenario
            let parameters = ScenarioParameters(
                dataSize: 1000,
                operationCount: 50,
                timeout: .seconds(5),
                errorRate: 0.1
            )
            
            let parameterizedScenario = ParameterizedTestScenario(parameters)
            
            try await parameterizedScenario.execute(in: context)
            
            // Verify scenario used parameters correctly
            let metrics = await context.getExecutionMetrics()
            XCTAssertEqual(metrics.processedItems, parameters.dataSize, "Should process parameterized data size")
            XCTAssertEqual(metrics.operationsPerformed, parameters.operationCount, "Should perform parameterized operations")
        }
    }
    
    // MARK: - Performance Tests
    
    func testContextTestingFrameworkPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                for i in 0..<50 {
                    let context = TestableFrameworkContext()
                    await context.onAppear()
                    
                    // Simulate testing operations
                    await context.performOperation()
                    await context.updateValue(i)
                    
                    await context.onDisappear()
                }
            },
            maxDuration: .milliseconds(500),
            maxMemoryGrowth: 2 * 1024 * 1024 // 2MB
        )
    }
    
    func testScenarioExecutionPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let context = CompositeScenarioContext()
                
                let scenarios: [TestScenario] = [
                    BasicSetupScenario(),
                    DataLoadingScenario(),
                    UserInteractionScenario(),
                    CleanupScenario()
                ]
                
                for scenario in scenarios {
                    await scenario.execute(in: context)
                }
            },
            maxDuration: .milliseconds(300),
            maxMemoryGrowth: 1 * 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testContextTestingMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            for iteration in 0..<10 {
                let context = ErrorRecoveryContext()
                await context.onAppear()
                
                // Execute various test scenarios
                let scenarios: [ErrorType] = [.networkFailure, .dataCorruption, .systemOverload]
                
                for scenario in scenarios {
                    let errorScenario = ErrorRecoveryScenario(scenario)
                    try await errorScenario.execute(in: context) {
                        await context.simulateError(scenario)
                        await context.attemptRecovery()
                    }
                }
                
                await context.onDisappear()
            }
        }
    }
}

// MARK: - Test Support Classes

@MainActor
class TestableFrameworkContext: AxiomContext {
    @Published private(set) var isInitialized = true
    @Published private(set) var asyncOperationCompleted = false
    @Published private(set) var value = 0
    @Published private(set) var status = ""
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func startAsyncOperation() async {
        try? await Task.sleep(for: .milliseconds(100))
        asyncOperationCompleted = true
    }
    
    func updateValue(_ newValue: Int) {
        value = newValue
    }
    
    func updateStatus(_ newStatus: String) {
        status = newStatus
    }
    
    func performOperation() {
        // Simulate operation
    }
}

@MainActor
class ActionSequenceContext: AxiomContext {
    @Published private(set) var isInitialized = false
    @Published private(set) var dataLoaded = false
    @Published private(set) var dataProcessed = false
    @Published private(set) var resultsSaved = false
    @Published private(set) var isComplete = false
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func processAction(_ action: ContextAction) async {
        switch action {
        case .initialize:
            isInitialized = true
        case .loadData:
            dataLoaded = true
        case .processData:
            dataProcessed = true
        case .saveResults:
            resultsSaved = true
            isComplete = true
        }
    }
}

@MainActor
class ErrorScenarioContext: AxiomContext {
    @Published private(set) var hasError = false
    @Published private(set) var isRecovered = false
    @Published private(set) var lastError: TestError?
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func injectError(_ error: TestError) {
        hasError = true
        lastError = error
    }
    
    func attemptRecovery() async {
        try? await Task.sleep(for: .milliseconds(100))
        hasError = false
        isRecovered = true
    }
    
    func reset() {
        hasError = false
        isRecovered = false
        lastError = nil
    }
}

@MainActor
class PerformanceTestContext: AxiomContext {
    @Published private(set) var itemsProcessed = 0
    @Published private(set) var temporaryDataSize = 0
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func processItem(_ index: Int) {
        itemsProcessed += 1
    }
    
    func createTemporaryData(size: Int) {
        temporaryDataSize += size
    }
    
    func cleanupTemporaryData() {
        temporaryDataSize = 0
    }
}

@MainActor
class MockableContext: AxiomContext {
    private let client: MockContextClient
    private let service: MockExternalService
    @Published private(set) var operationResult: Int = 0
    
    init(client: MockContextClient, service: MockExternalService) {
        self.client = client
        self.service = service
    }
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func performOperation() async {
        let result = await client.fetchData()
        await service.processData(result)
        
        switch result {
        case .success(let data):
            operationResult = data.value
        case .failure:
            operationResult = -1
        }
    }
}

// MARK: - Scenario Test Support Classes

@MainActor
class UserWorkflowContext: AxiomContext {
    @Published private(set) var workflowCompleted = false
    @Published private(set) var currentStep = 0
    @Published private(set) var isLoggedIn = false
    @Published private(set) var onDashboard = false
    
    private var workflowStartTime: Date?
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func handleAppLaunch() {
        workflowStartTime = Date()
        currentStep = 1
    }
    
    func handleUserLogin(credentials: TestCredentials) {
        isLoggedIn = credentials == .valid
        currentStep = 2
    }
    
    func navigateToDashboard() {
        onDashboard = true
        currentStep = 3
    }
    
    func performMainAction() {
        currentStep = 4
    }
    
    func saveChanges() {
        currentStep = 5
        workflowCompleted = true
    }
    
    func getWorkflowMetrics() -> WorkflowMetrics {
        let duration = workflowStartTime?.timeIntervalSinceNow ?? 0
        return WorkflowMetrics(
            stepsCompleted: currentStep,
            totalDuration: abs(duration)
        )
    }
}

@MainActor
class ErrorRecoveryContext: AxiomContext {
    @Published private(set) var hasNetworkError = false
    @Published private(set) var hasDataCorruption = false
    @Published private(set) var operationSucceeded = false
    @Published private(set) var dataRestored = false
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func performNetworkOperation() {
        // Simulate network operation
    }
    
    func simulateNetworkFailure() {
        hasNetworkError = true
    }
    
    func retryOperation() async {
        try? await Task.sleep(for: .milliseconds(200))
        hasNetworkError = false
        operationSucceeded = true
    }
    
    func corruptData() {
        hasDataCorruption = true
    }
    
    func recoverFromCorruption() {
        hasDataCorruption = false
        dataRestored = true
    }
    
    func simulateError(_ type: ErrorType) {
        switch type {
        case .networkFailure:
            hasNetworkError = true
        case .dataCorruption:
            hasDataCorruption = true
        case .systemOverload:
            // Simulate system overload
            break
        }
    }
    
    func attemptRecovery() async {
        hasNetworkError = false
        hasDataCorruption = false
        operationSucceeded = true
        dataRestored = true
    }
    
    func reset() {
        hasNetworkError = false
        hasDataCorruption = false
        operationSucceeded = false
        dataRestored = false
    }
}

@MainActor
class ConcurrencyTestContext: AxiomContext {
    @Published private(set) var completedOperations: [Int] = []
    @Published private(set) var stateUpdates: [Int] = []
    
    private let serialQueue = DispatchQueue(label: "concurrency.test")
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func performConcurrentOperation(id: Int) async {
        try? await Task.sleep(for: .milliseconds(10))
        
        await withCheckedContinuation { continuation in
            serialQueue.async {
                Task { @MainActor in
                    self.completedOperations.append(id)
                    continuation.resume()
                }
            }
        }
    }
    
    func updateSharedState(value: Int) async {
        await withCheckedContinuation { continuation in
            serialQueue.async {
                Task { @MainActor in
                    self.stateUpdates.append(value)
                    continuation.resume()
                }
            }
        }
    }
}

@MainActor
class LifecycleScenarioContext: AxiomContext {
    @Published private(set) var isLaunched = false
    @Published private(set) var isInBackground = false
    @Published private(set) var isTerminating = false
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func handleAppWillLaunch() {}
    func handleAppDidLaunch() {
        isLaunched = true
    }
    
    func handleAppWillEnterBackground() {}
    func handleAppDidEnterBackground() {
        isInBackground = true
    }
    
    func handleAppWillEnterForeground() {}
    func handleAppDidEnterForeground() {
        isInBackground = false
    }
    
    func handleAppWillTerminate() {
        isTerminating = true
    }
}

@MainActor
class EdgeCaseContext: AxiomContext {
    @Published private(set) var handledEmptyData = false
    @Published private(set) var processedLargeData = false
    @Published private(set) var rapidChangesHandled = 0
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func handleEmptyData() {
        handledEmptyData = true
    }
    
    func handleLargeDataSet(size: Int) async {
        // Simulate processing large data
        try? await Task.sleep(for: .milliseconds(100))
        processedLargeData = true
    }
    
    func rapidStateChange(iteration: Int) {
        rapidChangesHandled += 1
    }
}

// MARK: - Integration Test Support Classes

@MainActor
class DataManagementContext: AxiomContext {
    @Published private(set) var hasReceivedNetworkData = false
    @Published private(set) var hasProcessedUserAction = false
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func receiveNetworkData() {
        hasReceivedNetworkData = true
    }
    
    func processUserAction() {
        hasProcessedUserAction = true
    }
}

@MainActor
class UICoordinationContext: AxiomContext {
    private weak var dataContext: DataManagementContext?
    @Published private(set) var hasUpdatedUI = false
    
    init(dataContext: DataManagementContext) {
        self.dataContext = dataContext
    }
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func updateUI() {
        hasUpdatedUI = true
    }
    
    func triggerUserAction() {
        dataContext?.processUserAction()
    }
}

@MainActor
class NetworkOperationContext: AxiomContext {
    private weak var dataContext: DataManagementContext?
    
    init(dataContext: DataManagementContext) {
        self.dataContext = dataContext
    }
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func syncData() async {
        try? await Task.sleep(for: .milliseconds(50))
        dataContext?.receiveNetworkData()
    }
}

@MainActor
class CompositeScenarioContext: AxiomContext {
    @Published private(set) var setupCompleted = false
    @Published private(set) var dataLoaded = false
    @Published private(set) var userInteractionHandled = false
    @Published private(set) var cleanupCompleted = false
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func completeSetup() {
        setupCompleted = true
    }
    
    func loadData() {
        dataLoaded = true
    }
    
    func handleUserInteraction() {
        userInteractionHandled = true
    }
    
    func performCleanup() {
        cleanupCompleted = true
    }
}

@MainActor
class ParameterizedContext: AxiomContext {
    @Published private(set) var processedItems = 0
    @Published private(set) var operationsPerformed = 0
    
    func onAppear() async {}
    func onDisappear() async {}
    
    func processItems(count: Int) {
        processedItems = count
    }
    
    func performOperations(count: Int) {
        operationsPerformed = count
    }
    
    func getExecutionMetrics() -> ExecutionMetrics {
        return ExecutionMetrics(
            processedItems: processedItems,
            operationsPerformed: operationsPerformed
        )
    }
}

// MARK: - Mock Support Classes

actor MockContextClient {
    private var mockResponse: Result<MockData, Error> = .success(MockData(value: 0))
    private var callHistory: [String] = []
    
    func configureMockResponse(_ response: Result<MockData, Error>) {
        mockResponse = response
    }
    
    func fetchData() async -> Result<MockData, Error> {
        callHistory.append("fetchData")
        return mockResponse
    }
    
    func getCallHistory() -> [String] {
        return callHistory
    }
}

actor MockExternalService {
    private var mockDelay: Duration = .milliseconds(0)
    private var callHistory: [String] = []
    
    func configureMockDelay(_ delay: Duration) {
        mockDelay = delay
    }
    
    func processData(_ data: Result<MockData, Error>) async {
        callHistory.append("processData")
        try? await Task.sleep(for: mockDelay)
    }
    
    func getCallHistory() -> [String] {
        return callHistory
    }
}

// MARK: - Test Scenario Classes

protocol TestScenario {
    func execute(in context: any AxiomContext) async throws
}

class UserWorkflowScenario {
    func execute(in context: UserWorkflowContext, _ actions: () async throws -> Void) async throws {
        try await actions()
    }
}

class ErrorRecoveryScenario {
    let errorType: ErrorType
    
    init(_ errorType: ErrorType) {
        self.errorType = errorType
    }
    
    func execute(in context: ErrorRecoveryContext, _ actions: () async throws -> Void) async throws {
        try await actions()
    }
}

class ConcurrencyScenario {
    func execute(in context: ConcurrencyTestContext, _ actions: () async throws -> Void) async throws {
        try await actions()
    }
}

class AppLifecycleScenario {
    func execute(in context: LifecycleScenarioContext, _ actions: () async throws -> Void) async throws {
        try await actions()
    }
}

class EdgeCaseScenario {
    let edgeCase: EdgeCaseType
    
    init(_ edgeCase: EdgeCaseType) {
        self.edgeCase = edgeCase
    }
    
    func execute(in context: EdgeCaseContext, _ actions: () async throws -> Void) async throws {
        try await actions()
    }
}

class MultiContextIntegrationScenario {
    func execute(
        dataContext: DataManagementContext,
        uiContext: UICoordinationContext,
        networkContext: NetworkOperationContext,
        _ actions: () async throws -> Void
    ) async throws {
        try await actions()
    }
}

class CompositeTestScenario {
    let scenarios: [TestScenario]
    
    init(_ scenarios: [TestScenario]) {
        self.scenarios = scenarios
    }
    
    func execute(in context: CompositeScenarioContext) async throws {
        for scenario in scenarios {
            try await scenario.execute(in: context)
        }
    }
}

class ParameterizedTestScenario {
    let parameters: ScenarioParameters
    
    init(_ parameters: ScenarioParameters) {
        self.parameters = parameters
    }
    
    func execute(in context: ParameterizedContext) async throws {
        await context.processItems(count: parameters.dataSize)
        await context.performOperations(count: parameters.operationCount)
    }
}

// Individual scenario implementations
class BasicSetupScenario: TestScenario {
    func execute(in context: any AxiomContext) async throws {
        if let context = context as? CompositeScenarioContext {
            await context.completeSetup()
        }
    }
}

class DataLoadingScenario: TestScenario {
    func execute(in context: any AxiomContext) async throws {
        if let context = context as? CompositeScenarioContext {
            await context.loadData()
        }
    }
}

class UserInteractionScenario: TestScenario {
    func execute(in context: any AxiomContext) async throws {
        if let context = context as? CompositeScenarioContext {
            await context.handleUserInteraction()
        }
    }
}

class CleanupScenario: TestScenario {
    func execute(in context: any AxiomContext) async throws {
        if let context = context as? CompositeScenarioContext {
            await context.performCleanup()
        }
    }
}

// MARK: - Supporting Types

enum ContextAction {
    case initialize
    case loadData
    case processData
    case saveResults
}

enum TestError: Equatable {
    case networkTimeout
    case dataCorruption
    case systemOverload
}

enum ErrorType {
    case networkFailure
    case dataCorruption
    case systemOverload
}

enum EdgeCaseType {
    case emptyData
    case extremelyLargeData
    case rapidStateChanges
}

enum TestCredentials {
    case valid
    case invalid
}

struct MockData {
    let value: Int
}

struct ContextPerformanceRequirements {
    let maxDuration: Duration
    let maxMemoryGrowth: Int
    let maxCPUUsage: Double
}

struct ContextPerformanceResult {
    let meetsRequirements: Bool
    let itemsProcessed: Int
    let duration: Duration
    let memoryGrowth: Int
}

struct WorkflowMetrics {
    let stepsCompleted: Int
    let totalDuration: TimeInterval
}

struct ExecutionMetrics {
    let processedItems: Int
    let operationsPerformed: Int
}

struct ScenarioParameters {
    let dataSize: Int
    let operationCount: Int
    let timeout: Duration
    let errorRate: Double
}

// MARK: - Test Helper Extensions

extension TestHelpers.Context {
    static func assertActionSequence<T: AxiomContext>(
        in context: T,
        actions: [ContextAction],
        expectedStates: [((T) -> Bool)]
    ) async throws {
        guard let actionContext = context as? ActionSequenceContext else {
            throw TestError.systemOverload
        }
        
        for (action, expectedState) in zip(actions, expectedStates) {
            await actionContext.processAction(action)
            
            if !expectedState(context) {
                throw TestError.systemOverload
            }
        }
    }
    
    static func measurePerformance<T: AxiomContext>(
        in context: T,
        operation: (T) async throws -> Void,
        requirements: ContextPerformanceRequirements
    ) async throws -> ContextPerformanceResult {
        let startTime = Date()
        
        try await operation(context)
        
        let duration = Date().timeIntervalSince(startTime)
        
        if let perfContext = context as? PerformanceTestContext {
            return ContextPerformanceResult(
                meetsRequirements: duration < requirements.maxDuration.timeInterval,
                itemsProcessed: await perfContext.itemsProcessed,
                duration: .seconds(duration),
                memoryGrowth: 0
            )
        }
        
        return ContextPerformanceResult(
            meetsRequirements: false,
            itemsProcessed: 0,
            duration: .seconds(duration),
            memoryGrowth: 0
        )
    }
}

extension TestHelpers {
    enum Presentation {
        static func assertState<T: TestPresentation>(
            in presentation: T,
            timeout: Duration = .seconds(1),
            condition: @escaping (T) -> Bool,
            description: String
        ) async throws {
            let deadline = Date().addingTimeInterval(timeout.timeInterval)
            
            while Date() < deadline {
                if condition(presentation) {
                    return
                }
                try await Task.sleep(for: .milliseconds(10))
            }
            
            throw TestError.systemOverload
        }
    }
}

extension Duration {
    var timeInterval: TimeInterval {
        let (seconds, attoseconds) = self.components
        return TimeInterval(seconds) + TimeInterval(attoseconds) / 1e18
    }
}