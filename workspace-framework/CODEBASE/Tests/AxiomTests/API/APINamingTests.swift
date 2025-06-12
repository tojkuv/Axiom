import XCTest
@testable import Axiom

final class APINamingTests: XCTestCase {
    
    func testProtocolsDoNotHaveRedundantSuffixes() throws {
        let violations = APINamingValidator.findProtocolSuffixViolations()
        
        XCTAssertEqual(violations.count, 0, 
            "Found protocols with redundant suffixes: \(violations.joined(separator: ", "))")
    }
    
    func testMethodsUseConsistentPrefixes() throws {
        let violations = APINamingValidator.findInconsistentMethodPrefixes()
        
        XCTAssertEqual(violations.count, 0,
            "Found methods with inconsistent prefixes: \(violations.map { "\($0.method) in \($0.type)" }.joined(separator: ", "))")
    }
    
    func testBooleanPropertiesHaveProperPrefixes() throws {
        let violations = APINamingValidator.findBooleanPrefixViolations()
        
        XCTAssertEqual(violations.count, 0,
            "Found boolean properties without proper prefixes: \(violations.joined(separator: ", "))")
    }
    
    func testNoVagueClassNames() throws {
        let violations = APINamingValidator.findVagueClassNames()
        
        XCTAssertEqual(violations.count, 0,
            "Found classes with vague names: \(violations.joined(separator: ", "))")
    }
    
    func testAsyncMethodsFollowConventions() throws {
        let violations = APINamingValidator.findAsyncNamingViolations()
        
        XCTAssertEqual(violations.count, 0,
            "Found async methods with naming violations: \(violations.joined(separator: ", "))")
    }
    
    // Test for lifecycle method consistency
    func testLifecycleMethodsUseConsistentTense() throws {
        let violations = APINamingValidator.findLifecycleNamingViolations()
        
        XCTAssertEqual(violations.count, 0,
            "Found lifecycle methods with inconsistent tense: \(violations.joined(separator: ", "))")
    }
    
    // Test for parameter naming conventions
    func testParameterLabelsFollowConventions() throws {
        let violations = APINamingValidator.findParameterLabelViolations()
        
        XCTAssertEqual(violations.count, 0,
            "Found parameters with poor labels: \(violations.map { "\($0.method)(\($0.parameter))" }.joined(separator: ", "))")
    }
}