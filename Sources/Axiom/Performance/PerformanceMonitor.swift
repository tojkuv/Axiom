import Foundation

// MARK: - Performance Monitor Protocol

/// Protocol for monitoring and analyzing performance metrics
public protocol PerformanceMonitoring: Actor {
    /// Records the start of an operation
    func startOperation(_ name: String, category: PerformanceCategory) -> PerformanceToken
    
    /// Records the completion of an operation
    func endOperation(_ token: PerformanceToken) async
    
    /// Records the completion of an operation with additional metadata
    func endOperation(_ token: PerformanceToken, metadata: [String: Any]) async
    
    /// Gets performance metrics for a specific category
    func getMetrics(for category: PerformanceCategory) async -> PerformanceCategoryMetrics
    
    /// Gets overall performance summary
    func getOverallMetrics() async -> OverallPerformanceMetrics
    
    /// Gets recent performance alerts
    func getPerformanceAlerts() async -> [PerformanceAlert]
    
    /// Clears performance data
    func clearMetrics() async
}

// MARK: - Performance Monitor Implementation

/// Actor-based performance monitor with real-time analysis
public actor PerformanceMonitor: PerformanceMonitoring {
    // MARK: Properties
    
    /// Active operations being measured
    private var activeOperations: [UUID: ActiveOperation] = [:]
    
    /// Completed operations organized by category
    private var metrics: [PerformanceCategory: CategoryMetrics] = [:]
    
    /// Performance alerts
    private var alerts: [PerformanceAlert] = []
    
    /// Configuration for performance monitoring
    private let configuration: PerformanceConfiguration
    
    /// Maximum number of samples to keep per category
    private let maxSamplesPerCategory: Int
    
    /// Maximum number of alerts to keep
    private let maxAlerts: Int
    
    // Performance thresholds
    private let thresholds: PerformanceThresholds
    
    // MARK: Initialization
    
    public init(
        configuration: PerformanceConfiguration = PerformanceConfiguration(),
        maxSamplesPerCategory: Int = 10000,
        maxAlerts: Int = 1000
    ) {
        self.configuration = configuration
        self.maxSamplesPerCategory = maxSamplesPerCategory
        self.maxAlerts = maxAlerts
        self.thresholds = PerformanceThresholds()
        
        // Initialize metrics for all categories
        for category in PerformanceCategory.allCases {
            metrics[category] = CategoryMetrics()
        }
    }
    
    // MARK: Operation Tracking
    
    public func startOperation(_ name: String, category: PerformanceCategory) -> PerformanceToken {
        let token = PerformanceToken(
            id: UUID(),
            operationName: name,
            category: category,
            startTime: CFAbsoluteTimeGetCurrent()
        )
        
        let activeOp = ActiveOperation(
            token: token,
            startTime: CFAbsoluteTimeGetCurrent(),
            metadata: [:]
        )
        
        activeOperations[token.id] = activeOp
        return token
    }
    
    public func endOperation(_ token: PerformanceToken) async {
        await endOperation(token, metadata: [:])
    }
    
    public func endOperation(_ token: PerformanceToken, metadata: [String: Any]) async {
        guard let activeOp = activeOperations.removeValue(forKey: token.id) else {
            // Operation not found - might have been cleaned up already
            return
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - activeOp.startTime
        
        let completedOp = CompletedOperation(
            name: token.operationName,
            category: token.category,
            duration: duration,
            startTime: activeOp.startTime,
            endTime: endTime,
            metadata: metadata
        )
        
        // Add to metrics
        await addCompletedOperation(completedOp)
        
        // Check for performance issues
        await checkPerformanceThresholds(completedOp)
    }
    
    // MARK: Metrics Retrieval
    
    public func getMetrics(for category: PerformanceCategory) async -> PerformanceCategoryMetrics {
        guard let categoryMetrics = metrics[category] else {
            return PerformanceCategoryMetrics(
                category: category,
                totalOperations: 0,
                averageDuration: 0,
                minDuration: 0,
                maxDuration: 0,
                percentile95: 0,
                percentile99: 0,
                operationsPerSecond: 0,
                recentSamples: [OperationSample]()
            )
        }
        
        let samples = categoryMetrics.samples
        guard !samples.isEmpty else {
            return PerformanceCategoryMetrics(
                category: category,
                totalOperations: 0,
                averageDuration: 0,
                minDuration: 0,
                maxDuration: 0,
                percentile95: 0,
                percentile99: 0,
                operationsPerSecond: 0,
                recentSamples: [OperationSample]()
            )
        }
        
        let durations = samples.map { $0.duration }.sorted()
        let totalOps = samples.count
        let avgDuration = durations.reduce(0, +) / Double(totalOps)
        let minDuration = durations.first ?? 0
        let maxDuration = durations.last ?? 0
        
        let p95Index = Int(Double(totalOps) * 0.95)
        let p99Index = Int(Double(totalOps) * 0.99)
        let percentile95 = p95Index < totalOps ? durations[p95Index] : maxDuration
        let percentile99 = p99Index < totalOps ? durations[p99Index] : maxDuration
        
        // Calculate operations per second over last minute
        let oneMinuteAgo = CFAbsoluteTimeGetCurrent() - 60
        let recentOps = samples.filter { $0.endTime >= oneMinuteAgo }
        let opsPerSecond = Double(recentOps.count) / 60.0
        
        return PerformanceCategoryMetrics(
            category: category,
            totalOperations: totalOps,
            averageDuration: avgDuration,
            minDuration: minDuration,
            maxDuration: maxDuration,
            percentile95: percentile95,
            percentile99: percentile99,
            operationsPerSecond: opsPerSecond,
            recentSamples: Array(samples.suffix(100)) // Last 100 samples - using internal initializer
        )
    }
    
    public func getOverallMetrics() async -> OverallPerformanceMetrics {
        var categoryMetrics: [PerformanceCategory: PerformanceCategoryMetrics] = [:]
        
        for category in PerformanceCategory.allCases {
            categoryMetrics[category] = await getMetrics(for: category)
        }
        
        let totalOperations = categoryMetrics.values.reduce(0) { $0 + $1.totalOperations }
        let totalActiveOperations = activeOperations.count
        
        // Calculate memory usage estimation
        let memoryUsage = estimateMemoryUsage()
        
        // Calculate health score based on recent performance
        let healthScore = calculateHealthScore(categoryMetrics: categoryMetrics)
        
        return OverallPerformanceMetrics(
            categoryMetrics: categoryMetrics,
            totalOperations: totalOperations,
            activeOperations: totalActiveOperations,
            memoryUsage: memoryUsage,
            healthScore: healthScore,
            alertCount: alerts.count,
            uptime: calculateUptime()
        )
    }
    
    public func getPerformanceAlerts() async -> [PerformanceAlert] {
        // Return recent alerts (last 100)
        return Array(alerts.suffix(100))
    }
    
    public func clearMetrics() async {
        metrics.removeAll()
        alerts.removeAll()
        activeOperations.removeAll()
        
        // Reinitialize metrics for all categories
        for category in PerformanceCategory.allCases {
            metrics[category] = CategoryMetrics()
        }
    }
    
    // MARK: Private Methods
    
    private func addCompletedOperation(_ operation: CompletedOperation) async {
        guard var categoryMetrics = metrics[operation.category] else { return }
        
        categoryMetrics.samples.append(operation)
        
        // Enforce sample limit
        if categoryMetrics.samples.count > maxSamplesPerCategory {
            let excess = categoryMetrics.samples.count - maxSamplesPerCategory
            categoryMetrics.samples.removeFirst(excess)
        }
        
        metrics[operation.category] = categoryMetrics
    }
    
    private func checkPerformanceThresholds(_ operation: CompletedOperation) async {
        let threshold = thresholds.threshold(for: operation.category)
        
        // Check duration threshold
        if operation.duration > threshold.maxDuration {
            let alert = PerformanceAlert(
                type: .slowOperation,
                category: operation.category,
                operationName: operation.name,
                threshold: threshold.maxDuration,
                actualValue: operation.duration,
                timestamp: Date(),
                message: "Operation '\(operation.name)' exceeded duration threshold: \(operation.duration)s > \(threshold.maxDuration)s"
            )
            
            await addAlert(alert)
        }
        
        // Check if category is experiencing high latency
        let categoryMetrics = await getMetrics(for: operation.category)
        if categoryMetrics.percentile95 > threshold.p95Threshold {
            let alert = PerformanceAlert(
                type: .highLatency,
                category: operation.category,
                operationName: nil,
                threshold: threshold.p95Threshold,
                actualValue: categoryMetrics.percentile95,
                timestamp: Date(),
                message: "Category '\(operation.category)' experiencing high latency: P95 = \(categoryMetrics.percentile95)s"
            )
            
            await addAlert(alert)
        }
        
        // Check for memory issues
        let memoryUsage = estimateMemoryUsage()
        if memoryUsage.totalBytes > threshold.maxMemoryUsage {
            let alert = PerformanceAlert(
                type: .memoryPressure,
                category: operation.category,
                operationName: nil,
                threshold: Double(threshold.maxMemoryUsage),
                actualValue: Double(memoryUsage.totalBytes),
                timestamp: Date(),
                message: "High memory usage detected: \(memoryUsage.totalBytes) bytes"
            )
            
            await addAlert(alert)
        }
    }
    
    private func addAlert(_ alert: PerformanceAlert) async {
        alerts.append(alert)
        
        // Enforce alert limit
        if alerts.count > maxAlerts {
            let excess = alerts.count - maxAlerts
            alerts.removeFirst(excess)
        }
    }
    
    private func estimateMemoryUsage() -> MemoryUsage {
        let activeOpsMemory = activeOperations.count * MemoryLayout<ActiveOperation>.size
        let metricsMemory = metrics.values.reduce(0) { total, categoryMetrics in
            total + (categoryMetrics.samples.count * MemoryLayout<CompletedOperation>.size)
        }
        let alertsMemory = alerts.count * MemoryLayout<PerformanceAlert>.size
        
        return MemoryUsage(
            activeOperations: activeOpsMemory,
            historicalMetrics: metricsMemory,
            alerts: alertsMemory,
            totalBytes: activeOpsMemory + metricsMemory + alertsMemory
        )
    }
    
    private func calculateHealthScore(categoryMetrics: [PerformanceCategory: PerformanceCategoryMetrics]) -> Double {
        guard !categoryMetrics.isEmpty else { return 1.0 }
        
        let scores = categoryMetrics.compactMap { (category, metrics) -> Double? in
            guard metrics.totalOperations > 0 else { return nil }
            
            let threshold = thresholds.threshold(for: category)
            
            // Score based on P95 performance vs threshold
            let p95Score = min(1.0, threshold.p95Threshold / max(metrics.percentile95, 0.001))
            
            // Score based on operations per second vs expected throughput
            let throughputScore = min(1.0, metrics.operationsPerSecond / max(threshold.expectedThroughput, 0.001))
            
            // Combined score (weighted average)
            return (p95Score * 0.7) + (throughputScore * 0.3)
        }
        
        guard !scores.isEmpty else { return 1.0 }
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    private func calculateUptime() -> TimeInterval {
        // This would track actual uptime in a real implementation
        // For now, return a placeholder
        return 0.0
    }
}

// MARK: - Supporting Types

/// Categories for performance monitoring
public enum PerformanceCategory: String, CaseIterable, Sendable {
    case stateAccess = "state_access"
    case stateUpdate = "state_update"
    case snapshotCreation = "snapshot_creation"
    case transactionCommit = "transaction_commit"
    case transactionRollback = "transaction_rollback"
    case capabilityValidation = "capability_validation"
    case intelligenceQuery = "intelligence_query"
    case patternDetection = "pattern_detection"
    case domainValidation = "domain_validation"
    case contextCreation = "context_creation"
    case viewRendering = "view_rendering"
    case networkRequest = "network_request"
    case databaseOperation = "database_operation"
    case cacheOperation = "cache_operation"
    case computeIntensive = "compute_intensive"
}

/// Token returned when starting a performance measurement
public struct PerformanceToken: Sendable {
    let id: UUID
    let operationName: String
    let category: PerformanceCategory
    let startTime: TimeInterval
}

/// Configuration for performance monitoring
public struct PerformanceConfiguration: Sendable {
    public let enabledCategories: Set<PerformanceCategory>
    public let samplingRate: Double // 0.0 to 1.0
    public let enableAlerts: Bool
    public let enableAutomaticCleanup: Bool
    
    public init(
        enabledCategories: Set<PerformanceCategory> = Set(PerformanceCategory.allCases),
        samplingRate: Double = 1.0,
        enableAlerts: Bool = true,
        enableAutomaticCleanup: Bool = true
    ) {
        self.enabledCategories = enabledCategories
        self.samplingRate = max(0.0, min(1.0, samplingRate))
        self.enableAlerts = enableAlerts
        self.enableAutomaticCleanup = enableAutomaticCleanup
    }
}

/// Performance thresholds for different categories
public struct PerformanceThresholds {
    private let categoryThresholds: [PerformanceCategory: CategoryThreshold]
    
    public init() {
        var thresholds: [PerformanceCategory: CategoryThreshold] = [:]
        
        // Define default thresholds for each category
        thresholds[.stateAccess] = CategoryThreshold(
            maxDuration: 0.010, // 10ms
            p95Threshold: 0.005, // 5ms
            expectedThroughput: 1000.0, // ops/sec
            maxMemoryUsage: 1024 * 1024 // 1MB
        )
        
        thresholds[.stateUpdate] = CategoryThreshold(
            maxDuration: 0.050, // 50ms
            p95Threshold: 0.025, // 25ms
            expectedThroughput: 100.0, // ops/sec
            maxMemoryUsage: 5 * 1024 * 1024 // 5MB
        )
        
        thresholds[.snapshotCreation] = CategoryThreshold(
            maxDuration: 0.100, // 100ms
            p95Threshold: 0.050, // 50ms
            expectedThroughput: 50.0, // ops/sec
            maxMemoryUsage: 10 * 1024 * 1024 // 10MB
        )
        
        thresholds[.transactionCommit] = CategoryThreshold(
            maxDuration: 0.200, // 200ms
            p95Threshold: 0.100, // 100ms
            expectedThroughput: 20.0, // ops/sec
            maxMemoryUsage: 2 * 1024 * 1024 // 2MB
        )
        
        thresholds[.capabilityValidation] = CategoryThreshold(
            maxDuration: 0.001, // 1ms
            p95Threshold: 0.0005, // 0.5ms
            expectedThroughput: 10000.0, // ops/sec
            maxMemoryUsage: 512 * 1024 // 512KB
        )
        
        thresholds[.intelligenceQuery] = CategoryThreshold(
            maxDuration: 0.100, // 100ms (target from roadmap)
            p95Threshold: 0.075, // 75ms
            expectedThroughput: 10.0, // ops/sec
            maxMemoryUsage: 5 * 1024 * 1024 // 5MB
        )
        
        // Set reasonable defaults for other categories
        for category in PerformanceCategory.allCases {
            if thresholds[category] == nil {
                thresholds[category] = CategoryThreshold(
                    maxDuration: 1.0, // 1s default
                    p95Threshold: 0.500, // 500ms default
                    expectedThroughput: 10.0, // ops/sec default
                    maxMemoryUsage: 1024 * 1024 // 1MB default
                )
            }
        }
        
        self.categoryThresholds = thresholds
    }
    
    public func threshold(for category: PerformanceCategory) -> CategoryThreshold {
        return categoryThresholds[category] ?? CategoryThreshold(
            maxDuration: 1.0,
            p95Threshold: 0.500,
            expectedThroughput: 10.0,
            maxMemoryUsage: 1024 * 1024
        )
    }
}

/// Threshold values for a performance category
public struct CategoryThreshold: Sendable {
    public let maxDuration: TimeInterval
    public let p95Threshold: TimeInterval
    public let expectedThroughput: Double // operations per second
    public let maxMemoryUsage: Int // bytes
    
    public init(
        maxDuration: TimeInterval,
        p95Threshold: TimeInterval,
        expectedThroughput: Double,
        maxMemoryUsage: Int
    ) {
        self.maxDuration = maxDuration
        self.p95Threshold = p95Threshold
        self.expectedThroughput = expectedThroughput
        self.maxMemoryUsage = maxMemoryUsage
    }
}

/// Active operation being tracked
private struct ActiveOperation {
    let token: PerformanceToken
    let startTime: TimeInterval
    let metadata: [String: Any]
}

/// Completed operation with timing data
internal struct CompletedOperation {
    let name: String
    let category: PerformanceCategory
    let duration: TimeInterval
    let startTime: TimeInterval
    let endTime: TimeInterval
    let metadata: [String: Any]
}

/// Internal metrics storage for a category
private struct CategoryMetrics {
    var samples: [CompletedOperation] = []
}

/// Performance metrics for a specific category
public struct PerformanceCategoryMetrics: Sendable {
    public let category: PerformanceCategory
    public let totalOperations: Int
    public let averageDuration: TimeInterval
    public let minDuration: TimeInterval
    public let maxDuration: TimeInterval
    public let percentile95: TimeInterval
    public let percentile99: TimeInterval
    public let operationsPerSecond: Double
    public let recentSamples: [OperationSample]
    
    public init(
        category: PerformanceCategory,
        totalOperations: Int,
        averageDuration: TimeInterval,
        minDuration: TimeInterval,
        maxDuration: TimeInterval,
        percentile95: TimeInterval,
        percentile99: TimeInterval,
        operationsPerSecond: Double,
        recentSamples: [OperationSample]
    ) {
        self.category = category
        self.totalOperations = totalOperations
        self.averageDuration = averageDuration
        self.minDuration = minDuration
        self.maxDuration = maxDuration
        self.percentile95 = percentile95
        self.percentile99 = percentile99
        self.operationsPerSecond = operationsPerSecond
        self.recentSamples = recentSamples
    }
    
    internal init(
        category: PerformanceCategory,
        totalOperations: Int,
        averageDuration: TimeInterval,
        minDuration: TimeInterval,
        maxDuration: TimeInterval,
        percentile95: TimeInterval,
        percentile99: TimeInterval,
        operationsPerSecond: Double,
        recentSamples: [CompletedOperation]
    ) {
        self.category = category
        self.totalOperations = totalOperations
        self.averageDuration = averageDuration
        self.minDuration = minDuration
        self.maxDuration = maxDuration
        self.percentile95 = percentile95
        self.percentile99 = percentile99
        self.operationsPerSecond = operationsPerSecond
        self.recentSamples = recentSamples.map { OperationSample(from: $0) }
    }
}

/// Public representation of an operation sample
public struct OperationSample: Sendable {
    public let name: String
    public let duration: TimeInterval
    public let timestamp: Date
    
    fileprivate init(from operation: CompletedOperation) {
        self.name = operation.name
        self.duration = operation.duration
        self.timestamp = Date(timeIntervalSinceReferenceDate: operation.endTime)
    }
}

/// Overall performance metrics across all categories
public struct OverallPerformanceMetrics: Sendable {
    public let categoryMetrics: [PerformanceCategory: PerformanceCategoryMetrics]
    public let totalOperations: Int
    public let activeOperations: Int
    public let memoryUsage: MemoryUsage
    public let healthScore: Double // 0.0 to 1.0
    public let alertCount: Int
    public let uptime: TimeInterval
}

/// Memory usage breakdown
public struct MemoryUsage: Sendable {
    public let activeOperations: Int
    public let historicalMetrics: Int
    public let alerts: Int
    public let totalBytes: Int
    
    public var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .memory)
    }
}

