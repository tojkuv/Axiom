import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - Capability Macro

/// The @Capability macro generates capability validation implementation
/// Creates runtime validation with compile-time optimization
public struct CapabilityMacro: MemberMacro {
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
                    message: CapabilityMacroDiagnostic.notAStruct,
                    highlights: [Syntax(node)],
                    fixIts: [
                        FixIt(
                            message: CapabilityMacroFixIt.useStruct,
                            changes: [
                                .replace(
                                    oldNode: Syntax(node),
                                    newNode: Syntax(StringLiteralExprSyntax(content: "Apply @Capability to a struct"))
                                )
                            ]
                        )
                    ]
                )
            )
            return []
        }
        
        // Check if id property exists
        let hasId = structDecl.memberBlock.members.contains { member in
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                return varDecl.bindings.contains { binding in
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        return identifier.identifier.text == "id"
                    }
                    return false
                }
            }
            return false
        }
        
        // If no id property, produce diagnostic
        if !hasId {
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: CapabilityMacroDiagnostic.missingId,
                    highlights: [Syntax(node)],
                    fixIts: [
                        FixIt(
                            message: CapabilityMacroFixIt.addId,
                            changes: [
                                .replace(
                                    oldNode: Syntax(node),
                                    newNode: Syntax(StringLiteralExprSyntax(content: "Add id property"))
                                )
                            ]
                        )
                    ]
                )
            )
            return []
        }
        
        // Check if isAvailable method already exists
        let hasIsAvailable = structDecl.memberBlock.members.contains { member in
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                return funcDecl.name.text == "isAvailable"
            }
            return false
        }
        
        // Check if description property already exists
        let hasDescription = structDecl.memberBlock.members.contains { member in
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                return varDecl.bindings.contains { binding in
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        return identifier.identifier.text == "description"
                    }
                    return false
                }
            }
            return false
        }
        
        // If both already exist, don't generate anything
        if hasIsAvailable && hasDescription {
            return []
        }
        
        var generatedMembers: [DeclSyntax] = []
        
        // Generate isAvailable if it doesn't exist
        if !hasIsAvailable {
            let isAvailableDecl = """
            
            public func isAvailable() -> Bool {
                true
            }
            """
            generatedMembers.append(DeclSyntax(stringLiteral: isAvailableDecl))
        }
        
        // Generate description if it doesn't exist
        if !hasDescription {
            let descriptionDecl = """
            
            public var description: String {
                "\\(id)"
            }
            """
            generatedMembers.append(DeclSyntax(stringLiteral: descriptionDecl))
        }
        
        return generatedMembers
    }
}

// MARK: - Diagnostic Messages

enum CapabilityMacroDiagnostic: String, DiagnosticMessage {
    case notAStruct = "@Capability can only be applied to structs"
    case missingId = "@Capability requires an 'id' property"
    
    var message: String { self.rawValue }
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros", id: rawValue)
    }
    var severity: DiagnosticSeverity { .error }
}

enum CapabilityMacroFixIt: String, FixItMessage {
    case useStruct = "Change to 'struct'"
    case addId = "Add 'let id: String' property"
    
    var message: String { self.rawValue }
    var fixItID: MessageID {
        MessageID(domain: "AxiomMacros", id: rawValue)
    }
}

// MARK: - Public Macro Declaration

@attached(member, names: arbitrary)
public macro Capability() = #externalMacro(module: "AxiomMacros", type: "CapabilityMacro")