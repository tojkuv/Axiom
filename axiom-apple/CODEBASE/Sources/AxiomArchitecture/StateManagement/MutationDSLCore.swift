import Foundation
import AxiomCore

// MARK: - Mutation DSL

/// Enhanced protocol for types that support advanced mutation DSL (REQUIREMENTS-W-01-003)
public protocol MutableClient: AxiomClient {
    /// Perform a state mutation with automatic immutability preservation
    @MainActor
    @discardableResult
    func mutate<T>(_ mutation: (inout StateType) throws -> T) async rethrows -> T
    
    /// Perform an async state mutation with automatic immutability preservation
    @MainActor
    @discardableResult
    func mutateAsync<T>(_ mutation: (inout StateType) async throws -> T) async rethrows -> T
    
    /// Perform transactional mutations with atomicity guarantees
    @MainActor
    @discardableResult
    func transaction<T>(_ operations: (inout Transaction<StateType>) async throws -> T) async throws -> T
    
    /// Perform validated mutations with automatic validation
    @MainActor
    @discardableResult
    func validatedMutate<T>(
        _ mutation: (inout StateType) throws -> T,
        validations: [StateValidationRule<StateType>]
    ) async throws -> T
    
    /// Perform batch mutations with optimization
    @MainActor
    func batchMutate(_ mutations: [(inout StateType) throws -> Void]) async throws
}

/// Extension to AxiomClient protocol providing mutation DSL for simplified state updates
extension AxiomClient {
    /// Perform a state mutation with automatic immutability preservation.
    /// 
    /// This method provides a mutable-style syntax while maintaining immutable semantics.
    /// The state is copied before mutation, and the modified copy replaces the current state.
    ///
    /// Example:
    /// ```swift
    /// await client.mutate { state in
    ///     state.items.append("new item")
    ///     state.count += 1
    /// }
    /// ```
    ///
    /// - Parameter mutation: A closure that mutates a copy of the current state
    /// - Returns: The result of the mutation closure
    @MainActor
    @discardableResult
    public func mutate<T>(_ mutation: (inout StateType) throws -> T) async throws -> T {
        // This will be implemented by conforming types
        throw AxiomError.contextError(.initializationFailed("mutate must be implemented by conforming types"))
    }
    
    /// Perform an async state mutation with automatic immutability preservation.
    /// 
    /// Similar to `mutate` but supports async operations within the mutation closure.
    ///
    /// Example:
    /// ```swift
    /// let result = await client.mutateAsync { state in
    ///     let data = try await fetchData()
    ///     state.items = data
    ///     return data.count
    /// }
    /// ```
    ///
    /// - Parameter mutation: An async closure that mutates a copy of the current state
    /// - Returns: The result of the mutation closure
    @MainActor
    @discardableResult
    public func mutateAsync<T>(_ mutation: (inout StateType) async throws -> T) async throws -> T {
        // This will be implemented by conforming types
        throw AxiomError.contextError(.initializationFailed("mutateAsync must be implemented by conforming types"))
    }
}

// MARK: - Transaction Support (REQUIREMENTS-W-01-003)

/// Transaction for atomic multi-step mutations
public struct Transaction<S: AxiomState> {
    private var pendingOperations: [AnyOperation] = []
    private let initialState: S
    
    /// Type-erased operation container
    private struct AnyOperation {
        let apply: (inout S) throws -> Void
    }
    
    public init(initialState: S) {
        self.initialState = initialState
    }
    
    /// Update a property to a specific value
    public mutating func update<T>(_ keyPath: WritableKeyPath<S, T>, to value: T) {
        let operation = AnyOperation { state in
            state[keyPath: keyPath] = value
        }
        pendingOperations.append(operation)
    }
    
    /// Transform a property using a closure
    public mutating func transform<T>(_ keyPath: WritableKeyPath<S, T>, using transform: @escaping (T) -> T) {
        let operation = AnyOperation { state in
            state[keyPath: keyPath] = transform(state[keyPath: keyPath])
        }
        pendingOperations.append(operation)
    }
    
    /// Add conditional operation
    public mutating func updateIf<T>(
        _ condition: @escaping (S) -> Bool,
        _ keyPath: WritableKeyPath<S, T>,
        to value: T
    ) {
        let operation = AnyOperation { state in
            if condition(state) {
                state[keyPath: keyPath] = value
            }
        }
        pendingOperations.append(operation)
    }
    
