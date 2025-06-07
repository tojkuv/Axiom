# Framework Documentation

## Metadata

- **Generation Date**: January 7, 2025
- **Documentation Version**: 1.0.0
- **Status**: Active
- **Technology Versions**:
  - Swift: 5.9+
  - SwiftSyntax: 509.0.0+
- **Platform Targets**:
  - iOS: 16.0+
  - macOS: 13.0+
- **Cycle Reference**: CYCLE-001-FOUNDATION-ARCHITECTURE
- **Previous Documentation**: None (Initial Release)

## Overview

### Executive Summary

Axiom is a modern, actor-based architecture framework for Apple platforms that provides a robust foundation for building scalable, maintainable applications. The framework enforces strict architectural constraints through compile-time validation and runtime checks, ensuring predictable data flow and strong separation of concerns.

### Architecture Overview

Axiom implements a unidirectional data flow architecture with six immutable component types:
1. **Capability** - External system access (camera, network, location)
2. **State** - Immutable value types containing domain data
3. **Client** - Actor-based state containers with action processing
4. **Orchestrator** - Application-level coordinator for navigation and context creation
5. **Context** - MainActor-bound mediator between presentations and clients
6. **Presentation** - SwiftUI views with single context binding

### Core Design Principles

1. **Unidirectional Flow**: Dependencies flow strictly downstream (Orchestrator → Context → Client → Capability)
2. **Actor Isolation**: All state mutations occur within actor boundaries for thread safety
3. **Type Safety**: Compile-time validation of component relationships and dependencies
4. **Performance Guarantees**: 5ms state propagation, 10ms view updates, 10ms navigation transitions
5. **Memory Efficiency**: Stable memory usage with proper lifecycle management

### Technology Stack Summary

- **Language**: Swift 5.9+ with strict concurrency checking
- **UI Framework**: SwiftUI with Observation framework
- **Concurrency**: Swift actors and async/await
- **Macro System**: SwiftSyntax for code generation and validation
- **Testing**: XCTest with dedicated AxiomTesting utilities

### Key Capabilities

- Type-safe navigation with compile-time route validation
- Automatic error propagation from clients to contexts
- Concurrent state management with reentrancy protection
- Flexible middleware system for cross-cutting concerns
- Performance monitoring and metrics collection
- Memory-efficient component lifecycle management

## Requirements

### Technology Requirements

- **Swift**: Version 5.9 or later
- **Xcode**: Version 15.0 or later
- **SwiftSyntax**: Version 509.0.0 or later

### Platform Requirements

- **iOS**: 16.0 or later
- **macOS**: 13.0 or later
- **Catalyst**: Supported via iOS target
- **Swift Package Manager**: Required for dependency management

### Development Environment

- Full Swift concurrency support enabled
- Strict concurrency checking recommended
- SwiftUI previews for rapid development
- Unit testing infrastructure

### Dependencies

- **swift-syntax** (509.0.0+): Required for macro implementation
- No other external dependencies - framework is self-contained

## Core Architecture

### Architectural Principles

1. **Separation of Concerns**: Each component type has a single, well-defined responsibility
2. **Dependency Inversion**: High-level components depend on abstractions, not concrete implementations
3. **Open/Closed Principle**: Components are open for extension but closed for modification
4. **Interface Segregation**: Protocols are focused and minimal
5. **Liskov Substitution**: All protocol implementations are fully substitutable

### Component Hierarchy Diagram

```
┌─────────────────┐
│  Orchestrator   │ ← Application coordinator
└────────┬────────┘
         │
┌────────▼────────┐
│     Context     │ ← MainActor-bound mediator
└────────┬────────┘
         │
┌────────▼────────┐
│     Client      │ ← Actor-based state container
└────────┬────────┘
         │
┌────────▼────────┐
│   Capability    │ ← External system interface
└─────────────────┘

Parallel to Context:
┌─────────────────┐
│  Presentation   │ ← SwiftUI View (bound to Context)
└─────────────────┘

Within Client:
┌─────────────────┐
│      State      │ ← Immutable value type
└─────────────────┘
```

### Layer Responsibilities

#### Orchestrator Layer
- Creates and configures contexts with dependency injection
- Manages navigation state and transitions
- Monitors capability availability
- Coordinates application-level operations

#### Context Layer
- Mediates between presentations and clients
- Manages component lifecycle (onAppear/onDisappear)
- Handles error boundaries for client errors
- Provides @MainActor safety for UI updates

#### Client Layer
- Owns and manages immutable state
- Processes actions to produce new state
- Provides async state streams for observation
- Ensures thread-safe state mutations via actor isolation

#### Capability Layer
- Abstracts external system access
- Manages resource lifecycle (initialize/terminate)
- Reports availability status
- Handles platform-specific implementations

### Communication Patterns

1. **State Observation**: Clients emit state via AsyncStream, Contexts observe and update UI
2. **Action Processing**: Presentations dispatch actions through Context to Client
3. **Navigation Requests**: Presentation → Context → Orchestrator (enforced flow)
4. **Error Propagation**: Client errors bubble to Context error boundaries
5. **Capability Monitoring**: Orchestrator tracks capability status changes

## Component Specifications

### Client Protocol

**Purpose**: Actor-based state containers that process actions and emit state updates.

**Responsibilities**:
- Own and manage immutable state
- Process actions to produce new state
- Stream state updates via AsyncStream
- Ensure thread safety through actor isolation
- Maintain state consistency across async boundaries

**Interface Specification**:
```swift
public protocol Client<StateType, ActionType>: Actor {
    associatedtype StateType: State
    associatedtype ActionType
    
    var stateStream: AsyncStream<StateType> { get }
    func process(_ action: ActionType) async throws
}
```

**Dependencies**:
- May depend on Capabilities for external system access
- Cannot depend on other Clients (isolation requirement)
- State types must be value types (structs)

**Threading Model**:
- Runs on cooperative thread pool
- All mutations are actor-isolated
- State updates must propagate within 5ms

**Lifecycle Management**:
- Created by Context during initialization
- Lives as long as owning Context
- Automatically cleaned up on Context deallocation

### Context Protocol

**Purpose**: MainActor-bound coordinators that bridge Presentations and Clients.

**Responsibilities**:
- Coordinate between UI and business logic
- Manage component lifecycle
- Handle errors from Clients
- Provide @MainActor safety for UI updates
- Mediate navigation requests

**Interface Specification**:
```swift
@MainActor
public protocol Context: ObservableObject {
    func onAppear() async
    func onDisappear() async
}
```

**Dependencies**:
- Depends on Clients for state and action processing
- May depend on other Contexts (DAG requirement)
- Created by Orchestrator

**Threading Model**:
- Always runs on MainActor
- Bridges between MainActor (UI) and Client actors
- Ensures UI updates happen on main thread

**Lifecycle Management**:
- Created by Orchestrator on navigation
- onAppear() called when Presentation appears
- onDisappear() called when Presentation disappears
- Cleaned up after Presentation is removed

### Capability Protocol

**Purpose**: Abstractions for external system access with lifecycle management.

**Responsibilities**:
- Abstract platform-specific functionality
- Manage resource allocation/deallocation
- Report availability status
- Handle permission requests
- Provide async APIs for system access

**Interface Specification**:
```swift
public protocol Capability: Actor {
    var isAvailable: Bool { get async }
    func initialize() async throws
    func terminate() async
}
```

**Dependencies**:
- May depend on other Capabilities (DAG requirement)
- Cannot depend on Clients, Contexts, or Orchestrators
- Direct platform API access allowed

**Threading Model**:
- Actor-isolated for thread safety
- May use platform-specific dispatch queues internally
- State transitions must complete within 10ms

**Lifecycle Management**:
- Initialized on first use or app launch
- Terminated on app termination or when no longer needed
- Supports availability monitoring

### Orchestrator Protocol

**Purpose**: Application-level coordinator for navigation and dependency injection.

**Responsibilities**:
- Create Contexts with proper dependencies
- Manage navigation state and transitions
- Monitor Capability availability
- Coordinate application-wide operations
- Handle deep linking

**Interface Specification**:
```swift
public protocol Orchestrator: Actor {
    func createContext<P: Presentation>(
        for presentation: P.Type
    ) async -> P.ContextType
    
    func navigate(to route: Route) async
}
```

**Dependencies**:
- Depends on Contexts for screen coordination
- Cannot depend on Clients or Capabilities directly
- Top of the dependency hierarchy

**Threading Model**:
- Actor-isolated for thread safety
- Coordinates between multiple Contexts
- Navigation transitions must complete within 10ms

**Lifecycle Management**:
- Single instance per application
- Created at app launch
- Lives for entire app lifecycle
- Manages Context lifecycle

## Data Flow Patterns

### State Flow Documentation

The framework enforces unidirectional state flow to ensure predictability and debuggability:

```
User Input → Presentation → Context → Client → New State → Context → Presentation → UI Update
```

**Key Principles**:
1. **Single Source of Truth**: Each piece of state is owned by exactly one Client
2. **Immutable Updates**: All state changes create new immutable instances
3. **Observable Streams**: State changes are broadcast via AsyncStream
4. **No Shared Mutable State**: Clients are isolated from each other

**State Protocol Requirements**:
```swift
public protocol State: Equatable, Hashable, Sendable {
    // Must be a value type (struct)
    // All properties must be immutable (let)
}
```

### Action Flow Documentation

Actions flow through the system in a predictable manner:

1. **Action Creation**: Presentation creates action based on user input
2. **Context Dispatch**: Context forwards action to appropriate Client
3. **Client Processing**: Client processes action and produces new state
4. **State Emission**: New state emitted via AsyncStream
5. **UI Update**: Context observes state and triggers SwiftUI update

**Action Processing Example**:
```swift
// In Presentation
Button("Add Item") {
    Task { await context.addItem(name: "New Item") }
}

// In Context
func addItem(name: String) async {
    await client.process(.add(name: name))
}

// In Client
func process(_ action: Action) async throws {
    switch action {
    case .add(let name):
        let newItem = Item(name: name)
        updateState(state.withNewItem(newItem))
    }
}
```

### Error Propagation Patterns

Errors flow from Clients to Contexts through error boundaries:

