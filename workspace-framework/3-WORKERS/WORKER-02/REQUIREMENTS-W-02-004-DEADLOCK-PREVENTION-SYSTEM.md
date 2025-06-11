# REQUIREMENTS-W-02-004-DEADLOCK-PREVENTION-SYSTEM

## Requirement Overview

**ID**: W-02-004  
**Title**: Deadlock Prevention and Detection System  
**Type**: WORKER - Concurrency & Actor Safety Domain  
**Priority**: CRITICAL  
**Worker**: WORKER-02  
**Dependencies**: P-001 (Core Protocol Foundation), W-02-001 (Actor Isolation Patterns)  

## Executive Summary

Establish a comprehensive deadlock prevention and detection system that ensures safe cross-actor communication across the AxiomFramework. This requirement provides resource ordering protocols, wait-for graph analysis, timeout-based detection, and recovery mechanisms that prevent circular dependencies and guarantee forward progress in concurrent execution.

## Current State Analysis

**Existing Implementation in AxiomFramework**:
- `DeadlockPrevention` enum with basic timeout detection
- `performWithDeadlockDetection` function with 500ms timeout
- Basic resource ownership tracking in `PriorityCoordinator`
- Simple waiting client lists
- `DeadlockError` for timeout reporting

**Identified Gaps**:
- No wait-for graph construction or analysis
- Resource ordering protocols missing
- Deadlock recovery mechanisms absent
- Prevention strategies not comprehensive
- Runtime detection limited to timeouts

## Requirement Details

### 1. Resource Ordering Protocol

**Requirements**:
- Global resource ordering to prevent circular waits
- Automatic ordering enforcement
- Resource hierarchy validation
- Performance-optimized acquisition

**Ordering Rules**:
```swift
public protocol ResourceOrdering {
    // Unique resource identifier
    var resourceID: ResourceIdentifier { get }
    
    // Global ordering value
    var orderingKey: UInt64 { get }
    
    // Resource type for categorization
    var resourceType: ResourceType { get }
    
    // Validate acquisition order
    func validateAcquisitionOrder(
        holding: Set<ResourceIdentifier>
    ) throws
}
```

### 2. Wait-For Graph Analysis

**Requirements**:
- Real-time wait-for graph construction
- Cycle detection algorithms
- Graph visualization for debugging
- Performance-aware analysis

**Performance Targets**:
- < 1μs for graph updates
- < 10μs for cycle detection
- < 100μs for full graph analysis

### 3. Deadlock Detection

**Requirements**:
- Multiple detection strategies
- Configurable detection thresholds
- False positive minimization
- Recovery action triggers

### 4. Recovery Mechanisms

**Requirements**:
- Safe transaction rollback
- Resource preemption protocols
- State consistency preservation
- Progress guarantee strategies

## API Design

### Deadlock Prevention System

