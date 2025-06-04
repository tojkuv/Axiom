# RFC-001: Axiom Foundation Architecture

**RFC Number**: 001  
**Title**: Axiom Foundation Architecture  
**Status**: Draft  
**Type**: Architecture  
**Created**: 2025-01-06  
**Updated**: 2025-01-15  
**Authors**: Axiom Framework Team  
**Supersedes**: None  
**Superseded-By**: None

## Abstract

This RFC establishes the foundation architecture for the Axiom framework, defining the complete architectural blueprint from inception to first release. It specifies six immutable component types, nineteen architectural constraints with testable acceptance criteria, core protocols with clear test boundaries, performance requirements with measurable targets, and a TDD-oriented implementation roadmap. This foundation ensures thread safety, testability, and maintainability by leveraging Swift's actor model for concurrency and SwiftUI for reactive UI updates.

The foundation architecture enforces clear boundaries between components through compile-time and runtime validation, preventing common iOS development issues such as race conditions, circular dependencies, and memory leaks. Each requirement includes specific acceptance criteria enabling test-driven development cycles. This document serves as the definitive reference for building Axiom from initial implementation through first stable release, establishing all architectural principles, protocols, test strategies, and development milestones.

## Motivation

iOS development suffers from several recurring architectural problems:

1. **Race Conditions**: Concurrent access to shared mutable state causes unpredictable behavior
2. **Circular Dependencies**: Components with bidirectional dependencies create maintenance nightmares
3. **Memory Leaks**: Retain cycles from improper ownership patterns waste resources
4. **Testing Difficulties**: Tightly coupled components resist isolation for unit testing
5. **State Inconsistency**: Multiple sources of truth lead to synchronization bugs

Current iOS architectures (MVC, MVVM, VIPER) address some issues but lack strict constraints and comprehensive foundations. Axiom provides a complete architectural foundation with immutable rules, defined protocols, performance targets, and clear development roadmap from inception to release.

## Specification

### Component Types

The Axiom architecture consists of exactly six immutable component types:

| Component | Purpose | Dependencies | Thread Safety | Lifetime |
|-----------|---------|--------------|---------------|----------|
| **Capability** | External system access | Other Capabilities only | Thread-safe (see req. 11) | Transient |
| **Owned State** | Domain model representation | None | Value types | Singleton |
| **Client** | Domain logic | Capabilities only | Actor isolation | Singleton |
| **Orchestrator** | Application lifecycle | Creates Contexts | @MainActor | Singleton |
| **Context** | Feature coordination | Clients & Contexts | @MainActor | Per view instance |
| **Presentation** | User interface | One Context | SwiftUI View | Multiple instances |

### Architectural Constraints

#### Dependency Constraints (Rules 1-8)

1. **Client Dependency**: Clients can ONLY depend on Capabilities
   - Acceptance: Compiler rejects Client importing another Client type
   - Test: Attempt Client-to-Client dependency fails at compile time

2. **Context Dependency**: Contexts can ONLY depend on Clients and downstream Contexts
   - Acceptance: Compiler rejects Context importing Capability directly
   - Test: Context isolation test validates no capability access

3. **Capability Composition**: Capabilities can ONLY depend on other Capabilities (forming a DAG)
   - Acceptance: Circular capability dependency detected and rejected at runtime
   - Test: DAG validation test with 10 capabilities shows no cycles

4. **View-Context Binding**: Each View has exactly ONE Context dependency
   - Acceptance: View with multiple contexts fails SwiftUI compilation
   - Test: View creation test confirms single context requirement

5. **Unidirectional Flow**: Dependencies flow: Orchestrator → Context → Client → Capability → System
   - System Boundary: External dependencies outside framework control (iOS SDK, third-party frameworks, hardware APIs)
   - Acceptance: Reverse dependency attempts fail at compile time
   - Test: Dependency analyzer confirms unidirectional graph
   - Test: Dependency analyzer categorizes 100% of imports as framework-controlled or system

6. **Client Isolation**: Clients cannot depend on other Clients
   - Acceptance: Inter-client communication attempts fail compilation
   - Test: Client isolation test with 5 clients shows no cross-references

7. **State Ownership**: Each State is owned by exactly ONE Client
   - Acceptance: Shared state attempts trigger compiler error
   - Test: State ownership test validates 1:1 client-state pairing

