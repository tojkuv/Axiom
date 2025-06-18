import XCTest
import UIKit
import SwiftUI
@testable import AxiomCapabilityDomains
@testable import AxiomCore
@testable import AxiomCapabilities

/// Comprehensive test suite for Reduced Motion capability
@available(iOS 13.0, macOS 10.15, *)
final class ReducedMotionCapabilityTests: XCTestCase {
    
    var capability: ReducedMotionCapability!
    var testEnvironment: AxiomCapabilityEnvironment!
    var testConfiguration: ReducedMotionCapabilityConfiguration!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test environment
        testEnvironment = AxiomCapabilityEnvironment(
            isDebug: true,
            isLowPowerMode: false
        )
        
        // Create test configuration
        testConfiguration = ReducedMotionCapabilityConfiguration(
            enableReducedMotionSupport: true,
            enableAutomaticDetection: true,
            enableSystemIntegration: true,
            enableAnimationReduction: true,
            enableParallaxReduction: true,
            enableAutoPlayControl: true,
            enableTransitionSimplification: true,
            enableRealTimeMonitoring: true,
            maxConcurrentAdjustments: 5,
            adjustmentTimeout: 8.0,
            enableLogging: true,
            enableMetrics: true,
            enableCaching: true,
            cacheSize: 75,
            motionSensitivity: .medium,
            reductionLevel: .moderate,
            animationDuration: 0.1,
            transitionStyle: .fade,
            scrollBehavior: .smooth,
            supportedReductions: ReducedMotionCapabilityConfiguration.MotionReduction.allCases
        )
        
        capability = ReducedMotionCapability(
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
        let invalidConfig = ReducedMotionCapabilityConfiguration(
            maxConcurrentAdjustments: 0, // Invalid
            adjustmentTimeout: -1.0, // Invalid
            animationDuration: -0.1, // Invalid
            supportedReductions: [] // Invalid (empty)
        )
        XCTAssertFalse(invalidConfig.isValid, "Invalid configuration should not be valid")
    }
    
    func testConfigurationMerging() {
        let baseConfig = ReducedMotionCapabilityConfiguration()
        let updateConfig = ReducedMotionCapabilityConfiguration(
            enableParallaxReduction: false,
            motionSensitivity: .high,
            reductionLevel: .significant,
            animationDuration: 0.05
        )
        
        let mergedConfig = baseConfig.merged(with: updateConfig)
        
        XCTAssertFalse(mergedConfig.enableParallaxReduction, "Merged config should disable parallax reduction")
        XCTAssertEqual(mergedConfig.motionSensitivity, .high, "Merged config should have high motion sensitivity")
        XCTAssertEqual(mergedConfig.reductionLevel, .significant, "Merged config should have significant reduction level")
        XCTAssertEqual(mergedConfig.animationDuration, 0.05, "Merged config should have updated animation duration")
    }
    
    func testEnvironmentAdjustment() {
        let lowPowerEnvironment = AxiomCapabilityEnvironment(isLowPowerMode: true)
        let adjustedConfig = testConfiguration.adjusted(for: lowPowerEnvironment)
        
        XCTAssertEqual(adjustedConfig.adjustmentTimeout, min(testConfiguration.adjustmentTimeout, 4.0), "Adjustment timeout should be reduced in low power mode")
        XCTAssertEqual(adjustedConfig.maxConcurrentAdjustments, min(testConfiguration.maxConcurrentAdjustments, 2), "Max concurrent adjustments should be reduced in low power mode")
        XCTAssertFalse(adjustedConfig.enableRealTimeMonitoring, "Real-time monitoring should be disabled in low power mode")
        XCTAssertEqual(adjustedConfig.reductionLevel, .significant, "Reduction level should be significant in low power mode")
        XCTAssertEqual(adjustedConfig.animationDuration, 0.05, "Animation duration should be reduced in low power mode")
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
        XCTAssertTrue(isSupported, "Reduced Motion should be supported on iOS 13+")
    }
    
    func testPermissionRequest() async throws {
        // Reduced Motion doesn't require special permissions
        try await capability.requestPermission()
        // Should not throw
    }
    
    // MARK: - Motion Reduction Tests
    
