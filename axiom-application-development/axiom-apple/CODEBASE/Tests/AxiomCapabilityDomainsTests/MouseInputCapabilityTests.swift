import XCTest
import CoreGraphics
@testable import AxiomCapabilityDomains
@testable import AxiomCore
@testable import AxiomCapabilities

/// Comprehensive test suite for Mouse Input capability
@available(iOS 13.0, macOS 10.15, *)
final class MouseInputCapabilityTests: XCTestCase {
    
    var capability: MouseInputCapability!
    var testEnvironment: AxiomCapabilityEnvironment!
    var testConfiguration: MouseInputCapabilityConfiguration!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test environment
        testEnvironment = AxiomCapabilityEnvironment(
            isDebug: true,
            isLowPowerMode: false
        )
        
        // Create test configuration
        testConfiguration = MouseInputCapabilityConfiguration(
            enableMouseInput: true,
            enableTrackpadInput: true,
            enableScrollGestures: true,
            enableMultiButtonSupport: true,
            enablePrecisionPointing: true,
            enableMagicMouse: true,
            enableForceTouch: true,
            maxConcurrentInputs: 5,
            inputTimeout: 30.0,
            enableLogging: true,
            enableMetrics: true,
            enableCaching: true,
            cacheSize: 300,
            pointerSensitivity: .normal,
            scrollSensitivity: .normal,
            clickThreshold: .medium,
            doubleClickInterval: 0.5,
            dragThreshold: 5.0,
            scrollAcceleration: true,
            naturalScrolling: true,
            tapToClick: true,
            rightClickBehavior: .contextMenu
        )
        
        capability = MouseInputCapability(
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
        let invalidConfig = MouseInputCapabilityConfiguration(
            maxConcurrentInputs: 0, // Invalid
            inputTimeout: -1.0, // Invalid
            doubleClickInterval: -0.5 // Invalid
        )
        XCTAssertFalse(invalidConfig.isValid, "Invalid configuration should not be valid")
    }
    
    func testConfigurationMerging() {
        let baseConfig = MouseInputCapabilityConfiguration()
        let updateConfig = MouseInputCapabilityConfiguration(
            enableForceTouch: false,
            pointerSensitivity: .high,
            scrollSensitivity: .fast
        )
        
        let mergedConfig = baseConfig.merged(with: updateConfig)
        
        XCTAssertFalse(mergedConfig.enableForceTouch, "Merged config should disable force touch")
        XCTAssertEqual(mergedConfig.pointerSensitivity, .high, "Merged config should have high pointer sensitivity")
        XCTAssertEqual(mergedConfig.scrollSensitivity, .fast, "Merged config should have fast scroll sensitivity")
    }
    
    func testEnvironmentAdjustment() {
        let lowPowerEnvironment = AxiomCapabilityEnvironment(isLowPowerMode: true)
        let adjustedConfig = testConfiguration.adjusted(for: lowPowerEnvironment)
        
        XCTAssertEqual(adjustedConfig.inputTimeout, min(testConfiguration.inputTimeout, 15.0), "Input timeout should be reduced in low power mode")
        XCTAssertEqual(adjustedConfig.maxConcurrentInputs, min(testConfiguration.maxConcurrentInputs, 2), "Concurrent inputs should be reduced in low power mode")
        XCTAssertFalse(adjustedConfig.enableForceTouch, "Force touch should be disabled in low power mode")
        XCTAssertFalse(adjustedConfig.scrollAcceleration, "Scroll acceleration should be disabled in low power mode")
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
        XCTAssertTrue(isSupported, "Mouse input should be supported on iOS 13+")
    }
    
    func testPermissionRequest() async throws {
        // Mouse input doesn't require special permissions
        try await capability.requestPermission()
        // Should not throw
    }
    
    // MARK: - Mouse Input Processing Tests
    
    func testMouseClickEvent() async throws {
        try await capability.activate()
        
        let clickEvent = capability.createClickEvent(
            at: CGPoint(x: 100, y: 200),
            button: .left,
            clickCount: 1,
            deviceType: .mouse
        )
        
        let result = try await capability.processInput(clickEvent)
        
        XCTAssertTrue(result.success, "Click event processing should succeed")
        XCTAssertNil(result.error, "Click event should not have errors")
        XCTAssertEqual(result.processedInput.originalEvent.eventType, .mouseDown, "Event type should be mouseDown")
        XCTAssertEqual(result.processedInput.clickType, .singleClick, "Click type should be single click")
        XCTAssertGreaterThan(result.processingTime, 0, "Processing time should be positive")
    }
    
    func testMouseMoveEvent() async throws {
        try await capability.activate()
        
        let moveEvent = capability.createMoveEvent(
            to: CGPoint(x: 150, y: 250),
            delta: CGPoint(x: 10, y: 15),
            deviceType: .mouse
        )
        
        let result = try await capability.processInput(moveEvent)
        
        XCTAssertTrue(result.success, "Move event processing should succeed")
        XCTAssertEqual(result.processedInput.originalEvent.eventType, .mouseMoved, "Event type should be mouseMoved")
        XCTAssertEqual(result.processedInput.normalizedLocation, CGPoint(x: 150, y: 250), "Location should be normalized")
    }
    