8. **Context Composition**: Contexts form a DAG with no circular dependencies
   - Acceptance: Circular context references detected within 100ms at runtime
   - Test: Context graph with 20 nodes validates as acyclic

#### Lifetime Constraints (Rules 9-13)

9. **View Lifetime**: Multiple instances - new instance per usage in SwiftUI hierarchy
   - Acceptance: Multiple view instances have unique identities
   - Test: Create 10 views, verify 10 distinct instances via ObjectIdentifier

10. **Context Lifetime**: One instance per view instance - maintains 1:1 relationship
   - Acceptance: Each view instance gets unique context instance
   - Test: View-context pairing test shows 1:1 correspondence for 100 views

11. **Client Lifetime**: Singleton - one instance per client type for entire application
   - Acceptance: Multiple client requests return identical instance
   - Test: Concurrent access from 100 threads returns same client instance

12. **State Lifetime**: Singleton - one instance per state type, paired 1:1 with client
   - Acceptance: State instance remains constant across app lifecycle
   - Test: State identity test over 1000 mutations shows same instance

13. **Capability Lifetime**: Transient - recreated when permissions or availability changes
   - Acceptance: Permission change triggers capability recreation within 50ms
   - Test: Capability lifecycle test validates recreation on permission events

#### State Management Constraints (Rules 14-19)

14. **State Mutation**: State mutations must be atomic and produce new immutable instances
   - Acceptance: Concurrent mutations produce consistent final state
   - Test: 1000 concurrent state mutations show no data corruption
   - Refactoring: Consider copy-on-write optimization for large states

15. **Error Propagation**: Errors must propagate upward through component hierarchy without skipping levels
   - Acceptance: Error at capability level reaches context within 10ms
   - Test: Error injection at each level validates propagation path

16. **Capability Initialization**: Capability initialization must respect dependency order in the DAG
   - Acceptance: Dependent capabilities initialize after dependencies
   - Test: 10-node capability DAG initializes in topological order

17. **State Composition**: States must contain only value types (structs, enums, primitive types)
   - Acceptance: Compiler rejects reference types in state definitions
   - Test: State definition with class property fails compilation

18. **Action Definition**: Actions must be value types with clear command/query separation
   - Acceptance: Actions are immutable and side-effect free
   - Test: Action mutation attempts fail at compile time

19. **Error Boundaries**: Contexts act as error boundaries and must handle or explicitly propagate all Client errors
   - Acceptance: Unhandled client errors caught by context within 5ms
   - Test: Error boundary test validates 100% error capture rate

#### Constraint Dependencies

**Foundational Dependencies**:
- Rules 1-2 establish base dependency directions, enabling Rule 5 (unidirectional flow)
- Rules 6-7 establish ownership patterns, required for Rules 11-12 (singleton lifetimes)
- Rule 3 enables Rule 16 by establishing capability initialization order

**Lifetime Dependencies**:
- Rule 4 enforces Rule 10: View-Context binding requires matching lifetimes
- Rule 11 enables Rule 12: Singleton clients required for singleton state ownership
- Rule 13 is independent but coordinates with Rules 3 and 16 for capability lifecycle

**State Management Dependencies**:
- Rule 14 requires Rule 15: State mutation errors must propagate correctly
- Rule 17 enables Rule 14: Value types ensure atomic state mutations
- Rule 19 requires Rules 2 and 15: Contexts must be in hierarchy to act as boundaries

**Cross-Cutting Dependencies**:
- Rule 5 requires Rules 1-2 and enables clean testing boundaries
- Rule 8 requires Rule 2 but adds runtime cycle detection
- Rules 14-19 form cohesive state management subsystem

### Core Protocols

The framework defines four primary protocols with error handling and state observation capabilities:

**Capability Protocol**: Manages external system access with availability checking, initialization, invalidation, and error recovery strategies (retry, fallback, propagate, ignore).
- Required members: `isAvailable: Bool`, `initialize() async throws`, `invalidate()`, `capabilityIdentifier: String`
- Optional members: `recoveryStrategy: RecoveryStrategy`
- Test boundaries: Mock capabilities must simulate all availability states
- Acceptance: Capability mock can transition through all states in < 10ms
- Refactoring opportunity: Extract common capability behaviors into base protocol

**Client Protocol**: Actor-based business logic container providing thread-safe state management, action processing, state publishing via AsyncStream, and error handling.
- Required members: `stateStream: AsyncStream<State>`, `processAction(_ action: Action) async throws`, `initialState: State`
- Required associated types: `State`, `Action`
- Test boundaries: State streams must be observable in tests
- Acceptance: Test harness receives all state updates within 5ms
- Refactoring opportunity: Consider protocol extensions for common patterns

