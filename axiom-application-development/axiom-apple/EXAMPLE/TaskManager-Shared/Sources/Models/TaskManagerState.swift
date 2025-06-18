import Foundation
import Axiom

// MARK: - Task Manager State

/// The main state for the task manager application
public struct TaskManagerState: AxiomState {
    public let tasks: [Task]
    public let selectedFilter: Task.Filter
    public let selectedCategory: Category?
    public let sortOrder: Task.SortOrder
    public let searchQuery: String
    public let isAscending: Bool
    public let lastUpdated: Date
    
    public init(
        tasks: [Task] = [],
        selectedFilter: Task.Filter = .all,
        selectedCategory: Category? = nil,
        sortOrder: Task.SortOrder = .createdDate,
        searchQuery: String = "",
        isAscending: Bool = false,
        lastUpdated: Date = Date()
    ) {
        self.tasks = tasks
        self.selectedFilter = selectedFilter
        self.selectedCategory = selectedCategory
        self.sortOrder = sortOrder
        self.searchQuery = searchQuery
        self.isAscending = isAscending
        self.lastUpdated = lastUpdated
    }
}

// MARK: - State Mutations

extension TaskManagerState {
    /// Create a new state with updated tasks
    public func withTasks(_ newTasks: [Task]) -> TaskManagerState {
        TaskManagerState(
            tasks: newTasks,
            selectedFilter: selectedFilter,
            selectedCategory: selectedCategory,
            sortOrder: sortOrder,
            searchQuery: searchQuery,
            isAscending: isAscending,
            lastUpdated: Date()
        )
    }
    
    /// Create a new state with a task added
    public func addingTask(_ task: Task) -> TaskManagerState {
        var newTasks = tasks
        newTasks.append(task)
        return withTasks(newTasks)
    }
    
    /// Create a new state with a task updated
    public func updatingTask(_ updatedTask: Task) -> TaskManagerState {
        let newTasks = tasks.map { task in
            task.id == updatedTask.id ? updatedTask : task
        }
        return withTasks(newTasks)
    }
    
    /// Create a new state with a task removed
    public func removingTask(withId taskId: UUID) -> TaskManagerState {
        let newTasks = tasks.filter { $0.id != taskId }
        return withTasks(newTasks)
    }
    
    /// Create a new state with updated filter
    public func withFilter(_ newFilter: Task.Filter) -> TaskManagerState {
        TaskManagerState(
            tasks: tasks,
            selectedFilter: newFilter,
            selectedCategory: selectedCategory,
            sortOrder: sortOrder,
            searchQuery: searchQuery,
            isAscending: isAscending,
            lastUpdated: Date()
        )
    }
    
    /// Create a new state with updated category filter
    public func withCategoryFilter(_ category: Category?) -> TaskManagerState {
        TaskManagerState(
            tasks: tasks,
            selectedFilter: selectedFilter,
            selectedCategory: category,
            sortOrder: sortOrder,
            searchQuery: searchQuery,
            isAscending: isAscending,
            lastUpdated: Date()
        )
    }
    
    /// Create a new state with updated sort order
    public func withSortOrder(_ newSortOrder: Task.SortOrder, ascending: Bool? = nil) -> TaskManagerState {
        TaskManagerState(
            tasks: tasks,
            selectedFilter: selectedFilter,
            selectedCategory: selectedCategory,
            sortOrder: newSortOrder,
            searchQuery: searchQuery,
            isAscending: ascending ?? isAscending,
            lastUpdated: Date()
        )
    }
    
    /// Create a new state with updated search query
    public func withSearchQuery(_ query: String) -> TaskManagerState {
        TaskManagerState(
            tasks: tasks,
            selectedFilter: selectedFilter,
            selectedCategory: selectedCategory,
            sortOrder: sortOrder,
            searchQuery: query,
            isAscending: isAscending,
            lastUpdated: Date()
        )
    }
    
    /// Create a new state with toggled sort direction
    public func withToggledSortDirection() -> TaskManagerState {
        TaskManagerState(
            tasks: tasks,
            selectedFilter: selectedFilter,
            selectedCategory: selectedCategory,
            sortOrder: sortOrder,
            searchQuery: searchQuery,
            isAscending: !isAscending,
            lastUpdated: Date()
        )
    }
}

// MARK: - Computed Properties

extension TaskManagerState {
    /// Get filtered and sorted tasks based on current state
    public var filteredAndSortedTasks: [Task] {
        var result = tasks
        
        // Apply search filter
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result = result.filter { $0.matches(searchQuery: searchQuery) }
        }
        
        // Apply category filter
        if let selectedCategory = selectedCategory {
            result = result.filter { $0.category == selectedCategory }
        }
        
        // Apply status filter
        result = result.filter { selectedFilter.matches($0) }
        
        // Apply sorting
        result = sortTasks(result, by: sortOrder, ascending: isAscending)
        
