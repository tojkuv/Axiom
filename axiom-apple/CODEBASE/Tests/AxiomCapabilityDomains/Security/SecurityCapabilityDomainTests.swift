import XCTest
import AxiomTesting
@testable import AxiomCapabilityDomains
@testable import AxiomCapabilities
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomCapabilityDomains security capability domain functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class SecurityCapabilityDomainTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testSecurityCapabilityDomainInitialization() async throws {
        let securityDomain = SecurityCapabilityDomain()
        XCTAssertNotNil(securityDomain, "SecurityCapabilityDomain should initialize correctly")
        XCTAssertEqual(securityDomain.identifier, "axiom.capability.domain.security", "Should have correct identifier")
    }
    
    func testEncryptionCapabilityRegistration() async throws {
        let securityDomain = SecurityCapabilityDomain()
        
        let aesCapability = AESEncryptionCapability()
        let rsaCapability = RSAEncryptionCapability()
        let ecCapability = ECEncryptionCapability()
        let chachaCapability = ChaCha20Capability()
        
        await securityDomain.registerCapability(aesCapability)
        await securityDomain.registerCapability(rsaCapability)
        await securityDomain.registerCapability(ecCapability)
        await securityDomain.registerCapability(chachaCapability)
        
        let registeredCapabilities = await securityDomain.getRegisteredCapabilities()
        XCTAssertEqual(registeredCapabilities.count, 4, "Should have 4 registered encryption capabilities")
        
        let hasAES = await securityDomain.hasCapability("axiom.security.encryption.aes")
        XCTAssertTrue(hasAES, "Should have AES capability")
        
        let hasRSA = await securityDomain.hasCapability("axiom.security.encryption.rsa")
        XCTAssertTrue(hasRSA, "Should have RSA capability")
        
        let hasEC = await securityDomain.hasCapability("axiom.security.encryption.ec")
        XCTAssertTrue(hasEC, "Should have EC capability")
        
        let hasChaCha = await securityDomain.hasCapability("axiom.security.encryption.chacha20")
        XCTAssertTrue(hasChaCha, "Should have ChaCha20 capability")
    }
    
    func testAuthenticationCapabilityManagement() async throws {
        let securityDomain = SecurityCapabilityDomain()
        
        let biometricCapability = BiometricAuthCapability()
        let passwordCapability = PasswordAuthCapability()
        let tokenCapability = TokenAuthCapability()
        let oauthCapability = OAuthCapability()
        
        await securityDomain.registerCapability(biometricCapability)
        await securityDomain.registerCapability(passwordCapability)
        await securityDomain.registerCapability(tokenCapability)
        await securityDomain.registerCapability(oauthCapability)
        
        let authCapabilities = await securityDomain.getCapabilitiesOfType(.authentication)
        XCTAssertEqual(authCapabilities.count, 4, "Should have 4 authentication capabilities")
        
        let strongAuthCapability = await securityDomain.getBestCapabilityForUseCase(.strongAuth)
        XCTAssertNotNil(strongAuthCapability, "Should find best capability for strong authentication")
        
        let convenientAuthCapability = await securityDomain.getBestCapabilityForUseCase(.convenientAuth)
        XCTAssertNotNil(convenientAuthCapability, "Should find best capability for convenient authentication")
    }
    
    func testDigitalSignatureCapabilities() async throws {
        let securityDomain = SecurityCapabilityDomain()
        
        let rsaSigningCapability = RSASigningCapability()
        let ecdsaCapability = ECDSACapability()
        let ed25519Capability = Ed25519Capability()
        
        await securityDomain.registerCapability(rsaSigningCapability)
        await securityDomain.registerCapability(ecdsaCapability)
        await securityDomain.registerCapability(ed25519Capability)
        
        let signingCapabilities = await securityDomain.getCapabilitiesOfType(.digitalSignature)
        XCTAssertEqual(signingCapabilities.count, 3, "Should have 3 digital signature capabilities")
        
        let fastSigningCapability = await securityDomain.getBestCapabilityForUseCase(.fastSigning)
        XCTAssertNotNil(fastSigningCapability, "Should find best capability for fast signing")
    }
    
    func testSecurityPolicyEnforcement() async throws {
        let securityDomain = SecurityCapabilityDomain()
        
        // Register various security capabilities
        await securityDomain.registerCapability(AESEncryptionCapability())
        await securityDomain.registerCapability(BiometricAuthCapability())
        await securityDomain.registerCapability(RSASigningCapability())
        
        let securityPolicy = SecurityPolicy(
            encryptionLevel: .high,
            authenticationLevel: .strong,
            integrityLevel: .high,
            auditingLevel: .comprehensive
        )
        
        await securityDomain.enforceSecurityPolicy(securityPolicy)
        
        let currentPolicy = await securityDomain.getCurrentSecurityPolicy()
        XCTAssertEqual(currentPolicy.encryptionLevel, .high, "Should enforce high encryption level")
        XCTAssertEqual(currentPolicy.authenticationLevel, .strong, "Should enforce strong authentication")
        
        let compliance = await securityDomain.checkPolicyCompliance()
        XCTAssertTrue(compliance.isCompliant, "Should be compliant with security policy")
    }
    
    func testCertificateManagement() async throws {
        let securityDomain = SecurityCapabilityDomain()
        
        let certificateManager = await securityDomain.getCertificateManager()
        XCTAssertNotNil(certificateManager, "Should provide certificate manager")
        
        // Test certificate validation
        let testCertificate = TestCertificate(
            subject: "CN=Test Certificate",
            issuer: "CN=Test CA",
            validFrom: Date(),
            validTo: Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year
        )
        
        let isValid = await certificateManager!.validateCertificate(testCertificate)
        XCTAssertTrue(isValid, "Test certificate should be valid")
        
        // Test certificate chain validation
        let chainValidation = await certificateManager!.validateCertificateChain([testCertificate])
        XCTAssertNotNil(chainValidation, "Should validate certificate chain")
    }
    
    func testSecureStorageCapability() async throws {
        let securityDomain = SecurityCapabilityDomain()
        
        let keychainCapability = KeychainCapability()
        let secureEnclaveCapability = SecureEnclaveCapability()
        
        await securityDomain.registerCapability(keychainCapability)
        await securityDomain.registerCapability(secureEnclaveCapability)
        
        let storageCapabilities = await securityDomain.getCapabilitiesOfType(.secureStorage)
        XCTAssertEqual(storageCapabilities.count, 2, "Should have 2 secure storage capabilities")
        
        let highSecurityStorage = await securityDomain.getBestCapabilityForUseCase(.highSecurity)
        XCTAssertNotNil(highSecurityStorage, "Should find best capability for high security storage")
    }
    
    // MARK: - Performance Tests
    
    func testSecurityCapabilityDomainPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let securityDomain = SecurityCapabilityDomain()
                
                // Test rapid capability operations
                for i in 0..<100 {
                    let capability = TestSecurityCapability(index: i)
                    await securityDomain.registerCapability(capability)
                }
                
                // Test security policy enforcement performance
                for _ in 0..<25 {
                    let policy = SecurityPolicy(
                        encryptionLevel: .medium,
                        authenticationLevel: .basic,
                        integrityLevel: .medium,
                        auditingLevel: .basic
                    )
                    await securityDomain.enforceSecurityPolicy(policy)
                }
            },
            maxDuration: .milliseconds(300),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testSecurityCapabilityDomainMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let securityDomain = SecurityCapabilityDomain()
            
            // Simulate domain lifecycle
            for i in 0..<30 {
                let capability = TestSecurityCapability(index: i)
                await securityDomain.registerCapability(capability)
                
                if i % 5 == 0 {
                    let policy = SecurityPolicy(
                        encryptionLevel: .low,
                        authenticationLevel: .none,
                        integrityLevel: .low,
                        auditingLevel: .none
                    )
                    await securityDomain.enforceSecurityPolicy(policy)
                }
                
                if i % 10 == 0 {
                    await securityDomain.unregisterCapability(capability.identifier)
                }
            }
            
            await securityDomain.cleanup()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testSecurityCapabilityDomainErrorHandling() async throws {
        let securityDomain = SecurityCapabilityDomain()
        
        // Test registering capability with duplicate identifier
        let capability1 = TestSecurityCapability(index: 1)
        let capability2 = TestSecurityCapability(index: 1) // Same index = same identifier
        
        await securityDomain.registerCapability(capability1)
        
        do {
            try await securityDomain.registerCapabilityStrict(capability2)
            XCTFail("Should throw error for duplicate identifier")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for duplicate identifier")
        }
        
        // Test enforcing invalid security policy
        do {
            let invalidPolicy = SecurityPolicy(
                encryptionLevel: .invalid,
                authenticationLevel: .strong,
                integrityLevel: .high,
                auditingLevel: .comprehensive
            )
            try await securityDomain.enforceSecurityPolicyStrict(invalidPolicy)
            XCTFail("Should throw error for invalid policy")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid policy")
        }
        
        // Test certificate validation with expired certificate
        let certificateManager = await securityDomain.getCertificateManager()
        if let manager = certificateManager {
            let expiredCertificate = TestCertificate(
                subject: "CN=Expired Certificate",
                issuer: "CN=Test CA",
                validFrom: Date().addingTimeInterval(-365 * 24 * 60 * 60), // 1 year ago
                validTo: Date().addingTimeInterval(-1) // Yesterday
            )
            
            let isExpiredValid = await manager.validateCertificate(expiredCertificate)
            XCTAssertFalse(isExpiredValid, "Expired certificate should not be valid")
        }
    }
}

