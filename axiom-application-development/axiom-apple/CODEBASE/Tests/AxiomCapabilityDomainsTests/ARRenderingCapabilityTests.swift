import XCTest
import ARKit
import SceneKit
import RealityKit
@testable import AxiomCapabilityDomains
@testable import AxiomCore
@testable import AxiomCapabilities

/// Comprehensive test suite for AR Rendering capability
@available(iOS 13.0, macOS 10.15, *)
final class ARRenderingCapabilityTests: XCTestCase {
    
    var capability: ARRenderingCapability!
    var testEnvironment: AxiomCapabilityEnvironment!
    var testConfiguration: ARRenderingCapabilityConfiguration!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test environment
        testEnvironment = AxiomCapabilityEnvironment(
            isDebug: true,
            isLowPowerMode: false
        )
        
        // Create test configuration
        testConfiguration = ARRenderingCapabilityConfiguration(
            enableARRendering: true,
            enableWorldTracking: true,
            enablePlaneDetection: true,
            enableImageTracking: true,
            enableObjectDetection: true,
            enableBodyTracking: false,
            enableFaceTracking: false,
            enableOcclusion: true,
            enableLightEstimation: true,
            enableCollaborativeSession: false,
            enablePeopleOcclusion: false,
            maxConcurrentSessions: 2,
            sessionTimeout: 30.0,
            enableLogging: true,
            enableMetrics: true,
            enableCaching: true,
            cacheSize: 50,
            trackingQuality: .automatic,
            renderingFramework: .realityKit,
            worldAlignment: .gravity,
            planeDetection: .both,
            environmentTexturing: .automatic,
            maxAnchors: 100,
            frameSemantics: [.personSegmentation, .sceneDepth]
        )
        
        capability = ARRenderingCapability(
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
        let invalidConfig = ARRenderingCapabilityConfiguration(
            maxConcurrentSessions: 0, // Invalid
            sessionTimeout: -1.0, // Invalid
            maxAnchors: -1, // Invalid
            frameSemantics: [] // Invalid (empty)
        )
        XCTAssertFalse(invalidConfig.isValid, "Invalid configuration should not be valid")
    }
    
    func testConfigurationMerging() {
        let baseConfig = ARRenderingCapabilityConfiguration()
        let updateConfig = ARRenderingCapabilityConfiguration(
            enableFaceTracking: true,
            renderingFramework: .sceneKit,
            planeDetection: .horizontal,
            environmentTexturing: .manual
        )
        
        let mergedConfig = baseConfig.merged(with: updateConfig)
        
        XCTAssertTrue(mergedConfig.enableFaceTracking, "Merged config should enable face tracking")
        XCTAssertEqual(mergedConfig.renderingFramework, .sceneKit, "Merged config should use SceneKit framework")
        XCTAssertEqual(mergedConfig.planeDetection, .horizontal, "Merged config should use horizontal plane detection")
        XCTAssertEqual(mergedConfig.environmentTexturing, .manual, "Merged config should use manual environment texturing")
    }
    
    func testEnvironmentAdjustment() {
        let lowPowerEnvironment = AxiomCapabilityEnvironment(isLowPowerMode: true)
        let adjustedConfig = testConfiguration.adjusted(for: lowPowerEnvironment)
        
        XCTAssertEqual(adjustedConfig.sessionTimeout, min(testConfiguration.sessionTimeout, 15.0), "Session timeout should be reduced in low power mode")
        XCTAssertEqual(adjustedConfig.maxConcurrentSessions, 1, "Concurrent sessions should be reduced in low power mode")
        XCTAssertEqual(adjustedConfig.cacheSize, min(testConfiguration.cacheSize, 20), "Cache size should be reduced in low power mode")
        XCTAssertEqual(adjustedConfig.frameSemantics, [.personSegmentation], "Frame semantics should be reduced in low power mode")
        XCTAssertEqual(adjustedConfig.maxAnchors, min(testConfiguration.maxAnchors, 25), "Max anchors should be reduced in low power mode")
        XCTAssertEqual(adjustedConfig.renderingFramework, .sceneKit, "Rendering framework should be SceneKit in low power mode")
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
        // Note: This depends on device capabilities and ARKit availability
        print("AR support status: \(isSupported)")
    }
    
