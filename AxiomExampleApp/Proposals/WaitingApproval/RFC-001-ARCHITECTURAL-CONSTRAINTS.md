# RFC-001: Axiom Architectural Constraints

**RFC Number**: 001  
**Title**: Axiom Architectural Constraints  
**Status**: Proposed  
**Type**: Architecture  
**Created**: 2025-01-06  
**Authors**: Axiom Framework Team  
**Version**: 6.0

## Abstract

This RFC defines the immutable architectural foundation of the Axiom framework: seven component types and fifteen constraints (nine dependency rules and six lifetime rules) that govern all Axiom applications.

## Motivation

iOS development requires clear architectural boundaries to ensure maintainable, testable, and thread-safe applications. Axiom enforces these boundaries through compile-time and runtime constraints.

## Specification

### 1. Component Types

The Axiom architecture consists of exactly seven immutable component types:

#### 1.1 Capability
- **Purpose**: External system access
- **Dependencies**: None (leaf nodes)
- **Thread Safety**: Implementation-specific
- **Lifetime**: Transient (recreated as permissions change)

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
- **Purpose**: Application lifecycle, navigation, and context management
- **Dependencies**: Creates and manages all Contexts
- **Thread Safety**: @MainActor
- **Cardinality**: One per application (@main entry point)
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

### 2. Dependency Constraints

The following nine dependency rules are immutable and define what components can depend on:

1. **Client Dependency**: Clients (Stateful/Stateless) can ONLY depend on Capabilities
2. **Context Dependency**: Contexts can ONLY depend on Clients and downstream Contexts
3. **Capability Independence**: Capabilities have NO dependencies
4. **View-Context Binding**: Each View has exactly ONE Context dependency
5. **Unidirectional Flow**: Dependencies flow: Orchestrator → Context → Client → Capability → System
6. **Client Isolation**: Clients cannot depend on other Clients
7. **State Ownership**: Each State is owned by exactly ONE Client
8. **Context Composition**: Contexts form a DAG with no circular dependencies
9. **Orchestrator Responsibility**: Contexts can only be created through Orchestrator factory methods

### 3. Lifetime Constraints

The following six lifetime rules are immutable and define component lifecycles:

10. **View Lifetime**: Multiple instances - new instance per usage in SwiftUI hierarchy
11. **Context Lifetime**: Multiple instances - paired 1:1 with view instances
12. **Client Lifetime**: Singleton - one instance per client type for entire application
13. **State Lifetime**: Singleton - one instance per state type, paired 1:1 with client singleton
14. **Capability Lifetime**: Transient - recreated when permissions or availability changes
15. **Orchestrator Lifetime**: Singleton - one instance for entire application lifetime

### 4. Core Protocols

```swift
// Capability - External system access
protocol Capability {
    var isAvailable: Bool { get }
    func checkAvailability() async -> Bool
}

// Client - Business logic actor
protocol Client: Actor {
    associatedtype Action
    func send(_ action: Action) async throws
    func activate() async throws
    func deactivate() async
}

// Stateful Client - Client with owned state
protocol StatefulClient: Client {
    associatedtype State
    associatedtype StateUpdate
    var state: State { get async }
    var stateUpdates: AsyncStream<StateUpdate> { get }
}

// Context - Feature coordination
@MainActor
protocol Context: ObservableObject {
    associatedtype Action
    var orchestrator: Orchestrator { get }
    var contextId: String { get }
    func send(_ action: Action) async
    
    // View lifecycle
    func onAppear() async
    func onDisappear() async
    
    // App lifecycle
    func onBackground() async
    func onForeground() async
    func onInactive() async
    
    // Navigation lifecycle
    func onNavigateTo() async
    func onNavigateAway() async
    func canNavigateAway() async -> Bool
    func applyNavigationParams(_ params: NavigationParams) async
}

// Orchestrator - Application root and navigation controller
@MainActor
protocol Orchestrator: ObservableObject {
    var rootContexts: [any Context] { get }
    var capabilityRegistry: CapabilityRegistry { get }
    var navigationController: NavigationController { get }
    var scenePhase: ScenePhase { get }
    
    // Context management
    func createContext<T: Context>(_ type: T.Type, parent: (any Context)?) -> T
    
    // Navigation
    func navigate<T: Context>(to: T.Type, from: (any Context)?, params: NavigationParams?) async -> T
    func dismiss(_ context: any Context) async
    
    // Lifecycle
    func handleScenePhaseChange(_ phase: ScenePhase) async
    func handleDeepLink(_ url: URL) async
}
```

## Implementation Guidelines

### 5. Context Composition

Contexts form a directed acyclic graph (DAG) where:
- **Upstream Context**: A context that manages downstream contexts
- **Downstream Context**: A context that is a dependency of an upstream context
- **Root Context**: A context with no upstream dependencies
- **Leaf Context**: A context with no downstream dependencies

### 6. State Management

All state synchronization is achieved through singleton clients:
- Multiple view instances create multiple context instances
- All context instances of the same type observe the same singleton client
- State updates in the singleton client are automatically observed by all contexts
- No explicit synchronization code required

