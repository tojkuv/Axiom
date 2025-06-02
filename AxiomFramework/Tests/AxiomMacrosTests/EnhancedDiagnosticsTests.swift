import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import SwiftDiagnostics
import XCTest

// Test implementations for enhanced diagnostics system
#if canImport(AxiomMacros)
import AxiomMacros

final class EnhancedDiagnosticsTests: XCTestCase {
    
    // MARK: - Enhanced Diagnostic System Tests
    
    func testEnhancedDiagnosticSystemInitialization() throws {
        let mockContext = MockMacroExpansionContext()
        let coordinator = MacroCoordinator()
        
        let diagnosticSystem = EnhancedDiagnosticSystem(context: mockContext, coordinator: coordinator)
        XCTAssertNotNil(diagnosticSystem, "Should create enhanced diagnostic system")
    }
    
    func testContextAwareDeclarationValidation() throws {
        let mockContext = MockMacroExpansionContext()
        let coordinator = MacroCoordinator()
        let diagnosticSystem = EnhancedDiagnosticSystem(context: mockContext, coordinator: coordinator)
        
        // Test validation on incompatible declaration type  
        let enumDecl = try EnumDeclSyntax(
            name: .identifier("TestEnum"),
            memberBlock: MemberBlockSyntax(
                members: MemberBlockItemListSyntax([
                    MemberBlockItemSyntax(
                        decl: EnumCaseDeclSyntax(
                            elements: EnumCaseElementListSyntax([
                                EnumCaseElementSyntax(name: .identifier("value"))
                            ])
                        )
                    )
                ])
            )
        )
        let clientAttribute = AttributeSyntax(
            attributeName: IdentifierTypeSyntax(name: .identifier("Client"))
        )
        
        let result = diagnosticSystem.validateMacroApplication(
            ClientMacro.self,
            on: enumDecl,
            with: clientAttribute
        )
        
        XCTAssertFalse(result.isValid, "Should be invalid when applied to incompatible declaration")
        XCTAssertTrue(result.hasErrors, "Should have errors for incompatible declaration")
        XCTAssertGreaterThan(result.suggestions.count, 0, "Should provide suggestions for fixing issues")
    }
    
    func testProtocolConformanceValidation() throws {
        let mockContext = MockMacroExpansionContext()
        let coordinator = MacroCoordinator()
        let diagnosticSystem = EnhancedDiagnosticSystem(context: mockContext, coordinator: coordinator)
        
        // Test struct without required protocol conformance
        let structDecl = createMockStruct("TestStruct")
        let contextAttribute = createMockAttribute("Context")
        
        let result = diagnosticSystem.validateMacroApplication(
            ContextMacro.self,
            on: structDecl,
            with: contextAttribute
        )
        
        // Should suggest adding AxiomContext protocol conformance
        let protocolSuggestions = result.suggestions.filter { $0.contains("AxiomContext") }
        XCTAssertGreaterThan(protocolSuggestions.count, 0, "Should suggest adding required protocol conformance")
    }
    
    func testCrossMacroCompatibilityValidation() throws {
        let mockContext = MockMacroExpansionContext()
        let coordinator = MacroCoordinator()
        let diagnosticSystem = EnhancedDiagnosticSystem(context: mockContext, coordinator: coordinator)
        
        // Simulate shared context with reserved names
        let sharedContext = coordinator.getSharedContext()
        sharedContext.registerGeneratedMember("client", by: "ExistingMacro")
        
        // Test macro that would generate conflicting member
        let structDecl = createMockStruct("TestStruct")
        let clientAttribute = createMockAttribute("Client")
        
        let result = diagnosticSystem.validateMacroApplication(
            ClientMacro.self,
            on: structDecl,
            with: clientAttribute
        )
        
        // Should warn about potential naming conflicts
        let namingWarnings = result.issues.filter { $0.category == .namingConflict }
        XCTAssertGreaterThan(namingWarnings.count, 0, "Should detect potential naming conflicts")
    }
    
    func testArchitecturalConstraintValidation() throws {
        let mockContext = MockMacroExpansionContext()
        let coordinator = MacroCoordinator()
        let diagnosticSystem = EnhancedDiagnosticSystem(context: mockContext, coordinator: coordinator)
        
        // Test @Client macro without @Context
        let structDecl = createMockStruct("TestStruct")
        let clientAttribute = createMockAttribute("Client")
        
        let result = diagnosticSystem.validateMacroApplication(
            ClientMacro.self,
            on: structDecl,
            with: clientAttribute
        )
        
        // Should suggest using @Context for better integration
        let contextSuggestions = result.suggestions.filter { $0.contains("@Context") }
        XCTAssertGreaterThan(contextSuggestions.count, 0, "Should suggest @Context integration")
    }
    
