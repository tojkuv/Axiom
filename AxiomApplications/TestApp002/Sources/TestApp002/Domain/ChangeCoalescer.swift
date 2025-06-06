import Foundation

// REFACTOR Phase: Change Coalescing and Advanced Batching
// Implements intelligent batching and coalescing of state changes

/// Represents a coalesced change that combines multiple updates
struct CoalescedChange<Action>: Sendable where Action: Sendable {
    let actions: [Action]
    let timestamp: Date
    let priority: OperationPriority
}

/// Intelligent change coalescer that merges redundant updates
actor ChangeCoalescer<Action: Hashable & Sendable> {
    private var pendingChanges: [Action] = []
    private var coalescingTimer: Timer?
    private let coalescingWindow: TimeInterval
    private let maxBatchSize: Int
    
    init(coalescingWindow: TimeInterval = 0.008, maxBatchSize: Int = 20) {
        self.coalescingWindow = coalescingWindow
        self.maxBatchSize = maxBatchSize
    }
    
    /// Add a change to be coalesced
    func addChange(_ action: Action) async -> CoalescedChange<Action>? {
        pendingChanges.append(action)
        
        // If we hit max batch size, process immediately
        if pendingChanges.count >= maxBatchSize {
            return await processChanges()
        }
        
        // Otherwise wait for coalescence window
        return nil
    }
    
    /// Process and coalesce pending changes
    private func processChanges() async -> CoalescedChange<Action> {
        let changes = pendingChanges
        pendingChanges.removeAll()
        
        // Coalesce changes - remove duplicates and merge related
        let coalescedActions = coalesceActions(changes)
        
        return CoalescedChange(
            actions: coalescedActions,
            timestamp: Date(),
            priority: determinePriority(for: coalescedActions)
        )
    }
    
    /// Intelligently coalesce actions
    private func coalesceActions(_ actions: [Action]) -> [Action] {
        var coalesced: [Action] = []
        var seen = Set<Int>()
        
        // Process in reverse order to keep latest updates
        for action in actions.reversed() {
            let hash = action.hashValue
            if !seen.contains(hash) {
                seen.insert(hash)
                coalesced.insert(action, at: 0)
            }
        }
        
        return coalesced
    }
    
    /// Determine priority for coalesced batch
    private func determinePriority(for actions: [Action]) -> OperationPriority {
        // If any action is critical, the whole batch is critical
        return actions.isEmpty ? .normal : .high
    }
}

// MARK: - TaskAction Coalescing

extension TaskAction: Hashable {
    static func == (lhs: TaskAction, rhs: TaskAction) -> Bool {
        switch (lhs, rhs) {
        case (.create(let l), .create(let r)):
            return l.id == r.id
        case (.update(let l), .update(let r)):
            return l.id == r.id
        case (.delete(let l), .delete(let r)):
            return l == r
        case (.deleteMultiple(let l), .deleteMultiple(let r)):
            return l == r
        case (.search(let l), .search(let r)):
            return l == r
        case (.sort(let l), .sort(let r)):
            return l == r
        case (.filterByCategory(let l), .filterByCategory(let r)):
            return l == r
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .create(let task):
            hasher.combine("create")
            hasher.combine(task.id)
        case .update(let task):
            hasher.combine("update")
            hasher.combine(task.id)
        case .delete(let taskId):
            hasher.combine("delete")
            hasher.combine(taskId)
        case .deleteMultiple(let taskIds):
            hasher.combine("deleteMultiple")
            hasher.combine(taskIds)
        case .search(let query):
            hasher.combine("search")
            hasher.combine(query)
        case .sort(let criteria):
            hasher.combine("sort")
            hasher.combine(criteria)
        case .filterByCategory(let categoryId):
            hasher.combine("filter")
            hasher.combine(categoryId)
        default:
            hasher.combine(String(describing: self))
        }
    }
}

