import XCTest
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation
@testable import AxiomMacros

/// Tests for the macro infrastructure utilities
final class MacroInfrastructureTests: XCTestCase {
    
    // MARK: - SyntaxUtilities Tests
    
    func testExtractNameFromDeclarations() {
        // Test struct name extraction
        let structDecl = StructDeclSyntax(
            name: .identifier("TestStruct"),
            memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
        )
        XCTAssertEqual(SyntaxUtilities.extractName(from: structDecl), "TestStruct")
        
        // Test class name extraction
        let classDecl = ClassDeclSyntax(
            name: .identifier("TestClass"),
            memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
        )
        XCTAssertEqual(SyntaxUtilities.extractName(from: classDecl), "TestClass")
        
        // Test actor name extraction
        let actorDecl = ActorDeclSyntax(
            name: .identifier("TestActor"),
            memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
        )
        XCTAssertEqual(SyntaxUtilities.extractName(from: actorDecl), "TestActor")
        
        // Test enum name extraction
        let enumDecl = EnumDeclSyntax(
            name: .identifier("TestEnum"),
            memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
        )
        XCTAssertEqual(SyntaxUtilities.extractName(from: enumDecl), "TestEnum")
        
        // Test function name extraction
        let funcDecl = FunctionDeclSyntax(
            name: .identifier("testFunction"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax([])
                )
            )
        )
        XCTAssertEqual(SyntaxUtilities.extractName(from: funcDecl), "testFunction")
    }
    
    func testConformsToProtocol() {
        // Test struct with protocol conformance
        let structDecl = StructDeclSyntax(
            name: .identifier("TestStruct"),
            inheritanceClause: InheritanceClauseSyntax(
                inheritedTypes: InheritedTypeListSyntax([
                    InheritedTypeSyntax(
                        type: IdentifierTypeSyntax(name: .identifier("AxiomContext"))
                    )
                ])
            ),
            memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
        )
        
        XCTAssertTrue(SyntaxUtilities.conformsToProtocol(structDecl, protocolName: "AxiomContext"))
        XCTAssertFalse(SyntaxUtilities.conformsToProtocol(structDecl, protocolName: "AxiomClient"))
        
        // Test struct without protocol conformance
        let simpleStruct = StructDeclSyntax(
            name: .identifier("SimpleStruct"),
            memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
        )
        XCTAssertFalse(SyntaxUtilities.conformsToProtocol(simpleStruct, protocolName: "AxiomContext"))
    }
    
    func testFindPropertiesWithAttribute() {
        // Create test members with various attributes
        let members = MemberBlockItemListSyntax([
            MemberBlockItemSyntax(
                decl: VariableDeclSyntax(
                    attributes: AttributeListSyntax([
                        .attribute(AttributeSyntax(
                            attributeName: IdentifierTypeSyntax(name: .identifier("Client"))
                        ))
                    ]),
                    bindingSpecifier: .keyword(.var),
                    bindings: PatternBindingListSyntax([
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: .identifier("userClient")),
                            typeAnnotation: TypeAnnotationSyntax(
                                type: IdentifierTypeSyntax(name: .identifier("UserClient"))
                            )
                        )
                    ])
                )
            ),
            MemberBlockItemSyntax(
                decl: VariableDeclSyntax(
                    bindingSpecifier: .keyword(.var),
                    bindings: PatternBindingListSyntax([
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: .identifier("normalProperty")),
                            typeAnnotation: TypeAnnotationSyntax(
                                type: IdentifierTypeSyntax(name: .identifier("String"))
                            )
                        )
                    ])
                )
            ),
            MemberBlockItemSyntax(
                decl: VariableDeclSyntax(
                    attributes: AttributeListSyntax([
                        .attribute(AttributeSyntax(
                            attributeName: IdentifierTypeSyntax(name: .identifier("Client"))
                        ))
                    ]),
                    bindingSpecifier: .keyword(.var),
                    bindings: PatternBindingListSyntax([
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: .identifier("orderClient")),
                            typeAnnotation: TypeAnnotationSyntax(
                                type: IdentifierTypeSyntax(name: .identifier("OrderClient"))
                            )
                        )
                    ])
                )
            )
        ])
        
        let clientProperties = SyntaxUtilities.findProperties(withAttribute: "Client", in: members)
        XCTAssertEqual(clientProperties.count, 2)
        
        let propertyNames = clientProperties.compactMap { varDecl in
            varDecl.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        }
        XCTAssertEqual(Set(propertyNames), ["userClient", "orderClient"])
    }
    
    // MARK: - CodeGenerationUtilities Tests
    
    func testCreateStoredProperty() {
        let property = CodeGenerationUtilities.createStoredProperty(
            name: "testProperty",
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("String"))),
            isPrivate: true,
            isLet: true
        )
        
        let expectedCode = "private let testProperty: String"
        XCTAssertEqual(property.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), expectedCode)
    }
    
    func testCreateComputedProperty() {
        let getter = CodeBlockItemListSyntax([
            CodeBlockItemSyntax(
                item: .expr(ExprSyntax(
                    DeclReferenceExprSyntax(baseName: .identifier("_value"))
                ))
            )
        ])
        
        let property = CodeGenerationUtilities.createComputedProperty(
            name: "value",
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("Int"))),
            isPublic: true,
            getter: getter
        )
        
        XCTAssertTrue(property.description.contains("publicvarvalue:Int"), "Expected 'publicvarvalue:Int' in: \(property.description)")
        XCTAssertTrue(property.description.contains("_value"), "Expected '_value' in: \(property.description)")
    }
    
    func testCreateInitializer() {
        let parameters = [
            CodeGenerationUtilities.createParameter(
                name: "value",
                type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("String")))
            ),
            CodeGenerationUtilities.createParameter(
                label: "with",
                name: "count",
                type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("Int")))
            )
        ]
        
        let body = CodeBlockItemListSyntax([
            CodeBlockItemSyntax(
                item: .expr(ExprSyntax(
                    SequenceExprSyntax(
                        elements: ExprListSyntax([
                            ExprSyntax(MemberAccessExprSyntax(
                                base: ExprSyntax(DeclReferenceExprSyntax(baseName: .keyword(.self))),
                                period: .periodToken(),
                                declName: DeclReferenceExprSyntax(baseName: .identifier("value"))
                            )),
                            ExprSyntax(AssignmentExprSyntax()),
                            ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("value")))
                        ])
                    )
                ))
            )
        ])
        
        let initializer = CodeGenerationUtilities.createInitializer(
            parameters: parameters,
            isPublic: true,
            body: body
        )
        
        XCTAssertTrue(initializer.description.contains("public init"))
        XCTAssertTrue(initializer.description.contains("value: String"))
        XCTAssertTrue(initializer.description.contains("with count: Int"))
    }
    
    func testCreateFunctionCall() {
        let functionCall = CodeGenerationUtilities.createFunctionCall(
            function: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("performAction"))),
            arguments: [
                (label: "with", expression: ExprSyntax(StringLiteralExprSyntax(content: "test"))),
                (label: nil, expression: ExprSyntax(IntegerLiteralExprSyntax(literal: .integerLiteral("42"))))
            ]
        )
        
        let description = functionCall.description
        XCTAssertTrue(description.contains("performAction"), "Expected 'performAction' in: \(description)")
        XCTAssertTrue(description.contains("with"), "Expected 'with' in: \(description)")
        XCTAssertTrue(description.contains("42"), "Expected '42' in: \(description)")
    }
    
    func testCreateAwaitExpression() {
        let baseExpr = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("asyncFunction")))
        let awaitExpr = CodeGenerationUtilities.createAwaitExpression(baseExpr)
        
        XCTAssertTrue(awaitExpr.description.contains("await"))
        XCTAssertTrue(awaitExpr.description.contains("asyncFunction"))
    }
    
    func testCreateMemberAccess() {
        let base = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("object")))
        let memberAccess = CodeGenerationUtilities.createMemberAccess(
            base: base,
            member: "property"
        )
        
        XCTAssertEqual(memberAccess.description.trimmingCharacters(in: .whitespacesAndNewlines), "object.property")
    }
    
    // MARK: - ValidationUtilities Tests
    
    func testValidateSingleApplication() {
        let attributes = AttributeListSyntax([
            .attribute(AttributeSyntax(
                attributeName: IdentifierTypeSyntax(name: .identifier("Client"))
            )),
            .attribute(AttributeSyntax(
                attributeName: IdentifierTypeSyntax(name: .identifier("Published"))
            ))
        ])
        
        XCTAssertTrue(ValidationUtilities.validateSingleApplication(of: "Client", in: attributes))
        XCTAssertTrue(ValidationUtilities.validateSingleApplication(of: "Published", in: attributes))
        XCTAssertTrue(ValidationUtilities.validateSingleApplication(of: "NotPresent", in: attributes))
        
        // Test with duplicate
        let duplicateAttributes = AttributeListSyntax([
            .attribute(AttributeSyntax(
                attributeName: IdentifierTypeSyntax(name: .identifier("Client"))
            )),
            .attribute(AttributeSyntax(
                attributeName: IdentifierTypeSyntax(name: .identifier("Client"))
            ))
        ])
        
        XCTAssertFalse(ValidationUtilities.validateSingleApplication(of: "Client", in: duplicateAttributes))
    }
    
    func testValidateRequiredArguments() {
        let arguments = LabeledExprListSyntax([
            LabeledExprSyntax(
                label: .identifier("name"),
                expression: ExprSyntax(StringLiteralExprSyntax(content: "test"))
            ),
            LabeledExprSyntax(
                label: .identifier("value"),
                expression: ExprSyntax(IntegerLiteralExprSyntax(literal: .integerLiteral("42")))
            )
        ])
        
        let required: Set<String> = ["name", "value", "missing"]
        let missing = ValidationUtilities.validateRequiredArguments(arguments, required: required)
        
        XCTAssertEqual(missing, ["missing"])
    }
    
    func testValidateNoConflicts() {
        let attributes = AttributeListSyntax([
            .attribute(AttributeSyntax(
                attributeName: IdentifierTypeSyntax(name: .identifier("Client"))
            )),
            .attribute(AttributeSyntax(
                attributeName: IdentifierTypeSyntax(name: .identifier("Published"))
            ))
        ])
        
        let conflicting: Set<String> = ["Published", "ObservedObject"]
        let conflicts = ValidationUtilities.validateNoConflicts(with: conflicting, in: attributes)
        
        XCTAssertEqual(conflicts, ["Published"])
    }
    
    // MARK: - TypeCheckingUtilities Tests
    
    func testIsOptionalType() {
        let optionalType1 = OptionalTypeSyntax(
            wrappedType: IdentifierTypeSyntax(name: .identifier("String"))
        )
        XCTAssertTrue(TypeCheckingUtilities.isOptionalType(TypeSyntax(optionalType1)))
        
        let optionalType2 = IdentifierTypeSyntax(
            name: .identifier("Optional"),
            genericArgumentClause: GenericArgumentClauseSyntax(
                arguments: GenericArgumentListSyntax([
                    GenericArgumentSyntax(argument: IdentifierTypeSyntax(name: .identifier("Int")))
                ])
            )
        )
        XCTAssertTrue(TypeCheckingUtilities.isOptionalType(TypeSyntax(optionalType2)))
        
        let nonOptionalType = IdentifierTypeSyntax(name: .identifier("String"))
        XCTAssertFalse(TypeCheckingUtilities.isOptionalType(TypeSyntax(nonOptionalType)))
    }
    
    func testUnwrapOptionalType() {
        let optionalType = OptionalTypeSyntax(
            wrappedType: IdentifierTypeSyntax(name: .identifier("String"))
        )
        
        let unwrapped = TypeCheckingUtilities.unwrapOptionalType(TypeSyntax(optionalType))
        XCTAssertNotNil(unwrapped)
        XCTAssertEqual(unwrapped?.description.trimmingCharacters(in: .whitespacesAndNewlines), "String")
    }
    
    func testExtractGenericParameters() {
        let genericType = IdentifierTypeSyntax(
            name: .identifier("Array"),
            genericArgumentClause: GenericArgumentClauseSyntax(
                arguments: GenericArgumentListSyntax([
                    GenericArgumentSyntax(argument: IdentifierTypeSyntax(name: .identifier("String")))
                ])
            )
        )
        
        let parameters = TypeCheckingUtilities.extractGenericParameters(from: TypeSyntax(genericType))
        XCTAssertEqual(parameters, ["String"])
    }
    
    // MARK: - BasicMacroExpansionContext Tests
    
    func testBasicMacroExpansionContext() {
        let context = BasicMacroExpansionContext()
        
        // Test unique name generation
        let uniqueName = context.makeUniqueName("test")
        XCTAssertTrue(uniqueName.text.hasPrefix("test_"))
        XCTAssertTrue(uniqueName.text.count > 5) // Should have UUID suffix
        
        // Test module name
        XCTAssertEqual(context.moduleName, "TestModule")
        
        // Test diagnostics
        let diagnostic = Diagnostic(
            node: DeclReferenceExprSyntax(baseName: .identifier("test")),
            message: AxiomMacroDiagnostic.DiagnosticType.invalidArguments
        )
        
        context.diagnose(diagnostic)
        let diagnostics = context.getDiagnostics()
        XCTAssertEqual(diagnostics.count, 1)
        
        // Check that the message content matches what we expect
        // Based on compiler error, diagnostics.first?.message is a String
        XCTAssertEqual(diagnostics.first?.message, "Invalid arguments provided to the macro")
    }
}