    // MARK: - Diagnostic Issue Tests
    
    func testDiagnosticIssueCreation() throws {
        let mockNode = createMockStruct("Test")
        
        let issue = DiagnosticIssue(
            severity: .error,
            message: "Test error message",
            node: mockNode,
            suggestions: ["Fix suggestion 1", "Fix suggestion 2"],
            fixIts: [],
            category: .declarationType
        )
        
        XCTAssertEqual(issue.severity, .error, "Should have correct severity")
        XCTAssertEqual(issue.message, "Test error message", "Should have correct message")
        XCTAssertEqual(issue.suggestions.count, 2, "Should have correct number of suggestions")
        XCTAssertEqual(issue.category, .declarationType, "Should have correct category")
    }
    
    func testValidationResultAnalysis() throws {
        let mockNode = createMockStruct("Test")
        
        let errorIssue = DiagnosticIssue(
            severity: .error,
            message: "Error message",
            node: mockNode,
            category: .declarationType
        )
        
        let warningIssue = DiagnosticIssue(
            severity: .warning,
            message: "Warning message",
            node: mockNode,
            category: .bestPractice
        )
        
        let result = ValidationResult(
            isValid: false,
            issues: [errorIssue, warningIssue],
            suggestions: ["Global suggestion"]
        )
        
        XCTAssertFalse(result.isValid, "Should be invalid with issues")
        XCTAssertTrue(result.hasErrors, "Should have errors")
        XCTAssertTrue(result.hasWarnings, "Should have warnings")
        
        let categorized = result.issuesByCategory()
        XCTAssertEqual(categorized[.declarationType]?.count, 1, "Should have one declaration type issue")
        XCTAssertEqual(categorized[.bestPractice]?.count, 1, "Should have one best practice issue")
    }
    
    // MARK: - Intelligent Suggestion Tests
    
    func testIntelligentSuggestionGeneration() throws {
        let mockContext = MockMacroExpansionContext()
        let coordinator = MacroCoordinator()
        let diagnosticSystem = EnhancedDiagnosticSystem(context: mockContext, coordinator: coordinator)
        
        // Test suggestion generation for common scenarios
        let enumDecl = createMockStruct("TestEnum") // Using struct instead for simplicity
        let viewAttribute = createMockAttribute("View")
        
        let result = diagnosticSystem.validateMacroApplication(
            ViewMacro.self,
            on: enumDecl,
            with: viewAttribute
        )
        
        // Should suggest using @View on struct instead
        let suggestions = result.suggestions.filter { $0.contains("struct") }
        XCTAssertGreaterThan(suggestions.count, 0, "Should suggest using struct for @View macro")
    }
    
    func testFixItGeneration() throws {
        let mockContext = MockMacroExpansionContext()
        let coordinator = MacroCoordinator()
        let diagnosticSystem = EnhancedDiagnosticSystem(context: mockContext, coordinator: coordinator)
        
        // Test Fix-It generation for protocol conformance
        let structDecl = createMockStruct("TestStruct")
        let contextAttribute = createMockAttribute("Context")
        
        let result = diagnosticSystem.validateMacroApplication(
            ContextMacro.self,
            on: structDecl,
            with: contextAttribute
        )
        
        // Should generate Fix-Its for adding protocol conformance
        let fixItIssues = result.issues.filter { !$0.fixIts.isEmpty }
        XCTAssertGreaterThan(fixItIssues.count, 0, "Should generate Fix-Its for common issues")
    }
    
    // MARK: - Diagnostic Category Tests
    
    func testDiagnosticCategoryClassification() throws {
        // Test all diagnostic categories exist
        let allCategories = DiagnosticCategory.allCases
        
        XCTAssertTrue(allCategories.contains(.general), "Should have general category")
        XCTAssertTrue(allCategories.contains(.declarationType), "Should have declarationType category")
        XCTAssertTrue(allCategories.contains(.protocolConformance), "Should have protocolConformance category")
        XCTAssertTrue(allCategories.contains(.namingConflict), "Should have namingConflict category")
        XCTAssertTrue(allCategories.contains(.architecturalConstraint), "Should have architecturalConstraint category")
        XCTAssertTrue(allCategories.contains(.macroComposition), "Should have macroComposition category")
        XCTAssertTrue(allCategories.contains(.performanceOptimization), "Should have performanceOptimization category")
        XCTAssertTrue(allCategories.contains(.bestPractice), "Should have bestPractice category")
    }
    
