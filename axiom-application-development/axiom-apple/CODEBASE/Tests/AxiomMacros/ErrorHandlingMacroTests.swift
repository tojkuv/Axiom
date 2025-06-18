import XCTest
import AxiomTesting
@testable import AxiomMacros
@testable import AxiomCore
import SwiftSyntaxMacrosTestSupport

/// Comprehensive tests for AxiomMacros error handling macro functionality
final class ErrorHandlingMacroTests: XCTestCase {
    
    // MARK: - Basic Error Handling Macro Tests
    
    func testErrorHandlingMacroOnClass() throws {
        assertMacroExpansion(
            """
            @AxiomErrorHandling
            class DataService {
                func fetchData() async throws -> String {
                    // Implementation
                    return "data"
                }
            }
            """,
            expandedSource: """
            class DataService {
                func fetchData() async throws -> String {
                    // Implementation
                    return "data"
                }
            }
            
            extension DataService: ErrorBoundaryManaged {
                func handle(_ error: Error) async {
                    // Auto-generated error handling
                    if let axiomError = error as? AxiomError {
                        await handleAxiomError(axiomError)
                    } else {
                        await handleGenericError(error)
                    }
                }
                
                func executeWithRecovery<T: Sendable>(
                    _ operation: @Sendable () async throws -> T,
                    maxRetries: Int? = nil,
                    strategy: ErrorRecoveryStrategy = .propagate
                ) async throws -> T {
                    let maxAttempts = maxRetries ?? strategy.defaultRetryCount
                    var lastError: Error?
                    
                    for attempt in 1...maxAttempts {
                        do {
                            return try await operation()
                        } catch {
                            lastError = error
                            await handle(error)
                            
                            if attempt == maxAttempts || !canRecover(from: error) {
                                throw error
                            }
                            
                            await Task.sleep(for: .milliseconds(100 * attempt))
                        }
                    }
                    
                    throw lastError ?? AxiomError.unknownError
                }
                
                func canRecover(from error: Error) -> Bool {
                    guard let axiomError = error as? AxiomError else {
                        return false
                    }
                    
                    switch axiomError.recoveryStrategy {
                    case .retry:
                        return true
                    case .propagate, .silent, .userPrompt:
                        return false
                    }
                }
                
                private func handleAxiomError(_ error: AxiomError) async {
                    // Specific handling for AxiomError
                    switch error.recoveryStrategy {
                    case .retry:
                        // Log retry attempt
                        break
                    case .userPrompt(let message):
                        // Handle user prompt
                        break
                    case .silent:
                        // Silent handling
                        break
                    case .propagate:
                        // Propagate error
                        break
                    }
                }
                
                private func handleGenericError(_ error: Error) async {
                    // Generic error handling
                    print("Unhandled error: \\(error)")
                }
            }
            """,
            macros: ["AxiomErrorHandling": ErrorHandlingMacro.self]
        )
    }
    
    func testErrorHandlingMacroOnActor() throws {
        assertMacroExpansion(
            """
            @AxiomErrorHandling
            actor NetworkService {
                func upload(data: Data) async throws -> String {
                    // Implementation
                    return "success"
                }
            }
            """,
            expandedSource: """
            actor NetworkService {
                func upload(data: Data) async throws -> String {
                    // Implementation
                    return "success"
                }
            }
            
            extension NetworkService: ErrorBoundaryManaged {
                func handle(_ error: Error) async {
                    // Actor-specific error handling
                    if let axiomError = error as? AxiomError {
                        await handleAxiomError(axiomError)
                    } else {
                        await handleGenericError(error)
                    }
                }
                
                func executeWithRecovery<T: Sendable>(
                    _ operation: @Sendable () async throws -> T,
                    maxRetries: Int? = nil,
                    strategy: ErrorRecoveryStrategy = .propagate
                ) async throws -> T {
                    let maxAttempts = maxRetries ?? strategy.defaultRetryCount
                    var lastError: Error?
                    
                    for attempt in 1...maxAttempts {
                        do {
                            return try await operation()
                        } catch {
                            lastError = error
                            await handle(error)
                            
                            if attempt == maxAttempts || !canRecover(from: error) {
                                throw error
                            }
                            
                            // Actor-specific retry delay
                            try? await Task.sleep(for: .milliseconds(200 * attempt))
                        }
                    }
                    
                    throw lastError ?? AxiomError.unknownError
                }
                
                func canRecover(from error: Error) -> Bool {
                    guard let axiomError = error as? AxiomError else {
                        return false
                    }
                    
                    // Actor-specific recovery logic
                    switch axiomError {
                    case .networkError:
                        return true
                    case .clientError(.timeout):
                        return true
                    default:
                        return axiomError.recoveryStrategy.allowsRetry
                    }
                }
                
                private func handleAxiomError(_ error: AxiomError) async {
                    // Actor-specific AxiomError handling
                }
                
                private func handleGenericError(_ error: Error) async {
                    // Actor-specific generic error handling
                }
            }
            """,
            macros: ["AxiomErrorHandling": ErrorHandlingMacro.self]
        )
    }
    
