# REQUIREMENTS-W-01-003-MUTATION-DSL-ENHANCEMENTS

## Requirement Overview

**ID**: W-01-003  
**Title**: Mutation DSL and State Update Patterns  
**Type**: WORKER - State Management Domain  
**Priority**: HIGH  
**Worker**: WORKER-01  
**Dependencies**: P-001 (Core Protocol Foundation), W-01-001 (State Immutability), W-01-002 (State Ownership)  

## Executive Summary

Enhance the mutation Domain-Specific Language (DSL) to provide intuitive, type-safe state updates while maintaining immutability guarantees. This requirement delivers a comprehensive mutation system with automatic validation, performance optimization, and developer ergonomics that make immutable state updates as natural as mutable operations.

## Current State Analysis

**Existing Implementation in AxiomFramework**:
- `MutableClient` protocol with mutate/mutateAsync methods
- `ObservableClient` extension implementing mutation DSL
- `StateStreamBuilder` for configurable state streams
- `StateValidator` with validation rules
- `StateDiff` for change tracking
- Basic state validation framework

**Identified Gaps**:
- Limited mutation operators and combinators
- No transaction support for complex mutations
- Validation integration needs enhancement
- Performance optimization for batch mutations missing
- Debugging and introspection tools lacking
- No undo/redo support

## Requirement Details

### 1. Enhanced Mutation DSL

**Requirements**:
- Rich set of mutation operators for common patterns
- Type-safe mutation chaining and composition
- Automatic change tracking and diffing
- Integration with validation framework
- Performance optimization for mutations

**Core Operators**:
```swift
// Array mutations
state.items.append(item)
state.items.removeAll { $0.isCompleted }
state.items[0].title = "Updated"

// Dictionary mutations  
state.settings["theme"] = .dark
state.cache.removeValue(forKey: "old")

// Complex mutations
state.users
    .filter { $0.isActive }
    .forEach { $0.lastSeen = Date() }
```

### 2. Transactional Mutations

**Requirements**:
- Atomic multi-step mutations
- Rollback on validation failure
- Isolation levels for concurrent access
- Transaction logging and replay

### 3. Performance Optimizations

**Requirements**:
- Batch mutation coalescing
- Structural sharing for nested updates
- Lazy evaluation of expensive operations
- Parallel mutation execution where safe

### 4. Developer Experience

**Requirements**:
- Clear error messages for invalid mutations
- Mutation debugging and introspection
- Performance profiling integration
- Undo/redo capability

## API Design

### Enhanced Mutation DSL

```swift
// Extended MutableClient protocol
public protocol MutableClient: Client {
    // Basic mutations with result
    @discardableResult
    func mutate<T>(_ mutation: (inout StateType) throws -> T) async throws -> T
    
    // Transactional mutations
    @discardableResult
    func transaction<T>(_ operations: (Transaction<StateType>) async throws -> T) async throws -> T
    
    // Validated mutations
    @discardableResult
    func validatedMutate<T>(
        _ mutation: (inout StateType) throws -> T,
        validations: [StateValidationRule<StateType>]
    ) async throws -> T
    
    // Batch mutations with optimization
    func batchMutate(_ mutations: [(inout StateType) throws -> Void]) async throws
}

// Transaction support
public struct Transaction<S: State> {
    private var state: S
    private var operations: [Operation<S>] = []
    
    // Record operations for atomic execution
    public mutating func update<T>(
        _ keyPath: WritableKeyPath<S, T>,
        to value: T
    ) {
        operations.append(.update(keyPath, value))
    }
    
    public mutating func transform<T>(
        _ keyPath: WritableKeyPath<S, T>,
        using transform: @escaping (T) -> T
    ) {
        operations.append(.transform(keyPath, transform))
    }
    
    // Conditional operations
    public mutating func updateIf<T>(
        _ condition: @escaping (S) -> Bool,
        _ keyPath: WritableKeyPath<S, T>,
        to value: T
    ) {
        operations.append(.conditional(condition, .update(keyPath, value)))
    }
}

// Mutation operators via property wrapper
@propertyWrapper
public struct Mutable<Value> {
    private var getter: () -> Value
    private var setter: (Value) -> Void
    
    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }
    
    // Mutation operators
    public func update(_ transform: (inout Value) -> Void) {
        var value = getter()
        transform(&value)
        setter(value)
    }
}
```

### Collection Mutation Extensions

```swift
// Array mutation DSL
extension Array where Element: Identifiable {
    @discardableResult
    public mutating func update(
        id: Element.ID,
        _ transform: (inout Element) -> Void
    ) -> Bool {
        guard let index = firstIndex(where: { $0.id == id }) else {
            return false
        }
        transform(&self[index])
        return true
    }
    
    @discardableResult
    public mutating func upsert(_ element: Element) -> Element {
        if let index = firstIndex(where: { $0.id == element.id }) {
            self[index] = element
        } else {
            append(element)
        }
        return element
    }
    
    public mutating func removeAll(ids: Set<Element.ID>) {
        removeAll { ids.contains($0.id) }
    }
}

// Dictionary mutation DSL
extension Dictionary {
    @discardableResult
    public mutating func update(
        key: Key,
        default defaultValue: Value,
        _ transform: (inout Value) -> Void
    ) -> Value {
        var value = self[key] ?? defaultValue
        transform(&value)
        self[key] = value
        return value
    }
    
    public mutating func merge(
        _ other: Dictionary,
        uniquingKeysWith combine: (Value, Value) -> Value
    ) {
        for (key, value) in other {
            if let existing = self[key] {
                self[key] = combine(existing, value)
            } else {
                self[key] = value
            }
        }
    }
}
```

### Performance-Optimized Mutations

