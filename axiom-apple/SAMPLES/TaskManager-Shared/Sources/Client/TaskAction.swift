import Foundation
import Axiom

// MARK: - Task Actions

/// Actions that can be performed on tasks in the task manager
public enum TaskAction: Sendable, Equatable {
    // MARK: - Task CRUD Operations
    case createTask(CreateTaskData)
    case updateTask(taskId: UUID, updates: TaskUpdate)
    case deleteTask(taskId: UUID)
    case toggleTaskCompletion(taskId: UUID)
    case duplicateTask(taskId: UUID)
    
    // MARK: - Bulk Operations
    case createMultipleTasks([CreateTaskData])
    case deleteTasks(taskIds: [UUID])
    case completeAllTasks
    case deleteCompletedTasks
    case markTasksAsCompleted(taskIds: [UUID])
    case updateTasksCategory(taskIds: [UUID], category: Category)
    case updateTasksPriority(taskIds: [UUID], priority: Priority)
    
    // MARK: - Filtering and Sorting
    case setFilter(Task.Filter)
    case setCategoryFilter(Category?)
    case setSortOrder(Task.SortOrder, ascending: Bool)
    case setSearchQuery(String)
    case clearFilters
    case toggleSortDirection
    
    // MARK: - Data Management
    case loadTasks
    case saveTasks
    case importTasks([Task])
    case exportTasks
    case syncTasks
    case clearAllTasks
    
    // MARK: - Undo/Redo Support
    case undo
    case redo
    case saveStateSnapshot
}

// MARK: - Supporting Data Types

/// Data required to create a new task
public struct CreateTaskData: Sendable, Equatable, Codable {
    public let title: String
    public let taskDescription: String
    public let priority: Priority
    public let category: Category
    public let dueDate: Date?
    public let tags: Set<String>
    public let notes: String
    public let reminderTime: Date?
    
    public init(
        title: String,
        taskDescription: String = "",
        priority: Priority = .medium,
        category: Category = .personal,
        dueDate: Date? = nil,
        tags: Set<String> = [],
        notes: String = "",
        reminderTime: Date? = nil
    ) {
        self.title = title
        self.taskDescription = taskDescription
        self.priority = priority
        self.category = category
        self.dueDate = dueDate
        self.tags = tags
        self.notes = notes
        self.reminderTime = reminderTime
    }
    
    /// Convert to a Task with generated ID and timestamps
    public func toTask() -> Task {
        Task(
            title: title,
            taskDescription: taskDescription,
            priority: priority,
            category: category,
            dueDate: dueDate,
            tags: tags,
            notes: notes,
            reminderTime: reminderTime
        )
    }
}

/// Updates that can be applied to an existing task
public struct TaskUpdate: Sendable, Equatable, Codable {
    public let title: String?
    public let taskDescription: String?
    public let priority: Priority?
    public let category: Category?
    public let dueDate: Date??  // Double optional to distinguish between "don't change" and "set to nil"
    public let tags: Set<String>?
    public let notes: String?
    public let reminderTime: Date??
    public let isCompleted: Bool?
    
    public init(
        title: String? = nil,
        taskDescription: String? = nil,
        priority: Priority? = nil,
        category: Category? = nil,
        dueDate: Date?? = nil,
        tags: Set<String>? = nil,
        notes: String? = nil,
        reminderTime: Date?? = nil,
        isCompleted: Bool? = nil
    ) {
        self.title = title
        self.taskDescription = taskDescription
        self.priority = priority
        self.category = category
        self.dueDate = dueDate
        self.tags = tags
        self.notes = notes
        self.reminderTime = reminderTime
        self.isCompleted = isCompleted
    }
    
    /// Apply the updates to a task
    public func apply(to task: Task) -> Task {
        var updatedTask = task
        
        if let title = title {
            updatedTask = updatedTask.withTitle(title)
        }
        
        if let taskDescription = taskDescription {
            updatedTask = updatedTask.withDescription(taskDescription)
        }
        
        if let priority = priority {
            updatedTask = updatedTask.withPriority(priority)
        }
        
        if let category = category {
            updatedTask = updatedTask.withCategory(category)
        }
        
        if let dueDate = dueDate {
            updatedTask = updatedTask.withDueDate(dueDate)
        }
        
        if let tags = tags {
            updatedTask = updatedTask.withTags(tags)
        }
        
        if let notes = notes {
            updatedTask = updatedTask.withNotes(notes)
        }
        
        if let reminderTime = reminderTime {
            updatedTask = updatedTask.withReminderTime(reminderTime)
        }
        
        if let isCompleted = isCompleted {
            updatedTask = updatedTask.withCompletion(isCompleted)
        }
        
        return updatedTask
    }
    
    /// Check if any updates are specified
    public var hasUpdates: Bool {
        title != nil || 
        taskDescription != nil || 
        priority != nil || 
        category != nil || 
        dueDate != nil || 
        tags != nil || 
        notes != nil ||
        reminderTime != nil ||
        isCompleted != nil
    }
}

// MARK: - Action Validation

extension TaskAction {
    /// Validates that the action data is valid
    public var isValid: Bool {
        switch self {
        case .createTask(let data):
            return !data.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
        case .updateTask(_, let updates):
            return updates.hasUpdates
            
        case .createMultipleTasks(let taskDataArray):
            return !taskDataArray.isEmpty && taskDataArray.allSatisfy { 
                !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
            }
            
        case .deleteTasks(let taskIds), .markTasksAsCompleted(let taskIds), 
             .updateTasksCategory(let taskIds, _), .updateTasksPriority(let taskIds, _):
            return !taskIds.isEmpty
            
        case .importTasks(let tasks):
            return !tasks.isEmpty && tasks.allSatisfy { $0.isValid }
            
        default:
            return true
        }
    }
    
