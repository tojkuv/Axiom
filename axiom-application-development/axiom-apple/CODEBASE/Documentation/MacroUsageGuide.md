# Axiom Macros Usage Guide

## Overview

The Axiom framework provides a comprehensive set of Swift macros that dramatically reduce boilerplate code and ensure consistent patterns across your application. This guide demonstrates best practices for using all available macros.

## Available Macros

### Core Framework Macros

1. **@AxiomState** - Automatic state protocol conformance
2. **@AxiomAction** - Action pattern generation  
3. **@AxiomClient** - Client boilerplate generation
4. **@AxiomContext** - Context lifecycle automation
5. **@AxiomCapability** - Capability registration
6. **@AxiomErrorRecovery** - Error handling automation

### Specialized Macros

7. **@AutoMockable** - Testing mock generation
8. **@ErrorBoundary** - Error containment patterns
9. **@NavigationOrchestrator** - Navigation flow management
10. **@Presentation** - Presentation layer automation
11. **@PropagateErrors** - Error propagation patterns
12. **@RecoveryStrategy** - Recovery mechanism automation

## Macro Usage Guide

### 1. @AxiomState

Generates automatic AxiomState protocol conformance with validation and optimization.

#### Basic Usage

```swift
@AxiomState
struct UserState {
    let id: UUID
    let name: String
    let isActive: Bool
}
```

#### Advanced Usage with Parameters

```swift
@AxiomState(
    validation: true,           // Enable validation methods
    optimizeEquality: true,     // Optimize equality comparisons
    customHashable: false,      // Use default hashable implementation
    memoryOptimized: true       // Enable memory optimization
)
struct ComplexState {
    let users: [User]
    let settings: AppSettings
    let cache: DataCache
}
```

#### Generated Features

- **Equatable implementation** with optimized short-circuit evaluation
- **Hashable implementation** with performance considerations  
- **Sendable conformance** for safe concurrency
- **Memory monitoring** with footprint tracking
- **Validation methods** for state consistency
- **Transition validation** for state changes

### 2. @AxiomAction

Generates action protocol conformance with validation and performance tracking.

#### Basic Usage

```swift
@AxiomAction
enum UserAction {
    case login(String, String)
    case logout
    case updateProfile(User)
}
```

#### Advanced Usage with Parameters

```swift
@AxiomAction(
    validation: true,        // Enable validation
    performance: true,       // Enable performance tracking
    retry: false,           // Disable retry logic
    timeout: 5.0,           // Set timeout
    priority: "high"        // Set execution priority
)
enum NetworkAction {
    case fetchData(URL)
    case uploadFile(Data)
}
```

#### Generated Features

- **Action identification** with unique action IDs
- **Validation methods** for action parameters
- **Performance tracking** for execution monitoring
- **Sendable conformance** for safe concurrency
- **Error handling** integration

### 3. @AxiomClient

Generates minimal, reliable Client protocol conformance.

#### Basic Usage

```swift
@Client(state: UserState.self)
actor UserClient {
    // Client implementation generated automatically
}
```

#### Generated Features

- **State storage** with type safety
- **AsyncStream** for state observation
- **State update mechanism** with validation
- **Required protocol methods** implementation
- **Concurrency safety** with actor isolation

### 4. @AxiomContext

Generates context lifecycle automation with MainActor isolation.

#### Basic Usage

```swift
@AxiomContext
class UserContext: ObservableObject {
    @Published var state: UserState
}
```

#### Advanced Usage with Parameters

```swift
@AxiomContext(
    isolation: .mainActor,    // MainActor isolation
    observable: true          // ObservableObject conformance
)
class ComplexContext: ObservableObject {
    @Published var state: ComplexState
    @Published var isLoading: Bool
}
```

#### Generated Features

- **Lifecycle management** with activation/deactivation
- **MainActor isolation** for UI safety
- **Observable patterns** for SwiftUI integration
- **State synchronization** with automatic updates

### 5. @AxiomCapability

Generates capability protocol conformance with dependency management.

#### Basic Usage

```swift
@AxiomCapability(identifier: "storage.local")
struct LocalStorageCapability {
    func save(_ data: Data) async throws { }
    func load() async throws -> Data { }
}
```

#### Advanced Usage with Parameters

```swift
@AxiomCapability(
    identifier: "network.api",
    dependencies: ["auth.user", "network.http"],
    priority: .high
)
struct APICapability {
    func request(_ endpoint: URL) async throws -> Data {
        // Implementation
    }
}
```

#### Generated Features

- **Capability registration** with unique identifiers
- **Dependency injection** patterns
- **Lifecycle management** for capabilities
- **Priority-based** execution ordering

### 6. @AxiomErrorRecovery

Generates error handling automation with retry and circuit breaker patterns.

#### Retry Pattern

```swift
@AxiomErrorRecovery(.retry(attempts: 3, delay: 1.0))
func fetchUserData() async throws -> UserData {
    // Implementation with automatic retry on failure
}
```

#### Circuit Breaker Pattern

```swift
@AxiomErrorRecovery(.circuitBreaker(threshold: 5, timeout: 60.0))
func uploadData(_ data: Data) async throws {
    // Implementation with circuit breaker protection
}
```

#### Generated Features

