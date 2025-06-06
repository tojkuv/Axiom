# Framework: Axiom

**Framework Name**: Axiom Framework  
**Version**: 0.1.0  
**Updated**: 2025-01-06  
**Status**: Beta  
**Swift Version**: 5.9+  
**Platform Requirements**: iOS 16.0+, macOS 13.0+  
**Core Philosophy**: Strict architectural constraints enable predictable, testable iOS applications

## Architecture Overview

### Core Concepts

The Axiom framework enforces a strict unidirectional data flow architecture through six immutable component types. Each component has clearly defined responsibilities and dependency rules that are validated at compile-time and runtime. The architecture leverages Swift's actor model for thread safety and SwiftUI for reactive UI updates.

Components are organized in a hierarchical structure where dependencies flow strictly downward: Orchestrator → Context → Client → Capability → System. This prevents circular dependencies and ensures predictable state management. The framework enforces single ownership of state, 1:1 presentation-context binding, and actor-isolated state mutations.

Key architectural benefits include elimination of race conditions through actor isolation, prevention of memory leaks via clear ownership rules, and guaranteed UI responsiveness through performance constraints. The strict constraints may initially feel restrictive but ultimately reduce complexity and enable confident refactoring.

### Component Hierarchy

```
Application Layer:
└── Orchestrator (Actor) → manages application lifecycle
    ├── NavigationService → handles route transitions
    └── ContextBuilder → creates contexts with dependencies

UI Layer:
├── Presentation (View) → bound to single Context
└── Context (@MainActor) → mediates Client and UI
    ├── observes Client state stream
    └── dispatches actions to Client

Domain Layer:
├── Client (Actor) → owns State, processes Actions
├── State (Immutable) → value type data model
└── Action (Enum) → state mutation commands

Service Layer:
└── Capability (Actor) → external service interface
    ├── available/unavailable states
    └── lifecycle management
```

## Component Specifications

### Client (Domain Actor)
**Purpose**: Encapsulates domain logic and state management
**Constraints**: 
- Actor-isolated for thread safety
- Single State type ownership
- Processes Actions asynchronously
- Cannot communicate with other Clients directly

**Implementation Pattern**:
```swift
actor TodoClient: Client {
    typealias StateType = TodoState
    typealias ActionType = TodoAction
    
    private(set) var state: TodoState
    private var streamContinuations: [UUID: AsyncStream<TodoState>.Continuation] = [:]
    
    var stateStream: AsyncStream<TodoState> {
        AsyncStream { [weak self] continuation in
            let id = UUID()
            Task { [weak self] in
                await self?.addContinuation(continuation, id: id)
                if let currentState = await self?.state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    init(initialState: TodoState = TodoState()) {
        self.state = initialState
    }
    
    func process(_ action: TodoAction) async throws {
        switch action {
        case .addItem(let title):
            state = state.withNewItem(TodoItem(title: title))
        case .toggleItem(let id):
            state = state.toggleItem(id: id)
        case .deleteItem(let id):
            state = state.withoutItem(id: id)
        }
        notifyObservers()
    }
    
    private func notifyObservers() {
        for (_, continuation) in streamContinuations {
            continuation.yield(state)
        }
    }
}
```

**Common Patterns**:
- State persistence through Capability
- Child Client composition for complex domains
- Error recovery through state updates

**Anti-patterns**:
- Direct state exposure (`var state` instead of `private(set) var`)
- Synchronous blocking operations in `process()`
- Cross-actor state sharing between Clients

### State (Domain Model)
**Purpose**: Immutable data representation
**Constraints**:
- All properties must be let-declared
- Must conform to Equatable
- No business logic (pure data)
- Value type (struct) only

