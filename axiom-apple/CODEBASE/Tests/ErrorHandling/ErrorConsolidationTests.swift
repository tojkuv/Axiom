import XCTest
@testable import Axiom

final class ErrorConsolidationTests: XCTestCase {
    
    // Test that capability errors are part of AxiomError
    func testCapabilityErrorsConsolidated() throws {
        // Current state: CapabilityError is separate
        let capabilityError = CapabilityError.notAvailable("test")
        
        // Should be representable as AxiomError
        let axiomError = AxiomError.capability(CapabilityContext(
            capability: "test",
            reason: .notAvailable,
            metadata: [:]
        ))
        
        // This will fail until we add capability case to AxiomError
        switch axiomError {
        case .capability(let context):
            XCTAssertEqual(context.capability, "test")
            XCTAssertEqual(context.reason, .notAvailable)
        default:
            XCTFail("Should have capability case")
        }
    }
    
    // Test deep linking errors consolidation
    func testDeepLinkingErrorsConsolidated() throws {
        // Current: Separate DeepLinkingError
        let deepLinkError = DeepLinkingError.invalidURL("bad-url")
        
        // Should be: Part of navigation context
        let axiomError = AxiomError.navigation(NavigationContext(
            operation: "deepLink",
            route: "bad-url",
            reason: .invalidURL,
            metadata: ["url": "bad-url"]
        ))
        
        // Verify comprehensive navigation context
        switch axiomError {
        case .navigation(let context):
            XCTAssertEqual(context.operation, "deepLink")
            XCTAssertTrue(context.metadata.contains { $0.key == "url" })
        default:
            XCTFail("Should use navigation case for deep linking")
        }
    }
    
    // Test navigation flow errors consolidation
    func testNavigationFlowErrorsConsolidated() throws {
        // Current: Multiple navigation error types
        let flowError = NavigationFlowError.invalidFlow("test-flow")
        let patternError = NavigationPatternError.patternNotFound("modal")
        
        // Should be: Unified navigation context with detailed reason
        let flowAxiomError = AxiomError.navigation(NavigationContext(
            operation: "flow",
            route: "test-flow",
            reason: .invalidFlow,
            metadata: ["flowId": "test-flow"]
        ))
        
        let patternAxiomError = AxiomError.navigation(NavigationContext(
            operation: "pattern",
            route: "modal",
            reason: .patternNotFound,
            metadata: ["pattern": "modal"]
        ))
        
        // Both should use navigation case with rich context
        XCTAssertNotNil(flowAxiomError)
        XCTAssertNotNil(patternAxiomError)
    }
    
    // Test validation errors have consistent structure
    func testValidationErrorsConsistency() throws {
        // Current: Two different ValidationError types
        // 1. ValidationError in MutationDSL
        let dslValidation = ValidationError.validationFailed("email", "Invalid format")
        
        // 2. AxiomValidationError in ErrorHandling
        let axiomValidation = AxiomValidationError.formatError("email", "user@example.com")
        
        // Should be: Single validation approach
        let unifiedError = AxiomError.validation(ValidationContext(
            field: "email",
            value: "bad-email",
            rule: .format("email"),
            message: "Invalid email format"
        ))
        
        // Verify rich validation context
        switch unifiedError {
        case .validation(let context):
            XCTAssertEqual(context.field, "email")
            XCTAssertNotNil(context.value)
            XCTAssertNotNil(context.rule)
        default:
            XCTFail("Should be validation error")
        }
    }
    
    // Test client errors consolidation
    func testClientErrorsUnification() throws {
        // Current: ClientError vs AxiomClientError
        let clientError = ClientError.actionFailed("test")
        let axiomClientError = AxiomClientError.invalidAction("test")
        
        // Should be: Single client error approach
        let unifiedError = AxiomError.client(ClientContext(
            operation: "action",
            clientId: "test-client",
            reason: .actionFailed("test"),
            metadata: ["action": "test"]
        ))
        
        XCTAssertNotNil(unifiedError)
    }
    
