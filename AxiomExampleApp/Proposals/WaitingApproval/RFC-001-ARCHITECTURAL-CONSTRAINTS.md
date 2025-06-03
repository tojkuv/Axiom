# RFC-001: Axiom Architectural Constraints

## Executive Summary

Axiom enforces **non-negotiable architectural constraints** for iOS development through exactly seven core component types: Capability, Owned State, Stateful Client, Stateless Client, Orchestrator, Context, and Presentation. These components and their relationships are defined by nine immutable constraints.

**Core Truth**: The seven component types and nine architectural constraints are permanent and non-negotiable. Only implementation details may evolve.

## Non-Negotiable Architectural Components

These seven component types are **permanent and immutable**:

### 1. **Capability** - External System Access
- Leaf nodes with NO dependencies
- Direct system/device API access only
- Examples: Network, Storage, Biometrics

### 2. **Owned State** - Domain Models  
- Value types owned 1:1 by a single Client
- Immutable snapshots for thread safety
- No shared state between Clients

### 3. **Stateful Client** - Domain Logic with State
- Actor isolation for thread safety
- Owns exactly one State type
- Depends ONLY on Capabilities

### 4. **Stateless Client** - Pure Computation
- Actor isolation without persistent state
- Computation and transformation logic
- Depends ONLY on Capabilities

### 5. **Orchestrator** - Application Root
- @MainActor bound application-level coordinator
- Creates and owns root Contexts
- Manages application lifecycle

### 6. **Context** - Feature Coordination
- @MainActor bound for UI safety
- Coordinates multiple Clients for a feature
- CANNOT access Capabilities directly
- Composable: declares downstream Context dependencies
- Dependencies flow from upstream → downstream

### 7. **Presentation** - SwiftUI Views
- Exactly ONE Context dependency
- Reactive binding to Context state
- No business logic

## Non-Negotiable Architectural Constraints

These nine constraints are **permanent and immutable**:

1. **Clients → Capabilities Only**: Clients can ONLY depend on Capabilities
2. **Contexts → Clients & Contexts**: Contexts depend on Clients and downstream Contexts  
3. **Capabilities → Nothing**: Capabilities have NO dependencies
4. **Views → One Context**: Each View has exactly ONE Context
5. **Unidirectional Flow**: Orchestrator → Context DAG → View → Context → Client → Capability → System
6. **Client Isolation**: NO client-to-client dependencies ever
7. **State Ownership**: Each State is owned by exactly ONE Client
8. **Context Composition**: Contexts form a directed acyclic graph (no circular dependencies)
9. **Orchestrator Root**: Orchestrator creates root Contexts only

## Minimal Implementation

### Core Protocols (Simplified)

```swift
// 1. Capability - Leaf node with no dependencies
protocol Capability {
    var isAvailable: Bool { get }
}

// 2. Client - Actor with capability dependencies only
protocol Client: Actor {
    associatedtype Action
    func send(_ action: Action) async throws
}

// 3. Stateful Client - Client with owned state
protocol StatefulClient: Client {
    associatedtype State
    var state: State { get async }
}

// 4. Stateless Client - Client without persistent state
protocol StatelessClient: Client {
    // No state property
}

// 5. Context - MainActor feature coordinator
@MainActor
protocol Context: ObservableObject {
    associatedtype Action
    var downstreamContexts: [any Context] { get }
    func send(_ action: Action) async
}

// 6. Orchestrator - Application root
@MainActor
protocol Orchestrator: ObservableObject {
    var rootContexts: [any Context] { get }
}
```

### Example Implementation

