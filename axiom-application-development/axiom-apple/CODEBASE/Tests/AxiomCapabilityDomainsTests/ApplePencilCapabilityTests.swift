import XCTest
import PencilKit
import UIKit
import CoreGraphics
@testable import AxiomCapabilityDomains
@testable import AxiomCore
@testable import AxiomCapabilities

/// Comprehensive test suite for Apple Pencil capability
@available(iOS 13.0, macOS 10.15, *)
final class ApplePencilCapabilityTests: XCTestCase {
    
    var capability: ApplePencilCapability!
    var testEnvironment: AxiomCapabilityEnvironment!
    var testConfiguration: ApplePencilCapabilityConfiguration!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test environment
        testEnvironment = AxiomCapabilityEnvironment(
            isDebug: true,
            isLowPowerMode: false
        )
        
        // Create test configuration
        testConfiguration = ApplePencilCapabilityConfiguration(
            enableApplePencilSupport: true,
            enablePressureSensitivity: true,
            enableTiltSensitivity: true,
            enableAzimuthSensitivity: true,
            enableDoubleTapGesture: true,
            enablePencilGestures: true,
            enableDrawingMode: true,
            enableAnnotationMode: true,
            enablePrecisionMode: true,
            enableRealTimeInput: true,
            maxConcurrentInputs: 3,
            inputTimeout: 30.0,
            enableLogging: true,
            enableMetrics: true,
            enableCaching: true,
            cacheSize: 500,
            pressureSensitivity: .high,
            tiltSensitivity: .medium,
            inputSampling: .high,
            pencilGeneration: .any,
            inputLatencyTarget: 0.020,
            supportedModes: ApplePencilCapabilityConfiguration.InputMode.allCases
        )
        
        capability = ApplePencilCapability(
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
        let invalidConfig = ApplePencilCapabilityConfiguration(
            maxConcurrentInputs: 0, // Invalid
            inputTimeout: -1.0, // Invalid
            inputLatencyTarget: -0.1, // Invalid
            supportedModes: [] // Invalid (empty)
        )
        XCTAssertFalse(invalidConfig.isValid, "Invalid configuration should not be valid")
    }
    
    func testConfigurationMerging() {
        let baseConfig = ApplePencilCapabilityConfiguration()
        let updateConfig = ApplePencilCapabilityConfiguration(
            enableDoubleTapGesture: false,
            pressureSensitivity: .maximum,
            tiltSensitivity: .high,
            inputSampling: .ultra
        )
        
        let mergedConfig = baseConfig.merged(with: updateConfig)
        
        XCTAssertFalse(mergedConfig.enableDoubleTapGesture, "Merged config should disable double tap gesture")
        XCTAssertEqual(mergedConfig.pressureSensitivity, .maximum, "Merged config should have maximum pressure sensitivity")
        XCTAssertEqual(mergedConfig.tiltSensitivity, .high, "Merged config should have high tilt sensitivity")
        XCTAssertEqual(mergedConfig.inputSampling, .ultra, "Merged config should have ultra input sampling")
    }
    
    func testEnvironmentAdjustment() {
        let lowPowerEnvironment = AxiomCapabilityEnvironment(isLowPowerMode: true)
        let adjustedConfig = testConfiguration.adjusted(for: lowPowerEnvironment)
        
        XCTAssertEqual(adjustedConfig.inputTimeout, min(testConfiguration.inputTimeout, 15.0), "Input timeout should be reduced in low power mode")
        XCTAssertEqual(adjustedConfig.maxConcurrentInputs, min(testConfiguration.maxConcurrentInputs, 1), "Max concurrent inputs should be reduced in low power mode")
        XCTAssertFalse(adjustedConfig.enableRealTimeInput, "Real-time input should be disabled in low power mode")
        XCTAssertEqual(adjustedConfig.inputSampling, .standard, "Input sampling should be standard in low power mode")
        XCTAssertEqual(adjustedConfig.inputLatencyTarget, min(testConfiguration.inputLatencyTarget, 0.050), "Latency target should be relaxed in low power mode")
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
        XCTAssertTrue(isSupported, "Apple Pencil should be supported on iOS 9.1+")
    }
    
