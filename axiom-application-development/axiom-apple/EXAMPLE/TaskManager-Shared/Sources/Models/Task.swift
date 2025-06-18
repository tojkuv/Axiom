import Foundation
import Axiom

// MARK: - Task Model

/// Represents a task in the task manager application
public struct Task: AxiomState, Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let taskDescription: String
    public let priority: Priority
    public let category: Category
    public let isCompleted: Bool
    public let createdAt: Date
    public let completedAt: Date?
    public let dueDate: Date?
    public let tags: Set<String>
    public let notes: String
    public let reminderTime: Date?
    
    public init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String = "",
        priority: Priority = .medium,
        category: Category = .personal,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        dueDate: Date? = nil,
        tags: Set<String> = [],
        notes: String = "",
        reminderTime: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.priority = priority
        self.category = category
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.tags = tags
        self.notes = notes
        self.reminderTime = reminderTime
    }
}

// MARK: - Task State Mutations

extension Task {
    /// Create a new task with updated title
    public func withTitle(_ newTitle: String) -> Task {
        Task(
            id: id,
            title: newTitle,
            taskDescription: taskDescription,
            priority: priority,
            category: category,
            isCompleted: isCompleted,
            createdAt: createdAt,
            completedAt: completedAt,
            dueDate: dueDate,
            tags: tags,
            notes: notes,
            reminderTime: reminderTime
        )
    }
    
    /// Create a new task with updated description
    public func withDescription(_ newDescription: String) -> Task {
        Task(
            id: id,
            title: title,
            taskDescription: newDescription,
            priority: priority,
            category: category,
            isCompleted: isCompleted,
            createdAt: createdAt,
            completedAt: completedAt,
            dueDate: dueDate,
            tags: tags,
            notes: notes,
            reminderTime: reminderTime
        )
    }
    
    /// Create a new task with updated priority
    public func withPriority(_ newPriority: Priority) -> Task {
        Task(
            id: id,
            title: title,
            taskDescription: taskDescription,
            priority: newPriority,
            category: category,
            isCompleted: isCompleted,
            createdAt: createdAt,
            completedAt: completedAt,
            dueDate: dueDate,
            tags: tags,
            notes: notes,
            reminderTime: reminderTime
        )
    }
    
    /// Create a new task with updated category
    public func withCategory(_ newCategory: Category) -> Task {
        Task(
            id: id,
            title: title,
            taskDescription: taskDescription,
            priority: priority,
            category: newCategory,
            isCompleted: isCompleted,
            createdAt: createdAt,
            completedAt: completedAt,
            dueDate: dueDate,
            tags: tags,
            notes: notes,
            reminderTime: reminderTime
        )
    }
    
    /// Create a new task with updated completion status
    public func withCompletion(_ completed: Bool) -> Task {
        Task(
            id: id,
            title: title,
            taskDescription: taskDescription,
            priority: priority,
            category: category,
            isCompleted: completed,
            createdAt: createdAt,
            completedAt: completed ? Date() : nil,
            dueDate: dueDate,
            tags: tags,
            notes: notes,
            reminderTime: reminderTime
        )
    }
    
    /// Create a new task with updated due date
    public func withDueDate(_ newDueDate: Date?) -> Task {
        Task(
            id: id,
            title: title,
            taskDescription: taskDescription,
            priority: priority,
            category: category,
            isCompleted: isCompleted,
            createdAt: createdAt,
            completedAt: completedAt,
            dueDate: newDueDate,
            tags: tags,
            notes: notes,
            reminderTime: reminderTime
        )
    }
    
    /// Create a new task with updated tags
    public func withTags(_ newTags: Set<String>) -> Task {
        Task(
            id: id,
            title: title,
            taskDescription: taskDescription,
            priority: priority,
            category: category,
            isCompleted: isCompleted,
            createdAt: createdAt,
            completedAt: completedAt,
            dueDate: dueDate,
            tags: newTags,
            notes: notes,
            reminderTime: reminderTime
        )
    }
    
    /// Create a new task by adding a tag
    public func addingTag(_ tag: String) -> Task {
        var newTags = tags
        newTags.insert(tag)
        return withTags(newTags)
    }
    
    /// Create a new task by removing a tag
    public func removingTag(_ tag: String) -> Task {
        var newTags = tags
        newTags.remove(tag)
        return withTags(newTags)
    }
    
