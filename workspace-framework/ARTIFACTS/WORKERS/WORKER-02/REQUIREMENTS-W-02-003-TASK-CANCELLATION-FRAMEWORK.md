# REQUIREMENTS-W-02-003-TASK-CANCELLATION-FRAMEWORK

## Requirement Overview

**ID**: W-02-003  
**Title**: Task Cancellation and Priority Handling Framework  
**Type**: WORKER - Concurrency & Actor Safety Domain  
**Priority**: HIGH  
**Worker**: WORKER-02  
**Dependencies**: P-001 (Core Protocol Foundation), W-02-002 (Structured Concurrency Coordination)  

## Executive Summary

Establish a comprehensive task cancellation framework that ensures timely cancellation propagation, priority inheritance, and graceful cleanup across the AxiomFramework. This requirement provides cancellation protocols, priority management, timeout handling, and cleanup coordination that guarantee responsive cancellation within the required 10ms window while preventing resource leaks.

## Current State Analysis

**Existing Implementation in AxiomFramework**:
- `TaskCancellationCoordinator` actor for basic cancellation
- Context-to-client cancellation propagation
- `PriorityCoordinator` for priority inheritance attempts
- Basic task registration/unregistration
- Simple cancellation in `ConcurrentContext`

**Identified Gaps**:
- 10ms cancellation guarantee not enforced
- Priority inheritance incomplete implementation
- Cancellation acknowledgment missing
- Graceful cleanup coordination needed
- Cancellation metrics not collected

## Requirement Details

### 1. Fast Cancellation Propagation

**Requirements**:
- Guarantee cancellation within 10ms across entire task tree
- Asynchronous cancellation notification
- Cancellation acknowledgment protocol
- Performance monitoring of cancellation times

**Performance Targets**:
```swift
public protocol CancellationRequirements {
    // Maximum time for cancellation to propagate
    static var maxPropagationTime: Duration { .milliseconds(10) }
    
    // Maximum time for cleanup operations
    static var maxCleanupTime: Duration { .milliseconds(50) }
    
    // Maximum depth for instant cancellation
    static var instantCancellationDepth: Int { 3 }
}
```

### 2. Priority Inheritance System

**Requirements**:
- Automatic priority boost for blocking tasks
- Priority restoration after unblocking
- Deadlock prevention through priority ceiling
- Performance impact minimization

### 3. Graceful Cleanup Coordination

**Requirements**:
- Ordered cleanup of resources
- Cancellation checkpoints in long operations
- Partial work preservation
- Error-safe cleanup execution

### 4. Timeout Management

**Requirements**:
- Configurable timeout policies
- Automatic cancellation on timeout
- Timeout extension mechanisms
- Performance-aware timeout handling

## API Design

### Enhanced Cancellation System

