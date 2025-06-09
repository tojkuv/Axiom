import Foundation
import XCTest
@testable import Axiom

// MARK: - Performance Test Suite

/// Organizes and runs performance benchmarks
public class PerformanceTestSuite {
    public let name: String
    private var benchmarkDefinitions: [BenchmarkDefinition] = []
    private var iterations = 100
    private var warmupIterations = 10
    private var concurrency = 1
    
    public init(name: String) {
        self.name = name
    }
    
    // MARK: - Configuration
    
    public func addBenchmark(
        _ name: String,
        benchmark: @escaping (BenchmarkContext) async throws -> Void
    ) -> Self {
        benchmarkDefinitions.append(BenchmarkDefinition(name: name, benchmark: benchmark))
        return self
    }
    
    public func withIterations(_ count: Int) -> Self {
        self.iterations = count
        return self
    }
    
    public func withWarmupIterations(_ count: Int) -> Self {
        self.warmupIterations = count
        return self
    }
    
    public func withConcurrency(_ level: Int) -> Self {
        self.concurrency = level
        return self
    }
    
    // MARK: - Execution
    
    public func run() async throws -> PerformanceResults {
        var benchmarkResults: [BenchmarkResult] = []
        
        for definition in benchmarkDefinitions {
            let result = try await runBenchmark(definition)
            benchmarkResults.append(result)
        }
        
        return PerformanceResults(
            suiteName: name,
            benchmarks: benchmarkResults,
            totalDuration: benchmarkResults.reduce(0) { $0 + $1.totalDuration }
        )
    }
    
    private func runBenchmark(_ definition: BenchmarkDefinition) async throws -> BenchmarkResult {
        let context = BenchmarkContext(
            iterations: iterations,
            warmupIterations: warmupIterations,
            concurrency: concurrency
        )
        
        // Warmup
        for _ in 0..<warmupIterations {
            try await definition.benchmark(context)
        }
        
        // Actual measurements
        var measurements: [PerformanceMeasurement] = []
        let startTime = ContinuousClock.now
        
        for _ in 0..<iterations {
            let measurement = try await context.measureSingle {
                try await definition.benchmark(context)
            }
            measurements.append(measurement)
        }
        
        let endTime = ContinuousClock.now
        
        return BenchmarkResult(
            name: definition.name,
            measurements: measurements,
            totalDuration: (endTime - startTime).timeInterval,
            concurrentMetrics: context.concurrentMetrics
        )
    }
    
    // MARK: - Nested Types
    
    public var benchmarks: [BenchmarkDefinition] {
        benchmarkDefinitions
    }
}

// MARK: - Benchmark Context

/// Context provided to benchmark closures
public class BenchmarkContext {
    let iterations: Int
    let warmupIterations: Int
    let concurrency: Int
    private(set) var concurrentMetrics: ConcurrentMetrics?
    
    init(iterations: Int, warmupIterations: Int, concurrency: Int) {
        self.iterations = iterations
        self.warmupIterations = warmupIterations
        self.concurrency = concurrency
    }
    
    /// Measure a single operation
    public func measure<T>(
        _ operation: () async throws -> T
    ) async throws -> T {
        let startTime = ContinuousClock.now
        let startMemory = getCurrentMemoryUsage()
        
        let result = try await operation()
        
        let endTime = ContinuousClock.now
        let endMemory = getCurrentMemoryUsage()
        
        // Record metrics (simplified for now)
        _ = PerformanceMeasurement(
            duration: (endTime - startTime).timeInterval,
            cpuTime: 0, // Would need proper CPU time measurement
            memoryPeak: endMemory - startMemory
        )
        
        return result
    }
    
    /// Measure a single operation and return measurement
    func measureSingle<T>(
        _ operation: () async throws -> T
    ) async throws -> PerformanceMeasurement {
        let startTime = ContinuousClock.now
        let startMemory = getCurrentMemoryUsage()
        let startCPU = getProcessCPUTime()
        
        _ = try await operation()
        
        let endTime = ContinuousClock.now
        let endMemory = getCurrentMemoryUsage()
        let endCPU = getProcessCPUTime()
        
        return PerformanceMeasurement(
            duration: (endTime - startTime).timeInterval,
            cpuTime: endCPU - startCPU,
            memoryPeak: endMemory - startMemory
        )
    }
    
    /// Measure concurrent operations
    public func measureConcurrent<T>(
        tasks taskCount: Int,
        operation: @escaping (Int) async throws -> T
    ) async throws {
        let startTime = ContinuousClock.now
        
        try await withThrowingTaskGroup(of: T.self) { group in
            for index in 0..<taskCount {
                group.addTask {
                    try await operation(index)
                }
            }
            
            for try await _ in group {
                // Process results
            }
        }
        
        let endTime = ContinuousClock.now
        
        concurrentMetrics = ConcurrentMetrics(
            taskCount: taskCount,
            totalDuration: (endTime - startTime).timeInterval
        )
    }
    
