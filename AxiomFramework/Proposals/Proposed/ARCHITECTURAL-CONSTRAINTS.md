# RFC-001: Axiom Architectural Constraints

**RFC Number**: 001  
**Title**: Axiom Architectural Constraints  
**Status**: Proposed  
**Type**: Architecture  
**Created**: 2025-01-06  
**Authors**: Axiom Framework Team  
**Revision**: 3.0

## Abstract

This RFC defines the permanent and immutable architectural constraints of the Axiom framework. It establishes exactly seven component types and nine architectural constraints that form the non-negotiable foundation of all Axiom applications.

## Motivation

iOS development requires clear architectural boundaries to ensure maintainable, testable, and thread-safe applications. Axiom enforces these boundaries through compile-time and runtime constraints that prevent common architectural mistakes.

## Specification

### Section 1: Component Types

The Axiom architecture consists of exactly seven component types. These types are permanent and cannot be extended, modified, or removed.

#### 1.1 Capability
- **Purpose**: External system access
- **Dependencies**: None (leaf nodes)
- **Thread Safety**: Implementation-specific
- **Examples**: NetworkCapability, StorageCapability, BiometricsCapability

#### 1.2 Owned State
- **Purpose**: Domain model representation
- **Dependencies**: None
- **Thread Safety**: Value types with immutable snapshots
- **Ownership**: 1:1 relationship with a single Client

#### 1.3 Stateful Client
- **Purpose**: Domain logic with persistent state
- **Dependencies**: Capabilities only
- **Thread Safety**: Actor isolation
- **State**: Owns exactly one State type

#### 1.4 Stateless Client
- **Purpose**: Pure computation and transformation
- **Dependencies**: Capabilities only
- **Thread Safety**: Actor isolation
- **State**: None

#### 1.5 Orchestrator
- **Purpose**: Application lifecycle management
- **Dependencies**: Creates root Contexts
- **Thread Safety**: @MainActor
- **Cardinality**: One per application

#### 1.6 Context
- **Purpose**: Feature coordination
- **Dependencies**: Clients and downstream Contexts
- **Thread Safety**: @MainActor
- **Composition**: Forms directed acyclic graph (DAG)

#### 1.7 Presentation
- **Purpose**: User interface
- **Dependencies**: Exactly one Context
- **Thread Safety**: SwiftUI View
- **Logic**: None (presentation only)

### Section 2: Architectural Constraints

The following nine constraints are permanent and immutable:

#### 2.1 Client Dependency Constraint
Clients (both Stateful and Stateless) can ONLY depend on Capabilities.

#### 2.2 Context Dependency Constraint
Contexts can ONLY depend on Clients and downstream Contexts.

#### 2.3 Capability Independence Constraint
Capabilities have NO dependencies.

#### 2.4 View-Context Binding Constraint
Each View has exactly ONE Context dependency.

#### 2.5 Unidirectional Flow Constraint
Dependencies flow in one direction: Orchestrator → Context → Client → Capability → System.

#### 2.6 Client Isolation Constraint
Clients cannot depend on other Clients.

#### 2.7 State Ownership Constraint
Each State is owned by exactly ONE Client.

#### 2.8 Context Composition Constraint
Contexts form a directed acyclic graph with no circular dependencies.

#### 2.9 Orchestrator Responsibility Constraint
Contexts can only be created through the Orchestrator's factory methods.

### Section 3: Protocol Definitions

