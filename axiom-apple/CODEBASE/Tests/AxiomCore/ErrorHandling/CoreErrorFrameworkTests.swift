import XCTest
import AxiomTesting
import SwiftUI
@testable import AxiomCore
@testable import AxiomArchitecture

/// Comprehensive tests for core Axiom error framework functionality
/// 
/// Consolidates: AxiomErrorTests, ErrorHandlingFrameworkTests, UnifiedErrorSystemTests
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class CoreErrorFrameworkTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Error Type Tests
    
    func testAxiomErrorHierarchy() async throws {
        // Test that all error types can be represented
        let contextError = AxiomError.contextError(.lifecycleError("Failed to appear"))
        let clientError = AxiomError.clientError(.invalidAction("Unknown action"))
        let navigationError = AxiomError.navigationError(.invalidRoute("/unknown"))
        let persistenceError = AxiomError.persistenceError(.saveFailed("disk full"))
        let validationError = AxiomError.validationError(.invalidInput("email", "invalid format"))
        
        // All errors should have localized descriptions
        XCTAssertFalse(contextError.localizedDescription.isEmpty, "Context error should have description")
        XCTAssertFalse(clientError.localizedDescription.isEmpty, "Client error should have description")
        XCTAssertFalse(navigationError.localizedDescription.isEmpty, "Navigation error should have description")
        XCTAssertFalse(persistenceError.localizedDescription.isEmpty, "Persistence error should have description")
        XCTAssertFalse(validationError.localizedDescription.isEmpty, "Validation error should have description")
        
        // Test error equality
        let anotherContextError = AxiomError.contextError(.lifecycleError("Failed to appear"))
        XCTAssertEqual(contextError, anotherContextError, "Equal errors should be equal")
        
        let differentContextError = AxiomError.contextError(.lifecycleError("Different message"))
        XCTAssertNotEqual(contextError, differentContextError, "Different errors should not be equal")
    }
    
    func testErrorRecoveryStrategies() async throws {
        // Test that errors have appropriate recovery strategies
        let contextError = AxiomError.contextError(.lifecycleError("Failed"))
        XCTAssertEqual(contextError.recoveryStrategy, .propagate, "Context errors should propagate")
        
        let persistenceError = AxiomError.persistenceError(.saveFailed("network"))
        XCTAssertEqual(persistenceError.recoveryStrategy, .retry(attempts: 3), "Persistence errors should retry")
        
        let validationError = AxiomError.validationError(.invalidInput("field", "reason"))
        XCTAssertEqual(validationError.recoveryStrategy, .userPrompt(message: "Please correct the input"), "Validation errors should prompt user")
        
        // Test network errors have exponential backoff
        let networkError = AxiomError.networkError(.connectionFailed("timeout"))
        if case .retryWithBackoff(let attempts, let initialDelay, let multiplier) = networkError.recoveryStrategy {
            XCTAssertEqual(attempts, 3, "Network errors should retry 3 times")
            XCTAssertEqual(initialDelay, 1.0, "Initial delay should be 1 second")
            XCTAssertEqual(multiplier, 2.0, "Backoff multiplier should be 2")
        } else {
            XCTFail("Network errors should use retry with backoff strategy")
        }
    }
    
    func testErrorCodability() throws {
        // Test that errors can be encoded/decoded for persistence and network transport
        let originalError = AxiomError.clientError(.timeout(duration: 5.0))
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalError)
        
        let decoder = JSONDecoder()
        let decodedError = try decoder.decode(AxiomError.self, from: data)
        
        XCTAssertEqual(originalError, decodedError, "Encoded/decoded error should match original")
        
        // Test complex error with nested information
        let complexError = AxiomError.contextError(.stateCorruption(details: ["key1": "value1", "key2": "value2"]))
        let complexData = try encoder.encode(complexError)
        let decodedComplexError = try decoder.decode(AxiomError.self, from: complexData)
        
        XCTAssertEqual(complexError, decodedComplexError, "Complex error should encode/decode correctly")
    }
    
    // MARK: - Error Framework Integration Tests
    
    func testUnifiedErrorSystemIntegration() async throws {
        try await testEnvironment.runTest { env in
            let errorHandler = TestErrorHandler()
            
            // Test error system captures errors from different layers
            let context = try await env.createContext(
                ErrorTestContext.self,
                id: "unified-error-context"
            ) {
                ErrorTestContext(errorHandler: errorHandler)
            }
            
            let client = try await env.createClient(
                ErrorTestClient.self,
                id: "unified-error-client"
            ) {
                ErrorTestClient(id: "unified-error-client")
            }
            
            await context.attachClient(client)
            
            // Trigger errors from different layers
            let contextError = AxiomError.contextError(.lifecycleError("Context layer error"))
            let clientError = AxiomError.clientError(.invalidAction("Client layer error"))
            let persistenceError = AxiomError.persistenceError(.saveFailed("Persistence layer error"))
            
            await context.handleError(contextError)
            await client.handleError(clientError)
            
            // All errors should be captured by unified system
            let capturedErrors = await errorHandler.getCapturedErrors()
            XCTAssertGreaterThanOrEqual(capturedErrors.count, 2, "Should capture errors from multiple layers")
            
            // Verify error metadata is preserved
            for error in capturedErrors {
                XCTAssertNotNil(error.timestamp, "Error should have timestamp")
                XCTAssertNotNil(error.context, "Error should have context information")
                XCTAssertNotNil(error.stackTrace, "Error should have stack trace")
            }
        }
    }
    
    func testErrorFrameworkPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let errorHandler = TestErrorHandler()
                
                // Test rapid error processing
                for i in 0..<1000 {
                    let error = AxiomError.clientError(.timeout(duration: Double(i % 10)))
                    await errorHandler.handleError(error)
                }
                
                // Test error categorization performance
                let errors = await errorHandler.getCapturedErrors()
                let categorizedErrors = ErrorCategorizer.categorize(errors)
                
                XCTAssertEqual(categorizedErrors.count, errors.count, "All errors should be categorized")
            },
            maxDuration: .milliseconds(500),
            maxMemoryGrowth: 2 * 1024 * 1024 // 2MB
        )
    }
    
    // MARK: - Error Context and Metadata Tests
    
    func testErrorContextPreservation() async throws {
        let originalContext = ErrorContext(
            component: "TestComponent",
            operation: "testOperation",
            userID: "user123",
            sessionID: "session456",
            additionalData: ["key": "value"]
        )
        
        // Create error with context
        let error = AxiomError.contextError(.lifecycleError("Test error"))
        let errorWithContext = error.withContext(originalContext)
        
        XCTAssertEqual(errorWithContext.context?.component, "TestComponent")
        XCTAssertEqual(errorWithContext.context?.operation, "testOperation")
        XCTAssertEqual(errorWithContext.context?.userID, "user123")
        XCTAssertEqual(errorWithContext.context?.sessionID, "session456")
        XCTAssertEqual(errorWithContext.context?.additionalData["key"] as? String, "value")
    }
    
    func testErrorStackTraceCapture() async throws {
        func levelThree() throws {
            throw AxiomError.clientError(.invalidAction("Level 3 error"))
        }
        
        func levelTwo() throws {
            try levelThree()
        }
        
        func levelOne() throws {
            try levelTwo()
        }
        
        do {
            try levelOne()
            XCTFail("Should have thrown error")
        } catch let error as AxiomError {
            let stackTrace = error.stackTrace
            XCTAssertNotNil(stackTrace, "Error should capture stack trace")
            XCTAssertTrue(stackTrace!.contains("levelOne"), "Stack trace should contain calling function")
            XCTAssertTrue(stackTrace!.contains("levelTwo"), "Stack trace should contain intermediate function")
            XCTAssertTrue(stackTrace!.contains("levelThree"), "Stack trace should contain origin function")
        }
    }
    
    // MARK: - Error Classification Tests
    
    func testErrorSeverityClassification() async throws {
        let criticalError = AxiomError.systemError(.memoryExhausted)
        XCTAssertEqual(criticalError.severity, .critical, "System memory errors should be critical")
        
        let highError = AxiomError.persistenceError(.dataCorrupted("corrupted"))
        XCTAssertEqual(highError.severity, .high, "Data corruption should be high severity")
        
        let mediumError = AxiomError.networkError(.connectionFailed("timeout"))
        XCTAssertEqual(mediumError.severity, .medium, "Network errors should be medium severity")
        
        let lowError = AxiomError.validationError(.invalidInput("field", "format"))
        XCTAssertEqual(lowError.severity, .low, "Validation errors should be low severity")
        
        let infoError = AxiomError.userError(.cancelled)
        XCTAssertEqual(infoError.severity, .info, "User cancellation should be info level")
    }
    
    func testErrorRecoverabilityClassification() async throws {
        let recoverableError = AxiomError.networkError(.connectionFailed("timeout"))
        XCTAssertTrue(recoverableError.isRecoverable, "Network timeouts should be recoverable")
        
        let nonRecoverableError = AxiomError.systemError(.memoryExhausted)
        XCTAssertFalse(nonRecoverableError.isRecoverable, "Memory exhaustion should not be recoverable")
        
        let userRecoverableError = AxiomError.validationError(.invalidInput("email", "format"))
        XCTAssertTrue(userRecoverableError.isUserRecoverable, "Validation errors should be user recoverable")
        
        let systemRecoverableError = AxiomError.persistenceError(.saveFailed("disk full"))
        XCTAssertTrue(systemRecoverableError.isSystemRecoverable, "Disk full errors should be system recoverable")
    }
    
    // MARK: - Memory Management Tests
    
    func testErrorFrameworkMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let errorHandler = TestErrorHandler()
            
            // Simulate error handling lifecycle
            for i in 0..<100 {
                let error = AxiomError.contextError(.lifecycleError("Error \(i)"))
                let contextualError = error.withContext(ErrorContext(
                    component: "TestComponent\(i)",
                    operation: "operation\(i)",
                    userID: "user\(i)",
                    sessionID: "session\(i)",
                    additionalData: ["iteration": i]
                ))
                
                await errorHandler.handleError(contextualError)
                
                // Periodically clean up old errors
                if i % 20 == 0 {
                    await errorHandler.cleanup()
                }
            }
            
            await errorHandler.cleanup()
        }
    }
    
    // MARK: - Error Boundary Integration Tests
    
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
        
        XCTAssertNotNil(caughtError, "Error boundary should catch error")
        XCTAssert(caughtError is AxiomError, "Caught error should be AxiomError")
    }
    
    @MainActor
    func testErrorBoundaryRecoveryStrategies() async throws {
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
        XCTAssertEqual(context.attemptCount, 3, "Should retry twice before success")
    }
    
    @MainActor
    func testErrorBoundaryPropagation() async throws {
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
        
        XCTAssertNotNil(parent.receivedError, "Parent should receive propagated error")
        XCTAssert(parent.receivedError is AxiomError, "Propagated error should be AxiomError")
    }
}