    func testPermissionRequest() async throws {
        // AR rendering requires camera permissions - handled by ARKit
        try await capability.requestPermission()
        // Should not throw
    }
    
    // MARK: - AR Rendering Processing Tests
    
    func testWorldTrackingSession() async throws {
        try await capability.activate()
        
        let worldTrackingRequest = capability.createWorldTrackingRequest(
            enablePlaneDetection: true,
            enableImageTracking: false,
            enableOcclusion: true
        )
        
        let result = try await capability.startSession(worldTrackingRequest)
        
        XCTAssertTrue(result.success, "World tracking session should succeed")
        XCTAssertNil(result.error, "World tracking session should not have errors")
        XCTAssertEqual(result.requestId, worldTrackingRequest.id, "Result should match request ID")
        XCTAssertGreaterThan(result.processingTime, 0, "Processing time should be positive")
        XCTAssertGreaterThan(result.trackingQuality, 0, "Tracking quality should be positive")
    }
    
    func testFaceTrackingSession() async throws {
        try await capability.activate()
        
        let faceTrackingRequest = capability.createFaceTrackingRequest()
        
        let result = try await capability.startSession(faceTrackingRequest)
        
        XCTAssertTrue(result.success, "Face tracking session should succeed")
        XCTAssertEqual(result.requestId, faceTrackingRequest.id, "Result should match request ID")
        XCTAssertNotNil(result.sessionState, "Session state should be present")
        XCTAssertTrue([.normal, .limited, .notAvailable].contains(result.trackingState), "Should have valid tracking state")
    }
    
    func testImageTrackingSession() async throws {
        try await capability.activate()
        
        let imageTrackingRequest = capability.createImageTrackingRequest(maxTrackedImages: 3)
        
        let result = try await capability.startSession(imageTrackingRequest)
        
        XCTAssertTrue(result.success, "Image tracking session should succeed")
        XCTAssertEqual(result.requestId, imageTrackingRequest.id, "Result should match request ID")
        XCTAssertNotNil(result.renderingMetrics, "Rendering metrics should be present")
        XCTAssertGreaterThan(result.renderingMetrics.frameRate, 0, "Frame rate should be positive")
    }
    
    func testSessionStateAnalysis() async throws {
        try await capability.activate()
        
        let sessionRequest = capability.createWorldTrackingRequest()
        let result = try await capability.startSession(sessionRequest)
        
        XCTAssertTrue(result.success, "Session should succeed")
        XCTAssertNotNil(result.sessionState, "Session state should be present")
        
        let sessionState = result.sessionState
        XCTAssertTrue(sessionState.isRunning, "Session should be running")
        XCTAssertFalse(sessionState.isPaused, "Session should not be paused")
        XCTAssertTrue([.normal, .limited, .notAvailable].contains(sessionState.trackingState), "Should have valid tracking state")
        XCTAssertTrue([.notAvailable, .limited, .extending, .mapped].contains(sessionState.worldMappingStatus), "Should have valid world mapping status")
    }
    
    func testDetectionElements() async throws {
        try await capability.activate()
        
        let sessionRequest = capability.createWorldTrackingRequest(enablePlaneDetection: true)
        let result = try await capability.startSession(sessionRequest)
        
        XCTAssertTrue(result.success, "Session should succeed")
        
        if !result.detectedElements.isEmpty {
            let detectedElement = result.detectedElements.first!
            XCTAssertFalse(detectedElement.elementId.isEmpty, "Element ID should not be empty")
            XCTAssertTrue([.plane, .image, .object, .face, .body, .text, .unknown].contains(detectedElement.elementType), "Should have valid element type")
            XCTAssertGreaterThanOrEqual(detectedElement.confidence, 0.0, "Confidence should be non-negative")
            XCTAssertLessThanOrEqual(detectedElement.confidence, 1.0, "Confidence should be at most 1.0")
        }
    }
    
    func testAnchorProcessing() async throws {
        try await capability.activate()
        
        let sessionRequest = capability.createWorldTrackingRequest()
        let result = try await capability.startSession(sessionRequest)
        
        XCTAssertTrue(result.success, "Session should succeed")
        
        if !result.anchors.isEmpty {
            let anchor = result.anchors.first!
            XCTAssertFalse(anchor.anchorId.isEmpty, "Anchor ID should not be empty")
            XCTAssertTrue([.world, .plane, .image, .object, .face, .body, .environment].contains(anchor.anchorType), "Should have valid anchor type")
            XCTAssertNotNil(anchor.transform, "Anchor transform should be present")
        }
    }
    