// MARK: - Test Helper Classes

private struct AESEncryptionCapability: SecurityCapability {
    let identifier = "axiom.security.encryption.aes"
    let isAvailable = true
    let securityType: SecurityType = .encryption
    let strength: SecurityStrength = .high
    let performance: SecurityPerformance = .fast
}

private struct RSAEncryptionCapability: SecurityCapability {
    let identifier = "axiom.security.encryption.rsa"
    let isAvailable = true
    let securityType: SecurityType = .encryption
    let strength: SecurityStrength = .high
    let performance: SecurityPerformance = .medium
}

private struct ECEncryptionCapability: SecurityCapability {
    let identifier = "axiom.security.encryption.ec"
    let isAvailable = true
    let securityType: SecurityType = .encryption
    let strength: SecurityStrength = .high
    let performance: SecurityPerformance = .fast
}

private struct ChaCha20Capability: SecurityCapability {
    let identifier = "axiom.security.encryption.chacha20"
    let isAvailable = true
    let securityType: SecurityType = .encryption
    let strength: SecurityStrength = .high
    let performance: SecurityPerformance = .fast
}

private struct BiometricAuthCapability: SecurityCapability {
    let identifier = "axiom.security.auth.biometric"
    let isAvailable = true
    let securityType: SecurityType = .authentication
    let strength: SecurityStrength = .high
    let performance: SecurityPerformance = .fast
}

