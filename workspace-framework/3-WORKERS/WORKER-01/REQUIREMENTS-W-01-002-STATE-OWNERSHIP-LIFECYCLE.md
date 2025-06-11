# REQUIREMENTS-W-01-002-STATE-OWNERSHIP-LIFECYCLE

## Requirement Overview

**ID**: W-01-002  
**Title**: State Ownership and Lifecycle Management  
**Type**: WORKER - State Management Domain  
**Priority**: CRITICAL  
**Worker**: WORKER-01  
**Dependencies**: P-001 (Core Protocol Foundation), W-01-001 (State Immutability)  

## Executive Summary

Establish comprehensive state ownership rules and lifecycle management patterns that ensure each state instance is owned by exactly one client, preventing shared mutable state bugs and enabling predictable resource management. This requirement provides compile-time ownership validation, lifecycle coordination, and memory safety guarantees for state management across the AxiomFramework.

## Current State Analysis

**Existing Implementation in AxiomFramework**:
- `State` protocol with Equatable, Hashable, and Sendable conformance
- `StateOwnershipValidator` for runtime ownership validation
- `PartitionableState` protocol for large domain management
- `OwnedState` property wrapper (placeholder implementation)
- Test support types for validation

**Identified Gaps**:
- Compile-time ownership enforcement not implemented
- Lifecycle coordination between state and client missing
- State partitioning patterns need refinement
- Memory management for large state graphs incomplete
- Ownership transfer protocols undefined

## Requirement Details

### 1. Compile-Time State Ownership

**Requirements**:
- Each state instance owned by exactly one client
- Ownership validated at compile time via type system
- Transfer of ownership explicitly modeled
- Prevention of accidental state sharing

**Type System Enforcement**:
```swift
// State ownership marker
public struct StateOwnership<S: State, Owner: Client> {
    private let state: S
    fileprivate init(state: S) { self.state = state }
}

// Client owns its state type
public protocol Client {
    associatedtype OwnedState: State
    var ownership: StateOwnership<OwnedState, Self> { get }
}
```

### 2. State Lifecycle Management

**Requirements**:
- State creation tied to client initialization
- State cleanup on client deactivation
- Resource management for state-owned resources
- Lifecycle hooks for state transitions

**Lifecycle Phases**:
1. **Creation**: State initialized with client
2. **Activation**: State resources allocated
3. **Active**: State mutations and observations
4. **Deactivation**: Resources released
5. **Destruction**: State deallocated with client

### 3. Hierarchical State Management

**Requirements**:
- Parent-child state relationships
- Cascading lifecycle management
- Isolated sub-state ownership
- Efficient state partitioning

### 4. Memory Safety Guarantees

**Requirements**:
- No retain cycles between state and observers
- Automatic cleanup of state resources
- Memory pressure response
- Large state graph optimization

## API Design

### State Ownership System

```swift
// Enhanced State protocol with ownership
public protocol State: Equatable, Hashable, Sendable {
    associatedtype Owner: Client
    associatedtype Resources = Void
    
    // Lifecycle hooks
    func didCreate(owner: Owner) async
    func willActivate() async throws
    func didDeactivate() async
    
    // Resource management
    var resources: Resources { get }
}

// Compile-time ownership enforcement
@propertyWrapper
public struct Owned<S: State> {
    private let ownership: StateOwnership<S, S.Owner>
    
    public var wrappedValue: S {
        get { ownership.state }
    }
    
    public init(by owner: S.Owner, initialState: S) {
        self.ownership = StateOwnership(state: initialState)
    }
}

// Enhanced Client with state ownership
public protocol Client<StateType, ActionType>: Actor {
    associatedtype StateType: State where StateType.Owner == Self
    associatedtype ActionType
    
    @Owned var state: StateType { get }
    
    // Lifecycle coordination
    func stateWillUpdate(from old: StateType, to new: StateType) async
    func stateDidUpdate(from old: StateType, to new: StateType) async
}

// Hierarchical state management
public protocol HierarchicalState: State {
    associatedtype ChildStates: Collection where ChildStates.Element: State
    
    var children: ChildStates { get }
    
    func child<T: State>(ofType: T.Type, id: T.ID) -> T?
    func addChild<T: State>(_ child: T) -> Self
    func removeChild<T: State>(ofType: T.Type, id: T.ID) -> Self
}
```

### Lifecycle Coordination

