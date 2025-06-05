import Foundation

// MARK: - Immutable State Protocol

/// Protocol for immutable state types in the Axiom framework.
/// 
/// All state mutations produce new immutable value type instances,
/// ensuring thread safety and preventing data corruption during
/// concurrent access.
public protocol ImmutableState: Equatable, Sendable {
    /// Unique identifier for state versioning
    var id: String { get }
}

// MARK: - State Update Result

/// Result of a state update operation
public struct StateUpdateResult<State: ImmutableState> {
    public let oldState: State
    public let newState: State
    public let version: Int
    
    public init(oldState: State, newState: State, version: Int) {
        self.oldState = oldState
        self.newState = newState
        self.version = version
    }
}

// MARK: - Immutable State Manager

/// Manages immutable state updates with versioning.
/// 
/// This class ensures that all state mutations produce new instances
/// rather than modifying existing state.
public class ImmutableStateManager<State: ImmutableState> {
    private var _currentState: State
    private var version: Int = 0
    private let lock = NSLock()
    
    public var currentState: State {
        lock.lock()
        defer { lock.unlock() }
        return _currentState
    }
    
    public init(initialState: State) {
        self._currentState = initialState
    }
    
    /// Updates the state by applying a transformation.
    /// 
    /// - Parameter transform: A function that creates a new state from the current state
    /// - Returns: The new state after applying the transformation
    @discardableResult
    public func update(_ transform: (State) -> State) -> State {
        lock.lock()
        defer { lock.unlock() }
        
        let newState = transform(_currentState)
        _currentState = newState
        version += 1
        
        return newState
    }
    
    /// Updates the state with automatic versioning.
    /// 
    /// - Parameter transform: A function that creates a new state from the current state
    /// - Returns: Result containing old state, new state, and version
    public func updateWithResult(_ transform: (State) -> State) -> StateUpdateResult<State> {
        lock.lock()
        defer { lock.unlock() }
        
        let oldState = _currentState
        let newState = transform(oldState)
        _currentState = newState
        version += 1
        
        return StateUpdateResult(oldState: oldState, newState: newState, version: version)
    }
}

// MARK: - Concurrent Immutable State Manager

/// Actor-based state manager for concurrent immutable state updates.
/// 
/// Ensures all concurrent mutations produce consistent final state
/// without data corruption. Optimized for high-frequency updates.
public actor ConcurrentImmutableStateManager<State: ImmutableState> {
    private var _state: State
    private var version: Int = 0
    private var updateHistory: [String] = []
    private let historyLimit: Int
    
    public var state: State {
        _state
    }
    
    public init(initialState: State, historyLimit: Int = 1000) {
        self._state = initialState
        self.historyLimit = historyLimit
    }
    
    /// Performs an atomic state update.
    /// 
    /// - Parameter transform: A function that creates a new state from the current state
    /// - Returns: The new state after applying the transformation
    @discardableResult
    public func update(_ transform: (State) -> State) async -> State {
        let newState = transform(_state)
        _state = newState
        version += 1
        addToHistory("v\(version)")
        return newState
    }
    
    /// Performs a tracked state update.
    /// 
    /// - Parameters:
    ///   - id: Unique identifier for this update
    ///   - transform: A function that creates a new state from the current state
    /// - Returns: The new state after applying the transformation
    @discardableResult
    public func trackedUpdate(id: String, _ transform: (State) -> State) async -> State {
        let newState = transform(_state)
        _state = newState
        version += 1
        addToHistory(id)
        return newState
    }
    
    /// Performs multiple updates atomically.
    /// 
    /// - Parameter transforms: Array of transformations to apply
    /// - Returns: The final state after all transformations
    @discardableResult
    public func batchUpdate(_ transforms: [(State) -> State]) async -> State {
        let finalState = transforms.reduce(_state) { currentState, transform in
            transform(currentState)
        }
        _state = finalState
        version += transforms.count
        addToHistory("batch-v\(version)-count:\(transforms.count)")
        return finalState
    }
    
    /// Gets the current version number.
    public func getVersion() async -> Int {
        version
    }
    
    /// Gets the update history.
    public func getHistory() async -> [String] {
        updateHistory
    }
    
    /// Adds entry to history with size limit.
    private func addToHistory(_ entry: String) {
        updateHistory.append(entry)
        if updateHistory.count > historyLimit {
            updateHistory.removeFirst(updateHistory.count - historyLimit)
        }
    }
}

