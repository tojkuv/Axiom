import Foundation

// MARK: - Client Protocol

/// Core protocol for actor-based state containers with action processing.
/// 
/// Clients are the primary state management components in Axiom.
/// They own state, process actions, and stream state updates.
/// 
/// Requirements:
/// - Must be actor-based for thread safety
/// - Provides async stream of state updates
/// - Processes actions to produce new state
/// - State updates must be delivered within 5ms
public protocol Client<StateType, ActionType>: Actor {
    /// The type of state managed by this client
    associatedtype StateType: State
    
    /// The type of actions processed by this client
    associatedtype ActionType
    
    /// Stream of state updates for observation
    /// Must emit initial state upon subscription
    var stateStream: AsyncStream<StateType> { get }
    
    /// Process an action and update state accordingly
    /// - Parameter action: The action to process
    /// - Throws: If action processing fails
    func process(_ action: ActionType) async throws
    
    /// Called before state is updated (REQUIREMENTS-W-01-002 lifecycle hooks)
    /// - Parameters:
    ///   - old: The current state before update
    ///   - new: The new state that will be set
    func stateWillUpdate(from old: StateType, to new: StateType) async
    
    /// Called after state has been updated (REQUIREMENTS-W-01-002 lifecycle hooks)
    /// - Parameters:
    ///   - old: The previous state before update
    ///   - new: The current state after update
    func stateDidUpdate(from old: StateType, to new: StateType) async
}

// MARK: - Client Extensions

extension Client {
    /// Default implementation of stateWillUpdate - does nothing
    public func stateWillUpdate(from old: StateType, to new: StateType) async {
        // Default implementation - no action required
    }
    
    /// Default implementation of stateDidUpdate - does nothing
    public func stateDidUpdate(from old: StateType, to new: StateType) async {
        // Default implementation - no action required
    }
    /// Default timeout for state propagation (5ms)
    public static var statePropagationTimeout: Duration {
        .milliseconds(5)
    }
    
    /// Process multiple actions in sequence
    public func process<S: Sequence>(_ actions: S) async throws where S.Element == ActionType {
        for action in actions {
            try await process(action)
        }
    }
    
    /// Process actions with timeout
    public func process(_ action: ActionType, timeout: Duration) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.process(action)
            }
            
            group.addTask {
                try await Task.sleep(for: timeout)
                throw AxiomError.clientError(.timeout(duration: Double(timeout.components.seconds)))
            }
            
            try await group.next()
            group.cancelAll()
        }
    }
}

// MARK: - Client Error Types Consolidated into AxiomError
// 
// All client error types have been consolidated into AxiomError.clientError
// Legacy ClientError enum removed - use AxiomError.clientError with appropriate cases:
//
// ClientError.timeout -> AxiomError.clientError(.timeout(duration: Double))
// ClientError.notInitialized -> AxiomError.clientError(.notInitialized)
// ClientError.invalidAction(String) -> AxiomError.clientError(.invalidAction(String))

// MARK: - Observable Client Implementation

/// Observable actor implementation providing common client behaviors
/// 
/// This actor provides:
/// - State management with automatic streaming
/// - Thread-safe state mutations
/// - Performance guarantees for state propagation
public actor ObservableClient<S: State, A>: Client where S: Equatable {
    public typealias StateType = S
    public typealias ActionType = A
    /// Current state of the client
    public private(set) var state: S
    
    /// Continuation for state stream
    private var streamContinuations: [UUID: AsyncStream<S>.Continuation] = [:]
    
    /// Initialize with initial state
    public init(initialState: S) {
        self.state = initialState
    }
    
    /// Create a new state stream
    public var stateStream: AsyncStream<S> {
        AsyncStream { [weak self] continuation in
            let id = UUID()
            Task { [weak self] in
                await self?.addContinuation(continuation, id: id)
                
                // Yield initial state
                if let currentState = await self?.state {
                    continuation.yield(currentState)
                }
                
                // Clean up on termination
                continuation.onTermination = { @Sendable _ in
                    Task { @Sendable [weak self, id] in
                        await self?.removeContinuation(id: id)
                    }
                }
            }
        }
    }
    
    private func addContinuation(_ continuation: AsyncStream<S>.Continuation, id: UUID) {
        streamContinuations[id] = continuation
    }
    
    private func removeContinuation(id: UUID) {
        streamContinuations.removeValue(forKey: id)
    }
    
    /// Update state and notify all observers
    public func updateState(_ newState: S) {
        guard state != newState else { return }
        state = newState
        
        // Notify all active continuations
        for (_, continuation) in streamContinuations {
            continuation.yield(newState)
        }
    }
    
    /// Terminate all state streams
    public func terminateStreams() {
        for (_, continuation) in streamContinuations {
            continuation.finish()
        }
        streamContinuations.removeAll()
    }
    
    /// Process an action - base implementation does nothing
    /// Override in subclasses to handle specific actions
    public func process(_ action: A) async throws {
        // Base implementation - subclasses should override
    }
}

