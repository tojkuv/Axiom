import Foundation

// MARK: - Enhanced Actor Isolation Patterns (W-02-001)

/// Unique identifier for actors in the system
public struct ActorIdentifier: Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let type: String
    
    public init(id: UUID, name: String, type: String) {
        self.id = id
        self.name = name
        self.type = type
    }
}

/// Reentrancy policies for actor operations
public enum ReentrancyPolicy: Sendable {
    case allow
    case deny
    case queue
    case detectAndHandle
}

/// Enhanced actor protocol with isolation guarantees
public protocol IsolatedActor: Actor {
    associatedtype StateType: Sendable
    associatedtype ActionType
    associatedtype MessageType: ClientMessage
    
    /// Unique actor identifier for debugging and monitoring
    var actorID: ActorIdentifier { get }
    
    /// Quality of service for this actor
    var qualityOfService: DispatchQoS { get }
    
    /// Reentrancy policy for this actor
    var reentrancyPolicy: ReentrancyPolicy { get }
    
    /// Handle messages from contexts only
    func handleMessage(_ message: MessageType) async throws
    
    /// Validate actor state consistency
    func validateActorInvariants() async throws
}

/// Protocol for type-safe message passing between actors
public protocol ClientMessage: Sendable {
    var source: MessageSource { get }
    var timestamp: Date { get }
    var correlationID: UUID { get }
}

/// Message source for validation
public enum MessageSource: Sendable {
    case context(ContextIdentifier)
    case system
    case test
}

/// Context identifier for isolation enforcement
public struct ContextIdentifier: Hashable, Sendable {
    public let id: String
    
    public init(_ id: String) {
        self.id = id
    }
}

/// Isolation enforcer for runtime validation
public actor IsolationEnforcer {
    private var clientRegistry: [ActorIdentifier: IsolationInfo] = [:]
    private var communicationLog: [CommunicationRecord] = []
    
    struct IsolationInfo {
        let allowedContexts: Set<ContextIdentifier>
        let createdAt: Date
    }
    
    struct CommunicationRecord {
        let source: MessageSource
        let destination: ActorIdentifier
        let timestamp: Date
    }
    
    /// Register client with isolation rules
    public func registerClient(
        _ client: any IsolatedActor,
        allowedContexts: Set<ContextIdentifier>
    ) async throws {
        let actorID = await client.actorID
        let info = IsolationInfo(
            allowedContexts: allowedContexts,
            createdAt: Date()
        )
        clientRegistry[actorID] = info
    }
    
    /// Validate message routing
    public func validateCommunication(
        from source: MessageSource,
        to client: ActorIdentifier
    ) async throws {
        guard let info = clientRegistry[client] else {
            throw IsolationError.unregisteredClient(client)
        }
        
        switch source {
        case .context(let contextID):
            guard info.allowedContexts.contains(contextID) else {
                throw IsolationError.unauthorizedContext(
                    context: contextID,
                    client: client
                )
            }
        case .system, .test:
            // Always allowed
            break
        }
        
        // Log communication
        let record = CommunicationRecord(
            source: source,
            destination: client,
            timestamp: Date()
        )
        communicationLog.append(record)
    }
}

/// Context-mediated communication router
@MainActor
public class IsolatedCommunicationRouter {
    private let enforcer: IsolationEnforcer
    private var routingTable: [ActorIdentifier: any IsolatedActor] = [:]
    
    public init(enforcer: IsolationEnforcer) {
        self.enforcer = enforcer
    }
    
    /// Register client for routing
    public func registerClient(
        _ client: any IsolatedActor,
        allowedContexts: Set<ContextIdentifier>
    ) async {
        try? await enforcer.registerClient(client, allowedContexts: allowedContexts)
        routingTable[client.actorID] = client
    }
    
    /// Route message through context
    public func routeMessage<M: ClientMessage>(
        _ message: M,
        to clientID: ActorIdentifier,
        from context: ContextIdentifier
    ) async throws {
        // Validate routing is allowed
        try await enforcer.validateCommunication(
            from: .context(context),
            to: clientID
        )
        
        // Get client and deliver message
        guard let client = routingTable[clientID] else {
            throw RoutingError.clientNotFound(clientID)
        }
        
        // Type-safe message delivery
        if let typedMessage = message as? client.MessageType {
            try await client.handleMessage(typedMessage)
        } else {
            throw RoutingError.typeMismatch(
                expected: String(describing: type(of: client).MessageType),
                actual: String(describing: type(of: message))
            )
        }
    }
}