**Implementation Pattern**:
```swift
struct TodoState: State, Equatable {
    let items: [TodoItem]
    let filter: FilterMode
    let lastError: String?
    
    // Computed properties for derived state
    var activeItems: [TodoItem] {
        items.filter { !$0.isCompleted }
    }
    
    var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }
    
    // Immutable update methods
    func withNewItem(_ item: TodoItem) -> TodoState {
        TodoState(
            items: items + [item],
            filter: filter,
            lastError: nil
        )
    }
    
    func toggleItem(id: UUID) -> TodoState {
        TodoState(
            items: items.map { item in
                item.id == id ? item.toggled() : item
            },
            filter: filter,
            lastError: lastError
        )
    }
    
    func withoutItem(id: UUID) -> TodoState {
        TodoState(
            items: items.filter { $0.id != id },
            filter: filter,
            lastError: lastError
        )
    }
}

struct TodoItem: Equatable, Identifiable {
    let id: UUID
    let title: String
    let isCompleted: Bool
    let createdAt: Date
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
    }
    
    func toggled() -> TodoItem {
        TodoItem(
            id: id,
            title: title,
            isCompleted: !isCompleted,
            createdAt: createdAt
        )
    }
}
```

**Common Patterns**:
- Nested state for complex domains
- Codable conformance for persistence
- Builder methods for complex updates

**Anti-patterns**:
- Mutable properties (`var` instead of `let`)
- Side effects in computed properties
- Reference type properties (classes)

### Context (UI Coordinator)
**Purpose**: Mediates between Client and Presentation
**Constraints**:
- @MainActor bound
- ObservableObject conformance
- Manages single Client instance
- Handles lifecycle events

**Implementation Pattern**:
```swift
@MainActor
class TodoContext: ClientObservingContext<TodoClient> {
    @Published private(set) var items: [TodoItemViewModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let persistenceCapability: PersistenceCapability
    
    init(client: TodoClient, persistence: PersistenceCapability) {
        self.persistenceCapability = persistence
        super.init(client: client)
    }
    
    override func handleStateUpdate(_ state: TodoState) async {
        // Map domain state to view models
        self.items = state.items.map { item in
            TodoItemViewModel(
                id: item.id,
                title: item.title,
                isCompleted: item.isCompleted
            )
        }
        self.errorMessage = state.lastError
    }
    
    // User action handlers
    func addItem(title: String) {
        guard !title.isEmpty else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            
            try? await client.process(.addItem(title: title))
        }
    }
    
    func toggleItem(_ id: UUID) {
        Task {
            try? await client.process(.toggleItem(id: id))
        }
    }
    
    func deleteItem(_ id: UUID) {
        Task {
            try? await client.process(.deleteItem(id: id))
        }
    }
    
    // Lifecycle
    override func performAppearance() async {
        await super.performAppearance()
        // Load persisted data
        if let data = try? await persistenceCapability.load() {
            try? await client.process(.loadData(data))
        }
    }
}

// View-specific models
struct TodoItemViewModel: Identifiable {
    let id: UUID
    let title: String
    let isCompleted: Bool
}
```

**Common Patterns**:
- View state transformation
- Error presentation
- Loading state management
- Navigation coordination

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
- Single Context binding

**Implementation Pattern**:
```swift
struct TodoListView: View {
    @ObservedObject var context: TodoContext
    @State private var newItemTitle = ""
    @State private var showingDeleteConfirmation = false
    @State private var itemToDelete: UUID?
    
    var body: some View {
        NavigationView {
            VStack {
                // Add item input
                HStack {
                    TextField("New item", text: $newItemTitle)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Add") {
                        context.addItem(title: newItemTitle)
                        newItemTitle = ""
                    }
                    .disabled(newItemTitle.isEmpty)
                }
                .padding()
                
                // Items list
                if context.items.isEmpty {
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "checklist",
                        description: Text("Add your first todo item")
                    )
                } else {
                    List {
                        ForEach(context.items) { item in
                            TodoItemRow(
                                item: item,
                                onToggle: { context.toggleItem(item.id) },
                                onDelete: {
                                    itemToDelete = item.id
                                    showingDeleteConfirmation = true
                                }
                            )
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Todo List")
            .overlay {
                if context.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.regularMaterial)
                }
            }
            .alert("Delete Item?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let id = itemToDelete {
                        context.deleteItem(id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Error", isPresented: .constant(context.errorMessage != nil)) {
                Button("OK") {
                    // Context will clear error
                }
            } message: {
                Text(context.errorMessage ?? "")
            }
        }
        .task {
            await context.onAppear()
        }
    }
}

struct TodoItemRow: View {
    let item: TodoItemViewModel
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            Text(item.title)
                .strikethrough(item.isCompleted)
                .foregroundColor(item.isCompleted ? .gray : .primary)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
```

