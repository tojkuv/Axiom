import XCTest
import GameController
@testable import AxiomCapabilityDomains
@testable import AxiomCore
@testable import AxiomCapabilities

/// Comprehensive test suite for Game Controller capability
@available(iOS 13.0, macOS 10.15, *)
final class GameControllerCapabilityTests: XCTestCase {
    
    var capability: GameControllerCapability!
    var testEnvironment: AxiomCapabilityEnvironment!
    var testConfiguration: GameControllerCapabilityConfiguration!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test environment
        testEnvironment = AxiomCapabilityEnvironment(
            isDebug: true,
            isLowPowerMode: false
        )
        
        // Create test configuration
        testConfiguration = GameControllerCapabilityConfiguration(
            enableGameControllerSupport: true,
            enableControllerDiscovery: true,
            enableHapticFeedback: true,
            enableMotionSensing: true,
            enableBatteryMonitoring: true,
            enableProfileManagement: true,
            enableInputRecording: false,
            enableRealTimeInput: true,
            maxConcurrentControllers: 4,
            inputTimeout: 30.0,
            enableLogging: true,
            enableMetrics: true,
            enableCaching: true,
            cacheSize: 200,
            inputSensitivity: .normal,
            deadZoneThreshold: 0.15,
            hapticIntensity: 1.0,
            inputPollingRate: .standard,
            controllerPriority: .firstConnected,
            supportedControllers: GameControllerCapabilityConfiguration.ControllerType.allCases
        )
        
        capability = GameControllerCapability(
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
        let invalidConfig = GameControllerCapabilityConfiguration(
            maxConcurrentControllers: 0, // Invalid
            inputTimeout: -1.0, // Invalid
            deadZoneThreshold: 2.0, // Invalid (> 1.0)
            hapticIntensity: -0.5, // Invalid (< 0.0)
            supportedControllers: [] // Invalid (empty)
        )
        XCTAssertFalse(invalidConfig.isValid, "Invalid configuration should not be valid")
    }
    
    func testConfigurationMerging() {
        let baseConfig = GameControllerCapabilityConfiguration()
        let updateConfig = GameControllerCapabilityConfiguration(
            enableHapticFeedback: false,
            inputSensitivity: .high,
            deadZoneThreshold: 0.25,
            hapticIntensity: 0.8
        )
        
        let mergedConfig = baseConfig.merged(with: updateConfig)
        
        XCTAssertFalse(mergedConfig.enableHapticFeedback, "Merged config should disable haptic feedback")
        XCTAssertEqual(mergedConfig.inputSensitivity, .high, "Merged config should have high input sensitivity")
        XCTAssertEqual(mergedConfig.deadZoneThreshold, 0.25, "Merged config should have updated dead zone threshold")
        XCTAssertEqual(mergedConfig.hapticIntensity, 0.8, "Merged config should have updated haptic intensity")
    }
    
    func testEnvironmentAdjustment() {
        let lowPowerEnvironment = AxiomCapabilityEnvironment(isLowPowerMode: true)
        let adjustedConfig = testConfiguration.adjusted(for: lowPowerEnvironment)
        
        XCTAssertEqual(adjustedConfig.inputTimeout, min(testConfiguration.inputTimeout, 15.0), "Input timeout should be reduced in low power mode")
        XCTAssertEqual(adjustedConfig.maxConcurrentControllers, min(testConfiguration.maxConcurrentControllers, 2), "Max controllers should be reduced in low power mode")
        XCTAssertFalse(adjustedConfig.enableHapticFeedback, "Haptic feedback should be disabled in low power mode")
        XCTAssertEqual(adjustedConfig.inputPollingRate, .standard, "Polling rate should be standard in low power mode")
        XCTAssertEqual(adjustedConfig.inputSensitivity, .low, "Input sensitivity should be low in low power mode")
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
        XCTAssertTrue(isSupported, "Game Controller should be supported on iOS 13+")
    }
    
    func testPermissionRequest() async throws {
        // Game Controller doesn't require special permissions
        try await capability.requestPermission()
        // Should not throw
    }
    
    // MARK: - Controller Input Processing Tests
    
