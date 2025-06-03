# Testing Infrastructure and Error Handling Proposal

## Summary

Establish testing infrastructure with comprehensive dependency injection, macro-generated initializers, and zero-boilerplate architecture for the Axiom framework with action-based state management and strong concurrency safety.

**Core Architectural Constraint**: Every application-facing component follows a protocol-macro pairing where protocols define specifications and macros handle validation, code generation, and dependency injection.

**Action-Based Architecture**: Contexts define enumerated Actions that clients must implement. Parent contexts compose child actions, creating a unidirectional flow similar to TCA but adapted for our component hierarchy.

**Concurrency Safety**: Client state mutations are copy-only (immutable struct updates), preventing race conditions. Only clients can modify their own state through actions, ensuring thread-safe concurrent access from multiple contexts.

**Key Architectural Enforcement**: 
- **Client Isolation**: Clients cannot depend on other clients (domain boundaries)
- **Capability Exclusivity**: Only clients can use capabilities - contexts must coordinate through clients
- **State Hierarchy**: StatefulClients own @OwnedState via macro parameters, contexts observe client state through DI, presentations cannot define any state
- **No Circular Dependencies**: Capabilities cannot depend on capabilities, OwnedState cannot depend on OwnedState
- **Component Separation**: Components cannot define what their dependencies already define

### Key Features

**Dependency Injection**:
- Macro-generated initializers for all components
- Zero manual initialization code
- Compile-time dependency resolution
- Type-safe dependency registry
- Protocol-defined initialization patterns

**Type-Safe Architecture**:
- Properties declared as actual fields (not macro parameters)
- Macros derive behavior from type introspection
- Bidirectional binding from type analysis
- @Orchestrator replaces @Application

**Action-Based State Management**:
- Enumerated actions provide clear contracts
- Parent contexts compose child actions
- Copy-only mutations prevent race conditions
- Unidirectional data flow (Views → Contexts → Clients → State)
- Similar to TCA but adapted for our component hierarchy

**State Management**:
- StatefulClients own single @OwnedState through macro parameters (single state ownership)
- Contexts observe StatefulClient @OwnedState through dependency injection (no local state)
- @Context: Observable access to StatefulClient state with DI and actions
- @Presentation: Observable binding with action sending (no local state)

**Testing Infrastructure**:
- DI validation and mocking
- State immutability testing
- Initialization lifecycle testing
- Performance benchmarking

## Complete Macro and Protocol Reference

### Component Macros (8 total) - Prevention-Focused Architecture

**Core Principle**: Each macro enforces what components CANNOT define to maintain architectural boundaries. Components cannot define what their dependencies already define.

1. **@StatefulClient(stateType:capabilities:)**
   - **PREVENTS: Client-to-Client Dependencies** - No `@StatefulClient` or `@StatelessClient` injection (domain isolation)
   - **PREVENTS: Capability Definition** - Cannot define `@Capability` types (must inject existing ones)
   - **PREVENTS: Context State Types** - Cannot define what contexts define (separate state ownership)
   - **PREVENTS: Direct Capability Instantiation** - Must use dependency injection
   - **PREVENTS: Mutable State Mutations** - Enforces copy-only immutable updates
   - Parameters: stateType (required), capabilities (optional)

2. **@StatelessClient(capabilities:)**
   - **PREVENTS: Any State Declaration** - Cannot define state properties (stateless by design)
   - **PREVENTS: Client-to-Client Dependencies** - No other client injection (domain isolation)
   - **PREVENTS: Capability Definition** - Cannot define `@Capability` types (must inject existing ones)
   - **PREVENTS: Context Dependencies** - Cannot inject contexts (clients are leaf dependencies)
   - **PREVENTS: Direct Capability Instantiation** - Must use dependency injection
   - Parameters: capabilities (required)

3. **@Context(statefulClients:statelessClients:childContexts:)**
   - **PREVENTS: Capability Definition** - Cannot define `@Capability` types (clients define capabilities)
   - **PREVENTS: Client State Types** - Cannot define client-owned state (clients own their state)
   - **PREVENTS: Direct Client Instantiation** - Must use dependency injection
   - **PREVENTS: Capability Usage** - Cannot inject `@Capability` directly (must coordinate through clients)
   - **PREVENTS: Presentation State Types** - Cannot define what presentations define (but presentations have no state)
   - **ALLOWS: Multiple Local State Properties** - Can define state in class body (context-owned state)
   - Parameters: all optional, define dependencies

