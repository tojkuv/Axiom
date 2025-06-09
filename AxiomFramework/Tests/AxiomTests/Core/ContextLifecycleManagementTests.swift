import XCTest
import SwiftUI
@testable import Axiom

final class ContextLifecycleManagementTests: XCTestCase {
    
    // Test automatic context lifecycle management
    @MainActor
    func testAutomaticContextLifecycle() async throws {
        // Given: A context provider managing lifecycle
        let provider = ContextProvider()
        let tracker = LifecycleTracker()
        
        // When: Creating a managed context
        let contextId = "test-context-1"
        let context = provider.context(id: contextId) {
            TestManagedContext(id: contextId, tracker: tracker)
        }
        
        // Then: Context should be created and attached
        XCTAssertEqual(context.id, contextId)
        XCTAssertEqual(tracker.attachCount, 1)
        XCTAssertTrue(tracker.activeContexts.contains(contextId))
        
        // When: Removing the context
        provider.removeContext(id: contextId)
        
        // Then: Context should be detached
        XCTAssertEqual(tracker.detachCount, 1)
        XCTAssertFalse(tracker.activeContexts.contains(contextId))
        
        // And: Lifecycle should be balanced
        tracker.assertBalanced()
    }
    
    // Test identity-based context resolution
    @MainActor
    func testIdentityBasedContextResolution() async throws {
        // Given: A provider with multiple contexts
        let provider = ContextProvider()
        let tracker = LifecycleTracker()
        
        // When: Creating contexts with different identities
        let context1 = provider.context(id: "item-1") {
            TestManagedContext(id: "item-1", tracker: tracker)
        }
        let context2 = provider.context(id: "item-2") {
            TestManagedContext(id: "item-2", tracker: tracker)
        }
        
        // Then: Contexts should have distinct identities
        XCTAssertNotEqual(context1.id, context2.id)
        XCTAssertEqual(tracker.attachCount, 2)
        
        // When: Requesting existing context
        let existingContext = provider.context(id: "item-1") {
            TestManagedContext(id: "item-1", tracker: tracker)
        }
        
        // Then: Same instance should be returned (no new creation)
        XCTAssertTrue(context1 === existingContext)
        XCTAssertEqual(tracker.attachCount, 2) // No additional attach
    }
    
    // Test memory management with weak references
    @MainActor
    func testMemoryManagement() async throws {
        var provider: ContextProvider? = ContextProvider()
        weak var weakContext: TestManagedContext?
        
        // Create context and capture weak reference
        autoreleasepool {
            let context = provider?.context(id: "memory-test") {
                TestManagedContext(id: "memory-test", tracker: LifecycleTracker())
            }
            weakContext = context
        }
        
        // Context should still exist while provider holds it
        XCTAssertNotNil(weakContext)
        
        // When: Provider is deallocated
        provider = nil
        
        // Allow cleanup
        try await Task.sleep(for: .milliseconds(10))
        
        // Then: Context should be deallocated
        XCTAssertNil(weakContext)
    }
    
    // Test concurrent access safety
    @MainActor
    func testConcurrentAccess() async throws {
        let provider = ContextProvider()
        let tracker = LifecycleTracker()
        
        // When: Multiple concurrent context creations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask { @MainActor in
                    let context = provider.context(id: "concurrent-\(i)") {
                        TestManagedContext(id: "concurrent-\(i)", tracker: tracker)
                    }
                    XCTAssertEqual(context.id, "concurrent-\(i)")
                }
            }
        }
        
        // Then: All contexts should be created safely
        XCTAssertEqual(tracker.attachCount, 10)
        XCTAssertEqual(tracker.activeContexts.count, 10)
    }
    
    // Test SwiftUI view lifecycle integration
    @MainActor
    func testSwiftUILifecycleIntegration() async throws {
        // Given: A managed context view
        let provider = ContextProvider()
        let tracker = LifecycleTracker()
        
        struct TestView: View {
            let provider: ContextProvider
            let tracker: LifecycleTracker
            
            var body: some View {
                Text("Test")
                    .managedContext(
                        id: "swiftui-test",
                        create: { TestManagedContext(id: "swiftui-test", tracker: tracker) }
                    )
            }
        }
        
        // When: View appears (simulated)
        let testView = TestView(provider: provider, tracker: tracker)
        
        // Note: Full SwiftUI lifecycle testing would require view host
        // For now, we test the underlying provider behavior
        let context = provider.context(id: "swiftui-test") {
            TestManagedContext(id: "swiftui-test", tracker: tracker)
        }
        
        // Then: Context should be properly managed
        XCTAssertNotNil(context)
        XCTAssertEqual(tracker.attachCount, 1)
    }
}

// MARK: - Test Support Types

class TestManagedContext: BaseContext, ManagedContext {
    nonisolated let id: AnyHashable
    private let tracker: LifecycleTracker
    private(set) var isAttached = false
    
    init(id: AnyHashable, tracker: LifecycleTracker) {
        self.id = id
        self.tracker = tracker
        super.init()
    }
    
    func onAttach() {
        isAttached = true
        tracker.trackAttach(id: id)
    }
    
    func onDetach() {
        isAttached = false
        tracker.trackDetach(id: id)
    }
}

class LifecycleTracker {
    private(set) var attachCount = 0
    private(set) var detachCount = 0
    private(set) var activeContexts = Set<AnyHashable>()
    private let lock = NSLock()
    
    func trackAttach(id: AnyHashable) {
        lock.lock()
        defer { lock.unlock() }
        attachCount += 1
        activeContexts.insert(id)
    }
    
    func trackDetach(id: AnyHashable) {
        lock.lock()
        defer { lock.unlock() }
        detachCount += 1
        activeContexts.remove(id)
    }
    
    func assertBalanced(
        file: StaticString = #file,
        line: UInt = #line
    ) {
        lock.lock()
        defer { lock.unlock() }
        XCTAssertEqual(
            attachCount,
            detachCount,
            "Lifecycle imbalance: \(attachCount) attaches, \(detachCount) detaches",
            file: file,
            line: line
        )
    }
}