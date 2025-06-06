# Framework Description Format

Framework architecture reference specification for application development guidance.

## Description Structure

### Metadata Header
```markdown
# Framework: [Name]

**Framework Name**: [Official name]  
**Version**: [Semantic version]  
**Updated**: YYYY-MM-DD  
**Status**: Stable | Beta | Experimental  
**Swift Version**: [Minimum supported]  
**Platform Requirements**: [iOS/macOS versions]  
**Core Philosophy**: [One-sentence framework principle]
```

### 1. Architecture Overview

## Architecture Overview

### Core Concepts
[2-3 paragraphs explaining the fundamental architecture]
[Paragraph 1: Overall pattern and design philosophy]
[Paragraph 2: Component relationships and data flow]
[Paragraph 3: Key benefits and trade-offs]

### Component Hierarchy
[Visual or textual representation of component relationships]
```
Domain Layer:
├── Client (Actor) → owns State
├── State (Immutable) → defines data model
└── Action (Enum) → mutations catalog

UI Layer:
├── Context (@MainActor) → observes Client
├── Presentation (View) → bound to Context
└── Orchestrator → manages Context lifecycle

Service Layer:
├── Capability → external service interface
└── Resource → shared system access
```

### 2. Component Specifications

## Component Specifications

### Client (Domain Actor)
**Purpose**: Encapsulates domain logic and state management
**Constraints**: 
- Actor-isolated for thread safety
- Single State type ownership
- Processes Actions asynchronously

**Implementation Pattern**:
```swift
actor [Name]Client: Client {
    typealias StateType = [Name]State
    typealias ActionType = [Name]Action
    
    private(set) var state: StateType
    var stateStream: AsyncStream<StateType>
    
    func process(_ action: ActionType) async throws {
        // State mutations here
    }
}
```

**Common Patterns**:
- State persistence through Capability
- Child Client composition
- Error recovery strategies

**Anti-patterns**:
- Direct state exposure
- Synchronous blocking operations
- Cross-actor state sharing

### State (Domain Model)
**Purpose**: Immutable data representation
**Constraints**:
- All properties must be let-declared
- Must conform to Equatable
- No business logic

**Implementation Pattern**:
```swift
struct [Name]State: State, Equatable {
    let property1: Type
    let property2: Type
    
    // Computed properties allowed for derivations
    var derivedValue: Type {
        // Pure computation only
    }
}
```

**Common Patterns**:
- Nested state for complex domains
- Codable for persistence
- Partial update helpers

**Anti-patterns**:
- Mutable properties
- Side effects in computed properties
- Reference type properties

### Context (UI Coordinator)
**Purpose**: Mediates between Client and Presentation
**Constraints**:
- @MainActor bound
- ObservableObject conformance
- Manages single Client instance

**Implementation Pattern**:
```swift
@MainActor
class [Name]Context: Context<[Name]Client> {
    @Published private(set) var viewState: ViewState
    
    override func observeClient() {
        Task {
            for await state in client.stateStream {
                self.viewState = mapToViewState(state)
            }
        }
    }
    
    func handleUserAction(_ action: UserAction) {
        Task {
            await client.process(mapToClientAction(action))
        }
    }
}
```

**Common Patterns**:
- View state transformation
- Error presentation
- Loading state management

**Anti-patterns**:
- Direct Client exposure to View
- Business logic in Context
- Multiple Client management

### Presentation (SwiftUI View)
**Purpose**: Renders UI based on Context state
**Constraints**:
- Stateless regarding domain data
- Actions through Context only
- SwiftUI best practices

**Implementation Pattern**:
```swift
struct [Name]View: View {
    @ObservedObject var context: [Name]Context
    
    var body: some View {
        // UI composition based on context.viewState
        // All actions via context methods
    }
}
```

**Common Patterns**:
- Extracted subviews
- Conditional rendering
- Animation integration

**Anti-patterns**:
- Direct Client access
- Business logic in View
- Complex state derivation

### Orchestrator (Navigation)
**Purpose**: Application-wide navigation and Context lifecycle
**Constraints**:
- @MainActor bound
- Single instance per app
- Owns navigation state

**Implementation Pattern**:
```swift
@MainActor
class AppOrchestrator: Orchestrator {
    private var contexts: [Route: AnyContext] = [:]
    
    func navigate(to route: Route) {
        // Create/reuse Context
        // Update navigation state
    }
    
    func createContext(for route: Route) -> AnyContext {
        // Context factory logic
    }
}
```

**Common Patterns**:
- Context caching
- Deep link handling
- Tab/stack navigation

**Anti-patterns**:
- Context memory leaks
- Circular navigation dependencies
- State persistence in Orchestrator

### Capability (External Services)
**Purpose**: Abstraction for external dependencies
**Constraints**:
- Protocol-based interface
- Mockable for testing
- Error handling required

**Implementation Pattern**:
```swift
protocol [Name]Capability {
    func performOperation() async throws -> Result
}

actor [Name]CapabilityImpl: [Name]Capability {
    // Thread-safe implementation
}
```