**Context Protocol**: MainActor-bound feature coordinator that observes client state changes, handles user actions, manages view lifecycle, and provides error recovery.
- Required members: `observeClient() async`, `handleUserAction(_ action: UserAction) async`
- Required lifecycle methods: `onAppear()`, `onDisappear()`
- UserAction requirement: Must conform to a protocol with validation capabilities
- Environment support: Must support SwiftUI @Environment injection for configuration
- Test boundaries: Lifecycle methods must be independently testable
- Acceptance: Mock context handles 1000 actions without memory leaks
- Acceptance: Environment injection test validates configuration propagation through context hierarchy
- Test boundary: Mock environment values must be injectable in test contexts
- Refactoring opportunity: Extract observation logic into reusable component

**Orchestrator Protocol**: Application-level coordinator managing context creation, dependency injection, navigation control, and capability lifecycle events (permission changes, service availability).
- Required members: `createContext(for view: ViewType) -> Context`, `handleCapabilityChange(_ change: CapabilityChange)`
- Required services: context creation capability, dependency resolution capability, navigation management capability
- ViewType requirement: Must be a concrete type identifier, not a generic View protocol
- Test boundaries: Dependency injection must be overridable for testing
- Acceptance: Test orchestrator creates 50 contexts in < 500ms
- Refactoring opportunity: Use builder pattern for complex context creation

**Error Handling**: All protocols incorporate AxiomError with recovery strategies. Capability changes include permission revocation (biometrics, photos, notifications, camera, microphone, location) and service unavailability (network, bluetooth, authentication, storage).

### Error Recovery Specification

#### Component-Specific Recovery Strategies

**Capability Recovery**:
- **Retry**: Automatic retry with exponential backoff for transient failures
- **Fallback**: Return cached data with staleness indicator
- **Propagate**: Forward error to Client for domain-specific handling
- **Ignore**: Log and continue for non-critical capabilities

**Client Recovery**:
- **State Rollback**: Revert to previous valid state on mutation failure
- **Partial Update**: Apply valid portions of composite actions
- **Error State**: Transition to explicit error state with recovery actions
- **Graceful Degradation**: Continue with reduced functionality

**Context Recovery**:
- **User Notification**: Present error UI with recovery options
- **Automatic Retry**: Retry failed user actions with visual feedback
- **Navigation Fallback**: Navigate to safe state on critical errors
- **Silent Recovery**: Handle non-critical errors without user interruption

**Orchestrator Recovery**:
- **System Reset**: Reinitialize capability graph on critical failures
- **Partial Shutdown**: Disable affected subsystems while maintaining core functionality
- **Emergency Mode**: Minimal functionality with explicit user consent
- **Diagnostic Collection**: Gather system state for debugging

### Error Message Standardization

**Error Message Requirements**:
- **Error Code**: All framework errors must include unique error code for programmatic handling
- **Localized Description**: Human-readable error message appropriate for user display
- **Recovery Suggestion**: Actionable guidance for resolving or mitigating the error
- **Debug Information**: Technical details for developers (debug builds only)

**Error Message Format**:
- Code: Framework-specific error codes (e.g., AXIOM_CLIENT_001, AXIOM_CONTEXT_002)
- Description: Clear, concise explanation of what went wrong
- Recovery: Specific steps user or developer can take
- Context: Relevant state information for debugging

**Error Classification**:
- **Critical Errors**: Prevent core functionality, require immediate attention
- **Non-Critical Errors**: Allow degraded operation, can be handled gracefully
- **Warning Conditions**: Potential issues that don't stop execution

**Acceptance Criteria**:
- Error message audit shows 100% compliance with format requirements
- All error types include recovery suggestions
- Critical vs non-critical error classification covers all framework error types

### Component Initialization Order

**Bootstrap Sequence**:
1. **Capability Graph Construction**: Build DAG from capability dependencies
2. **Capability Initialization**: Initialize in topological order
3. **Client Creation**: Create singleton clients with initialized capabilities
4. **Orchestrator Setup**: Initialize with capability and client references
5. **Context Factory Registration**: Register context creation functions
6. **View Hierarchy Setup**: SwiftUI app initialization

