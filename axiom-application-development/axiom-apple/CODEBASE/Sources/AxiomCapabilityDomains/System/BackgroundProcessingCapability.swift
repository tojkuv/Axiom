import Foundation
import BackgroundTasks
import AxiomCore
import AxiomCapabilities

// MARK: - Background Processing Capability Configuration

/// Configuration for Background Processing capability
public struct BackgroundProcessingCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableBackgroundProcessing: Bool
    public let enableBackgroundAppRefresh: Bool
    public let enableBackgroundFetch: Bool
    public let enableBackgroundURLSessions: Bool
    public let maxConcurrentTasks: Int
    public let backgroundFetchInterval: TimeInterval
    public let taskTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableTaskScheduling: Bool
    public let enablePriorityManagement: Bool
    public let retryFailedTasks: Bool
    
    public init(
        enableBackgroundProcessing: Bool = true,
        enableBackgroundAppRefresh: Bool = true,
        enableBackgroundFetch: Bool = true,
        enableBackgroundURLSessions: Bool = true,
        maxConcurrentTasks: Int = 5,
        backgroundFetchInterval: TimeInterval = 3600.0, // 1 hour
        taskTimeout: TimeInterval = 30.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableTaskScheduling: Bool = true,
        enablePriorityManagement: Bool = true,
        retryFailedTasks: Bool = true
    ) {
        self.enableBackgroundProcessing = enableBackgroundProcessing
        self.enableBackgroundAppRefresh = enableBackgroundAppRefresh
        self.enableBackgroundFetch = enableBackgroundFetch
        self.enableBackgroundURLSessions = enableBackgroundURLSessions
        self.maxConcurrentTasks = maxConcurrentTasks
        self.backgroundFetchInterval = backgroundFetchInterval
        self.taskTimeout = taskTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableTaskScheduling = enableTaskScheduling
        self.enablePriorityManagement = enablePriorityManagement
        self.retryFailedTasks = retryFailedTasks
    }
    
    public var isValid: Bool {
        maxConcurrentTasks > 0 &&
        backgroundFetchInterval > 0 &&
        taskTimeout > 0
    }
    
    public func merged(with other: BackgroundProcessingCapabilityConfiguration) -> BackgroundProcessingCapabilityConfiguration {
        BackgroundProcessingCapabilityConfiguration(
            enableBackgroundProcessing: other.enableBackgroundProcessing,
            enableBackgroundAppRefresh: other.enableBackgroundAppRefresh,
            enableBackgroundFetch: other.enableBackgroundFetch,
            enableBackgroundURLSessions: other.enableBackgroundURLSessions,
            maxConcurrentTasks: other.maxConcurrentTasks,
            backgroundFetchInterval: other.backgroundFetchInterval,
            taskTimeout: other.taskTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableTaskScheduling: other.enableTaskScheduling,
            enablePriorityManagement: other.enablePriorityManagement,
            retryFailedTasks: other.retryFailedTasks
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> BackgroundProcessingCapabilityConfiguration {
        var adjustedInterval = backgroundFetchInterval
        var adjustedTimeout = taskTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentTasks = maxConcurrentTasks
        var adjustedBackgroundRefresh = enableBackgroundAppRefresh
        
        if environment.isLowPowerMode {
            adjustedInterval = max(backgroundFetchInterval, 7200.0) // Increase to 2 hours minimum
            adjustedTimeout = min(taskTimeout, 15.0) // Reduce to 15 seconds maximum
            adjustedConcurrentTasks = min(maxConcurrentTasks, 2)
            adjustedBackgroundRefresh = false
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return BackgroundProcessingCapabilityConfiguration(
            enableBackgroundProcessing: enableBackgroundProcessing,
            enableBackgroundAppRefresh: adjustedBackgroundRefresh,
            enableBackgroundFetch: enableBackgroundFetch,
            enableBackgroundURLSessions: enableBackgroundURLSessions,
            maxConcurrentTasks: adjustedConcurrentTasks,
            backgroundFetchInterval: adjustedInterval,
            taskTimeout: adjustedTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableTaskScheduling: enableTaskScheduling,
            enablePriorityManagement: enablePriorityManagement,
            retryFailedTasks: retryFailedTasks
        )
    }
}

// MARK: - Background Processing Types

/// Background task information
public struct BackgroundTask: Sendable, Identifiable, Codable {
    public let id: UUID
    public let identifier: String
    public let type: TaskType
    public let priority: TaskPriority
    public let status: TaskStatus
    public let creationDate: Date
    public let scheduledDate: Date?
    public let executionDate: Date?
    public let completionDate: Date?
    public let expirationDate: Date?
    public let metadata: [String: String]
    public let progress: Double
    public let error: BackgroundProcessingError?
    public let retryCount: Int
    public let maxRetries: Int
    
    public enum TaskType: String, Sendable, Codable, CaseIterable {
        case appRefresh = "app-refresh"
        case backgroundFetch = "background-fetch"
        case processing = "processing"
        case urlSession = "url-session"
        case maintenance = "maintenance"
        case sync = "sync"
        case upload = "upload"
        case download = "download"
    }
    
    public enum TaskPriority: String, Sendable, Codable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public enum TaskStatus: String, Sendable, Codable, CaseIterable {
        case scheduled = "scheduled"
        case queued = "queued"
        case running = "running"
        case completed = "completed"
        case failed = "failed"
        case cancelled = "cancelled"
        case expired = "expired"
    }
    
    public init(
        identifier: String,
        type: TaskType,
        priority: TaskPriority = .normal,
        scheduledDate: Date? = nil,
        expirationDate: Date? = nil,
        metadata: [String: String] = [:],
        maxRetries: Int = 3
    ) {
        self.id = UUID()
        self.identifier = identifier
        self.type = type
        self.priority = priority
        self.status = .scheduled
        self.creationDate = Date()
        self.scheduledDate = scheduledDate
        self.executionDate = nil
        self.completionDate = nil
        self.expirationDate = expirationDate
        self.metadata = metadata
        self.progress = 0.0
        self.error = nil
        self.retryCount = 0
        self.maxRetries = maxRetries
    }
    
    public var isActive: Bool {
        status == .running || status == .queued
    }
    
    public var isFinished: Bool {
        status == .completed || status == .failed || status == .cancelled || status == .expired
    }
    
    public var canRetry: Bool {
        status == .failed && retryCount < maxRetries
    }
    
    public var duration: TimeInterval? {
        guard let start = executionDate, let end = completionDate else { return nil }
        return end.timeIntervalSince(start)
    }
}

/// Background task request
public struct BackgroundTaskRequest: Sendable {
    public let identifier: String
    public let type: BackgroundTask.TaskType
    public let priority: BackgroundTask.TaskPriority
    public let requiresExternalPower: Bool
    public let requiresNetworkConnectivity: Bool
    public let earliestBeginDate: Date?
    public let metadata: [String: String]
    public let handler: @Sendable () async throws -> Void
    
    public init(
        identifier: String,
        type: BackgroundTask.TaskType,
        priority: BackgroundTask.TaskPriority = .normal,
        requiresExternalPower: Bool = false,
        requiresNetworkConnectivity: Bool = false,
        earliestBeginDate: Date? = nil,
        metadata: [String: String] = [:],
        handler: @escaping @Sendable () async throws -> Void
    ) {
        self.identifier = identifier
        self.type = type
        self.priority = priority
        self.requiresExternalPower = requiresExternalPower
        self.requiresNetworkConnectivity = requiresNetworkConnectivity
        self.earliestBeginDate = earliestBeginDate
        self.metadata = metadata
        self.handler = handler
    }
}

/// Background processing metrics
public struct BackgroundProcessingMetrics: Sendable {
    public let totalTasks: Int
    public let completedTasks: Int
    public let failedTasks: Int
    public let cancelledTasks: Int
    public let activeTasks: Int
    public let averageExecutionTime: TimeInterval
    public let successRate: Double
    public let tasksByType: [String: Int]
    public let tasksByPriority: [String: Int]
    public let errorsByType: [String: Int]
    public let backgroundFetchResultCounts: [String: Int]
    public let totalBackgroundTime: TimeInterval
    
    public init(
        totalTasks: Int = 0,
        completedTasks: Int = 0,
        failedTasks: Int = 0,
        cancelledTasks: Int = 0,
        activeTasks: Int = 0,
        averageExecutionTime: TimeInterval = 0,
        successRate: Double = 0,
        tasksByType: [String: Int] = [:],
        tasksByPriority: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        backgroundFetchResultCounts: [String: Int] = [:],
        totalBackgroundTime: TimeInterval = 0
    ) {
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.failedTasks = failedTasks
        self.cancelledTasks = cancelledTasks
        self.activeTasks = activeTasks
        self.averageExecutionTime = averageExecutionTime
        self.successRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0
        self.tasksByType = tasksByType
        self.tasksByPriority = tasksByPriority
        self.errorsByType = errorsByType
        self.backgroundFetchResultCounts = backgroundFetchResultCounts
        self.totalBackgroundTime = totalBackgroundTime
    }
}

// MARK: - Background Processing Resource

/// Background processing resource management
@available(iOS 13.0, macOS 10.15, *)
public actor BackgroundProcessingCapabilityResource: AxiomCapabilityResource {
    private let configuration: BackgroundProcessingCapabilityConfiguration
    private var registeredTasks: [String: BackgroundTask] = [:]
    private var activeTasks: [String: BackgroundTask] = [:]
    private var taskHandlers: [String: @Sendable () async throws -> Void] = [:]
    private var taskHistory: [BackgroundTask] = []
    private var metrics: BackgroundProcessingMetrics = BackgroundProcessingMetrics()
    private var taskStreamContinuation: AsyncStream<BackgroundTask>.Continuation?
    private var backgroundFetchTimer: Timer?
    private var taskQueue: [BackgroundTask] = []
    private var isProcessingQueue: Bool = false
    
    public init(configuration: BackgroundProcessingCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 8_000_000, // 8MB for task management
            cpu: 1.0, // Background processing coordination
            bandwidth: 0,
            storage: 2_000_000 // 2MB for task history
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let taskMemory = registeredTasks.count * 2_000
            let historyMemory = taskHistory.count * 1_000
            let queueMemory = taskQueue.count * 500
            
            return ResourceUsage(
                memory: taskMemory + historyMemory + queueMemory + 500_000,
                cpu: activeTasks.isEmpty ? 0.1 : 0.8,
                bandwidth: 0,
                storage: taskHistory.count * 200
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Background processing is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enableBackgroundProcessing
        }
        return false
    }
    
    public func release() async {
        // Cancel all active tasks
        for task in activeTasks.values {
            await cancelTask(task.identifier)
        }
        
        registeredTasks.removeAll()
        activeTasks.removeAll()
        taskHandlers.removeAll()
        taskHistory.removeAll()
        taskQueue.removeAll()
        
        backgroundFetchTimer?.invalidate()
        backgroundFetchTimer = nil
        
        taskStreamContinuation?.finish()
        
        metrics = BackgroundProcessingMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Setup background task scheduling
        if configuration.enableTaskScheduling {
            await setupBackgroundTaskScheduling()
        }
        
        // Setup background fetch if enabled
        if configuration.enableBackgroundFetch {
            await setupBackgroundFetch()
        }
    }
    
    internal func updateConfiguration(_ configuration: BackgroundProcessingCapabilityConfiguration) async throws {
        // Update background fetch interval if changed
        if configuration.backgroundFetchInterval != self.configuration.backgroundFetchInterval {
            await setupBackgroundFetch()
        }
    }
    
    // MARK: - Task Streams
    
    public var taskStream: AsyncStream<BackgroundTask> {
        AsyncStream { continuation in
            self.taskStreamContinuation = continuation
        }
    }
    
    // MARK: - Task Management
    
    public func registerTask(_ request: BackgroundTaskRequest) async throws {
        guard configuration.enableBackgroundProcessing else {
            throw BackgroundProcessingError.backgroundProcessingDisabled
        }
        
        let task = BackgroundTask(
            identifier: request.identifier,
            type: request.type,
            priority: request.priority,
            scheduledDate: request.earliestBeginDate,
            metadata: request.metadata
        )
        
        registeredTasks[request.identifier] = task
        taskHandlers[request.identifier] = request.handler
        
        if #available(iOS 13.0, macOS 10.15, *) {
            await scheduleBackgroundTask(request)
        }
        
        taskStreamContinuation?.yield(task)
        
        await updateTaskMetrics(task)
        
        if configuration.enableLogging {
            await logTask(task, action: "Registered")
        }
    }
    
    public func unregisterTask(_ identifier: String) async {
        registeredTasks.removeValue(forKey: identifier)
        taskHandlers.removeValue(forKey: identifier)
        
        if #available(iOS 13.0, macOS 10.15, *) {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        }
        
        if configuration.enableLogging {
            print("[BackgroundProcessing] 🗑️ Unregistered task: \(identifier)")
        }
    }
    
    public func executeTask(_ identifier: String) async throws {
        guard let task = registeredTasks[identifier] else {
            throw BackgroundProcessingError.taskNotFound(identifier)
        }
        
        guard let handler = taskHandlers[identifier] else {
            throw BackgroundProcessingError.handlerNotFound(identifier)
        }
        
        guard activeTasks.count < configuration.maxConcurrentTasks else {
            // Add to queue if at capacity
            var queuedTask = task
            queuedTask = BackgroundTask(
                identifier: task.identifier,
                type: task.type,
                priority: task.priority,
                scheduledDate: task.scheduledDate,
                metadata: task.metadata
            )
            taskQueue.append(queuedTask)
            return
        }
        
        let startTime = Date()
        var executingTask = task
        executingTask = BackgroundTask(
            identifier: task.identifier,
            type: task.type,
            priority: task.priority,
            scheduledDate: task.scheduledDate,
            metadata: task.metadata
        )
        
        activeTasks[identifier] = executingTask
        taskStreamContinuation?.yield(executingTask)
        
        do {
            try await handler()
            
            let completedTask = BackgroundTask(
                identifier: task.identifier,
                type: task.type,
                priority: task.priority,
                scheduledDate: task.scheduledDate,
                metadata: task.metadata
            )
            
            taskHistory.append(completedTask)
            activeTasks.removeValue(forKey: identifier)
            
            taskStreamContinuation?.yield(completedTask)
            
            await updateCompletionMetrics(completedTask, duration: Date().timeIntervalSince(startTime))
            
            if configuration.enableLogging {
                await logTask(completedTask, action: "Completed")
            }
            
        } catch {
            let failedTask = BackgroundTask(
                identifier: task.identifier,
                type: task.type,
                priority: task.priority,
                scheduledDate: task.scheduledDate,
                metadata: task.metadata
            )
            
            taskHistory.append(failedTask)
            activeTasks.removeValue(forKey: identifier)
            
            taskStreamContinuation?.yield(failedTask)
            
            await updateFailureMetrics(failedTask, error: error)
            
            if configuration.retryFailedTasks && failedTask.canRetry {
                await scheduleRetry(failedTask)
            }
            
            if configuration.enableLogging {
                await logTask(failedTask, action: "Failed")
            }
            
            throw error
        }
        
        // Process queue if available
        if !isProcessingQueue {
            await processTaskQueue()
        }
    }
    
    public func cancelTask(_ identifier: String) async {
        activeTasks.removeValue(forKey: identifier)
        
        if #available(iOS 13.0, macOS 10.15, *) {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        }
        
        if let task = registeredTasks[identifier] {
            let cancelledTask = BackgroundTask(
                identifier: task.identifier,
                type: task.type,
                priority: task.priority,
                scheduledDate: task.scheduledDate,
                metadata: task.metadata
            )
            
            taskHistory.append(cancelledTask)
            taskStreamContinuation?.yield(cancelledTask)
            
            await updateCancellationMetrics(cancelledTask)
            
            if configuration.enableLogging {
                await logTask(cancelledTask, action: "Cancelled")
            }
        }
    }
    
    public func getRegisteredTasks() async -> [BackgroundTask] {
        return Array(registeredTasks.values)
    }
    
    public func getActiveTasks() async -> [BackgroundTask] {
        return Array(activeTasks.values)
    }
    
    public func getTaskHistory(since: Date? = nil) async -> [BackgroundTask] {
        if let since = since {
            return taskHistory.filter { $0.creationDate >= since }
        }
        return taskHistory
    }
    
    public func getTask(by identifier: String) async -> BackgroundTask? {
        return registeredTasks[identifier] ?? activeTasks[identifier]
    }
    
    // MARK: - Background App Refresh
    
    public func setBackgroundAppRefreshEnabled(_ enabled: Bool) async {
        if #available(iOS 13.0, *) {
            // Note: This would typically involve UIApplication.shared.setMinimumBackgroundFetchInterval
            // For now, we'll track the state internally
        }
        
        if configuration.enableLogging {
            print("[BackgroundProcessing] 🔄 Background app refresh: \(enabled ? "enabled" : "disabled")")
        }
    }
    
    public func performBackgroundFetch() async -> UIBackgroundFetchResult {
        guard configuration.enableBackgroundFetch else {
            return .noData
        }
        
        // Execute background fetch tasks
        let fetchTasks = registeredTasks.values.filter { $0.type == .backgroundFetch }
        var hasNewData = false
        
        for task in fetchTasks {
            do {
                try await executeTask(task.identifier)
                hasNewData = true
            } catch {
                if configuration.enableLogging {
                    print("[BackgroundProcessing] ⚠️ Background fetch failed for \(task.identifier): \(error)")
                }
            }
        }
        
        let result: UIBackgroundFetchResult = hasNewData ? .newData : .noData
        await updateBackgroundFetchMetrics(result)
        
        return result
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> BackgroundProcessingMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = BackgroundProcessingMetrics()
    }
    
    // MARK: - Private Methods
    
    @available(iOS 13.0, macOS 10.15, *)
    private func setupBackgroundTaskScheduling() async {
        // Register for background task handling
        for task in registeredTasks.values {
            await scheduleBackgroundTask(BackgroundTaskRequest(
                identifier: task.identifier,
                type: task.type,
                priority: task.priority,
                metadata: task.metadata,
                handler: taskHandlers[task.identifier] ?? {}
            ))
        }
    }
    
    private func setupBackgroundFetch() async {
        backgroundFetchTimer?.invalidate()
        
        backgroundFetchTimer = Timer.scheduledTimer(withTimeInterval: configuration.backgroundFetchInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                _ = await self?.performBackgroundFetch()
            }
        }
    }
    
    @available(iOS 13.0, macOS 10.15, *)
    private func scheduleBackgroundTask(_ request: BackgroundTaskRequest) async {
        let taskRequest: BGTaskRequest
        
        switch request.type {
        case .appRefresh:
            let appRefreshRequest = BGAppRefreshTaskRequest(identifier: request.identifier)
            appRefreshRequest.earliestBeginDate = request.earliestBeginDate
            taskRequest = appRefreshRequest
            
        case .processing:
            let processingRequest = BGProcessingTaskRequest(identifier: request.identifier)
            processingRequest.requiresNetworkConnectivity = request.requiresNetworkConnectivity
            processingRequest.requiresExternalPower = request.requiresExternalPower
            processingRequest.earliestBeginDate = request.earliestBeginDate
            taskRequest = processingRequest
            
        default:
            // For other types, use app refresh as fallback
            let appRefreshRequest = BGAppRefreshTaskRequest(identifier: request.identifier)
            appRefreshRequest.earliestBeginDate = request.earliestBeginDate
            taskRequest = appRefreshRequest
        }
        
        do {
            try BGTaskScheduler.shared.submit(taskRequest)
            
            if configuration.enableLogging {
                print("[BackgroundProcessing] 📅 Scheduled task: \(request.identifier)")
            }
        } catch {
            if configuration.enableLogging {
                print("[BackgroundProcessing] ⚠️ Failed to schedule task \(request.identifier): \(error)")
            }
        }
    }
    
    private func processTaskQueue() async {
        guard !isProcessingQueue && !taskQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        // Sort queue by priority
        taskQueue.sort { task1, task2 in
            let priority1 = priorityValue(for: task1.priority)
            let priority2 = priorityValue(for: task2.priority)
            return priority1 > priority2
        }
        
        while !taskQueue.isEmpty && activeTasks.count < configuration.maxConcurrentTasks {
            let task = taskQueue.removeFirst()
            
            do {
                try await executeTask(task.identifier)
            } catch {
                if configuration.enableLogging {
                    print("[BackgroundProcessing] ⚠️ Queued task failed: \(task.identifier)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: BackgroundTask.TaskPriority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func scheduleRetry(_ task: BackgroundTask) async {
        guard task.canRetry else { return }
        
        let retryDelay = TimeInterval(pow(2.0, Double(task.retryCount))) // Exponential backoff
        let retryDate = Date().addingTimeInterval(retryDelay)
        
        var retryTask = task
        retryTask = BackgroundTask(
            identifier: task.identifier,
            type: task.type,
            priority: task.priority,
            scheduledDate: retryDate,
            metadata: task.metadata,
            maxRetries: task.maxRetries
        )
        
        registeredTasks[task.identifier] = retryTask
        
        if configuration.enableLogging {
            print("[BackgroundProcessing] 🔄 Scheduled retry for \(task.identifier) in \(retryDelay)s")
        }
    }
    
    private func updateTaskMetrics(_ task: BackgroundTask) async {
        let totalTasks = metrics.totalTasks + 1
        
        var tasksByType = metrics.tasksByType
        tasksByType[task.type.rawValue, default: 0] += 1
        
        var tasksByPriority = metrics.tasksByPriority
        tasksByPriority[task.priority.rawValue, default: 0] += 1
        
        metrics = BackgroundProcessingMetrics(
            totalTasks: totalTasks,
            completedTasks: metrics.completedTasks,
            failedTasks: metrics.failedTasks,
            cancelledTasks: metrics.cancelledTasks,
            activeTasks: activeTasks.count,
            averageExecutionTime: metrics.averageExecutionTime,
            successRate: metrics.successRate,
            tasksByType: tasksByType,
            tasksByPriority: tasksByPriority,
            errorsByType: metrics.errorsByType,
            backgroundFetchResultCounts: metrics.backgroundFetchResultCounts,
            totalBackgroundTime: metrics.totalBackgroundTime
        )
    }
    
    private func updateCompletionMetrics(_ task: BackgroundTask, duration: TimeInterval) async {
        let completedTasks = metrics.completedTasks + 1
        let totalTasks = max(metrics.totalTasks, completedTasks)
        
        let newAverageExecutionTime = ((metrics.averageExecutionTime * Double(metrics.completedTasks)) + duration) / Double(completedTasks)
        
        metrics = BackgroundProcessingMetrics(
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            failedTasks: metrics.failedTasks,
            cancelledTasks: metrics.cancelledTasks,
            activeTasks: activeTasks.count,
            averageExecutionTime: newAverageExecutionTime,
            successRate: totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0,
            tasksByType: metrics.tasksByType,
            tasksByPriority: metrics.tasksByPriority,
            errorsByType: metrics.errorsByType,
            backgroundFetchResultCounts: metrics.backgroundFetchResultCounts,
            totalBackgroundTime: metrics.totalBackgroundTime + duration
        )
    }
    
    private func updateFailureMetrics(_ task: BackgroundTask, error: Error) async {
        let failedTasks = metrics.failedTasks + 1
        
        var errorsByType = metrics.errorsByType
        let errorKey = String(describing: type(of: error))
        errorsByType[errorKey, default: 0] += 1
        
        metrics = BackgroundProcessingMetrics(
            totalTasks: metrics.totalTasks,
            completedTasks: metrics.completedTasks,
            failedTasks: failedTasks,
            cancelledTasks: metrics.cancelledTasks,
            activeTasks: activeTasks.count,
            averageExecutionTime: metrics.averageExecutionTime,
            successRate: metrics.totalTasks > 0 ? Double(metrics.completedTasks) / Double(metrics.totalTasks) : 0,
            tasksByType: metrics.tasksByType,
            tasksByPriority: metrics.tasksByPriority,
            errorsByType: errorsByType,
            backgroundFetchResultCounts: metrics.backgroundFetchResultCounts,
            totalBackgroundTime: metrics.totalBackgroundTime
        )
    }
    
    private func updateCancellationMetrics(_ task: BackgroundTask) async {
        let cancelledTasks = metrics.cancelledTasks + 1
        
        metrics = BackgroundProcessingMetrics(
            totalTasks: metrics.totalTasks,
            completedTasks: metrics.completedTasks,
            failedTasks: metrics.failedTasks,
            cancelledTasks: cancelledTasks,
            activeTasks: activeTasks.count,
            averageExecutionTime: metrics.averageExecutionTime,
            successRate: metrics.totalTasks > 0 ? Double(metrics.completedTasks) / Double(metrics.totalTasks) : 0,
            tasksByType: metrics.tasksByType,
            tasksByPriority: metrics.tasksByPriority,
            errorsByType: metrics.errorsByType,
            backgroundFetchResultCounts: metrics.backgroundFetchResultCounts,
            totalBackgroundTime: metrics.totalBackgroundTime
        )
    }
    
    private func updateBackgroundFetchMetrics(_ result: UIBackgroundFetchResult) async {
        let resultKey = switch result {
        case .newData: "newData"
        case .noData: "noData"
        case .failed: "failed"
        @unknown default: "unknown"
        }
        
        var backgroundFetchResultCounts = metrics.backgroundFetchResultCounts
        backgroundFetchResultCounts[resultKey, default: 0] += 1
        
        metrics = BackgroundProcessingMetrics(
            totalTasks: metrics.totalTasks,
            completedTasks: metrics.completedTasks,
            failedTasks: metrics.failedTasks,
            cancelledTasks: metrics.cancelledTasks,
            activeTasks: activeTasks.count,
            averageExecutionTime: metrics.averageExecutionTime,
            successRate: metrics.successRate,
            tasksByType: metrics.tasksByType,
            tasksByPriority: metrics.tasksByPriority,
            errorsByType: metrics.errorsByType,
            backgroundFetchResultCounts: backgroundFetchResultCounts,
            totalBackgroundTime: metrics.totalBackgroundTime
        )
    }
    
    private func logTask(_ task: BackgroundTask, action: String) async {
        let typeIcon = switch task.type {
        case .appRefresh: "🔄"
        case .backgroundFetch: "📥"
        case .processing: "⚙️"
        case .urlSession: "🌐"
        case .maintenance: "🧹"
        case .sync: "🔄"
        case .upload: "📤"
        case .download: "📥"
        }
        
        let priorityIcon = switch task.priority {
        case .low: "🔵"
        case .normal: "🟢"
        case .high: "🟠"
        case .critical: "🔴"
        }
        
        print("[BackgroundProcessing] \(typeIcon)\(priorityIcon) \(action): \(task.identifier) (\(task.type.rawValue))")
    }
}

// MARK: - Background Processing Capability Implementation

/// Background processing capability providing comprehensive background task management
@available(iOS 13.0, macOS 10.15, *)
public actor BackgroundProcessingCapability: DomainCapability {
    public typealias ConfigurationType = BackgroundProcessingCapabilityConfiguration
    public typealias ResourceType = BackgroundProcessingCapabilityResource
    
    private var _configuration: BackgroundProcessingCapabilityConfiguration
    private var _resources: BackgroundProcessingCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "background-processing-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: BackgroundProcessingCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: BackgroundProcessingCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: BackgroundProcessingCapabilityConfiguration = BackgroundProcessingCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = BackgroundProcessingCapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: BackgroundProcessingCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Background Processing configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        // Background processing is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Background processing permissions are handled through Info.plist and system settings
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Background Processing Operations
    
    /// Register a background task
    public func registerTask(_ request: BackgroundTaskRequest) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Background processing capability not available")
        }
        
        try await _resources.registerTask(request)
    }
    
    /// Unregister a background task
    public func unregisterTask(_ identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Background processing capability not available")
        }
        
        await _resources.unregisterTask(identifier)
    }
    
    /// Execute a background task
    public func executeTask(_ identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Background processing capability not available")
        }
        
        try await _resources.executeTask(identifier)
    }
    
    /// Cancel a background task
    public func cancelTask(_ identifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Background processing capability not available")
        }
        
        await _resources.cancelTask(identifier)
    }
    
    /// Get task stream
    public func getTaskStream() async throws -> AsyncStream<BackgroundTask> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Background processing capability not available")
        }
        
        return await _resources.taskStream
    }
    
    /// Get registered tasks
    public func getRegisteredTasks() async throws -> [BackgroundTask] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Background processing capability not available")
        }
        
        return await _resources.getRegisteredTasks()
    }
    
    /// Get active tasks
    public func getActiveTasks() async throws -> [BackgroundTask] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Background processing capability not available")
        }
        
        return await _resources.getActiveTasks()
    }
    
    /// Get task history
    public func getTaskHistory(since: Date? = nil) async throws -> [BackgroundTask] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Background processing capability not available")
        }
        
        return await _resources.getTaskHistory(since: since)
    }
    
    /// Get specific task
    public func getTask(by identifier: String) async throws -> BackgroundTask? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Background processing capability not available")
        }
        
        return await _resources.getTask(by: identifier)
    }
    
    /// Set background app refresh enabled
    public func setBackgroundAppRefreshEnabled(_ enabled: Bool) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Background processing capability not available")
        }
        
        await _resources.setBackgroundAppRefreshEnabled(enabled)
    }
    
    /// Perform background fetch
    public func performBackgroundFetch() async throws -> UIBackgroundFetchResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Background processing capability not available")
        }
        
        return await _resources.performBackgroundFetch()
    }
    
    /// Get background processing metrics
    public func getMetrics() async throws -> BackgroundProcessingMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Background processing capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Background processing capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Check if background processing is active
    public func hasActiveTasks() async throws -> Bool {
        let activeTasks = try await getActiveTasks()
        return !activeTasks.isEmpty
    }
    
    /// Get task count by type
    public func getTaskCount(for type: BackgroundTask.TaskType) async throws -> Int {
        let tasks = try await getRegisteredTasks()
        return tasks.filter { $0.type == type }.count
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Background processing specific errors
public enum BackgroundProcessingError: Error, LocalizedError {
    case backgroundProcessingDisabled
    case taskNotFound(String)
    case handlerNotFound(String)
    case taskExecutionFailed(String)
    case schedulingFailed(String)
    case tooManyActiveTasks(Int)
    case taskTimeout(String)
    case invalidTaskIdentifier(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .backgroundProcessingDisabled:
            return "Background processing is disabled"
        case .taskNotFound(let identifier):
            return "Background task not found: \(identifier)"
        case .handlerNotFound(let identifier):
            return "Task handler not found: \(identifier)"
        case .taskExecutionFailed(let reason):
            return "Task execution failed: \(reason)"
        case .schedulingFailed(let reason):
            return "Task scheduling failed: \(reason)"
        case .tooManyActiveTasks(let maxTasks):
            return "Too many active tasks (max: \(maxTasks))"
        case .taskTimeout(let identifier):
            return "Task timeout: \(identifier)"
        case .invalidTaskIdentifier(let identifier):
            return "Invalid task identifier: \(identifier)"
        case .configurationError(let reason):
            return "Background processing configuration error: \(reason)"
        }
    }
}