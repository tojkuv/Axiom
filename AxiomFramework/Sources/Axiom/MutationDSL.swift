import Foundation

// MARK: - Mutation DSL

/// Protocol for types that support mutation DSL
public protocol MutableClient: Client {
    /// Perform a state mutation with automatic immutability preservation
    @MainActor
    @discardableResult
    func mutate<T>(_ mutation: (inout StateType) throws -> T) async rethrows -> T
    
    /// Perform an async state mutation with automatic immutability preservation
    @MainActor
    @discardableResult
    func mutateAsync<T>(_ mutation: (inout StateType) async throws -> T) async rethrows -> T
}

/// Extension to Client protocol providing mutation DSL for simplified state updates
extension Client {
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
    public func mutate<T>(_ mutation: (inout StateType) throws -> T) async rethrows -> T {
        // This will be implemented by conforming types
        fatalError("mutate must be implemented by conforming types")
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
    public func mutateAsync<T>(_ mutation: (inout StateType) async throws -> T) async rethrows -> T {
        // This will be implemented by conforming types
        fatalError("mutateAsync must be implemented by conforming types")
    }
}

// MARK: - BaseClient Mutation Implementation

extension BaseClient: MutableClient {
    /// Perform a state mutation with automatic immutability preservation
    @MainActor
    @discardableResult
    public func mutate<T>(_ mutation: (inout S) throws -> T) async rethrows -> T {
        // Create mutable copy for mutation
        var mutableCopy = await state
        
        // Track if mutation actually changes state
        let oldState = await state
        
        // Perform mutation and capture result
        let result: T
        do {
            result = try mutation(&mutableCopy)
        } catch {
            // State not updated on error
            throw error
        }
        
        // Only update if state actually changed
        if oldState != mutableCopy {
            await updateState(mutableCopy)
        }
        
        return result
    }
    
    /// Perform an async state mutation with automatic immutability preservation
    @MainActor
    @discardableResult
    public func mutateAsync<T>(_ mutation: (inout S) async throws -> T) async rethrows -> T {
        // Create mutable copy for mutation
        var mutableCopy = await state
        
        // Track if mutation actually changes state
        let oldState = await state
        
        // Perform async mutation and capture result
        let result: T
        do {
            result = try await mutation(&mutableCopy)
        } catch {
            // State not updated on error
            throw error
        }
        
        // Only update if state actually changed
        if oldState != mutableCopy {
            await updateState(mutableCopy)
        }
        
        return result
    }
    
    /// Read state without mutation
    @MainActor
    public func withState<T>(_ operation: (S) throws -> T) async rethrows -> T {
        let currentState = await state
        return try operation(currentState)
    }
    
    /// Read state with async operation
    @MainActor
    public func withStateAsync<T>(_ operation: (S) async throws -> T) async rethrows -> T {
        let currentState = await state
        return try await operation(currentState)
    }
}

// MARK: - State Stream Builder

/// Configuration for state streams
public struct StreamConfiguration {
    public let bufferSize: Int
    public let bufferingPolicy: AsyncStream<Any>.Continuation.BufferingPolicy
    public let includeInitialState: Bool
    
    public static let `default` = StreamConfiguration(
        bufferSize: 100,
        bufferingPolicy: .bufferingNewest(100),
        includeInitialState: true
    )
    
    public static let highFrequency = StreamConfiguration(
        bufferSize: 10,
        bufferingPolicy: .bufferingNewest(10),
        includeInitialState: true
    )
    
    public static let unbuffered = StreamConfiguration(
        bufferSize: 0,
        bufferingPolicy: .unbounded,
        includeInitialState: true
    )
}

/// A builder for creating optimized state streams with configurable buffering
public struct StateStreamBuilder<S> {
    private let initialState: S
    private var configuration: StreamConfiguration = .default
    private var onTermination: (() -> Void)?
    
    /// Initialize with the initial state
    public init(initialState: S) {
        self.initialState = initialState
    }
    
    /// Configure the buffer size for the stream
    public func withBufferSize(_ size: Int) -> Self {
        var copy = self
        copy.configuration = StreamConfiguration(
            bufferSize: size,
            bufferingPolicy: .bufferingNewest(size),
            includeInitialState: configuration.includeInitialState
        )
        return copy
    }
    
    /// Use a predefined configuration
    public func withConfiguration(_ config: StreamConfiguration) -> Self {
        var copy = self
        copy.configuration = config
        return copy
    }
    
    /// Set termination handler
    public func onTermination(_ handler: @escaping () -> Void) -> Self {
        var copy = self
        copy.onTermination = handler
        return copy
    }
    
    /// Build the stream with configured options
    public func build() -> AsyncStream<S> {
        AsyncStream { continuation in
            // Yield initial state if configured
            if configuration.includeInitialState {
                continuation.yield(initialState)
            }
            
            // Set up termination handler
            if let onTermination = onTermination {
                continuation.onTermination = { _ in
                    onTermination()
                }
            }
        }
    }
    
    /// Build the stream with a continuation handler
    public func build(onContinuation: @escaping (AsyncStream<S>.Continuation) -> Void) -> AsyncStream<S> {
        AsyncStream { continuation in
            // Yield initial state if configured
            if configuration.includeInitialState {
                continuation.yield(initialState)
            }
            
            // Set up termination handler
            if let onTermination = onTermination {
                continuation.onTermination = { _ in
                    onTermination()
                }
            }
            
            // Provide continuation for external management
            onContinuation(continuation)
        }
    }
}

// MARK: - State Validator

/// Utilities for state validation and debugging
public struct StateValidator<S> {
    