```swift
// Resource identifier with ordering
public struct ResourceIdentifier: Hashable, Comparable, Sendable {
    public let id: UUID
    public let type: ResourceType
    public let orderingKey: UInt64
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.orderingKey < rhs.orderingKey
    }
}

// Resource types for categorization
public enum ResourceType: String, Sendable {
    case actor
    case data
    case io
    case computation
    case synchronization
}

// Deadlock prevention coordinator
public actor DeadlockPreventionCoordinator {
    private var waitForGraph = WaitForGraph()
    private var resourceOwnership: [ResourceIdentifier: ActorIdentifier] = [:]
    private var transactionLog = TransactionLog()
    private let detector = DeadlockDetector()
    
    // Request resources with ordering enforcement
    public func requestResources(
        _ resources: Set<ResourceIdentifier>,
        for actor: ActorIdentifier,
        timeout: Duration = .seconds(1)
    ) async throws -> ResourceLease {
        // Validate ordering
        try validateResourceOrdering(resources, holding: getHeldResources(for: actor))
        
        // Add to wait-for graph
        await waitForGraph.addWaitingFor(actor: actor, resources: resources)
        
        // Check for potential deadlock
        if let cycle = await detector.detectCycle(in: waitForGraph) {
            throw DeadlockError.cycleDetected(cycle)
        }
        
        // Try to acquire with timeout
        return try await withTimeout(timeout) {
            try await self.acquireResources(resources, for: actor)
        }
    }
    
    // Acquire resources in order
    private func acquireResources(
        _ resources: Set<ResourceIdentifier>,
        for actor: ActorIdentifier
    ) async throws -> ResourceLease {
        // Sort resources by ordering key
        let sortedResources = resources.sorted()
        var acquired: [ResourceIdentifier] = []
        
        do {
            for resource in sortedResources {
                try await acquireResource(resource, for: actor)
                acquired.append(resource)
            }
            
            // Remove from wait-for graph
            await waitForGraph.removeWaitingFor(actor: actor)
            
            return ResourceLease(
                resources: Set(acquired),
                actor: actor,
                coordinator: self
            )
        } catch {
            // Rollback on failure
            for resource in acquired.reversed() {
                await releaseResource(resource, from: actor)
            }
            throw error
        }
    }
    
    // Validate resource ordering
    private func validateResourceOrdering(
        _ requested: Set<ResourceIdentifier>,
        holding: Set<ResourceIdentifier>
    ) throws {
        guard let maxHeld = holding.max() else { return }
        guard let minRequested = requested.min() else { return }
        
        if maxHeld > minRequested {
            throw DeadlockError.orderingViolation(
                holding: maxHeld,
                requesting: minRequested
            )
        }
    }
}

// Wait-for graph for cycle detection
public actor WaitForGraph {
    private var edges: [ActorIdentifier: Set<ActorIdentifier>] = [:]
    private var resourceWaiters: [ResourceIdentifier: Set<ActorIdentifier>] = [:]
    private var resourceOwners: [ResourceIdentifier: ActorIdentifier] = [:]
    
    public func addWaitingFor(
        actor: ActorIdentifier,
        resources: Set<ResourceIdentifier>
    ) {
        for resource in resources {
            // Add to waiters
            resourceWaiters[resource, default: []].insert(actor)
            
            // If resource is owned, add edge
            if let owner = resourceOwners[resource] {
                edges[actor, default: []].insert(owner)
            }
        }
    }
    
    public func setOwnership(
        resource: ResourceIdentifier,
        owner: ActorIdentifier
    ) {
        resourceOwners[resource] = owner
        
        // Update edges for waiters
        if let waiters = resourceWaiters[resource] {
            for waiter in waiters {
                edges[waiter, default: []].insert(owner)
            }
        }
    }
    
    public func removeWaitingFor(actor: ActorIdentifier) {
        edges.removeValue(forKey: actor)
        
        // Remove from all waiter lists
        for (resource, var waiters) in resourceWaiters {
            waiters.remove(actor)
            if waiters.isEmpty {
                resourceWaiters.removeValue(forKey: resource)
            } else {
                resourceWaiters[resource] = waiters
            }
        }
    }
    
    public func getGraph() -> [ActorIdentifier: Set<ActorIdentifier>] {
        edges
    }
}

// Deadlock detector with multiple strategies
public actor DeadlockDetector {
    private let strategies: [DetectionStrategy] = [
        CycleDetectionStrategy(),
        TimeoutDetectionStrategy(),
        ResourcePatternStrategy()
    ]
    private var detectionMetrics = DetectionMetrics()
    
    public func detectCycle(in graph: WaitForGraph) async -> DeadlockCycle? {
        let adjacencyList = await graph.getGraph()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Try each strategy
        for strategy in strategies {
            if let cycle = strategy.detect(adjacencyList) {
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                await detectionMetrics.recordDetection(
                    strategy: strategy.name,
                    duration: duration,
                    cycleLength: cycle.actors.count
                )
                return cycle
            }
        }
        
        return nil
    }
}

// Cycle detection strategy
struct CycleDetectionStrategy: DetectionStrategy {
    let name = "DFS Cycle Detection"
    
    func detect(_ graph: [ActorIdentifier: Set<ActorIdentifier>]) -> DeadlockCycle? {
        var visited = Set<ActorIdentifier>()
        var recursionStack = Set<ActorIdentifier>()
        var path: [ActorIdentifier] = []
        
        func dfs(_ node: ActorIdentifier) -> DeadlockCycle? {
            visited.insert(node)
            recursionStack.insert(node)
            path.append(node)
            
            if let neighbors = graph[node] {
                for neighbor in neighbors {
                    if !visited.contains(neighbor) {
                        if let cycle = dfs(neighbor) {
                            return cycle
                        }
                    } else if recursionStack.contains(neighbor) {
                        // Found cycle
                        if let startIndex = path.firstIndex(of: neighbor) {
                            let cyclePath = Array(path[startIndex...])
                            return DeadlockCycle(
                                actors: cyclePath,
                                resources: findResourcesInCycle(cyclePath)
                            )
                        }
                    }
                }
            }
            
            recursionStack.remove(node)
            path.removeLast()
            return nil
        }
        
        // Check all nodes
        for node in graph.keys {
            if !visited.contains(node) {
                if let cycle = dfs(node) {
                    return cycle
                }
            }
        }
        
        return nil
    }
}

// Resource lease with automatic cleanup
public struct ResourceLease: Sendable {
    let resources: Set<ResourceIdentifier>
    let actor: ActorIdentifier
    private let coordinator: DeadlockPreventionCoordinator
    
    // Release resources in reverse order
    public func release() async {
        let sortedResources = resources.sorted().reversed()
        for resource in sortedResources {
            await coordinator.releaseResource(resource, from: actor)
        }
    }
}

// Recovery mechanisms
public actor DeadlockRecovery {
    private let preventionCoordinator: DeadlockPreventionCoordinator
    private var recoveryStrategies: [RecoveryStrategy] = [
        VictimSelectionStrategy(),
        TransactionRollbackStrategy(),
        ResourcePreemptionStrategy()
    ]
    
    public func recoverFromDeadlock(
        _ cycle: DeadlockCycle
    ) async throws {
        // Try recovery strategies in order
        for strategy in recoveryStrategies {
            if await strategy.canRecover(cycle) {
                try await strategy.recover(cycle, coordinator: preventionCoordinator)
                return
            }
        }
        
        throw DeadlockError.unrecoverable(cycle)
    }
}

// Transaction rollback for recovery
public actor TransactionLog {
    private var transactions: [UUID: Transaction] = [:]
    
    public struct Transaction {
        let id: UUID
        let actor: ActorIdentifier
        let startTime: Date
        var operations: [Operation] = []
        var checkpoints: [Checkpoint] = []
    }
    
    public func beginTransaction(for actor: ActorIdentifier) -> UUID {
        let id = UUID()
        transactions[id] = Transaction(
            id: id,
            actor: actor,
            startTime: Date()
        )
        return id
    }
    
    public func addOperation(
        to transactionID: UUID,
        operation: Operation
    ) async {
        transactions[transactionID]?.operations.append(operation)
    }
    
    public func checkpoint(
        transactionID: UUID,
        state: Any
    ) async -> CheckpointID {
        let checkpoint = Checkpoint(
            id: UUID(),
            timestamp: Date(),
            state: state
        )
        transactions[transactionID]?.checkpoints.append(checkpoint)
        return checkpoint.id
    }
    
    public func rollback(
        transactionID: UUID,
        to checkpoint: CheckpointID? = nil
    ) async throws {
        guard let transaction = transactions[transactionID] else {
            throw TransactionError.notFound(transactionID)
        }
        
        // Find rollback point
        let rollbackPoint: Int
        if let checkpoint = checkpoint,
           let index = transaction.checkpoints.firstIndex(where: { $0.id == checkpoint }) {
            rollbackPoint = transaction.operations.count // Simplified
        } else {
            rollbackPoint = 0 // Full rollback
        }
        
        // Rollback operations in reverse order
        for operation in transaction.operations[rollbackPoint...].reversed() {
            try await operation.rollback()
        }
    }
}
```