1. **Error Source**: Client throws error during action processing
2. **Automatic Propagation**: Error propagator captures and routes error
3. **Context Handling**: Context error boundary receives error
4. **Recovery Strategy**: Context applies appropriate recovery
5. **UI Feedback**: Presentation shows error state to user

**Error Categories**:
- **Network Errors**: Retry with exponential backoff
- **Validation Errors**: Immediate failure with user feedback
- **Authorization Errors**: Navigate to login flow
- **System Errors**: Log and fail gracefully

### Timing Requirements

The framework enforces strict timing requirements for responsive UX:

- **State Propagation**: < 5ms from Client state update to Context notification
- **UI Updates**: < 10ms from Context state change to SwiftUI render
- **Navigation**: < 10ms for route transitions
- **Error Handling**: < 50ms for error propagation and recovery
- **Capability State**: < 10ms for availability changes

## Concurrency Model

### Threading Architecture

Axiom leverages Swift's actor model for safe concurrent programming:

**Component Thread Affinity**:
- **Orchestrator**: Actor (cooperative thread pool)
- **Context**: @MainActor (UI thread)
- **Client**: Actor (cooperative thread pool)
- **Capability**: Actor (cooperative thread pool)
- **Presentation**: @MainActor (UI thread)
- **State**: Value type (no thread affinity)

### Isolation Boundaries

Each component type has strict isolation requirements:

1. **Client Isolation**:
   - Each Client is a separate actor
   - No shared mutable state between Clients
   - All state mutations are actor-isolated
   - Cross-client communication prohibited

2. **Context Isolation**:
   - All Contexts run on MainActor
   - Safe to update SwiftUI state
   - Bridges between UI and actor threads
   - Async boundaries when calling Clients

3. **Capability Isolation**:
   - Each Capability is a separate actor
   - Platform resources are actor-protected
   - Async APIs for all operations
   - Thread-safe state transitions

### Synchronization Patterns

**AsyncStream for State Observation**:
```swift
// In Client
private var streamContinuations: [UUID: AsyncStream<S>.Continuation] = [:]

public var stateStream: AsyncStream<S> {
    AsyncStream { continuation in
        let id = UUID()
        streamContinuations[id] = continuation
        continuation.yield(state) // Initial state
        continuation.onTermination = { _ in
            Task { await self.removeContinuation(id: id) }
        }
    }
}
```

**Task Cancellation Propagation**:
- Context cancellation automatically cancels Client tasks
- Propagation completes within 10ms
- TaskCancellationCoordinator manages relationships
- Proper cleanup on Context deallocation

### Async Operation Handling

**Reentrancy Protection**:
```swift
public protocol ConcurrentClient: Actor {
    var stateVersion: Int { get }
    func validateStateConsistency(expectedVersion: Int) -> Bool
    func handleStateChange(from previousVersion: Int) async
}

// Usage
func withStateValidation<T>(_ operation: () async throws -> T) async rethrows -> T {
    let startVersion = stateVersion
    let result = try await operation()
    if !validateStateConsistency(expectedVersion: startVersion) {
        await handleStateChange(from: startVersion)
    }
    return result
}
```

**Priority Inheritance**:
- High-priority UI tasks boost blocking operations
- PriorityCoordinator prevents priority inversion
- Automatic priority propagation across actors

**Deadlock Prevention**:
- Maximum 500ms timeout for cross-actor calls
- Automatic deadlock detection
- Recovery strategies for blocked operations

## Navigation System

### Overview

The Axiom navigation system provides type-safe, declarative navigation with compile-time route validation and middleware support. It enforces unidirectional navigation flow from Presentation → Context → Orchestrator, preventing architectural violations.

### Navigation Architecture

```
┌─────────────────┐
│  Presentation   │ ← Initiates navigation requests
└────────┬────────┘
         │
┌────────▼────────┐
│     Context     │ ← Validates and forwards requests
└────────┬────────┘
         │
┌────────▼────────┐
│  Orchestrator   │ ← Executes navigation transitions
└────────┬────────┘
         │
┌────────▼────────┐
│ NavigationFlow  │ ← Manages navigation state & history
└─────────────────┘
```

### Core Components

#### NavigationFlow

**Purpose**: Centralized navigation state management with history tracking and transition coordination.

**Interface**:
```swift
@MainActor
public final class NavigationFlow: ObservableObject {
    @Published public private(set) var currentRoute: Route?
    @Published public private(set) var history: [Route] = []
    @Published public private(set) var isTransitioning: Bool = false
    
    public func navigate(to route: Route) async throws
    public func navigateBack() async throws
    public func navigateToRoot() async throws
    public func canNavigateBack() -> Bool
    
    // Middleware support
    public func addMiddleware(_ middleware: NavigationMiddleware)
    public func removeMiddleware(_ middleware: NavigationMiddleware)
}
```

**Key Features**:
- History stack management with back navigation
- Transition state tracking
- Middleware chain for cross-cutting concerns
- Thread-safe state updates on MainActor

#### Route Protocol

**Purpose**: Type-safe route definitions with associated metadata.

**Interface**:
```swift
public protocol Route: Hashable, Sendable {
    var identifier: String { get }
    var parameters: [String: Any] { get }
    var metadata: RouteMetadata { get }
}

public struct RouteMetadata: Sendable {
    public let requiresAuthentication: Bool
    public let analyticsName: String?
    public let transitionStyle: TransitionStyle
    public let prefetchRequirements: [PrefetchRequirement]
}

public enum TransitionStyle: Sendable {
    case push
    case modal(presentationStyle: ModalPresentationStyle)
    case replace
    case custom(transition: AnyTransition)
}
```

**Usage Example**:
```swift
enum AppRoute: Route {
    case home
    case profile(userId: String)
    case settings(section: SettingsSection?)
    
    var identifier: String {
        switch self {
        case .home: "home"
        case .profile: "profile"
        case .settings: "settings"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .home: 
            [:]
        case .profile(let userId): 
            ["userId": userId]
        case .settings(let section):
            section.map { ["section": $0.rawValue] } ?? [:]
        }
    }
    
    var metadata: RouteMetadata {
        switch self {
        case .home:
            RouteMetadata(
                requiresAuthentication: false,
                analyticsName: "home_screen",
                transitionStyle: .replace,
                prefetchRequirements: []
            )
        case .profile:
            RouteMetadata(
                requiresAuthentication: true,
                analyticsName: "profile_screen",
                transitionStyle: .push,
                prefetchRequirements: [.userData]
            )
        case .settings:
            RouteMetadata(
                requiresAuthentication: true,
                analyticsName: "settings_screen",
                transitionStyle: .modal(presentationStyle: .formSheet),
                prefetchRequirements: []
            )
        }
    }
}
```

### Navigation Middleware

**Purpose**: Intercept and modify navigation requests for cross-cutting concerns.

**Interface**:
```swift
public protocol NavigationMiddleware: Sendable {
    func process(
        _ request: NavigationRequest,
        next: @Sendable (NavigationRequest) async throws -> NavigationResult
    ) async throws -> NavigationResult
}

public struct NavigationRequest: Sendable {
    public let route: Route
    public let source: NavigationSource
    public let timestamp: Date
    public let context: [String: Any]
}

public enum NavigationResult: Sendable {
    case success(Route)
    case cancelled(reason: String)
    case redirected(to: Route)
    case failed(Error)
}
```

**Common Middleware Examples**:

```swift
// Authentication Middleware
public struct AuthenticationMiddleware: NavigationMiddleware {
    let authService: AuthenticationService
    
    public func process(
        _ request: NavigationRequest,
        next: @Sendable (NavigationRequest) async throws -> NavigationResult
    ) async throws -> NavigationResult {
        guard request.route.metadata.requiresAuthentication else {
            return try await next(request)
        }
        
        guard await authService.isAuthenticated else {
            return .redirected(to: AppRoute.login(returnTo: request.route))
        }
        
        return try await next(request)
    }
}

// Analytics Middleware
public struct AnalyticsMiddleware: NavigationMiddleware {
    let analytics: AnalyticsService
    
    public func process(
        _ request: NavigationRequest,
        next: @Sendable (NavigationRequest) async throws -> NavigationResult
    ) async throws -> NavigationResult {
        let startTime = Date()
        let result = try await next(request)
        
        if case .success(let route) = result,
           let analyticsName = route.metadata.analyticsName {
            await analytics.track(
                event: "navigation",
                properties: [
                    "screen": analyticsName,
                    "duration": Date().timeIntervalSince(startTime),
                    "source": request.source.rawValue
                ]
            )
        }
        
        return result
    }
}

// Rate Limiting Middleware
public struct RateLimitingMiddleware: NavigationMiddleware {
    private let limiter = RateLimiter(maxRequests: 10, window: .seconds(1))
    
    public func process(
        _ request: NavigationRequest,
        next: @Sendable (NavigationRequest) async throws -> NavigationResult
    ) async throws -> NavigationResult {
        guard await limiter.shouldAllow(request.route.identifier) else {
            return .cancelled(reason: "Navigation rate limit exceeded")
        }
        
        return try await next(request)
    }
}
```

### Route Validation

**Compile-time Validation**:
```swift
@attached(member, names: named(validateRoutes))
public macro ValidateRoutes() = #externalMacro(
    module: "AxiomMacros",
    type: "ValidateRoutesMacro"
)

@ValidateRoutes
enum AppRoute: Route {
    case home
    case profile(userId: String)
    case settings
    
    // Macro generates:
    static func validateRoutes() {
        // Ensures all routes have unique identifiers
        // Validates parameter types are Sendable
        // Checks metadata completeness
    }
}
```

**Runtime Validation**:
```swift
public struct RouteValidator {
    public static func validate(_ route: Route) throws {
        // Validate parameter types
        for (key, value) in route.parameters {
            guard value is any Sendable else {
                throw ValidationError.nonSendableParameter(key)
            }
        }
        
        // Validate identifier format
        let identifierRegex = /^[a-zA-Z][a-zA-Z0-9_]*$/
        guard route.identifier.matches(identifierRegex) else {
            throw ValidationError.invalidIdentifier(route.identifier)
        }
        
        // Validate metadata
        if route.metadata.requiresAuthentication && 
           route.metadata.transitionStyle.isModal {
            throw ValidationError.modalCannotRequireAuth
        }
    }
}
```

### Deep Linking Support