    // MARK: - Error Boundary Context Tests
    
    func testErrorBoundaryContextMacro() throws {
        assertMacroExpansion(
            """
            @AxiomErrorContext(operation: "user_registration")
            class UserRegistrationService {
                func registerUser(_ email: String) async throws -> User {
                    // Implementation
                    return User(email: email)
                }
            }
            """,
            expandedSource: """
            class UserRegistrationService {
                func registerUser(_ email: String) async throws -> User {
                    // Implementation
                    return User(email: email)
                }
            }
            
            extension UserRegistrationService {
                func executeWithContext<T: Sendable>(
                    _ operation: @Sendable () async throws -> T
                ) async throws -> T {
                    let context = ErrorContext(
                        userAction: "user_registration",
                        feature: "registration",
                        operationId: UUID().uuidString,
                        metadata: [
                            "service": "UserRegistrationService",
                            "timestamp": ISO8601DateFormatter().string(from: Date())
                        ]
                    )
                    
                    do {
                        return try await operation()
                    } catch {
                        // Enhanced error with context
                        await logErrorWithContext(error, context: context)
                        throw error
                    }
                }
                
                private func logErrorWithContext(_ error: Error, context: ErrorContext) async {
                    // Context-aware error logging
                    let errorMessage = await UserErrorMessageService().getUserFriendlyMessage(
                        for: error as? AxiomError ?? .unknownError,
                        context: context
                    )
                    
                    print("Error in \\(context.userAction ?? "unknown"): \\(errorMessage.description)")
                }
            }
            """,
            macros: ["AxiomErrorContext": ErrorContextMacro.self]
        )
    }
    
    // MARK: - Error Propagation Tests
    
