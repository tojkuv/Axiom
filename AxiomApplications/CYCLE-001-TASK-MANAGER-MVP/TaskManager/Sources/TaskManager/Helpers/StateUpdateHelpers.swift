import Foundation
import Axiom

// MARK: - REFACTOR: State Update Helpers

/// Helper protocol for cleaner state updates
protocol StateUpdatable {
    associatedtype StateType: State
    func with(_ updates: (inout Builder) -> Void) -> StateType
    
    associatedtype Builder
}

// MARK: - TaskState Update Helpers

extension TaskState {
    struct Builder {
        var tasks: [TaskItem]
        var categories: [Category]
        var filter: TaskFilter?
        var isLoading: Bool
        var error: TaskError?
        var templates: [TaskTemplate]
        var templateSearchQuery: String
        var selectedTaskIds: Set<UUID>
        var batchOperationProgress: Double?
        var isBatchOperationInProgress: Bool
        
        init(from state: TaskState) {
            self.tasks = state.tasks
            self.categories = state.categories
            self.filter = state.filter
            self.isLoading = state.isLoading
            self.error = state.error
            self.templates = state.templates
            self.templateSearchQuery = state.templateSearchQuery
            self.selectedTaskIds = state.selectedTaskIds
            self.batchOperationProgress = state.batchOperationProgress
            self.isBatchOperationInProgress = state.isBatchOperationInProgress
        }
        
        func build() -> TaskState {
            TaskState(
                tasks: tasks,
                categories: categories,
                filter: filter,
                isLoading: isLoading,
                error: error,
                templates: templates,
                templateSearchQuery: templateSearchQuery,
                selectedTaskIds: selectedTaskIds,
                batchOperationProgress: batchOperationProgress,
                isBatchOperationInProgress: isBatchOperationInProgress
            )
        }
    }
}

extension TaskState: StateUpdatable {
    func with(_ updates: (inout Builder) -> Void) -> TaskState {
        var builder = Builder(from: self)
        updates(&builder)
        return builder.build()
    }
}

// MARK: - Filter Update Helpers

extension TaskState {
    /// Update just the filter portion of state
    func withFilter(_ filterUpdate: (TaskFilter?) -> TaskFilter?) -> TaskState {
        with { builder in
            builder.filter = filterUpdate(builder.filter)
        }
    }
    
    /// Update multiple filter properties at once
    func withFilterUpdates(
        searchQuery: String? = nil,
        selectedCategories: Set<UUID>? = nil,
        showCompleted: Bool? = nil,
        sortOrder: SortOrder? = nil,
        sortDirection: SortDirection? = nil,
        primarySortOrder: SortOrder? = nil,
        secondarySortOrder: SortOrder? = nil,
        dueDateFilter: DueDateFilter? = nil
    ) -> TaskState {
        withFilter { currentFilter in
            currentFilter?.with(
                searchQuery: searchQuery,
                selectedCategories: selectedCategories,
                showCompleted: showCompleted,
                sortOrder: sortOrder,
                sortDirection: sortDirection,
                primarySortOrder: primarySortOrder,
                secondarySortOrder: secondarySortOrder,
                dueDateFilter: dueDateFilter
            ) ?? TaskFilter(
                searchQuery: searchQuery ?? "",
                selectedCategories: selectedCategories ?? [],
                showCompleted: showCompleted ?? true,
                sortOrder: sortOrder ?? .dateCreated,
                sortDirection: sortDirection ?? .descending,
                primarySortOrder: primarySortOrder,
                secondarySortOrder: secondarySortOrder,
                dueDateFilter: dueDateFilter ?? .all
            )
        }
    }
}

// MARK: - Task Collection Helpers

extension TaskState {
    /// Add a task maintaining immutability
    func withAddedTask(_ task: TaskItem) -> TaskState {
        with { builder in
            builder.tasks.append(task)
        }
    }
    
    /// Update a specific task
    func withUpdatedTask(id: UUID, update: (TaskItem) -> TaskItem) -> TaskState {
        with { builder in
            if let index = builder.tasks.firstIndex(where: { $0.id == id }) {
                builder.tasks[index] = update(builder.tasks[index])
            }
        }
    }
    
    /// Remove a task
    func withRemovedTask(id: UUID) -> TaskState {
        with { builder in
            builder.tasks.removeAll { $0.id == id }
        }
    }
    
    /// Update a task in the tree (handles nested subtasks)
    func withUpdatedTaskTree(parentId: UUID, update: (TaskItem) -> TaskItem) -> TaskState {
        with { builder in
            builder.tasks = updateTaskInTree(parentId: parentId, in: builder.tasks, update: update)
        }
    }
    
    private func updateTaskInTree(parentId: UUID, in tasks: [TaskItem], update: (TaskItem) -> TaskItem) -> [TaskItem] {
        return tasks.map { task in
            if task.id == parentId {
                return update(task)
            }
            
            // Recursively check subtasks
            let updatedSubtasks = updateTaskInTree(parentId: parentId, in: task.subtasks, update: update)
            
            return TaskItem(
                id: task.id,
                title: task.title,
                description: task.description,
                categoryId: task.categoryId,
                priority: task.priority,
                isCompleted: task.isCompleted,
                createdAt: task.createdAt,
                updatedAt: task.updatedAt,
                dueDate: task.dueDate,
                parentId: task.parentId,
                subtasks: updatedSubtasks,
                dependencies: task.dependencies
            )
        }
    }
}

// MARK: - Category Helpers

extension TaskState {
    /// Add a category
    func withAddedCategory(_ category: Category) -> TaskState {
        with { builder in
            builder.categories.append(category)
        }
    }
    
    /// Update a category
    func withUpdatedCategory(id: UUID, update: (Category) -> Category) -> TaskState {
        with { builder in
            if let index = builder.categories.firstIndex(where: { $0.id == id }) {
                builder.categories[index] = update(builder.categories[index])
            }
        }
    }
    
    /// Remove a category
    func withRemovedCategory(id: UUID) -> TaskState {
        with { builder in
            builder.categories.removeAll { $0.id == id }
            // Also remove category from any tasks
            builder.tasks = builder.tasks.map { task in
                if task.categoryId == id {
                    return TaskItem(
                        id: task.id,
                        title: task.title,
                        description: task.description,
                        categoryId: nil,
                        priority: task.priority,
                        isCompleted: task.isCompleted,
                        createdAt: task.createdAt,
                        updatedAt: task.updatedAt,
                        dueDate: task.dueDate,
                        parentId: task.parentId,
                        subtasks: task.subtasks,
                        dependencies: task.dependencies
                    )
                }
                return task
            }
        }
    }
}