// MARK: - Copy-on-Write Container

/// A container that implements copy-on-write semantics for large state objects.
/// 
/// This optimization ensures that copying state is cheap until mutations occur.
/// Performance characteristics:
/// - O(1) copy operations (reference counting only)
/// - O(n) first mutation after copy (actual data copy)
/// - O(1) subsequent mutations on same instance
public struct COWContainer<Value> {
    private var storage: COWStorage<Value>
    
    public init(_ value: Value) {
        self.storage = COWStorage(value)
    }
    
    public var value: Value {
        get { storage.value }
        set {
            ensureUnique()
            storage.value = newValue
        }
    }
    
    /// Checks if this container shares storage with another.
    public func sharesStorage(with other: COWContainer<Value>) -> Bool {
        return storage === other.storage
    }
    
    /// Applies a mutation with copy-on-write semantics.
    public mutating func withMutation<T>(_ mutation: (inout Value) throws -> T) rethrows -> T {
        ensureUnique()
        return try mutation(&storage.value)
    }
    
    /// Ensures the storage is uniquely referenced, copying if needed.
    private mutating func ensureUnique() {
        if !isKnownUniquelyReferenced(&storage) {
            storage = COWStorage(storage.value)
        }
    }
    
    /// Pre-emptively makes storage unique if it will be mutated.
    /// Useful for optimizing multiple sequential mutations.
    public mutating func makeUnique() {
        ensureUnique()
    }
}

/// Internal storage class for copy-on-write implementation.
/// Uses class semantics for reference counting.
private final class COWStorage<Value> {
    var value: Value
    
    init(_ value: Value) {
        self.value = value
    }
}

// MARK: - Thread-Safe State Container

/// A thread-safe container for immutable state updates.
/// 
/// Provides safe concurrent read access and serialized write access.
public actor ThreadSafeStateContainer<State: ImmutableState> {
    private var _state: State
    private var writeCount: Int = 0
    
    public init(initialState: State) {
        self._state = initialState
    }
    
    /// Reads the current state.
    public func read() -> State {
        _state
    }
    
    /// Writes a new state.
    /// 
    /// - Parameter newState: The new state to set
    /// - Returns: The previous state
    @discardableResult
    public func write(_ newState: State) -> State {
        let oldState = _state
        _state = newState
        writeCount += 1
        return oldState
    }
    
    /// Updates the state with a transformation.
    /// 
    /// - Parameter transform: A function that creates a new state from the current state
    /// - Returns: The new state
    @discardableResult
    public func update(_ transform: (State) -> State) -> State {
        let newState = transform(_state)
        _state = newState
        writeCount += 1
        return newState
    }
    
    /// Gets the total number of writes.
    public func getWriteCount() -> Int {
        writeCount
    }
}

// MARK: - State Validation

/// Protocol for states that can validate their internal consistency.
public protocol ValidatableState: ImmutableState {
    /// Checks if the state is internally consistent.
    func isValid() -> Bool
    
    /// Checks if the state maintains invariants.
    func checkInvariants() -> [String]
}

// MARK: - Immutable Collection Helpers

/// Extensions for working with immutable collections in state.
public extension Array {
    /// Returns a new array with the element appended.
    func appending(_ element: Element) -> [Element] {
        var copy = self
        copy.append(element)
        return copy
    }
    
    /// Returns a new array with the elements appended.
    func appending<S: Sequence>(contentsOf elements: S) -> [Element] where S.Element == Element {
        var copy = self
        copy.append(contentsOf: elements)
        return copy
    }
    
    /// Returns a new array with the element at the specified index replaced.
    func replacing(at index: Int, with element: Element) -> [Element] {
        guard index >= 0 && index < count else { return self }
        var copy = self
        copy[index] = element
        return copy
    }
}

public extension Dictionary {
    /// Returns a new dictionary with the key-value pair added or updated.
    func setting(_ key: Key, to value: Value) -> [Key: Value] {
        var copy = self
        copy[key] = value
        return copy
    }
    
