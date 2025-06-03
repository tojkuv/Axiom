# RFC-001: Axiom Architectural Constraints

**RFC Number**: 001  
**Title**: Axiom Architectural Constraints  
**Status**: Proposed  
**Type**: Architecture  
**Created**: 2025-01-06  
**Authors**: Axiom Framework Team  
**Revision**: 4.0

## Abstract

This RFC defines the permanent and immutable architectural constraints of the Axiom framework. It establishes exactly seven component types, nine dependency constraints, and six lifetime constraints that form the non-negotiable foundation of all Axiom applications.

## Motivation

iOS development requires clear architectural boundaries to ensure maintainable, testable, and thread-safe applications. Axiom enforces these boundaries through compile-time and runtime constraints that prevent common architectural mistakes.

## Specification

### Section 1: Component Types

The Axiom architecture consists of exactly seven component types. These types are permanent and cannot be extended, modified, or removed.

#### 1.1 Capability
- **Purpose**: External system access
- **Dependencies**: None (leaf nodes)
- **Thread Safety**: Implementation-specific
- **Lifetime**: Transient (recreated as permissions change)
- **Examples**: NetworkCapability, StorageCapability, BiometricsCapability

#### 1.2 Owned State
- **Purpose**: Domain model representation
- **Dependencies**: None
- **Thread Safety**: Value types with immutable snapshots
- **Ownership**: 1:1 relationship with a single Client
- **Lifetime**: Singleton (one instance per state type)

#### 1.3 Stateful Client
- **Purpose**: Domain logic with persistent state
- **Dependencies**: Capabilities only
- **Thread Safety**: Actor isolation
- **State**: Owns exactly one State type
- **Lifetime**: Singleton (one instance per client type)

#### 1.4 Stateless Client
- **Purpose**: Pure computation and transformation
- **Dependencies**: Capabilities only
- **Thread Safety**: Actor isolation
- **State**: None
- **Lifetime**: Singleton (one instance per client type)

#### 1.5 Orchestrator
- **Purpose**: Application lifecycle management
- **Dependencies**: Creates root Contexts
- **Thread Safety**: @MainActor
- **Cardinality**: One per application
- **Lifetime**: Singleton (application lifetime)

#### 1.6 Context
- **Purpose**: Feature coordination
- **Dependencies**: Clients and downstream Contexts
- **Thread Safety**: @MainActor
- **Composition**: Forms directed acyclic graph (DAG)
- **Lifetime**: Multiple instances (one per view usage)

#### 1.7 Presentation
- **Purpose**: User interface
- **Dependencies**: Exactly one Context
- **Thread Safety**: SwiftUI View
- **Logic**: None (presentation only)
- **Lifetime**: Multiple instances (SwiftUI manages lifecycle)

### Section 2: Architectural Constraints

The following constraints are permanent and immutable:

#### Part A: Dependency Constraints (9 rules)

##### 2.1 Client Dependency Constraint
Clients (both Stateful and Stateless) can ONLY depend on Capabilities.

##### 2.2 Context Dependency Constraint
Contexts can ONLY depend on Clients and downstream Contexts.

##### 2.3 Capability Independence Constraint
Capabilities have NO dependencies.

##### 2.4 View-Context Binding Constraint
Each View has exactly ONE Context dependency.

##### 2.5 Unidirectional Flow Constraint
Dependencies flow in one direction: Orchestrator → Context → Client → Capability → System.

##### 2.6 Client Isolation Constraint
Clients cannot depend on other Clients.

##### 2.7 State Ownership Constraint
Each State is owned by exactly ONE Client.

##### 2.8 Context Composition Constraint
Contexts form a directed acyclic graph with no circular dependencies.

##### 2.9 Orchestrator Responsibility Constraint
Contexts can only be created through the Orchestrator's factory methods.

#### Part B: Lifetime Constraints (6 rules)

##### 2.10 View Lifetime Constraint
Views have MULTIPLE instances - new instance per usage in SwiftUI hierarchy.

##### 2.11 Context Lifetime Constraint  
Contexts have MULTIPLE instances - paired 1:1 with view instances.

##### 2.12 Client Lifetime Constraint
Clients are SINGLETONS - one instance per client type for entire application.

##### 2.13 State Lifetime Constraint
States are SINGLETONS - one instance per state type, paired 1:1 with client singleton.

##### 2.14 Capability Lifetime Constraint
Capabilities are TRANSIENT - recreated when permissions or availability changes.

##### 2.15 Orchestrator Lifetime Constraint
Orchestrator is a SINGLETON - one instance for entire application lifetime.

### Section 3: Protocol Definitions

```swift
// Component protocols define the contract for each type

protocol Capability {
    var isAvailable: Bool { get }
    func checkAvailability() async -> Bool
}

// Extended capability with lifecycle management
protocol ManagedCapability: Capability {
    var availabilityPublisher: AsyncStream<Bool> { get }
    func onBecomeAvailable() async
    func onBecomeUnavailable() async
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
    var contextId: String { get }
    func send(_ action: Action) async
    
    // Lifecycle
    func onAppear() async
    func onDisappear() async
    func onBackground() async
    func onForeground() async
    
    // State observation
    func startObservation() async
    func stopObservation()
    
    // Relationship management
    var upstreamContexts: [any Context] { get }
    var downstreamContexts: [any Context] { get }
}

extension Context {
    // Default implementation using orchestrator's registry
    var upstreamContexts: [any Context] {
        orchestrator.contextRegistry.getUpstreamContexts(for: self)
    }
    
    var downstreamContexts: [any Context] {
        orchestrator.contextRegistry.getDownstreamContexts(for: self)
    }
}

// Navigation support
@MainActor
protocol NavigationContext: Context {
    associatedtype Route
    var navigationStack: [any Context] { get set }
    func navigate(to route: Route) async
    func pop() async
    func popToRoot() async
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
4. A context can be downstream of multiple upstream contexts (shared contexts)
5. Only the Orchestrator factory creates contexts
6. Dependencies are immutable after initialization
7. Lifetime constraints enforced by the framework

#### 4.2.1 Component Lifetime Constraints
Axiom enforces specific lifetime patterns for each component type:

**Multiple Instances (Per Usage)**
- **Views**: New instance created for each usage in SwiftUI hierarchy
- **Contexts**: New instance created for each view, paired 1:1

**Singletons (Application Lifetime)**  
- **Clients**: ONE instance per client type for entire application
- **States**: ONE instance per state type, paired 1:1 with client singleton
- **Orchestrator**: ONE instance managing the entire application

**Transient (Permission-Based)**
- **Capabilities**: Recreated when permissions/availability changes

**Example: Singleton State Sharing**
```
CartView (instance 1) → CartContext (instance 1) → CartClient (singleton) → CartState (singleton)
CartView (instance 2) → CartContext (instance 2) → CartClient (singleton) → CartState (singleton)

