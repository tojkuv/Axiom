import XCTest
import AxiomTesting
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomPlatform telemetry functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class TelemetryTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testTelemetryInitialization() async throws {
        let telemetry = Telemetry()
        XCTAssertNotNil(telemetry, "Telemetry should initialize correctly")
    }
    
    func testEventTracking() async throws {
        let telemetry = Telemetry()
        
        await telemetry.trackEvent("user_action", properties: ["button": "save"])
        
        let eventCount = await telemetry.getTrackedEventCount()
        XCTAssertEqual(eventCount, 1, "Should track one event")
        
        let events = await telemetry.getTrackedEvents()
        XCTAssertEqual(events.count, 1, "Should have one tracked event")
        
        if let event = events.first {
            XCTAssertEqual(event.name, "user_action", "Should track correct event name")
            XCTAssertEqual(event.properties["button"] as? String, "save", "Should track correct properties")
        }
    }
    
    func testMetricsCollection() async throws {
        let telemetry = Telemetry()
        
        await telemetry.recordMetric("response_time", value: 150.5)
        await telemetry.recordMetric("memory_usage", value: 64.2)
        
        let metrics = await telemetry.getCollectedMetrics()
        XCTAssertEqual(metrics.count, 2, "Should collect two metrics")
        
        let responseTimeMetric = metrics.first { $0.name == "response_time" }
        XCTAssertNotNil(responseTimeMetric, "Should find response time metric")
        XCTAssertEqual(responseTimeMetric?.value, 150.5, "Should record correct metric value")
    }
    
    func testTelemetryBatching() async throws {
        let telemetry = Telemetry()
        
        // Enable batching
        await telemetry.enableBatching(batchSize: 5)
        
        // Track multiple events
        for i in 0..<10 {
            await telemetry.trackEvent("batch_event_\(i)")
        }
        
        let batchCount = await telemetry.getBatchCount()
        XCTAssertEqual(batchCount, 2, "Should create 2 batches for 10 events with batch size 5")
    }
    
    // MARK: - Performance Tests
    
    func testTelemetryPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let telemetry = Telemetry()
                
                // Track many events rapidly
                for i in 0..<1000 {
                    await telemetry.trackEvent("perf_test_\(i)", properties: ["index": i])
                }
            },
            maxDuration: .milliseconds(500),
            maxMemoryGrowth: 2 * 1024 * 1024 // 2MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testTelemetryMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let telemetry = Telemetry()
            
            // Simulate telemetry lifecycle
            await telemetry.enableBatching(batchSize: 10)
            
            for i in 0..<50 {
                await telemetry.trackEvent("memory_test_\(i)")
                await telemetry.recordMetric("metric_\(i)", value: Double(i))
            }
            
            await telemetry.flush()
            await telemetry.clearCache()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testTelemetryErrorHandling() async throws {
        let telemetry = Telemetry()
        
        // Test tracking event with invalid data
        do {
            let invalidProperties: [String: Any] = ["key": NSObject()]
            try await telemetry.trackEventStrict("invalid_event", properties: invalidProperties)
            XCTFail("Should throw error for invalid properties")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid properties")
        }
        
        // Test recording metric with invalid value
        do {
            try await telemetry.recordMetricStrict("invalid_metric", value: Double.nan)
            XCTFail("Should throw error for NaN value")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid metric value")
        }
    }
}