**Common Patterns**:
- Extracted subviews for reusability
- Conditional rendering based on state
- Animation integration
- @State for UI-only state

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
- Creates Contexts with dependencies

**Implementation Pattern**:
```swift
actor AppOrchestrator: ExtendedOrchestrator, NavigationService {
    // Navigation state
    private(set) var currentRoute: Route?
    private(set) var navigationHistory: [Route] = []
    private var routeHandlers: [Route: (Route) async -> any Context] = [:]
    
    // Dependency management
    private var contexts: [String: any Context] = [:]
    private var clients: [String: any Client] = [:]
    private var capabilities: [String: any Capability] = [:]
    
    init() {
        Task {
            await setupRoutes()
            await registerCapabilities()
        }
    }
    
    // Route setup
    private func setupRoutes() async {
        await registerRoute(.home) { _ in
            let client = TodoClient()
            let persistence = await self.capability(
                for: "persistence",
                as: PersistenceCapability.self
            )!
            return await TodoContext(client: client, persistence: persistence)
        }
        
        await registerRoute(.settings) { _ in
            let client = SettingsClient()
            return await SettingsContext(client: client)
        }
    }
    
    // Navigation
    func navigate(to route: Route) async {
        // Validate route
        guard await canNavigate(to: route) else { return }
        
        // Update history
        if let current = currentRoute {
            navigationHistory.append(current)
        }
        
        // Execute handler
        if let handler = routeHandlers[route] {
            let context = await handler(route)
            contexts[route.identifier] = context
        }
        
        currentRoute = route
    }
    
    func navigateBack() async {
        guard !navigationHistory.isEmpty else { return }
        let previous = navigationHistory.removeLast()
        await navigate(to: previous)
    }
    
    // Context creation
    func createContext<P: Presentation>(
        for presentation: P.Type
    ) async -> P.ContextType {
        // Type-based context creation
        switch presentation {
        case is TodoListView.Type:
            return await createTodoContext() as! P.ContextType
        case is SettingsView.Type:
            return await createSettingsContext() as! P.ContextType
        default:
            fatalError("Unknown presentation type")
        }
    }
    
    // Capability registration
    private func registerCapabilities() async {
        let persistence = PersistenceCapabilityImpl()
        await registerCapability(persistence, for: "persistence")
        try? await persistence.initialize()
        
        let network = NetworkCapabilityImpl()
        await registerCapability(network, for: "network")
        try? await network.initialize()
    }
}

// Route definitions
@frozen
enum Route: Hashable, Sendable {
    case home
    case detail(id: String)
    case settings
    case custom(path: String)
    
    var identifier: String {
        switch self {
        case .home: return "home"
        case .detail(let id): return "detail-\(id)"
        case .settings: return "settings"
        case .custom(let path): return "custom-\(path)"
        }
    }
}
```

**Common Patterns**:
- Context caching for performance
- Deep link handling
- Tab/stack navigation patterns
- Capability lifecycle management

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
- Actor-isolated for thread safety

