import Foundation
import Axiom

// REQ-013: Filter type for keyboard navigation
enum FilterType {
    case all
    case search
    case category
    case dueDate
}

/// Application state for task management
struct TaskState: State {
    let tasks: [TaskItem]
    let categories: [Category]
    let filter: TaskFilter?
    let isLoading: Bool
    let error: TaskError?
    
    // REQ-011: Task Templates
    let templates: [TaskTemplate]
    let templateSearchQuery: String
    
    // REQ-012: Bulk Operations
    let selectedTaskIds: Set<UUID>
    let batchOperationProgress: Double?
    let isBatchOperationInProgress: Bool
    
    // REQ-013: Keyboard Navigation
    let isCreateTaskModalPresented: Bool
    let showingDeleteConfirmation: Bool
    let deleteConfirmationTaskId: UUID?
    let editingTaskId: UUID?
    let isSearchActive: Bool
    
    init(
        tasks: [TaskItem] = [],
        categories: [Category] = Category.defaultCategories,
        filter: TaskFilter? = TaskFilter.default,
        isLoading: Bool = false,
        error: TaskError? = nil,
        templates: [TaskTemplate] = [],
        templateSearchQuery: String = "",
        selectedTaskIds: Set<UUID> = [],
        batchOperationProgress: Double? = nil,
        isBatchOperationInProgress: Bool = false,
        isCreateTaskModalPresented: Bool = false,
        showingDeleteConfirmation: Bool = false,
        deleteConfirmationTaskId: UUID? = nil,
        editingTaskId: UUID? = nil,
        isSearchActive: Bool = false
    ) {
        self.tasks = tasks
        self.categories = categories
        self.filter = filter
        self.isLoading = isLoading
        self.error = error
        self.templates = templates
        self.templateSearchQuery = templateSearchQuery
        self.selectedTaskIds = selectedTaskIds
        self.batchOperationProgress = batchOperationProgress
        self.isBatchOperationInProgress = isBatchOperationInProgress
        self.isCreateTaskModalPresented = isCreateTaskModalPresented
        self.showingDeleteConfirmation = showingDeleteConfirmation
        self.deleteConfirmationTaskId = deleteConfirmationTaskId
        self.editingTaskId = editingTaskId
        self.isSearchActive = isSearchActive
    }
}

/// Task-specific errors
enum TaskError: Error, Equatable, Hashable, LocalizedError {
    case taskNotFound(UUID)
    case invalidTaskData
    case persistenceFailed(String)
    
    // REQ-010: Subtasks and Dependencies
    case circularDependencyDetected([UUID])
    case incompletePrerequisites([UUID])
    case subtaskNotFound(UUID)
    case invalidParentTask(UUID)
    
    // REQ-011: Task Templates
    case templateNotFound(UUID)
    case duplicateTemplateName(String)
    case invalidTemplateStructure
    case templateInstantiationFailed(String)
    
    // REQ-012: Bulk Operations
    case noTasksSelected
    case batchOperationInProgress
    
    var errorDescription: String? {
        switch self {
        case .taskNotFound:
            return "Task not found"
        case .invalidTaskData:
            return "Invalid task data"
        case .persistenceFailed(let message):
            return "Save failed: \(message)"
        case .circularDependencyDetected(let cycle):
            return "Circular dependency detected involving \(cycle.count) tasks"
        case .incompletePrerequisites(let prerequisites):
            return "Cannot complete task: \(prerequisites.count) incomplete prerequisites"
        case .subtaskNotFound(let id):
            return "Subtask not found: \(id)"
        case .invalidParentTask(let id):
            return "Invalid parent task: \(id)"
        case .templateNotFound(let id):
            return "Template not found: \(id)"
        case .duplicateTemplateName(let name):
            return "Template name already exists: \(name)"
        case .invalidTemplateStructure:
            return "Invalid template structure"
        case .templateInstantiationFailed(let reason):
            return "Template instantiation failed: \(reason)"
        case .noTasksSelected:
            return "No tasks selected for bulk operation"
        case .batchOperationInProgress:
            return "Another batch operation is already in progress"
        }
    }
}

// MARK: - Computed Properties

extension TaskState {
    /// Current search query
    var searchQuery: String {
        filter?.searchQuery ?? ""
    }
    
    // REQ-013: Keyboard Navigation - Computed properties
    var activeFilter: FilterType {
        guard let filter = filter else { return .all }
        
        if !filter.searchQuery.isEmpty {
            return .search
        } else if !filter.selectedCategories.isEmpty {
            return .category
        } else if filter.dueDateFilter != .all {
            return .dueDate
        } else {
            return .all
        }
    }
    
