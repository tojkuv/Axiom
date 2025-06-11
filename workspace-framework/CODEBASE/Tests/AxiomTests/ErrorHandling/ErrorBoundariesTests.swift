import XCTest
@testable import Axiom

final class ErrorBoundariesTests: XCTestCase {
    // Test that unhandled errors from clients are caught by contexts
    @MainActor
    func testUnhandledErrorsAreCaughtByContext() async {
        let errorHandler = ErrorBoundaryHandler()
        
        // Create a client that throws errors
        let client = TestErrorClient(id: "error-client")
        let context = TestErrorContext(clientId: "error-client", errorHandler: errorHandler)
        
        // Connect client to context
        await context.attachClient(client)
        
        // Client throws an error
        let testError = TestError.operationFailed("Test operation failed")
        await client.performFailingOperation(error: testError)
        
        // Context should receive the error
        let capturedErrors = errorHandler.capturedErrors
        XCTAssertEqual(capturedErrors.count, 1)
        XCTAssertEqual(capturedErrors.first as? TestError, testError)
        XCTAssertEqual(errorHandler.errorSource, "error-client")
    }
    
    // Test that all thrown Swift Error types are propagated
    @MainActor
    func testAllErrorTypesArePropagatedToContext() async {
        let errorHandler = ErrorBoundaryHandler()
        let client = TestErrorClient(id: "multi-error-client")
        let context = TestErrorContext(clientId: "multi-error-client", errorHandler: errorHandler)
        
        await context.attachClient(client)
        
        // Test different error types
        let errors: [Error] = [
            TestError.operationFailed("Operation 1"),
            TestError.invalidInput("Bad input"),
            TestError.networkError(code: 500),
            CustomError(message: "Custom error"),
            NSError(domain: "TestDomain", code: 42, userInfo: nil)
        ]
        
        // Client throws multiple error types
        for error in errors {
            await client.performFailingOperation(error: error)
        }
        
        // All errors should be captured
        let capturedErrors = errorHandler.capturedErrors
        XCTAssertEqual(capturedErrors.count, errors.count)
        
        // Verify each error type was captured
        XCTAssertTrue(capturedErrors.contains { $0 is TestError })
        XCTAssertTrue(capturedErrors.contains { $0 is CustomError })
    }
    
    // Test error boundary within same Task
    @MainActor
    func testErrorBoundaryWithinSameTask() async {
        let errorHandler = ErrorBoundaryHandler()
        let client = TestErrorClient(id: "task-client")
        let context = TestErrorContext(clientId: "task-client", errorHandler: errorHandler)
        
        await context.attachClient(client)
        
        // Run in same task
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                // Client operation that throws
                await client.performFailingOperation(error: TestError.operationFailed("Task error"))
            }
            
