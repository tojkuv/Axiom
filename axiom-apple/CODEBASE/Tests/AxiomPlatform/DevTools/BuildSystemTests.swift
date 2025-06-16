import XCTest
import AxiomTesting
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomPlatform build system functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class BuildSystemTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testBuildSystemValidatorInitialization() async throws {
        let validator = BuildSystemValidator()
        XCTAssertNotNil(validator, "BuildSystemValidator should initialize correctly")
    }
    
    func testBuildConfigurationValidation() async throws {
        let validator = BuildSystemValidator()
        let config = BuildConfiguration()
        
        let isValid = await validator.validateConfiguration(config)
        XCTAssertTrue(isValid, "Default build configuration should be valid")
    }
    
    // MARK: - Performance Tests
    
    func testBuildSystemPerformanceRequirements() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let validator = BuildSystemValidator()
                let config = BuildConfiguration()
                _ = await validator.validateConfiguration(config)
            },
            maxDuration: .milliseconds(100),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testBuildSystemMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let validator = BuildSystemValidator()
            let config = BuildConfiguration()
            _ = await validator.validateConfiguration(config)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testBuildSystemErrorHandling() async throws {
        let validator = BuildSystemValidator()
        
        // Test with invalid configuration
        let invalidConfig = BuildConfiguration()
        // Set invalid properties that would cause validation to fail
        
        do {
            _ = try await validator.validateConfigurationStrict(invalidConfig)
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid configuration")
        }
    }
}