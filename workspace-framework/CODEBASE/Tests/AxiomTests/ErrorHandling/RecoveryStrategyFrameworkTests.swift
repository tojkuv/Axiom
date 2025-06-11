import XCTest
@testable import Axiom

/// Tests for comprehensive recovery strategy framework (REQUIREMENTS-W-06-003)
class RecoveryStrategyFrameworkTests: XCTestCase {
    
    // MARK: - Enhanced Recovery Strategy Tests
    
    func testEnhancedRetryWithConfigurableBackoff() async throws {
        // Test configurable backoff strategies
        let exponentialStrategy = EnhancedRecoveryStrategy.retry(
            maxAttempts: 3,
            backoff: .exponential(initial: 0.1, multiplier: 2.0, maxDelay: 5.0)
        )
        
        let linearStrategy = EnhancedRecoveryStrategy.retry(
            maxAttempts: 3, 
            backoff: .linear(initial: 0.1, increment: 0.1)
        )
        
        let constantStrategy = EnhancedRecoveryStrategy.retry(
            maxAttempts: 3,
            backoff: .constant(0.2)
        )
        
        var attemptTimes: [TimeInterval] = []
        let testOperation: () async throws -> String = {
            attemptTimes.append(CFAbsoluteTimeGetCurrent())
            if attemptTimes.count < 3 {
                throw TestRecoveryError.transientFailure
            }
            return "Success"
        }
        
        // Test exponential backoff timing
        let result = try await exponentialStrategy.execute(testOperation)
        XCTAssertEqual(result, "Success")
        XCTAssertEqual(attemptTimes.count, 3)
        
        // Verify exponential delays: ~0.1s, ~0.2s
        if attemptTimes.count >= 3 {
            let delay1 = attemptTimes[1] - attemptTimes[0]
            let delay2 = attemptTimes[2] - attemptTimes[1] 
            XCTAssertGreaterThan(delay1, 0.08)
            XCTAssertLessThan(delay1, 0.15)
            XCTAssertGreaterThan(delay2, 0.18)
            XCTAssertLessThan(delay2, 0.25)
        }
    }
    
    func testFallbackWithMultipleOptions() async throws {
        // Test chained fallback operations
        var primaryCalled = false
        var fallback1Called = false
        var fallback2Called = false
        
        let fallbackChain = EnhancedRecoveryStrategy.fallbackChain([
            { error in
                fallback1Called = true
                throw TestRecoveryError.fallbackFailure // First fallback fails
            },
            { error in
                fallback2Called = true
                return "Fallback success" // Second fallback succeeds
            }
        ])
        
        let testOperation: () async throws -> String = {
            primaryCalled = true
            throw TestRecoveryError.primaryFailure
        }
        
        let result = try await fallbackChain.execute(testOperation)
        
        XCTAssertTrue(primaryCalled)
        XCTAssertTrue(fallback1Called)
        XCTAssertTrue(fallback2Called)
        XCTAssertEqual(result, "Fallback success")
    }
    
    func testCategoryBasedRecoverySelection() async throws {
        // Test automatic strategy selection based on error category
        let networkError = AxiomError.networkError(.invalidURL(component: "host", value: "invalid"))
        let validationError = AxiomError.validationError(.invalidInput("email", "required"))
        let authError = AxiomError.clientError(.invalidAction("unauthorized"))
        
        let networkStrategy = RecoveryStrategySelector.defaultStrategy(for: networkError)
        let validationStrategy = RecoveryStrategySelector.defaultStrategy(for: validationError)
        let authStrategy = RecoveryStrategySelector.defaultStrategy(for: authError)
        
        // Network errors should use retry strategy
        XCTAssertTrue(networkStrategy.isRetryStrategy)
        if case .retry(let attempts, _) = networkStrategy {
            XCTAssertEqual(attempts, 3)
        }
        
        // Validation errors should use user prompt
        XCTAssertTrue(validationStrategy.isUserPromptStrategy)
        
        // Auth errors should use user prompt
        XCTAssertTrue(authStrategy.isUserPromptStrategy)
    }
    