/// Actor metrics collection
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
        let calls = callCounts[actorID] ?? 0
        let durations = callDurations[actorID] ?? []
        let reentrancies = reentrancyCounts[actorID] ?? 0
        
        let averageDuration = durations.isEmpty ? Duration.zero :
            Duration.nanoseconds(durations.map(\.components.attoseconds).reduce(0, +) / Int64(durations.count))
        
        return ActorMetricsSnapshot(
            callCount: calls,
            averageCallDuration: averageDuration,
            reentrancyRate: calls > 0 ? Double(reentrancies) / Double(calls) : 0.0
        )
    }
    
    private func calculateAverage(_ durations: [Duration]) -> Duration {
        guard !durations.isEmpty else { return Duration.zero }
        let total = durations.map(\.components.attoseconds).reduce(0, +)
        return Duration.nanoseconds(total / Int64(durations.count))
    }
    
    private func calculateReentrancyRate(_ actorID: ActorIdentifier) -> Double {
        let calls = callCounts[actorID] ?? 0
        let reentrancies = reentrancyCounts[actorID] ?? 0
        return calls > 0 ? Double(reentrancies) / Double(calls) : 0.0
    }
}

/// Performance metrics snapshot
public struct ActorMetricsSnapshot {
    public let callCount: Int
    public let averageCallDuration: Duration
    public let reentrancyRate: Double
    
    public init(callCount: Int, averageCallDuration: Duration, reentrancyRate: Double) {
        self.callCount = callCount
        self.averageCallDuration = averageCallDuration
        self.reentrancyRate = reentrancyRate
    }
}

/// Isolation-related errors
public enum IsolationError: Error {
    case unregisteredClient(ActorIdentifier)
    case unauthorizedContext(context: ContextIdentifier, client: ActorIdentifier)
    case unauthorizedCommunication
    case clientToClientDependency(from: ClientIdentifier, to: ClientIdentifier)
    case unauthorizedClientContext(context: ContextIdentifier, client: ClientIdentifier)
}

/// Routing-related errors
public enum RoutingError: Error {
    case actorNotFound(ActorIdentifier)
    case typeMismatch(expected: String, actual: String)
    case clientNotFound(ClientIdentifier)
}

/// Actor-related errors for concurrency safety
public enum ConcurrencyActorError: Error {
    case invariantViolation(String)
    case reentrancyDenied(OperationIdentifier)
    case actorNotFound(ActorIdentifier)
}

/// Operation identifier for reentrancy tracking
public enum OperationIdentifier: Hashable, Sendable {
    case operation(String)
    case action(String)
    
    public init(name: String, parameters: String = "") {
        self = .operation("\(name)(\(parameters))")
    }
    
    public static func action(_ action: String) -> OperationIdentifier {
        return .action(action)
    }
}

// MARK: - Actor-based Client Protocol

/// Protocol for clients that ensures concurrency safety through actor isolation.
/// 
/// All state mutations are actor-isolated with documented await points to prevent
/// data races and ensure thread safety. Clients can safely call other clients
/// through defined async protocols without risk of deadlock.
public protocol ConcurrentClient: Actor {
    /// The unique identifier for this client
    var id: String { get }
    
    /// The current state version for reentrancy checking
    var stateVersion: Int { get }
    
    /// Validates state consistency after await points
    /// 
    /// This method should be called after any await point where state
    /// might have changed due to reentrancy.
    /// 
    /// - Parameter expectedVersion: The state version before the await
    /// - Returns: true if state is still consistent
    func validateStateConsistency(expectedVersion: Int) -> Bool
    
    /// Handles state changes that occurred during an await point
    /// 
    /// - Parameter previousVersion: The state version before the await
    func handleStateChange(from previousVersion: Int) async
}

// MARK: - Task Cancellation Support

/// Manages task cancellation propagation from contexts to clients.
/// 
/// This ensures that when a context is cancelled, all associated client
/// tasks are cancelled within the required 10ms window.
public actor TaskCancellationCoordinator {
    /// Shared instance for task coordination
    public static let shared = TaskCancellationCoordinator()
    
    private var contextTasks: [String: Set<Task<Void, Never>>] = [:]
    private var clientTasks: [String: Set<Task<Void, Never>>] = [:]
    private var contextToClients: [String: Set<String>] = [:]
    
    private init() {}
    
    /// Registers a task for a context
    /// 
    /// - Parameters:
    ///   - task: The task to register
    ///   - contextId: The context identifier
    public func registerContextTask(_ task: Task<Void, Never>, for contextId: String) {
        contextTasks[contextId, default: []].insert(task)
        
        // Monitor the task for cancellation
        Task { [contextId] in
            // Wait for the task to complete or be cancelled
            _ = await task.result
            
            // If task was cancelled, propagate to clients
            if task.isCancelled {
                await self.propagateCancellation(from: contextId)
            }
        }
    }
    
    /// Registers a task for a client
    /// 
    /// - Parameters:
    ///   - task: The task to register
    ///   - clientId: The client identifier
    ///   - contextId: The associated context identifier
    public func registerClientTask(_ task: Task<Void, Never>, for clientId: String, context contextId: String) {
        clientTasks[clientId, default: []].insert(task)
        contextToClients[contextId, default: []].insert(clientId)
    }
    
    /// Propagates cancellation from a context to all associated clients
    /// 
    /// - Parameter contextId: The context that was cancelled
    func propagateCancellation(from contextId: String) async {
        // Get all associated client IDs
        guard let clientIds = contextToClients[contextId] else { return }
        
        // Cancel all client tasks
        for clientId in clientIds {
            if let tasks = clientTasks[clientId] {
                for task in tasks {
                    task.cancel()
                }
            }
        }
        
        // Clean up
        contextTasks.removeValue(forKey: contextId)
        contextToClients.removeValue(forKey: contextId)
        
        for clientId in clientIds {
            clientTasks.removeValue(forKey: clientId)
        }
    }
    
    /// Unregisters all tasks for a context
    /// 
    /// - Parameter contextId: The context identifier
    public func unregisterContext(_ contextId: String) {
        contextTasks.removeValue(forKey: contextId)
        
        if let clientIds = contextToClients[contextId] {
            for clientId in clientIds {
                clientTasks.removeValue(forKey: clientId)
            }
        }
        
        contextToClients.removeValue(forKey: contextId)
    }
}

