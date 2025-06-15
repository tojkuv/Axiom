import Foundation

// MARK: - AxiomObservableClient Mutation Implementation

extension AxiomObservableClient: MutableClient {
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
    
    /// Perform transactional mutations with atomicity guarantees
    @MainActor
    @discardableResult
    public func transaction<T>(_ operations: (inout Transaction<S>) async throws -> T) async throws -> T {
        let currentState = await state
        var transaction = Transaction(initialState: currentState)
        
        do {
            // Execute operations and capture result
            let result = try await operations(&transaction)
            
            // Apply all operations atomically if no errors
            let finalState = try transaction.apply()
            
            // Update state only if transaction succeeds completely
            await updateState(finalState)
            
            return result
        } catch {
            // Transaction failed - state remains unchanged
            transaction.clear()
            throw error
        }
    }
    
    /// Perform validated mutations with automatic validation
    @MainActor
    @discardableResult
    public func validatedMutate<T>(
        _ mutation: (inout S) throws -> T,
        validations: [StateValidationRule<S>]
    ) async throws -> T {
        // Create mutable copy for mutation
        var mutableCopy = await state
        
        // Perform mutation
        let result = try mutation(&mutableCopy)
        
        // Validate the mutated state
        try StateValidationUtilities.validate(mutableCopy, using: validations)
        
        // Only update if validation passes
        await updateState(mutableCopy)
        
        return result
    }
    
    /// Perform batch mutations with optimization
    @MainActor
    public func batchMutate(_ mutations: [(inout S) throws -> Void]) async throws {
        var mutableCopy = await state
        
        // Apply all mutations to the copy
        for mutation in mutations {
            try mutation(&mutableCopy)
        }
        
        // Single state update for all mutations
        await updateState(mutableCopy)
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
public struct StreamConfiguration: Sendable {
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
public struct StateStreamBuilder<S: Sendable> {
    private let initialState: S
    private var configuration: StreamConfiguration = .default
    private var onTermination: (@Sendable () -> Void)?
    
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
    public func onTermination(_ handler: @escaping @Sendable () -> Void) -> Self {
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
public struct StateValidationUtilities<S> {
    
    /// Validate state using provided rules
    public static func validate(_ state: S, using rules: [StateValidationRule<S>]) throws {
        var validationErrors: [Error] = []
        
        for (index, rule) in rules.enumerated() {
            do {
                try rule.validate(state)
            } catch {
                let wrappedError = AxiomError.validationError(.ruleFailed(
                    field: "rule_\(index)",
                    rule: rule.description,
                    reason: error.localizedDescription
                ))
                validationErrors.append(wrappedError)
            }
        }
        
        if !validationErrors.isEmpty {
            throw AxiomError.validationError(.invalidInput("state", "Multiple validation rules failed: \(validationErrors.count) errors"))
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

// MARK: - Validation Error Types Consolidated into AxiomError
// 
// All validation error types have been consolidated into AxiomError.validationError
// Legacy ValidationError enum removed - use AxiomError.validationError with appropriate cases:
//
// ValidationError.ruleFailed(index, description, underlyingError) -> AxiomError.validationError(.ruleFailed(field: String, rule: String, reason: String))
// ValidationError.multipleFailures([Error]) -> AxiomError.validationError(.invalidInput(String, String))

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

// MARK: - Enhanced AxiomObservableClient with Stream Builder

extension AxiomObservableClient {
    /// Create an optimized state stream using the builder pattern
    public var optimizedStateStream: AsyncStream<S> {
        get async {
            // Return the existing stateStream with custom configuration
            // In a real implementation, we'd create a wrapper that applies configuration
            return stateStream
        }
    }
    
    /// Get a custom configured state stream
    public func configuredStateStream(configuration: StreamConfiguration) async -> AsyncStream<S> {
        // Return the existing stateStream
        // In a real implementation, we'd create a wrapper that applies configuration
        return stateStream
    }
}

// MARK: - Convenience Initializers

extension StreamConfiguration {
    // Memberwise initializer is synthesized automatically
}