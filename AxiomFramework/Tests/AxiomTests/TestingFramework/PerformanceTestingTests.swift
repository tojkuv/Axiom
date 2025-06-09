import XCTest
@testable import Axiom
@testable import AxiomTesting

/// Tests for performance regression testing utilities
final class PerformanceTestingTests: XCTestCase {
    
    // MARK: - Test Types
    
    struct TestState: State, Equatable {
        var items: [String]
        var isProcessing: Bool
        var lastUpdate: Date?
    }
    
    enum TestAction {
        case addItem(String)
        case removeItem(at: Int)
        case processAll
        case clear
    }
    
    actor TestClient: Client {
        typealias StateType = TestState
        typealias ActionType = TestAction
        
        private(set) var state: TestState
        
        var stateStream: AsyncStream<TestState> {
            AsyncStream { continuation in
                continuation.yield(state)
            }
        }
        
        init(initialState: TestState) {
            self.state = initialState
        }
        
        func process(_ action: TestAction) async throws {
            switch action {
            case .addItem(let item):
                state.items.append(item)
                state.lastUpdate = Date()
                
            case .removeItem(let index):
                guard index < state.items.count else { return }
                state.items.remove(at: index)
                state.lastUpdate = Date()
                
            case .processAll:
                state.isProcessing = true
                // Simulate processing
                try await Task.sleep(for: .milliseconds(100))
                state.isProcessing = false
                state.lastUpdate = Date()
                
            case .clear:
                state.items.removeAll()
                state.lastUpdate = Date()
            }
        }
    }
    
    @MainActor
    final class TestContext: BaseContext {
        let client: TestClient
        var items: [String] = []
        
        init(client: TestClient) {
            self.client = client
            super.init()
        }
        
        func addItem(_ item: String) async throws {
            try await client.process(.addItem(item))
            await updateFromClient()
        }
        
        func processAllItems() async throws {
            try await client.process(.processAll)
        }
        
        private func updateFromClient() async {
            let state = await client.state
            self.items = state.items
        }
    }
    
    // MARK: - Performance Suite Tests
    
    func testPerformanceSuiteCreation() throws {
        // This should fail - PerformanceTestSuite doesn't exist yet
        let suite = PerformanceTestSuite(name: "Client Performance")
            .addBenchmark("State Update") { context in
                try await context.measure {
                    try await self.measureStateUpdate()
                }
            }
            .addBenchmark("Bulk Operations") { context in
                try await context.measure {
                    try await self.measureBulkOperations()
                }
            }
            .withIterations(100)
            .withWarmupIterations(10)
        
        XCTAssertEqual(suite.benchmarks.count, 2)
        XCTAssertEqual(suite.iterations, 100)
        XCTAssertEqual(suite.warmupIterations, 10)
    }
    
    func testPerformanceMeasurement() async throws {
        // Test basic performance measurement
        let measurement = try await PerformanceMeasurement.measure {
            let client = TestClient(initialState: TestState(items: []))
            
            for i in 0..<100 {
                try await client.process(.addItem("Item \(i)"))
            }
        }
        
        // Verify measurement data
        XCTAssertGreaterThan(measurement.duration, 0)
        XCTAssertGreaterThan(measurement.cpuTime, 0)
        XCTAssertGreaterThan(measurement.memoryPeak, 0)
        XCTAssertNotNil(measurement.timestamp)
    }
    
    func testPerformanceBaseline() async throws {
        // Test baseline comparison
        let baseline = PerformanceBaseline(
            name: "State Update Baseline",
            metrics: [
                .duration: 0.1, // 100ms
                .cpuTime: 0.08,
                .memoryPeak: 1024 * 1024 // 1MB
            ]
        )
        
        let measurement = try await PerformanceMeasurement.measure {
            try await self.measureStateUpdate()
        }
        
        // Compare against baseline
        let comparison = baseline.compare(with: measurement)
        
        XCTAssertNotNil(comparison.durationDelta)
        XCTAssertNotNil(comparison.cpuTimeDelta)
        XCTAssertNotNil(comparison.memoryDelta)
        
        // Check regression detection
        if let regression = comparison.detectRegression(threshold: 0.1) {
            XCTAssertTrue(regression.metrics.contains { $0.percentageChange > 0.1 })
        }
    }
    