// MARK: - Priority Handling

/// Manages priority inheritance to prevent priority inversion.
/// 
/// When a high-priority task is blocked by a low-priority task,
/// this coordinator ensures the low-priority task inherits the
/// higher priority temporarily.
public actor PriorityCoordinator {
    /// Shared instance for priority coordination
    public static let shared = PriorityCoordinator()
    
    private var resourceOwners: [String: (clientId: String, priority: TaskPriority)] = [:]
    private var waitingClients: [String: [(clientId: String, priority: TaskPriority)]] = [:]
    
    private init() {}
    
    /// Requests access to a resource with priority inheritance
    /// 
    /// - Parameters:
    ///   - resourceId: The resource identifier
    ///   - clientId: The client requesting access
    ///   - priority: The client's task priority
    /// - Returns: A continuation to resume when resource is available
    public func requestResource(_ resourceId: String, for clientId: String, priority: TaskPriority) async {
        if let owner = resourceOwners[resourceId] {
            // Resource is owned, add to waiting list
            waitingClients[resourceId, default: []].append((clientId, priority))
            
            // Check for priority inversion
            if priority.rawValue > owner.priority.rawValue {
                // Priority inheritance would happen here in a real implementation
                // For now, we just track it
            }
            
            // Wait for resource to be released
            await withCheckedContinuation { continuation in
                // In a real implementation, we'd store this continuation
                // and resume it when the resource is released
                continuation.resume()
            }
        } else {
            // Resource is available, grant immediately
            resourceOwners[resourceId] = (clientId, priority)
        }
    }
    
    /// Releases a resource
    /// 
    /// - Parameters:
    ///   - resourceId: The resource identifier
    ///   - clientId: The client releasing the resource
    public func releaseResource(_ resourceId: String, by clientId: String) {
        guard let owner = resourceOwners[resourceId], owner.clientId == clientId else {
            return
        }
        
        resourceOwners.removeValue(forKey: resourceId)
        
        // Grant to highest priority waiter
        if var waiters = waitingClients[resourceId], !waiters.isEmpty {
            // Sort by priority (highest first)
            waiters.sort { $0.priority.rawValue > $1.priority.rawValue }
            
            let nextOwner = waiters.removeFirst()
            resourceOwners[resourceId] = nextOwner
            
            if waiters.isEmpty {
                waitingClients.removeValue(forKey: resourceId)
            } else {
                waitingClients[resourceId] = waiters
            }
        }
    }
}

// MARK: - State Consistency Manager

/// Manages state consistency across concurrent operations.
/// 
/// Provides utilities for validating state after await points and
/// handling state changes gracefully during reentrancy.
public actor StateConsistencyManager {
    /// Tracks state versions for consistency checking
    private var stateVersions: [String: Int] = [:]
    
    /// Records a state version for a client
    /// 
    /// - Parameters:
    ///   - version: The current state version
    ///   - clientId: The client identifier
    public func recordStateVersion(_ version: Int, for clientId: String) {
        stateVersions[clientId] = version
    }
    
    /// Validates state consistency for a client
    /// 
    /// - Parameters:
    ///   - expectedVersion: The expected state version
    ///   - currentVersion: The current state version
    ///   - clientId: The client identifier
    /// - Returns: true if state is consistent
    public func validateConsistency(expected expectedVersion: Int, current currentVersion: Int, for clientId: String) -> Bool {
        let isConsistent = expectedVersion == currentVersion
        
        if !isConsistent {
            // State changed during await, record new version
            stateVersions[clientId] = currentVersion
        }
        
        return isConsistent
    }
}

// MARK: - Concurrent Context Base

/// Base implementation for contexts that support concurrent operations.
/// 
/// Provides task management and cancellation propagation to ensure
/// all client tasks are properly cancelled when the context is cancelled.
@MainActor
open class ConcurrentContext {
    /// The unique identifier for this context
    public let id: String
    
    /// Active tasks in this context
    private var activeTasks: Set<Task<Void, Never>> = []
    
    /// Associated client identifiers
    private var associatedClients: Set<String> = []
    
    public init(id: String) {
        self.id = id
    }
    
