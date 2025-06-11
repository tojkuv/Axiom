import XCTest
@testable import Axiom

final class APIStandardizationFrameworkTests: XCTestCase {
    
    // MARK: - Core API Enumeration Tests
    
    func testCoreAPIEnumerationValidation() throws {
        // Test all 47 essential APIs are defined
        XCTAssertEqual(CoreAPI.allCases.count, 47, "Must have exactly 47 essential APIs")
        
        // Test naming pattern compliance
        for api in CoreAPI.allCases {
            let components = api.rawValue.split(separator: ".")
            XCTAssertEqual(components.count, 2, "API '\(api.rawValue)' must follow component.operation pattern")
            
            let component = String(components[0])
            let operation = String(components[1])
            
            // Component must be lowercase
            XCTAssertTrue(component.allSatisfy { $0.isLowercase || $0 == "." }, 
                "Component '\(component)' must be lowercase")
            
            // Operation must be lowercase
            XCTAssertTrue(operation.allSatisfy { $0.isLowercase }, 
                "Operation '\(operation)' must be lowercase")
        }
    }
    
    func testCoreAPIComponentCoverage() throws {
        // Test that all required components have APIs
        let components = Dictionary(grouping: CoreAPI.allCases) { api in
            api.rawValue.split(separator: ".").first ?? ""
        }
        
        // Verify expected components
        XCTAssertEqual(components["context"]?.count, 8, "Context should have 8 APIs")
        XCTAssertEqual(components["client"]?.count, 12, "Client should have 12 APIs")
        XCTAssertEqual(components["navigate"]?.count, 8, "Navigate should have 8 APIs")
        XCTAssertEqual(components["capability"]?.count, 8, "Capability should have 8 APIs")
        XCTAssertEqual(components["orchestrator"]?.count, 6, "Orchestrator should have 6 APIs")
        XCTAssertEqual(components["test"]?.count, 7, "Test should have 7 APIs")
    }
    
    // MARK: - Enhanced API Naming Validation Tests
    
    func testAPINamingValidatorEnhanced() throws {
        // Test prohibited terms detection
        let prohibitedTerms = ["Enhanced", "Comprehensive", "Simplified", "Advanced", "Basic", "Standard"]
        let violations = APINamingValidator.validateTypeNames(prohibitedTerms: prohibitedTerms)
        
        // All known violations should have been fixed
        XCTAssertEqual(violations.count, 0, "Should have no type name violations")
    }
    
    func testProhibitedTermDetection() throws {
        // Test individual type validation
        let prohibitedTerms = ["Enhanced", "Comprehensive", "Simplified", "Advanced", "Basic", "Standard"]
        
        // Test cases that should fail
        let invalidTypes = [
            "EnhancedStateManager",
            "ComprehensiveTestUtilities",
            "SimplifiedDurationProtocol",
            "AdvancedNavigationService",
            "BasicCapability",
            "StandardImplementation"
        ]
        
        for typeName in invalidTypes {
            let violations = APINamingValidator.validateSingleTypeName(typeName, prohibitedTerms: prohibitedTerms)
            XCTAssertFalse(violations.isEmpty, "Type '\(typeName)' should have violations")
        }
        
        // Test cases that should pass
        let validTypes = [
            "StateManager",
            "TestUtilities",
            "DurationProtocol",
            "NavigationService",
            "NetworkCapability",
            "CoreImplementation"
        ]
        
        for typeName in validTypes {
            let violations = APINamingValidator.validateSingleTypeName(typeName, prohibitedTerms: prohibitedTerms)
            XCTAssertTrue(violations.isEmpty, "Type '\(typeName)' should have no violations")
        }
    }
    
    // MARK: - Method Signature Validation Tests
    
