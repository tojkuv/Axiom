import Foundation
import AxiomCore

// MARK: - Error Boundary Protocol

/// Protocol for contexts that can manage error boundaries
@MainActor
public protocol ErrorBoundaryManaged: AnyObject {
    /// Handle errors within this boundary
    func handle(_ error: Error) async
    
    /// Execute operation with error recovery
    func executeWithRecovery<T: Sendable>(
        _ operation: @Sendable () async throws -> T,
        maxRetries: Int?,
        strategy: ErrorRecoveryStrategy
    ) async throws -> T
    
    /// Check if error can be recovered
    func canRecover(from error: Error) -> Bool
}

// MARK: - Error Boundary Implementation

/// Base class for error boundary functionality
@MainActor
public class AxiomErrorBoundary: ObservableObject {
    @Published public private(set) var hasActiveError = false
    @Published public private(set) var lastError: Error?
    
    private var recoveryAttempts: [String: Int] = [:]
    
    public init() {}
    
    /// Handle errors within this boundary
    public func handle(_ error: Error) async {
        hasActiveError = true
        lastError = error
        
        // Log error for debugging
        print("[AxiomErrorBoundary] Error handled: \(error)")
    }
    
    /// Execute operation with error recovery
    public func executeWithRecovery<T: Sendable>(
        _ operation: @Sendable () async throws -> T,
        maxRetries: Int? = nil,
        strategy: ErrorRecoveryStrategy = .propagate
    ) async throws -> T {
        let maxAttempts = maxRetries ?? 1
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                let result = try await operation()
                
                // Clear error state on success
                hasActiveError = false
                lastError = nil
                
                return result
            } catch {
                lastError = error
                await handle(error)
                
                // If this is the last attempt or strategy doesn't allow retry, throw
                if attempt == maxAttempts || !shouldRetry(error: error, strategy: strategy) {
                    throw error
                }
                
                // Wait before retry
                try? await Task.sleep(for: .milliseconds(100 * attempt))
            }
        }
        
        // This should never be reached due to the loop logic above
        throw lastError ?? AxiomError.unknownError
    }
    
    /// Check if error can be recovered
    public func canRecover(from error: Error) -> Bool {
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
    
    /// Clear error state
    public func clearError() {
        hasActiveError = false
        lastError = nil
    }
    
    // MARK: - Private Helpers
    
    private func shouldRetry(error: Error, strategy: ErrorRecoveryStrategy) -> Bool {
        switch strategy {
        case .retry:
            return true
        case .propagate, .silent, .userPrompt:
            return false
        }
    }
}

// MARK: - Simple Error Boundary Mixin

/// Simple mixin for adding error boundary functionality to contexts
@MainActor
public class AxiomContextWithErrorBoundary: AxiomErrorBoundary, ErrorBoundaryManaged {
    
    public override init() {
        super.init()
    }
    
    // ErrorBoundaryManaged protocol implementation uses inherited methods from AxiomErrorBoundary
}

// MARK: - Recovery Result

/// Result of error recovery operation
public enum RecoveryResult: Equatable {
    case succeeded(attempts: Int)
    case failed(error: Error, attempts: Int)
    case abandoned(reason: String)
    
    public static func == (lhs: RecoveryResult, rhs: RecoveryResult) -> Bool {
        switch (lhs, rhs) {
        case (.succeeded(let a), .succeeded(let b)):
            return a == b
        case (.failed(_, let a), .failed(_, let b)):
            return a == b
        case (.abandoned(let a), .abandoned(let b)):
            return a == b
        default:
            return false
        }
    }
}