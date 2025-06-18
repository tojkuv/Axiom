import XCTest
import UIKit
import CoreGraphics
@testable import AxiomCapabilityDomains
@testable import AxiomCore
@testable import AxiomCapabilities

/// Comprehensive test suite for 3D Touch capability
@available(iOS 13.0, macOS 10.15, *)
final class ThreeDTouchCapabilityTests: XCTestCase {
    
    var capability: ThreeDTouchCapability!
    var testEnvironment: AxiomCapabilityEnvironment!
    var testConfiguration: ThreeDTouchCapabilityConfiguration!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test environment
        testEnvironment = AxiomCapabilityEnvironment(
            isDebug: true,
            isLowPowerMode: false
        )
        
        // Create test configuration
        testConfiguration = ThreeDTouchCapabilityConfiguration(
            enable3DTouchSupport: true,
            enablePeekPop: true,
            enableQuickActions: true,
            enablePreviewActions: true,
            enableForceTouch: true,
            enablePressureAnalysis: true,
            enableGesturePrediction: true,
            enableRealTimeProcessing: true,
            maxConcurrentTouches: 3,
            touchTimeout: 30.0,
            enableLogging: true,
            enableMetrics: true,
            enableCaching: true,
            cacheSize: 200,
            pressureSensitivity: .medium,
            forceThreshold: 0.5,
            peekThreshold: 0.35,
            popThreshold: 0.8,
            responsiveness: .standard,
            supportedGestures: ThreeDTouchCapabilityConfiguration.TouchGesture.allCases
        )
        
