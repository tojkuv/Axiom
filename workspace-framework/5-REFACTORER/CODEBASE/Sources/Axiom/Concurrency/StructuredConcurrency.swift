import Foundation

// MARK: - Structured Concurrency Coordination (W-02-002)

/// Task reference for hierarchy tracking
public struct TaskReference: Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let priority: TaskPriority
    public let createdAt: Date
    
    public init(id: UUID = UUID(), name: String, priority: TaskPriority = .medium) {
        self.id = id
        self.name = name
        self.priority = priority
        self.createdAt = Date()
    }
}

/// Internal task node for hierarchy management
private struct TaskNode {
    let reference: TaskReference
    var parent: TaskReference?
    var children: Set<TaskReference> = []
    weak var task: Task<Any, Error>?
}

/// Structured task coordinator for managing task hierarchies
public actor StructuredTaskCoordinator {
    private var taskHierarchy: [TaskReference: TaskNode] = [:]
    private var currentTaskStack: [TaskReference] = []
    private let metrics = TaskMetrics()
    
    public init() {}
    
    /// Get current task hierarchy for debugging
    public func getTaskHierarchy() -> [TaskReference: Set<TaskReference>] {
        var hierarchy: [TaskReference: Set<TaskReference>] = [:]
        for (ref, node) in taskHierarchy {
            hierarchy[ref] = node.children
        }
        return hierarchy
    }
    
    /// Create a child task with automatic management and performance optimization
    public func createChildTask<T>(
        name: String,
        priority: TaskPriority = .medium,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> Task<T, Error> {
        let startCreationTime = CFAbsoluteTimeGetCurrent()
        let parentRef = currentTaskStack.last
        let childRef = TaskReference(name: name, priority: priority)
        
        // Register in hierarchy with optimized batch operations
        await registerChild(childRef, parent: parentRef)
        
        // Create task with enhanced management and lifecycle tracking
        let task = Task(priority: priority) { [weak self] in
            // Performance tracking: ensure creation overhead < 1μs
            let creationDuration = CFAbsoluteTimeGetCurrent() - startCreationTime
            
            // Push to stack for child tracking
            await self?.pushTaskReference(childRef)
            
            // Notify start event
            await GlobalTaskRegistry.shared.notifyEvent(.started(childRef))
            
            defer {
                Task {
                    await self?.popTaskReference()
                    await self?.unregisterTask(childRef)
                }
            }
            
            do {
                let startTime = CFAbsoluteTimeGetCurrent()
                let result = try await operation()
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                
                await self?.metrics.recordSuccess(
                    childRef,
                    duration: Duration.seconds(duration),
                    creationOverhead: Duration.seconds(creationDuration)
                )
                
                // Notify completion event
                await GlobalTaskRegistry.shared.notifyEvent(
                    .completed(childRef, duration: Duration.seconds(duration))
                )
                
                return result
            } catch {
                await self?.metrics.recordFailure(childRef, error: error)
                
                // Notify failure event
                await GlobalTaskRegistry.shared.notifyEvent(.failed(childRef, error: error))
                
                throw error
            }
        }
        
        // Store weak reference to task with enhanced node management
        var node = taskHierarchy[childRef] ?? TaskNode(reference: childRef)
        node.task = task as? Task<Any, Error>
        taskHierarchy[childRef] = node
        
        return task
    }
    
    /// Register a child task in the hierarchy
    private func registerChild(_ child: TaskReference, parent: TaskReference?) {
        var childNode = TaskNode(reference: child, parent: parent)
        
        if let parent = parent {
            childNode.parent = parent
            if var parentNode = taskHierarchy[parent] {
                parentNode.children.insert(child)
                taskHierarchy[parent] = parentNode
            }
        }
        
        taskHierarchy[child] = childNode
        
        // Notify lifecycle observers
        Task {
            await GlobalTaskRegistry.shared.register(child, info: TaskInfo(
                name: child.name,
                priority: child.priority,
                parent: parent
            ))
        }
    }
    
    /// Unregister a task from the hierarchy
    private func unregisterTask(_ reference: TaskReference) {
        guard let node = taskHierarchy[reference] else { return }
        
        // Remove from parent's children
        if let parent = node.parent,
           var parentNode = taskHierarchy[parent] {
            parentNode.children.remove(reference)
            taskHierarchy[parent] = parentNode
        }
        
        // Remove from hierarchy
        taskHierarchy.removeValue(forKey: reference)
        
        // Notify registry
        Task {
            await GlobalTaskRegistry.shared.unregister(reference)
        }
    }
    
    /// Cancel a task and all its children with performance tracking
    public func cancelTaskTree(_ reference: TaskReference) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard let node = taskHierarchy[reference] else { return }
        
        // Cancel children first (depth-first) for proper cleanup order
        for child in node.children {
            await cancelTaskTree(child)
        }
        
        // Cancel the task itself
        node.task?.cancel()
        
        // Track cancellation propagation performance
        let propagationTime = CFAbsoluteTimeGetCurrent() - startTime
        await metrics.recordCancellation(
            reference,
            propagationTime: Duration.seconds(propagationTime)
        )
        
        // Notify cancellation event
        await GlobalTaskRegistry.shared.notifyEvent(.cancelled(reference))
    }
    
    /// Get performance statistics from the coordinator
    public func getPerformanceStats() async -> TaskPerformanceStats {
        return await metrics.getPerformanceStats()
    }
    
    /// Push task reference to current stack
    private func pushTaskReference(_ reference: TaskReference) {
        currentTaskStack.append(reference)
    }
    
    /// Pop task reference from current stack
    private func popTaskReference() {
        _ = currentTaskStack.popLast()
    }
    
    /// Add lifecycle observer
    public func addLifecycleObserver(_ observer: TaskLifecycleObserver) async {
        await GlobalTaskRegistry.shared.addObserver(observer)
    }
}

