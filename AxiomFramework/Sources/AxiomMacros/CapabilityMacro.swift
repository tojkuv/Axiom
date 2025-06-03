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
        // Parse macro parameters
        var isRequired = false
        var fallbackMode = ""
        var compileTimeOptimized = false
        var includeErrorHandler = false
        
        if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
            for argument in arguments {
                switch argument.label?.text {
                case "required":
                    if let boolExpr = argument.expression.as(BooleanLiteralExprSyntax.self) {
                        isRequired = boolExpr.literal.tokenKind == .keyword(.true)
                    }
                case "fallback":
                    if let stringExpr = argument.expression.as(StringLiteralExprSyntax.self),
                       let value = stringExpr.representedLiteralValue {
                        fallbackMode = value
                    }
                case "compileTime":
                    if let boolExpr = argument.expression.as(BooleanLiteralExprSyntax.self) {
                        compileTimeOptimized = boolExpr.literal.tokenKind == .keyword(.true)
                    }
                case "errorHandler":
                    if let boolExpr = argument.expression.as(BooleanLiteralExprSyntax.self) {
                        includeErrorHandler = boolExpr.literal.tokenKind == .keyword(.true)
                    }
                default:
                    break
                }
            }
        }
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
        
        var generatedMembers: [DeclSyntax] = []
        
        // Only generate enhanced functionality if any parameters are specified
        let enhancedMode = isRequired || !fallbackMode.isEmpty || compileTimeOptimized || includeErrorHandler
        
        // Generate static properties for parameters if provided
        if isRequired || !fallbackMode.isEmpty {
            if isRequired {
                let requiredDecl = """
                
                /// Indicates if this capability is required for the application
                public static let isRequired = true
                """
                generatedMembers.append(DeclSyntax(stringLiteral: requiredDecl))
            }
            
            if !fallbackMode.isEmpty {
                let fallbackDecl = """
                
                /// Fallback mode when capability is not available
                public static let fallbackMode = "\(fallbackMode)"
                """
                generatedMembers.append(DeclSyntax(stringLiteral: fallbackDecl))
            }
        }
        
        // Generate isAvailable if it doesn't exist
        if !hasIsAvailable {
            let isAvailableDecl: String
            if compileTimeOptimized {
                isAvailableDecl = """
                
                @inlinable
                public func isAvailable() -> Bool {
                    #if DEBUG
                    return true
                    #else
                    return false
                    #endif
                }
                """
            } else {
                isAvailableDecl = """
                
                public func isAvailable() -> Bool {
                    true
                }
                """
            }
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
        
        // Generate runtime validation methods only in enhanced mode
        if enhancedMode {
            // Request permission method
            let requestPermissionDecl: String
        if compileTimeOptimized {
            requestPermissionDecl = """
            
            /// Request permission for this capability
            @inlinable
            public func requestPermission() async -> Bool {
                // Default implementation - override for platform-specific behavior
                return isAvailable()
            }
            """
        } else {
            requestPermissionDecl = """
            
            /// Request permission for this capability
            public func requestPermission() async -> Bool {
                // Default implementation - override for platform-specific behavior
                return isAvailable()
            }
            """
        }
        generatedMembers.append(DeclSyntax(stringLiteral: requestPermissionDecl))
        
        // Validate method
        let validateDecl: String
        if compileTimeOptimized {
            validateDecl = """
            
            /// Validate capability requirements
            @inlinable
            public func validate() -> Result<Void, CapabilityError> {
                if isAvailable() {
                    return .success(())
                } else {
                    return .failure(.notAvailable(id))
                }
            }
            """
        } else {
            validateDecl = """
            
            /// Validate capability requirements
            public func validate() -> Result<Void, CapabilityError> {
                if isAvailable() {
                    return .success(())
                } else {
                    return .failure(.notAvailable(id))
                }
            }
            """
        }
        generatedMembers.append(DeclSyntax(stringLiteral: validateDecl))
        
        // Check with fallback method
        let checkWithFallbackDecl: String
        if compileTimeOptimized {
            if !fallbackMode.isEmpty {
                checkWithFallbackDecl = """
                
                /// Check if capability can be used with graceful degradation
                @inlinable
                public func checkWithFallback() -> CapabilityStatus {
                    if isAvailable() {
                        return .available
                    } else if Self.fallbackMode != "" {
                        return .degraded(reason: "Using fallback: \\(Self.fallbackMode)")
                    } else {
                        return .unavailable(reason: "Required capability \\(id) is not available")
                    }
                }
                """
            } else {
                checkWithFallbackDecl = """
                
                /// Check if capability can be used with graceful degradation
                @inlinable
                public func checkWithFallback() -> CapabilityStatus {
                    if isAvailable() {
                        return .available
                    } else {
                        return .degraded(reason: "Capability \\(id) is not available")
                    }
                }
                """
            }
        } else {
            if !fallbackMode.isEmpty {
                checkWithFallbackDecl = """
                
                /// Check if capability can be used with graceful degradation
                public func checkWithFallback() -> CapabilityStatus {
                    if isAvailable() {
                        return .available
                    } else if Self.fallbackMode != "" {
                        return .degraded(reason: "Using fallback: \\(Self.fallbackMode)")
                    } else {
                        return .unavailable(reason: "Required capability \\(id) is not available")
                    }
                }
                """
            } else {
                checkWithFallbackDecl = """
                
                /// Check if capability can be used with graceful degradation
                public func checkWithFallback() -> CapabilityStatus {
                    if isAvailable() {
                        return .available
                    } else {
                        return .degraded(reason: "Capability \\(id) is not available")
                    }
                }
                """
            }
        }
        generatedMembers.append(DeclSyntax(stringLiteral: checkWithFallbackDecl))
        
            // Generate error handling methods if requested
            if includeErrorHandler {
                let errorHandlerDecl = """
                
                /// Handle errors related to this capability
                public func handleError(_ error: Error) -> CapabilityError {
                    if let capError = error as? CapabilityError {
                        return capError
                    } else {
                        return .operationFailed(capability: id, reason: error.localizedDescription)
                    }
                }
                
                /// Perform operation with automatic error handling
                public func performWithErrorHandling<T>(_ operation: () throws -> T) -> Result<T, CapabilityError> {
                    do {
                        let result = try operation()
                        return .success(result)
                    } catch {
                        return .failure(handleError(error))
                    }
                }
                """
                generatedMembers.append(DeclSyntax(stringLiteral: errorHandlerDecl))
            }
        } // end of enhancedMode block
        
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
public macro Capability(
    required: Bool = false,
    fallback: String = "",
    compileTime: Bool = false,
    errorHandler: Bool = false
) = #externalMacro(module: "AxiomMacros", type: "CapabilityMacro")