```swift
// Component protocols define the contract for each type

protocol Capability {
    var isAvailable: Bool { get }
    func checkAvailability() async -> Bool
}

protocol Client: Actor {
    associatedtype Action
    func send(_ action: Action) async throws
    
    // Lifecycle
    func activate() async throws
    func deactivate() async
}

protocol StatefulClient: Client {
    associatedtype State
    associatedtype StateUpdate
    
    // Current state snapshot
    var state: State { get async }
    
    // State change stream
    var stateUpdates: AsyncStream<StateUpdate> { get }
}

protocol StatelessClient: Client {
    // No state requirement
}

@MainActor
protocol Context: ObservableObject {
    associatedtype Action
    var orchestrator: Orchestrator { get }
    var downstreamContexts: [any Context] { get }
    func send(_ action: Action) async
    
    // Lifecycle
    func onAppear() async
    func onDisappear() async
    func onBackground() async
    func onForeground() async
    
    // State observation
    func startObservation() async
    func stopObservation()
}

@MainActor
protocol Orchestrator: ObservableObject {
    var rootContexts: [any Context] { get }
    var capabilityRegistry: CapabilityRegistry { get }
    
    // Context factory
    func createContext<T: Context>(_ type: T.Type, parent: (any Context)?) -> T
}
```

### Section 4: Context Composition

#### 4.1 Terminology
- **Upstream Context**: A context that manages downstream contexts
- **Downstream Context**: A context that is a dependency of an upstream context
- **Root Context**: A context with no upstream dependencies
- **Leaf Context**: A context with no downstream dependencies

#### 4.2 Composition Rules
1. Dependencies must be unidirectional (no cycles)
2. Upstream contexts declare their downstream dependencies
3. A context can have multiple downstream contexts
4. A context can be downstream of multiple upstream contexts
5. Only the Orchestrator factory creates contexts
6. Dependencies are immutable after initialization

#### 4.3 Example DAG
```
Orchestrator
     └── CheckoutContext (root)
              ├── UserContext
              │        ├── ProfileContext (leaf)
              │        └── OrderContext (leaf)
              ├── CartContext (leaf)
              └── PaymentContext (leaf)
```

### Section 5: Implementation Examples

#### 5.1 Valid Implementation Pattern
```swift
// State owned by Client
struct UserState {
    let username: String
    let isLoggedIn: Bool
}

// State updates for reactive changes
enum UserStateUpdate {
    case loggedIn(username: String)
    case loggedOut
    case error(Error)
}

// Capability with no dependencies
final class NetworkCapability: Capability {
    private(set) var isAvailable = true
    
    func checkAvailability() async -> Bool {
        // Check network reachability
        isAvailable = true // Simplified
        return isAvailable
    }
    
    func request(_ endpoint: String) async throws -> Data {
        guard isAvailable else {
            throw NetworkError.unavailable
        }
        // Direct system API usage
        return Data()
    }
}

// Stateful Client with state stream
actor UserClient: StatefulClient {
    typealias Action = UserAction
    typealias State = UserState
    typealias StateUpdate = UserStateUpdate
    
    private let network: NetworkCapability  // ✅ Valid
    private(set) var state = UserState(username: "", isLoggedIn: false)
    
    // State update stream
    private let (stream, continuation) = AsyncStream.makeStream(of: UserStateUpdate.self)
    var stateUpdates: AsyncStream<UserStateUpdate> { stream }
    
    init(network: NetworkCapability) {
        self.network = network
    }
    
    func send(_ action: UserAction) async throws {
        switch action {
        case .login(let username):
            let data = try await network.request("/login")
            state = UserState(username: username, isLoggedIn: true)
            continuation.yield(.loggedIn(username: username))
        case .logout:
            state = UserState(username: "", isLoggedIn: false)
            continuation.yield(.loggedOut)
        }
    }
    
    func activate() async throws {
        guard await network.checkAvailability() else {
            throw NetworkError.unavailable
        }
    }
    
    func deactivate() async {
        continuation.finish()
    }
}

// Context with state observation
@MainActor
final class UserContext: Context {
    typealias Action = UserAction
    
    let orchestrator: Orchestrator
    let downstreamContexts: [any Context]
    private let userClient: UserClient
    private var observationTask: Task<Void, Never>?
    
    @Published private(set) var username = ""
    @Published private(set) var isLoggedIn = false
    @Published private(set) var error: Error?
    
    init(orchestrator: Orchestrator, orderContext: OrderContext, profileContext: ProfileContext, userClient: UserClient) {
        self.orchestrator = orchestrator
        self.downstreamContexts = [orderContext, profileContext]
        self.userClient = userClient
    }
    
    func send(_ action: UserAction) async {
        do {
            try await userClient.send(action)
            error = nil
        } catch {
            self.error = error
        }
    }
    
    func startObservation() async {
        // Activate client
        try? await userClient.activate()
        
        // Observe state updates
        observationTask = Task { [weak self] in
            guard let self else { return }
            for await update in userClient.stateUpdates {
                switch update {
                case .loggedIn(let username):
                    self.username = username
                    self.isLoggedIn = true
                    self.error = nil
                case .loggedOut:
                    self.username = ""
                    self.isLoggedIn = false
                    self.error = nil
                case .error(let error):
                    self.error = error
                }
            }
        }
    }
    
    func stopObservation() {
        observationTask?.cancel()
        Task { await userClient.deactivate() }
    }
    
    // Lifecycle methods
    func onAppear() async {
        await startObservation()
    }
    
    func onDisappear() async {
        stopObservation()
    }
    
    func onBackground() async {
        // Save state if needed
    }
    
    func onForeground() async {
        // Refresh state if needed
    }
}

// View with lifecycle integration
struct UserView: View {
    @ObservedObject var context: UserContext  // ✅ Exactly one context
    
    var body: some View {
        Group {
            if context.isLoggedIn {
                Text("Welcome, \(context.username)")
            } else if let error = context.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            } else {
                Text("Please log in")
            }
        }
        .task {
            await context.onAppear()
        }
        .onDisappear {
            Task { await context.onDisappear() }
        }
    }
}
```