ProfileView (instance A) → ProfileContext (instance A) → ProfileClient (singleton) → ProfileState (singleton)  
ProfileView (instance B) → ProfileContext (instance B) → ProfileClient (singleton) → ProfileState (singleton)
ProfileView (instance C) → ProfileContext (instance C) → ProfileClient (singleton) → ProfileState (singleton)

All ProfileContext instances observe the SAME ProfileClient and ProfileState.
```

**State Coordination Through Singleton Clients**
Since clients and states are singletons:
- All contexts of the same type observe the same state
- State updates in the client are seen by all observing contexts
- No need for explicit synchronization between contexts
- Thread safety guaranteed by actor isolation on clients

#### 4.2.2 Lifetime Constraints vs SwiftUI

```swift
// SwiftUI: Multiple view instances, each with local @State
VStack {
    ProfileView()  // View instance 1 with its own @State
    ProfileView()  // View instance 2 with its own @State  
}

// Axiom: Multiple view/context instances, but SHARED client/state
VStack {
    ProfileView()  // View instance 1 → Context instance 1 → ProfileClient (singleton)
    ProfileView()  // View instance 2 → Context instance 2 → ProfileClient (singleton)
}

// The key difference:
struct ProfileView: View {
    @ObservedObject var context: ProfileContext  // Context instance (multiple)
    // context.profileClient is a SINGLETON
    // All ProfileView instances see the SAME ProfileState
}

// This enables:
// - Consistent state across all views of the same type
// - Automatic synchronization without explicit coordination
// - Single source of truth per domain (client/state pair)
```

#### 4.2.3 Lifetime Enforcement

The framework enforces these lifetime constraints:

```swift
// Orchestrator ensures client singletons
func createContext<T: Context>(_ type: T.Type, parent: Context?) -> T {
    // 1. Create new context instance (always)
    let context = T.init(orchestrator: self)
    
    // 2. Get or create singleton client
    let client = getOrCreateSingletonClient(for: context)
    context.client = client  // All contexts share this client
    
    return context
}
```

#### 4.3 Example DAG
```
Orchestrator (singleton)
     ├── AppNavigationContext (root)
     │        ├── HomeContext
     │        │        ├── ProfileContext (instance A) → ProfileClient (singleton) → ProfileState (singleton)
     │        │        └── NotificationContext (instance A) → NotificationClient (singleton) → NotificationState (singleton)
     │        └── SettingsContext
     │                 ├── ProfileContext (instance B) → ProfileClient (singleton) → ProfileState (singleton)
     │                 └── NotificationContext (instance B) → NotificationClient (singleton) → NotificationState (singleton)
     └── CheckoutContext (root)
              ├── UserContext → UserClient (singleton) → UserState (singleton)
              │        └── ProfileContext (instance C) → ProfileClient (singleton) → ProfileState (singleton)
              ├── CartContext → CartClient (singleton) → CartState (singleton)
              │        └── PricingContext (instance D) → PricingClient (singleton) → PricingState (singleton)
              └── PaymentContext → PaymentClient (singleton) → PaymentState (singleton)
                       └── PricingContext (instance E) → PricingClient (singleton) → PricingState (singleton)