```swift
public protocol DeepLinkHandler {
    func canHandle(url: URL) -> Bool
    func route(from url: URL) async throws -> Route?
}

public struct UniversalLinkHandler: DeepLinkHandler {
    private let patterns: [URLPattern: (URLComponents) -> Route?]
    
    public func canHandle(url: URL) -> Bool {
        patterns.keys.contains { $0.matches(url) }
    }
    
    public func route(from url: URL) async throws -> Route? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let (_, handler) = patterns.first(where: { $0.key.matches(url) }) else {
            return nil
        }
        
        return handler(components)
    }
}

// Usage
let deepLinkHandler = UniversalLinkHandler(patterns: [
    URLPattern("app://profile/:userId"): { components in
        guard let userId = components.pathComponents[safe: 2] else { return nil }
        return AppRoute.profile(userId: userId)
    },
    URLPattern("https://example.com/settings/*"): { _ in
        return AppRoute.settings(section: nil)
    }
])
```

### Navigation Performance

**Optimization Strategies**:
1. **Route Prefetching**: Load required data before navigation completes
2. **Transition Caching**: Reuse computed transitions
3. **History Limiting**: Cap navigation history to prevent memory growth
4. **Lazy Context Creation**: Create contexts only when needed

**Performance Monitoring**:
```swift
public struct NavigationMetrics {
    public let transitionDuration: TimeInterval
    public let contextCreationTime: TimeInterval
    public let middlewareProcessingTime: TimeInterval
    public let totalNavigationTime: TimeInterval
    
    public static let targetTransitionTime: TimeInterval = 0.01 // 10ms
}
```

## Error Handling

### Overview

Axiom provides comprehensive error handling through error boundaries, automatic propagation, and recovery strategies. The system ensures errors are handled at appropriate levels while maintaining application stability.

### Error Architecture

```
┌─────────────────┐
│     Client      │ ← Error origin (throws during action processing)
└────────┬────────┘
         │ Automatic propagation
┌────────▼────────┐
│ Error Propagator│ ← Captures and routes errors
└────────┬────────┘
         │
┌────────▼────────┐
│ Error Boundary  │ ← Context-level error handling
└────────┬────────┘
         │
┌────────▼────────┐
│Recovery Strategy│ ← Applies appropriate recovery
└────────┬────────┘
         │
┌────────▼────────┐
│  Presentation   │ ← Displays error UI
└─────────────────┘
```

### Error Types

```swift
public protocol AxiomError: Error, Sendable {
    var code: String { get }
    var userMessage: String { get }
    var technicalMessage: String { get }
    var isRecoverable: Bool { get }
    var suggestedAction: ErrorAction? { get }
}

public enum ErrorAction: Sendable {
    case retry
    case authenticate
    case updateApp
    case contactSupport
    case dismiss
}

// Common Error Types
public enum NetworkError: AxiomError {
    case noConnection
    case timeout(duration: TimeInterval)
    case serverError(statusCode: Int)
    case invalidResponse
    
    public var isRecoverable: Bool {
        switch self {
        case .noConnection, .timeout: true
        case .serverError(let code): code >= 500
        case .invalidResponse: false
        }
    }
    
    public var suggestedAction: ErrorAction? {
        switch self {
        case .noConnection, .timeout, .serverError: .retry
        case .invalidResponse: .contactSupport
        }
    }
}

public enum ValidationError: AxiomError {
    case missingRequired(field: String)
    case invalidFormat(field: String, expectedFormat: String)
    case outOfRange(field: String, min: Any, max: Any)
    
    public var isRecoverable: Bool { true }
    public var suggestedAction: ErrorAction? { .dismiss }
}

public enum AuthorizationError: AxiomError {
    case unauthorized
    case forbidden
    case sessionExpired
    
    public var isRecoverable: Bool { true }
    public var suggestedAction: ErrorAction? { .authenticate }
}
```

### Error Boundaries

**Purpose**: Catch and handle errors at the Context level, preventing crashes and providing recovery options.

```swift
@MainActor
public protocol ErrorBoundary {
    func handleError(_ error: Error, from source: ErrorSource) async
    func setRecoveryStrategy(_ strategy: RecoveryStrategy, for errorType: any Error.Type)
    func clearError()
}

public enum ErrorSource: Sendable {
    case client(name: String)
    case capability(name: String)
    case navigation
    case initialization
}

// Implementation
@MainActor
public class StandardErrorBoundary: ErrorBoundary, ObservableObject {
    @Published public private(set) var currentError: (any Error)?
    @Published public private(set) var isRecovering: Bool = false
    
    private var recoveryStrategies: [ObjectIdentifier: any RecoveryStrategy] = [:]
    private let logger: Logger
    
    public func handleError(_ error: Error, from source: ErrorSource) async {
        logger.error("Error from \(source): \(error)")
        
        // Find appropriate recovery strategy
        let strategy = findRecoveryStrategy(for: error)
        
        isRecovering = true
        defer { isRecovering = false }
        
        do {
            let recovered = try await strategy.recover(from: error, source: source)
            if !recovered {
                currentError = error
            }
        } catch {
            // Recovery failed, show error to user
            currentError = error
        }
    }
    
    private func findRecoveryStrategy(for error: Error) -> any RecoveryStrategy {
        let errorType = type(of: error)
        let identifier = ObjectIdentifier(errorType)
        
        return recoveryStrategies[identifier] ?? DefaultRecoveryStrategy()
    }
}
```

### Recovery Strategies

**Purpose**: Define how to recover from specific error types.

```swift
public protocol RecoveryStrategy: Sendable {
    func canRecover(from error: Error) -> Bool
    func recover(from error: Error, source: ErrorSource) async throws -> Bool
}

// Retry Strategy with Exponential Backoff
public struct RetryRecoveryStrategy: RecoveryStrategy {
    public let maxAttempts: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    
    public func recover(from error: Error, source: ErrorSource) async throws -> Bool {
        guard let axiomError = error as? AxiomError,
              axiomError.isRecoverable else {
            return false
        }
        
        for attempt in 0..<maxAttempts {
            let delay = min(baseDelay * pow(2, Double(attempt)), maxDelay)
            try await Task.sleep(for: .seconds(delay))
            
            // Retry the operation
            if await retryOperation(source: source) {
                return true
            }
        }
        
        return false
    }
    
    private func retryOperation(source: ErrorSource) async -> Bool {
        // Implementation depends on error source
        // Returns true if retry succeeded
        false
    }
}

// Circuit Breaker Strategy
public actor CircuitBreakerStrategy: RecoveryStrategy {
    private var failureCount: Int = 0
    private var lastFailureTime: Date?
    private var state: CircuitState = .closed
    
    private let threshold: Int
    private let timeout: TimeInterval
    
    enum CircuitState {
        case closed  // Normal operation
        case open    // Failing, reject requests
        case halfOpen // Testing if service recovered
    }
    
    public func recover(from error: Error, source: ErrorSource) async throws -> Bool {
        switch state {
        case .open:
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) > timeout {
                state = .halfOpen
            } else {
                return false // Circuit is open, fail fast
            }
            
        case .halfOpen:
            // Try one request
            if await testOperation(source: source) {
                reset()
                return true
            } else {
                trip()
                return false
            }
            
        case .closed:
            failureCount += 1
            lastFailureTime = Date()
            
            if failureCount >= threshold {
                trip()
                return false
            }
            
            // Try retry with backoff
            return await retryWithBackoff(source: source)
        }
    }
    
    private func trip() {
        state = .open
        lastFailureTime = Date()
    }
    
    private func reset() {
        state = .closed
        failureCount = 0
        lastFailureTime = nil
    }
}

// Fallback Strategy
public struct FallbackRecoveryStrategy<T: Sendable>: RecoveryStrategy {
    private let fallbackProvider: @Sendable () async -> T
    private let fallbackApplier: @Sendable (T) async -> Void
    
    public func recover(from error: Error, source: ErrorSource) async throws -> Bool {
        let fallbackValue = await fallbackProvider()
        await fallbackApplier(fallbackValue)
        return true
    }
}
```

### Error Propagation

**Automatic Error Capture**:
```swift
// In BaseClient
public func process(_ action: ActionType) async throws {
    do {
        try await processAction(action)
    } catch {
        // Automatically propagate to error boundary
        await errorPropagator.propagate(error, from: .client(name: clientName))
        throw error
    }
}

// Error Propagator
public actor ErrorPropagator {
    private weak var errorBoundary: (any ErrorBoundary)?
    
    public func propagate(_ error: Error, from source: ErrorSource) async {
        guard let boundary = errorBoundary else { return }
        await boundary.handleError(error, from: source)
    }
}
```

### Error UI Components

```swift
public struct ErrorView: View {
    let error: any AxiomError
    let onRetry: () async -> Void
    let onDismiss: () -> Void
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: errorIcon)
                .font(.largeTitle)
                .foregroundColor(errorColor)
            
            Text(error.userMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            if let action = error.suggestedAction {
                actionButton(for: action)
            }
            
            if error.isRecoverable {
                Button("Retry") {
                    Task { await onRetry() }
                }
                .buttonStyle(.borderedProminent)
            }
            
            Button("Dismiss", action: onDismiss)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
    
    private var errorIcon: String {
        switch error {
        case is NetworkError: "wifi.exclamationmark"
        case is ValidationError: "exclamationmark.triangle"
        case is AuthorizationError: "lock"
        default: "exclamationmark.circle"
        }
    }
}

// Error Boundary View Modifier
public struct ErrorBoundaryModifier: ViewModifier {
    @ObservedObject var errorBoundary: StandardErrorBoundary
    
    public func body(content: Content) -> some View {
        content
            .overlay(alignment: .center) {
                if let error = errorBoundary.currentError as? any AxiomError {
                    ErrorView(
                        error: error,
                        onRetry: {
                            errorBoundary.clearError()
                            // Retry logic
                        },
                        onDismiss: errorBoundary.clearError
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
            .animation(.spring(), value: errorBoundary.currentError != nil)
    }
}
```

### Error Monitoring and Analytics