#### 5.2 Constraint Violations to Avoid
```swift
// ❌ VIOLATION: Client-to-client dependency
actor OrderClient: StatefulClient {
    private let userClient: UserClient  // NEVER ALLOWED
}

// ❌ VIOLATION: Context accessing capability
@MainActor 
final class AppContext: Context {
    private let network: NetworkCapability  // NEVER ALLOWED
}

// ❌ VIOLATION: Capability with dependencies
final class CacheCapability: Capability {
    private let logger: LoggerCapability  // NEVER ALLOWED
}

// ❌ VIOLATION: Shared state between clients
class SharedUserState {
    static let shared = SharedUserState()  // NEVER ALLOWED
}

// ❌ VIOLATION: Circular context dependencies
@MainActor
final class ContextA: Context {
    init(contextB: ContextB) {
        self.downstreamContexts = [contextB]
        contextB.downstreamContexts = [self]  // CREATES CYCLE
    }
}

// ❌ VIOLATION: Context creating contexts directly
@MainActor
final class ParentContext: Context {
    func createChild() -> ChildContext {  // NEVER ALLOWED
        return ChildContext()  // Must use orchestrator.createContext
    }
}

// ✅ CORRECT: Context creation through orchestrator
@MainActor
final class ParentContext: Context {
    func createChild() -> ChildContext {
        orchestrator.createContext(ChildContext.self, parent: self)
    }
}

// ❌ VIOLATION: View with multiple contexts
struct ComplexView: View {
    @ObservedObject var userContext: UserContext
    @ObservedObject var orderContext: OrderContext  // NEVER ALLOWED
}
```

### Section 6: Enforcement Mechanisms

#### 6.1 Compile-Time Enforcement
```swift
// Swift macro annotations
@AxiomClient
actor OrderClient {
    @Capability let payment: PaymentCapability  // ✅ Allowed
    @Client let userClient: UserClient          // ❌ Compile error
}
```

#### 6.2 Build-Time Enforcement
```yaml
# SwiftLint rules
axiom_constraints:
  - client_capability_only: error
  - context_client_only: error
  - capability_no_dependencies: error
  - view_single_context: error
```

