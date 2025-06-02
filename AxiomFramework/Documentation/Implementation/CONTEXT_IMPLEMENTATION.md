# Context Implementation Guide

Comprehensive guide for implementing context orchestration with client coordination and SwiftUI integration in the Axiom framework.

## Overview

AxiomContext serves as the orchestration layer between actor-based clients and SwiftUI views. It provides read-only access to client state, coordinates cross-cutting concerns, and enables reactive binding with the user interface.

## Client Orchestration

### Core Principles

1. **Read-only Access**: Contexts observe client state but never mutate it directly
2. **Orchestration**: Contexts coordinate operations across multiple clients
3. **MainActor Integration**: All contexts run on the main actor for SwiftUI compatibility
4. **1:1 Relationship**: Each context typically serves one view (architectural constraint)

### Basic Implementation

```swift
import Axiom
import SwiftUI

// Manual context implementation
@MainActor
class UserContext: AxiomContext, ObservableObject {
    // Client references (read-only access)
    let userClient: UserClient
    let analyticsClient: AnalyticsClient
    let performanceClient: PerformanceClient
    
    // Framework integration
    let intelligence: AxiomIntelligence
    let performanceMonitor: PerformanceMonitor
    
    init(
        userClient: UserClient,
        analyticsClient: AnalyticsClient,
        performanceClient: PerformanceClient,
        intelligence: AxiomIntelligence,
        performanceMonitor: PerformanceMonitor
    ) {
        self.userClient = userClient
        self.analyticsClient = analyticsClient
        self.performanceClient = performanceClient
        self.intelligence = intelligence
        self.performanceMonitor = performanceMonitor
        
        // Register for component analysis
        intelligence.registerComponent(self)
        intelligence.startMonitoring(self)
        
        // Start observing client state changes
        Task {
            await observeStateChanges()
        }
    }
    
    // State observation implementation
    func observeStateChanges() async {
        // Framework handles state change observation
        // This method can be overridden for custom behavior
    }
}
```

### Macro-Generated Implementation

```swift
// Automatic context generation using @Context macro
@Context(client: UserClient)
class UserContext {
    // Additional custom methods can be added
    
    func customOrchestration() async {
        // Custom orchestration logic
        await userClient.performAction()
        await analyticsClient.trackAction()
    }
}

// Generated code:
@MainActor
class UserContext: AxiomContext, ObservableObject {
    let client: UserClient  // Note: renamed from userClient to client
    let intelligence: AxiomIntelligence
    let performanceMonitor: PerformanceMonitor
    
    init(client: UserClient, intelligence: AxiomIntelligence, performanceMonitor: PerformanceMonitor) {
        self.client = client
        self.intelligence = intelligence
        self.performanceMonitor = performanceMonitor
        
        intelligence.registerComponent(self)
        intelligence.startMonitoring(self)
        
        Task {
            await observeStateChanges()
        }
    }
    
    func bind<T>(_ keyPath: KeyPath<UserClient.State, T>) -> Binding<T> {
        // Generated type-safe binding implementation
    }
    
    func observeStateChanges() async {
        // Generated state observation logic
    }
    
    // Custom methods from original class are preserved
    func customOrchestration() async {
        await client.performAction()
        // Note: analytics would need to be added as additional parameter
    }
}
```

## SwiftUI Integration

### ObservableObject Conformance

```swift
@MainActor
class UserContext: AxiomContext, ObservableObject {
    let userClient: UserClient
    
    // SwiftUI integration through @Published properties or objectWillChange
    
    func triggerViewUpdate() {
        // Manually trigger view updates when needed
        objectWillChange.send()
    }
    
    // Automatic updates through state observation
    func observeStateChanges() async {
        for await _ in userClient.stateChanges {
            // Trigger SwiftUI updates on state changes
            objectWillChange.send()
        }
    }
}
```

### Published Properties and State Object Usage

