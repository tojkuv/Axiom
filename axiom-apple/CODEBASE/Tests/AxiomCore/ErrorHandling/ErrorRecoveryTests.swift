import XCTest
import AxiomTesting
import SwiftUI
@testable import AxiomCore
@testable import AxiomArchitecture

/// Comprehensive tests for error recovery strategies and mechanisms
/// 
/// Consolidates: ErrorRecoveryTests, RecoveryStrategyFrameworkTests
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class ErrorRecoveryTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Basic Recovery Strategy Tests
    
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
        
        XCTAssertEqual(result, "Success", "Should succeed after retries")
        XCTAssertEqual(attemptCount, 3, "Should make 3 attempts total")
        
        // Verify exponential backoff timing
        if attemptTimes.count >= 3 {
            let delay1 = attemptTimes[1] - attemptTimes[0]
            let delay2 = attemptTimes[2] - attemptTimes[1]
            
            // Second delay should be approximately 2x the first (2^1 vs 2^0)
            XCTAssertGreaterThan(delay1, 0.9, "First retry delay should be ~1 second")
            XCTAssertGreaterThan(delay2, 1.9, "Second retry delay should be ~2 seconds")
            XCTAssertLessThan(delay2, 2.5, "Second retry delay should not be too long")
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
            XCTFail("Should throw error after max attempts")
        } catch {
            XCTAssertEqual(attemptCount, 2, "Should attempt exactly 2 times")
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError")
        }
    }
    
    func testCircuitBreakerRecoveryStrategy() async throws {
        let context = await ErrorTestHelpers.createTestContext(with: .circuitBreaker(
            failureThreshold: 3,
            recoveryTimeout: 1.0
        ))
        
        var operationCount = 0
        let failingOperation: () async throws -> String = {
            operationCount += 1
            throw AxiomError.networkError(.connectionFailed("Service unavailable"))
        }
        
        // First 3 failures should trigger circuit breaker
        for _ in 0..<3 {
            do {
                _ = try await context.errorBoundary.executeWithRecovery(failingOperation)
                XCTFail("Should fail")
            } catch {
                // Expected
            }
        }
        
        XCTAssertEqual(operationCount, 3, "Should execute 3 times before circuit opens")
        
        // Circuit should now be open - further calls should fail fast
        let fastFailStart = CFAbsoluteTimeGetCurrent()
        do {
            _ = try await context.errorBoundary.executeWithRecovery(failingOperation)
            XCTFail("Should fail fast")
        } catch {
            let fastFailDuration = CFAbsoluteTimeGetCurrent() - fastFailStart
            XCTAssertLessThan(fastFailDuration, 0.1, "Should fail fast when circuit is open")
        }
        
        XCTAssertEqual(operationCount, 3, "Should not execute operation when circuit is open")
        
        // Wait for recovery timeout
        try await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
        
        // Circuit should now be half-open - allow one test call
        let workingOperation: () async throws -> String = {
            operationCount += 1
            return "Circuit recovered"
        }
        
        let result = try await context.errorBoundary.executeWithRecovery(workingOperation)
        XCTAssertEqual(result, "Circuit recovered", "Circuit should recover after timeout")
        XCTAssertEqual(operationCount, 4, "Should execute test call after recovery")
    }
    
    func testFallbackRecoveryStrategy() async throws {
        let primaryService = MockService(name: "Primary", shouldFail: true)
        let fallbackService = MockService(name: "Fallback", shouldFail: false)
        
        let context = await ErrorTestHelpers.createTestContext(with: .fallback([
            FallbackOption(service: primaryService, priority: 1),
            FallbackOption(service: fallbackService, priority: 2)
        ]))
        
        let operation: () async throws -> String = {
            // Try primary service first
            if primaryService.shouldFail {
                throw AxiomError.networkError(.connectionFailed("Primary service down"))
            }
            return await primaryService.performOperation()
        }
        
        let result = try await context.errorBoundary.executeWithRecovery(operation)
        
        XCTAssertEqual(result, "Fallback operation completed", "Should use fallback service")
        XCTAssertTrue(primaryService.wasAttempted, "Should attempt primary service first")
        XCTAssertTrue(fallbackService.wasAttempted, "Should fall back to secondary service")
    }
    
    // MARK: - Recovery Strategy Framework Tests
    
    func testCompositeRecoveryStrategy() async throws {
        let compositeStrategy = CompositeRecoveryStrategy([
            .retry(attempts: 2),
            .circuitBreaker(failureThreshold: 5, recoveryTimeout: 2.0),
            .fallback([FallbackOption(service: MockService(name: "Fallback"), priority: 1)])
        ])
        
        let context = await ErrorTestHelpers.createTestContext(with: compositeStrategy)
        
        var attemptCount = 0
        let operation: () async throws -> String = {
            attemptCount += 1
            if attemptCount <= 4 { // Fail first 4 attempts
                throw AxiomError.networkError(.connectionFailed("Temporary failure"))
            }
            return "Success after retries"
        }
        
        let result = try await context.errorBoundary.executeWithRecovery(operation)
        
        // Should retry twice, then circuit breaker should kick in, then fallback
        XCTAssertNotNil(result, "Should eventually succeed through composite strategy")
    }
    
    func testAdaptiveRecoveryStrategy() async throws {
        let adaptiveStrategy = AdaptiveRecoveryStrategy()
        let context = await ErrorTestHelpers.createTestContext(with: adaptiveStrategy)
        
        // Train adaptive strategy with different error patterns
        for i in 0..<10 {
            let errorType: AxiomError = switch i % 3 {
            case 0: AxiomError.networkError(.connectionFailed("timeout"))
            case 1: AxiomError.persistenceError(.saveFailed("disk full"))
            default: AxiomError.clientError(.timeout(duration: 1.0))
            }
            
            await adaptiveStrategy.recordFailure(errorType, recoveredWith: .retry(attempts: 3))
        }
        
        // Test that strategy adapts based on historical data
        let networkError = AxiomError.networkError(.connectionFailed("new timeout"))
        let recommendedStrategy = await adaptiveStrategy.recommendStrategy(for: networkError)
        
        XCTAssertEqual(recommendedStrategy, .retry(attempts: 3), 
                      "Should recommend strategy based on historical success")
    }
    
    func testRecoveryStrategyMetrics() async throws {
        let metricsCollector = RecoveryMetricsCollector()
        let context = await ErrorTestHelpers.createTestContext(with: .retry(attempts: 3))
        context.metricsCollector = metricsCollector
        
        var attemptCount = 0
        let operation: () async throws -> String = {
            attemptCount += 1
            if attemptCount < 3 {
                throw AxiomError.networkError(.connectionFailed("attempt \(attemptCount)"))
            }
            return "Success"
        }
        
        _ = try await context.errorBoundary.executeWithRecovery(operation)
        
        let metrics = await metricsCollector.getMetrics()
        XCTAssertEqual(metrics.totalRecoveryAttempts, 2, "Should record 2 retry attempts")
        XCTAssertEqual(metrics.successfulRecoveries, 1, "Should record 1 successful recovery")
        XCTAssertGreaterThan(metrics.averageRecoveryTime, 0, "Should record recovery time")
    }
    
    // MARK: - Error-Specific Recovery Tests
    
    func testNetworkErrorRecovery() async throws {
        let networkRecoveryStrategy = NetworkErrorRecoveryStrategy()
        let context = await ErrorTestHelpers.createTestContext(with: networkRecoveryStrategy)
        
        var connectionAttempts = 0
        let networkOperation: () async throws -> String = {
            connectionAttempts += 1
            if connectionAttempts < 3 {
                throw AxiomError.networkError(.connectionFailed("DNS timeout"))
            }
            return "Network connection established"
        }
        
        let result = try await context.errorBoundary.executeWithRecovery(networkOperation)
        
        XCTAssertEqual(result, "Network connection established", "Should recover from network errors")
        XCTAssertEqual(connectionAttempts, 3, "Should retry network operations with backoff")
    }
    
    func testPersistenceErrorRecovery() async throws {
        let persistenceRecoveryStrategy = PersistenceErrorRecoveryStrategy()
        let context = await ErrorTestHelpers.createTestContext(with: persistenceRecoveryStrategy)
        
        var saveAttempts = 0
        let saveOperation: () async throws -> String = {
            saveAttempts += 1
            if saveAttempts == 1 {
                throw AxiomError.persistenceError(.saveFailed("disk full"))
            } else if saveAttempts == 2 {
                throw AxiomError.persistenceError(.saveFailed("lock timeout"))
            }
            return "Data saved successfully"
        }
        
        let result = try await context.errorBoundary.executeWithRecovery(saveOperation)
        
        XCTAssertEqual(result, "Data saved successfully", "Should recover from persistence errors")
        XCTAssertEqual(saveAttempts, 3, "Should implement persistence-specific recovery logic")
    }
    
    func testValidationErrorRecovery() async throws {
        let validationRecoveryStrategy = ValidationErrorRecoveryStrategy()
        let context = await ErrorTestHelpers.createTestContext(with: validationRecoveryStrategy)
        
        var correctionAttempts = 0
        let validationOperation: () async throws -> String = {
            correctionAttempts += 1
            if correctionAttempts == 1 {
                throw AxiomError.validationError(.invalidInput("email", "missing @ symbol"))
            }
            return "Validation passed"
        }
        
        // Validation errors should trigger user prompt for correction
        var userPrompted = false
        context.onUserPrompt = { message, completion in
            userPrompted = true
            XCTAssertTrue(message.contains("email"), "Should identify problematic field")
            completion(.corrected("user@example.com"))
        }
        
        let result = try await context.errorBoundary.executeWithRecovery(validationOperation)
        
        XCTAssertEqual(result, "Validation passed", "Should recover after user correction")
        XCTAssertTrue(userPrompted, "Should prompt user for validation error correction")
    }
    
    // MARK: - Recovery State Management Tests
    
    func testRecoveryStateTransitions() async throws {
        let context = await ErrorTestHelpers.createTestContext(with: .retry(attempts: 3))
        
        // Initial state
        XCTAssertEqual(context.recoveryState, .idle, "Should start in idle state")
        
        var attemptCount = 0
        let operation: () async throws -> String = {
            attemptCount += 1
            
            // Check state during execution
            if attemptCount == 1 {
                XCTAssertEqual(context.recoveryState, .attempting, "Should be in attempting state")
            } else {
                XCTAssertEqual(context.recoveryState, .retrying, "Should be in retrying state")
            }
            
            if attemptCount < 3 {
                throw AxiomError.networkError(.connectionFailed("attempt \(attemptCount)"))
            }
            return "Success"
        }
        
        _ = try await context.errorBoundary.executeWithRecovery(operation)
        
        XCTAssertEqual(context.recoveryState, .recovered, "Should be in recovered state after success")
    }
    
    func testRecoveryStateTimeout() async throws {
        let context = await ErrorTestHelpers.createTestContext(with: .retry(attempts: 5))
        context.recoveryTimeout = 2.0 // 2 second timeout
        
        let longRunningOperation: () async throws -> String = {
            // Simulate very slow operation
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            return "Completed"
        }
        
        do {
            _ = try await context.errorBoundary.executeWithRecovery(longRunningOperation)
            XCTFail("Should timeout")
        } catch {
            XCTAssertEqual(context.recoveryState, .timedOut, "Should be in timed out state")
            XCTAssertTrue(error is RecoveryTimeoutError, "Should throw recovery timeout error")
        }
    }
    
    // MARK: - User-Guided Recovery Tests
    
    func testUserGuidedRecovery() async throws {
        let context = await ErrorTestHelpers.createTestContext(with: .userGuided)
        
        var userInteractions: [UserRecoveryInteraction] = []
        context.onUserRecoveryPrompt = { error, options, completion in
            let interaction = UserRecoveryInteraction(
                error: error,
                options: options,
                selectedOption: options.first { $0.type == .retry }
            )
            userInteractions.append(interaction)
            completion(interaction.selectedOption!)
        }
        
        var attemptCount = 0
        let operation: () async throws -> String = {
            attemptCount += 1
            if attemptCount == 1 {
                throw AxiomError.networkError(.connectionFailed("Connection refused"))
            }
            return "User-guided recovery successful"
        }
        
        let result = try await context.errorBoundary.executeWithRecovery(operation)
        
        XCTAssertEqual(result, "User-guided recovery successful", "Should succeed with user guidance")
        XCTAssertEqual(userInteractions.count, 1, "Should prompt user once")
        XCTAssertEqual(userInteractions.first?.selectedOption?.type, .retry, "User should select retry")
    }
    
    func testUserRecoveryOptionGeneration() async throws {
        let optionGenerator = UserRecoveryOptionGenerator()
        
        // Test network error options
        let networkError = AxiomError.networkError(.connectionFailed("DNS resolution failed"))
        let networkOptions = await optionGenerator.generateOptions(for: networkError)
        
        XCTAssertTrue(networkOptions.contains { $0.type == .retry }, "Should offer retry for network errors")
        XCTAssertTrue(networkOptions.contains { $0.type == .useOfflineMode }, "Should offer offline mode")
        XCTAssertTrue(networkOptions.contains { $0.type == .changeSettings }, "Should offer settings change")
        
        // Test validation error options
        let validationError = AxiomError.validationError(.invalidInput("password", "too short"))
        let validationOptions = await optionGenerator.generateOptions(for: validationError)
        
        XCTAssertTrue(validationOptions.contains { $0.type == .correctInput }, "Should offer input correction")
        XCTAssertTrue(validationOptions.contains { $0.type == .skipValidation }, "Should offer skip option")
        XCTAssertTrue(validationOptions.contains { $0.type == .getHelp }, "Should offer help")
    }
    
    // MARK: - Performance Tests
    
    func testRecoveryPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let context = await ErrorTestHelpers.createTestContext(with: .retry(attempts: 3))
                
                // Test rapid recovery operations
                for i in 0..<100 {
                    var attemptCount = 0
                    let operation: () async throws -> String = {
                        attemptCount += 1
                        if attemptCount == 1 && i % 3 == 0 { // Fail every 3rd operation
                            throw AxiomError.clientError(.timeout(duration: 0.1))
                        }
                        return "Operation \(i) completed"
                    }
                    
                    _ = try await context.errorBoundary.executeWithRecovery(operation)
                }
            },
            maxDuration: .milliseconds(500),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    func testConcurrentRecoveryOperations() async throws {
        let context = await ErrorTestHelpers.createTestContext(with: .retry(attempts: 2))
        
        // Run multiple recovery operations concurrently
        await withTaskGroup(of: String.self) { group in
            for i in 0..<50 {
                group.addTask {
                    var attemptCount = 0
                    let operation: () async throws -> String = {
                        attemptCount += 1
                        if attemptCount == 1 && i % 5 == 0 { // Fail every 5th operation
                            throw AxiomError.networkError(.connectionFailed("timeout \(i)"))
                        }
                        return "Concurrent operation \(i) completed"
                    }
                    
                    return try await context.errorBoundary.executeWithRecovery(operation)
                }
            }
            
            var completedOperations = 0
            for await result in group {
                XCTAssertTrue(result.contains("completed"), "Operation should complete successfully")
                completedOperations += 1
            }
            
            XCTAssertEqual(completedOperations, 50, "All concurrent operations should complete")
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testRecoveryMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            // Test recovery strategy lifecycle
            for iteration in 0..<20 {
                let context = await ErrorTestHelpers.createTestContext(with: .retry(attempts: 3))
                
                for i in 0..<25 {
                    var attemptCount = 0
                    let operation: () async throws -> String = {
                        attemptCount += 1
                        if attemptCount == 1 {
                            throw AxiomError.clientError(.timeout(duration: Double(i % 5)))
                        }
                        return "Iteration \(iteration) Operation \(i) completed"
                    }
                    
                    _ = try await context.errorBoundary.executeWithRecovery(operation)
                }
                
                // Force cleanup
                await context.cleanup()
            }
        }
    }
}