// MARK: - Client Manager Protocol

/// Protocol for managing multiple clients
public protocol ClientManager: Actor {
    /// Register a client with the manager
    func register<C: Client>(_ client: C, for key: String) async
    
    /// Retrieve a registered client
    func client<C: Client>(for key: String, as type: C.Type) async -> C?
    
    /// Process an action on a specific client
    func processAction<C: Client>(
        for key: String,
        clientType: C.Type,
        action: C.ActionType
    ) async throws
}

// MARK: - Client Helpers

/// Helper to create type-safe client identifiers
public struct ClientIdentifier<C: Client>: Hashable, Sendable {
    public let key: String
    
    public init(_ key: String) {
        self.key = key
    }
}

/// Helper to batch multiple actions for atomic processing
public struct ActionBatch<Action> {
    public let actions: [Action]
    public let isAtomicExecution: Bool
    
    public init(actions: [Action], atomic: Bool = false) {
        self.actions = actions
        self.isAtomicExecution = atomic
    }
}

// MARK: - Performance Monitoring

/// Protocol for monitoring client performance
public protocol ClientPerformanceMonitor: Actor {
    /// Record state update timing
    func recordStateUpdate(clientId: String, duration: Duration) async
    
    /// Record action processing timing
    func recordActionProcessing(clientId: String, duration: Duration) async
    
    /// Get performance metrics for a client
    func metrics(for clientId: String) async -> ClientPerformanceMetrics?
}

/// Performance metrics for a client
// MARK: - Duration Extensions

extension Duration {
    /// Zero duration
    public static var zero: Duration {
        .seconds(0)
    }
}

public struct ClientPerformanceMetrics: Sendable {
    public let averageStateUpdateTime: Duration
    public let averageActionProcessingTime: Duration
    public let totalStateUpdates: Int
    public let totalActionsProcessed: Int
    public let maxStateUpdateTime: Duration
    public let minStateUpdateTime: Duration
    
    public init(
        averageStateUpdateTime: Duration,
        averageActionProcessingTime: Duration,
        totalStateUpdates: Int,
        totalActionsProcessed: Int,
        maxStateUpdateTime: Duration = .zero,
        minStateUpdateTime: Duration = .seconds(999)
    ) {
        self.averageStateUpdateTime = averageStateUpdateTime
        self.averageActionProcessingTime = averageActionProcessingTime
        self.totalStateUpdates = totalStateUpdates
        self.totalActionsProcessed = totalActionsProcessed
        self.maxStateUpdateTime = maxStateUpdateTime
        self.minStateUpdateTime = minStateUpdateTime
    }
}

// MARK: - AsyncStream Optimizations

extension AsyncStream where Element: Sendable {
    /// Create a multicast async stream that properly handles multiple observers
    public static func multicast(
        bufferingPolicy: Continuation.BufferingPolicy = .unbounded,
        _ build: @escaping (MulticastContinuation<Element>) -> Void
    ) -> AsyncStream<Element> {
        let multicast = MulticastContinuation<Element>()
        build(multicast)
        return multicast.stream
    }
}

/// A continuation that supports multiple observers
public final class MulticastContinuation<Element: Sendable>: @unchecked Sendable {
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]
    private let lock = NSLock()
    
    public var stream: AsyncStream<Element> {
        AsyncStream { continuation in
            let id = UUID()
            lock.lock()
            continuations[id] = continuation
            lock.unlock()
            
            continuation.onTermination = { [weak self] _ in
                self?.lock.lock()
                self?.continuations.removeValue(forKey: id)
                self?.lock.unlock()
            }
        }
    }
    
    public func yield(_ value: Element) {
        lock.lock()
        let currentContinuations = continuations
        lock.unlock()
        
        for (_, continuation) in currentContinuations {
            continuation.yield(value)
        }
    }
    
    public func finish() {
        lock.lock()
        let currentContinuations = continuations
        continuations.removeAll()
        lock.unlock()
        
        for (_, continuation) in currentContinuations {
            continuation.finish()
        }
    }
}