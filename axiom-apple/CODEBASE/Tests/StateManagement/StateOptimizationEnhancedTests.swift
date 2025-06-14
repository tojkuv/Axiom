import XCTest
@testable import Axiom

// MARK: - Test Types

struct OptimizedTestState: State, Equatable {
    var id = UUID().uuidString
    var numbers: [Int] = []
    var strings: [String] = []
    var nested: NestedState = NestedState()
    var metadata: [String: Any] = [:]
    
    struct NestedState: Equatable {
        var value: Int = 0
        var items: [String] = []
    }
}

/// Tests for REQUIREMENTS-W-01-004: State Optimization Strategies
final class StateOptimizationEnhancedTests: XCTestCase {
    
    // MARK: - RED Phase Tests for COW Optimization
    
    func testOptimizedCOWContainer() async throws {
        // Test COW container with metrics
        var container = OptimizedCOWContainer(OptimizedTestState())
        
        // Read operations should be O(1)
        let startRead = CFAbsoluteTimeGetCurrent()
        _ = container.value
        let readDuration = (CFAbsoluteTimeGetCurrent() - startRead) * 1_000_000_000 // ns
        XCTAssertLessThan(readDuration, 100) // < 100ns
        
        // Test COW behavior
        var container2 = container
        container2.value.numbers.append(42)
        
        // Original should be unchanged
        XCTAssertEqual(container.value.numbers, [])
        XCTAssertEqual(container2.value.numbers, [42])
        
        // Test batch mutations
        let mutations: [(inout OptimizedTestState) -> Void] = [
            { $0.numbers.append(1) },
            { $0.numbers.append(2) },
            { $0.strings.append("test") }
        ]
        
        container.batchMutate(mutations)
        XCTAssertEqual(container.value.numbers, [1, 2])
        XCTAssertEqual(container.value.strings, ["test"])
        
        // Test metrics
        let metrics = container.metrics
        XCTAssertGreaterThan(metrics.sharingRatio, 0)
        XCTAssertNotNil(metrics.recommendation)
    }
    
    func testCOWMetricsAndOptimization() async throws {
        var container = OptimizedCOWContainer(OptimizedTestState())
        
        // Simulate read-heavy workload
        for _ in 0..<100 {
            _ = container.value
        }
        
        // Few writes
        container.value.numbers.append(1)
        
        let metrics = container.metrics
        XCTAssertEqual(metrics.recommendation, .lazyClone)
        
        // Apply optimization
        container.optimizeForPattern(.readHeavy)
        
        // Verify optimization applied
        XCTAssertEqual(container.currentOptimizer, .lazyClone)
    }
    
    // MARK: - Intelligent Batching Tests
    
    func testAdaptiveBatchCoordinator() async throws {
        let coordinator = AdaptiveBatchCoordinator<OptimizedTestState>(target: .fps60)
        var executionCount = 0
        
        // Test immediate execution for critical updates
        await coordinator.enqueue({ state in
            state.numbers.append(999)
            executionCount += 1
        }, priority: .critical)
        
        // Critical updates should execute immediately
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        XCTAssertEqual(executionCount, 1)
        
        // Test batching for normal priority
        for i in 0..<10 {
            await coordinator.enqueue({ state in
                state.numbers.append(i)
            }, priority: .normal)
        }
        
        // Wait for batch to process
        try await Task.sleep(nanoseconds: 20_000_000) // 20ms
        
        // Verify batch processed efficiently
        let finalState = await coordinator.getCurrentState()
        XCTAssertEqual(finalState.numbers.count, 11) // 1 critical + 10 batched
    }
    
    func testPriorityQueueOrdering() async throws {
        var queue = PriorityQueue<TestUpdate>()
        
        // Insert updates with different priorities
        queue.insert(TestUpdate(priority: .low, value: 1))
        queue.insert(TestUpdate(priority: .critical, value: 2))
        queue.insert(TestUpdate(priority: .normal, value: 3))
        queue.insert(TestUpdate(priority: .high, value: 4))
        
        // Extract in priority order
        XCTAssertEqual(queue.extractMax()?.value, 2) // Critical
        XCTAssertEqual(queue.extractMax()?.value, 4) // High
        XCTAssertEqual(queue.extractMax()?.value, 3) // Normal
        XCTAssertEqual(queue.extractMax()?.value, 1) // Low
    }
    
    // MARK: - Memory-Efficient Storage Tests
    
    func testCompressedStateStorage() async throws {
        let largeState = OptimizedTestState(
            numbers: Array(0..<1000),
            strings: Array(repeating: "test", count: 100)
        )
        
        let storage = try await CompressedStateStorage(
            initialState: largeState,
            compressionLevel: .balanced
        )
        
        // Test transparent access
        let retrieved = try await storage.state
        XCTAssertEqual(retrieved.numbers.count, 1000)
        XCTAssertEqual(retrieved.strings.count, 100)
        
        // Test memory pressure handling
        await storage.handleMemoryPressure()
        
        // Should still be accessible after pressure
        let afterPressure = try await storage.state
        XCTAssertEqual(afterPressure.numbers.count, 1000)
    }
    