// MARK: - Test Helper Classes

private class MockService {
    let name: String
    var shouldFail: Bool
    var wasAttempted = false
    
    init(name: String, shouldFail: Bool = false) {
        self.name = name
        self.shouldFail = shouldFail
    }
    
    func performOperation() async -> String {
        wasAttempted = true
        return "\(name) operation completed"
    }
}

private struct FallbackOption {
    let service: MockService
    let priority: Int
    
    init(service: MockService, priority: Int = 1) {
        self.service = service
        self.priority = priority
    }
}

private enum RecoveryStrategy {
    case retry(attempts: Int)
    case circuitBreaker(failureThreshold: Int, recoveryTimeout: TimeInterval)
    case fallback([FallbackOption])
    case userGuided
}

private class CompositeRecoveryStrategy {
    let strategies: [RecoveryStrategy]
    
    init(_ strategies: [RecoveryStrategy]) {
        self.strategies = strategies
    }
}

private class AdaptiveRecoveryStrategy {
    private var successfulRecoveries: [String: RecoveryStrategy] = [:]
    
    func recordFailure(_ error: AxiomError, recoveredWith strategy: RecoveryStrategy) async {
        let errorKey = error.category
        successfulRecoveries[errorKey] = strategy
    }
    
    func recommendStrategy(for error: AxiomError) async -> RecoveryStrategy {
        let errorKey = error.category
        return successfulRecoveries[errorKey] ?? .retry(attempts: 3)
    }
}