**Implementation Pattern**:
```swift
protocol PersistenceCapability: Capability {
    func save(_ data: Data) async throws
    func load() async throws -> Data?
    func delete() async throws
}

actor PersistenceCapabilityImpl: PersistenceCapability {
    private let fileURL: URL
    private var state: CapabilityState = .unknown
    
    init() {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        self.fileURL = documentsPath.appendingPathComponent("todos.json")
    }
    
    var isAvailable: Bool {
        state == .available
    }
    
    func initialize() async throws {
        // Check file system availability
        let fileManager = FileManager.default
        let directory = fileURL.deletingLastPathComponent()
        
        if !fileManager.fileExists(atPath: directory.path) {
            state = .unavailable
            throw CapabilityError.initializationFailed(
                reason: "Documents directory not accessible"
            )
        }
        
        state = .available
    }
    
    func terminate() async {
        state = .unavailable
    }
    
    func save(_ data: Data) async throws {
        guard isAvailable else {
            throw CapabilityError.notAvailable
        }
        
        try data.write(to: fileURL)
    }
    
    func load() async throws -> Data? {
        guard isAvailable else {
            throw CapabilityError.notAvailable
        }
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        return try Data(contentsOf: fileURL)
    }
    
    func delete() async throws {
        guard isAvailable else {
            throw CapabilityError.notAvailable
        }
        
        try FileManager.default.removeItem(at: fileURL)
    }
}

// Network capability example
protocol NetworkCapability: Capability {
    func request<T: Decodable>(
        _ endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> T
}

actor NetworkCapabilityImpl: NetworkCapability {
    private var state: CapabilityState = .unknown
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    var isAvailable: Bool {
        state == .available
    }
    
    func initialize() async throws {
        // Check network connectivity
        // In production, use NWPathMonitor
        state = .available
    }
    
    func terminate() async {
        state = .unavailable
    }
    
    func request<T: Decodable>(
        _ endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> T {
        guard isAvailable else {
            throw CapabilityError.notAvailable
        }
        
        let (data, response) = try await session.data(from: endpoint.url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

**Common Patterns**:
- Network service wrapping
- Database abstraction
- System service access
- Mock implementations for testing

**Anti-patterns**:
- Concrete type dependencies
- Synchronous blocking calls
- Missing error handling

## Data Flow Patterns

### Unidirectional Flow
```
User Input → Presentation → Context → Client → State → Context → Presentation
```

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
- Orchestrator: Actor-isolated, manages Context lifecycle

### Error Propagation
1. Capability throws → Client catches and updates State
2. State includes error → Context maps to user message
3. Context presents → Presentation shows error UI
4. User dismisses → Context dispatches clear action

## Common Implementation Patterns

### Client Composition
```swift
// Parent Client managing child Clients
actor ShoppingCartClient: Client {
    let catalogClient: CatalogClient
    let pricingClient: PricingClient
    let inventoryClient: InventoryClient
    
    func process(_ action: CartAction) async throws {
        switch action {
        case .addItem(let productId):
            // Coordinate multiple clients
            async let product = catalogClient.getProduct(productId)
            async let price = pricingClient.getPrice(productId)
            async let availability = inventoryClient.checkStock(productId)
            
            let (productInfo, currentPrice, isAvailable) = try await (product, price, availability)
            
            if isAvailable {
                state = state.withItem(CartItem(
                    product: productInfo,
                    price: currentPrice,
                    quantity: 1
                ))
            }
            
        case .updateQuantity(let itemId, let quantity):
            // Delegate to child
            let available = try await inventoryClient.checkStock(itemId, quantity: quantity)
            if available {
                state = state.updateQuantity(itemId: itemId, quantity: quantity)
            }
        }
    }
}
```

### State Aggregation
```swift
// Context combining multiple Client states
@MainActor
class DashboardContext: ObservableObject {
    @Published var stats: DashboardStats
    @Published var recentActivity: [Activity]
    @Published var notifications: [Notification]
    
    let statsClient: StatsClient
    let activityClient: ActivityClient
    let notificationClient: NotificationClient
    
    func observeClients() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.observeStats() }
                group.addTask { await self.observeActivity() }
                group.addTask { await self.observeNotifications() }
            }
        }
    }
    
    private func observeStats() async {
        for await state in await statsClient.stateStream {
            self.stats = DashboardStats(from: state)
        }
    }
}
```

### Capability Injection
```swift
// Dependency injection pattern
actor UserClient: Client {
    private let authCapability: AuthenticationCapability
    private let storageCapability: StorageCapability
    private let analyticsCapability: AnalyticsCapability?
    
    init(
        auth: AuthenticationCapability,
        storage: StorageCapability,
        analytics: AnalyticsCapability? = nil
    ) {
        self.authCapability = auth
        self.storageCapability = storage
        self.analyticsCapability = analytics
    }
    
    func process(_ action: UserAction) async throws {
        switch action {
        case .login(let credentials):
            let token = try await authCapability.authenticate(credentials)
            let profile = try await authCapability.fetchProfile(token)
            
            state = state.authenticated(profile: profile, token: token)
            
            // Optional capability usage
            await analyticsCapability?.track(.userLoggedIn(userId: profile.id))
        }
    }
}
```

### Navigation Patterns
```swift
// Type-safe navigation with deep linking
extension AppOrchestrator {
    func handleDeepLink(_ url: URL) async {
        guard let route = parseRoute(from: url) else { return }
        
        switch route {
        case .detail(let id):
            // Navigate to detail with proper context setup
            await navigate(to: .home) // Ensure base context exists
            await navigate(to: .detail(id: id))
            
        case .settings:
            await navigate(to: .settings)
            
        default:
            await navigate(to: .home)
        }
    }
    
