# RFC-001: Axiom Foundation Architecture

**RFC Number**: 001  
**Title**: Axiom Foundation Architecture  
**Status**: Draft  
**Type**: Architecture  
**Created**: 2025-01-06  
**Updated**: 2025-06-05  
**Supersedes**: None  
**Superseded-By**: None

## Abstract

This RFC establishes the foundation architecture for the Axiom framework, defining the complete architectural blueprint. It specifies six immutable component types, ten core architectural constraints with testable acceptance criteria, core protocols with clear test boundaries, three key performance metrics, and comprehensive navigation architecture requirements. This foundation ensures thread safety, testability, and maintainability by leveraging Swift's actor model for concurrency and SwiftUI for reactive UI updates.

The foundation architecture enforces clear boundaries between components through compile-time and runtime validation, preventing common iOS development issues such as race conditions, circular dependencies, and memory leaks. Each requirement includes specific acceptance criteria enabling test-driven development cycles.

By establishing these immutable constraints and clear component relationships, Axiom enables teams to build maintainable iOS applications with confidence. The framework's strict architectural rules eliminate entire categories of bugs while its performance guarantees ensure smooth user experiences across all supported devices.

## Motivation

### Problem Statement

iOS development suffers from several recurring architectural problems:

1. **Race Conditions**: Concurrent access to shared mutable state causes unpredictable behavior
2. **Circular Dependencies**: Components with bidirectional dependencies create maintenance nightmares
3. **Memory Leaks**: Retain cycles from improper ownership patterns waste resources
4. **Testing Difficulties**: Tightly coupled components resist isolation for unit testing
5. **State Inconsistency**: Multiple sources of truth lead to synchronization bugs

### Current Limitations

Current iOS architectures (MVC, MVVM, VIPER) address some issues but lack strict constraints and comprehensive foundations. They often allow architectural violations that lead to technical debt, provide insufficient guidance on concurrency patterns, and lack built-in testability guarantees.

### Use Cases

Axiom provides a complete architectural foundation with immutable rules, defined protocols, performance targets, and clear development roadmap from inception to release. Key use cases include:

1. **Large Team Development**: Teams building complex iOS applications need consistent architectural patterns that prevent common mistakes and enable parallel development without conflicts
2. **High-Performance Applications**: Apps requiring smooth 60fps UI updates with complex state management benefit from Axiom's performance guarantees and efficient state propagation

## Specification

### Component Type Requirements

- **Six Immutable Component Types**:
  - Requirement: Framework defines exactly six component types (Capability, State, Client, Orchestrator, Context, Presentation)
  - Acceptance: Component type enumeration contains exactly six cases with @frozen preventing new cases
  - Boundary: Type system enforces no additional component types
  - Refactoring: Consider protocol extensions for shared behavior

- **Component Dependencies**:
  - Requirement: Each component type has strictly defined dependency rules
  - Acceptance: Build system validation script detects invalid dependencies and fails build with clear error messages
  - Boundary: Build-time dependency analyzer validates module dependencies match architectural constraints
  - Refactoring: Use phantom types for stronger compile-time guarantees

### Core Architectural Constraints

- **Client Isolation**:
  - Requirement: Clients can ONLY depend on Capabilities and cannot communicate with other Clients
  - Acceptance: Build validation rejects Client importing another Client type
  - Boundary: Client isolation test with 5 clients shows no cross-references
  - Refactoring: Consider mediator pattern if inter-client communication needed

- **Context Dependencies**:
  - Requirement: Contexts can ONLY depend on Clients and downstream Contexts, never directly on Capabilities
  - Acceptance: Static analysis detects direct Capability imports in Context modules during build validation
  - Boundary: Dependency graph tool shows zero Capability → Context edges
  - Refactoring: Extract capability facades if indirect access patterns emerge

- **Unidirectional Flow**:
  - Requirement: Dependencies flow strictly: Orchestrator → Context → Client → Capability → System
  - Acceptance: Reverse dependency attempts fail at compile time
  - Boundary: Dependency analyzer confirms unidirectional graph
  - Refactoring: Consider dependency injection for testing flexibility