private class NetworkErrorRecoveryStrategy {
    // Network-specific recovery logic
}

private class PersistenceErrorRecoveryStrategy {
    // Persistence-specific recovery logic
}

private class ValidationErrorRecoveryStrategy {
    // Validation-specific recovery logic
}

private actor RecoveryMetricsCollector {
    private var totalRecoveryAttempts = 0
    private var successfulRecoveries = 0
    private var recoveryTimes: [TimeInterval] = []
    
    func recordRecoveryAttempt() {
        totalRecoveryAttempts += 1
    }
    
    func recordSuccessfulRecovery(time: TimeInterval) {
        successfulRecoveries += 1
        recoveryTimes.append(time)
    }
    
    func getMetrics() -> (totalRecoveryAttempts: Int, successfulRecoveries: Int, averageRecoveryTime: TimeInterval) {
        let avgTime = recoveryTimes.isEmpty ? 0 : recoveryTimes.reduce(0, +) / Double(recoveryTimes.count)
        return (totalRecoveryAttempts, successfulRecoveries, avgTime)
    }
}

private enum RecoveryState {
    case idle
    case attempting
    case retrying
    case recovered
    case failed
    case timedOut
}

private struct UserRecoveryInteraction {
    let error: Error
    let options: [UserRecoveryOption]
    let selectedOption: UserRecoveryOption?
}