    func testButtonPressEvent() async throws {
        try await capability.activate()
        
        let buttonStates = GameControllerInputEvent.InputData.ButtonStates(
            buttonA: true,
            buttonB: false,
            buttonX: false,
            buttonY: false
        )
        
        let buttonEvent = capability.createButtonEvent(
            controllerId: "test-controller-1",
            controllerType: .mfi,
            buttonStates: buttonStates
        )
        
        let result = try await capability.processInput(buttonEvent)
        
        XCTAssertTrue(result.success, "Button press event processing should succeed")
        XCTAssertNil(result.error, "Button press event should not have errors")
        XCTAssertEqual(result.processedInput.originalEvent.eventType, .buttonPressed, "Event type should be buttonPressed")
        XCTAssertTrue(result.processedInput.filteredInput.deadZoneApplied, "Dead zone filtering should be applied")
        XCTAssertGreaterThan(result.processingTime, 0, "Processing time should be positive")
    }
    
    func testAnalogStickEvent() async throws {
        try await capability.activate()
        
        let leftThumbstick = GameControllerInputEvent.InputData.AnalogStates.ThumbstickData(
            x: 0.8,
            y: 0.6,
            magnitude: 1.0,
            angle: 0.0,
            isPressed: false
        )
        
        let rightThumbstick = GameControllerInputEvent.InputData.AnalogStates.ThumbstickData(
            x: 0.0,
            y: 0.0,
            magnitude: 0.0,
            angle: 0.0,
            isPressed: false
        )
        
        let analogStates = GameControllerInputEvent.InputData.AnalogStates(
            leftThumbstick: leftThumbstick,
            rightThumbstick: rightThumbstick,
            leftTrigger: 0.5,
            rightTrigger: 0.0
        )
        
        let analogEvent = capability.createAnalogEvent(
            controllerId: "test-controller-1",
            controllerType: .xbox,
            analogStates: analogStates
        )
        
        let result = try await capability.processInput(analogEvent)
        
        XCTAssertTrue(result.success, "Analog stick event processing should succeed")
        XCTAssertEqual(result.processedInput.originalEvent.eventType, .analogChanged, "Event type should be analogChanged")
        XCTAssertEqual(result.processedInput.contextualInput.inputPattern, .analog, "Input pattern should be analog")
        XCTAssertNotNil(result.processedInput.filteredInput.filteredAnalog, "Filtered analog data should be present")
    }
    
    func testMotionEvent() async throws {
        try await capability.activate()
        
        let motionData = GameControllerInputEvent.InputData.MotionData(
            gravity: SIMD3<Double>(0.0, -1.0, 0.0),
            acceleration: SIMD3<Double>(0.1, -0.9, 0.05),
            rotationRate: SIMD3<Double>(0.0, 0.0, 0.0),
            attitude: SIMD4<Double>(0.0, 0.0, 0.0, 1.0),
            timestamp: Date().timeIntervalSinceReferenceDate
        )
        
        let controllerInfo = GameControllerInputEvent.InputData.ControllerInfo(
            controllerType: .playstation,
            vendorName: "Sony",
            productCategory: "DualShock",
            deviceHash: "test-ps-controller",
            isWireless: true,
            supportsHaptics: true,
            supportsMotion: true,
            playerIndex: 0
        )
        
        let inputData = GameControllerInputEvent.InputData(
            eventType: .motionUpdate,
            controllerInfo: controllerInfo,
            motionData: motionData
        )
        
        let motionEvent = GameControllerInputEvent(controllerId: "test-ps-controller", inputData: inputData)
        
        let result = try await capability.processInput(motionEvent)
        
        XCTAssertTrue(result.success, "Motion event processing should succeed")
        XCTAssertEqual(result.processedInput.originalEvent.eventType, .motionUpdate, "Event type should be motionUpdate")
        XCTAssertEqual(result.processedInput.contextualInput.inputPattern, .motion, "Input pattern should be motion")
    }
    
    func testGestureRecognition() async throws {
        try await capability.activate()
        
        // Create button combo event
        let buttonStates = GameControllerInputEvent.InputData.ButtonStates(
            buttonA: true,
            buttonB: true,
            buttonX: false,
            buttonY: false
        )
        
        let comboEvent = capability.createButtonEvent(
            controllerId: "test-controller-1",
            controllerType: .mfi,
            buttonStates: buttonStates
        )
        
        let result = try await capability.processInput(comboEvent)
        
        XCTAssertTrue(result.success, "Button combo event processing should succeed")
        XCTAssertGreaterThan(result.gestureCount, 0, "Should recognize button combo gestures")
        
        let buttonComboGesture = result.recognizedGestures.first { $0.gestureType == .buttonCombo }
        XCTAssertNotNil(buttonComboGesture, "Should recognize button combo gesture")
        XCTAssertGreaterThan(buttonComboGesture!.confidence, 0.5, "Button combo gesture should have high confidence")
    }
    