```swift
// Cancellation token with acknowledgment
public actor CancellationToken {
    private var isCancelled = false
    private var cancellationHandlers: [CancellationHandler] = []
    private var acknowledgments: Set<UUID> = []
    private let metrics = CancellationMetrics()
    
    public struct CancellationHandler {
        let id: UUID
        let priority: TaskPriority
        let handler: @Sendable () async -> Void
        let requiresAcknowledgment: Bool
    }
    
    // Register cancellation handler
    public func onCancellation(
        priority: TaskPriority = .medium,
        requiresAcknowledgment: Bool = false,
        handler: @escaping @Sendable () async -> Void
    ) -> UUID {
        let id = UUID()
        let cancellationHandler = CancellationHandler(
            id: id,
            priority: priority,
            handler: handler,
            requiresAcknowledgment: requiresAcknowledgment
        )
        
        if isCancelled {
            Task(priority: priority) {
                await handler()
                if requiresAcknowledgment {
                    await self.acknowledge(id)
                }
            }
        } else {
            cancellationHandlers.append(cancellationHandler)
        }
        
        return id
    }
    
    // Cancel with guaranteed propagation time
    public func cancel() async {
        guard !isCancelled else { return }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        isCancelled = true
        
        // Sort handlers by priority
        let sortedHandlers = cancellationHandlers.sorted {
            $0.priority.rawValue > $1.priority.rawValue
        }
        
        // Execute handlers with timeout
        await withTaskGroup(of: Void.self) { group in
            for handler in sortedHandlers {
                group.addTask(priority: handler.priority) {
                    await handler.handler()
                    if handler.requiresAcknowledgment {
                        await self.acknowledge(handler.id)
                    }
                }
            }
            
            // Wait with timeout
            let timeoutTask = Task {
                try await Task.sleep(for: .milliseconds(10))
            }
            
            for await _ in group {
                if timeoutTask.isCancelled { break }
            }
            
            timeoutTask.cancel()
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        await metrics.recordCancellation(duration: duration, handlerCount: sortedHandlers.count)
    }
    
    // Acknowledge cancellation
    public func acknowledge(_ handlerID: UUID) {
        acknowledgments.insert(handlerID)
    }
    
    // Wait for all acknowledgments
    public func awaitAcknowledgments(timeout: Duration = .milliseconds(50)) async throws {
        let requiredAcks = cancellationHandlers
            .filter { $0.requiresAcknowledgment }
            .map { $0.id }
        
        let deadline = Date().addingTimeInterval(timeout.seconds)
        
        while !Set(requiredAcks).isSubset(of: acknowledgments) {
            if Date() > deadline {
                throw CancellationError.acknowledgmentTimeout(
                    missing: Set(requiredAcks).subtracting(acknowledgments)
                )
            }
            try await Task.sleep(for: .milliseconds(1))
        }
    }
}

// Priority-aware task with inheritance
public actor PriorityTask<Success: Sendable> {
    private var task: Task<Success, Error>
    private var currentPriority: TaskPriority
    private let originalPriority: TaskPriority
    private let priorityCoordinator: PriorityCoordinator
    
    public init(
        priority: TaskPriority = .medium,
        operation: @escaping @Sendable () async throws -> Success
    ) {
        self.originalPriority = priority
        self.currentPriority = priority
        self.priorityCoordinator = .shared
        
        self.task = Task(priority: priority) {
            try await operation()
        }
    }
    
    // Boost priority temporarily
    public func boostPriority(to newPriority: TaskPriority) async {
        guard newPriority.rawValue > currentPriority.rawValue else { return }
        
        currentPriority = newPriority
        
        // In real implementation, would adjust task scheduler priority
        await priorityCoordinator.recordPriorityBoost(
            from: originalPriority,
            to: newPriority
        )
    }
    
    // Restore original priority
    public func restorePriority() async {
        currentPriority = originalPriority
        await priorityCoordinator.recordPriorityRestore(to: originalPriority)
    }
    
    public var value: Success {
        get async throws {
            try await task.value
        }
    }
    
    public func cancel() {
        task.cancel()
    }
}

// Cancellable operation with checkpoints
public struct CancellableOperation<T> {
    private let operation: (CheckpointContext) async throws -> T
    private let token: CancellationToken
    
    public init(
        token: CancellationToken,
        operation: @escaping (CheckpointContext) async throws -> T
    ) {
        self.token = token
        self.operation = operation
    }
    
    public func execute() async throws -> T {
        let context = CheckpointContext(token: token)
        
        return try await withTaskCancellationHandler {
            try await operation(context)
        } onCancel: {
            Task {
                await token.cancel()
            }
        }
    }
}

// Checkpoint context for long operations
public actor CheckpointContext {
    private let token: CancellationToken
    private var checkpoints: [String: Any] = [:]
    private var lastCheckTime = CFAbsoluteTimeGetCurrent()
    
    init(token: CancellationToken) {
        self.token = token
    }
    
    // Check cancellation at checkpoint
    public func checkpoint(
        _ name: String,
        saveState: Any? = nil
    ) async throws {
        // Check if cancelled
        if await token.isCancelled {
            throw CancellationError.cancelledAtCheckpoint(name, state: checkpoints)
        }
        
        // Save checkpoint state
        if let state = saveState {
            checkpoints[name] = state
        }
        
        // Yield if running too long without check
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastCheckTime > 0.01 { // 10ms
            await Task.yield()
            lastCheckTime = now
        }
    }
    
    // Restore from checkpoint
    public func restore<T>(_ name: String, as type: T.Type) -> T? {
        checkpoints[name] as? T
    }
}

// Timeout manager with cancellation
public actor TimeoutManager {
    private var timeouts: [UUID: TimeoutInfo] = [:]
    
    struct TimeoutInfo {
        let task: any CancellableTask
        let deadline: Date
        let timeoutTask: Task<Void, Error>
    }
    
    // Execute with timeout
    public func withTimeout<T>(
        _ duration: Duration,
        priority: TaskPriority = .medium,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let id = UUID()
        let token = CancellationToken()
        
        let timeoutTask = Task(priority: priority) {
            try await Task.sleep(for: duration)
            await token.cancel()
            throw TimeoutError(duration: duration)
        }
        
        let operationTask = Task(priority: priority) {
            try await CancellableOperation(token: token) { _ in
                try await operation()
            }.execute()
        }
        
        // Store timeout info
        let info = TimeoutInfo(
            task: operationTask,
            deadline: Date().addingTimeInterval(duration.seconds),
            timeoutTask: timeoutTask
        )
        timeouts[id] = info
        
        defer {
            timeoutTask.cancel()
            timeouts.removeValue(forKey: id)
        }
        
        // Race between operation and timeout
        do {
            let result = try await operationTask.value
            timeoutTask.cancel()
            return result
        } catch {
            operationTask.cancel()
            throw error
        }
    }
    
    // Extend timeout for active operation
    public func extendTimeout(
        for id: UUID,
        by duration: Duration
    ) async throws {
        guard var info = timeouts[id] else {
            throw TimeoutError.invalidTimeoutID(id)
        }
        
        // Cancel old timeout
        info.timeoutTask.cancel()
        
        // Create new timeout
        let newDeadline = info.deadline.addingTimeInterval(duration.seconds)
        let newTimeoutTask = Task {
            try await Task.sleep(until: newDeadline)
            await info.task.cancel()
            throw TimeoutError(duration: duration)
        }
        
        info = TimeoutInfo(
            task: info.task,
            deadline: newDeadline,
            timeoutTask: newTimeoutTask
        )
        timeouts[id] = info
    }
}
```

