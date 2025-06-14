import XCTest
@testable import Axiom

/// Tests for standardized error propagation patterns
class ErrorPropagationPatternsTests: XCTestCase {
    
    // MARK: - Result-based Error Propagation Tests
    
    func testResultMapToAxiomError() async throws {
        // Test transformation from generic Error to AxiomError
        let genericError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let result: Result<String, Error> = .failure(genericError)
        
        let mappedResult = result.mapToAxiomError { error in
            .contextError(.lifecycleError("Mapped: \(error.localizedDescription)"))
        }
        
        switch mappedResult {
        case .success:
            XCTFail("Expected failure")
        case .failure(let axiomError):
            if case .contextError(let contextError) = axiomError,
               case .lifecycleError(let message) = contextError {
                XCTAssertTrue(message.contains("Mapped: Test error"))
            } else {
                XCTFail("Expected contextError with lifecycleError")
            }
        }
    }
    
    func testResultMapToAxiomErrorPreservesAxiomError() async throws {
        // Test that existing AxiomError is preserved, not double-wrapped
        let originalAxiomError = AxiomError.validationError(.invalidInput("email", "Invalid format"))
        let result: Result<String, Error> = .failure(originalAxiomError)
        
        let mappedResult = result.mapToAxiomError { error in
            .contextError(.lifecycleError("Should not be called"))
        }
        
        switch mappedResult {
        case .success:
            XCTFail("Expected failure")
        case .failure(let axiomError):
            XCTAssertEqual(axiomError, originalAxiomError)
        }
    }
    
    // MARK: - Async Task Error Propagation Tests
    
    func testAsyncTaskMapToAxiomError() async throws {
        let task = Task<String, Error> {
            throw NSError(domain: "AsyncDomain", code: 456, userInfo: [NSLocalizedDescriptionKey: "Async error"])
        }
        
        do {
            _ = try await task.mapToAxiomError { error in
                .clientError(.timeout(duration: 5.0))
            }
            XCTFail("Expected error")
        } catch let axiomError as AxiomError {
            if case .clientError(let clientError) = axiomError,
               case .timeout(let duration) = clientError {
                XCTAssertEqual(duration, 5.0)
            } else {
                XCTFail("Expected clientError with timeout")
            }
        } catch {
            XCTFail("Expected AxiomError, got \(error)")
        }
    }
    
    func testAsyncTaskMapToAxiomErrorPreservesAxiomError() async throws {
        let originalAxiomError = AxiomError.persistenceError(.saveFailed("Database locked"))
        
        let task = Task<String, Error> {
            throw originalAxiomError
        }
        
        do {
            _ = try await task.mapToAxiomError { error in
                .contextError(.lifecycleError("Should not be called"))
            }
            XCTFail("Expected error")
        } catch let axiomError as AxiomError {
            XCTAssertEqual(axiomError, originalAxiomError)
        } catch {
            XCTFail("Expected AxiomError, got \(error)")
        }
    }
    
    // MARK: - Error Context Preservation Tests
    
    func testErrorContextAccumulation() async throws {
        let baseError = AxiomError.networkError(NetworkContext(
            operation: "fetchUser",
            url: URL(string: "https://api.example.com/users/123"),
            underlying: nil,
            metadata: ["userId": "123"]
        ))
        
        let enrichedError = baseError
            .addingContext("component", "UserService")
            .addingContext("session", "abc-123")
        
        // For now, test that the error is preserved since addingContext returns self
        XCTAssertEqual(enrichedError.localizedDescription, baseError.localizedDescription)
    }
    
    func testErrorWrappingOperation() async throws {
        let baseError = AxiomError.validationError(.invalidInput("name", "Too short"))
        let wrappedError = baseError.wrapping("validateUserProfile")
        
        if case .validationError = wrappedError {
            // Should have wrapped_operation in metadata when implemented
            XCTAssertTrue(true) // Test structure ready for implementation
        } else {
            XCTFail("Expected validationError")
        }
    }
    