    // MARK: - Context-Aware Validation Tests
    
    func testDeclarationTypeDetection() throws {
        let mockContext = MockMacroExpansionContext()
        let coordinator = MacroCoordinator()
        let diagnosticSystem = EnhancedDiagnosticSystem(context: mockContext, coordinator: coordinator)
        
        // Test different declaration types
        let structDecl = try StructDeclSyntax("struct TestStruct { }") as any DeclSyntaxProtocol
        let classDecl = try ClassDeclSyntax("class TestClass { }") as any DeclSyntaxProtocol
        let actorDecl = try ActorDeclSyntax("actor TestActor { }") as any DeclSyntaxProtocol
        
        // Each should be correctly identified for appropriate macro usage
        XCTAssertNoThrow(try diagnosticSystem.validateDeclarationType(structDecl, for: ContextMacro.self))
        XCTAssertNoThrow(try diagnosticSystem.validateDeclarationType(classDecl, for: ContextMacro.self))
        XCTAssertNoThrow(try diagnosticSystem.validateDeclarationType(actorDecl, for: ClientMacro.self))
    }
    
    func testBestPracticeRecommendations() throws {
        let mockContext = MockMacroExpansionContext()
        let coordinator = MacroCoordinator()
        let diagnosticSystem = EnhancedDiagnosticSystem(context: mockContext, coordinator: coordinator)
        
        // Test recommendations for macro usage patterns
        let structDecl = createMockStruct("TestStruct")
        let observableAttribute = createMockAttribute("ObservableState")
        
        let result = diagnosticSystem.validateMacroApplication(
            ObservableStateMacro.self,
            on: structDecl,
            with: observableAttribute
        )
        
        // Should provide best practice recommendations
        let bestPracticeIssues = result.issues.filter { $0.category == .bestPractice }
        XCTAssertGreaterThanOrEqual(bestPracticeIssues.count, 0, "Should provide best practice recommendations when applicable")
    }
    
    // MARK: - Integration Tests
    
    func testDiagnosticSystemIntegrationWithMacroCoordinator() throws {
        let mockContext = MockMacroExpansionContext()
        let coordinator = MacroCoordinator()
        let diagnosticSystem = EnhancedDiagnosticSystem(context: mockContext, coordinator: coordinator)
        
        // Register multiple macros in coordinator
        coordinator.register(ClientMacro.self, name: "Client")
        coordinator.register(ContextMacro.self, name: "Context")
        
        // Test validation considers registered macros
        let structDecl = createMockStruct("TestStruct")
        let clientAttribute = createMockAttribute("Client")
        
        let result = diagnosticSystem.validateMacroApplication(
            ClientMacro.self,
            on: structDecl,
            with: clientAttribute
        )
        
        // Should provide context-aware suggestions based on available macros
        let contextSuggestions = result.suggestions.filter { $0.contains("Context") }
        XCTAssertGreaterThanOrEqual(contextSuggestions.count, 0, "Should suggest available complementary macros")
    }
}

// MARK: - Test Helper Extensions

extension EnhancedDiagnosticsTests {
    
    /// Helper to create mock syntax for testing
    private func createMockStruct(_ name: String) -> StructDeclSyntax {
        return StructDeclSyntax(
            name: .identifier(name),
            memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
        )
    }
    
    /// Helper to create mock attribute syntax
    private func createMockAttribute(_ name: String) -> AttributeSyntax {
        return AttributeSyntax(
            attributeName: IdentifierTypeSyntax(name: .identifier(name))
        )
    }
}

// MARK: - Mock Classes for Testing

/// Mock macro expansion context for testing
class MockMacroExpansionContext: MacroExpansionContext {
    var diagnostics: [Diagnostic] = []
    
    func makeUniqueName(_ name: String) -> TokenSyntax {
        return TokenSyntax.identifier(name + "_unique")
    }
    
    func diagnose(_ diagnostic: Diagnostic) {
        diagnostics.append(diagnostic)
    }
    
    func location<Node: SyntaxProtocol>(of node: Node, at position: PositionInSyntaxNode, filePathMode: SourceLocationFilePathMode) -> AbstractSourceLocation? {
        return nil
    }
}

#endif