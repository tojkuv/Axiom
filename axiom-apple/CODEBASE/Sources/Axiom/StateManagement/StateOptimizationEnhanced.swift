import Foundation

// MARK: - Advanced COW System (REQUIREMENTS-W-01-004)

/// Enhanced COW container with metrics and optimization
public struct OptimizedCOWContainer<Value> {
    private var storage: OptimizedCOWStorage<Value>
    public private(set) var metrics: COWMetrics
    public var currentOptimizer: COWOptimizer {
        storage.optimizer
    }
    
    public init(_ value: Value) {
        self.storage = OptimizedCOWStorage(value, optimizer: .automatic)
        self.metrics = COWMetrics()
    }
    
    /// Optimized access with metrics
    public var value: Value {
        mutating get {
            metrics.recordRead()
            return storage.value
        }
        set {
            let wasUnique = isKnownUniquelyReferenced(&storage)
            if !wasUnique {
                storage = storage.copy()
            }
            storage.value = newValue
            metrics.recordWrite(wasUnique: wasUnique)
        }
    }
    
    /// Batch mutations with single COW
    @discardableResult
    public mutating func batchMutate<T>(
        _ mutations: [(inout Value) throws -> T]
    ) throws -> [T] {
        if !isKnownUniquelyReferenced(&storage) {
            storage = storage.copy()
        }
        return try mutations.map { try $0(&storage.value) }
    }
    
    /// Predictive COW based on patterns
    public mutating func optimizeForPattern(_ pattern: MutationPattern) {
        switch pattern {
        case .readHeavy:
            storage.optimizer = .lazyClone
        case .writeHeavy:
            storage.optimizer = .eagerClone
        case .mixed:
            storage.optimizer = .adaptive
        }
    }
}

/// COW storage implementation
final class OptimizedCOWStorage<Value> {
    var value: Value
    var optimizer: COWOptimizer
    
    init(_ value: Value, optimizer: COWOptimizer) {
        self.value = value
        self.optimizer = optimizer
    }
    
    func copy() -> OptimizedCOWStorage<Value> {
        return OptimizedCOWStorage(value, optimizer: optimizer)
    }
}

/// COW optimization strategies
public enum COWOptimizer: Sendable {
    case automatic
    case lazyClone
    case eagerClone
    case adaptive
}

/// Mutation patterns for optimization
public enum MutationPattern {
    case readHeavy
    case writeHeavy
    case mixed
}

/// COW metrics for optimization decisions
public struct COWMetrics {
    public private(set) var totalReads: Int = 0
    public private(set) var totalWrites: Int = 0
    public private(set) var uniqueWrites: Int = 0
    public private(set) var clonedWrites: Int = 0
    
    public var sharingRatio: Double {
        guard totalWrites > 0 else { return 1.0 }
        return Double(uniqueWrites) / Double(totalWrites)
    }
    
    public var recommendation: COWOptimizer {
        let readWriteRatio = Double(totalReads) / max(Double(totalWrites), 1.0)
        
        switch readWriteRatio {
        case 0..<10: return .eagerClone
        case 10..<100: return .adaptive
        default: return .lazyClone
        }
    }
    
    mutating func recordRead() {
        totalReads += 1
    }
    
    mutating func recordWrite(wasUnique: Bool) {
        totalWrites += 1
        if wasUnique {
            uniqueWrites += 1
        } else {
            clonedWrites += 1
        }
    }
}

// MARK: - Intelligent Batching System (REQUIREMENTS-W-01-004)

