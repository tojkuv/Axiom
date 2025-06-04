# RFC-001: Axiom Foundation Architecture

**RFC Number**: 001  
**Title**: Axiom Foundation Architecture  
**Status**: Active  
**Type**: Architecture  
**Created**: 2025-01-06  
**Updated**: 2025-01-13  
**Authors**: Axiom Framework Team  
**Supersedes**: None  
**Superseded-By**: None

## Abstract

This RFC establishes the foundation architecture for the Axiom framework, defining the complete architectural blueprint from inception to first release. It specifies six immutable component types, nineteen architectural constraints, core protocols, performance requirements, and implementation roadmap. This foundation ensures thread safety, testability, and maintainability by leveraging Swift's actor model for concurrency and SwiftUI for reactive UI updates.

The foundation architecture enforces clear boundaries between components through compile-time and runtime validation, preventing common iOS development issues such as race conditions, circular dependencies, and memory leaks. This document serves as the definitive reference for building Axiom from initial implementation through first stable release, establishing all architectural principles, protocols, and development milestones.

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
2. **Context Dependency**: Contexts can ONLY depend on Clients and downstream Contexts
3. **Capability Composition**: Capabilities can ONLY depend on other Capabilities (forming a DAG)
4. **View-Context Binding**: Each View has exactly ONE Context dependency
5. **Unidirectional Flow**: Dependencies flow: Orchestrator → Context → Client → Capability → System
6. **Client Isolation**: Clients cannot depend on other Clients
7. **State Ownership**: Each State is owned by exactly ONE Client
8. **Context Composition**: Contexts form a DAG with no circular dependencies

#### Lifetime Constraints (Rules 9-13)

9. **View Lifetime**: Multiple instances - new instance per usage in SwiftUI hierarchy
10. **Context Lifetime**: One instance per view instance - maintains 1:1 relationship
11. **Client Lifetime**: Singleton - one instance per client type for entire application
12. **State Lifetime**: Singleton - one instance per state type, paired 1:1 with client
13. **Capability Lifetime**: Transient - recreated when permissions or availability changes

#### State Management Constraints (Rules 14-19)

14. **State Mutation**: State mutations must be atomic and produce new immutable instances
15. **Error Propagation**: Errors must propagate upward through component hierarchy without skipping levels
16. **Capability Initialization**: Capability initialization must respect dependency order in the DAG
17. **State Composition**: States must contain only value types (structs, enums, primitive types)
18. **Action Definition**: Actions must be value types with clear command/query separation
19. **Error Boundaries**: Contexts act as error boundaries and must handle or explicitly propagate all Client errors

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

**Client Protocol**: Actor-based business logic container providing thread-safe state management, action processing, state publishing via AsyncStream, and error handling.
- Required members: `stateStream: AsyncStream<State>`, `processAction(_ action: Action) async throws`, `initialState: State`
- Required associated types: `State`, `Action`

**Context Protocol**: MainActor-bound feature coordinator that observes client state changes, handles user actions, manages view lifecycle, and provides error recovery.
- Required members: `observeClient() async`, `handleUserAction(_ action: UserAction) async`
- Required lifecycle methods: `onAppear()`, `onDisappear()`
- UserAction requirement: Must conform to a protocol with validation capabilities

**Orchestrator Protocol**: Application-level coordinator managing context creation, dependency injection, navigation control, and capability lifecycle events (permission changes, service availability).
- Required members: `createContext(for view: ViewType) -> Context`, `handleCapabilityChange(_ change: CapabilityChange)`
- Required services: context creation capability, dependency resolution capability, navigation management capability
- ViewType requirement: Must be a concrete type identifier, not a generic View protocol

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

### Performance Requirements

#### Capability Performance
- **Initialization**: First check may take up to 10ms; subsequent checks must use cached results and complete in < 1ms
- **Invalidation**: Resource cleanup must complete in < 5ms
- **Recovery Strategy**: Strategy determination must complete in < 5ms (excluding execution)

#### Client Performance  
- **State Mutation**: Processing actions to produce new state must complete in < 8ms
- **State Publishing**: AsyncStream notification dispatch must occur within 1ms of state change
- **Memory**: Actor overhead must be < 512 bytes per instance (excluding state data)

#### Context Performance
- **Creation**: Context initialization must complete in < 50ms
- **State Observation**: State change receipt from Client must occur within 8ms of dispatch
- **Memory**: Framework overhead must be < 1KB per instance (excluding stored properties)
- **Lifecycle**: onAppear/onDisappear handlers must complete in < 10ms

#### View Performance
- **Rendering**: State mutation to UI update must complete in < 16ms (60fps requirement)
- **Navigation**: View transitions must complete in < 300ms (iOS standard animation)
- **Memory**: SwiftUI view body computation must use < 256KB stack space

**Measurement Methodology**: Performance targets must be measured at specific boundaries:
- State propagation: From actor queue dispatch to SwiftUI render completion
- Memory overhead: Framework-specific allocations excluding application data
- Capability checks: Differentiate first-time initialization from cached access

**Technical Limitations**:
- AsyncStream state observation has inherent latency due to actor queue scheduling
- Context memory measurement excludes Swift runtime overhead which varies by platform
- Performance targets assume iOS 15+ on A12 Bionic or newer processors

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

### Non-Functional Requirements

#### Debugging Support
- Framework must provide debug descriptions for all components showing dependency graphs
- Components must expose runtime inspection APIs for development builds

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

### Appendix B: Implementation Checklist

**Core Components**:
- [ ] AxiomError protocol with recovery strategies
- [ ] Capability protocol with degradation levels
- [ ] Client protocol with state observation and backpressure
- [ ] Context protocol with error boundary behavior
- [ ] Orchestrator protocol with capability monitoring
- [ ] CapabilityChange enum for lifecycle events
- [ ] CapabilityMonitor for permission/service tracking

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

### Appendix D: Version History

- **v1.5** (2025-01-13): Reorganized content, added complete dependency matrix, enhanced error recovery specs
- **v1.4** (2025-01-09): Added Rules 17-19, non-functional requirements, constraint enforcement mechanisms
- **v1.3** (2025-01-08): Added Rules 14-16, enhanced protocol specs, performance methodology
- **v1.2** (2025-01-07): Removed code examples, improved clarity and readability
- **v1.1** (2025-01-07): Added error handling, performance targets, state observation, testing patterns
- **v1.0** (2025-01-06): Initial RFC with six components, thirteen constraints, actor model