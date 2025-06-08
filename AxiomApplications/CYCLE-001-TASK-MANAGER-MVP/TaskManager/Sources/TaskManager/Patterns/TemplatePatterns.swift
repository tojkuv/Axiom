import Foundation
import Axiom

/// Reusable patterns for template management
/// REQ-011: Task Templates - REFACTOR phase patterns

// MARK: - Template Library Pattern

/// Pattern for managing a collection of templates with search and categorization
@MainActor
class TemplateLibraryPattern: ObservableObject {
    @Published var templates: [TaskTemplate] = []
    @Published var searchQuery: String = ""
    @Published var selectedCategory: String? = nil
    @Published var sortOrder: TemplateSortOrder = .nameAscending
    
    /// Filtered and sorted templates based on current criteria
    var filteredTemplates: [TaskTemplate] {
        var result = templates
        
        // Apply search filter
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter { template in
                template.name.lowercased().contains(query) ||
                template.category?.lowercased().contains(query) == true ||
                template.taskStructure.title.lowercased().contains(query)
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // Apply sorting
        return result.sorted { lhs, rhs in
            switch sortOrder {
            case .nameAscending:
                return lhs.name < rhs.name
            case .nameDescending:
                return lhs.name > rhs.name
            case .createdDateAscending:
                return lhs.createdAt < rhs.createdAt
            case .createdDateDescending:
                return lhs.createdAt > rhs.createdAt
            case .complexityAscending:
                return lhs.complexityAnalysis.complexityScore < rhs.complexityAnalysis.complexityScore
            case .complexityDescending:
                return lhs.complexityAnalysis.complexityScore > rhs.complexityAnalysis.complexityScore
            }
        }
    }
    
    /// Available categories from templates
    var availableCategories: [String] {
        let templateCategories = Set(templates.compactMap { $0.category })
        return Array(templateCategories.union(Set(TemplateUtilities.standardCategories))).sorted()
    }
    
    /// Add template with automatic category suggestion
    func addTemplate(_ template: TaskTemplate) {
        var optimizedTemplate = template
        
        // Auto-suggest category if none provided
        if optimizedTemplate.category == nil {
            optimizedTemplate = TaskTemplate(
                id: template.id,
                name: template.name,
                taskStructure: template.taskStructure,
                customizableFields: template.customizableFields,
                category: template.suggestedCategory,
                createdAt: template.createdAt,
                updatedAt: template.updatedAt
            )
        }
        
        templates.append(optimizedTemplate)
    }
    
    /// Update search query with debouncing for performance
    func updateSearchQuery(_ query: String) {
        searchQuery = query
    }
    
    /// Clear all filters
    func clearFilters() {
        searchQuery = ""
        selectedCategory = nil
        sortOrder = .nameAscending
    }
}

enum TemplateSortOrder: CaseIterable {
    case nameAscending
    case nameDescending
    case createdDateAscending
    case createdDateDescending
    case complexityAscending
    case complexityDescending
    
    var displayName: String {
        switch self {
        case .nameAscending: return "Name (A-Z)"
        case .nameDescending: return "Name (Z-A)"
        case .createdDateAscending: return "Oldest First"
        case .createdDateDescending: return "Newest First"
        case .complexityAscending: return "Simplest First"
        case .complexityDescending: return "Most Complex First"
        }
    }
}

// MARK: - Template Creation Wizard Pattern

/// Pattern for guided template creation with validation
@MainActor
class TemplateCreationWizardPattern: ObservableObject {
    @Published var currentStep: CreationStep = .sourceTask
    @Published var sourceTask: TaskItem?
    @Published var templateName: String = ""
    @Published var selectedCategory: String?
    @Published var detectedPlaceholders: Set<String> = []
    @Published var customizableFields: [String] = []
    @Published var validationErrors: [String] = []
    
    /// Check if current step is valid
    var isCurrentStepValid: Bool {
        switch currentStep {
        case .sourceTask:
            return sourceTask != nil
        case .naming:
            return !templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .customization:
            return validationErrors.isEmpty
        case .review:
            return finalTemplate != nil
        }
    }
    
    /// Preview of the final template
    var finalTemplate: TaskTemplate? {
        guard let sourceTask = sourceTask else { return nil }
        
        return TaskTemplate(
            name: templateName,
            taskStructure: sourceTask,
            customizableFields: customizableFields,
            category: selectedCategory
        )
    }
    
