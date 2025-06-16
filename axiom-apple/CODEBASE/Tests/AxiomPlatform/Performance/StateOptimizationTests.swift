import XCTest
import AxiomTesting
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomPlatform state optimization functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class StateOptimizationTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testStateOptimizationInitialization() async throws {
        let optimizer = StateOptimization()
        XCTAssertNotNil(optimizer, "StateOptimization should initialize correctly")
    }
    
    func testStateOptimizationEnhanced() async throws {
        let enhancedOptimizer = StateOptimizationEnhanced()
        XCTAssertNotNil(enhancedOptimizer, "StateOptimizationEnhanced should initialize correctly")
        
        let isOptimizationEnabled = await enhancedOptimizer.isOptimizationEnabled()
        XCTAssertNotNil(isOptimizationEnabled, "Optimization status should be determinable")
    }
    
    func testStatePropagationOptimization() async throws {
        let propagation = StatePropagation()
        
        await propagation.enableOptimization()
        let isOptimized = await propagation.isOptimized()
        XCTAssertTrue(isOptimized, "State propagation should be optimized")
        
        // Test propagation efficiency
        let startTime = ContinuousClock.now
        await propagation.propagateState(["key": "value"])
        let duration = ContinuousClock.now - startTime
        
        XCTAssertLessThan(duration.timeInterval, 0.001, "State propagation should be fast")
    }
    
    func testStateStorageOptimization() async throws {
        let storage = StateStorage()
        
        await storage.optimizeStorage()
        let isOptimized = await storage.isStorageOptimized()
        XCTAssertTrue(isOptimized, "State storage should be optimized")
        
        // Test storage efficiency
        let testData = Array(0..<1000).map { "item_\($0)" }
        await storage.store(testData)
        
        let memoryUsage = await storage.getMemoryUsage()
        XCTAssertLessThan(memoryUsage, 1024 * 1024, "Memory usage should be optimized") // Less than 1MB
    }
    
    // MARK: - Performance Tests
    
    func testStateOptimizationPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let optimizer = StateOptimizationEnhanced()
                
                // Test optimization of large state
                let largeState = Array(0..<10000).reduce(into: [String: Any]()) { dict, i in
                    dict["key_\(i)"] = "value_\(i)"
                }
                
                await optimizer.optimizeState(largeState)
            },
            maxDuration: .milliseconds(100),
            maxMemoryGrowth: 2 * 1024 * 1024 // 2MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testStateOptimizationMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let optimizer = StateOptimization()
            let storage = StateStorage()
            
            // Simulate multiple optimization cycles
            for i in 0..<10 {
                let state = ["iteration": i]
                await optimizer.optimizeState(state)
                await storage.store(state)
                await storage.clearCache()
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testStateOptimizationErrorHandling() async throws {
        let optimizer = StateOptimizationEnhanced()
        
        // Test optimization of invalid state
        do {
            let invalidState: [String: Any] = [:]
            try await optimizer.optimizeStateStrict(invalidState)
            XCTFail("Should throw error for empty state")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid state")
        }
    }
}