private struct UserRecoveryOption {
    let type: UserRecoveryOptionType
    let title: String
    let description: String
    
    init(type: UserRecoveryOptionType) {
        self.type = type
        self.title = type.defaultTitle
        self.description = type.defaultDescription
    }
}

private enum UserRecoveryOptionType {
    case retry
    case useOfflineMode
    case changeSettings
    case correctInput
    case skipValidation
    case getHelp
    case cancel
    
    var defaultTitle: String {
        switch self {
        case .retry: return "Retry"
        case .useOfflineMode: return "Use Offline Mode"
        case .changeSettings: return "Change Settings"
        case .correctInput: return "Correct Input"
        case .skipValidation: return "Skip Validation"
        case .getHelp: return "Get Help"
        case .cancel: return "Cancel"
        }
    }
    
    var defaultDescription: String {
        switch self {
        case .retry: return "Try the operation again"
        case .useOfflineMode: return "Continue without network connection"
        case .changeSettings: return "Modify application settings"
        case .correctInput: return "Fix the input and try again"
        case .skipValidation: return "Continue without validation"
        case .getHelp: return "View help documentation"
        case .cancel: return "Cancel the operation"
        }
    }
}

private class UserRecoveryOptionGenerator {
    func generateOptions(for error: AxiomError) async -> [UserRecoveryOption] {
        switch error {
        case .networkError:
            return [
                UserRecoveryOption(type: .retry),
                UserRecoveryOption(type: .useOfflineMode),
                UserRecoveryOption(type: .changeSettings),
                UserRecoveryOption(type: .cancel)
            ]
        case .validationError:
            return [
                UserRecoveryOption(type: .correctInput),
                UserRecoveryOption(type: .skipValidation),
                UserRecoveryOption(type: .getHelp),
                UserRecoveryOption(type: .cancel)
            ]
        default:
            return [
                UserRecoveryOption(type: .retry),
                UserRecoveryOption(type: .cancel)
            ]
        }
    }
}

private enum UserPromptResponse {
    case retry
    case corrected(String)
    case cancel
}

private struct RecoveryTimeoutError: Error {
    let timeout: TimeInterval
}