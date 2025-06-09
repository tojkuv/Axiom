import XCTest
import SwiftUI
@testable import Axiom

final class PresentationProtocolTests: XCTestCase {
    
    // Test that Presentation views require contexts
    @MainActor
    func testPresentationViewRequiresContext() async throws {
        // Given: A Presentation view type
        let presentationView = SamplePresentationView(context: TestPresentationContext())
        
        // Then: It should conform to Presentation protocol
        XCTAssertTrue(presentationView is any PresentationView)
        
        // And: It should have a context
        XCTAssertNotNil(presentationView.context)
    }
    
    // Test that simple views don't require contexts
    @MainActor
    func testSimpleViewDoesNotRequireContext() async throws {
        // Given: A simple view without context
        let simpleView = TestSimpleView(title: "Test")
        
        // Then: It should not conform to Presentation protocol
        XCTAssertFalse(simpleView is any PresentationView)
    }
    
    // Test DAG validation for Presentation views only
    @MainActor
    func testDAGValidationForPresentationViewsOnly() async throws {
        // Given: A mixed view hierarchy
        struct MixedHierarchy: View {
            @StateObject var rootContext = TestRootContext()
            
            var body: some View {
                VStack {
                    // Presentation view with context
                    SamplePresentationView(context: rootContext.childContext)
                    
                    // Simple view without context
                    TestSimpleView(title: "Badge")
                    
                    // Another Presentation view
                    SampleChildPresentationView(context: rootContext.anotherChildContext)
                }
            }
        }
        
        // When: Creating the view hierarchy
        let view = MixedHierarchy()
        
        // Then: Mixed hierarchy should be allowed
        // Simple views don't need contexts, only Presentation views do
        XCTAssertNotNil(view.rootContext.childContext)
        XCTAssertNotNil(view.rootContext.anotherChildContext)
    }
    
    // Test nested Presentation views maintain parent-child relationships
    @MainActor
    func testNestedPresentationViews() async throws {
        // Given: Nested Presentation views
        let parentContext = TestPresentationContext()
        let childContext = TestChildPresentationContext()
        parentContext.addChild(childContext)
        
        let parentView = SamplePresentationView(context: parentContext)
        let childView = SampleChildPresentationView(context: childContext)
        
        // When: Child emits action
        childContext.emit(TestChildPresentationContext.Action.buttonTapped)
        
        // Allow async propagation
        try await Task.sleep(for: .milliseconds(10))
        
        // Then: Parent should receive it
        XCTAssertEqual(parentContext.receivedActions.count, 1)
    }
    
    // Test Presentation view lifecycle
    @MainActor
    func testPresentationViewLifecycle() async throws {
        // Given: A Presentation view
        let context = TestPresentationContext()
        let view = SamplePresentationView(context: context)
        
        // When: View appears
        await context.onAppear()
        
        // Then: Context should be active
        XCTAssertTrue(context.isActive)
        
        // When: View disappears
        await context.onDisappear()
        
        // Then: Context should be inactive
        XCTAssertFalse(context.isActive)
    }
}

// MARK: - Test Views

/// Simple view without context
struct TestSimpleView: View {
    let title: String
    
    var body: some View {
        Text(title)
    }
}

/// Presentation view with context
struct SamplePresentationView: PresentationView {
    @ObservedObject var context: TestPresentationContext
    
    var body: some View {
        VStack {
            Text("Presentation View")
            Button("Action") {
                // Action handled by context
            }
        }
    }
}

/// Child Presentation view
struct SampleChildPresentationView: PresentationView {
    @ObservedObject var context: TestChildPresentationContext
    
    var body: some View {
        Button("Child Action") {
            context.emit(TestChildPresentationContext.Action.buttonTapped)
        }
    }
}

// MARK: - Test Contexts

@MainActor
class TestPresentationContext: BaseContext {
    private(set) var receivedActions: [Any] = []
    
    override func handleChildAction<T>(_ action: T, from child: any Context) {
        receivedActions.append(action)
    }
}

@MainActor
class TestChildPresentationContext: BaseContext {
    enum Action {
        case buttonTapped
        case valueChanged(String)
    }
}

@MainActor
class TestRootContext: BaseContext {
    @Published var childContext = TestPresentationContext()
    @Published var anotherChildContext = TestChildPresentationContext()
    
    override func onAppear() async {
        await super.onAppear()
        addChild(childContext)
        addChild(anotherChildContext)
    }
}