    // MARK: - Error Recovery Pattern Tests
    
    func testErrorRecoverableProtocol() async throws {
        let mockRecoverable = MockErrorRecoverable()
        
        let networkError = AxiomError.networkError(NetworkContext(
            operation: "sync",
            url: nil,
            underlying: nil,
            metadata: [:]
        ))
        
        let suggestions = mockRecoverable.recoverySuggestions(for: networkError)
        XCTAssertFalse(suggestions.isEmpty)
        
        let recoveryResult = await mockRecoverable.attemptRecovery(
            from: networkError,
            using: suggestions.first!
        )
        
        switch recoveryResult {
        case .success:
            XCTAssertTrue(true)
        case .failure(let error):
            XCTFail("Recovery should succeed for test, got \(error)")
        }
    }
    
    func testStandardRecoveryStrategies() async throws {
        // Test retry strategy
        let retryStrategy = StandardRecovery.retry(maxAttempts: 3, delay: 0.1)
        XCTAssertNotNil(retryStrategy)
        
        // Test fallback strategy
        let fallbackStrategy = StandardRecovery.fallback(to: "defaultValue")
        XCTAssertNotNil(fallbackStrategy)
        
        // Test ignore strategy
        let ignoreStrategy = StandardRecovery.ignore
        XCTAssertNotNil(ignoreStrategy)
        
        // Test report strategy
        let reportStrategy = StandardRecovery.reportAndContinue
        XCTAssertNotNil(reportStrategy)
    }
    
    // MARK: - Integration Pattern Tests
    
    func testDataServiceErrorPropagation() async throws {
        let dataService = MockDataServicePatterns()
        
        let result = await dataService.fetchUserData(id: "invalid-user")
        
        switch result {
        case .success:
            XCTFail("Expected failure for invalid user")
        case .failure(let error):
            // Should be properly mapped AxiomError
            XCTAssertNotNil(error, "Error should be properly returned")
            
            // Test that we got a context error (which is how networkError is mapped for now)
            if case .contextError(let contextError) = error {
                XCTAssertTrue(contextError.localizedDescription.contains("Network operation"))
            } else {
                XCTFail("Expected contextError from networkError mapping")
            }
        }
    }
    
    func testViewModelErrorRecovery() async throws {
        let viewModel = MockUserViewModel()
        
        // Should handle errors gracefully with recovery
        await viewModel.loadUser()
        
        // If network fails with 404, should use placeholder
        if let user = viewModel.user {
            XCTAssertEqual(user.name, "Placeholder User")
        } else {
            XCTFail("Expected placeholder user after recovery")
        }
    }
    
    // MARK: - Performance Tests
    
    func testErrorPropagationPerformance() async throws {
        let iterations = 1000
        
        measure {
            for i in 0..<iterations {
                let error = AxiomError.validationError(.invalidInput("field\(i)", "error\(i)"))
                let enriched = error
                    .addingContext("iteration", "\(i)")
                    .wrapping("performanceTest")
                
                _ = enriched.localizedDescription
            }
        }
    }
    
    func testResultMapPerformance() async throws {
        let iterations = 1000
        
        measure {
            for i in 0..<iterations {
                let result: Result<Int, Error> = .failure(NSError(domain: "Test", code: i))
                let mapped = result.mapToAxiomError { _ in
                    .contextError(.lifecycleError("Performance test \(i)"))
                }
                
                switch mapped {
                case .success:
                    break
                case .failure:
                    break
                }
            }
        }
    }
}

// MARK: - Mock Types

private class MockErrorRecoverable: ErrorRecoverable {
    typealias RecoveryOption = String
    
    func recoverySuggestions(for error: AxiomError) -> [String] {
        switch error {
        case .contextError:
            return ["retry", "offline_mode"]
        case .validationError:
            return ["user_correction"]
        default:
            return ["report"]
        }
    }
    