- **Presentation-Context Binding**:
  - Requirement: Each Presentation has exactly ONE Context dependency with matching lifetimes
  - Acceptance: Framework's @PresentationContext property wrapper enforces single context binding at runtime initialization
  - Boundary: Presentation-context pairing test shows 1:1 correspondence for 100 presentations
  - Refactoring: Use environment objects for shared state if needed

- **State Ownership**:
  - Requirement: Each State is owned by exactly ONE Client as immutable value types
  - Acceptance: Shared state attempts trigger compiler error
  - Boundary: State ownership test validates 1:1 client-state pairing
  - Refactoring: Consider state partitioning for large domains

- **Component Lifetimes**:
  - Requirement: Clients and States are singletons, Contexts per-presentation, Capabilities transient
  - Acceptance: Lifetime violations detected at runtime
  - Boundary: Component lifecycle test validates all lifetime rules
  - Refactoring: Implement lifecycle observers for debugging

- **DAG Composition**:
  - Requirement: Both Capabilities and Contexts form directed acyclic graphs
  - Acceptance: Topological sort succeeds for all component dependency graphs
  - Boundary: Graph validation with 20 nodes completes without cycles
  - Refactoring: Cache dependency resolution for performance

- **Error Boundaries**:
  - Requirement: Contexts handle all errors thrown by their associated Clients through async error propagation
  - Acceptance: Context error handlers receive all errors thrown from Client actor methods within the same Task
  - Boundary: Error boundary test validates all thrown Swift Error types from Client methods are propagated to Context error handlers
  - Refactoring: Implement error recovery strategies per error type

- **Concurrency Safety**:
  - Requirement: All state mutations are actor-isolated with documented await points
  - Acceptance: No deadlocks occur when Clients call other Clients through defined async protocols
  - Boundary: Stress test with 10 actors making cross-actor calls shows completion within 1 second
  - Refactoring: Consider priority inversion mitigation

- **State Immutability**:
  - Requirement: All state mutations produce new immutable value type instances
  - Acceptance: Concurrent mutations produce consistent final state
  - Boundary: 1000 concurrent state mutations show no data corruption
  - Refactoring: Implement copy-on-write for large states

### Protocol Requirements

- **Capability Protocol**:
  - Requirement: Manages external system access with lifecycle methods
  - Acceptance: Capability mock can transition through all states in < 10ms
  - Boundary: States include: available, unavailable, restricted, unknown
  - Refactoring: Extract common capability behaviors to protocol extension

- **State Protocol**:
  - Requirement: Value type with Equatable conformance for change detection
  - Acceptance: Protocol conformance test validates all stored properties are immutable
  - Boundary: Protocol extension validates all stored properties are let-declared
  - Refactoring: Codable conformance for serialization support

- **Client Protocol**:
  - Requirement: Actor-based container with state stream and action processing
  - Acceptance: Test harness receives all state updates within 5ms
  - Boundary: Test receives initial state + all subsequent mutations in order
  - Refactoring: Consider AsyncSequence for more flexible streaming

- **Context Protocol**:
  - Requirement: MainActor-bound coordinator with lifecycle and observation
  - Acceptance: Memory usage remains stable (±10%) after processing 1000 actions
  - Boundary: Lifecycle methods must be independently testable
  - Refactoring: Implement weak observation to prevent retain cycles

- **Orchestrator Protocol**:
  - Requirement: Application coordinator with context factory and capability monitoring
  - Acceptance: Test orchestrator creates 50 contexts with up to 5 client dependencies and standard UI bindings in < 500ms
  - Boundary: Dependency injection must be overridable for testing
  - Refactoring: Use builder pattern for complex initialization

- **Presentation Protocol**:
  - Requirement: SwiftUI View with single context binding and body computation
  - Acceptance: Compilation fails when accessing multiple contexts
  - Boundary: Body must be pure function of context state
  - Refactoring: Extract reusable view modifiers for common patterns

### Performance Requirements

- **State Propagation**:
  - Requirement: State changes propagate from mutation to UI in < 16ms
  - Acceptance: State propagation completes within 16ms on iPhone 12 or newer under standard test conditions
  - Boundary: Frame rate monitor shows no drops below 60fps
  - Refactoring: Batch updates if frequency exceeds display refresh rate

- **Memory Overhead**:
  - Requirement: Framework allocations < 1KB per component instance
  - Acceptance: Instruments shows < 1KB framework allocations
  - Boundary: Memory profiler validates overhead limits
  - Refactoring: Pool frequently allocated objects

