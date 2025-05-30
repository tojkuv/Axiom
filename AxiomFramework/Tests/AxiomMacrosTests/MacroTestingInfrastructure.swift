import XCTest
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import SwiftDiagnostics
import Foundation
@testable import AxiomMacros

// MARK: - Macro Testing Infrastructure

/// Base test case for Axiom macro tests
open class AxiomMacroTestCase: XCTestCase {
    
    /// The macros being tested
    open var testMacros: [String: Macro.Type] {
        [:]
    }
    
    /// Tests macro expansion with the given input and expected output
    func assertMacroExpansion(
        _ input: String,
        expandedSource expected: String,
        diagnostics: [DiagnosticSpec] = [],
        macros: [String: Macro.Type]? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertMacroExpansion(
            input,
            expandedSource: expected,
            diagnostics: diagnostics,
            macros: macros ?? testMacros,
            file: file,
            line: line
        )
    }
    
    /// Tests that a macro produces specific diagnostics
    func assertMacroDiagnostics(
        _ input: String,
        diagnostics expectedDiagnostics: [DiagnosticSpec],
        macros: [String: Macro.Type]? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertMacroExpansion(
            input,
            expandedSource: input, // No expansion expected
            diagnostics: expectedDiagnostics,
            macros: macros ?? testMacros,
            file: file,
            line: line
        )
    }
    
    /// Creates a diagnostic spec for testing
    func diagnostic(
        message: String,
        line: Int,
        column: Int,
        severity: DiagnosticSeverity = .error,
        fixIts: [FixItSpec] = []
    ) -> DiagnosticSpec {
        DiagnosticSpec(
            message: message,
            line: line,
            column: column,
            severity: severity,
            fixIts: fixIts
        )
    }
    
    /// Creates a fix-it spec for testing
    func fixIt(message: String) -> FixItSpec {
        FixItSpec(message: message)
    }
}

// MARK: - Test Helpers

/// Helper functions for macro testing
enum MacroTestHelpers {
    
    /// Creates a test struct declaration
    static func createTestStruct(
        name: String = "TestStruct",
        conformances: [String] = [],
        members: String = ""
    ) -> String {
        let conformanceClause = conformances.isEmpty ? "" : ": \(conformances.joined(separator: ", "))"
        return """
        struct \(name)\(conformanceClause) {
            \(members)
        }
        """
    }
    
    /// Creates a test class declaration
    static func createTestClass(
        name: String = "TestClass",
        conformances: [String] = [],
        members: String = ""
    ) -> String {
        let conformanceClause = conformances.isEmpty ? "" : ": \(conformances.joined(separator: ", "))"
        return """
        class \(name)\(conformanceClause) {
            \(members)
        }
        """
    }
    
    /// Creates a test actor declaration
    static func createTestActor(
        name: String = "TestActor",
        conformances: [String] = [],
        members: String = ""
    ) -> String {
        let conformanceClause = conformances.isEmpty ? "" : ": \(conformances.joined(separator: ", "))"
        return """
        actor \(name)\(conformanceClause) {
            \(members)
        }
        """
    }
    
    /// Creates a test property declaration
    static func createTestProperty(
        name: String,
        type: String,
        isVar: Bool = true,
        initialValue: String? = nil,
        attributes: [String] = []
    ) -> String {
        let attributesStr = attributes.isEmpty ? "" : attributes.joined(separator: " ") + " "
        let binding = isVar ? "var" : "let"
        let initializer = initialValue.map { " = \($0)" } ?? ""
        return "\(attributesStr)\(binding) \(name): \(type)\(initializer)"
    }
    
    /// Creates a test function declaration
    static func createTestFunction(
        name: String,
        parameters: [(label: String?, name: String, type: String)] = [],
        returnType: String? = nil,
        isAsync: Bool = false,
        throws: Bool = false,
        body: String = ""
    ) -> String {
        let paramsStr = parameters.map { param in
            let label = param.label.map { "\($0) " } ?? ""
            return "\(label)\(param.name): \(param.type)"
        }.joined(separator: ", ")
        
        let asyncStr = isAsync ? " async" : ""
        let throwsStr = `throws` ? " throws" : ""
        let returnStr = returnType.map { " -> \($0)" } ?? ""
        
        return """
        func \(name)(\(paramsStr))\(asyncStr)\(throwsStr)\(returnStr) {
            \(body)
        }
        """
    }
    
    /// Normalizes whitespace in code for comparison
    static func normalizeCode(_ code: String) -> String {
        code
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
    
    /// Compares two code strings ignoring whitespace differences
    static func assertCodeEqual(
        _ actual: String,
        _ expected: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let normalizedActual = normalizeCode(actual)
        let normalizedExpected = normalizeCode(expected)
        
        XCTAssertEqual(
            normalizedActual,
            normalizedExpected,
            """
            Code does not match.
            
            Actual:
            \(normalizedActual)
            
            Expected:
            \(normalizedExpected)
            """,
            file: file,
            line: line
        )
    }
}

// MARK: - Mock Types for Testing

/// Mock types that simulate Axiom framework types for testing
enum MockTypes {
    static let axiomContext = """
    protocol AxiomContext: ObservableObject {
        associatedtype View: AxiomView where View.Context == Self
        func onAppear() async
        func onDisappear() async
    }
    """
    
