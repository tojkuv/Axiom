# RFC-001: Axiom Foundation Architecture

**RFC Number**: 001  
**Title**: Axiom Foundation Architecture  
**Status**: Draft  
**Type**: Architecture  
**Created**: 2025-01-06  
**Updated**: 2025-06-04 16:59  
**Supersedes**: None  
**Superseded-By**: None

## Abstract

This RFC establishes the foundation architecture for the Axiom framework, defining the complete architectural blueprint. It specifies six immutable component types, ten core architectural constraints with testable acceptance criteria, core protocols with clear test boundaries, three key performance metrics, and comprehensive navigation architecture requirements. This foundation ensures thread safety, testability, and maintainability by leveraging Swift's actor model for concurrency and SwiftUI for reactive UI updates.

The foundation architecture enforces clear boundaries between components through compile-time and runtime validation, preventing common iOS development issues such as race conditions, circular dependencies, and memory leaks. Each requirement includes specific acceptance criteria enabling test-driven development cycles.

## Motivation

iOS development suffers from several recurring architectural problems:

1. **Race Conditions**: Concurrent access to shared mutable state causes unpredictable behavior
2. **Circular Dependencies**: Components with bidirectional dependencies create maintenance nightmares
3. **Memory Leaks**: Retain cycles from improper ownership patterns waste resources
4. **Testing Difficulties**: Tightly coupled components resist isolation for unit testing
5. **State Inconsistency**: Multiple sources of truth lead to synchronization bugs

Current iOS architectures (MVC, MVVM, VIPER) address some issues but lack strict constraints and comprehensive foundations. Axiom provides a complete architectural foundation with immutable rules, defined protocols, performance targets, and clear development roadmap from inception to release.

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
  - Acceptance: Presentation with multiple contexts fails SwiftUI compilation
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
  - Requirement: Contexts act as error boundaries and must handle all Client errors
  - Acceptance: Context error handlers invoked synchronously before client method returns
  - Boundary: Error boundary test validates all Swift Error types thrown by client methods are caught, excluding fatal errors and system crashes
  - Refactoring: Implement error recovery strategies per error type

- **Concurrency Safety**:
  - Requirement: All state mutations are actor-isolated with no reentrancy deadlocks
  - Acceptance: Actor isolation pattern prevents circular waiting conditions in framework-controlled paths
  - Boundary: Stress test with actor contention scenarios
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
  - Requirement: Actor methods complete atomically without reentrancy
  - Acceptance: Actor methods complete atomically without interleaving from the same task
  - Boundary: Test with 100 sequential async calls per actor
  - Refactoring: Consider priority inheritance for critical paths

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
  - Acceptance: Single navigation state instance across entire application with concurrent requests resolving to consistent final state
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

1. **Actor Isolation**: Prevents concurrent access to mutable state
2. **Capability Validation**: Runtime checks ensure system access is authorized
3. **Type Safety**: Compile-time validation prevents many security issues
4. **Memory Safety**: Clear ownership rules prevent use-after-free bugs

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