    func testRecoveryMetricsCollection() async throws {
        // Test recovery metrics and monitoring
        let metricsCollector = RecoveryMetricsCollector()
        let strategy = EnhancedRecoveryStrategy.retry(
            maxAttempts: 3,
            backoff: .exponential(),
            metrics: metricsCollector
        )
        
        var attemptCount = 0
        let testOperation: () async throws -> String = {
            attemptCount += 1
            if attemptCount < 3 {
                throw TestRecoveryError.transientFailure
            }
            return "Success"
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await strategy.execute(testOperation)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        XCTAssertEqual(result, "Success")
        
        // Verify metrics collection
        let metrics = metricsCollector.getMetrics(for: "testOperation")
        XCTAssertEqual(metrics.totalAttempts, 3)
        XCTAssertEqual(metrics.successCount, 1)
        XCTAssertEqual(metrics.failureCount, 0)
        XCTAssertGreaterThan(metrics.totalLatency, 0.1) // Should include backoff time
        XCTAssertLessThan(metrics.totalLatency, endTime - startTime + 0.1)
    }
    
    func testRecoveryMiddleware() async throws {
        // Test recovery middleware hooks
        var preRecoveryHookCalled = false
        var postRecoveryHookCalled = false
        var recoveryAttempted = false
        
        let middleware = RecoveryMiddleware()
        middleware.addPreRecoveryHook { error, attempt in
            preRecoveryHookCalled = true
            XCTAssertGreaterThan(attempt, 0)
        }
        
        middleware.addPostRecoveryHook { error, attempt, success in
            postRecoveryHookCalled = true
            if attempt == 2 {
                XCTAssertTrue(success)
            }
        }
        
        let strategy = EnhancedRecoveryStrategy.retry(
            maxAttempts: 3,
            backoff: .constant(0.01),
            middleware: middleware
        )
        
        var attemptCount = 0
        let testOperation: () async throws -> String = {
            attemptCount += 1
            recoveryAttempted = true
            if attemptCount < 3 {
                throw TestRecoveryError.transientFailure
            }
            return "Success"
        }
        
        let result = try await strategy.execute(testOperation)
        
        XCTAssertEqual(result, "Success")
        XCTAssertTrue(preRecoveryHookCalled)
        XCTAssertTrue(postRecoveryHookCalled)
        XCTAssertTrue(recoveryAttempted)
    }
    
    func testTimeoutIntegrationWithRecovery() async throws {
        // Test timeout management with recovery strategies
        let timeoutStrategy = EnhancedRecoveryStrategy.retryWithTimeout(
            maxAttempts: 3,
            operationTimeout: 0.5,
            backoff: .constant(0.1)
        )
        
        var attemptCount = 0
        let testOperation: () async throws -> String = {
            attemptCount += 1
            if attemptCount == 1 {
                // First attempt times out
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
            return "Success after timeout"
        }
        
        do {
            let result = try await timeoutStrategy.execute(testOperation)
            // Should succeed on second attempt (after first times out)
            XCTAssertEqual(result, "Success after timeout")
            XCTAssertEqual(attemptCount, 2)
        } catch {
            // If all attempts time out, verify proper error handling
            XCTAssertTrue(error is RecoveryTimeoutError)
        }
    }
    
    func testUserInteractionRecovery() async throws {
        // Test user prompt and interaction recovery
        let userPromptStrategy = EnhancedRecoveryStrategy.userPrompt(
            message: "Operation failed. Would you like to retry?",
            options: ["Retry", "Use Cached Data", "Cancel"],
            handler: { selectedOption in
                switch selectedOption {
                case "Retry":
                    return .retry(maxAttempts: 1, backoff: .none)
                case "Use Cached Data":
                    return .fallback { _ in "Cached data" }
                case "Cancel":
                    return .fail
                default:
                    return .fail
                }
            }
        )
        
        // Mock user interaction
        UserInteractionMock.setNextResponse("Use Cached Data")
        
        let testOperation: () async throws -> String = {
            throw TestRecoveryError.requiresUserDecision
        }
        
        let result = try await userPromptStrategy.execute(testOperation)
        XCTAssertEqual(result, "Cached data")
    }
    
    func testRecoveryWithErrorBoundaryIntegration() async throws {
        // Test integration with error boundary system
        let boundary = EnhancedErrorBoundary(
            id: "test-recovery-boundary",
            recoveryStrategy: .retry(maxAttempts: 2, backoff: .exponential())
        )
        
        var attemptCount = 0
        let client = MockRecoveryClient { 
            attemptCount += 1
            if attemptCount == 1 {
                throw TestRecoveryError.transientFailure
            }
            return "Boundary recovery success"
        }
        
        await boundary.attachClient(client)
        let result = try await client.performOperation()
        
        XCTAssertEqual(result, "Boundary recovery success")
        XCTAssertEqual(attemptCount, 2)
    }
    
    func testRecoveryContextPreservation() async throws {
        // Test context preservation through recovery attempts
        let context = RecoveryContext(
            operationId: "test-operation",
            userId: "user123",
            sessionId: "session456"
        )
        
        let strategy = EnhancedRecoveryStrategy.retry(
            maxAttempts: 3,
            backoff: .linear(initial: 0.01, increment: 0.01),
            preserveContext: true
        )
        
        var recoveredContext: RecoveryContext?
        let testOperation: () async throws -> String = {
            recoveredContext = RecoveryContext.current
            if recoveredContext?.operationId != "test-operation" {
                throw TestRecoveryError.contextLost
            }
            return "Context preserved"
        }
        
        let result = try await strategy.executeWithContext(context, operation: testOperation)
        
        XCTAssertEqual(result, "Context preserved")
        XCTAssertNotNil(recoveredContext)
        XCTAssertEqual(recoveredContext?.operationId, "test-operation")
        XCTAssertEqual(recoveredContext?.userId, "user123")
    }
    
    func testRecoveryPerformanceMetrics() async throws {
        // Test recovery performance impact measurement
        let metricsCollector = RecoveryMetricsCollector()
        let strategy = EnhancedRecoveryStrategy.retry(
            maxAttempts: 5,
            backoff: .exponential(initial: 0.01, multiplier: 1.5, maxDelay: 0.1),
            metrics: metricsCollector
        )
        
        // Run multiple operations to gather metrics
        for i in 0..<10 {
            var attemptCount = 0
            let testOperation: () async throws -> String = {
                attemptCount += 1
                if attemptCount <= i % 3 + 1 {  // Vary success rates
                    throw TestRecoveryError.transientFailure
                }
                return "Success \(i)"
            }
            
            _ = try await strategy.execute(testOperation)
        }
        
        let aggregateMetrics = metricsCollector.getAggregateMetrics()
        
        // Verify metrics collection
        XCTAssertEqual(aggregateMetrics.totalOperations, 10)
        XCTAssertGreaterThan(aggregateMetrics.averageAttempts, 1.0)
        XCTAssertLessThan(aggregateMetrics.averageAttempts, 4.0)
        XCTAssertEqual(aggregateMetrics.successRate, 1.0) // All should eventually succeed
        XCTAssertGreaterThan(aggregateMetrics.averageLatency, 0.0)
    }
}

// MARK: - Test Support Types

enum TestRecoveryError: Error {
    case transientFailure
    case primaryFailure
    case fallbackFailure
    case requiresUserDecision
    case contextLost
}

class MockRecoveryClient {
    private let operation: () async throws -> String
    
    init(operation: @escaping () async throws -> String) {
        self.operation = operation
    }
    
    func performOperation() async throws -> String {
        return try await operation()
    }
}