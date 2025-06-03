import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - Context Macro

/// The @Context macro generates context implementation members
/// Enforces client orchestration patterns and SwiftUI integration
public struct ContextMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate it's applied to a class
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: ContextMacroDiagnostic.notAClass,
                    highlights: [Syntax(node)],
                    fixIts: [
                        FixIt(
                            message: ContextMacroFixIt.useClass,
                            changes: [
                                .replace(
                                    oldNode: Syntax(node),
                                    newNode: Syntax(StringLiteralExprSyntax(content: "Apply @Context to a class"))
                                )
                            ]
                        )
                    ]
                )
            )
            return []
        }
        
        // Check for existing members
        let existingMembers = classDecl.memberBlock.members.compactMap { member in
            member.decl
        }
        
        let hasDerivedState = existingMembers.contains { member in
            if let structDecl = member.as(StructDeclSyntax.self) {
                return structDecl.name.text == "DerivedState"
            }
            return false
        }
        
        let hasPresentationActions = existingMembers.contains { member in
            if let structDecl = member.as(StructDeclSyntax.self) {
                return structDecl.name.text == "PresentationActions"
            }
            return false
        }
        
        // Extract access level
        let accessLevel = extractAccessLevel(from: classDecl)
        let publicPrefix = accessLevel.isEmpty ? "" : "\(accessLevel) "
        
        var declarations: [DeclSyntax] = []
        
        // Generate DerivedState if not present
        if !hasDerivedState {
            let stateDecl = DeclSyntax(stringLiteral: "\(publicPrefix)struct DerivedState: Axiom.State {\n    // TODO: Add derived state properties\n}")
                .with(\.leadingTrivia, .newlines(2))
            declarations.append(stateDecl)
        }
        
        // Generate PresentationActions if not present
        if !hasPresentationActions {
            let actionsDecl = DeclSyntax(stringLiteral: "\(publicPrefix)struct PresentationActions {\n    // TODO: Add action closures\n}")
                .with(\.leadingTrivia, .newlines(2))
            declarations.append(actionsDecl)
        }
        
        // Check for action-reducer validation
        if hasPresentationActions {
            validateActionReducerMapping(classDecl: classDecl, context: context)
        }
        
        return declarations
    }
    
    /// Extract access level from class declaration
    private static func extractAccessLevel(from decl: ClassDeclSyntax) -> String {
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
    
    /// Validate action-reducer mapping
    private static func validateActionReducerMapping(classDecl: ClassDeclSyntax, context: MacroExpansionContext) {
        // Find PresentationActions struct
        var actionProperties: [(name: String, line: Int, column: Int)] = []
        
        for member in classDecl.memberBlock.members {
            if let structDecl = member.decl.as(StructDeclSyntax.self),
               structDecl.name.text == "PresentationActions" {
                // Extract action properties
                for structMember in structDecl.memberBlock.members {
                    if let varDecl = structMember.decl.as(VariableDeclSyntax.self),
                       let binding = varDecl.bindings.first,
                       let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        actionProperties.append((
                            name: identifier.identifier.text,
                            line: 1,  // We can't get accurate line numbers in the expanded macro
                            column: 1
                        ))
                    }
                }
            }
        }
        
        // Find reducer methods
        var reducerMethods: Set<String> = []
        for member in classDecl.memberBlock.members {
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                reducerMethods.insert(funcDecl.name.text)
            }
        }
        
        // Check for missing reducers
        for action in actionProperties {
            if !reducerMethods.contains(action.name) {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(classDecl),
                        message: ContextMacroDiagnostic.missingReducer(actionName: action.name)
                    )
                )
            }
        }
    }
}

// MARK: - Diagnostic Messages

enum ContextMacroDiagnostic: DiagnosticMessage {
    case notAClass
    case missingReducer(actionName: String)
    
    var message: String {
        switch self {
        case .notAClass:
            return "@Context can only be applied to class declarations"
        case .missingReducer(let actionName):
            return "Missing reducer for action '\(actionName)'"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros", id: "context-diagnostic")
    }
    
    var severity: DiagnosticSeverity { .error }
}

enum ContextMacroFixIt: String, FixItMessage {
    case useClass = "Replace 'struct' with 'class'"
    
    var message: String { self.rawValue }
    var fixItID: MessageID {
        MessageID(domain: "AxiomMacros", id: rawValue)
    }
}

// MARK: - Public Macro Declaration

@attached(member, names: named(DerivedState), named(PresentationActions))
public macro Context() = #externalMacro(module: "AxiomMacros", type: "ContextMacro")