        capability = ThreeDTouchCapability(
            configuration: testConfiguration,
            environment: testEnvironment
        )
    }
    
    override func tearDown() async throws {
        if let capability = capability, await capability.isAvailable {
            await capability.deactivate()
        }
        capability = nil
        testConfiguration = nil
        testEnvironment = nil
        try await super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationValidation() {
        XCTAssertTrue(testConfiguration.isValid, "Test configuration should be valid")
        
        // Test invalid configuration
        let invalidConfig = ThreeDTouchCapabilityConfiguration(
            maxConcurrentTouches: 0, // Invalid
            touchTimeout: -1.0, // Invalid
            forceThreshold: 2.0, // Invalid (> 1.0)
            peekThreshold: 0.9, // Invalid (> popThreshold)
            popThreshold: 0.8,
            supportedGestures: [] // Invalid (empty)
        )
        XCTAssertFalse(invalidConfig.isValid, "Invalid configuration should not be valid")
    }
    
    func testConfigurationMerging() {
        let baseConfig = ThreeDTouchCapabilityConfiguration()
        let updateConfig = ThreeDTouchCapabilityConfiguration(
            enableQuickActions: false,
            pressureSensitivity: .firm,
            forceThreshold: 0.7,
            responsiveness: .immediate
        )
        
        let mergedConfig = baseConfig.merged(with: updateConfig)
        
        XCTAssertFalse(mergedConfig.enableQuickActions, "Merged config should disable quick actions")
        XCTAssertEqual(mergedConfig.pressureSensitivity, .firm, "Merged config should have firm pressure sensitivity")
        XCTAssertEqual(mergedConfig.forceThreshold, 0.7, "Merged config should have updated force threshold")
        XCTAssertEqual(mergedConfig.responsiveness, .immediate, "Merged config should have immediate responsiveness")
    }
    
    func testEnvironmentAdjustment() {
        let lowPowerEnvironment = AxiomCapabilityEnvironment(isLowPowerMode: true)
        let adjustedConfig = testConfiguration.adjusted(for: lowPowerEnvironment)
        
        XCTAssertEqual(adjustedConfig.touchTimeout, min(testConfiguration.touchTimeout, 15.0), "Touch timeout should be reduced in low power mode")
        XCTAssertEqual(adjustedConfig.maxConcurrentTouches, min(testConfiguration.maxConcurrentTouches, 1), "Concurrent touches should be reduced in low power mode")
        XCTAssertEqual(adjustedConfig.cacheSize, min(testConfiguration.cacheSize, 50), "Cache size should be reduced in low power mode")
        XCTAssertFalse(adjustedConfig.enableRealTimeProcessing, "Real-time processing should be disabled in low power mode")
        XCTAssertFalse(adjustedConfig.enablePressureAnalysis, "Pressure analysis should be disabled in low power mode")
        XCTAssertEqual(adjustedConfig.responsiveness, .standard, "Responsiveness should be standard in low power mode")
    }
    
    // MARK: - Capability Lifecycle Tests
    
    func testCapabilityActivation() async throws {
        XCTAssertEqual(await capability.state, .unknown, "Initial state should be unknown")
        
        try await capability.activate()
        
        XCTAssertEqual(await capability.state, .available, "State should be available after activation")
        XCTAssertTrue(await capability.isAvailable, "Capability should be available")
    }
    
    func testCapabilityDeactivation() async throws {
        try await capability.activate()
        XCTAssertTrue(await capability.isAvailable, "Capability should be available")
        
        await capability.deactivate()
        
        XCTAssertEqual(await capability.state, .unavailable, "State should be unavailable after deactivation")
        XCTAssertFalse(await capability.isAvailable, "Capability should not be available")
    }
    
    func testCapabilitySupport() async {
        let isSupported = await capability.isSupported()
        XCTAssertTrue(isSupported, "3D Touch should be supported on iOS 9+")
    }
    
    func testPermissionRequest() async throws {
        // 3D Touch doesn't require special permissions
        try await capability.requestPermission()
        // Should not throw
    }
    
    // MARK: - 3D Touch Processing Tests
    
    func testForceTouchEvent() async throws {
        try await capability.activate()
        
        let forceTouchEvent = capability.createForceTouchEvent(
            at: CGPoint(x: 200, y: 300),
            force: 0.8,
            maximumForce: 1.0,
            pressure: 0.7
        )
        
        let result = try await capability.processInput(forceTouchEvent)
        
        XCTAssertTrue(result.success, "Force touch event processing should succeed")
        XCTAssertNil(result.error, "Force touch event should not have errors")
        XCTAssertEqual(result.processedTouch.originalEvent.eventType, .forceTouchBegan, "Event type should be forceTouchBegan")
        XCTAssertGreaterThan(result.processedTouch.normalizedForce, 0.5, "Normalized force should be significant")
        XCTAssertGreaterThan(result.processingTime, 0, "Processing time should be positive")
        XCTAssertGreaterThan(result.qualityScore, 0, "Quality score should be positive")
    }
    
    func testPeekGestureEvent() async throws {
        try await capability.activate()
        
        let peekEvent = capability.createPeekEvent(
            at: CGPoint(x: 150, y: 250),
            force: 0.4,
            maximumForce: 1.0
        )
        
        let result = try await capability.processInput(peekEvent)
        
        XCTAssertTrue(result.success, "Peek gesture event processing should succeed")
        XCTAssertEqual(result.processedTouch.originalEvent.eventType, .peekStarted, "Event type should be peekStarted")
        XCTAssertEqual(result.processedTouch.gestureState, .peeking, "Gesture state should be peeking")
        XCTAssertGreaterThan(result.gestureCount, 0, "Should recognize peek gestures")
        
        let peekGesture = result.recognizedGestures.first { $0.gestureType == .peek }
        XCTAssertNotNil(peekGesture, "Should recognize peek gesture")
        XCTAssertGreaterThan(peekGesture!.confidence, 0.8, "Peek gesture should have high confidence")
    }
    
    func testPopGestureEvent() async throws {
        try await capability.activate()
        
        let popEvent = capability.createPopEvent(
            at: CGPoint(x: 300, y: 400),
            force: 0.9,
            maximumForce: 1.0
        )
        
        let result = try await capability.processInput(popEvent)
        
        XCTAssertTrue(result.success, "Pop gesture event processing should succeed")
        XCTAssertEqual(result.processedTouch.originalEvent.eventType, .popTriggered, "Event type should be popTriggered")
        XCTAssertEqual(result.processedTouch.gestureState, .popping, "Gesture state should be popping")
        
        let popGesture = result.recognizedGestures.first { $0.gestureType == .pop }
        XCTAssertNotNil(popGesture, "Should recognize pop gesture")
        XCTAssertGreaterThan(popGesture!.confidence, 0.9, "Pop gesture should have very high confidence")
    }
    
    func testTouchClassification() async throws {
        try await capability.activate()
        
        // Test light touch
        let lightTouchEvent = capability.createForceTouchEvent(
            at: CGPoint(x: 100, y: 150),
            force: 0.2,
            pressure: 0.1
        )
        
        let lightResult = try await capability.processInput(lightTouchEvent)
        XCTAssertTrue(lightResult.success, "Light touch processing should succeed")
        XCTAssertEqual(lightResult.processedTouch.touchClassification, .lightTouch, "Should classify as light touch")
        
        // Test firm touch
        let firmTouchEvent = capability.createForceTouchEvent(
            at: CGPoint(x: 100, y: 150),
            force: 0.75,
            pressure: 0.6
        )
        
        let firmResult = try await capability.processInput(firmTouchEvent)
        XCTAssertTrue(firmResult.success, "Firm touch processing should succeed")
        XCTAssertEqual(firmResult.processedTouch.touchClassification, .firmTouch, "Should classify as firm touch")
    }
    
    func testPressureAnalysis() async throws {
        try await capability.activate()
        
        let forceTouchEvent = capability.createForceTouchEvent(
            at: CGPoint(x: 200, y: 300),
            force: 0.7,
            pressure: 0.6
        )
        
        let result = try await capability.processInput(forceTouchEvent)
        
        XCTAssertTrue(result.success, "Force touch processing should succeed")
        XCTAssertGreaterThan(result.pressureAnalysis.averagePressure, 0, "Should have positive average pressure")
        XCTAssertGreaterThan(result.pressureAnalysis.peakPressure, 0, "Should have positive peak pressure")
        XCTAssertGreaterThanOrEqual(result.pressureAnalysis.steadiness, 0, "Steadiness should be non-negative")
        XCTAssertLessThanOrEqual(result.pressureAnalysis.steadiness, 1.0, "Steadiness should be at most 1.0")
        XCTAssertGreaterThan(result.pressureAnalysis.responsiveness, 0, "Responsiveness should be positive")
        XCTAssertTrue([.linear, .exponential, .stepped, .oscillating, .irregular].contains(result.pressureAnalysis.pressurePattern), "Should have valid pressure pattern")
    }
    
    func testVelocityAndAcceleration() async throws {
        try await capability.activate()
        
        let moveEvent = ThreeDTouchInputEvent(
            touchData: ThreeDTouchInputEvent.TouchData(
                eventType: .touchMoved,
                location: CGPoint(x: 150, y: 200),
                previousLocation: CGPoint(x: 100, y: 150),
                force: 0.6,
                pressure: 0.5,
                timestamp: Date().timeIntervalSinceReferenceDate
            )
        )
        
        let result = try await capability.processInput(moveEvent)
        
        XCTAssertTrue(result.success, "Move event processing should succeed")
        XCTAssertNotNil(result.processedTouch.velocityVector, "Velocity vector should be present")
        XCTAssertNotNil(result.processedTouch.accelerationVector, "Acceleration vector should be present")
    }
    
    func testPredictionData() async throws {
        try await capability.activate()
        
        // Create event with predicted touches
        let predictedTouch1 = ThreeDTouchInputEvent.TouchData.PredictedTouch(
            location: CGPoint(x: 210, y: 310),
            force: 0.6,
            pressure: 0.5,
            timestamp: Date().timeIntervalSinceReferenceDate + 0.016,
            confidence: 0.9
        )
        
        let predictedTouch2 = ThreeDTouchInputEvent.TouchData.PredictedTouch(
            location: CGPoint(x: 220, y: 320),
            force: 0.65,
            pressure: 0.55,
            timestamp: Date().timeIntervalSinceReferenceDate + 0.032,
            confidence: 0.8
        )
        
        let touchData = ThreeDTouchInputEvent.TouchData(
            eventType: .touchMoved,
            location: CGPoint(x: 200, y: 300),
            force: 0.55,
            pressure: 0.45,
            predictedTouches: [predictedTouch1, predictedTouch2]
        )
        
        let eventWithPrediction = ThreeDTouchInputEvent(touchData: touchData)
        let result = try await capability.processInput(eventWithPrediction)
        
        XCTAssertTrue(result.success, "Event with prediction processing should succeed")
        XCTAssertNotNil(result.processedTouch.predictionData, "Prediction data should be present")
        XCTAssertEqual(result.processedTouch.predictionData!.predictedLocations.count, 2, "Should have 2 predicted locations")
        XCTAssertEqual(result.processedTouch.predictionData!.predictedForces.count, 2, "Should have 2 predicted forces")
        XCTAssertEqual(result.processedTouch.predictionData!.confidenceScores.count, 2, "Should have 2 confidence scores")
        XCTAssertGreaterThan(result.processedTouch.predictionData!.predictionTime, 0, "Prediction time should be positive")
    }
    
    func testQuickActionGesture() async throws {
        try await capability.activate()
        
        // Create edge-based force touch for quick action
        let quickActionEvent = capability.createForceTouchEvent(
            at: CGPoint(x: 30, y: 200), // Near edge
            force: 0.85,
            pressure: 0.8
        )
        
        let result = try await capability.processInput(quickActionEvent)
        
        XCTAssertTrue(result.success, "Quick action event processing should succeed")
        
        let quickActionGesture = result.recognizedGestures.first { $0.gestureType == .quickAction }
        XCTAssertNotNil(quickActionGesture, "Should recognize quick action gesture")
        XCTAssertGreaterThan(quickActionGesture!.confidence, 0.7, "Quick action gesture should have good confidence")
    }
    
    // MARK: - Performance Tests
    
    func testTouchMetrics() async throws {
        try await capability.activate()
        
        // Process multiple touch events to generate metrics
        for i in 0..<10 {
            let touchEvent = capability.createForceTouchEvent(
                at: CGPoint(x: 100 + i * 10, y: 200 + i * 5),
                force: 0.3 + Double(i) * 0.05,
                pressure: 0.2 + Double(i) * 0.04
            )
            
            let result = try await capability.processInput(touchEvent)
            XCTAssertTrue(result.success, "Touch event \(i) processing should succeed")
        }
        
        let metrics = try await capability.getMetrics()
        
        XCTAssertGreaterThan(metrics.totalTouchEvents, 0, "Should have recorded touch events")
        XCTAssertGreaterThan(metrics.successfulEvents, 0, "Should have successful events")
        XCTAssertGreaterThan(metrics.averageProcessingTime, 0, "Should have positive average processing time")
        XCTAssertEqual(metrics.failedEvents, 0, "Should have no failed events")
        XCTAssertGreaterThan(metrics.performanceStats.averageTouchesPerSession, 0, "Should have positive average touches per session")
        XCTAssertGreaterThan(metrics.performanceStats.averageForceUsage, 0, "Should have positive average force usage")
    }
    
    func testInputLatency() async throws {
        try await capability.activate()
        
        let touchEvent = capability.createForceTouchEvent(
            at: CGPoint(x: 250, y: 350),
            force: 0.7,
            pressure: 0.6
        )
        
        let result = try await capability.processInput(touchEvent)
        
        XCTAssertTrue(result.success, "Touch event processing should succeed")
        XCTAssertGreaterThan(result.inputMetrics.averageLatency, 0, "Should have positive input latency")
        XCTAssertLessThan(result.inputMetrics.averageLatency, 0.1, "Input latency should be reasonable (< 100ms)")
        XCTAssertGreaterThan(result.inputMetrics.responsiveness, 0.5, "Should have good responsiveness")
        XCTAssertGreaterThan(result.inputMetrics.accuracy, 0.5, "Should have good accuracy")
    }
    
    func testTouchTimeout() async throws {
        try await capability.activate()
        
        // Test with very short timeout
        let shortTimeoutConfig = ThreeDTouchCapabilityConfiguration(
            touchTimeout: 0.001 // 1ms timeout
        )
        
        let timeoutCapability = ThreeDTouchCapability(
            configuration: shortTimeoutConfig,
            environment: testEnvironment
        )
        
        try await timeoutCapability.activate()
        
        let touchEvent = timeoutCapability.createForceTouchEvent(at: CGPoint(x: 100, y: 150))
        
        // Operation may succeed or timeout - both are valid outcomes for this test
        do {
            let result = try await timeoutCapability.processInput(touchEvent)
            XCTAssertNotNil(result, "Result should not be nil")
        } catch {
            XCTAssertTrue(error is ThreeDTouchError, "Should throw ThreeDTouchError on timeout")
        }
        
        await timeoutCapability.deactivate()
    }
    
    // MARK: - Error Handling Tests
    
    func testUnavailableCapability() async throws {
        // Test operations on inactive capability
        do {
            let touchEvent = capability.createForceTouchEvent(at: CGPoint(x: 100, y: 150))
            _ = try await capability.processInput(touchEvent)
            XCTFail("Should throw error when capability is not activated")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError, "Should throw AxiomCapabilityError when unavailable")
        }
    }
    
    func testInvalidConfiguration() async throws {
        let invalidConfig = ThreeDTouchCapabilityConfiguration(
            maxConcurrentTouches: -1,
            touchTimeout: -5.0,
            forceThreshold: 2.0
        )
        
        do {
            try await capability.updateConfiguration(invalidConfig)
            XCTFail("Should throw error for invalid configuration")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError, "Should throw AxiomCapabilityError for invalid config")
        }
    }
    
    // MARK: - Stream Tests
    
    func testResultStream() async throws {
        try await capability.activate()
        
        let resultStream = try await capability.getResultStream()
        
        // Create expectation for stream result
        let expectation = XCTestExpectation(description: "Result stream should emit result")
        expectation.expectedFulfillmentCount = 1
        
        // Listen to stream
        Task {
            for await result in resultStream {
                XCTAssertNotNil(result, "Stream result should not be nil")
                expectation.fulfill()
                break // Exit after first result
            }
        }
        
        // Perform operation to trigger stream
        let touchEvent = capability.createForceTouchEvent(at: CGPoint(x: 300, y: 400))
        let result = try await capability.processInput(touchEvent)
        XCTAssertTrue(result.success, "Operation should succeed")
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Device Support Tests
    
    func test3DTouchAvailability() async throws {
        let isAvailable = try await capability.is3DTouchAvailable()
        XCTAssertNotNil(isAvailable, "3D Touch availability should be determinable")
    }
    
    func testForceThresholds() async {
        let thresholds = await capability.getForceThresholds()
        
        XCTAssertEqual(thresholds.peek, testConfiguration.peekThreshold, "Peek threshold should match configuration")
        XCTAssertEqual(thresholds.pop, testConfiguration.popThreshold, "Pop threshold should match configuration")
        XCTAssertEqual(thresholds.force, testConfiguration.forceThreshold, "Force threshold should match configuration")
    }
    
    func testHapticFeedbackSupport() async {
        let supportsHaptic = await capability.supportsHapticFeedback()
        XCTAssertTrue(supportsHaptic, "Should support haptic feedback")
    }
    
    func testTouchEventCreationMethods() async {
        // Test force touch event creation
        let forceTouchEvent = capability.createForceTouchEvent(
            at: CGPoint(x: 200, y: 300),
            force: 0.8,
            maximumForce: 1.0,
            pressure: 0.7
        )
        
        XCTAssertEqual(forceTouchEvent.touchData.eventType, .forceTouchBegan, "Should create force touch event")
        XCTAssertEqual(forceTouchEvent.touchData.location, CGPoint(x: 200, y: 300), "Should set correct location")
        XCTAssertEqual(forceTouchEvent.touchData.force, 0.8, "Should set correct force")
        
        // Test peek event creation
        let peekEvent = capability.createPeekEvent(
            at: CGPoint(x: 150, y: 250),
            force: 0.4,
            maximumForce: 1.0
        )
        
        XCTAssertEqual(peekEvent.touchData.eventType, .peekStarted, "Should create peek event")
        XCTAssertEqual(peekEvent.touchData.force, 0.4, "Should set correct force")
        
        // Test pop event creation
        let popEvent = capability.createPopEvent(
            at: CGPoint(x: 300, y: 400),
            force: 0.9,
            maximumForce: 1.0
        )
        
        XCTAssertEqual(popEvent.touchData.eventType, .popTriggered, "Should create pop event")
        XCTAssertEqual(popEvent.touchData.force, 0.9, "Should set correct force")
    }
    
    // MARK: - Configuration Update Tests
    
    func testConfigurationUpdate() async throws {
        try await capability.activate()
        
        let newConfig = ThreeDTouchCapabilityConfiguration(
            pressureSensitivity: .firm,
            forceThreshold: 0.7,
            peekThreshold: 0.4,
            popThreshold: 0.85,
            enableLogging: false
        )
        
        try await capability.updateConfiguration(newConfig)
        
        let updatedConfig = await capability.configuration
        XCTAssertEqual(updatedConfig.pressureSensitivity, .firm, "Pressure sensitivity should be updated")
        XCTAssertEqual(updatedConfig.forceThreshold, 0.7, "Force threshold should be updated")
        XCTAssertEqual(updatedConfig.peekThreshold, 0.4, "Peek threshold should be updated")
        XCTAssertEqual(updatedConfig.popThreshold, 0.85, "Pop threshold should be updated")
        XCTAssertFalse(updatedConfig.enableLogging, "Logging should be disabled")
    }
    
    // MARK: - Cleanup Tests
    
    func testMetricsClearance() async throws {
        try await capability.activate()
        
        // Generate some metrics
        let touchEvent = capability.createForceTouchEvent(at: CGPoint(x: 100, y: 150))
        let result = try await capability.processInput(touchEvent)
        XCTAssertTrue(result.success, "Touch event processing should succeed")
        
        let metricsBeforeClear = try await capability.getMetrics()
        XCTAssertGreaterThan(metricsBeforeClear.totalTouchEvents, 0, "Should have metrics before clear")
        
        // Clear metrics
        try await capability.clearMetrics()
        
        let metricsAfterClear = try await capability.getMetrics()
        XCTAssertEqual(metricsAfterClear.totalTouchEvents, 0, "Metrics should be cleared")
    }
    
    func testCacheClearance() async throws {
        try await capability.activate()
        
        // Clear cache should not throw
        try await capability.clearCache()
    }
    
    func testEventHistory() async throws {
        try await capability.activate()
        
        // Create a few touch events
        for i in 0..<3 {
            let touchEvent = capability.createForceTouchEvent(
                at: CGPoint(x: 100 + i * 50, y: 150 + i * 30),
                force: 0.5 + Double(i) * 0.1
            )
            let result = try await capability.processInput(touchEvent)
            XCTAssertTrue(result.success, "Touch event \(i) should succeed")
        }
        
        let history = try await capability.getEventHistory()
        XCTAssertGreaterThan(history.count, 0, "Should have event history")
        
        // Test history with date filter
        let recentHistory = try await capability.getEventHistory(since: Date().addingTimeInterval(-10))
        XCTAssertLessThanOrEqual(recentHistory.count, history.count, "Recent history should be subset of total history")
    }
    
    func testActiveEvents() async throws {
        try await capability.activate()
        
        let activeEvents = try await capability.getActiveEvents()
        XCTAssertNotNil(activeEvents, "Active events should not be nil")
        // Note: In test environment, there may be no active events
    }
}