/// Performance alert
public struct PerformanceAlert: Sendable {
    public let type: AlertType
    public let category: PerformanceCategory
    public let operationName: String?
    public let threshold: Double
    public let actualValue: Double
    public let timestamp: Date
    public let message: String
    
    public enum AlertType: String, Sendable {
        case slowOperation = "slow_operation"
        case highLatency = "high_latency"
        case memoryPressure = "memory_pressure"
        case lowThroughput = "low_throughput"
        case errorRate = "error_rate"
    }
}

// MARK: - Convenience Extensions

extension PerformanceMonitor {
    /// Convenience method to measure a synchronous operation
    public func measure<T>(
        _ name: String,
        category: PerformanceCategory,
        operation: () throws -> T
    ) async rethrows -> T {
        let token = startOperation(name, category: category)
        defer {
            Task {
                await endOperation(token)
            }
        }
        return try operation()
    }
    
    /// Convenience method to measure an asynchronous operation
    public func measureAsync<T>(
        _ name: String,
        category: PerformanceCategory,
        operation: () async throws -> T
    ) async rethrows -> T {
        let token = startOperation(name, category: category)
        defer {
            Task {
                await endOperation(token)
            }
        }
        return try await operation()
    }
}

// MARK: - Global Performance Monitor

/// Global shared performance monitor instance
public actor GlobalPerformanceMonitor {
    public static let shared = GlobalPerformanceMonitor()
    
    private let monitor: PerformanceMonitor
    
    private init() {
        self.monitor = PerformanceMonitor()
    }
    
    public func getMonitor() -> PerformanceMonitor {
        monitor
    }
}

// MARK: - Protocol Extensions

extension PerformanceCategoryMetrics: CustomStringConvertible {
    public var description: String {
        """
        \(category.rawValue): \(totalOperations) ops, avg: \(String(format: "%.3f", averageDuration))s, p95: \(String(format: "%.3f", percentile95))s, ops/sec: \(String(format: "%.1f", operationsPerSecond))
        """
    }
}

extension PerformanceAlert: CustomStringConvertible {
    public var description: String {
        "\(type.rawValue) in \(category.rawValue): \(message)"
    }
}