```swift
// ✅ VALID: Follows all constraints

// 1. State (owned by Client)
struct UserState {
    let username: String
    let isLoggedIn: Bool
}

// 2. Capability (no dependencies)
final class NetworkCapability: Capability {
    let isAvailable = true
    
    func request(_ endpoint: String) async throws -> Data {
        // Direct URLSession usage
    }
}

// 3. Stateful Client (owns state)
actor UserClient: StatefulClient {
    typealias Action = UserAction
    typealias State = UserState
    
    // ✅ VALID: Capability dependencies only
    private let network: NetworkCapability
    
    // ❌ INVALID: Client dependencies
    // private let otherClient: SomeClient // CONSTRAINT VIOLATION
    
    private(set) var state = UserState(username: "", isLoggedIn: false)
    
    func send(_ action: UserAction) async throws {
        switch action {
        case .login(let username):
            let data = try await network.request("/login")
            state = UserState(username: username, isLoggedIn: true)
        }
    }
}

// 4. Stateless Client (no persistent state)
actor ImageProcessor: StatelessClient {
    typealias Action = ProcessAction
    
    private let storage: StorageCapability
    
    func send(_ action: ProcessAction) async throws {
        switch action {
        case .resize(let image, let size):
            let resized = resize(image, to: size)
            try await storage.save(resized)
            // No state retained
        }
    }
}

// 5. Context with composition
@MainActor
final class UserContext: Context {
    typealias Action = UserAction
    
    let downstreamContexts: [any Context]
    private let userClient: UserClient
    
    @Published private(set) var username = ""
    @Published private(set) var isLoggedIn = false
    
    // Upstream context manages its downstream dependencies
    init(orderContext: OrderContext, profileContext: ProfileContext, userClient: UserClient) {
        self.downstreamContexts = [orderContext, profileContext]
        self.userClient = userClient
    }
    
    func send(_ action: UserAction) async {
        try? await userClient.send(action)
        let state = await userClient.state
        username = state.username
        isLoggedIn = state.isLoggedIn
    }
}

// Downstream context example
@MainActor 
final class OrderContext: Context {
    typealias Action = OrderAction
    
    let downstreamContexts: [any Context] = []  // Leaf context
    private let orderClient: OrderClient
    
    init(orderClient: OrderClient) {
        self.orderClient = orderClient
    }
    
    func send(_ action: OrderAction) async {
        try? await orderClient.send(action)
    }
}

// Complex composition example
@MainActor
final class AppContext: Context {
    typealias Action = AppAction
    
    let downstreamContexts: [any Context]
    
    // App context manages the full context graph
    init(userContext: UserContext, cartContext: CartContext, paymentContext: PaymentContext) {
        // Upstream context declares its downstream dependencies
        self.downstreamContexts = [userContext, cartContext, paymentContext]
    }
    
    func send(_ action: AppAction) async {
        // Coordinate downstream contexts
        for context in downstreamContexts {
            if let userContext = context as? UserContext {
                // Access downstream context state/functionality
            }
        }
    }
}

// 6. Orchestrator (application root)
@MainActor
final class AppOrchestrator: Orchestrator {
    @Published private(set) var rootContexts: [any Context] = []
    
    func createContextGraph() {
        // Create capabilities
        let networkCapability = NetworkCapability()
        let storageCapability = StorageCapability()
        
        // Create clients
        let userClient = UserClient(network: networkCapability)
        let orderClient = OrderClient(network: networkCapability, storage: storageCapability)
        let profileClient = ProfileClient(storage: storageCapability)
        
        // Create leaf contexts first (no downstream dependencies)
        let orderContext = OrderContext(orderClient: orderClient)
        let profileContext = ProfileContext(profileClient: profileClient)
        
        // Create upstream contexts that depend on downstream contexts
        let userContext = UserContext(
            orderContext: orderContext,
            profileContext: profileContext,
            userClient: userClient
        )
        
        // Register only root contexts (those without upstream dependencies)
        rootContexts = [userContext]
    }
}

// 7. Presentation (View)
struct UserView: View {
    @ObservedObject var context: UserContext // Exactly ONE context
    
    var body: some View {
        if context.isLoggedIn {
            Text("Welcome, \(context.username)")
        }
    }
}
```

## Constraint Enforcement

### Option 1: Swift Macros (Compile-Time)
```swift
@AxiomClient
actor OrderClient {
    @Capability let payment: PaymentCapability  // ✅ Allowed
    @Client let userClient: UserClient          // ❌ Compile error
}
```

### Option 2: SwiftLint Rules (Build-Time)
```yaml
axiom_constraints:
  - client_capability_only: error
  - context_client_only: error
  - capability_no_dependencies: error
```

### Option 3: Runtime Validation (Development)
```swift
#if DEBUG
extension Client {
    func validateConstraints() {
        // Check dependencies at runtime
    }
}
#endif
```

## AI Code Generation Guide

### Constraint Violations AI Must Avoid

