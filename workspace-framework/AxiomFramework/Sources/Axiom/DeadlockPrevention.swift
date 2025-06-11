import Foundation

// MARK: - Deadlock Prevention and Detection System (W-02-004)

/// Resource identifier with global ordering
public struct ResourceIdentifier: Hashable, Comparable, Sendable {
    public let id: UUID
    public let type: ResourceType
    public let orderingKey: UInt64
    
    public init(id: UUID, type: ResourceType, orderingKey: UInt64) {
        self.id = id
        self.type = type
        self.orderingKey = orderingKey
    }
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.orderingKey < rhs.orderingKey
    }
}

/// Resource types for categorization and ordering
public enum ResourceType: String, Sendable {
    case actor
    case data
    case io
    case computation
    case synchronization
}

/// Deadlock cycle information
public struct DeadlockCycle {
    public let actors: [ActorIdentifier]
    public let resources: [ResourceIdentifier]
    
    public init(actors: [ActorIdentifier], resources: [ResourceIdentifier]) {
        self.actors = actors
        self.resources = resources
    }
}

/// Deadlock prevention errors
public enum DeadlockError: Error {
    case orderingViolation(holding: ResourceIdentifier, requesting: ResourceIdentifier)
    case cycleDetected(DeadlockCycle)
    case unrecoverable(DeadlockCycle)
    case timeout(Duration)
}

/// Transaction operation for rollback
public protocol Operation {
    func rollback() async throws
}

/// Resource request for banker's algorithm
public struct ResourceRequest {
    public let actor: ActorIdentifier
    public let resources: [ResourceType: Int]
    
    public init(actor: ActorIdentifier, resources: [ResourceType: Int]) {
        self.actor = actor
        self.resources = resources
    }
}

// MARK: - Enhanced Detection Metrics

/// Enhanced performance metrics for deadlock detection with monitoring
private actor DetectionMetrics {
    private var detections: [(strategy: String, duration: Double, cycleLength: Int)] = []
    private var graphUpdateTimes: [Double] = []
    private var orderValidationTimes: [Double] = []
    private let maxHistorySize = 1000
    
    func recordDetection(strategy: String, duration: Double, cycleLength: Int) {
        detections.append((strategy, duration, cycleLength))
        
        // Trim history if needed
        if detections.count > maxHistorySize {
            detections.removeFirst(detections.count - maxHistorySize)
        }
        
        // Performance warning for detection time
        if duration > 10e-6 { // > 10μs
            print("Warning: Detection time \(duration * 1_000_000)μs exceeds 10μs target")
        }
    }
    
    func recordGraphUpdate(duration: Double) {
        graphUpdateTimes.append(duration)
        
        // Trim history
        if graphUpdateTimes.count > maxHistorySize {
            graphUpdateTimes.removeFirst(graphUpdateTimes.count - maxHistorySize)
        }
        
        // Performance warning for graph updates
        if duration > 1e-6 { // > 1μs
            print("Warning: Graph update time \(duration * 1_000_000)μs exceeds 1μs target")
        }
    }
    
    func recordOrderValidation(duration: Double) {
        orderValidationTimes.append(duration)
        
        // Trim history
        if orderValidationTimes.count > maxHistorySize {
            orderValidationTimes.removeFirst(orderValidationTimes.count - maxHistorySize)
        }
        
        // Performance warning for order validation
        if duration > 1e-6 { // > 1μs
            print("Warning: Order validation time \(duration * 1_000_000)μs exceeds 1μs target")
        }
    }
    
    func getAverageDetectionTime() -> Double {
        guard !detections.isEmpty else { return 0 }
        return detections.map(\.duration).reduce(0, +) / Double(detections.count)
    }
    
    func getAverageGraphUpdateTime() -> Double {
        guard !graphUpdateTimes.isEmpty else { return 0 }
        return graphUpdateTimes.reduce(0, +) / Double(graphUpdateTimes.count)
    }
    
    func getAverageOrderValidationTime() -> Double {
        guard !orderValidationTimes.isEmpty else { return 0 }
        return orderValidationTimes.reduce(0, +) / Double(orderValidationTimes.count)
    }
    
    func getPerformanceStats() -> PerformanceStats {
        return PerformanceStats(
            averageDetectionTime: Duration.seconds(getAverageDetectionTime()),
            averageGraphUpdateTime: Duration.seconds(getAverageGraphUpdateTime()),
            averageOrderValidationTime: Duration.seconds(getAverageOrderValidationTime()),
            meetsDetectionTarget: getAverageDetectionTime() <= 10e-6,
            meetsGraphUpdateTarget: getAverageGraphUpdateTime() <= 1e-6,
            meetsOrderValidationTarget: getAverageOrderValidationTime() <= 1e-6,
            totalDetections: detections.count,
            totalGraphUpdates: graphUpdateTimes.count
        )
    }
}