```swift
public protocol ErrorMonitor: Actor {
    func track(_ error: Error, source: ErrorSource, context: ErrorContext)
    func getErrorMetrics() async -> ErrorMetrics
}

public struct ErrorContext: Sendable {
    public let userId: String?
    public let sessionId: String
    public let timestamp: Date
    public let deviceInfo: DeviceInfo
    public let appVersion: String
    public let stackTrace: [String]?
}

public struct ErrorMetrics: Sendable {
    public let totalErrors: Int
    public let errorsByType: [String: Int]
    public let errorsBySource: [ErrorSource: Int]
    public let recoverySuccessRate: Double
    public let averageRecoveryTime: TimeInterval
}

// Implementation
public actor StandardErrorMonitor: ErrorMonitor {
    private var errorLog: [ErrorRecord] = []
    private let maxLogSize = 1000
    
    public func track(_ error: Error, source: ErrorSource, context: ErrorContext) {
        let record = ErrorRecord(
            error: error,
            source: source,
            context: context,
            id: UUID()
        )
        
        errorLog.append(record)
        
        // Maintain log size
        if errorLog.count > maxLogSize {
            errorLog.removeFirst()
        }
        
        // Send to external service if critical
        if isCriticalError(error) {
            Task.detached {
                await self.sendToAnalytics(record)
            }
        }
    }
}
```

## Public APIs

### Overview

This section documents all key public interfaces in the Axiom framework with usage examples and best practices.

### Core Protocols

#### State Protocol

**Purpose**: Define immutable value types for domain data.

```swift
public protocol State: Equatable, Hashable, Sendable {
    // Marker protocol - no required methods
    // Must be implemented as a struct
}

// Usage Example
public struct TodoListState: State {
    public let items: [TodoItem]
    public let filter: TodoFilter
    public let isLoading: Bool
    
    public init(
        items: [TodoItem] = [],
        filter: TodoFilter = .all,
        isLoading: Bool = false
    ) {
        self.items = items
        self.filter = filter
        self.isLoading = isLoading
    }
    
    // Convenience methods for state updates
    public func withItems(_ items: [TodoItem]) -> TodoListState {
        TodoListState(items: items, filter: filter, isLoading: isLoading)
    }
    
    public func withFilter(_ filter: TodoFilter) -> TodoListState {
        TodoListState(items: items, filter: filter, isLoading: isLoading)
    }
    
    public func withLoading(_ isLoading: Bool) -> TodoListState {
        TodoListState(items: items, filter: filter, isLoading: isLoading)
    }
}
```

#### Client Protocol

**Purpose**: Actor-based state containers with action processing.

```swift
public protocol Client<StateType, ActionType>: Actor {
    associatedtype StateType: State
    associatedtype ActionType
    
    var stateStream: AsyncStream<StateType> { get }
    func process(_ action: ActionType) async throws
}

// Base implementation provided by framework
open class BaseClient<S: State, A>: Client {
    public typealias StateType = S
    public typealias ActionType = A
    
    private var state: S
    private var continuations: [UUID: AsyncStream<S>.Continuation] = [:]
    
    public var stateStream: AsyncStream<S> {
        AsyncStream { continuation in
            let id = UUID()
            continuations[id] = continuation
            continuation.yield(state)
            continuation.onTermination = { _ in
                Task { await self.removeContinuation(id) }
            }
        }
    }
    
    public init(initialState: S) {
        self.state = initialState
    }
    
    open func process(_ action: A) async throws {
        fatalError("Subclasses must implement process(_:)")
    }
    
    protected func updateState(_ newState: S) {
        state = newState
        for continuation in continuations.values {
            continuation.yield(newState)
        }
    }
    
    private func removeContinuation(_ id: UUID) {
        continuations.removeValue(forKey: id)
    }
}

// Usage Example
public actor TodoClient: BaseClient<TodoListState, TodoAction> {
    private let repository: TodoRepository
    
    public init(repository: TodoRepository) {
        self.repository = repository
        super.init(initialState: TodoListState())
    }
    
    public override func process(_ action: TodoAction) async throws {
        switch action {
        case .loadTodos:
            updateState(currentState.withLoading(true))
            let todos = try await repository.fetchTodos()
            updateState(currentState.withItems(todos).withLoading(false))
            
        case .addTodo(let title):
            let newTodo = TodoItem(id: UUID(), title: title, isCompleted: false)
            try await repository.saveTodo(newTodo)
            let updatedItems = currentState.items + [newTodo]
            updateState(currentState.withItems(updatedItems))
            
        case .toggleTodo(let id):
            guard let index = currentState.items.firstIndex(where: { $0.id == id }) else { return }
            var items = currentState.items
            items[index].isCompleted.toggle()
            try await repository.updateTodo(items[index])
            updateState(currentState.withItems(items))
            
        case .deleteTodo(let id):
            try await repository.deleteTodo(id)
            let filteredItems = currentState.items.filter { $0.id != id }
            updateState(currentState.withItems(filteredItems))
            
        case .setFilter(let filter):
            updateState(currentState.withFilter(filter))
        }
    }
    
    private var currentState: TodoListState {
        // Access current state (internal helper)
        state
    }
}

public enum TodoAction {
    case loadTodos
    case addTodo(title: String)
    case toggleTodo(id: UUID)
    case deleteTodo(id: UUID)
    case setFilter(TodoFilter)
}
```

#### Context Protocol

**Purpose**: MainActor-bound coordinators between UI and business logic.

```swift
@MainActor
public protocol Context: ObservableObject {
    func onAppear() async
    func onDisappear() async
}

// Base implementation with common functionality
@MainActor
open class BaseContext: Context {
    private var appearanceTask: Task<Void, Never>?
    
    open func onAppear() async {
        // Override in subclasses
    }
    
    open func onDisappear() async {
        appearanceTask?.cancel()
        appearanceTask = nil
    }
    
    deinit {
        appearanceTask?.cancel()
    }
}

// Usage Example
@MainActor
public final class TodoListContext: BaseContext {
    @Published public private(set) var todos: [TodoItem] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var error: Error?
    
    private let client: TodoClient
    private var stateTask: Task<Void, Never>?
    
    public init(client: TodoClient) {
        self.client = client
        super.init()
        observeClientState()
    }
    
    public override func onAppear() async {
        await super.onAppear()
        do {
            try await client.process(.loadTodos)
        } catch {
            self.error = error
        }
    }
    
    public override func onDisappear() async {
        await super.onDisappear()
        stateTask?.cancel()
    }
    
    public func addTodo(title: String) async {
        do {
            try await client.process(.addTodo(title: title))
        } catch {
            self.error = error
        }
    }
    
    public func toggleTodo(_ todo: TodoItem) async {
        do {
            try await client.process(.toggleTodo(id: todo.id))
        } catch {
            self.error = error
        }
    }
    
    public func deleteTodo(_ todo: TodoItem) async {
        do {
            try await client.process(.deleteTodo(id: todo.id))
        } catch {
            self.error = error
        }
    }
    
    private func observeClientState() {
        stateTask = Task { [weak self] in
            guard let self else { return }
            
            for await state in await client.stateStream {
                guard !Task.isCancelled else { break }
                
                self.todos = state.items
                self.isLoading = state.isLoading
            }
        }
    }
}
```

#### Capability Protocol

**Purpose**: Abstract external system access with lifecycle management.

```swift
public protocol Capability: Actor {
    var isAvailable: Bool { get async }
    func initialize() async throws
    func terminate() async
}

// Base implementation
open class BaseCapability: Capability {
    private var _isAvailable: Bool = false
    
    public var isAvailable: Bool {
        get async { _isAvailable }
    }
    
    open func initialize() async throws {
        // Override in subclasses
        _isAvailable = true
    }
    
    open func terminate() async {
        // Override in subclasses
        _isAvailable = false
    }
    
    protected func setAvailability(_ available: Bool) {
        _isAvailable = available
    }
}

// Usage Example - Camera Capability
public actor CameraCapability: BaseCapability {
    private var captureSession: AVCaptureSession?
    private let permissionService: PermissionService
    
    public init(permissionService: PermissionService) {
        self.permissionService = permissionService
        super.init()
    }
    
    public override func initialize() async throws {
        // Check permissions
        let hasPermission = await permissionService.requestCameraAccess()
        guard hasPermission else {
            throw CapabilityError.permissionDenied
        }
        
        // Setup capture session
        captureSession = AVCaptureSession()
        // ... configure session ...
        
        await super.initialize()
    }
    
    public override func terminate() async {
        captureSession?.stopRunning()
        captureSession = nil
        await super.terminate()
    }
    
    public func capturePhoto() async throws -> Data {
        guard isAvailable else {
            throw CapabilityError.notAvailable
        }
        
        // Capture implementation
        // ...
        return Data()
    }
}

// Usage Example - Network Capability
public actor NetworkCapability: BaseCapability {
    private let session: URLSession
    private let reachability: NetworkReachability
    
    public init() {
        self.session = URLSession(configuration: .default)
        self.reachability = NetworkReachability()
        super.init()
    }
    
    public override func initialize() async throws {
        await reachability.startMonitoring()
        setAvailability(await reachability.isReachable)
        
        // Monitor reachability changes
        Task {
            for await isReachable in reachability.statusStream {
                setAvailability(isReachable)
            }
        }
        
        await super.initialize()
    }
    
    public func request<T: Decodable>(
        _ endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> T {
        guard isAvailable else {
            throw NetworkError.noConnection
        }
        
        let (data, response) = try await session.data(for: endpoint.urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

#### Presentation Protocol

**Purpose**: SwiftUI views with single context binding.

```swift
public protocol Presentation: View {
    associatedtype ContextType: Context
    var context: ContextType { get }
}

// Usage Example
public struct TodoListView: Presentation {
    @ObservedObject public var context: TodoListContext
    @State private var newTodoTitle = ""
    @State private var showingAddSheet = false
    
    public init(context: TodoListContext) {
        self.context = context
    }
    