    private func parseRoute(from url: URL) -> Route? {
        // URL parsing logic
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        switch components.path {
        case "/item":
            if let id = components.queryItems?.first(where: { $0.name == "id" })?.value {
                return .detail(id: id)
            }
        case "/settings":
            return .settings
        default:
            return nil
        }
        
        return nil
    }
}
```

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
func testAddItemAction() async throws {
    // Given
    let client = TodoClient()
    var states: [TodoState] = []
    
    let observation = Task {
        for await state in client.stateStream {
            states.append(state)
        }
    }
    
    // When
    try await client.process(.addItem(title: "Test Item"))
    
    // Then
    try await Task.sleep(for: .milliseconds(10))
    observation.cancel()
    
    XCTAssertEqual(states.count, 2) // Initial + update
    XCTAssertEqual(states.last?.items.count, 1)
    XCTAssertEqual(states.last?.items.first?.title, "Test Item")
}

func testConcurrentActions() async throws {
    // Given
    let client = CounterClient()
    
    // When - 100 concurrent increments
    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<100 {
            group.addTask {
                try? await client.process(.increment)
            }
        }
    }
    
    // Then
    let finalState = await client.currentState
    XCTAssertEqual(finalState.count, 100)
}
```

### Context Testing
**Focus**: Client observation and view state mapping
**Approach**:
- Mock Client with controlled state stream
- Verify view state transformations
- Test error presentation
- Validate lifecycle management

```swift
func testContextStateMapping() async throws {
    // Given
    let mockClient = MockTodoClient()
    let context = TodoContext(client: mockClient)
    
    // When
    await mockClient.setState(TodoState(
        items: [TodoItem(title: "Test")],
        filter: .all,
        lastError: nil
    ))
    
    // Then
    try await Task.sleep(for: .milliseconds(10))
    XCTAssertEqual(context.items.count, 1)
    XCTAssertEqual(context.items.first?.title, "Test")
}
```

### Integration Testing
**Focus**: Component interaction and data flow
**Approach**:
- Test full stack from Presentation to Client
- Verify navigation flows
- Test Capability integration
- Measure performance requirements

```swift
func testFullStackFlow() async throws {
    // Given
    let orchestrator = TestOrchestrator()
    let context = await orchestrator.createContext(for: TodoListView.self)
    
    // When
    context.addItem(title: "Integration Test")
    try await Task.sleep(for: .milliseconds(50))
    
    // Then
    XCTAssertEqual(context.items.count, 1)
    XCTAssertLessThan(measureTime { context.items }, .milliseconds(16))
}
```

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

## Migration & Evolution

### Version Compatibility
- Framework version: 0.1.0
- Breaking changes: None yet (pre-1.0)
- Deprecation policy: 2 minor versions notice
- Migration tools: Coming in 1.0

### Extension Points
- Custom Client protocols via protocol extensions
- State middleware support (planned)
- Context decorators for cross-cutting concerns
- Capability adapters for third-party SDKs

### Future Roadmap
- SwiftData integration: v0.2.0
- Macro-based code generation: v0.3.0
- Performance profiling tools: v0.4.0
- Production readiness: v1.0.0

## Key Principles

1. **Architecture First**: Components follow strict architectural boundaries
2. **Type Safety**: Leverage Swift's type system throughout
3. **Testability**: Every component independently testable
4. **Performance**: Meet UI responsiveness requirements
5. **Maintainability**: Clear patterns reduce complexity

---

**This format serves as the authoritative reference for framework architecture and implementation patterns.**