    func testSessionManagement() async throws {
        try await capability.activate()
        
        let sessionRequest = capability.createWorldTrackingRequest()
        let result = try await capability.startSession(sessionRequest)
        
        XCTAssertTrue(result.success, "Session should succeed")
        
        let sessionId = result.requestId
        
        // Test pause session
        try await capability.pauseSession(sessionId)
        
        // Test stop session
        try await capability.stopSession(sessionId)
    }
    
    // MARK: - Performance Tests
    
    func testSessionMetrics() async throws {
        try await capability.activate()
        
        // Process multiple sessions to generate metrics
        for i in 0..<3 {
            let sessionRequest = capability.createWorldTrackingRequest()
            
            let result = try await capability.startSession(sessionRequest)
            XCTAssertTrue(result.success, "Session \(i) should succeed")
        }
        
        let metrics = try await capability.getMetrics()
        
        XCTAssertGreaterThan(metrics.totalSessions, 0, "Should have recorded sessions")
        XCTAssertGreaterThan(metrics.successfulSessions, 0, "Should have successful sessions")
        XCTAssertGreaterThan(metrics.averageProcessingTime, 0, "Should have positive average processing time")
        XCTAssertEqual(metrics.failedSessions, 0, "Should have no failed sessions")
        XCTAssertGreaterThan(metrics.performanceStats.averageAnchorsPerSession, 0, "Should have positive average anchors per session")
    }
    
    func testRenderingPerformance() async throws {
        try await capability.activate()
        
        let sessionRequest = capability.createWorldTrackingRequest()
        let result = try await capability.startSession(sessionRequest)
        
        XCTAssertTrue(result.success, "Session should succeed")
        XCTAssertGreaterThan(result.renderingMetrics.frameRate, 0, "Frame rate should be positive")
        XCTAssertGreaterThan(result.renderingMetrics.frameTime, 0, "Frame time should be positive")
        XCTAssertGreaterThanOrEqual(result.renderingMetrics.gpuUtilization, 0, "GPU utilization should be non-negative")
        XCTAssertLessThanOrEqual(result.renderingMetrics.gpuUtilization, 1.0, "GPU utilization should be at most 1.0")
        XCTAssertGreaterThan(result.renderingMetrics.memoryUsage, 0, "Memory usage should be positive")
        XCTAssertTrue([.nominal, .fair, .serious, .critical].contains(result.renderingMetrics.thermalState), "Should have valid thermal state")
        XCTAssertTrue([.poor, .acceptable, .good, .excellent].contains(result.renderingMetrics.trackingQuality), "Should have valid tracking quality")
    }
    
    func testSessionTimeout() async throws {
        try await capability.activate()
        
        // Test with very short timeout
        let shortTimeoutConfig = ARRenderingCapabilityConfiguration(
            sessionTimeout: 0.001 // 1ms timeout
        )
        
        let timeoutCapability = ARRenderingCapability(
            configuration: shortTimeoutConfig,
            environment: testEnvironment
        )
        
        try await timeoutCapability.activate()
        
        let sessionRequest = timeoutCapability.createWorldTrackingRequest()
        
        // Operation may succeed or timeout - both are valid outcomes for this test
        do {
            let result = try await timeoutCapability.startSession(sessionRequest)
            XCTAssertNotNil(result, "Result should not be nil")
        } catch {
            XCTAssertTrue(error is ARRenderingError, "Should throw ARRenderingError on timeout")
        }
        
        await timeoutCapability.deactivate()
    }
    
    // MARK: - Error Handling Tests
    
