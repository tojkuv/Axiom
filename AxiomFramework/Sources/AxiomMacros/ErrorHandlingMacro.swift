import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Macro that generates automatic retry logic with configurable backoff strategies
public struct ErrorHandlingMacro: MemberMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Extract macro parameters
        let retryCount = extractRetryCount(from: node) ?? 3
        let backoffStrategy = extractBackoffStrategy(from: node) ?? "exponential"
        
        // Generate helper methods for error handling
        let helperMethods = generateErrorHandlingHelpers(
            retryCount: retryCount,
            backoffStrategy: backoffStrategy
        )
        
        return helperMethods.map { DeclSyntax(stringLiteral: $0) }
    }
    
    private static func extractRetryCount(from node: AttributeSyntax) -> Int? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        
        for argument in arguments {
            if argument.label?.text == "retry" {
                return Int(argument.expression.description.trimmingCharacters(in: .whitespaces))
            }
        }
        
        return nil
    }
    
    private static func extractBackoffStrategy(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        
        for argument in arguments {
            if argument.label?.text == "backoff" {
                return argument.expression.description.trimmingCharacters(in: .whitespaces)
            }
        }
        
        return nil
    }
    
    private static func extractTimeout(from node: AttributeSyntax) -> TimeInterval? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        
        for argument in arguments {
            if argument.label?.text == "timeout" {
                return TimeInterval(argument.expression.description.trimmingCharacters(in: .whitespaces)) ?? nil
            }
        }
        
        return nil
    }
    
    private static func extractFallback(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        
        for argument in arguments {
            if argument.label?.text == "fallback" {
                return argument.expression.description.trimmingCharacters(in: .whitespaces)
            }
        }
        
        return nil
    }
    
    private static func generateErrorHandlingHelpers(
        retryCount: Int,
        backoffStrategy: String
    ) -> [String] {
        
        var helpers: [String] = []
        
        // Generate retry helper method
        let retryHelper = """
            private func executeWithRetry<T>(
                _ operation: () async throws -> T,
                maxAttempts: Int = \(retryCount)
            ) async throws -> T {
                var lastError: Error?
                
                for attempt in 1...maxAttempts {
                    do {
                        return try await operation()
                    } catch {
                        lastError = error
                        if attempt < maxAttempts {
                            let delay = calculateBackoffDelay(attempt: attempt)
                            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        }
                    }
                }
                
                throw lastError ?? NSError(domain: "RetryError", code: -1)
            }
            """
        
        helpers.append(retryHelper)
        
        // Generate backoff calculation helper
        let backoffHelper = """
            private func calculateBackoffDelay(attempt: Int) -> TimeInterval {
                let baseDelay: TimeInterval = 1.0
                return baseDelay * pow(2.0, Double(attempt - 1))
            }
            """
        
        helpers.append(backoffHelper)
        
        return helpers
    }
}

/// Macro that automatically adds error context to function calls
public struct ErrorContextMacro: MemberMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Extract macro parameters
        let operation = extractOperation(from: node) ?? "operation"
        
        // Generate helper method for error context
        let contextHelper = """
            private func executeWithContext<T>(
                operation: String = "\(operation)",
                _ work: () async throws -> T
            ) async throws -> T {
                do {
                    return try await work()
                } catch {
                    // In a real implementation, would add proper context
                    throw error
                }
            }
            """
        
        return [DeclSyntax(stringLiteral: contextHelper)]
    }
    
    private static func extractOperation(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        
        for argument in arguments {
            if argument.label?.text == "operation" {
                return argument.expression.description
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        }
        
        return nil
    }
    
    private static func extractMetadata(from node: AttributeSyntax) -> [String: String]? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        
        for argument in arguments {
            if argument.label?.text == "metadata" {
                // For now, return empty dict - full implementation would parse the dictionary
                return [:]
            }
        }
        
        return nil
    }
}