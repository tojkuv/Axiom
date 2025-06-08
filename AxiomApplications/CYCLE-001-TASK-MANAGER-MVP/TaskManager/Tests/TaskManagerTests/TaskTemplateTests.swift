import XCTest
import AxiomTesting
@testable import TaskManager

/// TDD Tests for REQ-011: Task Templates
/// Framework Components Under Test: Template State, Instantiation, Customization
final class TaskTemplateTests: XCTestCase {
    
    // MARK: - Template Creation Tests
    
    func testCreateBasicTemplate() async throws {
        // RED: Test basic template creation from task
        let client = TaskClient()
        let sourceTask = TaskItem(
            title: "Weekly Report",
            description: "Complete weekly progress report",
            priority: .high,
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )
        
        // Template creation should complete quickly
        let startTime = CFAbsoluteTimeGetCurrent()
        try await client.process(.createTemplate(from: sourceTask, name: "Weekly Report Template"))
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        let state = await client.currentState
        XCTAssertEqual(state.templates.count, 1)
        XCTAssertEqual(state.templates.first?.name, "Weekly Report Template")
        XCTAssertLessThan(elapsed, 0.05) // < 50ms requirement
    }
    
    func testCreateTemplateWithSubtasks() async throws {
        // RED: Test template creation with complex hierarchy
        let client = TaskClient()
        let sourceTask = TaskItem(
            title: "Project Setup",
            description: "Setup new project environment",
            priority: .high,
            subtasks: [
                TaskItem(title: "Create repository", priority: .high),
                TaskItem(title: "Setup CI/CD", priority: .medium),
                TaskItem(title: "Configure environment", priority: .low)
            ]
        )
        
        try await client.process(.createTemplate(from: sourceTask, name: "Project Setup Template"))
        
        let state = await client.currentState
        let template = state.templates.first
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.taskStructure.subtasks.count, 3)
        XCTAssertEqual(template?.taskStructure.title, "Project Setup")
    }
    
    func testCreateTemplateWithCustomization() async throws {
        // RED: Test template with customizable fields
        let client = TaskClient()
        let sourceTask = TaskItem(title: "{{CLIENT}} Meeting", description: "Meet with {{CLIENT}} about {{TOPIC}}")
        
        try await client.process(.createTemplate(
            from: sourceTask, 
            name: "Client Meeting Template",
            customizableFields: ["CLIENT", "TOPIC"]
        ))
        
        let state = await client.currentState
        let template = state.templates.first
        XCTAssertEqual(template?.customizableFields.count, 2)
        XCTAssertTrue(template?.customizableFields.contains("CLIENT") ?? false)
        XCTAssertTrue(template?.customizableFields.contains("TOPIC") ?? false)
    }
    
    // MARK: - Template Instantiation Tests
    
    func testInstantiateBasicTemplate() async throws {
        // RED: Test template instantiation performance
        let client = TaskClient()
        
        // First create a template
        let sourceTask = TaskItem(title: "Code Review", description: "Review pull request", priority: .medium)
        try await client.process(.createTemplate(from: sourceTask, name: "Code Review Template"))
        
        // Then instantiate it
        let templateId = (await client.currentState).templates.first!.id
        
        let startTime = CFAbsoluteTimeGetCurrent()
        try await client.process(.instantiateTemplate(templateId: templateId))
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        let state = await client.currentState
        XCTAssertEqual(state.tasks.count, 1)
        XCTAssertEqual(state.tasks.first?.title, "Code Review")
        XCTAssertLessThan(elapsed, 0.01) // < 10ms requirement
    }
    
    func testInstantiateTemplateWithCustomization() async throws {
        // RED: Test customized template instantiation
        let client = TaskClient()
        
        // Create template with customizable fields
        let sourceTask = TaskItem(title: "{{TYPE}} Testing", description: "Perform {{TYPE}} testing for {{FEATURE}}")
        try await client.process(.createTemplate(
            from: sourceTask,
            name: "Testing Template", 
            customizableFields: ["TYPE", "FEATURE"]
        ))
        
        let templateId = (await client.currentState).templates.first!.id
        let customizations = ["TYPE": "Unit", "FEATURE": "User Authentication"]
        
        try await client.process(.instantiateTemplate(
            templateId: templateId, 
            customizations: customizations
        ))
        
        let state = await client.currentState
        let instantiatedTask = state.tasks.first
        XCTAssertEqual(instantiatedTask?.title, "Unit Testing")
        XCTAssertEqual(instantiatedTask?.description, "Perform Unit testing for User Authentication")
    }
    
    func testInstantiateTemplateWithSubtasks() async throws {
        // RED: Test complex template instantiation
        let client = TaskClient()
        
        // Create template with subtasks
        let sourceTask = TaskItem(
            title: "Sprint Planning",
            subtasks: [
                TaskItem(title: "Review backlog"),
                TaskItem(title: "Estimate stories"),
                TaskItem(title: "Assign tasks")
            ]
        )
        try await client.process(.createTemplate(from: sourceTask, name: "Sprint Planning Template"))
        
        let templateId = (await client.currentState).templates.first!.id
        try await client.process(.instantiateTemplate(templateId: templateId))
        
        let state = await client.currentState
        let mainTask = state.tasks.first
        XCTAssertEqual(mainTask?.subtasks.count, 3)
        XCTAssertEqual(mainTask?.subtasks[0].title, "Review backlog")
    }
    
    // MARK: - Template Management Tests
    
    func testListTemplates() async throws {
        // RED: Test template listing functionality
        let client = TaskClient()
        
        // Create multiple templates
        let tasks = [
            TaskItem(title: "Daily Standup", priority: .low),
            TaskItem(title: "Code Review", priority: .medium), 
            TaskItem(title: "Deploy Release", priority: .high)
        ]
        
        for (index, task) in tasks.enumerated() {
            try await client.process(.createTemplate(from: task, name: "Template \(index + 1)"))
        }
        
        let state = await client.currentState
        XCTAssertEqual(state.templates.count, 3)
        XCTAssertEqual(state.templates.map { $0.name }.sorted(), ["Template 1", "Template 2", "Template 3"])
    }
    
    func testUpdateTemplate() async throws {
        // RED: Test template modification
        let client = TaskClient()
        
        let sourceTask = TaskItem(title: "Original Title", description: "Original Description")
        try await client.process(.createTemplate(from: sourceTask, name: "Test Template"))
        
        let templateId = (await client.currentState).templates.first!.id
        
        try await client.process(.updateTemplate(
            templateId: templateId,
            name: "Updated Template",
            taskStructure: TaskItem(title: "Updated Title", description: "Updated Description")
        ))
        
        let state = await client.currentState
        let template = state.templates.first
        XCTAssertEqual(template?.name, "Updated Template")
        XCTAssertEqual(template?.taskStructure.title, "Updated Title")
    }
    
    func testDeleteTemplate() async throws {
        // RED: Test template deletion
        let client = TaskClient()
        
        let sourceTask = TaskItem(title: "To Be Deleted")
        try await client.process(.createTemplate(from: sourceTask, name: "Delete Me"))
        
        let templateId = (await client.currentState).templates.first!.id
        try await client.process(.deleteTemplate(templateId: templateId))
        
        let state = await client.currentState
        XCTAssertEqual(state.templates.count, 0)
    }
    
    // MARK: - Template Library Tests
    
    func testSearchTemplates() async throws {
        // RED: Test template search functionality
        let client = TaskClient()
        
        // Create templates with different names
        let templates = [
            ("Meeting Template", TaskItem(title: "Team Meeting")),
            ("Code Review Template", TaskItem(title: "PR Review")),
            ("Testing Template", TaskItem(title: "QA Testing"))
        ]
        
        for (name, task) in templates {
            try await client.process(.createTemplate(from: task, name: name))
        }
        
        try await client.process(.searchTemplates(query: "Meeting"))
        
        let state = await client.currentState
        let searchResults = state.filteredTemplates
        XCTAssertEqual(searchResults.count, 1)
        XCTAssertEqual(searchResults.first?.name, "Meeting Template")
    }
    
    func testCategorizeTemplates() async throws {
        // RED: Test template categorization
        let client = TaskClient()
        
        let sourceTask = TaskItem(title: "Development Task")
        try await client.process(.createTemplate(
            from: sourceTask, 
            name: "Dev Template",
            category: "Development"
        ))
        
        let state = await client.currentState
        let template = state.templates.first
        XCTAssertEqual(template?.category, "Development")
    }
    
    // MARK: - Performance Tests
    
    func testTemplateCreationPerformance() async throws {
        // RED: Test template creation performance at scale
        let client = TaskClient()
        
        // Create tasks in batch for more realistic performance test
        var tasks: [TaskItem] = []
        for i in 0..<100 {
            tasks.append(TaskItem(title: "Task \(i)"))
        }
        
        measure {
            let expectation = self.expectation(description: "Templates created")
            
            Task {
                // Create templates concurrently for better performance testing
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for (index, task) in tasks.enumerated() {
                        group.addTask {
                            try await client.process(.createTemplate(from: task, name: "Template \(index)"))
                        }
                    }
                    
                    try await group.waitForAll()
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0) // Increased timeout for concurrent operations
        }
    }
    
    func testTemplateInstantiationPerformance() async throws {
        // RED: Test instantiation performance with complex templates
        let client = TaskClient()
        
        // Create complex template with many subtasks
        let complexTask = TaskItem(
            title: "Complex Project",
            subtasks: Array(0..<50).map { TaskItem(title: "Subtask \($0)") }
        )
        try await client.process(.createTemplate(from: complexTask, name: "Complex Template"))
        
        let templateId = (await client.currentState).templates.first!.id
        
        measure {
            let expectation = self.expectation(description: "Template instantiated")
            
            Task {
                try await client.process(.instantiateTemplate(templateId: templateId))
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInstantiateNonexistentTemplate() async throws {
        // RED: Test error handling for invalid template ID
        let client = TaskClient()
        let invalidId = UUID()
        
        do {
            try await client.process(.instantiateTemplate(templateId: invalidId))
            XCTFail("Should throw error for nonexistent template")
        } catch TaskError.templateNotFound {
            // Expected error
        }
    }
    
    func testCreateTemplateWithDuplicateName() async throws {
        // RED: Test error handling for duplicate template names
        let client = TaskClient()
        
        let task = TaskItem(title: "Test Task")
        try await client.process(.createTemplate(from: task, name: "Duplicate Name"))
        
        do {
            try await client.process(.createTemplate(from: task, name: "Duplicate Name"))
            XCTFail("Should throw error for duplicate template name")
        } catch TaskError.duplicateTemplateName {
            // Expected error
        }
    }
}