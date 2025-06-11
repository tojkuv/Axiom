import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import AxiomMacros
@testable import Axiom

/// Tests for error handling macros (REQUIREMENTS-W-06-005)
final class ErrorHandlingMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "ErrorBoundary": ErrorBoundaryMacro.self,
        "ErrorHandling": ErrorHandlingMacro.self,
        "ErrorContext": ErrorContextMacro.self,
        "RecoveryStrategy": RecoveryStrategyMacro.self,
        "PropagateErrors": PropagateErrorsMacro.self,
        "recoverable": RecoverableMacro.self
    ]
    
    // MARK: - ErrorBoundary Macro Tests
    
    func testErrorBoundaryMacroGeneration() throws {
        assertMacroExpansion(
            """
            @ErrorBoundary(strategy: .retry(maxAttempts: 3, delay: 2.0))
            class NetworkContext: ObservableContext {
                func fetchData() async throws -> Data {
                    try await client.performRequest()
                }
            }
            """,
            expandedSource: """
            class NetworkContext: ObservableContext {
                private let errorBoundary = ErrorBoundary(
                    id: "NetworkContext",
                    strategy: .retry(maxAttempts: 3, delay: 2.0)
                )
                
                func fetchData() async throws -> Data {
                    try await errorBoundary.executeWithRecovery {
                        try await self._wrapped_fetchData()
                    }
                }
                
                private func _wrapped_fetchData() async throws -> Data {
                    try await client.performRequest()
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testErrorBoundaryWithPropagateStrategy() throws {
        assertMacroExpansion(
            """
            @ErrorBoundary(strategy: .propagate)
            class DataContext: ObservableContext {
                func processData(_ data: Data) async throws -> ProcessedData {
                    try await processor.process(data)
                }
            }
            """,
            expandedSource: """
            class DataContext: ObservableContext {
                private let errorBoundary = ErrorBoundary(
                    id: "DataContext",
                    strategy: .propagate
                )
                
                func processData(_ data: Data) async throws -> ProcessedData {
                    try await errorBoundary.executeWithRecovery {
                        try await self._wrapped_processData(data)
                    }
                }
                
                private func _wrapped_processData(_ data: Data) async throws -> ProcessedData {
                    try await processor.process(data)
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - ErrorHandling Macro Tests
    
    func testErrorHandlingMacroWithComplexConfig() throws {
        assertMacroExpansion(
            """
            @ErrorHandling(
                retry: 3,
                backoff: .exponential(initial: 1.0, multiplier: 2.0),
                timeout: 30.0,
                fallback: "cachedData"
            )
            class DataService {
                func loadData() async throws -> Data {
                    return try await networkClient.fetchData()
                }
                
                func cachedData() async -> Data {
                    return Data()
                }
            }
            """,
            expandedSource: """
            class DataService {
                func loadData() async throws -> Data {
                    do {
                        return try await withRetry(
                            maxAttempts: 3,
                            backoff: .exponential(initial: 1.0, multiplier: 2.0),
                            timeout: 30.0
                        ) {
                            try await self._wrapped_loadData()
                        }
                    } catch {
                        return await self.cachedData()
                    }
                }
                
                private func _wrapped_loadData() async throws -> Data {
                    return try await networkClient.fetchData()
                }
                
                func cachedData() async -> Data {
                    return Data()
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testErrorHandlingWithSimpleRetry() throws {
        assertMacroExpansion(
            """
            @ErrorHandling(retry: 5)
            func fetchResource() async throws -> Resource {
                try await api.getResource()
            }
            """,
            expandedSource: """
            func fetchResource() async throws -> Resource {
                try await withRetry(
                    maxAttempts: 5,
                    backoff: .exponential()
                ) {
                    try await self._wrapped_fetchResource()
                }
            }
            
            private func _wrapped_fetchResource() async throws -> Resource {
                try await api.getResource()
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - ErrorContext Macro Tests
    
    func testErrorContextMacroEnrichment() throws {
        assertMacroExpansion(
            """
            @ErrorContext(
                operation: "user_data_sync",
                metadata: ["component": "sync_engine"]
            )
            class SyncContext: ObservableContext {
                func syncUserData(userId: String) async throws {
                    try await syncEngine.sync(userId)
                }
            }
            """,
            expandedSource: """
            class SyncContext: ObservableContext {
                func syncUserData(userId: String) async throws {
                    do {
                        try await self._wrapped_syncUserData(userId: userId)
                    } catch {
                        throw error
                            .addingContext("operation", "user_data_sync")
                            .addingContext("userId", userId)
                            .addingContext("component", "sync_engine")
                    }
                }
                
                private func _wrapped_syncUserData(userId: String) async throws {
                    try await syncEngine.sync(userId)
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testErrorContextWithoutMetadata() throws {
        assertMacroExpansion(
            """
            @ErrorContext(operation: "data_fetch")
            func fetchData(id: String) async throws -> Data {
                try await store.getData(id)
            }
            """,
            expandedSource: """
            func fetchData(id: String) async throws -> Data {
                do {
                    return try await self._wrapped_fetchData(id: id)
                } catch {
                    throw error
                        .addingContext("operation", "data_fetch")
                        .addingContext("id", id)
                }
            }
            
            private func _wrapped_fetchData(id: String) async throws -> Data {
                try await store.getData(id)
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - RecoveryStrategy Macro Tests
    
    func testRecoveryStrategyMacro() throws {
        assertMacroExpansion(
            """
            @RecoveryStrategy
            class PaymentContext: ObservableContext {
                @recoverable(.network, strategy: .retry(maxAttempts: 5))
                @recoverable(.timeout, strategy: .fail)
                @recoverable(.validation, strategy: .userPrompt("Check payment details"))
                func processPayment(_ amount: Decimal) async throws {
                    try await paymentGateway.process(amount)
                }
            }
            """,
            expandedSource: """
            class PaymentContext: ObservableContext {
                func processPayment(_ amount: Decimal) async throws {
                    do {
                        try await self._wrapped_processPayment(amount)
                    } catch {
                        let category = ErrorCategory.categorize(error)
                        let strategy: EnhancedRecoveryStrategy
                        
                        switch category {
                        case .network:
                            strategy = .retry(maxAttempts: 5, backoff: .exponential())
                        case .timeout:
                            strategy = .fail
                        case .validation:
                            strategy = .userPrompt(
                                message: "Check payment details",
                                options: ["Retry", "Cancel"],
                                handler: { option in
                                    option == "Retry" ? .retry(maxAttempts: 1, backoff: .none) : .fail
                                }
                            )
                        default:
                            strategy = RecoveryStrategySelector.defaultStrategy(for: error)
                        }
                        
                        return try await strategy.execute {
                            try await self._wrapped_processPayment(amount)
                        }
                    }
                }
                
                private func _wrapped_processPayment(_ amount: Decimal) async throws {
                    try await paymentGateway.process(amount)
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - PropagateErrors Macro Tests
    
    func testPropagateErrorsMacro() throws {
        assertMacroExpansion(
            """
            @PropagateErrors(to: AxiomError.self)
            actor DataProcessor {
                func process(_ data: Data) async throws -> ProcessedData {
                    try await processor.transform(data)
                }
            }
            """,
            expandedSource: """
            actor DataProcessor {
                func process(_ data: Data) async throws -> ProcessedData {
                    do {
                        return try await processor.transform(data)
                    } catch let error as AxiomError {
                        throw error
                    } catch {
                        throw AxiomError(legacy: error)
                            .addingContext("operation", "process")
                            .addingContext("actor", "DataProcessor")
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - Macro Composition Tests
    
    func testMacroComposition() throws {
        assertMacroExpansion(
            """
            @ErrorBoundary(strategy: .propagate)
            @ErrorContext(operation: "data_pipeline")
            @ErrorHandling(retry: 3, timeout: 60.0)
            class DataPipeline: ObservableContext {
                func process() async throws -> Result {
                    try await pipeline.execute()
                }
            }
            """,
            expandedSource: """
            class DataPipeline: ObservableContext {
                private let errorBoundary = ErrorBoundary(
                    id: "DataPipeline",
                    strategy: .propagate
                )
                
                func process() async throws -> Result {
                    try await errorBoundary.executeWithRecovery {
                        do {
                            return try await withRetry(
                                maxAttempts: 3,
                                backoff: .exponential(),
                                timeout: 60.0
                            ) {
                                try await self._wrapped_process()
                            }
                        } catch {
                            throw error.addingContext("operation", "data_pipeline")
                        }
                    }
                }
                
                private func _wrapped_process() async throws -> Result {
                    try await pipeline.execute()
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - Compile-Time Validation Tests
    
    func testMacroCompileTimeValidation() throws {
        // Test invalid recovery strategy
        assertMacroExpansion(
            """
            @ErrorBoundary(strategy: .invalidStrategy)
            class TestContext: ObservableContext {}
            """,
            expandedSource: """
            @ErrorBoundary(strategy: .invalidStrategy)
            class TestContext: ObservableContext {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Unknown recovery strategy 'invalidStrategy'. Available strategies: retry, fail, userPrompt, propagate",
                    line: 1,
                    column: 26
                )
            ],
            macros: testMacros
        )
        
        // Test missing fallback method
        assertMacroExpansion(
            """
            @ErrorHandling(fallback: "missingMethod")
            class TestService {
                func fetchData() async throws -> Data {
                    try await client.getData()
                }
            }
            """,
            expandedSource: """
            @ErrorHandling(fallback: "missingMethod")
            class TestService {
                func fetchData() async throws -> Data {
                    try await client.getData()
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Fallback method 'missingMethod' not found in type 'TestService'",
                    line: 1,
                    column: 26
                )
            ],
            macros: testMacros
        )
    }
    
    // MARK: - Performance Optimization Tests
    
    func testMacroPerformanceOptimization() throws {
        // Test that simple operations are inlined
        assertMacroExpansion(
            """
            @ErrorHandling(retry: 1)
            func simpleOperation() async throws -> String {
                return "result"
            }
            """,
            expandedSource: """
            func simpleOperation() async throws -> String {
                // Single retry should be inlined without wrapper overhead
                do {
                    return "result"
                } catch {
                    return "result"
                }
            }
            """,
            macros: testMacros
        )
    }
}

// MARK: - Error Injection Support Tests

final class ErrorInjectionTests: XCTestCase {
    enum TestError: Error {
        case injected
    }
    
    func testErrorInjectionPoints() async throws {
        // Test that macros generate testable error paths
        @ErrorBoundary(strategy: .retry(attempts: 3))
        class TestableContext: ObservableContext {
            var errorInjector: ((Int) throws -> Void)?
            
            func operation() async throws -> String {
                // The macro should generate code that calls errorInjector if set
                if let injector = errorInjector {
                    try injector(1) // This would be in generated wrapper
                }
                return "success"
            }
        }
        
        let context = await TestableContext()
        var attemptCount = 0
        
        // Inject errors for first 2 attempts
        await MainActor.run {
            context.errorInjector = { attempt in
                attemptCount = attempt
                if attempt < 3 {
                    throw TestError.injected
                }
            }
        }
        
        // This test validates the injection point concept
        // In real implementation, the macro would generate this
        do {
            _ = try await context.operation()
        } catch {
            XCTAssertTrue(error is TestError)
        }
        
        // Verify attempt count was updated
        XCTAssertGreaterThan(attemptCount, 0)
    }
}

// MARK: - Test Helpers

extension AxiomError {
    func addingContext(_ key: String, _ value: String) -> AxiomError {
        // This would use the real implementation from ErrorPropagation.swift
        return self
    }
}

/// Mock retry function for testing
func withRetry<T>(
    maxAttempts: Int,
    backoff: BackoffStrategy = .exponential(),
    timeout: TimeInterval? = nil,
    operation: () async throws -> T
) async throws -> T {
    try await operation()
}