```swift
@MainActor
class UserContext: AxiomContext, ObservableObject {
    let userClient: UserClient
    
    // @Published properties for direct SwiftUI integration
    @Published private var isLoading: Bool = false
    @Published private var errorMessage: String? = nil
    
    // State object integration in SwiftUI views
    init(userClient: UserClient) {
        self.userClient = userClient
        super.init()
        
        // Start observing state changes
        Task {
            await observeStateChanges()
        }
    }
    
    // Manually trigger objectWillChange for complex state updates
    func updateViewState() {
        objectWillChange.send()
    }
    
    // Example of @StateObject usage in SwiftUI views:
    /*
    struct UserView: View {
        @StateObject private var context = UserContext(userClient: UserClient())
        
        var body: some View {
            VStack {
                Text(context.userClient.stateSnapshot.name)
                
                if context.isLoading {
                    ProgressView()
                }
                
                if let error = context.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // Alternative using @ObservedObject when context is provided:
    struct UserDetailView: View {
        @ObservedObject var context: UserContext
        
        var body: some View {
            Text("User: \(context.userClient.stateSnapshot.name)")
        }
    }
    */
}
```

### State Binding

```swift
extension UserContext {
    // Type-safe binding to client state
    func bind<T>(_ keyPath: KeyPath<UserClient.State, T>) -> Binding<T> {
        return Binding(
            get: { [weak self] in
                guard let self = self else { 
                    // Provide safe default for deallocated context
                    return T.self as! T 
                }
                return self.userClient.stateSnapshot[keyPath: keyPath]
            },
            set: { [weak self] newValue in
                guard let self = self else { return }
                Task {
                    await self.userClient.updateState { state in
                        // Ensure keyPath is writable
                        guard let writableKeyPath = keyPath as? WritableKeyPath<UserClient.State, T> else {
                            assertionFailure("Cannot bind to read-only property")
                            return
                        }
                        state[keyPath: writableKeyPath] = newValue
                    }
                }
            }
        )
    }
    
    // Computed property binding
    func bindComputed<T>(_ computation: @escaping (UserClient.State) -> T) -> T {
        return computation(userClient.stateSnapshot)
    }
    
    // Derived state binding with transformation
    func bindDerived<T, U>(
        _ keyPath: KeyPath<UserClient.State, T>,
        transform: @escaping (T) -> U
    ) -> U {
        let value = userClient.stateSnapshot[keyPath: keyPath]
        return transform(value)
    }
}
```

### MainActor Integration

```swift
@MainActor
class UserContext: AxiomContext, ObservableObject {
    // All properties and methods automatically run on MainActor
    
    func updateUI() {
        // Safe to update UI directly - already on MainActor
        objectWillChange.send()
    }
    
    func performAsyncOperation() async {
        // Async operations maintain MainActor context
        await userClient.performAction()
        
        // UI updates are safe without additional MainActor calls
        objectWillChange.send()
    }
    
    // Computed properties are MainActor-safe
    var displayText: String {
        let state = userClient.stateSnapshot
        return "User: \(state.name) (\(state.email))"
    }
}
```

## Cross-Domain Coordination

### Multi-Client Orchestration

```swift
@MainActor
class ApplicationContext: AxiomContext, ObservableObject {
    // Multiple client references
    let userClient: UserClient
    let orderClient: OrderClient
    let analyticsClient: AnalyticsClient
    let notificationClient: NotificationClient
    
    // Framework integration
    let intelligence: AxiomIntelligence
    let performanceMonitor: PerformanceMonitor
    
    init(
        userClient: UserClient,
        orderClient: OrderClient,
        analyticsClient: AnalyticsClient,
        notificationClient: NotificationClient,
        intelligence: AxiomIntelligence,
        performanceMonitor: PerformanceMonitor
    ) {
        self.userClient = userClient
        self.orderClient = orderClient
        self.analyticsClient = analyticsClient
        self.notificationClient = notificationClient
        self.intelligence = intelligence
        self.performanceMonitor = performanceMonitor
        
        intelligence.registerComponent(self)
        intelligence.startMonitoring(self)
    }
    
    // Cross-domain coordination methods
    func processOrder(_ order: Order) async {
        // Orchestrate across multiple domains
        
        // 1. Create order
        await orderClient.createOrder(order)
        
        // 2. Update user order history
        await userClient.addOrderToHistory(order.id)
        
        // 3. Track analytics
        await analyticsClient.trackOrderCreation(order)
        
        // 4. Send notification
        await notificationClient.sendOrderConfirmation(order.id)
        
        // 5. Trigger UI update
        objectWillChange.send()
    }
    
    func handleUserLogout() async {
        // Coordinate logout across all domains
        
        // 1. Clear user authentication
        await userClient.logout()
        
        // 2. Clear sensitive order data
        await orderClient.clearUserOrders()
        
        // 3. Track logout analytics
        await analyticsClient.trackUserLogout()
        
        // 4. Clear notifications
        await notificationClient.clearUserNotifications()
        
        // UI update happens automatically through state observation
    }
}
```

