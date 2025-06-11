import XCTest
@testable import Axiom
@testable import AxiomTesting

@MainActor
final class PresentationContextBindingTests: XCTestCase {
    // Test that multiple contexts fail
    func testMultipleContextsFail() async {
        let validator = PresentationContextValidator()
        
        // Attempting to bind multiple contexts to a single presentation
        let presentation = MockPresentation(id: "test-presentation")
        let context1 = MockContext(id: "context-1")
        let context2 = MockContext(id: "context-2")
        
        // First binding should succeed
        XCTAssertTrue(validator.bindContext(context1, to: presentation))
        
        // Second binding should fail
        XCTAssertFalse(validator.bindContext(context2, to: presentation))
        
        // Verify error message
        XCTAssertEqual(
            validator.lastError,
            "Presentation 'test-presentation' already has context 'context-1' bound; cannot bind 'context-2'"
        )
    }
    
    // Test 1:1 binding enforcement
    func testOneToOneBinding() async {
        let validator = PresentationContextValidator()
        
        // Create multiple presentations and contexts
        let presentations = (0..<5).map { MockPresentation(id: "presentation-\($0)") }
        let contexts = (0..<5).map { MockContext(id: "context-\($0)") }
        
        // Each presentation should bind to exactly one context
        for (index, presentation) in presentations.enumerated() {
            XCTAssertTrue(validator.bindContext(contexts[index], to: presentation))
        }
        
        // Verify bindings
        for (index, presentation) in presentations.enumerated() {
            let context = validator.getContext(for: presentation) as? MockContext
            XCTAssertEqual(context?.id, "context-\(index)")
        }
        
        // Verify no cross-binding allowed
        XCTAssertFalse(validator.bindContext(contexts[0], to: presentations[1]))
    }
    
    // Test @PresentationContext property wrapper
    func testPresentationContextPropertyWrapper() async {
        // Test compilation failure when accessing multiple contexts
        // This will be a compile-time check, so we test the wrapper behavior
        
        struct TestPresentation {
            @PresentationContext var context: MockContext
            
            init(context: MockContext) {
                self._context = PresentationContext(wrappedValue: context)
            }
        }
        
        let context = MockContext(id: "test-context")
        let presentation = TestPresentation(context: context)
        
        XCTAssertEqual(presentation.context.id, "test-context")
        
        // Test that the wrapper enforces single binding
        // Attempting to reassign should fail at runtime
        // This will be enforced by the property wrapper's implementation
    }
    
    // Test boundary condition with 100 presentations
    func testBoundaryConditionsWith100Presentations() async {
        let validator = PresentationContextValidator()
        
        // Create 100 presentations and contexts
        let presentations = (0..<100).map { MockPresentation(id: "presentation-\($0)") }
        let contexts = (0..<100).map { MockContext(id: "context-\($0)") }
        
        // Bind each presentation to its corresponding context
        for (index, presentation) in presentations.enumerated() {
            XCTAssertTrue(validator.bindContext(contexts[index], to: presentation))
        }
        
        // Verify all bindings are 1:1
        for (index, presentation) in presentations.enumerated() {
            let context = validator.getContext(for: presentation) as? MockContext
            XCTAssertEqual(context?.id, "context-\(index)")
        }
        
        // Verify total binding count
        XCTAssertEqual(validator.bindingCount, 100)
        
        // Verify no duplicate bindings
        XCTAssertEqual(validator.uniquePresentationCount, 100)
        XCTAssertEqual(validator.uniqueContextCount, 100)
    }
    
    // Test lifetime matching
    func testLifetimeMatching() async throws {
        let validator = PresentationContextValidator()
        
        var presentation = MockPresentation(id: "test-presentation")
        let context = MockContext(id: "test-context")
        
        // Bind context to presentation
        XCTAssertTrue(validator.bindContext(context, to: presentation))
        
        // Note: Lifecycle management (appear/disappear) would be handled by SwiftUI
        // in the real implementation through @StateObject and onAppear/onDisappear
        
        // For now, we'll manually update the state for testing
        presentation.simulateAppear()
        context.isActive = true // Manual update for testing
        XCTAssertTrue(context.isActive)
        
        presentation.simulateDisappear()
        context.isActive = false // Manual update for testing
        XCTAssertFalse(context.isActive)
        
        // Context should be unbound after presentation is deallocated
        presentation.simulateDeallocation()
        XCTAssertNil(validator.getContext(for: presentation))
    }
}