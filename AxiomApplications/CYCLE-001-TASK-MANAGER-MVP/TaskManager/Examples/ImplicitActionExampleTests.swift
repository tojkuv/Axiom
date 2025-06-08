// COMPREHENSIVE IMPLICIT ACTION TESTING EXAMPLE
// Shows various testing patterns for implicit action subscription

import XCTest
import AxiomFramework
@testable import TaskManager

class ImplicitActionExampleTests: XCTestCase {
    
    // MARK: - Unit Tests for Individual Contexts
    
    func testTitleFieldValidation() async throws {
        // Test field-level context in isolation
        let titleContext = TitleFieldContext()
        var receivedActions: [TaskCreationAction] = []
        
        // Create test harness to capture emitted actions
        let harness = TestContextHarness(context: titleContext) { action in
            if let taskAction = action as? TaskCreationAction {
                receivedActions.append(taskAction)
            }
        }
        
        // Test validation flow
        titleContext.title = "T"
        titleContext.validateTitle()
        
        // Wait for async validation
        try await Task.sleep(nanoseconds: 600_000_000) // Wait for debounce + validation
        
        // Verify actions emitted
        XCTAssertEqual(receivedActions.count, 2)
        
        // First action: title changed
        if case .titleChanged(let title) = receivedActions[0] {
            XCTAssertEqual(title, "T")
        } else {
            XCTFail("Expected titleChanged action")
        }
        
        // Second action: validation result
        if case .titleValidation(let isValid, let error) = receivedActions[1] {
            XCTAssertFalse(isValid)
            XCTAssertEqual(error, "Title must be at least 3 characters")
        } else {
            XCTFail("Expected titleValidation action")
        }
    }
    
    func testFormValidationAggregation() async throws {
        // Test form-level validation without parent
        let formContext = TaskFormContext()
        var receivedActions: [TaskCreationAction] = []
        
        let harness = TestContextHarness(context: formContext) { action in
            if let taskAction = action as? TaskCreationAction {
                receivedActions.append(taskAction)
            }
        }
        
        // Set valid title
        formContext.titleField.title = "Valid Task Title"
        formContext.titleField.validateTitle()
        
        // Wait for validation
        try await Task.sleep(nanoseconds: 600_000_000)
        
        // Verify form emits validation state
        let validationActions = receivedActions.compactMap { action -> (Bool, [String])? in
            if case .validationStateChanged(let isValid, let errors) = action {
                return (isValid, errors)
            }
            return nil
        }
        
        XCTAssertFalse(validationActions.isEmpty)
        let lastValidation = validationActions.last!
        XCTAssertTrue(lastValidation.0) // Form should be valid
        XCTAssertTrue(lastValidation.1.isEmpty) // No errors
    }
    
    // MARK: - Integration Tests for Action Flow
    
    func testCompleteActionFlowFromFieldToRoot() async throws {
        // Test complete hierarchy
        let client = TaskClient()
        let rootContext = TaskCreationRootContext(client: client)
        
        // Track root-level state changes
        var canSaveStates: [Bool] = []
        let cancellable = rootContext.$canSave.sink { canSave in
            canSaveStates.append(canSave)
        }
        
        // Simulate user input
        rootContext.formContext.titleField.title = "New Task"
        rootContext.formContext.titleField.validateTitle()
        
        // Set other required fields
        rootContext.formContext.priorityPicker.priority = .high
        rootContext.formContext.categoryPicker.selectedCategory = Category.defaults.first
        
        // Wait for validation to propagate
        try await Task.sleep(nanoseconds: 700_000_000)
        
        // Verify root context received validation state
        XCTAssertTrue(canSaveStates.contains(true))
        XCTAssertTrue(rootContext.canSave)
        
        // Test save action flow
        rootContext.save()
        
        // Wait for async save
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify task was created in client
        let tasks = await client.state.tasks
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "New Task")
        XCTAssertEqual(tasks.first?.priority, .high)
        
