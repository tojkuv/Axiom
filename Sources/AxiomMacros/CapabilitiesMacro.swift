import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - @Capabilities Macro Implementation

/// The @Capabilities macro for automatic capability declaration and validation
/// Applied to actors that conform to AxiomClient to generate capability management code
public struct CapabilitiesMacro: MemberMacro, AxiomMacro {
    public static var macroName: String { "Capabilities" }
    
    public static func validateDeclaration<D: DeclSyntaxProtocol>(_ declaration: D, in context: some MacroExpansionContext) throws {
        // Validation is performed during expansion to provide better context
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Validate this is applied to an actor that conforms to AxiomClient
        guard let actorDecl = declaration.as(ActorDeclSyntax.self) else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: CapabilitiesMacroDiagnostic.onlyOnActors
                )
            )
            return []
        }
        
        guard SyntaxUtilities.conformsToProtocol(actorDecl, protocolName: "AxiomClient") else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: CapabilitiesMacroDiagnostic.mustConformToAxiomClient
                )
            )
            return []
        }
        
        // Extract capabilities from the macro argument
        let capabilities = try extractCapabilities(from: node, in: context)
        
        guard !capabilities.isEmpty else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: CapabilitiesMacroDiagnostic.emptyCapabilities
                )
            )
            return []
        }
        
        // Generate the capability management code
        var generatedMembers: [DeclSyntax] = []
        
        // 1. Generate private capability manager property
        if let capabilityManagerProperty = generateCapabilityManagerProperty() {
            generatedMembers.append(DeclSyntax(capabilityManagerProperty))
        }
        
        // 2. Generate public capabilities computed property
        if let capabilitiesProperty = generateCapabilitiesComputedProperty() {
            generatedMembers.append(DeclSyntax(capabilitiesProperty))
        }
        
        // 3. Generate static requiredCapabilities property
        if let requiredCapabilitiesProperty = generateRequiredCapabilitiesProperty(capabilities: capabilities) {
            generatedMembers.append(DeclSyntax(requiredCapabilitiesProperty))
        }
        
        // 4. Generate enhanced initializer
        if let initializer = generateCapabilityInitializer(actorName: actorDecl.name.text) {
            generatedMembers.append(DeclSyntax(initializer))
        }
        
        return generatedMembers
    }
    
    // MARK: - Capability Extraction
    
    private static func extractCapabilities(
        from node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) throws -> [String] {
        guard let arguments = node.arguments,
              case .argumentList(let argumentList) = arguments,
              let firstArgument = argumentList.first else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: CapabilitiesMacroDiagnostic.missingCapabilitiesArgument
                )
            )
            return []
        }
        
        // Parse the capabilities array
        guard let arrayExpr = firstArgument.expression.as(ArrayExprSyntax.self) else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: firstArgument.expression,
                    message: CapabilitiesMacroDiagnostic.invalidCapabilitiesFormat
                )
            )
            return []
        }
        
        var capabilities: [String] = []
        for element in arrayExpr.elements {
            if let memberAccess = element.expression.as(MemberAccessExprSyntax.self) {
                let capabilityName = memberAccess.declName.baseName.text
                capabilities.append(capabilityName)
            } else {
                context.diagnose(
                    SyntaxUtilities.createDiagnostic(
                        node: element.expression,
                        message: CapabilitiesMacroDiagnostic.invalidCapabilityElement
                    )
                )
            }
        }
        
        return capabilities
    }
    
    // MARK: - Code Generation
    
    private static func generateCapabilityManagerProperty() -> VariableDeclSyntax? {
        return CodeGenerationUtilities.createStoredProperty(
            name: "_capabilityManager",
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("CapabilityManager"))),
            isPrivate: true,
            isLet: true
        )
    }
    
    private static func generateCapabilitiesComputedProperty() -> VariableDeclSyntax? {
        let getter = CodeBlockItemListSyntax([
            CodeBlockItemSyntax(
                item: .expr(ExprSyntax(
                    DeclReferenceExprSyntax(baseName: .identifier("_capabilityManager"))
                ))
            )
        ])
        
        return CodeGenerationUtilities.createComputedProperty(
            name: "capabilities",
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("CapabilityManager"))),
            isPublic: false,
            getter: getter
        )
    }
    
    private static func generateRequiredCapabilitiesProperty(capabilities: [String]) -> VariableDeclSyntax? {
        // Create array elements for the capabilities
        var capabilityElements: [ArrayElementSyntax] = []
        for (index, capability) in capabilities.enumerated() {
            let memberAccess = MemberAccessExprSyntax(
                period: .periodToken(),
                declName: DeclReferenceExprSyntax(baseName: .identifier(capability))
            )
            
            let element = ArrayElementSyntax(
                expression: ExprSyntax(memberAccess),
                trailingComma: index < capabilities.count - 1 ? .commaToken() : nil
            )
            capabilityElements.append(element)
        }
        
        let arrayExpr = ArrayExprSyntax(
            leftSquare: .leftSquareToken(),
            elements: ArrayElementListSyntax(capabilityElements),
            rightSquare: .rightSquareToken()
        )
        
        let setInitializer = FunctionCallExprSyntax(
            calledExpression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("Set"))),
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax([
                LabeledExprSyntax(expression: ExprSyntax(arrayExpr))
            ]),
            rightParen: .rightParenToken()
        )
        
        let getter = CodeBlockItemListSyntax([
            CodeBlockItemSyntax(
                item: .expr(ExprSyntax(setInitializer))
            )
        ])
        
        let accessorBlock = AccessorBlockSyntax(
            accessors: .getter(getter)
        )
        
        let pattern = PatternBindingSyntax(
            pattern: IdentifierPatternSyntax(identifier: .identifier("requiredCapabilities")),
            typeAnnotation: TypeAnnotationSyntax(
                type: TypeSyntax(IdentifierTypeSyntax(
                    name: .identifier("Set"),
                    genericArgumentClause: GenericArgumentClauseSyntax(
                        arguments: GenericArgumentListSyntax([
                            GenericArgumentSyntax(
                                argument: TypeSyntax(IdentifierTypeSyntax(name: .identifier("Capability")))
                            )
                        ])
                    )
                ))
            ),
            accessorBlock: accessorBlock
        )
        
        return VariableDeclSyntax(
            modifiers: [
                DeclModifierSyntax(name: .keyword(.static))
            ],
            bindingSpecifier: .keyword(.var),
            bindings: PatternBindingListSyntax([pattern])
        )
    }
    
    private static func generateCapabilityInitializer(actorName: String) -> InitializerDeclSyntax? {
        // Create parameter for capability manager
        let parameter = CodeGenerationUtilities.createParameter(
            name: "capabilityManager",
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("CapabilityManager")))
        )
        
        // Create assignment statement
        let assignment = CodeBlockItemSyntax(
            item: .expr(ExprSyntax(
                SequenceExprSyntax(
                    elements: ExprListSyntax([
                        ExprSyntax(MemberAccessExprSyntax(
                            base: ExprSyntax(DeclReferenceExprSyntax(baseName: .keyword(.self))),
                            period: .periodToken(),
                            declName: DeclReferenceExprSyntax(baseName: .identifier("_capabilityManager"))
                        )),
                        ExprSyntax(AssignmentExprSyntax()),
                        ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("capabilityManager")))
                    ])
                )
            ))
        )
        
        // Create capability validation loop
        let forInStmt = ForStmtSyntax(
            forKeyword: .keyword(.for),
            pattern: IdentifierPatternSyntax(identifier: .identifier("capability")),
            inKeyword: .keyword(.in),
            sequence: ExprSyntax(MemberAccessExprSyntax(
                base: ExprSyntax(DeclReferenceExprSyntax(baseName: .keyword(.Self))),
                period: .periodToken(),
                declName: DeclReferenceExprSyntax(baseName: .identifier("requiredCapabilities"))
            )),
            body: CodeBlockSyntax(
                statements: CodeBlockItemListSyntax([
                    CodeBlockItemSyntax(
                        item: .expr(ExprSyntax(
                            TryExprSyntax(
                                expression: ExprSyntax(
                                    FunctionCallExprSyntax(
                                        calledExpression: ExprSyntax(MemberAccessExprSyntax(
                                            base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("capabilityManager"))),
                                            period: .periodToken(),
                                            declName: DeclReferenceExprSyntax(baseName: .identifier("validate"))
                                        )),
                                        leftParen: .leftParenToken(),
                                        arguments: LabeledExprListSyntax([
                                            LabeledExprSyntax(
                                                expression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("capability")))
                                            )
                                        ]),
                                        rightParen: .rightParenToken()
                                    )
                                )
                            )
                        ))
                    )
                ])
            )
        )
        
        let validationLoop = CodeBlockItemSyntax(
            item: .stmt(StmtSyntax(forInStmt))
        )
        
        let body = CodeBlockItemListSyntax([assignment, validationLoop])
        
        return InitializerDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax([parameter])
                ),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(
                    asyncSpecifier: .keyword(.async),
                    throwsSpecifier: .keyword(.throws)
                )
            ),
            body: CodeBlockSyntax(statements: body)
        )
    }
}