    public var body: some View {
        NavigationView {
            VStack {
                if context.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    todoList
                }
            }
            .navigationTitle("Todos")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                addTodoSheet
            }
            .task {
                await context.onAppear()
            }
            .onDisappear {
                Task {
                    await context.onDisappear()
                }
            }
        }
    }
    
    private var todoList: some View {
        List {
            ForEach(context.todos) { todo in
                TodoRow(
                    todo: todo,
                    onToggle: {
                        Task {
                            await context.toggleTodo(todo)
                        }
                    }
                )
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        await context.deleteTodo(context.todos[index])
                    }
                }
            }
        }
    }
    
    private var addTodoSheet: some View {
        NavigationView {
            Form {
                TextField("Todo Title", text: $newTodoTitle)
            }
            .navigationTitle("Add Todo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddSheet = false
                        newTodoTitle = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await context.addTodo(title: newTodoTitle)
                            showingAddSheet = false
                            newTodoTitle = ""
                        }
                    }
                    .disabled(newTodoTitle.isEmpty)
                }
            }
        }
    }
}
```

#### Orchestrator Protocol

**Purpose**: Application-level coordinator for navigation and dependency injection.

```swift
public protocol Orchestrator: Actor {
    func createContext<P: Presentation>(
        for presentation: P.Type
    ) async -> P.ContextType
    
    func navigate(to route: Route) async
}

// Usage Example
public actor AppOrchestrator: Orchestrator {
    private let navigationFlow: NavigationFlow
    private let dependencyContainer: DependencyContainer
    
    public init(
        navigationFlow: NavigationFlow,
        dependencyContainer: DependencyContainer
    ) {
        self.navigationFlow = navigationFlow
        self.dependencyContainer = dependencyContainer
    }
    
    public func createContext<P: Presentation>(
        for presentation: P.Type
    ) async -> P.ContextType {
        // Factory pattern for context creation
        switch presentation {
        case is TodoListView.Type:
            let repository = await dependencyContainer.resolve(TodoRepository.self)
            let client = TodoClient(repository: repository)
            return TodoListContext(client: client) as! P.ContextType
            
        case is ProfileView.Type:
            let userService = await dependencyContainer.resolve(UserService.self)
            let client = ProfileClient(userService: userService)
            return ProfileContext(client: client) as! P.ContextType
            
        default:
            fatalError("Unknown presentation type: \(presentation)")
        }
    }
    
    public func navigate(to route: Route) async {
        await MainActor.run {
            Task {
                try await navigationFlow.navigate(to: route)
            }
        }
    }
}
```

### Macro APIs

#### Component Validation Macros

```swift
// State Validation
@attached(extension, conformances: State)
@attached(member, names: named(init))
public macro AxiomState() = #externalMacro(
    module: "AxiomMacros",
    type: "AxiomStateMacro"
)

// Usage
@AxiomState
public struct UserProfileState {
    public let user: User
    public let posts: [Post]
    public let isFollowing: Bool
}
// Generates: Equatable, Hashable, Sendable conformance and memberwise init

// Client Validation
@attached(peer, names: overloaded)
public macro AxiomClient() = #externalMacro(
    module: "AxiomMacros",
    type: "AxiomClientMacro"
)

// Usage
@AxiomClient
public actor UserProfileClient: Client {
    // Validates:
    // - Actor isolation
    // - State type conformance
    // - Action processing implementation
}

// Context Validation
@attached(peer, names: overloaded)
public macro AxiomContext() = #externalMacro(
    module: "AxiomMacros",
    type: "AxiomContextMacro"
)

// Usage
@AxiomContext
@MainActor
public final class UserProfileContext: Context {
    // Validates:
    // - @MainActor requirement
    // - Observable conformance
    // - Lifecycle method implementation
}
```

### Testing APIs

```swift
// Test Utilities
public actor TestClient<S: State, A>: Client {
    public var stateHistory: [S] = []
    public var actionHistory: [A] = []
    
    public func simulateState(_ state: S) {
        // Emit state without processing action
    }
    
    public func verifyAction(_ predicate: (A) -> Bool) -> Bool {
        actionHistory.contains(where: predicate)
    }
}

// Context Testing
@MainActor
public class TestContext<C: Context>: ObservableObject {
    public let context: C
    public private(set) var lifecycleEvents: [LifecycleEvent] = []
    
    public func simulateAppear() async {
        lifecycleEvents.append(.appeared)
        await context.onAppear()
    }
    
    public func simulateDisappear() async {
        lifecycleEvents.append(.disappeared)
        await context.onDisappear()
    }
}

// Integration Testing
public struct AxiomTestCase {
    public static func test<P: Presentation>(
        presentation: P.Type,
        scenario: (P.ContextType) async throws -> Void
    ) async throws {
        let orchestrator = TestOrchestrator()
        let context = await orchestrator.createContext(for: presentation)
        try await scenario(context)
    }
}

// Usage Example
func testTodoListAddition() async throws {
    try await AxiomTestCase.test(presentation: TodoListView.self) { context in
        // Initial state
        XCTAssertEqual(context.todos.count, 0)
        
        // Add todo
        await context.addTodo(title: "Test Todo")
        
        // Verify
        XCTAssertEqual(context.todos.count, 1)
        XCTAssertEqual(context.todos.first?.title, "Test Todo")
    }
}
```

### Performance Monitoring APIs

```swift
public protocol PerformanceMonitor: Actor {
    func startMeasurement(label: String) -> MeasurementToken
    func endMeasurement(_ token: MeasurementToken)
    func getMetrics() async -> PerformanceMetrics
}

public struct MeasurementToken: Sendable {
    let id: UUID
    let label: String
    let startTime: Date
}

public struct PerformanceMetrics: Sendable {
    public let averageStateUpdateTime: TimeInterval
    public let averageActionProcessingTime: TimeInterval
    public let averageNavigationTime: TimeInterval
    public let memoryFootprint: Int
}

// Usage
public actor MetricsCollector: PerformanceMonitor {
    private var measurements: [UUID: Measurement] = [:]
    
    public func measure<T>(
        label: String,
        operation: () async throws -> T
    ) async rethrows -> T {
        let token = startMeasurement(label: label)
        defer { endMeasurement(token) }
        return try await operation()
    }
}

## Implementation Guidelines

### Coding Standards

#### Swift Style Guide

**Naming Conventions**:
- Types and protocols: `UpperCamelCase`
- Functions, properties, variables: `lowerCamelCase`
- Constants: `lowerCamelCase` (not SCREAMING_SNAKE_CASE)
- Acronyms: Treat as words (e.g., `UrlRequest` not `URLRequest` in our codebase)

**Code Organization**:
```swift
// Standard component organization
public actor ExampleClient: BaseClient<ExampleState, ExampleAction> {
    // MARK: - Types
    public enum ExampleAction {
        case load
        case update(String)
    }
    
    // MARK: - Properties
    private let repository: ExampleRepository
    private let validator: ExampleValidator
    
    // MARK: - Initialization
    public init(repository: ExampleRepository, validator: ExampleValidator) {
        self.repository = repository
        self.validator = validator
        super.init(initialState: ExampleState())
    }
    
    // MARK: - Client Protocol
    public override func process(_ action: ExampleAction) async throws {
        // Implementation
    }
    
    // MARK: - Private Methods
    private func validateData(_ data: String) throws {
        // Implementation
    }
}
```

**Access Control**:
- Use `public` for framework APIs
- Use `internal` for module-internal APIs
- Use `private` for implementation details
- Use `fileprivate` sparingly, only when necessary

**Documentation**:
```swift
/// Processes user actions and updates application state.
/// 
/// This client manages the core business logic for user profile operations,
/// including data validation, persistence, and state management.
///
/// - Note: All operations are performed asynchronously and are thread-safe.
public actor UserProfileClient: Client {
    /// Processes the given action and updates state accordingly.
    ///
    /// - Parameter action: The action to process
    /// - Throws: `ValidationError` if the action contains invalid data
    /// - Throws: `NetworkError` if the network operation fails
    public func process(_ action: UserAction) async throws {
        // Implementation
    }
}
```

### Architecture Patterns

#### Dependency Injection Pattern

**Container-Based DI**:
```swift
public actor DependencyContainer {
    private var factories: [ObjectIdentifier: any Factory] = [:]
    private var singletons: [ObjectIdentifier: Any] = [:]
    
    public func register<T>(
        _ type: T.Type,
        scope: Scope = .transient,
        factory: @escaping () async -> T
    ) {
        let key = ObjectIdentifier(type)
        factories[key] = FactoryWrapper(scope: scope, factory: factory)
    }
    
    public func resolve<T>(_ type: T.Type) async -> T {
        let key = ObjectIdentifier(type)
        
        // Check for singleton
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        // Create new instance
        guard let factory = factories[key] else {
            fatalError("No factory registered for \(type)")
        }
        
        let instance = await factory.create()
        
        if factory.scope == .singleton {
            singletons[key] = instance
        }
        
        return instance as! T
    }
}

// Usage in Orchestrator
public actor AppOrchestrator: Orchestrator {
    private let container: DependencyContainer
    
    public func createContext<P: Presentation>(
        for presentation: P.Type
    ) async -> P.ContextType {
        // Resolve dependencies and create context
        let dependencies = await resolveDependencies(for: presentation)
        return await contextFactory.create(presentation, dependencies: dependencies)
    }
}
```

#### State Management Pattern

**Immutable State Updates**:
```swift
public struct AppState: State {
    public let user: User?
    public let settings: Settings
    public let cache: DataCache
    
    // Builder pattern for complex state updates
    public func with(
        user: User? = nil,
        settings: Settings? = nil,
        cache: DataCache? = nil
    ) -> AppState {
        AppState(
            user: user ?? self.user,
            settings: settings ?? self.settings,
            cache: cache ?? self.cache
        )
    }
    
    // Functional updates
    public func updateUser(_ transform: (User?) -> User?) -> AppState {
        with(user: transform(user))
    }
}

// Usage in Client
func process(_ action: AppAction) async throws {
    switch action {
    case .userLoggedIn(let user):
        updateState(state.with(user: user))
        
    case .updateSettings(let updates):
        let newSettings = state.settings.applying(updates)
        updateState(state.with(settings: newSettings))
    }
}
```

#### Middleware Pattern

