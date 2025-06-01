import Testing
import Foundation
import SwiftUI
import Combine
@testable import Axiom

// MARK: - AxiomContext Testing Infrastructure

/// Mock AxiomIntelligence for testing
actor MockAxiomIntelligence: AxiomIntelligence {
    var enabledFeatures: Set<IntelligenceFeature> = []
    var confidenceThreshold: Double = 0.8
    var automationLevel: AutomationLevel = .supervised
    var learningMode: LearningMode = .suggestion
    var performanceConfiguration: IntelligencePerformanceConfiguration = IntelligencePerformanceConfiguration()
    
    func enableFeature(_ feature: IntelligenceFeature) async { enabledFeatures.insert(feature) }
    func disableFeature(_ feature: IntelligenceFeature) async { enabledFeatures.remove(feature) }
    func setAutomationLevel(_ level: AutomationLevel) async { automationLevel = level }
    func setLearningMode(_ mode: LearningMode) async { learningMode = mode }
    func getMetrics() async -> IntelligenceMetrics { 
        return IntelligenceMetrics(
            totalOperations: 0,
            averageResponseTime: 0.0,
            cacheHitRate: 0.0,
            successfulPredictions: 0,
            predictionAccuracy: 0.0,
            featureMetrics: [:],
            timestamp: Date()
        )
    }
    func reset() async { enabledFeatures.removeAll() }
    func processQuery(_ query: String) async throws -> QueryResponse { return QueryResponse.explanation("Test", confidence: 0.9) }
    func analyzeCodePatterns() async throws -> [OptimizationSuggestion] { return [] }
    func predictArchitecturalIssues() async throws -> [ArchitecturalRisk] { return [] }
    func generateDocumentation(for componentID: ComponentID) async throws -> GeneratedDocumentation { 
        return GeneratedDocumentation(
            componentID: componentID,
            title: "Test Documentation",
            overview: "Test overview",
            purpose: "Test purpose",
            responsibilities: ["Test responsibility"],
            dependencies: ["Test dependency"],
            usagePatterns: ["Test pattern"],
            performanceCharacteristics: ["Test characteristic"],
            bestPractices: ["Test practice"],
            examples: ["Test example"],
            generatedAt: Date()
        )
    }
    func suggestRefactoring() async throws -> [RefactoringSuggestion] { return [] }
    func registerComponent<T: AxiomContext>(_ component: T) async {}
}

/// Test implementation of AxiomContext for comprehensive testing
@MainActor
final class TestContext: AxiomContext {
    typealias View = TestAxiomView
    typealias Clients = TestClientContainer
    
    let clients: TestClientContainer
    let intelligence: any AxiomIntelligence
    
    // Test state tracking
    @Published var isLoading: Bool = false
    @Published var lastError: (any AxiomError)?
    @Published var analyticsEvents: [AnalyticsEvent] = []
    @Published var lifecycleEvents: [LifecycleEvent] = []
    
    init() {
        self.clients = TestClientContainer()
        self.intelligence = MockAxiomIntelligence()
    }
    
    // MARK: Lifecycle Implementation
    
    func onAppear() async {
        lifecycleEvents.append(.appeared)
    }
    
    func onDisappear() async {
        lifecycleEvents.append(.disappeared)
    }
    
    func onClientStateChange<T: AxiomClient>(_ client: T) async {
        lifecycleEvents.append(.clientStateChanged(String(describing: T.self)))
    }
    
    // MARK: Error Handling Implementation
    
    func handleError(_ error: any AxiomError) async {
        lastError = error
        lifecycleEvents.append(.errorHandled(error.userMessage))
    }
    
    // MARK: Analytics Implementation
    
    func trackAnalyticsEvent(_ event: String, parameters: [String: Any]) async {
        analyticsEvents.append(AnalyticsEvent(name: event, parameters: parameters))
    }
}

/// Test view for context relationship validation
struct TestAxiomView: AxiomView {
    typealias Context = TestContext
    @ObservedObject var context: TestContext
    
    var body: some View {
        Text("Test View")
    }
}

/// Test client container
struct TestClientContainer: ClientDependencies {
    let userClient = TestUserClient()
    let orderClient = TestOrderClient()
}

