import XCTest
@testable import Axiom

// MARK: - Error Test Helpers

/// Utilities for testing error handling functionality
public struct ErrorTestHelpers {
    
    /// Assert that an error boundary properly catches and handles errors
    public static func assertErrorBoundary<C: Context & ErrorBoundaryManaged>(
        in context: C,
        when operation: () async throws -> Void,
        catchesError expectedError: AxiomError,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        var caughtError: Error?
        
        await MainActor.run {
            context.errorBoundary.onError = { error in
                caughtError = error
            }
        }
        
        do {
            try await operation()
            XCTFail("Expected error \(expectedError) but no error was thrown", 
                    file: file, line: line)
        } catch {
            // Error should be caught by boundary
            try? await Task.sleep(nanoseconds: 1_000_000) // Allow boundary to process (1ms)
            
            if let axiomError = caughtError as? AxiomError {
                XCTAssertEqual(axiomError, expectedError, file: file, line: line)
            } else {
                XCTFail("Expected AxiomError but got \(type(of: caughtError))", 
                        file: file, line: line)
            }
        }
    }
    
    /// Simulate and validate error recovery
    public static func simulateErrorRecovery<C: Context & ErrorBoundaryManaged>(
        in context: C,
        with strategy: ErrorRecoveryStrategy,
        for error: AxiomError,
        expecting result: RecoveryResult,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> RecoveryResult {
        await context.configureErrorRecovery(strategy)
        
        var recoveryAttempts = 0
        let operation = {
            recoveryAttempts += 1
            throw error
        }
        
        do {
            _ = try await context.errorBoundary.executeWithRecovery(operation)
            return .succeeded(attempts: recoveryAttempts)
        } catch {
            return .failed(after: recoveryAttempts, finalError: error)
        }
    }
    
    /// Validate error propagation through boundaries
    public static func validateErrorPropagation(
        from source: any Actor,
        to destination: any ErrorBoundaryManaged,
        through path: [any Actor],
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        var propagationPath: [String] = []
        
        // Set up tracking at each boundary
        for actor in path {
            if let boundary = actor as? ErrorBoundaryManaged {
                await MainActor.run {
                    boundary.errorBoundary.onError = { error in
                        propagationPath.append(String(describing: type(of: actor)))
                    }
                }
            }
        }
        
        // Trigger error from source
        let testError = AxiomError.clientError(.invalidAction("test"))
        
        // Simulate error propagation
        if let errorSource = source as? ErrorBoundaryManaged {
            await errorSource.errorBoundary.handle(testError)
        }
        
        // Allow propagation to complete
        try? await Task.sleep(nanoseconds: 1_000_000)
        
        XCTAssertEqual(propagationPath.count, path.count, 
                      "Error should propagate through all boundaries", 
                      file: file, line: line)
    }
    
    /// Assert that an operation throws the expected error
    public static func assertThrows<T>(
        _ expectedError: AxiomError,
        when operation: () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected error \(expectedError) but operation succeeded", 
                    file: file, line: line)
        } catch let error as AxiomError {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Expected AxiomError but got \(type(of: error)): \(error)", 
                    file: file, line: line)
        }
    }
    
    /// Measure error handling performance
    public static func measureErrorHandling(
        iterations: Int = 1000,
        operation: () async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> ErrorPerformanceMetrics {
        let startTime = CFAbsoluteTimeGetCurrent()
        var successCount = 0
        var errorCount = 0
        
        for _ in 0..<iterations {
            do {
                try await operation()
                successCount += 1
            } catch {
                errorCount += 1
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let averageTime = totalTime / Double(iterations)
        
        return ErrorPerformanceMetrics(
            totalTime: totalTime,
            averageTime: averageTime,
            successRate: Double(successCount) / Double(iterations),
            errorRate: Double(errorCount) / Double(iterations)
        )
    }
    
    /// Create a test context with error boundary configuration
    @MainActor
    public static func createTestContext(
        with strategy: ErrorRecoveryStrategy = .propagate
    ) async -> TestContext {
        let context = TestContext()
        await context.configureErrorRecovery(strategy)
        return context
    }
}

// MARK: - Recovery Result

/// Result of error recovery attempt
public enum RecoveryResult: Equatable {
    case succeeded(attempts: Int)
    case failed(after: Int, finalError: Error)
    
    public static func == (lhs: RecoveryResult, rhs: RecoveryResult) -> Bool {
        switch (lhs, rhs) {
        case (.succeeded(let l), .succeeded(let r)):
            return l == r
        case (.failed(let l1, _), .failed(let r1, _)):
            return l1 == r1
        default:
            return false
        }
    }
}

// MARK: - Performance Metrics

/// Metrics for error handling performance
public struct ErrorPerformanceMetrics {
    public let totalTime: TimeInterval
    public let averageTime: TimeInterval
    public let successRate: Double
    public let errorRate: Double
    
    /// Check if performance meets target
    public func meetsTarget(maxAverageTime: TimeInterval = 0.0001) -> Bool {
        return averageTime < maxAverageTime
    }
}

// MARK: - Test Context

/// A test context for error handling scenarios
@MainActor
public class TestContext: ObservableContext {
    public var testState: String = ""
    
    public override init() {
        super.init()
    }
    
    /// Test method that can throw errors
    public func riskyOperation() async throws {
        throw AxiomError.contextError(.lifecycleError("Test error"))
    }
    
    /// Test method with retry capability
    public func retryableOperation(failUntilAttempt: Int) async throws -> String {
        struct RetryState {
            static var attempts = 0
        }
        
        RetryState.attempts += 1
        
        if RetryState.attempts < failUntilAttempt {
            throw AxiomError.clientError(.timeout(duration: 0.1))
        }
        
        return "Success after \(RetryState.attempts) attempts"
    }
}

// MARK: - Mock Error Boundary

/// Mock error boundary for testing
@MainActor
public class MockErrorBoundary: AxiomErrorBoundary {
    public var handledErrors: [Error] = []
    public var recoveryAttempts: [String: Int] = [:]
    
    public override func handle(_ error: Error) async {
        handledErrors.append(error)
        await super.handle(error)
    }
    
    public override func executeWithRecovery<T>(
        _ operation: () async throws -> T,
        maxRetries: Int? = nil
    ) async throws -> T {
        let key = UUID().uuidString
        recoveryAttempts[key] = 0
        
        do {
            let result = try await super.executeWithRecovery(operation, maxRetries: maxRetries)
            recoveryAttempts[key] = (recoveryAttempts[key] ?? 0) + 1
            return result
        } catch {
            recoveryAttempts[key] = maxRetries ?? 1
            throw error
        }
    }
}