- **Component Initialization**:
  - Requirement: Any component initializes in < 50ms
  - Acceptance: Component creation benchmark shows p99 < 50ms
  - Boundary: Initialization timing across all component types
  - Refactoring: Lazy initialization for expensive resources

### Concurrency Model Requirements

- **Actor Reentrancy**:
  - Requirement: Actor methods handle potential reentrancy through explicit state validation
  - Acceptance: Actor methods validate preconditions after each await point and handle state changes gracefully
  - Boundary: Test with 100 concurrent async calls showing consistent state despite reentrancy
  - Refactoring: Consider using actor-isolated serial queues for critical sections requiring atomicity

- **Task Cancellation**:
  - Requirement: Task cancellation propagates from Context to all associated Clients
  - Acceptance: All client tasks cancelled within 10ms of context cancellation
  - Boundary: Test with 5 clients per context, each with 3 active tasks
  - Refactoring: Implement cancellation tokens for complex flows

### Package Modularity Requirements

- **Module Structure**:
  - Requirement: Framework splits into Core, UI, and Testing modules
  - Acceptance: Zero import statements between modules except defined dependencies
  - Boundary: Swift Package Manager validates module boundaries
  - Refactoring: Extract additional modules as framework grows

- **Minimum Example**:
  - Requirement: Complete TODO app demonstrates all 6 component types
  - Acceptance: Example app passes 10 functional tests covering CRUD operations
  - Boundary: Example app uses only framework-provided protocols and types
  - Refactoring: Create template generators for common patterns

### Navigation Architecture Requirements

- **Navigation Component Type (E1)**:
  - Requirement: Navigation is an Orchestrator service, not a separate component type
  - Acceptance: NavigationService protocol conforms to Orchestrator capabilities
  - Boundary: Type system prevents navigation implementation outside Orchestrator
  - Refactoring: Extract navigation coordination into dedicated Orchestrator extension

- **Navigation State (E2)**:
  - Requirement: Navigation state is global state owned by Orchestrator
  - Acceptance: Concurrent navigation requests are serialized with last-write-wins semantics, verified by sequential state history
  - Boundary: Navigation state mutations only through Orchestrator methods
  - Refactoring: Implement navigation history stack for back navigation

- **Navigation Request Flow (E3)**:
  - Requirement: Navigation flows from Presentation → Context → Orchestrator
  - Acceptance: Direct Presentation to Orchestrator navigation fails compilation
  - Boundary: Context mediates all navigation requests from its Presentation
  - Refactoring: Add navigation middleware for cross-cutting concerns

- **Route Definition (E4)**:
  - Requirement: Routes defined as type-safe Swift enums with associated values
  - Acceptance: Invalid route construction fails at compile time with exhaustive enum switching
  - Boundary: Route enum marked @frozen preventing runtime additions
  - Refactoring: Generate routes from declarative navigation graph

- **Navigation Testability (E5)**:
  - Requirement: Navigation logic testable without instantiating UI components
  - Acceptance: Navigation tests run in < 10ms without SwiftUI dependencies using mock orchestrator
  - Boundary: Navigation decisions pure functions of current state and route
  - Refactoring: Extract navigation rules into testable decision trees

- **Deep Link Support (E6)**:
  - Requirement: URL to route resolution with type-safe parameter extraction
  - Acceptance: Invalid URLs produce structured errors, not crashes, with parser handling all registered URL patterns
  - Boundary: URL parsing isolated from navigation execution
  - Refactoring: Implement URL pattern matching with regex builders

- **Pattern Support (E7)**:
  - Requirement: Framework supports stack, modal, and tab navigation patterns
  - Acceptance: Each pattern maintains independent navigation state with proper hierarchy preservation
  - Boundary: Navigation patterns composable without conflicts
  - Refactoring: Add custom navigation pattern protocol for extensibility

- **Navigation Cancellation (E8)**:
  - Requirement: In-flight navigation cancellable via Swift concurrency Task cancellation
  - Acceptance: Cancelled navigation leaves state unchanged with rapid requests cancelling previous pending navigations
  - Boundary: Task cancellation propagates to all navigation-triggered operations
  - Refactoring: Implement navigation transaction support for atomicity