    private func getCurrentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
    
    private func getProcessCPUTime() -> TimeInterval {
        var info = rusage()
        getrusage(RUSAGE_SELF, &info)
        
        let userTime = TimeInterval(info.ru_utime.tv_sec) + TimeInterval(info.ru_utime.tv_usec) / 1_000_000
        let systemTime = TimeInterval(info.ru_stime.tv_sec) + TimeInterval(info.ru_stime.tv_usec) / 1_000_000
        
        return userTime + systemTime
    }
}

// MARK: - Performance Measurement

/// Captures performance metrics for a single operation
public struct PerformanceMeasurement {
    public let duration: TimeInterval
    public let cpuTime: TimeInterval
    public let memoryPeak: Int
    public let timestamp: Date
    
    public init(
        duration: TimeInterval,
        cpuTime: TimeInterval,
        memoryPeak: Int,
        timestamp: Date = Date()
    ) {
        self.duration = duration
        self.cpuTime = cpuTime
        self.memoryPeak = memoryPeak
        self.timestamp = timestamp
    }
    
    /// Measure an async operation
    public static func measure<T>(
        _ operation: () async throws -> T
    ) async throws -> PerformanceMeasurement {
        let context = BenchmarkContext(iterations: 1, warmupIterations: 0, concurrency: 1)
        return try await context.measureSingle(operation)
    }
}

// MARK: - Performance Baseline

/// Represents expected performance metrics for comparison
public struct PerformanceBaseline {
    public let name: String
    public let metrics: [PerformanceMetric: Double]
    
    public init(name: String, metrics: [PerformanceMetric: Double]) {
        self.name = name
        self.metrics = metrics
    }
    
    /// Compare measurement against baseline
    public func compare(with measurement: PerformanceMeasurement) -> BaselineComparison {
        var deltas: [PerformanceMetric: Double] = [:]
        
        if let expectedDuration = metrics[.duration] {
            deltas[.duration] = (measurement.duration - expectedDuration) / expectedDuration
        }
        
        if let expectedCPU = metrics[.cpuTime] {
            deltas[.cpuTime] = (measurement.cpuTime - expectedCPU) / expectedCPU
        }
        
        if let expectedMemory = metrics[.memoryPeak] {
            let actualMemory = Double(measurement.memoryPeak)
            deltas[.memoryPeak] = (actualMemory - expectedMemory) / expectedMemory
        }
        
        return BaselineComparison(
            baseline: self,
            measurement: measurement,
            deltas: deltas
        )
    }
}

// MARK: - Performance Regression Detection

/// Detects performance regressions
public struct PerformanceRegressionDetector {
    public let thresholds: [PerformanceMetric: Double]
    
    public init(thresholds: [PerformanceMetric: Double]) {
        self.thresholds = thresholds
    }
    
    /// Detect regressions in current measurement compared to historical data
    public func detectRegressions(
        current: PerformanceMeasurement,
        historical: [PerformanceMeasurement]
    ) -> [PerformanceRegression] {
        guard !historical.isEmpty else { return [] }
        
        var regressions: [PerformanceRegression] = []
        
        // Calculate historical averages
        let avgDuration = historical.map { $0.duration }.reduce(0, +) / Double(historical.count)
        let avgCPU = historical.map { $0.cpuTime }.reduce(0, +) / Double(historical.count)
        let avgMemory = Double(historical.map { $0.memoryPeak }.reduce(0, +)) / Double(historical.count)
        
        // Check duration regression
        if let threshold = thresholds[.duration] {
            let change = (current.duration - avgDuration) / avgDuration
            if change > threshold {
                regressions.append(PerformanceRegression(
                    metric: .duration,
                    percentageChange: change,
                    message: "Duration increased by \(Int(change * 100))%"
                ))
            }
        }
        
        // Check CPU regression
        if let threshold = thresholds[.cpu] {
            let change = (current.cpuTime - avgCPU) / avgCPU
            if change > threshold {
                regressions.append(PerformanceRegression(
                    metric: .cpu,
                    percentageChange: change,
                    message: "CPU time increased by \(Int(change * 100))%"
                ))
            }
        }
        
        // Check memory regression
        if let threshold = thresholds[.memory] {
            let change = (Double(current.memoryPeak) - avgMemory) / avgMemory
            if change > threshold {
                regressions.append(PerformanceRegression(
                    metric: .memory,
                    percentageChange: change,
                    message: "Memory usage increased by \(Int(change * 100))%"
                ))
            }
        }
        
        return regressions
    }
}

// MARK: - Performance Report

