import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - @View Macro Implementation

/// The @View macro for automatic SwiftUI view integration with AxiomContext
/// Applied to structs that conform to View to generate AxiomView boilerplate
public struct ViewMacro: MemberMacro, AxiomMacro {
    public static var macroName: String { "View" }
    
    public static func validateDeclaration<D: DeclSyntaxProtocol>(_ declaration: D, in context: some MacroExpansionContext) throws {
        // Validation is performed during expansion to provide better context
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Validate this is applied to a struct that conforms to View
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: ViewMacroDiagnostic.onlyOnStructs
                )
            )
            return []
        }
        
        guard SyntaxUtilities.conformsToProtocol(structDecl, protocolName: "View") else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: ViewMacroDiagnostic.mustConformToView
                )
            )
            return []
        }
        
        // Extract context type from the macro argument
        let contextType = try extractContextType(from: node, in: context)
        
        // If empty, extractContextType has already diagnosed the issue
        guard !contextType.isEmpty else {
            return []
        }
        
        // Validate that the struct doesn't already have a context property
        let members = SyntaxUtilities.extractMembers(from: structDecl) ?? MemberBlockItemListSyntax([])
        if hasExistingContextProperty(in: members) {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: ViewMacroDiagnostic.existingContextProperty
                )
            )
            return []
        }
        
        // Generate the boilerplate code
        var generatedMembers: [DeclSyntax] = []
        
        // 1. Generate @ObservedObject context property
        if let contextProperty = generateContextProperty(contextType: contextType) {
            generatedMembers.append(DeclSyntax(contextProperty))
        }
        
        // 2. Generate default initializer
        if let initializer = generateInitializer(contextType: contextType) {
            generatedMembers.append(DeclSyntax(initializer))
        }
        
        // 3. Generate lifecycle integration methods
        if let lifecycleMethods = generateLifecycleMethods() {
            generatedMembers.append(contentsOf: lifecycleMethods)
        }
        
        // 4. Generate error handling support
        if let errorHandlingProperty = generateErrorHandlingProperty() {
            generatedMembers.append(DeclSyntax(errorHandlingProperty))
        }
        
        // 5. Generate intelligence integration methods
        if let intelligenceMethods = generateIntelligenceMethods() {
            generatedMembers.append(contentsOf: intelligenceMethods)
        }
        
        return generatedMembers
    }
    
    // MARK: - Context Type Extraction
    
    private static func extractContextType(
        from node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) throws -> String {
        guard let arguments = node.arguments,
              case .argumentList(let argumentList) = arguments,
              let firstArgument = argumentList.first else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: ViewMacroDiagnostic.missingContextArgument
                )
            )
            return ""
        }
        
        // Extract the context type from the argument
        let contextType = firstArgument.expression.trimmedDescription
        
        // Validate it's a proper type identifier
        guard contextType.first?.isUppercase == true else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: firstArgument.expression,
                    message: ViewMacroDiagnostic.invalidContextType
                )
            )
            return ""
        }
        
        return contextType
    }
    
    // MARK: - Validation Helpers
    
    private static func hasExistingContextProperty(in members: MemberBlockItemListSyntax) -> Bool {
        return members.contains { member in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = varDecl.bindings.first,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                return false
            }
            
            return pattern.identifier.text == "context"
        }
    }
    
    // MARK: - Code Generation
    
    private static func generateContextProperty(contextType: String) -> VariableDeclSyntax? {
        // Create @ObservedObject var context: ContextType
        let typeAnnotation = TypeAnnotationSyntax(
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier(contextType)))
        )
        
        let pattern = PatternBindingSyntax(
            pattern: IdentifierPatternSyntax(identifier: .identifier("context")),
            typeAnnotation: typeAnnotation
        )
        
        return VariableDeclSyntax(
            attributes: AttributeListSyntax([
                .attribute(AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("ObservedObject"))
                ))
            ]),
            bindingSpecifier: .keyword(.var),
            bindings: PatternBindingListSyntax([pattern])
        )
    }
    
    private static func generateInitializer(contextType: String) -> InitializerDeclSyntax? {
        // Create init(context: ContextType)
        let parameter = CodeGenerationUtilities.createParameter(
            name: "context",
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier(contextType)))
        )
        
        // Create assignment statement: self.context = context
        let assignment = CodeBlockItemSyntax(
            item: .expr(ExprSyntax(
                SequenceExprSyntax(
                    elements: ExprListSyntax([
                        ExprSyntax(MemberAccessExprSyntax(
                            base: ExprSyntax(DeclReferenceExprSyntax(baseName: .keyword(.self))),
                            period: .periodToken(),
                            declName: DeclReferenceExprSyntax(baseName: .identifier("context"))
                        )),
                        ExprSyntax(AssignmentExprSyntax()),
                        ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("context")))
                    ])
                )
            ))
        )
        
        let body = CodeBlockItemListSyntax([assignment])
        
        return CodeGenerationUtilities.createInitializer(
            parameters: [parameter],
            isPublic: true,
            body: body
        )
    }
    
    private static func generateLifecycleMethods() -> [DeclSyntax]? {
        var methods: [DeclSyntax] = []
        
        // Generate onAppear method
        if let onAppearMethod = generateOnAppearMethod() {
            methods.append(DeclSyntax(onAppearMethod))
        }
        
        // Generate onDisappear method
        if let onDisappearMethod = generateOnDisappearMethod() {
            methods.append(DeclSyntax(onDisappearMethod))
        }
        
        return methods.isEmpty ? nil : methods
    }
    
    private static func generateOnAppearMethod() -> FunctionDeclSyntax? {
        // Generate: private func axiomOnAppear() async { await context.onAppear() }
        let contextCall = CodeGenerationUtilities.createAwaitExpression(
            ExprSyntax(CodeGenerationUtilities.createFunctionCall(
                function: ExprSyntax(MemberAccessExprSyntax(
                    base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("context"))),
                    period: .periodToken(),
                    declName: DeclReferenceExprSyntax(baseName: .identifier("onAppear"))
                )),
                arguments: []
            ))
        )
        
        let body = CodeBlockItemListSyntax([
            CodeBlockItemSyntax(item: .expr(ExprSyntax(contextCall)))
        ])
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.private))],
            name: .identifier("axiomOnAppear"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax([])
                ),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(
                    asyncSpecifier: .keyword(.async)
                )
            ),
            body: CodeBlockSyntax(statements: body)
        )
    }
    
    private static func generateOnDisappearMethod() -> FunctionDeclSyntax? {
        // Generate: private func axiomOnDisappear() async { await context.onDisappear() }
        let contextCall = CodeGenerationUtilities.createAwaitExpression(
            ExprSyntax(CodeGenerationUtilities.createFunctionCall(
                function: ExprSyntax(MemberAccessExprSyntax(
                    base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("context"))),
                    period: .periodToken(),
                    declName: DeclReferenceExprSyntax(baseName: .identifier("onDisappear"))
                )),
                arguments: []
            ))
        )
        
        let body = CodeBlockItemListSyntax([
            CodeBlockItemSyntax(item: .expr(ExprSyntax(contextCall)))
        ])
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.private))],
            name: .identifier("axiomOnDisappear"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax([])
                ),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(
                    asyncSpecifier: .keyword(.async)
                )
            ),
            body: CodeBlockSyntax(statements: body)
        )
    }
    
    private static func generateErrorHandlingProperty() -> VariableDeclSyntax? {
        // Generate: @State private var showingError = false
        let pattern = PatternBindingSyntax(
            pattern: IdentifierPatternSyntax(identifier: .identifier("showingError")),
            initializer: InitializerClauseSyntax(
                value: ExprSyntax(BooleanLiteralExprSyntax(literal: .keyword(.false)))
            )
        )
        
        return VariableDeclSyntax(
            attributes: AttributeListSyntax([
                .attribute(AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("State"))
                ))
            ]),
            modifiers: [DeclModifierSyntax(name: .keyword(.private))],
            bindingSpecifier: .keyword(.var),
            bindings: PatternBindingListSyntax([pattern])
        )
    }
    
    private static func generateIntelligenceMethods() -> [DeclSyntax]? {
        var methods: [DeclSyntax] = []
        
        // Generate queryIntelligence method
        if let queryMethod = generateQueryIntelligenceMethod() {
            methods.append(DeclSyntax(queryMethod))
        }
        
        return methods.isEmpty ? nil : methods
    }
    
    private static func generateQueryIntelligenceMethod() -> FunctionDeclSyntax? {
        // Generate: private func queryIntelligence(_ query: String) async -> String?
        let parameter = CodeGenerationUtilities.createParameter(
            label: "_",
            name: "query",
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("String")))
        )
        
        let intelligenceCall = CodeGenerationUtilities.createAwaitExpression(
            ExprSyntax(CodeGenerationUtilities.createFunctionCall(
                function: ExprSyntax(MemberAccessExprSyntax(
                    base: ExprSyntax(MemberAccessExprSyntax(
                        base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("context"))),
                        period: .periodToken(),
                        declName: DeclReferenceExprSyntax(baseName: .identifier("intelligence"))
                    )),
                    period: .periodToken(),
                    declName: DeclReferenceExprSyntax(baseName: .identifier("query"))
                )),
                arguments: [(label: nil, expression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("query"))))]
            ))
        )
        
        let returnStatement = CodeBlockItemSyntax(
            item: .stmt(StmtSyntax(ReturnStmtSyntax(
                expression: ExprSyntax(intelligenceCall)
            )))
        )
        
        let body = CodeBlockItemListSyntax([returnStatement])
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.private))],
            name: .identifier("queryIntelligence"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax([parameter])
                ),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(
                    asyncSpecifier: .keyword(.async)
                ),
                returnClause: ReturnClauseSyntax(
                    type: TypeSyntax(OptionalTypeSyntax(
                        wrappedType: TypeSyntax(IdentifierTypeSyntax(name: .identifier("String")))
                    ))
                )
            ),
            body: CodeBlockSyntax(statements: body)
        )
    }
}

