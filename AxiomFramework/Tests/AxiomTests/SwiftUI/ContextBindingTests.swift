import Testing
import SwiftUI
import Combine
@testable import Axiom

/// Context binding and reactivity tests for SwiftUI integration
/// 
/// Focuses on:
/// - Reactive binding performance and correctness
/// - Memory leak prevention in binding chains
/// - Type safety in binding relationships
/// - Complex state change propagation
@Suite("Context Binding Tests")
struct ContextBindingTests {
    
    // MARK: - Test Infrastructure
    
    /// Advanced context for binding testing
    @MainActor
    final class AdvancedBindingContext: AxiomContext, ObservableObject {
        typealias View = AdvancedBindingView
        typealias Clients = AdvancedBindingClientContainer
        
        let clients: AdvancedBindingClientContainer
        let intelligence: any AxiomIntelligence
        
        // Complex published properties for binding tests
        @Published var userState: UserDisplayState = UserDisplayState()
        @Published var orderState: OrderDisplayState = OrderDisplayState()
        @Published var uiState: UIDisplayState = UIDisplayState()
        
        // Performance tracking
        @Published var bindingMetrics: BindingMetrics = BindingMetrics()
        
        // Binding chain test properties
        @Published var derivedValue: String = ""
        @Published var computedProperty: Int = 0
        @Published var formattedDisplay: String = ""
        
        init() {
            self.clients = AdvancedBindingClientContainer()
            self.intelligence = MockBindingIntelligence()
            
            setupBindingObservation()
        }
        
        // MARK: - Lifecycle Implementation
        
        func onAppear() async {
            await refreshAllStates()
        }
        
        func onDisappear() async {
            // Cleanup if needed
        }
        
        func onClientStateChange<T: AxiomClient>(_ client: T) async {
            bindingMetrics.clientStateChanges += 1
            
            switch client {
            case is AdvancedUserClient:
                await updateUserState()
            case is AdvancedOrderClient:
                await updateOrderState()
            case is AdvancedUIClient:
                await updateUIState()
            default:
                break
            }
            
            await updateDerivedProperties()
        }
        
        // MARK: - Error Handling
        
        func handleError(_ error: any AxiomError) async {
            uiState.errorMessage = error.userMessage
            bindingMetrics.errorCount += 1
        }
        
        // MARK: - Analytics
        
        func trackAnalyticsEvent(_ event: String, parameters: [String: Any]) async {
            bindingMetrics.analyticsEvents += 1
        }
        
        // MARK: - Private Implementation
        
        private func setupBindingObservation() {
            // Setup client observers
            Task {
                await clients.userClient.addObserver(self)
                await clients.orderClient.addObserver(self)
                await clients.uiClient.addObserver(self)
            }
        }
        
        private func refreshAllStates() async {
            await updateUserState()
            await updateOrderState()
            await updateUIState()
            await updateDerivedProperties()
        }
        
        private func updateUserState() async {
            let state = await clients.userClient.stateSnapshot
            
            userState = UserDisplayState(
                isLoggedIn: state.currentUser != nil,
                username: state.currentUser?.name ?? "",
                userCount: state.users.count,
                lastActivity: state.lastActivity
            )
            
            bindingMetrics.userStateUpdates += 1
        }
        
        private func updateOrderState() async {
            let state = await clients.orderClient.stateSnapshot
            
            orderState = OrderDisplayState(
                orderCount: state.orders.count,
                totalValue: state.orders.values.reduce(0) { $0 + $1.total },
                isProcessing: state.isProcessingOrder,
                lastOrderDate: state.lastOrderDate
            )
            
            bindingMetrics.orderStateUpdates += 1
        }
        
        private func updateUIState() async {
            let state = await clients.uiClient.stateSnapshot
            
            uiState = UIDisplayState(
                currentView: state.activeView,
                isLoading: state.isLoading,
                navigationDepth: state.navigationStack.count,
                modalCount: state.presentedModals.count,
                errorMessage: uiState.errorMessage // Preserve existing error
            )
            
            bindingMetrics.uiStateUpdates += 1
        }
        
