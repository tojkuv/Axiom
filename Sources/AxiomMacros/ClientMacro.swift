import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - @Client Macro Implementation

/// The @Client macro for automatic client dependency injection
/// Applied to properties in AxiomContext structs to generate boilerplate code
public struct ClientMacro: MemberMacro, AxiomMacro {
    public static var macroName: String { "Client" }
    
    public static func validateDeclaration<D: DeclSyntaxProtocol>(_ declaration: D, in context: some MacroExpansionContext) throws {
        // Validation is performed during expansion to provide better context
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Validate this is applied to a struct that conforms to AxiomContext
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: ClientMacroDiagnostic.onlyOnStructs
                )
            )
            return []
        }
        
        guard SyntaxUtilities.conformsToProtocol(structDecl, protocolName: "AxiomContext") else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: ClientMacroDiagnostic.mustConformToAxiomContext
                )
            )
            return []
        }
        
        // Find all properties marked with @Client
        let members = SyntaxUtilities.extractMembers(from: structDecl) ?? MemberBlockItemListSyntax([])
        let clientProperties = SyntaxUtilities.findProperties(withAttribute: "Client", in: members)
        
        guard !clientProperties.isEmpty else {
            // No @Client properties found, nothing to generate
            return []
        }
        
        // Validate client properties
        for property in clientProperties {
            try validateClientProperty(property, in: context)
        }
        
        // Generate the boilerplate code
        var generatedMembers: [DeclSyntax] = []
        
        // 1. Generate private stored properties
        for property in clientProperties {
            if let privateProperty = try generatePrivateProperty(for: property) {
                generatedMembers.append(DeclSyntax(privateProperty))
            }
        }
        
        // 2. Generate public computed properties
        for property in clientProperties {
            if let computedProperty = try generateComputedProperty(for: property) {
                generatedMembers.append(DeclSyntax(computedProperty))
            }
        }
        
        // 3. Generate initializer
        if let initializer = try generateInitializer(for: clientProperties, structName: structDecl.name.text) {
            generatedMembers.append(DeclSyntax(initializer))
        }
        
        // 4. Generate deinit
        if let deinitDecl = try generateDeinitializer(for: clientProperties) {
            generatedMembers.append(DeclSyntax(deinitDecl))
        }
        
        return generatedMembers
    }
    
    // MARK: - Validation
    
    private static func validateClientProperty(_ property: VariableDeclSyntax, in context: some MacroExpansionContext) throws {
        guard let binding = property.bindings.first,
              let _ = binding.pattern.as(IdentifierPatternSyntax.self),
              let typeAnnotation = binding.typeAnnotation else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: property,
                    message: ClientMacroDiagnostic.invalidPropertyDeclaration
                )
            )
            return
        }
        
        // Validate that it's a var declaration
        guard property.bindingSpecifier.tokenKind == .keyword(.var) else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: property,
                    message: ClientMacroDiagnostic.mustBeVar
                )
            )
            return
        }
        
        // Validate that it doesn't have an initializer
        guard binding.initializer == nil else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: property,
                    message: ClientMacroDiagnostic.cannotHaveInitializer
                )
            )
            return
        }
        
        // Validate that the type conforms to AxiomClient (this is a simplified check)
        let typeName = typeAnnotation.type.trimmedDescription
        if !typeName.hasSuffix("Client") {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: property,
                    message: ClientMacroDiagnostic.mustConformToAxiomClient
                )
            )
        }
    }
    
    // MARK: - Code Generation
    
    private static func generatePrivateProperty(for property: VariableDeclSyntax) throws -> VariableDeclSyntax? {
        guard let binding = property.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              let typeAnnotation = binding.typeAnnotation else {
            return nil
        }
        
        let propertyName = pattern.identifier.text
        let privatePropertyName = "_\(propertyName)"
        
        return CodeGenerationUtilities.createStoredProperty(
            name: privatePropertyName,
            type: typeAnnotation.type,
            isPrivate: true,
            isLet: true
        )
    }
    
    private static func generateComputedProperty(for property: VariableDeclSyntax) throws -> VariableDeclSyntax? {
        guard let binding = property.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              let typeAnnotation = binding.typeAnnotation else {
            return nil
        }
        
        let propertyName = pattern.identifier.text
        let privatePropertyName = "_\(propertyName)"
        
        let getter = CodeBlockItemListSyntax([
            CodeBlockItemSyntax(
                item: .expr(ExprSyntax(
                    DeclReferenceExprSyntax(baseName: .identifier(privatePropertyName))
                ))
            )
        ])
        
        return CodeGenerationUtilities.createComputedProperty(
            name: propertyName,
            type: typeAnnotation.type,
            isPublic: false,
            getter: getter
        )
    }
    
    private static func generateInitializer(
        for properties: [VariableDeclSyntax],
        structName: String
    ) throws -> InitializerDeclSyntax? {
        var parameters: [FunctionParameterSyntax] = []
        var assignmentStatements: [CodeBlockItemSyntax] = []
        var observerRegistrations: [CodeBlockItemSyntax] = []
        
        for property in properties {
            guard let binding = property.bindings.first,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  let typeAnnotation = binding.typeAnnotation else {
                continue
            }
            
            let propertyName = pattern.identifier.text
            let privatePropertyName = "_\(propertyName)"
            
            // Create parameter
            let parameter = CodeGenerationUtilities.createParameter(
                name: propertyName,
                type: typeAnnotation.type
            )
            parameters.append(parameter)
            
            // Create assignment statement
            let assignment = CodeBlockItemSyntax(
                item: .expr(ExprSyntax(
                    SequenceExprSyntax(
                        elements: ExprListSyntax([
                            ExprSyntax(MemberAccessExprSyntax(
                                base: ExprSyntax(DeclReferenceExprSyntax(baseName: .keyword(.self))),
                                period: .periodToken(),
                                declName: DeclReferenceExprSyntax(baseName: .identifier(privatePropertyName))
                            )),
                            ExprSyntax(AssignmentExprSyntax()),
                            ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(propertyName)))
                        ])
                    )
                ))
            )
            assignmentStatements.append(assignment)
            
            // Create observer registration
            let addObserverCall = CodeGenerationUtilities.createFunctionCall(
                function: ExprSyntax(MemberAccessExprSyntax(
                    base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(propertyName))),
                    period: .periodToken(),
                    declName: DeclReferenceExprSyntax(baseName: .identifier("addObserver"))
                )),
                arguments: [(label: nil, expression: ExprSyntax(DeclReferenceExprSyntax(baseName: .keyword(.self))))]
            )
            
            let awaitedCall = CodeGenerationUtilities.createAwaitExpression(ExprSyntax(addObserverCall))
            let registration = CodeBlockItemSyntax(
                item: .expr(ExprSyntax(awaitedCall))
            )
            observerRegistrations.append(registration)
        }
        
        // Create Task block for async observer registration
        let taskCall = CodeGenerationUtilities.createFunctionCall(
            function: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("Task"))),
            arguments: []
        )
        
        let taskBlock = CodeBlockItemSyntax(
            item: .expr(ExprSyntax(taskCall))
        )
        
        // Combine all body statements
        var bodyStatements = assignmentStatements
        if !observerRegistrations.isEmpty {
            bodyStatements.append(taskBlock)
        }
        
        let body = CodeBlockItemListSyntax(bodyStatements)
        
        return CodeGenerationUtilities.createInitializer(
            parameters: parameters,
            isPublic: true,
            body: body
        )
    }
    
    private static func generateDeinitializer(for properties: [VariableDeclSyntax]) throws -> DeinitializerDeclSyntax? {
        guard !properties.isEmpty else { return nil }
        
        var observerRemovals: [CodeBlockItemSyntax] = []
        
        for property in properties {
            guard let binding = property.bindings.first,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }
            
            let propertyName = pattern.identifier.text
            
            // Create observer removal
            let removeObserverCall = CodeGenerationUtilities.createFunctionCall(
                function: ExprSyntax(MemberAccessExprSyntax(
                    base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(propertyName))),
                    period: .periodToken(),
                    declName: DeclReferenceExprSyntax(baseName: .identifier("removeObserver"))
                )),
                arguments: [(label: nil, expression: ExprSyntax(DeclReferenceExprSyntax(baseName: .keyword(.self))))]
            )
            
            let awaitedCall = CodeGenerationUtilities.createAwaitExpression(ExprSyntax(removeObserverCall))
            let removal = CodeBlockItemSyntax(
                item: .expr(ExprSyntax(awaitedCall))
            )
            observerRemovals.append(removal)
        }
        
        // Create Task block for async observer removal
        let taskCall = CodeGenerationUtilities.createFunctionCall(
            function: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("Task"))),
            arguments: []
        )
        
        let taskBlock = CodeBlockItemSyntax(
            item: .expr(ExprSyntax(taskCall))
        )
        
        let body = CodeBlockItemListSyntax([taskBlock])
        
        return DeinitializerDeclSyntax(
            body: CodeBlockSyntax(statements: body)
        )
    }
}

// MARK: - Diagnostic Messages

/// Diagnostic messages specific to the @Client macro
enum ClientMacroDiagnostic: String, DiagnosticMessage {
    case onlyOnStructs
    case mustConformToAxiomContext
    case invalidPropertyDeclaration
    case mustBeVar
    case cannotHaveInitializer
    case mustConformToAxiomClient
    
    var message: String {
        switch self {
        case .onlyOnStructs:
            return "@Client can only be applied to structs"
        case .mustConformToAxiomContext:
            return "@Client can only be used in structs that conform to AxiomContext"
        case .invalidPropertyDeclaration:
            return "@Client property must have a valid type annotation"
        case .mustBeVar:
            return "@Client properties must be declared with 'var'"
        case .cannotHaveInitializer:
            return "@Client properties cannot have initial values"
        case .mustConformToAxiomClient:
            return "@Client property type should conform to AxiomClient protocol"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros.Client", id: rawValue)
    }
    
    var severity: DiagnosticSeverity {
        .error
    }
}


// MARK: - Macro Declaration

/// The @Client macro adds automatic client dependency injection to AxiomContext properties
@attached(member, names: arbitrary)
public macro Client() = #externalMacro(module: "AxiomMacros", type: "ClientMacro")