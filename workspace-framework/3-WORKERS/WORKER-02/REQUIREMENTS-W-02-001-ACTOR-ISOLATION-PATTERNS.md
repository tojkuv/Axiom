# REQUIREMENTS-W-02-001-ACTOR-ISOLATION-PATTERNS

## Requirement Overview

**ID**: W-02-001  
**Title**: Actor Isolation Patterns and Safety Guarantees  
**Type**: WORKER - Concurrency & Actor Safety Domain  
**Priority**: CRITICAL  
**Worker**: WORKER-02  
**Dependencies**: P-001 (Core Protocol Foundation)  

## Executive Summary

Establish comprehensive actor isolation patterns that ensure data race safety across the AxiomFramework. This requirement provides actor protocols, isolation boundaries, cross-actor communication patterns, and reentrancy handling that prevent concurrency bugs and enable safe parallel execution in multi-core environments.

## Current State Analysis

**Existing Implementation in AxiomFramework**:
- `ConcurrentClient` protocol with actor isolation
- `StateConsistencyManager` for reentrancy detection
- Basic state version tracking for consistency
- `withStateValidation` utility for safe operations
- Actor-based clients with async state streams

**Identified Gaps**:
- Reentrancy patterns need standardization
- Cross-actor call ordering not guaranteed
- Actor priority inheritance not implemented
- Isolation boundary enforcement incomplete
- Performance impact of actor hops unmeasured

## Requirement Details

### 1. Enhanced Actor Isolation Protocol

**Requirements**:
- Strengthen `ConcurrentClient` with isolation guarantees
- Add cross-actor communication protocols
- Implement reentrancy detection and handling
- Support for actor priority and quality of service

**Enhancements Needed**:
```swift
public protocol IsolatedActor: Actor {
    // Unique actor identifier for debugging
    var actorID: ActorIdentifier { get }
    
    // Quality of service for this actor
    var qualityOfService: DispatchQoS { get }
    
    // Reentrancy policy for this actor
    var reentrancyPolicy: ReentrancyPolicy { get }
    
    // Validate actor state consistency
    func validateActorInvariants() async throws
}
```

### 2. Cross-Actor Communication Patterns

**Requirements**:
- Safe message passing between actors
- Ordered delivery guarantees when needed
- Timeout handling for cross-actor calls
- Performance monitoring of actor hops

**Performance Targets**:
- < 1μs overhead for local actor calls
- < 10μs for cross-actor communication
- Zero data races in stress testing

### 3. Reentrancy Management

**Requirements**:
- Automatic reentrancy detection
- Configurable reentrancy policies
- State consistency validation after reentrancy
- Performance-aware reentrancy handling

### 4. Actor Isolation Boundaries

**Requirements**:
- Clear isolation boundary definitions
- Sendable conformance enforcement
- Value type isolation patterns
- Reference type safety mechanisms

## API Design

### Enhanced Actor System

```swift
// Actor identifier for debugging and monitoring
public struct ActorIdentifier: Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let type: String
}

// Reentrancy policies
public enum ReentrancyPolicy: Sendable {
    case allow
    case deny
    case queue
    case detectAndHandle
}

// Enhanced isolated actor protocol
public protocol IsolatedActor: Actor {
    var actorID: ActorIdentifier { get }
    var qualityOfService: DispatchQoS { get }
    var reentrancyPolicy: ReentrancyPolicy { get }
    
    func validateActorInvariants() async throws
}

// Cross-actor message passing
public actor MessageRouter {
    private var routes: [ActorIdentifier: any IsolatedActor] = [:]
    private let metrics: ActorMetrics
    
    public func send<T: Sendable>(
        _ message: T,
        to: ActorIdentifier,
        priority: TaskPriority = .medium,
        timeout: Duration? = nil
    ) async throws -> MessageResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard let actor = routes[to] else {
            throw ActorError.actorNotFound(to)
        }
        
        let result = try await withTimeout(timeout) {
            try await self.deliver(message, to: actor)
        }
        
        metrics.recordDelivery(
            duration: CFAbsoluteTimeGetCurrent() - startTime,
            actorID: to
        )
        
        return result
    }
}

// Reentrancy detection and handling
public actor ReentrancyGuard {
    private var activeOperations: Set<OperationIdentifier> = []
    private var queuedOperations: [QueuedOperation] = []
    
    public func executeWithGuard<T>(
        policy: ReentrancyPolicy,
        operation: OperationIdentifier,
        body: () async throws -> T
    ) async throws -> T {
        switch policy {
        case .allow:
            return try await body()
            
        case .deny:
            guard !activeOperations.contains(operation) else {
                throw ActorError.reentrancyDenied(operation)
            }
            activeOperations.insert(operation)
            defer { activeOperations.remove(operation) }
            return try await body()
            
        case .queue:
            if activeOperations.contains(operation) {
                return try await queueOperation(operation, body: body)
            } else {
                activeOperations.insert(operation)
                defer { activeOperations.remove(operation) }
                return try await body()
            }
            
        case .detectAndHandle:
            let isReentrant = activeOperations.contains(operation)
            activeOperations.insert(operation)
            defer { activeOperations.remove(operation) }
            
            if isReentrant {
                // Handle reentrancy with custom logic
                return try await handleReentrantOperation(operation, body: body)
            } else {
                return try await body()
            }
        }
    }
}

// Actor isolation boundary enforcement
@propertyWrapper
public struct ActorIsolated<Value: Sendable> {
    private let storage: ActorStorage<Value>
    
    public init(wrappedValue: Value, actor: any Actor) {
        self.storage = ActorStorage(value: wrappedValue, actor: actor)
    }
    
    public var wrappedValue: Value {
        get async { await storage.value }
    }
    
    public var projectedValue: ActorIsolationInfo {
        ActorIsolationInfo(actor: storage.actor)
    }
}

// Safe actor client implementation
public actor SafeActorClient<StateType: Sendable, ActionType>: IsolatedActor, Client {
    public let actorID = ActorIdentifier(
        id: UUID(),
        name: String(describing: Self.self),
        type: "Client"
    )
    public let qualityOfService: DispatchQoS = .userInitiated
    public let reentrancyPolicy: ReentrancyPolicy = .detectAndHandle
    
    private var state: StateType
    private let reentrancyGuard = ReentrancyGuard()
    private let stateValidator: StateValidator<StateType>
    
    public var stateStream: AsyncStream<StateType> {
        // Implementation with isolation guarantees
    }
    
    public func process(_ action: ActionType) async throws {
        try await reentrancyGuard.executeWithGuard(
            policy: reentrancyPolicy,
            operation: .action(String(describing: action))
        ) {
            // Process with isolation guarantees
            try await self.validateActorInvariants()
        }
    }
    
    public func validateActorInvariants() async throws {
        try await stateValidator.validate(state)
    }
}
```