    func testPermissionRequest() async throws {
        // Apple Pencil doesn't require special permissions
        try await capability.requestPermission()
        // Should not throw
    }
    
    // MARK: - Pencil Input Processing Tests
    
    func testDrawingEvent() async throws {
        try await capability.activate()
        
        let drawingEvent = capability.createDrawingEvent(
            at: CGPoint(x: 200, y: 300),
            pressure: 0.7,
            tilt: 0.3,
            azimuth: 1.2
        )
        
        let result = try await capability.processInput(drawingEvent)
        
        XCTAssertTrue(result.success, "Drawing event processing should succeed")
        XCTAssertNil(result.error, "Drawing event should not have errors")
        XCTAssertEqual(result.processedInput.originalEvent.eventType, .moved, "Event type should be moved")
        XCTAssertEqual(result.processedInput.inputMode, .drawing, "Input mode should be drawing")
        XCTAssertGreaterThan(result.processingTime, 0, "Processing time should be positive")
        XCTAssertGreaterThan(result.qualityScore, 0, "Quality score should be positive")
    }
    
    func testPencilGestureEvent() async throws {
        try await capability.activate()
        
        let gestureEvent = capability.createGestureEvent(
            gestureType: .doubleTapped,
            at: CGPoint(x: 150, y: 250)
        )
        
        let result = try await capability.processInput(gestureEvent)
        
        XCTAssertTrue(result.success, "Gesture event processing should succeed")
        XCTAssertEqual(result.processedInput.originalEvent.eventType, .doubleTapped, "Event type should be doubleTapped")
        XCTAssertEqual(result.processedInput.inputMode, .gesture, "Input mode should be gesture")
        XCTAssertGreaterThan(result.gestureCount, 0, "Should recognize pencil gestures")
        
        let doubleTapGesture = result.recognizedGestures.first { $0.gestureType == .doubleTap }
        XCTAssertNotNil(doubleTapGesture, "Should recognize double tap gesture")
        XCTAssertGreaterThan(doubleTapGesture!.confidence, 0.8, "Double tap gesture should have high confidence")
    }
    
    func testPressureSensitivity() async throws {
        try await capability.activate()
        
        // Test high pressure drawing
        let highPressureEvent = capability.createDrawingEvent(
            at: CGPoint(x: 100, y: 150),
            pressure: 0.95,
            tilt: 0.1,
            azimuth: 0.5
        )
        
        let highPressureResult = try await capability.processInput(highPressureEvent)
        
        XCTAssertTrue(highPressureResult.success, "High pressure event processing should succeed")
        XCTAssertEqual(highPressureResult.processedInput.inputMode, .drawing, "High pressure should trigger drawing mode")
        XCTAssertGreaterThan(highPressureResult.processedInput.adjustedPressure, 0.8, "Adjusted pressure should be high")
        
        // Test light pressure for precision mode
        let lightPressureEvent = capability.createDrawingEvent(
            at: CGPoint(x: 100, y: 150),
            pressure: 0.15,
            tilt: 0.1,
            azimuth: 0.5
        )
        
        let lightPressureResult = try await capability.processInput(lightPressureEvent)
        
        XCTAssertTrue(lightPressureResult.success, "Light pressure event processing should succeed")
        XCTAssertEqual(lightPressureResult.processedInput.inputMode, .precision, "Light pressure should trigger precision mode")
    }
    
