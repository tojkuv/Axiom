import Foundation
import Axiom

/// Task template model for REQ-011: Task Templates
/// Represents a reusable task structure that can be instantiated
struct TaskTemplate: State, Codable {
    let id: UUID
    let name: String
    let taskStructure: TaskItem
    let customizableFields: [String]
    let category: String?
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        taskStructure: TaskItem,
        customizableFields: [String] = [],
        category: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.taskStructure = taskStructure
        self.customizableFields = customizableFields
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Template Instantiation

extension TaskTemplate {
    /// Instantiate a task from this template with optional customizations
    /// Uses optimized utilities for better performance
    func instantiate(customizations: [String: String] = [:]) -> TaskItem {
        return TemplateUtilities.instantiateTemplateOptimized(self, customizations: customizations)
    }
}

// MARK: - Template Validation

extension TaskTemplate {
    /// Validate template using utilities for comprehensive checking
    var validation: ValidationResult {
        return TemplateUtilities.validateTemplate(self)
    }
    
    /// Validate that all customizable fields have corresponding placeholders in the template
    var isValid: Bool {
        return validation.isValid
    }
    
    /// Get complexity analysis for performance optimization
    var complexityAnalysis: ComplexityAnalysis {
        return TemplateUtilities.analyzeComplexity(self)
    }
    
    /// Suggest category based on template content
    var suggestedCategory: String? {
        return category ?? TemplateUtilities.suggestCategory(for: self)
    }
}