## Rationale

### Design Decisions

1. **Actor-Based Clients**: Swift's actor model provides thread safety without manual locking, eliminating data races by design.

2. **1:1 Presentation-Context Relationship**: Each presentation instance gets its own context instance, maintaining independent context state verified through identity testing and enabling proper lifecycle management.

3. **Singleton Clients**: Single source of truth for each domain ensures synchronization across all observers without explicit coordination code.

4. **Transient Capabilities**: System permissions and availability change at runtime; transient lifecycle allows capability unavailability to trigger defined error states without crashes.

5. **Service-Oriented Orchestrator**: Orchestrator provides context creation, dependency resolution, and navigation management capabilities to enable focused testing and clear responsibilities.

### Alternatives Considered

1. **Shared Contexts**: Rejected due to complexity of managing multiple presentation lifecycles
2. **Direct Presentation-Client Binding**: Rejected as it violates separation of concerns
3. **Manual Thread Synchronization**: Rejected in favor of actor model simplicity
4. **Static Capability Instances**: Rejected due to inability to handle permission changes

## Backwards Compatibility

As the foundational RFC for Axiom, this specification establishes the baseline architecture from which all future development proceeds. All subsequent RFCs must maintain compatibility with this foundation architecture.

Framework is currently in MVP stage - breaking changes are acceptable until version 1.0 release.

## Security Considerations

### Threat Model

1. **Concurrent Data Access**: Multiple threads attempting to modify shared state simultaneously
2. **Unauthorized System Access**: Components attempting to use capabilities without proper permissions
3. **Memory Corruption**: Use-after-free or buffer overflow vulnerabilities from improper memory management
4. **Injection Attacks**: Malicious input exploiting weak type validation or improper data handling

### Mitigations

1. **Actor Isolation**: Prevents concurrent access to mutable state through Swift's actor model, ensuring all state mutations are serialized
2. **Capability Validation**: Runtime checks ensure system access is authorized before any capability usage, with fail-safe defaults
3. **Type Safety**: Compile-time validation prevents many security issues including type confusion and invalid state transitions
4. **Memory Safety**: Clear ownership rules enforced by Swift's ARC prevent use-after-free bugs and memory leaks

### Security Boundaries

1. **Component Boundaries**: Each component type has defined security boundaries preventing unauthorized cross-component access
2. **Actor Boundaries**: Actor isolation creates security boundaries preventing race conditions and data corruption
3. **Capability Boundaries**: System capabilities are isolated behind protocols with explicit authorization requirements
4. **Module Boundaries**: Swift Package Manager enforces module boundaries preventing unauthorized internal access

## Test Strategy

### Unit Tests
- Component isolation tests validating individual behaviors
- Protocol conformance verification
- Thread safety validation with race condition detection
- Performance characteristic measurements

### Integration Tests
- Component interaction flows testing coordination
- Error propagation path validation
- State synchronization scenario verification
- Capability lifecycle integration testing

### Performance Tests
- State propagation latency measurements
- Memory overhead profiling
- Component initialization benchmarks
- Concurrent operation stress testing

### Test Infrastructure
- Mock capabilities with configurable behaviors
- Test harnesses for async stream observation
- Performance measurement utilities
- Circular dependency detection tools

## References

### Normative References

- [Swift Evolution: Actor Model](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md) - Defines the actor concurrency model used for Client isolation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui) - Specifies the UI framework requirements for Presentation components

### Informative References