/// Update priorities for batch coordination
public enum UpdatePriority: Int, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    public static func < (lhs: UpdatePriority, rhs: UpdatePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Performance targets for optimization
public enum PerformanceTarget {
    case fps60
    case fps30
    case custom(maxLatency: TimeInterval, batchingThreshold: Double)
    
    var maxLatency: TimeInterval {
        switch self {
        case .fps60: return 0.016 // 16ms
        case .fps30: return 0.033 // 33ms
        case .custom(let latency, _): return latency
        }
    }
    
    var batchingThreshold: Double {
        switch self {
        case .fps60: return 60.0
        case .fps30: return 30.0
        case .custom(_, let threshold): return threshold
        }
    }
}

/// Batching decision types
enum BatchingDecision {
    case immediate
    case batch(delay: TimeInterval)
    case deferred
}

/// Adaptive batch coordinator for intelligent update batching
public actor AdaptiveBatchCoordinator<S: AxiomState> {
    private let predictor: UpdatePredictor
    private var priorityQueue: PriorityQueue<BatchedUpdate<S>>
    private var currentBatch: UpdateBatch<S>?
    private let performanceTarget: PerformanceTarget
    private var currentState: S
    
    public init(initialState: S, target: PerformanceTarget = .fps60) {
        self.currentState = initialState
        self.predictor = UpdatePredictor()
        self.priorityQueue = PriorityQueue { $0.priority > $1.priority }
        self.performanceTarget = target
    }
    
    /// Enqueue update with automatic batching decision
    public func enqueue(
        _ update: @escaping (inout S) -> Void,
        priority: UpdatePriority = .normal,
        deadline: Date? = nil
    ) async {
        let batchDecision = await decideBatching(priority: priority, deadline: deadline)
        
        switch batchDecision {
        case .immediate:
            await executeImmediate(update)
        case .batch(let delay):
            await addToBatch(update, priority: priority, delay: delay)
        case .deferred:
            priorityQueue.insert(BatchedUpdate(update: update, priority: priority, deadline: deadline))
        }
    }
    
    public func getCurrentState() async -> S {
        return currentState
    }
    
    private func executeImmediate(_ update: @escaping (inout S) -> Void) async {
        update(&currentState)
        await predictor.recordUpdate()
    }
    
    private func addToBatch(_ update: @escaping (inout S) -> Void, priority: UpdatePriority, delay: TimeInterval) async {
        if currentBatch == nil {
            currentBatch = UpdateBatch()
            Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await processBatch()
            }
        }
        currentBatch?.add(update, priority: priority)
    }
    
    private func processBatch() async {
        guard let batch = currentBatch else { return }
        currentBatch = nil
        
        // Apply all updates in the batch
        for update in batch.updates {
            update(&currentState)
        }
        
        await predictor.recordBatch(size: batch.updates.count)
    }
    
    private func decideBatching(priority: UpdatePriority, deadline: Date?) async -> BatchingDecision {
        let updateRate = await predictor.currentUpdateRate()
        let latencyBudget = performanceTarget.maxLatency
        
        // High priority or deadline approaching
        if priority == .critical || isDeadlineNear(deadline) {
            return .immediate
        }
        
        // High frequency updates - batch aggressively
        if updateRate > performanceTarget.batchingThreshold {
            let optimalDelay = calculateOptimalDelay(updateRate: updateRate)
            return .batch(delay: min(optimalDelay, latencyBudget))
        }
        
        // Low frequency - execute immediately
        return updateRate < 10 ? .immediate : .deferred
    }
    
    private func isDeadlineNear(_ deadline: Date?) -> Bool {
        guard let deadline = deadline else { return false }
        return deadline.timeIntervalSinceNow < performanceTarget.maxLatency
    }
    
    private func calculateOptimalDelay(updateRate: Double) -> TimeInterval {
        // Adaptive delay based on update rate
        let baseDelay = 1.0 / updateRate
        return min(baseDelay * 2, performanceTarget.maxLatency)
    }
}

/// Batched update container
struct BatchedUpdate<S> {
    let update: (inout S) -> Void
    let priority: UpdatePriority
    let deadline: Date?
}

/// Update batch for coalescing
struct UpdateBatch<S> {
    var updates: [(inout S) -> Void] = []
    
    mutating func add(_ update: @escaping (inout S) -> Void, priority: UpdatePriority) {
        updates.append(update)
    }
}

/// Update rate predictor
actor UpdatePredictor {
    private var recentUpdates: [Date] = []
    private let windowSize: TimeInterval = 1.0 // 1 second window
    
    func recordUpdate() {
        recentUpdates.append(Date())
        cleanOldUpdates()
    }
    
    func recordBatch(size: Int) {
        for _ in 0..<size {
            recentUpdates.append(Date())
        }
        cleanOldUpdates()
    }
    
    func currentUpdateRate() -> Double {
        cleanOldUpdates()
        return Double(recentUpdates.count) / windowSize
    }
    
    private func cleanOldUpdates() {
        let cutoff = Date().addingTimeInterval(-windowSize)
        recentUpdates.removeAll { $0 < cutoff }
    }
}