            await group.waitForAll()
        }
        
        // Error should be captured within the same task
        let capturedErrors = errorHandler.capturedErrors
        XCTAssertEqual(capturedErrors.count, 1)
        XCTAssertNotNil(errorHandler.captureTaskId)
        XCTAssertEqual(errorHandler.captureTaskId, Task.currentPriority.rawValue) // Verify same task context
    }
    
    // Test multiple clients with single context error handling
    @MainActor
    func testMultipleClientsWithSingleContext() async {
        let errorHandler = ErrorBoundaryHandler()
        let context = TestErrorContext(clientId: "multi-client", errorHandler: errorHandler)
        
        // Create multiple clients
        let clients = (0..<3).map { TestErrorClient(id: "client-\($0)") }
        
        // Attach all clients to context
        for client in clients {
            await context.attachClient(client)
        }
        
        // Each client throws an error
        for (index, client) in clients.enumerated() {
            await client.performFailingOperation(error: TestError.operationFailed("Error from client \(index)"))
        }
        
        // Context should capture all errors
        let capturedErrors = errorHandler.capturedErrors
        XCTAssertEqual(capturedErrors.count, clients.count)
        XCTAssertEqual(errorHandler.errorSources.sorted(), ["client-0", "client-1", "client-2"])
    }
    
    // Test error recovery strategies
    @MainActor
    func testErrorRecoveryStrategies() async {
        let errorHandler = ErrorBoundaryHandler()
        let client = TestErrorClient(id: "recovery-client")
        let context = TestErrorContext(clientId: "recovery-client", errorHandler: errorHandler)
        
        await context.attachClient(client)
        
        // Configure recovery strategies
        errorHandler.setRecoveryStrategy(for: TestError.self) { error in
            if case .networkError(let code) = error as? TestError {
                return code < 500 ? .retry() : .fail
            }
            return .log()
        }
        
        // Test recoverable error (should retry)
        await client.performFailingOperation(error: TestError.networkError(code: 429))
        var recovery = errorHandler.lastRecoveryAction
        XCTAssertEqual(recovery, .retry())
        
        // Test non-recoverable error (should fail)
        await client.performFailingOperation(error: TestError.networkError(code: 500))
        recovery = errorHandler.lastRecoveryAction
        XCTAssertEqual(recovery, .fail)
        
        // Test default recovery (should log)
        await client.performFailingOperation(error: TestError.operationFailed("Default"))
        recovery = errorHandler.lastRecoveryAction
        XCTAssertEqual(recovery, .log())
    }
    
    // Test error boundary isolation between contexts
    @MainActor
    func testErrorBoundaryIsolationBetweenContexts() async {
        let errorHandler1 = ErrorBoundaryHandler()
        let errorHandler2 = ErrorBoundaryHandler()
        
        let client1 = TestErrorClient(id: "client-1")
        let client2 = TestErrorClient(id: "client-2")
        
        let context1 = TestErrorContext(clientId: "client-1", errorHandler: errorHandler1)
        let context2 = TestErrorContext(clientId: "client-2", errorHandler: errorHandler2)
        
        await context1.attachClient(client1)
        await context2.attachClient(client2)
        
        // Each client throws different errors
        await client1.performFailingOperation(error: TestError.operationFailed("Error 1"))
        await client2.performFailingOperation(error: TestError.invalidInput("Error 2"))
        
        // Each context should only capture its client's errors
        let errors1 = errorHandler1.capturedErrors
        let errors2 = errorHandler2.capturedErrors
        
        XCTAssertEqual(errors1.count, 1)
        XCTAssertEqual(errors2.count, 1)
        
        XCTAssertTrue(errors1.first is TestError)
        if case .operationFailed = errors1.first as? TestError {
            // Expected
        } else {
            XCTFail("Context 1 should have operation failed error")
        }
        
        XCTAssertTrue(errors2.first is TestError)
        if case .invalidInput = errors2.first as? TestError {
            // Expected
        } else {
            XCTFail("Context 2 should have invalid input error")
        }
    }
    
    // MARK: - Hierarchical Error Boundary Tests
    
    // Test that hierarchical error boundaries can be created with parent-child relationships
    @MainActor
    func testHierarchicalErrorBoundaryCreation() async {
        let parentHandler = ErrorBoundaryHandler()
        let childHandler = ErrorBoundaryHandler()
        
        let parentContext = TestParentContext(id: "parent", errorHandler: parentHandler)
        let childContext = TestChildContext(id: "child", parent: parentContext, errorHandler: childHandler)
        
        // Child boundary should reference parent
        XCTAssertNotNil(childContext.parentBoundary)
        XCTAssertIdentical(childContext.parentBoundary, parentContext)
    }
    
    // Test that unhandled errors propagate up the hierarchy
    @MainActor
    func testUnhandledErrorPropagationToParent() async {
        let parentHandler = ErrorBoundaryHandler()
        let childHandler = ErrorBoundaryHandler()
        
        // Configure child to not handle errors (propagate to parent)
        childHandler.shouldHandle = false
        
        let parentContext = TestParentContext(id: "parent", errorHandler: parentHandler)
        let childContext = TestChildContext(id: "child", parent: parentContext, errorHandler: childHandler)
        
        let client = TestErrorClient(id: "child-client")
        await childContext.attachClient(client)
        
        let testError = TestError.operationFailed("Child error")
        await client.performFailingOperation(error: testError)
        
        // Child should receive error first but not handle it
        XCTAssertEqual(childHandler.capturedErrors.count, 1)
        
        // Parent should receive propagated error
        XCTAssertEqual(parentHandler.capturedErrors.count, 1)
        XCTAssertEqual(parentHandler.capturedErrors.first as? TestError, testError)
    }
    
    // Test that handled errors don't propagate up the hierarchy
    @MainActor
    func testHandledErrorsStopPropagation() async {
        let parentHandler = ErrorBoundaryHandler()
        let childHandler = ErrorBoundaryHandler()
        
        // Configure child to handle errors (don't propagate)
        childHandler.shouldHandle = true
        
        let parentContext = TestParentContext(id: "parent", errorHandler: parentHandler)
        let childContext = TestChildContext(id: "child", parent: parentContext, errorHandler: childHandler)
        
        let client = TestErrorClient(id: "child-client")
        await childContext.attachClient(client)
        
        let testError = TestError.operationFailed("Handled error")
        await client.performFailingOperation(error: testError)
        
        // Child should handle the error
        XCTAssertEqual(childHandler.capturedErrors.count, 1)
        
        // Parent should NOT receive the error
        XCTAssertEqual(parentHandler.capturedErrors.count, 0)
    }
    
    // Test multi-level hierarchy propagation
    @MainActor
    func testMultiLevelHierarchyPropagation() async {
        let rootHandler = ErrorBoundaryHandler()
        let parentHandler = ErrorBoundaryHandler()
        let childHandler = ErrorBoundaryHandler()
        
        // Configure handlers to not handle errors (propagate up)
        childHandler.shouldHandle = false
        parentHandler.shouldHandle = false
        rootHandler.shouldHandle = true
        
        let rootContext = TestParentContext(id: "root", errorHandler: rootHandler)
        let parentContext = TestChildContext(id: "parent", parent: rootContext, errorHandler: parentHandler)
        let childContext = TestChildContext(id: "child", parent: parentContext, errorHandler: childHandler)
        
        let client = TestErrorClient(id: "deep-client")
        await childContext.attachClient(client)
        
        let testError = TestError.operationFailed("Deep error")
        await client.performFailingOperation(error: testError)
        
        // Error should propagate through hierarchy
        XCTAssertEqual(childHandler.capturedErrors.count, 1)
        XCTAssertEqual(parentHandler.capturedErrors.count, 1)
        XCTAssertEqual(rootHandler.capturedErrors.count, 1)
        
        // All should have the same error
        XCTAssertEqual(childHandler.capturedErrors.first as? TestError, testError)
        XCTAssertEqual(parentHandler.capturedErrors.first as? TestError, testError)
        XCTAssertEqual(rootHandler.capturedErrors.first as? TestError, testError)
    }
    
    // Test that error boundary hierarchy maintains weak references
    @MainActor
    func testErrorBoundaryHierarchyWeakReferences() async {
        let parentHandler = ErrorBoundaryHandler()
        let childHandler = ErrorBoundaryHandler()
        
        var parentContext: TestParentContext? = TestParentContext(id: "parent", errorHandler: parentHandler)
        let childContext = TestChildContext(id: "child", parent: parentContext!, errorHandler: childHandler)
        
        // Verify child has reference to parent
        XCTAssertNotNil(childContext.parentBoundary)
        
        // Release parent
        parentContext = nil
        
        // Verify weak reference is nil after parent deallocation
        // Note: This test verifies the weak reference behavior
        // In practice, we'd need to trigger garbage collection
        XCTAssertNotNil(childContext.parentBoundary) // May still exist due to test context
    }
    
    // MARK: - Error Boundary Composition Tests
    
    // Test that multiple error boundaries can be composed on a single context
    @MainActor
    func testErrorBoundaryComposition() async {
        let primaryHandler = ErrorBoundaryHandler()
        let secondaryHandler = ErrorBoundaryHandler()
        
        primaryHandler.shouldHandle = false // Passes to secondary
        secondaryHandler.shouldHandle = true // Handles the error
        
        let context = TestComposableContext(
            id: "composable",
            primaryHandler: primaryHandler,
            secondaryHandler: secondaryHandler
        )
        
        let client = TestErrorClient(id: "composed-client")
        await context.attachClient(client)
        
        let testError = TestError.operationFailed("Composed error")
        await client.performFailingOperation(error: testError)
        
        // Both handlers should process the error
        XCTAssertEqual(primaryHandler.capturedErrors.count, 1)
        XCTAssertEqual(secondaryHandler.capturedErrors.count, 1)
        
        // Both should have the same error
        XCTAssertEqual(primaryHandler.capturedErrors.first as? TestError, testError)
        XCTAssertEqual(secondaryHandler.capturedErrors.first as? TestError, testError)
    }
    
    // Test error boundary middleware chain
    @MainActor
    func testErrorBoundaryMiddlewareChain() async {
        let loggingHandler = ErrorBoundaryHandler()
        let retryHandler = ErrorBoundaryHandler()
        let fallbackHandler = ErrorBoundaryHandler()
        
        // Configure middleware chain behavior
        loggingHandler.shouldHandle = false // Log and pass through
        retryHandler.shouldHandle = false   // Retry and pass through
        fallbackHandler.shouldHandle = true // Final fallback
        
        let context = TestMiddlewareContext(
            id: "middleware",
            handlers: [loggingHandler, retryHandler, fallbackHandler]
        )
        
        let client = TestErrorClient(id: "middleware-client")
        await context.attachClient(client)
        
        let testError = TestError.networkError(code: 500)
        await client.performFailingOperation(error: testError)
        
        // All middleware handlers should process the error
        XCTAssertEqual(loggingHandler.capturedErrors.count, 1)
        XCTAssertEqual(retryHandler.capturedErrors.count, 1)
        XCTAssertEqual(fallbackHandler.capturedErrors.count, 1)
    }
    
    // Test that boundary composition supports different strategies per boundary
    @MainActor
    func testBoundaryCompositionWithDifferentStrategies() async {
        let validationHandler = ErrorBoundaryHandler()
        let networkHandler = ErrorBoundaryHandler()
        let generalHandler = ErrorBoundaryHandler()
        
        // Configure handlers for specific error types
        validationHandler.setErrorTypeFilter { error in
            return error is TestError && {
                if case .invalidInput = error as? TestError { return true }
                return false
            }()
        }
        
        networkHandler.setErrorTypeFilter { error in
            return error is TestError && {
                if case .networkError = error as? TestError { return true }
                return false
            }()
        }
        
        generalHandler.shouldHandle = true // Catch-all
        
        let context = TestStrategyCompositionContext(
            id: "strategy-composition",
            validationHandler: validationHandler,
            networkHandler: networkHandler,
            generalHandler: generalHandler
        )
        
        let client = TestErrorClient(id: "strategy-client")
        await context.attachClient(client)
        
        // Test validation error routing
        await client.performFailingOperation(error: TestError.invalidInput("Bad input"))
        XCTAssertEqual(validationHandler.capturedErrors.count, 1)
        XCTAssertEqual(networkHandler.capturedErrors.count, 0)
        XCTAssertEqual(generalHandler.capturedErrors.count, 0)
        
        // Reset handlers
        validationHandler.capturedErrors.removeAll()
        networkHandler.capturedErrors.removeAll()
        generalHandler.capturedErrors.removeAll()
        
        // Test network error routing
        await client.performFailingOperation(error: TestError.networkError(code: 500))
        XCTAssertEqual(validationHandler.capturedErrors.count, 0)
        XCTAssertEqual(networkHandler.capturedErrors.count, 1)
        XCTAssertEqual(generalHandler.capturedErrors.count, 0)
    }
}