**Initialization Failure Handling**:
- **Capability Failure**: Mark as unavailable, continue with degraded mode
- **Required Capability Failure**: Halt initialization, present error UI
- **Client Failure**: Log error, skip dependent features
- **Orchestrator Failure**: Fatal error, app cannot continue

### Implementation Requirements

1. **Thread Safety**: All Clients must guarantee thread-safe state access; all Contexts must execute on the main UI thread
2. **State Management**: States must be value types with immutable snapshots
3. **Memory Management**: Contexts must prevent retain cycles when observing state changes
4. **Navigation Safety**: Navigation management must detect and prevent circular navigation paths
5. **Capability Lifecycle**: Capabilities must handle initialization/invalidation
6. **Testing Support**: Framework must provide testing utilities for capability simulation, client stubbing, and orchestration control
7. **Error Handling**: All components must implement error handling with recovery strategies
8. **State Observation**: Clients must expose state updates: `stateUpdates: AsyncStream<State>` property
9. **Performance**: Components must meet defined performance targets
10. **Validation Enforcement**: Each constraint must specify compile-time or runtime enforcement mechanism
11. **Capability Thread Safety**: Capabilities must either be @MainActor, actor-isolated, or use explicit synchronization
12. **Component Destruction Order**: Component destruction must follow reverse dependency order: Views → Contexts → Clients → Capabilities
13. **Package Distribution**: Swift Package Manager compatible, minimum iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0
    - Acceptance: Package.swift validates platform requirements and builds successfully

## Performance Specification

The framework performance requirements are organized by component with consistent measurement methodology and acceptance criteria.

### Performance Requirements

#### Capability Performance
- **Initialization**: First check may take up to 10ms; subsequent checks must use cached results and complete in < 1ms
  - Acceptance: Performance test with 100 capability checks shows p99 < 1ms for cached
  - Test boundary: Separate first-time vs cached performance measurements
- **Invalidation**: Resource cleanup must complete in < 5ms
  - Acceptance: Invalidation test with 50 capabilities completes in < 250ms total
- **Recovery Strategy**: Strategy determination must complete in < 5ms (excluding execution)
  - Acceptance: Strategy selection for 1000 errors averages < 3ms

#### Client Performance  
- **State Mutation**: Processing actions to produce new state must complete in < 8ms
  - Acceptance: Load test with 10,000 actions shows p95 < 8ms
  - Refactoring: Consider state diffing for large state objects
- **State Publishing**: AsyncStream notification dispatch must occur within 1ms of state change
  - Acceptance: State propagation test measures dispatch latency < 1ms
- **Memory**: Actor overhead must be < 512 bytes per instance (excluding state data)
  - Acceptance: Memory profiler shows framework overhead < 512 bytes

#### Context Performance
- **Creation**: Context initialization must complete in < 50ms
  - Acceptance: Context creation benchmark with dependencies shows p99 < 50ms
  - Refactoring: Lazy initialization for non-critical components
- **State Observation**: State change receipt from Client must occur within 8ms of dispatch
  - Acceptance: End-to-end state propagation test validates < 8ms latency
- **Memory**: Framework overhead must be < 1KB per instance (excluding stored properties)
  - Acceptance: Instruments shows < 1KB framework allocations per context
- **Lifecycle**: onAppear/onDisappear handlers must complete in < 10ms
  - Acceptance: Lifecycle performance test shows all handlers < 10ms

#### View Performance
- **Rendering**: State mutation to UI update must complete in < 16ms (60fps requirement)
  - Acceptance: UI test with rapid state changes maintains 60fps
  - Test: Frame rate monitor shows no drops below 60fps
- **Navigation**: View transitions must complete in < 300ms (iOS standard animation)
  - Acceptance: Navigation timing test shows all transitions < 300ms
- **Memory**: SwiftUI view body computation must use < 256KB stack space
  - Acceptance: Stack profiler validates < 256KB usage during body calls

**Measurement Methodology**: Performance targets must be measured at specific boundaries:
- State propagation: From actor queue dispatch to SwiftUI render completion
- Memory overhead: Framework-specific allocations excluding application data
- Capability checks: Differentiate first-time initialization from cached access

**Technical Limitations**:
- AsyncStream state observation has inherent latency due to actor queue scheduling
- Context memory measurement excludes Swift runtime overhead which varies by platform
- Performance targets assume iOS 15+ on A12 Bionic or newer processors

### Performance Summary