/// Priority queue implementation
public struct PriorityQueue<Element> {
    private var heap: [Element] = []
    private let comparator: (Element, Element) -> Bool
    
    public init(comparator: @escaping (Element, Element) -> Bool) {
        self.comparator = comparator
    }
    
    public mutating func insert(_ element: Element) {
        heap.append(element)
        heapifyUp(heap.count - 1)
    }
    
    public mutating func extractMax() -> Element? {
        guard !heap.isEmpty else { return nil }
        
        if heap.count == 1 {
            return heap.removeLast()
        }
        
        let max = heap[0]
        heap[0] = heap.removeLast()
        heapifyDown(0)
        return max
    }
    
    private mutating func heapifyUp(_ index: Int) {
        var childIndex = index
        let child = heap[childIndex]
        var parentIndex = (childIndex - 1) / 2
        
        while childIndex > 0 && comparator(child, heap[parentIndex]) {
            heap[childIndex] = heap[parentIndex]
            childIndex = parentIndex
            parentIndex = (childIndex - 1) / 2
        }
        
        heap[childIndex] = child
    }
    
    private mutating func heapifyDown(_ index: Int) {
        let count = heap.count
        let element = heap[index]
        var parentIndex = index
        
        while true {
            let leftChildIndex = 2 * parentIndex + 1
            let rightChildIndex = leftChildIndex + 1
            var candidateIndex = parentIndex
            
            if leftChildIndex < count && comparator(heap[leftChildIndex], heap[candidateIndex]) {
                candidateIndex = leftChildIndex
            }
            
            if rightChildIndex < count && comparator(heap[rightChildIndex], heap[candidateIndex]) {
                candidateIndex = rightChildIndex
            }
            
            if candidateIndex == parentIndex {
                break
            }
            
            heap[parentIndex] = heap[candidateIndex]
            parentIndex = candidateIndex
        }
        
        heap[parentIndex] = element
    }
}

// MARK: - Memory-Efficient Storage (REQUIREMENTS-W-01-004)

/// Compression levels for state storage
public enum CompressionLevel: Sendable {
    case none
    case fast
    case balanced
    case maximum
}

/// Cache policies for compressed storage
public enum CachePolicy {
    case always
    case never
    case adaptive
    
    func shouldCache<S>(_ state: S) -> Bool {
        switch self {
        case .always: return true
        case .never: return false
        case .adaptive:
            // Cache based on state size
            let size = MemoryLayout<S>.size(ofValue: state)
            return size < 10_000 // Cache states smaller than 10KB
        }
    }
}