**Composable Middleware Chain**:
```swift
public struct MiddlewareChain<Input, Output> {
    private let middlewares: [any Middleware<Input, Output>]
    
    public func process(
        _ input: Input,
        finalHandler: (Input) async throws -> Output
    ) async throws -> Output {
        // Build the chain recursively
        func buildChain(
            at index: Int
        ) -> (Input) async throws -> Output {
            guard index < middlewares.count else {
                return finalHandler
            }
            
            let middleware = middlewares[index]
            let next = buildChain(at: index + 1)
            
            return { input in
                try await middleware.process(input, next: next)
            }
        }
        
        let chain = buildChain(at: 0)
        return try await chain(input)
    }
}

// Example: Logging Middleware
public struct LoggingMiddleware<Input, Output>: Middleware {
    let logger: Logger
    
    public func process(
        _ input: Input,
        next: (Input) async throws -> Output
    ) async throws -> Output {
        logger.debug("Processing: \(input)")
        let startTime = Date()
        
        do {
            let output = try await next(input)
            let duration = Date().timeIntervalSince(startTime)
            logger.debug("Completed in \(duration)s")
            return output
        } catch {
            logger.error("Failed: \(error)")
            throw error
        }
    }
}
```

### Best Practices

#### Component Design

1. **Single Responsibility**: Each component should have one clear purpose
2. **Dependency Inversion**: Depend on protocols, not concrete types
3. **Immutability First**: Prefer immutable data structures
4. **Fail Fast**: Validate inputs early and throw descriptive errors
5. **Async by Default**: Design APIs for async operation

#### State Management

1. **No Shared Mutable State**: All state mutations happen within actors
2. **Unidirectional Flow**: State flows in one direction only
3. **Immutable Updates**: Never modify state in-place
4. **State Versioning**: Include version numbers for optimistic updates
5. **Minimal State**: Store only essential data in state

#### Error Handling

1. **Typed Errors**: Use specific error types, not generic Error
2. **Recovery Strategies**: Provide clear recovery paths
3. **User-Friendly Messages**: Separate technical and user messages
4. **Error Boundaries**: Catch errors at appropriate levels
5. **Logging**: Log all errors with context

#### Performance

1. **Lazy Loading**: Load data only when needed
2. **Cancellation**: Support task cancellation throughout
3. **Debouncing**: Debounce rapid user actions
4. **Caching**: Cache expensive computations
5. **Batch Updates**: Group related state updates

#### Testing

1. **Test in Isolation**: Mock dependencies for unit tests
2. **Test Behaviors**: Focus on outcomes, not implementation
3. **Test Edge Cases**: Include error paths and boundaries
4. **Test Concurrency**: Verify thread safety and race conditions
5. **Test Performance**: Include performance benchmarks

### Anti-patterns to Avoid

#### State Anti-patterns

```swift
// ❌ BAD: Mutable state
class BadState {
    var items: [Item] = [] // Mutable array
    var isLoading = false  // Mutable property
}

// ✅ GOOD: Immutable state
struct GoodState: State {
    let items: [Item]      // Immutable array
    let isLoading: Bool    // Immutable property
}

// ❌ BAD: Direct state mutation
client.state.items.append(newItem) // Modifying state directly

// ✅ GOOD: Functional state update
updateState(state.withNewItem(newItem)) // Creating new state
```

#### Dependency Anti-patterns

```swift
// ❌ BAD: Circular dependencies
class ContextA {
    let contextB: ContextB
    init(contextB: ContextB) {
        self.contextB = contextB
        contextB.contextA = self // Circular reference
    }
}

// ✅ GOOD: Acyclic dependencies
class ContextA {
    let client: ClientA
    init(client: ClientA) {
        self.client = client
    }
}

// ❌ BAD: Hidden dependencies
class BadClient {
    func process(_ action: Action) {
        let api = NetworkAPI.shared // Hidden singleton dependency
        api.request(...)
    }
}

// ✅ GOOD: Explicit dependencies
class GoodClient {
    let networkCapability: NetworkCapability
    
    init(networkCapability: NetworkCapability) {
        self.networkCapability = networkCapability
    }
}
```

#### Concurrency Anti-patterns

```swift
// ❌ BAD: Shared mutable state without protection
class BadCache {
    var cache: [String: Data] = [] // Unsafe concurrent access
    
    func get(_ key: String) -> Data? {
        cache[key] // Race condition
    }
}

// ✅ GOOD: Actor-isolated state
actor GoodCache {
    private var cache: [String: Data] = []
    
    func get(_ key: String) -> Data? {
        cache[key] // Thread-safe access
    }
}

// ❌ BAD: Blocking the main thread
@MainActor
func badMethod() {
    let data = syncNetworkCall() // Blocks UI
    updateUI(with: data)
}

// ✅ GOOD: Async operations
@MainActor
func goodMethod() async {
    let data = await asyncNetworkCall() // Non-blocking
    updateUI(with: data)
}
```

#### Navigation Anti-patterns

```swift
// ❌ BAD: Direct navigation from Client
actor BadClient: Client {
    func process(_ action: Action) async {
        // ...
        await navigationController.push(SomeView()) // Breaks architecture
    }
}

// ✅ GOOD: Navigation through proper channels
actor GoodClient: Client {
    func process(_ action: Action) async throws {
        // Process action and update state
        // Navigation happens in Context/Orchestrator
    }
}
```

## Performance Considerations

### Performance Requirements

#### Response Time Targets

1. **State Updates**: < 5ms from Client state change to Context notification
2. **UI Rendering**: < 10ms from Context update to SwiftUI render
3. **Navigation**: < 10ms for route transitions
4. **Action Processing**: < 50ms for typical user actions
5. **App Launch**: < 1s cold start, < 100ms warm start

#### Memory Targets

1. **Base Memory**: < 50MB framework overhead
2. **State Memory**: < 1MB per Client instance
3. **Navigation Stack**: < 10MB for 50-screen history
4. **Cache Limits**: Configurable with sensible defaults
5. **Leak Prevention**: Zero memory leaks in framework code

#### Concurrency Targets

1. **Actor Contention**: < 1ms average wait time
2. **Task Startup**: < 1ms to create and start tasks
3. **Cancellation**: < 10ms to cancel task hierarchies
4. **Thread Pool**: Efficient use of system thread pool
5. **Deadlock Prevention**: Zero deadlocks guaranteed

### Optimization Strategies

#### State Optimization

```swift
// Efficient State Design
public struct OptimizedState: State {
    // Use value types for efficient copying
    public let items: [Item]
    
    // Use computed properties for derived state
    public var itemCount: Int { items.count }
    public var isEmpty: Bool { items.isEmpty }
    
    // Lazy computation for expensive operations
    private var _sortedItems: [Item]?
    public var sortedItems: [Item] {
        mutating get {
            if _sortedItems == nil {
                _sortedItems = items.sorted { $0.date > $1.date }
            }
            return _sortedItems!
        }
    }
}

// Copy-on-write optimization
public struct LargeDataState: State {
    private var storage: Storage
    
    private class Storage {
        var data: [LargeItem]
        
        init(data: [LargeItem]) {
            self.data = data
        }
    }
    
    // Implement copy-on-write
    private var isKnownUniquelyReferenced: Bool {
        isKnownUniquelyReferenced(&storage)
    }
    
    public mutating func append(_ item: LargeItem) {
        if !isKnownUniquelyReferenced {
            storage = Storage(data: storage.data)
        }
        storage.data.append(item)
    }
}
```

#### Async Stream Optimization

```swift
// Efficient AsyncStream implementation
public actor OptimizedClient: Client {
    private let streamBuffer = StreamBuffer<StateType>()
    
    public var stateStream: AsyncStream<StateType> {
        streamBuffer.stream
    }
    
    private func updateState(_ newState: StateType) {
        // Deduplicate updates
        guard newState != currentState else { return }
        
        currentState = newState
        streamBuffer.send(newState)
    }
}

// Buffer implementation with backpressure
actor StreamBuffer<T: Sendable> {
    private var continuations: [UUID: AsyncStream<T>.Continuation] = [:]
    private let maxBufferSize = 10
    private var buffer: [T] = []
    
    var stream: AsyncStream<T> {
        AsyncStream(bufferingPolicy: .bufferingNewest(maxBufferSize)) { continuation in
            let id = UUID()
            continuations[id] = continuation
            
            // Send buffered values
            for value in buffer {
                continuation.yield(value)
            }
            
            continuation.onTermination = { _ in
                Task { await self.removeContinuation(id) }
            }
        }
    }
}
```

#### Navigation Optimization

```swift
// Preloading and caching
public actor OptimizedOrchestrator: Orchestrator {
    private let contextCache = ContextCache()
    private let preloader = RoutePreloader()
    
    public func navigate(to route: Route) async {
        // Preload next likely routes
        await preloader.preloadAdjacentRoutes(from: route)
        
        // Check cache first
        if let cachedContext = await contextCache.get(route) {
            await navigationFlow.navigate(to: route, context: cachedContext)
            return
        }
        
        // Create and cache new context
        let context = await createContext(for: route)
        await contextCache.set(route, context: context)
        await navigationFlow.navigate(to: route, context: context)
    }
}

// Smart preloading based on user patterns
actor RoutePreloader {
    private let predictor = RoutePredictor()
    
    func preloadAdjacentRoutes(from currentRoute: Route) async {
        let likelyRoutes = await predictor.predictNextRoutes(
            from: currentRoute,
            limit: 3
        )
        
        for route in likelyRoutes {
            Task.detached(priority: .background) {
                await self.preloadRoute(route)
            }
        }
    }
}
```

### Profiling Guidelines

#### Performance Monitoring

```swift
// Built-in performance tracking
public actor PerformanceProfiler {
    private var metrics: [MetricType: [Measurement]] = [:]
    
    public func measure<T>(
        _ type: MetricType,
        operation: () async throws -> T
    ) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - start
            Task {
                await self.record(type: type, duration: duration)
            }
        }
        
        return try await operation()
    }
    
    public func getReport() async -> PerformanceReport {
        var report = PerformanceReport()
        
        for (type, measurements) in metrics {
            let durations = measurements.map { $0.duration }
            report.metrics[type] = MetricSummary(
                count: measurements.count,
                average: durations.average,
                median: durations.median,
                p95: durations.percentile(95),
                p99: durations.percentile(99)
            )
        }
        
        return report
    }
}

// Automated performance regression detection
public struct PerformanceRegression {
    public static func detectRegressions(
        current: PerformanceReport,
        baseline: PerformanceReport,
        threshold: Double = 0.1 // 10% regression threshold
    ) -> [RegressionWarning] {
        var warnings: [RegressionWarning] = []
        
        for (metric, currentSummary) in current.metrics {
            guard let baselineSummary = baseline.metrics[metric] else {
                continue
            }
            
            let regression = (currentSummary.average - baselineSummary.average) 
                           / baselineSummary.average
            
            if regression > threshold {
                warnings.append(RegressionWarning(
                    metric: metric,
                    baselineAverage: baselineSummary.average,
                    currentAverage: currentSummary.average,
                    regressionPercent: regression * 100
                ))
            }
        }
        
        return warnings
    }
}
```