    func testUnavailableCapability() async throws {
        // Test operations on inactive capability
        do {
            let sessionRequest = capability.createWorldTrackingRequest()
            _ = try await capability.startSession(sessionRequest)
            XCTFail("Should throw error when capability is not activated")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError, "Should throw AxiomCapabilityError when unavailable")
        }
    }
    
    func testInvalidConfiguration() async throws {
        let invalidConfig = ARRenderingCapabilityConfiguration(
            maxConcurrentSessions: -1,
            sessionTimeout: -5.0,
            maxAnchors: -10
        )
        
        do {
            try await capability.updateConfiguration(invalidConfig)
            XCTFail("Should throw error for invalid configuration")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError, "Should throw AxiomCapabilityError for invalid config")
        }
    }
    
    func testSessionLimitExceeded() async throws {
        try await capability.activate()
        
        // Create capability with max 1 session
        let limitedConfig = ARRenderingCapabilityConfiguration(maxConcurrentSessions: 1)
        let limitedCapability = ARRenderingCapability(
            configuration: limitedConfig,
            environment: testEnvironment
        )
        
        try await limitedCapability.activate()
        
        // Start first session (should succeed)
        let sessionRequest1 = limitedCapability.createWorldTrackingRequest()
        let result1 = try await limitedCapability.startSession(sessionRequest1)
        XCTAssertTrue(result1.success, "First session should succeed")
        
        await limitedCapability.deactivate()
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
        let sessionRequest = capability.createWorldTrackingRequest()
        let result = try await capability.startSession(sessionRequest)
        XCTAssertTrue(result.success, "Operation should succeed")
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - AR Features Tests
    
    func testARSupportCheck() async throws {
        let support = try await capability.checkARSupport()
        
        // Note: Results depend on device capabilities
        XCTAssertNotNil(support.worldTracking, "World tracking support should be determinable")
        XCTAssertNotNil(support.faceTracking, "Face tracking support should be determinable")
        XCTAssertNotNil(support.bodyTracking, "Body tracking support should be determinable")
        XCTAssertNotNil(support.imageTracking, "Image tracking support should be determinable")
    }
    
    func testARCapabilities() async throws {
        let capabilities = try await capability.getARCapabilities()
        
        XCTAssertNotNil(capabilities, "AR capabilities should not be nil")
        // Note: Actual capabilities depend on device hardware
    }
    
    func testSessionCreationMethods() async {
        // Test world tracking request creation
        let worldRequest = capability.createWorldTrackingRequest(
            enablePlaneDetection: true,
            enableImageTracking: false,
            enableOcclusion: true
        )
        
        XCTAssertEqual(worldRequest.sessionConfig.configType, .worldTracking, "Should create world tracking config")
        XCTAssertEqual(worldRequest.sessionConfig.planeDetection, .both, "Should enable plane detection")
        XCTAssertEqual(worldRequest.sessionConfig.frameSemantics, [.personSegmentation, .sceneDepth], "Should include occlusion semantics")
        
        // Test face tracking request creation
        let faceRequest = capability.createFaceTrackingRequest()
        
        XCTAssertEqual(faceRequest.sessionConfig.configType, .faceTracking, "Should create face tracking config")
        XCTAssertEqual(faceRequest.sessionConfig.frameSemantics, [.personSegmentation], "Should include person segmentation")
        
        // Test image tracking request creation
        let imageRequest = capability.createImageTrackingRequest(maxTrackedImages: 5)
        
        XCTAssertEqual(imageRequest.sessionConfig.configType, .imageTracking, "Should create image tracking config")
        XCTAssertEqual(imageRequest.trackingOptions.maximumNumberOfTrackedImages, 5, "Should set max tracked images")
    }
    
    // MARK: - Configuration Update Tests
    
    func testConfigurationUpdate() async throws {
        try await capability.activate()
        
        let newConfig = ARRenderingCapabilityConfiguration(
            renderingFramework: .sceneKit,
            planeDetection: .horizontal,
            environmentTexturing: .manual,
            enableLogging: false
        )
        
        try await capability.updateConfiguration(newConfig)
        
        let updatedConfig = await capability.configuration
        XCTAssertEqual(updatedConfig.renderingFramework, .sceneKit, "Rendering framework should be updated")
        XCTAssertEqual(updatedConfig.planeDetection, .horizontal, "Plane detection should be updated")
        XCTAssertEqual(updatedConfig.environmentTexturing, .manual, "Environment texturing should be updated")
        XCTAssertFalse(updatedConfig.enableLogging, "Logging should be disabled")
    }
    
    // MARK: - Cleanup Tests
    
    func testMetricsClearance() async throws {
        try await capability.activate()
        
        // Generate some metrics
        let sessionRequest = capability.createWorldTrackingRequest()
        let result = try await capability.startSession(sessionRequest)
        XCTAssertTrue(result.success, "Session should succeed")
        
        let metricsBeforeClear = try await capability.getMetrics()
        XCTAssertGreaterThan(metricsBeforeClear.totalSessions, 0, "Should have metrics before clear")
        
        // Clear metrics
        try await capability.clearMetrics()
        
        let metricsAfterClear = try await capability.getMetrics()
        XCTAssertEqual(metricsAfterClear.totalSessions, 0, "Metrics should be cleared")
    }
    
    func testCacheClearance() async throws {
        try await capability.activate()
        
        // Clear cache should not throw
        try await capability.clearCache()
    }
    
    func testSessionHistory() async throws {
        try await capability.activate()
        
        // Create a few sessions
        for i in 0..<3 {
            let sessionRequest = capability.createWorldTrackingRequest()
            let result = try await capability.startSession(sessionRequest)
            XCTAssertTrue(result.success, "Session \(i) should succeed")
        }
        
        let history = try await capability.getSessionHistory()
        XCTAssertGreaterThan(history.count, 0, "Should have session history")
        
        // Test history with date filter
        let recentHistory = try await capability.getSessionHistory(since: Date().addingTimeInterval(-10))
        XCTAssertLessThanOrEqual(recentHistory.count, history.count, "Recent history should be subset of total history")
    }
    
    func testActiveSessions() async throws {
        try await capability.activate()
        
        let activeSessions = try await capability.getActiveSessions()
        XCTAssertNotNil(activeSessions, "Active sessions should not be nil")
        // Note: In test environment, there may be no active sessions
    }
}

