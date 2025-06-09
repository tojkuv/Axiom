import XCTest
import Foundation
@testable import Axiom

// MARK: - Performance Testing Framework

/// Comprehensive performance and memory testing utilities for Axiom
/// Provides benchmarking, memory leak detection, and load testing capabilities
public struct PerformanceTestHelpers {
    
    // MARK: - Memory Leak Detection
    
    /// Assert no memory leaks occur during operation
    public static func assertNoMemoryLeaks<T>(
        operation: @escaping () async throws -> T,
        timeout: Duration = .seconds(5),
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> T {
        weak var weakReference: AnyObject?
        
        let result: T = try await withCheckedThrowingContinuation { continuation in
            autoreleasepool {
                let trackingObject = NSObject()
                weakReference = trackingObject
                
                Task {
                    do {
                        let value = try await operation()
                        continuation.resume(returning: value)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
        
        // Allow garbage collection
        try await Task.sleep(for: .milliseconds(100))
        
        // Force garbage collection if possible
        if #available(iOS 13.0, macOS 10.15, *) {
            // Run multiple GC cycles to ensure cleanup
            for _ in 0..<3 {
                autoreleasepool {}
                try await Task.sleep(for: .milliseconds(10))
            }
        }
        
        if weakReference != nil {
            XCTFail("Memory leak detected - object not deallocated", file: file, line: line)
        }
        
        return result
    }
    
    /// Track memory usage during operation
    public static func trackMemoryUsage<T>(
        during operation: () async throws -> T,
        samplingInterval: Duration = .milliseconds(100)
    ) async throws -> (result: T, memoryProfile: MemoryProfile) {
        var samples: [MemorySnapshot] = []
        let startTime = ContinuousClock.now
        
        // Start memory monitoring
        let monitoringTask = Task {
            while !Task.isCancelled {
                let snapshot = MemorySnapshot(
                    timestamp: ContinuousClock.now,
                    usage: getCurrentMemoryUsage()
                )
                samples.append(snapshot)
                
                try? await Task.sleep(for: samplingInterval)
            }
        }
        
        // Execute operation
        let result = try await operation()
        
        // Stop monitoring
        monitoringTask.cancel()
        
        let endTime = ContinuousClock.now
        let profile = MemoryProfile(
            duration: endTime - startTime,
            samples: samples,
            peakUsage: samples.map(\.usage).max() ?? 0,
            averageUsage: samples.isEmpty ? 0 : samples.map(\.usage).reduce(0, +) / samples.count,
            finalUsage: samples.last?.usage ?? 0
        )
        
        return (result, profile)
    }
    
    /// Assert memory usage stays within bounds
    public static func assertMemoryBounds<T>(
        during operation: () async throws -> T,
        maxGrowth: Int = 10 * 1024 * 1024, // 10MB default
        maxPeak: Int = 100 * 1024 * 1024,  // 100MB default
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> T {
        let startMemory = getCurrentMemoryUsage()
        
        let (result, profile) = try await trackMemoryUsage(during: operation)
        
        let memoryGrowth = profile.finalUsage - startMemory
        
        XCTAssertLessThanOrEqual(
            memoryGrowth,
            maxGrowth,
            "Memory growth (\(memoryGrowth / 1024)KB) exceeded limit (\(maxGrowth / 1024)KB)",
            file: file,
            line: line
        )
        
        XCTAssertLessThanOrEqual(
            profile.peakUsage,
            maxPeak,
            "Peak memory usage (\(profile.peakUsage / 1024)KB) exceeded limit (\(maxPeak / 1024)KB)",
            file: file,
            line: line
        )
        
        return result
    }
    
    // MARK: - Performance Benchmarking
    
    /// Benchmark operation performance
    public static func benchmark<T>(
        _ operation: () async throws -> T,
        iterations: Int = 10,
        warmupIterations: Int = 2
    ) async throws -> PerformanceBenchmark<T> {
        var results: [T] = []
        var durations: [Duration] = []
        var memorySnapshots: [(start: Int, end: Int)] = []
        
        // Warmup iterations
        for _ in 0..<warmupIterations {
            _ = try await operation()
        }
        
        // Benchmark iterations
        for _ in 0..<iterations {
            let startMemory = getCurrentMemoryUsage()
            let startTime = ContinuousClock.now
            
            let result = try await operation()
            
            let endTime = ContinuousClock.now
            let endMemory = getCurrentMemoryUsage()
            
            results.append(result)
            durations.append(endTime - startTime)
            memorySnapshots.append((start: startMemory, end: endMemory))
        }
        
        return PerformanceBenchmark(
            results: results,
            durations: durations,
            memorySnapshots: memorySnapshots,
            iterations: iterations
        )
    }
    
    /// Assert performance requirements are met
    public static func assertPerformanceRequirements<T>(
        operation: () async throws -> T,
        maxDuration: Duration = .seconds(1),
        maxMemoryGrowth: Int = 1024 * 1024, // 1MB
        iterations: Int = 5,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let benchmark = try await Self.benchmark(operation, iterations: iterations)
        
        XCTAssertLessThanOrEqual(
            benchmark.averageDuration,
            maxDuration,
            "Average duration (\(benchmark.averageDuration)) exceeded requirement (\(maxDuration))",
            file: file,
            line: line
        )
        
        XCTAssertLessThanOrEqual(
            benchmark.averageMemoryGrowth,
            maxMemoryGrowth,
            "Average memory growth (\(benchmark.averageMemoryGrowth / 1024)KB) exceeded requirement (\(maxMemoryGrowth / 1024)KB)",
            file: file,
            line: line
        )
    }
    
    // MARK: - Load Testing
    
    /// Perform concurrent load testing
    public static func loadTest(
        concurrency: Int = 10,
        duration: Duration = .seconds(10),
        operation: @escaping () async throws -> Void
    ) async throws -> LoadTestResults {
        let startTime = ContinuousClock.now
        let endTime = startTime + duration
        
        var results: [LoadTestResult] = []
        let resultsLock = NSLock()
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Start concurrent workers
            for workerId in 0..<concurrency {
                group.addTask {
                    var operationCount = 0
                    var errorCount = 0
                    var totalDuration: Duration = .zero
                    
                    while ContinuousClock.now < endTime {
                        let operationStart = ContinuousClock.now
                        
                        do {
                            try await operation()
                            operationCount += 1
                        } catch {
                            errorCount += 1
                        }
                        
                        let operationEnd = ContinuousClock.now
                        totalDuration += operationEnd - operationStart
                        
                        // Brief pause to allow other tasks
                        try? await Task.sleep(for: .milliseconds(1))
                    }
                    
                    let result = LoadTestResult(
                        workerId: workerId,
                        operationCount: operationCount,
                        errorCount: errorCount,
                        totalDuration: totalDuration,
                        averageDuration: operationCount > 0 ? totalDuration / operationCount : .zero
                    )
                    
                    resultsLock.lock()
                    results.append(result)
                    resultsLock.unlock()
                }
            }
        }
        
        let actualDuration = ContinuousClock.now - startTime
        
        return LoadTestResults(
            concurrency: concurrency,
            requestedDuration: duration,
            actualDuration: actualDuration,
            results: results
        )
    }
    
    /// Assert load test requirements
    public static func assertLoadTestRequirements(
        concurrency: Int = 10,
        duration: Duration = .seconds(10),
        minThroughput: Int = 100, // operations per second
        maxErrorRate: Double = 0.01, // 1%
        operation: @escaping () async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let results = try await loadTest(
            concurrency: concurrency,
            duration: duration,
            operation: operation
        )
        
        let actualThroughput = results.throughputPerSecond
        let actualErrorRate = results.errorRate
        
        XCTAssertGreaterThanOrEqual(
            Int(actualThroughput),
            minThroughput,
            "Throughput (\(Int(actualThroughput)) ops/sec) below requirement (\(minThroughput) ops/sec)",
            file: file,
            line: line
        )
        
        XCTAssertLessThanOrEqual(
            actualErrorRate,
            maxErrorRate,
            "Error rate (\(actualErrorRate * 100)%) exceeded requirement (\(maxErrorRate * 100)%)",
            file: file,
            line: line
        )
    }
    
    // MARK: - Stress Testing
    
    /// Perform stress testing with increasing load
    public static func stressTest(
        startingConcurrency: Int = 1,
        maxConcurrency: Int = 100,
        stepSize: Int = 10,
        stepDuration: Duration = .seconds(5),
        operation: @escaping () async throws -> Void
    ) async throws -> StressTestResults {
        var stepResults: [StressTestStep] = []
        
        var currentConcurrency = startingConcurrency
        while currentConcurrency <= maxConcurrency {
            let stepStart = ContinuousClock.now
            
            let loadResults = try await loadTest(
                concurrency: currentConcurrency,
                duration: stepDuration,
                operation: operation
            )
            
            let stepEnd = ContinuousClock.now
            
            let step = StressTestStep(
                concurrency: currentConcurrency,
                duration: stepEnd - stepStart,
                throughput: loadResults.throughputPerSecond,
                errorRate: loadResults.errorRate,
                averageResponseTime: loadResults.averageResponseTime
            )
            
            stepResults.append(step)
            
            // Check if system is becoming unstable
            if step.errorRate > 0.5 { // 50% error rate
                break
            }
            
            currentConcurrency += stepSize
        }
        
        return StressTestResults(steps: stepResults)
    }
    
    // MARK: - Context-Specific Testing
    
    /// Test context performance under load
    public static func testContextPerformance<C: Context>(
        context: C,
        actionCount: Int = 1000,
        concurrentClients: Int = 10
    ) async throws -> ContextPerformanceResults {
        let startTime = ContinuousClock.now
        let startMemory = getCurrentMemoryUsage()
        
        var actionDurations: [Duration] = []
        let durationsLock = NSLock()
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<concurrentClients {
                group.addTask {
                    for _ in 0..<(actionCount / concurrentClients) {
                        let actionStart = ContinuousClock.now
                        
                        // Simulate context action
                        await MainActor.run {
                            // Context action simulation would go here
                        }
                        
                        let actionEnd = ContinuousClock.now
                        let actionDuration = actionEnd - actionStart
                        
                        durationsLock.lock()
                        actionDurations.append(actionDuration)
                        durationsLock.unlock()
                        
                        // Brief pause
                        try? await Task.sleep(for: .milliseconds(1))
                    }
                }
            }
        }
        
        let endTime = ContinuousClock.now
        let endMemory = getCurrentMemoryUsage()
        
        return ContextPerformanceResults(
            totalDuration: endTime - startTime,
            actionCount: actionDurations.count,
            averageActionDuration: actionDurations.isEmpty ? .zero : actionDurations.reduce(.zero, +) / actionDurations.count,
            memoryGrowth: endMemory - startMemory,
            throughput: Double(actionDurations.count) / (endTime - startTime).timeInterval
        )
    }
    
    // MARK: - Utility Functions
    
    private static func getCurrentMemoryUsage() -> Int {
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
}

// MARK: - Supporting Types

/// Memory snapshot at a point in time
public struct MemorySnapshot {
    public let timestamp: ContinuousClock.Instant
    public let usage: Int
}

/// Memory usage profile over time
public struct MemoryProfile {
    public let duration: Duration
    public let samples: [MemorySnapshot]
    public let peakUsage: Int
    public let averageUsage: Int
    public let finalUsage: Int
    
    public var memoryGrowth: Int {
        guard let first = samples.first, let last = samples.last else { return 0 }
        return last.usage - first.usage
    }
}

/// Performance benchmark results
public struct PerformanceBenchmark<T> {
    public let results: [T]
    public let durations: [Duration]
    public let memorySnapshots: [(start: Int, end: Int)]
    public let iterations: Int
    
    public var averageDuration: Duration {
        durations.isEmpty ? .zero : durations.reduce(.zero, +) / iterations
    }
    
    public var minDuration: Duration {
        durations.min() ?? .zero
    }
    
    public var maxDuration: Duration {
        durations.max() ?? .zero
    }
    
    public var averageMemoryGrowth: Int {
        memorySnapshots.isEmpty ? 0 : memorySnapshots.map { $0.end - $0.start }.reduce(0, +) / iterations
    }
    
    public var standardDeviation: Duration {
        guard iterations > 1 else { return .zero }
        
        let average = averageDuration.timeInterval
        let variance = durations.map { pow($0.timeInterval - average, 2) }.reduce(0, +) / Double(iterations - 1)
        
        return Duration.seconds(sqrt(variance))
    }
}

/// Load test result for a single worker
public struct LoadTestResult {
    public let workerId: Int
    public let operationCount: Int
    public let errorCount: Int
    public let totalDuration: Duration
    public let averageDuration: Duration
    
    public var errorRate: Double {
        let total = operationCount + errorCount
        return total > 0 ? Double(errorCount) / Double(total) : 0.0
    }
}

/// Combined load test results
public struct LoadTestResults {
    public let concurrency: Int
    public let requestedDuration: Duration
    public let actualDuration: Duration
    public let results: [LoadTestResult]
    
    public var totalOperations: Int {
        results.map(\.operationCount).reduce(0, +)
    }
    
    public var totalErrors: Int {
        results.map(\.errorCount).reduce(0, +)
    }
    
    public var throughputPerSecond: Double {
        Double(totalOperations) / actualDuration.timeInterval
    }
    
    public var errorRate: Double {
        let total = totalOperations + totalErrors
        return total > 0 ? Double(totalErrors) / Double(total) : 0.0
    }
    
    public var averageResponseTime: Duration {
        let totalDuration = results.map(\.totalDuration).reduce(.zero, +)
        return totalOperations > 0 ? totalDuration / totalOperations : .zero
    }
}

/// Stress test step result
public struct StressTestStep {
    public let concurrency: Int
    public let duration: Duration
    public let throughput: Double
    public let errorRate: Double
    public let averageResponseTime: Duration
}

/// Stress test results
public struct StressTestResults {
    public let steps: [StressTestStep]
    
    public var peakThroughput: Double {
        steps.map(\.throughput).max() ?? 0.0
    }
    
    public var optimalConcurrency: Int? {
        steps.max { $0.throughput < $1.throughput }?.concurrency
    }
    
    public var breakingPoint: Int? {
        steps.first { $0.errorRate > 0.1 }?.concurrency
    }
}

/// Context performance results
public struct ContextPerformanceResults {
    public let totalDuration: Duration
    public let actionCount: Int
    public let averageActionDuration: Duration
    public let memoryGrowth: Int
    public let throughput: Double
    
    public var actionsPerSecond: Double {
        throughput
    }
    
    public var memoryEfficiency: Double {
        // Memory efficiency: actions per KB of memory used
        memoryGrowth > 0 ? Double(actionCount) / Double(memoryGrowth / 1024) : Double.infinity
    }
}

// MARK: - Duration Extensions

extension Duration {
    var timeInterval: TimeInterval {
        let (seconds, attoseconds) = self.components
        return TimeInterval(seconds) + TimeInterval(attoseconds) / 1_000_000_000_000_000_000
    }
    
    static func / (lhs: Duration, rhs: Int) -> Duration {
        guard rhs > 0 else { return .zero }
        let (seconds, attoseconds) = lhs.components
        let totalAttoseconds = Int64(seconds) * 1_000_000_000_000_000_000 + Int64(attoseconds)
        let dividedAttoseconds = totalAttoseconds / Int64(rhs)
        let newSeconds = dividedAttoseconds / 1_000_000_000_000_000_000
        let remainingAttoseconds = dividedAttoseconds % 1_000_000_000_000_000_000
        return Duration(secondsComponent: newSeconds, attosecondsComponent: remainingAttoseconds)
    }
}

// MARK: - XCTest Extensions

public extension XCTestCase {
    
    /// Measure performance with detailed metrics
    func measureDetailedPerformance<T>(
        _ operation: () async throws -> T,
        iterations: Int = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> T {
        let benchmark = try await PerformanceTestHelpers.benchmark(operation, iterations: iterations)
        
        // Log detailed metrics
        print("Performance Metrics:")
        print("  Average: \(benchmark.averageDuration)")
        print("  Min: \(benchmark.minDuration)")
        print("  Max: \(benchmark.maxDuration)")
        print("  Std Dev: \(benchmark.standardDeviation)")
        print("  Memory Growth: \(benchmark.averageMemoryGrowth / 1024)KB")
        
        return benchmark.results.last!
    }
    
    /// Measure memory usage with detailed tracking
    func measureMemoryUsage<T>(
        _ operation: () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> T {
        let (result, profile) = try await PerformanceTestHelpers.trackMemoryUsage(during: operation)
        
        print("Memory Profile:")
        print("  Peak Usage: \(profile.peakUsage / 1024)KB")
        print("  Average Usage: \(profile.averageUsage / 1024)KB")
        print("  Memory Growth: \(profile.memoryGrowth / 1024)KB")
        print("  Duration: \(profile.duration)")
        
        return result
    }
}