### Transaction-like Operations

```swift
extension ApplicationContext {
    func performAtomicUserUpdate(_ updates: UserUpdates) async -> Bool {
        // Attempt coordinated update across multiple clients
        
        // Start transaction-like operation
        let userSnapshot = await userClient.stateSnapshot
        let analyticsSnapshot = await analyticsClient.stateSnapshot
        
        do {
            // Apply updates
            await userClient.updateProfile(updates.profile)
            await analyticsClient.recordProfileUpdate(updates.profile)
            
            // Validate consistency
            let newUserState = await userClient.stateSnapshot
            let newAnalyticsState = await analyticsClient.stateSnapshot
            
            if isConsistent(userState: newUserState, analyticsState: newAnalyticsState) {
                // Success - trigger UI update
                objectWillChange.send()
                return true
            } else {
                // Rollback on inconsistency
                await rollbackUpdates(
                    userSnapshot: userSnapshot,
                    analyticsSnapshot: analyticsSnapshot
                )
                return false
            }
            
        } catch {
            // Rollback on error
            await rollbackUpdates(
                userSnapshot: userSnapshot,
                analyticsSnapshot: analyticsSnapshot
            )
            return false
        }
    }
    
    private func rollbackUpdates(
        userSnapshot: UserClient.State,
        analyticsSnapshot: AnalyticsClient.State
    ) async {
        await userClient.restoreState(userSnapshot)
        await analyticsClient.restoreState(analyticsSnapshot)
    }
}
```

## 1:1 Relationship

### Architectural Constraint Compliance

```swift
// ✅ Correct: 1:1 relationship
@MainActor
class UserContext: AxiomContext, ObservableObject {
    // Single primary client
    let userClient: UserClient
    
    // Supporting clients for cross-cutting concerns
    let analyticsClient: AnalyticsClient
    let performanceClient: PerformanceClient
}

struct UserView: AxiomView {
    @ObservedObject var context: UserContext  // Single context reference
    
    var body: some View {
        VStack {
            Text(context.bind(\.name).wrappedValue)
            // View content
        }
    }
}

// ❌ Incorrect: Multiple contexts violate 1:1 constraint
struct BadView: View {
    @ObservedObject var userContext: UserContext
    @ObservedObject var orderContext: OrderContext  // Violates 1:1 constraint
    
    var body: some View {
        // This architecture violates the 1:1 view-context relationship
        Text("Bad Pattern")
    }
}
```

### Context Composition for Complex Views

```swift
// For complex views requiring multiple domains, compose at context level
@MainActor
class CompositeContext: AxiomContext, ObservableObject {
    // Composed contexts
    let userContext: UserContext
    let orderContext: OrderContext
    let settingsContext: SettingsContext
    
    // Framework integration
    let intelligence: AxiomIntelligence
    let performanceMonitor: PerformanceMonitor
    
    init(
        userContext: UserContext,
        orderContext: OrderContext,
        settingsContext: SettingsContext,
        intelligence: AxiomIntelligence,
        performanceMonitor: PerformanceMonitor
    ) {
        self.userContext = userContext
        self.orderContext = orderContext
        self.settingsContext = settingsContext
        self.intelligence = intelligence
        self.performanceMonitor = performanceMonitor
        
        intelligence.registerComponent(self)
        intelligence.startMonitoring(self)
    }
    
    // Delegate to appropriate sub-contexts
    func bindUser<T>(_ keyPath: KeyPath<UserClient.State, T>) -> Binding<T> {
        return userContext.bind(keyPath)
    }
    
    func bindOrder<T>(_ keyPath: KeyPath<OrderClient.State, T>) -> Binding<T> {
        return orderContext.bind(keyPath)
    }
    
    // Coordinated operations across domains
    func placeOrder(_ order: Order) async {
        await userContext.userClient.recordPendingOrder(order)
        await orderContext.orderClient.createOrder(order)
        
        objectWillChange.send()
    }
}

// Single context for complex view
struct DashboardView: AxiomView {
    @ObservedObject var context: CompositeContext  // Still 1:1 relationship
    
    var body: some View {
        VStack {
            UserSection(context: context)
            OrderSection(context: context)
            SettingsSection(context: context)
        }
    }
}
```