/// Generates human-readable performance reports
public struct PerformanceReport {
    /// Generate a report from performance results
    public static func generate(from results: PerformanceResults) -> String {
        var report = """
        Performance Test Report: \(results.suiteName)
        ================================================
        
        """
        
        for benchmark in results.benchmarks {
            report += generateBenchmarkSection(benchmark)
            report += "\n"
        }
        
        report += """
        
        Total Duration: \(String(format: "%.3f", results.totalDuration))s
        """
        
        return report
    }
    
    private static func generateBenchmarkSection(_ benchmark: BenchmarkResult) -> String {
        let stats = benchmark.statistics
        
        return """
        \(benchmark.name)
        ----------------
        Iterations: \(benchmark.measurements.count)
        Duration:
          Average: \(String(format: "%.3f", stats.averageDuration))s
          Median: \(String(format: "%.3f", stats.medianDuration))s
          Min: \(String(format: "%.3f", stats.minDuration))s
          Max: \(String(format: "%.3f", stats.maxDuration))s
          Std Dev: \(String(format: "%.3f", stats.standardDeviation))s
        CPU Time:
          Average: \(String(format: "%.3f", stats.averageCPUTime))s
        Memory:
          Peak: \(formatBytes(stats.peakMemory))
          Average: \(formatBytes(stats.averageMemory))
        
        """
    }
    
    private static func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Supporting Types

public struct BenchmarkDefinition {
    public let name: String
    public let benchmark: (BenchmarkContext) async throws -> Void
}

public struct BenchmarkResult {
    public let name: String
    public let measurements: [PerformanceMeasurement]
    public let totalDuration: TimeInterval
    public let concurrentMetrics: ConcurrentMetrics?
    
    public var statistics: BenchmarkStatistics {
        BenchmarkStatistics(measurements: measurements)
    }
}

public struct BenchmarkStatistics {
    public let averageDuration: TimeInterval
    public let medianDuration: TimeInterval
    public let minDuration: TimeInterval
    public let maxDuration: TimeInterval
    public let standardDeviation: TimeInterval
    public let averageCPUTime: TimeInterval
    public let peakMemory: Int
    public let averageMemory: Int
    
    init(measurements: [PerformanceMeasurement]) {
        guard !measurements.isEmpty else {
            self.averageDuration = 0
            self.medianDuration = 0
            self.minDuration = 0
            self.maxDuration = 0
            self.standardDeviation = 0
            self.averageCPUTime = 0
            self.peakMemory = 0
            self.averageMemory = 0
            return
        }
        
        let durations = measurements.map { $0.duration }.sorted()
        self.averageDuration = durations.reduce(0, +) / Double(durations.count)
        self.medianDuration = durations[durations.count / 2]
        self.minDuration = durations.first!
        self.maxDuration = durations.last!
        
        let variance = durations.map { pow($0 - averageDuration, 2) }.reduce(0, +) / Double(durations.count)
        self.standardDeviation = sqrt(variance)
        
        self.averageCPUTime = measurements.map { $0.cpuTime }.reduce(0, +) / Double(measurements.count)
        self.peakMemory = measurements.map { $0.memoryPeak }.max() ?? 0
        self.averageMemory = measurements.map { $0.memoryPeak }.reduce(0, +) / measurements.count
    }
}

public struct PerformanceResults {
    public let suiteName: String
    public let benchmarks: [BenchmarkResult]
    public let totalDuration: TimeInterval
}

public struct ConcurrentMetrics {
    public let taskCount: Int
    public let totalDuration: TimeInterval
}

public struct BaselineComparison {
    public let baseline: PerformanceBaseline
    public let measurement: PerformanceMeasurement
    private let deltas: [PerformanceMetric: Double]
    
    init(baseline: PerformanceBaseline, measurement: PerformanceMeasurement, deltas: [PerformanceMetric: Double]) {
        self.baseline = baseline
        self.measurement = measurement
        self.deltas = deltas
    }
    
    public var durationDelta: Double? { deltas[.duration] }
    public var cpuTimeDelta: Double? { deltas[.cpuTime] }
    public var memoryDelta: Double? { deltas[.memoryPeak] }
    
    public func detectRegression(threshold: Double) -> PerformanceRegression? {
        for (metric, delta) in deltas {
            if delta > threshold {
                return PerformanceRegression(
                    metric: metric,
                    percentageChange: delta,
                    message: "\(metric) increased by \(Int(delta * 100))%"
                )
            }
        }
        return nil
    }
}

public struct PerformanceRegression {
    public let metric: PerformanceMetric
    public let percentageChange: Double
    public let message: String
    
    public var metrics: [PerformanceRegression] {
        [self]
    }
}

public enum PerformanceMetric: CaseIterable {
    case duration
    case cpuTime
    case memoryPeak
    case memory
    case cpu
}