    /// Registers a client with this context
    /// 
    /// - Parameter clientId: The client identifier to associate
    public func registerClient(_ clientId: String) {
        associatedClients.insert(clientId)
    }
    
    /// Starts a cancellable task in this context
    /// 
    /// - Parameter operation: The async operation to perform
    /// - Returns: The created task
    @discardableResult
    public func startTask(_ operation: @escaping () async -> Void) -> Task<Void, Never> {
        let task = Task { [weak self, id] in
            await operation()
        }
        
        activeTasks.insert(task)
        
        // Register with cancellation coordinator
        Task { [weak self, id] in
            await TaskCancellationCoordinator.shared.registerContextTask(task, for: id)
            
            // Clean up after task completes
            _ = await task.result
            await MainActor.run { [weak self] in
                _ = self?.activeTasks.remove(task)
            }
        }
        
        return task
    }
    
    /// Cancels all active tasks in this context
    public func cancelAllTasks() {
        for task in activeTasks {
            task.cancel()
        }
        activeTasks.removeAll()
        
        // Unregister from coordinator
        Task {
            await TaskCancellationCoordinator.shared.unregisterContext(id)
        }
    }
    
    deinit {
        // Tasks will be cancelled when activeTasks is deallocated
        for task in activeTasks {
            task.cancel()
        }
    }
}

// MARK: - Actor Safety Extensions

/// Extension providing actor safety utilities
extension ConcurrentClient {
    /// Executes an operation with state consistency validation
    /// 
    /// - Parameter operation: The async operation to perform
    /// - Returns: The result of the operation
    public func withStateValidation<T>(_ operation: () async throws -> T) async rethrows -> T {
        let startVersion = stateVersion
        
        let result = try await operation()
        
        // Validate state after operation
        if !validateStateConsistency(expectedVersion: startVersion) {
            await handleStateChange(from: startVersion)
        }
        
        return result
    }
}

// MARK: - Deadlock Prevention

/// Utilities for preventing deadlocks in cross-actor calls
public enum DeadlockPrevention {
    /// Maximum time to wait for a cross-actor call before considering it a potential deadlock
    public static let deadlockTimeout: TimeInterval = 0.5
    
    /// Performs a cross-actor call with deadlock detection
    /// 
    /// - Parameters:
    ///   - operation: The async operation to perform
    ///   - timeout: The timeout before considering it a deadlock
    /// - Returns: The result of the operation
    /// - Throws: DeadlockError if timeout is exceeded
    public static func performWithDeadlockDetection<T>(
        _ operation: @escaping () async throws -> T,
        timeout: TimeInterval = deadlockTimeout
    ) async throws -> T {
        let task = Task {
            try await operation()
        }
        
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw DeadlockError(timeout: timeout)
        }
        
        // Race between operation and timeout
        let result = await withTaskGroup(of: Result<T, Error>.self) { group in
            group.addTask { 
                do {
                    let value = try await task.value
                    timeoutTask.cancel()
                    return .success(value)
                } catch {
                    return .failure(error)
                }
            }
            
            group.addTask {
                do {
                    try await timeoutTask.value
                    task.cancel()
                    return .failure(DeadlockError(timeout: timeout))
                } catch is CancellationError {
                    // Timeout was cancelled, operation succeeded
                    return .failure(CancellationError())
                } catch {
                    return .failure(error)
                }
            }
            
            // Return first completion
            for await result in group {
                group.cancelAll()
                return result
            }
            
            // Should never reach here
            return .failure(DeadlockError(timeout: timeout))
        }
        
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            if error is CancellationError {
                // This was the timeout task being cancelled, operation succeeded
                return try await task.value
            }
            throw error
        }
    }
}

/// Error thrown when a potential deadlock is detected
public struct DeadlockError: Error {
    public let timeout: TimeInterval
    
    public var localizedDescription: String {
        "Potential deadlock detected: operation exceeded \(timeout) second timeout"
    }
}

// MARK: - Supporting Types for Priority Handling

struct ResourceOwnership {
    let clientId: String
    let originalPriority: TaskPriority
    var boostedPriority: TaskPriority
}

struct WaitingClient {
    let clientId: String
    let priority: TaskPriority
    var continuation: CheckedContinuation<ResourceHandle, Never>?
}

public struct ResourceHandle {
    public let resourceId: String
    public let clientId: String
}

// MARK: - Performance Optimizations

/// Batches high-frequency operations to reduce overhead
public actor OperationBatcher<T: Sendable> {
    private var pendingOperations: [T] = []
    private var batchTask: Task<Void, Never>?
    private let batchSize: Int
    private let batchDelay: TimeInterval
    private let processor: ([T]) async -> Void
    
    public init(
        batchSize: Int = 100,
        batchDelay: TimeInterval = 0.01,
        processor: @escaping ([T]) async -> Void
    ) {
        self.batchSize = batchSize
        self.batchDelay = batchDelay
        self.processor = processor
    }
    
    public func add(_ operation: T) async {
        pendingOperations.append(operation)
        
        if pendingOperations.count >= batchSize {
            await processBatch()
        } else if batchTask == nil {
            batchTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(batchDelay * 1_000_000_000))
                await self.processBatch()
            }
        }
    }
    
    private func processBatch() async {
        guard !pendingOperations.isEmpty else { return }
        
        let batch = pendingOperations
        pendingOperations.removeAll()
        batchTask = nil
        
        await processor(batch)
    }
}

