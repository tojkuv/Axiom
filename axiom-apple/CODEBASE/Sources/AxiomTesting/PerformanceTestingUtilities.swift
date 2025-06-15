import Foundation
import XCTest
@testable import Axiom

// MARK: - Memory Leak Detection

/// Detects memory leaks during test execution
public class MemoryLeakDetector {
    private var initialAllocations: Int = 0
    private var leaks: [MemoryLeak] = []
    
    public init() {}
    
    /// Detect memory leaks in an operation
    public func detectLeaks<T>(
        in operation: () async throws -> T
    ) async throws -> MemoryLeakReport {
        // Track initial allocations
        initialAllocations = getCurrentAllocations()
        
        // Run operation
        _ = try await operation()
        
        // Allow cleanup
        for _ in 0..<10 {
            try await Task.sleep(for: .milliseconds(10))
        }
        
        // Check final allocations
        let finalAllocations = getCurrentAllocations()
        let totalDeallocations = initialAllocations // Simplified
        
        // Detect leaks (simplified - real implementation would be more sophisticated)
        if finalAllocations > initialAllocations {
            leaks.append(MemoryLeak(
                description: "Potential memory leak detected",
                allocations: finalAllocations - initialAllocations
            ))
        }
        
        return MemoryLeakReport(
            leaks: leaks,
            totalAllocations: finalAllocations,
            totalDeallocations: totalDeallocations
        )
    }
    
