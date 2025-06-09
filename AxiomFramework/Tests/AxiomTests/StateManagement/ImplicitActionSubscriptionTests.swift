import XCTest
@testable import Axiom

final class ImplicitActionSubscriptionTests: XCTestCase {
    
    // Test implicit action subscription from child to parent
    @MainActor
    func testImplicitActionSubscription() async throws {
        // Given: A parent context with a child context
        let parent = TestParentContext()
        let child = TestChildContext()
        parent.addChild(child)
        
        // When: Child emits an action
        let testAction = TestChildContext.Action.itemSelected(id: "test-123")
        child.emit(testAction)
        
        // Allow async propagation
        try await Task.sleep(for: .milliseconds(10))
        
        // Then: Parent should receive the action
        let capturedActions = parent.capturedActions
        XCTAssertEqual(capturedActions.count, 1)
        
        if let captured = capturedActions.first as? TestChildContext.Action {
            if case .itemSelected(let id) = captured {
                XCTAssertEqual(id, "test-123")
            } else {
                XCTFail("Wrong action type received")
            }
        } else {
            XCTFail("No action captured")
        }
    }
    
    // Test multiple children emitting actions
    @MainActor
    func testMultipleChildrenActions() async throws {
        // Given: A parent with multiple children
        let parent = TestParentContext()
        let child1 = TestChildContext()
        let child2 = TestChildContext()
        
        parent.addChild(child1)
        parent.addChild(child2)
        
        // When: Both children emit actions
        child1.emit(TestChildContext.Action.itemSelected(id: "child1"))
        child2.emit(TestChildContext.Action.itemDeleted(id: "child2"))
        
        // Allow async propagation
        try await Task.sleep(for: .milliseconds(20))
        
        // Then: Parent should receive both actions
        let capturedActions = parent.capturedActions
        XCTAssertEqual(capturedActions.count, 2)
    }
    
    // Test weak parent reference to prevent cycles
    @MainActor
    func testWeakParentReference() async throws {
        var parent: TestParentContext? = TestParentContext()
        let child = TestChildContext()
        
        parent?.addChild(child)
        
        // Verify child has parent
        let hasParent = child.parentContext != nil
        XCTAssertTrue(hasParent)
        
        // When: Parent is deallocated
        parent = nil
        
        // Allow weak reference to clear
        try await Task.sleep(for: .milliseconds(10))
        
        // Then: Child's parent reference should be nil
        let parentAfterDealloc = child.parentContext
        XCTAssertNil(parentAfterDealloc)
    }
    
    // Test child context lifecycle management
    @MainActor
    func testChildContextLifecycle() async throws {
        // Given: A parent context
        let parent = TestParentContext()
        var child: TestChildContext? = TestChildContext()
        
        parent.addChild(child!)
        
        // Verify child is tracked
        let childCount = parent.childContexts.count
        XCTAssertEqual(childCount, 1)
        
        // When: Child is deallocated
        child = nil
        
        // Allow weak reference to clear
        try await Task.sleep(for: .milliseconds(10))
        
        // Force cleanup
        parent.cleanupDeallocatedChildren()
        
        // Then: Parent should not retain child
        let childCountAfter = parent.childContexts.count
        XCTAssertEqual(childCountAfter, 0)
    }
    
    // Test action does not emit without parent
    @MainActor
    func testActionWithoutParent() async throws {
        // Given: A child context without parent
        let child = TestChildContext()
        
        // When: Child emits action
        child.emit(TestChildContext.Action.itemSelected(id: "orphan"))
        
        // Then: No error occurs (action is silently dropped)
        // This test passes if no crash occurs
    }
    
    // Test type safety of actions
    @MainActor
    func testActionTypeSafety() async throws {
        // Given: A parent and child with different action types
        let parent = TestParentContext()
        let child = TestChildContext()
        parent.addChild(child)
        
        // When: Child emits its action type
        child.emit(TestChildContext.Action.itemSelected(id: "typed"))
        
        // Allow async propagation
        try await Task.sleep(for: .milliseconds(10))
        
        // Then: Parent can handle it with type checking
        let handled = parent.handledActionTypes
        XCTAssertFalse(handled.isEmpty, "Should have handled at least one action")
        XCTAssertTrue(handled.contains("Action"), "Should have handled TestChildContext.Action")
    }
}

// MARK: - Test Contexts

@MainActor
class TestParentContext: BaseContext {
    private(set) var capturedActions: [Any] = []
    private(set) var handledActionTypes: Set<String> = []
    
    override func handleChildAction<T>(_ action: T, from child: any Context) {
        capturedActions.append(action)
        handledActionTypes.insert(String(describing: type(of: action)))
    }
}

@MainActor
class TestChildContext: BaseContext {
    enum Action {
        case itemSelected(id: String)
        case itemDeleted(id: String)
        case itemUpdated(id: String, value: String)
    }
}