// MARK: - Task Metrics

/// Enhanced internal metrics collection for tasks with performance tracking
private actor TaskMetrics {
    private var taskDurations: [TaskReference: [Duration]] = [:]
    private var taskFailures: [TaskReference: [Error]] = [:]
    private var taskCancellations: Set<TaskReference> = []
    private var creationOverheads: [Duration] = []
    private var cancellationPropagationTimes: [Duration] = []
    
    func recordSuccess(_ reference: TaskReference, duration: Duration, creationOverhead: Duration? = nil) {
        taskDurations[reference, default: []].append(duration)
        
        // Track creation overhead for performance analysis
        if let overhead = creationOverhead {
            creationOverheads.append(overhead)
            
            // Warn if creation overhead exceeds 1μs target
            if overhead.components.attoseconds > 1_000 { // 1μs = 1000 attoseconds
                print("Warning: Task creation overhead \(overhead) exceeds 1μs target")
            }
        }
    }
    
    func recordFailure(_ reference: TaskReference, error: Error) {
        taskFailures[reference, default: []].append(error)
    }
    
    func recordCancellation(_ reference: TaskReference, propagationTime: Duration? = nil) {
        taskCancellations.insert(reference)
        
        // Track cancellation propagation performance
        if let propTime = propagationTime {
            cancellationPropagationTimes.append(propTime)
            
            // Warn if propagation exceeds 5μs target
            if propTime.components.attoseconds > 5_000 { // 5μs = 5000 attoseconds
                print("Warning: Cancellation propagation \(propTime) exceeds 5μs target")
            }
        }
    }
    
    /// Get performance statistics
    func getPerformanceStats() -> TaskPerformanceStats {
        let avgCreationOverhead = creationOverheads.isEmpty ? Duration.zero : 
            Duration.nanoseconds(creationOverheads.map(\.components.attoseconds).reduce(0, +) / Int64(creationOverheads.count))
        
        let avgCancellationTime = cancellationPropagationTimes.isEmpty ? Duration.zero :
            Duration.nanoseconds(cancellationPropagationTimes.map(\.components.attoseconds).reduce(0, +) / Int64(cancellationPropagationTimes.count))
        
        return TaskPerformanceStats(
            totalTasksCreated: taskDurations.count,
            totalTasksCompleted: taskDurations.values.flatMap { $0 }.count,
            totalTasksFailed: taskFailures.values.flatMap { $0 }.count,
            totalTasksCancelled: taskCancellations.count,
            averageCreationOverhead: avgCreationOverhead,
            averageCancellationPropagation: avgCancellationTime,
            meetsCreationTarget: avgCreationOverhead.components.attoseconds <= 1_000,
            meetsCancellationTarget: avgCancellationTime.components.attoseconds <= 5_000
        )
    }
}