### 7. Valid Implementation Pattern

```swift
// State (Singleton per type)
struct UserState {
    let username: String
    let isLoggedIn: Bool
}

// Capability (Transient)
final class NetworkCapability: Capability {
    private(set) var isAvailable = true
    
    func checkAvailability() async -> Bool {
        // Check network reachability
        return isAvailable
    }
}

// Client (Singleton per type)
actor UserClient: StatefulClient {
    typealias Action = UserAction
    typealias State = UserState
    
    private let network: NetworkCapability  // ✅ Valid: Capability dependency
    private(set) var state = UserState(username: "", isLoggedIn: false)
    
    func send(_ action: Action) async throws {
        switch action {
        case .login(let username):
            // Update state and notify observers
        }
    }
}

// Context (Multiple instances)
@MainActor
final class UserContext: Context {
    typealias Action = UserAction
    
    let orchestrator: Orchestrator
    let contextId = UUID().uuidString
    private let userClient: UserClient  // Singleton reference
    
    @Published private(set) var username = ""
    @Published private(set) var isLoggedIn = false
    
    func send(_ action: UserAction) async {
        try? await userClient.send(action)
    }
}

// View (Multiple instances)
struct UserView: View {
    @ObservedObject var context: UserContext  // ✅ Valid: Single context
    
    var body: some View {
        Text(context.isLoggedIn ? "Welcome" : "Please log in")
    }
}
```

### 8. Constraint Violations

```swift
// ❌ Client-to-client dependency
actor OrderClient: StatefulClient {
    private let userClient: UserClient  // VIOLATION
}

// ❌ Context accessing capability
@MainActor 
final class AppContext: Context {
    private let network: NetworkCapability  // VIOLATION
}

// ❌ Capability with dependencies
final class CacheCapability: Capability {
    private let logger: LoggerCapability  // VIOLATION
}

// ❌ View with multiple contexts
struct ComplexView: View {
    @ObservedObject var userContext: UserContext
    @ObservedObject var orderContext: OrderContext  // VIOLATION
}
```

### 9. Error Handling

```swift
enum AxiomError: Error, LocalizedError {
    case capabilityUnavailable(String)
    case stateInconsistency(String)
    case contextNotFound(String)
    case clientActionFailed(action: String, underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .capabilityUnavailable(let name):
            return "\(name) capability is not available"
        case .stateInconsistency(let details):
            return "State inconsistency: \(details)"
        case .contextNotFound(let id):
            return "Context not found: \(id)"
        case .clientActionFailed(let action, let error):
            return "Action '\(action)' failed: \(error.localizedDescription)"
        }
    }
}
```

### 10. Navigation System

```swift
// Navigation parameters for type-safe data passing
protocol NavigationParams {
    // Base protocol for navigation data
}

// Navigation controller managed by Orchestrator
@MainActor
final class NavigationController: ObservableObject {
    @Published private(set) var navigationStacks: [String: NavigationStack] = [:]
    @Published private(set) var activeStackId: String?
    
    struct NavigationStack {
        let id: String
        let rootContext: any Context
        private(set) var contexts: [any Context]
        
        mutating func push(_ context: any Context) {
            contexts.append(context)
        }
        
        mutating func pop() -> (any Context)? {
            contexts.popLast()
        }
    }
    
    func push(_ context: any Context, onto parent: (any Context)?) {
        // Validate DAG constraints
        // Update navigation state
    }
}

// Navigation implementation in Orchestrator
extension Orchestrator {
    func navigate<T: Context>(
        to contextType: T.Type,
        from parent: (any Context)?,
        params: NavigationParams?
    ) async -> T {
        // 1. Create context through factory
        let context = createContext(contextType, parent: parent)
        
        // 2. Handle navigation lifecycle
        if let parent = parent {
            guard await parent.canNavigateAway() else {
                // Navigation cancelled
                return context
            }
            await parent.onNavigateAway()
        }
        
        // 3. Apply parameters and notify
        if let params = params {
            await context.applyNavigationParams(params)
        }
        await context.onNavigateTo()
        
        // 4. Update navigation state
        navigationController.push(context, onto: parent)
        
        return context
    }
}
```

### 11. Orchestrator as Application Entry Point

