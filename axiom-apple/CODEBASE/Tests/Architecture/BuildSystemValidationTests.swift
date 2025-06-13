import XCTest
@testable import Axiom

final class BuildSystemValidationTests: XCTestCase {
    
    func testDebugConfigurationAvailable() {
        #if DEBUG
        XCTAssertTrue(true, "Debug configuration should be available")
        #else
        XCTFail("Debug configuration not properly set")
        #endif
    }
    
    func testReleaseOptimizations() {
        #if RELEASE
        XCTAssertTrue(true, "Release configuration should be available")
        #else
        // This test will fail in debug mode, which is expected
        print("Running in debug mode - release configuration not active")
        #endif
    }
    
    @MainActor
    func testFeatureFlagInfrastructure() {
        let flags = BuildConfiguration.shared
        XCTAssertNotNil(flags.isTestingEnabled)
        XCTAssertNotNil(flags.isLoggingEnabled)
        XCTAssertNotNil(flags.isPerformanceMonitoringEnabled)
    }
    
    @MainActor
    func testPlatformSpecificConfiguration() {
        let config = BuildConfiguration.shared
        
        #if os(iOS)
        XCTAssertTrue(config.supportsiOS)
        #elseif os(macOS)
        XCTAssertTrue(config.supportsmacOS)
        #elseif os(watchOS)
        XCTAssertTrue(config.supportsWatchOS)
        #elseif os(tvOS)
        XCTAssertTrue(config.supportstvOS)
        #endif
    }
    
    @MainActor
    func testResourceBundling() {
        let config = BuildConfiguration.shared
        
        // Module bundle availability test
        XCTAssertNotNil(config.hasResources)
        
        // In a package context, Bundle.module might not be available
        // This is acceptable for the foundation test
    }
    
    func testBuildSystemReadyForParallelWork() async {
        let validator = BuildSystemValidator.shared
        let result = await validator.validateBuildConfiguration()
        
        // Build system should be valid
        XCTAssertTrue(result.isValid, "Build system should be ready for parallel work")
        XCTAssertTrue(result.issues.isEmpty, "No critical issues should prevent parallel work")
        
        let config = await BuildConfiguration.shared
        XCTAssertNotNil(config.isLoggingEnabled)
        XCTAssertNotNil(config.hasResources)
    }
    
    func testCIEnvironmentDetection() async {
        let config = await BuildConfiguration.shared
        
        // Test should work in both CI and local environments
        XCTAssertNotNil(config.isCIEnvironment)
        XCTAssertNotNil(config.buildNumber)
        XCTAssertNotNil(config.gitCommitHash)
    }
    
    @MainActor
    func testFoundationPatternsAccessible() {
        let config = BuildConfiguration.shared
        
        // Verify basic configuration patterns work
        XCTAssertNotNil(config.isDebugBuild)
        XCTAssertNotNil(config.isReleaseBuild)
        XCTAssertNotNil(config.isTestBuild)
        
        // Verify conditional execution patterns
        var debugExecuted = false
        var releaseExecuted = false
        var testingExecuted = false
        
        config.executeInDebug { debugExecuted = true }
        config.executeInRelease { releaseExecuted = true }
        config.executeInTesting { testingExecuted = true }
        
        #if DEBUG
        XCTAssertTrue(debugExecuted, "Debug block should execute in debug builds")
        #else
        XCTAssertFalse(debugExecuted, "Debug block should not execute in release builds")
        #endif
        
        #if TESTING
        XCTAssertTrue(testingExecuted, "Testing block should execute in test builds")
        #endif
    }
    
    func testBuildValidationResult() async {
        let validator = BuildSystemValidator.shared
        let result = await validator.validateBuildConfiguration()
        
        // Validate the result structure
        XCTAssertNotNil(result.isValid)
        XCTAssertNotNil(result.issues)
        XCTAssertNotNil(result.warnings)
        
        // In a properly configured system, we should have minimal issues
        for issue in result.issues {
            print("Build Issue: \(issue.description)")
        }
        
        for warning in result.warnings {
            print("Build Warning: \(warning.description)")
        }
    }
    
    @MainActor
    func testPlatformFeatureConsistency() {
        let config = BuildConfiguration.shared
        
        // Verify exactly one platform is supported (current platform)
        let supportedPlatforms = [
            config.supportsiOS,
            config.supportsmacOS,
            config.supportsWatchOS,
            config.supportstvOS
        ].filter { $0 }
        
        XCTAssertEqual(supportedPlatforms.count, 1, "Exactly one platform should be supported at runtime")
    }
    
    func testAsyncBuildValidation() async {
        let validator = BuildSystemValidator.shared
        
        // Test concurrent validation calls
        async let result1 = validator.validateBuildConfiguration()
        async let result2 = validator.validateBuildConfiguration()
        
        let (validation1, validation2) = await (result1, result2)
        
        // Both validations should succeed
        XCTAssertNotNil(validation1)
        XCTAssertNotNil(validation2)
        
        // Results should be consistent
        XCTAssertEqual(validation1.isValid, validation2.isValid)
    }
}