LIFETIME CONSTRAINTS:
- Views: Multiple instances (new instance per usage)
- Contexts: Multiple instances (paired 1:1 with view instances)
- Clients: SINGLETON per type (one UserClient for entire app)
- States: SINGLETON per type (paired 1:1 with client singleton)
- Capabilities: Transient (recreated to reflect permission changes)
- Orchestrator: SINGLETON (application-wide)
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
            // Atomic state update and notification
            await updateState { currentState in
                UserState(username: username, isLoggedIn: true)
            }
            continuation.yield(.loggedIn(username: username))
        case .logout:
            await updateState { _ in
                UserState(username: "", isLoggedIn: false)
            }
            continuation.yield(.loggedOut)
        }
    }
    
    private func updateState(_ transform: (UserState) -> UserState) async {
        state = transform(state)
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

// Context with state observation - multiple instances observe singleton client
@MainActor
final class UserContext: Context {
    typealias Action = UserAction
    
    let orchestrator: Orchestrator
    let contextId = UUID().uuidString  // Unique per context instance
    private let userClient: UserClient  // Singleton - shared by all UserContext instances
    private var observationTask: Task<Void, Never>?
    
    @Published private(set) var username = ""
    @Published private(set) var isLoggedIn = false
    @Published private(set) var error: Error?
    
    init(orchestrator: Orchestrator, parent: (any Context)?, userClient: UserClient) {
        self.orchestrator = orchestrator
        self.userClient = userClient  // Receives singleton client
        
        // Downstream contexts are managed by the registry
        // Access via the downstreamContexts computed property
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
        // Stop any existing observation
        stopObservation()
        
        // Activate client
        try? await userClient.activate()
        
        // Create cancellable observation task
        observationTask = Task { [weak self] in
            guard let self else { return }
            
            // Load initial state
            let initialState = await userClient.state
            await MainActor.run {
                self.username = initialState.username
                self.isLoggedIn = initialState.isLoggedIn
            }
            
            // Observe state updates
            for await update in userClient.stateUpdates {
                // Check if task is cancelled
                if Task.isCancelled { break }
                
                await MainActor.run { [weak self] in
                    guard let self else { return }
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
    }
    
    func stopObservation() {
        observationTask?.cancel()
        observationTask = nil
        Task { [weak userClient] in
            await userClient?.deactivate()
        }
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

// ❌ VIOLATION: State not owned by a client
class SharedUserState {
    static let shared = SharedUserState()  // NEVER ALLOWED - States must be owned by a client
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

Stateful clients (singletons) provide reactive state updates through AsyncStream:

```swift
// Singleton client - one instance for entire app
actor ProductClient: StatefulClient {
    typealias State = ProductState
    typealias StateUpdate = ProductStateUpdate
    
    // Singleton state - one instance owned by this client
    private(set) var state = ProductState(items: [])
    
    // Stream broadcasts to all observing contexts
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

Multiple context instances observe the singleton client's state updates:

```swift
@MainActor
final class ProductContext: Context {
    @Published private(set) var items: [Product] = []
    @Published private(set) var totalPrice: Decimal = 0
    
    private var observationTask: Task<Void, Never>?
    private let productClient: ProductClient  // Singleton - shared by all ProductContext instances
    
    func startObservation() async {
        // Cancel any existing observation
        observationTask?.cancel()
        
        // Create new observation task
        observationTask = Task { [weak self, productClient] in
            guard let self else { return }
            
            // Initial state
            let state = await productClient.state
            await MainActor.run {
                self.items = state.items
                self.totalPrice = state.totalPrice
            }
            
            // Observe updates with cancellation check
            for await update in productClient.stateUpdates {
                if Task.isCancelled { break }
                
                await MainActor.run { [weak self] in
                    guard let self else { return }
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
    
    func stopObservation() {
        observationTask?.cancel()
        observationTask = nil
    }
    
    private func recalculateTotal() {
        totalPrice = items.reduce(0) { $0 + $1.price }
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
    private var contextRegistry = ContextRegistry()
    private var contextFactories: [ObjectIdentifier: ContextFactory] = [:]
    
    init() {
        // Register capabilities
        setupCapabilities()
        setupContextFactories()
    }
    
    private func setupCapabilities() {
        capabilityRegistry.register(NetworkCapability())
        capabilityRegistry.register(StorageCapability())
        capabilityRegistry.register(BiometricsCapability())
    }
    
    private func setupContextFactories() {
        // Register context factories
        registerContextFactory(UserContext.self) { orchestrator, parent in
            let network = orchestrator.capabilityRegistry.resolve(NetworkCapability.self)
            let userClient = UserClient(network: network)
            return UserContext(
                orchestrator: orchestrator,
                parent: parent,
                userClient: userClient
            )
        }
        
        // Register additional context factories as needed
        // Example:
        // registerContextFactory(ProductContext.self) { orchestrator, parent in
        //     let network = orchestrator.capabilityRegistry.resolve(NetworkCapability.self)
        //     let productClient = ProductClient(network: network)
        //     return ProductContext(
        //         orchestrator: orchestrator,
        //         parent: parent,
        //         productClient: productClient
        //     )
        // }
    }
    
    func registerContextFactory<T: Context>(_ type: T.Type, factory: @escaping ContextFactory) {
        contextFactories[ObjectIdentifier(type)] = factory
    }
    
    func createContext<T: Context>(_ type: T.Type, parent: (any Context)?) -> T {
        // ALWAYS create new instance - no context sharing
        // This enforces state isolation (1:1:1 Context:Client:State)
        
        // Create new context using factory
        guard let factory = contextFactories[ObjectIdentifier(type)] else {
            fatalError("No factory registered for context type \(type)")
        }
        
        let context = factory(self, parent)
        contextRegistry.register(context)
        
        // Add relationship
        if let parent = parent {
            contextRegistry.addRelationship(parent: parent, child: context)
            
            // Check for cycles
            if contextRegistry.contextGraph.detectCycle() {
                contextRegistry.remove(context)
                fatalError("Cycle detected when adding context \(type) as child of \(parent.contextId)")
            }
        } else {
            // Track root contexts
            rootContexts.append(context)
        }
        
        return context as! T
    }
}

// Context registry tracking all unique context instances
@MainActor
final class ContextRegistry {
    private var contexts: [String: any Context] = [:] // contextId -> context
    private var contextGraph = ContextGraph()
    
    func register(_ context: any Context) {
        contexts[context.contextId] = context
    }
    
    func getContext(byId contextId: String) -> (any Context)? {
        contexts[contextId]
    }
    
    func remove(_ context: any Context) {
        contexts[context.contextId] = nil
        contextGraph.removeContext(context.contextId)
    }
    
    func addRelationship(parent: any Context, child: any Context) {
        contextGraph.addEdge(from: parent.contextId, to: child.contextId)
    }
    
    func getUpstreamContexts(for context: any Context) -> [any Context] {
        let parentIds = contextGraph.getParents(of: context.contextId)
        return parentIds.compactMap { contexts[$0] }
    }
    
    func getDownstreamContexts(for context: any Context) -> [any Context] {
        let childIds = contextGraph.getChildren(of: context.contextId)
        return childIds.compactMap { contexts[$0] }
    }
}

// DAG structure to track context relationships
@MainActor
final class ContextGraph {
    private var adjacencyList: [String: Set<String>] = [:] // parent -> children
    private var reverseList: [String: Set<String>] = [:] // child -> parents
    
    func addEdge(from parent: String, to child: String) {
        adjacencyList[parent, default: []].insert(child)
        reverseList[child, default: []].insert(parent)
    }
    
    func removeContext(_ contextId: String) {
        // Remove as parent
        if let children = adjacencyList[contextId] {
            for child in children {
                reverseList[child]?.remove(contextId)
            }
        }
        adjacencyList[contextId] = nil
        
        // Remove as child
        if let parents = reverseList[contextId] {
            for parent in parents {
                adjacencyList[parent]?.remove(contextId)
            }
        }
        reverseList[contextId] = nil
    }
    
    func getParents(of contextId: String) -> [String] {
        Array(reverseList[contextId] ?? [])
    }
    
    func getChildren(of contextId: String) -> [String] {
        Array(adjacencyList[contextId] ?? [])
    }
    
    func detectCycle() -> Bool {
        var visited = Set<String>()
        var recursionStack = Set<String>()
        
        for contextId in adjacencyList.keys {
            if hasCycle(contextId, visited: &visited, recursionStack: &recursionStack) {
                return true
            }
        }
        return false
    }
    
    private func hasCycle(_ contextId: String, visited: inout Set<String>, recursionStack: inout Set<String>) -> Bool {
        visited.insert(contextId)
        recursionStack.insert(contextId)
        
        if let children = adjacencyList[contextId] {
            for child in children {
                if !visited.contains(child) {
                    if hasCycle(child, visited: &visited, recursionStack: &recursionStack) {
                        return true
                    }
                } else if recursionStack.contains(child) {
                    return true // Cycle detected
                }
            }
        }
        
        recursionStack.remove(contextId)
        return false
    }
}

typealias ContextFactory = (Orchestrator, (any Context)?) -> any Context
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

#### 12.3 Context Isolation Example

```swift
// Example: PricingContext with separate instances
@MainActor
final class PricingContext: Context {
    typealias Action = PricingAction
    
    let orchestrator: Orchestrator
    let contextId = UUID().uuidString
    private let pricingClient: PricingClient  // Each context has its own client
    
    @Published private(set) var taxRate: Decimal = 0
    @Published private(set) var shippingCost: Decimal = 0
    @Published private(set) var discount: Decimal = 0
    
    init(orchestrator: Orchestrator, parent: (any Context)?, pricingClient: PricingClient) {
        self.orchestrator = orchestrator
        self.pricingClient = pricingClient
    }
    
    func calculateTotal(subtotal: Decimal) -> Decimal {
        let tax = subtotal * taxRate
        return subtotal + tax + shippingCost - discount
    }
    
    // Other Context methods...
}

// Usage: Each context gets its own instance
@MainActor
final class CartContext: Context {
    private lazy var pricingContext: PricingContext = {
        // Creates NEW instance with its own PricingClient and PricingState
        orchestrator.createContext(PricingContext.self, parent: self)
    }()
    
    func calculateCartTotal() async -> Decimal {
        let subtotal = items.reduce(0) { $0 + $1.price }
        return pricingContext.calculateTotal(subtotal: subtotal)
    }
}

@MainActor  
final class CheckoutContext: Context {
    private lazy var pricingContext: PricingContext = {
        // Creates DIFFERENT instance with its own PricingClient and PricingState
        orchestrator.createContext(PricingContext.self, parent: self)
    }()
    
    func calculateOrderTotal() async -> Decimal {
        let subtotal = orderItems.reduce(0) { $0 + $1.price }
        return pricingContext.calculateTotal(subtotal: subtotal)
    }
}

// IMPORTANT: State Isolation
// - CartContext.pricingContext has its own PricingClient and PricingState
// - CheckoutContext.pricingContext has a DIFFERENT PricingClient and PricingState
// - They do NOT share state

// Coordinating Without Shared State:
// If cart and checkout need synchronized pricing:
@MainActor
final class OrderFlowContext: Context {  // Parent context
    private let cartContext: CartContext
    private let checkoutContext: CheckoutContext
    
    func synchronizePricing() async {
        // Coordinate through actions, not shared state
        await cartContext.send(.updatePricing(rates: currentRates))
        await checkoutContext.send(.updatePricing(rates: currentRates))
    }
}
```

### Section 13: Navigation Patterns

#### 13.1 Navigation Context Implementation

```swift
@MainActor
final class AppNavigationContext: NavigationContext {
    typealias Action = NavigationAction
    typealias Route = AppRoute
    
    let orchestrator: Orchestrator
    let contextId = UUID().uuidString
    
    @Published var navigationStack: [any Context] = []
    @Published var currentRoute: AppRoute?
    
    init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
    }
    
    func send(_ action: NavigationAction) async {
        switch action {
        case .navigate(let route):
            await navigate(to: route)
        case .pop:
            await pop()
        case .popToRoot:
            await popToRoot()
        }
    }
    
    func navigate(to route: AppRoute) async {
        // Stop observation on current context
        if let current = navigationStack.last {
            await current.onDisappear()
        }
        
        // Create and push new context
        let context = route.createContext(orchestrator: orchestrator, parent: self)
        navigationStack.append(context)
        currentRoute = route
        
        // Start observation on new context
        await context.onAppear()
    }
    
    func pop() async {
        guard navigationStack.count > 1 else { return }
        
        // Stop observation on current context
        if let current = navigationStack.last {
            await current.onDisappear()
        }
        
        navigationStack.removeLast()
        
        // Resume observation on previous context
        if let previous = navigationStack.last {
            await previous.onForeground()
        }
    }
    
    func popToRoot() async {
        guard !navigationStack.isEmpty else { return }
        
        // Stop observation on all contexts except root
        for context in navigationStack.dropFirst() {
            await context.onDisappear()
        }
        
        // Keep only root context
        if let root = navigationStack.first {
            navigationStack = [root]
            await root.onForeground()
        }
    }
    
    // Standard Context lifecycle
    func startObservation() async {
        // Navigation context doesn't observe clients
    }
    
    func stopObservation() {
        // Navigation context doesn't observe clients
    }
    
    func onAppear() async {
        if let current = navigationStack.last {
            await current.onAppear()
        }
    }
    
    func onDisappear() async {
        for context in navigationStack {
            await context.onDisappear()
        }
    }
    
    func onBackground() async {
        if let current = navigationStack.last {
            await current.onBackground()
        }
    }
    
    func onForeground() async {
        if let current = navigationStack.last {
            await current.onForeground()
        }
    }
}

// Route definition
enum AppRoute {
    case login
    case home
    case product(id: String)
    case checkout
    
    func createContext(orchestrator: Orchestrator, parent: (any Context)?) -> any Context {
        switch self {
        case .login:
            return orchestrator.createContext(LoginContext.self, parent: parent)
        case .home:
            return orchestrator.createContext(HomeContext.self, parent: parent)
        case .product(let id):
            let context = orchestrator.createContext(ProductContext.self, parent: parent)
            Task { await context.send(.loadProduct(id)) }
            return context
        case .checkout:
            return orchestrator.createContext(CheckoutContext.self, parent: parent)
        }
    }
}

enum NavigationAction {
    case navigate(AppRoute)
    case pop
    case popToRoot
}
```

#### 13.2 Navigation View Integration

```swift
struct AppNavigationView: View {
    @ObservedObject var navigationContext: AppNavigationContext
    
    var body: some View {
        NavigationStack(path: $navigationContext.navigationStack) {
            // Root view
            if let rootContext = navigationContext.navigationStack.first {
                contextView(for: rootContext)
            } else {
                LoginView(context: orchestrator.createContext(LoginContext.self, parent: navigationContext))
            }
        }
    }
    
    @ViewBuilder
    func contextView(for context: any Context) -> some View {
        switch context {
        case let loginContext as LoginContext:
            LoginView(context: loginContext)
        case let homeContext as HomeContext:
            HomeView(context: homeContext)
        case let productContext as ProductContext:
            ProductView(context: productContext)
        case let checkoutContext as CheckoutContext:
            CheckoutView(context: checkoutContext)
        default:
            EmptyView()
        }
    }
}
```

### Section 14: Error Handling Standards

#### 14.1 Core Error Types

```swift
public enum AxiomError: Error, LocalizedError {
    // Capability errors
    case capabilityUnavailable(String)
    case capabilityTimeout(String)
    
    // State errors
    case stateInconsistency(String)
    case stateUpdateFailed(String)
    
    // Context errors
    case contextNotFound(String)
    case contextInitializationFailed(String)
    
    // Client errors
    case clientActionFailed(action: String, underlying: Error)
    case clientNotActivated(String)
    
    public var errorDescription: String? {
        switch self {
        case .capabilityUnavailable(let name):
            return "\(name) capability is not available"
        case .capabilityTimeout(let name):
            return "\(name) capability timed out"
        case .stateInconsistency(let details):
            return "State inconsistency: \(details)"
        case .stateUpdateFailed(let details):
            return "State update failed: \(details)"
        case .contextNotFound(let id):
            return "Context not found: \(id)"
        case .contextInitializationFailed(let details):
            return "Context initialization failed: \(details)"
        case .clientActionFailed(let action, let underlying):
            return "Client action '\(action)' failed: \(underlying.localizedDescription)"
        case .clientNotActivated(let name):
            return "Client \(name) not activated"
        }
    }
}

// Error handler protocol
@MainActor
protocol ErrorHandlingContext: Context {
    var errorHandler: ErrorHandler { get }
}

@MainActor
final class ErrorHandler: ObservableObject {
    @Published var currentError: AxiomError?
    @Published var errorHistory: [ErrorRecord] = []
    
    struct ErrorRecord {
        let error: AxiomError
        let timestamp: Date
        let context: String
        let recovered: Bool
    }
    
    func handle(_ error: AxiomError, in context: String) {
        currentError = error
        errorHistory.append(ErrorRecord(
            error: error,
            timestamp: Date(),
            context: context,
            recovered: false
        ))
    }
    
    func recover() {
        if let current = currentError,
           let index = errorHistory.lastIndex(where: { $0.error.localizedDescription == current.localizedDescription }) {
            errorHistory[index] = ErrorRecord(
                error: current,
                timestamp: errorHistory[index].timestamp,
                context: errorHistory[index].context,
                recovered: true
            )
        }
        currentError = nil
    }
}
```

#### 14.2 Error Recovery Patterns

```swift
// Capability with error recovery
final class NetworkCapability: ManagedCapability {
    private(set) var isAvailable = true
    private let (availabilityStream, availabilityContinuation) = AsyncStream.makeStream(of: Bool.self)
    var availabilityPublisher: AsyncStream<Bool> { availabilityStream }
    
    func request(_ endpoint: String) async throws -> Data {
        guard isAvailable else {
            throw AxiomError.capabilityUnavailable("Network")
        }
        
        do {
            return try await performRequest(endpoint)
        } catch {
            // Update availability on network errors
            if isNetworkError(error) {
                await updateAvailability(false)
            }
            throw AxiomError.clientActionFailed(action: "network request", underlying: error)
        }
    }
    
    func checkAvailability() async -> Bool {
        let reachable = await checkReachability()
        await updateAvailability(reachable)
        return reachable
    }
    
    private func updateAvailability(_ available: Bool) async {
        let changed = isAvailable != available
        isAvailable = available
        
        if changed {
            availabilityContinuation.yield(available)
            if available {
                await onBecomeAvailable()
            } else {
                await onBecomeUnavailable()
            }
        }
    }
    
    func onBecomeAvailable() async {
        // Retry pending requests
    }
    
    func onBecomeUnavailable() async {
        // Cancel active requests
    }
}

// Context with error handling
@MainActor
final class ResilientContext: Context, ErrorHandlingContext {
    let errorHandler = ErrorHandler()
    
    func send(_ action: Action) async {
        do {
            try await client.send(action)
        } catch let error as AxiomError {
            errorHandler.handle(error, in: contextId)
            await attemptRecovery(from: error)
        } catch {
            errorHandler.handle(.clientActionFailed(action: "\(action)", underlying: error), in: contextId)
        }
    }
    
    private func attemptRecovery(from error: AxiomError) async {
        switch error {
        case .capabilityUnavailable:
            // Wait for capability to become available
            await waitForCapabilityRecovery()
        case .stateInconsistency:
            // Reload state from source of truth
            await reloadState()
        default:
            // No automatic recovery
            break
        }
    }
}
```

### Section 15: App Lifecycle Management

#### 15.1 Lifecycle Coordinator

```swift
@MainActor
final class AppLifecycleCoordinator: ObservableObject {
    @Published var phase: ScenePhase = .active
    @Published var isFirstLaunch = true
    
    private let orchestrator: Orchestrator
    private var lifecycleTasks: [Task<Void, Never>] = []
    
    init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
    }
    
    func handlePhaseChange(_ newPhase: ScenePhase) async {
        let oldPhase = phase
        phase = newPhase
        
        // Cancel previous lifecycle tasks
        lifecycleTasks.forEach { $0.cancel() }
        lifecycleTasks.removeAll()
        
        switch (oldPhase, newPhase) {
        case (_, .active):
            await handleBecomeActive()
        case (.active, .inactive):
            await handleBecomeInactive()
        case (.inactive, .background):
            await handleEnterBackground()
        case (.background, .inactive):
            await handleEnterForeground()
        default:
            break
        }
    }
    
    private func handleBecomeActive() async {
        if isFirstLaunch {
            isFirstLaunch = false
            await performFirstLaunch()
        } else {
            await resumeFromBackground()
        }
    }
    
    private func handleBecomeInactive() async {
        // Pause active operations
        for context in orchestrator.rootContexts {
            let task = Task {
                await context.onBackground()
            }
            lifecycleTasks.append(task)
        }
        await withTaskGroup(of: Void.self) { group in
            for task in lifecycleTasks {
                group.addTask { await task.value }
            }
        }
    }
    
    private func handleEnterBackground() async {
        // Save state and cleanup
        await saveApplicationState()
        await cleanupResources()
    }
    
    private func handleEnterForeground() async {
        // Restore state and refresh
        await restoreApplicationState()
        for context in orchestrator.rootContexts {
            await context.onForeground()
        }
    }
    
    private func performFirstLaunch() async {
        // Initialize root contexts
        let navigationContext = orchestrator.createContext(AppNavigationContext.self, parent: nil)
        await navigationContext.navigate(to: .login)
    }
    
    private func saveApplicationState() async {
        // Persist current navigation state
        // Save user preferences
        // Cache important data
    }
    
    private func restoreApplicationState() async {
        // Reload navigation state
        // Refresh capabilities
        await orchestrator.capabilityRegistry.refreshAll()
    }
    
    private func cleanupResources() async {
        // Release unused resources
        // Cancel background tasks
    }
    
    private func resumeFromBackground() async {
        // Check for updates
        // Refresh authentication
        // Sync data
    }
}
```

#### 15.2 App Entry Point

```swift
@main
struct AxiomApp: App {
    @StateObject private var orchestrator = AppOrchestrator()
    @StateObject private var lifecycleCoordinator: AppLifecycleCoordinator
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        let orchestrator = AppOrchestrator()
        _orchestrator = StateObject(wrappedValue: orchestrator)
        _lifecycleCoordinator = StateObject(wrappedValue: AppLifecycleCoordinator(orchestrator: orchestrator))
    }
    
    var body: some Scene {
        WindowGroup {
            if let navigationContext = orchestrator.rootContexts.first as? AppNavigationContext {
                AppNavigationView(navigationContext: navigationContext)
            } else {
                ProgressView("Initializing...")
                    .task {
                        await lifecycleCoordinator.handlePhaseChange(.active)
                    }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            Task {
                await lifecycleCoordinator.handlePhaseChange(newPhase)
            }
        }
    }
}
```

#### 15.3 Deep Linking Support

```swift
extension AppNavigationContext {
    func handleDeepLink(_ url: URL) async {
        guard let route = AppRoute.from(url: url) else { return }
        
        // Navigate to deep link destination
        await popToRoot()
        await navigate(to: route)
    }
}

extension AppRoute {
    static func from(url: URL) -> AppRoute? {
        guard url.scheme == "axiomapp" else { return nil }
        
        switch url.host {
        case "product":
            if let id = url.pathComponents.dropFirst().first {
                return .product(id: id)
            }
        case "checkout":
            return .checkout
        case "home":
            return .home
        default:
            return nil
        }
        return nil
    }
}
```

### Section 16: Performance Monitoring

#### 16.1 Client Metrics

```swift
#if DEBUG
protocol InstrumentedClient: Client {
    var metrics: ClientMetrics { get }
}

actor ClientMetrics {
    private(set) var actionCount: Int = 0
    private(set) var totalDuration: TimeInterval = 0
    private(set) var errorCount: Int = 0
    private var actionDurations: [String: [TimeInterval]] = [:]
    
    var averageResponseTime: TimeInterval {
        actionCount > 0 ? totalDuration / Double(actionCount) : 0
    }
    
    var errorRate: Double {
        actionCount > 0 ? Double(errorCount) / Double(actionCount) : 0
    }
    
    func recordAction(_ action: String, duration: TimeInterval, error: Error?) {
        actionCount += 1
        totalDuration += duration
        if error != nil {
            errorCount += 1
        }
        
        if actionDurations[action] == nil {
            actionDurations[action] = []
        }
        actionDurations[action]?.append(duration)
    }
    
    func averageDuration(for action: String) -> TimeInterval? {
        guard let durations = actionDurations[action], !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }
}

// Instrumented client wrapper
actor InstrumentedClientWrapper<C: Client>: Client, InstrumentedClient {
    typealias Action = C.Action
    
    private let wrapped: C
    let metrics = ClientMetrics()
    
    init(wrapping client: C) {
        self.wrapped = client
    }
    
    func send(_ action: Action) async throws {
        let start = Date()
        var error: Error?
        
        do {
            try await wrapped.send(action)
        } catch let e {
            error = e
            throw e
        }
        
        let duration = Date().timeIntervalSince(start)
        await metrics.recordAction("\(action)", duration: duration, error: error)
    }
    
    func activate() async throws {
        try await wrapped.activate()
    }
    
    func deactivate() async {
        await wrapped.deactivate()
    }
}
#endif

### Section 20: Lifetime Implications

#### 20.1 State Synchronization Through Singletons

The singleton pattern for clients and states provides automatic synchronization:

```swift
// Multiple views showing user info
struct HeaderView: View {
    @ObservedObject var context: UserContext  // Instance A
}

struct ProfileView: View {
    @ObservedObject var context: UserContext  // Instance B  
}

struct SettingsView: View {
    @ObservedObject var context: UserContext  // Instance C
}

// All three context instances observe the SAME UserClient singleton
// When any view triggers an action:
await headerContext.send(.logout)  

// All views automatically see the update because:
// 1. Action goes to singleton UserClient
// 2. UserClient updates singleton UserState  
// 3. All UserContext instances observe the change
// 4. All views update automatically
```

#### 20.2 Capability Transience

Capabilities are recreated to reflect system changes:

```swift
final class BiometricsCapability: Capability {
    private(set) var isAvailable: Bool
    
    init() {
        // Check current biometric availability
        isAvailable = checkBiometricHardware()
    }
    
    func checkAvailability() async -> Bool {
        // Re-check when permissions might have changed
        isAvailable = checkBiometricHardware() && checkBiometricPermission()
        return isAvailable
    }
}

// Orchestrator recreates capability when:
// - App returns from background
// - Settings change notification received
// - Permission change detected
```

#### 20.3 Memory Management

The lifetime constraints simplify memory management:

```swift
// Views and Contexts: Released when UI is dismissed
// - SwiftUI manages view lifecycle
// - Contexts released with their views

// Clients and States: Live for application lifetime
// - No retain cycles between singleton clients
// - State owned by client (strong reference)

// Capabilities: Released and recreated as needed
// - No long-term memory footprint
// - Fresh instances reflect current permissions
```

## Rationale

### Design Decisions

1. **Seven Component Types**: Provides complete coverage of iOS app architecture while maintaining simplicity
2. **Nine Dependency Constraints**: Minimum set of rules to ensure architectural integrity
3. **Six Lifetime Constraints**: Defines component lifecycles for predictable behavior
4. **Actor Isolation**: Leverages Swift's concurrency model for thread safety
5. **Context DAG**: Enables complex feature composition while preventing cycles
6. **Singleton Clients**: Provides automatic state synchronization across views
7. **Transient Capabilities**: Ensures permissions are always current

### Benefits

1. **Clear Boundaries**: Each component has a single responsibility
2. **Thread Safety**: Actor isolation prevents race conditions
3. **Testability**: Unidirectional dependencies simplify testing
4. **AI Compliance**: Clear rules for code generation
5. **Maintainability**: Consistent patterns throughout codebase
6. **Consistent State**: Singleton clients provide single source of truth
7. **Automatic Synchronization**: All contexts observe same client state

## Non-Goals

This RFC explicitly does NOT define:
- Specific business logic patterns
- Database schema or persistence formats
- Network protocol specifications
- UI styling or animation guidelines
- Localization strategies
- Analytics implementation details

## Future Considerations

While the seven component types and nine constraints are permanent, future RFCs may address:
- Implementation patterns within constraints
- Tooling for constraint enforcement
- Performance optimization techniques
- Testing strategies

### Section 17: Data Persistence Patterns

#### 17.1 Storage Capability

```swift
final class StorageCapability: Capability {
    private(set) var isAvailable = true
    private let container: URL
    
    init() {
        // Transient - new instance when permissions change
        container = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func checkAvailability() async -> Bool {
        isAvailable = FileManager.default.isWritableFile(atPath: container.path)
        return isAvailable
    }
    
    func save<T: Codable>(_ object: T, key: String) async throws {
        guard isAvailable else {
            throw AxiomError.capabilityUnavailable("Storage")
        }
        
        let url = container.appendingPathComponent("\(key).json")
        let data = try JSONEncoder().encode(object)
        try data.write(to: url)
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T {
        guard isAvailable else {
            throw AxiomError.capabilityUnavailable("Storage")
        }
        
        let url = container.appendingPathComponent("\(key).json")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }
    
    func delete(key: String) async throws {
        let url = container.appendingPathComponent("\(key).json")
        try FileManager.default.removeItem(at: url)
    }
}

// Persistent state client
actor PersistentClient: StatefulClient {
    private let storage: StorageCapability
    private let persistenceKey: String
    
    func send(_ action: Action) async throws {
        // Process action and update state
        try await processAction(action)
        
        // Persist state after each change
        try await storage.save(state, key: persistenceKey)
        
        // Notify observers
        continuation.yield(.stateUpdated)
    }
    
    func activate() async throws {
        // Load persisted state on activation
        if let persisted = try? await storage.load(State.self, key: persistenceKey) {
            state = persisted
            continuation.yield(.stateRestored)
        }
    }
}
```

#### 17.2 Cache Management

```swift
final class CacheCapability: Capability {
    private var cache = NSCache<NSString, CacheEntry>()
    private(set) var isAvailable = true
    
    class CacheEntry {
        let data: Data
        let expiration: Date
        
        var isExpired: Bool {
            Date() > expiration
        }
        
        init(data: Data, ttl: TimeInterval) {
            self.data = data
            self.expiration = Date().addingTimeInterval(ttl)
        }
    }
    
    func set(_ data: Data, for key: String, ttl: TimeInterval = 300) {
        let entry = CacheEntry(data: data, ttl: ttl)
        cache.setObject(entry, forKey: key as NSString)
    }
    
    func get(_ key: String) -> Data? {
        guard let entry = cache.object(forKey: key as NSString) else { return nil }
        
        if entry.isExpired {
            cache.removeObject(forKey: key as NSString)
            return nil
        }
        
        return entry.data
    }
    
    func clear() {
        cache.removeAllObjects()
    }
    
    func checkAvailability() async -> Bool {
        true // Memory cache is always available
    }
}
```

### Section 18: Background Task Management

#### 18.1 Background Task Capability

```swift
final class BackgroundTaskCapability: Capability {
    private(set) var isAvailable = true
    private var activeTasks: [String: Task<Void, Error>] = [:]
    
    func checkAvailability() async -> Bool {
        // Check if background modes are enabled
        isAvailable = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") != nil
        return isAvailable
    }
    
    func scheduleTask(_ identifier: String, operation: @escaping () async throws -> Void) async throws {
        guard isAvailable else {
            throw AxiomError.capabilityUnavailable("BackgroundTask")
        }
        
        // Cancel existing task if any
        activeTasks[identifier]?.cancel()
        
        // Create new background task
        let task = Task.detached(priority: .background) {
            try await operation()
        }
        
        activeTasks[identifier] = task
    }
    
    func cancelTask(_ identifier: String) {
        activeTasks[identifier]?.cancel()
        activeTasks[identifier] = nil
    }
    
    func cancelAllTasks() {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
    }
}

// Client with background sync
actor SyncClient: StatefulClient {
    private let network: NetworkCapability
    private let storage: StorageCapability
    private let backgroundTask: BackgroundTaskCapability
    
    func startBackgroundSync() async throws {
        try await backgroundTask.scheduleTask("sync") { [weak self] in
            guard let self else { return }
            
            while !Task.isCancelled {
                try await self.performSync()
                try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            }
        }
    }
    
    private func performSync() async throws {
        // Load local changes
        let changes = await loadPendingChanges()
        
        // Sync with server
        for change in changes {
            try await network.request("/sync", body: change)
            await markSynced(change)
        }
        
        // Update state
        continuation.yield(.syncCompleted(count: changes.count))
    }
}
```

### Section 19: Shared UI State Management

#### 19.1 Theme and Preferences

```swift
// Shared UI state capability
final class UIStateCapability: Capability {
    private(set) var isAvailable = true
    
    @Published var theme: Theme = .system
    @Published var preferredLanguage: String = "en"
    @Published var accessibility: AccessibilitySettings = .default
    
    enum Theme: String, Codable {
        case light, dark, system
    }
    
    struct AccessibilitySettings: Codable {
        var fontSize: CGFloat = 17
        var reduceMotion: Bool = false
        var increaseContrast: Bool = false
        
        static let `default` = AccessibilitySettings()
    }
    
    func checkAvailability() async -> Bool {
        true // UI state is always available
    }
    
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        // Apply to UIKit if needed
        Task { @MainActor in
            switch theme {
            case .light:
                UIApplication.shared.windows.forEach { 
                    $0.overrideUserInterfaceStyle = .light 
                }
            case .dark:
                UIApplication.shared.windows.forEach { 
                    $0.overrideUserInterfaceStyle = .dark 
                }
            case .system:
                UIApplication.shared.windows.forEach { 
                    $0.overrideUserInterfaceStyle = .unspecified 
                }
            }
        }
    }
}

// Context that provides UI state
@MainActor
final class AppearanceContext: Context {
    let uiState: UIStateCapability
    
    init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
        self.uiState = orchestrator.capabilityRegistry.resolve(UIStateCapability.self)
        self.contextId = UUID().uuidString
        self.downstreamContexts = []
    }
    
    func send(_ action: AppearanceAction) async {
        switch action {
        case .setTheme(let theme):
            uiState.applyTheme(theme)
        case .setLanguage(let language):
            uiState.preferredLanguage = language
        case .updateAccessibility(let settings):
            uiState.accessibility = settings
        }
    }
}
```

## Conclusion

The seven component types, nine dependency constraints, and six lifetime constraints defined in this RFC form the permanent foundation of the Axiom framework. These are architectural laws that MUST be followed without exception.

Version 4.0 adds critical production patterns:
- **Complete Orchestrator Implementation** (Section 8.2) - Factory-based context creation with proper DAG support
- **Component Lifetime Constraints** (Section 4.2.1 & 12.3) - Singleton clients with multiple context instances
- **Navigation Patterns** (Section 13) - Stack-based navigation with proper lifecycle management  
- **Error Handling Standards** (Section 14) - Comprehensive error types and recovery patterns
- **App Lifecycle Management** (Section 15) - Scene phase handling and state preservation
- **Performance Monitoring** (Section 16) - Instrumented clients for metrics collection
- **Data Persistence** (Section 17) - Storage and cache capabilities
- **Background Tasks** (Section 18) - Long-running operation management
- **Shared UI State** (Section 19) - Theme and preference management

The DAG-based context composition with singleton clients provides a single source of truth per domain while maintaining the simplicity of unidirectional data flow. Multiple context instances observe the same client state, ensuring automatic synchronization without explicit coordination.

These patterns demonstrate how to build production-ready iOS applications within the Axiom constraints, providing solutions for navigation, error handling, persistence, and performance monitoring while maintaining architectural integrity.

## Appendix: Quick Reference

### Component Types & Lifetimes
1. Capability - External system access (Transient)
2. Owned State - Domain models (Singleton per type)
3. Stateful Client - Domain logic with state (Singleton per type)
4. Stateless Client - Pure computation (Singleton per type)
5. Orchestrator - Application root (Singleton)
6. Context - Feature coordination (Multiple instances)
7. Presentation - SwiftUI views (Multiple instances)

### Architectural Constraints
**Dependency Constraints:**
1. Clients → Capabilities only
2. Contexts → Clients & downstream Contexts
3. Capabilities → Nothing
4. Views → One Context
5. Unidirectional flow
6. No client-to-client dependencies
7. Single state ownership
8. Context DAG (no cycles)
9. Orchestrator creates contexts

**Lifetime Constraints:**
10. Views - Multiple instances
11. Contexts - Multiple instances  
12. Clients - Singleton per type
13. States - Singleton per type
14. Capabilities - Transient
15. Orchestrator - Singleton

### Implementation Patterns
- Navigation (Section 13)
- Error Handling (Section 14)
- App Lifecycle (Section 15)
- Performance Monitoring (Section 16)