// MARK: - Test Extensions

extension ThreeDTouchCapabilityTests {
    
    /// Helper method to create test touch events
    private func createTestTouchEvents(count: Int) async throws {
        for i in 0..<count {
            let touchEvent = capability.createForceTouchEvent(
                at: CGPoint(x: 100 + i * 10, y: 150 + i * 5),
                force: 0.3 + Double(i) * 0.05,
                pressure: 0.2 + Double(i) * 0.04
            )
            
            let result = try await capability.processInput(touchEvent)
            XCTAssertTrue(result.success, "Test touch event \(i) should succeed")
        }
    }
    
    /// Helper method to verify 3D Touch input result
    private func verifyThreeDTouchResult(_ result: ThreeDTouchInputResult, shouldSucceed: Bool = true) {
        XCTAssertEqual(result.success, shouldSucceed, "Operation success should match expectation")
        
        if shouldSucceed {
            XCTAssertNil(result.error, "Successful operation should not have error")
            XCTAssertGreaterThan(result.processingTime, 0, "Processing time should be positive")
            XCTAssertGreaterThan(result.qualityScore, 0, "Quality score should be positive")
            XCTAssertNotNil(result.pressureAnalysis, "Pressure analysis should be present")
            XCTAssertNotNil(result.inputMetrics, "Input metrics should be present")
        } else {
            XCTAssertNotNil(result.error, "Failed operation should have error")
        }
        
        XCTAssertGreaterThanOrEqual(result.processedTouch.normalizedForce, 0.0, "Normalized force should be non-negative")
        XCTAssertLessThanOrEqual(result.processedTouch.normalizedForce, 1.0, "Normalized force should be at most 1.0")
    }
    