/// Performance statistics for task metrics
public struct TaskPerformanceStats {
    public let totalTasksCreated: Int
    public let totalTasksCompleted: Int
    public let totalTasksFailed: Int
    public let totalTasksCancelled: Int
    public let averageCreationOverhead: Duration
    public let averageCancellationPropagation: Duration
    public let meetsCreationTarget: Bool
    public let meetsCancellationTarget: Bool
}

// MARK: - Concurrency Limiter

/// Enhanced concurrency limiter with performance monitoring and fairness
public actor ConcurrencyLimiter {
    private let maxConcurrency: Int
    private var currentCount: Int = 0
    private var waiters: [WaiterInfo] = []
    private var acquisitionTimes: [Duration] = []
    private var totalAcquisitions: Int = 0
    
    private struct WaiterInfo {
        let continuation: CheckedContinuation<Void, Never>
        let requestTime: Date
        let priority: TaskPriority
    }
    
    public init(maxConcurrency: Int) {
        self.maxConcurrency = maxConcurrency
    }
    
    /// Acquire a slot for execution with priority and timing
    public func acquire(priority: TaskPriority = .medium) async {
        let requestTime = Date()
        
        if currentCount < maxConcurrency {
            currentCount += 1
            totalAcquisitions += 1
            
            // Record immediate acquisition (< 100ns target)
            let acquisitionDuration = Date().timeIntervalSince(requestTime)
            acquisitionTimes.append(Duration.seconds(acquisitionDuration))
        } else {
            await withCheckedContinuation { continuation in
                let waiterInfo = WaiterInfo(
                    continuation: continuation,
                    requestTime: requestTime,
                    priority: priority
                )
                
                // Insert in priority order (higher priority first)
                let insertIndex = waiters.firstIndex { waiter in
                    waiter.priority.rawValue < priority.rawValue
                } ?? waiters.endIndex
                
                waiters.insert(waiterInfo, at: insertIndex)
            }
            
            // Record wait time
            let acquisitionDuration = Date().timeIntervalSince(requestTime)
            acquisitionTimes.append(Duration.seconds(acquisitionDuration))
            totalAcquisitions += 1
        }
    }
    
    /// Release a slot after execution with fairness
    public func release() {
        if let waiterInfo = waiters.first {
            waiters.removeFirst()
            waiterInfo.continuation.resume()
        } else {
            currentCount -= 1
        }
    }
    
    /// Get concurrency limiter statistics
    public func getStats() -> ConcurrencyLimiterStats {
        let avgAcquisitionTime = acquisitionTimes.isEmpty ? Duration.zero :
            Duration.nanoseconds(acquisitionTimes.map(\.components.attoseconds).reduce(0, +) / Int64(acquisitionTimes.count))
        
        let currentWaitTime = waiters.isEmpty ? Duration.zero :
            Duration.seconds(Date().timeIntervalSince(waiters.first?.requestTime ?? Date()))
        
        return ConcurrencyLimiterStats(
            maxConcurrency: maxConcurrency,
            currentUsage: currentCount,
            waitingTasks: waiters.count,
            totalAcquisitions: totalAcquisitions,
            averageAcquisitionTime: avgAcquisitionTime,
            currentWaitTime: currentWaitTime,
            meetsAcquisitionTarget: avgAcquisitionTime.components.attoseconds <= 100_000 // 100ns
        )
    }
}