/// Compressed state storage for memory efficiency
public actor CompressedStateStorage<S: AxiomState & Codable> {
    private var compressed: Data?
    private var cache: S?
    private let compressionLevel: CompressionLevel
    private let cachePolicy: CachePolicy
    
    public init(
        initialState: S,
        compressionLevel: CompressionLevel = .balanced,
        cachePolicy: CachePolicy = .adaptive
    ) async throws {
        self.compressionLevel = compressionLevel
        self.cachePolicy = cachePolicy
        self.compressed = try await compress(initialState)
        self.cache = cachePolicy.shouldCache(initialState) ? initialState : nil
    }
    
    /// Transparent access with decompression
    public var state: S {
        get async throws {
            if let cached = cache {
                return cached
            }
            
            guard let compressed = compressed else {
                throw AxiomError.validationError(.ruleFailed(
                    field: "compressed_state", 
                    rule: "data_integrity", 
                    reason: "Failed to decompress state for type \(String(describing: S.self))"
                ))
            }
            
            let decompressed = try await decompress(compressed, to: S.self)
            
            // Update cache based on policy
            if cachePolicy.shouldCache(decompressed) {
                cache = decompressed
            }
            
            return decompressed
        }
    }
    
    /// Update with compression
    public func update(_ newState: S) async throws {
        compressed = try await compress(newState)
        cache = cachePolicy.shouldCache(newState) ? newState : nil
    }
    
    /// Handle memory pressure
    public func handleMemoryPressure() async {
        cache = nil
        // Force higher compression if possible
        if let currentState = try? await state {
            compressed = try? await compress(currentState, level: .maximum)
        }
    }
    
    // MARK: - Private Compression Methods
    
    private func compress(_ state: S, level: CompressionLevel? = nil) async throws -> Data {
        let effectiveLevel = level ?? compressionLevel
        
        // For MVP, use simple JSON encoding as "compression"
        let encoder = JSONEncoder()
        let data = try encoder.encode(state)
        
        // Simulate compression based on level
        switch effectiveLevel {
        case .none:
            return data
        case .fast, .balanced, .maximum:
            // In production, would use actual compression algorithms
            return data
        }
    }
    
    private func decompress<T: Decodable>(_ data: Data, to type: T.Type) async throws -> T {
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}

/// Protocol for incremental state computation
public protocol IncrementalState: AxiomState {
    associatedtype Increment
    
    func apply(increment: Increment) -> Self
    func computeIncrement(from previous: Self) -> Increment?
}

/// Manager for incremental state updates
public actor IncrementalStateManager<S: IncrementalState> {
    private var baseState: S
    private var increments: [S.Increment] = []
    private let compactionThreshold: Int
    private var compactionCount: Int = 0
    
    public init(
        initialState: S,
        compactionThreshold: Int = 100
    ) {
        self.baseState = initialState
        self.compactionThreshold = compactionThreshold
    }
    
    /// Apply increment efficiently
    public func applyIncrement(_ increment: S.Increment) async -> S {
        increments.append(increment)
        
        // Compact if needed
        if increments.count > compactionThreshold {
            await compact()
        }
        
        // Apply all increments to base
        return increments.reduce(baseState) { state, increment in
            state.apply(increment: increment)
        }
    }
    
    public func getCurrentState() async -> S {
        return increments.reduce(baseState) { state, increment in
            state.apply(increment: increment)
        }
    }
    
    public func getCompactionCount() async -> Int {
        return compactionCount
    }
    
    private func compact() async {
        let currentState = increments.reduce(baseState) { state, increment in
            state.apply(increment: increment)
        }
        baseState = currentState
        increments.removeAll(keepingCapacity: true)
        compactionCount += 1
    }
}

// MARK: - Performance Monitoring (REQUIREMENTS-W-01-004)

/// Operation types for performance tracking
public enum OperationType: Sendable {
    case read
    case write
    case batch
    case compress
    case decompress
}

/// State operation record
public struct StateOperation: Sendable {
    let type: OperationType
    let duration: TimeInterval
    let memoryDelta: Int
    let stateSize: Int
    let timestamp: Date
}

/// Performance metrics collection
public struct PerformanceMetrics: Sendable {
    public let operations: [StateOperation]
    
    public init(operations: [StateOperation] = []) {
        self.operations = operations
    }
    
    mutating func record(operation: StateOperation) {
        var mutableOps = operations
        mutableOps.append(operation)
        self = PerformanceMetrics(operations: mutableOps)
    }
    
    func getAlerts(thresholds: AlertThresholds) -> [PerformanceAlert] {
        var alerts: [PerformanceAlert] = []
        
        // Check for slow operations
        let slowOps = operations.filter { $0.duration > thresholds.maxOperationDuration }
        if !slowOps.isEmpty {
            alerts.append(.slowOperation(count: slowOps.count))
        }
        
        // Check for memory issues
        let totalMemoryDelta = operations.reduce(0) { $0 + $1.memoryDelta }
        if totalMemoryDelta > thresholds.maxMemoryGrowth {
            alerts.append(.excessiveMemoryGrowth(bytes: totalMemoryDelta))
        }
        
        return alerts
    }
}

/// Alert thresholds configuration
public struct AlertThresholds: Sendable {
    let maxOperationDuration: TimeInterval
    let maxMemoryGrowth: Int
    
    public static let `default` = AlertThresholds(
        maxOperationDuration: 0.001, // 1ms
        maxMemoryGrowth: 10_000_000 // 10MB
    )
}

// PerformanceAlert is defined in PerformanceMonitoring.swift - using unified definition

/// Optimization suggestions
public enum OptimizationSuggestion: Equatable, Sendable {
    case enableBatching(threshold: Double)
    case enableCompression(level: CompressionLevel)
    case optimizeCOW(strategy: COWOptimizer)
    case enableIncremental(threshold: Int)
}

/// Performance report
public struct PerformanceReport {
    public let metrics: PerformanceMetrics
    public let recommendations: [OptimizationSuggestion]
    public let alerts: [PerformanceAlert]
}

/// Real-time performance monitor
public actor StatePerformanceMonitor {
    private var metrics: PerformanceMetrics
    private let alertThresholds: AlertThresholds
    private var optimizationEngine: OptimizationEngine
    
    public init(thresholds: AlertThresholds = .default) {
        self.metrics = PerformanceMetrics()
        self.alertThresholds = thresholds
        self.optimizationEngine = OptimizationEngine()
    }
    
    /// Record state operation metrics
    public func recordOperation(
        type: OperationType,
        duration: TimeInterval,
        memoryDelta: Int,
        stateSize: Int
    ) async {
        metrics.record(
            operation: StateOperation(
                type: type,
                duration: duration,
                memoryDelta: memoryDelta,
                stateSize: stateSize,
                timestamp: Date()
            )
        )
        
        // Check for performance issues
        if let alert = checkAlerts() {
            await handleAlert(alert)
        }
        
        // Suggest optimizations
        let currentMetrics = metrics
        if let suggestion = await optimizationEngine.analyze(currentMetrics) {
            await applySuggestion(suggestion)
        }
    }
    
    /// Generate performance report
    public func generateReport() async -> PerformanceReport {
        let recommendations = await optimizationEngine.getRecommendations()
        return PerformanceReport(
            metrics: metrics,
            recommendations: recommendations,
            alerts: metrics.getAlerts(thresholds: alertThresholds)
        )
    }
    
    private func checkAlerts() -> PerformanceAlert? {
        let alerts = metrics.getAlerts(thresholds: alertThresholds)
        return alerts.first
    }
    
    private func handleAlert(_ alert: PerformanceAlert) async {
        // Log or handle alerts as needed
        print("Performance Alert: \(alert)")
    }
    
    private func applySuggestion(_ suggestion: OptimizationSuggestion) async {
        // Apply optimization suggestions
        print("Applying optimization: \(suggestion)")
    }
}

/// Optimization engine for pattern analysis
public actor OptimizationEngine {
    private var recommendations: [OptimizationSuggestion] = []
    
    public func analyze(_ metrics: PerformanceMetrics) async -> OptimizationSuggestion? {
        // Analyze patterns
        let patterns = detectPatterns(in: metrics)
        
        // Generate suggestions
        let suggestion: OptimizationSuggestion?
        switch patterns.primary {
        case .highFrequencyUpdates:
            suggestion = .enableBatching(threshold: patterns.updateRate)
        case .largeStateSize:
            suggestion = .enableCompression(level: .balanced)
        case .frequentCloning:
            suggestion = .optimizeCOW(strategy: .lazyClone)
        case .memoryPressure:
            suggestion = .enableIncremental(threshold: patterns.stateSize / 100)
        default:
            suggestion = nil
        }
        
        if let suggestion = suggestion {
            recommendations.append(suggestion)
        }
        
        return suggestion
    }
    
    public func getRecommendations() async -> [OptimizationSuggestion] {
        return recommendations
    }
    
    private func detectPatterns(in metrics: PerformanceMetrics) -> (primary: Pattern, updateRate: Double, stateSize: Int) {
        let operations = metrics.operations
        
        // Calculate update rate
        let timeWindow: TimeInterval = 1.0
        let recentOps = operations.filter { Date().timeIntervalSince($0.timestamp) < timeWindow }
        let updateRate = Double(recentOps.count) / timeWindow
        
        // Determine average state size
        let avgStateSize = operations.isEmpty ? 0 : operations.reduce(0) { $0 + $1.stateSize } / operations.count
        
        // Detect primary pattern
        let writeOps = operations.filter { $0.type == .write }
        let readOps = operations.filter { $0.type == .read }
        
        let pattern: Pattern
        if updateRate > 60 {
            pattern = .highFrequencyUpdates
        } else if avgStateSize > 1_000_000 {
            pattern = .largeStateSize
        } else if writeOps.count > readOps.count * 2 {
            pattern = .frequentCloning
        } else {
            pattern = .normal
        }
        
        return (pattern, updateRate, avgStateSize)
    }
    
    enum Pattern {
        case highFrequencyUpdates
        case largeStateSize
        case frequentCloning
        case memoryPressure
        case normal
    }
}