| Component | Operation | Target | Measurement | Acceptance Test |
|-----------|-----------|--------|-------------|-----------------|
| **Capability** | Initialization (first) | < 10ms | Individual capability | 100 capability checks p99 < 1ms cached |
| **Capability** | Initialization (cached) | < 1ms | Individual capability | Performance test with 100 checks |
| **Capability** | Invalidation | < 5ms | Resource cleanup | 50 capabilities complete in < 250ms |
| **Capability** | Recovery Strategy | < 5ms | Strategy determination | 1000 errors average < 3ms |
| **Client** | State Mutation | < 8ms | Action processing | 10,000 actions p95 < 8ms |
| **Client** | State Publishing | < 1ms | AsyncStream dispatch | State propagation test < 1ms |
| **Client** | Memory Overhead | < 512 bytes | Actor overhead | Memory profiler validation |
| **Context** | Creation | < 50ms | Initialization | With dependencies p99 < 50ms |
| **Context** | State Observation | < 8ms | Client to Context | End-to-end test < 8ms |
| **Context** | Memory Overhead | < 1KB | Framework allocations | Instruments validation |
| **Context** | Lifecycle Methods | < 10ms | onAppear/onDisappear | All handlers < 10ms |
| **View** | Rendering | < 16ms | State to UI update | 60fps maintenance test |
| **View** | Navigation | < 300ms | View transitions | All transitions < 300ms |
| **View** | Memory | < 256KB | Body computation | Stack profiler validation |

### State Observation Mechanism

Clients publish state changes through AsyncStream, allowing Contexts to observe and react to state updates. The pattern ensures unidirectional data flow while maintaining thread safety:

- **Client State Publishing**: Clients expose state changes via AsyncStream, yielding new states after processing actions
- **Context Observation**: Contexts subscribe to client state streams using weak self references in tasks
- **Lifecycle Management**: Observation tasks are cancelled when views disappear, preventing memory leaks
- **Thread Safety**: Actor isolation in Clients and MainActor binding in Contexts ensure safe concurrent access


### Capability Lifecycle Triggers

Capabilities invalidate and reinitialize based on system events:

**Permission Changes**: When users revoke permissions (biometrics, photos, notifications, camera, microphone, location), capabilities must invalidate and provide fallbacks following this hierarchy:
1. Return cached data with staleness indicator
2. Return empty data with unavailability reason
3. Trigger user notification for manual resolution

**Service Availability**: Network connectivity loss triggers offline mode with cached data usage. Authentication token expiration requires re-authentication. Other services (bluetooth, storage) follow similar patterns.

**Monitoring Implementation**: The Orchestrator monitors system notifications and network path updates to detect capability changes, invoking appropriate handlers to maintain system consistency.

### Capability Taxonomy

Capabilities are classified into four categories with specific requirements:

**System Capabilities**:
- Access device features (camera, microphone, location, biometrics)
- Permission-based lifecycle with user consent requirements
- Must handle permission revocation gracefully

**Network Capabilities**:
- External service communication (REST, GraphQL, WebSocket)
- Connectivity-aware with offline fallback support
- Must implement request queuing for offline-to-online transitions

**Storage Capabilities**:
- Local data persistence (files, databases, keychain)
- Space-aware with cleanup strategies
- Must handle storage pressure events

**Computation Capabilities**:
- Resource-intensive operations (image processing, ML inference)
- Battery and thermal aware
- Must support operation cancellation and progress reporting

### Partial Capability Degradation

Capabilities support degraded operation modes:

**Degradation Levels**:
1. **Full**: All features available with normal performance
2. **Limited**: Core features only, reduced performance acceptable
3. **Minimal**: Critical features only, user notification required
4. **Unavailable**: No features, must fail gracefully

**Negotiation Protocol**:
- Clients query capability degradation level before use
- Capabilities advertise current level via `degradationLevel` property
- Contexts adjust UI based on available capability levels
- Orchestrator tracks system-wide degradation for coordinated response

### Enhanced State Observation

**Backpressure Handling**:
- AsyncStream buffers limited to 10 pending states
- Overflow triggers state coalescing (keep only latest)
- Contexts can request replay of missed states
- Critical state changes marked as non-droppable

**Observation Guarantees**:
- Order preservation: States delivered in mutation order
- Delivery confirmation: Contexts acknowledge critical states
- Cancellation safety: Clean task termination without state loss
- Recovery support: Contexts can resume observation after errors