- [Swift Evolution: Actor Model](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [iOS App Architecture](https://developer.apple.com/documentation/uikit/app_and_environment)

## TDD Implementation Checklist

**Last Updated**: 2025-06-04 16:59  
**Current Focus**: Foundation architecture specification  
**Session Notes**: Applied [R1-R20] revisions to fix all technical impossibilities and improve testability. Added navigation architecture requirements [E1-E8] for comprehensive navigation support

### Component Types
- [ ] Component Type Definition
  - [ ] Red: Test component type enumeration
  - [ ] Green: Define six component types
  - [ ] Refactor: Add type documentation
- [ ] Dependency Rules
  - [ ] Red: Test invalid dependencies fail
  - [ ] Green: Implement dependency validation
  - [ ] Refactor: Optimize compile-time checks

### Core Constraints (1-5)
- [ ] Client Isolation
  - [ ] Red: Test client-to-client communication fails
  - [ ] Green: Implement isolation rules
  - [ ] Refactor: Add diagnostic messages
- [ ] Context Dependencies
  - [ ] Red: Test direct capability access fails
  - [ ] Green: Implement context constraints
  - [ ] Refactor: Extract validation logic
- [ ] Unidirectional Flow
  - [ ] Red: Test reverse dependencies fail
  - [ ] Green: Implement flow validation
  - [ ] Refactor: Create dependency analyzer
- [ ] Presentation-Context Binding
  - [ ] Red: Test multiple contexts fail
  - [ ] Green: Implement 1:1 binding
  - [ ] Refactor: Add SwiftUI property wrappers
- [ ] State Ownership
  - [ ] Red: Test shared state fails
  - [ ] Green: Implement ownership rules
  - [ ] Refactor: Add ownership diagnostics

### Core Constraints (6-10)
- [ ] Component Lifetimes
  - [ ] Red: Test lifetime violations
  - [ ] Green: Implement lifetime management
  - [ ] Refactor: Add lifecycle observers
- [ ] DAG Composition
  - [ ] Red: Test circular dependencies
  - [ ] Green: Implement DAG validation
  - [ ] Refactor: Cache resolution results
- [ ] Error Boundaries
  - [ ] Red: Test unhandled errors
  - [ ] Green: Implement error boundaries
  - [ ] Refactor: Add recovery strategies
- [ ] Concurrency Safety
  - [ ] Red: Test deadlock scenarios
  - [ ] Green: Implement actor safety
  - [ ] Refactor: Add priority handling
- [ ] State Immutability
  - [ ] Red: Test mutable state corruption
  - [ ] Green: Implement immutable updates
  - [ ] Refactor: Add copy-on-write

### Core Protocols
- [ ] Capability Protocol
  - [ ] Red: Test lifecycle transitions
  - [ ] Green: Define protocol requirements
  - [ ] Refactor: Extract common behaviors
- [ ] Client Protocol
  - [ ] Red: Test state streaming
  - [ ] Green: Define actor protocol
  - [ ] Refactor: Optimize AsyncStream
- [ ] Context Protocol
  - [ ] Red: Test observation patterns
  - [ ] Green: Define MainActor protocol
  - [ ] Refactor: Add weak references
- [ ] Orchestrator Protocol
  - [ ] Red: Test context creation
  - [ ] Green: Define orchestrator interface
  - [ ] Refactor: Add builder pattern

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

### Core Public APIs

- **Capability**: Base protocol for all capabilities
  - Requirement: All public methods use @available annotation with explicit iOS version
  - Acceptance: Compiler warns when using deprecated APIs after 2 major versions
  - Boundary: Public API changes tracked in migration guide
  - Refactoring: Extract shared capability behaviors to protocol extensions

- **State**: Protocol for domain model value types
  - Requirement: Equatable value types with immutable properties
  - Acceptance: State mutations create new instances with value semantics
  - Boundary: No reference types allowed in state definitions
  - Refactoring: Automatic Codable synthesis for persistence

- **Client**: Actor protocol for business logic
  - Requirement: Generic over State and Action types with AsyncStream observation
  - Acceptance: Type inference works for all standard Swift types
  - Boundary: Error propagation through typed throws
  - Refactoring: Consider AsyncSequence for flexible streaming

- **Context**: MainActor protocol for UI coordination
  - Requirement: SwiftUI lifecycle integration with type-safe action handling
  - Acceptance: Context lifecycle matches SwiftUI view lifecycle
  - Boundary: Environment value support for configuration
  - Refactoring: Weak observation patterns for memory efficiency

- **Orchestrator**: Application coordinator protocol
  - Requirement: Context factory methods with capability lifecycle management
  - Acceptance: All contexts created through orchestrator factory
  - Boundary: Navigation coordination through type-safe routing
  - Refactoring: Builder pattern for complex initialization flows

- **Presentation**: SwiftUI view protocol for UI components
  - Requirement: Single context binding with automatic lifecycle management
  - Acceptance: Presentation compilation fails with multiple context bindings
  - Boundary: SwiftUI body computation with framework-provided property wrappers
  - Refactoring: Custom property wrappers for common presentation patterns

### API Stability Guarantees

- Protocol requirements are additive only
- Default implementations provided for new requirements
- Deprecated APIs maintained for 2 major versions
- Breaking changes require new protocol versions

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