### Prevention Strategies

```swift
// Banker's algorithm for deadlock avoidance
public actor BankersAlgorithm {
    private var available: [ResourceType: Int] = [:]
    private var maximum: [ActorIdentifier: [ResourceType: Int]] = [:]
    private var allocation: [ActorIdentifier: [ResourceType: Int]] = [:]
    
    public func isSafeState(
        after request: ResourceRequest
    ) async -> Bool {
        // Simulate allocation
        var testAvailable = available
        var testAllocation = allocation
        
        // Apply request
        for (type, count) in request.resources {
            testAvailable[type, default: 0] -= count
            testAllocation[request.actor, default: [:]][type, default: 0] += count
        }
        
        // Check if resulting state is safe
        return checkSafeSequence(
            available: testAvailable,
            allocation: testAllocation,
            maximum: maximum
        )
    }
    
    private func checkSafeSequence(
        available: [ResourceType: Int],
        allocation: [ActorIdentifier: [ResourceType: Int]],
        maximum: [ActorIdentifier: [ResourceType: Int]]
    ) -> Bool {
        var work = available
        var finish = Set<ActorIdentifier>()
        
        while finish.count < allocation.count {
            var found = false
            
            for (actor, alloc) in allocation where !finish.contains(actor) {
                let need = calculateNeed(
                    maximum: maximum[actor] ?? [:],
                    allocation: alloc
                )
                
                if canSatisfy(need: need, available: work) {
                    // Release resources
                    for (type, count) in alloc {
                        work[type, default: 0] += count
                    }
                    finish.insert(actor)
                    found = true
                    break
                }
            }
            
            if !found {
                return false // No safe sequence exists
            }
        }
        
        return true
    }
}
```