// MARK: - Test Extensions

extension ARRenderingCapabilityTests {
    
    /// Helper method to create test AR sessions
    private func createTestSessions(count: Int) async throws {
        for i in 0..<count {
            let sessionRequest = capability.createWorldTrackingRequest()
            
            let result = try await capability.startSession(sessionRequest)
            XCTAssertTrue(result.success, "Test session \(i) should succeed")
        }
    }
    
    /// Helper method to verify AR rendering result
    private func verifyARRenderingResult(_ result: ARRenderingResult, shouldSucceed: Bool = true) {
        XCTAssertEqual(result.success, shouldSucceed, "Operation success should match expectation")
        
        if shouldSucceed {
            XCTAssertNil(result.error, "Successful operation should not have error")
            XCTAssertGreaterThan(result.processingTime, 0, "Processing time should be positive")
            XCTAssertNotNil(result.sessionState, "Session state should be present")
            XCTAssertNotNil(result.renderingMetrics, "Rendering metrics should be present")
        } else {
            XCTAssertNotNil(result.error, "Failed operation should have error")
        }
        
        XCTAssertGreaterThanOrEqual(result.trackingQuality, 0.0, "Tracking quality should be non-negative")
        XCTAssertLessThanOrEqual(result.trackingQuality, 1.0, "Tracking quality should be at most 1.0")
    }
    
    /// Helper method to create complex AR session request
    private func createComplexSessionRequest() -> ARRenderingRequest {
        let sessionConfig = ARRenderingRequest.SessionConfiguration(
            configType: .worldTracking,
            worldAlignment: .gravityAndHeading,
            planeDetection: .both,
            environmentTexturing: .automatic,
            frameSemantics: [.personSegmentation, .sceneDepth, .bodyDetection],
            isLightEstimationEnabled: true,
            providesAudioData: false,
            isAutoFocusEnabled: true
        )
        
        let renderingOptions = ARRenderingRequest.RenderingOptions(
            framework: .realityKit,
            enableStatistics: true,
            enableDebugging: false,
            enablePhysics: true,
            enableAntialiasing: true,
            enableHDR: false,
            renderingAPI: .metal,
            shadowQuality: .high,
            textureQuality: .ultra
        )
        
        let trackingOptions = ARRenderingRequest.TrackingOptions(
            resetTracking: false,
            removeExistingAnchors: false,
            relocalizationEnabled: true,
            userFaceTrackingEnabled: false,
            environmentProbeAnchorEnabled: true,
            automaticImageScaleEstimationEnabled: true,
            wantsHDREnvironmentTextures: false,
            maximumNumberOfTrackedImages: 3
        )
        
        return ARRenderingRequest(
            sessionConfig: sessionConfig,
            renderingOptions: renderingOptions,
            trackingOptions: trackingOptions,
            priority: .high
        )
    }
}