    static let axiomClient = """
    protocol AxiomClient: Actor {
        associatedtype Domain: DomainModel
        func addObserver(_ observer: any AxiomContext) async
        func removeObserver(_ observer: any AxiomContext) async
    }
    """
    
    static let axiomView = """
    protocol AxiomView: View {
        associatedtype Context: AxiomContext where Context.View == Self
        var context: Context { get }
        init(context: Context)
    }
    """
    
    static let domainModel = """
    protocol DomainModel: Sendable, Identifiable, Equatable {
        associatedtype ID: Hashable & Sendable
        var id: ID { get }
    }
    """
    
    static let capability = """
    enum Capability: String, CaseIterable {
        case network
        case storage
        case keychain
        case analytics
        case notifications
        case location
        case camera
        case microphone
    }
    """
    
    static let capabilityManager = """
    actor CapabilityManager {
        func validate(_ capability: Capability) throws
        func validateCached(_ capability: Capability) throws
        func hasCapability(_ capability: Capability) async throws -> Bool
    }
    """
    
    static func allMockTypes() -> String {
        """
        \(axiomContext)
        
        \(axiomClient)
        
        \(axiomView)
        
        \(domainModel)
        
        \(capability)
        
        \(capabilityManager)
        """
    }
}

// MARK: - Test Syntax Builders

/// Builders for creating test syntax nodes
enum TestSyntaxBuilders {
    
    /// Creates a test source file
    static func sourceFile(@CodeBlockItemListBuilder items: () -> CodeBlockItemListSyntax) -> SourceFileSyntax {
        SourceFileSyntax(
            statements: items()
        )
    }
    
    /// Creates a test struct declaration
    static func structDecl(
        name: String,
        inheritedTypes: [String] = [],
        @MemberBlockItemListBuilder members: () -> MemberBlockItemListSyntax = { MemberBlockItemListSyntax([]) }
    ) -> StructDeclSyntax {
        StructDeclSyntax(
            name: .identifier(name),
            inheritanceClause: inheritedTypes.isEmpty ? nil : InheritanceClauseSyntax(
                inheritedTypes: InheritedTypeListSyntax(
                    inheritedTypes.map { typeName in
                        InheritedTypeSyntax(
                            type: IdentifierTypeSyntax(name: .identifier(typeName))
                        )
                    }
                )
            ),
            memberBlock: MemberBlockSyntax(
                members: members()
            )
        )
    }
    
    /// Creates a test variable declaration
    static func varDecl(
        name: String,
        type: String,
        isLet: Bool = false,
        initialValue: String? = nil,
        attributes: [String] = []
    ) -> VariableDeclSyntax {
        VariableDeclSyntax(
            attributes: AttributeListSyntax(
                attributes.map { attrName in
                    .attribute(
                        AttributeSyntax(
                            attributeName: IdentifierTypeSyntax(name: .identifier(attrName))
                        )
                    )
                }
            ),
            bindingSpecifier: .keyword(isLet ? .let : .var),
            bindings: PatternBindingListSyntax([
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(identifier: .identifier(name)),
                    typeAnnotation: TypeAnnotationSyntax(
                        type: IdentifierTypeSyntax(name: .identifier(type))
                    ),
                    initializer: initialValue.map { value in
                        InitializerClauseSyntax(
                            value: StringLiteralExprSyntax(
                                openingQuote: .stringQuoteToken(),
                                segments: [.stringSegment(StringSegmentSyntax(content: .stringSegment(value)))],
                                closingQuote: .stringQuoteToken()
                            )
                        )
                    }
                )
            ])
        )
    }
}

// MARK: - Macro Expansion Test Extensions

extension XCTestCase {
    /// Tests multiple macro expansions in sequence
    func assertMultipleMacroExpansions(
        _ testCases: [(input: String, expected: String, diagnostics: [DiagnosticSpec])],
        macros: [String: Macro.Type],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for (_, testCase) in testCases.enumerated() {
            assertMacroExpansion(
                testCase.input,
                expandedSource: testCase.expected,
                diagnostics: testCase.diagnostics,
                macros: macros,
                file: file,
                line: line
            )
        }
    }
    
    /// Tests that a macro preserves the original source (no expansion)
    func assertNoMacroExpansion(
        _ input: String,
        macros: [String: Macro.Type],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertMacroExpansion(
            input,
            expandedSource: input,
            diagnostics: [],
            macros: macros,
            file: file,
            line: line
        )
    }
}

// MARK: - Diagnostic Testing Extensions

extension DiagnosticSpec {
    /// Creates an error diagnostic spec
    static func error(
        _ message: String,
        line: Int,
        column: Int,
        fixIts: [FixItSpec] = []
    ) -> DiagnosticSpec {
        DiagnosticSpec(
            message: message,
            line: line,
            column: column,
            severity: .error,
            fixIts: fixIts
        )
    }
    
    /// Creates a warning diagnostic spec
    static func warning(
        _ message: String,
        line: Int,
        column: Int,
        fixIts: [FixItSpec] = []
    ) -> DiagnosticSpec {
        DiagnosticSpec(
            message: message,
            line: line,
            column: column,
            severity: .warning,
            fixIts: fixIts
        )
    }
    
    /// Creates a note diagnostic spec
    static func note(
        _ message: String,
        line: Int,
        column: Int
    ) -> DiagnosticSpec {
        DiagnosticSpec(
            message: message,
            line: line,
            column: column,
            severity: .note,
            fixIts: []
        )
    }
}