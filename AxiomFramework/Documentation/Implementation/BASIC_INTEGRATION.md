# Basic Integration Guide

Comprehensive developer onboarding guide for integrating the Axiom framework into iOS applications.

## Quick Start

Get started with Axiom in under 10 minutes by following this step-by-step integration guide.

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later

## Installation

### Swift Package Manager

Add Axiom to your project using Swift Package Manager:

1. Open your Xcode project
2. Select File → Add Package Dependencies
3. Enter the repository URL: `https://github.com/your-org/Axiom`
4. Select the version range and add to your target

### Package.swift

For Swift packages, add Axiom as a dependency:

```swift
// Package.swift
import PackageDescription

let package = Package(
    name: "YourPackage",
    dependencies: [
        .package(url: "https://github.com/your-org/Axiom", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: ["Axiom"]
        )
    ]
)
```

## First Steps

### 1. Import the Framework

```swift
import Axiom
import SwiftUI

// Basic setup for your app
struct ContentView: View {
    var body: some View {
        Text("Hello, Axiom!")
    }
}
```

### 2. Create Your First Domain Model

```swift
// Define your application state as a value object
struct UserState {
    var name: String = ""
    var email: String = ""
    var isLoggedIn: Bool = false
    var preferences: UserPreferences = UserPreferences()
}

struct UserPreferences {
    var theme: String = "light"
    var notifications: Bool = true
}
```

### 3. Generate Actor-based Client

```swift
// Use @Client macro for automatic actor generation
@Client
struct UserState {
    var name: String = ""
    var email: String = ""
    var isLoggedIn: Bool = false
}

// Generated: UserClient actor with thread-safe state management
```

### 4. Create Context for Orchestration

```swift
// Use @Context macro for automatic context generation
@Context(client: UserClient)
class UserContext {
    // Additional custom methods can be added here
    
    func login(username: String, password: String) async {
        // Orchestrate login process
        await client.updateState { state in
            state.name = username
            state.isLoggedIn = true
        }
    }
}
```

### 5. Build SwiftUI View

```swift
// Use @View macro for automatic view generation
@View(context: UserContext)
struct UserView {
    var body: some View {
        VStack {
            if context.bind(\.isLoggedIn).wrappedValue {
                Text("Welcome, \(context.bind(\.name).wrappedValue)!")
                Button("Logout") {
                    Task {
                        await context.client.updateState { state in
                            state.isLoggedIn = false
                            state.name = ""
                        }
                    }
                }
            } else {
                LoginView(context: context)
            }
        }
    }
}
```

## Hello World Example

Complete minimal example demonstrating Axiom integration:

```swift
import Axiom
import SwiftUI

// Example: Complete Axiom application setup
@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Domain model
@Client
struct AppState {
    var message: String = "Hello, World!"
    var count: Int = 0
}

// Context orchestration
@Context(client: AppClient)
class AppContext {
    func incrementCounter() async {
        await client.updateState { state in
            state.count += 1
            state.message = "Count: \(state.count)"
        }
    }
}

// SwiftUI view
@View(context: AppContext)
struct ContentView {
    var body: some View {
        VStack(spacing: 20) {
            Text(context.bind(\.message).wrappedValue)
                .font(.title)
            
            Button("Increment") {
                Task {
                    await context.incrementCounter()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

## Basic Usage Example

### Manual Implementation (Without Macros)

If you prefer manual implementation or need custom behavior:

```swift
// Manual actor implementation
actor UserClient: AxiomClient {
    typealias State = UserState
    
    private(set) var stateSnapshot = UserState()
    let capabilities: CapabilityManager
    
    init(capabilities: CapabilityManager) {
        self.capabilities = capabilities
    }
    
    func updateState(_ update: @Sendable (inout State) -> Void) async {
        update(&stateSnapshot)
        await notifyStateChange()
    }
    
    private func notifyStateChange() async {
        // Notify observers of state changes
    }
    
    // Custom business logic
    func login(username: String, password: String) async throws {
        // Validate credentials through capability system
        guard await capabilities.validate(AuthenticationCapability.self) else {
            throw UserError.authenticationUnavailable
        }
        
        // Execute login
        let result = try await capabilities.execute(
            AuthenticationCapability.self,
            with: LoginRequest(username: username, password: password)
        )
        
        // Update state
        await updateState { state in
            state.name = result.username
            state.isLoggedIn = true
        }
    }
}

