import XCTest
@testable import Axiom
import AxiomTesting

/// Tests for enhanced error recovery mechanisms
final class ErrorRecoveryTests: XCTestCase {
    
    // MARK: - Retry Tests
    
    func testAutomaticRetryWithBackoff() async throws {
        let context = await ErrorTestHelpers.createTestContext(with: .retry(attempts: 3))
        
        var attemptCount = 0
        var attemptTimes: [TimeInterval] = []
        
        let operation: () async throws -> String = {
            attemptCount += 1
            attemptTimes.append(CFAbsoluteTimeGetCurrent())
            
            if attemptCount < 3 {
                throw AxiomError.clientError(.timeout(duration: 1.0))
            }
            return "Success"
        }
        
        let result = try await context.errorBoundary.executeWithRecovery(operation)
        
        XCTAssertEqual(result, "Success")
        XCTAssertEqual(attemptCount, 3)
        
        // Verify exponential backoff timing
        if attemptTimes.count >= 3 {
            let delay1 = attemptTimes[1] - attemptTimes[0]
            let delay2 = attemptTimes[2] - attemptTimes[1]
            
            // Second delay should be approximately 2x the first (2^1 vs 2^0)
            XCTAssertGreaterThan(delay1, 0.9) // ~1 second
            XCTAssertGreaterThan(delay2, 1.9) // ~2 seconds
        }
    }
    
    func testRetryFailsAfterMaxAttempts() async throws {
        let context = await ErrorTestHelpers.createTestContext(with: .retry(attempts: 2))
        
        var attemptCount = 0
        let operation: () async throws -> String = {
            attemptCount += 1
            throw AxiomError.clientError(.timeout(duration: 0.1))
        }
        
        do {
            _ = try await context.errorBoundary.executeWithRecovery(operation)
            XCTFail("Expected operation to fail after max retries")
        } catch {
            XCTAssertEqual(attemptCount, 2)
            XCTAssertTrue(error is AxiomError)
        }
    }
    
    func testNoRetryForValidationErrors() async throws {
        let context = await ErrorTestHelpers.createTestContext(with: .retry(attempts: 3))
        
        var attemptCount = 0
        let operation: () async throws -> String = {
            attemptCount += 1
            throw AxiomError.validationError(.invalidInput("email", "invalid format"))
        }
        
        do {
            _ = try await context.errorBoundary.executeWithRecovery(operation)
            XCTFail("Expected validation error to not be retried")
        } catch {
            // Should fail immediately without retry
            XCTAssertEqual(attemptCount, 1)
        }
    }
    
    // MARK: - Fallback Tests
    
    func testFallbackOperationExecution() async throws {
        var fallbackExecuted = false
        let fallbackStrategy = ErrorRecoveryStrategy.fallback {
            fallbackExecuted = true
            return "Fallback result"
        }
        
        let context = await ErrorTestHelpers.createTestContext(with: fallbackStrategy)
        
        let operation: () async throws -> String = {
            throw AxiomError.persistenceError(.saveFailed("disk full"))
        }
        
        let result = try await context.errorBoundary.executeWithRecovery(operation)
        XCTAssertTrue(fallbackExecuted)
        XCTAssertEqual(result, "Fallback result")
    }
    
    func testFallbackAfterRetryFailure() async throws {
        var primaryAttempts = 0
        var fallbackExecuted = false
        
        let fallbackStrategy = ErrorRecoveryStrategy.fallback {
            fallbackExecuted = true
            return "Fallback after retries"
        }
        
        let context = await ErrorTestHelpers.createTestContext(with: fallbackStrategy)
        
        let operation: () async throws -> String = {
            primaryAttempts += 1
            throw AxiomError.clientError(.timeout(duration: 0.1))
        }
        
        // Test with explicit retry count
        let result = try await context.errorBoundary.executeWithRecovery(operation, maxRetries: 2)
        
        XCTAssertEqual(primaryAttempts, 2)
        XCTAssertTrue(fallbackExecuted)
        XCTAssertEqual(result, "Fallback after retries")
    }
    