    func testIncrementalStateComputation() async throws {
        struct IncrementalTestState: IncrementalState {
            var id = UUID().uuidString
            var value: Int = 0
            var history: [Int] = []
            
            struct Increment {
                let delta: Int
            }
            
            func apply(increment: Increment) -> IncrementalTestState {
                var newState = self
                newState.value += increment.delta
                newState.history.append(increment.delta)
                return newState
            }
            
            func computeIncrement(from previous: IncrementalTestState) -> Increment? {
                guard value != previous.value else { return nil }
                return Increment(delta: value - previous.value)
            }
        }
        
        let manager = IncrementalStateManager(
            initialState: IncrementalTestState(),
            compactionThreshold: 5
        )
        
        // Apply increments
        for i in 1...10 {
            let increment = IncrementalTestState.Increment(delta: i)
            _ = await manager.applyIncrement(increment)
        }
        
        // Get final state
        let finalState = await manager.getCurrentState()
        XCTAssertEqual(finalState.value, 55) // Sum of 1..10
        XCTAssertEqual(finalState.history.count, 10)
        
        // Verify compaction occurred
        let compactionCount = await manager.getCompactionCount()
        XCTAssertGreaterThan(compactionCount, 0)
    }
    
    // MARK: - Performance Monitoring Tests
    
    func testStatePerformanceMonitor() async throws {
        let monitor = StatePerformanceMonitor()
        
        // Record various operations
        await monitor.recordOperation(
            type: .read,
            duration: 0.0001, // 100μs
            memoryDelta: 0,
            stateSize: 1024
        )
        
        await monitor.recordOperation(
            type: .write,
            duration: 0.001, // 1ms
            memoryDelta: 512,
            stateSize: 1536
        )
        
        // Record high-frequency updates
        for _ in 0..<100 {
            await monitor.recordOperation(
                type: .write,
                duration: 0.0002,
                memoryDelta: 0,
                stateSize: 1536
            )
        }
        
        // Generate report
        let report = await monitor.generateReport()
        XCTAssertNotNil(report.recommendations.first)
        XCTAssertEqual(report.recommendations.first?.type, .enableBatching)
    }
    
    func testOptimizationEngineRecommendations() async throws {
        let engine = OptimizationEngine()
        
        // Test high-frequency update pattern
        let highFreqMetrics = PerformanceMetrics(
            operations: Array(repeating: StateOperation(
                type: .write,
                duration: 0.0001,
                memoryDelta: 0,
                stateSize: 1024,
                timestamp: Date()
            ), count: 1000)
        )
        
        let suggestion = await engine.analyze(highFreqMetrics)
        XCTAssertEqual(suggestion, .enableBatching(threshold: 100))
        
        // Test large state pattern
        let largeStateMetrics = PerformanceMetrics(
            operations: [StateOperation(
                type: .write,
                duration: 0.01,
                memoryDelta: 1_000_000,
                stateSize: 10_000_000,
                timestamp: Date()
            )]
        )
        
        let largeSuggestion = await engine.analyze(largeStateMetrics)
        XCTAssertEqual(largeSuggestion, .enableCompression(level: .balanced))
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndOptimization() async throws {
        // Create a client with all optimizations enabled
        final actor OptimizedClient: BaseClient<OptimizedTestState, TestAction> {
            let cowContainer: OptimizedCOWContainer<OptimizedTestState>
            let batchCoordinator: AdaptiveBatchCoordinator<OptimizedTestState>
            let performanceMonitor: StatePerformanceMonitor
            
            override init(initialState: OptimizedTestState = OptimizedTestState()) {
                self.cowContainer = OptimizedCOWContainer(initialState)
                self.batchCoordinator = AdaptiveBatchCoordinator(target: .fps60)
                self.performanceMonitor = StatePerformanceMonitor()
                super.init(initialState: initialState)
            }
            
            func process(_ action: TestAction) async throws {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                switch action {
                case .batchUpdate(let values):
                    await batchCoordinator.enqueue { state in
                        state.numbers.append(contentsOf: values)
                    }
                case .singleUpdate(let value):
                    cowContainer.value.numbers.append(value)
                }
                
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                await performanceMonitor.recordOperation(
                    type: .write,
                    duration: duration,
                    memoryDelta: 0,
                    stateSize: MemoryLayout.size(ofValue: cowContainer.value)
                )
            }
        }
        
        let client = OptimizedClient()
        
        // Perform various operations
        try await client.process(.singleUpdate(42))
        try await client.process(.batchUpdate([1, 2, 3, 4, 5]))
        
        // High-frequency updates
        for i in 0..<100 {
            try await client.process(.singleUpdate(i))
        }
        
        // Check optimization recommendations
        let report = await client.performanceMonitor.generateReport()
        XCTAssertFalse(report.recommendations.isEmpty)
    }
    
    // MARK: - Supporting Types
    
    struct TestUpdate: Comparable {
        let priority: UpdatePriority
        let value: Int
        
        static func < (lhs: TestUpdate, rhs: TestUpdate) -> Bool {
            lhs.priority.rawValue < rhs.priority.rawValue
        }
    }
    
    enum TestAction {
        case singleUpdate(Int)
        case batchUpdate([Int])
    }
}

// MARK: - Mock Implementations for Testing

extension OptimizedTestState {
    static func == (lhs: OptimizedTestState, rhs: OptimizedTestState) -> Bool {
        // Simplified equality for testing
        return lhs.id == rhs.id &&
               lhs.numbers == rhs.numbers &&
               lhs.strings == rhs.strings &&
               lhs.nested == rhs.nested
    }
}