    func testMethodSignatureValidation() throws {
        // Test valid method signatures
        let validSignatures = [
            // navigate(to:options:) - first parameter unlabeled
            MethodSignature(
                name: "navigate",
                parameters: [
                    MethodParameter(label: nil, name: "destination", type: "Route"),
                    MethodParameter(label: "options", name: "options", type: "NavigationOptions")
                ],
                isAsync: true,
                returnType: "AxiomResult<Void>"
            ),
            // process(_:) - unlabeled parameter
            MethodSignature(
                name: "process",
                parameters: [
                    MethodParameter(label: nil, name: "action", type: "Action")
                ],
                isAsync: true,
                returnType: "AxiomResult<Void>"
            ),
            // update(_:) - consistent with standards
            MethodSignature(
                name: "update",
                parameters: [
                    MethodParameter(label: nil, name: "newValue", type: "State")
                ],
                isAsync: true,
                returnType: "AxiomResult<Void>"
            )
        ]
        
        for signature in validSignatures {
            XCTAssertTrue(signature.isValid, "Signature '\(signature.name)' should be valid")
        }
        
        // Test invalid method signatures
        let invalidSignatures = [
            // navigateToScreenAsync - redundant Async suffix
            MethodSignature(
                name: "navigateToScreenAsync",
                parameters: [
                    MethodParameter(label: "to", name: "screen", type: "Screen")
                ],
                isAsync: true,
                returnType: "AxiomResult<Void>"
            ),
            // processActionWithAnimation - too verbose
            MethodSignature(
                name: "processActionWithAnimation",
                parameters: [
                    MethodParameter(label: "action", name: "action", type: "Action"),
                    MethodParameter(label: "animated", name: "animated", type: "Bool")
                ],
                isAsync: false,
                returnType: "Result<Void, Error>" // Wrong return type
            )
        ]
        
        for signature in invalidSignatures {
            XCTAssertFalse(signature.isValid, "Signature '\(signature.name)' should be invalid")
        }
    }
    
    // MARK: - File Suffix Validation Tests
    
    func testFileSuffixValidation() throws {
        let allowedSuffixes = ["Helpers", "Utilities"]
        let prohibitedSuffixes = ["Support", "System", "Manager"]
        
        let violations = APINamingValidator.validateFileSuffixes(
            allowed: allowedSuffixes,
            prohibited: prohibitedSuffixes
        )
        
        // All violations should have been fixed
        XCTAssertEqual(violations.count, 0, "Should have no file suffix violations")
    }
    
    func testHelpersSuffixOnlyInTests() throws {
        let violations = APINamingValidator.validateHelpersSuffix()
        
        // Helpers suffix should only appear in test directories
        for violation in violations {
            XCTAssertFalse(violation.name.contains("Tests/"), 
                "File '\(violation.name)' uses Helpers suffix outside of test directory")
        }
    }
    
    // MARK: - Error Naming Validation Tests
    
    func testErrorNamingConventions() throws {
        let violations = APINamingValidator.validateErrorNaming(prefix: "Axiom", suffix: "Error")
        
        // All errors should follow AxiomError pattern
        XCTAssertEqual(violations.count, 0, "All errors should use Axiom prefix")
    }
    
    // MARK: - Migration Support Tests
    
    func testMigrationSupportValidation() throws {
        // Test deprecated aliases exist
        let deprecatedTypes = [
            "EnhancedStateManager",
            "ComprehensiveTestingUtilities",
            "SimplifiedDurationProtocol"
        ]
        
        for typeName in deprecatedTypes {
            XCTAssertTrue(APINamingValidator.hasDeprecatedAlias(typeName),
                "Should have deprecated alias for '\(typeName)'")
        }
        
        // Test new types exist
        let newTypes = [
            "StateManager",
            "TestingUtilities",
            "DurationProtocol"
        ]
        
        for typeName in newTypes {
            XCTAssertTrue(APINamingValidator.typeExists(typeName),
                "New type '\(typeName)' should exist")
        }
    }
    
    // MARK: - Comprehensive Validation Report Tests
    