/// Comprehensive performance statistics
public struct PerformanceStats {
    public let averageDetectionTime: Duration
    public let averageGraphUpdateTime: Duration
    public let averageOrderValidationTime: Duration
    public let meetsDetectionTarget: Bool
    public let meetsGraphUpdateTarget: Bool
    public let meetsOrderValidationTarget: Bool
    public let totalDetections: Int
    public let totalGraphUpdates: Int
}

/// Detection strategy protocol
protocol DetectionStrategy {
    var name: String { get }
    func detect(_ graph: [ActorIdentifier: Set<ActorIdentifier>]) -> DeadlockCycle?
}

// MARK: - Deadlock Prevention Coordinator

/// Enhanced central coordinator for deadlock prevention with performance monitoring
public actor DeadlockPreventionCoordinator {
    private var waitForGraph = WaitForGraph()
    private var resourceOwnership: [ResourceIdentifier: ActorIdentifier] = [:]
    private var actorResources: [ActorIdentifier: Set<ResourceIdentifier>] = [:]
    private let detector = DeadlockDetector()
    private let transactionLog = TransactionLog()
    private var acquisitionOrder: [ActorIdentifier: [ResourceIdentifier]] = [:]
    private var detectionStats = DetectionStats()
    private var metrics = DetectionMetrics()
    
    // Performance optimization: Pre-computed ordering cache
    private var orderingCache: [Set<ResourceIdentifier>: [ResourceIdentifier]] = [:]
    private let maxCacheSize = 1000
    
    public init() {}
    
    /// Request resources with ordering enforcement
    public func requestResources(
        _ resources: Set<ResourceIdentifier>,
        for actor: ActorIdentifier,
        timeout: Duration = .seconds(1)
    ) async throws -> ResourceLease {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Get currently held resources
        let heldResources = actorResources[actor] ?? []
        
        // Validate ordering
        try validateResourceOrdering(resources, holding: heldResources)
        
        // Add to wait-for graph
        await waitForGraph.addWaitingFor(actor: actor, resources: resources)
        
        // Check for potential deadlock
        if let cycle = await detector.detectCycle(in: waitForGraph) {
            await waitForGraph.removeWaitingFor(actor: actor)
            throw DeadlockError.cycleDetected(cycle)
        }
        
        // Try to acquire with timeout
        do {
            return try await withTimeout(timeout) {
                try await self.acquireResources(resources, for: actor)
            }
        } catch {
            await waitForGraph.removeWaitingFor(actor: actor)
            throw error
        }
    }
    
    /// Acquire resources in order
    private func acquireResources(
        _ resources: Set<ResourceIdentifier>,
        for actor: ActorIdentifier
    ) async throws -> ResourceLease {
        // Sort resources by ordering key
        let sortedResources = resources.sorted()
        var acquired: [ResourceIdentifier] = []
        
        do {
            for resource in sortedResources {
                try await acquireResource(resource, for: actor)
                acquired.append(resource)
            }
            
            // Record acquisition order
            acquisitionOrder[actor] = sortedResources
            
            // Remove from wait-for graph
            await waitForGraph.removeWaitingFor(actor: actor)
            
            return ResourceLease(
                resources: Set(acquired),
                actor: actor,
                coordinator: self
            )
        } catch {
            // Rollback on failure
            for resource in acquired.reversed() {
                await releaseResource(resource, from: actor)
            }
            throw error
        }
    }
    
    /// Acquire single resource
    private func acquireResource(
        _ resource: ResourceIdentifier,
        for actor: ActorIdentifier
    ) async throws {
        // Check if resource is available
        if let currentOwner = resourceOwnership[resource] {
            if currentOwner != actor {
                // Resource is owned by another actor - wait or fail
                throw DeadlockError.timeout(.milliseconds(100))
            }
        }
        
        // Acquire resource
        resourceOwnership[resource] = actor
        actorResources[actor, default: []].insert(resource)
        
        // Update wait-for graph
        await waitForGraph.setOwnership(resource: resource, owner: actor)
    }
    
    /// Release resource
    public func releaseResource(
        _ resource: ResourceIdentifier,
        from actor: ActorIdentifier
    ) async {
        resourceOwnership.removeValue(forKey: resource)
        actorResources[actor]?.remove(resource)
        
        // Clean up if no resources held
        if actorResources[actor]?.isEmpty == true {
            actorResources.removeValue(forKey: actor)
            acquisitionOrder.removeValue(forKey: actor)
        }
    }
    
    /// Enhanced validate resource ordering with performance tracking
    public func validateResourceOrdering(
        _ requested: Set<ResourceIdentifier>,
        holding: Set<ResourceIdentifier>
    ) throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            Task {
                await metrics.recordOrderValidation(duration: duration)
            }
        }
        
        guard let maxHeld = holding.max() else { return }
        guard let minRequested = requested.min() else { return }
        
        if maxHeld > minRequested {
            throw DeadlockError.orderingViolation(
                holding: maxHeld,
                requesting: minRequested
            )
        }
    }
    
    /// Get held resources for actor
    public func getHeldResources(for actor: ActorIdentifier) -> Set<ResourceIdentifier> {
        return actorResources[actor] ?? []
    }
    
    /// Get acquisition order for actor
    public func getAcquisitionOrder(for actor: ActorIdentifier) -> [ResourceIdentifier] {
        return acquisitionOrder[actor] ?? []
    }
    
    /// Get detection statistics
    public func getDetectionStats() -> DetectionStats {
        return detectionStats
    }
    
    /// Get comprehensive performance statistics
    public func getPerformanceStats() async -> PerformanceStats {
        return await metrics.getPerformanceStats()
    }
    
    /// Optimized resource ordering with caching
    private func getOptimizedOrdering(_ resources: Set<ResourceIdentifier>) -> [ResourceIdentifier] {
        // Check cache first
        if let cached = orderingCache[resources] {
            return cached
        }
        
        // Compute ordering
        let sorted = resources.sorted()
        
        // Cache result (with size limit)
        if orderingCache.count < maxCacheSize {
            orderingCache[resources] = sorted
        } else {
            // Simple cache eviction - remove random entry
            if let randomKey = orderingCache.keys.randomElement() {
                orderingCache.removeValue(forKey: randomKey)
            }
            orderingCache[resources] = sorted
        }
        
        return sorted
    }
}

