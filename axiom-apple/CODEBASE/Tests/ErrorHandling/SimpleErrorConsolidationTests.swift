import XCTest
@testable import Axiom

final class SimpleErrorConsolidationTests: XCTestCase {
    
    // Test that we need to add capability case to AxiomError
    func testNeedCapabilityCase() throws {
        // This test will fail because AxiomError doesn't have capability case
        let expectedError = "capability case needed"
        
        // Check current AxiomError cases
        let contextError = AxiomError.contextError(.lifecycleError("test"))
        let clientError = AxiomError.clientError(.invalidAction("test"))
        let navigationError = AxiomError.navigationError(.invalidRoute("test"))
        let persistenceError = AxiomError.persistenceError(.saveFailed("test"))
        let validationError = AxiomError.validationError(.invalidInput("field", "reason"))
        
        // We need a capability case but it doesn't exist
        // let capabilityError = AxiomError.capability(...)  // This doesn't compile
        
        XCTAssertNotNil(contextError)
        XCTAssertNotNil(clientError)
        XCTAssertNotNil(navigationError)
        XCTAssertNotNil(persistenceError)
        XCTAssertNotNil(validationError)
        
        // This assertion will remind us we need to add capability case
        XCTFail("AxiomError needs capability case to consolidate CapabilityError")
    }
    
    // Test that navigation errors need consolidation
    func testNavigationErrorsNeedConsolidation() throws {
        // Currently we have many separate navigation error types
        let deepLinkError = DeepLinkingError.invalidURL("test")
        let flowError = NavigationFlowError.invalidFlow("test")
        let patternError = NavigationPatternError.patternNotFound("test")
        let cancellationError = NavigationCancellationError.cancellationInProgress
        
        // These should all be consolidated into AxiomError.navigationError
        XCTAssertNotNil(deepLinkError)
        XCTAssertNotNil(flowError) 
        XCTAssertNotNil(patternError)
        XCTAssertNotNil(cancellationError)
        
        // Current AxiomNavigationError is too limited
        let currentNavError = AxiomError.navigationError(.invalidRoute("test"))
        XCTAssertNotNil(currentNavError)
        
        XCTFail("Multiple navigation error types need consolidation into AxiomError")
    }
    
    // Test that we have duplicate validation error types
    func testDuplicateValidationErrors() throws {
        // We have two different ValidationError types
        let mutationValidationError = ValidationError.validationFailed("field", "reason")
        let axiomValidationError = AxiomValidationError.invalidInput("field", "reason")
        
        XCTAssertNotNil(mutationValidationError)
        XCTAssertNotNil(axiomValidationError)
        
        XCTFail("Two different ValidationError types exist - need consolidation")
    }
    
    // Test that we have duplicate client error types
    func testDuplicateClientErrors() throws {
        // We have ClientError and AxiomClientError
        let clientError = ClientError.actionFailed("test")
        let axiomClientError = AxiomClientError.invalidAction("test")
        
        XCTAssertNotNil(clientError)
        XCTAssertNotNil(axiomClientError)
        
        XCTFail("Two different Client error types exist - need consolidation")
    }
    
    // Test error count to verify we have 12+ error types
    func testErrorTypeCount() throws {
        let errorTypes = [
            "CapabilityError",
            "ClientError", 
            "NavigationError",
            "DeepLinkingError",
            "ValidationError",
            "NavigationCancellationError", 
            "NavigationFlowError",
            "NavigationMiddlewareError",
            "NavigationPatternError",
            "RouteValidationError",
            "NavigationGraphError",
            "PersistenceError",
            "ContextError",
            "AxiomClientError",
            "AxiomNavigationError",
            "AxiomValidationError"
        ]
        
        XCTAssertGreaterThanOrEqual(errorTypes.count, 12, "Should have 12+ error types to consolidate")
        XCTFail("Need to consolidate \(errorTypes.count) error types into unified AxiomError")
    }
}