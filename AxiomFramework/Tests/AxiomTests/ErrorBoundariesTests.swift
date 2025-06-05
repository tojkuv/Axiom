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
}