**Common Patterns**:
- Network service wrapping
- Database abstraction
- System service access

**Anti-patterns**:
- Concrete type dependencies
- Synchronous blocking calls
- Missing error handling

### 3. Data Flow Patterns

## Data Flow Patterns

### Unidirectional Flow
User Input → Presentation → Context → Client → State → Context → Presentation

### State Propagation Timing
- User action dispatch: Immediate
- Client processing: < 50ms for sync operations
- State stream emission: Immediate after mutation
- Context update: Next RunLoop cycle
- View refresh: Within 16ms of Context update

### Concurrency Model
- Clients: Actor-isolated, concurrent operations safe
- Contexts: MainActor-bound, sequential updates
- Capabilities: Actor or async based on needs
- Orchestrator: MainActor, manages Context lifecycle

### Error Propagation
1. Capability throws → Client catches and updates State
2. State includes error → Context maps to user message
3. Context presents → Presentation shows error UI
4. User dismisses → Context dispatches clear action

### 4. Common Implementation Patterns

## Common Implementation Patterns

### Client Composition
```swift
// Parent Client managing child Clients
actor ParentClient: Client {
    let childClient1: ChildClient1
    let childClient2: ChildClient2
    
    func process(_ action: ParentAction) async throws {
        switch action {
        case .delegateToChild1(let childAction):
            try await childClient1.process(childAction)
        case .coordinateChildren:
            // Coordinate multiple children
        }
    }
}
```

### State Aggregation
```swift
// Context combining multiple Client states
@MainActor
class AggregateContext: ObservableObject {
    @Published var combinedState: CombinedViewState
    
    let client1: Client1
    let client2: Client2
    
    func observeClients() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.observeClient1() }
                group.addTask { await self.observeClient2() }
            }
        }
    }
}
```

### Capability Injection
```swift
// Dependency injection pattern
actor ServiceClient: Client {
    private let networkCapability: NetworkCapability
    private let cacheCapability: CacheCapability
    
    init(
        network: NetworkCapability = NetworkCapabilityImpl(),
        cache: CacheCapability = CacheCapabilityImpl()
    ) {
        self.networkCapability = network
        self.cacheCapability = cache
    }
}
```

### Navigation Patterns
```swift
// Type-safe navigation
enum AppRoute {
    case home
    case detail(id: String)
    case settings(section: SettingsSection?)
}

// Context-mediated navigation
class HomeContext: Context<HomeClient> {
    weak var orchestrator: AppOrchestrator?
    
    func navigateToDetail(id: String) {
        orchestrator?.navigate(to: .detail(id: id))
    }
}
```

### 5. Testing Guidelines

## Testing Guidelines

### Client Testing
**Focus**: State mutations and action processing
**Approach**: 
- Test each action produces expected state
- Verify AsyncStream emissions
- Test error scenarios
- Validate concurrency safety

**Example Pattern**:
```swift
func testClientAction() async throws {
    let client = TestClient()
    var states: [TestState] = []
    
    Task {
        for await state in client.stateStream {
            states.append(state)
        }
    }
    
    try await client.process(.testAction)
    
    XCTAssertEqual(states.last, expectedState)
}
```

### Context Testing
**Focus**: Client observation and view state mapping
**Approach**:
- Mock Client with controlled state stream
- Verify view state transformations
- Test error presentation
- Validate lifecycle management

### Integration Testing
**Focus**: Component interaction and data flow
**Approach**:
- Test full stack from Presentation to Client
- Verify navigation flows
- Test Capability integration
- Measure performance requirements

### 6. Performance Considerations

## Performance Considerations

### State Design
- Keep State structs small (< 1KB)
- Use computed properties for derivations
- Avoid deep nesting (max 3 levels)
- Consider pagination for lists

### Update Optimization
- Batch related state changes
- Use Equatable to prevent unnecessary updates
- Implement custom equality for complex types
- Profile state propagation paths

### Memory Management
- Contexts released on navigation
- Weak Orchestrator references
- Client cleanup on deallocation
- Capability resource management

### Concurrency
- Leverage actor isolation
- Avoid blocking operations
- Use TaskGroup for parallel work
- Cancel tasks on Context deallocation

### 7. Migration & Evolution

## Migration & Evolution

### Version Compatibility
- Framework version: [Current version]
- Breaking changes: [Last breaking version]
- Deprecation policy: [Timeline and process]
- Migration tools: [Available helpers]

### Extension Points
- Custom Client protocols
- State middleware support
- Context decorators
- Capability adapters

### Future Roadmap
- [Feature 1]: [Target version]
- [Feature 2]: [Target version]
- [Optimization 1]: [Expected impact]

## Key Principles

1. **Architecture First**: Components follow strict architectural boundaries
2. **Type Safety**: Leverage Swift's type system throughout
3. **Testability**: Every component independently testable
4. **Performance**: Meet UI responsiveness requirements
5. **Maintainability**: Clear patterns reduce complexity

---

**This format serves as the authoritative reference for framework architecture and implementation patterns.**