    // Test error context preservation
    func testErrorContextPreservation() throws {
        // Ensure no loss of information during consolidation
        let originalError = NavigationCancellationError.cancellationInProgress
        
        // Converted to AxiomError should preserve all context
        let axiomError = AxiomError.navigation(NavigationContext(
            operation: "cancellation",
            route: nil,
            reason: .cancellationInProgress,
            metadata: ["state": "inProgress"]
        ))
        
        // Verify context is comprehensive
        if case .navigation(let context) = axiomError {
            XCTAssertEqual(context.operation, "cancellation")
            XCTAssertEqual(context.reason, .cancellationInProgress)
            XCTAssertFalse(context.metadata.isEmpty)
        }
    }
    
    // Test error recovery strategy mapping
    func testErrorRecoveryStrategyMapping() throws {
        // Each error type should map to appropriate recovery
        let errors: [(AxiomError, ErrorRecoveryStrategy)] = [
            (.capability(CapabilityContext(capability: "test", reason: .notAvailable)), .silent),
            (.navigation(NavigationContext(operation: "route", reason: .notFound)), .userPrompt("Route not found")),
            (.client(ClientContext(operation: "timeout", reason: .timeout(5.0))), .retry(attempts: 3)),
            (.validation(ValidationContext(field: "email", rule: .required)), .userPrompt("Please correct input"))
        ]
        
        for (error, expectedStrategy) in errors {
            // This will fail until we implement proper recovery mapping
            let actualStrategy = error.recoveryStrategy
            XCTAssertEqual(actualStrategy, expectedStrategy)
        }
    }
    
    // Test comprehensive error categorization
    func testComprehensiveErrorCategorization() throws {
        // All 12+ error types should map to AxiomError cases
        let errorMappings: [String: AxiomError.Category] = [
            "CapabilityError": .capability,
            "ClientError": .client,
            "NavigationError": .navigation,
            "DeepLinkingError": .navigation,
            "ValidationError": .validation,
            "NavigationCancellationError": .navigation,
            "NavigationFlowError": .navigation,
            "NavigationMiddlewareError": .navigation,
            "NavigationPatternError": .navigation,
            "RouteValidationError": .navigation,
            "NavigationGraphError": .navigation,
            "PersistenceError": .persistence
        ]
        
        // Verify all error types have a home in AxiomError
        XCTAssertEqual(errorMappings.count, 12)
        XCTAssertEqual(Set(errorMappings.values).count, 4) // capability, client, navigation, validation
    }
}

// Helper types for testing (will be implemented in GREEN phase)
struct CapabilityContext: Equatable {
    let capability: String
    let reason: CapabilityReason
    let metadata: [String: String]
    
    enum CapabilityReason: Equatable {
        case notAvailable
        case insufficientPermissions
        case configurationError
    }
}

struct NavigationContext: Equatable {
    let operation: String
    let route: String?
    let reason: NavigationReason
    let metadata: [String: String]
    
    enum NavigationReason: Equatable {
        case invalidURL
        case notFound
        case invalidFlow
        case patternNotFound
        case cancellationInProgress
        case guardFailed
    }
}

struct ClientContext: Equatable {
    let operation: String
    let clientId: String
    let reason: ClientReason
    let metadata: [String: String]
    
    enum ClientReason: Equatable {
        case actionFailed(String)
        case timeout(TimeInterval)
        case notInitialized
    }
}

struct ValidationContext: Equatable {
    let field: String
    let value: Any?
    let rule: ValidationRule
    let message: String
    
    enum ValidationRule: Equatable {
        case required
        case format(String)
        case range(String)
        case custom(String)
    }
    
    static func == (lhs: ValidationContext, rhs: ValidationContext) -> Bool {
        lhs.field == rhs.field && 
        lhs.rule == rhs.rule && 
        lhs.message == rhs.message
    }
}

// Extension to AxiomError for testing (will be implemented)
extension AxiomError {
    enum Category {
        case capability
        case client
        case navigation
        case validation
        case persistence
        case context
    }
}