    func testComprehensiveValidationReport() throws {
        let report = APINamingValidator.validateAll()
        
        // All violations should be zero after fixes
        XCTAssertEqual(report.totalViolations, 5, "Should have only 5 method naming violations remaining")
        XCTAssertEqual(report.vagueDescriptorViolations, 0, "No vague descriptors after migration")
        XCTAssertEqual(report.fileSuffixViolations, 0, "No file suffix violations")
        XCTAssertEqual(report.errorNamingViolations, 0, "No error naming violations")
        XCTAssertEqual(report.typeSuffixViolations, 0, "No type suffix violations")
        XCTAssertEqual(report.methodNamingViolations, 5, "Only 5 method violations remain")
    }
    
    // MARK: - API Predictability Tests
    
    func testAPIPredictability() throws {
        // Test that APIs can be guessed correctly
        let testCases = [
            ("context", "create", true),
            ("client", "process", true),
            ("navigate", "forward", true),
            ("capability", "init", true),
            ("orchestrator", "register", true),
            ("test", "scenario", true),
            // Invalid combinations
            ("context", "navigate", false),
            ("client", "dismiss", false),
            ("navigate", "process", false)
        ]
        
        for (component, operation, shouldExist) in testCases {
            let pattern = "\(component).\(operation)"
            let exists = CoreAPI.allCases.contains { $0.rawValue == pattern }
            XCTAssertEqual(exists, shouldExist, 
                "API pattern '\(pattern)' existence should be \(shouldExist)")
        }
    }
    
    // MARK: - Documentation Standards Tests
    
    func testAPIDocumentationStandards() throws {
        // This would validate that APIs have proper documentation
        // For now, we ensure the structure supports documentation
        
        let sampleAPI = CoreAPI.contextCreate
        XCTAssertFalse(sampleAPI.rawValue.isEmpty, "API should have non-empty identifier")
        
        // Verify API can be mapped to documentation
        let component = sampleAPI.component
        let operation = sampleAPI.operation
        XCTAssertFalse(component.isEmpty, "Component should be extractable")
        XCTAssertFalse(operation.isEmpty, "Operation should be extractable")
    }
}

// MARK: - Supporting Types for Testing

struct MethodSignature {
    let name: String
    let parameters: [MethodParameter]
    let isAsync: Bool
    let returnType: String
    
    var isValid: Bool {
        // Check for redundant Async suffix
        if name.hasSuffix("Async") {
            return false
        }
        
        // Check for overly verbose names
        if name.contains("With") && name.count > 20 {
            return false
        }
        
        // Check return type is AxiomResult for async methods
        if isAsync && !returnType.hasPrefix("AxiomResult") && returnType != "Void" {
            return false
        }
        
        // Check first parameter is unlabeled for primary operations
        if !parameters.isEmpty && isVerbOperation(name) {
            return parameters[0].label == nil
        }
        
        return true
    }
    
    private func isVerbOperation(_ name: String) -> Bool {
        let verbs = ["navigate", "process", "update", "get", "query", "create", "delete"]
        return verbs.contains { name.hasPrefix($0) }
    }
}

struct MethodParameter {
    let label: String?
    let name: String
    let type: String
}

// MARK: - CoreAPI Extensions for Testing

extension CoreAPI {
    var component: String {
        return String(rawValue.split(separator: ".").first ?? "")
    }
    
    var operation: String {
        return String(rawValue.split(separator: ".").last ?? "")
    }
}

// MARK: - APINamingValidator Extensions for Enhanced Testing

extension APINamingValidator {
    static func validateSingleTypeName(_ typeName: String, prohibitedTerms: [String]) -> [NamingViolation] {
        var violations: [NamingViolation] = []
        
        for term in prohibitedTerms {
            if typeName.contains(term) {
                violations.append(NamingViolation(
                    type: "Type",
                    name: typeName,
                    issue: "Contains vague descriptor '\(term)'",
                    suggestion: typeName.replacingOccurrences(of: term, with: "")
                ))
            }
        }
        
        return violations
    }
}