    /// Returns validation errors if any
    public var validationErrors: [String] {
        var errors: [String] = []
        
        switch self {
        case .createTask(let data):
            if data.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append("Task title cannot be empty")
            }
            
        case .updateTask(_, let updates):
            if !updates.hasUpdates {
                errors.append("No updates specified")
            }
            
        case .createMultipleTasks(let taskDataArray):
            if taskDataArray.isEmpty {
                errors.append("No tasks to create")
            }
            for (index, data) in taskDataArray.enumerated() {
                if data.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    errors.append("Task \(index + 1) title cannot be empty")
                }
            }
            
        case .deleteTasks(let taskIds), .markTasksAsCompleted(let taskIds), 
             .updateTasksCategory(let taskIds, _), .updateTasksPriority(let taskIds, _):
            if taskIds.isEmpty {
                errors.append("No task IDs specified")
            }
            
        case .importTasks(let tasks):
            if tasks.isEmpty {
                errors.append("No tasks to import")
            }
            for (index, task) in tasks.enumerated() {
                let taskErrors = task.validationErrors
                if !taskErrors.isEmpty {
                    errors.append("Task \(index + 1): \(taskErrors.joined(separator: ", "))")
                }
            }
            
        default:
            break
        }
        
        return errors
    }
}

// MARK: - Action Descriptions

extension TaskAction {
    /// Human-readable description of the action
    public var description: String {
        switch self {
        case .createTask(let data):
            return "Create task: \(data.title)"
        case .updateTask(let taskId, _):
            return "Update task: \(taskId)"
        case .deleteTask(let taskId):
            return "Delete task: \(taskId)"
        case .toggleTaskCompletion(let taskId):
            return "Toggle completion for task: \(taskId)"
        case .duplicateTask(let taskId):
            return "Duplicate task: \(taskId)"
        case .createMultipleTasks(let taskDataArray):
            return "Create \(taskDataArray.count) tasks"
        case .deleteTasks(let taskIds):
            return "Delete \(taskIds.count) tasks"
        case .completeAllTasks:
            return "Complete all tasks"
        case .deleteCompletedTasks:
            return "Delete completed tasks"
        case .markTasksAsCompleted(let taskIds):
            return "Mark \(taskIds.count) tasks as completed"
        case .updateTasksCategory(let taskIds, let category):
            return "Update \(taskIds.count) tasks to category: \(category.displayName)"
        case .updateTasksPriority(let taskIds, let priority):
            return "Update \(taskIds.count) tasks to priority: \(priority.displayName)"
        case .setFilter(let filter):
            return "Set filter: \(filter.displayName)"
        case .setCategoryFilter(let category):
            return "Set category filter: \(category?.displayName ?? "All")"
        case .setSortOrder(let sortOrder, let ascending):
            return "Set sort order: \(sortOrder.displayName) (\(ascending ? "ascending" : "descending"))"
        case .setSearchQuery(let query):
            return "Set search query: \(query)"
        case .clearFilters:
            return "Clear all filters"
        case .toggleSortDirection:
            return "Toggle sort direction"
        case .loadTasks:
            return "Load tasks"
        case .saveTasks:
            return "Save tasks"
        case .importTasks(let tasks):
            return "Import \(tasks.count) tasks"
        case .exportTasks:
            return "Export tasks"
        case .syncTasks:
            return "Sync tasks"
        case .clearAllTasks:
            return "Clear all tasks"
        case .undo:
            return "Undo"
        case .redo:
            return "Redo"
        case .saveStateSnapshot:
            return "Save state snapshot"
        }
    }
    
    /// Short description suitable for logging
    public var logDescription: String {
        switch self {
        case .createTask:
            return "CREATE_TASK"
        case .updateTask:
            return "UPDATE_TASK"
        case .deleteTask:
            return "DELETE_TASK"
        case .toggleTaskCompletion:
            return "TOGGLE_COMPLETION"
        case .duplicateTask:
            return "DUPLICATE_TASK"
        case .createMultipleTasks:
            return "CREATE_MULTIPLE_TASKS"
        case .deleteTasks:
            return "DELETE_TASKS"
        case .completeAllTasks:
            return "COMPLETE_ALL_TASKS"
        case .deleteCompletedTasks:
            return "DELETE_COMPLETED_TASKS"
        case .markTasksAsCompleted:
            return "MARK_TASKS_COMPLETED"
        case .updateTasksCategory:
            return "UPDATE_TASKS_CATEGORY"
        case .updateTasksPriority:
            return "UPDATE_TASKS_PRIORITY"
        case .setFilter:
            return "SET_FILTER"
        case .setCategoryFilter:
            return "SET_CATEGORY_FILTER"
        case .setSortOrder:
            return "SET_SORT_ORDER"
        case .setSearchQuery:
            return "SET_SEARCH_QUERY"
        case .clearFilters:
            return "CLEAR_FILTERS"
        case .toggleSortDirection:
            return "TOGGLE_SORT_DIRECTION"
        case .loadTasks:
            return "LOAD_TASKS"
        case .saveTasks:
            return "SAVE_TASKS"
        case .importTasks:
            return "IMPORT_TASKS"
        case .exportTasks:
            return "EXPORT_TASKS"
        case .syncTasks:
            return "SYNC_TASKS"
        case .clearAllTasks:
            return "CLEAR_ALL_TASKS"
        case .undo:
            return "UNDO"
        case .redo:
            return "REDO"
        case .saveStateSnapshot:
            return "SAVE_STATE_SNAPSHOT"
        }
    }
}