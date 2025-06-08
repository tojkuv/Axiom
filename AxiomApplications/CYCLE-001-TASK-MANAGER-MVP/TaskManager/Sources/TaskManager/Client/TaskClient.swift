import Foundation
import Axiom

/// Task management client implementing Axiom's Client protocol
actor TaskClient: Client {
    typealias StateType = TaskState
    typealias ActionType = TaskAction
    
    private(set) var state: TaskState
    let stateStream: AsyncStream<TaskState>
    private let continuation: AsyncStream<TaskState>.Continuation
    
    /// Convenience property for test compatibility
    var currentState: TaskState {
        state
    }
    
    init() {
        self.state = TaskState()
        let (stream, continuation) = AsyncStream<TaskState>.makeStream()
        self.stateStream = stream
        self.continuation = continuation
        // Emit initial state
        continuation.yield(state)
    }
    
    private func updateState(_ newState: TaskState) {
        guard state != newState else { return }
        state = newState
        continuation.yield(newState)
    }
    
    func process(_ action: TaskAction) async throws {
        switch action {
        // Task CRUD
        case .addTask(let title, let description, let categoryId, let priority, let dueDate, let createdAt):
            let newState = await addTask(title: title, description: description, categoryId: categoryId, priority: priority, dueDate: dueDate, createdAt: createdAt)
            updateState(newState)
            
        case .updateTask(let id, let title, let description, let categoryId, let priority, let dueDate, let isCompleted):
            let newState = await updateTask(id: id, title: title, description: description, categoryId: categoryId, priority: priority, dueDate: dueDate, isCompleted: isCompleted)
            updateState(newState)
            
        case .deleteTask(let id):
            let newState = await deleteTask(id: id)
            updateState(newState)
            
        case .toggleTaskCompletion(let id):
            do {
                let newState = try await toggleTaskCompletion(id: id)
                updateState(newState)
            } catch {
                throw error
            }
            
        case .loadTasks:
            let newState = await loadTasks()
            updateState(newState)
            
        case .clearError:
            let newState = TaskState(
                tasks: state.tasks,
                categories: state.categories,
                filter: state.filter,
                isLoading: false,
                error: nil,
                templates: state.templates,
                templateSearchQuery: state.templateSearchQuery
            )
            updateState(newState)
            
        // Category Management
        case .setCategories(let categories):
            let newState = TaskState(
                tasks: state.tasks,
                categories: categories,
                filter: state.filter,
                isLoading: state.isLoading,
                error: state.error,
                templates: state.templates,
                templateSearchQuery: state.templateSearchQuery
            )
            updateState(newState)
            
        case .addCategory(let name, let color, let icon):
            let newState = await addCategory(name: name, color: color, icon: icon)
            updateState(newState)
            
        case .updateCategory(let id, let name, let color, let icon):
            let newState = await updateCategory(id: id, name: name, color: color, icon: icon)
            updateState(newState)
            
        case .deleteCategory(let id):
            let newState = await deleteCategory(id: id)
            updateState(newState)
            
        // Filtering
        case .setSearchQuery(let query):
            updateState(state.withFilterUpdates(searchQuery: query))
            
        case .toggleCategoryFilter(let categoryId):
            var selectedCategories = state.filter?.selectedCategories ?? []
            if selectedCategories.contains(categoryId) {
                selectedCategories.remove(categoryId)
            } else {
                selectedCategories.insert(categoryId)
            }
            updateState(state.withFilterUpdates(selectedCategories: selectedCategories))
            
        case .setSortOrder(let sortOrder):
            updateState(state.withFilterUpdates(sortOrder: sortOrder))
            
        case .setSortDirection(let direction):
            updateState(state.withFilterUpdates(sortDirection: direction))
            
        case .setSortCriteria(let primary, let secondary, let direction):
            updateState(state.withFilterUpdates(
                sortDirection: direction,
                primarySortOrder: primary,
                secondarySortOrder: secondary
            ))
            
        case .setShowCompleted(let show):
            updateState(state.withFilterUpdates(showCompleted: show))
            
        case .setDueDateFilter(let filter):
            updateState(state.withFilterUpdates(dueDateFilter: filter))
            
        case .clearFilters:
            updateState(state.withFilter { _ in TaskFilter.default })
            
        // REQ-010: Subtasks and Dependencies
        case .addSubtask(let parentId, let title, let description, let priority):
            let newState = await addSubtask(parentId: parentId, title: title, description: description, priority: priority)
            updateState(newState)
            
        case .deleteSubtask(let id):
            let newState = await deleteSubtask(id: id)
            updateState(newState)
            
        case .toggleSubtaskCompletion(let id):
            let newState = await toggleSubtaskCompletion(id: id)
            updateState(newState)
            
        case .addDependency(let dependentTaskId, let prerequisiteTaskId):
            do {
                let newState = try await addDependency(dependentTaskId: dependentTaskId, prerequisiteTaskId: prerequisiteTaskId)
                updateState(newState)
            } catch {
                // Let the error propagate
                throw error
            }
            
        case .removeDependency(let dependentTaskId, let prerequisiteTaskId):
            let newState = await removeDependency(dependentTaskId: dependentTaskId, prerequisiteTaskId: prerequisiteTaskId)
            updateState(newState)
            
        // REQ-011: Task Templates
        case .createTemplate(let sourceTask, let name, let customizableFields, let category):
            do {
                let newState = try await createTemplate(from: sourceTask, name: name, customizableFields: customizableFields, category: category)
                updateState(newState)
            } catch {
                throw error
            }
            
        case .instantiateTemplate(let templateId, let customizations):
            do {
                let newState = try await instantiateTemplate(templateId: templateId, customizations: customizations)
                updateState(newState)
            } catch {
                throw error
            }
            
        case .updateTemplate(let templateId, let name, let taskStructure, let customizableFields, let category):
            do {
                let newState = try await updateTemplate(templateId: templateId, name: name, taskStructure: taskStructure, customizableFields: customizableFields, category: category)
                updateState(newState)
            } catch {
                throw error
            }
            
        case .deleteTemplate(let templateId):
            do {
                let newState = try await deleteTemplate(templateId: templateId)
                updateState(newState)
            } catch {
                throw error
            }
            
        case .searchTemplates(let query):
            let newState = TaskState(
                tasks: state.tasks,
                categories: state.categories,
                filter: state.filter,
                isLoading: state.isLoading,
                error: state.error,
                templates: state.templates,
                templateSearchQuery: query
            )
            updateState(newState)
            
        case .clearTemplateSearch:
            let newState = TaskState(
                tasks: state.tasks,
                categories: state.categories,
                filter: state.filter,
                isLoading: state.isLoading,
                error: state.error,
                templates: state.templates,
                templateSearchQuery: ""
            )
            updateState(newState)
            
        // REQ-012: Bulk Operations
        case .toggleTaskSelection(let id):
            let newState = await toggleTaskSelection(id: id)
            updateState(newState)
            
        case .clearAllSelections:
            let newState = TaskState(
                tasks: state.tasks,
                categories: state.categories,
                filter: state.filter,
                isLoading: state.isLoading,
                error: state.error,
                templates: state.templates,
                templateSearchQuery: state.templateSearchQuery,
                selectedTaskIds: [],
                batchOperationProgress: nil,
                isBatchOperationInProgress: false
            )
            updateState(newState)
            
        case .batchDeleteSelected:
            do {
                let newState = try await batchDeleteSelected()
                updateState(newState)
            } catch {
                throw error
            }
            
        case .batchUpdateStatus(let isCompleted):
            do {
                let newState = try await batchUpdateStatus(isCompleted: isCompleted)
                updateState(newState)
            } catch {
                throw error
            }
            
        case .batchUpdateCategory(let categoryId):
            do {
                let newState = try await batchUpdateCategory(categoryId: categoryId)
                updateState(newState)
            } catch {
                throw error
            }
            
        case .batchUpdatePriority(let priority):
            do {
                let newState = try await batchUpdatePriority(priority: priority)
                updateState(newState)
            } catch {
                throw error
            }
            
        case .cancelBatchOperation:
            let newState = await cancelBatchOperation()
            updateState(newState)
            
        case .selectAllTasks:
            let newState = await selectAllTasks()
            updateState(newState)
            
        // REQ-013: Keyboard Navigation
        case .setCreateTaskModalPresented(let isPresented):
            let newState = TaskState(
                tasks: state.tasks,
                categories: state.categories,
                filter: state.filter,
                isLoading: state.isLoading,
                error: state.error,
                templates: state.templates,
                templateSearchQuery: state.templateSearchQuery,
                selectedTaskIds: state.selectedTaskIds,
                batchOperationProgress: state.batchOperationProgress,
                isBatchOperationInProgress: state.isBatchOperationInProgress,
                isCreateTaskModalPresented: isPresented,
                showingDeleteConfirmation: state.showingDeleteConfirmation,
                deleteConfirmationTaskId: state.deleteConfirmationTaskId,
                editingTaskId: state.editingTaskId,
                isSearchActive: state.isSearchActive
            )
            updateState(newState)
            
        case .setDeleteConfirmationPresented(let isPresented, let taskId):
            let newState = TaskState(
                tasks: state.tasks,
                categories: state.categories,
                filter: state.filter,
                isLoading: state.isLoading,
                error: state.error,
                templates: state.templates,
                templateSearchQuery: state.templateSearchQuery,
                selectedTaskIds: state.selectedTaskIds,
                batchOperationProgress: state.batchOperationProgress,
                isBatchOperationInProgress: state.isBatchOperationInProgress,
                isCreateTaskModalPresented: state.isCreateTaskModalPresented,
                showingDeleteConfirmation: isPresented,
                deleteConfirmationTaskId: taskId,
                editingTaskId: state.editingTaskId,
                isSearchActive: state.isSearchActive
            )
            updateState(newState)
            
        case .setEditingTask(let taskId):
            let newState = TaskState(
                tasks: state.tasks,
                categories: state.categories,
                filter: state.filter,
                isLoading: state.isLoading,
                error: state.error,
                templates: state.templates,
                templateSearchQuery: state.templateSearchQuery,
                selectedTaskIds: state.selectedTaskIds,
                batchOperationProgress: state.batchOperationProgress,
                isBatchOperationInProgress: state.isBatchOperationInProgress,
                isCreateTaskModalPresented: state.isCreateTaskModalPresented,
                showingDeleteConfirmation: state.showingDeleteConfirmation,
                deleteConfirmationTaskId: state.deleteConfirmationTaskId,
                editingTaskId: taskId,
                isSearchActive: state.isSearchActive
            )
            updateState(newState)
            
        case .setSearchActive(let isActive):
            let newState = TaskState(
                tasks: state.tasks,
                categories: state.categories,
                filter: state.filter,
                isLoading: state.isLoading,
                error: state.error,
                templates: state.templates,
                templateSearchQuery: state.templateSearchQuery,
                selectedTaskIds: state.selectedTaskIds,
                batchOperationProgress: state.batchOperationProgress,
                isBatchOperationInProgress: state.isBatchOperationInProgress,
                isCreateTaskModalPresented: state.isCreateTaskModalPresented,
                showingDeleteConfirmation: state.showingDeleteConfirmation,
                deleteConfirmationTaskId: state.deleteConfirmationTaskId,
                editingTaskId: state.editingTaskId,
                isSearchActive: isActive
            )
            updateState(newState)
            
        }
    }
    
    // MARK: - Private Implementation
    
    private func addTask(title: String, description: String?, categoryId: UUID? = nil, priority: Priority = .medium, dueDate: Date? = nil, createdAt: Date? = nil) async -> TaskState {
        let newTask = TaskItem(
            title: title,
            description: description,
            categoryId: categoryId,
            priority: priority,
            createdAt: createdAt ?? Date(),
            dueDate: dueDate
        )
        
        return state.withAddedTask(newTask).with { builder in
            builder.isLoading = false
            builder.error = nil
        }
    }
    
    private func updateTask(id: UUID, title: String?, description: String?, categoryId: UUID?, priority: Priority?, dueDate: Date?, isCompleted: Bool?) async -> TaskState {
        return state.withUpdatedTask(id: id) { existingTask in
            TaskItem(
                id: existingTask.id,
                title: title ?? existingTask.title,
                description: description ?? existingTask.description,
                categoryId: categoryId ?? existingTask.categoryId,
                priority: priority ?? existingTask.priority,
                isCompleted: isCompleted ?? existingTask.isCompleted,
                createdAt: existingTask.createdAt,
                updatedAt: Date(),
                dueDate: dueDate ?? existingTask.dueDate
            )
        }.with { builder in
            builder.isLoading = false
            builder.error = nil
        }
    }
    
    private func deleteTask(id: UUID) async -> TaskState {
        if !state.tasks.contains(where: { $0.id == id }) {
            return state.with { builder in
                builder.isLoading = false
                builder.error = .taskNotFound(id)
            }
        }
        
        return state.withRemovedTask(id: id).with { builder in
            builder.isLoading = false
            builder.error = nil
        }
    }
    
    private func toggleTaskCompletion(id: UUID) async throws -> TaskState {
        // Check if task exists
        guard let task = findTask(id: id, in: state.tasks) else {
            throw TaskError.taskNotFound(id)
        }
        
        let shouldComplete = !task.isCompleted
        
        // If completing task, check dependencies using DependencyValidator
        if shouldComplete && !task.dependencies.isEmpty {
            let incompletePrerequisites = DependencyValidator.validatePrerequisites(for: id, in: state.tasks)
            
            if !incompletePrerequisites.isEmpty {
                throw TaskError.incompletePrerequisites(incompletePrerequisites)
            }
        }
        
        return await updateTask(
            id: id,
            title: nil,
            description: nil,
            categoryId: nil,
            priority: nil,
            dueDate: nil,
            isCompleted: shouldComplete
        )
    }
    
    private func loadTasks() async -> TaskState {
        // TODO: Implement persistence loading
        return TaskState(
            tasks: state.tasks,
            categories: state.categories,
            filter: state.filter,
            isLoading: false,
            error: nil
        )
    }
    
    // MARK: - Category Management
    
    private func addCategory(name: String, color: String, icon: String?) async -> TaskState {
        let newCategory = Category(
            name: name,
            color: color,
            icon: icon
        )
        
        var updatedCategories = state.categories
        updatedCategories.append(newCategory)
        
        return TaskState(
            tasks: state.tasks,
            categories: updatedCategories,
            filter: state.filter,
            isLoading: false,
            error: nil
        )
    }
    
    private func updateCategory(id: UUID, name: String?, color: String?, icon: String?) async -> TaskState {
        var updatedCategories = state.categories
        
        guard let index = updatedCategories.firstIndex(where: { $0.id == id }) else {
            return state // Category not found - could add error
        }
        
        let existingCategory = updatedCategories[index]
        let updatedCategory = Category(
            id: existingCategory.id,
            name: name ?? existingCategory.name,
            color: color ?? existingCategory.color,
            icon: icon ?? existingCategory.icon,
            createdAt: existingCategory.createdAt,
            updatedAt: Date()
        )
        
        updatedCategories[index] = updatedCategory
        
        return TaskState(
            tasks: state.tasks,
            categories: updatedCategories,
            filter: state.filter,
            isLoading: false,
            error: nil
        )
    }
    
    private func deleteCategory(id: UUID) async -> TaskState {
        let updatedCategories = state.categories.filter { $0.id != id }
        
        // Also remove category from any tasks
        let updatedTasks = state.tasks.map { task in
            if task.categoryId == id {
                return TaskItem(
                    id: task.id,
                    title: task.title,
                    description: task.description,
                    categoryId: nil, // Remove category reference
                    priority: task.priority,
                    isCompleted: task.isCompleted,
                    createdAt: task.createdAt,
                    updatedAt: Date(),
                    dueDate: task.dueDate,
                    parentId: task.parentId,
                    subtasks: task.subtasks,
                    dependencies: task.dependencies
                )
            }
            return task
        }
        
        return TaskState(
            tasks: updatedTasks,
            categories: updatedCategories,
            filter: state.filter,
            isLoading: false,
            error: nil
        )
    }
    
    // MARK: - REQ-010: Subtasks and Dependencies Implementation
    
    private func addSubtask(parentId: UUID, title: String, description: String?, priority: Priority) async -> TaskState {
        // Verify parent task exists
        guard findTask(id: parentId, in: state.tasks) != nil else {
            return state.with { builder in
                builder.error = .invalidParentTask(parentId)
            }
        }
        
        let newSubtask = TaskItem(
            title: title,
            description: description,
            priority: priority,
            parentId: parentId
        )
        
        return state.withUpdatedTaskTree(parentId: parentId) { parentTask in
            var updatedSubtasks = parentTask.subtasks
            updatedSubtasks.append(newSubtask)
            
            return TaskItem(
                id: parentTask.id,
                title: parentTask.title,
                description: parentTask.description,
                categoryId: parentTask.categoryId,
                priority: parentTask.priority,
                isCompleted: parentTask.isCompleted,
                createdAt: parentTask.createdAt,
                updatedAt: Date(),
                dueDate: parentTask.dueDate,
                parentId: parentTask.parentId,
                subtasks: updatedSubtasks,
                dependencies: parentTask.dependencies
            )
        }.with { builder in
            builder.error = nil
        }
    }
    
    private func deleteSubtask(id: UUID) async -> TaskState {
        guard let (parentId, _) = findSubtaskWithParent(id: id, in: state.tasks) else {
            return state.with { builder in
                builder.error = .subtaskNotFound(id)
            }
        }
        
        return state.withUpdatedTaskTree(parentId: parentId) { parentTask in
            let updatedSubtasks = removeSubtaskRecursively(id: id, from: parentTask.subtasks)
            
            return TaskItem(
                id: parentTask.id,
                title: parentTask.title,
                description: parentTask.description,
                categoryId: parentTask.categoryId,
                priority: parentTask.priority,
                isCompleted: parentTask.isCompleted,
                createdAt: parentTask.createdAt,
                updatedAt: Date(),
                dueDate: parentTask.dueDate,
                parentId: parentTask.parentId,
                subtasks: updatedSubtasks,
                dependencies: parentTask.dependencies
            )
        }.with { builder in
            builder.error = nil
        }
    }
    
    private func toggleSubtaskCompletion(id: UUID) async -> TaskState {
        guard let (parentId, subtask) = findSubtaskWithParent(id: id, in: state.tasks) else {
            return state.with { builder in
                builder.error = .subtaskNotFound(id)
            }
        }
        
        let shouldComplete = !subtask.isCompleted
        
        // Check dependencies if completing using DependencyValidator
        if shouldComplete && !subtask.dependencies.isEmpty {
            let incompletePrerequisites = DependencyValidator.validatePrerequisites(for: id, in: state.tasks)
            
            if !incompletePrerequisites.isEmpty {
                return state.with { builder in
                    builder.error = .incompletePrerequisites(incompletePrerequisites)
                }
            }
        }
        
        return state.withUpdatedTaskTree(parentId: parentId) { parentTask in
            let updatedSubtasks = updateSubtaskRecursively(id: id, in: parentTask.subtasks) { existingSubtask in
                TaskItem(
                    id: existingSubtask.id,
                    title: existingSubtask.title,
                    description: existingSubtask.description,
                    categoryId: existingSubtask.categoryId,
                    priority: existingSubtask.priority,
                    isCompleted: shouldComplete,
                    createdAt: existingSubtask.createdAt,
                    updatedAt: Date(),
                    dueDate: existingSubtask.dueDate,
                    parentId: existingSubtask.parentId,
                    subtasks: existingSubtask.subtasks,
                    dependencies: existingSubtask.dependencies
                )
            }
            
            // Update parent completion based on subtasks
            let allSubtasksCompleted = updatedSubtasks.allSatisfy { $0.isCompleted }
            let parentShouldComplete = allSubtasksCompleted && !updatedSubtasks.isEmpty
            
            return TaskItem(
                id: parentTask.id,
                title: parentTask.title,
                description: parentTask.description,
                categoryId: parentTask.categoryId,
                priority: parentTask.priority,
                isCompleted: parentShouldComplete,
                createdAt: parentTask.createdAt,
                updatedAt: Date(),
                dueDate: parentTask.dueDate,
                parentId: parentTask.parentId,
                subtasks: updatedSubtasks,
                dependencies: parentTask.dependencies
            )
        }.with { builder in
            builder.error = nil
        }
    }
    
    private func addDependency(dependentTaskId: UUID, prerequisiteTaskId: UUID) async throws -> TaskState {
        // Verify both tasks exist
        guard findTask(id: dependentTaskId, in: state.tasks) != nil else {
            throw TaskError.taskNotFound(dependentTaskId)
        }
        
        guard findTask(id: prerequisiteTaskId, in: state.tasks) != nil else {
            throw TaskError.taskNotFound(prerequisiteTaskId)
        }
        
        // Check for circular dependency
        if let cycle = detectCircularDependency(adding: prerequisiteTaskId, to: dependentTaskId) {
            throw TaskError.circularDependencyDetected(cycle)
        }
        
        return state.withUpdatedTask(id: dependentTaskId) { existingTask in
            var updatedDependencies = existingTask.dependencies
            updatedDependencies.insert(prerequisiteTaskId)
            
            return TaskItem(
                id: existingTask.id,
                title: existingTask.title,
                description: existingTask.description,
                categoryId: existingTask.categoryId,
                priority: existingTask.priority,
                isCompleted: existingTask.isCompleted,
                createdAt: existingTask.createdAt,
                updatedAt: Date(),
                dueDate: existingTask.dueDate,
                parentId: existingTask.parentId,
                subtasks: existingTask.subtasks,
                dependencies: updatedDependencies
            )
        }.with { builder in
            builder.error = nil
        }
    }
    
    private func removeDependency(dependentTaskId: UUID, prerequisiteTaskId: UUID) async -> TaskState {
        guard let dependentTask = findTask(id: dependentTaskId, in: state.tasks) else {
            return state.with { builder in
                builder.error = .taskNotFound(dependentTaskId)
            }
        }
        
        var updatedDependencies = dependentTask.dependencies
        updatedDependencies.remove(prerequisiteTaskId)
        
        return state.withUpdatedTask(id: dependentTaskId) { existingTask in
            TaskItem(
                id: existingTask.id,
                title: existingTask.title,
                description: existingTask.description,
                categoryId: existingTask.categoryId,
                priority: existingTask.priority,
                isCompleted: existingTask.isCompleted,
                createdAt: existingTask.createdAt,
                updatedAt: Date(),
                dueDate: existingTask.dueDate,
                parentId: existingTask.parentId,
                subtasks: existingTask.subtasks,
                dependencies: updatedDependencies
            )
        }.with { builder in
            builder.error = nil
        }
    }
    
    // MARK: - Helper Methods for Tree Operations (REFACTORED)
    
    /// Use TreeUtilities for consistent tree operations
    private func findTask(id: UUID, in tasks: [TaskItem]) -> TaskItem? {
        return TreeUtilities.findTask(id: id, in: tasks)
    }
    
    /// Use TreeUtilities for finding subtasks with parent info
    private func findSubtaskWithParent(id: UUID, in tasks: [TaskItem]) -> (parentId: UUID, subtask: TaskItem)? {
        return TreeUtilities.findSubtaskWithParent(id: id, in: tasks)
    }
    
    /// Use TreeUtilities for removing subtasks
    private func removeSubtaskRecursively(id: UUID, from subtasks: [TaskItem]) -> [TaskItem] {
        return TreeUtilities.removeSubtaskRecursively(id: id, from: subtasks)
    }
    
    /// Use TreeUtilities for updating subtasks
    private func updateSubtaskRecursively(id: UUID, in subtasks: [TaskItem], update: (TaskItem) -> TaskItem) -> [TaskItem] {
        return TreeUtilities.updateSubtaskRecursively(id: id, in: subtasks, update: update)
    }
    
    /// Use DependencyValidator for circular dependency detection
    private func detectCircularDependency(adding prerequisiteId: UUID, to dependentId: UUID) -> [UUID]? {
        return DependencyValidator.detectCircularDependency(
            adding: prerequisiteId,
            to: dependentId,
            in: state.tasks
        )
    }
    
    // MARK: - REQ-011: Template Management Implementation
    
    private func createTemplate(from sourceTask: TaskItem, name: String, customizableFields: [String], category: String?) async throws -> TaskState {
        // Check for duplicate template name
        if state.templates.contains(where: { $0.name == name }) {
            throw TaskError.duplicateTemplateName(name)
        }
        
        let template = TaskTemplate(
            name: name,
            taskStructure: sourceTask,
            customizableFields: customizableFields,
            category: category
        )
        
        var updatedTemplates = state.templates
        updatedTemplates.append(template)
        
        return TaskState(
            tasks: state.tasks,
            categories: state.categories,
            filter: state.filter,
            isLoading: false,
            error: nil,
            templates: updatedTemplates,
            templateSearchQuery: state.templateSearchQuery
        )
    }
    
    private func instantiateTemplate(templateId: UUID, customizations: [String: String]) async throws -> TaskState {
        guard let template = state.templates.first(where: { $0.id == templateId }) else {
            throw TaskError.templateNotFound(templateId)
        }
        
        let instantiatedTask = template.instantiate(customizations: customizations)
        
        var updatedTasks = state.tasks
        updatedTasks.append(instantiatedTask)
        
        return TaskState(
            tasks: updatedTasks,
            categories: state.categories,
            filter: state.filter,
            isLoading: false,
            error: nil,
            templates: state.templates,
            templateSearchQuery: state.templateSearchQuery
        )
    }
    
    private func updateTemplate(templateId: UUID, name: String?, taskStructure: TaskItem?, customizableFields: [String]?, category: String?) async throws -> TaskState {
        guard let templateIndex = state.templates.firstIndex(where: { $0.id == templateId }) else {
            throw TaskError.templateNotFound(templateId)
        }
        
        let existingTemplate = state.templates[templateIndex]
        
        // Check for name conflicts if name is being changed
        if let newName = name, newName != existingTemplate.name {
            if state.templates.contains(where: { $0.name == newName && $0.id != templateId }) {
                throw TaskError.duplicateTemplateName(newName)
            }
        }
        
        let updatedTemplate = TaskTemplate(
            id: existingTemplate.id,
            name: name ?? existingTemplate.name,
            taskStructure: taskStructure ?? existingTemplate.taskStructure,
            customizableFields: customizableFields ?? existingTemplate.customizableFields,
            category: category ?? existingTemplate.category,
            createdAt: existingTemplate.createdAt,
            updatedAt: Date()
        )
        
        var updatedTemplates = state.templates
        updatedTemplates[templateIndex] = updatedTemplate
        
        return TaskState(
            tasks: state.tasks,
            categories: state.categories,
            filter: state.filter,
            isLoading: state.isLoading,
            error: nil,
            templates: updatedTemplates,
            templateSearchQuery: state.templateSearchQuery
        )
    }
    
    private func deleteTemplate(templateId: UUID) async throws -> TaskState {
        guard state.templates.contains(where: { $0.id == templateId }) else {
            throw TaskError.templateNotFound(templateId)
        }
        
        let updatedTemplates = state.templates.filter { $0.id != templateId }
        
        return TaskState(
            tasks: state.tasks,
            categories: state.categories,
            filter: state.filter,
            isLoading: state.isLoading,
            error: nil,
            templates: updatedTemplates,
            templateSearchQuery: state.templateSearchQuery
        )
    }
    
    // MARK: - REQ-012: Bulk Operations Implementation
    
    private func toggleTaskSelection(id: UUID) async -> TaskState {
        var updatedSelections = state.selectedTaskIds
        
        if updatedSelections.contains(id) {
            updatedSelections.remove(id)
        } else {
            updatedSelections.insert(id)
        }
        
        return state.with { builder in
            builder.selectedTaskIds = updatedSelections
            builder.error = nil
        }
    }
    
    private func batchDeleteSelected() async throws -> TaskState {
        guard !state.selectedTaskIds.isEmpty else {
            throw TaskError.noTasksSelected
        }
        
        guard !state.isBatchOperationInProgress else {
            throw TaskError.batchOperationInProgress
        }
        
        // Framework Challenge: Batch operations with progress tracking
        let selectedIds = state.selectedTaskIds
        let totalTasks = selectedIds.count
        var processedTasks = 0
        
        // Start with progress tracking and lock flag
        var currentState = state.with { builder in
            builder.batchOperationProgress = 0.0
            builder.isBatchOperationInProgress = true
        }
        updateState(currentState)
        
        // Filter out selected tasks while tracking progress
        let filteredTasks = currentState.tasks.filter { task in
            let shouldKeep = !selectedIds.contains(task.id)
            if !shouldKeep {
                processedTasks += 1
                let progress = Double(processedTasks) / Double(totalTasks)
                
                // Update progress state
                currentState = currentState.with { builder in
                    builder.batchOperationProgress = progress
                }
                updateState(currentState)
                
                // Framework Challenge: Progress updates need to maintain 60fps
                // Small delay to simulate batch processing and test progress UI
                if processedTasks % 10 == 0 {
                    Task { try? await Task.sleep(nanoseconds: 1_000_000) } // 1ms delay every 10 items
                }
            }
            return shouldKeep
        }
        
        // Complete the operation
        return currentState.with { builder in
            builder.tasks = filteredTasks
            builder.selectedTaskIds = []
            builder.batchOperationProgress = nil
            builder.isBatchOperationInProgress = false
            builder.error = nil
        }
    }
    
    private func batchUpdateStatus(isCompleted: Bool) async throws -> TaskState {
        guard !state.selectedTaskIds.isEmpty else {
            throw TaskError.noTasksSelected
        }
        
        guard !state.isBatchOperationInProgress else {
            throw TaskError.batchOperationInProgress
        }
        
        let selectedIds = state.selectedTaskIds
        let totalTasks = selectedIds.count
        var processedTasks = 0
        
        // Start progress tracking and lock flag
        var currentState = state.with { builder in
            builder.batchOperationProgress = 0.0
            builder.isBatchOperationInProgress = true
        }
        updateState(currentState)
        
        // Update tasks with progress tracking
        let updatedTasks = currentState.tasks.map { task in
            if selectedIds.contains(task.id) {
                processedTasks += 1
                let progress = Double(processedTasks) / Double(totalTasks)
                
                // Update progress
                currentState = currentState.with { builder in
                    builder.batchOperationProgress = progress
                }
                updateState(currentState)
                
                // Framework Performance: Batch processing optimization
                if processedTasks % 50 == 0 {
                    Task { try? await Task.sleep(nanoseconds: 1_000_000) } // 1ms delay every 50 items
                }
                
                return TaskItem(
                    id: task.id,
                    title: task.title,
                    description: task.description,
                    categoryId: task.categoryId,
                    priority: task.priority,
                    isCompleted: isCompleted,
                    createdAt: task.createdAt,
                    updatedAt: Date(),
                    dueDate: task.dueDate,
                    parentId: task.parentId,
                    subtasks: task.subtasks,
                    dependencies: task.dependencies
                )
            }
            return task
        }
        
        return currentState.with { builder in
            builder.tasks = updatedTasks
            builder.selectedTaskIds = []
            builder.batchOperationProgress = nil
            builder.isBatchOperationInProgress = false
            builder.error = nil
        }
    }
    
    private func batchUpdateCategory(categoryId: UUID) async throws -> TaskState {
        guard !state.selectedTaskIds.isEmpty else {
            throw TaskError.noTasksSelected
        }
        
        guard !state.isBatchOperationInProgress else {
            throw TaskError.batchOperationInProgress
        }
        
        let selectedIds = state.selectedTaskIds
        let totalTasks = selectedIds.count
        var processedTasks = 0
        
        // Start progress tracking and lock flag
        var currentState = state.with { builder in
            builder.batchOperationProgress = 0.0
            builder.isBatchOperationInProgress = true
        }
        updateState(currentState)
        
        let updatedTasks = currentState.tasks.map { task in
            if selectedIds.contains(task.id) {
                processedTasks += 1
                let progress = Double(processedTasks) / Double(totalTasks)
                
                currentState = currentState.with { builder in
                    builder.batchOperationProgress = progress
                }
                updateState(currentState)
                
                if processedTasks % 50 == 0 {
                    Task { try? await Task.sleep(nanoseconds: 1_000_000) }
                }
                
                return TaskItem(
                    id: task.id,
                    title: task.title,
                    description: task.description,
                    categoryId: categoryId,
                    priority: task.priority,
                    isCompleted: task.isCompleted,
                    createdAt: task.createdAt,
                    updatedAt: Date(),
                    dueDate: task.dueDate,
                    parentId: task.parentId,
                    subtasks: task.subtasks,
                    dependencies: task.dependencies
                )
            }
            return task
        }
        
        return currentState.with { builder in
            builder.tasks = updatedTasks
            builder.selectedTaskIds = []
            builder.batchOperationProgress = nil
            builder.isBatchOperationInProgress = false
            builder.error = nil
        }
    }
    
    private func batchUpdatePriority(priority: Priority) async throws -> TaskState {
        guard !state.selectedTaskIds.isEmpty else {
            throw TaskError.noTasksSelected
        }
        
        guard !state.isBatchOperationInProgress else {
            throw TaskError.batchOperationInProgress
        }
        
        let selectedIds = state.selectedTaskIds
        let totalTasks = selectedIds.count
        var processedTasks = 0
        
        var currentState = state.with { builder in
            builder.batchOperationProgress = 0.0
        }
        updateState(currentState)
        
        let updatedTasks = currentState.tasks.map { task in
            if selectedIds.contains(task.id) {
                processedTasks += 1
                let progress = Double(processedTasks) / Double(totalTasks)
                
                currentState = currentState.with { builder in
                    builder.batchOperationProgress = progress
                }
                updateState(currentState)
                
                if processedTasks % 50 == 0 {
                    Task { try? await Task.sleep(nanoseconds: 1_000_000) }
                }
                
                return TaskItem(
                    id: task.id,
                    title: task.title,
                    description: task.description,
                    categoryId: task.categoryId,
                    priority: priority,
                    isCompleted: task.isCompleted,
                    createdAt: task.createdAt,
                    updatedAt: Date(),
                    dueDate: task.dueDate,
                    parentId: task.parentId,
                    subtasks: task.subtasks,
                    dependencies: task.dependencies
                )
            }
            return task
        }
        
        return currentState.with { builder in
            builder.tasks = updatedTasks
            builder.selectedTaskIds = []
            builder.batchOperationProgress = nil
            builder.isBatchOperationInProgress = false
            builder.error = nil
        }
    }
    
    private func cancelBatchOperation() async -> TaskState {
        return state.with { builder in
            builder.batchOperationProgress = nil
            builder.isBatchOperationInProgress = false
            builder.error = nil
        }
    }
    
    private func selectAllTasks() async -> TaskState {
        let allTaskIds = Set(state.filteredTasks.map { $0.id })
        return TaskState(
            tasks: state.tasks,
            categories: state.categories,
            filter: state.filter,
            isLoading: state.isLoading,
            error: state.error,
            templates: state.templates,
            templateSearchQuery: state.templateSearchQuery,
            selectedTaskIds: allTaskIds,
            batchOperationProgress: state.batchOperationProgress,
            isBatchOperationInProgress: state.isBatchOperationInProgress,
            isCreateTaskModalPresented: state.isCreateTaskModalPresented,
            showingDeleteConfirmation: state.showingDeleteConfirmation,
            deleteConfirmationTaskId: state.deleteConfirmationTaskId,
            editingTaskId: state.editingTaskId,
            isSearchActive: state.isSearchActive
        )
    }
}

// MARK: - Convenience Methods

extension TaskClient {
    /// Convenience method to match test/context expectations
    func send(_ action: TaskAction) async {
        do {
            try await process(action)
        } catch {
            // Log error if needed
        }
    }
    
    #if DEBUG
    /// Test helper to verify action processing completes
    func sendAndWait(_ action: TaskAction) async {
        await send(action)
        // Ensure state propagation with slightly longer delay
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
    }
    #endif
}