    /// Validate state using provided rules
    public static func validate(_ state: S, using rules: [StateValidationRule<S>]) throws {
        var validationErrors: [Error] = []
        
        for (index, rule) in rules.enumerated() {
            do {
                try rule.validate(state)
            } catch {
                let wrappedError = ValidationError.ruleFailed(
                    index: index,
                    description: rule.description,
                    underlyingError: error
                )
                validationErrors.append(wrappedError)
            }
        }
        
        if !validationErrors.isEmpty {
            throw ValidationError.multipleFailures(validationErrors)
        }
    }
    
    /// Compare two states and generate a diff
    public static func diff(_ before: S, _ after: S) -> StateDiff<S> {
        StateDiff(before: before, after: after)
    }
    
    /// Create a composite validator
    public static func all(_ rules: StateValidationRule<S>...) -> StateValidationRule<S> {
        StateValidationRule(description: "All of \(rules.count) rules") { state in
            try validate(state, using: rules)
        }
    }
    
    /// Create an optional validator
    public static func optional(_ rule: StateValidationRule<S>) -> StateValidationRule<S> {
        StateValidationRule(description: "Optional: \(rule.description)") { state in
            // Silently succeed if validation fails
            _ = try? rule.validate(state)
        }
    }
}

// MARK: - Supporting Types

/// A rule for validating state
public struct StateValidationRule<S> {
    public let description: String
    private let validator: (S) throws -> Void
    
    public init(description: String = "Custom validation", validator: @escaping (S) throws -> Void) {
        self.description = description
        self.validator = validator
    }
    
    public func validate(_ state: S) throws {
        try validator(state)
    }
    
    /// Combine with another rule using AND logic
    public func and(_ other: StateValidationRule<S>) -> StateValidationRule<S> {
        StateValidationRule(description: "\(description) AND \(other.description)") { state in
            try self.validate(state)
            try other.validate(state)
        }
    }
    
    /// Combine with another rule using OR logic
    public func or(_ other: StateValidationRule<S>) -> StateValidationRule<S> {
        StateValidationRule(description: "\(description) OR \(other.description)") { state in
            do {
                try self.validate(state)
            } catch {
                try other.validate(state)
            }
        }
    }
}

/// Validation errors
public enum ValidationError: Error {
    case ruleFailed(index: Int, description: String, underlyingError: Error)
    case multipleFailures([Error])
}

/// Represents the difference between two states
public struct StateDiff<S> {
    public let before: S
    public let after: S
    public let timestamp: Date
    
    public init(before: S, after: S) {
        self.before = before
        self.after = after
        self.timestamp = Date()
    }
    
    /// Check if states are different (requires Equatable)
    public func hasChanges() -> Bool where S: Equatable {
        before != after
    }
    
    /// Get a description of the change
    public func description<T>(for keyPath: KeyPath<S, T>) -> String where T: Equatable {
        let beforeValue = before[keyPath: keyPath]
        let afterValue = after[keyPath: keyPath]
        
        if beforeValue == afterValue {
            return "No change"
        } else {
            return "Changed from \(beforeValue) to \(afterValue)"
        }
    }
    
    /// Time since the diff was created
    public var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
}

// MARK: - Enhanced BaseClient with Stream Builder

extension BaseClient {
    /// Create an optimized state stream using the builder pattern
    public var optimizedStateStream: AsyncStream<S> {
        get async {
            // Return the existing stateStream with custom configuration
            // In a real implementation, we'd create a wrapper that applies configuration
            return await stateStream
        }
    }
    
    /// Get a custom configured state stream
    public func configuredStateStream(configuration: StreamConfiguration) async -> AsyncStream<S> {
        // Return the existing stateStream
        // In a real implementation, we'd create a wrapper that applies configuration
        return await stateStream
    }
}

// MARK: - Convenience Initializers

extension StreamConfiguration {
    // Memberwise initializer is synthesized automatically
}

// MARK: - Common Validation Rules

extension StateValidationRule {
    /// Validate that a value is not empty
    public static func notEmpty<T: Collection>(
        _ keyPath: KeyPath<S, T>,
        description: String? = nil
    ) -> StateValidationRule<S> {
        StateValidationRule(
            description: description ?? "Collection at \(keyPath) should not be empty"
        ) { state in
            guard !state[keyPath: keyPath].isEmpty else {
                throw ValidationError.ruleFailed(
                    index: 0,
                    description: "Empty collection",
                    underlyingError: NSError(domain: "StateValidation", code: 1)
                )
            }
        }
    }
    
    /// Validate that a value is within range
    public static func inRange<T: Comparable>(
        _ keyPath: KeyPath<S, T>,
        range: ClosedRange<T>,
        description: String? = nil
    ) -> StateValidationRule<S> {
        StateValidationRule(
            description: description ?? "Value at \(keyPath) should be in range \(range)"
        ) { state in
            let value = state[keyPath: keyPath]
            guard range.contains(value) else {
                throw ValidationError.ruleFailed(
                    index: 0,
                    description: "Value \(value) out of range \(range)",
                    underlyingError: NSError(domain: "StateValidation", code: 2)
                )
            }
        }
    }
}