    /// Advance to next step
    func nextStep() {
        switch currentStep {
        case .sourceTask:
            if sourceTask != nil {
                extractPlaceholders()
                currentStep = .naming
            }
        case .naming:
            if isCurrentStepValid {
                currentStep = .customization
            }
        case .customization:
            validateCustomization()
            if validationErrors.isEmpty {
                currentStep = .review
            }
        case .review:
            break // Final step
        }
    }
    
    /// Go back to previous step
    func previousStep() {
        switch currentStep {
        case .sourceTask:
            break // First step
        case .naming:
            currentStep = .sourceTask
        case .customization:
            currentStep = .naming
        case .review:
            currentStep = .customization
        }
    }
    
    /// Extract placeholders from source task
    private func extractPlaceholders() {
        guard let task = sourceTask else { return }
        
        let template = TaskTemplate(
            name: "temp",
            taskStructure: task,
            customizableFields: []
        )
        
        let result = TemplateUtilities.validateTemplate(template)
        // Extract placeholders that were found but not declared
        detectedPlaceholders = Set(result.errors.compactMap { error in
            if error.contains("Placeholder '{{") && error.contains("}}' found") {
                let start = error.range(of: "{{")?.upperBound
                let end = error.range(of: "}}")?.lowerBound
                if let start = start, let end = end, start < end {
                    return String(error[start..<end])
                }
            }
            return nil
        })
    }
    
    /// Validate current customization settings
    private func validateCustomization() {
        guard let template = finalTemplate else {
            validationErrors = ["Cannot create template"]
            return
        }
        
        let result = TemplateUtilities.validateTemplate(template)
        validationErrors = result.errors
    }
    
    /// Reset wizard to initial state
    func reset() {
        currentStep = .sourceTask
        sourceTask = nil
        templateName = ""
        selectedCategory = nil
        detectedPlaceholders = []
        customizableFields = []
        validationErrors = []
    }
}

enum CreationStep: CaseIterable {
    case sourceTask
    case naming
    case customization
    case review
    
    var title: String {
        switch self {
        case .sourceTask: return "Select Source Task"
        case .naming: return "Name Template"
        case .customization: return "Configure Fields"
        case .review: return "Review & Create"
        }
    }
    
    var description: String {
        switch self {
        case .sourceTask: return "Choose a task to use as the template basis"
        case .naming: return "Give your template a descriptive name and category"
        case .customization: return "Configure which fields can be customized"
        case .review: return "Review your template and create it"
        }
    }
}

// MARK: - Template Instantiation Pattern

/// Pattern for guided template instantiation with customization
@MainActor
class TemplateInstantiationPattern: ObservableObject {
    @Published var selectedTemplate: TaskTemplate?
    @Published var customizations: [String: String] = [:]
    @Published var previewTask: TaskItem?
    @Published var validationErrors: [String] = []
    
    /// Whether instantiation is ready
    var canInstantiate: Bool {
        selectedTemplate != nil && validationErrors.isEmpty
    }
    
    /// Set template and initialize customizations
    func setTemplate(_ template: TaskTemplate) {
        selectedTemplate = template
        
        // Initialize customizations with empty values
        customizations = Dictionary(uniqueKeysWithValues: 
            template.customizableFields.map { ($0, "") }
        )
        
        updatePreview()
    }
    
    /// Update customization value
    func updateCustomization(field: String, value: String) {
        customizations[field] = value
        updatePreview()
        validateCustomizations()
    }
    
    /// Generate preview of instantiated task
    private func updatePreview() {
        guard let template = selectedTemplate else {
            previewTask = nil
            return
        }
        
        previewTask = template.instantiate(customizations: customizations)
    }
    
    /// Validate current customization values
    private func validateCustomizations() {
        validationErrors = []
        
        guard let template = selectedTemplate else {
            validationErrors.append("No template selected")
            return
        }
        
        // Check for required fields (those with empty values)
        for field in template.customizableFields {
            if customizations[field]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
                validationErrors.append("Field '\(field)' is required")
            }
        }
    }
    
    /// Create final task from template
    func instantiate() -> TaskItem? {
        guard canInstantiate,
              let template = selectedTemplate else { return nil }
        
        return template.instantiate(customizations: customizations)
    }
    
    /// Reset pattern to initial state
    func reset() {
        selectedTemplate = nil
        customizations = [:]
        previewTask = nil
        validationErrors = []
    }
}