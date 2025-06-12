import XCTest
@testable import Axiom

final class NamingConventionTests: XCTestCase {
    
    // MARK: - Vague Descriptor Tests
    
    func testNoVagueDescriptorsInTypeNames() throws {
        // Test that no types use vague descriptors
        let vagueTerms = ["Enhanced", "Comprehensive", "Simplified", "Advanced", "Basic", "Standard"]
        let violations = APINamingValidator.validateTypeNames(prohibitedTerms: vagueTerms)
        
        XCTAssertTrue(violations.isEmpty, 
                     "Found vague descriptors in type names: \(violations.map { $0.description })")
    }
    
    // MARK: - File Suffix Tests
    
    func testFileSuffixConsistency() throws {
        // Test that file suffixes follow standard patterns
        let allowedSuffixes = ["Helpers", "Utilities"]
        let prohibitedSuffixes = ["Support", "System"]
        
        let violations = APINamingValidator.validateFileSuffixes(
            allowed: allowedSuffixes,
            prohibited: prohibitedSuffixes
        )
        
        XCTAssertTrue(violations.isEmpty,
                     "Found non-standard file suffixes: \(violations.map { $0.description })")
    }
    
    func testHelpersOnlyInTests() throws {
        // Helpers suffix should only be used in test files
        let violations = APINamingValidator.validateHelpersSuffix()
        
        XCTAssertTrue(violations.isEmpty,
                     "Found Helpers suffix in production code: \(violations.map { $0.description })")
    }
    
    // MARK: - Error Naming Tests
    
    func testAllErrorsHaveAxiomPrefix() throws {
        // All error types should start with "Axiom"
        let violations = APINamingValidator.validateErrorNaming(prefix: "Axiom", suffix: "Error")
        
        XCTAssertTrue(violations.isEmpty,
                     "Found errors without Axiom prefix: \(violations.map { $0.description })")
    }
    
    // MARK: - Type Suffix Tests
    
    func testTypeSuffixSemantics() throws {
        // Validate that type suffixes are used correctly
        let suffixRules = [
            "Manager": "Should be stateful coordinators",
            "Handler": "Should process events",
            "Service": "Should be stateless utilities",
            "Provider": "Should provide dependencies",
            "Controller": "Should only be used for UI contexts"
        ]
        
        let violations = APINamingValidator.validateTypeSuffixes(rules: suffixRules)
        
        XCTAssertTrue(violations.isEmpty,
                     "Found incorrect type suffix usage: \(violations.map { $0.description })")
    }
    
    // MARK: - Method Naming Tests
    
    func testMethodNamingConsistency() throws {
        // Test that methods use consistent naming patterns
        let violations = APINamingValidator.validateMethodNaming()
        
        XCTAssertTrue(violations.isEmpty,
                     "Found inconsistent method naming: \(violations.map { $0.description })")
    }
    
    // MARK: - Integration Tests
    
    func testComprehensiveNamingValidation() throws {
        // Run all naming validations together
        let report = APINamingValidator.validateAll()
        
        XCTAssertEqual(report.totalViolations, 0,
                      "Found \(report.totalViolations) naming violations:\n\(report.summary)")
        
        // Verify specific counts
        XCTAssertEqual(report.vagueDescriptorViolations, 0)
        XCTAssertEqual(report.fileSuffixViolations, 0)
        XCTAssertEqual(report.errorNamingViolations, 0)
        XCTAssertEqual(report.typeSuffixViolations, 0)
        XCTAssertEqual(report.methodNamingViolations, 0)
    }
}

// MARK: - Test Helpers

extension NamingConventionTests {
    
    func testSpecificVagueDescriptorReplacement() throws {
        // Test that specific vague descriptors are replaced correctly
        let replacements = [
            "EnhancedStateManager": "CachedStateManager",
            "ComprehensiveTestingUtilities": "PerformanceTestUtilities",
            "SimplifiedDurationProtocol": "BasicDuration"
        ]
        
        for (old, new) in replacements {
            let exists = APINamingValidator.typeExists(old)
            XCTAssertFalse(exists, "\(old) should be renamed to \(new)")
        }
    }
    
    func testDeprecatedTypeAliases() throws {
        // Test that deprecated type aliases exist for migration
        let deprecatedTypes = [
            "EnhancedStateManager",
            "ComprehensiveTestingUtilities"
        ]
        
        for type in deprecatedTypes {
            let hasAlias = APINamingValidator.hasDeprecatedAlias(type)
            XCTAssertTrue(hasAlias, "\(type) should have deprecated type alias")
        }
    }
}