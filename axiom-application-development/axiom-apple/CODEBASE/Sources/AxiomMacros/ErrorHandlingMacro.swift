import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// ErrorHandling macro implementation (REQUIREMENTS-W-06-005)
/// Generates retry logic with backoff, timeout, and fallback support
/// Optimized for compile-time performance and runtime efficiency
public struct ErrorHandlingMacro: PeerMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Extract and validate parameters early
        let parameters = try extractParameters(from: node)
        
        // Fast path for different declaration types
        switch declaration {
        case let classDecl as ClassDeclSyntax:
            return try processClass(classDecl, parameters: parameters)
        case let functionDecl as FunctionDeclSyntax:
            return try processFunction(functionDecl, parameters: parameters)
        default:
            throw ErrorHandlingMacroError.unsupportedDeclaration
        }
    }
    
    private struct ErrorHandlingParameters {
        let retry: Int
        let backoff: String
        let timeout: Double?
        let fallback: String?
    }
    
    /// Optimized parameter extraction with validation
    private static func extractParameters(from node: AttributeSyntax) throws -> ErrorHandlingParameters {
        guard let arguments = node.arguments,
              case .argumentList(let argList) = arguments else {
            return ErrorHandlingParameters(retry: 3, backoff: ".exponential()", timeout: nil, fallback: nil)
        }
        
        var retry = 3
        var backoff = ".exponential()"
        var timeout: Double?
        var fallback: String?
        
        // Optimized argument processing with early exit
        for arg in argList {
            guard let label = arg.label?.text else { continue }
            
            switch label {
            case "retry":
                retry = extractIntParameter(from: arg.expression) ?? 3
                if retry < 1 {
                    throw ErrorHandlingMacroError.invalidRetryCount
                }
            case "backoff":
                backoff = arg.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
                if backoff.isEmpty {
                    throw ErrorHandlingMacroError.invalidBackoffStrategy
                }
            case "timeout":
                timeout = extractDoubleParameter(from: arg.expression)
                if let t = timeout, t <= 0 {
                    throw ErrorHandlingMacroError.invalidTimeout
                }
            case "fallback":
                fallback = extractStringParameter(from: arg.expression)
                if fallback?.isEmpty == true {
                    throw ErrorHandlingMacroError.invalidFallback
                }
            default:
                break
            }
        }
        
        return ErrorHandlingParameters(retry: retry, backoff: backoff, timeout: timeout, fallback: fallback)
    }
    
    /// Extract integer parameter with validation
    private static func extractIntParameter(from expression: ExprSyntax) -> Int? {
        if let intLiteral = expression.as(IntegerLiteralExprSyntax.self) {
            return Int(intLiteral.literal.text)
        }
        return nil
    }
    
    /// Extract double parameter with validation
    private static func extractDoubleParameter(from expression: ExprSyntax) -> Double? {
        if let floatLiteral = expression.as(FloatLiteralExprSyntax.self) {
            return Double(floatLiteral.literal.text)
        }
        return nil
    }
    
    /// Extract string parameter with validation
    private static func extractStringParameter(from expression: ExprSyntax) -> String? {
        if let stringLiteral = expression.as(StringLiteralExprSyntax.self) {
            return stringLiteral.segments.first?.description
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        return nil
    }
    
    private static func processClass(_ classDecl: ClassDeclSyntax, parameters: ErrorHandlingParameters) throws -> [DeclSyntax] {
        var results: [DeclSyntax] = []
        
        for member in classDecl.memberBlock.members {
            if let function = member.decl.as(FunctionDeclSyntax.self),
               function.signature.effectSpecifiers?.asyncSpecifier != nil,
               function.signature.effectSpecifiers?.throwsClause?.throwsSpecifier != nil {
                results.append(contentsOf: try generateWrappedMethod(function, parameters: parameters))
            }
        }
        
        return results
    }
    
    private static func processFunction(_ function: FunctionDeclSyntax, parameters: ErrorHandlingParameters) throws -> [DeclSyntax] {
        if parameters.retry == 1 {
            // Optimize for single retry
            return try generateInlinedRetry(function, parameters: parameters)
        } else {
            return try generateWrappedMethod(function, parameters: parameters)
        }
    }
    
    private static func generateWrappedMethod(_ function: FunctionDeclSyntax, parameters: ErrorHandlingParameters) throws -> [DeclSyntax] {
        let functionName = function.name.text
        let wrappedName = "_wrapped_\(functionName)"
        
        // Generate parameter forwarding
        let parameterForwarding = function.signature.parameterClause.parameters.isEmpty ? "" :
            function.signature.parameterClause.parameters.map { param in
                let label = param.firstName.text
                let name = param.secondName?.text ?? param.firstName.text
                return label == "_" ? name : "\(label): \(name)"
            }.joined(separator: ", ")
        
        // Create wrapped function
        var wrappedFunction = function
        wrappedFunction.name = TokenSyntax(stringLiteral: wrappedName)
        wrappedFunction.modifiers = DeclModifierListSyntax {
            DeclModifierSyntax(name: .keyword(.private))
        }
        
        // Generate new function body
        let hasReturn = function.signature.returnClause != nil
        let returnKeyword = hasReturn ? "return " : ""
        let timeoutParam = parameters.timeout.map { ", timeout: \($0)" } ?? ""
        
        var newBody: String
        if let fallback = parameters.fallback {
            newBody = """
                do {
                    \(returnKeyword)try await withRetry(
                        maxAttempts: \(parameters.retry),
                        backoff: \(parameters.backoff)\(timeoutParam)
                    ) {
                        try await self.\(wrappedName)(\(parameterForwarding))
                    }
                } catch {
                    \(returnKeyword)await self.\(fallback)()
                }
                """
        } else {
            newBody = """
                \(returnKeyword)try await withRetry(
                    maxAttempts: \(parameters.retry),
                    backoff: \(parameters.backoff)\(timeoutParam)
                ) {
                    try await self.\(wrappedName)(\(parameterForwarding))
                }
                """
        }
        
        var newFunction = function
        newFunction.body = CodeBlockSyntax(
            leftBrace: .leftBraceToken(),
            statements: CodeBlockItemListSyntax([
                CodeBlockItemSyntax(item: .expr(ExprSyntax(stringLiteral: newBody)))
            ]),
            rightBrace: .rightBraceToken()
        )
        
        return [
            DeclSyntax(newFunction),
            DeclSyntax(wrappedFunction)
        ]
    }
    
    private static func generateInlinedRetry(_ function: FunctionDeclSyntax, parameters: ErrorHandlingParameters) throws -> [DeclSyntax] {
        // For single retry, inline the logic for better performance
        let originalBody = function.body?.statements.description ?? "fatalError()"
        
        let inlinedBody = """
            do {
                \(originalBody)
            } catch {
                \(originalBody)
            }
            """
        
        var optimizedFunction = function
        optimizedFunction.body = CodeBlockSyntax(
            leftBrace: .leftBraceToken(),
            statements: CodeBlockItemListSyntax([
                CodeBlockItemSyntax(item: .expr(ExprSyntax(stringLiteral: inlinedBody)))
            ]),
            rightBrace: .rightBraceToken()
        )
        
        return [DeclSyntax(optimizedFunction)]
    }
}