    /// Transform conditionally
    public mutating func transformIf<T>(
        _ condition: @escaping (S) -> Bool,
        _ keyPath: WritableKeyPath<S, T>,
        using transform: @escaping (T) -> T
    ) {
        let operation = AnyOperation { state in
            if condition(state) {
                state[keyPath: keyPath] = transform(state[keyPath: keyPath])
            }
        }
        pendingOperations.append(operation)
    }
    
    /// Add validation step
    public mutating func validate(_ validation: @escaping (S) throws -> Void) {
        let operation = AnyOperation { state in
            try validation(state)
        }
        pendingOperations.append(operation)
    }
    
    /// Apply all operations to create final state
    internal func apply() throws -> S {
        var state = initialState
        
        // Apply operations atomically
        for operation in pendingOperations {
            try operation.apply(&state)
        }
        
        return state
    }
    
    /// Get the number of pending operations
    public var operationCount: Int {
        return pendingOperations.count
    }
    
    /// Clear all pending operations (for rollback)
    public mutating func clear() {
        pendingOperations.removeAll()
    }
}

// MARK: - Enhanced Collection Extensions (REQUIREMENTS-W-01-003)

extension Array where Element: Identifiable {
    /// Update element by ID, returning success status
    @discardableResult
    public mutating func update(id: Element.ID, _ transform: (inout Element) -> Void) -> Bool {
        guard let index = firstIndex(where: { $0.id == id }) else {
            return false
        }
        transform(&self[index])
        return true
    }
    
    /// Insert or update element (upsert)
    @discardableResult
    public mutating func upsert(_ element: Element) -> Element {
        if let index = firstIndex(where: { $0.id == element.id }) {
            self[index] = element
        } else {
            append(element)
        }
        return element
    }
    
    /// Remove all elements with specified IDs
    public mutating func removeAll(ids: Set<Element.ID>) {
        removeAll { ids.contains($0.id) }
    }
}

extension Dictionary {
    /// Update value with default, applying transform
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
    
    /// Merge with another dictionary using combining function
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

// MARK: - Property Mutation Extensions

extension String {
    /// Append a suffix to the string
    public mutating func append(_ suffix: String) {
        self += suffix
    }
    
    /// Prepend a prefix to the string
    public mutating func prepend(_ prefix: String) {
        self = prefix + self
    }
    
    /// Replace all occurrences of a substring
    public mutating func replaceAll(_ target: String, with replacement: String) {
        self = self.replacingOccurrences(of: target, with: replacement)
    }
}

extension Int {
    /// Increment by amount
    public mutating func increment(by amount: Int = 1) {
        self += amount
    }
    
    /// Decrement by amount
    public mutating func decrement(by amount: Int = 1) {
        self -= amount
    }
    
    /// Multiply by factor
    public mutating func multiply(by factor: Int) {
        self *= factor
    }
}

extension Bool {
    /// Toggle the boolean value
    public mutating func toggle() {
        self = !self
    }
}

// MARK: - Enhanced Array Mutation Extensions

extension Array {
    /// Remove first element matching predicate
    @discardableResult
    public mutating func removeFirst(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        guard let index = try firstIndex(where: predicate) else { return nil }
        return remove(at: index)
    }
    
    /// Remove last element matching predicate
    @discardableResult
    public mutating func removeLast(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        guard let index = try lastIndex(where: predicate) else { return nil }
        return remove(at: index)
    }
    
    /// Move element from one index to another
    public mutating func move(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              indices.contains(sourceIndex),
              indices.contains(destinationIndex) else { return }
        
        let element = remove(at: sourceIndex)
        insert(element, at: destinationIndex)
    }
    
    /// Swap elements at two indices
    public mutating func swap(at i: Int, _ j: Int) {
        guard i != j,
              indices.contains(i),
              indices.contains(j) else { return }
        
        swapAt(i, j)
    }
}

extension Array where Element: Equatable & Hashable {
    /// Remove all duplicate elements, keeping first occurrence
    public mutating func removeDuplicates() {
        var seen = Set<Element>()
        self = filter { element in
            if seen.contains(element) {
                return false
            } else {
                seen.insert(element)
                return true
            }
        }
    }
}

// MARK: - Set Mutation Extensions

extension Set {
    /// Toggle membership of an element
    @discardableResult
    public mutating func toggle(_ member: Element) -> Bool {
        if contains(member) {
            remove(member)
            return false
        } else {
            insert(member)
            return true
        }
    }
    
    /// Insert multiple elements
    public mutating func insert<S: Sequence>(contentsOf sequence: S) where S.Element == Element {
        for element in sequence {
            insert(element)
        }
    }
}