import XCTest
import AxiomTesting
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomPlatform graceful degradation functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class GracefulDegradationTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testGracefulDegradationInitialization() async throws {
        let degradation = GracefulDegradation()
        XCTAssertNotNil(degradation, "GracefulDegradation should initialize correctly")
    }
    
    func testPerformanceDegradationDetection() async throws {
        let degradation = GracefulDegradation()
        
        // Simulate normal performance
        await degradation.reportPerformanceMetric(.cpuUsage, value: 0.3) // 30%
        let isPerformingWell = await degradation.isPerformingWell()
        XCTAssertTrue(isPerformingWell, "Should be performing well with low CPU usage")
        
        // Simulate high CPU usage
        await degradation.reportPerformanceMetric(.cpuUsage, value: 0.9) // 90%
        let isDegraded = await degradation.isPerformanceDegraded()
        XCTAssertTrue(isDegraded, "Should detect performance degradation with high CPU usage")
    }
    
    func testAdaptivePerformanceAdjustment() async throws {
        let adaptivePerformance = AdaptivePerformance()
        
        // Test performance level adjustment
        await adaptivePerformance.adjustPerformanceLevel(.high)
        let currentLevel = await adaptivePerformance.getCurrentPerformanceLevel()
        XCTAssertEqual(currentLevel, .high, "Should set high performance level")
        
        // Simulate resource constraint
        await adaptivePerformance.reportResourceConstraint(.memoryPressure)
        let adjustedLevel = await adaptivePerformance.getCurrentPerformanceLevel()
        XCTAssertNotEqual(adjustedLevel, .high, "Should adjust performance level under memory pressure")
    }
    
    func testFeatureDegradation() async throws {
        let degradation = GracefulDegradation()
        
        // Enable all features initially
        await degradation.enableFeature(.animations)
        await degradation.enableFeature(.backgroundProcessing)
        await degradation.enableFeature(.highQualityRendering)
        
        let allEnabled = await degradation.areAllFeaturesEnabled()
        XCTAssertTrue(allEnabled, "All features should be enabled initially")
        
        // Simulate memory pressure
        await degradation.handleResourceConstraint(.memoryPressure)
        
        let animationsEnabled = await degradation.isFeatureEnabled(.animations)
        let backgroundProcessingEnabled = await degradation.isFeatureEnabled(.backgroundProcessing)
        
        // Some features should be disabled under memory pressure
        XCTAssertFalse(animationsEnabled || backgroundProcessingEnabled, 
                      "Some features should be disabled under memory pressure")
    }
    
    // MARK: - Performance Tests
    
    func testGracefulDegradationPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let degradation = GracefulDegradation()
                
                // Test rapid performance metric reporting
                for i in 0..<100 {
                    let cpuValue = Double(i % 100) / 100.0
                    await degradation.reportPerformanceMetric(.cpuUsage, value: cpuValue)
                }
                
                // Test performance level adjustments
                let levels: [PerformanceLevel] = [.low, .medium, .high, .auto]
                for level in levels {
                    await degradation.adjustToPerformanceLevel(level)
                }
            },
            maxDuration: .milliseconds(100),
            maxMemoryGrowth: 512 * 1024 // 512KB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testGracefulDegradationMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let degradation = GracefulDegradation()
            let adaptivePerformance = AdaptivePerformance()
            
            // Simulate degradation lifecycle
            for i in 0..<50 {
                await degradation.reportPerformanceMetric(.memoryUsage, value: Double(i) / 50.0)
                await adaptivePerformance.adjustPerformanceLevel(.auto)
                
                if i % 10 == 0 {
                    await degradation.handleResourceConstraint(.memoryPressure)
                }
            }
            
            await degradation.reset()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testGracefulDegradationErrorHandling() async throws {
        let degradation = GracefulDegradation()
        
        // Test invalid performance metric
        do {
            try await degradation.reportPerformanceMetricStrict(.cpuUsage, value: -1.0)
            XCTFail("Should throw error for negative performance metric")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid metric value")
        }
        
        // Test invalid performance level
        do {
            try await degradation.adjustToPerformanceLevelStrict(.invalid)
            XCTFail("Should throw error for invalid performance level")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid performance level")
        }
    }
}