enum ErrorHandlingMacroError: Error, CustomStringConvertible {
    case unsupportedDeclaration
    case invalidRetryCount
    case invalidBackoffStrategy
    case invalidTimeout
    case invalidFallback
    
    var description: String {
        switch self {
        case .unsupportedDeclaration:
            return "@ErrorHandling can only be applied to classes or functions"
        case .invalidRetryCount:
            return "Retry count must be greater than 0"
        case .invalidBackoffStrategy:
            return "Backoff strategy cannot be empty"
        case .invalidTimeout:
            return "Timeout must be greater than 0"
        case .invalidFallback:
            return "Fallback method name cannot be empty"
        }
    }
}

/// Macro that generates detailed error descriptions and context information for enums
/// 
/// Usage:
/// ```swift
/// @ErrorContext(domain: "TaskManager")
/// enum TaskError: Error {
///     case loadFailed
///     case networkUnavailable
/// }
/// ```
/// 
/// This macro generates:
/// - Detailed error descriptions for each case
/// - Error context information
/// - Recovery suggestions
/// - User-friendly error messages
/// - Integration with error handling framework
public struct ErrorContextMacro: MemberMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Verify this is applied to an enum that conforms to Error
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw EnhancedMacroError.invalidDeclaration("@ErrorContext can only be applied to enums")
        }
        
        // Extract error context parameters
        let parameters = try extractParameters(from: node)
        
        // Generate comprehensive error context members
        let errorDescriptions = generateErrorDescriptions(for: enumDecl, parameters: parameters)
        let recoveryStrategies = generateRecoveryStrategies(for: enumDecl, parameters: parameters)
        let userMessages = generateUserMessages(for: enumDecl, parameters: parameters)
        let contextInfo = generateContextInfo(parameters: parameters)
        let localizationSupport = generateLocalizationSupport(for: enumDecl, parameters: parameters)
        
        return errorDescriptions + recoveryStrategies + userMessages + contextInfo + localizationSupport
    }
    
    // MARK: - Parameter Extraction
    
    private struct ErrorContextParameters {
        let domain: String
        let includeRecoveryStrategies: Bool
        let includeUserMessages: Bool
        let includeLocalization: Bool
        let contextPrefix: String
    }
    
    private static func extractParameters(from node: AttributeSyntax) throws -> ErrorContextParameters {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return ErrorContextParameters(
                domain: "Unknown",
                includeRecoveryStrategies: true,
                includeUserMessages: true,
                includeLocalization: false,
                contextPrefix: "Error"
            )
        }
        
        var domain = "Unknown"
        var includeRecoveryStrategies = true
        var includeUserMessages = true
        var includeLocalization = false
        var contextPrefix = "Error"
        
        for argument in arguments {
            switch argument.label?.text {
            case "domain":
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self) {
                    domain = stringLiteral.segments.description
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                }
            case "includeRecoveryStrategies":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    includeRecoveryStrategies = boolLiteral.literal.text == "true"
                }
            case "includeUserMessages":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    includeUserMessages = boolLiteral.literal.text == "true"
                }
            case "includeLocalization":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    includeLocalization = boolLiteral.literal.text == "true"
                }
            case "contextPrefix":
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self) {
                    contextPrefix = stringLiteral.segments.description
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                }
            default:
                break
            }
        }
        
        return ErrorContextParameters(
            domain: domain,
            includeRecoveryStrategies: includeRecoveryStrategies,
            includeUserMessages: includeUserMessages,
            includeLocalization: includeLocalization,
            contextPrefix: contextPrefix
        )
    }
    
    // MARK: - Code Generation Helpers
    
    private static func generateErrorDescriptions(
        for enumDecl: EnumDeclSyntax,
        parameters: ErrorContextParameters
    ) -> [DeclSyntax] {
        let cases = extractEnumCases(from: enumDecl)
        
        let descriptions = cases.map { caseName in
            let humanReadable = generateHumanReadableDescription(from: caseName)
            return """
            
            /// Auto-generated error description for \(caseName)
            case .\(caseName):
                return "\(parameters.contextPrefix): \(humanReadable)"
            """
        }.joined(separator: "")
        
        return [
            """
            
            // MARK: - Generated Error Descriptions
            
            /// Provides detailed error descriptions
            public var errorDescription: String? {
                switch self {\(raw: descriptions)
                }
            }
            """
        ]
    }
    
    private static func generateRecoveryStrategies(
        for enumDecl: EnumDeclSyntax,
        parameters: ErrorContextParameters
    ) -> [DeclSyntax] {
        guard parameters.includeRecoveryStrategies else { return [] }
        
        let cases = extractEnumCases(from: enumDecl)
        
        let strategies = cases.map { caseName in
            let strategy = generateRecoveryStrategy(for: caseName)
            return """
            
            case .\(caseName):
                return "\(strategy)"
            """
        }.joined(separator: "")
        
        return [
            """
            
            // MARK: - Generated Recovery Strategies
            
            /// Provides recovery strategies for errors
            public var recoverySuggestion: String? {
                switch self {\(raw: strategies)
                }
            }
            """
        ]
    }
    
    private static func generateUserMessages(
        for enumDecl: EnumDeclSyntax,
        parameters: ErrorContextParameters
    ) -> [DeclSyntax] {
        guard parameters.includeUserMessages else { return [] }
        
        let cases = extractEnumCases(from: enumDecl)
        
        let messages = cases.map { caseName in
            let userMessage = generateUserFriendlyMessage(for: caseName)
            return """
            
            case .\(caseName):
                return "\(userMessage)"
            """
        }.joined(separator: "")
        
        return [
            """
            
            // MARK: - Generated User Messages
            
            /// Provides user-friendly error messages
            public var userMessage: String {
                switch self {\(raw: messages)
                }
            }
            """
        ]
    }
    
    private static func generateContextInfo(parameters: ErrorContextParameters) -> [DeclSyntax] {
        return [
            """
            
            // MARK: - Generated Context Information
            
            /// Error domain for this error type
            public static var errorDomain: String {
                return "\(raw: parameters.domain)"
            }
            
            /// Error code based on case
            public var errorCode: Int {
                switch self {
                \(raw: "// Error codes will be generated based on enum cases")
                }
            }
            
            /// Additional context information
            public var contextInfo: [String: Any] {
                return [
                    "domain": Self.errorDomain,
                    "code": errorCode,
                    "timestamp": Date(),
                    "case": String(describing: self)
                ]
            }
            """
        ]
    }
    
    private static func generateLocalizationSupport(
        for enumDecl: EnumDeclSyntax,
        parameters: ErrorContextParameters
    ) -> [DeclSyntax] {
        guard parameters.includeLocalization else { return [] }
        
        return [
            """
            
            // MARK: - Generated Localization Support
            
            /// Localized error description
            public var localizedDescription: String {
                return NSLocalizedString(
                    "\(raw: parameters.contextPrefix.lowercased())_\\(String(describing: self))",
                    comment: "Error description for \\(String(describing: self))"
                )
            }
            
            /// Localized recovery suggestion
            public var localizedRecoverySuggestion: String? {
                return NSLocalizedString(
                    "\(raw: parameters.contextPrefix.lowercased())_\\(String(describing: self))_recovery",
                    comment: "Recovery suggestion for \\(String(describing: self))"
                )
            }
            """
        ]
    }
    
    // MARK: - Helper Methods
    
    private static func extractEnumCases(from enumDecl: EnumDeclSyntax) -> [String] {
        return enumDecl.memberBlock.members.compactMap { member in
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                return caseDecl.elements.first?.name.text
            }
            return nil
        }
    }
    
    private static func generateHumanReadableDescription(from caseName: String) -> String {
        // Convert camelCase to human readable
        let result = caseName.reduce("") { result, character in
            if character.isUppercase && !result.isEmpty {
                return result + " " + character.lowercased()
            } else {
                return result + String(character)
            }
        }
        return result.prefix(1).capitalized + result.dropFirst()
    }
    
    private static func generateRecoveryStrategy(for caseName: String) -> String {
        switch caseName.lowercased() {
        case let name where name.contains("network"):
            return "Check your internet connection and try again"
        case let name where name.contains("permission"):
            return "Please grant the required permissions in Settings"
        case let name where name.contains("load"):
            return "Please try reloading the data"
        case let name where name.contains("save"):
            return "Please try saving again"
        default:
            return "Please try the operation again"
        }
    }
    
    private static func generateUserFriendlyMessage(for caseName: String) -> String {
        switch caseName.lowercased() {
        case let name where name.contains("network"):
            return "Unable to connect to the internet"
        case let name where name.contains("permission"):
            return "Permission required to continue"
        case let name where name.contains("load"):
            return "Failed to load data"
        case let name where name.contains("save"):
            return "Failed to save changes"
        default:
            return "An error occurred"
        }
    }
}

// MARK: - Enhanced Error Types

enum EnhancedMacroError: Error, CustomStringConvertible {
    case invalidDeclaration(String)
    case invalidArguments(String)
    case unsupportedFeature(String)
    
    var description: String {
        switch self {
        case .invalidDeclaration(let message):
            return "Invalid declaration: \(message)"
        case .invalidArguments(let message):
            return "Invalid arguments: \(message)"
        case .unsupportedFeature(let message):
            return "Unsupported feature: \(message)"
        }
    }
}