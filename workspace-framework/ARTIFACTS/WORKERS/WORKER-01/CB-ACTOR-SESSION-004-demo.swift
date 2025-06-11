// Demonstration of REQUIREMENTS-W-01-004: State Optimization Strategies
import Foundation

// Simple demo without complex framework dependencies
struct DemoState: Codable, Equatable {
    var id = UUID().uuidString
    var numbers: [Int] = []
    var value: Int = 0
}

// Test COW Container
func demonstrateOptimizedCOW() {
    print("=== COW Container Demonstration ===")
    
    var container1 = OptimizedCOWContainer(DemoState(value: 10))
    var container2 = container1
    
    print("Initial values:")
    print("Container1: \(container1.value.value)")
    print("Container2: \(container2.value.value)")
    
    // Modify one container
    container2.value.value = 20
    container2.value.numbers.append(42)
    
    print("\nAfter modifying container2:")
    print("Container1: \(container1.value.value), numbers: \(container1.value.numbers)")
    print("Container2: \(container2.value.value), numbers: \(container2.value.numbers)")
    
    // Test batch mutations
    let mutations: [(inout DemoState) throws -> Void] = [
        { $0.numbers.append(1) },
        { $0.numbers.append(2) },
        { $0.value += 5 }
    ]
    
    container1.batchMutate(mutations)
    print("\nAfter batch mutations on container1:")
    print("Container1: \(container1.value.value), numbers: \(container1.value.numbers)")
    
    // Check metrics
    let metrics = container1.metrics
    print("\nMetrics:")
    print("Total reads: \(metrics.totalReads)")
    print("Total writes: \(metrics.totalWrites)")
    print("Sharing ratio: \(metrics.sharingRatio)")
    print("Recommendation: \(metrics.recommendation)")
}

// Test Priority Queue
func demonstratePriorityQueue() {
    print("\n=== Priority Queue Demonstration ===")
    
    struct TestTask {
        let priority: UpdatePriority
        let name: String
    }
    
    var queue = PriorityQueue<TestTask> { $0.priority > $1.priority }
    
    // Add tasks with different priorities
    queue.insert(TestTask(priority: .low, name: "Low priority task"))
    queue.insert(TestTask(priority: .critical, name: "Critical task"))
    queue.insert(TestTask(priority: .normal, name: "Normal task"))
    queue.insert(TestTask(priority: .high, name: "High priority task"))
    
    print("Processing tasks in priority order:")
    while let task = queue.extractMax() {
        print("- \(task.name) (priority: \(task.priority))")
    }
}

// Test Performance Monitoring
func demonstratePerformanceMonitoring() async {
    print("\n=== Performance Monitoring Demonstration ===")
    
    let monitor = StatePerformanceMonitor()
    
    // Simulate various operations
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
    
    // Simulate high-frequency updates
    for _ in 0..<100 {
        await monitor.recordOperation(
            type: .write,
            duration: 0.0002, // 200μs
            memoryDelta: 0,
            stateSize: 1536
        )
    }
    
    let report = await monitor.generateReport()
    print("Performance Report:")
    print("- Total operations: \(report.metrics.operations.count)")
    print("- Recommendations count: \(report.recommendations.count)")
    if let firstRecommendation = report.recommendations.first {
        print("- First recommendation: \(firstRecommendation)")
    }
    print("- Alerts count: \(report.alerts.count)")
}

// Test Compression Storage
func demonstrateCompressedStorage() async throws {
    print("\n=== Compressed Storage Demonstration ===")
    
    // Create a larger state
    let largeState = DemoState(
        numbers: Array(0..<100),
        value: 12345
    )
    
    print("Original state size: \(largeState.numbers.count) numbers")
    
    let storage = try await CompressedStateStorage(
        initialState: largeState,
        compressionLevel: .balanced,
        cachePolicy: .adaptive
    )
    
    // Retrieve and verify
    let retrieved = try await storage.state
    print("Retrieved state size: \(retrieved.numbers.count) numbers, value: \(retrieved.value)")
    
    // Update state
    let updatedState = DemoState(value: 54321)
    try await storage.update(updatedState)
    
    let newRetrieved = try await storage.state
    print("Updated state value: \(newRetrieved.value)")
    
    // Test memory pressure
    await storage.handleMemoryPressure()
    let afterPressure = try await storage.state
    print("After memory pressure, value: \(afterPressure.value)")
}

// Main demonstration
func runStateOptimizationDemo() async {
    print("🚀 State Optimization Strategies Demo")
    print("=====================================")
    
    demonstrateOptimizedCOW()
    demonstratePriorityQueue()
    await demonstratePerformanceMonitoring()
    
    do {
        try await demonstrateCompressedStorage()
    } catch {
        print("Compression demo error: \(error)")
    }
    
    print("\n✅ Demo completed successfully!")
    print("Enhanced state optimization strategies implemented:")
    print("- COW optimization with metrics")
    print("- Priority-based batching")
    print("- Performance monitoring")
    print("- Compressed state storage")
}