/// Test user client
actor TestUserClient: AxiomClient {
    struct State: Sendable {
        var users: [String: String] = [:]
        var isLoading: Bool = false
    }
    
    private(set) var stateSnapshot = State()
    let capabilities: CapabilityManager = CapabilityManager()
    private var observers: [WeakObserver] = []
    
    func updateState<T>(_ update: @Sendable (inout State) throws -> T) async rethrows -> T {
        let result = try update(&stateSnapshot)
        await notifyObservers()
        return result
    }
    
    func validateState() async throws {
        // Basic validation for testing
    }
    
    func initialize() async throws {
        // Initialize for testing
    }
    
    func shutdown() async {
        // Shutdown for testing
    }
    
    func addObserver<T: AxiomContext>(_ context: T) async {
        observers.append(WeakObserver(context))
    }
    
    func removeObserver<T: AxiomContext>(_ context: T) async {
        observers.removeAll { $0.observer === context }
    }
    
    func notifyObservers() async {
        // Notify observers of state change
        for observer in observers {
            if let context = observer.observer as? TestContext {
                await context.onClientStateChange(self)
            }
        }
    }
}

/// Test order client
actor TestOrderClient: AxiomClient {
    struct State: Sendable {
        var orders: [String] = []
        var total: Double = 0.0
    }
    
    private(set) var stateSnapshot = State()
    let capabilities: CapabilityManager = CapabilityManager()
    private var observers: [WeakObserver] = []
    
    func updateState<T>(_ update: @Sendable (inout State) throws -> T) async rethrows -> T {
        let result = try update(&stateSnapshot)
        await notifyObservers()
        return result
    }
    
    func validateState() async throws {
        // Basic validation for testing
    }
    
    func initialize() async throws {
        // Initialize for testing
    }
    
    func shutdown() async {
        // Shutdown for testing
    }
    
    func addObserver<T: AxiomContext>(_ context: T) async {
        observers.append(WeakObserver(context))
    }
    
    func removeObserver<T: AxiomContext>(_ context: T) async {
        observers.removeAll { $0.observer === context }
    }
    
    func notifyObservers() async {
        // Notify observers of state change
        for observer in observers {
            if let context = observer.observer as? TestContext {
                await context.onClientStateChange(self)
            }
        }
    }
}

/// Supporting types for testing
struct AnalyticsEvent {
    let name: String
    let parameters: [String: Any]
    let timestamp: Date = Date()
}

enum LifecycleEvent: Equatable {
    case appeared
    case disappeared
    case clientStateChanged(String)
    case errorHandled(String)
}

/// Test error implementation
struct TestAxiomError: AxiomError {
    let id: UUID = UUID()
    let category: ErrorCategory = .validation
    let severity: ErrorSeverity = .error
    let context: ErrorContext = ErrorContext(component: ComponentID("TestComponent"))
    let recoveryActions: [RecoveryAction] = [.retry(after: 1.0)]
    let userMessage: String
    let technicalDetails: String
    
    init(message: String, details: String = "") {
        self.userMessage = message
        self.technicalDetails = details
    }
}

// MARK: - AxiomContext Core Protocol Tests

@Test("AxiomContext initialization")
@MainActor
func testContextInitialization() async throws {
    let context = TestContext()
    
    // Verify proper initialization
    #expect(context.analyticsEvents.isEmpty)
    #expect(context.lifecycleEvents.isEmpty)
    #expect(context.lastError == nil)
    #expect(context.isLoading == false)
}

@Test("AxiomContext view-context 1:1 relationship")
@MainActor
func testViewContextRelationship() throws {
    let context = TestContext()
    let view = TestAxiomView(context: context)
    
    // Verify 1:1 type relationship at compile time
    #expect(TestAxiomView.Context.self == TestContext.self)
    #expect(TestContext.View.self == TestAxiomView.self)
    
    // Verify runtime relationship
    #expect(view.context === context)
}

@Test("AxiomContext lifecycle methods")
@MainActor
func testContextLifecycleMethods() async throws {
    let context = TestContext()
    
    // Test onAppear
    await context.onAppear()
    #expect(context.lifecycleEvents.contains(.appeared))
    
    // Test onDisappear
    await context.onDisappear()
    #expect(context.lifecycleEvents.contains(.disappeared))
    
    // Test onClientStateChange
    await context.onClientStateChange(context.clients.userClient)
    #expect(context.lifecycleEvents.contains(.clientStateChanged("TestUserClient")))
}

