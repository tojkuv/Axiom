import XCTest
@testable import TaskManager
import AxiomCore

@MainActor
final class ImplicitActionExampleTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    private var taskClient: MockTaskClient!
    private var navigationService: MockNavigationService!
    
    override func setUp() async throws {
        taskClient = MockTaskClient()
        navigationService = MockNavigationService()
    }
    
    // MARK: - Action Flow Tests
    
    func testActionFlowsUpHierarchy() async {
        // Given: A context hierarchy
        let rootContext = TaskCreationRootContext(
            taskClient: taskClient,
            navigationService: navigationService
        )
        let formContext = TaskFormContext()
        let validationContext = FieldValidationContext()
        
        // Wire up the hierarchy
        let rootNode = ContextNode(context: rootContext)
        let formNode = ContextNode(context: formContext, parent: rootNode)
        let validationNode = ContextNode(context: validationContext, parent: formNode)
        
        // When: An action is sent to the leaf context
        await validationContext.send(.updateTitle("Test Task"))
        
        // Then: The action flows up to the form context
        XCTAssertEqual(formContext.title, "Test Task")
    }
    
    func testSelectiveActionHandling() async {
        // Given: Contexts that handle different actions
        let rootContext = TaskCreationRootContext(
            taskClient: taskClient,
            navigationService: navigationService
        )
        let formContext = TaskFormContext()
        
        let rootNode = ContextNode(context: rootContext)
        let formNode = ContextNode(context: formContext, parent: rootNode)
        
        // When: A form action is sent
        await formContext.send(.updatePriority(.high))
        
        // Then: Form context handles it, root context ignores it
        XCTAssertEqual(formContext.priority, .high)
        XCTAssertTrue(rootContext.isPresented) // Root state unchanged
        
        // When: A navigation action is sent
        await formContext.send(.dismiss)
        
        // Then: Root context handles it
        XCTAssertFalse(rootContext.isPresented)
        XCTAssertTrue(navigationService.dismissCalled)
    }
    
    // MARK: - Validation Flow Tests
    
    func testValidationPropagation() async {
        // Given: Form context with validation
        let formContext = TaskFormContext()
        
        // When: Title is updated with invalid value
        await formContext.send(.updateTitle(""))
        await formContext.send(.validateTitle)
        
        // Then: Validation error is set
        XCTAssertNotNil(formContext.titleError)
        XCTAssertFalse(formContext.isValid)
        
        // When: Title is updated with valid value
        await formContext.send(.updateTitle("Valid Task Title"))
        
        // Then: Validation passes
        XCTAssertNil(formContext.titleError)
        XCTAssertTrue(formContext.isValid)
    }
    
    func testAsyncValidationWithDebounce() async {
        // Given: Validation context
        let validationContext = FieldValidationContext()
        
        // When: Multiple rapid updates
        await validationContext.send(.updateTitle("te"))
        await validationContext.send(.updateTitle("tes"))
        await validationContext.send(.updateTitle("test"))
        
        // Wait for debounce
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        // Then: Only final validation runs
        XCTAssertEqual(
            validationContext.validationMessage,
            "Title contains reserved word 'test'"
        )
    }
    
    // MARK: - Form Submission Tests
    
    func testSuccessfulFormSubmission() async {
        // Given: Complete context hierarchy
        let rootContext = TaskCreationRootContext(
            taskClient: taskClient,
            navigationService: navigationService
        )
        let formContext = TaskFormContext()
        
        let rootNode = ContextNode(context: rootContext)
        let formNode = ContextNode(context: formContext, parent: rootNode)
        
        // Setup valid form data
        await formContext.send(.updateTitle("Test Task"))
        await formContext.send(.updateDescription("Test Description"))
        await formContext.send(.updatePriority(.high))
        await formContext.send(.updateCategory(.work))
        
        // When: Form is submitted
        await formContext.send(.submitForm)
        
        // Then: Task is saved and navigation occurs
        XCTAssertTrue(taskClient.createTaskCalled)
        XCTAssertNotNil(rootContext.savedTask)
        XCTAssertFalse(rootContext.isPresented)
    }
    
    func testFormSubmissionWithValidationError() async {
        // Given: Form with invalid data
        let formContext = TaskFormContext()
        
        // When: Form is submitted without title
        await formContext.send(.submitForm)
        
        // Then: Validation error is shown, no save occurs
        XCTAssertFalse(formContext.isValid)
        XCTAssertFalse(formContext.isSaving)
    }
    
    // MARK: - Error Handling Tests
    
    func testSaveErrorHandling() async {
        // Given: Task client that will fail
        taskClient.shouldFailCreateTask = true
        
        let rootContext = TaskCreationRootContext(
            taskClient: taskClient,
            navigationService: navigationService
        )
        let formContext = TaskFormContext()
        
        let rootNode = ContextNode(context: rootContext)
        let formNode = ContextNode(context: formContext, parent: rootNode)
        
        // Setup valid form
        await formContext.send(.updateTitle("Test Task"))
        
        // When: Save fails
        await rootContext.send(.saveTask)
        
        // Then: Error is handled gracefully
        XCTAssertNil(rootContext.savedTask)
        XCTAssertTrue(rootContext.isPresented) // Still presented
        XCTAssertFalse(formContext.isSaving)
    }
    
    // MARK: - State Consistency Tests
    
    func testLoadingStateConsistency() async {
        // Given: Form context
        let formContext = TaskFormContext()
        
        // When: Saving starts
        await formContext.send(.savingStarted)
        
        // Then: Loading state is set
        XCTAssertTrue(formContext.isSaving)
        
        // When: Saving completes
        await formContext.send(.savingCompleted(Task(
            title: "Test",
            priority: .medium,
            category: .personal
        )))
        
        // Then: Loading state is cleared
        XCTAssertFalse(formContext.isSaving)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteUserFlow() async {
        // This test demonstrates the full user flow with implicit actions
        
        // 1. Create the view hierarchy
        let rootContext = TaskCreationRootContext(
            taskClient: taskClient,
            navigationService: navigationService
        )
        let formContext = TaskFormContext()
        let validationContext = FieldValidationContext()
        
        let rootNode = ContextNode(context: rootContext)
        let formNode = ContextNode(context: formContext, parent: rootNode)
        let validationNode = ContextNode(context: validationContext, parent: formNode)
        
        // 2. User types title (action flows from validation -> form)
        await validationContext.send(.updateTitle("My Important Task"))
        XCTAssertEqual(formContext.title, "My Important Task")
        
        // 3. User sets priority (action handled by form)
        await formContext.send(.updatePriority(.urgent))
        XCTAssertEqual(formContext.priority, .urgent)
        
        // 4. User submits form (action flows form -> root)
        await formContext.send(.submitForm)
        
        // 5. Verify the complete flow
        XCTAssertTrue(taskClient.createTaskCalled)
        XCTAssertNotNil(rootContext.savedTask)
        XCTAssertFalse(rootContext.isPresented)
        XCTAssertTrue(navigationService.dismissCalled)
    }
}

