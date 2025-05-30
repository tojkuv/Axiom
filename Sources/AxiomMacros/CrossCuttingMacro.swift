import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - @CrossCutting Macro Implementation

/// The @CrossCutting macro for supervised cross-cutting concern injection
/// Applied to AxiomContext structs to inject analytics, logging, error reporting, etc.
public struct CrossCuttingMacro: MemberMacro, AxiomMacro {
    public static var macroName: String { "CrossCutting" }
    
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
                    message: CrossCuttingMacroDiagnostic.onlyOnStructs
                )
            )
            return []
        }
        
        guard SyntaxUtilities.conformsToProtocol(structDecl, protocolName: "AxiomContext") else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: CrossCuttingMacroDiagnostic.mustConformToAxiomContext
                )
            )
            return []
        }
        
        // Extract cross-cutting concerns from the macro argument
        let concerns = try extractCrossCuttingConcerns(from: node, in: context)
        
        guard !concerns.isEmpty else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: CrossCuttingMacroDiagnostic.emptyConcerns
                )
            )
            return []
        }
        
        // Generate the cross-cutting infrastructure
        var generatedMembers: [DeclSyntax] = []
        
        // 1. Generate private service properties
        for concern in concerns {
            if let serviceProperty = generateServiceProperty(for: concern) {
                generatedMembers.append(DeclSyntax(serviceProperty))
            }
        }
        
        // 2. Generate public computed properties
        for concern in concerns {
            if let computedProperty = generateComputedProperty(for: concern) {
                generatedMembers.append(DeclSyntax(computedProperty))
            }
        }
        
        // 3. Generate enhanced initializer
        if let initializer = generateCrossCuttingInitializer(for: concerns, structName: structDecl.name.text) {
            generatedMembers.append(DeclSyntax(initializer))
        }
        
        return generatedMembers
    }
    
    // MARK: - Cross-Cutting Concern Extraction
    
    private static func extractCrossCuttingConcerns(
        from node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CrossCuttingConcern] {
        guard let arguments = node.arguments,
              case .argumentList(let argumentList) = arguments,
              let firstArgument = argumentList.first else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: CrossCuttingMacroDiagnostic.missingConcernsArgument
                )
            )
            return []
        }
        
        // Parse the concerns array
        guard let arrayExpr = firstArgument.expression.as(ArrayExprSyntax.self) else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: firstArgument.expression,
                    message: CrossCuttingMacroDiagnostic.invalidConcernsFormat
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
                            message: CrossCuttingMacroDiagnostic.unknownConcern(concernName)
                        )
                    )
                }
            } else {
                context.diagnose(
                    SyntaxUtilities.createDiagnostic(
                        node: element.expression,
                        message: CrossCuttingMacroDiagnostic.invalidConcernElement
                    )
                )
            }
        }
        
        return concerns
    }
    
    // MARK: - Code Generation
    
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
    
    private static func generateComputedProperty(for concern: CrossCuttingConcern) -> VariableDeclSyntax? {
        let propertyName = concern.propertyName
        let privatePropertyName = "_\(propertyName)"
        let serviceType = concern.serviceTypeName
        
        let getter = CodeBlockItemListSyntax([
            CodeBlockItemSyntax(
                item: .expr(ExprSyntax(
                    DeclReferenceExprSyntax(baseName: .identifier(privatePropertyName))
                ))
            )
        ])
        
        return CodeGenerationUtilities.createComputedProperty(
            name: propertyName,
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier(serviceType))),
            isPublic: false,
            getter: getter
        )
    }
    
    private static func generateCrossCuttingInitializer(
        for concerns: [CrossCuttingConcern],
        structName: String
    ) -> InitializerDeclSyntax? {
        var parameters: [FunctionParameterSyntax] = []
        var assignmentStatements: [CodeBlockItemSyntax] = []
        
        for concern in concerns {
            let propertyName = concern.propertyName
            let privatePropertyName = "_\(propertyName)"
            let serviceType = concern.serviceTypeName
            
            // Create parameter
            let parameter = CodeGenerationUtilities.createParameter(
                name: propertyName,
                type: TypeSyntax(IdentifierTypeSyntax(name: .identifier(serviceType)))
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
        }
        
        let body = CodeBlockItemListSyntax(assignmentStatements)
        
        return CodeGenerationUtilities.createInitializer(
            parameters: parameters,
            isPublic: true,
            body: body
        )
    }
}

// MARK: - Cross-Cutting Concern Types

/// Represents a cross-cutting concern that can be injected
enum CrossCuttingConcern: String, CaseIterable {
    case analytics
    case logging
    case errorReporting
    case performance
    case security
    case monitoring
    case audit
    case metrics
    
    static func fromString(_ name: String) -> CrossCuttingConcern? {
        return CrossCuttingConcern(rawValue: name)
    }
    
    var propertyName: String {
        switch self {
        case .analytics:
            return "analytics"
        case .logging:
            return "logger"
        case .errorReporting:
            return "errorReporting"
        case .performance:
            return "performance"
        case .security:
            return "security"
        case .monitoring:
            return "monitoring"
        case .audit:
            return "audit"
        case .metrics:
            return "metrics"
        }
    }
    
    var serviceTypeName: String {
        switch self {
        case .analytics:
            return "AnalyticsService"
        case .logging:
            return "LoggingService"
        case .errorReporting:
            return "ErrorReportingService"
        case .performance:
            return "PerformanceService"
        case .security:
            return "SecurityService"
        case .monitoring:
            return "MonitoringService"
        case .audit:
            return "AuditService"
        case .metrics:
            return "MetricsService"
        }
    }
}

// MARK: - Diagnostic Messages

/// Diagnostic messages specific to the @CrossCutting macro
enum CrossCuttingMacroDiagnostic: DiagnosticMessage {
    case onlyOnStructs
    case mustConformToAxiomContext
    case emptyConcerns
    case missingConcernsArgument
    case invalidConcernsFormat
    case invalidConcernElement
    case unknownConcern(String)
    
    var message: String {
        switch self {
        case .onlyOnStructs:
            return "@CrossCutting can only be applied to structs"
        case .mustConformToAxiomContext:
            return "@CrossCutting can only be used in structs that conform to AxiomContext"
        case .emptyConcerns:
            return "@CrossCutting requires at least one cross-cutting concern to be specified"
        case .missingConcernsArgument:
            return "@CrossCutting requires a cross-cutting concerns array argument"
        case .invalidConcernsFormat:
            return "@CrossCutting argument must be an array of cross-cutting concerns"
        case .invalidConcernElement:
            return "Invalid cross-cutting concern element. Use .concernName format"
        case .unknownConcern(let name):
            return "Unknown cross-cutting concern: '\(name)'. Available: analytics, logging, errorReporting, performance, security, monitoring, audit, metrics"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros.CrossCutting", id: "crossCutting")
    }
    
    var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - Macro Declaration

/// The @CrossCutting macro adds supervised cross-cutting concern injection to AxiomContext structs
@attached(member, names: arbitrary)
public macro CrossCutting<T>(_ concerns: [T]) = #externalMacro(module: "AxiomMacros", type: "CrossCuttingMacro")