// MARK: - Test Helper Classes

private class TestErrorHandler {
    private var capturedErrors: [AxiomError] = []
    private let lock = NSLock()
    
    func handleError(_ error: AxiomError) async {
        lock.withLock {
            capturedErrors.append(error)
        }
    }
    
    func getCapturedErrors() async -> [AxiomError] {
        return lock.withLock {
            return capturedErrors
        }
    }
    
    func cleanup() async {
        lock.withLock {
            capturedErrors.removeAll()
        }
    }
}

private class ErrorTestContext: ObservableContext {
    let errorHandler: TestErrorHandler
    
    init(errorHandler: TestErrorHandler) {
        self.errorHandler = errorHandler
        super.init()
    }
    
    func handleError(_ error: AxiomError) async {
        await errorHandler.handleError(error)
    }
}

private class ErrorTestClient: Client {
    let id: String
    
    init(id: String) {
        self.id = id
        super.init()
    }
    
    func handleError(_ error: AxiomError) async {
        // Handle error through client error boundary
    }
}

private struct ErrorContext {
    let component: String
    let operation: String
    let userID: String?
    let sessionID: String?
    let additionalData: [String: Any]
    
    init(component: String, operation: String, userID: String? = nil, sessionID: String? = nil, additionalData: [String: Any] = [:]) {
        self.component = component
        self.operation = operation
        self.userID = userID
        self.sessionID = sessionID
        self.additionalData = additionalData
    }
}

private struct ErrorCategorizer {
    static func categorize(_ errors: [AxiomError]) -> [String: [AxiomError]] {
        var categorized: [String: [AxiomError]] = [:]
        
        for error in errors {
            let category = error.category
            if categorized[category] == nil {
                categorized[category] = []
            }
            categorized[category]?.append(error)
        }
        
        return categorized
    }
}