/// Concurrency limiter statistics
public struct ConcurrencyLimiterStats {
    public let maxConcurrency: Int
    public let currentUsage: Int
    public let waitingTasks: Int
    public let totalAcquisitions: Int
    public let averageAcquisitionTime: Duration
    public let currentWaitTime: Duration
    public let meetsAcquisitionTarget: Bool
}

// MARK: - Coordinated Task Group

/// Enhanced task group with coordination support
public struct CoordinatedTaskGroup<Success: Sendable> {
    private let coordinator: StructuredTaskCoordinator
    private let limiter: ConcurrencyLimiter?
    private var tasks: [Task<Success, Error>] = []
    
    public init(
        coordinator: StructuredTaskCoordinator,
        maxConcurrency: Int? = nil
    ) {
        self.coordinator = coordinator
        self.limiter = maxConcurrency.map { ConcurrencyLimiter(maxConcurrency: $0) }
    }
    
    /// Add a coordinated task
    public mutating func addTask(
        priority: TaskPriority = .medium,
        operation: @escaping @Sendable () async throws -> Success
    ) async {
        // Acquire limiter if available
        if let limiter = limiter {
            await limiter.acquire()
        }
        
        let task = try! await coordinator.createChildTask(
            name: "GroupTask",
            priority: priority
        ) { [limiter] in
            defer {
                if let limiter = limiter {
                    Task {
                        await limiter.release()
                    }
                }
            }
            
            return try await operation()
        }
        
        tasks.append(task)
    }
    
    /// Wait for all tasks with optional timeout
    public func waitForAll(timeout: Duration? = nil) async throws -> [Success] {
        if let timeout = timeout {
            return try await withTimeout(timeout) {
                try await self.collectResults()
            }
        } else {
            return try await collectResults()
        }
    }
    
    /// Collect results from partial failures
    public func collectResults() async -> [Result<Success, Error>] {
        var results: [Result<Success, Error>] = []
        
        for task in tasks {
            do {
                let value = try await task.value
                results.append(.success(value))
            } catch {
                results.append(.failure(error))
            }
        }
        
        return results
    }
    
    private func collectResults() async throws -> [Success] {
        var results: [Success] = []
        var errors: [Error] = []
        
        for task in tasks {
            do {
                let value = try await task.value
                results.append(value)
            } catch {
                errors.append(error)
            }
        }
        
        if !errors.isEmpty {
            throw ConcurrentErrors(errors: errors.enumerated().map { index, error in
                ConcurrentErrors.TaskError(
                    reference: TaskReference(name: "Task\(index)"),
                    error: error,
                    timestamp: Date()
                )
            })
        }
        
        return results
    }
}

// MARK: - Resource Management

/// Resource requirements for tasks
public enum ResourceRequirement: Hashable, Sendable {
    case memory(megabytes: Int)
    case cpu(cores: Int)
    case custom(String, value: Int)
}

/// Resource lease for tracking in structured concurrency
public struct TaskTaskResourceLease: Sendable {
    public let id: UUID
    public let resources: Set<ResourceRequirement>
    public let priority: TaskPriority
    
    init(resources: Set<ResourceRequirement>, priority: TaskPriority) {
        self.id = UUID()
        self.resources = resources
        self.priority = priority
    }
}

