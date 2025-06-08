import XCTest
import SwiftUI
import Axiom
@testable import TaskManager

final class CreateTaskViewTests: XCTestCase {
    
    // MARK: - RED Phase: CreateTaskView Tests
    
    func testCreateTaskViewInitialization() async {
        // Test view creation with context
        // Framework insight: Modal view patterns?
        let client = await TaskTestHelpers.makeClient()
        let context = await CreateTaskContext(client: client)
        
        await MainActor.run {
            let view = CreateTaskView(context: context)
            XCTAssertNotNil(view)
        }
    }
    
    func testCreateTaskViewFormBinding() async {
        // Test form field bindings
        // Framework insight: How do forms bind to context state?
        let client = await TaskTestHelpers.makeClient()
        let context = await CreateTaskContext(client: client)
        
        await MainActor.run {
            let view = CreateTaskView(context: context)
            
            // Verify initial state
            XCTAssertEqual(context.title, "")
            XCTAssertNil(context.description)
            
            // Simulate form input
            context.title = "Test Title"
            context.description = "Test Description"
            
            // Context should reflect changes
            XCTAssertEqual(context.title, "Test Title")
            XCTAssertEqual(context.description, "Test Description")
        }
    }
    
    func testCreateTaskViewValidationDisplay() async {
        // Test validation error display
        // Framework insight: Error UI patterns?
        let client = await TaskTestHelpers.makeClient()
        let context = await CreateTaskContext(client: client)
        
        await MainActor.run {
            let view = CreateTaskView(context: context)
            
            // Set validation error
            context.validationError = "Title is required"
            
            // View should be able to display error
            XCTAssertNotNil(context.validationError)
        }
    }
    
    func testCreateTaskViewSubmitButton() async {
        // Test submit button state
        // Framework insight: Form submission patterns?
        let client = await TaskTestHelpers.makeClient()
        let context = await CreateTaskContext(client: client)
        
        await MainActor.run {
            let view = CreateTaskView(context: context)
            
            // Submit should be disabled when invalid
            context.title = ""
            XCTAssertFalse(context.isValid)
            
            // Submit should be enabled when valid
            context.title = "Valid Title"
            XCTAssertTrue(context.isValid)
            
            // Submit should be disabled when submitting
            context.isSubmitting = true
            XCTAssertTrue(context.isSubmitting)
        }
    }
    
    func testCreateTaskViewNavigationButtons() async {
        // Test navigation bar buttons
        // Framework insight: Modal navigation patterns?
        let client = await TaskTestHelpers.makeClient()
        let mockNavigation = await MockNavigationService()
        let context = await CreateTaskContext(
            client: client,
            navigationService: mockNavigation
        )
        
        await MainActor.run {
            let view = CreateTaskView(context: context)
            
            // View should have cancel and save actions
            // Cancel should dismiss
            context.cancel()
            
            // Save should validate and submit
            context.title = "New Task"
            XCTAssertTrue(context.isValid)
        }
    }
    
    func testCreateTaskViewKeyboardHandling() async {
        // Test keyboard and focus management
        // Framework insight: Form UX patterns?
        let client = await TaskTestHelpers.makeClient()
        let context = await CreateTaskContext(client: client)
        
        await MainActor.run {
            let view = CreateTaskView(context: context)
            
            // View should handle keyboard properly
            // This is more of a UI test, but we verify the structure exists
            XCTAssertNotNil(view)
        }
    }
}

