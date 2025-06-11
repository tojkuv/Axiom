import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// PropagateErrors macro implementation (REQUIREMENTS-W-06-005)
/// Generates error transformation code for cross-actor propagation
public struct PropagateErrorsMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Extract target error type
        let targetType = try extractTargetType(from: node)
        
        // Get the type name for context
        let typeName = declaration.as(ActorDeclSyntax.self)?.name.text ??
                      declaration.as(ClassDeclSyntax.self)?.name.text ??
                      declaration.as(StructDeclSyntax.self)?.name.text ?? "Unknown"
        
        // Process all throwing methods
        var wrappedMethods: [DeclSyntax] = []
        
        if let actorDecl = declaration.as(ActorDeclSyntax.self) {
            wrappedMethods = processActor(actorDecl, targetType: targetType, typeName: typeName)
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            wrappedMethods = processClass(classDecl, targetType: targetType, typeName: typeName)
        }
        
        return wrappedMethods
    }
    
    private static func extractTargetType(from node: AttributeSyntax) throws -> String {
        guard let arguments = node.arguments,
              case .argumentList(let argList) = arguments,
              let toArg = argList.first(where: { $0.label?.text == "to" }) else {
            throw PropagateErrorsMacroError.missingTargetType
        }
        
        // Extract the type expression
        return toArg.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func processActor(_ actorDecl: ActorDeclSyntax, targetType: String, typeName: String) -> [DeclSyntax] {
        var results: [DeclSyntax] = []
        
        for member in actorDecl.memberBlock.members {
            if let function = member.decl.as(FunctionDeclSyntax.self),
               function.signature.effectSpecifiers?.throwsSpecifier != nil {
                results.append(contentsOf: wrapMethod(function, targetType: targetType, typeName: typeName, isActor: true))
            }
        }
        
        return results
    }
    
    private static func processClass(_ classDecl: ClassDeclSyntax, targetType: String, typeName: String) -> [DeclSyntax] {
        var results: [DeclSyntax] = []
        
        for member in classDecl.memberBlock.members {
            if let function = member.decl.as(FunctionDeclSyntax.self),
               function.signature.effectSpecifiers?.throwsSpecifier != nil {
                results.append(contentsOf: wrapMethod(function, targetType: targetType, typeName: typeName, isActor: false))
            }
        }
        
        return results
    }
    
    private static func wrapMethod(_ function: FunctionDeclSyntax, targetType: String, typeName: String, isActor: Bool) -> [DeclSyntax] {
        let functionName = function.name.text
        let wrappedName = "_wrapped_\(functionName)"
        
        // Generate parameter forwarding
        let parameterForwarding = function.signature.parameterClause.parameters.isEmpty ? "" :
            function.signature.parameterClause.parameters.map { param in
                let label = param.firstName.text
                let name = param.secondName?.text ?? param.firstName.text
                return label == "_" ? name : "\(label): \(name)"
            }.joined(separator: ", ")
        
        // Create wrapped function (original implementation)
        var wrappedFunction = function
        wrappedFunction.name = TokenSyntax(stringLiteral: wrappedName)
        wrappedFunction.modifiers = DeclModifierListSyntax {
            DeclModifierSyntax(name: .keyword(.private))
        }
        // Move original body to wrapped function
        wrappedFunction.body = function.body
        
        // Generate new function body with error propagation
        let hasReturn = function.signature.returnClause != nil
        let returnKeyword = hasReturn ? "return " : ""
        let asyncKeyword = function.signature.effectSpecifiers?.asyncSpecifier != nil ? "await " : ""
        let actorContext = isActor ? "actor" : "type"
        
        let newBody = """
            do {
                \(returnKeyword)try \(asyncKeyword)self.\(wrappedName)(\(parameterForwarding))
            } catch let error as \(targetType) {
                throw error
            } catch {
                throw \(targetType)(legacy: error)
                    .addingContext("operation", "\(functionName)")
                    .addingContext("\(actorContext)", "\(typeName)")
            }
            """
        
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
}

enum PropagateErrorsMacroError: Error, CustomStringConvertible {
    case missingTargetType
    case invalidTargetType
    
    var description: String {
        switch self {
        case .missingTargetType:
            return "@PropagateErrors requires a 'to' parameter specifying the target error type"
        case .invalidTargetType:
            return "Invalid target error type specified"
        }
    }
}