    func testMouseScrollEvent() async throws {
        try await capability.activate()
        
        let scrollEvent = capability.createScrollEvent(
            at: CGPoint(x: 300, y: 400),
            deltaX: 10.0,
            deltaY: -15.0,
            deviceType: .mouse
        )
        
        let result = try await capability.processInput(scrollEvent)
        
        XCTAssertTrue(result.success, "Scroll event processing should succeed")
        XCTAssertEqual(result.processedInput.originalEvent.eventType, .scrollWheel, "Event type should be scrollWheel")
        XCTAssertNotNil(result.processedInput.acceleratedScroll, "Accelerated scroll should be present")
    }
    
    func testGestureRecognition() async throws {
        try await capability.activate()
        
        // Create scroll event with significant delta to trigger gesture recognition
        let scrollEvent = capability.createScrollEvent(
            at: CGPoint(x: 200, y: 300),
            deltaX: 25.0,
            deltaY: 5.0,
            deviceType: .magicMouse
        )
        
        let result = try await capability.processInput(scrollEvent)
        
        XCTAssertTrue(result.success, "Scroll event processing should succeed")
        XCTAssertGreaterThan(result.gestureCount, 0, "Should recognize scroll gestures")
        
        let swipeRightGesture = result.recognizedGestures.first { $0.gestureType == .swipeRight }
        XCTAssertNotNil(swipeRightGesture, "Should recognize swipe right gesture")
    }
    
    func testMotionAnalysis() async throws {
        try await capability.activate()
        
        let moveEvent = capability.createMoveEvent(
            to: CGPoint(x: 100, y: 150),
            delta: CGPoint(x: 20, y: 30),
            deviceType: .trackpad
        )
        
        let result = try await capability.processInput(moveEvent)
        
        XCTAssertTrue(result.success, "Move event processing should succeed")
        XCTAssertGreaterThan(result.motionAnalysis.averageVelocity.x, 0, "Should have positive X velocity")
        XCTAssertGreaterThan(result.motionAnalysis.averageVelocity.y, 0, "Should have positive Y velocity")
        XCTAssertGreaterThan(result.motionAnalysis.smoothness, 0, "Should have smoothness score")
        XCTAssertGreaterThan(result.motionAnalysis.precision, 0, "Should have precision score")
    }
    
    func testDragOperations() async throws {
        try await capability.activate()
        
        // Create drag event
        let dragEvent = MouseInputEvent(mouseData: MouseInputEvent.MouseData(
            eventType: .mouseDragged,
            location: CGPoint(x: 200, y: 300),
            deltaLocation: CGPoint(x: 15, y: 20)
        ))
        
        let result = try await capability.processInput(dragEvent)
        
        XCTAssertTrue(result.success, "Drag event processing should succeed")
        XCTAssertNotNil(result.processedInput.dragInfo, "Drag info should be present")
        XCTAssertTrue(result.processedInput.dragInfo!.isDragging, "Should be in dragging state")
        XCTAssertGreaterThan(result.processedInput.dragInfo!.totalDistance, 0, "Drag distance should be positive")
    }
    
    func testHoverOperations() async throws {
        try await capability.activate()
        
        // Create hover event
        let hoverEvent = MouseInputEvent(mouseData: MouseInputEvent.MouseData(
            eventType: .mouseMoved,
            location: CGPoint(x: 150, y: 200)
        ))
        
        let result = try await capability.processInput(hoverEvent)
        
        XCTAssertTrue(result.success, "Hover event processing should succeed")
        XCTAssertNotNil(result.processedInput.hoverInfo, "Hover info should be present")
        XCTAssertTrue(result.processedInput.hoverInfo!.isHovering, "Should be in hovering state")
    }
    
    // MARK: - Performance Tests
    
    func testInputMetrics() async throws {
        try await capability.activate()
        
        // Process multiple events to generate metrics
        for i in 0..<10 {
            let event = capability.createClickEvent(
                at: CGPoint(x: 100 + i * 10, y: 150 + i * 5),
                button: .left,
                clickCount: 1
            )
            
            let result = try await capability.processInput(event)
            XCTAssertTrue(result.success, "Event \(i) processing should succeed")
        }
        
        let metrics = try await capability.getMetrics()
        
        XCTAssertGreaterThan(metrics.totalEvents, 0, "Should have recorded events")
        XCTAssertGreaterThan(metrics.successfulEvents, 0, "Should have successful events")
        XCTAssertGreaterThan(metrics.averageProcessingTime, 0, "Should have positive average processing time")
        XCTAssertEqual(metrics.failedEvents, 0, "Should have no failed events")
        XCTAssertGreaterThan(metrics.performanceStats.averageMouseSpeed, 0, "Should have positive average mouse speed")
    }
    
