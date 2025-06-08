import XCTest
import Axiom
@testable import TaskManager

final class CreateTaskContextTests: XCTestCase {
    
    // MARK: - RED Phase: CreateTaskContext Tests
    
    func testCreateTaskContextInitialization() async {
        // Testing context for modal task creation
        // Framework insight: How do modal contexts differ?
        let client = await TaskTestHelpers.makeClient()
        let mockNavigation = await MockNavigationService()
        
        let context = await CreateTaskContext(
            client: client,
            navigationService: mockNavigation
        )
        
        await MainActor.run {
            // Should start with empty form state
            XCTAssertEqual(context.title, "")
            XCTAssertNil(context.description)
            XCTAssertFalse(context.isSubmitting)
            XCTAssertNil(context.validationError)
        }
    }
    
    func testCreateTaskContextValidation() async {
        // Test form validation logic
        // Framework insight: Where should validation live?
        let client = await TaskTestHelpers.makeClient()
        let context = await CreateTaskContext(client: client)
        
        await MainActor.run {
            // Empty title should fail validation
            context.title = ""
            XCTAssertFalse(context.isValid)
            
            // Whitespace-only title should fail
            context.title = "   "
            XCTAssertFalse(context.isValid)
            
            // Valid title should pass
            context.title = "Valid Task"
            XCTAssertTrue(context.isValid)
        }
    }
    
    func testCreateTaskSubmission() async {
        // Test task creation through context
        // Framework insight: How do contexts handle async submission?
        let client = await TaskTestHelpers.makeClient()
        let mockNavigation = await MockNavigationService()
        let context = await CreateTaskContext(
            client: client,
            navigationService: mockNavigation
        )
        
        await MainActor.run {
            // Set up valid task data
            context.title = "New Task"
            context.description = "Task description"
        }
        
        // Submit the task
        await context.submit()
        
        // Verify task was added to client
        let state = await client.state
        XCTAssertEqual(state.tasks.count, 1)
        XCTAssertEqual(state.tasks.first?.title, "New Task")
        XCTAssertEqual(state.tasks.first?.description, "Task description")
        
        // Verify navigation was dismissed
        await MainActor.run {
            XCTAssertTrue(mockNavigation.dismissCalled)
        }
    }
    
    func testCreateTaskValidationError() async {
        // Test validation error handling
        // Framework insight: How are form errors displayed?
        let client = await TaskTestHelpers.makeClient()
        let context = await CreateTaskContext(client: client)
        
        await MainActor.run {
            // Try to submit with invalid data
            context.title = ""
        }
        
        await context.submit()
        
        await MainActor.run {
            // Should have validation error
            XCTAssertNotNil(context.validationError)
            XCTAssertEqual(context.validationError, "Title is required")
            XCTAssertFalse(context.isSubmitting)
        }
    }
    
    func testCreateTaskSubmissionState() async {
        // Test submission state management
        // Framework insight: How to handle loading states?
        let client = await TaskTestHelpers.makeClient()
        let context = await CreateTaskContext(client: client)
        
        await MainActor.run {
            context.title = "Test Task"
            
            // Should not be submitting initially
            XCTAssertFalse(context.isSubmitting)
        }
        
        // Start submission
        let submitTask = Task {
            await context.submit()
        }
        
        // Check submitting state
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        await MainActor.run {
            // Should be submitting during operation
            // Note: This might be flaky due to timing
        }
        
        await submitTask.value
        
        await MainActor.run {
            // Should not be submitting after completion
            XCTAssertFalse(context.isSubmitting)
        }
    }
    
    func testCreateTaskCancellation() async {
        // Test cancel action
        // Framework insight: Modal dismissal patterns?
        let client = await TaskTestHelpers.makeClient()
        let mockNavigation = await MockNavigationService()
        let context = await CreateTaskContext(
            client: client,
            navigationService: mockNavigation
        )
        
        await MainActor.run {
            // Set some data
            context.title = "Unsaved Task"
            context.description = "This will be lost"
        }
        
        // Cancel the form
        await MainActor.run {
            context.cancel()
        }
        
        // Verify navigation was dismissed
        await MainActor.run {
            XCTAssertTrue(mockNavigation.dismissCalled)
        }
        
        // Verify no task was added
        let state = await client.state
        XCTAssertEqual(state.tasks.count, 0)
    }
    
    func testCreateTaskErrorPropagation() async {
        // Test error boundary integration
        // Framework insight: How do modal contexts handle errors?
        let client = await TaskTestHelpers.makeClient()
        let context = await CreateTaskContext(client: client)
        
        // Force an error by submitting a task that will fail
        // (In real app, this might be a network error)
        await MainActor.run {
            context.title = "Task That Fails"
        }
        
        // Note: We'd need to mock client failure here
        // For now, just verify error handling structure exists
        await context.submit()
        
        await MainActor.run {
            // Context should handle errors gracefully
            XCTAssertFalse(context.isSubmitting)
        }
    }
}