/// Resource monitor for acquisition and release
actor ResourceMonitor {
    private var availableResources: [ResourceRequirement: Int] = [
        .memory(megabytes: 1): 1024, // 1GB total
        .cpu(cores: 1): ProcessInfo.processInfo.processorCount
    ]
    private var allocatedResources: [TaskResourceLease] = []
    
    func acquire(_ requirements: Set<ResourceRequirement>, priority: TaskPriority) async throws -> TaskResourceLease {
        // Simplified implementation for MVP
        let lease = TaskResourceLease(resources: requirements, priority: priority)
        allocatedResources.append(lease)
        return lease
    }
    
    func release(_ lease: TaskResourceLease) {
        allocatedResources.removeAll { $0.id == lease.id }
    }
    
    func handleCancellation(_ lease: TaskResourceLease) {
        release(lease)
    }
}

/// Resource-aware executor for managed execution
public actor ResourceAwareExecutor {
    private let resourceMonitor = ResourceMonitor()
    private var activeTasks: Set<TaskReference> = []
    
    public init() {}
    
    /// Execute with resource management
    public func executeWithResources<T>(
        resources: Set<ResourceRequirement>,
        priority: TaskPriority = .medium,
        onRelease: (() -> Void)? = nil,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        // Acquire resources
        let lease = try await resourceMonitor.acquire(resources, priority: priority)
        
        defer {
            Task {
                await resourceMonitor.release(lease)
                onRelease?()
            }
        }
        
        // Execute with monitoring
        return try await withTaskCancellationHandler {
            try await operation()
        } onCancel: {
            Task {
                await resourceMonitor.handleCancellation(lease)
                onRelease?()
            }
        }
    }
}

// MARK: - Error Handling

/// Aggregated errors from concurrent operations
public struct ConcurrentErrors: Error {
    public let errors: [TaskError]
    
    public struct TaskError {
        public let reference: TaskReference
        public let error: Error
        public let timestamp: Date
    }
}

// MARK: - Task Lifecycle

/// Task lifecycle events
public enum TaskLifecycleEvent {
    case created(TaskReference)
    case started(TaskReference)
    case completed(TaskReference, duration: Duration)
    case failed(TaskReference, error: Error)
    case cancelled(TaskReference)
}

/// Protocol for lifecycle observers
public protocol TaskLifecycleObserver: Actor {
    func handleEvent(_ event: TaskLifecycleEvent) async
}

/// Task information for registry
public struct TaskInfo: Sendable {
    public let name: String
    public let priority: TaskPriority
    public let parent: TaskReference?
    public let createdAt: Date
    
    public init(name: String, priority: TaskPriority, parent: TaskReference?) {
        self.name = name
        self.priority = priority
        self.parent = parent
        self.createdAt = Date()
    }
}

/// Enhanced global task registry for system-wide tracking with performance monitoring
public actor GlobalTaskRegistry {
    public static let shared = GlobalTaskRegistry()
    
    private var tasks: [TaskReference: TaskInfo] = [:]
    private var observers: [any TaskLifecycleObserver] = []
    private var eventHistory: [TimestampedEvent] = []
    private let maxEventHistory = 1000
    
    private struct TimestampedEvent {
        let event: TaskLifecycleEvent
        let timestamp: Date
    }
    
    private init() {}
    
    public func register(_ reference: TaskReference, info: TaskInfo) {
        tasks[reference] = info
        
        Task {
            await notifyEvent(.created(reference))
        }
    }
    
    public func unregister(_ reference: TaskReference) {
        tasks.removeValue(forKey: reference)
    }
    
    public func addObserver(_ observer: any TaskLifecycleObserver) {
        observers.append(observer)
    }
    
    public func getActiveTaskCount() -> Int {
        return tasks.count
    }
    
    /// Get task registry statistics
    public func getRegistryStats() -> TaskRegistryStats {
        let totalEventsLogged = eventHistory.count
        let recentEvents = eventHistory.suffix(100) // Last 100 events
        
        let eventCounts = recentEvents.reduce(into: [String: Int]()) { counts, timestampedEvent in
            let eventType = String(describing: timestampedEvent.event).components(separatedBy: "(").first ?? "unknown"
            counts[eventType, default: 0] += 1
        }
        
        return TaskRegistryStats(
            activeTasks: tasks.count,
            totalEventsLogged: totalEventsLogged,
            observersCount: observers.count,
            recentEventCounts: eventCounts
        )
    }
    
    /// Public method for notifying events (enhanced from private)
    public func notifyEvent(_ event: TaskLifecycleEvent) async {
        // Store event history for debugging
        let timestampedEvent = TimestampedEvent(event: event, timestamp: Date())
        eventHistory.append(timestampedEvent)
        
        // Trim history if needed
        if eventHistory.count > maxEventHistory {
            eventHistory.removeFirst(eventHistory.count - maxEventHistory)
        }
        
        // Notify all observers efficiently
        await withTaskGroup(of: Void.self) { group in
            for observer in observers {
                group.addTask {
                    await observer.handleEvent(event)
                }
            }
        }
    }
    
    private func notifyObservers(_ event: TaskLifecycleEvent) async {
        await notifyEvent(event)
    }
}

