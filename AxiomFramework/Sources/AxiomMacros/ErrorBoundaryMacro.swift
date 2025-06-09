import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Macro that generates automatic error boundary handling for contexts
public struct ErrorBoundaryMacro: MemberMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Extract parameters from macro
        let strategy = extractStrategy(from: node) ?? ".propagate"
        let customHandler = extractCustomHandler(from: node)
        
        var members: [DeclSyntax] = []
        
        // Generate error boundary initialization
        let boundaryInit = """
            private func initializeErrorBoundary() {
                errorBoundary.configure(strategy: \(strategy))
            }
            """
        
        members.append(DeclSyntax(stringLiteral: boundaryInit))
        
        // Generate wrapped methods for error handling
        if let classDecl = declaration.as(ClassDeclSyntax.self) {
            for member in classDecl.memberBlock.members {
                if let function = member.decl.as(FunctionDeclSyntax.self),
                   function.signature.effectSpecifiers?.asyncSpecifier != nil,
                   function.signature.effectSpecifiers?.throwsSpecifier != nil {
                    
                    let wrappedMethod = generateWrappedMethod(
                        for: function,
                        strategy: strategy,
                        customHandler: customHandler
                    )
                    
                    members.append(DeclSyntax(stringLiteral: wrappedMethod))
                }
            }
        }
        
        // Add lifecycle integration
        let lifecycleIntegration = """
            
            override func performAppearance() async {
                await super.performAppearance()
                initializeErrorBoundary()
            }
            """
        
        members.append(DeclSyntax(stringLiteral: lifecycleIntegration))
        
        return members
    }
    
    private static func extractStrategy(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        
        for argument in arguments {
            if argument.label?.text == "strategy" {
                return argument.expression.description.trimmingCharacters(in: .whitespaces)
            }
        }
        
        return nil
    }
    
    private static func extractCustomHandler(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        
        for argument in arguments {
            if argument.label?.text == "customHandler" {
                return argument.expression.description
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        }
        
        return nil
    }
    
    private static func generateWrappedMethod(
        for function: FunctionDeclSyntax,
        strategy: String,
        customHandler: String?
    ) -> String {
        let functionName = function.name.text
        let wrappedName = "_wrapped_\(functionName)"
        
        // Generate parameter list
        let params = function.signature.parameterClause.parameters
            .map { param in
                let label = param.secondName?.text ?? param.firstName.text
                return "\(label): \(label)"
            }
            .joined(separator: ", ")
        
        // Generate original method rename
        let originalMethod = function.description
            .replacingOccurrences(of: functionName, with: wrappedName)
            .replacingOccurrences(of: "throws", with: "throws")
        
        // Generate wrapper method
        var wrapper = """
            
            \(originalMethod)
            
            \(function.modifiers.description)func \(functionName)\(function.signature.parameterClause) async throws\(function.signature.returnClause?.description ?? "") {
                do {
                    \(function.signature.returnClause != nil ? "return " : "")try await \(wrappedName)(\(params))
                } catch {
                    await errorBoundary.handle(error)
            """
        
        if let handler = customHandler {
            wrapper += """
                    
                    await \(handler)(error)
            """
        }
        
        if strategy.contains("retry") {
            wrapper += """
                    
                    // Retry logic handled by error boundary
                    throw error
            """
        } else if strategy == ".propagate" {
            wrapper += """
                    
                    throw error
            """
        }
        
        wrapper += """
                
                }
            }
            """
        
        return wrapper
    }
}

// Extension to make the macro available
extension ErrorBoundaryMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        return []
    }
}