/// Detection statistics
public struct DetectionStats {
    public var deadlocksDetected: Int = 0
    public var cyclesDetected: Int = 0
    public var averageDetectionTime: Duration = .zero
    
    public init() {}
}

// MARK: - Wait-For Graph

/// Enhanced wait-for graph for cycle detection with performance tracking
public actor WaitForGraph {
    private var edges: [ActorIdentifier: Set<ActorIdentifier>] = [:]
    private var resourceWaiters: [ResourceIdentifier: Set<ActorIdentifier>] = [:]
    private var resourceOwners: [ResourceIdentifier: ActorIdentifier] = [:]
    private var metrics = DetectionMetrics()
    
    // Performance optimization: Track graph modification count for pruning
    private var modificationCount: Int = 0
    private let pruningThreshold = 1000
    
    public init() {}
    
    public func addWaitingFor(
        actor: ActorIdentifier,
        resources: Set<ResourceIdentifier>
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for resource in resources {
            // Add to waiters
            resourceWaiters[resource, default: []].insert(actor)
            
            // If resource is owned, add edge
            if let owner = resourceOwners[resource] {
                edges[actor, default: []].insert(owner)
            }
        }
        
        // Track modification and performance
        modificationCount += 1
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        Task {
            await metrics.recordGraphUpdate(duration: duration)
        }
        
        // Trigger pruning if threshold reached
        if modificationCount >= pruningThreshold {
            pruneGraph()
        }
    }
    
    public func setOwnership(
        resource: ResourceIdentifier,
        owner: ActorIdentifier
    ) {
        resourceOwners[resource] = owner
        
        // Update edges for waiters
        if let waiters = resourceWaiters[resource] {
            for waiter in waiters {
                edges[waiter, default: []].insert(owner)
            }
        }
    }
    
    public func removeWaitingFor(actor: ActorIdentifier) {
        edges.removeValue(forKey: actor)
        
        // Remove from all waiter lists
        for (resource, var waiters) in resourceWaiters {
            waiters.remove(actor)
            if waiters.isEmpty {
                resourceWaiters.removeValue(forKey: resource)
            } else {
                resourceWaiters[resource] = waiters
            }
        }
    }
    
    public func getGraph() -> [ActorIdentifier: Set<ActorIdentifier>] {
        edges
    }
    
    /// Prune graph to remove stale entries and improve performance
    private func pruneGraph() {
        // Remove empty waiter sets
        resourceWaiters = resourceWaiters.compactMapValues { waiters in
            waiters.isEmpty ? nil : waiters
        }
        
        // Remove empty edge sets
        edges = edges.compactMapValues { neighbors in
            neighbors.isEmpty ? nil : neighbors
        }
        
        // Reset modification counter
        modificationCount = 0
    }
    
    /// Get graph statistics for monitoring
    public func getGraphStats() -> GraphStats {
        return GraphStats(
            totalEdges: edges.values.map(\.count).reduce(0, +),
            totalNodes: edges.count,
            totalResources: resourceOwners.count,
            totalWaiters: resourceWaiters.values.map(\.count).reduce(0, +)
        )
    }
}