/// Specialized coalescer for TaskActions with domain-specific logic
actor TaskActionCoalescer {
    private let baseCoalescer = ChangeCoalescer<TaskAction>()
    
    /// Add action with intelligent coalescing
    func addAction(_ action: TaskAction) async -> [TaskAction]? {
        if let coalesced = await baseCoalescer.addChange(action) {
            return optimizeActionSequence(coalesced.actions)
        }
        return nil
    }
    
    /// Optimize action sequence for better performance
    private func optimizeActionSequence(_ actions: [TaskAction]) -> [TaskAction] {
        var optimized: [TaskAction] = []
        var taskUpdates: [String: Task] = [:] // Track latest update per task
        var deletedTasks = Set<String>()
        var lastSearch: String?
        var lastSort: SortCriteria?
        var lastFilter: String??
        
        // Process actions to coalesce
        for action in actions {
            switch action {
            case .create(let task):
                if !deletedTasks.contains(task.id) {
                    taskUpdates[task.id] = task
                }
                
            case .update(let task):
                if !deletedTasks.contains(task.id) {
                    taskUpdates[task.id] = task
                }
                
            case .delete(let taskId):
                deletedTasks.insert(taskId)
                taskUpdates.removeValue(forKey: taskId)
                
            case .search(let query):
                lastSearch = query
                
            case .sort(let criteria):
                lastSort = criteria
                
            case .filterByCategory(let categoryId):
                lastFilter = categoryId
                
            default:
                optimized.append(action)
            }
        }
        
        // Build optimized sequence
        // 1. All creates/updates (coalesced)
        for (_, task) in taskUpdates {
            optimized.append(.update(task))
        }
        
        // 2. All deletes
        for taskId in deletedTasks {
            optimized.append(.delete(taskId: taskId))
        }
        
        // 3. Last search/sort/filter only
        if let search = lastSearch {
            optimized.append(.search(query: search))
        }
        if let sort = lastSort {
            optimized.append(.sort(by: sort))
        }
        if let filter = lastFilter {
            optimized.append(.filterByCategory(categoryId: filter))
        }
        
        return optimized
    }
}

// MARK: - Batched State Updater

/// Coordinates batched state updates with coalescing
actor BatchedStateUpdater {
    private let optimizer = StatePropagationOptimizer()
    private let coalescer = TaskActionCoalescer()
    private var updateTimer: Timer?
    private let batchInterval: TimeInterval = 0.008 // 8ms batching window
    
    /// Process action with batching and coalescing
    func processAction(_ action: TaskAction, on client: TaskClient) async throws {
        // Add to coalescer
        if let optimizedActions = await coalescer.addAction(action) {
            // Process optimized batch
            for optimizedAction in optimizedActions {
                try await client.process(optimizedAction)
            }
        }
    }
    
    /// Force process any pending actions
    func flush(on client: TaskClient) async throws {
        // Force coalescer to process
        if let optimizedActions = await coalescer.addAction(.search(query: "")) {
            for action in optimizedActions.dropLast() { // Skip dummy search
                try await client.process(action)
            }
        }
    }
}

// MARK: - Performance Monitor

/// Monitors and reports state propagation performance
actor PerformanceMonitor {
    private var metrics: [PropagationMetric] = []
    private let metricsLimit = 1000
    
    struct PropagationMetric {
        let actionType: String
        let duration: TimeInterval
        let timestamp: Date
        let batchSize: Int
    }
    
    /// Record a propagation metric
    func recordMetric(action: String, duration: TimeInterval, batchSize: Int = 1) {
        let metric = PropagationMetric(
            actionType: action,
            duration: duration,
            timestamp: Date(),
            batchSize: batchSize
        )
        
        metrics.append(metric)
        
        // Keep only recent metrics
        if metrics.count > metricsLimit {
            metrics.removeFirst(metrics.count - metricsLimit)
        }
        
        // Log slow propagations
        if duration > 16.0 {
            print("⚠️ Slow propagation: \(action) took \(duration)ms (batch: \(batchSize))")
        }
    }
    
    /// Get performance summary
    func performanceSummary() -> (average: TimeInterval, p95: TimeInterval, p99: TimeInterval) {
        guard !metrics.isEmpty else { return (0, 0, 0) }
        
        let durations = metrics.map { $0.duration }.sorted()
        let average = durations.reduce(0, +) / Double(durations.count)
        
        let p95Index = Int(Double(durations.count) * 0.95)
        let p99Index = Int(Double(durations.count) * 0.99)
        
        let p95 = durations[min(p95Index, durations.count - 1)]
        let p99 = durations[min(p99Index, durations.count - 1)]
        
        return (average, p95, p99)
    }
    
    /// Get metrics for specific action type
    func metricsForAction(_ actionType: String) -> [PropagationMetric] {
        return metrics.filter { $0.actionType == actionType }
    }
}