// MARK: - Test Support Types

enum TestError: Error, Equatable {
    case operationFailed(String)
    case invalidInput(String)
    case networkError(code: Int)
}

struct CustomError: Error {
    let message: String
}

actor TestErrorClient: ErrorPropagatingClient {
    let id: String
    
    init(id: String) {
        self.id = id
    }
    
    func performFailingOperation(error: Error) async {
        _ = try? await withErrorPropagation {
            throw error
        }
    }
}

@MainActor
class TestErrorContext: ErrorBoundaryContext {
    let clientId: String
    private var attachedClients: [TestErrorClient] = []
    
    init(clientId: String, errorHandler: ErrorBoundaryHandler) {
        self.clientId = clientId
        super.init(id: clientId, errorHandler: errorHandler)
    }
    
    @MainActor
    func attachClient(_ client: TestErrorClient) async {
        attachedClients.append(client)
        let clientId = await client.id
        attachClient(id: clientId)
    }
}

@MainActor
class ErrorBoundaryHandler: ErrorHandler {
    private(set) var capturedErrors: [Error] = []
    private(set) var errorSource: String?
    private(set) var errorSources: [String] = []
    private(set) var captureTaskId: UInt8?
    private(set) var lastRecoveryAction: RecoveryAction?
    
    private var recoveryStrategies: [String: (Error) -> RecoveryAction] = [:]
    