4. **@Capability**
   - **PREVENTS: All Dependencies** - Cannot inject any other components (leaf nodes)
   - **PREVENTS: State Ownership** - Cannot define state (pure external service)
   - **PREVENTS: Other Capability Dependencies** - Cannot inject other `@Capability` instances
   - **PREVENTS: Client/Context Dependencies** - Cannot inject application components
   - **RESTRICTION: Client-Only Usage** - Only clients can inject capabilities
   - Parameters: none (enforces zero dependencies)

5. **@Presentation(contextType:)**
   - **PREVENTS: Local State Declaration** - Cannot define `@State`, `@StateObject`, etc. (contexts own all state)
   - **PREVENTS: Context State Types** - Cannot define what contexts define (context owns state)
   - **PREVENTS: Client Dependencies** - Cannot inject clients directly (contexts mediate)
   - **PREVENTS: Direct State Mutation** - Cannot modify state (action-based only)
   - **PREVENTS: Context Instantiation** - Must receive context via dependency injection
   - **ENFORCES: ViewBuilder Usage** - Must use `@ViewBuilder` functions for view composition
   - Parameters: contextType (required)

6. **@OwnedState**
   - **PREVENTS: Dependencies on Other OwnedState** - Cannot inject other `@OwnedState` instances
   - **PREVENTS: Client Dependencies** - Cannot inject clients (state-only, no behavior)
   - **PREVENTS: Capability Dependencies** - Cannot inject capabilities (pure state)
   - **PREVENTS: Immutable Declaration** - Must be mutable class for `@Published` properties
   - **RESTRICTION: StatefulClient-Only Usage** - Only StatefulClients can own `@OwnedState`
   - **IMPLICIT DI**: StatefulClients make OwnedState observable to contexts automatically
   - Parameters: none

7. **@Orchestrator(entryView:entryContext:dependencies:)**
   - **PREVENTS: Multiple Entry Points** - Only one `@Orchestrator` per application
   - **PREVENTS: Direct Component Instantiation** - All components must use dependency injection
   - **PREVENTS: Incomplete Registration** - All dependencies must be registered
   - **ENFORCES: Complete Dependency Graph** - Validates entire component hierarchy
   - Parameters: all required

8. **@DependencyRegistry**
   - **PREVENTS: Circular Dependencies** - Compile-time cycle detection
   - **PREVENTS: Missing Registrations** - All dependencies must be registered
   - **PREVENTS: Type Mismatches** - Type-safe dependency resolution
   - **VALIDATES: Complete Dependency Graph** - Ensures all components can be resolved
   - Parameters: none

### Component Protocols (8 total)

1. **StatefulClient**: Actor protocol with state ownership
2. **StatelessClient**: Actor protocol without state
3. **Context**: ObservableObject with action handling
4. **Capability**: External service integration
5. **Presentation**: View with context binding
6. **OwnedState**: Observable state for StatefulClients
7. **Orchestrator**: App entry point
8. **DependencyRegistry**: Dependency registration

### Supporting Protocols

- **Injectable**: Zero-parameter init requirement
- **DependencyContainer**: DI container operations

### Utility Macros

- **@Observable**: Property wrapper for state fields
- **@TestingFramework**: Testing infrastructure
- **@ErrorBoundary**: Error handling utilities

## Architectural Principles

### Protocol-Macro Pairing

Every application-facing component follows a strict protocol-macro pairing:
- **Protocol**: Defines the specification and contract
- **Macro**: Handles validation, code generation, and dependency injection

### Key Architectural Constraints

1. **Client Isolation**: Clients cannot depend on other clients. Each client is an isolated domain boundary.

2. **Capabilities are Client-Only**: Only StatefulClient and StatelessClient can use capabilities. Contexts cannot use capabilities directly - they must coordinate through clients.

3. **No Capability Dependencies**: Capabilities cannot depend on other capabilities. They are leaf nodes in the dependency graph.

4. **No OwnedState Dependencies**: OwnedState instances cannot depend on other OwnedState. Each is independent.

5. **State Ownership Rules**:
   - StatefulClients: Own single @OwnedState type via macro parameter, make observable to contexts
   - Contexts: Observe client state through dependency injection, no local state ownership
   - Presentations: Cannot define any local state (use ViewBuilder functions)

6. **Component Hierarchy Enforcement**:
   - Components cannot define what their dependencies define
   - Contexts cannot define capabilities or client state
   - Presentations cannot define state (contexts handle all state)

### Architectural Enforcement Matrix

**Core Rule**: Components CANNOT define what their dependencies already define.