## Advanced Binding Patterns

### Conditional Binding

```swift
extension UserContext {
    func bindIfLoggedIn<T>(_ keyPath: KeyPath<UserClient.State, T>) -> Binding<T?> {
        return Binding(
            get: { [weak self] in
                guard let self = self else { return nil }
                let state = self.userClient.stateSnapshot
                return state.isLoggedIn ? state[keyPath: keyPath] : nil
            },
            set: { [weak self] newValue in
                guard let self = self,
                      let newValue = newValue else { return }
                
                Task {
                    await self.userClient.updateState { state in
                        guard state.isLoggedIn else { return }
                        guard let writableKeyPath = keyPath as? WritableKeyPath<UserClient.State, T> else { return }
                        state[keyPath: writableKeyPath] = newValue
                    }
                }
            }
        )
    }
}
```

### Debounced Binding

```swift
extension UserContext {
    func bindWithDebounce<T: Equatable>(
        _ keyPath: KeyPath<UserClient.State, T>,
        debounceTime: TimeInterval = 0.5
    ) -> Binding<T> {
        return Binding(
            get: { [weak self] in
                guard let self = self else { return T.self as! T }
                return self.userClient.stateSnapshot[keyPath: keyPath]
            },
            set: { [weak self] newValue in
                guard let self = self else { return }
                
                // Cancel previous debounce
                self.cancelPendingUpdate(for: keyPath)
                
                // Schedule new update
                self.scheduleUpdate(for: keyPath, value: newValue, after: debounceTime)
            }
        )
    }
    
    private func scheduleUpdate<T>(
        for keyPath: KeyPath<UserClient.State, T>,
        value: T,
        after delay: TimeInterval
    ) {
        Task {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            await userClient.updateState { state in
                guard let writableKeyPath = keyPath as? WritableKeyPath<UserClient.State, T> else { return }
                state[keyPath: writableKeyPath] = value
            }
        }
    }
}
```

### Validated Binding

```swift
extension UserContext {
    func bindWithValidation<T>(
        _ keyPath: KeyPath<UserClient.State, T>,
        validator: @escaping (T) -> Bool
    ) -> Binding<T> {
        return Binding(
            get: { [weak self] in
                guard let self = self else { return T.self as! T }
                return self.userClient.stateSnapshot[keyPath: keyPath]
            },
            set: { [weak self] newValue in
                guard let self = self else { return }
                
                // Validate before updating
                guard validator(newValue) else {
                    // Could trigger validation error state
                    return
                }
                
                Task {
                    await self.userClient.updateState { state in
                        guard let writableKeyPath = keyPath as? WritableKeyPath<UserClient.State, T> else { return }
                        state[keyPath: writableKeyPath] = newValue
                    }
                }
            }
        )
    }
}
```

## Performance Optimization

### Efficient State Access

```swift
@MainActor
class UserContext: AxiomContext, ObservableObject {
    // Cache frequently accessed state values
    private var cachedDisplayName: String?
    private var lastStateVersion: Int = 0
    
    var displayName: String {
        let currentState = userClient.stateSnapshot
        
        // Check if cache is still valid
        if currentState.version != lastStateVersion {
            cachedDisplayName = generateDisplayName(from: currentState)
            lastStateVersion = currentState.version
        }
        
        return cachedDisplayName ?? "Unknown"
    }
    
    private func generateDisplayName(from state: UserClient.State) -> String {
        if !state.firstName.isEmpty && !state.lastName.isEmpty {
            return "\(state.firstName) \(state.lastName)"
        } else if !state.firstName.isEmpty {
            return state.firstName
        } else if !state.email.isEmpty {
            return state.email
        } else {
            return "Guest User"
        }
    }
}
```