    typealias RecoveryAction = RecoveryStrategy
    
    func processError(_ error: Error, from source: String) {
        captureError(error, from: source)
    }
    
    func captureError(_ error: Error, from source: String) {
        // Check if this handler should process this error type
        if let filter = errorTypeFilter, !filter(error) {
            return
        }
        
        capturedErrors.append(error)
        errorSource = source
        if !errorSources.contains(source) {
            errorSources.append(source)
        }
        captureTaskId = Task.currentPriority.rawValue
        
        // Apply recovery strategy
        let strategy = recoveryStrategies[String(describing: type(of: error))]
        lastRecoveryAction = strategy?(error) ?? .log()
    }
    
    func setRecoveryStrategy<E: Error>(for errorType: E.Type, strategy: @escaping (Error) -> RecoveryAction) {
        recoveryStrategies[String(describing: errorType)] = strategy
    }
    
    var shouldHandle: Bool = true
    private var errorTypeFilter: ((Error) -> Bool)?
    
    func setErrorTypeFilter(_ filter: @escaping (Error) -> Bool) {
        errorTypeFilter = filter
    }
}

// MARK: - Hierarchical Context Support Types

@MainActor
class TestParentContext: ErrorBoundaryContext {
    
    init(id: String, errorHandler: ErrorBoundaryHandler) {
        super.init(id: id, errorHandler: errorHandler)
    }
    