    func testThumbstickFlickGesture() async throws {
        try await capability.activate()
        
        // Create thumbstick flick event with high magnitude
        let leftThumbstick = GameControllerInputEvent.InputData.AnalogStates.ThumbstickData(
            x: 0.9,
            y: 0.8,
            magnitude: 0.95,
            angle: 0.0,
            isPressed: false
        )
        
        let rightThumbstick = GameControllerInputEvent.InputData.AnalogStates.ThumbstickData(
            x: 0.0,
            y: 0.0,
            magnitude: 0.0,
            angle: 0.0,
            isPressed: false
        )
        
        let analogStates = GameControllerInputEvent.InputData.AnalogStates(
            leftThumbstick: leftThumbstick,
            rightThumbstick: rightThumbstick,
            leftTrigger: 0.0,
            rightTrigger: 0.0
        )
        
        let flickEvent = capability.createAnalogEvent(
            controllerId: "test-controller-1",
            controllerType: .xbox,
            analogStates: analogStates
        )
        
        let result = try await capability.processInput(flickEvent)
        
        XCTAssertTrue(result.success, "Thumbstick flick event processing should succeed")
        
        let flickGesture = result.recognizedGestures.first { $0.gestureType == .thumbstickFlick }
        XCTAssertNotNil(flickGesture, "Should recognize thumbstick flick gesture")
    }
    
    func testHapticFeedback() async throws {
        try await capability.activate()
        
        let buttonStates = GameControllerInputEvent.InputData.ButtonStates(
            buttonA: true,
            buttonB: false,
            buttonX: false,
            buttonY: false
        )
        
        let buttonEvent = capability.createButtonEvent(
            controllerId: "test-controller-1",
            controllerType: .mfi,
            buttonStates: buttonStates
        )
        
        let result = try await capability.processInput(buttonEvent)
        
        XCTAssertTrue(result.success, "Button event processing should succeed")
        XCTAssertNotNil(result.hapticFeedback, "Haptic feedback should be provided for button press")
        XCTAssertEqual(result.hapticFeedback!.feedbackType, .light, "Feedback type should be light for button press")
        XCTAssertTrue(result.hapticFeedback!.success, "Haptic feedback should succeed")
    }
    
    // MARK: - Performance Tests
    
    func testInputMetrics() async throws {
        try await capability.activate()
        
        // Process multiple events to generate metrics
        for i in 0..<10 {
            let buttonStates = GameControllerInputEvent.InputData.ButtonStates(
                buttonA: i % 2 == 0,
                buttonB: i % 3 == 0,
                buttonX: false,
                buttonY: false
            )
            
            let event = capability.createButtonEvent(
                controllerId: "test-controller-\(i % 2)",
                controllerType: .mfi,
                buttonStates: buttonStates
            )
            
            let result = try await capability.processInput(event)
            XCTAssertTrue(result.success, "Event \(i) processing should succeed")
        }
        
        let metrics = try await capability.getMetrics()
        
        XCTAssertGreaterThan(metrics.totalInputEvents, 0, "Should have recorded events")
        XCTAssertGreaterThan(metrics.successfulEvents, 0, "Should have successful events")
        XCTAssertGreaterThan(metrics.averageProcessingTime, 0, "Should have positive average processing time")
        XCTAssertEqual(metrics.failedEvents, 0, "Should have no failed events")
        XCTAssertGreaterThan(metrics.performanceStats.averageButtonsPerSession, 0, "Should have positive average buttons per session")
    }
    
    func testInputLatency() async throws {
        try await capability.activate()
        
        let buttonStates = GameControllerInputEvent.InputData.ButtonStates(buttonA: true)
        let event = capability.createButtonEvent(
            controllerId: "test-controller-1",
            controllerType: .mfi,
            buttonStates: buttonStates
        )
        
        let result = try await capability.processInput(event)
        
        XCTAssertTrue(result.success, "Event processing should succeed")
        XCTAssertGreaterThan(result.inputMetrics.averageLatency, 0, "Should have positive input latency")
        XCTAssertLessThan(result.inputMetrics.averageLatency, 0.1, "Input latency should be reasonable (< 100ms)")
    }
    
