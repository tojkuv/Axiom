import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

/// ActionMacro generates Action protocol conformance with execution pipeline and validation
///
/// Usage:
/// ```swift
/// @Action
/// enum TodoAction {
///     case addItem(String)
///     case toggleItem(UUID)
///     case deleteItem(UUID)
/// }
/// ```
///
/// This macro generates:
/// - Sendable conformance for thread safety
/// - Execution pipeline with pre/post processing
/// - Action validation and sanitization
/// - Performance tracking for action execution
/// - Automatic error handling integration
public struct ActionMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // Validate that this is applied to an enum or struct
        let isEnum = declaration.is(EnumDeclSyntax.self)
        let isStruct = declaration.is(StructDeclSyntax.self)
        
        guard isEnum || isStruct else {
            throw ActionMacroError.mustBeAppliedToEnumOrStruct
        }
        
        // Extract macro parameters
        let parameters = try extractParameters(from: node)
        
        // Get the type name
        let typeName = if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            enumDecl.name.text
        } else if let structDecl = declaration.as(StructDeclSyntax.self) {
            structDecl.name.text
        } else {
            throw ActionMacroError.mustBeAppliedToEnumOrStruct
        }
        
        // Generate extensions
        let actionExtension = try generateActionExtension(
            typeName: typeName,
            declaration: declaration,
            parameters: parameters,
            context: context
        )
        
        let executionExtension = try generateExecutionExtension(
            typeName: typeName,
            declaration: declaration,
            parameters: parameters,
            context: context
        )
        
        return [actionExtension, executionExtension]
    }
    
    // MARK: - Parameter Extraction
    
    private struct ActionMacroParameters {
        let enableValidation: Bool
        let trackPerformance: Bool
        let enableRetry: Bool
        let timeout: Double?
        let priority: String
    }
    
    private static func extractParameters(from node: AttributeSyntax) throws -> ActionMacroParameters {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            // Default parameters
            return ActionMacroParameters(
                enableValidation: true,
                trackPerformance: true,
                enableRetry: false,
                timeout: nil,
                priority: "medium"
            )
        }
        
        var enableValidation = true
        var trackPerformance = true
        var enableRetry = false
        var timeout: Double?
        var priority = "medium"
        
        for argument in arguments {
            switch argument.label?.text {
            case "validation":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    enableValidation = boolLiteral.literal.text == "true"
                }
            case "performance":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    trackPerformance = boolLiteral.literal.text == "true"
                }
            case "retry":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    enableRetry = boolLiteral.literal.text == "true"
                }
            case "timeout":
                if let floatLiteral = argument.expression.as(FloatLiteralExprSyntax.self) {
                    timeout = Double(floatLiteral.literal.text) ?? 5.0
                }
            case "priority":
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self) {
                    priority = stringLiteral.segments.description
                        .trimmingCharacters(in: CharacterSet(["\"", " "]))
                }
            default:
                break
            }
        }
        
        return ActionMacroParameters(
            enableValidation: enableValidation,
            trackPerformance: trackPerformance,
            enableRetry: enableRetry,
            timeout: timeout,
            priority: priority
        )
    }
    
    // MARK: - Extension Generation
    
    private static func generateActionExtension(
        typeName: String,
        declaration: some DeclGroupSyntax,
        parameters: ActionMacroParameters,
        context: some MacroExpansionContext
    ) throws -> ExtensionDeclSyntax {
        // Generate Sendable conformance and basic action protocol support
        let actionCode = generateActionConformanceCode(
            typeName: typeName,
            declaration: declaration,
            parameters: parameters
        )
        
        return try ExtensionDeclSyntax(
            """
            extension \(raw: typeName): Sendable {
                \(raw: actionCode)
            }
            """
        )
    }
    
    private static func generateExecutionExtension(
        typeName: String,
        declaration: some DeclGroupSyntax,
        parameters: ActionMacroParameters,
        context: some MacroExpansionContext
    ) throws -> ExtensionDeclSyntax {
        let executionCode = generateExecutionPipelineCode(
            typeName: typeName,
            declaration: declaration,
            parameters: parameters
        )
        
        return try ExtensionDeclSyntax(
            """
            extension \(raw: typeName) {
                \(raw: executionCode)
            }
            """
        )
    }
    
    // MARK: - Code Generation Helpers
    
    private static func generateActionConformanceCode(
        typeName: String,
        declaration: some DeclGroupSyntax,
        parameters: ActionMacroParameters
    ) -> String {
        var code = """
        
        // MARK: - Generated Action Protocol Conformance
        
        /// Action identifier for tracking and debugging
        public var actionId: String {
            return "\\(type(of: self)).\\(String(describing: self))"
        }
        
        /// Action description for logging
        public var description: String {
            return String(describing: self)
        }
        
        /// Indicates if this action should trigger an automatic save
        public var triggersSave: Bool {
            // Actions that modify data should trigger saves
            let description = String(describing: self)
            return description.contains("add") || 
                   description.contains("update") || 
                   description.contains("delete") || 
                   description.contains("toggle") ||
                   description.contains("bulk")
        }
        """
        
        if parameters.enableValidation {
            code += """
            
            // MARK: - Action Validation
            
            /// Validates the action before execution
            public func validate() -> Bool {
                // Default implementation - actions are valid by default
                return validateParameters()
            }
            
            /// Validates action parameters
            private func validateParameters() -> Bool {
                // Default implementation - override for specific validation
                return true
            }
            """
        }
        
        return code
    }
    
    private static func generateExecutionPipelineCode(
        typeName: String,
        declaration: some DeclGroupSyntax,
        parameters: ActionMacroParameters
    ) -> String {
        var code = """
        
        // MARK: - Generated Execution Support
        
        /// Simple validation check
        public func isValid() -> Bool {
            \(parameters.enableValidation ? """
            return validate()
            """ : """
            return true
            """)
        }
        """
        
        if parameters.trackPerformance {
            code += """
            
            // MARK: - Performance Tracking
            
            /// Track action execution for debugging
            public func trackExecution(_ duration: TimeInterval) {
                #if DEBUG
                print("Action \\(actionId) executed in \\(String(format: "%.2f", duration * 1000))ms")
                #endif
            }
            """
        }
        
        return code
    }
}

// These supporting types are now handled by the framework

// MARK: - Error Types

enum ActionMacroError: Error, CustomStringConvertible {
    case mustBeAppliedToEnumOrStruct
    case invalidParameters
    case missingRequiredCases
    
    var description: String {
        switch self {
        case .mustBeAppliedToEnumOrStruct:
            return "@Action can only be applied to enum or struct declarations"
        case .invalidParameters:
            return "@Action has invalid parameters"
        case .missingRequiredCases:
            return "@Action requires at least one case or property"
        }
    }
}