/// Graph statistics for monitoring
public struct GraphStats {
    public let totalEdges: Int
    public let totalNodes: Int
    public let totalResources: Int
    public let totalWaiters: Int
}

// MARK: - Deadlock Detector

/// Deadlock detector with multiple strategies
public actor DeadlockDetector {
    private let strategies: [DetectionStrategy] = [
        CycleDetectionStrategy()
    ]
    private var detectionMetrics = DetectionMetrics()
    
    public init() {}
    
    public func detectCycle(in graph: WaitForGraph) async -> DeadlockCycle? {
        let adjacencyList = await graph.getGraph()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Try each strategy
        for strategy in strategies {
            if let cycle = strategy.detect(adjacencyList) {
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                await detectionMetrics.recordDetection(
                    strategy: strategy.name,
                    duration: duration,
                    cycleLength: cycle.actors.count
                )
                return cycle
            }
        }
        
        return nil
    }
}

// MARK: - Cycle Detection Strategy

/// DFS-based cycle detection strategy
struct CycleDetectionStrategy: DetectionStrategy {
    let name = "DFS Cycle Detection"
    
    func detect(_ graph: [ActorIdentifier: Set<ActorIdentifier>]) -> DeadlockCycle? {
        var visited = Set<ActorIdentifier>()
        var recursionStack = Set<ActorIdentifier>()
        var path: [ActorIdentifier] = []
        
        func dfs(_ node: ActorIdentifier) -> DeadlockCycle? {
            visited.insert(node)
            recursionStack.insert(node)
            path.append(node)
            
            if let neighbors = graph[node] {
                for neighbor in neighbors {
                    if !visited.contains(neighbor) {
                        if let cycle = dfs(neighbor) {
                            return cycle
                        }
                    } else if recursionStack.contains(neighbor) {
                        // Found cycle
                        if let startIndex = path.firstIndex(of: neighbor) {
                            let cyclePath = Array(path[startIndex...])
                            return DeadlockCycle(
                                actors: cyclePath,
                                resources: findResourcesInCycle(cyclePath)
                            )
                        }
                    }
                }
            }
            
            recursionStack.remove(node)
            path.removeLast()
            return nil
        }
        
        // Check all nodes
        for node in graph.keys {
            if !visited.contains(node) {
                if let cycle = dfs(node) {
                    return cycle
                }
            }
        }
        
        return nil
    }
    