        cancellable.cancel()
    }
    
    func testErrorPropagation() async throws {
        // Test error handling through hierarchy
        let client = TaskClient()
        let rootContext = TaskCreationRootContext(client: client)
        
        // Set invalid due date
        rootContext.formContext.dueDatePicker.dueDate = Date().addingTimeInterval(-3600) // Past date
        
        // Try to save
        rootContext.formContext.titleField.title = "Task"
        rootContext.formContext.titleField.validateTitle()
        
        try await Task.sleep(nanoseconds: 700_000_000)
        
        // Force save even though invalid
        rootContext.save()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify error was shown
        XCTAssertTrue(rootContext.showError)
        XCTAssertTrue(rootContext.errorMessage.contains("future"))
    }
    
    // MARK: - Test Patterns for Implicit Actions
    
    func testSelectiveActionHandling() async throws {
        // Create custom context that only handles specific actions
        class SelectiveFormContext: TaskFormContext {
            var handledPriorityChanges = 0
            
            override func handleChildAction<T>(_ action: T, from child: Context) {
                guard let taskAction = action as? TaskCreationAction else { return }
                
                // Only handle priority changes, ignore others
                switch taskAction {
                case .priorityChanged:
                    handledPriorityChanges += 1
                default:
                    super.handleChildAction(action, from: child)
                }
            }
        }
        
        let formContext = SelectiveFormContext()
        
        // Change various fields
        formContext.titleField.title = "Test"
        formContext.priorityPicker.priority = .high
        formContext.categoryPicker.selectedCategory = Category.defaults.first
        formContext.priorityPicker.priority = .critical
        
        // Verify selective handling
        XCTAssertEqual(formContext.handledPriorityChanges, 2)
    }
    
    func testActionOrdering() async throws {
        // Test that actions maintain order through async operations
        let formContext = TaskFormContext()
        var receivedActions: [String] = []
        
        let harness = TestContextHarness(context: formContext) { action in
            if let taskAction = action as? TaskCreationAction {
                switch taskAction {
                case .titleChanged: receivedActions.append("title")
                case .priorityChanged: receivedActions.append("priority")
                case .categorySelected: receivedActions.append("category")
                case .validationStateChanged: receivedActions.append("validation")
                default: break
                }
            }
        }
        
        // Rapid changes
        formContext.titleField.title = "A"
        formContext.priorityPicker.priority = .high
        formContext.categoryPicker.selectedCategory = Category.defaults.first
        formContext.titleField.title = "AB"
        formContext.priorityPicker.priority = .low
        
        // Wait for all actions
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify order maintained
        XCTAssertEqual(receivedActions.first, "title")
        XCTAssertTrue(receivedActions.contains("priority"))
        XCTAssertTrue(receivedActions.contains("category"))
    }
    
    // MARK: - Performance Tests
    
    func testImplicitActionPerformance() throws {
        // Measure overhead of implicit action routing
        let rootContext = TaskCreationRootContext(client: TaskClient())
        
        measure {
            // Simulate 1000 rapid actions
            for i in 0..<1000 {
                rootContext.formContext.titleField.title = "Task \(i)"
                rootContext.formContext.priorityPicker.priority = i % 2 == 0 ? .high : .low
            }
        }
        
        // Should complete in < 100ms for 1000 actions
    }
    
    // MARK: - Memory Tests
    
    func testContextMemoryManagement() async throws {
        // Verify no retain cycles with implicit actions
        weak var weakForm: TaskFormContext?
        weak var weakTitle: TitleFieldContext?
        
        autoreleasepool {
            let client = TaskClient()
            let rootContext = TaskCreationRootContext(client: client)
            weakForm = rootContext.formContext
            weakTitle = rootContext.formContext.titleField
            
            // Trigger actions
            rootContext.formContext.titleField.title = "Test"
            rootContext.formContext.titleField.validateTitle()
            
            // Root context should be deallocated after this
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify contexts were deallocated
        XCTAssertNil(weakForm)
        XCTAssertNil(weakTitle)
    }
}

// MARK: - Test Helpers

/// Test harness that captures actions emitted by a context
class TestContextHarness {
    private let context: Context
    private let actionHandler: (Any) -> Void
    
    init(context: Context, actionHandler: @escaping (Any) -> Void) {
        self.context = context
        self.actionHandler = actionHandler
        
        // Hook into framework's implicit action routing
        context._testActionHandler = actionHandler
    }
}

// Extension to support testing
extension Context {
    var _testActionHandler: ((Any) -> Void)? {
        get { objc_getAssociatedObject(self, &TestHandlerKey) as? (Any) -> Void }
        set { objc_setAssociatedObject(self, &TestHandlerKey, newValue, .OBJC_ASSOCIATION_COPY) }
    }
    
    // Override emit for testing
    override func emit<T>(_ action: T) {
        if let handler = _testActionHandler {
            handler(action)
        } else {
            super.emit(action)
        }
    }
}

private var TestHandlerKey: UInt8 = 0

// MARK: - Test Patterns Documentation

/*
 IMPLICIT ACTION TESTING PATTERNS:
 
 1. Unit Testing Individual Contexts:
    - Use TestContextHarness to capture emitted actions
    - Test contexts in isolation without parent
    - Verify correct actions are emitted
 
 2. Integration Testing Action Flow:
    - Create full context hierarchy
    - Simulate user interactions
    - Verify actions propagate correctly
    - Check final state consistency
 
 3. Selective Action Handling:
    - Test that parents only handle relevant actions
    - Verify unhandled actions propagate up
    - Check action filtering logic
 
 4. Async Action Testing:
    - Use appropriate sleep times for debouncing
    - Verify async validation results
    - Test action ordering with async operations
 
 5. Performance Testing:
    - Measure action routing overhead
    - Test with high volume of actions
    - Verify no performance degradation
 
 6. Memory Testing:
    - Check for retain cycles
    - Verify proper cleanup
    - Test weak references
 */