// MARK: - Diagnostic Messages

/// Diagnostic messages specific to the @View macro
enum ViewMacroDiagnostic: String, DiagnosticMessage {
    case onlyOnStructs
    case mustConformToView
    case missingContextType
    case missingContextArgument
    case invalidContextType
    case existingContextProperty
    case conflictingMacros
    
    var message: String {
        switch self {
        case .onlyOnStructs:
            return "@View can only be applied to structs"
        case .mustConformToView:
            return "@View can only be used in structs that conform to View"
        case .missingContextType:
            return "@View requires a context type to be specified"
        case .missingContextArgument:
            return "@View requires a context type argument"
        case .invalidContextType:
            return "@View context type must be a valid type identifier"
        case .existingContextProperty:
            return "@View cannot be applied to structs that already have a 'context' property"
        case .conflictingMacros:
            return "@View conflicts with other view-related macros"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros.View", id: rawValue)
    }
    
    var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - Macro Declaration

/// The @View macro adds automatic AxiomView integration to SwiftUI View structs
@attached(member, names: named(context), named(init), named(axiomOnAppear), named(axiomOnDisappear), named(showingError), named(queryIntelligence))
public macro View<ContextType>(_ contextType: ContextType.Type) = #externalMacro(module: "AxiomMacros", type: "ViewMacro")