    private func findResourcesInCycle(_ actors: [ActorIdentifier]) -> [ResourceIdentifier] {
        // Simplified - return empty array for MVP
        return []
    }
}

// MARK: - Resource Lease

/// Resource lease with automatic cleanup
public struct ResourceLease: Sendable {
    public let resources: Set<ResourceIdentifier>
    public let actor: ActorIdentifier
    private let coordinator: DeadlockPreventionCoordinator
    
    public init(
        resources: Set<ResourceIdentifier>,
        actor: ActorIdentifier,
        coordinator: DeadlockPreventionCoordinator
    ) {
        self.resources = resources
        self.actor = actor
        self.coordinator = coordinator
    }
    
    /// Release resources in reverse order
    public func release() async {
        let sortedResources = resources.sorted().reversed()
        for resource in sortedResources {
            await coordinator.releaseResource(resource, from: actor)
        }
    }
}

// MARK: - Recovery System

/// Recovery statistics
public struct RecoveryStats {
    public let totalRecoveries: Int
    public let successfulRecoveries: Int
    
    public init(totalRecoveries: Int, successfulRecoveries: Int) {
        self.totalRecoveries = totalRecoveries
        self.successfulRecoveries = successfulRecoveries
    }
}

/// Deadlock recovery strategy protocol
protocol DeadlockRecoveryStrategy {
    func canRecover(_ cycle: DeadlockCycle) async -> Bool
    func recover(_ cycle: DeadlockCycle, coordinator: DeadlockPreventionCoordinator) async throws
}

/// Deadlock recovery coordinator
public actor DeadlockRecovery {
    private let preventionCoordinator: DeadlockPreventionCoordinator
    private var recoveryStrategies: [DeadlockRecoveryStrategy] = []
    private var totalRecoveries: Int = 0
    private var successfulRecoveries: Int = 0
    
    public init(coordinator: DeadlockPreventionCoordinator = DeadlockPreventionCoordinator()) {
        self.preventionCoordinator = coordinator
        self.recoveryStrategies = [
            VictimSelectionStrategy(),
            TransactionRollbackStrategy(),
            ResourcePreemptionStrategy()
        ]
    }
    
    public func recoverFromDeadlock(_ cycle: DeadlockCycle) async throws {
        totalRecoveries += 1
        
        // Try recovery strategies in order
        for strategy in recoveryStrategies {
            if await strategy.canRecover(cycle) {
                try await strategy.recover(cycle, coordinator: preventionCoordinator)
                successfulRecoveries += 1
                return
            }
        }
        
        throw DeadlockError.unrecoverable(cycle)
    }
    
    public func getRecoveryStats() -> RecoveryStats {
        return RecoveryStats(
            totalRecoveries: totalRecoveries,
            successfulRecoveries: successfulRecoveries
        )
    }
}

