import XCTest
@testable import Axiom

final class ErrorPropertyTests: XCTestCase {
    
    func testCapabilityErrorHasIdAndUserMessage() {
        // Test each case of CapabilityError
        let deniedError = CapabilityError.denied(.network)
        XCTAssertNotNil(deniedError.id)
        XCTAssertFalse(deniedError.userMessage.isEmpty)
        
        let expiredError = CapabilityError.expired(CapabilityLease(id: "test", capability: .network, grantedAt: Date(), duration: 60.0, validationRequirement: .none))
        XCTAssertNotNil(expiredError.id)
        XCTAssertFalse(expiredError.userMessage.isEmpty)
        
        let unavailableError = CapabilityError.unavailable(.network)
        XCTAssertNotNil(unavailableError.id)
        XCTAssertFalse(unavailableError.userMessage.isEmpty)
        
        let configError = CapabilityError.configurationInvalid("test config")
        XCTAssertNotNil(configError.id)
        XCTAssertFalse(configError.userMessage.isEmpty)
    }
    
    func testDomainErrorHasIdAndUserMessage() {
        // Test each case of DomainError
        let validationError = DomainError.validationFailed(DomainValidationResult(isValid: false, errors: ["Field required"]))
        XCTAssertNotNil(validationError.id)
        XCTAssertFalse(validationError.userMessage.isEmpty)
        
        let businessRuleError = DomainError.businessRuleViolation(BusinessRule(description: "Rule violated"))
        XCTAssertNotNil(businessRuleError.id)
        XCTAssertFalse(businessRuleError.userMessage.isEmpty)
        
        let stateError = DomainError.stateInconsistent("Inconsistent state")
        XCTAssertNotNil(stateError.id)
        XCTAssertFalse(stateError.userMessage.isEmpty)
        
        let aggregateError = DomainError.aggregateNotFound("aggregate-123")
        XCTAssertNotNil(aggregateError.id)
        XCTAssertFalse(aggregateError.userMessage.isEmpty)
    }
    
    func testGenericErrorHasIdAndUserMessage() {
        struct TestError: Error {
            let message: String
        }
        
        let genericError = GenericError(underlyingError: TestError(message: "Test error"))
        XCTAssertNotNil(genericError.id)
        XCTAssertFalse(genericError.userMessage.isEmpty)
    }
    
    func testAxiomApplicationErrorHasIdAndUserMessage() {
        // Test each case of AxiomApplicationError
        let launchError = AxiomApplicationError.applicationNotLaunched
        XCTAssertNotNil(launchError.id)
        XCTAssertFalse(launchError.userMessage.isEmpty)
        
        let bindingError = AxiomApplicationError.invalidViewContextBinding(contextType: "TestContext", viewType: "TestView")
        XCTAssertNotNil(bindingError.id)
        XCTAssertFalse(bindingError.userMessage.isEmpty)
        
        let dependencyError = AxiomApplicationError.dependencyResolutionFailed("TestDependency")
        XCTAssertNotNil(dependencyError.id)
        XCTAssertFalse(dependencyError.userMessage.isEmpty)
        
        let configError = AxiomApplicationError.configurationError("Invalid config")
        XCTAssertNotNil(configError.id)
        XCTAssertFalse(configError.userMessage.isEmpty)
    }
    
    func testErrorIdsAreUnique() {
        // Each error should generate a unique ID
        let error1 = CapabilityError.denied(.network)
        let error2 = CapabilityError.denied(.network)
        
        XCTAssertNotEqual(error1.id, error2.id, "Each error instance should have a unique ID")
    }
    
    func testUserMessagesAreUserFriendly() {
        // Test that user messages don't contain technical jargon
        let technicalError = CapabilityError.expired(CapabilityLease(id: "lease-123", capability: .network, grantedAt: Date(), duration: 60.0, validationRequirement: .none))
        
        // User message should not contain technical IDs
        XCTAssertFalse(technicalError.userMessage.contains("lease-123"))
        XCTAssertTrue(technicalError.userMessage.contains("expired") || technicalError.userMessage.contains("refresh"))
    }
}