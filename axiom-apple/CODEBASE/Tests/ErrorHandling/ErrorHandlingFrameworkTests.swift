import XCTest
import SwiftUI
@testable import Axiom
@testable import AxiomTesting

/// Comprehensive tests for Error Handling framework functionality
/// Tests error boundaries, propagation, recovery strategies, and isolation using AxiomTesting framework
final class ErrorHandlingFrameworkTests: XCTestCase {
    
    // MARK: - Test Environment
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Error Boundary Tests
    
    func testErrorBoundariesCaptureUnhandledErrors() async throws {
        try await testEnvironment.runTest { env in
            let errorHandler = TestErrorHandler()
            let client = try await env.createClient(
                ErrorTestClient.self,
                id: "error-client"
            ) {
                ErrorTestClient(id: "error-client")
            }
            
            let context = try await env.createContext(
                ErrorTestContext.self,
                id: "error-context"
            ) {
                ErrorTestContext(errorHandler: errorHandler)
            }
            
            // Attach client to context for error boundary
            await context.attachClient(client)
            
            // Client throws an error
            let testError = TestFrameworkError.operationFailed("Test operation failed")
            await client.performFailingOperation(error: testError)
            
            // Assert error was captured by context
            try await TestHelpers.context.assertState(
                in: context,
                timeout: .seconds(1),
                condition: { _ in
                    errorHandler.capturedErrors.count == 1 &&
                    (errorHandler.capturedErrors.first as? TestFrameworkError) == testError
                },
                description: "Context should capture client errors"
            )
            
            // Verify error source tracking
            XCTAssertEqual(errorHandler.errorSource, "error-client")
        }
    }
    
    func testAllErrorTypesArePropagatedToContext() async throws {
        try await testEnvironment.runTest { env in
            let errorHandler = TestErrorHandler()
            let client = try await env.createClient(
                ErrorTestClient.self,
                id: "multi-error-client"
            ) {
                ErrorTestClient(id: "multi-error-client")
            }
            
            let context = try await env.createContext(
                ErrorTestContext.self,
                id: "multi-error-context"
            ) {
                ErrorTestContext(errorHandler: errorHandler)
            }
            
            await context.attachClient(client)
            
            // Test different error types using framework utilities
            let errors: [Error] = [
                TestFrameworkError.operationFailed("Operation 1"),
                TestFrameworkError.invalidInput("Bad input"),
                TestFrameworkError.networkError(code: 500),
                CustomTestError(message: "Custom error"),
                NSError(domain: "TestDomain", code: 42, userInfo: nil)
            ]
            
            // Client throws multiple error types concurrently
            await withTaskGroup(of: Void.self) { group in
                for error in errors {
                    group.addTask {
                        await client.performFailingOperation(error: error)
                    }
                }
            }
            
            // All errors should be captured
            try await TestHelpers.context.assertState(
                in: context,
                timeout: .seconds(2),
                condition: { _ in errorHandler.capturedErrors.count == errors.count },
                description: "All error types should be captured"
            )
            
            // Verify each error type was captured
            XCTAssertTrue(errorHandler.capturedErrors.contains { $0 is TestFrameworkError })
            XCTAssertTrue(errorHandler.capturedErrors.contains { $0 is CustomTestError })
            XCTAssertTrue(errorHandler.capturedErrors.contains { $0 is NSError })
        }
    }
    