#### Memory Profiling

```swift
// Memory tracking
public actor MemoryProfiler {
    private let baseline = MemorySnapshot.current
    
    public func captureSnapshot(label: String) -> MemorySnapshot {
        let snapshot = MemorySnapshot.current
        let delta = snapshot.residentSize - baseline.residentSize
        
        return MemorySnapshot(
            label: label,
            residentSize: snapshot.residentSize,
            virtualSize: snapshot.virtualSize,
            deltaFromBaseline: delta
        )
    }
    
    public func detectLeaks(
        perform operation: () async -> Void
    ) async -> [PotentialLeak] {
        let beforeSnapshot = captureSnapshot(label: "before")
        
        await operation()
        
        // Force cleanup
        for _ in 0..<3 {
            await Task.yield()
        }
        
        let afterSnapshot = captureSnapshot(label: "after")
        
        // Check for memory growth
        let growth = afterSnapshot.residentSize - beforeSnapshot.residentSize
        
        if growth > 1_000_000 { // 1MB threshold
            return [PotentialLeak(
                sizeDelta: growth,
                beforeSnapshot: beforeSnapshot,
                afterSnapshot: afterSnapshot
            )]
        }
        
        return []
    }
}
```

### Resource Management

#### Lifecycle Management

```swift
// Automatic resource cleanup
public actor ResourceManager {
    private var resources: [ResourceHandle] = []
    
    public func acquire<R: Resource>(_ resource: R) async -> ResourceHandle {
        let handle = ResourceHandle(resource: resource)
        resources.append(handle)
        
        await resource.initialize()
        
        return handle
    }
    
    public func releaseAll() async {
        await withTaskGroup(of: Void.self) { group in
            for handle in resources {
                group.addTask {
                    await handle.release()
                }
            }
        }
        resources.removeAll()
    }
    
    deinit {
        Task {
            await releaseAll()
        }
    }
}

// Smart caching with memory pressure handling
public actor AdaptiveCache<Key: Hashable, Value> {
    private var storage: [Key: CacheEntry<Value>] = [:]
    private let maxSize: Int
    private let maxAge: TimeInterval
    
    public init(maxSize: Int = 100, maxAge: TimeInterval = 300) {
        self.maxSize = maxSize
        self.maxAge = maxAge
        
        // Monitor memory pressure
        Task {
            await monitorMemoryPressure()
        }
    }
    
    private func monitorMemoryPressure() async {
        for await notification in NotificationCenter.default.notifications(
            named: UIApplication.didReceiveMemoryWarningNotification
        ) {
            await evacuate(percentage: 0.5) // Remove 50% of cache
        }
    }
    
    public func evacuate(percentage: Double) async {
        let targetSize = Int(Double(storage.count) * (1 - percentage))
        
        // Remove oldest entries first
        let sorted = storage.sorted { $0.value.timestamp < $1.value.timestamp }
        let toRemove = sorted.prefix(storage.count - targetSize)
        
        for (key, _) in toRemove {
            storage.removeValue(forKey: key)
        }
    }
}
```

#### Connection Pooling

```swift
// Efficient connection management
public actor ConnectionPool<Connection: NetworkConnection> {
    private var available: [Connection] = []
    private var inUse: Set<Connection> = []
    private let maxConnections: Int
    
    public func acquire() async throws -> Connection {
        // Reuse existing connection
        if let connection = available.popLast() {
            inUse.insert(connection)
            return connection
        }
        
        // Create new connection if under limit
        guard inUse.count < maxConnections else {
            // Wait for available connection
            return try await waitForAvailable()
        }
        
        let connection = try await Connection.create()
        inUse.insert(connection)
        return connection
    }
    
    public func release(_ connection: Connection) {
        inUse.remove(connection)
        
        if connection.isValid {
            available.append(connection)
        } else {
            Task {
                await connection.close()
            }
        }
    }
}
```

## Testing Strategy

### Test Architecture

#### Test Structure

```
Tests/
├── UnitTests/
│   ├── ClientTests/
│   │   ├── StateTests.swift
│   │   ├── ActionProcessingTests.swift
│   │   └── MockCapabilities.swift
│   ├── ContextTests/
│   │   ├── LifecycleTests.swift
│   │   ├── StateObservationTests.swift
│   │   └── ErrorBoundaryTests.swift
│   ├── CapabilityTests/
│   │   ├── InitializationTests.swift
│   │   ├── AvailabilityTests.swift
│   │   └── MockPlatformAPIs.swift
│   └── OrchestratorTests/
│       ├── NavigationTests.swift
│       ├── DependencyInjectionTests.swift
│       └── MockNavigationFlow.swift
├── IntegrationTests/
│   ├── EndToEndFlowTests.swift
│   ├── NavigationFlowTests.swift
│   ├── ErrorRecoveryTests.swift
│   └── PerformanceTests.swift
├── SnapshotTests/
│   ├── PresentationTests/
│   │   └── __Snapshots__/
│   └── ErrorUITests/
│       └── __Snapshots__/
└── TestUtilities/
    ├── TestDoubles/
    ├── Assertions/
    └── Fixtures/
```

#### Test Pyramid

1. **Unit Tests (70%)**
   - Fast, isolated component tests
   - Mock all dependencies
   - Test individual methods and behaviors
   - Sub-millisecond execution time

2. **Integration Tests (20%)**
   - Test component interactions
   - Use real implementations where possible
   - Test complete user flows
   - Sub-second execution time

3. **End-to-End Tests (10%)**
   - Full application tests
   - Real UI, real services
   - Critical user journeys only
   - Accept longer execution times

### Test Patterns

#### Client Testing Pattern

```swift
// Test doubles for isolation
actor TestCapability: NetworkCapability {
    var requestResponses: [String: Result<Data, Error>] = [:]
    var requestCount = 0
    
    func request(_ endpoint: Endpoint) async throws -> Data {
        requestCount += 1
        
        guard let response = requestResponses[endpoint.path] else {
            throw NetworkError.notFound
        }
        
        return try response.get()
    }
}

// Client test example
class UserClientTests: XCTestCase {
    var client: UserClient!
    var mockNetwork: TestCapability!
    
    override func setUp() async throws {
        mockNetwork = TestCapability()
        client = UserClient(network: mockNetwork)
    }
    
    func testLoadUserSuccess() async throws {
        // Arrange
        let userData = try JSONEncoder().encode(User.fixture())
        await mockNetwork.setResponse(
            for: "/users/123",
            response: .success(userData)
        )
        
        // Act
        try await client.process(.loadUser(id: "123"))
        let state = await client.currentState
        
        // Assert
        XCTAssertNotNil(state.user)
        XCTAssertEqual(state.user?.id, "123")
        XCTAssertFalse(state.isLoading)
        XCTAssertEqual(await mockNetwork.requestCount, 1)
    }
    
    func testLoadUserFailure() async throws {
        // Arrange
        await mockNetwork.setResponse(
            for: "/users/123",
            response: .failure(NetworkError.serverError(500))
        )
        
        // Act & Assert
        await XCTAssertThrowsError(
            try await client.process(.loadUser(id: "123"))
        ) { error in
            XCTAssertTrue(error is NetworkError)
        }
    }
}
```

#### Context Testing Pattern

```swift
// Context lifecycle testing
@MainActor
class TodoContextTests: XCTestCase {
    func testLifecycleEvents() async throws {
        // Arrange
        let client = TestTodoClient()
        let context = TodoListContext(client: client)
        let lifecycleMonitor = LifecycleMonitor()
        
        // Act
        await lifecycleMonitor.observe(context) {
            await context.onAppear()
            await context.onDisappear()
        }
        
        // Assert
        XCTAssertEqual(lifecycleMonitor.events, [
            .willAppear,
            .didAppear,
            .willDisappear,
            .didDisappear
        ])
    }
    
    func testStateObservation() async throws {
        // Arrange
        let client = TestTodoClient()
        let context = TodoListContext(client: client)
        var observations: [TodoListState] = []
        
        let cancellable = context.$todos.sink { todos in
            observations.append(TodoListState(items: todos))
        }
        
        // Act
        await client.simulateState(TodoListState(items: [TodoItem.fixture()]))
        await client.simulateState(TodoListState(items: [TodoItem.fixture(), TodoItem.fixture()]))
        
        // Assert
        XCTAssertEqual(observations.count, 3) // Initial + 2 updates
        XCTAssertEqual(observations.last?.items.count, 2)
        
        cancellable.cancel()
    }
}
```

#### Navigation Testing Pattern

```swift
// Navigation flow testing
class NavigationTests: XCTestCase {
    var orchestrator: TestOrchestrator!
    var navigationFlow: NavigationFlow!
    
    override func setUp() {
        navigationFlow = NavigationFlow()
        orchestrator = TestOrchestrator(navigationFlow: navigationFlow)
    }
    
    func testNavigationWithMiddleware() async throws {
        // Arrange
        let authMiddleware = MockAuthMiddleware(isAuthenticated: false)
        navigationFlow.addMiddleware(authMiddleware)
        
        // Act
        let result = try await navigationFlow.navigate(
            to: AppRoute.profile(userId: "123")
        )
        
        // Assert
        switch result {
        case .redirected(let route):
            XCTAssertEqual(route, AppRoute.login(returnTo: .profile(userId: "123")))
        default:
            XCTFail("Expected redirect to login")
        }
    }
    
    func testDeepLinking() async throws {
        // Arrange
        let url = URL(string: "app://profile/123")!
        
        // Act
        let route = try await orchestrator.handleDeepLink(url)
        
        // Assert
        XCTAssertEqual(route, AppRoute.profile(userId: "123"))
        XCTAssertEqual(navigationFlow.currentRoute, route)
    }
}
```

### Coverage Requirements

#### Code Coverage Targets