| Component Type | CANNOT Define | Reason | Must Use Instead |
|---|---|---|---|
| **@StatefulClient** | Other clients (`@StatefulClient`, `@StatelessClient`) | Domain isolation | Coordinate through contexts |
| **@StatefulClient** | Capabilities (`@Capability`) | Separation of concerns | Inject existing capabilities |
| **@StatefulClient** | Context state types | Single ownership | Own state via `stateType` parameter |
| **@StatelessClient** | Any state properties | Stateless design | Pure computation only |
| **@StatelessClient** | Other clients | Domain isolation | Coordinate through contexts |
| **@StatelessClient** | Capabilities (`@Capability`) | Separation of concerns | Inject existing capabilities |
| **@Context** | Capabilities (`@Capability`) | Clients own capabilities | Coordinate through injected clients |
| **@Context** | Client state types | Clients own their @OwnedState | Observe client state through DI |
| **@Presentation** | Local state (`@State`, `@StateObject`) | StatefulClients own all state | Use `@ViewBuilder` functions |
| **@Presentation** | Context state access | Contexts observe client state | Access through injected context |
| **@Presentation** | Client dependencies | Contexts mediate | Access through injected context |
| **@Capability** | Any dependencies | Leaf node design | Direct external integration only |
| **@OwnedState** | Other `@OwnedState` | Independence requirement | Each state is isolated |
| **@OwnedState** | Any dependencies | Pure state design | StatefulClient-owned only |

### Component Definition Boundaries

```swift
// ❌ VIOLATIONS: Components defining what dependencies define

// StatefulClient defining capabilities (clients inject capabilities, not define them)
@StatefulClient(stateType: UserState.self)
actor UserClient {
    // ❌ Cannot define capability
    @Capability
    class NetworkCapability { ... }  // VIOLATION: Clients inject capabilities
}

// Context defining capabilities (clients own capabilities)
@Context(statefulClients: [UserClient.self])
class UserContext {
    // ❌ Cannot define capability
    @Capability
    class AnalyticsCapability { ... }  // VIOLATION: Contexts coordinate through clients
}

// Presentation defining local state (contexts own state)
@Presentation(contextType: UserContext.self)
struct UserView {
    @ObservedObject var context: UserContext
    // ❌ Cannot define local state
    @State var isShowingDetails = false  // VIOLATION: Contexts own all state
}

// Client depending on other clients (domain isolation)
@StatefulClient(stateType: UserState.self)
actor UserClient {
    // ❌ Cannot inject other clients
    private let cartClient: CartClient  // VIOLATION: Client isolation boundary
}

// ✅ CORRECT: Components using what dependencies define

// StatefulClient injecting capabilities (not defining them)
@StatefulClient(
    stateType: UserState.self,
    capabilities: [NetworkCapability.self]  // ✅ Inject existing
)
actor UserClient { ... }

// Context coordinating through clients (not defining capabilities)
@Context(
    statefulClients: [UserClient.self],
    statelessClients: [AnalyticsClient.self]  // ✅ Coordinate through clients
)
class UserContext { ... }

// Presentation using ViewBuilder (not local state)
@Presentation(contextType: UserContext.self)
struct UserView {
    @ObservedObject var context: UserContext
    // ✅ Use ViewBuilder functions instead of local state
    
    @ViewBuilder
    private var detailsView: some View {
        if context.state.isShowingDetails {
            Text("Details...")
        }
    }
}
```

### Component Protocol-Macro Pairs

```swift
// 1. Stateful Client Component (owns and persists state)
protocol StatefulClient: Actor {
    associatedtype State
    var state: State { get }
}

@StatefulClient(stateType: UserState.self) // Generates init(), state management, DI

// 2. Stateless Client Component (no state, pure computation/service)
protocol StatelessClient: Actor {
    // No state requirement - pure service/computation
}

@StatelessClient(capabilities: [NetworkCapability.self]) // Generates init(), DI only

// 3. Context Component (observes StatefulClient state through DI)
@MainActor
protocol Context: ObservableObject {
    associatedtype Action  // Enumerated actions this context handles
    
    // Contexts observe StatefulClient @OwnedState through dependency injection
    // No direct state ownership - state comes from injected StatefulClients
    
    func send(_ action: Action) async  // Handle actions
}

@Context(
    statefulClients: [UserClient.self],
    statelessClients: [AnalyticsClient.self]
) // Generates init(), bindings, DI, ObservableObject conformance, action handling

// 4. Capability Component
protocol Capability {
    // Service integration contract
}

@Capability // Generates init(), no dependencies allowed

// 5. Presentation Component
protocol Presentation: View {
    associatedtype ContextType: Context
    var context: ContextType { get }
}

@Presentation(contextType:) // Generates init(), bindings, computed properties

// 6. Owned State Component (for Context)
protocol OwnedState: ObservableObject {
    // Mutable state ownership contract
}

@OwnedState // Generates @Published properties, observation

// 7. Orchestrator Component
protocol Orchestrator {
    static func main() async throws
    static var container: DependencyContainer { get }
}

@Orchestrator(entryView:entryContext:dependencies:) // Generates entry point, DI setup

// 8. Dependency Registry Component
protocol DependencyRegistry {
    func register(to container: DependencyContainer)
}

@DependencyRegistry // Validates completeness, type safety
```

