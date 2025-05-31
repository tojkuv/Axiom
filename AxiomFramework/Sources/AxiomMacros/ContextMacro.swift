import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - @Context Macro Implementation

/// The @Context macro for comprehensive context orchestration automation
/// Applied to classes that conform to AxiomContext to generate complete boilerplate
/// Integrates @Client + @CrossCutting functionality plus context-specific features
public struct ContextMacro: MemberMacro, AxiomMacro {
    public static var macroName: String { "Context" }
    
    public static func validateDeclaration<D: DeclSyntaxProtocol>(_ declaration: D, in context: some MacroExpansionContext) throws {
        // Validation is performed during expansion to provide better context
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Validate this is applied to a class that conforms to AxiomContext
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: ContextMacroDiagnostic.onlyOnClasses
                )
            )
            return []
        }
        
        guard SyntaxUtilities.conformsToProtocol(classDecl, protocolName: "AxiomContext") else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: ContextMacroDiagnostic.mustConformToAxiomContext
                )
            )
            return []
        }
        
        // Extract configuration from the macro arguments
        let config = try extractContextConfiguration(from: node, in: context)
        
        guard !config.clients.isEmpty || !config.crossCutting.isEmpty else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: ContextMacroDiagnostic.emptyConfiguration
                )
            )
            return []
        }
        
        // Generate the comprehensive context orchestration
        var generatedMembers: [DeclSyntax] = []
        
        // 1. Generate client properties and infrastructure (from @Client)
        for clientType in config.clients {
            if let clientProperty = generateClientProperty(for: clientType) {
                generatedMembers.append(DeclSyntax(clientProperty))
            }
        }
        
        // 2. Generate cross-cutting service properties (from @CrossCutting)
        for concern in config.crossCutting {
            if let serviceProperty = generateServiceProperty(for: concern) {
                generatedMembers.append(DeclSyntax(serviceProperty))
            }
        }
        
        // 3. Generate AxiomIntelligence integration
        if let intelligenceProperty = generateIntelligenceProperty() {
            generatedMembers.append(DeclSyntax(intelligenceProperty))
        }
        
        // 4. Generate ContextStateBinder integration
        if let stateBinderProperty = generateStateBinderProperty() {
            generatedMembers.append(DeclSyntax(stateBinderProperty))
        }
        
        // 5. Generate comprehensive initializer
        if let initializer = generateContextInitializer(
            for: config, 
            className: classDecl.name.text
        ) {
            generatedMembers.append(DeclSyntax(initializer))
        }
        
        // 6. Generate lifecycle management
        if let lifecycleMethods = generateLifecycleMethods(for: config) {
            generatedMembers.append(contentsOf: lifecycleMethods)
        }
        
        // 7. Generate observer pattern management
        if let observerMethods = generateObserverMethods(for: config.clients) {
            generatedMembers.append(contentsOf: observerMethods)
        }
        
        // 8. Generate error handling coordination
        if let errorHandlingMethods = generateErrorHandlingMethods() {
            generatedMembers.append(contentsOf: errorHandlingMethods)
        }
        
        // 9. Generate performance monitoring integration
        if let performanceMethods = generatePerformanceMethods() {
            generatedMembers.append(contentsOf: performanceMethods)
        }
        
        // 10. Generate deinitializer with cleanup
        if let deinitializer = generateContextDeinitializer(for: config) {
            generatedMembers.append(DeclSyntax(deinitializer))
        }
        
        return generatedMembers
    }
    
    // MARK: - Configuration Extraction
    
    private static func extractContextConfiguration(
        from node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) throws -> ContextConfiguration {
        guard let arguments = node.arguments,
              case .argumentList(let argumentList) = arguments else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: ContextMacroDiagnostic.missingConfiguration
                )
            )
            return ContextConfiguration()
        }
        
        var clientTypes: [String] = []
        var crossCuttingConcerns: [CrossCuttingConcern] = []
        
        for argument in argumentList {
            if let label = argument.label {
                switch label.text {
                case "clients":
                    clientTypes = try extractClientTypes(from: argument.expression, in: context)
                case "crossCutting":
                    crossCuttingConcerns = try extractCrossCuttingConcerns(from: argument.expression, in: context)
                default:
                    context.diagnose(
                        SyntaxUtilities.createDiagnostic(
                            node: argument,
                            message: ContextMacroDiagnostic.unknownParameter(label.text)
                        )
                    )
                }
            }
        }
        
        return ContextConfiguration(
            clients: clientTypes,
            crossCutting: crossCuttingConcerns
        )
    }
    
    private static func extractClientTypes(
        from expression: ExprSyntax,
        in context: some MacroExpansionContext
    ) throws -> [String] {
        guard let arrayExpr = expression.as(ArrayExprSyntax.self) else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: expression,
                    message: ContextMacroDiagnostic.invalidClientsFormat
                )
            )
            return []
        }
        
        var clientTypes: [String] = []
        for element in arrayExpr.elements {
            if let memberAccess = element.expression.as(MemberAccessExprSyntax.self) {
                // Handle .self access like DataClient.self
                if memberAccess.declName.baseName.text == "self",
                   let base = memberAccess.base?.trimmedDescription {
                    clientTypes.append(base)
                }
            } else if let typeExpr = element.expression.as(DeclReferenceExprSyntax.self) {
                // Handle direct type references
                clientTypes.append(typeExpr.baseName.text)
            } else {
                context.diagnose(
                    SyntaxUtilities.createDiagnostic(
                        node: element.expression,
                        message: ContextMacroDiagnostic.invalidClientElement
                    )
                )
            }
        }
        
        return clientTypes
    }
    
    private static func extractCrossCuttingConcerns(
        from expression: ExprSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CrossCuttingConcern] {
        guard let arrayExpr = expression.as(ArrayExprSyntax.self) else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: expression,
                    message: ContextMacroDiagnostic.invalidCrossCuttingFormat
                )
            )
            return []
        }
        
        var concerns: [CrossCuttingConcern] = []
        for element in arrayExpr.elements {
            if let memberAccess = element.expression.as(MemberAccessExprSyntax.self) {
                let concernName = memberAccess.declName.baseName.text
                if let concern = CrossCuttingConcern.fromString(concernName) {
                    concerns.append(concern)
                } else {
                    context.diagnose(
                        SyntaxUtilities.createDiagnostic(
                            node: element.expression,
                            message: ContextMacroDiagnostic.unknownConcern(concernName)
                        )
                    )
                }
            } else {
                context.diagnose(
                    SyntaxUtilities.createDiagnostic(
                        node: element.expression,
                        message: ContextMacroDiagnostic.invalidConcernElement
                    )
                )
            }
        }
        
        return concerns
    }
    
    // MARK: - Client Infrastructure Generation
    
    private static func generateClientProperty(for clientType: String) -> VariableDeclSyntax? {
        let propertyName = clientType.lowercasingFirst() + "Client"
        let privatePropertyName = "_\(propertyName)"
        
        // Generate: private let _dataClient: DataClient
        return CodeGenerationUtilities.createStoredProperty(
            name: privatePropertyName,
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier(clientType))),
            isPrivate: true,
            isLet: true
        )
    }
    
    private static func generateServiceProperty(for concern: CrossCuttingConcern) -> VariableDeclSyntax? {
        let propertyName = "_\(concern.propertyName)"
        let serviceType = concern.serviceTypeName
        
        return CodeGenerationUtilities.createStoredProperty(
            name: propertyName,
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier(serviceType))),
            isPrivate: true,
            isLet: true
        )
    }
    
    private static func generateIntelligenceProperty() -> VariableDeclSyntax? {
        return CodeGenerationUtilities.createStoredProperty(
            name: "_intelligence",
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("AxiomIntelligence"))),
            isPrivate: true,
            isLet: true
        )
    }
    
    private static func generateStateBinderProperty() -> VariableDeclSyntax? {
        return CodeGenerationUtilities.createStoredProperty(
            name: "_stateBinder",
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("ContextStateBinder"))),
            isPrivate: true,
            isLet: true
        )
    }
    
    // MARK: - Comprehensive Initializer Generation
    
    private static func generateContextInitializer(
        for config: ContextConfiguration,
        className: String
    ) -> InitializerDeclSyntax? {
        var parameters: [FunctionParameterSyntax] = []
        var assignmentStatements: [CodeBlockItemSyntax] = []
        var observerRegistrations: [CodeBlockItemSyntax] = []
        
        // Add client parameters and assignments
        for clientType in config.clients {
            let propertyName = clientType.lowercasingFirst() + "Client"
            let privatePropertyName = "_\(propertyName)"
            
            let parameter = CodeGenerationUtilities.createParameter(
                name: propertyName,
                type: TypeSyntax(IdentifierTypeSyntax(name: .identifier(clientType)))
            )
            parameters.append(parameter)
            
            let assignment = createAssignmentStatement(
                propertyName: privatePropertyName,
                parameterName: propertyName
            )
            assignmentStatements.append(assignment)
            
            // Add observer registration for this client
            let observerRegistration = createObserverRegistration(clientName: propertyName)
            observerRegistrations.append(observerRegistration)
        }
        
        // Add cross-cutting service parameters and assignments
        for concern in config.crossCutting {
            let propertyName = concern.propertyName
            let privatePropertyName = "_\(propertyName)"
            let serviceType = concern.serviceTypeName
            
            let parameter = CodeGenerationUtilities.createParameter(
                name: propertyName,
                type: TypeSyntax(IdentifierTypeSyntax(name: .identifier(serviceType)))
            )
            parameters.append(parameter)
            
            let assignment = createAssignmentStatement(
                propertyName: privatePropertyName,
                parameterName: propertyName
            )
            assignmentStatements.append(assignment)
        }
        
        // Add intelligence parameter and assignment
        let intelligenceParameter = CodeGenerationUtilities.createParameter(
            name: "intelligence",
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("AxiomIntelligence")))
        )
        parameters.append(intelligenceParameter)
        
        let intelligenceAssignment = createAssignmentStatement(
            propertyName: "_intelligence",
            parameterName: "intelligence"
        )
        assignmentStatements.append(intelligenceAssignment)
        
        // Add state binder parameter and assignment
        let stateBinderParameter = CodeGenerationUtilities.createParameter(
            name: "stateBinder",
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("ContextStateBinder")))
        )
        parameters.append(stateBinderParameter)
        
        let stateBinderAssignment = createAssignmentStatement(
            propertyName: "_stateBinder",
            parameterName: "stateBinder"
        )
        assignmentStatements.append(stateBinderAssignment)
        
        // Create async Task for observer registrations
        var bodyStatements = assignmentStatements
        if !observerRegistrations.isEmpty {
            let taskBlock = createAsyncTaskBlock(statements: observerRegistrations)
            bodyStatements.append(taskBlock)
        }
        
        let body = CodeBlockItemListSyntax(bodyStatements)
        
        return CodeGenerationUtilities.createInitializer(
            parameters: parameters,
            isPublic: true,
            body: body
        )
    }
    
    // MARK: - Lifecycle Management Generation
    
    private static func generateLifecycleMethods(
        for config: ContextConfiguration
    ) -> [DeclSyntax]? {
        var methods: [DeclSyntax] = []
        
        // Generate onAppear implementation
        if let onAppearMethod = generateOnAppearImplementation(for: config) {
            methods.append(DeclSyntax(onAppearMethod))
        }
        
        // Generate onDisappear implementation
        if let onDisappearMethod = generateOnDisappearImplementation(for: config) {
            methods.append(DeclSyntax(onDisappearMethod))
        }
        
        // Generate onClientStateChange implementation
        if let stateChangeMethod = generateStateChangeImplementation() {
            methods.append(DeclSyntax(stateChangeMethod))
        }
        
        return methods.isEmpty ? nil : methods
    }
    
    private static func generateOnAppearImplementation(
        for config: ContextConfiguration
    ) -> FunctionDeclSyntax? {
        var statements: [CodeBlockItemSyntax] = []
        
        // Track analytics for view appeared
        let analyticsCall = createMethodCall(
            method: "trackViewAppeared",
            arguments: []
        )
        statements.append(CodeBlockItemSyntax(item: .expr(ExprSyntax(analyticsCall))))
        
        // Start performance monitoring
        let performanceCall = createMethodCall(
            method: "startContextPerformanceMonitoring",
            arguments: []
        )
        statements.append(CodeBlockItemSyntax(item: .expr(ExprSyntax(performanceCall))))
        
        let body = CodeBlockItemListSyntax(statements)
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: .identifier("onAppear"),
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
    
    private static func generateOnDisappearImplementation(
        for config: ContextConfiguration
    ) -> FunctionDeclSyntax? {
        var statements: [CodeBlockItemSyntax] = []
        
        // Track analytics for view disappeared
        let analyticsCall = createMethodCall(
            method: "trackViewDisappeared",
            arguments: []
        )
        statements.append(CodeBlockItemSyntax(item: .expr(ExprSyntax(analyticsCall))))
        
        // Stop performance monitoring
        let performanceCall = createMethodCall(
            method: "stopContextPerformanceMonitoring",
            arguments: []
        )
        statements.append(CodeBlockItemSyntax(item: .expr(ExprSyntax(performanceCall))))
        
        let body = CodeBlockItemListSyntax(statements)
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: .identifier("onDisappear"),
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
    
    private static func generateStateChangeImplementation() -> FunctionDeclSyntax? {
        let parameter = CodeGenerationUtilities.createParameter(
            name: "client",
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("T")))
        )
        
        var statements: [CodeBlockItemSyntax] = []
        
        // Update state binder
        let stateBinderCall = createMethodCall(
            target: "_stateBinder",
            method: "updateState",
            arguments: [(label: "from", expression: "client")]
        )
        statements.append(CodeBlockItemSyntax(item: .expr(ExprSyntax(stateBinderCall))))
        
        // Record state change performance
        let performanceCall = createMethodCall(
            method: "recordStateChangePerformance",
            arguments: [(label: "client", expression: "client")]
        )
        statements.append(CodeBlockItemSyntax(item: .expr(ExprSyntax(performanceCall))))
        
        let body = CodeBlockItemListSyntax(statements)
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: .identifier("onClientStateChange"),
            genericParameterClause: GenericParameterClauseSyntax(
                parameters: GenericParameterListSyntax([
                    GenericParameterSyntax(
                        name: .identifier("T"),
                        colon: .colonToken(),
                        inheritedType: TypeSyntax(IdentifierTypeSyntax(name: .identifier("AxiomClient")))
                    )
                ])
            ),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax([parameter])
                ),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(
                    asyncSpecifier: .keyword(.async)
                )
            ),
            body: CodeBlockSyntax(statements: body)
        )
    }
    
    // MARK: - Observer Pattern Management
    
    private static func generateObserverMethods(
        for clients: [String]
    ) -> [DeclSyntax]? {
        guard !clients.isEmpty else { return nil }
        
        var methods: [DeclSyntax] = []
        
        // Generate client accessor methods
        for clientType in clients {
            if let accessorMethod = generateClientAccessor(for: clientType) {
                methods.append(DeclSyntax(accessorMethod))
            }
        }
        
        return methods.isEmpty ? nil : methods
    }
    
    private static func generateClientAccessor(for clientType: String) -> FunctionDeclSyntax? {
        let propertyName = clientType.lowercasingFirst() + "Client"
        let privatePropertyName = "_\(propertyName)"
        let methodName = clientType.lowercasingFirst()
        
        let returnStatement = CodeBlockItemSyntax(
            item: .stmt(StmtSyntax(ReturnStmtSyntax(
                expression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(privatePropertyName)))
            )))
        )
        
        let body = CodeBlockItemListSyntax([returnStatement])
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: .identifier(methodName),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax([])
                ),
                returnClause: ReturnClauseSyntax(
                    type: TypeSyntax(IdentifierTypeSyntax(name: .identifier(clientType)))
                )
            ),
            body: CodeBlockSyntax(statements: body)
        )
    }
    
    // MARK: - Error Handling Methods
    
    private static func generateErrorHandlingMethods() -> [DeclSyntax]? {
        var methods: [DeclSyntax] = []
        
        // Generate handleError implementation
        if let errorHandlerMethod = generateErrorHandlerImplementation() {
            methods.append(DeclSyntax(errorHandlerMethod))
        }
        
        return methods.isEmpty ? nil : methods
    }
    
    private static func generateErrorHandlerImplementation() -> FunctionDeclSyntax? {
        let parameter = CodeGenerationUtilities.createParameter(
            name: "error",
            type: TypeSyntax(SomeOrAnyTypeSyntax(
                someOrAnySpecifier: .keyword(.any),
                constraint: TypeSyntax(IdentifierTypeSyntax(name: .identifier("AxiomError")))
            ))
        )
        
        var statements: [CodeBlockItemSyntax] = []
        
        // Track error analytics
        let analyticsCall = createMethodCall(
            method: "trackError",
            arguments: [(label: nil, expression: "error")]
        )
        statements.append(CodeBlockItemSyntax(item: .expr(ExprSyntax(analyticsCall))))
        
        // Log error if logging service is available
        let logCall = createConditionalMethodCall(
            target: "_logger",
            method: "logError",
            arguments: [(label: nil, expression: "error")]
        )
        statements.append(logCall)
        
        // Report error if error reporting service is available  
        let reportCall = createConditionalMethodCall(
            target: "_errorReporting",
            method: "reportError",
            arguments: [(label: nil, expression: "error")]
        )
        statements.append(reportCall)
        
        let body = CodeBlockItemListSyntax(statements)
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: .identifier("handleError"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax([parameter])
                ),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(
                    asyncSpecifier: .keyword(.async)
                )
            ),
            body: CodeBlockSyntax(statements: body)
        )
    }
    
    // MARK: - Performance Monitoring Methods
    
    private static func generatePerformanceMethods() -> [DeclSyntax]? {
        var methods: [DeclSyntax] = []
        
        // Generate trackAnalyticsEvent implementation
        if let analyticsMethod = generateAnalyticsImplementation() {
            methods.append(DeclSyntax(analyticsMethod))
        }
        
        // Generate performance monitoring helpers
        if let performanceHelpers = generatePerformanceHelpers() {
            methods.append(contentsOf: performanceHelpers)
        }
        
        return methods.isEmpty ? nil : methods
    }
    
    private static func generateAnalyticsImplementation() -> FunctionDeclSyntax? {
        let eventParameter = CodeGenerationUtilities.createParameter(
            name: "event",
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("String")))
        )
        
        let parametersParameter = CodeGenerationUtilities.createParameter(
            name: "parameters",
            type: TypeSyntax(DictionaryTypeSyntax(
                key: TypeSyntax(IdentifierTypeSyntax(name: .identifier("String"))),
                value: TypeSyntax(IdentifierTypeSyntax(name: .identifier("Any")))
            ))
        )
        
        var statements: [CodeBlockItemSyntax] = []
        
        // Use analytics service if available
        let analyticsCall = createConditionalMethodCall(
            target: "_analytics",
            method: "track",
            arguments: [
                (label: "event", expression: "event"),
                (label: "parameters", expression: "parameters")
            ]
        )
        statements.append(analyticsCall)
        
        let body = CodeBlockItemListSyntax(statements)
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: .identifier("trackAnalyticsEvent"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax([eventParameter, parametersParameter])
                ),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(
                    asyncSpecifier: .keyword(.async)
                )
            ),
            body: CodeBlockSyntax(statements: body)
        )
    }
    
    private static func generatePerformanceHelpers() -> [DeclSyntax]? {
        var methods: [DeclSyntax] = []
        
        // Generate start monitoring method
        if let startMethod = generateStartPerformanceMethod() {
            methods.append(DeclSyntax(startMethod))
        }
        
        // Generate stop monitoring method
        if let stopMethod = generateStopPerformanceMethod() {
            methods.append(DeclSyntax(stopMethod))
        }
        
        // Generate record state change method
        if let recordMethod = generateRecordStateChangeMethod() {
            methods.append(DeclSyntax(recordMethod))
        }
        
        return methods.isEmpty ? nil : methods
    }
    
    private static func generateStartPerformanceMethod() -> FunctionDeclSyntax? {
        var statements: [CodeBlockItemSyntax] = []
        
        let performanceCall = createConditionalMethodCall(
            target: "_performance",
            method: "startContextMonitoring",
            arguments: [(label: "context", expression: "self")]
        )
        statements.append(performanceCall)
        
        let body = CodeBlockItemListSyntax(statements)
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.private))],
            name: .identifier("startContextPerformanceMonitoring"),
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
    
    private static func generateStopPerformanceMethod() -> FunctionDeclSyntax? {
        var statements: [CodeBlockItemSyntax] = []
        
        let performanceCall = createConditionalMethodCall(
            target: "_performance",
            method: "stopContextMonitoring",
            arguments: [(label: "context", expression: "self")]
        )
        statements.append(performanceCall)
        
        let body = CodeBlockItemListSyntax(statements)
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.private))],
            name: .identifier("stopContextPerformanceMonitoring"),
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
    
    private static func generateRecordStateChangeMethod() -> FunctionDeclSyntax? {
        let parameter = CodeGenerationUtilities.createParameter(
            name: "client",
            type: TypeSyntax(SomeOrAnyTypeSyntax(
                someOrAnySpecifier: .keyword(.any),
                constraint: TypeSyntax(IdentifierTypeSyntax(name: .identifier("AxiomClient")))
            ))
        )
        
        var statements: [CodeBlockItemSyntax] = []
        
        let performanceCall = createConditionalMethodCall(
            target: "_performance",
            method: "recordStateChange",
            arguments: [(label: "client", expression: "client")]
        )
        statements.append(performanceCall)
        
        let body = CodeBlockItemListSyntax(statements)
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.private))],
            name: .identifier("recordStateChangePerformance"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax([parameter])
                ),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(
                    asyncSpecifier: .keyword(.async)
                )
            ),
            body: CodeBlockSyntax(statements: body)
        )
    }
    
    // MARK: - Deinitializer Generation
    
    private static func generateContextDeinitializer(
        for config: ContextConfiguration
    ) -> DeinitializerDeclSyntax? {
        guard !config.clients.isEmpty else { return nil }
        
        var statements: [CodeBlockItemSyntax] = []
        
        // Create observer removal for all clients
        for clientType in config.clients {
            let propertyName = clientType.lowercasingFirst() + "Client"
            let removal = createObserverRemoval(clientName: propertyName)
            statements.append(removal)
        }
        
        // Create Task block for async cleanup
        let taskBlock = createAsyncTaskBlock(statements: statements)
        let body = CodeBlockItemListSyntax([taskBlock])
        
        return DeinitializerDeclSyntax(
            body: CodeBlockSyntax(statements: body)
        )
    }
    
    // MARK: - Helper Methods
    
    private static func createAssignmentStatement(
        propertyName: String,
        parameterName: String
    ) -> CodeBlockItemSyntax {
        return CodeBlockItemSyntax(
            item: .expr(ExprSyntax(
                SequenceExprSyntax(
                    elements: ExprListSyntax([
                        ExprSyntax(MemberAccessExprSyntax(
                            base: ExprSyntax(DeclReferenceExprSyntax(baseName: .keyword(.self))),
                            period: .periodToken(),
                            declName: DeclReferenceExprSyntax(baseName: .identifier(propertyName))
                        )),
                        ExprSyntax(AssignmentExprSyntax()),
                        ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(parameterName)))
                    ])
                )
            ))
        )
    }
    
    private static func createObserverRegistration(clientName: String) -> CodeBlockItemSyntax {
        let addObserverCall = CodeGenerationUtilities.createAwaitExpression(
            ExprSyntax(CodeGenerationUtilities.createFunctionCall(
                function: ExprSyntax(MemberAccessExprSyntax(
                    base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(clientName))),
                    period: .periodToken(),
                    declName: DeclReferenceExprSyntax(baseName: .identifier("addObserver"))
                )),
                arguments: [(label: nil, expression: ExprSyntax(DeclReferenceExprSyntax(baseName: .keyword(.self))))]
            ))
        )
        
        return CodeBlockItemSyntax(item: .expr(ExprSyntax(addObserverCall)))
    }
    
    private static func createObserverRemoval(clientName: String) -> CodeBlockItemSyntax {
        let removeObserverCall = CodeGenerationUtilities.createAwaitExpression(
            ExprSyntax(CodeGenerationUtilities.createFunctionCall(
                function: ExprSyntax(MemberAccessExprSyntax(
                    base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(clientName))),
                    period: .periodToken(),
                    declName: DeclReferenceExprSyntax(baseName: .identifier("removeObserver"))
                )),
                arguments: [(label: nil, expression: ExprSyntax(DeclReferenceExprSyntax(baseName: .keyword(.self))))]
            ))
        )
        
        return CodeBlockItemSyntax(item: .expr(ExprSyntax(removeObserverCall)))
    }
    
    private static func createAsyncTaskBlock(statements: [CodeBlockItemSyntax]) -> CodeBlockItemSyntax {
        return CodeBlockItemSyntax(
            item: .expr(ExprSyntax(
                CodeGenerationUtilities.createFunctionCall(
                    function: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("Task"))),
                    arguments: []
                )
            ))
        )
    }
    
    private static func createMethodCall(
        target: String? = nil,
        method: String,
        arguments: [(label: String?, expression: String)]
    ) -> FunctionCallExprSyntax {
        let functionExpr: ExprSyntax
        if let target = target {
            functionExpr = ExprSyntax(MemberAccessExprSyntax(
                base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(target))),
                period: .periodToken(),
                declName: DeclReferenceExprSyntax(baseName: .identifier(method))
            ))
        } else {
            functionExpr = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(method)))
        }
        
        let labeledArguments = arguments.map { arg in
            (label: arg.label, expression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(arg.expression))))
        }
        
        return CodeGenerationUtilities.createFunctionCall(
            function: functionExpr,
            arguments: labeledArguments
        )
    }
    
    private static func createConditionalMethodCall(
        target: String,
        method: String,
        arguments: [(label: String?, expression: String)]
    ) -> CodeBlockItemSyntax {
        // For now, just create a direct call - could be enhanced to check for nil
        let call = createMethodCall(target: target, method: method, arguments: arguments)
        return CodeBlockItemSyntax(item: .expr(ExprSyntax(call)))
    }
}