### Actor Performance Monitoring

```swift
// Actor metrics collection
public actor ActorMetrics {
    private var callCounts: [ActorIdentifier: Int] = [:]
    private var callDurations: [ActorIdentifier: [Duration]] = [:]
    private var reentrancyCounts: [ActorIdentifier: Int] = [:]
    
    public func recordCall(
        actorID: ActorIdentifier,
        duration: Duration,
        wasReentrant: Bool
    ) {
        callCounts[actorID, default: 0] += 1
        callDurations[actorID, default: []].append(duration)
        
        if wasReentrant {
            reentrancyCounts[actorID, default: 0] += 1
        }
    }
    
    public func getMetrics(for actorID: ActorIdentifier) -> ActorMetricsSnapshot {
        ActorMetricsSnapshot(
            callCount: callCounts[actorID] ?? 0,
            averageCallDuration: calculateAverage(callDurations[actorID] ?? []),
            reentrancyRate: calculateReentrancyRate(actorID)
        )
    }
}
```

## Technical Design

### Architecture Components

1. **Actor Isolation Layer**
   - Protocol-based isolation boundaries
   - Sendable enforcement at compile time
   - Runtime isolation validation
   - Performance monitoring integration

2. **Communication Layer**
   - Message routing infrastructure
   - Priority-based delivery
   - Timeout handling
   - Metrics collection

3. **Reentrancy Layer**
   - Policy-based reentrancy control
   - State consistency validation
   - Queue management for deferred operations
   - Performance optimization

4. **Monitoring Layer**
   - Actor call metrics
   - Reentrancy detection rates
   - Performance bottleneck identification
   - Optimization recommendations

### Isolation Strategies

1. **Value Type Isolation**
   - Automatic Sendable conformance
   - Copy semantics for safety
   - No shared mutable state
   - Performance through stack allocation

2. **Reference Type Isolation**
   - Actor wrapping for classes
   - Sendable validation
   - Deep copy utilities
   - Memory management

3. **Collection Isolation**
   - Copy-on-write collections
   - Sendable element validation
   - Concurrent collection types
   - Performance optimization

## Success Criteria

### Functional Validation

- [ ] **Actor Isolation**: No data races in concurrent stress tests
- [ ] **Cross-Actor Calls**: Message delivery within timeout constraints
- [ ] **Reentrancy Handling**: All policies correctly implemented
- [ ] **Sendable Enforcement**: Compile-time validation of boundaries
- [ ] **State Consistency**: Invariants maintained across operations

### Integration Validation

- [ ] **Protocol Adoption**: All clients implement IsolatedActor
- [ ] **Message Routing**: Cross-actor communication functional
- [ ] **Metrics Collection**: Performance data available
- [ ] **Error Handling**: Isolation violations properly reported
- [ ] **Testing Support**: Actor testing utilities available

### Performance Validation

- [ ] **Actor Call Overhead**: < 1μs for local calls
- [ ] **Cross-Actor Latency**: < 10μs for message passing
- [ ] **Reentrancy Detection**: < 100ns overhead
- [ ] **Memory Overhead**: < 1KB per actor instance
- [ ] **Concurrent Scaling**: Linear with CPU cores

## Implementation Priority

1. **Phase 1**: IsolatedActor protocol and basic enforcement
2. **Phase 2**: Cross-actor communication infrastructure
3. **Phase 3**: Reentrancy detection and handling
4. **Phase 4**: Performance monitoring and optimization

This requirement provides the foundational actor isolation patterns that ensure data race safety and predictable concurrent execution across the entire AxiomFramework.