### Utility Macros (No Protocol Required)

```swift
// Property wrappers and helpers
@Observable // Property wrapper for observable fields
@TestingFramework // Internal framework testing utilities
@ErrorBoundary // Error handling utilities
```

## Technical Specification

### 1. Zero-Initializer Architecture with Action-Based Updates

```swift
// Context defines actions that clients must implement
@Context(
    statefulClients: [UserClient.self],
    statelessClients: [AnalyticsClient.self]
)
class UserContext: Context {
    // Define enumerated actions
    enum Action {
        case login(username: String, password: String)
        case logout
        case updateProfile(name: String)
    }
    
    // State defined inside context (can have multiple properties)
    var state: UserContextState
    
    // Dependencies injected by macro based on parameters
    // private let userClient: UserClient
    // private let analyticsClient: AnalyticsClient
    
    // Macro generates this method
    func send(_ action: Action) async {
        switch action {
        case .login(let username, let password):
            // Client must implement this action
            await userClient.send(.login(username: username, password: password))
            // Update context state from client state
            state.username = await userClient.state.username
            state.isLoggedIn = await userClient.state.isLoggedIn
            
        case .logout:
            await userClient.send(.logout)
            state.username = ""
            state.isLoggedIn = false
            
        case .updateProfile(let name):
            await userClient.send(.updateProfile(name: name))
            state.username = await userClient.state.username
        }
    }
}

// Client implements context-defined actions with copy-only mutations
@StatefulClient(
    stateType: UserState.self,
    capabilities: [NetworkCapability.self]
)
actor UserClient: StatefulClient {
    // State generated by macro based on stateType parameter
    // private(set) var state: UserState = UserState()
    
    // Capabilities injected by macro based on capabilities parameter
    // private let network: NetworkCapability
    
    // Client must implement context's action enum
    enum Action {
        case login(username: String, password: String)
        case logout
        case updateProfile(name: String)
    }
    
    func send(_ action: Action) async {
        switch action {
        case .login(let username, let password):
            let response = await network.post("/login", body: ["username": username, "password": password])
            // Copy-only state mutation - replace entire state
            state = UserState(
                username: response.username,
                isLoggedIn: true
            )
            
        case .logout:
            await network.post("/logout")
            // Copy-only state mutation
            state = UserState(username: "", isLoggedIn: false)
            
        case .updateProfile(let name):
            await network.post("/profile", body: ["name": name])
            // Copy-only state mutation - preserve other fields
            state = UserState(
                username: name,
                isLoggedIn: state.isLoggedIn
            )
        }
    }
}

// Client state struct - no special protocol needed
struct UserState: Sendable, Equatable {
    let username: String
    let isLoggedIn: Bool
}

// Parent-Child Action Composition
@Context(
    childContexts: [UserContext.self, CartContext.self]
)
class AppContext: Context {
    // Parent must enumerate child actions
    enum Action {
        // Own actions
        case selectTab(AppTab)
        case refresh
        
        // Child context actions
        case user(UserContext.Action)
        case cart(CartContext.Action)
    }
    
    // State defined inside context
    var state: AppState
    
    // Child contexts injected by macro
    // private let userContext: UserContext
    // private let cartContext: CartContext
    
    func send(_ action: Action) async {
        switch action {
        case .selectTab(let tab):
            state.selectedTab = tab
            
        case .refresh:
            // Compose child actions
            await userContext.send(.logout)
            await cartContext.send(.clear)
            
        case .user(let userAction):
            // Forward to child context
            await userContext.send(userAction)
            // Update parent state if needed
            if case .logout = userAction {
                state.selectedTab = .login
            }
            
        case .cart(let cartAction):
            await cartContext.send(cartAction)
        }
    }
}

// View sends actions to context (no local state allowed)
@Presentation(contextType: UserContext.self)
struct UserView: Presentation {
    @ObservedObject var context: UserContext
    // ❌ @State var isShowingDetails = false  // Not allowed - contexts own all state
    
    var body: some View {
        VStack {
            Text(context.state.username)  // ✅ Read context state
            
            loginButton  // ✅ Use ViewBuilder functions
            
            if context.state.isLoggedIn {
                loggedInContent  // ✅ Compose with ViewBuilder
            }
        }
    }
    
    // ✅ ViewBuilder functions for composition (no local state needed)
    @ViewBuilder
    private var loginButton: some View {
        Button("Login") {
            Task {
                await context.send(.login(username: "user", password: "pass"))
            }
        }
    }
    
    @ViewBuilder
    private var loggedInContent: some View {
        VStack {
            Text("Welcome, \(context.state.username)!")
            Button("Logout") {
                Task {
                    await context.send(.logout)
                }
            }
        }
    }
}

// Stateless client for pure computation/service
@StatelessClient(
    capabilities: [NetworkCapability.self]
)
actor AnalyticsClient: StatelessClient {
    // No state - pure service
    // Capabilities injected by macro
    // private let network: NetworkCapability
    
    // Macro generates:
    // - init() with DI container injection
    // - No state management needed
    
    func trackEvent(_ event: String) async {
        await network.post("/analytics", body: ["event": event])
    }
}

// Context can inject both stateful and stateless clients
@Context(
    statefulClients: [UserClient.self],
    statelessClients: [AnalyticsClient.self]
)
class UserContext: Context {
    // Action enum defines all possible operations
    enum Action {
        case login(username: String, password: String)
        case logout
        case updateProfile(name: String)
    }
    
    // Dependencies injected by macro based on parameters
    // private let userClient: UserClient  // StatefulClient (owns @OwnedState)
    // private let analyticsClient: AnalyticsClient  // StatelessClient
    
    // Macro generates:
    // - init() that receives dependencies from DI container
    // - ObservableObject conformance by observing injected StatefulClient @OwnedState
    // - send(_ action:) implementation
    // - Protocol conformance validation
    
    // Computed properties provide observable access to StatefulClient state
    var username: String {
        // Observable access to userClient.state.username through DI
        userClient.state.username
    }
    
    var isLoggedIn: Bool {
        // Observable access to userClient.state.isLoggedIn through DI
        userClient.state.isLoggedIn
    }
    
    func send(_ action: Action) async {
        switch action {
        case .login(let username, let password):
            // Forward action to StatefulClient (which owns @OwnedState)
            await userClient.send(.login(username: username, password: password))
            // StatefulClient @OwnedState automatically triggers observable updates
            
            // Use stateless client for analytics
            await analyticsClient.trackEvent("user_login")
            
        case .logout:
            await userClient.send(.logout)
            // StatefulClient @OwnedState automatically triggers observable updates
            await analyticsClient.trackEvent("user_logout")
            
        case .updateProfile(let name):
            await userClient.send(.updateProfile(name: name))
            // StatefulClient @OwnedState automatically triggers observable updates
            await analyticsClient.trackEvent("profile_updated")
        }
    }
}

// Owned state for StatefulClient (StatefulClient-only, no dependencies)
@OwnedState
class UserState: OwnedState {
    @Published var username: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var profile: UserProfile? = nil
    // ❌ Cannot depend on other OwnedState instances
    // ❌ Cannot be used by contexts directly (StatefulClient-only)
    
    // Macro generates:
    // - ObservableObject conformance
    // - Prevents dependencies on other OwnedState
    // - Validates StatefulClient-only usage
    // - Implicit observable access for contexts through StatefulClient DI
}

// Dependency Registry with macro
@DependencyRegistry
struct AppDependencies: DependencyRegistry {
    // Actual registration code with type safety
    func register(to container: DependencyContainer) {
        // Stateful Clients
        container.register(UserClient.self, scope: .singleton)
        
        // Stateless Clients
        container.register(AnalyticsClient.self, scope: .singleton)
        
        // Capabilities (no dependencies - leaf nodes)
        container.register(NetworkCapability.self, scope: .singleton) { NetworkCapability() }
        container.register(DatabaseCapability.self, scope: .singleton) { DatabaseCapability() }
        
        // Contexts
        container.register(AppContext.self, scope: .transient)
        container.register(UserContext.self, scope: .transient)
    }
    
    // Macro generates:
    // - DependencyRegistry protocol conformance
    // - Validation of registration completeness
    // - Type-safe dependency graph
}

// Orchestrator with dependency registry
@Orchestrator(
    entryView: AppView.self,
    entryContext: AppContext.self,
    dependencies: AppDependencies.self
)
struct ExampleApp {
    // Macro generates:
    // - @main static func main() async throws
    // - Orchestrator protocol conformance
    // - DI container initialization with AppDependencies
    // - Error handling and lifecycle management
}

// Capability: Leaf node with no dependencies
@Capability
class NetworkCapability: Capability {
    // ❌ Cannot inject other capabilities
    // ❌ Cannot inject clients or contexts
    // ❌ Cannot have any dependencies (leaf node)
    // ✅ Direct external system integration only
    
    // Macro generates:
    // - init() with no parameters (enforces zero dependencies)
    // - Capability protocol conformance
    // - Validates leaf node status
    
    func post(_ path: String, body: Any? = nil) async -> Response {
        // Direct external network integration
        // URLSession, Alamofire, etc. - external only
    }
}
```

