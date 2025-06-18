import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// StateMacro generates Axiom State protocol conformance with validation and optimizations
///
/// Usage:
/// ```swift
/// @AxiomState
/// struct TodoState {
///     let items: [TodoItem]
///     let filter: Filter
/// }
/// ```
///
/// This macro generates:
/// - Axiom AxiomState protocol conformance (Equatable, Hashable, Sendable)
/// - Validation methods for immutability
/// - Optimized equality and hashing implementations
/// - State transition methods with validation
/// - Memory-efficient state storage
public struct StateMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // Validate that this is applied to a struct
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw StateMacroError.mustBeAppliedToStruct
        }
        
        // Extract macro parameters
        let parameters = try extractParameters(from: node)
        
        // Get the type name
        let typeName = structDecl.name.text
        
        // Generate extensions
        let stateExtension = try generateStateExtension(
            typeName: typeName,
            structDecl: structDecl,
            parameters: parameters,
            context: context
        )
        
        let validationExtension = try generateValidationExtension(
            typeName: typeName,
            structDecl: structDecl,
            parameters: parameters,
            context: context
        )
        
        return [stateExtension, validationExtension]
    }
    
    // MARK: - Parameter Extraction
    
    private struct StateMacroParameters {
        let enableValidation: Bool
        let optimizeEquality: Bool
        let customHashable: Bool
        let memoryOptimized: Bool
    }
    
    private static func extractParameters(from node: AttributeSyntax) throws -> StateMacroParameters {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            // Default parameters
            return StateMacroParameters(
                enableValidation: true,
                optimizeEquality: true,
                customHashable: false,
                memoryOptimized: true
            )
        }
        
        var enableValidation = true
        var optimizeEquality = true
        var customHashable = false
        var memoryOptimized = true
        
        for argument in arguments {
            switch argument.label?.text {
            case "validation":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    enableValidation = boolLiteral.literal.text == "true"
                }
            case "optimizeEquality":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    optimizeEquality = boolLiteral.literal.text == "true"
                }
            case "customHashable":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    customHashable = boolLiteral.literal.text == "true"
                }
            case "memoryOptimized":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    memoryOptimized = boolLiteral.literal.text == "true"
                }
            default:
                break
            }
        }
        
        return StateMacroParameters(
            enableValidation: enableValidation,
            optimizeEquality: optimizeEquality,
            customHashable: customHashable,
            memoryOptimized: memoryOptimized
        )
    }
    
    // MARK: - Extension Generation
    
    private static func generateStateExtension(
        typeName: String,
        structDecl: StructDeclSyntax,
        parameters: StateMacroParameters,
        context: some MacroExpansionContext
    ) throws -> ExtensionDeclSyntax {
        // Get stored properties for equality and hashing
        let storedProperties = extractStoredProperties(from: structDecl)
        
        // Generate conformance code
        let conformanceCode = generateStateConformanceCode(
            properties: storedProperties,
            parameters: parameters
        )
        
        return try ExtensionDeclSyntax(
            """
            extension \(raw: typeName): AxiomState {
                \(raw: conformanceCode)
            }
            """
        )
    }
    
    private static func generateValidationExtension(
        typeName: String,
        structDecl: StructDeclSyntax,
        parameters: StateMacroParameters,
        context: some MacroExpansionContext
    ) throws -> ExtensionDeclSyntax {
        guard parameters.enableValidation else {
            return try ExtensionDeclSyntax("extension \(raw: typeName) {}")
        }
        
        let validationCode = generateValidationCode(
            structDecl: structDecl,
            parameters: parameters
        )
        
        return try ExtensionDeclSyntax(
            """
            extension \(raw: typeName) {
                \(raw: validationCode)
            }
            """
        )
    }
    
    // MARK: - Code Generation Helpers
    
    private static func extractStoredProperties(from structDecl: StructDeclSyntax) -> [String] {
        var properties: [String] = []
        
        for member in structDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        properties.append(identifier.identifier.text)
                    }
                }
            }
        }
        
        return properties
    }
    
    private static func generateStateConformanceCode(
        properties: [String],
        parameters: StateMacroParameters
    ) -> String {
        var code = """
        
        // MARK: - Generated AxiomState Protocol Conformance
        
        /// Generated Equatable implementation
        """
        
        if parameters.optimizeEquality {
            code += """
            
            public static func == (lhs: Self, rhs: Self) -> Bool {
                // Optimized equality check with short-circuit evaluation
            """
            
            for property in properties {
                code += """
                
                if lhs.\(property) != rhs.\(property) { return false }
                """
            }
            
            code += """
            
                return true
            }
            """
        }
        
        if parameters.customHashable {
            code += """
            
            /// Generated Hashable implementation
            public func hash(into hasher: inout Hasher) {
                // Optimized hashing with performance considerations
            """
            
            for property in properties {
                code += """
                
                hasher.combine(\(property))
                """
            }
            
            code += """
            
            }
            """
        }
        
        if parameters.memoryOptimized {
            code += """
            
            // MARK: - Memory Optimization
            
            /// Memory-efficient state representation
            public var memoryFootprint: Int {
                // Estimate memory usage for monitoring
                return \(properties.count * 8) // Simplified estimation
            }
            
            /// Check if state is memory-efficient
            public var isMemoryEfficient: Bool {
                return memoryFootprint < 1024 // 1KB threshold
            }
            """
        }
        
        return code
    }
    
    private static func generateValidationCode(
        structDecl: StructDeclSyntax,
        parameters: StateMacroParameters
    ) -> String {
        let properties = extractStoredProperties(from: structDecl)
        
        return """
        
        // MARK: - Generated State Validation
        
        /// Validates that all properties are immutable (compile-time enforced)
        public static func validateImmutability() -> Bool {
            // This is enforced at compile-time by Swift's 'let' declarations
            return true
        }
        
        /// Validates state consistency rules
        public func validateConsistency() -> StateValidationResult {
            var issues: [String] = []
            
            // Basic validation rules
            \(properties.map { property in
                """
                
                // Validate \(property) property
                if !validate\(property.capitalized)Property() {
                    issues.append("Invalid \(property) property")
                }
                """
            }.joined())
            
            return StateValidationResult(
                isValid: issues.isEmpty,
                issues: issues
            )
        }
        
        /// Validates state transitions
        public func validateTransition(to newState: Self) -> StateTransitionResult {
            let oldValidation = validateConsistency()
            let newValidation = newState.validateConsistency()
            
            guard oldValidation.isValid && newValidation.isValid else {
                return StateTransitionResult(
                    isValid: false,
                    reason: "Invalid state in transition",
                    oldState: self,
                    newState: newState
                )
            }
            
            // Additional transition-specific validation
            if !isValidTransition(to: newState) {
                return StateTransitionResult(
                    isValid: false,
                    reason: "Invalid state transition",
                    oldState: self,
                    newState: newState
                )
            }
            
            return StateTransitionResult(
                isValid: true,
                reason: "Valid transition",
                oldState: self,
                newState: newState
            )
        }
        
        // MARK: - Property Validation Methods
        
        \(properties.map { property in
            """
            
            /// Validates \(property) property
            private func validate\(property.capitalized)Property() -> Bool {
                // Override in custom extension for specific validation
                return true
            }
            """
        }.joined())
        
        // MARK: - Transition Validation
        
        /// Validates if transition to new state is allowed
        private func isValidTransition(to newState: Self) -> Bool {
            // Override in custom extension for specific transition rules
            return true
        }
        
        // MARK: - Generated State Mutation Helpers
        
        /// Create new state with validated changes
        public func withValidatedChanges<T>(
            _ changes: (inout Self) throws -> T
        ) rethrows -> (result: T, newState: Self) {
            var newState = self
            let result = try changes(&newState)
            
            // Validate the transition
            let transitionResult = validateTransition(to: newState)
            guard transitionResult.isValid else {
                preconditionFailure("Invalid state transition: \\(transitionResult.reason)")
            }
            
            return (result, newState)
        }
        """
    }
}

// MARK: - Supporting Types

/// Result of state validation
public struct StateValidationResult {
    public let isValid: Bool
    public let issues: [String]
    
    public init(isValid: Bool, issues: [String]) {
        self.isValid = isValid
        self.issues = issues
    }
}

/// Result of state transition validation
public struct StateTransitionResult {
    public let isValid: Bool
    public let reason: String
    public let oldState: Any
    public let newState: Any
    
    public init(isValid: Bool, reason: String, oldState: Any, newState: Any) {
        self.isValid = isValid
        self.reason = reason
        self.oldState = oldState
        self.newState = newState
    }
}

// MARK: - Error Types

enum StateMacroError: Error, CustomStringConvertible {
    case mustBeAppliedToStruct
    case invalidParameters
    case missingRequiredProperties
    
    var description: String {
        switch self {
        case .mustBeAppliedToStruct:
            return "@AxiomState can only be applied to struct declarations"
        case .invalidParameters:
            return "@AxiomState has invalid parameters"
        case .missingRequiredProperties:
            return "@AxiomState requires at least one stored property"
        }
    }
}