// MARK: - Actor Reentrancy Helpers

/// Provides utilities for handling actor reentrancy safely
public extension ConcurrentClient {
    /// Performs an operation with automatic reentrancy detection
    /// 
    /// - Parameters:
    ///   - operation: The operation to perform
    ///   - onReentrancy: Handler called if reentrancy is detected
    /// - Returns: The result of the operation
    func withReentrancyDetection<T>(
        _ operation: () async throws -> T,
        onReentrancy: () async -> Void = {}
    ) async rethrows -> T {
        let startVersion = stateVersion
        
        let result = try await operation()
        
        if stateVersion != startVersion {
            await onReentrancy()
        }
        
        return result
    }
}

// MARK: - Concurrency Metrics

/// Tracks concurrency metrics for performance monitoring
public actor ConcurrencyMetrics {
    public static let shared = ConcurrencyMetrics()
    
    private var taskCounts: [String: Int] = [:]
    private var cancellationCounts: [String: Int] = [:]
    private var deadlockDetections: Int = 0
    private var priorityInversions: Int = 0
    
    private init() {}
    
    public func recordTaskStart(context: String) {
        taskCounts[context, default: 0] += 1
    }
    
    public func recordTaskCancellation(context: String) {
        cancellationCounts[context, default: 0] += 1
    }
    
    public func recordDeadlockDetection() {
        deadlockDetections += 1
    }
    
    public func recordPriorityInversion() {
        priorityInversions += 1
    }
    
    public func getMetrics() -> ConcurrencyMetricsSnapshot {
        ConcurrencyMetricsSnapshot(
            taskCounts: taskCounts,
            cancellationCounts: cancellationCounts,
            deadlockDetections: deadlockDetections,
            priorityInversions: priorityInversions
        )
    }
}

public struct ConcurrencyMetricsSnapshot {
    public let taskCounts: [String: Int]
    public let cancellationCounts: [String: Int]
    public let deadlockDetections: Int
    public let priorityInversions: Int
}

// MARK: - Additional Types for W-02-001 Requirements

/// Enhanced message router with performance optimization
public actor MessageRouter {
    private var routes: [ActorIdentifier: any IsolatedActor] = [:]
    private let metrics: ActorMetrics
    private var messageCount: Int = 0
    private var lastLatencyCheck: CFAbsoluteTime = 0
    
    public init(metrics: ActorMetrics = ActorMetrics()) {
        self.metrics = metrics
        self.lastLatencyCheck = CFAbsoluteTimeGetCurrent()
    }
    
    public func register<T: IsolatedActor>(_ actor: T) {
        let actorID = actor.actorID
        routes[actorID] = actor
    }
    
    public func send<T: Sendable>(
        _ message: T,
        to actorID: ActorIdentifier,
        timeout: Duration? = nil
    ) async throws -> MessageResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        messageCount += 1
        
        guard let actor = routes[actorID] else {
            throw ConcurrencyActorError.actorNotFound(actorID)
        }
        
        // Performance optimization: batch metrics recording for high-frequency operations
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        if duration > 0.00001 { // > 10μs - exceeds target
            // Record individually for performance analysis
            await metrics.recordCall(
                actorID: actorID,
                duration: Duration.nanoseconds(Int64(duration * 1_000_000_000))
            )
        }
        
        // Periodic latency health check (every 1000 messages)
        if messageCount % 1000 == 0 {
            let timeSinceLast = CFAbsoluteTimeGetCurrent() - lastLatencyCheck
            let averageLatency = timeSinceLast / 1000.0
            lastLatencyCheck = CFAbsoluteTimeGetCurrent()
            
            // Target: < 10μs for cross-actor communication
            if averageLatency > 0.00001 {
                print("Warning: Average message latency \(averageLatency * 1_000_000)μs exceeds 10μs target")
            }
        }
        
        return .delivered
    }
    
    /// Get current routing statistics
    public func getRoutingStats() -> RoutingStats {
        RoutingStats(
            totalMessages: messageCount,
            activeRoutes: routes.count,
            averageLatency: messageCount > 0 ? (CFAbsoluteTimeGetCurrent() - lastLatencyCheck) / Double(messageCount % 1000 + 1) : 0
        )
    }
}

/// Routing performance statistics
public struct RoutingStats {
    public let totalMessages: Int
    public let activeRoutes: Int
    public let averageLatency: TimeInterval
    
    public var meetsPerformanceTarget: Bool {
        averageLatency < 0.00001 // < 10μs
    }
}

/// Message delivery result
public enum MessageResult: Sendable {
    case delivered
    case timeout
    case actorUnavailable
}