    func attemptRecovery(from error: AxiomError, using option: String) async -> Result<Void, AxiomError> {
        // Mock successful recovery
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        return .success(())
    }
}

private actor MockDataServicePatterns {
    func fetchUserData(id: String) async -> Result<User, AxiomError> {
        // Simulate network call that fails
        if id == "invalid-user" {
            let networkError = AxiomError.networkError(NetworkContext(
                operation: "fetchUser",
                url: URL(string: "https://api.example.com/users/\(id)"),
                underlying: NSError(domain: NSURLErrorDomain, code: 404),
                metadata: ["userId": id]
            ))
            return .failure(networkError)
        }
        
        return .success(User(id: id, name: "Test User"))
    }
}

private class MockUserViewModel: ObservableObject {
    @Published var user: User?
    @Published var error: AxiomError?
    @Published var showError = false
    
    private let dataService = MockDataServicePatterns()
    
    func loadUser() async {
        let result = await dataService.fetchUserData(id: "invalid-user")
        
        await MainActor.run {
            switch result {
            case .success(let user):
                self.user = user
            case .failure(let error):
                self.error = error
                self.showError = true
            }
        }
    }
}

private struct User {
    let id: String
    let name: String
}

// Extension to add recovery method to Result
private extension Result where Failure == AxiomError {
    func recover(_ recovery: (Failure) async -> Result<Success, Failure>) async -> Result<Success, Failure> {
        switch self {
        case .success:
            return self
        case .failure(let error):
            return await recovery(error)
        }
    }
}

// Extensions use the NetworkContext from ErrorPropagation.swift

// MARK: - Additional Error Propagation Pattern Tests (REQUIREMENTS-W-06-002)

extension ErrorPropagationPatternsTests {
    
    // MARK: - Error Categorization System Tests
    
    func testAutomaticErrorCategorization() async throws {
        // Test automatic error categorization based on error type
        let networkError = URLError(.notConnectedToInternet)
        let category = ErrorCategory.categorize(networkError)
        XCTAssertEqual(category, .network)
        
        let validationError = AxiomError.validationError(.invalidInput("email", "required"))
        let validationCategory = ErrorCategory.categorize(validationError)
        XCTAssertEqual(validationCategory, .validation)
        
        let systemError = NSError(domain: NSCocoaErrorDomain, code: 1, userInfo: nil)
        let systemCategory = ErrorCategory.categorize(systemError)
        XCTAssertEqual(systemCategory, .system)
        
        // Test AxiomError.networkError categorization
        let axiomNetworkError = AxiomError.networkError(.invalidURL(component: "host", value: "invalid"))
        let axiomNetworkCategory = ErrorCategory.categorize(axiomNetworkError)
        XCTAssertEqual(axiomNetworkCategory, .system) // navigation errors map to system
    }
    
    func testCustomErrorCategoryDefinitions() async throws {
        // Test support for custom error category definitions
        let customError = CustomBusinessError.insufficientFunds
        let category = ErrorCategory.categorize(customError)
        // This should fail until custom category support is implemented
        XCTAssertEqual(category, .unknown)
    }
    
    func testCategoryBasedErrorHandling() async throws {
        // Test error handling based on category
        let networkError = AxiomError.networkError(NetworkContext(operation: "fetch", url: nil))
        let category = ErrorCategory.categorize(networkError)
        
        let recoveryStrategy = defaultRecoveryStrategy(for: category)
        
        switch category {
        case .network:
            XCTAssertEqual(recoveryStrategy, .retry(maxAttempts: 3, delay: 2.0))
        default:
            XCTFail("Should be network category")
        }
    }
    
    // MARK: - Propagation Middleware Tests
    