        return result
    }
    
    /// Get tasks grouped by category
    public var tasksGroupedByCategory: [Category: [Task]] {
        Dictionary(grouping: filteredAndSortedTasks) { $0.category }
    }
    
    /// Get tasks grouped by priority
    public var tasksGroupedByPriority: [Priority: [Task]] {
        Dictionary(grouping: filteredAndSortedTasks) { $0.priority }
    }
    
    /// Get tasks grouped by completion status
    public var tasksGroupedByCompletion: (completed: [Task], pending: [Task]) {
        let completed = filteredAndSortedTasks.filter { $0.isCompleted }
        let pending = filteredAndSortedTasks.filter { !$0.isCompleted }
        return (completed, pending)
    }
    
    /// Get statistics for the current state
    public var statistics: TaskStatistics {
        TaskStatistics(
            totalTasks: tasks.count,
            completedTasks: tasks.filter { $0.isCompleted }.count,
            pendingTasks: tasks.filter { !$0.isCompleted }.count,
            overdueTasks: tasks.filter { $0.isOverdue }.count,
            dueTodayTasks: tasks.filter { $0.isDueToday }.count,
            dueThisWeekTasks: tasks.filter { $0.isDueThisWeek }.count,
            filteredTasksCount: filteredAndSortedTasks.count,
            tasksByCategory: Dictionary(grouping: tasks) { $0.category }.mapValues { $0.count },
            tasksByPriority: Dictionary(grouping: tasks) { $0.priority }.mapValues { $0.count }
        )
    }
    
    /// Get a specific task by ID
    public func task(withId id: UUID) -> Task? {
        tasks.first { $0.id == id }
    }
    
    /// Check if there are any pending tasks
    public var hasPendingTasks: Bool {
        tasks.contains { !$0.isCompleted }
    }
    
    /// Check if there are any overdue tasks
    public var hasOverdueTasks: Bool {
        tasks.contains { $0.isOverdue }
    }
    
    /// Check if there are any tasks due today
    public var hasTasksDueToday: Bool {
        tasks.contains { $0.isDueToday }
    }
}

// MARK: - Task Sorting

extension TaskManagerState {
    private func sortTasks(_ tasks: [Task], by sortOrder: Task.SortOrder, ascending: Bool) -> [Task] {
        let sorted = tasks.sorted { task1, task2 in
            let result: Bool
            
            switch sortOrder {
            case .createdDate:
                result = task1.createdAt < task2.createdAt
            case .dueDate:
                // Handle nil due dates - put them at the end
                switch (task1.dueDate, task2.dueDate) {
                case (nil, nil):
                    result = task1.createdAt < task2.createdAt
                case (nil, _):
                    result = false
                case (_, nil):
                    result = true
                case (let date1?, let date2?):
                    result = date1 < date2
                }
            case .priority:
                result = task1.priority.weight > task2.priority.weight
            case .title:
                result = task1.title.localizedCaseInsensitiveCompare(task2.title) == .orderedAscending
            case .completion:
                result = task1.isCompleted && !task2.isCompleted
            }
            
            return ascending ? result : !result
        }
        
        return sorted
    }
}

// MARK: - Task Statistics

/// Statistics about tasks in the current state
public struct TaskStatistics: Equatable, Hashable, Sendable {
    public let totalTasks: Int
    public let completedTasks: Int
    public let pendingTasks: Int
    public let overdueTasks: Int
    public let dueTodayTasks: Int
    public let dueThisWeekTasks: Int
    public let filteredTasksCount: Int
    public let tasksByCategory: [Category: Int]
    public let tasksByPriority: [Priority: Int]
    
    public init(
        totalTasks: Int,
        completedTasks: Int,
        pendingTasks: Int,
        overdueTasks: Int,
        dueTodayTasks: Int,
        dueThisWeekTasks: Int,
        filteredTasksCount: Int,
        tasksByCategory: [Category: Int],
        tasksByPriority: [Priority: Int]
    ) {
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.pendingTasks = pendingTasks
        self.overdueTasks = overdueTasks
        self.dueTodayTasks = dueTodayTasks
        self.dueThisWeekTasks = dueThisWeekTasks
        self.filteredTasksCount = filteredTasksCount
        self.tasksByCategory = tasksByCategory
        self.tasksByPriority = tasksByPriority
    }
    
    /// Completion percentage (0.0 to 1.0)
    public var completionPercentage: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    /// Whether all tasks are completed
    public var isAllCompleted: Bool {
        totalTasks > 0 && completedTasks == totalTasks
    }
    
    /// Whether there are no tasks
    public var isEmpty: Bool {
        totalTasks == 0
    }
}

// MARK: - State Validation

extension TaskManagerState {
    /// Validates the state for consistency
    public var isValid: Bool {
        // Check that all tasks have unique IDs
        let uniqueIds = Set(tasks.map { $0.id })
        return uniqueIds.count == tasks.count
    }
    
    /// Returns validation errors if any
    public var validationErrors: [String] {
        var errors: [String] = []
        
        // Check for duplicate task IDs
        let taskIds = tasks.map { $0.id }
        let uniqueIds = Set(taskIds)
        if uniqueIds.count != taskIds.count {
            errors.append("Duplicate task IDs found")
        }
        
        // Validate individual tasks
        for task in tasks {
            if !task.isValid {
                errors.append("Invalid task: \(task.title)")
            }
        }
        
        return errors
    }
}