import XCTest
@testable import Axiom

/// Tests for error boundary functionality
final class ErrorBoundaryTests: XCTestCase {
    
    // MARK: - Basic Error Boundary Tests
    
    @MainActor
    func testErrorBoundaryCreation() async {
        let boundary = ErrorBoundary()
        XCTAssertNotNil(boundary)
        
        // Test with specific strategy
        let retryBoundary = ErrorBoundary(strategy: .retry(attempts: 3))
        XCTAssertNotNil(retryBoundary)
    }
    
    @MainActor
    func testErrorBoundaryInContext() async {
        class TestContext: ObservableContext {}
        
        let context = TestContext()
        XCTAssertNotNil(context.errorBoundary)
        
        // Should return same instance
        let boundary1 = context.errorBoundary
        let boundary2 = context.errorBoundary
        XCTAssertTrue(boundary1 === boundary2)
    }
    
    @MainActor
    func testErrorPropagationToParent() async {
        class ParentContext: ObservableContext {
            var receivedError: Error?
            
            override func handleBoundaryError(_ error: Error) async {
                receivedError = error
            }
        }
        
        class ChildContext: ObservableContext {}
        
        let parent = ParentContext()
        let child = ChildContext()
        child.parentContext = parent
        child.errorBoundary.setParent(parent)
        
        let testError = AxiomError.contextError(.lifecycleError("Test"))
        await child.errorBoundary.handle(testError)
        
        XCTAssertNotNil(parent.receivedError)
        XCTAssertEqual(parent.receivedError as? AxiomError, testError)
    }
    
    @MainActor
    func testRetryStrategy() async {
        let boundary = ErrorBoundary(strategy: .retry(attempts: 3))
        
        var errorHandlerCallCount = 0
        boundary.onError = { _ in
            errorHandlerCallCount += 1
        }
        
        let testError = AxiomError.clientError(.timeout(duration: 1.0))
        
        // First 3 attempts should be handled
        for _ in 0..<3 {
            await boundary.handle(testError)
        }
        
        XCTAssertEqual(errorHandlerCallCount, 3)
    }
    
    @MainActor
    func testSilentStrategy() async {
        let boundary = ErrorBoundary(strategy: .silent)
        
        var errorLogged = false
        boundary.onError = { _ in
            errorLogged = true
        }
        
        let testError = AxiomError.validationError(.missingRequired("field"))
        await boundary.handle(testError)
        
        XCTAssertTrue(errorLogged)
    }
    
    @MainActor
    func testStrategyConfiguration() async {
        let boundary = ErrorBoundary(strategy: .propagate)
        
        // Change strategy
        boundary.configure(strategy: .retry(attempts: 5))
        
        // Test new strategy is applied
        var retryCount = 0
        boundary.onError = { _ in
            retryCount += 1
        }
        
        let testError = AxiomError.persistenceError(.saveFailed("test"))
        for _ in 0..<5 {
            await boundary.handle(testError)
        }
        
        XCTAssertEqual(retryCount, 5)
    }
    
    // MARK: - Integration Tests
    
    @MainActor
    func testErrorBoundaryChain() async {
        class RootContext: ObservableContext {
            var errors: [Error] = []
            
            override func handleBoundaryError(_ error: Error) async {
                errors.append(error)
            }
        }
        
        class MiddleContext: ObservableContext {
            override func handleBoundaryError(_ error: Error) async {
                // Transform error
                let wrappedError = AxiomError.contextError(.childContextError(error.localizedDescription))
                await super.handleBoundaryError(wrappedError)
            }
        }
        
        class LeafContext: ObservableContext {}
        
        let root = RootContext()
        let middle = MiddleContext()
        let leaf = LeafContext()
        
        middle.parentContext = root
        middle.errorBoundary.setParent(root)
        
        leaf.parentContext = middle
        leaf.errorBoundary.setParent(middle)
        
        let originalError = AxiomError.navigationError(.routeNotFound("/test"))
        await leaf.errorBoundary.handle(originalError)
        
        XCTAssertEqual(root.errors.count, 1)
        XCTAssertTrue(root.errors[0] is AxiomError)
        
        if case .contextError(.childContextError(let message)) = root.errors[0] as? AxiomError {
            XCTAssertTrue(message.contains("Route not found"))
        } else {
            XCTFail("Expected wrapped context error")
        }
    }
}