### Testing Infrastructure

**Testing Utilities**:
- **Capability Simulation**: Mock capabilities with configurable availability, degradation levels, and failure modes
- **Client Stubbing**: Predefined state sequences with timing control for deterministic testing
- **Orchestration Control**: Dependency injection overrides and lifecycle event simulation
- **Performance Harness**: Automated measurement with statistical analysis and regression detection
- **CircularDependencyDetector**: Runtime validation of component relationships
- **Debug Inspection APIs**: Component introspection for development builds

**Test Categories**:

**Unit Tests**: Verify individual component behavior
- State transition correctness in Clients
- Error propagation through component hierarchy  
- Recovery strategy selection and execution
- Capability degradation handling
- Thread safety validation with race condition detection

**Integration Tests**: Validate component interactions
- Complete user flows from View to Capability
- Cross-component error handling
- State synchronization across multiple contexts
- Capability lifecycle during permission changes
- Navigation flow integrity

**Performance Tests**: Ensure targets are met
- Context creation: initialization to ready state (<50ms)
- State propagation: actor dispatch to view render (<16ms)
- Memory overhead: framework allocations only (<1KB/context)
- Capability checks: cached access performance (<1ms)
- Error recovery: strategy determination time (<5ms)

### Test Strategy

The framework testing approach follows the test pyramid with emphasis on fast, isolated tests:

**Unit Test Categories**:
- Component isolation tests (milliseconds)
- Protocol conformance tests
- Thread safety validation
- Performance characteristic tests

**Integration Test Categories**:
- Component interaction flows (seconds)
- Error propagation paths
- State synchronization scenarios
- Capability lifecycle integration

**End-to-End Test Categories**:
- Complete user workflows (minutes)
- Permission change handling
- App lifecycle scenarios
- Performance under load

### Non-Functional Requirements

#### Debugging Support
- Framework must provide debug descriptions for all components showing dependency graphs
  - Acceptance: Debug description includes full dependency tree
- Components must expose runtime inspection APIs for development builds
  - Acceptance: Inspection API reveals internal state without side effects

#### Observability Requirements
- Framework must expose metrics for: component creation/destruction, error rates, performance violations
- Metrics must be accessible through standardized observability protocols

#### Configuration Management
- Capabilities must support configuration injection without recompilation
- Configuration changes must not require capability recreation unless permissions change

#### Versioning Requirements
- Framework must provide version detection and compatibility checking at initialization
- Version mismatches must fail fast with clear error messages

### Constraint Enforcement Mechanisms

| Constraint | Enforcement Method | Validation Time |
|------------|-------------------|----------------|
| Rules 1-7 | Type system | Compile-time |
| Rule 8 | CircularDependencyDetector | Runtime |
| Rules 9-10 | Framework lifecycle management | Runtime |
| Rules 11-13 | Object lifetime tracking | Runtime |
| Rules 14-16 | Protocol requirements | Compile-time |
| Rules 17-19 | Type system + protocol requirements | Compile-time |

**Performance Enforcement**: Performance violations must trigger warnings in DEBUG builds and errors in RELEASE builds.


### Migration Guide

**From MVVM**: Transform ViewModels into Contexts, Services into Capabilities, and Models into State+Client pairs. Move @Published properties from ViewModels to Contexts while keeping business logic in actor-based Clients.

**From MVC**: Replace ViewControllers with SwiftUI Views and Contexts. Move service calls to Capabilities accessed through Clients. Transition from callback-based to async/await patterns.

**Key Migration Points**:
- ViewModels/Controllers become Contexts
- Services become Capabilities 
- Models split into immutable State and actor-based Clients
- Use @Published in Contexts for UI binding
- Navigation managed by Orchestrator's navigation management capability
- Dependencies injected via Orchestrator's dependency resolution capability

## Rationale

### Design Decisions

1. **Actor-Based Clients**: Swift's actor model provides thread safety without manual locking, eliminating data races by design.

2. **1:1 View-Context Relationship**: Each view instance gets its own context instance, preventing state bleeding between views and enabling proper lifecycle management.

3. **Singleton Clients**: Single source of truth for each domain ensures synchronization across all observers without explicit coordination code.

4. **Transient Capabilities**: System permissions and availability change at runtime; transient lifecycle allows graceful handling of these changes.

5. **Service-Oriented Orchestrator**: Orchestrator must provide context creation capability, dependency resolution capability, and navigation management capability to enable focused testing and clear responsibilities.