    func testTiltAndAzimuthCalibration() async throws {
        try await capability.activate()
        
        let tiltedEvent = capability.createDrawingEvent(
            at: CGPoint(x: 300, y: 400),
            pressure: 0.6,
            tilt: 1.0, // Significant tilt
            azimuth: 2.5 // Specific azimuth angle
        )
        
        let result = try await capability.processInput(tiltedEvent)
        
        XCTAssertTrue(result.success, "Tilted pencil event processing should succeed")
        XCTAssertGreaterThan(result.processedInput.calibratedTilt, 0, "Calibrated tilt should be positive")
        XCTAssertGreaterThan(result.processedInput.calibratedAzimuth, 0, "Calibrated azimuth should be positive")
        
        // Check for tilt gesture recognition
        let tiltGesture = result.recognizedGestures.first { $0.gestureType == .tiltGesture }
        if result.processedInput.calibratedTilt > 0.8 {
            XCTAssertNotNil(tiltGesture, "Should recognize tilt gesture for highly tilted pencil")
        }
    }
    
    func testStrokeAnalysis() async throws {
        try await capability.activate()
        
        // Simulate a stroke by processing multiple events
        let strokeEvents = [
            capability.createDrawingEvent(at: CGPoint(x: 100, y: 200), pressure: 0.5),
            capability.createDrawingEvent(at: CGPoint(x: 120, y: 220), pressure: 0.6),
            capability.createDrawingEvent(at: CGPoint(x: 140, y: 240), pressure: 0.7),
            capability.createDrawingEvent(at: CGPoint(x: 160, y: 260), pressure: 0.6),
            capability.createDrawingEvent(at: CGPoint(x: 180, y: 280), pressure: 0.5)
        ]
        
        var lastResult: ApplePencilInputResult?
        for event in strokeEvents {
            lastResult = try await capability.processInput(event)
            XCTAssertTrue(lastResult!.success, "Stroke event processing should succeed")
        }
        
        guard let result = lastResult else {
            XCTFail("Should have processed stroke events")
            return
        }
        
        XCTAssertGreaterThan(result.strokeAnalysis.strokeCount, 0, "Should have stroke count")
        XCTAssertGreaterThan(result.strokeAnalysis.averageStrokeLength, 0, "Should have positive average stroke length")
        XCTAssertGreaterThan(result.strokeAnalysis.averagePressure, 0, "Should have positive average pressure")
        XCTAssertGreaterThan(result.strokeAnalysis.smoothnessScore, 0, "Should have positive smoothness score")
        XCTAssertGreaterThan(result.strokeAnalysis.precisionScore, 0, "Should have positive precision score")
        XCTAssertGreaterThan(result.strokeAnalysis.consistencyScore, 0, "Should have positive consistency score")
    }
    
    func testPredictionData() async throws {
        try await capability.activate()
        
        // Create event with predicted inputs
        let predictedInput1 = ApplePencilInputEvent.PencilData.PredictedInput(
            location: CGPoint(x: 210, y: 310),
            pressure: 0.6,
            altitudeAngle: 0.2,
            azimuthAngle: 1.0,
            timestamp: Date().timeIntervalSinceReferenceDate + 0.016,
            confidence: 0.9
        )
        
        let predictedInput2 = ApplePencilInputEvent.PencilData.PredictedInput(
            location: CGPoint(x: 220, y: 320),
            pressure: 0.65,
            altitudeAngle: 0.25,
            azimuthAngle: 1.1,
            timestamp: Date().timeIntervalSinceReferenceDate + 0.032,
            confidence: 0.8
        )
        
        let pencilInfo = ApplePencilInputEvent.PencilData.PencilInfo(
            pencilType: .applePencil2,
            generation: .secondGeneration
        )
        
        let pencilData = ApplePencilInputEvent.PencilData(
            eventType: .moved,
            location: CGPoint(x: 200, y: 300),
            pressure: 0.55,
            altitudeAngle: 0.15,
            azimuthAngle: 0.9,
            pencilInfo: pencilInfo,
            timestamp: Date().timeIntervalSinceReferenceDate,
            predictedInputs: [predictedInput1, predictedInput2]
        )
        
        let eventWithPrediction = ApplePencilInputEvent(pencilData: pencilData)
        
        let result = try await capability.processInput(eventWithPrediction)
        
        XCTAssertTrue(result.success, "Event with prediction processing should succeed")
        XCTAssertNotNil(result.processedInput.predictionData, "Prediction data should be present")
        XCTAssertEqual(result.processedInput.predictionData!.predictedPoints.count, 2, "Should have 2 predicted points")
        XCTAssertEqual(result.processedInput.predictionData!.confidenceScores.count, 2, "Should have 2 confidence scores")
        XCTAssertGreaterThan(result.processedInput.predictionData!.predictionDistance, 0, "Prediction distance should be positive")
    }
    