    func testAnimationReduction() async throws {
        try await capability.activate()
        
        let animationRequest = capability.createAnimationReductionRequest(
            animationId: "test-fade-animation",
            duration: 2.0,
            animationType: .fade,
            targetLevel: .moderate
        )
        
        let result = try await capability.performReduction(animationRequest)
        
        XCTAssertTrue(result.success, "Animation reduction should succeed")
        XCTAssertNil(result.error, "Animation reduction should not have errors")
        XCTAssertGreaterThan(result.reducedAnimations.count, 0, "Should have reduced animations")
        XCTAssertGreaterThan(result.reductionMetrics.animationsReduced, 0, "Should report reduced animations")
        XCTAssertGreaterThan(result.processingTime, 0, "Processing time should be positive")
        XCTAssertGreaterThan(result.reductionEffectiveness, 0, "Reduction effectiveness should be positive")
        
        let reducedAnimation = result.reducedAnimations.first!
        XCTAssertLessThan(reducedAnimation.newDuration, reducedAnimation.originalDuration, "Animation duration should be reduced")
        XCTAssertNotEqual(reducedAnimation.reductionApplied, .none, "Some reduction should be applied")
    }
    
    func testParallaxDisable() async throws {
        try await capability.activate()
        
        let parallaxRequest = capability.createParallaxDisableRequest(
            effectId: "test-parallax-effect",
            intensity: 0.8
        )
        
        let result = try await capability.performReduction(parallaxRequest)
        
        XCTAssertTrue(result.success, "Parallax disable should succeed")
        XCTAssertGreaterThan(result.disabledEffects.count, 0, "Should have disabled effects")
        XCTAssertGreaterThan(result.reductionMetrics.effectsDisabled, 0, "Should report disabled effects")
        
        let disabledEffect = result.disabledEffects.first!
        XCTAssertEqual(disabledEffect.originalEffect.effectType, .parallax, "Disabled effect should be parallax")
        XCTAssertTrue([.motionSensitivity, .accessibilityRequirement].contains(disabledEffect.disabledReason), "Should have appropriate disable reason")
    }
    
    func testAutoPlayControl() async throws {
        try await capability.activate()
        
        let autoPlayRequest = capability.createAutoPlayControlRequest(
            contentId: "test-video-content",
            contentType: .video,
            hasMotion: true
        )
        
        let result = try await capability.performReduction(autoPlayRequest)
        
        XCTAssertTrue(result.success, "Auto-play control should succeed")
        XCTAssertGreaterThan(result.modifiedContent.count, 0, "Should have modified content")
        XCTAssertGreaterThan(result.reductionMetrics.contentModified, 0, "Should report modified content")
        
        let modifiedContent = result.modifiedContent.first!
        XCTAssertTrue(modifiedContent.wasAutoPlayDisabled, "Auto-play should be disabled")
        XCTAssertTrue(modifiedContent.playControlsAdded, "Play controls should be added")
        XCTAssertFalse(modifiedContent.modifiedContent.isAutoPlaying, "Modified content should not auto-play")
    }
    
    func testComplexReductionRequest() async throws {
        try await capability.activate()
        
        // Create complex request with multiple elements
        let animationElement = MotionReductionRequest.ReductionTarget.AnimationElement(
            elementId: "complex-bounce-animation",
            animationType: .bounce,
            duration: 3.0,
            properties: [
                MotionReductionRequest.ReductionTarget.AnimationElement.AnimationProperty(
                    propertyName: "transform.scale",
                    fromValue: "1.0",
                    toValue: "1.5",
                    keyPath: "transform.scale"
                ),
                MotionReductionRequest.ReductionTarget.AnimationElement.AnimationProperty(
                    propertyName: "opacity",
                    fromValue: "0.0",
                    toValue: "1.0",
                    keyPath: "opacity"
                )
            ],
            timing: .spring,
            repeatCount: 3
        )
        
        let motionEffect = MotionReductionRequest.ReductionTarget.MotionEffect(
            effectId: "shake-effect",
            effectType: .shake,
            intensity: 0.9
        )
        
        let contentElement = MotionReductionRequest.ReductionTarget.ContentElement(
            elementId: "background-video",
            contentType: .video,
            isAutoPlaying: true,
            hasMotion: true,
            motionIntensity: 0.7
        )
        
        let target = MotionReductionRequest.ReductionTarget(
            targetType: .application,
            identifier: "complex-ui-test",
            animationElements: [animationElement],
            motionEffects: [motionEffect],
            contentElements: [contentElement],
            interactionElements: []
        )
        
        let complexRequest = MotionReductionRequest(
            target: target,
            reductionType: .fullReduction,
            targetLevel: .significant
        )
        
        let result = try await capability.performReduction(complexRequest)
        
        XCTAssertTrue(result.success, "Complex reduction should succeed")
        XCTAssertGreaterThan(result.reductionMetrics.totalElementsProcessed, 2, "Should process multiple elements")
        XCTAssertTrue(result.hasSignificantReductions, "Should have significant reductions")
        XCTAssertGreaterThan(result.reductionMetrics.accessibilityImprovement, 0, "Should improve accessibility")
        XCTAssertGreaterThan(result.reductionMetrics.userExperienceScore, 0, "Should have positive UX score")
    }
    