    /// Helper method to create complex touch event with coalesced touches
    private func createComplexTouchEvent() -> ThreeDTouchInputEvent {
        let coalescedTouch1 = ThreeDTouchInputEvent.TouchData.CoalescedTouch(
            location: CGPoint(x: 195, y: 295),
            force: 0.55,
            pressure: 0.45,
            timestamp: Date().timeIntervalSinceReferenceDate - 0.016
        )
        
        let coalescedTouch2 = ThreeDTouchInputEvent.TouchData.CoalescedTouch(
            location: CGPoint(x: 198, y: 298),
            force: 0.58,
            pressure: 0.48,
            timestamp: Date().timeIntervalSinceReferenceDate - 0.008
        )
        
        let predictedTouch = ThreeDTouchInputEvent.TouchData.PredictedTouch(
            location: CGPoint(x: 205, y: 305),
            force: 0.65,
            pressure: 0.55,
            timestamp: Date().timeIntervalSinceReferenceDate + 0.016,
            confidence: 0.85
        )
        
        let deviceInfo = ThreeDTouchInputEvent.TouchData.DeviceInfo(
            supports3DTouch: true,
            supportsForceTouch: true,
            maximumForce: 1.0,
            deviceModel: "iPhone 6s",
            screenSize: CGSize(width: 375, height: 667),
            pixelDensity: 2.0
        )
        
        let touchData = ThreeDTouchInputEvent.TouchData(
            eventType: .touchMoved,
            location: CGPoint(x: 200, y: 300),
            previousLocation: CGPoint(x: 190, y: 290),
            force: 0.6,
            maximumPossibleForce: 1.0,
            pressure: 0.5,
            majorRadius: 10.0,
            majorRadiusTolerance: 1.0,
            phase: .moved,
            touchType: .direct,
            deviceInfo: deviceInfo,
            timestamp: Date().timeIntervalSinceReferenceDate,
            coalescedTouches: [coalescedTouch1, coalescedTouch2],
            predictedTouches: [predictedTouch]
        )
        
        return ThreeDTouchInputEvent(touchData: touchData)
    }
}