/// Simple victim selection strategy
struct VictimSelectionStrategy: DeadlockRecoveryStrategy {
    func canRecover(_ cycle: DeadlockCycle) async -> Bool {
        return !cycle.actors.isEmpty
    }
    
    func recover(_ cycle: DeadlockCycle, coordinator: DeadlockPreventionCoordinator) async throws {
        // Simple strategy: release resources from first actor in cycle
        if let victim = cycle.actors.first {
            let resources = await coordinator.getHeldResources(for: victim)
            for resource in resources {
                await coordinator.releaseResource(resource, from: victim)
            }
        }
    }
}

// MARK: - Transaction System

/// Transaction operation wrapper
private struct TestOperation: Operation {
    let action: () async throws -> Void
    
    func rollback() async throws {
        // Simplified rollback for MVP
        try await action()
    }
}

/// Checkpoint information
public struct Checkpoint {
    public let id: UUID
    public let timestamp: Date
    public let state: Any
    
    public init(id: UUID, timestamp: Date, state: Any) {
        self.id = id
        self.timestamp = timestamp
        self.state = state
    }
}

public typealias CheckpointID = UUID

/// Transaction errors
public enum TransactionError: Error {
    case notFound(UUID)
    case invalidOperation
}

/// Transaction log for rollback
public actor TransactionLog {
    private var transactions: [UUID: Transaction] = [:]
    
    public init() {}
    
    public struct Transaction {
        let id: UUID
        let actor: ActorIdentifier
        let startTime: Date
        var operations: [Operation] = []
        var checkpoints: [Checkpoint] = []
    }
    
    public func beginTransaction(for actor: ActorIdentifier) -> UUID {
        let id = UUID()
        transactions[id] = Transaction(
            id: id,
            actor: actor,
            startTime: Date()
        )
        return id
    }
    
    public func addOperation(to transactionID: UUID, operation: Operation) async {
        transactions[transactionID]?.operations.append(operation)
    }
    
    public func checkpoint(transactionID: UUID, state: Any) async -> CheckpointID {
        let checkpoint = Checkpoint(
            id: UUID(),
            timestamp: Date(),
            state: state
        )
        transactions[transactionID]?.checkpoints.append(checkpoint)
        return checkpoint.id
    }
    
    public func rollback(transactionID: UUID, to checkpoint: CheckpointID? = nil) async throws {
        guard let transaction = transactions[transactionID] else {
            throw TransactionError.notFound(transactionID)
        }
        
        // Find rollback point
        let rollbackPoint: Int
        if let checkpoint = checkpoint,
           let _ = transaction.checkpoints.firstIndex(where: { $0.id == checkpoint }) {
            rollbackPoint = transaction.operations.count // Simplified
        } else {
            rollbackPoint = 0 // Full rollback
        }
        
        // Rollback operations in reverse order
        for operation in transaction.operations[rollbackPoint...].reversed() {
            try await operation.rollback()
        }
    }
    
    public func getTransaction(_ transactionID: UUID) -> Transaction? {
        return transactions[transactionID]
    }
}

// MARK: - Banker's Algorithm

