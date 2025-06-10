import XCTest
@testable import Axiom

/// Tests for unified AxiomError hierarchy
final class AxiomErrorTests: XCTestCase {
    
    // MARK: - Error Type Tests
    
    func testAxiomErrorHierarchy() {
        // Test that all error types can be represented
        let contextError = AxiomError.contextError(.lifecycleError("Failed to appear"))
        let clientError = AxiomError.clientError(.invalidAction("Unknown action"))
        let navigationError = AxiomError.navigationError(.invalidRoute("/unknown"))
        let persistenceError = AxiomError.persistenceError(.saveFailed("disk full"))
        let validationError = AxiomError.validationError(.invalidInput("email", "invalid format"))
        
        // All errors should have localized descriptions
        XCTAssertFalse(contextError.localizedDescription.isEmpty)
        XCTAssertFalse(clientError.localizedDescription.isEmpty)
        XCTAssertFalse(navigationError.localizedDescription.isEmpty)
        XCTAssertFalse(persistenceError.localizedDescription.isEmpty)
        XCTAssertFalse(validationError.localizedDescription.isEmpty)
    }
    
    func testErrorRecoveryStrategies() {
        // Test that errors have appropriate recovery strategies
        let contextError = AxiomError.contextError(.lifecycleError("Failed"))
        XCTAssertEqual(contextError.recoveryStrategy, .propagate)
        
        let persistenceError = AxiomError.persistenceError(.saveFailed("network"))
        XCTAssertEqual(persistenceError.recoveryStrategy, .retry(attempts: 3))
        
        let validationError = AxiomError.validationError(.invalidInput("field", "reason"))
        XCTAssertEqual(validationError.recoveryStrategy, .userPrompt(message: "Please correct the input"))
    }
    
    func testErrorCodability() throws {
        // Test that errors can be encoded/decoded
        let originalError = AxiomError.clientError(.timeout(duration: 5.0))
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalError)
        
        let decoder = JSONDecoder()
        let decodedError = try decoder.decode(AxiomError.self, from: data)
        
        XCTAssertEqual(originalError, decodedError)
    }
    
    // MARK: - Error Boundary Tests
    
    @MainActor
    func testErrorBoundaryMacroGeneration() async throws {
        // Test that @ErrorBoundary generates proper error handling
        @ErrorBoundary
        class TestContext: ObservableContext {
            func riskyOperation() async throws {
                throw AxiomError.contextError(.lifecycleError("Test error"))
            }
        }
        
        let context = TestContext()
        
        // Error should be caught by boundary
        var caughtError: Error?
        context.errorBoundary.onError = { error in
            caughtError = error
        }
        
        try await context.riskyOperation()
        
        XCTAssertNotNil(caughtError)
        XCTAssert(caughtError is AxiomError)
    }
    
    @MainActor
    func testErrorRecoveryStrategies() async throws {
        // Test different recovery strategies
        @ErrorBoundary(strategy: .retry(attempts: 2))
        class RetryContext: ObservableContext {
            var attemptCount = 0
            
            func failingOperation() async throws {
                attemptCount += 1
                if attemptCount < 3 {
                    throw AxiomError.clientError(.timeout(duration: 1.0))
                }
            }
        }
        
        let context = RetryContext()
        
        // Should succeed after retries
        try await context.failingOperation()
        XCTAssertEqual(context.attemptCount, 3)
    }
    
    @MainActor
    func testErrorPropagation() async throws {
        // Test error propagation through boundaries
        class ParentContext: ObservableContext {
            var receivedError: Error?
            
            override func handleBoundaryError(_ error: Error) async {
                receivedError = error
            }
        }
        
        @ErrorBoundary(strategy: .propagate)
        class ChildContext: ObservableContext {
            func throwError() async throws {
                throw AxiomError.navigationError(.routeNotFound("/test"))
            }
        }
        
        let parent = ParentContext()
        let child = ChildContext()
        child.parentContext = parent
        
        try await child.throwError()
        
        XCTAssertNotNil(parent.receivedError)
        XCTAssert(parent.receivedError is AxiomError)
    }
}