    func testErrorBoundaryIsolationBetweenContexts() async throws {
        try await testEnvironment.runTest { env in
            let errorHandler1 = TestErrorHandler()
            let errorHandler2 = TestErrorHandler()
            
            let client1 = try await env.createClient(
                ErrorTestClient.self,
                id: "client-1"
            ) {
                ErrorTestClient(id: "client-1")
            }
            
            let client2 = try await env.createClient(
                ErrorTestClient.self,
                id: "client-2"
            ) {
                ErrorTestClient(id: "client-2")
            }
            
            let context1 = try await env.createContext(
                ErrorTestContext.self,
                id: "context-1"
            ) {
                ErrorTestContext(errorHandler: errorHandler1)
            }
            
            let context2 = try await env.createContext(
                ErrorTestContext.self,
                id: "context-2"
            ) {
                ErrorTestContext(errorHandler: errorHandler2)
            }
            
            await context1.attachClient(client1)
            await context2.attachClient(client2)
            
            // Each client throws different errors
            await client1.performFailingOperation(error: TestFrameworkError.operationFailed("Error 1"))
            await client2.performFailingOperation(error: TestFrameworkError.invalidInput("Error 2"))
            
            // Each context should only capture its client's errors
            try await TestHelpers.context.assertState(
                in: context1,
                condition: { _ in errorHandler1.capturedErrors.count == 1 },
                description: "Context 1 should only capture client 1 errors"
            )
            
            try await TestHelpers.context.assertState(
                in: context2,
                condition: { _ in errorHandler2.capturedErrors.count == 1 },
                description: "Context 2 should only capture client 2 errors"
            )
            
            // Verify error isolation
            XCTAssertTrue(errorHandler1.capturedErrors.first is TestFrameworkError)
            XCTAssertTrue(errorHandler2.capturedErrors.first is TestFrameworkError)
            
            if case .operationFailed = errorHandler1.capturedErrors.first as? TestFrameworkError {
                // Expected
            } else {
                XCTFail("Context 1 should have operation failed error")
            }
            
            if case .invalidInput = errorHandler2.capturedErrors.first as? TestFrameworkError {
                // Expected
            } else {
                XCTFail("Context 2 should have invalid input error")
            }
        }
    }
    
    // MARK: - Error Recovery Strategy Tests
    
    func testErrorRecoveryStrategies() async throws {
        try await testEnvironment.runTest { env in
            let errorHandler = TestErrorHandler()
            let client = try await env.createClient(
                ErrorTestClient.self,
                id: "recovery-client"
            ) {
                ErrorTestClient(id: "recovery-client")
            }
            
            let context = try await env.createContext(
                ErrorTestContext.self,
                id: "recovery-context"
            ) {
                ErrorTestContext(errorHandler: errorHandler)
            }
            
            await context.attachClient(client)
            
            // Configure recovery strategies using framework utilities
            errorHandler.setRecoveryStrategy(for: TestFrameworkError.self) { error in
                if case .networkError(let code) = error as? TestFrameworkError {
                    return code < 500 ? .retry(maxAttempts: 3) : .fail
                }
                return .log()
            }
            
            // Test recoverable error (should retry)
            await client.performFailingOperation(error: TestFrameworkError.networkError(code: 429))
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { _ in
                    errorHandler.lastRecoveryAction == .retry(maxAttempts: 3)
                },
                description: "Recoverable errors should trigger retry strategy"
            )
            
            // Test non-recoverable error (should fail)
            await client.performFailingOperation(error: TestFrameworkError.networkError(code: 500))
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { _ in
                    errorHandler.lastRecoveryAction == .fail
                },
                description: "Non-recoverable errors should trigger fail strategy"
            )
            
            // Test default recovery (should log)
            await client.performFailingOperation(error: TestFrameworkError.operationFailed("Default"))
            
