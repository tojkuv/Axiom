import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Macro that generates mock implementations for protocols
public struct AutoMockableMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Ensure we're attached to a protocol
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else {
            throw AutoMockableError.notAProtocol
        }
        
        let protocolName = protocolDecl.name.text
        let mockClassName = "Mock\(protocolName)"
        
        // Extract protocol requirements
        let requirements = extractRequirements(from: protocolDecl)
        
        // Generate mock class
        let mockClass = generateMockClass(
            name: mockClassName,
            protocolName: protocolName,
            requirements: requirements
        )
        
        return [DeclSyntax(mockClass)]
    }
    
    // MARK: - Requirement Extraction
    
    private static func extractRequirements(from protocol: ProtocolDeclSyntax) -> [ProtocolRequirement] {
        var requirements: [ProtocolRequirement] = []
        
        for member in `protocol`.memberBlock.members {
            if let functionDecl = member.decl.as(FunctionDeclSyntax.self) {
                requirements.append(.function(extractFunction(functionDecl)))
            } else if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                requirements.append(.property(extractProperty(variableDecl)))
            }
        }
        
        return requirements
    }
    
    private static func extractFunction(_ function: FunctionDeclSyntax) -> FunctionRequirement {
        let name = function.name.text
        let isAsync = function.signature.effectSpecifiers?.asyncSpecifier != nil
        let isThrowing = function.signature.effectSpecifiers?.throwsSpecifier != nil
        let parameters = function.signature.parameterClause.parameters.map { param in
            ParameterInfo(
                label: param.firstName.text,
                name: param.secondName?.text ?? param.firstName.text,
                type: param.type.description.trimmingCharacters(in: .whitespaces)
            )
        }
        let returnType = function.signature.returnClause?.type.description.trimmingCharacters(in: .whitespaces)
        
        return FunctionRequirement(
            name: name,
            parameters: parameters,
            returnType: returnType,
            isAsync: isAsync,
            isThrowing: isThrowing
        )
    }
    
    private static func extractProperty(_ variable: VariableDeclSyntax) -> PropertyRequirement {
        guard let binding = variable.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              let type = binding.typeAnnotation?.type else {
            return PropertyRequirement(name: "unknown", type: "Any", isGet: true, isSet: false, isAsync: false)
        }
        
        let name = pattern.identifier.text
        let typeName = type.description.trimmingCharacters(in: .whitespaces)
        
        // Check for get/set
        var isGet = true
        var isSet = false
        var isAsync = false
        
        if let accessors = binding.accessorBlock {
            switch accessors.accessors {
            case .getter:
                isGet = true
            case .accessors(let list):
                for accessor in list {
                    switch accessor.accessorSpecifier.text {
                    case "get":
                        isGet = true
                        isAsync = accessor.effectSpecifiers?.asyncSpecifier != nil
                    case "set":
                        isSet = true
                    default:
                        break
                    }
                }
            @unknown default:
                break
            }
        }
        
        return PropertyRequirement(
            name: name,
            type: typeName,
            isGet: isGet,
            isSet: isSet,
            isAsync: isAsync
        )
    }
    
    // MARK: - Mock Generation
    
    private static func generateMockClass(
        name: String,
        protocolName: String,
        requirements: [ProtocolRequirement]
    ) -> ClassDeclSyntax {
        let members = requirements.flatMap { requirement -> [MemberBlockItemSyntax] in
            switch requirement {
            case .function(let function):
                return generateMockFunction(function)
            case .property(let property):
                return generateMockProperty(property)
            }
        }
        
        return ClassDeclSyntax(
            leadingTrivia: .newlines(2),
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: .identifier(name),
            inheritanceClause: InheritanceClauseSyntax(
                inheritedTypes: InheritedTypeListSyntax([
                    InheritedTypeSyntax(type: TypeSyntax(stringLiteral: protocolName))
                ])
            ),
            memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax(members))
        )
    }
    
    private static func generateMockFunction(_ function: FunctionRequirement) -> [MemberBlockItemSyntax] {
        var members: [MemberBlockItemSyntax] = []
        
        // Generate mock property for tracking
        let mockPropertyName = "\(function.name)Mock"
        let mockType = generateMockMethodType(for: function)
        
        let mockProperty = VariableDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            bindingSpecifier: .keyword(.let),
            bindings: PatternBindingListSyntax([
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(identifier: .identifier(mockPropertyName)),
                    initializer: InitializerClauseSyntax(
                        value: FunctionCallExprSyntax(
                            calledExpression: ExprSyntax(stringLiteral: mockType),
                            leftParen: .leftParenToken(),
                            arguments: [],
                            rightParen: .rightParenToken()
                        )
                    )
                )
            ])
        )
        members.append(MemberBlockItemSyntax(decl: mockProperty))
        
        // Generate function implementation
        let functionImpl = generateFunctionImplementation(function, mockPropertyName: mockPropertyName)
        members.append(MemberBlockItemSyntax(decl: functionImpl))
        
        return members
    }
    
    private static func generateMockProperty(_ property: PropertyRequirement) -> [MemberBlockItemSyntax] {
        var members: [MemberBlockItemSyntax] = []
        
        // Generate mock property for tracking
        let mockPropertyName = "\(property.name)Mock"
        let mockType = "MockProperty<\(property.type)>"
        
        let mockProperty = VariableDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            bindingSpecifier: .keyword(.let),
            bindings: PatternBindingListSyntax([
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(identifier: .identifier(mockPropertyName)),
                    initializer: InitializerClauseSyntax(
                        value: FunctionCallExprSyntax(
                            calledExpression: ExprSyntax(stringLiteral: mockType),
                            leftParen: .leftParenToken(),
                            arguments: [],
                            rightParen: .rightParenToken()
                        )
                    )
                )
            ])
        )
        members.append(MemberBlockItemSyntax(decl: mockProperty))
        
        // Generate property implementation
        let propertyImpl = generatePropertyImplementation(property, mockPropertyName: mockPropertyName)
        members.append(MemberBlockItemSyntax(decl: propertyImpl))
        
        return members
    }
    
    private static func generateMockMethodType(for function: FunctionRequirement) -> String {
        let paramTypes = function.parameters.map { $0.type }.joined(separator: ", ")
        let paramType = function.parameters.isEmpty ? "Void" : 
            function.parameters.count == 1 ? function.parameters[0].type : "(\(paramTypes))"
        let returnType = function.returnType ?? "Void"
        
        return "MockMethod<\(paramType), \(returnType)>"
    }
    
    private static func generateFunctionImplementation(
        _ function: FunctionRequirement,
        mockPropertyName: String
    ) -> FunctionDeclSyntax {
        // Build parameter list
        let parameters = FunctionParameterListSyntax(
            function.parameters.map { param in
                FunctionParameterSyntax(
                    firstName: .identifier(param.label ?? param.name),
                    secondName: param.label != nil ? .identifier(param.name) : nil,
                    colon: .colonToken(),
                    type: TypeSyntax(stringLiteral: param.type)
                )
            }
        )
        
        // Build function signature
        var effectSpecifiers: FunctionEffectSpecifiersSyntax?
        if function.isAsync || function.isThrowing {
            effectSpecifiers = FunctionEffectSpecifiersSyntax(
                asyncSpecifier: function.isAsync ? .keyword(.async) : nil,
                throwsSpecifier: function.isThrowing ? .keyword(.throws) : nil
            )
        }
        
        let returnClause = function.returnType.map { returnType in
            ReturnClauseSyntax(
                type: TypeSyntax(stringLiteral: returnType)
            )
        }
        
        // Build function body
        let callArguments = function.parameters.isEmpty ? "" :
            function.parameters.count == 1 ? "with: \(function.parameters[0].name)" :
            "with: (\(function.parameters.map { $0.name }.joined(separator: ", ")))"
        
        let awaitKeyword = function.isAsync ? "await " : ""
        let tryKeyword = function.isThrowing ? "try " : ""
        let returnKeyword = function.returnType != nil ? "return " : ""
        
        let bodyStatement = "\(returnKeyword)\(tryKeyword)\(awaitKeyword)\(mockPropertyName).call(\(callArguments))"
        
        return FunctionDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            name: .identifier(function.name),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: parameters
                ),
                effectSpecifiers: effectSpecifiers,
                returnClause: returnClause
            ),
            body: CodeBlockSyntax(
                statements: CodeBlockItemListSyntax([
                    CodeBlockItemSyntax(
                        item: .expr(ExprSyntax(stringLiteral: bodyStatement))
                    )
                ])
            )
        )
    }
    
    private static func generatePropertyImplementation(
        _ property: PropertyRequirement,
        mockPropertyName: String
    ) -> VariableDeclSyntax {
        var accessors: [AccessorDeclSyntax] = []
        
        // Generate getter
        if property.isGet {
            let getterBody = property.isAsync ? 
                "await \(mockPropertyName).get()" :
                "\(mockPropertyName).get()"
            
            accessors.append(AccessorDeclSyntax(
                accessorSpecifier: .keyword(.get),
                effectSpecifiers: property.isAsync ? AccessorEffectSpecifiersSyntax(asyncSpecifier: .keyword(.async)) : nil,
                body: CodeBlockSyntax(
                    statements: CodeBlockItemListSyntax([
                        CodeBlockItemSyntax(
                            item: .expr(ExprSyntax(stringLiteral: getterBody))
                        )
                    ])
                )
            ))
        }
        
        // Generate setter
        if property.isSet {
            accessors.append(AccessorDeclSyntax(
                accessorSpecifier: .keyword(.set),
                body: CodeBlockSyntax(
                    statements: CodeBlockItemListSyntax([
                        CodeBlockItemSyntax(
                            item: .expr(ExprSyntax(stringLiteral: "\(mockPropertyName).set(newValue)"))
                        )
                    ])
                )
            ))
        }
        
        return VariableDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .keyword(.public))],
            bindingSpecifier: .keyword(.var),
            bindings: PatternBindingListSyntax([
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(identifier: .identifier(property.name)),
                    typeAnnotation: TypeAnnotationSyntax(
                        type: TypeSyntax(stringLiteral: property.type)
                    ),
                    accessorBlock: AccessorBlockSyntax(
                        accessors: .accessors(AccessorDeclListSyntax(accessors))
                    )
                )
            ])
        )
    }
}

// MARK: - Supporting Types

enum ProtocolRequirement {
    case function(FunctionRequirement)
    case property(PropertyRequirement)
}

struct FunctionRequirement {
    let name: String
    let parameters: [ParameterInfo]
    let returnType: String?
    let isAsync: Bool
    let isThrowing: Bool
}

struct PropertyRequirement {
    let name: String
    let type: String
    let isGet: Bool
    let isSet: Bool
    let isAsync: Bool
}

struct ParameterInfo {
    let label: String?
    let name: String
    let type: String
}

// MARK: - Errors

enum AutoMockableError: Error, CustomStringConvertible {
    case notAProtocol
    
    var description: String {
        switch self {
        case .notAProtocol:
            return "@AutoMockable can only be applied to protocols"
        }
    }
}