    // REQ-012: Bulk Operations - Multi-select state
    var isMultiSelectMode: Bool {
        !selectedTaskIds.isEmpty
    }
    
    /// Returns tasks filtered and sorted according to current filter
    var filteredTasks: [TaskItem] {
        guard let filter = filter else { return tasks }
        
        var result = tasks
        
        // Apply search filter
        if !filter.searchQuery.isEmpty {
            let query = filter.searchQuery.lowercased()
            result = result.filter { task in
                task.title.lowercased().contains(query) ||
                (task.description?.lowercased().contains(query) ?? false)
            }
        }
        
        // Apply category filter
        if !filter.selectedCategories.isEmpty {
            result = result.filter { task in
                if let categoryId = task.categoryId {
                    return filter.selectedCategories.contains(categoryId)
                }
                return false
            }
        }
        
        // Apply completion filter
        if !filter.showCompleted {
            result = result.filter { !$0.isCompleted }
        }
        
        // Apply due date filter
        result = applyDueDateFilter(to: result, filter: filter.dueDateFilter)
        
        // Apply sorting
        result = applySorting(to: result, filter: filter)
        
        return result
    }
    
    /// Returns templates filtered by search query
    var filteredTemplates: [TaskTemplate] {
        guard !templateSearchQuery.isEmpty else { return templates }
        
        let query = templateSearchQuery.lowercased()
        return templates.filter { template in
            template.name.lowercased().contains(query) ||
            template.category?.lowercased().contains(query) == true ||
            template.taskStructure.title.lowercased().contains(query)
        }
    }
    
    /// Apply sorting logic with support for multi-criteria and direction
    private func applySorting(to tasks: [TaskItem], filter: TaskFilter) -> [TaskItem] {
        // Use SortUtilities for cleaner implementation
        if let primarySort = filter.primarySortOrder {
            // Multi-criteria sorting
            return SortUtilities.multiCriteriaSort(
                tasks,
                primary: { task1, task2 in
                    compareTaskForSort(task1, task2, by: primarySort)
                },
                secondary: filter.secondarySortOrder.map { secondarySort in
                    { task1, task2 in
                        compareTaskForSort(task1, task2, by: secondarySort)
                    }
                },
                direction: filter.sortDirection
            )
        } else {
            // Single criteria sorting
            return SortUtilities.multiCriteriaSort(
                tasks,
                primary: { task1, task2 in
                    compareTaskForSort(task1, task2, by: filter.sortOrder)
                },
                direction: filter.sortDirection
            )
        }
    }
    
    /// Compare two tasks by a specific sort order (always returns as if ascending)
    private func compareTaskForSort(_ task1: TaskItem, _ task2: TaskItem, by sortOrder: SortOrder) -> ComparisonResult {
        switch sortOrder {
        case .alphabetical:
            return SortUtilities.Comparisons.byString(\.title)(task1, task2)
        case .dateCreated:
            return task1.createdAt.compare(task2.createdAt)
        case .dateModified:
            return task1.updatedAt.compare(task2.updatedAt)
        case .priority:
            return SortUtilities.Comparisons.byNumber(\.priority.numericValue)(task1, task2)
        case .dueDate:
            // Due date sorting - tasks with no date sort last
            let date1 = task1.dueDate
            let date2 = task2.dueDate
            
            switch (date1, date2) {
            case (nil, nil):
                return .orderedSame
            case (nil, _):
                return .orderedDescending
            case (_, nil):
                return .orderedAscending
            case let (d1?, d2?):
                return d1.compare(d2)
            }
        }
    }
    
    /// Apply due date filter
    private func applyDueDateFilter(to tasks: [TaskItem], filter: DueDateFilter) -> [TaskItem] {
        switch filter {
        case .all:
            return tasks
            
        case .overdue:
            return tasks.filter { $0.isOverdue }
            
        case .today:
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            
            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate >= today && dueDate < tomorrow
            }
            
        case .thisWeek:
            let calendar = Calendar.current
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!
            
            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate >= startOfWeek && dueDate < endOfWeek
            }
            
        case .thisMonth:
            let calendar = Calendar.current
            let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            
            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate >= startOfMonth && dueDate < endOfMonth
            }
            
        case .noDueDate:
            return tasks.filter { $0.dueDate == nil }
        }
    }
}