### Alternatives Considered

1. **Shared Contexts**: Rejected due to complexity of managing multiple view lifecycles
2. **Direct View-Client Binding**: Rejected as it violates separation of concerns
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

## References

- [Swift Evolution: Actor Model](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [iOS App Architecture](https://developer.apple.com/documentation/uikit/app_and_environment)

## Appendices

### Appendix A: Constraint Dependency Matrix

| Constraint | Requires | Enables | Validation |
|------------|----------|---------|------------|
| Rule 1 (Client→Capability) | - | Rules 5, 6 | Type system |
| Rule 2 (Context→Client/Context) | Rule 1 | Rules 5, 8 | Type system |
| Rule 3 (Capability DAG) | - | Rule 16 | Type system |
| Rule 4 (View→Context) | - | Rule 10 | Type system |
| Rule 5 (Unidirectional) | Rules 1, 2 | - | Type system |
| Rule 6 (Client Isolation) | Rule 1 | Rule 11 | Type system |
| Rule 7 (State Ownership) | - | Rule 12 | Type system |
| Rule 8 (Context DAG) | Rule 2 | - | Runtime |
| Rule 9 (View Multiple) | - | - | Runtime |
| Rule 10 (Context Per-View) | Rule 4 | - | Runtime |
| Rule 11 (Client Singleton) | Rule 6 | Rule 12 | Runtime |
| Rule 12 (State Singleton) | Rules 7, 11 | - | Runtime |
| Rule 13 (Capability Transient) | - | - | Runtime |
| Rule 14 (State Mutation) | - | Rule 15 | Compile-time |
| Rule 15 (Error Propagation) | Rule 14 | Rule 19 | Compile-time |
| Rule 16 (Capability Init) | Rule 3 | - | Compile-time |
| Rule 17 (State Value Types) | - | Rule 14 | Compile-time |
| Rule 18 (Action Value Types) | - | - | Compile-time |
| Rule 19 (Error Boundaries) | Rules 2, 15 | - | Compile-time |

### Appendix B: TDD Implementation Checklist

**Core Components** (Red-Green-Refactor cycles):
- [ ] AxiomError protocol with recovery strategies
  - [ ] Write failing test for error recovery behavior
  - [ ] Implement minimal error handling to pass test
  - [ ] Refactor to extract common recovery patterns
- [ ] Capability protocol with degradation levels
  - [ ] Write test for capability degradation transitions
  - [ ] Implement degradation level support
  - [ ] Refactor to eliminate duplication across capabilities
- [ ] Client protocol with state observation and backpressure
  - [ ] Write test for state stream backpressure handling
  - [ ] Implement AsyncStream with buffering
  - [ ] Refactor to optimize memory usage
- [ ] Context protocol with error boundary behavior
  - [ ] Write test for error boundary catching
  - [ ] Implement error handling in context
  - [ ] Refactor to centralize error handling logic
- [ ] Orchestrator protocol with capability monitoring
  - [ ] Write test for capability lifecycle monitoring
  - [ ] Implement monitoring system
  - [ ] Refactor to use observer pattern
- [ ] CapabilityChange enum for lifecycle events
  - [ ] Write test for all change event types
  - [ ] Implement enum with associated values
  - [ ] Refactor if enum becomes too large
- [ ] CapabilityMonitor for permission/service tracking
  - [ ] Write test for permission change detection
  - [ ] Implement system notification observers
  - [ ] Refactor to separate concerns by capability type

**Infrastructure Components**:
- [ ] Component initialization ordering system
- [ ] Circular dependency detector
- [ ] Performance monitoring framework
- [ ] Debug inspection APIs
- [ ] Metrics collection system
- [ ] Version compatibility checker

**Capability Features**:
- [ ] Capability taxonomy implementation (System/Network/Storage/Computation)
- [ ] Degradation level negotiation protocol
- [ ] Offline-to-online transition handling
- [ ] Permission revocation handlers

**State Management**:
- [ ] AsyncStream backpressure handling
- [ ] State coalescing for overflow
- [ ] Critical state marking system
- [ ] State replay mechanism

### Appendix C: MVP Implementation Guide

#### Core Constraints (MVP - Phase 1)

For initial MVP implementation, focus on these essential constraints:

1. **Rule 1**: Clients can ONLY depend on Capabilities
2. **Rule 2**: Contexts can ONLY depend on Clients and downstream Contexts  
3. **Rule 4**: Each View has exactly ONE Context dependency
4. **Rule 5**: Unidirectional flow: Orchestrator → Context → Client → Capability
5. **Rule 7**: Each State is owned by exactly ONE Client
6. **Rule 11**: Client Lifetime: Singleton

These six constraints provide the core architectural safety while keeping implementation complexity manageable.

#### Extended Constraints (v1.0 - Phase 2)

Add these constraints after MVP validation:

7. **Rule 3**: Capability Composition (DAG formation)
8. **Rule 6**: Client Isolation (no Client-Client dependencies)
9. **Rule 8**: Context Composition (DAG with no cycles)
10. **Rule 9**: View Lifetime (multiple instances)
11. **Rule 10**: Context Lifetime (one per view instance)
12. **Rule 12**: State Lifetime (singleton)
13. **Rule 13**: Capability Lifetime (transient)

#### MVP Implementation Strategy

1. **Phase 1 (Weeks 1-2)**: Implement core protocols with basic error handling
2. **Phase 2 (Weeks 3-4)**: Add state observation mechanism
3. **Phase 3 (Week 5)**: Implement capability lifecycle for permissions
4. **Phase 4 (Week 6)**: Add performance monitoring and optimization
5. **Phase 5 (Weeks 7-8)**: Complete testing infrastructure

### Appendix D: Refactoring Opportunities

**Protocol Segregation**:
- Large protocols can be split into focused concerns
- Common patterns extracted into protocol extensions
- Default implementations for standard behaviors

**State Management Optimization**:
- Copy-on-write for large state objects
- State diffing to minimize update overhead
- Compression for state snapshots

**Performance Improvements**:
- Lazy initialization for expensive components
- Caching strategies for capability checks
- Batch processing for state updates

**Code Organization**:
- Extract common error handling patterns
- Centralize validation logic
- Modularize capability implementations

### Appendix E: Version History

- **v1.7** (2025-01-15): Stabilization improvements: system boundary clarification, error message standardization, performance consolidation, SwiftUI Environment support
- **v1.6** (2025-01-13): Added TDD acceptance criteria, test boundaries, refactoring opportunities
- **v1.5** (2025-01-13): Reorganized content, added complete dependency matrix, enhanced error recovery specs
- **v1.4** (2025-01-09): Added Rules 17-19, non-functional requirements, constraint enforcement mechanisms
- **v1.3** (2025-01-08): Added Rules 14-16, enhanced protocol specs, performance methodology
- **v1.2** (2025-01-07): Removed code examples, improved clarity and readability
- **v1.1** (2025-01-07): Added error handling, performance targets, state observation, testing patterns
- **v1.0** (2025-01-06): Initial RFC with six components, thirteen constraints, actor model

### Appendix F: TDD Enhancement Summary

This revision enhances RFC-001 with comprehensive TDD support:

**Testable Requirements**:
- All 19 constraints now include acceptance criteria
- Each requirement specifies measurable test outcomes
- Performance targets include specific test scenarios

**Test Boundaries**:
- Protocol definitions include test boundary specifications
- Mock requirements clearly defined for each component
- Integration points identified for testing

**Implementation Approach**:
- TDD checklist follows Red-Green-Refactor cycles
- Each component implementation starts with failing tests
- Refactoring opportunities identified throughout

**Quality Metrics**:
- Acceptance criteria use quantifiable measures
- Performance tests specify percentile requirements
- Memory and timing constraints are testable

This TDD-oriented approach ensures the framework can be built incrementally with confidence, maintaining quality through comprehensive test coverage at every stage.

### Appendix G: Stabilization Summary

Version 1.7 adds critical stabilization improvements for implementation readiness:

**System Boundary Clarification**:
- Clear definition of "System" as external dependencies outside framework control
- Dependency analyzer requirements for import classification

**Error Message Standardization**:
- Standardized error format with codes, descriptions, and recovery suggestions
- Clear classification of critical vs non-critical errors
- Comprehensive error handling requirements

**Performance Consolidation**:
- Unified Performance Specification section with summary table
- Consistent measurement methodology across all components
- Clear acceptance criteria for all performance targets

**SwiftUI Environment Integration**:
- Context protocol support for @Environment injection
- Configuration propagation through context hierarchy
- Test boundaries for environment value injection

These stabilization improvements ensure consistent implementation patterns and reduce integration complexity during framework development.