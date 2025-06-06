import XCTest
@testable import TestApp002Core

// State Propagation Tests - GREEN Phase
// These tests verify that optimizations keep state propagation under 16ms
class StatePropagationTestsGreen: XCTestCase {
    var optimizer: StatePropagationOptimizer!
    
    override func setUp() async throws {
        optimizer = StatePropagationOptimizer()
    }
    
    // MARK: - GREEN Phase Tests (Should pass - propagation < 16ms)
    
    func testOptimizedSingleUpdateUnder16ms() async throws {
        let storageCapability = MockStorageCapability()
        let networkCapability = MockNetworkCapability()
        let notificationCapability = MockNotificationCapability()
        
        let taskClient = TaskClient(
            userId: "test-user",
            storageCapability: storageCapability,
            networkCapability: networkCapability,
            notificationCapability: notificationCapability
        )
        
        // Measure optimized propagation
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await optimizer.processUpdate {
            let task = Task(title: "Optimized Task")
            try? await taskClient.process(.create(task))
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let propagationTime = (endTime - startTime) * 1000
        
        print("Optimized single update: \(propagationTime)ms")
        
        XCTAssertLessThan(propagationTime, 16.0,
            "Optimized state propagation should be under 16ms, but was \(propagationTime)ms")
    }
    
    func testBatchedUpdatesUnder16ms() async throws {
        let storageCapability = MockStorageCapability()
        let networkCapability = MockNetworkCapability()
        let notificationCapability = MockNotificationCapability()
        
        let taskClient = TaskClient(
            userId: "test-user",
            storageCapability: storageCapability,
            networkCapability: networkCapability,
            notificationCapability: notificationCapability
        )
        
        // Queue multiple updates
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Add 10 updates to be batched
        for i in 0..<10 {
            await optimizer.processUpdate {
                let task = Task(
                    id: "batch-\(i)",
                    title: "Batch Task \(i)"
                )
                try? await taskClient.process(.create(task))
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = (endTime - startTime) * 1000
        
        print("Batched 10 updates in: \(totalTime)ms")
        
        // Batched updates should complete as a group under 16ms
        XCTAssertLessThan(totalTime, 16.0,
            "Batched updates should complete under 16ms, but took \(totalTime)ms")
    }
    
    func testStreamThrottlingKeepsUnder16ms() async throws {
        let throttler = StreamThrottler<Int>(throttleInterval: 0.008) // 8ms throttle
        
        // Create a rapid fire stream
        let (stream, continuation) = AsyncStream<Int>.makeStream()
        let throttledStream = await throttler.throttledStream(from: stream)
        
        // Send rapid updates
        _Concurrency.Task {
            for i in 0..<100 {
                continuation.yield(i)
                try? await _Concurrency.Task.sleep(nanoseconds: 1_000_000) // 1ms between updates
            }
            continuation.finish()
        }
        
        // Measure throttled emission rate
        var emissionTimes: [TimeInterval] = []
        var lastEmissionTime = CFAbsoluteTimeGetCurrent()
        
        for await _ in throttledStream.prefix(10) {
            let currentTime = CFAbsoluteTimeGetCurrent()
            let timeSinceLastEmission = (currentTime - lastEmissionTime) * 1000
            emissionTimes.append(timeSinceLastEmission)
            lastEmissionTime = currentTime
        }
        
        // Average time between emissions should be close to throttle interval
        let averageInterval = emissionTimes.dropFirst().reduce(0, +) / Double(emissionTimes.count - 1)
        print("Average throttled interval: \(averageInterval)ms")
        
        XCTAssertGreaterThan(averageInterval, 7.0, "Throttling should space updates at least 7ms apart")
        XCTAssertLessThan(averageInterval, 16.0, "Throttling should not exceed frame time")
    }
    
    func testEfficientStateEqualityUnder16ms() async throws {
        // Create large states
        var tasks: [Task] = []
        for i in 0..<1000 {
            tasks.append(Task(
                id: "task-\(i)",
                title: "Task \(i)",
                description: "Description \(i)"
            ))
        }
        
        let state1 = TaskListState(tasks: tasks)
        let state2 = TaskListState(tasks: tasks)
        
        // Measure optimized equality check
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform multiple equality checks
        for _ in 0..<100 {
            _ = state1 == state2
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = (endTime - startTime) * 1000
        let averageTime = totalTime / 100
        
        print("Average optimized equality check: \(averageTime)ms")
        
        XCTAssertLessThan(averageTime, 0.5,
            "Optimized equality check should be very fast, but took \(averageTime)ms")
    }
    
    func testComplexOperationsWithOptimizationUnder16ms() async throws {
        let storageCapability = MockStorageCapability()
        let networkCapability = MockNetworkCapability()
        let notificationCapability = MockNotificationCapability()
        
        let taskClient = TaskClient(
            userId: "test-user",
            storageCapability: storageCapability,
            networkCapability: networkCapability,
            notificationCapability: notificationCapability
        )
        
        // Create dataset
        for i in 0..<100 {
            let task = Task(
                id: "task-\(i)",
                title: "Task \(i)"
            )
            try await taskClient.process(.create(task))
        }
        
        // Measure complex operation with optimization
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try await taskClient.processOptimized(.search(query: "Task"))
        try await taskClient.processOptimized(.sort(by: .priority(ascending: false)))
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = (endTime - startTime) * 1000
        
        print("Optimized complex operations: \(totalTime)ms")
        
        XCTAssertLessThan(totalTime, 16.0,
            "Complex operations should complete under 16ms with optimization, but took \(totalTime)ms")
    }
    
    func testOptimizerMetricsTracking() async throws {
        // Simulate various update times
        for i in 0..<20 {
            await optimizer.processUpdate {
                // Simulate varying processing times
                let sleepTime = UInt64(i % 5) * 1_000_000 // 0-4ms
                try? await _Concurrency.Task.sleep(nanoseconds: sleepTime)
            }
        }
        
        let averageTime = await optimizer.averagePropagationTime()
        let maxTime = await optimizer.maxPropagationTime()
        
        print("Average propagation: \(averageTime)ms, Max: \(maxTime)ms")
        
        XCTAssertLessThan(averageTime, 16.0, "Average propagation should be under 16ms")
        XCTAssertLessThan(maxTime, 20.0, "Max propagation should be close to 16ms")
    }
    
    func testArrayDifferPerformance() throws {
        // Test efficient array comparison
        let array1 = Array(0..<10000)
        let array2 = Array(0..<10000)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = StateDiffer.efficientArrayCompare(array1, array2)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let compareTime = (endTime - startTime) * 1000
        
        print("Efficient array compare (10k elements): \(compareTime)ms")
        
        XCTAssertTrue(result, "Arrays should be equal")
        XCTAssertLessThan(compareTime, 5.0, "Array comparison should be fast")
        
        // Test with different arrays
        let array3 = Array(0..<9999) + [10000]
        
        let startTime2 = CFAbsoluteTimeGetCurrent()
        let result2 = StateDiffer.efficientArrayCompare(array1, array3)
        let endTime2 = CFAbsoluteTimeGetCurrent()
        let compareTime2 = (endTime2 - startTime2) * 1000
        
        print("Efficient array compare (different): \(compareTime2)ms")
        
        XCTAssertFalse(result2, "Arrays should not be equal")
        XCTAssertLessThan(compareTime2, 1.0, "Early exit should be very fast")
    }
}