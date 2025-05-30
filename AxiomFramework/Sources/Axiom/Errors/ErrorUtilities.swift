import Foundation
import SwiftUI

// MARK: - Simplified Error Handling Utilities

/// Utility for wrapping common Swift errors as AxiomErrors without boilerplate
public struct AxiomErrorFactory {
    
    /// Wrap any Swift Error as an AxiomError with appropriate categorization
    public static func wrap(
        _ error: Error,
        component: String,
        category: ErrorCategory? = nil,
        severity: ErrorSeverity? = nil,
        userMessage: String? = nil
    ) -> any AxiomError {
        
        let inferredCategory = category ?? inferCategory(from: error)
        let inferredSeverity = severity ?? inferSeverity(from: error)
        let defaultMessage = userMessage ?? error.localizedDescription
        
        return WrappedAxiomError(
            underlying: error,
            component: component,
            category: inferredCategory,
            severity: inferredSeverity,
            userMessage: defaultMessage
        )
    }
    
    /// Create a simple AxiomError with minimal boilerplate
    public static func create(
        message: String,
        component: String,
        category: ErrorCategory = .architectural,
        severity: ErrorSeverity = .error
    ) -> any AxiomError {
        
        return SimpleAxiomError(
            message: message,
            component: component,
            category: category,
            severity: severity
        )
    }
    
    // MARK: - Private Helpers
    
    private static func inferCategory(from error: Error) -> ErrorCategory {
        switch error {
        case is DecodingError, is EncodingError:
            return .validation
        case let nsError as NSError where nsError.domain == NSURLErrorDomain:
            return .configuration
        case is CancellationError:
            return .architectural
        default:
            return .architectural
        }
    }
    
    private static func inferSeverity(from error: Error) -> ErrorSeverity {
        switch error {
        case is CancellationError:
            return .warning
        case let nsError as NSError where nsError.code == NSURLErrorNotConnectedToInternet:
            return .warning
        default:
            return .error
        }
    }
}

// MARK: - Wrapped Error Implementation

public struct WrappedAxiomError: AxiomError {
    public let id = UUID()
    public let underlying: Error
    public let component: String
    public let category: ErrorCategory
    public let severity: ErrorSeverity
    public let userMessage: String
    
    public var context: ErrorContext {
        ErrorContext(
            component: ComponentID(component),
            timestamp: Date(),
            additionalInfo: [
                "underlying_type": String(describing: type(of: underlying)),
                "underlying_description": underlying.localizedDescription
            ]
        )
    }
    
    public var recoveryActions: [RecoveryAction] {
        // Generate reasonable recovery actions based on error type
        switch underlying {
        case let nsError as NSError where nsError.domain == NSURLErrorDomain:
            return [.retry(after: 3.0)]
        case is DecodingError:
            return [.reconfigure("Refresh data from source")]
        default:
            return [.retry(after: 1.0)]
        }
    }
    
    public var errorDescription: String? {
        userMessage
    }
}

// MARK: - Simple Error Implementation

public struct SimpleAxiomError: AxiomError {
    public let id = UUID()
    public let message: String
    public let component: String
    public let category: ErrorCategory
    public let severity: ErrorSeverity
    
    public var context: ErrorContext {
        ErrorContext(
            component: ComponentID(component),
            timestamp: Date(),
            additionalInfo: [:]
        )
    }
    
    public var recoveryActions: [RecoveryAction] { [] }
    public var userMessage: String { message }
    public var errorDescription: String? { message }
}

// MARK: - Result Extensions

extension Result where Failure == Error {
    /// Convert Swift Result to AxiomError Result with automatic error wrapping
    public func asAxiomResult(component: String) -> Result<Success, WrappedAxiomError> {
        mapError { error in
            AxiomErrorFactory.wrap(error, component: component) as! WrappedAxiomError
        }
    }
}

// MARK: - Async Error Handling

/// Utilities for handling async operations with automatic error wrapping
public struct AsyncErrorHandler {
    
    /// Execute async operation with automatic error wrapping
    public static func execute<T>(
        component: String,
        operation: () async throws -> T
    ) async -> Result<T, WrappedAxiomError> {
        do {
            let result = try await operation()
            return .success(result)
        } catch {
            return .failure(AxiomErrorFactory.wrap(error, component: component) as! WrappedAxiomError)
        }
    }
    
    /// Execute async operation with custom error handling
    public static func execute<T, E: AxiomError>(
        component: String,
        errorHandler: (Error) -> E,
        operation: () async throws -> T
    ) async -> Result<T, E> {
        do {
            let result = try await operation()
            return .success(result)
        } catch {
            return .failure(errorHandler(error))
        }
    }
}

// MARK: - Error Recovery Helpers

/// Helper for implementing error recovery in contexts
public struct ErrorRecoveryHelper {
    
    /// Execute a recovery action with proper error handling
    public static func executeRecovery(
        action: RecoveryAction,
        context: any AxiomContext
    ) async {
        // This would contain common recovery logic
        print("🔄 Executing recovery action: \(action.description)")
        
        switch action {
        case .retry(let interval):
            print("⏱️ Retrying after \(interval) seconds")
            // Implement retry logic with delay
        case .reconfigure(let message):
            print("🔧 Reconfiguring: \(message)")
            // Implement reconfiguration logic
        case .fallback(let message):
            print("🔄 Falling back: \(message)")
            // Implement fallback logic
        case .ignore:
            print("⚠️ Ignoring error and continuing")
        case .escalate:
            print("🚨 Escalating error")
        case .custom(let message, let action):
            print("🛠️ Custom action: \(message)")
            action()
        }
    }
}

// MARK: - SwiftUI Error Handling

/// View modifier for handling AxiomErrors in SwiftUI
public struct AxiomErrorModifier: ViewModifier {
    let error: (any AxiomError)?
    let onRecovery: ((RecoveryAction) async -> Void)?
    
    public func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil)) {
                if let error = error {
                    ForEach(Array(error.recoveryActions.prefix(3).enumerated()), id: \.offset) { index, action in
                        Button(action.description) {
                            Task {
                                await onRecovery?(action)
                            }
                        }
                    }
                    
                    Button("Dismiss", role: .cancel) { }
                }
            } message: {
                if let error = error {
                    Text(error.userMessage)
                }
            }
    }
}

extension View {
    /// Apply AxiomError handling to a view
    public func axiomErrorHandling(
        error: (any AxiomError)?,
        onRecovery: ((RecoveryAction) async -> Void)? = nil
    ) -> some View {
        modifier(AxiomErrorModifier(error: error, onRecovery: onRecovery))
    }
}