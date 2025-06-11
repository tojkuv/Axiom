import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// ErrorBoundary macro implementation (REQUIREMENTS-W-06-005)
/// Generates automatic error boundary setup for contexts and classes
/// Optimized for performance and type safety
public struct ErrorBoundaryMacro: MemberMacro, PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate declaration type first for better error messages
        guard declaration.is(ClassDeclSyntax.self) || 
              declaration.is(StructDeclSyntax.self) || 
              declaration.is(ActorDeclSyntax.self) else {
            throw ErrorBoundaryMacroError.unsupportedDeclaration
        }
        
        // Extract recovery strategy from macro arguments
        guard let arguments = node.arguments,
              case .argumentList(let argList) = arguments else {
            throw ErrorBoundaryMacroError.missingStrategy
        }
        
        // Extract and validate strategy parameter
        let strategy = try extractStrategy(from: argList)
        
        // Type name extraction no longer needed for current implementation
        // let typeName = extractTypeName(from: declaration)
        
        // Generate optimized error boundary configuration
        let errorBoundaryDecl = """
            private func configureErrorBoundary() {
                Task { @MainActor in
                    await self.configureErrorRecovery(\(strategy))
                }
            }
            """
        
        return [DeclSyntax(stringLiteral: errorBoundaryDecl)]
    }
    
    /// Optimized type name extraction
    private static func extractTypeName(from declaration: some DeclGroupSyntax) -> String {
        if let classDecl = declaration.as(ClassDeclSyntax.self) {
            return classDecl.name.text
        } else if let structDecl = declaration.as(StructDeclSyntax.self) {
            return structDecl.name.text
        } else if let actorDecl = declaration.as(ActorDeclSyntax.self) {
            return actorDecl.name.text
        }
        return "Unknown"
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Handle method wrapping for classes/structs - optimized type checking
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            return []
        }
        
        var wrappedMethods: [DeclSyntax] = []
        wrappedMethods.reserveCapacity(classDecl.memberBlock.members.count * 2)
        
        // Process all throwing async methods with optimized filtering
        for member in classDecl.memberBlock.members {
            guard let function = member.decl.as(FunctionDeclSyntax.self),
                  isAsyncThrowingFunction(function) else {
                continue
            }
            
            let functionName = function.name.text
            let wrappedName = "_wrapped_\(functionName)"
            
            // Optimized parameter forwarding generation
            let parameterForwarding = generateParameterForwarding(for: function)
            
            // Create wrapped function with optimized modifiers
            var wrappedFunction = function
            wrappedFunction.name = TokenSyntax(stringLiteral: wrappedName)
            wrappedFunction.modifiers = DeclModifierListSyntax {
                DeclModifierSyntax(name: .keyword(.private))
            }
            wrappedFunction.body = function.body
            
            // Generate optimized error boundary call
            let hasReturn = function.signature.returnClause != nil
            let returnKeyword = hasReturn ? "return " : ""
            
            let newBodyContent = """
                \(returnKeyword)try await errorBoundary.executeWithRecovery {
                    \(returnKeyword)try await self.\(wrappedName)(\(parameterForwarding))
                }
                """
            
            var newFunction = function
            newFunction.body = CodeBlockSyntax(
                leftBrace: .leftBraceToken(),
                statements: CodeBlockItemListSyntax([
                    CodeBlockItemSyntax(item: .expr(ExprSyntax(stringLiteral: newBodyContent)))
                ]),
                rightBrace: .rightBraceToken()
            )
            
            wrappedMethods.append(DeclSyntax(wrappedFunction))
            wrappedMethods.append(DeclSyntax(newFunction))
        }
        
        return wrappedMethods
    }
    
    /// Optimized check for async throwing functions
    private static func isAsyncThrowingFunction(_ function: FunctionDeclSyntax) -> Bool {
        guard let effectSpecifiers = function.signature.effectSpecifiers else {
            return false
        }
        return effectSpecifiers.asyncSpecifier != nil && effectSpecifiers.throwsSpecifier != nil
    }
    
    /// Optimized parameter forwarding generation
    private static func generateParameterForwarding(for function: FunctionDeclSyntax) -> String {
        let parameters = function.signature.parameterClause.parameters
        guard !parameters.isEmpty else { return "" }
        
        return parameters.map { param in
            let label = param.firstName.text
            let name = param.secondName?.text ?? param.firstName.text
            return label == "_" ? name : "\(label): \(name)"
        }.joined(separator: ", ")
    }
    
    /// Optimized strategy extraction with validation
    private static func extractStrategy(from arguments: LabeledExprListSyntax) throws -> String {
        guard let strategyArg = arguments.first(where: { $0.label?.text == "strategy" }) else {
            throw ErrorBoundaryMacroError.missingStrategy
        }
        
        let expr = strategyArg.expression
        let strategy = expr.description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate strategy syntax for common patterns
        if strategy.isEmpty {
            throw ErrorBoundaryMacroError.invalidStrategy("empty strategy")
        }
        
        // Basic validation for known strategy patterns
        let validPatterns = [".retry", ".fail", ".userPrompt", ".propagate"]
        let isValidPattern = validPatterns.contains { strategy.hasPrefix($0) }
        
        if !isValidPattern && !strategy.starts(with: ".") {
            throw ErrorBoundaryMacroError.invalidStrategy(strategy)
        }
        
        return strategy
    }
}

enum ErrorBoundaryMacroError: Error, CustomStringConvertible {
    case missingStrategy
    case invalidStrategy(String)
    case unsupportedDeclaration
    
    var description: String {
        switch self {
        case .missingStrategy:
            return "ErrorBoundary macro requires a strategy parameter"
        case .invalidStrategy(let strategy):
            return "Unknown recovery strategy '\(strategy)'. Available strategies: retry, fail, userPrompt, propagate"
        case .unsupportedDeclaration:
            return "@ErrorBoundary can only be applied to classes, structs, or actors"
        }
    }
}