#### 6.3 Runtime Validation
```swift
#if DEBUG
extension Client {
    func validateConstraints() {
        // Runtime dependency validation
    }
}
#endif
```

### Section 7: State Management Patterns

#### 7.1 State Update Streams

Stateful clients must provide reactive state updates through AsyncStream:

```swift
actor ProductClient: StatefulClient {
    typealias State = ProductState
    typealias StateUpdate = ProductStateUpdate
    
    private(set) var state = ProductState(items: [])
    private let (stream, continuation) = AsyncStream.makeStream(of: ProductStateUpdate.self)
    var stateUpdates: AsyncStream<ProductStateUpdate> { stream }
    
    func send(_ action: ProductAction) async throws {
        switch action {
        case .addItem(let item):
            state.items.append(item)
            continuation.yield(.itemAdded(item))
        case .removeItem(let id):
            state.items.removeAll { $0.id == id }
            continuation.yield(.itemRemoved(id))
        }
    }
    
    deinit {
        continuation.finish()
    }
}
```

#### 7.2 Context State Observation

Contexts observe client state updates and transform them into @Published properties:

```swift
@MainActor
final class ProductContext: Context {
    @Published private(set) var items: [Product] = []
    @Published private(set) var totalPrice: Decimal = 0
    
    private var observationTask: Task<Void, Never>?
    
    func startObservation() async {
        observationTask = Task { [weak self] in
            guard let self else { return }
            
            // Initial state
            let state = await productClient.state
            self.items = state.items
            self.totalPrice = state.totalPrice
            
            // Observe updates
            for await update in productClient.stateUpdates {
                switch update {
                case .itemAdded(let item):
                    self.items.append(item)
                    self.recalculateTotal()
                case .itemRemoved(let id):
                    self.items.removeAll { $0.id == id }
                    self.recalculateTotal()
                }
            }
        }
    }
}
```

### Section 8: Capability Registry

#### 8.1 Registry Implementation

```swift
@MainActor
final class CapabilityRegistry {
    private var capabilities: [ObjectIdentifier: any Capability] = [:]
    private let lock = NSLock()
    
    func register<T: Capability>(_ capability: T) {
        lock.withLock {
            capabilities[ObjectIdentifier(T.self)] = capability
        }
    }
    
    func resolve<T: Capability>(_ type: T.Type) -> T {
        lock.withLock {
            guard let capability = capabilities[ObjectIdentifier(type)] as? T else {
                fatalError("Capability \(type) not registered. Register with orchestrator.capabilityRegistry.register()")
            }
            return capability
        }
    }
    
    func resolveOptional<T: Capability>(_ type: T.Type) -> T? {
        lock.withLock {
            capabilities[ObjectIdentifier(type)] as? T
        }
    }
}
```

#### 8.2 Orchestrator Integration

```swift
@MainActor
final class AppOrchestrator: Orchestrator {
    let capabilityRegistry = CapabilityRegistry()
    private(set) var rootContexts: [any Context] = []
    
    init() {
        // Register capabilities
        capabilityRegistry.register(NetworkCapability())
        capabilityRegistry.register(StorageCapability())
        capabilityRegistry.register(BiometricsCapability())
    }
    
    func createContext<T: Context>(_ type: T.Type, parent: (any Context)?) -> T {
        // Context factory with dependency injection
        // Implementation depends on specific context requirements
        fatalError("Subclass must implement createContext")
    }
}
```

### Section 9: Testing Patterns

#### 9.1 Mock Capabilities

```swift
protocol MockCapability: Capability {
    func reset()
}

final class MockNetworkCapability: NetworkCapability, MockCapability {
    var mockResponses: [String: Result<Data, Error>] = [:]
    var requestCount = 0
    
    override func request(_ endpoint: String) async throws -> Data {
        requestCount += 1
        guard let result = mockResponses[endpoint] else {
            throw NetworkError.notFound
        }
        return try result.get()
    }
    
    func reset() {
        mockResponses.removeAll()
        requestCount = 0
    }
}
```

