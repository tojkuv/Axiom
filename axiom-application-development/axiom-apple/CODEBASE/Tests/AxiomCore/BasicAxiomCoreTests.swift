import XCTest
import AxiomTesting
@testable import AxiomCore
@testable import AxiomArchitecture

/// Basic tests for AxiomCore module functionality that can run in MVP
final class BasicAxiomCoreTests: XCTestCase {
    
    // MARK: - Basic Error Framework Tests
    
    func testAxiomErrorCreation() throws {
        let contextError = AxiomError.contextError(.lifecycleError("Test error"))
        let clientError = AxiomError.clientError(.timeout(duration: 1.0))
        let networkError = AxiomError.networkError(.connectionFailed("Test"))
        
        XCTAssertNotNil(contextError, "Context error should be created")
        XCTAssertNotNil(clientError, "Client error should be created")
        XCTAssertNotNil(networkError, "Network error should be created")
    }
    
    func testErrorRecoveryStrategies() throws {
        let retryStrategy = ErrorRecoveryStrategy.retry(attempts: 3)
        let propagateStrategy = ErrorRecoveryStrategy.propagate
        let silentStrategy = ErrorRecoveryStrategy.silent
        let userPromptStrategy = ErrorRecoveryStrategy.userPrompt(message: "Test")
        
        XCTAssertNotNil(retryStrategy, "Retry strategy should be created")
        XCTAssertNotNil(propagateStrategy, "Propagate strategy should be created")
        XCTAssertNotNil(silentStrategy, "Silent strategy should be created")
        XCTAssertNotNil(userPromptStrategy, "User prompt strategy should be created")
    }
    
    // MARK: - Basic Context Tests
    
    @MainActor
    func testBasicContextCreation() async throws {
        let context = AxiomObservableContext()
        XCTAssertNotNil(context, "Context should be created")
        XCTAssertFalse(context.isActive, "Context should start inactive")
    }
    
    @MainActor
    func testContextLifecycle() async throws {
        let context = AxiomObservableContext()
        
        try await context.activate()
        XCTAssertTrue(context.isActive, "Context should be active after activation")
        
        await context.deactivate()
        XCTAssertFalse(context.isActive, "Context should be inactive after deactivation")
    }
    
    // MARK: - Basic Error Boundary Tests
    
    @MainActor
    func testErrorBoundaryCreation() async throws {
        let boundary = AxiomErrorBoundary()
        XCTAssertNotNil(boundary, "Error boundary should be created")
        XCTAssertFalse(boundary.hasActiveError, "New boundary should not have active error")
    }
    
    @MainActor
    func testErrorBoundaryHandleError() async throws {
        let boundary = AxiomErrorBoundary()
        let error = AxiomError.contextError(.lifecycleError("Test error"))
        
        await boundary.handle(error)
        
        XCTAssertTrue(boundary.hasActiveError, "Boundary should have active error after handling")
        XCTAssertNotNil(boundary.lastError, "Boundary should store last error")
    }
    
    // MARK: - Basic State Protocol Tests
    
    func testBasicStateProtocol() throws {
        // Test that the state protocol exists and can be used
        struct TestState: AxiomState {
            let value: String = "test"
        }
        
        let state = TestState()
        XCTAssertNotNil(state, "State should be created")
        XCTAssertEqual(state.value, "test", "State should have correct value")
    }
}