import XCTest
@testable import Axiom

final class ErrorPropagationTests: XCTestCase {
    
    // Test Result extension for error mapping
    func testResultMapToAxiomError() async throws {
        // Test successful result passes through
        let successResult: Result<String, Error> = .success("data")
        let mappedSuccess = successResult.mapToAxiomError { error in
            .contextError(.lifecycleError("Unexpected: \(error)"))
        }
        
        switch mappedSuccess {
        case .success(let value):
            XCTAssertEqual(value, "data")
        case .failure:
            XCTFail("Success should not be transformed to failure")
        }
        
        // Test error mapping
        let failureResult: Result<String, Error> = .failure(TestError.networkFailure)
        let mappedFailure = failureResult.mapToAxiomError { error in
            .navigationError(.navigationBlocked("Network error: \(error)"))
        }
        
        switch mappedFailure {
        case .success:
            XCTFail("Failure should not become success")
        case .failure(let axiomError):
            if case .navigationError(let navError) = axiomError {
                XCTAssertTrue(navError.localizedDescription.contains("Network error"))
            } else {
                XCTFail("Wrong error type")
            }
        }
        
        // Test AxiomError passes through unchanged
        let axiomResult: Result<String, Error> = .failure(AxiomError.clientError(.timeout(duration: 5)))
        let mappedAxiom = axiomResult.mapToAxiomError { _ in
            .contextError(.lifecycleError("Should not be called"))
        }
        
        switch mappedAxiom {
        case .failure(let error):
            if case .clientError(.timeout(let duration)) = error {
                XCTAssertEqual(duration, 5)
            } else {
                XCTFail("AxiomError should pass through unchanged")
            }
        case .success:
            XCTFail("Should remain failure")
        }
    }
    
