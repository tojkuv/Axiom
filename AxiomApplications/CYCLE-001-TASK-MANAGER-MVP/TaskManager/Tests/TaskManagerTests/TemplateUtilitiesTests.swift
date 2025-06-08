import XCTest
@testable import TaskManager

/// Tests for TemplateUtilities - REFACTOR phase validation
final class TemplateUtilitiesTests: XCTestCase {
    
    // MARK: - Template Validation Tests
    
    func testValidTemplateValidation() {
        // Given: A valid template with matching placeholders
        let sourceTask = TaskItem(
            title: "{{TYPE}} Review",
            description: "Perform {{TYPE}} review for {{PROJECT}}"
        )
        let template = TaskTemplate(
            name: "Review Template",
            taskStructure: sourceTask,
            customizableFields: ["TYPE", "PROJECT"]
        )
        
        // When: Validating the template
        let result = TemplateUtilities.validateTemplate(template)
        
        // Then: Should be valid
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }
    
    func testInvalidTemplateValidation() {
        // Given: Template with mismatched placeholders
        let sourceTask = TaskItem(
            title: "{{TYPE}} Review",
            description: "Perform {{MISSING}} review"
        )
        let template = TaskTemplate(
            name: "Review Template",
            taskStructure: sourceTask,
            customizableFields: ["TYPE", "PROJECT"] // PROJECT not used, MISSING not declared
        )
        
        // When: Validating the template
        let result = TemplateUtilities.validateTemplate(template)
        
        // Then: Should be invalid with specific errors
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("PROJECT") })
        XCTAssertTrue(result.errors.contains { $0.contains("MISSING") })
    }
    
    func testEmptyTemplateNameValidation() {
        // Given: Template with empty name
        let template = TaskTemplate(
            name: "   ", // Only whitespace
            taskStructure: TaskItem(title: "Test"),
            customizableFields: []
        )
        
        // When: Validating the template
        let result = TemplateUtilities.validateTemplate(template)
        
        // Then: Should be invalid
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("name cannot be empty") })
    }
    
    // MARK: - Performance Optimization Tests
    
    func testOptimizedTemplateInstantiation() {
        // Given: Complex template with subtasks
        let sourceTask = TaskItem(
            title: "{{PROJECT}} Setup",
            description: "Setup {{PROJECT}} for {{CLIENT}}",
            subtasks: [
                TaskItem(title: "Create {{PROJECT}} repo"),
                TaskItem(title: "Configure {{PROJECT}} environment"),
                TaskItem(title: "Setup {{PROJECT}} CI/CD")
            ]
        )
        let template = TaskTemplate(
            name: "Project Setup",
            taskStructure: sourceTask,
            customizableFields: ["PROJECT", "CLIENT"]
        )
        
        let customizations = ["PROJECT": "MyApp", "CLIENT": "Acme Corp"]
        
        // When: Using optimized instantiation
        let instantiatedTask = TemplateUtilities.instantiateTemplateOptimized(template, customizations: customizations)
        
        // Then: Should correctly apply customizations
        XCTAssertEqual(instantiatedTask.title, "MyApp Setup")
        XCTAssertEqual(instantiatedTask.description, "Setup MyApp for Acme Corp")
        XCTAssertEqual(instantiatedTask.subtasks.count, 3)
        XCTAssertEqual(instantiatedTask.subtasks[0].title, "Create MyApp repo")
        XCTAssertEqual(instantiatedTask.subtasks[1].title, "Configure MyApp environment")
        XCTAssertEqual(instantiatedTask.subtasks[2].title, "Setup MyApp CI/CD")
    }
    
    func testOptimizedInstantiationPerformance() {
        // Given: Complex template for performance testing
        let subtasks = Array(0..<20).map { TaskItem(title: "Subtask \($0) for {{PROJECT}}") }
        let sourceTask = TaskItem(
            title: "{{PROJECT}} Implementation",
            description: "Complete {{PROJECT}} for {{CLIENT}}",
            subtasks: subtasks
        )
        let template = TaskTemplate(
            name: "Implementation Template",
            taskStructure: sourceTask,
            customizableFields: ["PROJECT", "CLIENT"]
        )
        
        let customizations = ["PROJECT": "TestApp", "CLIENT": "TestClient"]
        
        // When: Measuring optimized instantiation
        measure {
            for _ in 0..<100 {
                _ = TemplateUtilities.instantiateTemplateOptimized(template, customizations: customizations)
            }
        }
    }
    
    // MARK: - Complexity Analysis Tests
    
    func testSimpleTemplateComplexity() {
        // Given: Simple template
        let template = TaskTemplate(
            name: "Simple Task",
            taskStructure: TaskItem(title: "Simple {{TYPE}} task"),
            customizableFields: ["TYPE"]
        )
        
        // When: Analyzing complexity
        let analysis = TemplateUtilities.analyzeComplexity(template)
        
        // Then: Should be low complexity
        XCTAssertEqual(analysis.taskCount, 1)
        XCTAssertEqual(analysis.maxDepth, 1)
        XCTAssertEqual(analysis.placeholderCount, 1)
        XCTAssertEqual(analysis.performanceLevel, .excellent)
        XCTAssertTrue(analysis.warnings.isEmpty)
    }
    
    func testComplexTemplateComplexity() {
        // Given: Complex template with many subtasks and deep nesting
        let deepSubtasks = [
            TaskItem(title: "Level 2", subtasks: [
                TaskItem(title: "Level 3", subtasks: [
                    TaskItem(title: "Level 4")
                ])
            ])
        ]
        let manySubtasks = Array(0..<60).map { TaskItem(title: "Task \($0)") }
        let sourceTask = TaskItem(
            title: "{{A}} {{B}} {{C}} {{D}} {{E}} {{F}} {{G}} {{H}} {{I}} {{J}} {{K}} {{L}}", // 12 placeholders
            subtasks: manySubtasks + deepSubtasks
        )
        let template = TaskTemplate(
            name: "Complex Template",
            taskStructure: sourceTask,
            customizableFields: Array("ABCDEFGHIJKL").map { String($0) }
        )
        
        // When: Analyzing complexity
        let analysis = TemplateUtilities.analyzeComplexity(template)
        
        // Then: Should detect high complexity with warnings
        XCTAssertGreaterThan(analysis.taskCount, 50)
        XCTAssertGreaterThan(analysis.maxDepth, 3)
        XCTAssertGreaterThan(analysis.placeholderCount, 10)
        XCTAssertEqual(analysis.performanceLevel, .poor)
        XCTAssertFalse(analysis.warnings.isEmpty)
        XCTAssertFalse(analysis.suggestions.isEmpty)
    }
    
    // MARK: - Category Suggestion Tests
    
    func testDevelopmentCategorySuggestion() {
        // Given: Template with development-related content
        let template = TaskTemplate(
            name: "Implementation Template",
            taskStructure: TaskItem(
                title: "Implement new feature",
                description: "Code the new functionality and develop tests"
            ),
            customizableFields: []
        )
        
        // When: Getting category suggestion
        let suggestion = TemplateUtilities.suggestCategory(for: template)
        
        // Then: Should suggest Development
        XCTAssertEqual(suggestion, "Development")
    }
    
    func testTestingCategorySuggestion() {
        // Given: Template with testing-related content
        let template = TaskTemplate(
            name: "QA Template",
            taskStructure: TaskItem(
                title: "Test new feature",
                description: "Perform QA testing and bug validation"
            ),
            customizableFields: []
        )
        
        // When: Getting category suggestion
        let suggestion = TemplateUtilities.suggestCategory(for: template)
        
        // Then: Should suggest Testing
        XCTAssertEqual(suggestion, "Testing")
    }
    
    func testMeetingCategorySuggestion() {
        // Given: Template with meeting-related content
        let template = TaskTemplate(
            name: "Team Standup",
            taskStructure: TaskItem(
                title: "Daily standup meeting",
                description: "Team standup and review session"
            ),
            customizableFields: []
        )
        
        // When: Getting category suggestion
        let suggestion = TemplateUtilities.suggestCategory(for: template)
        
        // Then: Should suggest Meetings
        XCTAssertEqual(suggestion, "Meetings")
    }
    
    func testDocumentationCategorySuggestion() {
        // Given: Template with documentation-related content
        let template = TaskTemplate(
            name: "API Documentation",
            taskStructure: TaskItem(
                title: "Write API documentation",
                description: "Document the new API endpoints and create README"
            ),
            customizableFields: []
        )
        
        // When: Getting category suggestion
        let suggestion = TemplateUtilities.suggestCategory(for: template)
        
        // Then: Should suggest Documentation
        XCTAssertEqual(suggestion, "Documentation")
    }
    
    func testPlanningCategorySuggestion() {
        // Given: Template with planning-related content
        let template = TaskTemplate(
            name: "Sprint Planning",
            taskStructure: TaskItem(
                title: "Plan next sprint",
                description: "Sprint planning session and roadmap review"
            ),
            customizableFields: []
        )
        
        // When: Getting category suggestion
        let suggestion = TemplateUtilities.suggestCategory(for: template)
        
        // Then: Should suggest Planning
        XCTAssertEqual(suggestion, "Planning")
    }
    
    func testGeneralCategorySuggestion() {
        // Given: Template with generic content
        let template = TaskTemplate(
            name: "Generic Task",
            taskStructure: TaskItem(
                title: "Complete some work",
                description: "Do something important"
            ),
            customizableFields: []
        )
        
        // When: Getting category suggestion
        let suggestion = TemplateUtilities.suggestCategory(for: template)
        
        // Then: Should suggest General
        XCTAssertEqual(suggestion, "General")
    }
    
    // MARK: - Standard Categories Test
    
    func testStandardCategories() {
        // When: Getting standard categories
        let categories = TemplateUtilities.standardCategories
        
        // Then: Should contain expected categories
        XCTAssertTrue(categories.contains("Development"))
        XCTAssertTrue(categories.contains("Testing"))
        XCTAssertTrue(categories.contains("Documentation"))
        XCTAssertTrue(categories.contains("Meetings"))
        XCTAssertTrue(categories.contains("Planning"))
        XCTAssertTrue(categories.contains("Maintenance"))
        XCTAssertTrue(categories.contains("Personal"))
        XCTAssertTrue(categories.contains("General"))
    }
}