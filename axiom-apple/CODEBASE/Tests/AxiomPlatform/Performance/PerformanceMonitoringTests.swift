import XCTest
import AxiomTesting
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomPlatform performance monitoring functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class PerformanceMonitoringTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testPerformanceMonitoringInitialization() async throws {
        let monitor = PerformanceMonitoring()
        XCTAssertNotNil(monitor, "PerformanceMonitoring should initialize correctly")
    }
    
    func testMetricsCollection() async throws {
        let monitor = PerformanceMonitoring()
        
        await monitor.startMonitoring()
        
        // Simulate some work
        try await Task.sleep(for: .milliseconds(50))
        
        await monitor.stopMonitoring()
        
        let metrics = await monitor.getCollectedMetrics()
        XCTAssertFalse(metrics.isEmpty, "Should collect performance metrics")
    }
    
    func testPerformanceBudgetValidation() async throws {
        let budget = PerformanceBudget()
        let monitor = PerformanceMonitoring()
        
        budget.maxMemoryUsage = 10 * 1024 * 1024 // 10MB
        budget.maxCPUUsage = 0.8 // 80%
        
        await monitor.setBudget(budget)
        await monitor.startMonitoring()
        
        // Simulate work within budget
        try await Task.sleep(for: .milliseconds(10))
        
        let isWithinBudget = await monitor.isWithinBudget()
        XCTAssertTrue(isWithinBudget, "Should be within performance budget")
        
        await monitor.stopMonitoring()
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceMonitoringOverhead() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let monitor = PerformanceMonitoring()
                await monitor.startMonitoring()
                
                // Monitoring overhead should be minimal
                for _ in 0..<100 {
                    _ = await monitor.getCurrentMetrics()
                }
                
                await monitor.stopMonitoring()
            },
            maxDuration: .milliseconds(50),
            maxMemoryGrowth: 512 * 1024 // 512KB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testPerformanceMonitoringMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let monitor = PerformanceMonitoring()
            
            await monitor.startMonitoring()
            
            // Simulate extended monitoring
            for _ in 0..<50 {
                _ = await monitor.getCurrentMetrics()
                try? await Task.sleep(for: .milliseconds(1))
            }
            
            await monitor.stopMonitoring()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testPerformanceMonitoringErrorHandling() async throws {
        let monitor = PerformanceMonitoring()
        
        // Test invalid budget setting
        do {
            let invalidBudget = PerformanceBudget()
            invalidBudget.maxMemoryUsage = -1 // Invalid value
            
            try await monitor.setBudgetStrict(invalidBudget)
            XCTFail("Should throw error for invalid budget")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid budget")
        }
    }
}