    func testPerformanceRegressionDetection() async throws {
        // Test automatic regression detection
        let detector = PerformanceRegressionDetector(
            thresholds: [
                .duration: 0.1, // 10% regression threshold
                .memory: 0.2,   // 20% regression threshold
                .cpu: 0.15      // 15% regression threshold
            ]
        )
        
        // Simulate historical data
        let historicalMeasurements = [
            PerformanceMeasurement(duration: 0.1, cpuTime: 0.08, memoryPeak: 1024 * 1024),
            PerformanceMeasurement(duration: 0.11, cpuTime: 0.09, memoryPeak: 1024 * 1024),
            PerformanceMeasurement(duration: 0.09, cpuTime: 0.07, memoryPeak: 1024 * 1024)
        ]
        
        // New measurement with regression
        let newMeasurement = PerformanceMeasurement(
            duration: 0.15, // 50% slower
            cpuTime: 0.12,
            memoryPeak: 2 * 1024 * 1024 // 2x memory
        )
        
        let regressions = detector.detectRegressions(
            current: newMeasurement,
            historical: historicalMeasurements
        )
        
        XCTAssertFalse(regressions.isEmpty)
        XCTAssertTrue(regressions.contains { $0.metric == .duration })
        XCTAssertTrue(regressions.contains { $0.metric == .memory })
    }
    
    func testPerformanceReport() async throws {
        // Test performance report generation
        let suite = PerformanceTestSuite(name: "Framework Performance")
        
        let results = try await suite
            .addBenchmark("Context Creation") { context in
                try await context.measure {
                    _ = TestContext(client: TestClient(initialState: TestState(items: [])))
                }
            }
            .addBenchmark("State Updates") { context in
                try await context.measure {
                    try await self.measureStateUpdate()
                }
            }
            .run()
        
        let report = PerformanceReport.generate(from: results)
        
        // Verify report contents
        XCTAssertTrue(report.contains("Framework Performance"))
        XCTAssertTrue(report.contains("Context Creation"))
        XCTAssertTrue(report.contains("State Updates"))
        XCTAssertTrue(report.contains("Duration"))
        XCTAssertTrue(report.contains("CPU Time"))
        XCTAssertTrue(report.contains("Memory"))
    }
    
    func testMemoryLeakDetection() async throws {
        // Test memory leak detection during performance tests
        let detector = MemoryLeakDetector()
        
        let leakReport = try await detector.detectLeaks {
            var contexts: [TestContext] = []
            
            for _ in 0..<10 {
                let client = TestClient(initialState: TestState(items: []))
                let context = TestContext(client: client)
                contexts.append(context)
                
                try await context.addItem("Test")
            }
            
            // Clear references
            contexts.removeAll()
        }
        
        // Should detect no leaks in well-behaved code
        XCTAssertTrue(leakReport.leaks.isEmpty)
        XCTAssertEqual(leakReport.totalAllocations, leakReport.totalDeallocations)
    }
    
    func testPerformanceAnnotations() async throws {
        // Test @PerformanceTest annotation
        @PerformanceTest(
            baseline: 0.1,
            iterations: 100,
            warmup: 10
        )
        func testAnnotatedPerformance() async throws {
            let client = TestClient(initialState: TestState(items: []))
            try await client.process(.addItem("Test"))
        }
        
        // Annotation should automatically run performance test
        let results = try await testAnnotatedPerformance()
        
        XCTAssertNotNil(results.average)
        XCTAssertNotNil(results.median)
        XCTAssertNotNil(results.standardDeviation)
        XCTAssertEqual(results.iterations, 100)
    }
    
    func testPerformanceDataCollection() async throws {
        // Test collecting performance data over time
        let collector = PerformanceDataCollector(
            testName: "State Update Performance",
            storageKey: "test.performance.stateUpdate"
        )
        
        // Run multiple measurements
        for i in 0..<5 {
            let measurement = try await PerformanceMeasurement.measure {
                try await self.measureStateUpdate()
            }
            
            try await collector.record(measurement, metadata: [
                "iteration": i,
                "timestamp": Date()
            ])
        }
        
        // Retrieve historical data
        let historicalData = try await collector.getHistoricalData(limit: 10)
        
        XCTAssertEqual(historicalData.count, 5)
        XCTAssertTrue(historicalData.allSatisfy { $0.metadata["iteration"] != nil })
    }
    
    func testPerformanceTrends() async throws {
        // Test performance trend analysis
        let analyzer = PerformanceTrendAnalyzer()
        
        // Simulate measurements over time
        let measurements = (0..<20).map { i in
            PerformanceMeasurement(
                duration: 0.1 + Double(i) * 0.005, // Gradual slowdown
                cpuTime: 0.08,
                memoryPeak: 1024 * 1024,
                timestamp: Date().addingTimeInterval(Double(i) * 3600) // Hourly
            )
        }
        
        let trends = analyzer.analyzeTrends(measurements: measurements)
        
        // Should detect upward trend in duration
        XCTAssertTrue(trends.duration.isIncreasing)
        XCTAssertGreaterThan(trends.duration.slope, 0)
        XCTAssertFalse(trends.memory.isIncreasing)
    }
    
