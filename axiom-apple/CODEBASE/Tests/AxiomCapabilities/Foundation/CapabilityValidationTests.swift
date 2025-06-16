import XCTest
import AxiomTesting
@testable import AxiomCapabilities
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomCapabilities validation and security functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class CapabilityValidationTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testCapabilityValidatorInitialization() async throws {
        let validator = CapabilityValidator()
        XCTAssertNotNil(validator, "CapabilityValidator should initialize correctly")
    }
    
    func testCapabilitySignatureValidation() async throws {
        let validator = CapabilityValidator()
        let signedCapability = SignedTestCapability()
        
        let isValidSignature = await validator.validateSignature(signedCapability)
        XCTAssertTrue(isValidSignature, "Valid signature should pass validation")
        
        let tampered = TamperedTestCapability()
        let isTamperedValid = await validator.validateSignature(tampered)
        XCTAssertFalse(isTamperedValid, "Tampered signature should fail validation")
    }
    
    func testCapabilityPermissionValidation() async throws {
        let validator = CapabilityValidator()
        let permissionCapability = PermissionValidationCapability()
        
        // Test with granted permissions
        let context = ValidationContext(grantedPermissions: ["camera", "location"])
        let hasPermissions = await validator.validatePermissions(permissionCapability, context: context)
        XCTAssertTrue(hasPermissions, "Should validate when all permissions are granted")
        
        // Test with missing permissions
        let restrictedContext = ValidationContext(grantedPermissions: ["camera"])
        let hasMissingPermissions = await validator.validatePermissions(permissionCapability, context: restrictedContext)
        XCTAssertFalse(hasMissingPermissions, "Should fail when permissions are missing")
    }
    
    func testCapabilityDependencyValidation() async throws {
        let validator = CapabilityValidator()
        let dependencyCapability = DependencyValidationCapability()
        
        // Test with satisfied dependencies
        let registry = TestCapabilityRegistry()
        await registry.registerCapability(BaseValidationCapability())
        
        let context = ValidationContext(capabilityRegistry: registry)
        let hasDependencies = await validator.validateDependencies(dependencyCapability, context: context)
        XCTAssertTrue(hasDependencies, "Should validate when dependencies are satisfied")
        
        // Test with missing dependencies
        let emptyRegistry = TestCapabilityRegistry()
        let emptyContext = ValidationContext(capabilityRegistry: emptyRegistry)
        let hasMissingDependencies = await validator.validateDependencies(dependencyCapability, context: emptyContext)
        XCTAssertFalse(hasMissingDependencies, "Should fail when dependencies are missing")
    }
    
    func testCapabilitySecurityValidation() async throws {
        let validator = CapabilityValidator()
        let secureCapability = SecureValidationCapability()
        
        // Test with valid security context
        let secureContext = ValidationContext(
            securityLevel: .high,
            sandboxed: true,
            encryptionEnabled: true
        )
        let isSecure = await validator.validateSecurity(secureCapability, context: secureContext)
        XCTAssertTrue(isSecure, "Should validate secure capability in secure context")
        
        // Test with insufficient security
        let insecureContext = ValidationContext(
            securityLevel: .low,
            sandboxed: false,
            encryptionEnabled: false
        )
        let isInsecure = await validator.validateSecurity(secureCapability, context: insecureContext)
        XCTAssertFalse(isInsecure, "Should fail secure capability in insecure context")
    }
    
    func testCapabilityVersionValidation() async throws {
        let validator = CapabilityValidator()
        
        let currentCapability = VersionedTestCapability(version: "2.0.0")
        let minimumVersion = "1.5.0"
        let maximumVersion = "3.0.0"
        
        let isValidVersion = await validator.validateVersion(
            currentCapability,
            minimumVersion: minimumVersion,
            maximumVersion: maximumVersion
        )
        XCTAssertTrue(isValidVersion, "Version 2.0.0 should be valid between 1.5.0 and 3.0.0")
        
        let oldCapability = VersionedTestCapability(version: "1.0.0")
        let isTooOld = await validator.validateVersion(
            oldCapability,
            minimumVersion: minimumVersion,
            maximumVersion: maximumVersion
        )
        XCTAssertFalse(isTooOld, "Version 1.0.0 should be too old")
        
        let newCapability = VersionedTestCapability(version: "4.0.0")
        let isTooNew = await validator.validateVersion(
            newCapability,
            minimumVersion: minimumVersion,
            maximumVersion: maximumVersion
        )
        XCTAssertFalse(isTooNew, "Version 4.0.0 should be too new")
    }
    
    func testComprehensiveCapabilityValidation() async throws {
        let validator = CapabilityValidator()
        let comprehensiveCapability = ComprehensiveTestCapability()
        
        let context = ValidationContext(
            grantedPermissions: ["camera", "location"],
            securityLevel: .high,
            sandboxed: true,
            encryptionEnabled: true,
            capabilityRegistry: TestCapabilityRegistry()
        )
        
        let validationResult = await validator.validateCapability(comprehensiveCapability, context: context)
        XCTAssertTrue(validationResult.isValid, "Comprehensive validation should pass")
        XCTAssertTrue(validationResult.errors.isEmpty, "Should have no validation errors")
        
        // Add base dependency to registry
        await context.capabilityRegistry?.registerCapability(BaseValidationCapability())
        
        let updatedResult = await validator.validateCapability(comprehensiveCapability, context: context)
        XCTAssertTrue(updatedResult.isValid, "Should pass with satisfied dependencies")
    }
    
    // MARK: - Performance Tests
    
    func testCapabilityValidationPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let validator = CapabilityValidator()
                let context = ValidationContext(
                    grantedPermissions: ["camera", "location", "microphone"],
                    securityLevel: .medium,
                    sandboxed: true,
                    encryptionEnabled: true
                )
                
                // Test rapid validation of multiple capabilities
                for i in 0..<100 {
                    let capability = PerformanceValidationCapability(index: i)
                    _ = await validator.validateCapability(capability, context: context)
                }
            },
            maxDuration: .milliseconds(300),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testCapabilityValidationMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let validator = CapabilityValidator()
            let context = ValidationContext(
                grantedPermissions: ["camera", "location"],
                securityLevel: .high,
                sandboxed: true,
                encryptionEnabled: true
            )
            
            // Simulate validation lifecycle
            for i in 0..<50 {
                let capability = MemoryValidationCapability(index: i)
                _ = await validator.validateSignature(capability)
                _ = await validator.validatePermissions(capability, context: context)
                _ = await validator.validateSecurity(capability, context: context)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testCapabilityValidationErrorHandling() async throws {
        let validator = CapabilityValidator()
        
        // Test validation with nil capability
        do {
            let context = ValidationContext()
            try await validator.validateCapabilityStrict(nil, context: context)
            XCTFail("Should throw error for nil capability")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for nil capability")
        }
        
        // Test validation with corrupted signature
        let corruptedCapability = CorruptedSignatureCapability()
        do {
            try await validator.validateSignatureStrict(corruptedCapability)
            XCTFail("Should throw error for corrupted signature")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for corrupted signature")
        }
        
        // Test validation with invalid context
        let capability = ComprehensiveTestCapability()
        do {
            let invalidContext = ValidationContext(securityLevel: .invalid)
            try await validator.validateCapabilityStrict(capability, context: invalidContext)
            XCTFail("Should throw error for invalid context")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid context")
        }
    }
}