    // MARK: - Error Handling Tests
    
    func testUnavailableCapability() async throws {
        // Test operations on inactive capability
        do {
            let buttonStates = GameControllerInputEvent.InputData.ButtonStates(buttonA: true)
            let event = capability.createButtonEvent(
                controllerId: "test-controller-1",
                controllerType: .mfi,
                buttonStates: buttonStates
            )
            _ = try await capability.processInput(event)
            XCTFail("Should throw error when capability is not activated")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError, "Should throw AxiomCapabilityError when unavailable")
        }
    }
    
    func testInvalidConfiguration() async throws {
        let invalidConfig = GameControllerCapabilityConfiguration(
            maxConcurrentControllers: -1,
            inputTimeout: -5.0,
            deadZoneThreshold: 2.0
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
        let buttonStates = GameControllerInputEvent.InputData.ButtonStates(buttonA: true)
        let event = capability.createButtonEvent(
            controllerId: "test-controller-1",
            controllerType: .mfi,
            buttonStates: buttonStates
        )
        let result = try await capability.processInput(event)
        XCTAssertTrue(result.success, "Operation should succeed")
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Controller Management Tests
    
    func testConnectedControllers() async throws {
        try await capability.activate()
        
        let controllers = try await capability.getConnectedControllers()
        XCTAssertNotNil(controllers, "Connected controllers list should not be nil")
        // Note: In test environment, may be empty since no real controllers are connected
    }
    
    func testControllerConnection() async throws {
        try await capability.activate()
        
        let hasConnectedControllers = try await capability.hasConnectedControllers()
        // Note: In test environment, this will likely be false
        XCTAssertFalse(hasConnectedControllers, "Should have no connected controllers in test environment")
        
        let controllerCount = try await capability.getConnectedControllerCount()
        XCTAssertEqual(controllerCount, 0, "Controller count should be 0 in test environment")
    }
    
    // MARK: - Configuration Update Tests
    
    func testConfigurationUpdate() async throws {
        try await capability.activate()
        
        let newConfig = GameControllerCapabilityConfiguration(
            inputSensitivity: .high,
            deadZoneThreshold: 0.25,
            hapticIntensity: 0.8,
            enableLogging: false
        )
        
        try await capability.updateConfiguration(newConfig)
        
        let updatedConfig = await capability.configuration
        XCTAssertEqual(updatedConfig.inputSensitivity, .high, "Input sensitivity should be updated")
        XCTAssertEqual(updatedConfig.deadZoneThreshold, 0.25, "Dead zone threshold should be updated")
        XCTAssertEqual(updatedConfig.hapticIntensity, 0.8, "Haptic intensity should be updated")
        XCTAssertFalse(updatedConfig.enableLogging, "Logging should be disabled")
    }
    
    // MARK: - Cleanup Tests
    
    func testMetricsClearance() async throws {
        try await capability.activate()
        
        // Generate some metrics
        let buttonStates = GameControllerInputEvent.InputData.ButtonStates(buttonA: true)
        let event = capability.createButtonEvent(
            controllerId: "test-controller-1",
            controllerType: .mfi,
            buttonStates: buttonStates
        )
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

extension GameControllerCapabilityTests {
    
    /// Helper method to create test controller events
    private func createTestControllerEvents(count: Int) async throws {
        for i in 0..<count {
            let buttonStates = GameControllerInputEvent.InputData.ButtonStates(
                buttonA: i % 2 == 0,
                buttonB: i % 3 == 0
            )
            
            let event = capability.createButtonEvent(
                controllerId: "test-controller-\(i % 2)",
                controllerType: .mfi,
                buttonStates: buttonStates
            )
            
            let result = try await capability.processInput(event)
            XCTAssertTrue(result.success, "Test event creation should succeed")
        }
    }
    
    /// Helper method to verify controller input result
    private func verifyControllerInputResult(_ result: GameControllerInputResult, shouldSucceed: Bool = true) {
        XCTAssertEqual(result.success, shouldSucceed, "Operation success should match expectation")
        
        if shouldSucceed {
            XCTAssertNil(result.error, "Successful operation should not have error")
            XCTAssertGreaterThan(result.processingTime, 0, "Processing time should be positive")
        } else {
            XCTAssertNotNil(result.error, "Failed operation should have error")
        }
        
        XCTAssertNotNil(result.inputMetrics, "Operation should have metrics")
    }
}