### 2. Dependency Injection Container

```swift
// Generated DI container protocol
protocol DependencyContainer {
    func register<T>(_ type: T.Type, scope: InjectionScope, factory: @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T
    func createScope() -> DependencyScope
}

// Injection scopes
enum InjectionScope {
    case singleton    // One instance for app lifetime
    case transient    // New instance each time
    case scoped       // One instance per scope
}

// Protocol-defined initialization
protocol Injectable {
    init()  // Zero-parameter initializer required
}

// Dependency registry protocol
protocol DependencyRegistry {
    func register(to container: DependencyContainer)
}

// Orchestrator protocol  
protocol Orchestrator {
    static func main() async throws
    static var container: DependencyContainer { get }
}

// All components conform to Injectable
extension StatefulClient: Injectable { }
extension StatelessClient: Injectable { }
extension Context: Injectable { }
extension Capability: Injectable { }
extension Presentation: Injectable { }

// Example of generated container usage
class GeneratedDependencyContainer: DependencyContainer {
    // Macro generates complete implementation
    // Including factory methods for all registered types
    // Automatic dependency resolution
    // Scope management
}
```

### 3. State Management with Type-Safe Properties

```swift
// App state struct - simple value type
struct AppState: Sendable, Equatable {
    let currentTab: ApplicationTab
    let isLoading: Bool
}

// Context with actual properties and type derivation
@Context(
    statefulClients: [UserClient.self],
    statelessClients: [AnalyticsClient.self]
)
class AppContext: Context {
    // State property (required by Context protocol)
    var state: AppContextState
    
    // Local properties
    var cacheData: [String: Any] = [:]
    
    // Dependencies injected by macro
    // private let userClient: UserClient
    // private let analyticsClient: AnalyticsClient
    
    // Macro generates:
    // - init() with DI
    // - ObservableObject conformance  
    // - Bidirectional binding from state type
    // - Protocol validation
    
    func navigateToTab(_ tab: ApplicationTab) async {
        state.currentTab = tab
        await analyticsClient.trackNavigation(to: tab)
    }
}

// Context observes StatefulClient state (no @OwnedState for contexts)
// AppContext gets observable state from injected StatefulClients
// through dependency injection automatically

// Presentation with context type derivation
@Presentation(contextType: AppContext.self)
struct AppView: Presentation {
    // Context property (required by Presentation protocol)
    @ObservedObject var context: AppContext
    
    // Macro generates:
    // - init() with context from DI container
    // - Protocol conformance validation
    // - Computed properties from context.state
    // - Bidirectional binding support
    
    var body: some View {
        TabView(selection: .constant(context.state.currentTab)) {
            UserView()
                .tabItem { Label("User", systemImage: "person") }
                .tag(ApplicationTab.user)
        }
        .overlay(context.state.isLoading ? ProgressView() : nil)
    }
}

```