## Technical Design

### Architecture Components

1. **Prevention Layer**
   - Resource ordering protocols
   - Banker's algorithm implementation
   - Two-phase locking
   - Timestamp ordering

2. **Detection Layer**
   - Wait-for graph maintenance
   - Multiple detection algorithms
   - False positive filtering
   - Performance optimization

3. **Recovery Layer**
   - Victim selection strategies
   - Transaction rollback
   - Resource preemption
   - State restoration

4. **Monitoring Layer**
   - Deadlock frequency tracking
   - Recovery success rates
   - Performance impact measurement
   - Pattern analysis

### Prevention Strategies

1. **Resource Ordering**
   - Global ordering enforcement
   - Automatic order validation
   - Performance optimization
   - Debugging support

2. **Deadlock Avoidance**
   - Banker's algorithm variants
   - Safe state validation
   - Request denial handling
   - Performance tuning

3. **Timeout-Based Prevention**
   - Adaptive timeout values
   - Exponential backoff
   - Priority consideration
   - Progress monitoring

## Success Criteria

### Functional Validation

- [ ] **Deadlock Prevention**: No deadlocks in stress tests
- [ ] **Cycle Detection**: All cycles detected within 10μs
- [ ] **Resource Ordering**: Ordering violations prevented
- [ ] **Recovery Success**: 100% recovery from detected deadlocks
- [ ] **State Consistency**: No corruption after recovery

### Integration Validation

- [ ] **Framework Integration**: All actors use prevention system
- [ ] **Graph Accuracy**: Wait-for graph correctly maintained
- [ ] **Recovery Integration**: Clean rollback of operations
- [ ] **Metric Collection**: Deadlock metrics available
- [ ] **Testing Support**: Deadlock injection for testing

### Performance Validation

- [ ] **Detection Speed**: < 10μs for cycle detection
- [ ] **Prevention Overhead**: < 1μs for order validation
- [ ] **Recovery Time**: < 100ms for full recovery
- [ ] **Graph Updates**: < 1μs per edge modification
- [ ] **Memory Overhead**: < 10KB for typical graphs

## Implementation Priority

1. **Phase 1**: Resource ordering and basic prevention
2. **Phase 2**: Wait-for graph and cycle detection
3. **Phase 3**: Recovery mechanisms and rollback
4. **Phase 4**: Advanced strategies and optimization

This requirement provides the comprehensive deadlock prevention and detection system that ensures safe, deadlock-free concurrent execution across the entire AxiomFramework.