        private func updateDerivedProperties() async {
            // Complex derived property calculation
            derivedValue = "\(userState.username)-\(orderState.orderCount)-\(uiState.currentView)"
            
            computedProperty = userState.userCount + orderState.orderCount + uiState.navigationDepth
            
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formattedDisplay = "Users: \(userState.userCount), Orders: \(orderState.orderCount) at \(formatter.string(from: Date()))"
            
            bindingMetrics.derivedPropertyUpdates += 1
        }
        
        // MARK: - Test Helpers
        
        func simulateComplexStateChange() async {
            // Trigger cascading state changes
            await clients.userClient.updateState { state in
                state.users["new_user"] = AdvancedUser(
                    id: "new_user",
                    name: "Test User \(state.users.count)",
                    email: "test\(state.users.count)@test.com"
                )
            }
            
            await clients.orderClient.updateState { state in
                state.orders["new_order"] = AdvancedOrder(
                    id: "new_order",
                    userId: "new_user",
                    total: 99.99
                )
            }
            
            await clients.uiClient.updateState { state in
                state.navigationStack.append("order_details")
            }
        }
        
        func resetMetrics() {
            bindingMetrics = BindingMetrics()
        }
    }
    
    /// Test view for advanced binding validation
    struct AdvancedBindingView: AxiomView {
        typealias Context = AdvancedBindingContext
        @ObservedObject var context: AdvancedBindingContext
        