// MARK: - Context Configuration

/// Configuration extracted from @Context macro arguments
struct ContextConfiguration {
    let clients: [String]
    let crossCutting: [CrossCuttingConcern]
    
    init(clients: [String] = [], crossCutting: [CrossCuttingConcern] = []) {
        self.clients = clients
        self.crossCutting = crossCutting
    }
}

// MARK: - String Extensions

extension String {
    /// Converts the first character to lowercase
    func lowercasingFirst() -> String {
        guard !isEmpty else { return self }
        return prefix(1).lowercased() + dropFirst()
    }
}

// MARK: - Diagnostic Messages

/// Diagnostic messages specific to the @Context macro
enum ContextMacroDiagnostic: DiagnosticMessage {
    case onlyOnClasses
    case mustConformToAxiomContext
    case emptyConfiguration
    case missingConfiguration
    case unknownParameter(String)
    case invalidClientsFormat
    case invalidClientElement
    case invalidCrossCuttingFormat
    case invalidConcernElement
    case unknownConcern(String)
    
    var message: String {
        switch self {
        case .onlyOnClasses:
            return "@Context can only be applied to classes"
        case .mustConformToAxiomContext:
            return "@Context can only be used in classes that conform to AxiomContext"
        case .emptyConfiguration:
            return "@Context requires at least one client or cross-cutting concern to be specified"
        case .missingConfiguration:
            return "@Context requires configuration parameters (clients and/or crossCutting)"
        case .unknownParameter(let name):
            return "Unknown @Context parameter: '\(name)'. Valid parameters: clients, crossCutting"
        case .invalidClientsFormat:
            return "@Context clients parameter must be an array of client types"
        case .invalidClientElement:
            return "Invalid client element. Use ClientType.self format"
        case .invalidCrossCuttingFormat:
            return "@Context crossCutting parameter must be an array of cross-cutting concerns"
        case .invalidConcernElement:
            return "Invalid cross-cutting concern element. Use .concernName format"
        case .unknownConcern(let name):
            return "Unknown cross-cutting concern: '\(name)'. Available: analytics, logging, errorReporting, performance, security, monitoring, audit, metrics"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros.Context", id: "context")
    }
    
    var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - Macro Declaration

/// The @Context macro provides comprehensive context orchestration automation
/// Integrates @Client + @CrossCutting functionality plus context-specific features
@attached(member, names: arbitrary)
public macro Context(
    clients: [Any] = [], 
    crossCutting: [Any] = []
) = #externalMacro(module: "AxiomMacros", type: "ContextMacro")