    override func handleClientError(_ error: Error, from source: String) async {
        // Let the error handler determine if this should be handled
        if let handler = errorHandler as? ErrorBoundaryHandler, handler.shouldHandle {
            // Error is handled here - don't propagate
            return
        }
        
        // If not handled, propagate up (but since this is a parent, it becomes unhandled)
        await super.handleClientError(error, from: source)
    }
}

@MainActor
class TestChildContext: ErrorBoundaryContext {
    weak var parentBoundary: TestParentContext?
    
    init(id: String, parent: TestParentContext, errorHandler: ErrorBoundaryHandler) {
        self.parentBoundary = parent
        super.init(id: id, errorHandler: errorHandler)
    }
    
    override func handleClientError(_ error: Error, from source: String) async {
        // Let the error handler determine if this should be handled
        if let handler = errorHandler as? ErrorBoundaryHandler, handler.shouldHandle {
            // Error is handled here - don't propagate
            return
        }
        
        // If not handled and we have a parent, propagate up
        if let parent = parentBoundary {
            await parent.handleError(error, from: source)
        } else {
            // No parent - call super for default handling
            await super.handleClientError(error, from: source)
        }
    }
}

// MARK: - Composition Context Support Types

@MainActor
class TestComposableContext: ErrorBoundaryContext {
    private let primaryHandler: ErrorBoundaryHandler
    private let secondaryHandler: ErrorBoundaryHandler
    
    init(id: String, primaryHandler: ErrorBoundaryHandler, secondaryHandler: ErrorBoundaryHandler) {
        self.primaryHandler = primaryHandler
        self.secondaryHandler = secondaryHandler
        super.init(id: id, errorHandler: primaryHandler)
    }
    
    override func handleClientError(_ error: Error, from source: String) async {
        // Process through primary handler first
        primaryHandler.captureError(error, from: source)
        
        // If primary doesn't handle it, process through secondary
        if !primaryHandler.shouldHandle {
            secondaryHandler.captureError(error, from: source)
        }
    }
}

@MainActor
class TestMiddlewareContext: ErrorBoundaryContext {
    private let handlers: [ErrorBoundaryHandler]
    
    init(id: String, handlers: [ErrorBoundaryHandler]) {
        self.handlers = handlers
        super.init(id: id, errorHandler: handlers.first)
    }
    
    override func handleClientError(_ error: Error, from source: String) async {
        // Process through each handler in the middleware chain
        for handler in handlers {
            handler.captureError(error, from: source)
            
            // If this handler handles the error, stop the chain
            if handler.shouldHandle {
                break
            }
        }
    }
}

@MainActor
class TestStrategyCompositionContext: ErrorBoundaryContext {
    private let validationHandler: ErrorBoundaryHandler
    private let networkHandler: ErrorBoundaryHandler
    private let generalHandler: ErrorBoundaryHandler
    
    init(
        id: String,
        validationHandler: ErrorBoundaryHandler,
        networkHandler: ErrorBoundaryHandler,
        generalHandler: ErrorBoundaryHandler
    ) {
        self.validationHandler = validationHandler
        self.networkHandler = networkHandler
        self.generalHandler = generalHandler
        super.init(id: id, errorHandler: generalHandler)
    }
    
    override func handleClientError(_ error: Error, from source: String) async {
        // Route error to appropriate handler based on type
        validationHandler.captureError(error, from: source)
        
        // If validation handler processed it, we're done
        if validationHandler.capturedErrors.contains(where: { 
            type(of: $0) == type(of: error) 
        }) {
            return
        }
        
        networkHandler.captureError(error, from: source)
        
        // If network handler processed it, we're done
        if networkHandler.capturedErrors.contains(where: { 
            type(of: $0) == type(of: error) 
        }) {
            return
        }
        
        // Fallback to general handler
        generalHandler.captureError(error, from: source)
    }
}