// Manual context implementation
@MainActor
class UserContext: AxiomContext, ObservableObject {
    let client: UserClient
    let analyzer: FrameworkAnalyzer
    let performanceMonitor: PerformanceMonitor
    
    init(client: UserClient, analyzer: FrameworkAnalyzer, performanceMonitor: PerformanceMonitor) {
        self.client = client
        self.analyzer = analyzer
        self.performanceMonitor = performanceMonitor
        
        // Register for component analysis
        analyzer.registerComponent(self)
        analyzer.startMonitoring(self)
    }
    
    func bind<T>(_ keyPath: KeyPath<UserClient.State, T>) -> Binding<T> {
        return Binding(
            get: { [weak self] in
                guard let self = self else { return T.self as! T }
                return self.client.stateSnapshot[keyPath: keyPath]
            },
            set: { [weak self] newValue in
                guard let self = self else { return }
                Task {
                    await self.client.updateState { state in
                        state[keyPath: keyPath as! WritableKeyPath<UserClient.State, T>] = newValue
                    }
                }
            }
        )
    }
}

// Manual view implementation
struct UserView: AxiomView {
    @ObservedObject var context: UserContext
    
    var body: some View {
        VStack {
            Text("User: \(context.bind(\.name).wrappedValue)")
            Toggle("Logged In", isOn: context.bind(\.isLoggedIn))
        }
    }
    
    func handleStateChange() {
        // Handle reactive state updates
    }
    
    func validateArchitecturalConstraints() -> Bool {
        // Validate 1:1 view-context relationship
        return true
    }
}
```

## Advanced Patterns

### Capability Integration

```swift
// Add capabilities to your client
@Client
@Capabilities([.network, .storage, .analytics])
struct UserState {
    var name: String = ""
    var email: String = ""
}

// Use capabilities in your context
@Context(client: UserClient)
class UserContext {
    func saveUserData() async {
        // Capability validation with graceful degradation
        if await client.capabilities.validate(StorageCapability.self) {
            // Full functionality
            try await client.capabilities.execute(StorageCapability.self, with: userData)
        } else {
            // Fallback mechanism
            await storeInMemory(userData)
        }
    }
}
```

### Analysis Integration

```swift
// Add analysis features to your context
@Context(client: UserClient)
@Analysis(features: ["component_analysis", "performance_monitoring"])
class UserContext {
    func analyzeUserBehavior() async {
        let patterns = await analyzer.detectPatterns()
        let performance = await analyzer.collectPerformanceMetrics()
        
        // Use insights for optimization
        if performance.averageResponseTime > 100 {
            await optimizeUserFlow()
        }
    }
}
```

### Multi-Client Orchestration

```swift
// Orchestrate multiple clients through context
@MainActor
class ApplicationContext: AxiomContext {
    let userClient: UserClient
    let orderClient: OrderClient
    let analyticsClient: AnalyticsClient
    
    // Cross-domain coordination
    func processOrder(_ order: Order) async {
        await orderClient.createOrder(order)
        await userClient.recordOrderHistory(order.id)
        await analyticsClient.trackOrderCreation(order)
    }
}
```

## Migration

### From Traditional MVC

If migrating from traditional MVC architecture:

1. **Models → Domain Models**: Convert model classes to value objects
2. **Controllers → Contexts**: Transform view controllers to context classes
3. **Views → AxiomViews**: Update views to use context binding
4. **State Management → Actors**: Move state to actor-based clients

### From Other Frameworks

#### From Redux/TCA

```swift
// TCA Store → Axiom Client
// TCA State → Domain Model
// TCA Actions → Client methods
// TCA Reducers → updateState closures
// TCA Effects → Capability system

// Before (TCA)
struct AppState {
    var count = 0
}

enum AppAction {
    case increment
    case decrement
}

let appReducer = Reducer<AppState, AppAction, Void> { state, action, _ in
    switch action {
    case .increment:
        state.count += 1
        return .none
    case .decrement:
        state.count -= 1
        return .none
    }
}