    // MARK: - Performance Tests
    
    func testInputMetrics() async throws {
        try await capability.activate()
        
        // Process multiple events to generate metrics
        for i in 0..<15 {
            let event = capability.createDrawingEvent(
                at: CGPoint(x: 100 + i * 10, y: 200 + i * 5),
                pressure: 0.5 + Float(i) * 0.02,
                tilt: 0.1 + Float(i) * 0.05,
                azimuth: Float(i) * 0.1
            )
            
            let result = try await capability.processInput(event)
            XCTAssertTrue(result.success, "Event \(i) processing should succeed")
        }
        
        let metrics = try await capability.getMetrics()
        
        XCTAssertGreaterThan(metrics.totalInputEvents, 0, "Should have recorded events")
        XCTAssertGreaterThan(metrics.successfulEvents, 0, "Should have successful events")
        XCTAssertGreaterThan(metrics.averageProcessingTime, 0, "Should have positive average processing time")
        XCTAssertEqual(metrics.failedEvents, 0, "Should have no failed events")
        XCTAssertGreaterThan(metrics.performanceStats.averageStrokesPerSession, 0, "Should have positive average strokes per session")
        XCTAssertGreaterThan(metrics.performanceStats.averagePressureSensitivity, 0, "Should have positive average pressure sensitivity")
    }
    
    func testInputLatency() async throws {
        try await capability.activate()
        
        let event = capability.createDrawingEvent(
            at: CGPoint(x: 250, y: 350),
            pressure: 0.8,
            tilt: 0.2,
            azimuth: 1.5
        )
        
        let result = try await capability.processInput(event)
        
        XCTAssertTrue(result.success, "Event processing should succeed")
        XCTAssertGreaterThan(result.inputMetrics.averageLatency, 0, "Should have positive input latency")
        XCTAssertLessThan(result.inputMetrics.averageLatency, 0.1, "Input latency should be reasonable (< 100ms)")
        XCTAssertGreaterThan(result.inputMetrics.responsiveness, 0.5, "Should have good responsiveness")
    }
    
    // MARK: - Error Handling Tests
    