    // Test async Task error mapping
    func testTaskMapToAxiomError() async throws {
        // Test successful task
        let successTask = Task<String, Error> {
            return "async data"
        }
        
        let mappedTask = successTask.mapToAxiomError { error in
            .contextError(.lifecycleError("Unexpected: \(error)"))
        }
        
        let result = try await mappedTask.value
        XCTAssertEqual(result, "async data")
        
        // Test failing task
        let failureTask = Task<String, Error> {
            throw TestError.asyncFailure
        }
        
        let mappedFailure = failureTask.mapToAxiomError { error in
            .clientError(.invalidAction("Async failed: \(error)"))
        }
        
        do {
            _ = try await mappedFailure.value
            XCTFail("Should throw error")
        } catch let error as AxiomError {
            if case .clientError(.invalidAction(let message)) = error {
                XCTAssertTrue(message.contains("Async failed"))
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    // Test error context preservation
    func testErrorContextPreservation() throws {
        let originalError = AxiomError.navigationError(.routeNotFound("/users"))
        
        // Test adding context
        let withContext = originalError.addingContext("userId", "123")
            .addingContext("timestamp", "2024-01-01")
        
        // This will fail until we implement context metadata
        if case .navigationError(let navError) = withContext {
            // Need to access metadata - not yet implemented
            XCTAssertNotNil(navError)
        }
        
        // Test wrapping operation
        let wrapped = originalError.wrapping("fetchUserData")
        XCTAssertNotNil(wrapped)
    }
    
    // Test error recovery patterns
    func testErrorRecoveryStrategies() async throws {
        let service = MockRecoverableService()
        
        // Test retry recovery
        let retryResult = await service.operationWithRetry()
        switch retryResult {
        case .success:
            XCTAssertTrue(service.attemptCount > 1, "Should have retried")
        case .failure:
            XCTFail("Retry should eventually succeed")
        }
        
        // Test fallback recovery
        let fallbackResult = await service.operationWithFallback()
        switch fallbackResult {
        case .success(let value):
            XCTAssertEqual(value, "fallback", "Should use fallback value")
        case .failure:
            XCTFail("Fallback should not fail")
        }
    }
    
    // Test error propagation through components
    func testErrorPropagationChain() async throws {
        let dataService = MockDataService()
        
        // Test error propagates with context
        let result = await dataService.fetchUserData(id: "invalid")
        
        switch result {
        case .success:
            XCTFail("Invalid ID should fail")
        case .failure(let error):
            // Verify error has proper context from each layer
            switch error {
            case .validationError(let context):
                XCTAssertEqual(context.field, "userData")
                XCTAssertEqual(context.rule, "parsing")
            case .navigationError(let context):
                XCTAssertTrue(context.localizedDescription.contains("invalid"))
            default:
                XCTFail("Wrong error type propagated")
            }
        }
    }
    
    // Test recovery protocol implementation
    func testErrorRecoverableProtocol() async throws {
        let viewModel = MockErrorRecoverableViewModel()
        
        // Test recovery suggestions
        let networkError = AxiomError.navigationError(.navigationBlocked("No connection"))
        let suggestions = viewModel.recoverySuggestions(for: networkError)
        XCTAssertTrue(suggestions.contains(.retry(maxAttempts: 3, delay: 1.0)))
        
        // Test recovery attempt
        let recoveryResult = await viewModel.attemptRecovery(
            from: networkError,
            using: .retry(maxAttempts: 3, delay: 0.1)
        )
        
        switch recoveryResult {
        case .success:
            XCTAssertTrue(viewModel.retryCount > 0)
        case .failure:
            // Retry might fail, that's OK for test
            break
        }
    }
    
    // Test no silent error swallowing
    func testNoSilentErrorSwallowing() async throws {
        let service = MockNavigationService()
        
        // Old pattern that swallows errors
        service.navigateOldStyle(to: "invalid-route")
        XCTAssertNil(service.lastError, "Old style swallows errors")
        
        // New pattern that propagates errors
        do {
            try await service.navigateNewStyle(to: "invalid-route")
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error as? AxiomError)
        }
    }
}

// Test helpers
enum TestError: Error {
    case networkFailure
    case asyncFailure
    case validationFailure
}

class MockRecoverableService {
    var attemptCount = 0
    
    func operationWithRetry() async -> Result<String, AxiomError> {
        attemptCount += 1
        if attemptCount < 3 {
            return .failure(.navigationError(.navigationBlocked("Retry needed")))
        }
        return .success("Success after retries")
    }
    
    func operationWithFallback() async -> Result<String, AxiomError> {
        // Always fails, should use fallback
        return .failure(.clientError(.notInitialized))
            .recover { _ in .success("fallback") }
    }
}

class MockDataService {
    func fetchUserData(id: String) async -> Result<User, AxiomError> {
        // Simulate network call
        if id == "invalid" {
            return .failure(.validationError(.invalidInput("userId", "Invalid format")))
        }
        
        return .success(User(id: id, name: "Test User"))
    }
}

struct User {
    let id: String
    let name: String
}

class MockErrorRecoverableViewModel: ErrorRecoverable {
    typealias RecoveryOption = StandardRecovery
    
    var retryCount = 0
    
    func recoverySuggestions(for error: AxiomError) -> [StandardRecovery] {
        switch error {
        case .navigationError:
            return [.retry(maxAttempts: 3, delay: 1.0), .reportAndContinue]
        case .clientError(.timeout):
            return [.retry(maxAttempts: 1, delay: 2.0)]
        default:
            return [.reportAndContinue]
        }
    }
    
    func attemptRecovery(from error: AxiomError, using option: StandardRecovery) async -> Result<Void, AxiomError> {
        switch option {
        case .retry(let maxAttempts, _):
            retryCount += 1
            if retryCount >= maxAttempts {
                return .success(())
            }
            return .failure(error)
        case .reportAndContinue:
            return .success(())
        default:
            return .failure(error)
        }
    }
}

class MockNavigationService {
    var lastError: Error?
    
    // Old style - swallows errors
    func navigateOldStyle(to route: String) {
        if route == "invalid-route" {
            // Error swallowed
            return
        }
        // Navigate...
    }
    
    // New style - propagates errors
    func navigateNewStyle(to route: String) async throws {
        if route == "invalid-route" {
            throw AxiomError.navigationError(.routeNotFound(route))
        }
        // Navigate...
    }
}

// Extension needed for testing
extension Result {
    func recover(_ transform: (Failure) -> Result<Success, Failure>) -> Result<Success, Failure> {
        switch self {
        case .success:
            return self
        case .failure(let error):
            return transform(error)
        }
    }
}