- **Automatic retry logic** with exponential backoff
- **Circuit breaker protection** against cascading failures
- **Error tracking** and monitoring
- **Graceful degradation** strategies

## Best Practices

### 1. State Management

```swift
// ✅ Good: Use @AxiomState for all state types
@AxiomState(validation: true, memoryOptimized: true)
struct AppState {
    let user: User?
    let settings: Settings
    let networkStatus: NetworkStatus
}

// ❌ Avoid: Manual state protocol implementation
struct ManualState: AxiomState {
    // Manual implementation is error-prone
}
```

### 2. Action Design

```swift
// ✅ Good: Use clear, descriptive action names
@AxiomAction
enum UserAction {
    case authenticateUser(email: String, password: String)
    case updateUserProfile(User)
    case deleteUserAccount(userId: UUID)
}

// ❌ Avoid: Generic or unclear action names
@AxiomAction
enum Action {
    case doSomething(Any)
    case update(String)
}
```

### 3. Client Architecture

```swift
// ✅ Good: One client per domain
@Client(state: UserState.self)
actor UserClient {
    // User-specific operations
}

@Client(state: OrderState.self)
actor OrderClient {
    // Order-specific operations
}

// ❌ Avoid: Monolithic clients
@Client(state: AppState.self)
actor AppClient {
    // Too many responsibilities
}
```

### 4. Context Isolation

```swift
// ✅ Good: Use @MainActor for UI contexts
@AxiomContext(isolation: .mainActor, observable: true)
class UIContext: ObservableObject {
    @Published var state: UIState
}

// ✅ Good: Use regular isolation for background contexts
@AxiomContext
class DataProcessingContext {
    var state: ProcessingState
}
```

### 5. Capability Organization

```swift
// ✅ Good: Fine-grained capabilities with clear dependencies
@AxiomCapability(
    identifier: "storage.secure", 
    dependencies: ["crypto.keychain"],
    priority: .high
)
struct SecureStorageCapability { }

@AxiomCapability(
    identifier: "storage.cache",
    dependencies: ["storage.local"],
    priority: .medium
)
struct CacheCapability { }

// ❌ Avoid: Monolithic capabilities
@AxiomCapability(identifier: "everything")
struct AllInOneCapability { }
```

### 6. Error Recovery Strategies

```swift
// ✅ Good: Use appropriate recovery patterns
@AxiomErrorRecovery(.retry(attempts: 3, delay: 1.0))
func networkRequest() async throws -> Data {
    // Network operations benefit from retry
}

@AxiomErrorRecovery(.circuitBreaker(threshold: 5, timeout: 60.0))
func criticalSystemOperation() async throws {
    // Critical operations need circuit breaker protection
}

// ❌ Avoid: Wrong recovery pattern for the use case
@AxiomErrorRecovery(.retry(attempts: 100, delay: 0.01))
func quickLocalOperation() async throws {
    // Local operations don't need aggressive retry
}
```

## Complete Example

```swift
import AxiomCore
import AxiomArchitecture
import AxiomMacros

// Domain Model
struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
}

// State with automatic protocol conformance
@AxiomState(validation: true, memoryOptimized: true)
struct TaskState {
    let tasks: [Task]
    let isLoading: Bool
    let error: String?
}

// Actions with automatic protocol conformance
@AxiomAction(validation: true, performance: true)
enum TaskAction {
    case loadTasks
    case addTask(Task)
    case toggleTask(UUID)
    case deleteTask(UUID)
}

// Client with automatic implementation
@Client(state: TaskState.self)
actor TaskClient {
    @AxiomErrorRecovery(.retry(attempts: 3))
    func loadTasks() async throws -> [Task] {
        // Implementation with automatic retry
    }
    
    @AxiomErrorRecovery(.circuitBreaker(threshold: 5, timeout: 60.0))
    func saveTask(_ task: Task) async throws {
        // Implementation with circuit breaker
    }
}

// Context with lifecycle automation
@AxiomContext(isolation: .mainActor, observable: true)
class TaskListContext: ObservableObject {
    @Published var state: TaskState = TaskState(tasks: [], isLoading: false, error: nil)
    
    private let client: TaskClient
    
    init(client: TaskClient) {
        self.client = client
    }
}

// Capability with dependency management
@AxiomCapability(
    identifier: "task.persistence",
    dependencies: ["storage.local"],
    priority: .high
)
struct TaskPersistenceCapability {
    func saveTasks(_ tasks: [Task]) async throws {
        // Persistence implementation
    }
    
    func loadTasks() async throws -> [Task] {
        // Loading implementation
    }
}
```

## Performance Considerations

1. **Memory Usage**: @AxiomState includes memory monitoring to track state footprint
2. **Compilation Time**: Macros add minimal compilation overhead
3. **Runtime Performance**: Generated code is optimized for production use
4. **Error Handling**: Built-in error recovery reduces cascade failures

## Testing

All macros include comprehensive test coverage:

- **Expansion tests** validate generated code
- **Integration tests** ensure framework compatibility
- **Performance tests** verify macro efficiency
- **Error scenario tests** validate error handling

## Migration Guide

When migrating from manual implementations:

1. Replace manual protocol conformance with macro annotations
2. Remove boilerplate code that's now generated
3. Update tests to work with macro-generated APIs
4. Verify performance characteristics remain acceptable

This completes the comprehensive Axiom Macros usage guide.