#### 9.2 Testable Clients

```swift
protocol TestableClient: Client {
    associatedtype MockState
    func reset(to state: MockState) async
}

extension UserClient: TestableClient {
    typealias MockState = UserState
    
    func reset(to mockState: UserState) async {
        state = mockState
        continuation.yield(.loggedIn(username: mockState.username))
    }
}
```

#### 9.3 Integration Testing

```swift
final class UserFlowTests: XCTestCase {
    var orchestrator: TestOrchestrator!
    var mockNetwork: MockNetworkCapability!
    
    override func setUp() async throws {
        orchestrator = TestOrchestrator()
        mockNetwork = MockNetworkCapability()
        orchestrator.capabilityRegistry.register(mockNetwork)
    }
    
    func testLoginFlow() async throws {
        // Arrange
        mockNetwork.mockResponses["/login"] = .success(Data())
        let context = orchestrator.createContext(UserContext.self, parent: nil)
        
        // Act
        await context.onAppear()
        await context.send(.login("test@example.com"))
        
        // Assert
        XCTAssertEqual(context.username, "test@example.com")
        XCTAssertTrue(context.isLoggedIn)
        XCTAssertEqual(mockNetwork.requestCount, 1)
    }
}
```

### Section 10: Macro Implementation

#### 10.1 Client Macro

```swift
@attached(member)
@attached(extension, conformances: Client)
public macro AxiomClient() = #externalMacro(
    module: "AxiomMacros",
    type: "AxiomClientMacro"
)

// Usage
@AxiomClient
actor OrderClient {
    @Capability var payment: PaymentCapability
    @Capability var inventory: InventoryCapability
    @State var orders: [Order] = []
    
    func processOrder(_ order: Order) async throws {
        try await payment.charge(order.total)
        try await inventory.reserve(order.items)
        orders.append(order)
    }
}

// Macro expansion validates:
// - Only @Capability properties allowed as dependencies
// - Exactly one @State property
// - Generates required protocol conformance
```

#### 10.2 Context Macro

```swift
@attached(member)
@attached(extension, conformances: Context)
public macro AxiomContext() = #externalMacro(
    module: "AxiomMacros",
    type: "AxiomContextMacro"
)

// Usage
@AxiomContext
@MainActor
final class CheckoutContext {
    @Client let orderClient: OrderClient
    @Client let paymentClient: PaymentClient
    @Downstream let userContext: UserContext
    @Downstream let cartContext: CartContext
    
    @Published var isProcessing = false
}

// Macro validates:
// - Only @Client and @Downstream dependencies
// - Generates lifecycle methods
// - Creates observation setup
```

### Section 11: Performance Considerations

#### 11.1 Actor Reentrancy

Clients must handle reentrancy carefully:

```swift
actor DataClient: StatefulClient {
    private var pendingOperations: [UUID: Task<Void, Error>] = [:]
    
    func send(_ action: DataAction) async throws {
        switch action {
        case .fetch(let id):
            // Prevent duplicate fetches
            if let existing = pendingOperations[id] {
                try await existing.value
                return
            }
            
            let task = Task {
                defer { pendingOperations[id] = nil }
                // Perform fetch
            }
            pendingOperations[id] = task
            try await task.value
        }
    }
}
```

#### 11.2 State Update Coalescing

```swift
actor OptimizedClient: StatefulClient {
    private var updateBuffer: [StateUpdate] = []
    private var flushTask: Task<Void, Never>?
    
    private func scheduleFlush() {
        guard flushTask == nil else { return }
        
        flushTask = Task {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            let updates = updateBuffer
            updateBuffer.removeAll()
            flushTask = nil
            
            // Coalesce updates
            let coalesced = coalesce(updates)
            continuation.yield(coalesced)
        }
    }
}
```

### Section 12: Migration Guide

#### 12.1 From MVC to Axiom