@Test("AxiomContext error handling")
@MainActor
func testContextErrorHandling() async throws {
    let context = TestContext()
    let testError = TestAxiomError(message: "Test error", details: "Test details")
    
    // Test error handling
    await context.handleError(testError)
    
    #expect(context.lastError?.userMessage == "Test error")
    #expect(context.lifecycleEvents.contains(.errorHandled("Test error")))
}

@Test("AxiomContext analytics tracking")
@MainActor
func testContextAnalyticsTracking() async throws {
    let context = TestContext()
    
    // Test basic analytics event
    await context.trackAnalyticsEvent("test_event", parameters: ["key": "value"])
    
    #expect(context.analyticsEvents.count == 1)
    #expect(context.analyticsEvents.first?.name == "test_event")
    #expect(context.analyticsEvents.first?.parameters["key"] as? String == "value")
}

// MARK: - AxiomContext Resource Access Tests

@Test("AxiomContext capability manager access")
@MainActor
func testCapabilityManagerAccess() async throws {
    let context = TestContext()
    
    // Test capability manager access
    let _ = try await context.capabilityManager()
    
    // Test capability validation convenience method
    try await context.validateCapability(.network)
    
    // Test multiple capability validation
    try await context.validateCapabilities([.network, .storage])
}

@Test("AxiomContext performance monitor access")
@MainActor
func testPerformanceMonitorAccess() async throws {
    let context = TestContext()
    
    // Test performance monitor access
    let _ = try await context.performanceMonitor()
    
    // Test performance metric recording
    let metric = PerformanceMetric(
        name: "test_metric",
        value: 100.0,
        unit: .count,
        category: .computeIntensive
    )
    await context.recordPerformanceMetric(metric)
}

@Test("AxiomContext performance tracking wrapper")
@MainActor
func testPerformanceTrackingWrapper() async throws {
    let context = TestContext()
    
    // Test performance tracking with successful operation
    let result = await context.withPerformanceTracking(
        operation: "test_operation",
        category: .computeIntensive
    ) {
        return "success"
    }
    
    #expect(result == "success")
    
    // Test performance tracking with throwing operation
    do {
        let _ = try await context.withPerformanceTracking(
            operation: "failing_operation",
            category: .computeIntensive
        ) {
            throw TestAxiomError(message: "Test failure")
        }
        #expect(Bool(false), "Should have thrown")
    } catch {
        #expect(error is TestAxiomError)
    }
}

// MARK: - AxiomContext Analytics Enhancement Tests

@Test("AxiomContext analytics wrapper with success")
@MainActor
func testAnalyticsWrapperSuccess() async throws {
    let context = TestContext()
    
    let result = await context.withAnalytics(
        action: "test_action",
        parameters: ["input": "test"]
    ) {
        return "success_result"
    }
    
    #expect(result == "success_result")
    #expect(context.analyticsEvents.count == 1)
    
    let event = context.analyticsEvents.first!
    #expect(event.name == "test_action")
    #expect(event.parameters["input"] as? String == "test")
    #expect(event.parameters["success"] as? Bool == true)
    #expect(event.parameters["duration_ms"] as? Int != nil)
}

@Test("AxiomContext analytics wrapper with failure")
@MainActor
func testAnalyticsWrapperFailure() async throws {
    let context = TestContext()
    
    do {
        let _ = try await context.withAnalytics(
            action: "failing_action",
            parameters: ["input": "test"]
        ) {
            throw TestAxiomError(message: "Test failure")
        }
        #expect(Bool(false), "Should have thrown")
    } catch {
        #expect(error is TestAxiomError)
    }
    
    #expect(context.analyticsEvents.count == 1)
    
    let event = context.analyticsEvents.first!
    #expect(event.name == "failing_action_failed")
    #expect(event.parameters["success"] as? Bool == false)
    #expect(event.parameters["error"] as? String != nil)
}

@Test("AxiomContext analytics convenience methods")
@MainActor
func testAnalyticsConvenienceMethods() async throws {
    let context = TestContext()
    
    // Test simple action tracking
    await context.trackAction("user_action", parameters: ["step": "1"])
    
    // Test interaction tracking
    await context.trackInteraction(element: "button", action: "tap", parameters: ["id": "submit"])
    
    // Test business event tracking
    await context.trackBusinessEvent(event: "purchase", value: 99.99, parameters: ["currency": "USD"])
    
    // Test lifecycle tracking
    await context.trackViewAppeared()
    await context.trackViewDisappeared()
    
    // Test error tracking
    let error = TestAxiomError(message: "Test error")
    await context.trackError(error, context: "test_context")
    
    // Test performance milestone tracking
    await context.trackPerformanceMilestone("load_complete", duration: 1.5)
    
    #expect(context.analyticsEvents.count == 7)
    #expect(context.analyticsEvents.contains { $0.name == "user_action" })
    #expect(context.analyticsEvents.contains { $0.name == "button_tap" })
    #expect(context.analyticsEvents.contains { $0.name == "business_purchase" })
    #expect(context.analyticsEvents.contains { $0.name == "view_appeared" })
    #expect(context.analyticsEvents.contains { $0.name == "view_disappeared" })
    #expect(context.analyticsEvents.contains { $0.name == "error_occurred" })
    #expect(context.analyticsEvents.contains { $0.name == "performance_load_complete" })
}

