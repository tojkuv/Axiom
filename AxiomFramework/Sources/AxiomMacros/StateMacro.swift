import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - State Macro

/// The @State macro generates state implementation
/// Enforces immutable value object patterns
public struct StateMacro: MemberMacro {
    
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
                    message: StateMacroDiagnostic.notAStruct,
                    highlights: [Syntax(node)],
                    fixIts: [
                        FixIt(
                            message: StateMacroFixIt.useStruct,
                            changes: [
                                .replace(
                                    oldNode: Syntax(node),
                                    newNode: Syntax(StringLiteralExprSyntax(content: "Apply @State to a struct"))
                                )
                            ]
                        )
                    ]
                )
            )
            return []
        }
        
        // Check if there's already an init()
        let hasDefaultInit = structDecl.memberBlock.members.contains { member in
            if let initDecl = member.decl.as(InitializerDeclSyntax.self) {
                return initDecl.signature.parameterClause.parameters.isEmpty
            }
            return false
        }
        
        // If there's already a default init, don't generate one
        if hasDefaultInit {
            return []
        }
        
        // Extract properties that need initialization
        var propertiesToInit: [(name: String, type: TypeSyntax, isLet: Bool, isOptional: Bool)] = []
        
        for member in structDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                // Skip computed properties
                if varDecl.bindings.contains(where: { binding in
                    if case .getter = binding.accessorBlock?.accessors {
                        return true
                    }
                    return false
                }) {
                    continue
                }
                
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                       let type = binding.typeAnnotation?.type {
                        let isLet = varDecl.bindingSpecifier.tokenKind == .keyword(.let)
                        let isOptional = type.is(OptionalTypeSyntax.self) || type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)
                        propertiesToInit.append((
                            name: identifier.identifier.text,
                            type: type,
                            isLet: isLet,
                            isOptional: isOptional
                        ))
                    }
                }
            }
        }
        
        // Generate initializer body
        var initStatements: [String] = []
        for property in propertiesToInit {
            let defaultValue = generateDefaultValue(for: property.type, isOptional: property.isOptional)
            initStatements.append("self.\(property.name) = \(defaultValue)")
        }
        
        // Extract access level
        let accessLevel = extractAccessLevel(from: structDecl)
        
        // Generate initializer body
        var initBody: [String] = []
        for property in propertiesToInit {
            let defaultValue = generateDefaultValue(for: property.type, isOptional: property.isOptional)
            initBody.append("self.\(property.name) = \(defaultValue)")
        }
        
        // Build the init method as a string with exact formatting
        let accessModifier = accessLevel.isEmpty ? "" : "\(accessLevel) "
        
        // Build the init declaration without extra indentation
        // The macro framework will add its own indentation
        var initDecl = "\n"
        initDecl += "\(accessModifier)init() {\n"
        for line in initBody {
            initDecl += "    \(line)\n"
        }
        initDecl += "}"
        
        return [DeclSyntax(stringLiteral: initDecl)]
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
    
    /// Generate default value for a type
    private static func generateDefaultValue(for type: TypeSyntax, isOptional: Bool) -> String {
        if isOptional {
            return "nil"
        }
        
        // Handle dictionary types (check first before array)
        if type.is(DictionaryTypeSyntax.self) || (type.description.contains("[") && type.description.contains(":")) {
            return "[:]"
        }
        
        // Handle array types
        if type.is(ArrayTypeSyntax.self) || type.description.contains("[") {
            return "[]"
        }
        
        // Handle basic types
        let typeString = type.trimmedDescription
        switch typeString {
        case "String":
            return "\"\""
        case "Int", "Int8", "Int16", "Int32", "Int64":
            return "0"
        case "UInt", "UInt8", "UInt16", "UInt32", "UInt64":
            return "0"
        case "Float", "Double", "CGFloat":
            return "0.0"
        case "Bool":
            return "false"
        default:
            // For custom types, try to call their init()
            return "\(typeString)()"
        }
    }
}

// MARK: - Diagnostic Messages

enum StateMacroDiagnostic: String, DiagnosticMessage {
    case notAStruct = "@State can only be applied to struct declarations"
    
    var message: String { self.rawValue }
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros", id: rawValue)
    }
    var severity: DiagnosticSeverity { .error }
}

enum StateMacroFixIt: String, FixItMessage {
    case useStruct = "Replace 'class' with 'struct'"
    
    var message: String { self.rawValue }
    var fixItID: MessageID {
        MessageID(domain: "AxiomMacros", id: rawValue)
    }
}

// MARK: - Public Macro Declaration

@attached(member, names: named(init))
public macro State() = #externalMacro(module: "AxiomMacros", type: "StateMacro")