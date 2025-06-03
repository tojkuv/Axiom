import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - Client Macro

/// The @Client macro generates actor-based client implementation
/// Enforces 1:1 client-state ownership pattern
public struct ClientMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate it's applied to an actor
        guard let actorDecl = declaration.as(ActorDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: ClientMacroDiagnostic.notAnActor,
                    highlights: [Syntax(node)],
                    fixIts: [
                        FixIt(
                            message: ClientMacroFixIt.useActor,
                            changes: [
                                .replace(
                                    oldNode: Syntax(node),
                                    newNode: Syntax(StringLiteralExprSyntax(content: "Apply @Client to an actor"))
                                )
                            ]
                        )
                    ]
                )
            )
            return []
        }
        
        // Extract state type from attribute
        guard let stateType = extractStateType(from: node) else {
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: ClientMacroDiagnostic.missingStateParameter
                )
            )
            return []
        }
        
        // Extract access control modifier
        let accessLevel = extractAccessLevel(from: actorDecl)
        let publicPrefix = accessLevel.isEmpty ? "" : "\(accessLevel) "
        
        // Check for existing members
        let existingMembers = actorDecl.memberBlock.members.compactMap { member in
            member.decl
        }
        
        let hasInitializer = existingMembers.contains { member in
            member.is(InitializerDeclSyntax.self)
        }
        
        let hasUpdateState = existingMembers.contains { member in
            if let function = member.as(FunctionDeclSyntax.self) {
                return function.name.text == "updateState"
            }
            return false
        }
        
        var declarations: [DeclSyntax] = []
        
        // Generate State typealias
        let typealiasDecl = "\(publicPrefix)typealias State = \(stateType)"
        declarations.append(DeclSyntax(stringLiteral: typealiasDecl))
        
        // Generate state property
        if hasInitializer {
            // If there's a custom initializer, don't initialize the state
            let stateDecl = DeclSyntax(stringLiteral: "private(set) var state: \(stateType)")
                .with(\.leadingTrivia, .newlines(2))
            declarations.append(stateDecl)
        } else {
            // Initialize with default constructor
            let stateDecl = DeclSyntax(stringLiteral: "private(set) var state = \(stateType)()")
                .with(\.leadingTrivia, .newlines(2))
            declarations.append(stateDecl)
        }
        
        // Generate updateState method if not already present
        if !hasUpdateState {
            let updateStateDecl = DeclSyntax(stringLiteral: "\(publicPrefix)func updateState(_ transform: (inout \(stateType)) -> Void) async {\n    transform(&state)\n}")
                .with(\.leadingTrivia, .newlines(2))
            declarations.append(updateStateDecl)
        }
        
        return declarations
    }
    
    /// Extract state type from macro attribute
    private static func extractStateType(from node: AttributeSyntax) -> String? {
        // Look for state parameter in the attribute
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        
        for argument in arguments {
            if argument.label?.text == "state" {
                // Handle different expression types
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    // Handle complex types like Feature.Module.ComplexState
                    return extractComplexType(from: memberAccess)
                } else if let identifier = argument.expression.as(DeclReferenceExprSyntax.self) {
                    // Handle simple types like UserProfileState
                    return identifier.baseName.text
                }
            }
        }
        
        return nil
    }
    
    /// Extract complex type name from member access expression
    private static func extractComplexType(from expr: MemberAccessExprSyntax) -> String {
        var components: [String] = [expr.declName.baseName.text]
        var current = expr.base
        
        while let memberAccess = current?.as(MemberAccessExprSyntax.self) {
            components.insert(memberAccess.declName.baseName.text, at: 0)
            current = memberAccess.base
        }
        
        if let identifier = current?.as(DeclReferenceExprSyntax.self) {
            components.insert(identifier.baseName.text, at: 0)
        }
        
        return components.joined(separator: ".")
    }
    
    /// Extract access level from actor declaration
    private static func extractAccessLevel(from decl: ActorDeclSyntax) -> String {
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

enum ClientMacroDiagnostic: String, DiagnosticMessage {
    case notAnActor = "@Client can only be applied to actor declarations"
    case missingStateParameter = "@Client requires a 'state' parameter specifying the State type"
    
    var message: String { self.rawValue }
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros", id: rawValue)
    }
    var severity: DiagnosticSeverity { .error }
}

enum ClientMacroFixIt: String, FixItMessage {
    case useActor = "Replace 'class' with 'actor'"
    
    var message: String { self.rawValue }
    var fixItID: MessageID {
        MessageID(domain: "AxiomMacros", id: rawValue)
    }
}

// MARK: - Public Macro Declaration

@attached(member, names: arbitrary)
public macro Client(state: Any.Type) = #externalMacro(module: "AxiomMacros", type: "ClientMacro")