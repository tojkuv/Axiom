import Foundation

/// Utilities for template operations and performance optimization
/// REQ-011: Task Templates - REFACTOR phase extraction
struct TemplateUtilities {
    
    // MARK: - Template Validation
    
    /// Validate template structure and customizable fields
    static func validateTemplate(_ template: TaskTemplate) -> ValidationResult {
        var errors: [String] = []
        
        // Check name is not empty
        if template.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Template name cannot be empty")
        }
        
        // Validate customizable fields have corresponding placeholders
        let taskText = extractAllText(from: template.taskStructure)
        let detectedPlaceholders = extractPlaceholders(from: taskText)
        
        for field in template.customizableFields {
            if !detectedPlaceholders.contains(field) {
                errors.append("Customizable field '\(field)' has no corresponding placeholder in template text")
            }
        }
        
        // Check for orphaned placeholders
        let orphanedPlaceholders = detectedPlaceholders.subtracting(Set(template.customizableFields))
        for placeholder in orphanedPlaceholders {
            errors.append("Placeholder '{{\(placeholder)}}' found but not declared as customizable field")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    /// Extract all text content from a task item and its subtasks
    private static func extractAllText(from taskItem: TaskItem) -> String {
        var text = "\(taskItem.title) \(taskItem.description ?? "")"
        
        for subtask in taskItem.subtasks {
            text += " \(extractAllText(from: subtask))"
        }
        
        return text
    }
    
    /// Extract placeholder patterns like {{FIELD}} from text
    private static func extractPlaceholders(from text: String) -> Set<String> {
        let pattern = #"\{\{([A-Z_]+)\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return Set(matches.compactMap { match in
            if let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
            return nil
        })
    }
    
    // MARK: - Performance Optimization
    
    /// Optimized template instantiation with minimal state operations
    static func instantiateTemplateOptimized(
        _ template: TaskTemplate,
        customizations: [String: String] = [:]
    ) -> TaskItem {
        // Pre-compile customization mappings for performance
        let compiledCustomizations = compileCustomizations(customizations)
        
        return instantiateTaskItemOptimized(template.taskStructure, customizations: compiledCustomizations)
    }
    
    /// Compile customizations into efficient lookup structure
    private static func compileCustomizations(_ customizations: [String: String]) -> [(pattern: String, replacement: String)] {
        return customizations.map { (key, value) in
            (pattern: "{{\(key)}}", replacement: value)
        }
    }
    
    /// Optimized recursive task instantiation
    private static func instantiateTaskItemOptimized(
        _ taskItem: TaskItem,
        customizations: [(pattern: String, replacement: String)]
    ) -> TaskItem {
        let instantiatedTitle = applyCustomizationsOptimized(to: taskItem.title, customizations: customizations)
        let instantiatedDescription = taskItem.description.map { 
            applyCustomizationsOptimized(to: $0, customizations: customizations) 
        }
        
        // Use lazy evaluation for subtasks to avoid unnecessary processing
        let instantiatedSubtasks: [TaskItem] = {
            return taskItem.subtasks.map { subtask in
                instantiateTaskItemOptimized(subtask, customizations: customizations)
            }
        }()
        
        return TaskItem(
            title: instantiatedTitle,
            description: instantiatedDescription,
            categoryId: taskItem.categoryId,
            priority: taskItem.priority,
            isCompleted: false,
            dueDate: taskItem.dueDate,
            subtasks: instantiatedSubtasks,
            dependencies: [] // Dependencies not carried over
        )
    }
    
    /// Optimized string replacement using compiled patterns
    private static func applyCustomizationsOptimized(
        to text: String,
        customizations: [(pattern: String, replacement: String)]
    ) -> String {
        var result = text
        for (pattern, replacement) in customizations {
            result = result.replacingOccurrences(of: pattern, with: replacement)
        }
        return result
    }
    
    // MARK: - Template Analysis
    
    /// Analyze template complexity for performance warnings
    static func analyzeComplexity(_ template: TaskTemplate) -> ComplexityAnalysis {
        let taskCount = countTotalTasks(template.taskStructure)
        let maxDepth = calculateMaxDepth(template.taskStructure)
        let placeholderCount = template.customizableFields.count
        
        var warnings: [String] = []
        var suggestions: [String] = []
        
        // Performance thresholds based on framework limitations
        if taskCount > 50 {
            warnings.append("High task count (\(taskCount)) may impact instantiation performance")
            suggestions.append("Consider breaking down into smaller templates")
        }
        
        if maxDepth > 5 {
            warnings.append("Deep nesting (\(maxDepth) levels) may slow rendering")
            suggestions.append("Flatten hierarchy where possible")
        }
        
        if placeholderCount > 10 {
            warnings.append("Many customizable fields (\(placeholderCount)) increases complexity")
            suggestions.append("Group related fields or use fewer variables")
        }
        
        let complexityScore = calculateComplexityScore(taskCount: taskCount, maxDepth: maxDepth, placeholderCount: placeholderCount)
        
        return ComplexityAnalysis(
            taskCount: taskCount,
            maxDepth: maxDepth,
            placeholderCount: placeholderCount,
            complexityScore: complexityScore,
            warnings: warnings,
            suggestions: suggestions
        )
    }
    
    /// Count total tasks including nested subtasks
    private static func countTotalTasks(_ taskItem: TaskItem) -> Int {
        return 1 + taskItem.subtasks.reduce(0) { $0 + countTotalTasks($1) }
    }
    
    /// Calculate maximum nesting depth
    private static func calculateMaxDepth(_ taskItem: TaskItem) -> Int {
        guard !taskItem.subtasks.isEmpty else { return 1 }
        return 1 + (taskItem.subtasks.map { calculateMaxDepth($0) }.max() ?? 0)
    }
    
    /// Calculate complexity score for performance prediction
    private static func calculateComplexityScore(taskCount: Int, maxDepth: Int, placeholderCount: Int) -> Int {
        // Weighted complexity calculation
        return (taskCount * 2) + (maxDepth * 5) + (placeholderCount * 1)
    }
    
    // MARK: - Template Categories
    
    /// Standard template categories for organization
    static let standardCategories = [
        "Development",
        "Testing",
        "Documentation", 
        "Meetings",
        "Planning",
        "Maintenance",
        "Personal",
        "General"
    ]
    
    /// Suggest category based on template content
    static func suggestCategory(for template: TaskTemplate) -> String? {
        let content = extractAllText(from: template.taskStructure).lowercased()
        let words = content.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
        
        // Use word boundaries for more accurate matching
        // Order matters: check more specific categories first
        if words.contains(where: { ["test", "testing", "qa", "bug", "unit", "integration"].contains($0) }) {
            return "Testing"
        } else if words.contains(where: { ["plan", "planning", "sprint", "roadmap", "schedule"].contains($0) }) {
            return "Planning"
        } else if words.contains(where: { ["doc", "documentation", "write", "readme", "document"].contains($0) }) {
            return "Documentation"
        } else if words.contains(where: { ["code", "coding", "implement", "implementation", "develop", "development", "feature"].contains($0) }) {
            return "Development"
        } else if words.contains(where: { ["meeting", "meet", "standup", "review", "session"].contains($0) }) {
            return "Meetings"
        }
        
        return "General"
    }
}

// MARK: - Supporting Types

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
}

struct ComplexityAnalysis {
    let taskCount: Int
    let maxDepth: Int
    let placeholderCount: Int
    let complexityScore: Int
    let warnings: [String]
    let suggestions: [String]
    
    var performanceLevel: TemplatePerformanceLevel {
        switch complexityScore {
        case 0...20: return .excellent
        case 21...50: return .good
        case 51...100: return .moderate
        default: return .poor
        }
    }
}

enum TemplatePerformanceLevel {
    case excellent, good, moderate, poor
    
    var description: String {
        switch self {
        case .excellent: return "Excellent - Fast instantiation expected"
        case .good: return "Good - Normal performance expected"
        case .moderate: return "Moderate - May notice slight delays"
        case .poor: return "Poor - Consider simplifying template"
        }
    }
}