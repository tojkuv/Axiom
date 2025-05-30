import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

// MARK: - Macro Infrastructure

/// Base protocol for all Axiom macros
public protocol AxiomMacro: Macro {
    /// The name of the macro as it appears in source code
    static var macroName: String { get }
    
    /// Validates that a macro is applied to the correct declaration type
    static func validateDeclaration<D: DeclSyntaxProtocol>(_ declaration: D, in context: some MacroExpansionContext) throws
}

// MARK: - Diagnostic Messages

/// Common diagnostic messages for Axiom macros
public enum AxiomMacroDiagnostic {
    /// Base diagnostic type
    public enum DiagnosticType: String, DiagnosticMessage {
        case wrongDeclarationType
        case missingProtocolConformance
        case invalidArguments
        case duplicateApplication
        case conflictingMacros
        
        public var message: String {
            switch self {
            case .wrongDeclarationType:
                return "This macro can only be applied to the specified declaration type"
            case .missingProtocolConformance:
                return "The declaration must conform to the required protocol"
            case .invalidArguments:
                return "Invalid arguments provided to the macro"
            case .duplicateApplication:
                return "This macro cannot be applied multiple times to the same declaration"
            case .conflictingMacros:
                return "This macro conflicts with another macro on the same declaration"
            }
        }
        
        public var diagnosticID: MessageID {
            MessageID(domain: "AxiomMacros", id: rawValue)
        }
        
        public var severity: DiagnosticSeverity {
            .error
        }
    }
}

// MARK: - Syntax Utilities

/// Utilities for working with Swift syntax
public enum SyntaxUtilities {
    
    /// Extracts the name from a declaration
    public static func extractName(from declaration: some DeclSyntaxProtocol) -> String? {
        switch declaration {
        case let structDecl as StructDeclSyntax:
            return structDecl.name.text
        case let classDecl as ClassDeclSyntax:
            return classDecl.name.text
        case let actorDecl as ActorDeclSyntax:
            return actorDecl.name.text
        case let enumDecl as EnumDeclSyntax:
            return enumDecl.name.text
        case let funcDecl as FunctionDeclSyntax:
            return funcDecl.name.text
        case let varDecl as VariableDeclSyntax:
            return varDecl.bindings.first?.pattern.trimmedDescription
        default:
            return nil
        }
    }
    
    /// Checks if a declaration conforms to a specific protocol
    public static func conformsToProtocol(_ declaration: some DeclSyntaxProtocol, protocolName: String) -> Bool {
        guard let inheritanceClause = extractInheritanceClause(from: declaration) else {
            return false
        }
        
        return inheritanceClause.inheritedTypes.contains { inheritedType in
            inheritedType.type.trimmedDescription == protocolName
        }
    }
    
    /// Extracts the inheritance clause from a declaration
    public static func extractInheritanceClause(from declaration: some DeclSyntaxProtocol) -> InheritanceClauseSyntax? {
        switch declaration {
        case let structDecl as StructDeclSyntax:
            return structDecl.inheritanceClause
        case let classDecl as ClassDeclSyntax:
            return classDecl.inheritanceClause
        case let actorDecl as ActorDeclSyntax:
            return actorDecl.inheritanceClause
        case let enumDecl as EnumDeclSyntax:
            return enumDecl.inheritanceClause
        default:
            return nil
        }
    }
    
    /// Extracts members from a declaration
    public static func extractMembers(from declaration: some DeclSyntaxProtocol) -> MemberBlockItemListSyntax? {
        switch declaration {
        case let structDecl as StructDeclSyntax:
            return structDecl.memberBlock.members
        case let classDecl as ClassDeclSyntax:
            return classDecl.memberBlock.members
        case let actorDecl as ActorDeclSyntax:
            return actorDecl.memberBlock.members
        case let enumDecl as EnumDeclSyntax:
            return enumDecl.memberBlock.members
        default:
            return nil
        }
    }
    