### 4. State Visibility and Concurrency Rules

```swift
// CLIENT STATE MUTATIONS: Copy-only for concurrency safety
@StatefulClient
actor UserClient: StatefulClient {
    private(set) var state: UserState  // Immutable struct
    
    enum Action {
        case login(username: String, password: String)
        case updateProfile(name: String)
    }
    
    func send(_ action: Action) async {
        switch action {
        case .login(let username, _):
            // ✅ Copy-only mutation - replace entire state
            state = UserState(username: username, isLoggedIn: true)
            
        case .updateProfile(let name):
            // ✅ Copy-only mutation - preserve other fields
            state = UserState(
                username: name,
                isLoggedIn: state.isLoggedIn  // Copy existing values
            )
        }
    }
}

// ACTION FLOW: Parent contexts compose child actions
@Context(
    childContexts: [UserContext.self, CartContext.self]
)
class AppContext: Context {
    enum Action {
        case refresh
        case user(UserContext.Action)  // Child actions
        case cart(CartContext.Action)
    }
    
    // Injected by macro
    // private let userContext: UserContext
    // private let cartContext: CartContext
    
    func send(_ action: Action) async {
        switch action {
        case .refresh:
            // Compose multiple child actions
            await userContext.send(.logout)
            await cartContext.send(.clear)
            
        case .user(let userAction):
            // Forward to child
            await userContext.send(userAction)
            
        case .cart(let cartAction):
            await cartContext.send(cartAction)
        }
    }
}

// CLIENT STATE VISIBILITY: Only contexts with injected client
@Context(
    statefulClients: [UserClient.self]
)
class UserContext: Context {
    // Injected by macro
    // private let userClient: UserClient
    
    enum Action {
        case refreshUser
    }
    
    func send(_ action: Action) async {
        switch action {
        case .refreshUser:
            // ✅ Can access state - client is injected
            let clientState = await userClient.state
            state.username = clientState.username
        }
    }
}

// CONCURRENT ACCESS: Multiple contexts safely share client
@Context(
    statefulClients: [UserClient.self]
)
class CartContext: Context {
    // Same instance injected by macro
    // private let userClient: UserClient
    
    enum Action {
        case addToCart(productId: String)
    }
    
    func send(_ action: Action) async {
        switch action {
        case .addToCart(let productId):
            // Safe concurrent read - immutable state
            let user = await userClient.state
            if user.isLoggedIn {
                // Add to cart...
            }
        }
    }
}
```