    func testUnavailableCapability() async throws {
        // Test operations on inactive capability
        do {
            let event = capability.createDrawingEvent(at: CGPoint(x: 100, y: 150))
            _ = try await capability.processInput(event)
            XCTFail("Should throw error when capability is not activated")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError, "Should throw AxiomCapabilityError when unavailable")
        }
    }
    
    func testInvalidConfiguration() async throws {
        let invalidConfig = ApplePencilCapabilityConfiguration(
            maxConcurrentInputs: -1,
            inputTimeout: -5.0,
            inputLatencyTarget: -0.1
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
        let event = capability.createDrawingEvent(at: CGPoint(x: 300, y: 400))
        let result = try await capability.processInput(event)
        XCTAssertTrue(result.success, "Operation should succeed")
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Pencil Status Tests
    
    func testPencilConnection() async throws {
        try await capability.activate()
        
        let isConnected = try await capability.isPencilConnected()
        // Note: In test environment, this will likely be false
        XCTAssertFalse(isConnected, "Should have no connected pencil in test environment")
    }
    
    func testPencilBatteryLevel() async throws {
        try await capability.activate()
        
        let batteryLevel = try await capability.getPencilBatteryLevel()
        // Note: In test environment, this will likely be nil
        XCTAssertNil(batteryLevel, "Should have no battery level in test environment")
    }
    
    func testSupportedPencilGeneration() async {
        let supportedGeneration = await capability.getSupportedPencilGeneration()
        XCTAssertEqual(supportedGeneration, testConfiguration.pencilGeneration, "Should return configured pencil generation")
    }
    
    // MARK: - Configuration Update Tests
    
    func testConfigurationUpdate() async throws {
        try await capability.activate()
        
        let newConfig = ApplePencilCapabilityConfiguration(
            pressureSensitivity: .maximum,
            tiltSensitivity: .high,
            inputSampling: .ultra,
            enableLogging: false
        )
        
        try await capability.updateConfiguration(newConfig)
        
        let updatedConfig = await capability.configuration
        XCTAssertEqual(updatedConfig.pressureSensitivity, .maximum, "Pressure sensitivity should be updated")
        XCTAssertEqual(updatedConfig.tiltSensitivity, .high, "Tilt sensitivity should be updated")
        XCTAssertEqual(updatedConfig.inputSampling, .ultra, "Input sampling should be updated")
        XCTAssertFalse(updatedConfig.enableLogging, "Logging should be disabled")
    }
    
    // MARK: - Cleanup Tests
    
    func testMetricsClearance() async throws {
        try await capability.activate()
        
        // Generate some metrics
        let event = capability.createDrawingEvent(at: CGPoint(x: 100, y: 150))
        let result = try await capability.processInput(event)
        XCTAssertTrue(result.success, "Event processing should succeed")
        
        let metricsBeforeClear = try await capability.getMetrics()
        XCTAssertGreaterThan(metricsBeforeClear.totalInputEvents, 0, "Should have metrics before clear")
        
        // Clear metrics
        try await capability.clearMetrics()
        
        let metricsAfterClear = try await capability.getMetrics()
        XCTAssertEqual(metricsAfterClear.totalInputEvents, 0, "Metrics should be cleared")
    }
    
    func testCacheClearance() async throws {
        try await capability.activate()
        
        // Clear cache should not throw
        try await capability.clearCache()
    }
}

// MARK: - Test Extensions

extension ApplePencilCapabilityTests {
    
    /// Helper method to create test pencil stroke
    private func createTestStroke(pointCount: Int) async throws -> ApplePencilInputResult {
        var lastResult: ApplePencilInputResult?
        
        for i in 0..<pointCount {
            let event = capability.createDrawingEvent(
                at: CGPoint(x: 100 + i * 5, y: 200 + i * 3),
                pressure: 0.5 + Float(i) * 0.05,
                tilt: 0.1 + Float(i) * 0.02,
                azimuth: Float(i) * 0.1
            )
            
            lastResult = try await capability.processInput(event)
            XCTAssertTrue(lastResult!.success, "Stroke point \(i) processing should succeed")
        }
        
        guard let result = lastResult else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No stroke result"])
        }
        
        return result
    }
    
    /// Helper method to verify pencil input result
    private func verifyPencilInputResult(_ result: ApplePencilInputResult, shouldSucceed: Bool = true) {
        XCTAssertEqual(result.success, shouldSucceed, "Operation success should match expectation")
        
        if shouldSucceed {
            XCTAssertNil(result.error, "Successful operation should not have error")
            XCTAssertGreaterThan(result.processingTime, 0, "Processing time should be positive")
            XCTAssertGreaterThan(result.qualityScore, 0, "Quality score should be positive")
        } else {
            XCTAssertNotNil(result.error, "Failed operation should have error")
        }
        
        XCTAssertNotNil(result.inputMetrics, "Operation should have metrics")
        XCTAssertNotNil(result.strokeAnalysis, "Operation should have stroke analysis")
    }
}