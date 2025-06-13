import XCTest
@testable import Axiom

/// Simple tests for REQUIREMENTS-W-01-004: State Optimization Strategies
final class StateOptimizationSimpleTests: XCTestCase {
    
    // MARK: - Test Types
    
    struct SimpleTestState: State, Equatable, Codable {
        var id = UUID().uuidString
        var numbers: [Int] = []
        var strings: [String] = []
        var value: Int = 0
    }
    
    // MARK: - COW Container Tests
    
    func testOptimizedCOWContainerBasics() {
        var container = OptimizedCOWContainer(SimpleTestState())
        
        // Test initial access
        XCTAssertEqual(container.value.numbers.count, 0)
        
        // Test mutation
        container.value.numbers.append(42)
        XCTAssertEqual(container.value.numbers, [42])
        
        // Test metrics
        XCTAssertGreaterThan(container.metrics.totalReads, 0)
        XCTAssertGreaterThan(container.metrics.totalWrites, 0)
    }
    
    func testCOWSharing() {
        var container1 = OptimizedCOWContainer(SimpleTestState(value: 10))
        var container2 = container1
        
        // Both should have same initial value
        XCTAssertEqual(container1.value.value, 10)
        XCTAssertEqual(container2.value.value, 10)
        
        // Modify one
        container2.value.value = 20
        
        // Original should be unchanged
        XCTAssertEqual(container1.value.value, 10)
        XCTAssertEqual(container2.value.value, 20)
    }
    
    func testCOWBatchMutation() {
        var container = OptimizedCOWContainer(SimpleTestState())
        
        let mutations: [(inout SimpleTestState) throws -> Int] = [
            { state in
                state.numbers.append(1)
                return 1
            },
            { state in
                state.numbers.append(2)
                return 2
            },
            { state in
                state.strings.append("test")
                return 3
            }
        ]
        
        let results = container.batchMutate(mutations)
        
        XCTAssertEqual(results, [1, 2, 3])
        XCTAssertEqual(container.value.numbers, [1, 2])
        XCTAssertEqual(container.value.strings, ["test"])
    }
    
    func testCOWMetrics() {
        var container = OptimizedCOWContainer(SimpleTestState())
        
        // Perform reads
        for _ in 0..<10 {
            _ = container.value
        }
        
        // Perform writes
        for i in 0..<5 {
            container.value.numbers.append(i)
        }
        
        let metrics = container.metrics
        XCTAssertEqual(metrics.totalReads, 10)
        XCTAssertEqual(metrics.totalWrites, 5)
        XCTAssertGreaterThan(metrics.sharingRatio, 0)
        
        // Test recommendation
        let recommendation = metrics.recommendation
        XCTAssertNotNil(recommendation)
    }
    
    // MARK: - Priority Queue Tests
    
    func testPriorityQueueOrdering() {
        var queue = PriorityQueue<TestUpdate> { $0.priority > $1.priority }
        
        // Insert items with different priorities
        queue.insert(TestUpdate(priority: .low, value: 1))
        queue.insert(TestUpdate(priority: .critical, value: 2))
        queue.insert(TestUpdate(priority: .normal, value: 3))
        queue.insert(TestUpdate(priority: .high, value: 4))
        
        // Extract in priority order (highest first)
        XCTAssertEqual(queue.extractMax()?.value, 2) // Critical
        XCTAssertEqual(queue.extractMax()?.value, 4) // High
        XCTAssertEqual(queue.extractMax()?.value, 3) // Normal
        XCTAssertEqual(queue.extractMax()?.value, 1) // Low
        XCTAssertNil(queue.extractMax()) // Empty
    }
    
    func testPriorityQueueEmptyAndSingle() {
        var queue = PriorityQueue<TestUpdate> { $0.priority > $1.priority }
        
        // Empty queue
        XCTAssertNil(queue.extractMax())
        
        // Single item
        queue.insert(TestUpdate(priority: .normal, value: 42))
        XCTAssertEqual(queue.extractMax()?.value, 42)
        XCTAssertNil(queue.extractMax())
    }
    
    // MARK: - Performance Monitor Tests
    
    func testPerformanceMetrics() async {
        let monitor = StatePerformanceMonitor()
        
        // Record some operations
        await monitor.recordOperation(
            type: .read,
            duration: 0.0001,
            memoryDelta: 0,
            stateSize: 1024
        )
        
        await monitor.recordOperation(
            type: .write,
            duration: 0.001,
            memoryDelta: 512,
            stateSize: 1536
        )
        
        // Generate report
        let report = await monitor.generateReport()
        XCTAssertNotNil(report.metrics)
        XCTAssertEqual(report.metrics.operations.count, 2)
    }
    
    func testOptimizationEngine() async {
        let engine = OptimizationEngine()
        
        // Create metrics with high-frequency pattern
        let operations = Array(repeating: StateOperation(
            type: .write,
            duration: 0.0001,
            memoryDelta: 0,
            stateSize: 1024,
            timestamp: Date()
        ), count: 1000)
        
        var metrics = PerformanceMetrics(operations: operations)
        
        let suggestion = await engine.analyze(metrics)
        XCTAssertNotNil(suggestion)
        
        // Test large state pattern
        let largeOperation = StateOperation(
            type: .write,
            duration: 0.01,
            memoryDelta: 1_000_000,
            stateSize: 10_000_000,
            timestamp: Date()
        )
        
        metrics = PerformanceMetrics(operations: [largeOperation])
        let largeSuggestion = await engine.analyze(metrics)
        XCTAssertNotNil(largeSuggestion)
    }
    
    // MARK: - Compression Storage Tests
    
    func testCompressedStateStorage() async throws {
        let largeState = SimpleTestState(
            numbers: Array(0..<100),
            strings: Array(repeating: "test", count: 50),
            value: 12345
        )
        
        let storage = try await CompressedStateStorage(
            initialState: largeState,
            compressionLevel: .balanced,
            cachePolicy: .adaptive
        )
        
        // Test retrieval
        let retrieved = try await storage.state
        XCTAssertEqual(retrieved.numbers.count, 100)
        XCTAssertEqual(retrieved.strings.count, 50)
        XCTAssertEqual(retrieved.value, 12345)
        
        // Test update
        let updatedState = SimpleTestState(value: 54321)
        try await storage.update(updatedState)
        
        let newRetrieved = try await storage.state
        XCTAssertEqual(newRetrieved.value, 54321)
        
        // Test memory pressure handling
        await storage.handleMemoryPressure()
        
        // Should still work after pressure
        let afterPressure = try await storage.state
        XCTAssertEqual(afterPressure.value, 54321)
    }
    
    // MARK: - Supporting Types
    
    struct TestUpdate: Comparable {
        let priority: UpdatePriority
        let value: Int
        
        static func < (lhs: TestUpdate, rhs: TestUpdate) -> Bool {
            lhs.priority < rhs.priority
        }
    }
}