```swift
// SwiftUI App with Orchestrator as @main
@main
struct AxiomApp: App {
    @StateObject private var orchestrator = AppOrchestrator()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            orchestrator.rootView
                .onOpenURL { url in
                    Task { await orchestrator.handleDeepLink(url) }
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            Task { await orchestrator.handleScenePhaseChange(newPhase) }
        }
    }
}

// Concrete Orchestrator implementation
@MainActor
final class AppOrchestrator: Orchestrator {
    @Published private(set) var rootContexts: [any Context] = []
    @Published private(set) var scenePhase: ScenePhase = .active
    @Published private(set) var rootView: AnyView = AnyView(ProgressView())
    
    let capabilityRegistry = CapabilityRegistry()
    let navigationController = NavigationController()
    
    init() {
        Task { await bootstrap() }
    }
    
    private func bootstrap() async {
        // 1. Initialize capabilities
        capabilityRegistry.register(NetworkCapability())
        capabilityRegistry.register(StorageCapability())
        
        // 2. Create root navigation context
        let rootNav = createContext(RootNavigationContext.self, parent: nil)
        rootContexts = [rootNav]
        
        // 3. Set root view
        rootView = AnyView(RootNavigationView(context: rootNav))
    }
    
    func handleScenePhaseChange(_ phase: ScenePhase) async {
        scenePhase = phase
        
        // Notify all contexts through navigation hierarchy
        for stack in navigationController.navigationStacks.values {
            for context in stack.contexts {
                switch phase {
                case .active:
                    await context.onForeground()
                case .inactive:
                    await context.onInactive()
                case .background:
                    await context.onBackground()
                @unknown default:
                    break
                }
            }
        }
        
        // Update transient capabilities
        await capabilityRegistry.refreshAll()
    }
    
    func handleDeepLink(_ url: URL) async {
        // Route to appropriate context based on URL
        // Example: axiom://profile/123 -> ProfileContext
    }
}
```

### 12. Navigation Example

```swift
// Define navigation routes
enum AppRoute {
    case login
    case home
    case profile(userId: String)
    case settings
}

// Navigation parameters for profile
struct ProfileNavigationParams: NavigationParams {
    let userId: String
}

// Root navigation context
@MainActor
final class RootNavigationContext: Context {
    typealias Action = AppRoute
    
    let orchestrator: Orchestrator
    let contextId = UUID().uuidString
    @Published private(set) var currentRoute: AppRoute?
    
    func send(_ action: AppRoute) async {
        currentRoute = action
        
        switch action {
        case .login:
            await orchestrator.navigate(to: LoginContext.self, from: self, params: nil)
        case .home:
            await orchestrator.navigate(to: HomeContext.self, from: self, params: nil)
        case .profile(let userId):
            let params = ProfileNavigationParams(userId: userId)
            await orchestrator.navigate(to: ProfileContext.self, from: self, params: params)
        case .settings:
            await orchestrator.navigate(to: SettingsContext.self, from: self, params: nil)
        }
    }
    
    // Navigation lifecycle
    func canNavigateAway() async -> Bool { true }
    func onNavigateTo() async { }
    func onNavigateAway() async { }
}

// Context with navigation parameters
@MainActor
final class ProfileContext: Context {
    typealias Action = ProfileAction
    
    let orchestrator: Orchestrator
    let contextId = UUID().uuidString
    @Published private(set) var userId: String = ""
    @Published private(set) var hasUnsavedChanges = false
    
    private let profileClient: ProfileClient
    
    func applyNavigationParams(_ params: NavigationParams) async {
        if let profileParams = params as? ProfileNavigationParams {
            self.userId = profileParams.userId
            await loadProfile()
        }
    }
    
    func canNavigateAway() async -> Bool {
        if hasUnsavedChanges {
            // Show confirmation dialog
            return await showSaveChangesDialog()
        }
        return true
    }
    
    private func loadProfile() async {
        await send(.loadProfile(userId))
    }
}
```

## Rationale

### Design Decisions

1. **Seven Component Types**: Complete coverage of iOS architecture while maintaining simplicity
2. **Fifteen Constraints**: Minimum rules to ensure architectural integrity (9 dependency + 6 lifetime)
3. **Actor Isolation**: Leverages Swift concurrency for thread safety
4. **Singleton Clients**: Automatic state synchronization across views
5. **Transient Capabilities**: Ensures permissions are always current
6. **Integrated Navigation**: Type-safe navigation managed by Orchestrator
7. **Unified Lifecycle**: Single point of control for app and navigation lifecycle

### Benefits

1. **Clear Boundaries**: Each component has a single responsibility
2. **Thread Safety**: Actor isolation prevents race conditions
3. **Testability**: Unidirectional dependencies simplify testing
4. **Maintainability**: Consistent patterns throughout codebase
5. **Automatic Synchronization**: Singleton clients provide single source of truth
6. **Navigation Safety**: Type-safe navigation with lifecycle guarantees
7. **Central Control**: Orchestrator manages all app coordination from @main

## Non-Goals

This RFC does NOT define:
- Business logic patterns
- Database schemas
- Network protocols
- UI styling guidelines
- Localization strategies
- Analytics implementation

## Future Considerations

While the seven component types and fifteen constraints are immutable, future RFCs may address:
- Implementation patterns within constraints
- Performance optimization techniques
- Testing strategies
- Tooling support

## Appendix: Quick Reference

### Component Types
1. **Capability** - External system access (Transient)
2. **Owned State** - Domain models (Singleton)
3. **Stateful Client** - Domain logic with state (Singleton)
4. **Stateless Client** - Pure computation (Singleton)
5. **Orchestrator** - Application root (Singleton)
6. **Context** - Feature coordination (Multiple instances)
7. **Presentation** - SwiftUI views (Multiple instances)

### Constraints Summary
**Dependency (1-9)**: Client→Capability, Context→Client/Context, No cycles, Single ownership
**Lifetime (10-15)**: Views/Contexts (multiple), Clients/States/Orchestrator (singleton), Capabilities (transient)