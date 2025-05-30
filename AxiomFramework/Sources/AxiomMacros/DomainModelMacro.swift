import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - @DomainModel Macro Implementation

/// The @DomainModel macro for automatic domain model generation
/// Applied to structs to generate validation, business rules, and immutable update methods
public struct DomainModelMacro: MemberMacro, AxiomMacro {
    public static var macroName: String { "DomainModel" }
    
    public static func validateDeclaration<D: DeclSyntaxProtocol>(_ declaration: D, in context: some MacroExpansionContext) throws {
        // Validation is performed during expansion to provide better context
    }
    
    // MARK: - MemberMacro Implementation
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Validate this is applied to a struct
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: DomainModelMacroDiagnostic.onlyOnStructs
                )
            )
            return []
        }
        
        let structName = structDecl.name.text
        let members = SyntaxUtilities.extractMembers(from: structDecl) ?? MemberBlockItemListSyntax([])
        
        // Extract properties and business rule methods
        let properties = extractProperties(from: members)
        let businessRuleMethods = extractBusinessRuleMethods(from: members)
        
        // Generate the domain model methods
        var generatedMembers: [DeclSyntax] = []
        
        // 1. Generate validate() method
        if let validateMethod = try generateValidateMethod(businessRuleMethods: businessRuleMethods) {
            generatedMembers.append(DeclSyntax(validateMethod))
        }
        
        // 2. Generate businessRules() method
        if let businessRulesMethod = try generateBusinessRulesMethod(businessRuleMethods: businessRuleMethods) {
            generatedMembers.append(DeclSyntax(businessRulesMethod))
        }
        
        // 3. Generate immutable update methods
        for property in properties {
            if let updateMethod = try generateUpdateMethod(for: property, structName: structName, allProperties: properties) {
                generatedMembers.append(DeclSyntax(updateMethod))
            }
        }
        
        // 4. Generate ArchitecturalDNA methods
        if let componentIdProperty = generateComponentIdProperty(structName: structName) {
            generatedMembers.append(DeclSyntax(componentIdProperty))
        }
        
        if let purposeProperty = generatePurposeProperty(structName: structName) {
            generatedMembers.append(DeclSyntax(purposeProperty))
        }
        
        if let constraintsProperty = generateConstraintsProperty() {
            generatedMembers.append(DeclSyntax(constraintsProperty))
        }
        
        return generatedMembers
    }
    
    // MARK: - Property and Method Extraction
    
    private static func extractProperties(from members: MemberBlockItemListSyntax) -> [PropertyInfo] {
        var properties: [PropertyInfo] = []
        
        for member in members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = varDecl.bindings.first,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  let typeAnnotation = binding.typeAnnotation else {
                continue
            }
            
            // Only include stored properties (let/var without accessors)
            if binding.accessorBlock == nil {
                properties.append(PropertyInfo(
                    name: pattern.identifier.text,
                    type: typeAnnotation.type,
                    isLet: varDecl.bindingSpecifier.tokenKind == .keyword(.let)
                ))
            }
        }
        
        return properties
    }
    
    private static func extractBusinessRuleMethods(from members: MemberBlockItemListSyntax) -> [BusinessRuleMethodInfo] {
        var businessRuleMethods: [BusinessRuleMethodInfo] = []
        
        for member in members {
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
                continue
            }
            
            // Check if function has @BusinessRule attribute
            for attribute in funcDecl.attributes {
                if case .attribute(let attr) = attribute,
                   attr.attributeName.trimmedDescription == "BusinessRule" {
                    
                    let ruleName = extractBusinessRuleName(from: attr) ?? "Business rule violation"
                    businessRuleMethods.append(BusinessRuleMethodInfo(
                        name: funcDecl.name.text,
                        ruleName: ruleName
                    ))
                    break
                }
            }
        }
        
        return businessRuleMethods
    }
    
    private static func extractBusinessRuleName(from attribute: AttributeSyntax) -> String? {
        guard let arguments = attribute.arguments,
              case .argumentList(let argumentList) = arguments,
              let firstArgument = argumentList.first,
              let stringLiteral = firstArgument.expression.as(StringLiteralExprSyntax.self),
              case .stringSegment(let segment) = stringLiteral.segments.first else {
            return nil
        }
        
        return segment.content.text
    }
    
    // MARK: - Code Generation
    
    private static func generateValidateMethod(businessRuleMethods: [BusinessRuleMethodInfo]) throws -> FunctionDeclSyntax? {
        var bodyStatements: [CodeBlockItemSyntax] = []
        
        // Create issues array
        let issuesDeclaration = CodeBlockItemSyntax(
            item: .decl(DeclSyntax(
                VariableDeclSyntax(
                    bindingSpecifier: .keyword(.var),
                    bindings: PatternBindingListSyntax([
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: .identifier("issues")),
                            typeAnnotation: TypeAnnotationSyntax(
                                type: TypeSyntax(ArrayTypeSyntax(
                                    element: TypeSyntax(IdentifierTypeSyntax(name: .identifier("ValidationIssue")))
                                ))
                            ),
                            initializer: InitializerClauseSyntax(
                                value: ExprSyntax(ArrayExprSyntax(
                                    leftSquare: .leftSquareToken(),
                                    elements: ArrayElementListSyntax([]),
                                    rightSquare: .rightSquareToken()
                                ))
                            )
                        )
                    ])
                )
            ))
        )
        bodyStatements.append(issuesDeclaration)
        
        // Add validation checks for each business rule
        for businessRule in businessRuleMethods {
            let condition = PrefixOperatorExprSyntax(
                operator: .exclamationMarkToken(),
                expression: ExprSyntax(
                    FunctionCallExprSyntax(
                        calledExpression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(businessRule.name))),
                        leftParen: .leftParenToken(),
                        arguments: LabeledExprListSyntax([]),
                        rightParen: .rightParenToken()
                    )
                )
            )
            
            let businessRuleCall = FunctionCallExprSyntax(
                calledExpression: ExprSyntax(MemberAccessExprSyntax(
                    period: .periodToken(),
                    declName: DeclReferenceExprSyntax(baseName: .identifier("businessRuleViolation"))
                )),
                leftParen: .leftParenToken(),
                arguments: LabeledExprListSyntax([
                    LabeledExprSyntax(
                        expression: ExprSyntax(StringLiteralExprSyntax(content: businessRule.ruleName))
                    )
                ]),
                rightParen: .rightParenToken()
            )
            
            let appendCall = FunctionCallExprSyntax(
                calledExpression: ExprSyntax(MemberAccessExprSyntax(
                    base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("issues"))),
                    period: .periodToken(),
                    declName: DeclReferenceExprSyntax(baseName: .identifier("append"))
                )),
                leftParen: .leftParenToken(),
                arguments: LabeledExprListSyntax([
                    LabeledExprSyntax(
                        expression: ExprSyntax(businessRuleCall)
                    )
                ]),
                rightParen: .rightParenToken()
            )
            
            let ifStatement = IfExprSyntax(
                conditions: ConditionElementListSyntax([
                    ConditionElementSyntax(condition: .expression(ExprSyntax(condition)))
                ]),
                body: CodeBlockSyntax(
                    statements: CodeBlockItemListSyntax([
                        CodeBlockItemSyntax(item: .expr(ExprSyntax(appendCall)))
                    ])
                )
            )
            
            bodyStatements.append(CodeBlockItemSyntax(item: .expr(ExprSyntax(ifStatement))))
        }
        
        // Return ValidationResult
        let returnStatement = CodeBlockItemSyntax(
            item: .stmt(StmtSyntax(
                ReturnStmtSyntax(
                    expression: ExprSyntax(
                        FunctionCallExprSyntax(
                            calledExpression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("ValidationResult"))),
                            leftParen: .leftParenToken(),
                            arguments: LabeledExprListSyntax([
                                LabeledExprSyntax(
                                    label: .identifier("issues"),
                                    expression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("issues")))
                                )
                            ]),
                            rightParen: .rightParenToken()
                        )
                    )
                )
            ))
        )
        bodyStatements.append(returnStatement)
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: .identifier("validate"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax([])
                ),
                returnClause: ReturnClauseSyntax(
                    type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("ValidationResult")))
                )
            ),
            body: CodeBlockSyntax(statements: CodeBlockItemListSyntax(bodyStatements))
        )
    }
    
    private static func generateBusinessRulesMethod(businessRuleMethods: [BusinessRuleMethodInfo]) throws -> FunctionDeclSyntax? {
        var arrayElements: [ArrayElementSyntax] = []
        
        for (index, businessRule) in businessRuleMethods.enumerated() {
            let businessRuleInit = FunctionCallExprSyntax(
                calledExpression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("BusinessRule"))),
                leftParen: .leftParenToken(),
                arguments: LabeledExprListSyntax([
                    LabeledExprSyntax(
                        label: .identifier("name"),
                        expression: ExprSyntax(StringLiteralExprSyntax(content: businessRule.ruleName))
                    ),
                    LabeledExprSyntax(
                        label: .identifier("validator"),
                        expression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(businessRule.name)))
                    )
                ]),
                rightParen: .rightParenToken()
            )
            
            let element = ArrayElementSyntax(
                expression: ExprSyntax(businessRuleInit),
                trailingComma: index < businessRuleMethods.count - 1 ? .commaToken() : nil
            )
            arrayElements.append(element)
        }
        
        let arrayExpr = ArrayExprSyntax(
            leftSquare: .leftSquareToken(),
            elements: ArrayElementListSyntax(arrayElements),
            rightSquare: .rightSquareToken()
        )
        
        let returnStatement = CodeBlockItemSyntax(
            item: .stmt(StmtSyntax(
                ReturnStmtSyntax(expression: ExprSyntax(arrayExpr))
            ))
        )
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: .identifier("businessRules"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax([])
                ),
                returnClause: ReturnClauseSyntax(
                    type: TypeSyntax(ArrayTypeSyntax(
                        element: TypeSyntax(IdentifierTypeSyntax(name: .identifier("BusinessRule")))
                    ))
                )
            ),
            body: CodeBlockSyntax(statements: CodeBlockItemListSyntax([returnStatement]))
        )
    }
    
    private static func generateUpdateMethod(
        for property: PropertyInfo,
        structName: String,
        allProperties: [PropertyInfo]
    ) throws -> FunctionDeclSyntax? {
        let capitalizedName = property.name.prefix(1).uppercased() + property.name.dropFirst()
        let methodName = "withUpdated\(capitalizedName)"
        let parameterName = "new\(capitalizedName)"
        
        // Create parameter
        let parameter = CodeGenerationUtilities.createParameter(
            name: parameterName,
            type: property.type
        )
        
        // Create new instance with updated property
        var initArguments: [LabeledExprSyntax] = []
        for prop in allProperties {
            let argumentValue = prop.name == property.name ? 
                ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(parameterName))) :
                ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(prop.name)))
            
            initArguments.append(LabeledExprSyntax(
                label: .identifier(prop.name),
                expression: argumentValue
            ))
        }
        
        let newInstanceInit = FunctionCallExprSyntax(
            calledExpression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(structName))),
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax(initArguments),
            rightParen: .rightParenToken()
        )
        
        let updatedDeclaration = CodeBlockItemSyntax(
            item: .decl(DeclSyntax(
                VariableDeclSyntax(
                    bindingSpecifier: .keyword(.let),
                    bindings: PatternBindingListSyntax([
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: .identifier("updated")),
                            initializer: InitializerClauseSyntax(value: ExprSyntax(newInstanceInit))
                        )
                    ])
                )
            ))
        )
        
        // Validate the updated instance
        let validationCall = FunctionCallExprSyntax(
            calledExpression: ExprSyntax(MemberAccessExprSyntax(
                base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("updated"))),
                period: .periodToken(),
                declName: DeclReferenceExprSyntax(baseName: .identifier("validate"))
            )),
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax([]),
            rightParen: .rightParenToken()
        )
        
        let validationDeclaration = CodeBlockItemSyntax(
            item: .decl(DeclSyntax(
                VariableDeclSyntax(
                    bindingSpecifier: .keyword(.let),
                    bindings: PatternBindingListSyntax([
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: .identifier("validation")),
                            initializer: InitializerClauseSyntax(value: ExprSyntax(validationCall))
                        )
                    ])
                )
            ))
        )
        
        // Return success or failure based on validation using if-else
        let successCall = FunctionCallExprSyntax(
            calledExpression: ExprSyntax(MemberAccessExprSyntax(
                period: .periodToken(),
                declName: DeclReferenceExprSyntax(baseName: .identifier("success"))
            )),
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax([
                LabeledExprSyntax(expression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("updated"))))
            ]),
            rightParen: .rightParenToken()
        )
        
        let failureCall = FunctionCallExprSyntax(
            calledExpression: ExprSyntax(MemberAccessExprSyntax(
                period: .periodToken(),
                declName: DeclReferenceExprSyntax(baseName: .identifier("failure"))
            )),
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax([
                LabeledExprSyntax(expression: ExprSyntax(
                    MemberAccessExprSyntax(
                        period: .periodToken(),
                        declName: DeclReferenceExprSyntax(baseName: .identifier("validationFailed"))
                    )
                ))
            ]),
            rightParen: .rightParenToken()
        )
        
        let ifStatement = IfExprSyntax(
            conditions: ConditionElementListSyntax([
                ConditionElementSyntax(condition: .expression(ExprSyntax(
                    MemberAccessExprSyntax(
                        base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("validation"))),
                        period: .periodToken(),
                        declName: DeclReferenceExprSyntax(baseName: .identifier("isValid"))
                    )
                )))
            ]),
            body: CodeBlockSyntax(
                statements: CodeBlockItemListSyntax([
                    CodeBlockItemSyntax(item: .stmt(StmtSyntax(
                        ReturnStmtSyntax(expression: ExprSyntax(successCall))
                    )))
                ])
            ),
            elseKeyword: .keyword(.else),
            elseBody: .codeBlock(CodeBlockSyntax(
                statements: CodeBlockItemListSyntax([
                    CodeBlockItemSyntax(item: .stmt(StmtSyntax(
                        ReturnStmtSyntax(expression: ExprSyntax(failureCall))
                    )))
                ])
            ))
        )
        
        let conditionalReturnStatement = CodeBlockItemSyntax(
            item: .expr(ExprSyntax(ifStatement))
        )
        
        let bodyStatements = CodeBlockItemListSyntax([
            updatedDeclaration,
            validationDeclaration,
            conditionalReturnStatement
        ])
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: .identifier(methodName),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax([parameter])
                ),
                returnClause: ReturnClauseSyntax(
                    type: TypeSyntax(IdentifierTypeSyntax(
                        name: .identifier("Result"),
                        genericArgumentClause: GenericArgumentClauseSyntax(
                            arguments: GenericArgumentListSyntax([
                                GenericArgumentSyntax(
                                    argument: TypeSyntax(IdentifierTypeSyntax(name: .identifier(structName)))
                                ),
                                GenericArgumentSyntax(
                                    argument: TypeSyntax(IdentifierTypeSyntax(name: .identifier("DomainError")))
                                )
                            ])
                        )
                    ))
                )
            ),
            body: CodeBlockSyntax(statements: bodyStatements)
        )
    }
    
    private static func generateComponentIdProperty(structName: String) -> VariableDeclSyntax? {
        let getter = CodeBlockItemListSyntax([
            CodeBlockItemSyntax(
                item: .expr(ExprSyntax(
                    FunctionCallExprSyntax(
                        calledExpression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("ComponentID"))),
                        leftParen: .leftParenToken(),
                        arguments: LabeledExprListSyntax([
                            LabeledExprSyntax(
                                expression: ExprSyntax(StringLiteralExprSyntax(content: "\(structName)-DomainModel"))
                            )
                        ]),
                        rightParen: .rightParenToken()
                    )
                ))
            )
        ])
        
        return CodeGenerationUtilities.createComputedProperty(
            name: "componentId",
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("ComponentID"))),
            isPublic: false,
            getter: getter
        )
    }
    
    private static func generatePurposeProperty(structName: String) -> VariableDeclSyntax? {
        let getter = CodeBlockItemListSyntax([
            CodeBlockItemSyntax(
                item: .expr(ExprSyntax(
                    FunctionCallExprSyntax(
                        calledExpression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("ComponentPurpose"))),
                        leftParen: .leftParenToken(),
                        arguments: LabeledExprListSyntax([
                            LabeledExprSyntax(
                                label: .identifier("domain"),
                                expression: ExprSyntax(MemberAccessExprSyntax(
                                    period: .periodToken(),
                                    declName: DeclReferenceExprSyntax(baseName: .identifier("domainModeling"))
                                ))
                            ),
                            LabeledExprSyntax(
                                label: .identifier("responsibility"),
                                expression: ExprSyntax(MemberAccessExprSyntax(
                                    period: .periodToken(),
                                    declName: DeclReferenceExprSyntax(baseName: .identifier("valueObject"))
                                ))
                            ),
                            LabeledExprSyntax(
                                label: .identifier("businessValue"),
                                expression: ExprSyntax(MemberAccessExprSyntax(
                                    period: .periodToken(),
                                    declName: DeclReferenceExprSyntax(baseName: .identifier("dataIntegrity"))
                                ))
                            ),
                            LabeledExprSyntax(
                                label: .identifier("userImpact"),
                                expression: ExprSyntax(MemberAccessExprSyntax(
                                    period: .periodToken(),
                                    declName: DeclReferenceExprSyntax(baseName: .identifier("essential"))
                                ))
                            )
                        ]),
                        rightParen: .rightParenToken()
                    )
                ))
            )
        ])
        
        return CodeGenerationUtilities.createComputedProperty(
            name: "purpose",
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("ComponentPurpose"))),
            isPublic: false,
            getter: getter
        )
    }
    
    private static func generateConstraintsProperty() -> VariableDeclSyntax? {
        let arrayElements = [
            ArrayElementSyntax(
                expression: ExprSyntax(MemberAccessExprSyntax(
                    period: .periodToken(),
                    declName: DeclReferenceExprSyntax(baseName: .identifier("immutableValueObject"))
                )),
                trailingComma: .commaToken()
            ),
            ArrayElementSyntax(
                expression: ExprSyntax(MemberAccessExprSyntax(
                    period: .periodToken(),
                    declName: DeclReferenceExprSyntax(baseName: .identifier("businessLogicEmbedded"))
                )),
                trailingComma: .commaToken()
            ),
            ArrayElementSyntax(
                expression: ExprSyntax(MemberAccessExprSyntax(
                    period: .periodToken(),
                    declName: DeclReferenceExprSyntax(baseName: .identifier("domainValidation"))
                ))
            )
        ]
        
        let arrayExpr = ArrayExprSyntax(
            leftSquare: .leftSquareToken(),
            elements: ArrayElementListSyntax(arrayElements),
            rightSquare: .rightSquareToken()
        )
        
        let getter = CodeBlockItemListSyntax([
            CodeBlockItemSyntax(
                item: .expr(ExprSyntax(arrayExpr))
            )
        ])
        
        return CodeGenerationUtilities.createComputedProperty(
            name: "constraints",
            type: TypeSyntax(ArrayTypeSyntax(
                element: TypeSyntax(IdentifierTypeSyntax(name: .identifier("ArchitecturalConstraint")))
            )),
            isPublic: false,
            getter: getter
        )
    }
}

// MARK: - Supporting Types

struct PropertyInfo {
    let name: String
    let type: TypeSyntax
    let isLet: Bool
}

struct BusinessRuleMethodInfo {
    let name: String
    let ruleName: String
}

// MARK: - Diagnostic Messages

/// Diagnostic messages specific to the @DomainModel macro
enum DomainModelMacroDiagnostic: String, DiagnosticMessage {
    case onlyOnStructs
    case invalidBusinessRule
    case missingValidationMethod
    
    var message: String {
        switch self {
        case .onlyOnStructs:
            return "@DomainModel can only be applied to structs"
        case .invalidBusinessRule:
            return "@BusinessRule methods must return Bool and take no parameters"
        case .missingValidationMethod:
            return "@BusinessRule attribute requires a validation method name"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros.DomainModel", id: rawValue)
    }
    
    var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - Macro Declaration

/// The @DomainModel macro adds domain model validation and immutable update methods
@attached(member, names: named(validate), named(businessRules), arbitrary)
public macro DomainModel() = #externalMacro(module: "AxiomMacros", type: "DomainModelMacro")