```swift
// Batch mutation coordinator
public actor BatchMutationCoordinator<S: State> {
    private var pendingMutations: [DeferredMutation<S>] = []
    private let coalescingWindow: TimeInterval = 0.016 // 1 frame
    
    public func enqueue(_ mutation: @escaping (inout S) -> Void) async {
        let deferred = DeferredMutation(mutation: mutation)
        pendingMutations.append(deferred)
        
        // Coalesce mutations within time window
        Task {
            try? await Task.sleep(for: .milliseconds(16))
            await processBatch()
        }
    }
    
    private func processBatch() async {
        guard !pendingMutations.isEmpty else { return }
        
        let mutations = pendingMutations
        pendingMutations.removeAll(keepingCapacity: true)
        
        // Optimize and combine mutations
        let optimized = optimizeMutations(mutations)
        
        // Execute as single state update
        await executeOptimized(optimized)
    }
}

// Undo/Redo support
public actor UndoManager<S: State> {
    private var history: [StateSnapshot<S>] = []
    private var currentIndex: Int = -1
    private let maxHistory: Int
    
    public init(maxHistory: Int = 100) {
        self.maxHistory = maxHistory
    }
    
    public func recordSnapshot(_ state: S) {
        // Remove any redo history
        if currentIndex < history.count - 1 {
            history.removeLast(history.count - currentIndex - 1)
        }
        
        // Add new snapshot
        history.append(StateSnapshot(state: state, timestamp: Date()))
        currentIndex = history.count - 1
        
        // Trim old history
        if history.count > maxHistory {
            history.removeFirst()
            currentIndex -= 1
        }
    }
    
    public func undo() -> S? {
        guard currentIndex > 0 else { return nil }
        currentIndex -= 1
        return history[currentIndex].state
    }
    
    public func redo() -> S? {
        guard currentIndex < history.count - 1 else { return nil }
        currentIndex += 1
        return history[currentIndex].state
    }
}
```

### Debugging and Introspection

```swift
// Mutation debugger
public struct MutationDebugger<S: State> {
    public static func trace<T>(
        _ mutation: (inout S) throws -> T,
        on state: S
    ) throws -> (result: T, diff: StateDiff<S>, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        var mutableState = state
        
        // Capture before state
        let before = state
        
        // Execute mutation
        let result = try mutation(&mutableState)
        
        // Calculate diff
        let diff = StateDiff(before: before, after: mutableState)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Log mutation details
        print("""
        Mutation Debug:
        - Duration: \(duration * 1000)ms
        - Changes: \(diff.hasChanges() ? "Yes" : "No")
        - Memory: \(MemoryLayout.size(ofValue: mutableState)) bytes
        """)
        
        return (result, diff, duration)
    }
}

// Mutation profiler
public actor MutationProfiler<S: State> {
    private var profiles: [MutationProfile] = []
    
    public func profile<T>(
        name: String,
        _ mutation: (inout S) throws -> T,
        on state: S
    ) async throws -> T {
        let profile = try await measure {
            try MutationDebugger.trace(mutation, on: state)
        }
        
        profiles.append(MutationProfile(
            name: name,
            duration: profile.duration,
            memoryDelta: profile.memoryDelta
        ))
        
        return profile.result
    }
    
    public func report() -> MutationReport {
        MutationReport(profiles: profiles)
    }
}
```

## Technical Design

### Architecture Components

1. **Mutation Engine**
   - DSL for natural mutation syntax
   - Automatic immutability preservation
   - Change tracking and diffing
   - Validation integration

2. **Transaction System**
   - Atomic multi-step operations
   - Rollback capability
   - Isolation for concurrent access
   - Transaction log for replay

3. **Performance Layer**
   - Batch mutation optimization
   - Structural sharing
   - Lazy evaluation
   - Parallel execution

4. **Developer Tools**
   - Mutation debugging
   - Performance profiling
   - Undo/redo support
   - Introspection APIs

### Optimization Strategies

1. **Batch Coalescing**
   - Combine multiple mutations in single update
   - Remove redundant operations
   - Optimize operation order
   - Minimize state copies

2. **Structural Sharing**
   - Share unchanged portions between versions
   - Copy-on-write for collections
   - Path copying for nested updates
   - Memory pooling for allocations

3. **Lazy Evaluation**
   - Defer expensive computations
   - Cache intermediate results
   - Skip unnecessary validations
   - Incremental updates

## Success Criteria

### Functional Validation

- [ ] **DSL Completeness**: All common mutation patterns supported
- [ ] **Transaction Atomicity**: Multi-step mutations execute atomically
- [ ] **Validation Integration**: All mutations validated automatically
- [ ] **Undo/Redo**: State history maintained correctly
- [ ] **Type Safety**: Compile-time validation of mutations

### Integration Validation

- [ ] **Client Integration**: All clients support enhanced DSL
- [ ] **Stream Updates**: Mutations trigger state streams
- [ ] **Error Handling**: Invalid mutations reported clearly
- [ ] **Performance Tools**: Profiling integrated seamlessly
- [ ] **Debug Support**: Mutation tracing available

### Performance Validation

- [ ] **Mutation Speed**: < 100ns for simple property updates
- [ ] **Batch Efficiency**: > 10x speedup for batched operations
- [ ] **Memory Usage**: < 2x peak memory during mutations
- [ ] **Transaction Overhead**: < 1μs for transaction setup
- [ ] **Profiling Impact**: < 5% overhead when enabled

## Implementation Priority

1. **Phase 1**: Enhanced mutation operators and DSL
2. **Phase 2**: Transaction support and atomicity
3. **Phase 3**: Performance optimizations and batching
4. **Phase 4**: Developer tools and debugging support

This requirement delivers a powerful, intuitive mutation system that makes working with immutable state as natural as mutable operations while maintaining all safety guarantees.