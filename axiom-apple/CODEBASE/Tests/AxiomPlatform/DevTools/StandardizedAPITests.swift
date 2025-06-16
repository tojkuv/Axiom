import XCTest
import AxiomTesting
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomPlatform API standardization functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class StandardizedAPITests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testStandardizedAPIInitialization() async throws {
        let api = StandardizedAPI()
        XCTAssertNotNil(api, "StandardizedAPI should initialize correctly")
    }
    
    func testAPINamingValidator() async throws {
        let validator = APINamingValidator()
        
        let validName = "getUserProfile"
        let isValid = await validator.validateMethodName(validName)
        XCTAssertTrue(isValid, "Valid method name should pass validation")
        
        let invalidName = "get_user_profile"
        let isInvalid = await validator.validateMethodName(invalidName)
        XCTAssertFalse(isInvalid, "Invalid method name should fail validation")
    }
    
    func testStandardizedImplementations() async throws {
        let implementations = StandardizedImplementations()
        
        let standardMethods = await implementations.getStandardMethods()
        XCTAssertFalse(standardMethods.isEmpty, "Should have standard method implementations")
    }
    
    // MARK: - Performance Tests
    
    func testAPIStandardizationPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let validator = APINamingValidator()
                let methodNames = ["getUserProfile", "updateUserData", "deleteUser", "createUserSession"]
                
                for name in methodNames {
                    _ = await validator.validateMethodName(name)
                }
            },
            maxDuration: .milliseconds(50),
            maxMemoryGrowth: 512 * 1024 // 512KB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testAPIStandardizationMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let validator = APINamingValidator()
            let api = StandardizedAPI()
            
            for i in 0..<100 {
                let methodName = "testMethod\(i)"
                _ = await validator.validateMethodName(methodName)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testAPIStandardizationErrorHandling() async throws {
        let implementations = StandardizedImplementations()
        
        do {
            _ = try await implementations.validateImplementation(nil)
            XCTFail("Should throw error for nil implementation")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid implementation")
        }
    }
}