// MARK: - Diagnostic Messages

/// Diagnostic messages specific to the @Capabilities macro
enum CapabilitiesMacroDiagnostic: String, DiagnosticMessage {
    case onlyOnActors
    case mustConformToAxiomClient
    case emptyCapabilities
    case missingCapabilitiesArgument
    case invalidCapabilitiesFormat
    case invalidCapabilityElement
    
    var message: String {
        switch self {
        case .onlyOnActors:
            return "@Capabilities can only be applied to actors"
        case .mustConformToAxiomClient:
            return "@Capabilities can only be used in actors that conform to AxiomClient"
        case .emptyCapabilities:
            return "@Capabilities requires at least one capability to be specified"
        case .missingCapabilitiesArgument:
            return "@Capabilities requires a capabilities array argument"
        case .invalidCapabilitiesFormat:
            return "@Capabilities argument must be an array of capabilities"
        case .invalidCapabilityElement:
            return "Invalid capability element. Use .capabilityName format"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros.Capabilities", id: rawValue)
    }
    
    var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - Macro Declaration

/// The @Capabilities macro adds automatic capability management to AxiomClient actors
@attached(member, names: named(_capabilityManager), named(capabilities), named(requiredCapabilities), named(init))
public macro Capabilities<T>(_ capabilities: [T]) = #externalMacro(module: "AxiomMacros", type: "CapabilitiesMacro")