    /// Finds all properties with a specific attribute
    public static func findProperties(withAttribute attributeName: String, in members: MemberBlockItemListSyntax) -> [VariableDeclSyntax] {
        members.compactMap { member in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                return nil
            }
            
            let hasAttribute = varDecl.attributes.contains { attribute in
                switch attribute {
                case .attribute(let attr):
                    return attr.attributeName.trimmedDescription == attributeName
                case .ifConfigDecl:
                    return false
                }
            }
            
            return hasAttribute ? varDecl : nil
        }
    }
    
    /// Extracts type information from a variable declaration
    public static func extractType(from varDecl: VariableDeclSyntax) -> TypeSyntax? {
        guard let binding = varDecl.bindings.first,
              let typeAnnotation = binding.typeAnnotation else {
            return nil
        }
        
        return typeAnnotation.type
    }
    
    /// Creates a diagnostic for a node
    public static func createDiagnostic<N: SyntaxProtocol>(
        node: N,
        message: any DiagnosticMessage,
        highlights: [Syntax] = [],
        notes: [Note] = [],
        fixIts: [FixIt] = []
    ) -> Diagnostic {
        Diagnostic(
            node: node,
            message: message,
            highlights: highlights,
            notes: notes,
            fixIts: fixIts
        )
    }
}

// MARK: - Code Generation Utilities

/// Utilities for generating Swift code
public enum CodeGenerationUtilities {
    
    /// Creates a stored property declaration
    public static func createStoredProperty(
        name: String,
        type: TypeSyntax,
        isPrivate: Bool = true,
        isLet: Bool = true,
        initializer: ExprSyntax? = nil
    ) -> VariableDeclSyntax {
        let pattern = PatternBindingSyntax(
            pattern: IdentifierPatternSyntax(identifier: .identifier(name)),
            typeAnnotation: TypeAnnotationSyntax(type: type),
            initializer: initializer.map { InitializerClauseSyntax(value: $0) }
        )
        
        return VariableDeclSyntax(
            modifiers: isPrivate ? [DeclModifierSyntax(name: .keyword(.private))] : [],
            bindingSpecifier: .keyword(isLet ? .let : .var),
            bindings: PatternBindingListSyntax([pattern])
        )
    }
    
    /// Creates a computed property declaration
    public static func createComputedProperty(
        name: String,
        type: TypeSyntax,
        isPublic: Bool = false,
        getter: CodeBlockItemListSyntax
    ) -> VariableDeclSyntax {
        let accessorBlock = AccessorBlockSyntax(
            accessors: .getter(getter)
        )
        
        let pattern = PatternBindingSyntax(
            pattern: IdentifierPatternSyntax(identifier: .identifier(name)),
            typeAnnotation: TypeAnnotationSyntax(type: type),
            accessorBlock: accessorBlock
        )
        
        return VariableDeclSyntax(
            modifiers: isPublic ? [DeclModifierSyntax(name: .keyword(.public))] : [],
            bindingSpecifier: .keyword(.var),
            bindings: PatternBindingListSyntax([pattern])
        )
    }
    
    /// Creates an initializer declaration
    public static func createInitializer(
        parameters: [FunctionParameterSyntax],
        isPublic: Bool = false,
        body: CodeBlockItemListSyntax
    ) -> InitializerDeclSyntax {
        InitializerDeclSyntax(
            modifiers: isPublic ? [DeclModifierSyntax(name: .keyword(.public))] : [],
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax(parameters)
                )
            ),
            body: CodeBlockSyntax(statements: body)
        )
    }
    
    /// Creates a function parameter
    public static func createParameter(
        label: String? = nil,
        name: String,
        type: TypeSyntax
    ) -> FunctionParameterSyntax {
        FunctionParameterSyntax(
            firstName: label.map { TokenSyntax.identifier($0) } ?? TokenSyntax.wildcardToken(),
            secondName: label != nil ? TokenSyntax.identifier(name) : nil,
            type: type
        )
    }
    
    /// Creates a function call expression
    public static func createFunctionCall(
        function: ExprSyntax,
        arguments: [(label: String?, expression: ExprSyntax)] = []
    ) -> FunctionCallExprSyntax {
        let argumentList = arguments.map { arg in
            LabeledExprSyntax(
                label: arg.label.map { .identifier($0) },
                expression: arg.expression
            )
        }
        
        return FunctionCallExprSyntax(
            calledExpression: function,
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax(argumentList),
            rightParen: .rightParenToken()
        )
    }
    
    /// Creates an await expression
    public static func createAwaitExpression(_ expression: ExprSyntax) -> AwaitExprSyntax {
        AwaitExprSyntax(expression: expression)
    }
    
    /// Creates a member access expression
    public static func createMemberAccess(
        base: ExprSyntax?,
        member: String
    ) -> MemberAccessExprSyntax {
        MemberAccessExprSyntax(
            base: base,
            period: .periodToken(),
            declName: DeclReferenceExprSyntax(baseName: .identifier(member))
        )
    }
}

// MARK: - Validation Utilities

/// Utilities for validating macro applications
public enum ValidationUtilities {
    