### Selective Updates

```swift
extension UserContext {
    // Only update specific UI components based on what changed
    func observeStateChanges() async {
        var previousState = await userClient.stateSnapshot
        
        for await currentState in userClient.stateChanges {
            // Check specific properties for changes
            if currentState.name != previousState.name ||
               currentState.email != previousState.email {
                // Trigger UI update only for profile changes
                await MainActor.run {
                    objectWillChange.send()
                }
            }
            
            if currentState.preferences != previousState.preferences {
                // Handle preferences changes separately
                await handlePreferencesChange(currentState.preferences)
            }
            
            previousState = currentState
        }
    }
    
    @MainActor
    private func handlePreferencesChange(_ preferences: UserPreferences) async {
        // Specific handling for preferences changes
        if preferences.theme != userClient.stateSnapshot.preferences.theme {
            // Theme change requires full UI refresh
            objectWillChange.send()
        }
    }
}
```

## Testing Patterns

### Unit Testing Contexts

```swift
import XCTest
@testable import Axiom

@MainActor
final class UserContextTests: XCTestCase {
    var context: UserContext!
    var mockUserClient: MockUserClient!
    var mockIntelligence: MockAxiomIntelligence!
    var mockPerformanceMonitor: MockPerformanceMonitor!
    
    override func setUp() async throws {
        mockUserClient = MockUserClient()
        mockIntelligence = MockAxiomIntelligence()
        mockPerformanceMonitor = MockPerformanceMonitor()
        
        context = UserContext(
            userClient: mockUserClient,
            intelligence: mockIntelligence,
            performanceMonitor: mockPerformanceMonitor
        )
    }
    
    func testStateBinding() async {
        // Test binding functionality
        await mockUserClient.updateName("Test User")
        
        let nameBinding = context.bind(\.name)
        XCTAssertEqual(nameBinding.wrappedValue, "Test User")
    }
    
    func testCrossClientOrchestration() async {
        // Test orchestration across multiple clients
        await context.processOrder(testOrder)
        
        // Verify coordination occurred
        XCTAssertTrue(mockUserClient.orderHistoryUpdated)
        XCTAssertTrue(mockAnalyticsClient.orderTracked)
    }
}
```

### Integration Testing

```swift
@MainActor
final class ContextIntegrationTests: XCTestCase {
    func testFullViewContextFlow() async throws {
        // Test complete view-context-client integration
        let capabilities = CapabilityManager()
        let userClient = UserClient(capabilities: capabilities)
        let context = UserContext(userClient: userClient, ...)
        
        // Simulate user interaction
        let nameBinding = context.bind(\.name)
        nameBinding.wrappedValue = "Integration Test"
        
        // Wait for async update
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify state propagation
        let finalState = await userClient.stateSnapshot
        XCTAssertEqual(finalState.name, "Integration Test")
    }
}
```

## Best Practices

### Architecture

1. **Single Responsibility**: Each context manages one primary domain
2. **Read-only Access**: Never mutate client state directly from context
3. **1:1 Relationship**: Maintain one context per view
4. **Composition**: Use context composition for complex scenarios

### Performance

1. **Selective Updates**: Only trigger UI updates when necessary
2. **Cache Computed Values**: Cache expensive computed properties
3. **Batch Operations**: Group related client operations
4. **Async Patterns**: Use async/await for all client interactions

### SwiftUI Integration

1. **MainActor Compliance**: Always mark contexts with @MainActor
2. **ObservableObject**: Conform to ObservableObject for reactive updates
3. **Weak References**: Use weak references in bindings to prevent cycles
4. **Lifecycle Management**: Properly handle view lifecycle events

### Testing

1. **Mock Dependencies**: Use mock clients and services for testing
2. **State Verification**: Test state propagation through binding
3. **Orchestration Testing**: Verify cross-client coordination
4. **Performance Testing**: Validate update performance

---

**Context Implementation Guide** - Complete guide for client orchestration, SwiftUI integration, and reactive binding with architectural constraint compliance