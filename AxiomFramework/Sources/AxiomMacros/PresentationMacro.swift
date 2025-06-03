import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - Presentation Macro

/// The @Presentation macro generates SwiftUI view implementation
/// Enforces 1:1 view-context relationship
public struct PresentationMacro: MemberMacro {
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
                    message: PresentationMacroDiagnostic.notAStruct,
                    highlights: [Syntax(node)],
                    fixIts: [
                        FixIt(
                            message: PresentationMacroFixIt.useStruct,
                            changes: [
                                .replace(
                                    oldNode: Syntax(node),
                                    newNode: Syntax(StringLiteralExprSyntax(content: "Apply @Presentation to a struct"))
                                )
                            ]
                        )
                    ]
                )
            )
            return []
        }
        
        // Check if context property exists
        let hasContext = structDecl.memberBlock.members.contains { member in
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                return varDecl.bindings.contains { binding in
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        return identifier.identifier.text == "context"
                    }
                    return false
                }
            }
            return false
        }
        
        // If no context property, produce diagnostic
        if !hasContext {
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: PresentationMacroDiagnostic.missingContext,
                    highlights: [Syntax(node)],
                    fixIts: [
                        FixIt(
                            message: PresentationMacroFixIt.addContext,
                            changes: [
                                .replace(
                                    oldNode: Syntax(node),
                                    newNode: Syntax(StringLiteralExprSyntax(content: "Add context property"))
                                )
                            ]
                        )
                    ]
                )
            )
            return []
        }
        
        // Check if body property already exists
        let hasBody = structDecl.memberBlock.members.contains { member in
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                return varDecl.bindings.contains { binding in
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        return identifier.identifier.text == "body"
                    }
                    return false
                }
            }
            return false
        }
        
        // If body already exists, don't generate one
        if hasBody {
            return []
        }
        
        // Extract access level
        let accessLevel = extractAccessLevel(from: structDecl)
        let publicPrefix = accessLevel.isEmpty ? "" : "\(accessLevel) "
        
        // Extract struct name
        let structName = structDecl.name.text
        
        // Generate body property
        let bodyDecl = """
        
        \(publicPrefix)var body: some View {
            Text("\(structName)")
        }
        """
        
        return [DeclSyntax(stringLiteral: bodyDecl)]
    }
    
    /// Extract access level from struct declaration
    private static func extractAccessLevel(from decl: StructDeclSyntax) -> String {
        for modifier in decl.modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.public):
                return "public"
            case .keyword(.internal):
                return "internal"
            case .keyword(.fileprivate):
                return "fileprivate"
            case .keyword(.private):
                return "private"
            default:
                continue
            }
        }
        return ""
    }
}

// MARK: - Diagnostic Messages

enum PresentationMacroDiagnostic: String, DiagnosticMessage {
    case notAStruct = "@Presentation can only be applied to structs"
    case missingContext = "@Presentation requires a 'context' property"
    
    var message: String { self.rawValue }
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros", id: rawValue)
    }
    var severity: DiagnosticSeverity { .error }
}

enum PresentationMacroFixIt: String, FixItMessage {
    case useStruct = "Change to 'struct'"
    case addContext = "Add 'var context: YourContext' property"
    
    var message: String { self.rawValue }
    var fixItID: MessageID {
        MessageID(domain: "AxiomMacros", id: rawValue)
    }
}

// MARK: - Public Macro Declaration

@attached(member, names: arbitrary)
public macro Presentation() = #externalMacro(module: "AxiomMacros", type: "PresentationMacro")