    /// Create a new task with updated notes
    public func withNotes(_ newNotes: String) -> Task {
        Task(
            id: id,
            title: title,
            taskDescription: taskDescription,
            priority: priority,
            category: category,
            isCompleted: isCompleted,
            createdAt: createdAt,
            completedAt: completedAt,
            dueDate: dueDate,
            tags: tags,
            notes: newNotes,
            reminderTime: reminderTime
        )
    }
    
    /// Create a new task with updated reminder time
    public func withReminderTime(_ newReminderTime: Date?) -> Task {
        Task(
            id: id,
            title: title,
            taskDescription: taskDescription,
            priority: priority,
            category: category,
            isCompleted: isCompleted,
            createdAt: createdAt,
            completedAt: completedAt,
            dueDate: dueDate,
            tags: tags,
            notes: notes,
            reminderTime: newReminderTime
        )
    }
}

// MARK: - Task Computed Properties

extension Task {
    /// Whether the task is overdue
    public var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }
    
    /// Days remaining until due date
    public var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day
    }
    
    /// Whether the task is due today
    public var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDate(dueDate, inSameDayAs: Date())
    }
    
    /// Whether the task is due this week
    public var isDueThisWeek: Bool {
        guard let dueDate = dueDate else { return false }
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
        return dueDate >= startOfWeek && dueDate <= endOfWeek
    }
    
    /// Whether the task has notes
    public var hasNotes: Bool {
        !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Whether the task has a reminder set
    public var hasReminder: Bool {
        reminderTime != nil
    }
    
    /// Human-readable due date description
    public var dueDateDescription: String? {
        guard let dueDate = dueDate else { return nil }
        
        if isDueToday {
            return "Due today"
        } else if isOverdue {
            let formatter = RelativeDateTimeFormatter()
            return "Overdue \(formatter.localizedString(for: dueDate, relativeTo: Date()))"
        } else if isDueThisWeek {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "Due \(formatter.string(from: dueDate))"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Due \(formatter.string(from: dueDate))"
        }
    }
}

// MARK: - Task Validation

extension Task {
    /// Validates the task data
    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns validation errors if any
    public var validationErrors: [String] {
        var errors: [String] = []
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Title cannot be empty")
        }
        
        if let dueDate = dueDate, dueDate < createdAt {
            errors.append("Due date cannot be before creation date")
        }
        
        if isCompleted && completedAt == nil {
            errors.append("Completed tasks must have a completion date")
        }
        
        if !isCompleted && completedAt != nil {
            errors.append("Incomplete tasks cannot have a completion date")
        }
        
        return errors
    }
}

// MARK: - Task Sorting and Filtering

extension Task {
    /// Sort descriptor for tasks
    public enum SortOrder: String, CaseIterable, Codable, Sendable {
        case createdDate = "createdDate"
        case dueDate = "dueDate"
        case priority = "priority"
        case title = "title"
        case completion = "completion"
        
        public var displayName: String {
            switch self {
            case .createdDate: return "Created Date"
            case .dueDate: return "Due Date"
            case .priority: return "Priority"
            case .title: return "Title"
            case .completion: return "Completion"
            }
        }
    }
    
    /// Filter options for tasks
    public enum Filter: String, CaseIterable, Codable, Sendable {
        case all = "all"
        case pending = "pending"
        case completed = "completed"
        case overdue = "overdue"
        case dueToday = "dueToday"
        case dueThisWeek = "dueThisWeek"
        
        public var displayName: String {
            switch self {
            case .all: return "All Tasks"
            case .pending: return "Pending"
            case .completed: return "Completed"
            case .overdue: return "Overdue"
            case .dueToday: return "Due Today"
            case .dueThisWeek: return "Due This Week"
            }
        }
        
        /// Check if a task matches this filter
        public func matches(_ task: Task) -> Bool {
            switch self {
            case .all: return true
            case .pending: return !task.isCompleted
            case .completed: return task.isCompleted
            case .overdue: return task.isOverdue
            case .dueToday: return task.isDueToday
            case .dueThisWeek: return task.isDueThisWeek
            }
        }
    }
}

// MARK: - Task Search

extension Task {
    /// Check if the task matches a search query
    public func matches(searchQuery: String) -> Bool {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return true
        }
        
        let query = searchQuery.lowercased()
        
        return title.lowercased().contains(query) ||
               taskDescription.lowercased().contains(query) ||
               category.displayName.lowercased().contains(query) ||
               priority.displayName.lowercased().contains(query) ||
               tags.contains { $0.lowercased().contains(query) }
    }
}