    /// Returns a new dictionary with the key removed.
    func removing(_ key: Key) -> [Key: Value] {
        var copy = self
        copy.removeValue(forKey: key)
        return copy
    }
}

// MARK: - State Builder

/// A builder pattern for constructing immutable states.
/// Optimized for chained modifications without intermediate allocations.
public struct StateBuilder<State> {
    private let build: () -> State
    
    public init(_ build: @escaping () -> State) {
        self.build = build
    }
    
    public init(from state: State) {
        self.build = { state }
    }
    
    public func make() -> State {
        build()
    }
    
    /// Modifies a single property.
    public func with<T>(_ keyPath: WritableKeyPath<State, T>, value: T) -> StateBuilder<State> {
        StateBuilder {
            var state = self.build()
            state[keyPath: keyPath] = value
            return state
        }
    }
    
    /// Applies multiple modifications in a single step.
    public func withChanges(_ changes: @escaping (inout State) -> Void) -> StateBuilder<State> {
        StateBuilder {
            var state = self.build()
            changes(&state)
            return state
        }
    }
    
    /// Conditionally applies a modification.
    public func withIf<T>(_ condition: Bool, _ keyPath: WritableKeyPath<State, T>, value: T) -> StateBuilder<State> {
        guard condition else { return self }
        return with(keyPath, value: value)
    }
}

// MARK: - Performance Optimizations

/// Protocol for states that support batch updates.
public protocol BatchUpdatable: ImmutableState {
    /// Applies multiple updates in a single atomic operation.
    func applyingBatch(_ updates: [(keyPath: PartialKeyPath<Self>, value: Any)]) -> Self
}

/// Optimized state update queue for high-frequency mutations.
public actor StateUpdateQueue<State: ImmutableState> {
    private var pendingUpdates: [(State) -> State] = []
    private var batchTimer: Task<Void, Never>?
    private let batchInterval: TimeInterval
    private let maxBatchSize: Int
    private let container: ConcurrentImmutableStateManager<State>
    
    public init(
        initialState: State,
        batchInterval: TimeInterval = 0.016, // ~60fps
        maxBatchSize: Int = 100
    ) {
        self.container = ConcurrentImmutableStateManager(initialState: initialState)
        self.batchInterval = batchInterval
        self.maxBatchSize = maxBatchSize
    }
    
    /// Enqueues an update for batched processing.
    public func enqueueUpdate(_ update: @escaping (State) -> State) async {
        pendingUpdates.append(update)
        
        if pendingUpdates.count >= maxBatchSize {
            await processBatch()
        } else if batchTimer == nil {
            batchTimer = Task {
                try? await Task.sleep(nanoseconds: UInt64(batchInterval * 1_000_000_000))
                await self.processBatch()
            }
        }
    }
    
    /// Processes all pending updates.
    private func processBatch() async {
        guard !pendingUpdates.isEmpty else { return }
        
        let updates = pendingUpdates
        pendingUpdates.removeAll(keepingCapacity: true)
        batchTimer = nil
        
        // Apply all updates in sequence
        await container.update { state in
            updates.reduce(state) { currentState, update in
                update(currentState)
            }
        }
    }
    
    /// Gets the current state.
    public func currentState() async -> State {
        await processBatch() // Ensure pending updates are applied
        return await container.state
    }
}

// MARK: - Memory-Efficient State Storage

/// A memory-efficient storage for states with large collections.
public struct CompactStateStorage<State: ImmutableState> {
    private var storage: COWContainer<State>
    private let compressionThreshold: Int
    
    public init(state: State, compressionThreshold: Int = 1000) {
        self.storage = COWContainer(state)
        self.compressionThreshold = compressionThreshold
    }
    
    public var state: State {
        storage.value
    }
    
    /// Updates the state with automatic memory optimization.
    public mutating func update(_ transform: (State) -> State) -> State {
        let newState = storage.withMutation { currentState in
            transform(currentState)
        }
        return newState
    }
}

// MARK: - Immutable State Macros (Future)

// Note: When Swift macros are more mature, we can add:
// @ImmutableState - Automatically generates immutable update methods
// @COW - Adds copy-on-write optimization to large state types
// @StateValidation - Adds automatic validation after mutations
// @BatchUpdate - Generates efficient batch update methods