    private func getCurrentAllocations() -> Int {
        // Simplified - real implementation would use malloc statistics
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

public struct MemoryLeak {
    public let description: String
    public let allocations: Int
}

public struct MemoryLeakReport {
    public let leaks: [MemoryLeak]
    public let totalAllocations: Int
    public let totalDeallocations: Int
}

// MARK: - Performance Test Annotation

/// Property wrapper for performance tests
@propertyWrapper
public struct PerformanceTest {
    private let baseline: TimeInterval
    private let iterations: Int
    private let warmup: Int
    
    public var wrappedValue: () async throws -> PerformanceTestResult {
        return { [self] in
            let suite = PerformanceTestSuite(name: "PerformanceTest")
                .withIterations(iterations)
                .withWarmupIterations(warmup)
                .addBenchmark("Test") { _ in
                    // The actual test would be injected here
                }
            
            let results = try await suite.run()
            let benchmark = results.benchmarks.first!
            
            return PerformanceTestResult(
                average: benchmark.statistics.averageDuration,
                median: benchmark.statistics.medianDuration,
                standardDeviation: benchmark.statistics.standardDeviation,
                iterations: iterations
            )
        }
    }
    
    public init(baseline: TimeInterval, iterations: Int, warmup: Int) {
        self.baseline = baseline
        self.iterations = iterations
        self.warmup = warmup
    }
}

public struct PerformanceTestResult {
    public let average: TimeInterval
    public let median: TimeInterval
    public let standardDeviation: TimeInterval
    public let iterations: Int
}

// MARK: - Performance Data Collection

/// Collects and stores performance data over time
public actor PerformanceDataCollector {
    private let testName: String
    private let storageKey: String
    private var measurements: [StoredMeasurement] = []
    
    public init(testName: String, storageKey: String) {
        self.testName = testName
        self.storageKey = storageKey
    }
    
    /// Record a performance measurement
    public func record(
        _ measurement: PerformanceMeasurement,
        metadata: [String: Any] = [:]
    ) async throws {
        let stored = StoredMeasurement(
            measurement: measurement,
            metadata: metadata
        )
        measurements.append(stored)
    }
    
    /// Get historical performance data
    public func getHistoricalData(limit: Int? = nil) async throws -> [StoredMeasurement] {
        if let limit = limit {
            return Array(measurements.suffix(limit))
        }
        return measurements
    }
}

public struct StoredMeasurement {
    public let measurement: PerformanceMeasurement
    public let metadata: [String: Any]
}

// MARK: - Performance Trend Analysis

/// Analyzes performance trends over time
public struct PerformanceTrendAnalyzer {
    public init() {}
    
    /// Analyze trends in performance measurements
    public func analyzeTrends(measurements: [PerformanceMeasurement]) -> PerformanceTrends {
        guard measurements.count >= 2 else {
            return PerformanceTrends(
                duration: PerformanceTrend(isIncreasing: false, slope: 0),
                memory: PerformanceTrend(isIncreasing: false, slope: 0),
                cpu: PerformanceTrend(isIncreasing: false, slope: 0)
            )
        }
        
        // Calculate trends using linear regression (simplified)
        let durationTrend = calculateTrend(values: measurements.map { $0.duration })
        let memoryTrend = calculateTrend(values: measurements.map { Double($0.memoryPeak) })
        let cpuTrend = calculateTrend(values: measurements.map { $0.cpuTime })
        
        return PerformanceTrends(
            duration: durationTrend,
            memory: memoryTrend,
            cpu: cpuTrend
        )
    }
    
    private func calculateTrend(values: [Double]) -> PerformanceTrend {
        guard values.count >= 2 else {
            return PerformanceTrend(isIncreasing: false, slope: 0)
        }
        
        // Simple linear regression
        let n = Double(values.count)
        let indices = Array(0..<values.count).map { Double($0) }
        
        let sumX = indices.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(indices, values).map { $0 * $1 }.reduce(0, +)
        let sumX2 = indices.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        
        return PerformanceTrend(
            isIncreasing: slope > 0,
            slope: slope
        )
    }
}

public struct PerformanceTrends {
    public let duration: PerformanceTrend
    public let memory: PerformanceTrend
    public let cpu: PerformanceTrend
}

public struct PerformanceTrend {
    public let isIncreasing: Bool
    public let slope: Double
}

// MARK: - Performance Test Generation

/// Generates performance tests automatically
public struct PerformanceTestGenerator {
    public init() {}
    
    /// Generate performance tests for a client type
    public func generatePerformanceTests<C: AxiomClient>(
        for clientType: C.Type,
        scenarios: [PerformanceScenario]
    ) -> String {
        let className = String(describing: clientType).replacingOccurrences(of: ".", with: "")
        
        var code = """
        import XCTest
        @testable import Axiom
        
        final class \(className)PerformanceTests: XCTestCase {
        
        """
        
        for scenario in scenarios {
            code += generateScenarioTest(scenario, for: clientType)
        }
        
        code += "}"
        
        return code
    }
    
    private func generateScenarioTest<C: AxiomClient>(
        _ scenario: PerformanceScenario,
        for clientType: C.Type
    ) -> String {
        switch scenario {
        case .stateUpdate(let actions):
            return """
            
                func testStateUpdatePerformance() async throws {
                    let baseline = PerformanceBaseline(
                        name: "State Update",
                        metrics: [.duration: 0.1]
                    )
                    
                    let measurement = try await PerformanceMeasurement.measure {
                        let client = // Initialize client
                        for _ in 0..<\(actions) {
                            // Perform state update
                        }
                    }
                    
                    let comparison = baseline.compare(with: measurement)
                    XCTAssertNil(comparison.detectRegression(threshold: 0.1))
                }
            
            """
            
        case .concurrentLoad(let tasks, let actionsPerTask):
            return """
            
                func testConcurrentLoadPerformance() async throws {
                    let suite = PerformanceTestSuite(name: "Concurrent Load")
                        .withConcurrency(\(tasks))
                        .addBenchmark("Concurrent Updates") { context in
                            try await context.measureConcurrent(tasks: \(tasks)) { _ in
                                // Perform \(actionsPerTask) actions
                            }
                        }
                    
                    let results = try await suite.run()
                    // Assert performance
                }
            
            """
            
        case .memoryStress(let allocations):
            return """
            
                func testMemoryStressPerformance() async throws {
                    let detector = MemoryLeakDetector()
                    let report = try await detector.detectLeaks {
                        // Perform \(allocations) allocations
                    }
                    
                    XCTAssertTrue(report.leaks.isEmpty)
                }
            
            """
            
        case .cpuIntensive(let iterations):
            return """
            
                func testCpuIntensivePerformance() async throws {
                    measure {
                        // Perform \(iterations) CPU-intensive operations
                    }
                }
            
            """
        }
    }
}

public enum PerformanceScenario {
    case stateUpdate(actions: Int)
    case concurrentLoad(tasks: Int, actionsPerTask: Int)
    case memoryStress(allocations: Int)
    case cpuIntensive(iterations: Int)
}

// MARK: - XCTest Extensions

public extension XCTestCase {
    /// Run a performance test with automatic baseline comparison
    func runPerformanceTest(
        baseline: PerformanceBaseline,
        iterations: Int = 100,
        test: @escaping () async throws -> Void
    ) async throws {
        let suite = PerformanceTestSuite(name: "Performance Test")
            .withIterations(iterations)
            .addBenchmark("Test") { _ in
                try await test()
            }
        
        let results = try await suite.run()
        
        guard let benchmark = results.benchmarks.first,
              let measurement = benchmark.measurements.first else {
            XCTFail("No measurements recorded")
            return
        }
        
        let comparison = baseline.compare(with: measurement)
        
        if let regression = comparison.detectRegression(threshold: 0.1) {
            XCTFail("Performance regression detected: \(regression.message)")
        }
    }
}