/// Banker's algorithm for deadlock avoidance
public actor BankersAlgorithm {
    private var available: [ResourceType: Int] = [:]
    private var maximum: [ActorIdentifier: [ResourceType: Int]] = [:]
    private var allocation: [ActorIdentifier: [ResourceType: Int]] = [:]
    
    public init() {}
    
    public func setAvailable(resources: [ResourceType: Int]) {
        available = resources
    }
    
    public func setMaximum(for actor: ActorIdentifier, resources: [ResourceType: Int]) {
        maximum[actor] = resources
    }
    
    public func setAllocation(for actor: ActorIdentifier, resources: [ResourceType: Int]) {
        allocation[actor] = resources
    }
    
    public func isSafeState(after request: ResourceRequest) async -> Bool {
        // Simulate allocation
        var testAvailable = available
        var testAllocation = allocation
        
        // Apply request
        for (type, count) in request.resources {
            testAvailable[type, default: 0] -= count
            testAllocation[request.actor, default: [:]][type, default: 0] += count
        }
        
        // Check if resulting state is safe
        return checkSafeSequence(
            available: testAvailable,
            allocation: testAllocation,
            maximum: maximum
        )
    }
    
    private func checkSafeSequence(
        available: [ResourceType: Int],
        allocation: [ActorIdentifier: [ResourceType: Int]],
        maximum: [ActorIdentifier: [ResourceType: Int]]
    ) -> Bool {
        var work = available
        var finish = Set<ActorIdentifier>()
        
        while finish.count < allocation.count {
            var found = false
            
            for (actor, alloc) in allocation where !finish.contains(actor) {
                let need = calculateNeed(
                    maximum: maximum[actor] ?? [:],
                    allocation: alloc
                )
                
                if canSatisfy(need: need, available: work) {
                    // Release resources
                    for (type, count) in alloc {
                        work[type, default: 0] += count
                    }
                    finish.insert(actor)
                    found = true
                    break
                }
            }
            
            if !found {
                return false // No safe sequence exists
            }
        }
        
        return true
    }
    
    private func calculateNeed(
        maximum: [ResourceType: Int],
        allocation: [ResourceType: Int]
    ) -> [ResourceType: Int] {
        var need: [ResourceType: Int] = [:]
        for (type, max) in maximum {
            need[type] = max - (allocation[type] ?? 0)
        }
        return need
    }
    
    private func canSatisfy(
        need: [ResourceType: Int],
        available: [ResourceType: Int]
    ) -> Bool {
        for (type, needed) in need {
            if needed > (available[type] ?? 0) {
                return false
            }
        }
        return true
    }
}

// MARK: - Timeout Utility

// MARK: - Enhanced Recovery Strategies

/// Transaction rollback recovery strategy
struct TransactionRollbackStrategy: DeadlockRecoveryStrategy {
    func canRecover(_ cycle: DeadlockCycle) async -> Bool {
        // Can recover if actors have active transactions
        return !cycle.actors.isEmpty
    }
    
    func recover(_ cycle: DeadlockCycle, coordinator: DeadlockPreventionCoordinator) async throws {
        // Simple strategy: release resources from actor with most resources
        var maxResources = 0
        var victim: ActorIdentifier?
        
        for actor in cycle.actors {
            let resources = await coordinator.getHeldResources(for: actor)
            if resources.count > maxResources {
                maxResources = resources.count
                victim = actor
            }
        }
        
        if let victim = victim {
            let resources = await coordinator.getHeldResources(for: victim)
            for resource in resources {
                await coordinator.releaseResource(resource, from: victim)
            }
        }
    }
}

/// Resource preemption recovery strategy
struct ResourcePreemptionStrategy: DeadlockRecoveryStrategy {
    func canRecover(_ cycle: DeadlockCycle) async -> Bool {
        // Can always attempt preemption as last resort
        return true
    }
    
    func recover(_ cycle: DeadlockCycle, coordinator: DeadlockPreventionCoordinator) async throws {
        // Preempt resources from lowest priority actor (simplified)
        if let victim = cycle.actors.first {
            let resources = await coordinator.getHeldResources(for: victim)
            for resource in resources {
                await coordinator.releaseResource(resource, from: victim)
            }
        }
    }
}

// MARK: - Timeout Utility

/// Execute with timeout (reusing from structured concurrency)
private func withTimeout<T>(
    _ timeout: Duration,
    operation: @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(for: timeout)
            throw DeadlockError.timeout(timeout)
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}