### 5. Compile-Time Safety

```swift
// Views have no local state - use ViewBuilder for composition
@Presentation(contextType: UserContext.self)
struct UserView: Presentation {
    @ObservedObject var context: UserContext
    // ❌ @State var isShowingDetails = false  // Not allowed - contexts own all state
    
    var body: some View {
        VStack {
            Text(context.state.username)  // ✅ Read context state
            
            loginButton  // ✅ Use ViewBuilder functions
            
            if context.state.isShowingDetails {
                detailsView  // ✅ Compose with ViewBuilder
            }
        }
    }
    
    // ✅ ViewBuilder functions for composition (no local state)
    @ViewBuilder
    private var loginButton: some View {
        Button("Login") {
            Task {
                await context.send(.login(username: "user", password: "pass"))
            }
        }
    }
    
    @ViewBuilder
    private var detailsView: some View {
        Text("User details...")
    }
}

// Context handles actions, updates its own state
@Context(
    statefulClients: [UserClient.self]
)
class UserContext: Context {
    var state: UserContextState  // OwnedState - mutable
    
    // Injected by macro
    // private let userClient: UserClient
    
    enum Action {
        case login(username: String, password: String)
        case logout
    }
    
    func send(_ action: Action) async {
        switch action {
        case .login(let username, let password):
            // ✅ Forward to client action
            await userClient.send(.login(username: username, password: password))
            
            // ✅ Update context state
            let clientState = await userClient.state
            state.username = clientState.username
            state.isLoggedIn = clientState.isLoggedIn
            
        case .logout:
            await userClient.send(.logout)
            state.username = ""
            state.isLoggedIn = false
        }
    }
}

// Client uses copy-only mutations
@StatefulClient
actor UserClient: StatefulClient {
    private(set) var state: UserState  // Immutable struct
    
    enum Action {
        case login(username: String, password: String)
        case logout
    }
    
    func send(_ action: Action) async {
        switch action {
        case .login(let username, _):
            // ✅ Copy-only mutation - replace entire state
            state = UserState(username: username, isLoggedIn: true)
            
        case .logout:
            // ✅ Copy-only mutation
            state = UserState(username: "", isLoggedIn: false)
        }
    }
}
```

### 6. Testing Infrastructure with DI Focus

```swift
// Dependency injection testing
@TestingFramework
struct DependencyInjectionTesting {
    static func validateInjection<T: Injectable>(_ type: T.Type) -> InjectionValidationResult
    static func validateScope(_ scope: InjectionScope, for type: Any.Type) async throws
    static func mockDependency<T>(_ type: T.Type, with mock: T)
}

// Initializer testing
@TestingFramework
struct InitializerTesting {
    static func validateMacroGeneratedInit<T>(_ type: T.Type) -> InitializerValidationResult
    static func validateZeroParameterInit<T: Injectable>(_ type: T.Type) async throws
    static func validateDependencyResolution<T>(_ type: T.Type, in container: DependencyContainer) async throws
}

// Configuration testing
@TestingFramework
struct ConfigurationTesting {
    static func validateOrchestratorConfig(_ app: any Orchestrator) async throws
    static func validateDependencyRegistration(_ registrations: [DependencyRegistry]) async throws
    static func validateInjectionScopes(_ container: DependencyContainer) async throws
}

// Action-based testing
@TestingFramework
struct ActionTesting {
    static func testContextAction<C: Context>(_ context: C, action: C.Action, expectedState: C.State) async throws
    static func testClientAction<T: StatefulClient>(_ client: T, action: T.Action, expectedState: T.State) async throws
    static func testActionComposition<P: Context>(_ parent: P, childAction: P.Action) async throws
    static func testConcurrentActions<C: Context>(_ context: C, actions: [C.Action]) async throws
}
```

### 7. Error Handling with DI Integration