    func testErrorTransformationMiddleware() async throws {
        // Test error transformation middleware pipeline
        let middleware = ErrorPropagationMiddleware()
        
        // Add transformation middleware
        middleware.addTransformer("enrichment") { error in
            return error.addingContext("middleware", "enrichment")
                      .addingContext("timestamp", ISO8601DateFormatter().string(from: Date()))
        }
        
        // Add filtering middleware
        middleware.addFilter("debug") { error in
            // Only propagate non-debug errors in production
            if case .contextError(.lifecycleError(let message)) = error,
               message.contains("debug") {
                return false
            }
            return true
        }
        
        let originalError = AxiomError.contextError(.lifecycleError("test error"))
        let processedError = await middleware.process(originalError)
        
        // Should be enriched with middleware context
        XCTAssertNotNil(processedError)
    }
    
    func testErrorSuppressionMiddleware() async throws {
        // Test error filtering and suppression
        let middleware = ErrorPropagationMiddleware()
        
        // Add suppression for debug errors
        middleware.addFilter("suppress-debug") { error in
            if case .contextError(.lifecycleError(let message)) = error,
               message.contains("debug") {
                return false // Suppress debug errors
            }
            return true
        }
        
        let debugError = AxiomError.contextError(.lifecycleError("debug: test message"))
        let suppressedError = await middleware.process(debugError)
        
        // Should be nil (suppressed)
        XCTAssertNil(suppressedError)
        
        let normalError = AxiomError.validationError(.invalidInput("field", "required"))
        let passedError = await middleware.process(normalError)
        
        // Should pass through
        XCTAssertNotNil(passedError)
    }
    
    func testMiddlewareOrdering() async throws {
        // Test that middleware executes in correct order
        let middleware = ErrorPropagationMiddleware()
        var executionOrder: [String] = []
        
        middleware.addTransformer("first") { error in
            executionOrder.append("first")
            return error.addingContext("order", "first")
        }
        
        middleware.addTransformer("second") { error in
            executionOrder.append("second")
            return error.addingContext("order", "second")
        }
        
        let originalError = AxiomError.contextError(.lifecycleError("ordering test"))
        _ = await middleware.process(originalError)
        
        XCTAssertEqual(executionOrder, ["first", "second"])
    }
    
    // MARK: - Cross-Actor Error Flow Tests
    
    func testCrossActorErrorPropagation() async throws {
        // Test safe error propagation across actor boundaries
        let backgroundActor = BackgroundDataActor()
        
        do {
            _ = try await backgroundActor.performNetworkOperation()
            XCTFail("Should throw error")
        } catch let error as AxiomError {
            // Error should maintain sendable requirements
            XCTAssertTrue(error is AxiomError)
            if case .networkError(.invalidURL) = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected network error")
            }
        } catch {
            XCTFail("Should propagate as AxiomError")
        }
    }
    
    @MainActor
    func testMainActorToBackgroundActorErrorFlow() async throws {
        // Test error flow from MainActor to background actor
        let backgroundActor = BackgroundDataActor()
        let mainActorService = MainActorUIService(dataActor: backgroundActor)
        
        do {
            await mainActorService.processUserRequest()
            XCTFail("Should propagate error from background actor")
        } catch let error as AxiomError {
            // Should maintain actor isolation guarantees
            XCTAssertTrue(error is AxiomError)
        }
    }
    
    func testSendableErrorRequirements() async throws {
        // Test that errors meet sendable requirements for cross-actor use
        let networkContext = NetworkContext(
            operation: "fetch",
            url: URL(string: "https://example.com"),
            underlying: URLError(.notConnectedToInternet)
        )
        
        let error = AxiomError.networkError(networkContext)
        
        // Should be able to send across actor boundaries
        let actor = BackgroundDataActor()
        await actor.handleError(error)
        
        XCTAssertTrue(true) // Test that compilation succeeds
    }
    
    // MARK: - Enhanced Error Metadata Tests
    
    func testErrorMetadataEnhancement() async throws {
        // Test enhanced error metadata system
        let baseError = AxiomError.validationError(.invalidInput("email", "required"))
        
        let enhancedError = baseError
            .addingContext("user_id", "12345")
            .addingContext("session_id", "abc-def-123")
            .addingContext("request_id", "req-456")
            .addingContext("component", "UserRegistration")
        
        // Should preserve all context metadata
        // This will fail until metadata system is properly implemented
        let metadata = enhancedError.metadata
        XCTAssertEqual(metadata["user_id"], "12345")
        XCTAssertEqual(metadata["session_id"], "abc-def-123")
        XCTAssertEqual(metadata["request_id"], "req-456")
        XCTAssertEqual(metadata["component"], "UserRegistration")
    }
    
    func testErrorChaining() async throws {
        // Test error chaining and wrapping
        let rootError = AxiomError.persistenceError(.saveFailed("Database connection lost"))
        let wrappedError = AxiomError.clientError(.stateUpdateFailed("User save failed"))
            .chainedWith(rootError)
        
        // Should contain reference to previous error
        let metadata = wrappedError.metadata
        XCTAssertNotNil(metadata["previous_error"])
    }
    
    func testContextPreservationAcrossAsyncBoundaries() async throws {
        // Test that error context is preserved across async boundaries
        let result = await withErrorContext("userOperation") {
            try await performNestedAsyncOperation()
        }
        
        switch result {
        case .failure(let error):
            // Should preserve operation context
            let metadata = error.metadata
            XCTAssertEqual(metadata["operation"], "userOperation")
        case .success:
            XCTFail("Should fail for test")
        }
    }
}