    func testConcurrentPerformanceTesting() async throws {
        // Test performance under concurrent load
        let suite = PerformanceTestSuite(name: "Concurrent Performance")
            .withConcurrency(10) // Run 10 concurrent operations
        
        let results = try await suite
            .addBenchmark("Concurrent State Updates") { context in
                try await context.measureConcurrent(tasks: 10) { taskIndex in
                    let client = TestClient(initialState: TestState(items: []))
                    
                    for i in 0..<100 {
                        try await client.process(.addItem("Task \(taskIndex) Item \(i)"))
                    }
                }
            }
            .run()
        
        // Verify concurrent execution metrics
        XCTAssertNotNil(results.benchmarks.first?.concurrentMetrics)
        XCTAssertEqual(results.benchmarks.first?.concurrentMetrics?.taskCount, 10)
    }
    
    func testPerformanceTestGeneration() throws {
        // Test automatic performance test generation
        let generator = PerformanceTestGenerator()
        
        let generatedTests = generator.generatePerformanceTests(
            for: TestClient.self,
            scenarios: [
                .stateUpdate(actions: 100),
                .concurrentLoad(tasks: 10, actionsPerTask: 50),
                .memoryStress(allocations: 1000),
                .cpuIntensive(iterations: 10000)
            ]
        )
        
        // Verify generated test code
        XCTAssertTrue(generatedTests.contains("func testStateUpdatePerformance()"))
        XCTAssertTrue(generatedTests.contains("func testConcurrentLoadPerformance()"))
        XCTAssertTrue(generatedTests.contains("func testMemoryStressPerformance()"))
        XCTAssertTrue(generatedTests.contains("func testCpuIntensivePerformance()"))
        
        // Should include proper measurements
        XCTAssertTrue(generatedTests.contains("PerformanceMeasurement.measure"))
        XCTAssertTrue(generatedTests.contains("baseline.compare"))
    }
    
    // MARK: - Helper Methods
    
    private func measureStateUpdate() async throws {
        let client = TestClient(initialState: TestState(items: []))
        
        for i in 0..<100 {
            try await client.process(.addItem("Item \(i)"))
        }
    }
    
    private func measureBulkOperations() async throws {
        let client = TestClient(initialState: TestState(items: []))
        
        // Add items
        for i in 0..<50 {
            try await client.process(.addItem("Item \(i)"))
        }
        
        // Process all
        try await client.process(.processAll)
        
        // Clear
        try await client.process(.clear)
    }
}

// MARK: - Expected Performance API

/*
The performance testing utilities should provide:

1. PerformanceTestSuite - Organize and run performance benchmarks
2. PerformanceMeasurement - Capture performance metrics
3. PerformanceBaseline - Compare against expected performance
4. PerformanceRegressionDetector - Detect performance regressions
5. MemoryLeakDetector - Detect memory leaks
6. @PerformanceTest - Annotation for performance tests
7. PerformanceReport - Generate readable reports
8. PerformanceTrendAnalyzer - Analyze performance over time
9. PerformanceTestGenerator - Generate performance tests

Key features:
- Automatic baseline comparison
- Regression detection with configurable thresholds
- Memory leak detection
- Concurrent performance testing
- Historical data tracking
- Trend analysis
- Report generation
*/

// MARK: - Mock Types for Expected API

struct PerformanceMeasurement {
    let duration: TimeInterval
    let cpuTime: TimeInterval
    let memoryPeak: Int
    let timestamp: Date
    
    init(duration: TimeInterval, cpuTime: TimeInterval, memoryPeak: Int, timestamp: Date = Date()) {
        self.duration = duration
        self.cpuTime = cpuTime
        self.memoryPeak = memoryPeak
        self.timestamp = timestamp
    }
    
    static func measure(_ operation: () async throws -> Void) async throws -> PerformanceMeasurement {
        // Placeholder implementation
        fatalError("Not implemented")
    }
}

enum PerformanceMetric {
    case duration
    case cpuTime
    case memory
    case cpu
}

struct PerformanceRegression {
    let metric: PerformanceMetric
    let percentageChange: Double
    let message: String
}

struct PerformanceTrend {
    let isIncreasing: Bool
    let slope: Double
}

struct PerformanceTrends {
    let duration: PerformanceTrend
    let memory: PerformanceTrend
    let cpu: PerformanceTrend
}