            try await TestHelpers.context.assertState(
                in: context,
                condition: { _ in
                    errorHandler.lastRecoveryAction == .log()
                },
                description: "Default errors should trigger log strategy"
            )
        }
    }
    
    func testErrorRecoveryStrategyPerformance() async throws {
        try await testEnvironment.runTest { env in
            // Test performance of error recovery under load
            try await TestHelpers.performance.assertPerformanceRequirements(
                operation: {
                    let errorHandler = TestErrorHandler()
                    let client = ErrorTestClient(id: "perf-client")
                    let context = ErrorTestContext(errorHandler: errorHandler)
                    
                    // Configure fast recovery strategy
                    errorHandler.setRecoveryStrategy(for: TestFrameworkError.self) { _ in .log() }
                    
                    await context.attachClient(client)
                    
                    // Process many errors quickly
                    await withTaskGroup(of: Void.self) { group in
                        for i in 0..<100 {
                            group.addTask {
                                await client.performFailingOperation(
                                    error: TestFrameworkError.operationFailed("Error \(i)")
                                )
                            }
                        }
                    }
                    
                    // Verify all errors were processed
                    XCTAssertEqual(errorHandler.capturedErrors.count, 100)
                },
                maxDuration: .milliseconds(500), // Should process quickly
                maxMemoryGrowth: 5 * 1024, // 5KB max growth
                iterations: 1
            )
        }
    }
    
    // MARK: - Concurrent Error Handling Tests
    
    func testMultipleClientsWithSingleContextErrorHandling() async throws {
        try await testEnvironment.runTest { env in
            let errorHandler = TestErrorHandler()
            let context = try await env.createContext(
                ErrorTestContext.self,
                id: "multi-client-context"
            ) {
                ErrorTestContext(errorHandler: errorHandler)
            }
            
            // Create multiple clients using framework utilities
            let clients = try await withTaskGroup(of: ErrorTestClient.self) { group in
                var clients: [ErrorTestClient] = []
                for i in 0..<5 {
                    group.addTask {
                        await env.createClient(
                            ErrorTestClient.self,
                            id: "client-\(i)"
                        ) {
                            ErrorTestClient(id: "client-\(i)")
                        }
                    }
                }
                
                for await client in group {
                    clients.append(client)
                }
                return clients
            }
            
            // Attach all clients to context
            for client in clients {
                await context.attachClient(client)
            }
            
            // Each client throws an error concurrently
            await withTaskGroup(of: Void.self) { group in
                for (index, client) in clients.enumerated() {
                    group.addTask {
                        await client.performFailingOperation(
                            error: TestFrameworkError.operationFailed("Error from client \(index)")
                        )
                    }
                }
            }
            
            // Context should capture all errors
            try await TestHelpers.context.assertState(
                in: context,
                timeout: .seconds(2),
                condition: { _ in errorHandler.capturedErrors.count == clients.count },
                description: "Context should capture errors from all clients"
            )
            
            // Verify all client sources are tracked
            let expectedSources = clients.compactMap { await $0.id }.sorted()
            XCTAssertEqual(errorHandler.errorSources.sorted(), expectedSources)
        }
    }
    
    func testErrorBoundaryMemoryManagement() async throws {
        try await testEnvironment.runTest { env in
            // Test memory management of error boundaries under stress
            try await TestHelpers.context.assertNoMemoryLeaks {
                let errorHandler = TestErrorHandler()
                
                var context: ErrorTestContext? = ErrorTestContext(errorHandler: errorHandler)
                var client: ErrorTestClient? = ErrorTestClient(id: "memory-client")
                
                await context?.attachClient(client!)
                
                // Generate many errors
                for i in 0..<50 {
                    await client?.performFailingOperation(
                        error: TestFrameworkError.operationFailed("Memory test \(i)")
                    )
                }
                
                // Verify errors were captured
                XCTAssertEqual(errorHandler.capturedErrors.count, 50)
                
                // Clean up references
                client = nil
                context = nil
                
                // Allow cleanup
                try await Task.sleep(for: .milliseconds(50))
            }
        }
    }
    
    // MARK: - Error Propagation Chain Tests
    
    func testErrorPropagationChain() async throws {
        try await testEnvironment.runTest { env in
            let rootHandler = TestErrorHandler()
            let childHandler = TestErrorHandler()
            
            let rootContext = try await env.createContext(
                ErrorTestContext.self,
                id: "root-context"
            ) {
                ErrorTestContext(errorHandler: rootHandler)
            }
            
            let childContext = try await env.createContext(
                ErrorTestContext.self,
                id: "child-context"
            ) {
                ErrorTestContext(errorHandler: childHandler, parent: rootContext)
            }
            
            let client = try await env.createClient(
                ErrorTestClient.self,
                id: "chain-client"
            ) {
                ErrorTestClient(id: "chain-client")
            }
            
            // Establish parent-child relationship
            try await TestHelpers.context.establishParentChild(
                parent: rootContext,
                child: childContext
            )
            
            await childContext.attachClient(client)
            
            // Configure child to propagate unhandled errors to parent
            childHandler.shouldPropagateToParent = true
            
            // Client throws an error
            await client.performFailingOperation(
                error: TestFrameworkError.operationFailed("Chain propagation test")
            )
            
            // Child should capture error first
            try await TestHelpers.context.assertState(
                in: childContext,
                condition: { _ in childHandler.capturedErrors.count == 1 },
                description: "Child context should capture error first"
            )
            
            // Error should propagate to parent if unhandled
            try await TestHelpers.context.assertState(
                in: rootContext,
                timeout: .seconds(1),
                condition: { _ in rootHandler.capturedErrors.count == 1 },
                description: "Error should propagate to parent context"
            )
        }
    }
    
    // MARK: - Framework Compliance Tests
    
    func testErrorHandlingFrameworkCompliance() async throws {
        let errorHandler = TestErrorHandler()
        let client = ErrorTestClient(id: "compliance-client")
        let context = ErrorTestContext(errorHandler: errorHandler)
        
        // Use framework compliance testing
        assertFrameworkCompliance(errorHandler)
        assertFrameworkCompliance(client)
        assertFrameworkCompliance(context)
        
        // Error handling specific compliance
        XCTAssertTrue(errorHandler is ErrorHandler, "Must implement ErrorHandler protocol")
        XCTAssertTrue(client is Client, "Must implement Client protocol")
        XCTAssertTrue(context is Context, "Must implement Context protocol")
    }
}