// MARK: - Test Helper Classes

private struct SignedTestCapability: AxiomCapability {
    let identifier = "test.signed.capability"
    let isAvailable = true
    let signature = "valid_signature_data"
}

private struct TamperedTestCapability: AxiomCapability {
    let identifier = "test.tampered.capability"
    let isAvailable = true
    let signature = "tampered_signature_data"
}

private struct PermissionValidationCapability: AxiomCapability {
    let identifier = "test.permission.validation.capability"
    let isAvailable = true
    let requiredPermissions = ["camera", "location"]
}

private struct DependencyValidationCapability: AxiomCapability {
    let identifier = "test.dependency.validation.capability"
    let isAvailable = true
    let dependencies = ["test.base.validation.capability"]
}

private struct BaseValidationCapability: AxiomCapability {
    let identifier = "test.base.validation.capability"
    let isAvailable = true
}

private struct SecureValidationCapability: AxiomCapability {
    let identifier = "test.secure.validation.capability"
    let isAvailable = true
    let securityRequirements = SecurityRequirements(
        minimumSecurityLevel: .high,
        requiresSandbox: true,
        requiresEncryption: true
    )
}

private struct VersionedTestCapability: AxiomCapability {
    let identifier = "test.versioned.capability"
    let isAvailable = true
    let version: String
    
    init(version: String) {
        self.version = version
    }
}

private struct ComprehensiveTestCapability: AxiomCapability {
    let identifier = "test.comprehensive.capability"
    let isAvailable = true
    let requiredPermissions = ["camera", "location"]
    let dependencies = ["test.base.validation.capability"]
    let securityRequirements = SecurityRequirements(
        minimumSecurityLevel: .medium,
        requiresSandbox: true,
        requiresEncryption: false
    )
}

private struct PerformanceValidationCapability: AxiomCapability {
    let identifier: String
    let isAvailable = true
    let requiredPermissions = ["camera"]
    
    init(index: Int) {
        self.identifier = "test.performance.validation.capability.\(index)"
    }
}

private struct MemoryValidationCapability: AxiomCapability {
    let identifier: String
    let isAvailable = true
    
    init(index: Int) {
        self.identifier = "test.memory.validation.capability.\(index)"
    }
}

private struct CorruptedSignatureCapability: AxiomCapability {
    let identifier = "test.corrupted.capability"
    let isAvailable = true
    let signature = "corrupted_data"
}

private struct ValidationContext {
    let grantedPermissions: [String]
    let securityLevel: SecurityLevel
    let sandboxed: Bool
    let encryptionEnabled: Bool
    let capabilityRegistry: TestCapabilityRegistry?
    
    init(
        grantedPermissions: [String] = [],
        securityLevel: SecurityLevel = .medium,
        sandboxed: Bool = false,
        encryptionEnabled: Bool = false,
        capabilityRegistry: TestCapabilityRegistry? = nil
    ) {
        self.grantedPermissions = grantedPermissions
        self.securityLevel = securityLevel
        self.sandboxed = sandboxed
        self.encryptionEnabled = encryptionEnabled
        self.capabilityRegistry = capabilityRegistry
    }
}

private enum SecurityLevel {
    case low
    case medium
    case high
    case invalid
}

private struct SecurityRequirements {
    let minimumSecurityLevel: SecurityLevel
    let requiresSandbox: Bool
    let requiresEncryption: Bool
}

private class TestCapabilityRegistry {
    private var capabilities: [String: AxiomCapability] = [:]
    
    func registerCapability(_ capability: AxiomCapability) async {
        capabilities[capability.identifier] = capability
    }
    
    func isCapabilityRegistered(_ identifier: String) async -> Bool {
        return capabilities[identifier] != nil
    }
}

private struct ValidationResult {
    let isValid: Bool
    let errors: [String]
}