// After (Axiom)
@Client
struct AppState {
    var count = 0
}

// Methods replace actions/reducers
extension AppClient {
    func increment() async {
        await updateState { state in
            state.count += 1
        }
    }
    
    func decrement() async {
        await updateState { state in
            state.count -= 1
        }
    }
}
```

#### From Combine/ObservableObject

```swift
// Before (Combine)
class UserViewModel: ObservableObject {
    @Published var name = ""
    @Published var isLoggedIn = false
    
    func login() {
        // Manual state updates
        name = "User"
        isLoggedIn = true
    }
}

// After (Axiom)
@Client
struct UserState {
    var name = ""
    var isLoggedIn = false
}

@Context(client: UserClient)
class UserContext {
    func login() async {
        await client.updateState { state in
            state.name = "User"
            state.isLoggedIn = true
        }
    }
}
```

## Common Patterns

### Loading States

```swift
@Client
struct DataState {
    var items: [Item] = []
    var isLoading: Bool = false
    var error: DataError? = nil
}

@Context(client: DataClient)
class DataContext {
    func loadData() async {
        await client.updateState { state in
            state.isLoading = true
            state.error = nil
        }
        
        do {
            let items = try await dataService.fetchItems()
            await client.updateState { state in
                state.items = items
                state.isLoading = false
            }
        } catch {
            await client.updateState { state in
                state.error = DataError.fetchFailed(error)
                state.isLoading = false
            }
        }
    }
}
```

### Form Handling

```swift
@Client
struct FormState {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var isValid: Bool = false
}

@Context(client: FormClient)
class FormContext {
    func validateForm() async {
        await client.updateState { state in
            state.isValid = !state.firstName.isEmpty && 
                           !state.lastName.isEmpty && 
                           state.email.contains("@")
        }
    }
    
    func submitForm() async {
        guard client.stateSnapshot.isValid else { return }
        
        let formData = FormData(
            firstName: client.stateSnapshot.firstName,
            lastName: client.stateSnapshot.lastName,
            email: client.stateSnapshot.email
        )
        
        // Submit through capability system
        try await client.capabilities.execute(FormSubmissionCapability.self, with: formData)
    }
}
```

### Navigation State

```swift
@Client
struct NavigationState {
    var currentTab: Tab = .home
    var navigationPath: [Route] = []
    var presentedSheet: Sheet? = nil
}

@Context(client: NavigationClient)
class NavigationContext {
    func navigate(to route: Route) async {
        await client.updateState { state in
            state.navigationPath.append(route)
        }
    }
    
    func presentSheet(_ sheet: Sheet) async {
        await client.updateState { state in
            state.presentedSheet = sheet
        }
    }
}
```

## Best Practices

### State Design

1. **Use Value Objects**: Always design state as immutable value objects
2. **Single Responsibility**: Each client should manage one domain area
3. **Minimal State**: Store only essential state, derive computed properties
4. **Avoid Optionals**: Use default values instead of optionals when possible

### Performance

1. **Batch Updates**: Group related state changes in single `updateState` call
2. **Selective Binding**: Bind to specific properties, not entire state
3. **Lazy Loading**: Load data on-demand through capabilities
4. **Monitor Performance**: Use built-in performance monitoring

### Testing

1. **Test State Logic**: Unit test client state mutations
2. **Mock Capabilities**: Use mock capability managers for testing
3. **Integration Tests**: Test complete view-context-client flow
4. **Performance Tests**: Validate performance characteristics

## Troubleshooting

### Common Issues

**Compilation Errors**:
- Ensure all required imports are present
- Verify macro syntax and parameters
- Check architectural constraint compliance

**Runtime Issues**:
- Validate capability availability before usage
- Ensure proper async/await usage
- Check for memory leaks in binding chains

**Performance Issues**:
- Monitor state update frequency
- Check for excessive view re-renders
- Validate capability cache configuration

### Getting Help

- Review framework documentation in `Documentation/`
- Check example implementations in test application
- Validate architectural constraints through analysis system
- Use performance monitoring for optimization insights

---

**Basic Integration Guide** - Complete developer onboarding for iOS architectural framework with component analysis capabilities