```swift
// State lifecycle manager
public actor StateLifecycleManager<S: State> {
    private let state: S
    private let owner: S.Owner
    private var phase: LifecyclePhase = .created
    
    public enum LifecyclePhase {
        case created
        case activating
        case active
        case deactivating
        case destroyed
    }
    
    public init(state: S, owner: S.Owner) async {
        self.state = state
        self.owner = owner
        await state.didCreate(owner: owner)
    }
    
    public func activate() async throws {
        guard phase == .created else {
            throw AxiomError.lifecycleError(.invalidTransition(
                from: String(describing: phase),
                to: "active"
            ))
        }
        
        phase = .activating
        try await state.willActivate()
        phase = .active
    }
    
    public func deactivate() async {
        guard phase == .active else { return }
        
        phase = .deactivating
        await state.didDeactivate()
        phase = .destroyed
    }
}

// Partitioned state management
public protocol PartitionedState: State {
    associatedtype PartitionKey: Hashable
    associatedtype Partition: State
    
    // Partition access
    subscript(partition: PartitionKey) -> Partition? { get }
    
    // Partition management
    func withPartition(_ key: PartitionKey, _ transform: (Partition?) -> Partition?) -> Self
}

// Memory-efficient state storage
public actor StateStorage<S: State> {
    private var primary: S
    private var partitions: [AnyHashable: Any] = [:]
    private let memoryLimit: Int
    
    public init(state: S, memoryLimit: Int = 100_000_000) { // 100MB default
        self.primary = state
        self.memoryLimit = memoryLimit
    }
    
    public func partition<P: PartitionedState>(
        _ keyPath: KeyPath<S, P>,
        key: P.PartitionKey
    ) async -> P.Partition? {
        // Lazy load partitions with memory management
        let partition = primary[keyPath: keyPath][key]
        await trackMemoryUsage(for: partition)
        return partition
    }
    
    private func trackMemoryUsage(for partition: Any?) async {
        // Memory pressure handling
        if await currentMemoryUsage() > memoryLimit {
            await evictLeastRecentlyUsed()
        }
    }
}
```

### Ownership Transfer

```swift
// Safe ownership transfer protocol
public protocol TransferableState: State {
    func prepareForTransfer() async -> TransferToken<Self>
}

public struct TransferToken<S: TransferableState> {
    fileprivate let state: S
    fileprivate let checksum: Int
    
    public func complete<NewOwner: Client>(to newOwner: NewOwner) async throws -> S 
        where S.Owner == NewOwner {
        // Validate transfer integrity
        guard state.hashValue == checksum else {
            throw AxiomError.stateError(.corruptedState(
                type: String(describing: S.self)
            ))
        }
        
        // Complete ownership transfer
        await state.didCreate(owner: newOwner)
        return state
    }
}
```

## Technical Design

### Architecture Components

1. **Ownership Layer**
   - Compile-time type system enforcement
   - Runtime validation for dynamic scenarios
   - Ownership transfer protocols
   - Debug-mode ownership tracking

2. **Lifecycle Layer**
   - Phase-based state transitions
   - Resource allocation/deallocation
   - Cascading lifecycle management
   - Error recovery during transitions

3. **Memory Management Layer**
   - Weak reference patterns for observers
   - Partition-based memory optimization
   - Lazy loading for large states
   - Memory pressure response

4. **Hierarchical Management**
   - Parent-child relationships
   - Isolated sub-state ownership
   - Efficient tree traversal
   - Batch update coordination

### Implementation Strategies

1. **Type-Safe Ownership**
   - Phantom types for ownership marking
   - Compile-time validation via generics
   - Runtime assertions in debug builds
   - Clear ownership in type signatures

2. **Lifecycle Coordination**
   - Async lifecycle methods
   - Proper ordering of operations
   - Resource cleanup guarantees
   - Recovery from partial failures

3. **Memory Optimization**
   - Copy-on-write for large states
   - Structural sharing between versions
   - Weak observer patterns
   - Automatic partition eviction

## Success Criteria

### Functional Validation

- [ ] **Ownership Guarantee**: Each state owned by exactly one client
- [ ] **Compile-Time Safety**: Ownership violations caught at compile time
- [ ] **Lifecycle Coordination**: All phases execute in correct order
- [ ] **Resource Management**: No resource leaks in lifecycle transitions
- [ ] **Memory Safety**: No retain cycles or memory leaks

### Integration Validation

- [ ] **Client Integration**: All clients properly own their state
- [ ] **Lifecycle Hooks**: State lifecycle methods called correctly
- [ ] **Hierarchical States**: Parent-child relationships maintained
- [ ] **Transfer Protocol**: Ownership transfers work safely
- [ ] **Memory Management**: Large states handled efficiently

### Performance Validation

- [ ] **Ownership Overhead**: < 10ns for ownership checks
- [ ] **Lifecycle Transitions**: < 1ms for typical state activation
- [ ] **Memory Efficiency**: < 5% overhead for ownership tracking
- [ ] **Partition Loading**: < 10ms for lazy partition access
- [ ] **Transfer Speed**: < 100μs for ownership transfer

## Implementation Priority

1. **Phase 1**: Compile-time ownership enforcement via type system
2. **Phase 2**: Lifecycle management and coordination
3. **Phase 3**: Hierarchical and partitioned state support
4. **Phase 4**: Memory optimization and transfer protocols

This requirement ensures safe, predictable state ownership throughout the AxiomFramework, preventing shared mutable state bugs and enabling efficient resource management.