        var body: some View {
            VStack {
                // User section
                Section("User State") {
                    Text("Logged In: \(context.userState.isLoggedIn ? "Yes" : "No")")
                    Text("Username: \(context.userState.username)")
                    Text("User Count: \(context.userState.userCount)")
                }
                
                // Order section
                Section("Order State") {
                    Text("Order Count: \(context.orderState.orderCount)")
                    Text("Total Value: $\(context.orderState.totalValue, specifier: "%.2f")")
                    Text("Processing: \(context.orderState.isProcessing ? "Yes" : "No")")
                }
                
                // UI section
                Section("UI State") {
                    Text("Current View: \(context.uiState.currentView)")
                    Text("Loading: \(context.uiState.isLoading ? "Yes" : "No")")
                    Text("Nav Depth: \(context.uiState.navigationDepth)")
                    
                    if let error = context.uiState.errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                    }
                }
                
                // Derived properties
                Section("Derived") {
                    Text("Derived: \(context.derivedValue)")
                    Text("Computed: \(context.computedProperty)")
                    Text("Formatted: \(context.formattedDisplay)")
                }
                
                // Actions
                Button("Complex State Change") {
                    Task {
                        await context.simulateComplexStateChange()
                    }
                }
                
                // Metrics
                Section("Metrics") {
                    Text("User Updates: \(context.bindingMetrics.userStateUpdates)")
                    Text("Order Updates: \(context.bindingMetrics.orderStateUpdates)")
                    Text("UI Updates: \(context.bindingMetrics.uiStateUpdates)")
                    Text("Derived Updates: \(context.bindingMetrics.derivedPropertyUpdates)")
                }
            }
            .onAppear {
                Task {
                    await context.onAppear()
                }
            }
        }
    }
    
    // MARK: - Supporting Types
    
    struct UserDisplayState {
        var isLoggedIn: Bool = false
        var username: String = ""
        var userCount: Int = 0
        var lastActivity: Date = Date()
    }
    
    struct OrderDisplayState {
        var orderCount: Int = 0
        var totalValue: Double = 0.0
        var isProcessing: Bool = false
        var lastOrderDate: Date? = nil
    }
    
    struct UIDisplayState {
        var currentView: String = "main"
        var isLoading: Bool = false
        var navigationDepth: Int = 0
        var modalCount: Int = 0
        var errorMessage: String? = nil
    }
    
    struct BindingMetrics {
        var userStateUpdates: Int = 0
        var orderStateUpdates: Int = 0
        var uiStateUpdates: Int = 0
        var derivedPropertyUpdates: Int = 0
        var clientStateChanges: Int = 0
        var errorCount: Int = 0
        var analyticsEvents: Int = 0
    }
    
    // MARK: - Test Clients
    
    struct AdvancedBindingClientContainer: ClientDependencies {
        let userClient = AdvancedUserClient()
        let orderClient = AdvancedOrderClient()
        let uiClient = AdvancedUIClient()
    }
    
    struct AdvancedUser: Sendable {
        let id: String
        let name: String
        let email: String
        let createdAt: Date = Date()
    }
    
    struct AdvancedOrder: Sendable {
        let id: String
        let userId: String
        let total: Double
        let createdAt: Date = Date()
    }
    
    actor AdvancedUserClient: AxiomClient {
        struct State: Sendable {
            var users: [String: AdvancedUser] = [:]
            var currentUser: AdvancedUser? = nil
            var lastActivity: Date = Date()
            var isLoading: Bool = false
        }
        
        private(set) var stateSnapshot = State()
        let capabilities: CapabilityManager = CapabilityManager()
        private var observers: [WeakObserver] = []
        
        func updateState<T>(_ update: @Sendable (inout State) throws -> T) async rethrows -> T {
            let result = try update(&stateSnapshot)
            stateSnapshot.lastActivity = Date()
            await notifyObservers()
            return result
        }
        
        func validateState() async throws {}
        func initialize() async throws {}
        func shutdown() async { observers.removeAll() }
        
        func addObserver<T: AxiomContext>(_ context: T) async {
            observers.append(WeakObserver(context))
        }
        
        func removeObserver<T: AxiomContext>(_ context: T) async {
            observers.removeAll { $0.observer === context }
        }
        
        func notifyObservers() async {
            for observer in observers {
                if let context = observer.observer as? AdvancedBindingContext {
                    await context.onClientStateChange(self)
                }
            }
        }
    }
    
    actor AdvancedOrderClient: AxiomClient {
        struct State: Sendable {
            var orders: [String: AdvancedOrder] = [:]
            var isProcessingOrder: Bool = false
            var lastOrderDate: Date? = nil
        }
        
        private(set) var stateSnapshot = State()
        let capabilities: CapabilityManager = CapabilityManager()
        private var observers: [WeakObserver] = []
        
        func updateState<T>(_ update: @Sendable (inout State) throws -> T) async rethrows -> T {
            let result = try update(&stateSnapshot)
            if !stateSnapshot.orders.isEmpty {
                stateSnapshot.lastOrderDate = Date()
            }
            await notifyObservers()
            return result
        }
        
        func validateState() async throws {}
        func initialize() async throws {}
        func shutdown() async { observers.removeAll() }
        
        func addObserver<T: AxiomContext>(_ context: T) async {
            observers.append(WeakObserver(context))
        }
        
        func removeObserver<T: AxiomContext>(_ context: T) async {
            observers.removeAll { $0.observer === context }
        }
        
        func notifyObservers() async {
            for observer in observers {
                if let context = observer.observer as? AdvancedBindingContext {
                    await context.onClientStateChange(self)
                }
            }
        }
    }
    
    actor AdvancedUIClient: AxiomClient {
        struct State: Sendable {
            var activeView: String = "main"
            var isLoading: Bool = false
            var navigationStack: [String] = []
            var presentedModals: Set<String> = []
        }
        
        private(set) var stateSnapshot = State()
        let capabilities: CapabilityManager = CapabilityManager()
        private var observers: [WeakObserver] = []
        
        func updateState<T>(_ update: @Sendable (inout State) throws -> T) async rethrows -> T {
            let result = try update(&stateSnapshot)
            await notifyObservers()
            return result
        }
        
        func validateState() async throws {}
        func initialize() async throws {}
        func shutdown() async { observers.removeAll() }
        
        func addObserver<T: AxiomContext>(_ context: T) async {
            observers.append(WeakObserver(context))
        }
        
        func removeObserver<T: AxiomContext>(_ context: T) async {
            observers.removeAll { $0.observer === context }
        }
        
        func notifyObservers() async {
            for observer in observers {
                if let context = observer.observer as? AdvancedBindingContext {
                    await context.onClientStateChange(self)
                }
            }
        }
    }
    
    /// Mock intelligence for binding tests
    actor MockBindingIntelligence: AxiomIntelligence {
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
    
    // MARK: - Core Binding Tests
    
    @Test("Complex binding chain updates")
    @MainActor
    func testComplexBindingChainUpdates() async throws {
        let context = AdvancedBindingContext()
        
        // Track all property changes
        var userStateChanges = 0
        var orderStateChanges = 0
        var derivedValueChanges = 0
        var computedPropertyChanges = 0
        
        let userStateCancellable = context.$userState.sink { _ in userStateChanges += 1 }
        let orderStateCancellable = context.$orderState.sink { _ in orderStateChanges += 1 }
        let derivedValueCancellable = context.$derivedValue.sink { _ in derivedValueChanges += 1 }
        let computedPropertyCancellable = context.$computedProperty.sink { _ in computedPropertyChanges += 1 }
        
        // Trigger initial load
        await context.onAppear()
        
        // Reset counters after initial load
        userStateChanges = 0
        orderStateChanges = 0
        derivedValueChanges = 0
        computedPropertyChanges = 0
        
        // Perform complex state change
        await context.simulateComplexStateChange()
        
        // Wait for all updates to propagate
        try await Task.sleep(for: .milliseconds(100))
        
        // Cleanup subscriptions
        userStateCancellable.cancel()
        orderStateCancellable.cancel()
        derivedValueCancellable.cancel()
        computedPropertyCancellable.cancel()
        
        // Verify cascading updates occurred
        #expect(userStateChanges > 0, "User state should have updated")
        #expect(orderStateChanges > 0, "Order state should have updated")
        #expect(derivedValueChanges > 0, "Derived value should have updated")
        #expect(computedPropertyChanges > 0, "Computed property should have updated")
        
        // Verify final state
        #expect(context.userState.userCount > 0)
        #expect(context.orderState.orderCount > 0)
        #expect(!context.derivedValue.isEmpty)
        #expect(context.computedProperty > 0)
    }
    
    @Test("Binding performance under rapid updates")
    @MainActor
    func testBindingPerformanceUnderRapidUpdates() async throws {
        let context = AdvancedBindingContext()
        let updateCount = 100
        
        // Ensure observers are setup and context is initialized
        await context.onAppear()
        
        // Reset metrics after setup
        context.resetMetrics()
        
        // Track binding updates
        var totalBindingUpdates = 0
        let cancellable = context.$bindingMetrics.sink { _ in
            totalBindingUpdates += 1
        }
        
        // Small delay to ensure observer setup is complete
        try await Task.sleep(for: .milliseconds(10))
        
        // Measure rapid updates
        let startTime = ContinuousClock.now
        
        // Use batched sequential updates for reliable actor state management
        for i in 0..<updateCount {
            await context.clients.userClient.updateState { state in
                state.users["rapid_\(i)"] = AdvancedUser(
                    id: "rapid_\(i)",
                    name: "Rapid User \(i)",
                    email: "rapid\(i)@test.com"
                )
            }
            
            // Allow observer notifications to propagate periodically
            if i % 10 == 0 {
                try await Task.sleep(for: .milliseconds(1))
            }
        }
        
        // Wait for all binding updates to complete with extra time for the last update
        try await Task.sleep(for: .milliseconds(300))
        
        let duration = ContinuousClock.now - startTime
        let durationSeconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        let updatesPerSecond = Double(updateCount) / durationSeconds
        
        cancellable.cancel()
        
        print("📊 Rapid Binding Updates Performance:")
        print("   Updates: \(updateCount)")
        print("   Duration: \(duration)")
        print("   Updates/sec: \(String(format: "%.0f", updatesPerSecond))")
        print("   Binding propagations: \(totalBindingUpdates)")
        
        // Performance targets (realistic for actor-based systems with full observer patterns and comprehensive testing)
        #expect(updatesPerSecond > 250.0, "Binding updates too slow: \(String(format: "%.0f", updatesPerSecond)) updates/sec")
        #expect(context.bindingMetrics.userStateUpdates >= updateCount, "Not all user state updates propagated")
        
        // Verify state consistency
        #expect(context.userState.userCount == updateCount)
    }
    
    @Test("Memory efficiency in binding chains")
    @MainActor
    func testMemoryEfficiencyInBindingChains() async throws {
        var contexts: [AdvancedBindingContext] = []
        var cancellables: [AnyCancellable] = []
        
        let memoryBefore = MemoryTracker.currentUsage()
        
        // Create multiple contexts with binding chains
        for i in 0..<50 {
            let context = AdvancedBindingContext()
            contexts.append(context)
            
            // Setup multiple bindings per context
            let cancellable = context.$userState
                .combineLatest(context.$orderState)
                .combineLatest(context.$uiState)
                .sink { _ in
                    // Simulate binding work
                }
            
            cancellables.append(cancellable)
            
            // Add some data to each context
            await context.clients.userClient.updateState { state in
                state.users["user_\(i)"] = AdvancedUser(
                    id: "user_\(i)",
                    name: "User \(i)",
                    email: "user\(i)@test.com"
                )
            }
        }
        
        let memoryAfter = MemoryTracker.currentUsage()
        let memoryPerContext = (memoryAfter - memoryBefore) / contexts.count
        
        print("📊 Binding Chain Memory Usage:")
        print("   Contexts: \(contexts.count)")
        print("   Total Memory: \((memoryAfter - memoryBefore) / 1024 / 1024) MB")
        print("   Memory/Context: \(memoryPerContext / 1024) KB")
        
        // Cleanup
        cancellables.forEach { $0.cancel() }
        contexts.removeAll()
        
        // Target: < 500KB per context with bindings
        #expect(memoryPerContext < 500_000, "Memory per context too high: \(memoryPerContext / 1024) KB")
    }
    
    @Test("Binding correctness under concurrent updates")
    @MainActor
    func testBindingCorrectnessUnderConcurrentUpdates() async throws {
        let context = AdvancedBindingContext()
        
        // Track state consistency
        var stateInconsistencies = 0
        let cancellable = context.$bindingMetrics.sink { metrics in
            // Check for inconsistent state
            if context.userState.userCount != context.computedProperty - context.orderState.orderCount - context.uiState.navigationDepth {
                stateInconsistencies += 1
            }
        }
        
        // Perform concurrent updates to different clients
        await withTaskGroup(of: Void.self) { group in
            // User updates
            for i in 0..<20 {
                group.addTask {
                    await context.clients.userClient.updateState { state in
                        state.users["concurrent_user_\(i)"] = AdvancedUser(
                            id: "concurrent_user_\(i)",
                            name: "Concurrent User \(i)",
                            email: "concurrent\(i)@test.com"
                        )
                    }
                }
            }
            
            // Order updates
            for i in 0..<20 {
                group.addTask {
                    await context.clients.orderClient.updateState { state in
                        state.orders["concurrent_order_\(i)"] = AdvancedOrder(
                            id: "concurrent_order_\(i)",
                            userId: "concurrent_user_\(i)",
                            total: Double(i) * 10.0
                        )
                    }
                }
            }
            
            // UI updates
            for i in 0..<20 {
                group.addTask {
                    await context.clients.uiClient.updateState { state in
                        if i % 2 == 0 {
                            state.navigationStack.append("view_\(i)")
                        } else {
                            if !state.navigationStack.isEmpty {
                                state.navigationStack.removeLast()
                            }
                        }
                    }
                }
            }
        }
        
        // Wait for all bindings to stabilize
        try await Task.sleep(for: .milliseconds(300))
        
        cancellable.cancel()
        
        print("📊 Concurrent Binding Updates:")
        print("   User count: \(context.userState.userCount)")
        print("   Order count: \(context.orderState.orderCount)")
        print("   Nav depth: \(context.uiState.navigationDepth)")
        print("   Computed: \(context.computedProperty)")
        print("   Inconsistencies: \(stateInconsistencies)")
        
        // Verify final consistency
        let expectedComputed = context.userState.userCount + context.orderState.orderCount + context.uiState.navigationDepth
        #expect(context.computedProperty == expectedComputed, "Computed property inconsistent: \(context.computedProperty) vs \(expectedComputed)")
        
        // Should have minimal inconsistencies during updates
        #expect(stateInconsistencies < 5, "Too many state inconsistencies: \(stateInconsistencies)")
    }
    
    @Test("Binding cleanup and memory leak prevention")
    @MainActor
    func testBindingCleanupAndMemoryLeakPrevention() async throws {
        weak var weakContext: AdvancedBindingContext?
        var cancellables: [AnyCancellable] = []
        
        // Create context and bindings in isolated scope
        do {
            let context = AdvancedBindingContext()
            weakContext = context
            
            // Create multiple bindings
            let userBinding = context.$userState.sink { _ in }
            let orderBinding = context.$orderState.sink { _ in }
            let derivedBinding = context.$derivedValue.sink { _ in }
            let metricsBinding = context.$bindingMetrics.sink { _ in }
            
            cancellables = [userBinding, orderBinding, derivedBinding, metricsBinding]
            
            // Use the context
            await context.onAppear()
            await context.simulateComplexStateChange()
            
            // Verify context exists
            #expect(weakContext != nil)
        }
        
        // Cancel all bindings
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        // Force cleanup
        for _ in 0..<10 {
            autoreleasepool {
                let _ = Array(0..<1000).map { $0 }
            }
        }
        
        // Wait for cleanup
        try await Task.sleep(for: .milliseconds(100))
        
        // Verify context was deallocated
        #expect(weakContext == nil, "Context not deallocated - binding memory leak detected")
    }
    
    @Test("Complex derived property updates")
    @MainActor
    func testComplexDerivedPropertyUpdates() async throws {
        let context = AdvancedBindingContext()
        
        // Track derived property changes
        var derivedUpdates: [String] = []
        var formattedUpdates: [String] = []
        
        let derivedCancellable = context.$derivedValue.sink { value in
            derivedUpdates.append(value)
        }
        
        let formattedCancellable = context.$formattedDisplay.sink { value in
            formattedUpdates.append(value)
        }
        
        // Trigger updates that should cause derived property changes
        await context.onAppear()
        
        // Clear initial values
        derivedUpdates.removeAll()
        formattedUpdates.removeAll()
        
        // Perform sequential updates
        await context.clients.userClient.updateState { state in
            let testUser = AdvancedUser(id: "test", name: "TestUser", email: "test@test.com")
            state.currentUser = testUser
            state.users["test"] = testUser  // Add to users collection for userCount
        }
        
        await context.clients.orderClient.updateState { state in
            state.orders["order1"] = AdvancedOrder(id: "order1", userId: "test", total: 50.0)
        }
        
        await context.clients.uiClient.updateState { state in
            state.activeView = "order_view"
        }
        
        // Wait for all updates
        try await Task.sleep(for: .milliseconds(100))
        
        // Cleanup
        derivedCancellable.cancel()
        formattedCancellable.cancel()
        
        print("📊 Derived Property Updates:")
        print("   Derived updates: \(derivedUpdates.count)")
        print("   Formatted updates: \(formattedUpdates.count)")
        print("   Final derived: \(context.derivedValue)")
        print("   Final formatted: \(context.formattedDisplay)")
        
        // Verify derived properties were updated
        #expect(derivedUpdates.count >= 3, "Should have at least 3 derived updates")
        #expect(formattedUpdates.count >= 3, "Should have at least 3 formatted updates")
        
        // Verify final values are correct
        #expect(context.derivedValue.contains("TestUser"))
        #expect(context.derivedValue.contains("order_view"))
        #expect(context.formattedDisplay.contains("Users: 1"))
        #expect(context.formattedDisplay.contains("Orders: 1"))
    }
}


