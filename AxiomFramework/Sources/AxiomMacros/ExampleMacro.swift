import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - Example Macro for Testing Infrastructure

/// A simple example macro that adds a greeting property to a struct
/// This is used to test that the macro infrastructure is working correctly
public struct GreetingMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate it's applied to a struct
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: GreetingMacroDiagnostic.onlyOnStructs
                )
            )
            return []
        }
        
        // Extract the name argument if provided
        let name = extractName(from: node) ?? "World"
        
        // Generate the greeting property
        let greetingProperty = """
            public var greeting: String {
                "Hello, \(name)!"
            }
            """
        
        return [DeclSyntax(stringLiteral: greetingProperty)]
    }
    
    private static func extractName(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments,
              case .argumentList(let argumentList) = arguments,
              let firstArgument = argumentList.first,
              let stringLiteral = firstArgument.expression.as(StringLiteralExprSyntax.self),
              case .stringSegment(let segment) = stringLiteral.segments.first else {
            return nil
        }
        
        return segment.content.text
    }
}

/// Diagnostic messages for the greeting macro
enum GreetingMacroDiagnostic: String, DiagnosticMessage {
    case onlyOnStructs
    
    var message: String {
        switch self {
        case .onlyOnStructs:
            return "@Greeting can only be applied to structs"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros", id: rawValue)
    }
    
    var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - Macro Declaration

/// The @Greeting macro adds a greeting property to a struct
@attached(member, names: named(greeting))
public macro Greeting(_ name: String = "World") = #externalMacro(module: "AxiomMacros", type: "GreetingMacro")