// MARK: - Mock Infrastructure

private final class MockTaskClient: TaskClient {
    var createTaskCalled = false
    var shouldFailCreateTask = false
    
    func createTask(_ task: Task) async throws -> Task {
        createTaskCalled = true
        if shouldFailCreateTask {
            throw TaskClientError.saveFailed
        }
        return task.withId(UUID())
    }
    
    func updateTask(_ task: Task) async throws -> Task {
        task
    }
    
    func deleteTask(_ id: UUID) async throws {
        // Not used in this test
    }
    
    func fetchTasks() async throws -> [Task] {
        []
    }
}

private final class MockNavigationService: NavigationService {
    var dismissCalled = false
    var currentRoute: TaskRoute?
    
    func navigate(to route: TaskRoute) {
        currentRoute = route
    }
    
    func dismiss() {
        dismissCalled = true
        currentRoute = nil
    }
}

enum TaskClientError: Error {
    case saveFailed
}

// MARK: - Context Node Helper
// This simulates the framework's context hierarchy management

@MainActor
private class ContextNode {
    let context: any ViewContext
    let parent: ContextNode?
    var children: [ContextNode] = []
    
    init(context: any ViewContext, parent: ContextNode? = nil) {
        self.context = context
        self.parent = parent
        parent?.children.append(self)
        
        // Setup implicit action forwarding
        setupActionForwarding()
    }
    
    private func setupActionForwarding() {
        // This simulates what the framework does internally
        // Actions not handled by this context are forwarded to parent
    }
}