```swift
// ❌ VIOLATION 1: Client-to-client dependency
actor OrderClient: StatefulClient {
    private let userClient: UserClient  // NEVER ALLOWED
}
// ✅ FIX: Move coordination to Context

// ❌ VIOLATION 2: Context accessing capability
@MainActor 
final class AppContext: Context {
    private let network: NetworkCapability  // NEVER ALLOWED
}
// ✅ FIX: Access capabilities through Clients

// ❌ VIOLATION 3: Capability with dependencies
final class CacheCapability: Capability {
    private let logger: LoggerCapability  // NEVER ALLOWED
}
// ✅ FIX: Capabilities are leaf nodes

// ❌ VIOLATION 4: Shared state between clients
class SharedUserState {  // NEVER ALLOWED
    static let shared = SharedUserState()
}
// ✅ FIX: Each Client owns its state

// ❌ VIOLATION 5: Circular context dependencies
@MainActor
final class ContextA: Context {
    init(contextB: ContextB) {
        self.downstreamContexts = [contextB]
        contextB.downstreamContexts = [self]  // NEVER ALLOWED - creates cycle
    }
}
// ✅ FIX: Context dependencies must form a directed acyclic graph

// ❌ VIOLATION 6: Context creating contexts
@MainActor
final class ParentContext: Context {
    func createChild() -> ChildContext {  // NEVER ALLOWED
        let child = ChildContext()
        self.downstreamContexts.append(child)
        return child
    }
}
// ✅ FIX: Only Orchestrator creates contexts

// ❌ VIOLATION 7: View with multiple contexts
struct ComplexView: View {
    @ObservedObject var userContext: UserContext
    @ObservedObject var orderContext: OrderContext  // NEVER ALLOWED
    
    var body: some View {
        Text("Multiple contexts")
    }
}
// ✅ FIX: Each View has exactly ONE Context

// ✅ VALID: Upstream context managing multiple downstream dependencies
@MainActor
final class CheckoutContext: Context {
    let downstreamContexts: [any Context]
    
    init(userContext: UserContext, cartContext: CartContext, paymentContext: PaymentContext) {
        // Upstream context manages its downstream dependencies
        self.downstreamContexts = [userContext, cartContext, paymentContext]
    }
    
    func send(_ action: CheckoutAction) async {
        // Can coordinate downstream contexts
        if let userContext = downstreamContexts.first(where: { $0 is UserContext }) as? UserContext {
            guard userContext.isLoggedIn else { return }
        }
    }
}
```

## Context Composition Deep Dive

### Understanding Context Dependencies

Contexts form a directed acyclic graph (DAG) through dependency injection:

- **Upstream Contexts**: Contexts that manage and coordinate downstream contexts
- **Downstream Contexts**: Contexts that are dependencies of upstream contexts
- **Root Contexts**: Top-level contexts that have downstream dependencies but no upstream
- **Leaf Contexts**: Contexts with no downstream dependencies

**Key Principle**: Upstream contexts declare and manage their downstream dependencies, similar to dependency injection patterns.

### Rules for Context Composition

1. Dependencies must be **unidirectional** - no cycles allowed
2. Upstream contexts **declare** their downstream dependencies
3. A context can have **multiple downstream contexts**
4. A context can be a downstream dependency of **multiple upstream contexts**
5. Only the **Orchestrator** can create contexts
6. Dependencies are **immutable** after initialization

### Example Context DAG

```
Orchestrator
     |
     └── CheckoutContext (root)
              ├── UserContext
              │        ├── ProfileContext (leaf)
              │        └── OrderContext (leaf)
              ├── CartContext (leaf)
              └── PaymentContext (leaf)

Flow: CheckoutContext → {UserContext, CartContext, PaymentContext} → {ProfileContext, OrderContext}
```

In this DAG:
- `CheckoutContext` is the root (no upstream dependencies)
- `CheckoutContext` manages `UserContext`, `CartContext`, and `PaymentContext` as downstream dependencies
- `UserContext` manages `ProfileContext` and `OrderContext` as its downstream dependencies
- Leaf contexts have no downstream dependencies

## Benefits of Constraints

1. **Clear Boundaries**: Every component has a single, well-defined responsibility
2. **Thread Safety**: Actor isolation prevents race conditions
3. **Testability**: Dependencies flow in one direction
4. **AI Compliance**: Clear rules that AI can follow
5. **Maintainability**: Consistent patterns across codebase
6. **Composability**: Contexts can be composed into complex DAGs while maintaining safety

## Non-Goals

This proposal does NOT prescribe:
- Specific error handling mechanisms
- State synchronization strategies  
- Testing frameworks
- Dependency injection patterns
- Naming conventions beyond component types

## Implementation Priority

1. **Phase 1**: Define core protocols (1 day)
2. **Phase 2**: Create macro annotations (3 days)
3. **Phase 3**: Add SwiftLint rules (2 days)
4. **Phase 4**: Build example app (2 days)

## Conclusion

Axiom defines **seven permanent component types** and **nine immutable constraints** that form the foundation of the architecture. These are not guidelines or suggestions—they are architectural laws that MUST be followed:

**The Seven Components**: Capability, Owned State, Stateful Client, Stateless Client, Orchestrator, Context, and Presentation are the ONLY allowed component types.

**The Nine Constraints**: Define the exact relationships and dependencies between components. No exceptions or variations are permitted.

Implementation details, error handling, and specific patterns may evolve, but these components and constraints are **permanent and non-negotiable**, even in future revisions of the framework.

---

**RFC Number**: 001  
**Title**: Axiom Architectural Constraints  
**Status**: Proposed  
**Type**: Architecture  
**Created**: 2025-01-06  
**Authors**: Axiom Framework Team