```swift
// BEFORE: Traditional MVC
class ProductViewController: UIViewController {
    var products: [Product] = []
    let networkService = NetworkService.shared
    
    func loadProducts() {
        networkService.fetchProducts { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let products):
                    self?.products = products
                    self?.tableView.reloadData()
                case .failure(let error):
                    self?.showError(error)
                }
            }
        }
    }
}

// AFTER: Axiom Architecture
// Step 1: Extract capability
final class NetworkCapability: Capability {
    func fetchProducts() async throws -> [Product] {
        // Network implementation
    }
}

// Step 2: Create client
@AxiomClient
actor ProductClient {
    @Capability var network: NetworkCapability
    @State var products: [Product] = []
    
    func loadProducts() async throws {
        products = try await network.fetchProducts()
    }
}

// Step 3: Create context
@AxiomContext
@MainActor
final class ProductContext {
    @Client let productClient: ProductClient
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func loadProducts() async {
        isLoading = true
        error = nil
        do {
            try await productClient.send(.load)
        } catch {
            self.error = error
        }
        isLoading = false
    }
}

// Step 4: Create view
struct ProductListView: View {
    @ObservedObject var context: ProductContext
    
    var body: some View {
        List(context.products) { product in
            ProductRow(product: product)
        }
        .task {
            await context.loadProducts()
        }
    }
}
```

#### 12.2 Migration Checklist

1. **Identify Capabilities**: Extract external dependencies (network, storage, device features)
2. **Create Clients**: Move business logic into actor-isolated clients
3. **Design State**: Define immutable state types owned by clients  
4. **Build Contexts**: Create @MainActor contexts for UI coordination
5. **Update Views**: Convert to SwiftUI with single context dependency
6. **Setup Orchestrator**: Register capabilities and create root contexts
7. **Add Testing**: Implement mock capabilities and test flows

## Rationale

### Design Decisions

1. **Seven Component Types**: Provides complete coverage of iOS app architecture while maintaining simplicity
2. **Nine Constraints**: Minimum set of rules to ensure architectural integrity
3. **Actor Isolation**: Leverages Swift's concurrency model for thread safety
4. **Context DAG**: Enables complex feature composition while preventing cycles
5. **Single Ownership**: Eliminates shared mutable state issues

### Benefits

1. **Clear Boundaries**: Each component has a single responsibility
2. **Thread Safety**: Actor isolation prevents race conditions
3. **Testability**: Unidirectional dependencies simplify testing
4. **AI Compliance**: Clear rules for code generation
5. **Maintainability**: Consistent patterns throughout codebase

## Non-Goals

This RFC explicitly does NOT define:
- Error handling strategies
- State synchronization mechanisms
- Testing frameworks or patterns
- Dependency injection implementations
- Naming conventions beyond type suffixes
- Performance optimization strategies

## Future Considerations

While the seven component types and nine constraints are permanent, future RFCs may address:
- Implementation patterns within constraints
- Tooling for constraint enforcement
- Performance optimization techniques
- Testing strategies

## Conclusion

The seven component types and nine architectural constraints defined in this RFC form the permanent foundation of the Axiom framework. These are architectural laws that MUST be followed without exception. Implementation details may evolve, but these fundamental constraints are immutable.

The additional patterns provided in Sections 7-12 demonstrate how to implement production-ready applications within these constraints, including state management, dependency injection, testing, and migration strategies.

## Appendix: Quick Reference

### Component Types
1. Capability - External system access
2. Owned State - Domain models
3. Stateful Client - Domain logic with state
4. Stateless Client - Pure computation
5. Orchestrator - Application root
6. Context - Feature coordination
7. Presentation - SwiftUI views

### Architectural Constraints
1. Clients → Capabilities only
2. Contexts → Clients & downstream Contexts
3. Capabilities → Nothing
4. Views → One Context
5. Unidirectional flow
6. No client-to-client dependencies
7. Single state ownership
8. Context DAG (no cycles)
9. Orchestrator creates contexts