import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - @ObservableState Macro Implementation

/// The @ObservableState macro for automatic state property generation and observation capabilities
/// Applied to structs or classes to generate observable state patterns
public struct ObservableStateMacro: MemberMacro, AxiomMacro {
    public static var macroName: String { "ObservableState" }
    
    public static func validateDeclaration<D: DeclSyntaxProtocol>(_ declaration: D, in context: some MacroExpansionContext) throws {
        // Validation is performed during expansion to provide better context
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Validate this is applied to a struct or class only
        let isStruct = declaration.as(StructDeclSyntax.self) != nil
        let isClass = declaration.as(ClassDeclSyntax.self) != nil
        
        guard isStruct || isClass else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: ObservableStateMacroDiagnostic.onlyOnStructsOrClasses
                )
            )
            return []
        }
        
        // Extract properties from the declaration
        let members: MemberBlockItemListSyntax
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            members = structDecl.memberBlock.members
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            members = classDecl.memberBlock.members
        } else {
            members = MemberBlockItemListSyntax([])
        }
        let varProperties = extractVariableProperties(from: members)
        
        // Generate the boilerplate code
        var generatedMembers: [DeclSyntax] = []
        
        // Generate the code in sections matching test expectations
        generatedMembers.append(DeclSyntax("// MARK: - Observable State Properties"))
        
        if let stateVersionProperty = generateStateVersionProperty() {
            generatedMembers.append(DeclSyntax(stateVersionProperty))
        }
        
        generatedMembers.append(DeclSyntax("// MARK: - State Change Notifications"))
        
        if let notifyMethod = generateNotifyStateChangeMethod() {
            generatedMembers.append(DeclSyntax(notifyMethod))
        }
        
        // Generate setter methods for var properties (if any exist)
        if !varProperties.isEmpty {
            generatedMembers.append(DeclSyntax("// MARK: - Observable State Setters"))
            
            for property in varProperties {
                if let setter = generateSetterMethod(for: property, isStruct: isStruct) {
                    generatedMembers.append(DeclSyntax(setter))
                }
            }
        }
        
        return generatedMembers
    }
    
    // MARK: - Property Extraction
    
    private static func extractVariableProperties(from members: MemberBlockItemListSyntax) -> [VariableProperty] {
        var properties: [VariableProperty] = []
        
        for member in members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.bindingSpecifier.tokenKind == .keyword(.var) else {
                continue
            }
            
            // Check if it's private
            let isPrivate = varDecl.modifiers.contains { modifier in
                modifier.name.tokenKind == .keyword(.private)
            }
            
            // Skip private properties - only generate setters for public/internal
            guard !isPrivate else { continue }
            
            for binding in varDecl.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                      let typeAnnotation = binding.typeAnnotation?.type else {
                    continue
                }
                
                let propertyName = pattern.identifier.text
                let propertyType = typeAnnotation.trimmedDescription
                
                // Skip non-equatable types (heuristic approach)
                guard isLikelyEquatable(propertyType) else {
                    continue
                }
                
                properties.append(VariableProperty(
                    name: propertyName,
                    type: propertyType
                ))
            }
        }
        
        return properties
    }
    
    /// Simple heuristic to determine if a type is likely Equatable
    private static func isLikelyEquatable(_ type: String) -> Bool {
        // Skip obvious non-equatable types
        if type.contains("Any") ||
           type.contains("->") ||   // Function types
           type.hasPrefix("(") && type.hasSuffix(")") && type.contains("->") {  // Closures
            return false
        }
        
        // Skip dictionaries with Any values
        if type.contains("[") && type.contains(":") && type.contains("Any") {
            return false
        }
        
        // For all other types, assume they are likely equatable
        // This includes: String, Int, Bool, [String], Int?, custom types, etc.
        return true
    }
    
    // MARK: - Code Generation
    
    private static func generateStateVersionProperty() -> VariableDeclSyntax? {
        let pattern = PatternBindingSyntax(
            pattern: IdentifierPatternSyntax(identifier: .identifier("_stateVersion")),
            typeAnnotation: TypeAnnotationSyntax(
                type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("Int")))
            ),
            initializer: InitializerClauseSyntax(
                value: ExprSyntax(IntegerLiteralExprSyntax(literal: .integerLiteral("0")))
            )
        )
        
        return VariableDeclSyntax(
            attributes: AttributeListSyntax([
                .attribute(AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("Published"))
                ))
            ]),
            modifiers: [DeclModifierSyntax(name: .keyword(.private))],
            bindingSpecifier: .keyword(.var),
            bindings: PatternBindingListSyntax([pattern])
        )
    }
    
    
    private static func generateNotifyStateChangeMethod() -> FunctionDeclSyntax? {
        // Generate: private func notifyStateChange() { _stateVersion += 1 }
        let incrementStatement = CodeBlockItemSyntax(
            item: .expr(ExprSyntax(
                SequenceExprSyntax(
                    elements: ExprListSyntax([
                        ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("_stateVersion"))),
                        ExprSyntax(BinaryOperatorExprSyntax(text: "+=")),
                        ExprSyntax(IntegerLiteralExprSyntax(literal: .integerLiteral("1")))
                    ])
                )
            ))
        )
        
        let body = CodeBlockItemListSyntax([incrementStatement])
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.private))],
            name: .identifier("notifyStateChange"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax([])
                )
            ),
            body: CodeBlockSyntax(statements: body)
        )
    }
    
    
    private static func generateSetterMethod(for property: VariableProperty, isStruct: Bool) -> FunctionDeclSyntax? {
        let capitalizedName = property.name.capitalizedFirst
        let methodName = "set\(capitalizedName)"
        let mutatingKeyword = isStruct ? "mutating " : ""
        
        // Use string interpolation to create the entire function
        let functionDeclaration = DeclSyntax(
            """
            \(raw: mutatingKeyword)func \(raw: methodName)(_ newValue: \(raw: property.type)) {
                if \(raw: property.name) != newValue {
                    \(raw: property.name) = newValue
                    notifyStateChange()
                }
            }
            """
        )
        
        return functionDeclaration.as(FunctionDeclSyntax.self)
    }
}

// MARK: - Supporting Types

private struct VariableProperty {
    let name: String
    let type: String
}

// MARK: - Diagnostic Messages

/// Diagnostic messages specific to the @ObservableState macro
enum ObservableStateMacroDiagnostic: String, DiagnosticMessage {
    case onlyOnStructsOrClasses
    case conflictingMacros
    case invalidPropertyType
    
    var message: String {
        switch self {
        case .onlyOnStructsOrClasses:
            return "@ObservableState can only be applied to structs or classes"
        case .conflictingMacros:
            return "@ObservableState conflicts with other state-related macros"
        case .invalidPropertyType:
            return "@ObservableState cannot handle this property type"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros.ObservableState", id: rawValue)
    }
    
    var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - String Extensions

private extension String {
    var capitalizedFirst: String {
        guard !isEmpty else { return self }
        return String(prefix(1).uppercased() + dropFirst())
    }
}

// MARK: - Macro Declaration

/// The @ObservableState macro adds automatic state property generation and observation capabilities
@attached(member, names: named(_stateVersion), named(notifyStateChange), arbitrary)
public macro ObservableState() = #externalMacro(module: "AxiomMacros", type: "ObservableStateMacro")