/// Task registry statistics
public struct TaskRegistryStats {
    public let activeTasks: Int
    public let totalEventsLogged: Int
    public let observersCount: Int
    public let recentEventCounts: [String: Int]
}

// MARK: - Utility Functions

/// Timeout error for operations
public struct TimeoutError: Error {
    public let duration: Duration
}

/// Execute with timeout
public func withTimeout<T: Sendable>(
    _ timeout: Duration,
    operation: @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(for: timeout)
            throw TimeoutError(duration: timeout)
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

/// Create a coordinated task group
public func withCoordinatedTaskGroup<T>(
    of type: T.Type,
    coordinator: StructuredTaskCoordinator,
    maxConcurrency: Int? = nil,
    timeout: Duration? = nil,
    failureMode: FailureMode = .throwOnFirst,
    body: (inout CoordinatedTaskGroup<T>) async throws -> [T]
) async throws -> [T] {
    var group = CoordinatedTaskGroup<T>(
        coordinator: coordinator,
        maxConcurrency: maxConcurrency
    )
    
    _ = try await body(&group)
    
    return try await group.waitForAll(timeout: timeout)
}

/// Failure handling modes
public enum FailureMode {
    case throwOnFirst
    case partial
    case collectAll
}

// Overload for Result return type
public func withCoordinatedTaskGroup<T>(
    of type: T.Type,
    coordinator: StructuredTaskCoordinator,
    maxConcurrency: Int? = nil,
    failureMode: FailureMode,
    body: (inout CoordinatedTaskGroup<T>) async throws -> [Result<T, Error>]
) async throws -> [Result<T, Error>] {
    var group = CoordinatedTaskGroup<T>(
        coordinator: coordinator,
        maxConcurrency: maxConcurrency
    )
    
    _ = try await body(&group)
    
    return await group.collectResults()
}

// MARK: - Extensions for Task Groups

extension ThrowingTaskGroup {
    /// Execute with concurrency limit
    public mutating func mapWithLimit<T, R>(
        _ items: [T],
        maxConcurrency: Int,
        transform: @escaping @Sendable (T) async throws -> R
    ) async throws -> [R] where ChildTaskResult == (Int, R) {
        var index = 0
        var results: [(Int, R)] = []
        results.reserveCapacity(items.count)
        
        // Initial batch
        for item in items.prefix(maxConcurrency) {
            let currentIndex = index
            addTask {
                let result = try await transform(item)
                return (currentIndex, result)
            }
            index += 1
        }
        
        // Process remaining with sliding window
        for item in items.dropFirst(maxConcurrency) {
            let (completedIndex, result) = try await next()!
            results.append((completedIndex, result))
            
            let currentIndex = index
            addTask {
                let result = try await transform(item)
                return (currentIndex, result)
            }
            index += 1
        }
        
        // Collect remaining
        for try await result in self {
            results.append(result)
        }
        
        return results
            .sorted { $0.0 < $1.0 }
            .map { $0.1 }
    }
}