// MARK: - Test Support Types

// Test Error Types
enum TestFrameworkError: Error, Equatable {
    case operationFailed(String)
    case invalidInput(String)
    case networkError(code: Int)
    case timeoutError(duration: TimeInterval)
    case authenticationFailed
}

struct CustomTestError: Error, Equatable {
    let message: String
}

// Error Recovery Strategies
enum RecoveryStrategy: Equatable {
    case log()
    case retry(maxAttempts: Int = 1)
    case fail
    case ignore
}

// Error Handler Protocol
protocol ErrorHandler: AnyObject {
    func processError(_ error: Error, from source: String)
    func captureError(_ error: Error, from source: String)
}

// Test Error Handler Implementation
@MainActor
class TestErrorHandler: ErrorHandler {
    private(set) var capturedErrors: [Error] = []
    private(set) var errorSource: String?
    private(set) var errorSources: [String] = []
    private(set) var captureTaskId: UInt8?
    private(set) var lastRecoveryAction: RecoveryStrategy?
    
    var shouldPropagateToParent: Bool = false
    private var recoveryStrategies: [String: (Error) -> RecoveryStrategy] = [:]
    
    func processError(_ error: Error, from source: String) {
        captureError(error, from: source)
    }
    
    func captureError(_ error: Error, from source: String) {
        capturedErrors.append(error)
        errorSource = source
        if !errorSources.contains(source) {
            errorSources.append(source)
        }
        captureTaskId = Task.currentPriority?.rawValue
        
        // Apply recovery strategy
        let strategy = recoveryStrategies[String(describing: type(of: error))]
        lastRecoveryAction = strategy?(error) ?? .log()
    }
    
    func setRecoveryStrategy<E: Error>(for errorType: E.Type, strategy: @escaping (Error) -> RecoveryStrategy) {
        recoveryStrategies[String(describing: errorType)] = strategy
    }
    
    func clearErrors() {
        capturedErrors.removeAll()
        errorSources.removeAll()
        errorSource = nil
        captureTaskId = nil
        lastRecoveryAction = nil
    }
}

// Error Propagating Client
actor ErrorTestClient: Client {
    typealias StateType = ErrorTestState
    typealias ActionType = ErrorTestAction
    
    let id: String
    private(set) var currentState = ErrorTestState()
    private let stream: AsyncStream<ErrorTestState>
    private let continuation: AsyncStream<ErrorTestState>.Continuation
    
    var stateStream: AsyncStream<ErrorTestState> {
        stream
    }
    
    init(id: String) {
        self.id = id
        (stream, continuation) = AsyncStream.makeStream(of: ErrorTestState.self)
        continuation.yield(currentState)
    }
    
    func performFailingOperation(error: Error) async {
        // Simulate error propagation to context
        currentState = ErrorTestState(
            lastError: error,
            errorCount: currentState.errorCount + 1
        )
        continuation.yield(currentState)
    }
    
    func process(_ action: ErrorTestAction) async throws {
        switch action {
        case .simulateError(let error):
            throw error
        case .reset:
            currentState = ErrorTestState()
            continuation.yield(currentState)
        }
    }
    
    deinit {
        continuation.finish()
    }
}

