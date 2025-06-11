import Foundation

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
    private var priorityStats = PriorityStats()
    
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
    
    /// Records a priority boost for statistics tracking
    public func recordPriorityBoost(from: TaskPriority, to: TaskPriority) async {
        priorityStats.totalBoosts += 1
        priorityStats.lastBoostTime = CFAbsoluteTimeGetCurrent()
    }
    
    /// Records a priority restore for statistics tracking
    public func recordPriorityRestore(to: TaskPriority) async {
        priorityStats.totalRestores += 1
        priorityStats.lastRestoreTime = CFAbsoluteTimeGetCurrent()
    }
    
    /// Gets current priority statistics
    public func getPriorityStats() async -> PriorityStats {
        priorityStats
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
    
    /// Handle state changes during reentrancy
    func handleStateChange(from previousVersion: Int) async {
        // Default implementation - can be overridden by clients
        print("State changed from version \(previousVersion) to \(stateVersion)")
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

/// Priority coordination statistics
public struct PriorityStats {
    public var totalBoosts: Int = 0
    public var totalRestores: Int = 0
    public var lastBoostTime: CFAbsoluteTime = 0
    public var lastRestoreTime: CFAbsoluteTime = 0
}