    func testPropagateErrorsMacro() throws {
        assertMacroExpansion(
            """
            @PropagateErrors(to: ErrorHandlingService.self)
            actor DataProcessor {
                func processData(_ data: Data) async throws -> ProcessedData {
                    // Implementation
                    return ProcessedData()
                }
            }
            """,
            expandedSource: """
            actor DataProcessor {
                func processData(_ data: Data) async throws -> ProcessedData {
                    // Implementation
                    return ProcessedData()
                }
            }
            
            extension DataProcessor {
                private func propagateError(_ error: Error, from function: String) async {
                    let errorDetails = ErrorPropagationDetails(
                        sourceActor: "DataProcessor",
                        function: function,
                        error: error,
                        timestamp: Date()
                    )
                    
                    await ErrorHandlingService.shared.receiveError(errorDetails)
                }
                
                func processDataWithErrorPropagation(_ data: Data) async throws -> ProcessedData {
                    do {
                        return try await processData(data)
                    } catch {
                        await propagateError(error, from: "processData")
                        throw error
                    }
                }
            }
            """,
            macros: ["PropagateErrors": PropagateErrorsMacro.self]
        )
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingMacroErrorOnStruct() throws {
        XCTAssertThrowsError(
            try ErrorHandlingMacro.expansion(
                of: AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("AxiomErrorHandling"))
                ),
                attachedTo: StructDeclSyntax(
                    name: .identifier("TestStruct"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                providingExtensionsOf: IdentifierTypeSyntax(name: .identifier("TestStruct")),
                conformingTo: [],
                in: TestMacroExpansionContext()
            )
        ) { error in
            XCTAssertTrue(error is ErrorHandlingMacroError)
        }
    }
    
    func testErrorHandlingMacroErrorOnEnum() throws {
        XCTAssertThrowsError(
            try ErrorHandlingMacro.expansion(
                of: AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("AxiomErrorHandling"))
                ),
                attachedTo: EnumDeclSyntax(
                    name: .identifier("TestEnum"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                providingExtensionsOf: IdentifierTypeSyntax(name: .identifier("TestEnum")),
                conformingTo: [],
                in: TestMacroExpansionContext()
            )
        ) { error in
            XCTAssertTrue(error is ErrorHandlingMacroError)
        }
    }
    
    // MARK: - Recovery Strategy Tests
    
    func testRecoveryStrategyMacro() throws {
        assertMacroExpansion(
            """
            @RecoveryStrategy(.retry(attempts: 3))
            class FileUploadService {
                func uploadFile(_ file: URL) async throws -> String {
                    // Implementation
                    return "uploaded"
                }
            }
            """,
            expandedSource: """
            class FileUploadService {
                func uploadFile(_ file: URL) async throws -> String {
                    // Implementation
                    return "uploaded"
                }
            }
            
            extension FileUploadService {
                var defaultRecoveryStrategy: ErrorRecoveryStrategy {
                    return .retry(attempts: 3)
                }
                
                func executeWithDefaultRecovery<T: Sendable>(
                    _ operation: @Sendable () async throws -> T
                ) async throws -> T {
                    return try await executeWithRecovery(operation, strategy: defaultRecoveryStrategy)
                }
                
                func executeWithRecovery<T: Sendable>(
                    _ operation: @Sendable () async throws -> T,
                    strategy: ErrorRecoveryStrategy
                ) async throws -> T {
                    switch strategy {
                    case .retry(let attempts):
                        return try await executeWithRetry(operation, maxAttempts: attempts)
                    case .propagate:
                        return try await operation()
                    case .silent:
                        do {
                            return try await operation()
                        } catch {
                            // Silent failure - provide default value or rethrow
                            throw error
                        }
                    case .userPrompt(let message):
                        // Handle user prompt scenario
                        return try await operation()
                    }
                }
                
                private func executeWithRetry<T: Sendable>(
                    _ operation: @Sendable () async throws -> T,
                    maxAttempts: Int
                ) async throws -> T {
                    var lastError: Error?
                    
                    for attempt in 1...maxAttempts {
                        do {
                            return try await operation()
                        } catch {
                            lastError = error
                            
                            if attempt == maxAttempts {
                                throw error
                            }
                            
                            // Exponential backoff
                            let delay = min(1000 * Int(pow(2.0, Double(attempt - 1))), 30000)
                            try? await Task.sleep(for: .milliseconds(delay))
                        }
                    }
                    
                    throw lastError ?? AxiomError.unknownError
                }
            }
            """,
            macros: ["RecoveryStrategy": RecoveryStrategyMacro.self]
        )
    }
    
    // MARK: - Performance Tests
    
    func testErrorHandlingMacroPerformance() throws {
        let iterations = 25
        let expectation = self.expectation(description: "Error handling macro expansion performance")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            for _ in 0..<iterations {
                _ = try? ErrorHandlingMacro.expansion(
                    of: AttributeSyntax(
                        attributeName: IdentifierTypeSyntax(name: .identifier("AxiomErrorHandling"))
                    ),
                    attachedTo: ClassDeclSyntax(
                        name: .identifier("TestService"),
                        memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                    ),
                    providingExtensionsOf: IdentifierTypeSyntax(name: .identifier("TestService")),
                    conformingTo: [],
                    in: TestMacroExpansionContext()
                )
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let averageTime = (endTime - startTime) / Double(iterations)
            
            XCTAssertLessThan(averageTime, 0.005, "Error handling macro expansion should be fast (< 5ms per expansion)")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
}

// MARK: - Test Helper

/// Test macro expansion context for error handling testing
class TestMacroExpansionContext: MacroExpansionContext {
    func makeUniqueName(_ name: String) -> TokenSyntax {
        return TokenSyntax(.identifier("\\(name)_\\(UUID().uuidString.prefix(8))"), presence: .present)
    }
    
    func diagnose(_ diagnostic: Diagnostic) {
        // Handle diagnostics in tests
    }
}

// MARK: - ErrorHandlingMacroError for Testing

enum ErrorHandlingMacroError: Error, LocalizedError, Equatable {
    case mustBeAppliedToClassOrActor
    case invalidRecoveryStrategy(String)
    case missingTargetType
    case invalidParameter(String)
    
    var errorDescription: String? {
        switch self {
        case .mustBeAppliedToClassOrActor:
            return "ErrorHandlingMacro can only be applied to class or actor declarations"
        case .invalidRecoveryStrategy(let strategy):
            return "Invalid recovery strategy: \\(strategy)"
        case .missingTargetType:
            return "Missing target type for error propagation"
        case .invalidParameter(let param):
            return "Invalid parameter: \\(param)"
        }
    }
}

// MARK: - Additional Test Types

struct ProcessedData {
    let processedAt = Date()
}

struct User {
    let email: String
    let registeredAt = Date()
}

struct ErrorPropagationDetails {
    let sourceActor: String
    let function: String
    let error: Error
    let timestamp: Date
}