    // MARK: - Strategy Tests
    
    func testPropagateStrategy() async throws {
        let parentContext = await ErrorTestHelpers.createTestContext()
        let childContext = await ErrorTestHelpers.createTestContext(with: .propagate)
        
        var parentReceivedError = false
        parentContext.errorBoundary.onError = { _ in
            parentReceivedError = true
        }
        
        childContext.errorBoundary.setParent(parentContext)
        
        await childContext.errorBoundary.handle(
            AxiomError.contextError(.lifecycleError("Child error"))
        )
        
        // Allow propagation
        await Task.yield()
        
        XCTAssertTrue(parentReceivedError)
    }
    
    func testSilentStrategy() async throws {
        let context = await ErrorTestHelpers.createTestContext(with: .silent)
        
        var errorHandled = false
        context.errorBoundary.onError = { _ in
            errorHandled = true
        }
        
        // Silent errors should be handled without propagation
        await context.errorBoundary.handle(
            AxiomError.clientError(.invalidAction("test"))
        )
        
        XCTAssertTrue(errorHandled)
    }
    
    // MARK: - Performance Tests
    
    func testErrorHandlingPerformance() async throws {
        let context = await ErrorTestHelpers.createTestContext()
        
        let metrics = try await ErrorTestHelpers.measureErrorHandling(
            iterations: 1000
        ) {
            // Simple operation that succeeds
            return
        }
        
        // Error handling overhead should be minimal (<0.1ms average)
        XCTAssertTrue(metrics.meetsTarget(maxAverageTime: 0.0001))
        XCTAssertEqual(metrics.successRate, 1.0)
    }
    
    func testRetryPerformanceOverhead() async throws {
        let context = await ErrorTestHelpers.createTestContext(with: .retry(attempts: 1))
        
        let operation: () async throws -> Void = {
            // Immediate success
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try await context.errorBoundary.executeWithRecovery(operation)
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Single successful operation should have minimal overhead
        XCTAssertLessThan(elapsed, 0.001) // Less than 1ms
    }
    
    // MARK: - Integration Tests
    
    func testErrorRecoveryWithTestHelpers() async throws {
        let context = await ErrorTestHelpers.createTestContext()
        
        let result = try await ErrorTestHelpers.simulateErrorRecovery(
            in: context,
            with: .retry(attempts: 3),
            for: .clientError(.timeout(duration: 0.1)),
            expecting: .failed(after: 3, finalError: AxiomError.clientError(.timeout(duration: 0.1)))
        )
        
        if case .failed(let attempts, _) = result {
            XCTAssertEqual(attempts, 3)
        } else {
            XCTFail("Expected failure after retries")
        }
    }
    
    func testComplexRecoveryScenario() async throws {
        // Test a scenario with multiple error types and recovery strategies
        let context = await ErrorTestHelpers.createTestContext()
        
        var operationCount = 0
        let complexOperation: () async throws -> String = {
            operationCount += 1
            
            switch operationCount {
            case 1:
                // First attempt: network error (should retry)
                throw AxiomError.clientError(.timeout(duration: 0.1))
            case 2:
                // Second attempt: validation error (should not retry)
                throw AxiomError.validationError(.invalidInput("data", "corrupt"))
            default:
                return "Should not reach here"
            }
        }
        
        await context.configureErrorRecovery(.retry(attempts: 3))
        
        do {
            _ = try await context.errorBoundary.executeWithRecovery(complexOperation)
            XCTFail("Expected validation error")
        } catch let error as AxiomError {
            // Should fail on validation error without further retries
            XCTAssertEqual(operationCount, 2)
            if case .validationError = error {
                // Expected
            } else {
                XCTFail("Expected validation error")
            }
        }
    }
}