    func testReductionLevels() async throws {
        try await capability.activate()
        
        let baseRequest = capability.createAnimationReductionRequest(
            animationId: "level-test-animation",
            duration: 2.0,
            animationType: .bounce,
            targetLevel: .minimal
        )
        
        // Test minimal reduction
        let minimalResult = try await capability.performReduction(baseRequest)
        XCTAssertTrue(minimalResult.success, "Minimal reduction should succeed")
        
        // Test moderate reduction
        let moderateRequest = MotionReductionRequest(
            target: baseRequest.target,
            reductionType: baseRequest.reductionType,
            targetLevel: .moderate
        )
        let moderateResult = try await capability.performReduction(moderateRequest)
        XCTAssertTrue(moderateResult.success, "Moderate reduction should succeed")
        
        // Test significant reduction
        let significantRequest = MotionReductionRequest(
            target: baseRequest.target,
            reductionType: baseRequest.reductionType,
            targetLevel: .significant
        )
        let significantResult = try await capability.performReduction(significantRequest)
        XCTAssertTrue(significantResult.success, "Significant reduction should succeed")
        
        // Compare reduction levels
        let minimalAnimation = minimalResult.reducedAnimations.first!
        let moderateAnimation = moderateResult.reducedAnimations.first!
        let significantAnimation = significantResult.reducedAnimations.first!
        
        XCTAssertGreaterThan(minimalAnimation.newDuration, moderateAnimation.newDuration, "Minimal should preserve more duration than moderate")
        XCTAssertGreaterThan(moderateAnimation.newDuration, significantAnimation.newDuration, "Moderate should preserve more duration than significant")
    }
    
    // MARK: - System Integration Tests
    
    func testSystemReducedMotionDetection() async throws {
        try await capability.activate()
        
        let isSystemEnabled = try await capability.isSystemReducedMotionEnabled()
        // Note: In test environment, this depends on actual system settings
        XCTAssertNotNil(isSystemEnabled, "Should be able to detect system reduced motion setting")
    }
    
    func testCurrentMotionSensitivity() async throws {
        try await capability.activate()
        
        let currentSensitivity = try await capability.getCurrentMotionSensitivity()
        XCTAssertTrue(ReducedMotionCapabilityConfiguration.MotionSensitivity.allCases.contains(currentSensitivity), "Should return valid motion sensitivity")
    }
    
    // MARK: - Performance Tests
    
    func testReductionMetrics() async throws {
        try await capability.activate()
        
        // Process multiple reductions to generate metrics
        for i in 0..<5 {
            let request = capability.createAnimationReductionRequest(
                animationId: "metrics-test-animation-\(i)",
                duration: 1.0 + Double(i) * 0.5,
                animationType: .fade,
                targetLevel: .moderate
            )
            
            let result = try await capability.performReduction(request)
            XCTAssertTrue(result.success, "Reduction \(i) should succeed")
        }
        
        let metrics = try await capability.getMetrics()
        
        XCTAssertGreaterThan(metrics.totalReductions, 0, "Should have recorded reductions")
        XCTAssertGreaterThan(metrics.successfulReductions, 0, "Should have successful reductions")
        XCTAssertGreaterThan(metrics.averageProcessingTime, 0, "Should have positive average processing time")
        XCTAssertEqual(metrics.failedReductions, 0, "Should have no failed reductions")
        XCTAssertGreaterThan(metrics.averageReductionLevel, 0, "Should have positive average reduction level")
        XCTAssertGreaterThan(metrics.performanceStats.totalAnimationsProcessed, 0, "Should have processed animations")
    }
    
    func testReductionTimeout() async throws {
        try await capability.activate()
        
        // Test with very short timeout
        let shortTimeoutConfig = ReducedMotionCapabilityConfiguration(
            adjustmentTimeout: 0.001 // 1ms timeout
        )
        
        let timeoutCapability = ReducedMotionCapability(
            configuration: shortTimeoutConfig,
            environment: testEnvironment
        )
        
        try await timeoutCapability.activate()
        
        let request = timeoutCapability.createAnimationReductionRequest(
            animationId: "timeout-test-animation",
            duration: 2.0,
            targetLevel: .moderate
        )
        
        // Operation may succeed or timeout - both are valid outcomes for this test
        do {
            let result = try await timeoutCapability.performReduction(request)
            XCTAssertNotNil(result, "Result should not be nil")
        } catch {
            XCTAssertTrue(error is ReducedMotionError, "Should throw ReducedMotionError on timeout")
        }
        
        await timeoutCapability.deactivate()
    }
    
    // MARK: - Error Handling Tests
    