1. **Framework Core**: 95% minimum coverage
   - Client protocol implementations: 100%
   - Context protocol implementations: 100%
   - Navigation system: 95%
   - Error handling: 95%

2. **Public APIs**: 100% coverage required
   - All public methods must have tests
   - All error cases must be tested
   - All edge cases must be covered

3. **Integration Points**: 90% minimum
   - Component interactions
   - Navigation flows
   - Error propagation

#### Coverage Reporting

```swift
// Coverage configuration
let package = Package(
    name: "Axiom",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [...],
    dependencies: [...],
    targets: [
        .target(
            name: "Axiom",
            dependencies: ["AxiomMacros"]
        ),
        .testTarget(
            name: "AxiomTests",
            dependencies: ["Axiom", "AxiomTesting"],
            resources: [.copy("__Snapshots__")]
        )
    ]
)

// Coverage script
#!/bin/bash
swift test --enable-code-coverage
xcrun llvm-cov report \
    .build/debug/AxiomPackageTests.xctest/Contents/MacOS/AxiomPackageTests \
    -instr-profile=.build/debug/codecov/default.profdata \
    -ignore-filename-regex=".*(Tests|Mocks|Generated).*"
```

### Integration Test Approach

#### Component Integration Tests

```swift
// Full stack integration test
class TodoFlowIntegrationTests: XCTestCase {
    var app: TestApplication!
    
    override func setUp() async throws {
        app = try await TestApplication.launch(
            configuration: .integration
        )
    }
    
    func testCompleteTodoFlow() async throws {
        // Navigate to todo list
        try await app.navigate(to: .todoList)
        
        // Verify initial state
        let todoContext = try await app.currentContext(as: TodoListContext.self)
        XCTAssertTrue(todoContext.todos.isEmpty)
        
        // Add todo
        await todoContext.addTodo(title: "Integration Test Todo")
        
        // Verify todo added
        XCTAssertEqual(todoContext.todos.count, 1)
        XCTAssertEqual(todoContext.todos.first?.title, "Integration Test Todo")
        
        // Toggle completion
        if let todo = todoContext.todos.first {
            await todoContext.toggleTodo(todo)
            XCTAssertTrue(todoContext.todos.first?.isCompleted ?? false)
        }
        
        // Navigate to detail
        if let todo = todoContext.todos.first {
            try await app.navigate(to: .todoDetail(id: todo.id))
            
            let detailContext = try await app.currentContext(as: TodoDetailContext.self)
            XCTAssertEqual(detailContext.todo.id, todo.id)
        }
    }
}
```

#### Performance Integration Tests

```swift
class PerformanceIntegrationTests: XCTestCase {
    func testStateUpdatePerformance() async throws {
        let client = TodoClient(repository: InMemoryTodoRepository())
        
        await measure(
            metrics: [XCTClockMetric(), XCTMemoryMetric()]
        ) {
            // Add 1000 todos
            for i in 0..<1000 {
                try await client.process(.addTodo(title: "Todo \(i)"))
            }
        }
        
        // Verify performance requirements
        XCTAssertLessThan(averageTime, 0.005) // 5ms per update
        XCTAssertLessThan(peakMemory, 10_000_000) // 10MB max
    }
    
    func testNavigationPerformance() async throws {
        let app = try await TestApplication.launch()
        
        await measure(metrics: [XCTClockMetric()]) {
            // Navigate through 50 screens
            for i in 0..<50 {
                try await app.navigate(to: .screen(index: i))
            }
        }
        
        // Verify navigation performance
        XCTAssertLessThan(averageTime, 0.01) // 10ms per navigation
    }
}
```

#### Error Recovery Integration Tests

```swift
class ErrorRecoveryIntegrationTests: XCTestCase {
    func testNetworkErrorRecovery() async throws {
        // Arrange
        let network = TestNetworkCapability()
        let client = UserClient(network: network)
        let context = UserContext(client: client)
        
        // Simulate network failure
        await network.simulateError(.noConnection)
        
        // Act - First attempt fails
        await context.loadUser(id: "123")
        XCTAssertNotNil(context.error)
        
        // Fix network
        await network.clearErrors()
        
        // Retry
        await context.retry()
        
        // Assert - Recovery successful
        XCTAssertNil(context.error)
        XCTAssertNotNil(context.user)
    }
    
    func testCircuitBreakerIntegration() async throws {
        // Arrange
        let circuitBreaker = CircuitBreakerStrategy(
            threshold: 3,
            timeout: 1.0
        )
        let context = TestContext(recoveryStrategy: circuitBreaker)
        
        // Act - Trigger circuit breaker
        for _ in 0..<3 {
            await context.simulateError(NetworkError.timeout(5))
        }
        
        // Assert - Circuit open
        await context.simulateError(NetworkError.timeout(5))
        XCTAssertTrue(context.lastErrorHandled)
        XCTAssertEqual(context.errorCount, 3) // No 4th attempt
        
        // Wait for timeout
        try await Task.sleep(for: .seconds(1.1))
        
        // Circuit should be half-open, ready to test
        await context.simulateSuccess()
        XCTAssertEqual(context.successCount, 1)
    }
}
```

## Appendices

### Migration Guide

#### Migrating from Version 0.x to 1.0

**Breaking Changes**:

1. **State Protocol Changes**
   ```swift
   // Old (0.x)
   protocol State {
       var id: UUID { get }
   }
   
   // New (1.0)
   protocol State: Equatable, Hashable, Sendable {
       // No required properties
   }
   
   // Migration:
   // Remove id property unless needed for business logic
   // Add Equatable and Hashable conformance
   ```

2. **Client API Changes**
   ```swift
   // Old (0.x)
   class Client {
       @Published var state: State
       func dispatch(_ action: Action)
   }
   
   // New (1.0)
   actor Client {
       var stateStream: AsyncStream<State> { get }
       func process(_ action: Action) async throws
   }
   
   // Migration:
   // Convert class to actor
   // Replace @Published with AsyncStream
   // Make process async and throwing
   ```

3. **Context Lifecycle Changes**
   ```swift
   // Old (0.x)
   class Context: ObservableObject {
       func viewDidAppear()
       func viewDidDisappear()
   }
   
   // New (1.0)
   @MainActor
   class Context: ObservableObject {
       func onAppear() async
       func onDisappear() async
   }
   
   // Migration:
   // Add @MainActor annotation
   // Rename lifecycle methods
   // Make methods async
   ```

**Migration Steps**:

1. **Update Dependencies**
   ```swift
   // Package.swift
   dependencies: [
       .package(url: "https://github.com/axiom/axiom.git", from: "1.0.0")
   ]
   ```

2. **Run Migration Tool**
   ```bash
   swift run axiom-migrate --from 0.x --to 1.0 Sources/
   ```

3. **Manual Updates**
   - Review generated changes
   - Update custom Client implementations
   - Convert synchronous code to async
   - Add error handling where needed

4. **Testing**
   - Run existing tests
   - Add new tests for async behavior
   - Verify performance requirements

### Glossary

**Actor**: Swift's concurrency primitive that provides isolated state access and prevents data races.

**Action**: A message sent to a Client to trigger state changes or side effects.

**Capability**: An abstraction over external system access (camera, network, etc.) with lifecycle management.

**Client**: An actor-based component that owns state and processes actions to produce new state.

**Context**: A MainActor-bound component that mediates between Presentations and Clients.

**Middleware**: A composable unit that intercepts and potentially modifies navigation requests.

**Orchestrator**: The top-level component that creates Contexts and manages navigation.

**Presentation**: A SwiftUI View that binds to a single Context for its data and behavior.

**Route**: A type-safe navigation destination with associated parameters and metadata.

**State**: An immutable value type that represents the data for a specific domain.

**Unidirectional Flow**: An architectural pattern where data flows in one direction: User → Presentation → Context → Client → State → Context → Presentation.

### References

#### Swift Resources

1. **Swift Concurrency**
   - [Swift Concurrency Guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
   - [WWDC: Meet async/await](https://developer.apple.com/videos/play/wwdc2021/10132/)
   - [Swift Evolution: Actors](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)

2. **SwiftUI**
   - [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
   - [Observation Framework](https://developer.apple.com/documentation/observation)
   - [SwiftUI Performance](https://developer.apple.com/videos/play/wwdc2023/10160/)

3. **Swift Macros**
   - [Swift Macros Guide](https://docs.swift.org/swift-book/ReferenceManual/Macros.html)
   - [SwiftSyntax Documentation](https://github.com/apple/swift-syntax)

#### Architecture Resources

1. **Unidirectional Data Flow**
   - [Redux Architecture](https://redux.js.org/understanding/thinking-in-redux/motivation)
   - [The Elm Architecture](https://guide.elm-lang.org/architecture/)
   - [Flux Pattern](https://facebook.github.io/flux/docs/in-depth-overview)

2. **Actor Model**
   - [Actor Model Theory](https://en.wikipedia.org/wiki/Actor_model)
   - [Erlang/OTP Design Principles](https://erlang.org/doc/design_principles/des_princ.html)

3. **Mobile Architecture**
   - [iOS Architecture Patterns](https://developer.apple.com/documentation/uikit/mvc)
   - [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
   - [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)

#### Performance Resources

1. **Profiling Tools**
   - [Instruments User Guide](https://help.apple.com/instruments/mac/current/)
   - [Memory Graph Debugger](https://developer.apple.com/documentation/xcode/diagnosing-memory-disk-and-energy-issues)
   - [Time Profiler](https://developer.apple.com/videos/play/wwdc2021/10211/)

2. **Optimization Guides**
   - [Swift Performance](https://github.com/apple/swift/blob/main/docs/OptimizationTips.rst)
   - [Reducing Memory Footprint](https://developer.apple.com/documentation/xcode/reducing-your-app-s-memory-use)

#### Testing Resources

1. **Testing Frameworks**
   - [XCTest Documentation](https://developer.apple.com/documentation/xctest)
   - [Swift Testing](https://github.com/apple/swift-testing)
   - [Snapshot Testing](https://github.com/pointfreeco/swift-snapshot-testing)

2. **Testing Best Practices**
   - [iOS Testing Best Practices](https://developer.apple.com/videos/play/wwdc2023/10169/)
   - [Test-Driven Development](https://www.martinfowler.com/bliki/TestDrivenDevelopment.html)
```