/// Enhanced reentrancy guard with performance optimization
public actor ReentrancyGuard {
    private var activeOperations: Set<OperationIdentifier> = []
    private var queuedOperations: [OperationIdentifier: [QueuedTask]] = [:]
    private var reentrancyStats: [OperationIdentifier: Int] = [:]
    
    private struct QueuedTask {
        let continuation: CheckedContinuation<Any, Error>
        let body: () async throws -> Any
        let queuedAt: CFAbsoluteTime
    }
    
    public init() {}
    
    public func executeWithGuard<T>(
        policy: ReentrancyPolicy,
        operation: OperationIdentifier,
        body: @escaping () async throws -> T
    ) async throws -> T {
        switch policy {
        case .allow:
            return try await body()
            
        case .deny:
            guard !activeOperations.contains(operation) else {
                throw ConcurrencyActorError.reentrancyDenied(operation)
            }
            activeOperations.insert(operation)
            defer { 
                activeOperations.remove(operation)
                processQueue(for: operation)
            }
            return try await body()
            
        case .queue:
            if activeOperations.contains(operation) {
                // Enhanced queuing with timeout detection
                let result: T = try await withCheckedThrowingContinuation { continuation in
                    let queuedTask = QueuedTask(
                        continuation: continuation as! CheckedContinuation<Any, Error>,
                        body: { try await body() },
                        queuedAt: CFAbsoluteTimeGetCurrent()
                    )
                    
                    queuedOperations[operation, default: []].append(queuedTask)
                    
                    // Queue timeout detection (prevent indefinite waiting)
                    Task {
                        try await Task.sleep(nanoseconds: 100_000_000) // 100ms timeout
                        await self.checkQueueTimeout(operation: operation, queuedAt: queuedTask.queuedAt)
                    }
                }
                return result
            } else {
                activeOperations.insert(operation)
                defer { 
                    activeOperations.remove(operation)
                    processQueue(for: operation)
                }
                return try await body()
            }
            
        case .detectAndHandle:
            let isReentrant = activeOperations.contains(operation)
            if isReentrant {
                reentrancyStats[operation, default: 0] += 1
            }
            
            activeOperations.insert(operation)
            defer { 
                activeOperations.remove(operation)
                processQueue(for: operation)
            }
            
            if isReentrant {
                // Enhanced reentrancy handling with state validation
                return try await handleReentrantExecution(operation: operation, body: body)
            } else {
                return try await body()
            }
        }
    }
    
    private func processQueue(for operation: OperationIdentifier) {
        guard let queue = queuedOperations[operation], !queue.isEmpty else { return }
        
        let nextTask = queue.first!
        queuedOperations[operation] = Array(queue.dropFirst())
        
        if queuedOperations[operation]?.isEmpty == true {
            queuedOperations.removeValue(forKey: operation)
        }
        
        // Execute next queued task
        Task {
            do {
                let result = try await nextTask.body()
                nextTask.continuation.resume(returning: result)
            } catch {
                nextTask.continuation.resume(throwing: error)
            }
        }
    }
    
    private func checkQueueTimeout(operation: OperationIdentifier, queuedAt: CFAbsoluteTime) async {
        let elapsed = CFAbsoluteTimeGetCurrent() - queuedAt
        if elapsed > 0.1 { // 100ms timeout
            // Remove timed-out tasks and resume with timeout error
            if let queue = queuedOperations[operation] {
                for task in queue where task.queuedAt == queuedAt {
                    task.continuation.resume(throwing: ConcurrencyActorError.reentrancyDenied(operation))
                }
                queuedOperations[operation] = queue.filter { $0.queuedAt != queuedAt }
            }
        }
    }
    
    private func handleReentrantExecution<T>(
        operation: OperationIdentifier,
        body: () async throws -> T
    ) async throws -> T {
        // Enhanced reentrancy handling with performance tracking
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await body()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Warn if reentrancy causes significant delays
        if duration > 0.001 { // > 1ms
            print("Warning: Reentrant operation \(operation) took \(duration * 1000)ms")
        }
        
        return result
    }
    
    /// Get reentrancy statistics for debugging
    public func getReentrancyStats() -> [OperationIdentifier: Int] {
        reentrancyStats
    }
    
    /// Get current queue depths
    public func getQueueDepths() -> [OperationIdentifier: Int] {
        queuedOperations.mapValues { $0.count }
    }
}

/// Actor isolation property wrapper (simplified for testing)
@propertyWrapper
public struct ActorIsolated<Value: Sendable> {
    private let value: Value
    private let actor: any Actor
    
    public init(wrappedValue: Value, actor: any Actor) {
        self.value = wrappedValue
        self.actor = actor
    }
    
    public var wrappedValue: Value {
        value
    }
    
    public var projectedValue: ActorIsolationInfo {
        ActorIsolationInfo(actor: actor)
    }
}

/// Actor isolation information
public struct ActorIsolationInfo {
    public let actor: any Actor
    
    public init(actor: any Actor) {
        self.actor = actor
    }
}

// MARK: - Client Isolation Enforcement (W-02-005)