    func testUnavailableCapability() async throws {
        // Test operations on inactive capability
        do {
            let request = capability.createAnimationReductionRequest(
                animationId: "unavailable-test",
                duration: 1.0
            )
            _ = try await capability.performReduction(request)
            XCTFail("Should throw error when capability is not activated")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError, "Should throw AxiomCapabilityError when unavailable")
        }
    }
    
    func testInvalidConfiguration() async throws {
        let invalidConfig = ReducedMotionCapabilityConfiguration(
            maxConcurrentAdjustments: -1,
            adjustmentTimeout: -5.0,
            animationDuration: -0.1
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
        let request = capability.createAnimationReductionRequest(
            animationId: "stream-test-animation",
            duration: 1.5
        )
        let result = try await capability.performReduction(request)
        XCTAssertTrue(result.success, "Operation should succeed")
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Configuration Update Tests
    
    func testConfigurationUpdate() async throws {
        try await capability.activate()
        
        let newConfig = ReducedMotionCapabilityConfiguration(
            motionSensitivity: .high,
            reductionLevel: .significant,
            animationDuration: 0.05,
            enableLogging: false
        )
        
        try await capability.updateConfiguration(newConfig)
        
        let updatedConfig = await capability.configuration
        XCTAssertEqual(updatedConfig.motionSensitivity, .high, "Motion sensitivity should be updated")
        XCTAssertEqual(updatedConfig.reductionLevel, .significant, "Reduction level should be updated")
        XCTAssertEqual(updatedConfig.animationDuration, 0.05, "Animation duration should be updated")
        XCTAssertFalse(updatedConfig.enableLogging, "Logging should be disabled")
    }
    
    // MARK: - Cleanup Tests
    
    func testMetricsClearance() async throws {
        try await capability.activate()
        
        // Generate some metrics
        let request = capability.createAnimationReductionRequest(
            animationId: "metrics-clear-test",
            duration: 1.0
        )
        let result = try await capability.performReduction(request)
        XCTAssertTrue(result.success, "Reduction should succeed")
        
        let metricsBeforeClear = try await capability.getMetrics()
        XCTAssertGreaterThan(metricsBeforeClear.totalReductions, 0, "Should have metrics before clear")
        
        // Clear metrics
        try await capability.clearMetrics()
        
        let metricsAfterClear = try await capability.getMetrics()
        XCTAssertEqual(metricsAfterClear.totalReductions, 0, "Metrics should be cleared")
    }
    
    func testCacheClearance() async throws {
        try await capability.activate()
        
        // Clear cache should not throw
        try await capability.clearCache()
    }
}

// MARK: - Test Extensions

extension ReducedMotionCapabilityTests {
    
    /// Helper method to create test motion reduction requests
    private func createTestReductionRequests(count: Int) async throws {
        for i in 0..<count {
            let request = capability.createAnimationReductionRequest(
                animationId: "test-animation-\(i)",
                duration: 1.0 + Double(i) * 0.2,
                animationType: .fade,
                targetLevel: .moderate
            )
            
            let result = try await capability.performReduction(request)
            XCTAssertTrue(result.success, "Test reduction \(i) should succeed")
        }
    }
    
    /// Helper method to verify motion reduction result
    private func verifyMotionReductionResult(_ result: MotionReductionResult, shouldSucceed: Bool = true) {
        XCTAssertEqual(result.success, shouldSucceed, "Operation success should match expectation")
        
        if shouldSucceed {
            XCTAssertNil(result.error, "Successful operation should not have error")
            XCTAssertGreaterThan(result.processingTime, 0, "Processing time should be positive")
            XCTAssertGreaterThan(result.reductionEffectiveness, 0, "Reduction effectiveness should be positive")
        } else {
            XCTAssertNotNil(result.error, "Failed operation should have error")
        }
        
        XCTAssertNotNil(result.reductionMetrics, "Operation should have metrics")
    }
    
    /// Helper method to create complex animation element
    private func createComplexAnimationElement(id: String, duration: TimeInterval) -> MotionReductionRequest.ReductionTarget.AnimationElement {
        return MotionReductionRequest.ReductionTarget.AnimationElement(
            elementId: id,
            animationType: .bounce,
            duration: duration,
            properties: [
                MotionReductionRequest.ReductionTarget.AnimationElement.AnimationProperty(
                    propertyName: "opacity",
                    fromValue: "0.0",
                    toValue: "1.0",
                    keyPath: "opacity"
                ),
                MotionReductionRequest.ReductionTarget.AnimationElement.AnimationProperty(
                    propertyName: "transform.scale",
                    fromValue: "0.8",
                    toValue: "1.0",
                    keyPath: "transform.scale"
                )
            ],
            timing: .spring,
            repeatCount: 2
        )
    }
}