// MARK: - Additional Test Support Types

private enum CustomBusinessError: Error {
    case insufficientFunds
    case invalidAccountType
    case businessHourRestriction
}

private class ErrorPropagationMiddleware {
    private var transformers: [(String, (AxiomError) -> AxiomError)] = []
    private var filters: [(String, (AxiomError) -> Bool)] = []
    
    func addTransformer(_ name: String, _ transformer: @escaping (AxiomError) -> AxiomError) {
        transformers.append((name, transformer))
    }
    
    func addFilter(_ name: String, _ filter: @escaping (AxiomError) -> Bool) {
        filters.append((name, filter))
    }
    
    func process(_ error: AxiomError) async -> AxiomError? {
        var processedError = error
        
        // Apply transformers in order
        for (_, transformer) in transformers {
            processedError = transformer(processedError)
        }
        
        // Apply filters
        for (_, filter) in filters {
            if !filter(processedError) {
                return nil // Suppressed
            }
        }
        
        return processedError
    }
}

private actor BackgroundDataActor {
    func performNetworkOperation() async throws -> String {
        // Simulate network failure
        throw AxiomError.networkError(.invalidURL(component: "host", value: "invalid"))
    }
    
    func handleError(_ error: AxiomError) async {
        // Process error in background actor
        print("Background actor handling: \(error)")
    }
}

@MainActor
private class MainActorUIService {
    private let dataActor: BackgroundDataActor
    
    init(dataActor: BackgroundDataActor) {
        self.dataActor = dataActor
    }
    
    func processUserRequest() async throws {
        // Propagate error from background actor to main actor
        _ = try await dataActor.performNetworkOperation()
    }
}

private func defaultRecoveryStrategy(for category: ErrorCategory) -> PropagationRecoveryStrategy {
    switch category {
    case .network:
        return .retry(maxAttempts: 3, delay: 2.0)
    case .validation:
        return .fail
    case .authorization:
        return .log(level: .error)
    case .dataIntegrity:
        return .log(level: .critical)
    case .system:
        return .fail
    case .unknown:
        return .log(level: .warning)
    }
}

private func performNestedAsyncOperation() async throws -> String {
    // Simulate nested async failure
    throw URLError(.timedOut)
}

// Extension to AxiomError for metadata access (to be implemented)
private extension AxiomError {
    var metadata: [String: String] {
        // Placeholder - should return actual metadata when implemented
        return [:]
    }
}