import XCTest
import AxiomTesting
import SwiftUI
@testable import AxiomCore
@testable import AxiomArchitecture

/// Comprehensive tests for error boundary functionality and containment
/// 
/// Consolidates: ErrorBoundariesTests, ErrorBoundaryTests
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class ErrorBoundaryTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Basic Error Boundary Tests
    
    @MainActor
    func testErrorBoundaryCreation() async throws {
        let boundary = ErrorBoundary()
        XCTAssertNotNil(boundary, "Error boundary should initialize")
        XCTAssertEqual(boundary.strategy, .isolate, "Default strategy should be isolate")
        XCTAssertFalse(boundary.hasActiveError, "New boundary should not have active error")
    }
    
    @MainActor
    func testErrorBoundaryWithDifferentStrategies() async throws {
        let isolateBoundary = ErrorBoundary(strategy: .isolate)
        XCTAssertEqual(isolateBoundary.strategy, .isolate)
        
        let propagateBoundary = ErrorBoundary(strategy: .propagate)
        XCTAssertEqual(propagateBoundary.strategy, .propagate)
        
        let retryBoundary = ErrorBoundary(strategy: .retry(attempts: 3))
        XCTAssertEqual(retryBoundary.strategy, .retry(attempts: 3))
        
        let userPromptBoundary = ErrorBoundary(strategy: .userPrompt(message: "Please try again"))
        XCTAssertEqual(userPromptBoundary.strategy, .userPrompt(message: "Please try again"))
    }
    
    // MARK: - Error Capture and Isolation Tests
    
    @MainActor
    func testErrorBoundaryCapturesUnhandledErrors() async throws {
        try await testEnvironment.runTest { env in
            let boundary = ErrorBoundary(strategy: .isolate)
            var capturedError: Error?
            
            boundary.onError = { error in
                capturedError = error
            }
            
            let context = TestBoundaryContext(errorBoundary: boundary)
            
            // Simulate unhandled error
            let testError = AxiomError.contextError(.lifecycleError("Test error"))
            await context.simulateError(testError)
            
            XCTAssertNotNil(capturedError, "Error boundary should capture unhandled error")
            XCTAssertTrue(capturedError is AxiomError, "Captured error should be AxiomError")
            XCTAssertTrue(boundary.hasActiveError, "Boundary should have active error")
        }
    }
    
    @MainActor
    func testErrorBoundaryIsolation() async throws {
        try await testEnvironment.runTest { env in
            let parentBoundary = ErrorBoundary(strategy: .isolate)
            let childBoundary = ErrorBoundary(strategy: .isolate)
            childBoundary.parentBoundary = parentBoundary
            
            var parentErrors: [Error] = []
            var childErrors: [Error] = []
            
            parentBoundary.onError = { error in
                parentErrors.append(error)
            }
            
            childBoundary.onError = { error in
                childErrors.append(error)
            }
            
            let childContext = TestBoundaryContext(errorBoundary: childBoundary)
            
            // Child error should be isolated
            let childError = AxiomError.clientError(.invalidAction("Child error"))
            await childContext.simulateError(childError)
            
            XCTAssertEqual(childErrors.count, 1, "Child boundary should capture child error")
            XCTAssertEqual(parentErrors.count, 0, "Parent boundary should not receive isolated error")
            XCTAssertTrue(childBoundary.hasActiveError, "Child boundary should have active error")
            XCTAssertFalse(parentBoundary.hasActiveError, "Parent boundary should not have active error")
        }
    }
    
    @MainActor
    func testErrorBoundaryPropagation() async throws {
        try await testEnvironment.runTest { env in
            let parentBoundary = ErrorBoundary(strategy: .isolate)
            let childBoundary = ErrorBoundary(strategy: .propagate)
            childBoundary.parentBoundary = parentBoundary
            
            var parentErrors: [Error] = []
            var childErrors: [Error] = []
            
            parentBoundary.onError = { error in
                parentErrors.append(error)
            }
            
            childBoundary.onError = { error in
                childErrors.append(error)
            }
            
            let childContext = TestBoundaryContext(errorBoundary: childBoundary)
            
            // Child error should propagate to parent
            let childError = AxiomError.navigationError(.routeNotFound("/test"))
            await childContext.simulateError(childError)
            
            XCTAssertEqual(childErrors.count, 1, "Child boundary should see error first")
            XCTAssertEqual(parentErrors.count, 1, "Parent boundary should receive propagated error")
            XCTAssertTrue(parentBoundary.hasActiveError, "Parent boundary should have active error")
        }
    }
    
    // MARK: - Error Recovery Strategy Tests
    
    @MainActor
    func testErrorBoundaryRetryStrategy() async throws {
        try await testEnvironment.runTest { env in
            let boundary = ErrorBoundary(strategy: .retry(attempts: 3))
            var attemptCount = 0
            var finalResult: String?
            
            boundary.onRecovery = { result in
                finalResult = result as? String
            }
            
            let context = TestBoundaryContext(errorBoundary: boundary)
            
            // Set up operation that succeeds on third attempt
            context.operation = { [unowned context] in
                attemptCount += 1
                if attemptCount < 3 {
                    throw AxiomError.networkError(.connectionFailed("Attempt \(attemptCount)"))
                }
                return "Success after \(attemptCount) attempts"
            }
            
            await context.executeOperation()
            
            XCTAssertEqual(attemptCount, 3, "Should retry 3 times total")
            XCTAssertEqual(finalResult, "Success after 3 attempts", "Should succeed after retries")
            XCTAssertFalse(boundary.hasActiveError, "Boundary should not have active error after recovery")
        }
    }
    
    @MainActor
    func testErrorBoundaryRetryExhaustion() async throws {
        try await testEnvironment.runTest { env in
            let boundary = ErrorBoundary(strategy: .retry(attempts: 2))
            var attemptCount = 0
            var finalError: Error?
            
            boundary.onError = { error in
                finalError = error
            }
            
            let context = TestBoundaryContext(errorBoundary: boundary)
            
            // Set up operation that always fails
            context.operation = { [unowned context] in
                attemptCount += 1
                throw AxiomError.networkError(.connectionFailed("Attempt \(attemptCount)"))
            }
            
            await context.executeOperation()
            
            XCTAssertEqual(attemptCount, 2, "Should attempt twice before giving up")
            XCTAssertNotNil(finalError, "Should have final error after retry exhaustion")
            XCTAssertTrue(boundary.hasActiveError, "Boundary should have active error after retry exhaustion")
        }
    }
    
    @MainActor
    func testErrorBoundaryUserPromptStrategy() async throws {
        try await testEnvironment.runTest { env in
            let boundary = ErrorBoundary(strategy: .userPrompt(message: "Please try again"))
            var promptMessage: String?
            var userResponse: UserPromptResponse?
            
            boundary.onUserPrompt = { message, completion in
                promptMessage = message
                // Simulate user choosing to retry
                completion(.retry)
            }
            
            boundary.onUserResponse = { response in
                userResponse = response
            }
            
            let context = TestBoundaryContext(errorBoundary: boundary)
            
            let error = AxiomError.validationError(.invalidInput("email", "Invalid format"))
            await context.simulateError(error)
            
            XCTAssertEqual(promptMessage, "Please try again", "Should show correct prompt message")
            XCTAssertEqual(userResponse, .retry, "Should capture user response")
        }
    }
    
    // MARK: - Hierarchical Error Boundary Tests
    
    @MainActor
    func testNestedErrorBoundaries() async throws {
        try await testEnvironment.runTest { env in
            // Create hierarchy: Root -> Middle -> Leaf
            let rootBoundary = ErrorBoundary(strategy: .isolate)
            let middleBoundary = ErrorBoundary(strategy: .propagate)
            let leafBoundary = ErrorBoundary(strategy: .retry(attempts: 1))
            
            middleBoundary.parentBoundary = rootBoundary
            leafBoundary.parentBoundary = middleBoundary
            
            var rootErrors: [Error] = []
            var middleErrors: [Error] = []
            var leafErrors: [Error] = []
            
            rootBoundary.onError = { rootErrors.append($0) }
            middleBoundary.onError = { middleErrors.append($0) }
            leafBoundary.onError = { leafErrors.append($0) }
            
            let leafContext = TestBoundaryContext(errorBoundary: leafBoundary)
            
            // Leaf error should retry once, then propagate through middle to root
            leafContext.operation = {
                throw AxiomError.clientError(.timeout(duration: 1.0))
            }
            
            await leafContext.executeOperation()
            
            XCTAssertEqual(leafErrors.count, 1, "Leaf should see error first")
            XCTAssertEqual(middleErrors.count, 1, "Middle should receive propagated error")
            XCTAssertEqual(rootErrors.count, 1, "Root should receive error from middle")
            XCTAssertTrue(rootBoundary.hasActiveError, "Root should have active error")
        }
    }
    
    @MainActor
    func testErrorBoundaryContextInheritance() async throws {
        try await testEnvironment.runTest { env in
            let parentBoundary = ErrorBoundary(strategy: .isolate)
            parentBoundary.context = ErrorBoundaryContext(
                component: "ParentComponent",
                userId: "user123",
                sessionId: "session456"
            )
            
            let childBoundary = ErrorBoundary(strategy: .propagate)
            childBoundary.parentBoundary = parentBoundary
            
            // Child should inherit parent context
            XCTAssertEqual(childBoundary.inheritedContext?.userId, "user123")
            XCTAssertEqual(childBoundary.inheritedContext?.sessionId, "session456")
            
            // Child can override specific context values
            childBoundary.context = ErrorBoundaryContext(
                component: "ChildComponent",
                userId: "user123", // Inherited
                sessionId: "session456", // Inherited
                additionalData: ["childData": "value"]
            )
            
            let childContext = TestBoundaryContext(errorBoundary: childBoundary)
            let error = AxiomError.contextError(.lifecycleError("Test"))
            
            var capturedError: AxiomError?
            childBoundary.onError = { error in
                capturedError = error as? AxiomError
            }
            
            await childContext.simulateError(error)
            
            XCTAssertNotNil(capturedError?.boundaryContext)
            XCTAssertEqual(capturedError?.boundaryContext?.component, "ChildComponent")
            XCTAssertEqual(capturedError?.boundaryContext?.userId, "user123")
        }
    }
    
    // MARK: - Error Boundary Performance Tests
    
    func testErrorBoundaryPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let boundary = ErrorBoundary(strategy: .isolate)
                
                // Test rapid error handling
                for i in 0..<1000 {
                    let error = AxiomError.clientError(.timeout(duration: Double(i % 10)))
                    await boundary.handleError(error, from: "test-component-\(i)")
                }
                
                // Test boundary tree traversal
                let rootBoundary = ErrorBoundary(strategy: .isolate)
                var currentBoundary = rootBoundary
                
                // Create deep hierarchy
                for i in 0..<100 {
                    let childBoundary = ErrorBoundary(strategy: .propagate)
                    childBoundary.parentBoundary = currentBoundary
                    currentBoundary = childBoundary
                }
                
                // Error should propagate up the entire chain
                let leafError = AxiomError.networkError(.connectionFailed("Deep error"))
                await currentBoundary.handleError(leafError, from: "leaf-component")
            },
            maxDuration: .milliseconds(200),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testErrorBoundaryMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let rootBoundary = ErrorBoundary(strategy: .isolate)
            
            // Simulate boundary lifecycle with many child boundaries
            for i in 0..<50 {
                let childBoundary = ErrorBoundary(strategy: .retry(attempts: 2))
                childBoundary.parentBoundary = rootBoundary
                childBoundary.context = ErrorBoundaryContext(
                    component: "TestComponent\(i)",
                    userId: "user\(i)",
                    sessionId: "session\(i)"
                )
                
                let context = TestBoundaryContext(errorBoundary: childBoundary)
                let error = AxiomError.clientError(.invalidAction("Error \(i)"))
                await context.simulateError(error)
                
                // Periodically clear error states
                if i % 10 == 0 {
                    await childBoundary.clearError()
                }
            }
            
            await rootBoundary.clearAllErrors()
        }
    }
    
    // MARK: - Error Boundary State Management Tests
    
    @MainActor
    func testErrorBoundaryStateTransitions() async throws {
        let boundary = ErrorBoundary(strategy: .isolate)
        
        // Initial state
        XCTAssertEqual(boundary.state, .idle, "Boundary should start in idle state")
        XCTAssertFalse(boundary.hasActiveError, "Should not have active error")
        
        // Error state
        let error = AxiomError.contextError(.lifecycleError("Test error"))
        await boundary.handleError(error, from: "test-component")
        
        XCTAssertEqual(boundary.state, .error, "Boundary should be in error state")
        XCTAssertTrue(boundary.hasActiveError, "Should have active error")
        
        // Recovery state
        await boundary.beginRecovery()
        XCTAssertEqual(boundary.state, .recovering, "Boundary should be in recovering state")
        
        // Back to idle
        await boundary.clearError()
        XCTAssertEqual(boundary.state, .idle, "Boundary should return to idle state")
        XCTAssertFalse(boundary.hasActiveError, "Should not have active error after clear")
    }
    
    @MainActor
    func testErrorBoundaryErrorHistory() async throws {
        let boundary = ErrorBoundary(strategy: .isolate)
        boundary.keepErrorHistory = true
        
        // Generate multiple errors
        let errors = [
            AxiomError.contextError(.lifecycleError("Error 1")),
            AxiomError.clientError(.invalidAction("Error 2")),
            AxiomError.networkError(.connectionFailed("Error 3"))
        ]
        
        for (index, error) in errors.enumerated() {
            await boundary.handleError(error, from: "component-\(index)")
        }
        
        let errorHistory = await boundary.getErrorHistory()
        XCTAssertEqual(errorHistory.count, 3, "Should maintain error history")
        
        // Verify chronological order
        for (index, historicalError) in errorHistory.enumerated() {
            XCTAssertEqual(historicalError.error, errors[index], "Errors should be in chronological order")
            XCTAssertNotNil(historicalError.timestamp, "Each error should have timestamp")
            XCTAssertEqual(historicalError.component, "component-\(index)", "Component should be recorded")
        }
    }
}

// MARK: - Test Helper Classes

@MainActor
private class TestBoundaryContext: ObservableObject {
    let errorBoundary: ErrorBoundary
    var operation: (() async throws -> Any)?
    
    init(errorBoundary: ErrorBoundary) {
        self.errorBoundary = errorBoundary
    }
    
    func simulateError(_ error: Error) async {
        await errorBoundary.handleError(error, from: "test-context")
    }
    
    func executeOperation() async {
        guard let operation = operation else { return }
        
        do {
            let result = try await operation()
            await errorBoundary.handleRecovery(result)
        } catch {
            await errorBoundary.handleError(error, from: "test-context")
        }
    }
}

private struct ErrorBoundaryContext {
    let component: String
    let userId: String?
    let sessionId: String?
    let additionalData: [String: Any]
    
    init(component: String, userId: String? = nil, sessionId: String? = nil, additionalData: [String: Any] = [:]) {
        self.component = component
        self.userId = userId
        self.sessionId = sessionId
        self.additionalData = additionalData
    }
}

private enum UserPromptResponse {
    case retry
    case cancel
    case ignore
}