// MARK: - AxiomContext Client Integration Tests

@Test("AxiomContext client state change observation")
@MainActor
func testClientStateChangeObservation() async throws {
    let context = TestContext()
    
    // Setup context as observer
    await context.clients.userClient.addObserver(context)
    
    // Trigger state change
    let _ = await context.clients.userClient.updateState { state in
        state.users["test"] = "Test User"
        return ()
    }
    
    // Verify observation (would need to wait for async notification)
    // This test demonstrates the pattern - full implementation would need proper async testing
    let currentState = await context.clients.userClient.stateSnapshot
    #expect(currentState.users["test"] == "Test User")
}

@Test("AxiomContext multi-client orchestration")
@MainActor
func testMultiClientOrchestration() async throws {
    let context = TestContext()
    
    // Test orchestrating multiple clients
    let _ = await context.clients.userClient.updateState { state in
        state.users["user1"] = "John Doe"
        return ()
    }
    
    let _ = await context.clients.orderClient.updateState { state in
        state.orders.append("ORDER001")
        state.total = 99.99
        return ()
    }
    
    // Verify orchestration results
    let userState = await context.clients.userClient.stateSnapshot
    let orderState = await context.clients.orderClient.stateSnapshot
    
    #expect(userState.users["user1"] == "John Doe")
    #expect(orderState.orders.contains("ORDER001"))
    #expect(orderState.total == 99.99)
}

// MARK: - AxiomContext ObservableObject Tests

@Test("AxiomContext observable object behavior")
@MainActor
func testObservableObjectBehavior() async throws {
    let context = TestContext()
    var publishedChanges: [String] = []
    
    // Subscribe to published changes
    let cancellable = context.$isLoading.sink { _ in
        publishedChanges.append("isLoading")
    }
    
    let errorCancellable = context.$lastError.sink { _ in
        publishedChanges.append("lastError")
    }
    
    // Trigger published property changes
    context.isLoading = true
    context.lastError = TestAxiomError(message: "Test error")
    
    // Cleanup
    cancellable.cancel()
    errorCancellable.cancel()
    
    // Verify changes were published
    #expect(publishedChanges.contains("isLoading"))
    #expect(publishedChanges.contains("lastError"))
}

// MARK: - Supporting Test Infrastructure

// MARK: - AxiomContext Performance Tests

@Test("AxiomContext resource access performance")
@MainActor
func testResourceAccessPerformance() async throws {
    let context = TestContext()
    
    // Measure capability manager access performance
    let startTime = ContinuousClock.now
    for _ in 0..<100 {
        let _ = try await context.capabilityManager()
    }
    let capabilityDuration = ContinuousClock.now - startTime
    
    // Should be fast (< 100ms for 100 accesses)
    #expect(capabilityDuration < .milliseconds(100))
    
    // Measure performance monitor access performance
    let monitorStartTime = ContinuousClock.now
    for _ in 0..<100 {
        let _ = try await context.performanceMonitor()
    }
    let monitorDuration = ContinuousClock.now - monitorStartTime
    
    // Should be fast (< 100ms for 100 accesses)
    #expect(monitorDuration < .milliseconds(100))
}

@Test("AxiomContext analytics performance")
@MainActor
func testAnalyticsPerformance() async throws {
    let context = TestContext()
    
    // Measure analytics tracking performance
    let startTime = ContinuousClock.now
    for i in 0..<1000 {
        await context.trackAnalyticsEvent("performance_test_\(i)", parameters: ["index": i])
    }
    let duration = ContinuousClock.now - startTime
    
    // Should track 1000 events in < 500ms
    #expect(duration < .milliseconds(500))
    #expect(context.analyticsEvents.count == 1000)
}