private struct PasswordAuthCapability: SecurityCapability {
    let identifier = "axiom.security.auth.password"
    let isAvailable = true
    let securityType: SecurityType = .authentication
    let strength: SecurityStrength = .medium
    let performance: SecurityPerformance = .fast
}

private struct TokenAuthCapability: SecurityCapability {
    let identifier = "axiom.security.auth.token"
    let isAvailable = true
    let securityType: SecurityType = .authentication
    let strength: SecurityStrength = .high
    let performance: SecurityPerformance = .medium
}

private struct OAuthCapability: SecurityCapability {
    let identifier = "axiom.security.auth.oauth"
    let isAvailable = true
    let securityType: SecurityType = .authentication
    let strength: SecurityStrength = .medium
    let performance: SecurityPerformance = .medium
}

private struct RSASigningCapability: SecurityCapability {
    let identifier = "axiom.security.signing.rsa"
    let isAvailable = true
    let securityType: SecurityType = .digitalSignature
    let strength: SecurityStrength = .high
    let performance: SecurityPerformance = .medium
}

private struct ECDSACapability: SecurityCapability {
    let identifier = "axiom.security.signing.ecdsa"
    let isAvailable = true
    let securityType: SecurityType = .digitalSignature
    let strength: SecurityStrength = .high
    let performance: SecurityPerformance = .fast
}

private struct Ed25519Capability: SecurityCapability {
    let identifier = "axiom.security.signing.ed25519"
    let isAvailable = true
    let securityType: SecurityType = .digitalSignature
    let strength: SecurityStrength = .high
    let performance: SecurityPerformance = .fastest
}

private struct KeychainCapability: SecurityCapability {
    let identifier = "axiom.security.storage.keychain"
    let isAvailable = true
    let securityType: SecurityType = .secureStorage
    let strength: SecurityStrength = .high
    let performance: SecurityPerformance = .fast
}

private struct SecureEnclaveCapability: SecurityCapability {
    let identifier = "axiom.security.storage.enclave"
    let isAvailable = true
    let securityType: SecurityType = .secureStorage
    let strength: SecurityStrength = .highest
    let performance: SecurityPerformance = .medium
}

private struct TestSecurityCapability: SecurityCapability {
    let identifier: String
    let isAvailable = true
    let securityType: SecurityType = .encryption
    let strength: SecurityStrength = .medium
    let performance: SecurityPerformance = .medium
    
    init(index: Int) {
        self.identifier = "test.security.capability.\(index)"
    }
}

private enum SecurityType {
    case encryption
    case authentication
    case digitalSignature
    case secureStorage
    case accessControl
}

private enum SecurityStrength {
    case low
    case medium
    case high
    case highest
}

private enum SecurityPerformance {
    case slow
    case medium
    case fast
    case fastest
}

private enum SecurityLevel {
    case none
    case low
    case medium
    case high
    case invalid
}

private enum SecurityUseCase {
    case strongAuth
    case convenientAuth
    case fastSigning
    case highSecurity
    case compliance
}

private struct SecurityPolicy {
    let encryptionLevel: SecurityLevel
    let authenticationLevel: SecurityLevel
    let integrityLevel: SecurityLevel
    let auditingLevel: SecurityLevel
}

private struct TestCertificate {
    let subject: String
    let issuer: String
    let validFrom: Date
    let validTo: Date
}