    func testEventTimeout() async throws {
        try await capability.activate()
        
        // Test with very short timeout
        let shortTimeoutConfig = MouseInputCapabilityConfiguration(
            inputTimeout: 0.001 // 1ms timeout
        )
        
        let timeoutCapability = MouseInputCapability(
            configuration: shortTimeoutConfig,
            environment: testEnvironment
        )
        
        try await timeoutCapability.activate()
        
        let event = timeoutCapability.createClickEvent(at: CGPoint(x: 100, y: 150))
        
        // Operation may succeed or timeout - both are valid outcomes for this test
        do {
            let result = try await timeoutCapability.processInput(event)
            XCTAssertNotNil(result, "Result should not be nil")
        } catch {
            XCTAssertTrue(error is MouseInputError, "Should throw MouseInputError on timeout")
        }
        
        await timeoutCapability.deactivate()
    }
    
    // MARK: - Error Handling Tests
    
    func testUnavailableCapability() async throws {
        // Test operations on inactive capability
        do {
            let event = capability.createClickEvent(at: CGPoint(x: 100, y: 150))
            _ = try await capability.processInput(event)
            XCTFail("Should throw error when capability is not activated")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError, "Should throw AxiomCapabilityError when unavailable")
        }
    }
    
    func testInvalidConfiguration() async throws {
        let invalidConfig = MouseInputCapabilityConfiguration(
            maxConcurrentInputs: -1,
            inputTimeout: -5.0
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
        let event = capability.createClickEvent(at: CGPoint(x: 200, y: 250))
        let result = try await capability.processInput(event)
        XCTAssertTrue(result.success, "Operation should succeed")
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Configuration Update Tests
    
    func testConfigurationUpdate() async throws {
        try await capability.activate()
        
        let newConfig = MouseInputCapabilityConfiguration(
            pointerSensitivity: .high,
            scrollSensitivity: .fast,
            enableLogging: false
        )
        
        try await capability.updateConfiguration(newConfig)
        
        let updatedConfig = await capability.configuration
        XCTAssertEqual(updatedConfig.pointerSensitivity, .high, "Pointer sensitivity should be updated")
        XCTAssertEqual(updatedConfig.scrollSensitivity, .fast, "Scroll sensitivity should be updated")
        XCTAssertFalse(updatedConfig.enableLogging, "Logging should be disabled")
    }
    
    // MARK: - Convenience Method Tests
    
    func testConvenienceMethods() async throws {
        try await capability.activate()
        
        // Test has active events
        let hasActiveInitially = try await capability.hasActiveEvents()
        XCTAssertFalse(hasActiveInitially, "Should have no active events initially")
        
        // Test average mouse speed
        let initialSpeed = try await capability.getAverageMouseSpeed()
        XCTAssertGreaterThanOrEqual(initialSpeed, 0, "Average mouse speed should be non-negative")
        
        // Process some events
        let event1 = capability.createMoveEvent(to: CGPoint(x: 100, y: 150), delta: CGPoint(x: 10, y: 15))
        let event2 = capability.createMoveEvent(to: CGPoint(x: 150, y: 200), delta: CGPoint(x: 20, y: 25))
        
        _ = try await capability.processInput(event1)
        _ = try await capability.processInput(event2)
        
        let updatedSpeed = try await capability.getAverageMouseSpeed()
        XCTAssertGreaterThan(updatedSpeed, 0, "Average mouse speed should be positive after movement")
    }
    
    // MARK: - Cleanup Tests
    
    func testMetricsClearance() async throws {
        try await capability.activate()
        
        // Generate some metrics
        let event = capability.createClickEvent(at: CGPoint(x: 100, y: 150))
        let result = try await capability.processInput(event)
        XCTAssertTrue(result.success, "Event processing should succeed")
        
        let metricsBeforeClear = try await capability.getMetrics()
        XCTAssertGreaterThan(metricsBeforeClear.totalEvents, 0, "Should have metrics before clear")
        
        // Clear metrics
        try await capability.clearMetrics()
        
        let metricsAfterClear = try await capability.getMetrics()
        XCTAssertEqual(metricsAfterClear.totalEvents, 0, "Metrics should be cleared")
    }
    
    func testCacheClearance() async throws {
        try await capability.activate()
        
        // Clear cache should not throw
        try await capability.clearCache()
    }
}

// MARK: - Test Extensions

extension MouseInputCapabilityTests {
    
    /// Helper method to create test mouse events
    private func createTestMouseEvents(count: Int) async throws {
        for i in 0..<count {
            let event = capability.createClickEvent(
                at: CGPoint(x: 100 + i * 10, y: 150 + i * 5),
                button: .left,
                clickCount: 1
            )
            
            let result = try await capability.processInput(event)
            XCTAssertTrue(result.success, "Test event creation should succeed")
        }
    }
    
    /// Helper method to verify mouse input result
    private func verifyMouseInputResult(_ result: MouseInputResult, shouldSucceed: Bool = true) {
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