- [iOS App Architecture](https://developer.apple.com/documentation/uikit/app_and_environment) - Provides context on iOS application lifecycle and architecture patterns

## TDD Implementation Checklist

**Last Updated**: 2025-06-05  
**Current Focus**: Performance Requirements implementation  
**Session Notes**: Applied [R1-R20] revisions to fix all technical impossibilities and improve testability. Added navigation architecture requirements [E1-E8] for comprehensive navigation support. Applied [R1-R5] revisions to address actor reentrancy, error boundaries, concurrency safety, navigation state consistency, and presentation-context binding. Completed Component Types and Dependency Rules with performance optimizations. Implemented Client Isolation with comprehensive validation and diagnostic messages. Completed Context Dependencies with build-time validation support and compile-time safety extensions. Completed Unidirectional Flow with comprehensive validation, error messaging, and dependency analyzer. Completed Presentation-Context Binding with 1:1 enforcement, property wrapper support, and SwiftUI integration patterns. Completed State Ownership with immutable value type enforcement, ownership diagnostics, and state partitioning support for large domains. Completed Component Lifetimes with singleton enforcement for Clients/States, per-presentation Contexts, transient Capabilities, lifecycle observers, and comprehensive metrics tracking. Completed DAG Composition with circular dependency detection, topological sorting, separate graphs for capabilities/contexts, caching for performance optimization, and cycle prevention checks. Completed Error Boundaries with async error propagation from Clients to Contexts, recovery strategies, error categorization, enhanced error context, and performance optimizations. Completed Concurrency Safety with actor-based client isolation, task cancellation propagation, priority inheritance for avoiding priority inversion, deadlock prevention, operation batching for performance, and comprehensive concurrency metrics. Completed State Immutability with all state mutations producing new immutable value type instances, concurrent mutations producing consistent final state, copy-on-write optimization for large states, thread-safe state containers, and performance optimizations for high-frequency updates. Completed all Core Protocols: Capability Protocol with lifecycle transitions and common behaviors, Client Protocol with state streaming and AsyncStream optimizations, Context Protocol with MainActor binding and weak reference support, and Orchestrator Protocol with context creation and builder pattern implementation.

### Component Types
- [x] Component Type Definition
  - [x] Red: Test component type enumeration - Tests/AxiomTests/ComponentTypeTests.swift:9
  - [x] Green: Define six component types - Sources/Axiom/ComponentType.swift:3
  - [x] Refactor: Add type documentation - Sources/Axiom/ComponentType.swift:1-39
- [x] Dependency Rules  
  - [x] Red: Test invalid dependencies fail - Tests/AxiomTests/DependencyRulesTests.swift:8
  - [x] Green: Implement dependency validation - Sources/Axiom/DependencyRules.swift:4
  - [x] Refactor: Optimize compile-time checks - Sources/Axiom/DependencyRules.swift:9-27,79-100,142-181

### Core Constraints (1-5)
- [x] Client Isolation
  - [x] Red: Test client-to-client communication fails - Tests/AxiomTests/ClientIsolationTests.swift:8-31
  - [x] Green: Implement isolation rules - Sources/Axiom/ClientIsolation.swift:14-184
  - [x] Refactor: Add diagnostic messages - Sources/Axiom/ClientIsolation.swift:17-69,95-179
- [x] Context Dependencies
  - [x] Red: Test direct capability access fails - Tests/AxiomTests/ContextDependenciesTests.swift:8-36
  - [x] Green: Implement context constraints - Sources/Axiom/ContextDependencies.swift:6-82
  - [x] Refactor: Extract validation logic - Sources/Axiom/ContextDependencies.swift:60-81,312-338
- [x] Unidirectional Flow
  - [x] Red: Test reverse dependencies fail - Tests/AxiomTests/UnidirectionalFlowTests.swift:8-36
  - [x] Green: Implement flow validation - Sources/Axiom/UnidirectionalFlow.swift:13-66
  - [x] Refactor: Create dependency analyzer - Sources/Axiom/UnidirectionalFlow.swift:105-225,230-268
- [x] Presentation-Context Binding
  - [x] Red: Test multiple contexts fail - Tests/AxiomTests/PresentationContextBindingTests.swift:8
  - [x] Green: Implement 1:1 binding - Sources/Axiom/PresentationContextBinding.swift:20
  - [x] Refactor: Add SwiftUI property wrappers - Sources/Axiom/PresentationContextBinding.swift:131-159
- [x] State Ownership
  - [x] Red: Test shared state fails - Tests/AxiomTests/StateOwnershipTests.swift:7
  - [x] Green: Implement ownership rules - Sources/Axiom/StateOwnership.swift:43
  - [x] Refactor: Add ownership diagnostics - Sources/Axiom/StateOwnership.swift:167-205

### Core Constraints (6-10)
- [x] Component Lifetimes
  - [x] Red: Test lifetime violations - Tests/AxiomTests/ComponentLifetimesTests.swift:13
  - [x] Green: Implement lifetime management - Sources/Axiom/ComponentLifetimes.swift:46
  - [x] Refactor: Add lifecycle observers - Sources/Axiom/ComponentLifetimes.swift:238-266
- [x] DAG Composition
  - [x] Red: Test circular dependencies - Tests/AxiomTests/DAGCompositionTests.swift:6
  - [x] Green: Implement DAG validation - Sources/Axiom/DAGComposition.swift:13
  - [x] Refactor: Cache resolution results - Sources/Axiom/DAGComposition.swift:27-34,129-178,304-355
- [x] Error Boundaries
  - [x] Red: Test unhandled errors - Tests/AxiomTests/ErrorBoundariesTests.swift:5
  - [x] Green: Implement error boundaries - Sources/Axiom/ErrorBoundaries.swift:9
  - [x] Refactor: Add recovery strategies - Sources/Axiom/ErrorBoundaries.swift:203-302
- [x] Concurrency Safety
  - [x] Red: Test deadlock scenarios - Tests/AxiomTests/ConcurrencySafetyTests.swift:5
  - [x] Green: Implement actor safety - Sources/Axiom/ConcurrencySafety.swift:9
  - [x] Refactor: Add priority handling - Sources/Axiom/ConcurrencySafety.swift:415-547
- [x] State Immutability
  - [x] Red: Test mutable state corruption - Tests/AxiomTests/StateImmutabilityTests.swift:5
  - [x] Green: Implement immutable updates - Sources/Axiom/StateImmutability.swift:9
  - [x] Refactor: Add copy-on-write - Sources/Axiom/StateImmutability.swift:138-179,374-467

### Core Protocols
- [x] Capability Protocol
  - [x] Red: Test lifecycle transitions - Tests/AxiomTests/CapabilityProtocolTests.swift:6-154
  - [x] Green: Define protocol requirements - Sources/Axiom/CapabilityProtocol.swift:13-22
  - [x] Refactor: Extract common behaviors - Sources/Axiom/CapabilityProtocol.swift:139-221
- [x] Client Protocol
  - [x] Red: Test state streaming - Tests/AxiomTests/ClientProtocolTests.swift:8-206
  - [x] Green: Define actor protocol - Sources/Axiom/ClientProtocol.swift:14-28
  - [x] Refactor: Optimize AsyncStream - Sources/Axiom/ClientProtocol.swift:189-244
- [x] Context Protocol
  - [x] Red: Test observation patterns - Tests/AxiomTests/ContextProtocolTests.swift:8-193
  - [x] Green: Define MainActor protocol - Sources/Axiom/ContextProtocol.swift:15-23
  - [x] Refactor: Add weak references - Sources/Axiom/ContextProtocol.swift:153-206,243-338
- [x] Orchestrator Protocol
  - [x] Red: Test context creation - Tests/AxiomTests/OrchestratorProtocolTests.swift:8-211
  - [x] Green: Define orchestrator interface - Sources/Axiom/OrchestratorProtocol.swift:16-24
  - [x] Refactor: Add builder pattern - Sources/Axiom/OrchestratorProtocol.swift:344-453,197-287

### Performance Requirements
- [ ] State Propagation
  - [ ] Red: Test 60fps requirement
  - [ ] Green: Implement fast propagation
  - [ ] Refactor: Batch updates
- [ ] Memory Overhead
  - [ ] Red: Test 1KB limit
  - [ ] Green: Minimize allocations
  - [ ] Refactor: Object pooling
- [ ] Initialization Speed
  - [ ] Red: Test 50ms limit
  - [ ] Green: Optimize initialization
  - [ ] Refactor: Lazy loading

### Navigation Architecture
- [ ] Navigation Service
  - [ ] Red: Test navigation without Orchestrator
  - [ ] Green: Implement as Orchestrator service
  - [ ] Refactor: Extract navigation coordination
- [ ] Route Definitions
  - [ ] Red: Test invalid route construction
  - [ ] Green: Implement type-safe route enums
  - [ ] Refactor: Generate from navigation graph
- [ ] Navigation Flow
  - [ ] Red: Test direct Presentation navigation
  - [ ] Green: Implement proper request flow
  - [ ] Refactor: Add navigation middleware
- [ ] Deep Linking
  - [ ] Red: Test invalid URL handling
  - [ ] Green: Implement URL to route parsing
  - [ ] Refactor: Regex-based pattern matching
- [ ] Navigation Patterns
  - [ ] Red: Test pattern conflicts
  - [ ] Green: Implement stack/modal/tab support
  - [ ] Refactor: Custom pattern protocol
- [ ] Cancellation Support
  - [ ] Red: Test uncancellable navigation
  - [ ] Green: Implement task cancellation
  - [ ] Refactor: Navigation transactions

## API Design

### Public Interface Evolution

The framework maintains API stability through:
- Semantic versioning with clear deprecation cycles
- Protocol-based design allowing extension without modification
- Default implementations for backwards compatibility
- Compile-time availability annotations

### Core Protocol Interfaces

**Capability Protocol**
```swift
public protocol Capability {
    var isAvailable: Bool { get async }
    func initialize() async throws
    func terminate() async
}
```

**State Protocol**
```swift
public protocol State: Equatable, Sendable {
    // Value type with immutable properties
}
```

**Client Protocol**
```swift
public protocol Client<StateType, ActionType>: Actor {
    associatedtype StateType: State
    associatedtype ActionType
    
    var stateStream: AsyncStream<StateType> { get }
    func process(_ action: ActionType) async throws
}
```

**Context Protocol**
```swift
@MainActor
public protocol Context: ObservableObject {
    func onAppear() async
    func onDisappear() async
}
```

**Orchestrator Protocol**
```swift
public protocol Orchestrator: Actor {
    func createContext<T: Context>(_ type: T.Type) async -> T
    func navigate(to route: Route) async
}
```

**Presentation Protocol**
```swift
public protocol Presentation: View {
    associatedtype ContextType: Context
    var context: ContextType { get }
}
```

### API Stability Guarantees

- Protocol requirements are additive only
- Default implementations provided for new requirements
- Deprecated APIs maintained for 2 major versions
- Breaking changes require new protocol versions
- All public APIs marked with @available annotations

### Versioning Strategy

**Major Version (X.0.0)**
- Breaking changes to protocol requirements
- Removal of deprecated APIs
- Fundamental architectural changes

**Minor Version (0.X.0)**
- New protocol requirements with defaults
- New optional protocol methods
- Performance improvements

**Patch Version (0.0.X)**
- Bug fixes without API changes
- Documentation updates
- Internal optimizations

### Migration Support

The framework provides:
- Automated migration tools for common patterns
- Deprecation warnings with fix-it suggestions
- Migration guides for each major version
- Compatibility mode for gradual adoption

## Performance Constraints

### Framework Overhead Limits

- **Binary Size**:
  - Requirement: Core module < 1MB for arm64 release build with -Osize optimization, excluding Swift runtime
  - Acceptance: xcarchive size < 1MB for arm64 release build with -Osize
  - Boundary: Measured using size command on framework binary
  - Refactoring: Module splitting if size exceeds 800KB

- **Runtime Memory**:
  - Requirement: < 10MB for 100 active components
  - Acceptance: Memory profiler shows < 10MB with 100 components
  - Boundary: Measured after 5 minutes of active use
  - Refactoring: Object pooling for frequently allocated types

- **CPU Overhead**:
  - Requirement: State propagation completes in < 1ms per update on A12 Bionic or newer
  - Acceptance: Instruments shows < 5% CPU in state mutation → UI update path
  - Boundary: Measured with 10 state updates per second at 60fps
  - Refactoring: Batch processing for high-frequency updates

- **Startup Time**:
  - Requirement: < 100ms framework initialization
  - Acceptance: Time profiler shows < 100ms from first call to ready
  - Boundary: Measured on minimum supported hardware
  - Refactoring: Lazy initialization for non-critical components

### Benchmark Requirements

All performance claims validated through:
- Automated benchmark suite in CI/CD
- Device testing on minimum supported hardware
- Profiling data for common usage patterns
- Regression detection for performance changes

### Baseline Hardware Specifications

- **iOS Devices**: iPhone 12, iPad Air 4th generation or newer
- **macOS**: M1 Mac or newer
- **Testing Environment**: Standard device conditions with no background apps

### Performance Optimization Guidelines

- Prefer value types to reduce allocation overhead
- Use copy-on-write for large state objects
- Batch UI updates within frame boundaries
- Profile before optimizing bottlenecks