    /// Validates that a macro is not applied multiple times
    public static func validateSingleApplication(
        of macroName: String,
        in attributes: AttributeListSyntax
    ) -> Bool {
        let count = attributes.filter { attribute in
            switch attribute {
            case .attribute(let attr):
                return attr.attributeName.trimmedDescription == macroName
            case .ifConfigDecl:
                return false
            }
        }.count
        
        return count <= 1
    }
    
    /// Validates that required arguments are present
    public static func validateRequiredArguments(
        _ arguments: LabeledExprListSyntax?,
        required: Set<String>
    ) -> Set<String> {
        guard let arguments = arguments else {
            return required
        }
        
        let providedLabels = Set(arguments.compactMap { $0.label?.text })
        return required.subtracting(providedLabels)
    }
    
    /// Validates that no conflicting macros are present
    public static func validateNoConflicts(
        with conflictingMacros: Set<String>,
        in attributes: AttributeListSyntax
    ) -> Set<String> {
        let appliedMacros = attributes.compactMap { attribute -> String? in
            switch attribute {
            case .attribute(let attr):
                return attr.attributeName.trimmedDescription
            case .ifConfigDecl:
                return nil
            }
        }
        
        return conflictingMacros.intersection(appliedMacros)
    }
}

// MARK: - Type Checking Utilities

/// Utilities for type checking and inference
public enum TypeCheckingUtilities {
    
    /// Checks if a type conforms to a protocol
    public static func typeConforms(
        _ type: TypeSyntax,
        to protocolName: String,
        in context: some MacroExpansionContext
    ) -> Bool {
        // This is a simplified check - in a real implementation,
        // we would use the type checker API when available
        return type.trimmedDescription.contains(protocolName)
    }
    
    /// Extracts generic parameters from a type
    public static func extractGenericParameters(from type: TypeSyntax) -> [String] {
        guard let identifierType = type.as(IdentifierTypeSyntax.self),
              let genericArguments = identifierType.genericArgumentClause else {
            return []
        }
        
        return genericArguments.arguments.map { $0.argument.trimmedDescription }
    }
    
    /// Checks if a type is optional
    public static func isOptionalType(_ type: TypeSyntax) -> Bool {
        if type.is(OptionalTypeSyntax.self) {
            return true
        }
        
        if let identifierType = type.as(IdentifierTypeSyntax.self),
           identifierType.name.text == "Optional",
           identifierType.genericArgumentClause != nil {
            return true
        }
        
        return false
    }
    
    /// Unwraps an optional type to get the underlying type
    public static func unwrapOptionalType(_ type: TypeSyntax) -> TypeSyntax? {
        if let optionalType = type.as(OptionalTypeSyntax.self) {
            return optionalType.wrappedType
        }
        
        if let identifierType = type.as(IdentifierTypeSyntax.self),
           identifierType.name.text == "Optional",
           let genericArgument = identifierType.genericArgumentClause?.arguments.first {
            return genericArgument.argument
        }
        
        return nil
    }
}

// MARK: - Macro Testing Utilities

/// Utilities for testing macros
public enum MacroTestingUtilities {
    
    /// Creates a test context for macro expansion
    public static func createTestContext() -> BasicMacroExpansionContext {
        BasicMacroExpansionContext()
    }
    
    /// Compares generated code with expected code
    public static func assertCodeEquals(
        generated: String,
        expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let normalizedGenerated = generated.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedExpected = expected.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if normalizedGenerated != normalizedExpected {
            print("Generated code does not match expected:")
            print("Generated:\n\(normalizedGenerated)")
            print("Expected:\n\(normalizedExpected)")
            assert(false, "Code generation mismatch", file: file, line: line)
        }
    }
}

// MARK: - Basic Macro Expansion Context

/// A basic implementation of MacroExpansionContext for testing
public class BasicMacroExpansionContext: MacroExpansionContext {
    private var diagnostics: [Diagnostic] = []
    
    public init() {}
    
    public func makeUniqueName(_ name: String) -> TokenSyntax {
        return TokenSyntax.identifier("\(name)_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))")
    }
    
    public func diagnose(_ diagnostic: Diagnostic) {
        diagnostics.append(diagnostic)
    }
    
    public func location(
        of node: some SyntaxProtocol,
        at position: PositionInSyntaxNode,
        filePathMode: SourceLocationFilePathMode
    ) -> AbstractSourceLocation? {
        nil
    }
    
    public var location: AbstractSourceLocation? {
        nil
    }
    
    public var moduleName: String {
        "TestModule"
    }
    
    public func getDiagnostics() -> [Diagnostic] {
        diagnostics
    }
}