// Test State for Error Client
struct ErrorTestState: State, Sendable {
    let lastError: Error?
    let errorCount: Int
    
    init(lastError: Error? = nil, errorCount: Int = 0) {
        self.lastError = lastError
        self.errorCount = errorCount
    }
}

// Test Actions for Error Client
enum ErrorTestAction: Equatable {
    case simulateError(TestFrameworkError)
    case reset
}

// Error Boundary Context
@MainActor
class ErrorTestContext: ObservableContext {
    private let errorHandler: TestErrorHandler
    private var attachedClients: [ErrorTestClient] = []
    private weak var parentContext: ErrorTestContext?
    
    init(errorHandler: TestErrorHandler, parent: ErrorTestContext? = nil) {
        self.errorHandler = errorHandler
        self.parentContext = parent
        super.init()
    }
    
    func attachClient(_ client: ErrorTestClient) async {
        attachedClients.append(client)
        let clientId = await client.id
        
        // Simulate error boundary by observing client state
        Task { [weak self] in
            for await state in await client.stateStream {
                if let error = state.lastError {
                    await MainActor.run {
                        self?.errorHandler.captureError(error, from: clientId)
                        
                        // Propagate to parent if configured
                        if let shouldPropagate = self?.errorHandler.shouldPropagateToParent,
                           shouldPropagate,
                           let parent = self?.parentContext {
                            parent.errorHandler.captureError(error, from: clientId)
                        }
                    }
                }
            }
        }
    }
    
    func getAttachedClients() -> [ErrorTestClient] {
        return attachedClients
    }
    
    override func performDisappearance() async {
        await super.performDisappearance()
        attachedClients.removeAll()
    }
}

// MARK: - Framework Extensions

extension TestFrameworkError: CustomStringConvertible {
    var description: String {
        switch self {
        case .operationFailed(let message):
            return "Operation Failed: \(message)"
        case .invalidInput(let message):
            return "Invalid Input: \(message)"
        case .networkError(let code):
            return "Network Error: \(code)"
        case .timeoutError(let duration):
            return "Timeout Error: \(duration)s"
        case .authenticationFailed:
            return "Authentication Failed"
        }
    }
}

extension TestHelpers {
    struct ErrorHandling {
        /// Assert that an error boundary captures the expected error
        static func assertErrorCaptured<E: Error & Equatable>(
            by handler: TestErrorHandler,
            error: E,
            from source: String,
            timeout: Duration = .seconds(1),
            file: StaticString = #file,
            line: UInt = #line
        ) async throws {
            let startTime = Date()
            
            while Date().timeIntervalSince(startTime) < timeout.timeInterval {
                if handler.capturedErrors.contains(where: { ($0 as? E) == error }) &&
                   handler.errorSource == source {
                    return
                }
                try await Task.sleep(for: .milliseconds(10))
            }
            
            XCTFail(
                "Error \(error) from source \(source) was not captured within \(timeout)",
                file: file,
                line: line
            )
        }
        
        /// Assert that error recovery strategy is applied correctly
        static func assertRecoveryStrategy(
            handler: TestErrorHandler,
            expectedStrategy: RecoveryStrategy,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            XCTAssertEqual(
                handler.lastRecoveryAction,
                expectedStrategy,
                "Recovery strategy should match expected",
                file: file,
                line: line
            )
        }
    }
}

extension TestHelpers {
    static let errorHandling = ErrorHandling.self
}

// Helper Extensions
private extension Duration {
    var timeInterval: TimeInterval {
        Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
    }
}

private extension Array {
    func appending(_ element: Element) -> [Element] {
        var copy = self
        copy.append(element)
        return copy
    }
}