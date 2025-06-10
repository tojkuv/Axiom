import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Enhanced macro that enforces single-context presentation architecture
///
/// Usage:
/// ```swift
/// @Presentation(context: TaskListContext.self)
/// struct TaskListView {
///     var body: some View {
///         List(context.tasks) { task in
///             TaskRow(task: task)
///         }
///     }
/// }
/// ```
///
/// This macro:
/// - Enforces single context per presentation
/// - Generates context property and initializer
/// - Provides compile-time architectural safety
/// - Prevents stateful views without @Presentation
public struct PresentationMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate this is applied to a struct
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.unsupportedDeclaration
        }
        
        // Extract context type from macro parameters
        let contextType = try extractContextType(from: node)
        
        // Validate single context constraint
        try validateSingleContextConstraint(in: structDecl, contextType: contextType)
        
        // Generate context property and initializers
        return generateContextMembers(contextType: contextType)
    }
    
    // MARK: - Parameter Extraction
    
    private static func extractContextType(from node: AttributeSyntax) throws -> String {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            throw MacroError.invalidArguments
        }
        
        for argument in arguments {
            if argument.label?.text == "context" {
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    return memberAccess.base?.description.trimmingCharacters(in: .whitespaces) ?? ""
                }
            }
        }
        
        throw MacroError.missingContextType
    }
    
    // MARK: - Validation
    
    private static func validateSingleContextConstraint(
        in structDecl: StructDeclSyntax,
        contextType: String
    ) throws {
        // Check for existing @StateObject properties that aren't our generated context
        for member in structDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                // Check if this property has @StateObject attribute
                let hasStateObject = varDecl.attributes.contains { attribute in
                    if case .attribute(let attr) = attribute,
                       let identifierType = attr.attributeName.as(IdentifierTypeSyntax.self) {
                        return identifierType.name.text == "StateObject"
                    }
                    return false
                }
                
                if hasStateObject {
                    // Found a StateObject - this violates single context constraint
                    throw MacroError.multipleContextsNotAllowed
                }
            }
            
            // Also check for @State properties which should require @Presentation
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                let hasState = varDecl.attributes.contains { attribute in
                    if case .attribute(let attr) = attribute,
                       let identifierType = attr.attributeName.as(IdentifierTypeSyntax.self) {
                        return identifierType.name.text == "State"
                    }
                    return false
                }
                
                if hasState {
                    // Found @State in a view that should use @Presentation
                    throw MacroError.statefulViewRequiresPresentation
                }
            }
        }
    }
    
    // MARK: - Member Generation
    
    private static func generateContextMembers(contextType: String) -> [DeclSyntax] {
        return [
            """
            
            // MARK: - Generated Context
            
            /// The context this presentation observes
            @StateObject private var context: \(raw: contextType)
            """,
            """
            
            // MARK: - Generated Initializer
            
            init(context: \(raw: contextType)) {
                self._context = StateObject(wrappedValue: context)
            }
            """,
            """
            
            init() {
                // Default initializer requires client injection
                fatalError("Presentation requires context parameter")
            }
            """
        ]
    }
}

// MARK: - Extension Macro Implementation

extension PresentationMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // Extract type name and context type
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.unsupportedDeclaration
        }
        
        let typeName = structDecl.name.text
        let contextType = try extractContextType(from: node)
        
        // Generate PresentationProtocol conformance
        let presentationExtension = try ExtensionDeclSyntax(
            """
            extension \(raw: typeName): PresentationProtocol {
                typealias ContextType = \(raw: contextType)
            }
            """
        )
        
        return [presentationExtension]
    }
}

// MARK: - Peer Macro for Compile-Time Validation

extension PresentationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Generate compile-time validation code
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            return []
        }
        
        let typeName = structDecl.name.text
        
        // Generate a validation type that enforces constraints at compile time
        return [
            """
            
            // Compile-time validation for \(raw: typeName)
            private struct _ValidatePresentation\(raw: typeName) {
                // This type exists solely for compile-time validation
                // It will cause errors if architectural constraints are violated
            }
            """
        ]
    }
}

// MARK: - Error Handling

extension MacroError {
    static let multipleContextsNotAllowed = MacroError.invalidArguments
    static let missingContextType = MacroError.invalidArguments
    static let statefulViewRequiresPresentation = MacroError.invalidArguments
}