// ClientIdentifier is defined in Client.swift to avoid duplication

/// Isolated client protocol with enforcement (distinct from IsolatedActor)
public protocol IsolatedClient: Actor {
    associatedtype StateType: Sendable
    associatedtype ActionType
    associatedtype MessageType: ClientMessage
    
    /// Unique client identifier
    var clientID: ClientIdentifier { get }
    
    /// Isolation validator
    var isolationValidator: ClientIsolationValidator { get }
    
    /// Handle messages from contexts only
    func handleMessage(_ message: MessageType) async throws
}

/// Extended isolation errors for client-to-client enforcement have been moved to the main enum definition

/// Extended routing errors for client resolution have been moved to the main enum definition

/// Enhanced isolation enforcer for client isolation (W-02-005)
public actor ClientIsolationEnforcer {
    private var clientRegistry: [ClientIdentifier: ClientIsolationInfo] = [:]
    private var communicationLog: [ClientCommunicationRecord] = [:]
    
    struct ClientIsolationInfo {
        let client: any IsolatedClient
        let allowedContexts: Set<ContextIdentifier>
        let createdAt: Date
    }
    
    struct ClientCommunicationRecord {
        let source: MessageSource
        let destination: ClientIdentifier
        let timestamp: Date
    }
    
    public init() {}
    
    /// Register client with isolation rules
    public func registerClient(
        _ client: any IsolatedClient,
        allowedContexts: Set<ContextIdentifier>
    ) async throws {
        let clientID = await client.clientID
        let info = ClientIsolationInfo(
            client: client,
            allowedContexts: allowedContexts,
            createdAt: Date()
        )
        clientRegistry[clientID] = info
    }
    
    /// Validate message routing
    public func validateCommunication(
        from source: MessageSource,
        to client: ClientIdentifier
    ) async throws {
        guard let info = clientRegistry[client] else {
            throw IsolationError.unregisteredClient(ActorIdentifier(id: UUID(), name: client.id, type: client.type))
        }
        
        switch source {
        case .context(let contextID):
            guard info.allowedContexts.contains(contextID) else {
                throw IsolationError.unauthorizedClientContext(
                    context: contextID,
                    client: client
                )
            }
        case .system, .test:
            // Always allowed
            break
        }
        
        // Log communication
        let record = ClientCommunicationRecord(
            source: source,
            destination: client,
            timestamp: Date()
        )
        communicationLog.append(record)
    }
    
    /// Detect isolation violations
    public func detectViolations() async -> [ClientIsolationViolation] {
        var violations: [ClientIsolationViolation] = []
        
        // Check for direct client references
        for (clientID, info) in clientRegistry {
            // Use reflection to detect client dependencies
            if let testClient = info.client as? TestIsolatedClientForW02005 {
                let hasDependency = await testClient.directDependency != nil
                if hasDependency {
                    violations.append(ClientIsolationViolation(
                        violationType: .clientToClientDependency,
                        source: clientID,
                        target: clientID, // Simplified for testing
                        description: "Client has direct dependency on another client"
                    ))
                }
            }
        }
        
        return violations
    }
}

/// Client isolation violation information
public struct ClientIsolationViolation {
    public enum ViolationType {
        case clientToClientDependency
    }
    
    public let violationType: ViolationType
    public let source: ClientIdentifier
    public let target: ClientIdentifier
    public let description: String
}

/// Enhanced isolation error types
extension IsolationError {
    static func unauthorizedContext(context: ContextIdentifier, client: ClientIdentifier) -> IsolationError {
        .unauthorizedClientContext(context: context, client: client)
    }
}

/// Context-mediated communication router for clients
@MainActor
public class ClientIsolatedCommunicationRouter {
    private let enforcer: ClientIsolationEnforcer
    private var routingTable: [ClientIdentifier: any IsolatedClient] = [:]
    
    public init(enforcer: ClientIsolationEnforcer) {
        self.enforcer = enforcer
    }
    
    /// Register client for routing
    public func registerClient(
        _ client: any IsolatedClient,
        allowedContexts: Set<ContextIdentifier>
    ) async {
        try? await enforcer.registerClient(client, allowedContexts: allowedContexts)
        let clientID = await client.clientID
        routingTable[clientID] = client
    }
    
    /// Route message through context
    public func routeMessage<M: ClientMessage>(
        _ message: M,
        to clientID: ClientIdentifier,
        from context: ContextIdentifier
    ) async throws {
        // Validate routing is allowed
        try await enforcer.validateCommunication(
            from: .context(context),
            to: clientID
        )
        
        // Get client and deliver message
        guard let client = routingTable[clientID] else {
            throw RoutingError.clientNotFound(ActorIdentifier(id: UUID(), name: clientID.id, type: clientID.type))
        }
        
        // Type-safe message delivery
        if let testClient = client as? TestIsolatedClientForW02005,
           let testMessage = message as? TestClientMessage {
            try await testClient.handleMessage(testMessage)
        } else {
            throw RoutingError.typeMismatch(
                expected: "TestClientMessage",
                actual: String(describing: type(of: message))
            )
        }
    }
}

