import Foundation
import Axiom

/// Task model conforming to Axiom's State protocol
struct TaskItem: State, Codable {
    let id: UUID
    let title: String
    let description: String?
    let categoryId: UUID?
    let priority: Priority
    let isCompleted: Bool
    let createdAt: Date
    let updatedAt: Date
    let dueDate: Date?
    
    // REQ-010: Subtasks and Dependencies
    let parentId: UUID?
    let subtasks: [TaskItem]
    let dependencies: Set<UUID>
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        categoryId: UUID? = nil,
        priority: Priority = .medium,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        dueDate: Date? = nil,
        parentId: UUID? = nil,
        subtasks: [TaskItem] = [],
        dependencies: Set<UUID> = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.categoryId = categoryId
        self.priority = priority
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.dueDate = dueDate
        self.parentId = parentId
        self.subtasks = subtasks
        self.dependencies = dependencies
    }
}

// MARK: - Due Date Computed Properties

extension TaskItem {
    /// Check if task is overdue
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        
        // Task is overdue if due date has passed with a small grace period
        // Grace period of 60 seconds to handle "due now" scenarios
        let gracePeriod: TimeInterval = 60
        return dueDate.addingTimeInterval(gracePeriod) < Date()
    }
    
    /// Formatted due date for display
    var formattedDueDate: String {
        guard let dueDate = dueDate else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }
    
    /// Relative due date string (e.g., "Tomorrow", "In 2 hours")
    var relativeDueDate: String {
        guard let dueDate = dueDate else { return "" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: dueDate, relativeTo: Date())
    }
    
    /// Overdue level based on priority
    var overdueLevel: OverdueLevel {
        guard isOverdue else { return .none }
        
        switch priority {
        case .critical: return .critical
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        }
    }
    
    /// Severity of how overdue the task is
    var overdueSeverity: OverdueSeverity {
        guard let dueDate = dueDate, isOverdue else { return .none }
        
        let hoursOverdue = Date().timeIntervalSince(dueDate) / 3600
        
        if hoursOverdue > 24 {
            return .severe
        } else if hoursOverdue > 8 {
            return .moderate
        } else if hoursOverdue > 1 {
            return .mild
        } else {
            return .recent
        }
    }
    
    /// Whether to show overdue indicator in UI
    var shouldShowOverdueIndicator: Bool {
        isOverdue && !isCompleted
    }
}

// MARK: - Overdue Types

enum OverdueLevel: Equatable {
    case none, low, medium, high, critical
}

enum OverdueSeverity: Equatable {
    case none, recent, mild, moderate, severe
}

// MARK: - Subtask and Dependency Computed Properties

extension TaskItem {
    /// Completion percentage based on subtasks
    var completionPercentage: Double {
        guard !subtasks.isEmpty else {
            return isCompleted ? 100.0 : 0.0
        }
        
        let completedCount = subtasks.filter { $0.isCompleted }.count
        return (Double(completedCount) / Double(subtasks.count)) * 100.0
    }
    
    /// Whether this task has any subtasks
    var hasSubtasks: Bool {
        !subtasks.isEmpty
    }
    
    /// Whether this task has any dependencies
    var hasDependencies: Bool {
        !dependencies.isEmpty
    }
    
    /// Flattened list of all subtasks (including nested)
    var allSubtasks: [TaskItem] {
        var result: [TaskItem] = []
        
        func collectSubtasks(_ task: TaskItem) {
            result.append(contentsOf: task.subtasks)
            for subtask in task.subtasks {
                collectSubtasks(subtask)
            }
        }
        
        collectSubtasks(self)
        return result
    }
    
    /// Total count of all nested subtasks
    var totalSubtaskCount: Int {
        subtasks.count + subtasks.reduce(0) { $0 + $1.totalSubtaskCount }
    }
    
    /// Depth of the deepest subtask hierarchy
    var maxDepth: Int {
        guard !subtasks.isEmpty else { return 0 }
        return 1 + (subtasks.map { $0.maxDepth }.max() ?? 0)
    }
}

// MARK: - Type Alias for Compatibility

// Using TaskModel to avoid conflict with Swift's Task type
typealias TaskModel = TaskItem