```swift
public enum AxiomError: Error, Equatable {
    case clientError(ClientError)
    case contextError(ContextError)
    case presentationError(PresentationError)
    case bindingError(BindingError)
    case validationError(ValidationError)
    case injectionError(InjectionError)  // DI-specific errors
    case initializationError(InitializationError)
    case actionError(ActionError)  // Action handling errors
}

// DI-specific errors
public enum InjectionError: Error {
    case dependencyNotRegistered(type: Any.Type)
    case cyclicDependency(chain: [Any.Type])
    case scopeMismatch(expected: InjectionScope, actual: InjectionScope)
    case initializationFailed(type: Any.Type, underlying: Error)
}

// Action-specific errors
public enum ActionError: Error {
    case unhandledAction(action: Any)
    case actionForwardingFailed(parent: Any.Type, child: Any.Type)
    case concurrentMutationDetected
    case invalidActionState
}

@ErrorBoundary
struct AxiomErrorBoundary<Content: View>: View {
    let content: Content
    let errorHandler: (AxiomError) -> Void
    
    // Macro generates DI-aware error handling
}
```

## Implementation Plan

### Phase 1: Dependency Injection & Initializers (Week 1-2)
- Implement DI container with compile-time validation
- Generate zero-parameter initializers for all components
- Protocol-defined initialization patterns (Injectable)
- Automatic dependency resolution and scope management
- @Orchestrator macro DI container generation

### Phase 2: Enhanced Component Macros (Week 3-4)  
- @Client macro with DI and generated initializers
- @Context macro with DI and state ownership
- @Presentation macro with automatic context injection
- @Capability macro for non-component capabilities
- State management through macro parameters

### Phase 3: Testing Infrastructure (Week 5-6)
- DI testing and mocking framework
- Initializer validation testing
- Configuration testing
- State immutability validation
- Performance benchmarking

## Success Criteria

### Dependency Injection
- **Zero manual initializers**: 100% macro-generated initialization
- **Compile-time DI validation**: All dependencies resolved at compile time
- **Automatic configuration**: Zero manual dependency setup
- **Protocol compliance**: All components implement Injectable protocol
- **Scope management**: Proper singleton/transient/scoped lifecycles

### State Management
- **Immutable state**: Compile-time prevention of view mutations
- **Generated initializers**: All state types have macro-generated init
- **Observable binding**: <5ms automatic UI updates

### Testing
- **DI mocking**: Complete mock injection framework
- **Initializer testing**: 100% coverage of generated initializers
- **Configuration validation**: Automated DI configuration testing
- **Performance**: <50ms app startup with full DI

---

**Status**: Ready for review  
**Timeline**: 6 weeks  
**Priority**: Critical - Zero-boilerplate DI architecture

## Key Architectural Decisions

### Action-Based Architecture
- **Enumerated Actions**: Contexts define Action enums that clients must implement
- **Parent-Child Composition**: Parents enumerate and forward child context actions
- **Unidirectional Flow**: Views → Context Actions → Client Actions → State Updates
- **Type Safety**: Compile-time validation of action handling

### Copy-Only State Mutations
- **Immutable Updates**: Client state mutations use struct copy semantics
- **No Shared Mutable State**: Prevents race conditions in concurrent access
- **Thread Safety**: Actor isolation + immutable state = safe concurrency
- **Predictable Updates**: Every state change creates a new immutable snapshot

### Two Client Types
1. **StatefulClient**: Owns state defined via macro parameter (single state ownership)
2. **StatelessClient**: Pure computation/service with no state

### State Management Distinction
- **StatefulClients**: Own @OwnedState through macro parameters (e.g., `@StatefulClient(stateType: UserState.self)`)
- **Contexts**: Observe StatefulClient @OwnedState through dependency injection (computed properties provide access)
- **@OwnedState Protocol**: StatefulClients make @OwnedState observable to contexts automatically through DI

### Capability Constraints
- **Client-Only Usage**: Only clients can use capabilities (architectural boundary)
- **No Dependencies**: Capabilities cannot depend on other capabilities
- **Leaf Nodes**: Capabilities are the bottom of the dependency hierarchy

### StatefulClient @OwnedState Rules
- **Ownership**: Only StatefulClients can own @OwnedState instances
- **Visibility**: StatefulClient @OwnedState only observable to contexts that have the client injected
- **Modification**: Only the StatefulClient can modify its own @OwnedState via actions
- **Sharing**: Single StatefulClient instance can be safely injected into multiple contexts
- **No Global State**: Prevents unnecessary globally accessible state patterns

### Context Observable Access
- Contexts observe StatefulClient @OwnedState through:
  - Computed properties that access injected StatefulClient state
  - Automatic observable updates when StatefulClient @OwnedState changes
- Sibling contexts cannot access each other's injected StatefulClient state directly

### Protocol-Macro Pairs (8 total)
All application-facing components follow strict protocol-macro pairing for type safety and zero boilerplate.