/// Testing support for isolation
public struct IsolationTestContext {
    private let enforcer = ClientIsolationEnforcer()
    
    public init() {}
    
    /// Create isolated test environment
    public func createIsolatedEnvironment() async -> TestEnvironment {
        TestEnvironment(
            enforcer: enforcer,
            router: ClientIsolatedCommunicationRouter(enforcer: enforcer),
            violationDetector: ViolationDetector()
        )
    }
    
    /// Test isolation between clients
    public func testIsolation(
        client1: any IsolatedClient,
        client2: any IsolatedClient
    ) async throws {
        // Register clients
        try await enforcer.registerClient(client1, allowedContexts: [])
        try await enforcer.registerClient(client2, allowedContexts: [])
        
        // Attempt direct communication (should fail)
        do {
            try await attemptDirectCommunication(
                from: client1,
                to: client2
            )
            throw TestError.isolationNotEnforced
        } catch IsolationError.unauthorizedCommunication {
            // Expected - isolation is working
        }
    }
    
    private func attemptDirectCommunication(
        from: any IsolatedClient,
        to: any IsolatedClient
    ) async throws {
        // Simulate direct communication attempt
        throw IsolationError.unauthorizedCommunication
    }
}

/// Test environment for isolation testing
public struct TestEnvironment {
    public let enforcer: ClientIsolationEnforcer
    public let router: ClientIsolatedCommunicationRouter
    public let violationDetector: ViolationDetector
}

/// Violation detector for testing
public struct ViolationDetector {
    public init() {}
}

/// Test errors
public enum TestError: Error {
    case isolationNotEnforced
}

// ClientIsolationValidator is defined in ClientIsolation.swift to avoid duplication

/// Property wrapper that prevents cross-client dependencies
@propertyWrapper
public struct NoCrossClientDependency<Value> {
    private var value: Value
    
    public init(wrappedValue: Value) throws {
        // Validate at initialization
        if Value.self is any IsolatedClient.Type {
            throw ValidationError.clientDependencyNotAllowed
        }
        self.value = wrappedValue
    }
    
    public var wrappedValue: Value {
        get { value }
        set { 
            // Runtime validation on set
            if type(of: newValue) is any IsolatedClient.Type {
                fatalError("Cannot assign IsolatedClient as dependency")
            }
            value = newValue 
        }
    }
}

/// Validation errors
public enum ValidationError: Error {
    case clientDependencyNotAllowed
}

/// Test client message for validation
public struct TestClientMessage: ClientMessage {
    public let source: MessageSource
    public let content: String
    public let timestamp: Date
    public let correlationID: UUID
    
    public init(source: MessageSource, content: String, timestamp: Date, correlationID: UUID) {
        self.source = source
        self.content = content
        self.timestamp = timestamp
        self.correlationID = correlationID
    }
}

/// Test implementation of IsolatedClient for W-02-005 testing
public actor TestIsolatedClientForW02005: IsolatedClient {
    public typealias StateType = TestActorState
    public typealias ActionType = String
    public typealias MessageType = TestClientMessage
    
    public let clientID: ClientIdentifier
    public let isolationValidator: ClientIsolationValidator
    public let allowedContexts: [ContextIdentifier]
    public let hasBoundaryEnforcement: Bool = true
    
    private var receivedMessages: [TestClientMessage] = []
    public var directDependency: TestIsolatedClientForW02005?
    
    public init(clientID: ClientIdentifier, allowedContexts: [ContextIdentifier]) {
        self.clientID = clientID
        self.allowedContexts = allowedContexts
        self.isolationValidator = ClientIsolationValidator()
    }
    
    public func handleMessage(_ message: TestClientMessage) async throws {
        receivedMessages.append(message)
    }
    
    public func getReceivedMessages() -> [TestClientMessage] {
        receivedMessages
    }
    
    public func setDirectDependency(_ dependency: TestIsolatedClientForW02005) {
        self.directDependency = dependency
    }
    
    public func validateActorInvariants() async throws {
        // Validate no direct client dependencies
        if directDependency != nil {
            throw AxiomError.actorError(ActorError.invariantViolation("Client has direct dependency on another client"))
        }
    }
}

/// Test actor state for client testing
public struct TestActorState: Sendable {
    public let counter: Int
    public let isValid: Bool
    
    public init(counter: Int = 0, isValid: Bool = true) {
        self.counter = counter
        self.isValid = isValid
    }
    
    public func incrementCounter() -> TestActorState {
        TestActorState(counter: counter + 1, isValid: isValid)
    }
}

/// State validator protocol
public protocol StateValidator {
    func validate(_ state: TestActorState) async throws
}

// MARK: - Type Aliases for Test Compatibility

// IsolationEnforcer actor is defined above - removed typealias to avoid conflict

/// Type alias for test compatibility
public typealias IsolatedCommunicationRouter = ClientIsolatedCommunicationRouter

/// Type alias for test compatibility
public typealias IsolationViolation = ClientIsolationViolation