### Cleanup Coordination

```swift
// Cleanup coordinator for ordered resource release
public actor CleanupCoordinator {
    private var cleanupHandlers: [CleanupHandler] = []
    
    public struct CleanupHandler {
        let id: UUID
        let priority: Int // Higher = earlier execution
        let handler: @Sendable () async throws -> Void
        let name: String
    }
    
    // Register cleanup handler
    public func registerCleanup(
        name: String,
        priority: Int = 0,
        handler: @escaping @Sendable () async throws -> Void
    ) -> UUID {
        let id = UUID()
        let cleanupHandler = CleanupHandler(
            id: id,
            priority: priority,
            handler: handler,
            name: name
        )
        cleanupHandlers.append(cleanupHandler)
        return id
    }
    
    // Execute cleanup in priority order
    public func executeCleanup() async {
        let sortedHandlers = cleanupHandlers.sorted { $0.priority > $1.priority }
        
        for handler in sortedHandlers {
            do {
                try await handler.handler()
            } catch {
                // Log but continue cleanup
                await logCleanupError(handler: handler, error: error)
            }
        }
        
        cleanupHandlers.removeAll()
    }
}
```

## Technical Design

### Architecture Components

1. **Cancellation Layer**
   - Token-based cancellation system
   - Acknowledgment protocol
   - Propagation guarantees
   - Performance monitoring

2. **Priority Layer**
   - Priority inheritance mechanism
   - Boost/restore functionality
   - Deadlock prevention
   - Performance optimization

3. **Cleanup Layer**
   - Ordered cleanup execution
   - Error-safe cleanup
   - Resource tracking
   - Partial state preservation

4. **Timeout Layer**
   - Configurable timeout policies
   - Extension mechanisms
   - Cancellation integration
   - Performance awareness

### Cancellation Strategies

1. **Hierarchical Cancellation**
   - Parent-to-child propagation
   - Sibling independence
   - Orphan prevention
   - Acknowledgment collection

2. **Priority-Based Cancellation**
   - High-priority handlers first
   - Parallel execution where possible
   - Timeout enforcement
   - Metric collection

3. **Checkpoint-Based Cancellation**
   - Regular cancellation checks
   - State preservation
   - Resumable operations
   - Performance balance

## Success Criteria

### Functional Validation

- [ ] **Cancellation Speed**: All tasks cancelled within 10ms
- [ ] **Priority Inheritance**: Correct priority propagation verified
- [ ] **Cleanup Execution**: All cleanup handlers run in order
- [ ] **Timeout Accuracy**: Timeouts trigger within 1ms tolerance
- [ ] **Checkpoint Recovery**: Operations resumable from checkpoints

### Integration Validation

- [ ] **Framework Adoption**: All long operations use checkpoints
- [ ] **Token Integration**: Cancellation tokens properly propagated
- [ ] **Cleanup Registration**: Resources register cleanup handlers
- [ ] **Metric Collection**: Cancellation metrics available
- [ ] **Error Handling**: Cancellation errors properly reported

### Performance Validation

- [ ] **Propagation Time**: < 10ms for full tree cancellation
- [ ] **Checkpoint Overhead**: < 100ns per checkpoint
- [ ] **Priority Switch**: < 1μs for priority changes
- [ ] **Cleanup Speed**: < 50ms for full cleanup
- [ ] **Memory Overhead**: < 1KB per cancellation token

## Implementation Priority

1. **Phase 1**: CancellationToken and basic propagation
2. **Phase 2**: Priority inheritance and timeout management
3. **Phase 3**: Checkpoint system and cleanup coordination
4. **Phase 4**: Performance optimization and metrics

This requirement provides the comprehensive task cancellation framework that ensures responsive, reliable cancellation with proper cleanup across the entire AxiomFramework.