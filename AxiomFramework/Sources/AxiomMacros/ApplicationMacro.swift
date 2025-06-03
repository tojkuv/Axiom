import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - Application Macro

/// The @Application macro generates application entry point implementation
/// Creates runtime management and lifecycle coordination
public struct ApplicationMacro: MemberMacro {
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
                    message: ApplicationMacroDiagnostic.notAStruct,
                    highlights: [Syntax(node)],
                    fixIts: [
                        FixIt(
                            message: ApplicationMacroFixIt.useStruct,
                            changes: [
                                .replace(
                                    oldNode: Syntax(node),
                                    newNode: Syntax(StringLiteralExprSyntax(content: "Apply @Application to a struct"))
                                )
                            ]
                        )
                    ]
                )
            )
            return []
        }
        
        // Check for configure method
        var hasValidConfigure = false
        var isConfigureAsync = false
        
        for member in structDecl.memberBlock.members {
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self),
               funcDecl.name.text == "configure" {
                // Check if it has parameters
                if !funcDecl.signature.parameterClause.parameters.isEmpty {
                    context.diagnose(
                        Diagnostic(
                            node: node,
                            message: ApplicationMacroDiagnostic.configureHasParameters,
                            highlights: [Syntax(funcDecl.signature.parameterClause)],
                            fixIts: [
                                FixIt(
                                    message: ApplicationMacroFixIt.removeParameters,
                                    changes: [
                                        .replace(
                                            oldNode: Syntax(funcDecl.signature.parameterClause),
                                            newNode: Syntax(FunctionParameterClauseSyntax(parameters: FunctionParameterListSyntax([])))
                                        )
                                    ]
                                )
                            ]
                        )
                    )
                    return []
                }
                hasValidConfigure = true
                isConfigureAsync = funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil
                break
            }
        }
        
        // Check if main method already exists
        let hasMain = structDecl.memberBlock.members.contains { member in
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                return funcDecl.name.text == "main" && 
                       funcDecl.modifiers.contains { $0.name.tokenKind == .keyword(.static) }
            }
            return false
        }
        
        // If main already exists, don't generate anything
        if hasMain {
            return []
        }
        
        // Extract access level
        let accessLevel = extractAccessLevel(from: structDecl)
        let publicPrefix = accessLevel.isEmpty ? "" : "\(accessLevel) "
        
        // Extract struct name
        let structName = structDecl.name.text
        
        var generatedMembers: [DeclSyntax] = []
        
        // Generate configure if it doesn't exist
        if !hasValidConfigure {
            let configureDecl = """
            func configure() async throws {
                // Default configuration
            }
            """
            generatedMembers.append(DeclSyntax(stringLiteral: configureDecl))
            isConfigureAsync = true  // Auto-generated configure is always async
        }
        
        // Generate main method
        let awaitKeyword = isConfigureAsync ? "await " : ""
        let mainDecl = """
        
        @main
        \(publicPrefix)static func main() async throws {
            let app = \(structName)()
            try \(awaitKeyword)app.configure()
        }
        """
        generatedMembers.append(DeclSyntax(stringLiteral: mainDecl))
        
        return generatedMembers
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

enum ApplicationMacroDiagnostic: String, DiagnosticMessage {
    case notAStruct = "@Application can only be applied to structs"
    case configureHasParameters = "configure() must have no parameters"
    
    var message: String { self.rawValue }
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros", id: rawValue)
    }
    var severity: DiagnosticSeverity { .error }
}

enum ApplicationMacroFixIt: String, FixItMessage {
    case useStruct = "Change to 'struct'"
    case removeParameters = "Remove parameters from configure()"
    
    var message: String { self.rawValue }
    var fixItID: MessageID {
        MessageID(domain: "AxiomMacros", id: rawValue)
    }
}

// MARK: - Public Macro Declaration

@attached(member, names: arbitrary)
public macro Application() = #externalMacro(module: "AxiomMacros", type: "ApplicationMacro")