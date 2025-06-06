import Foundation
import Axiom

// MARK: - Task Validation Errors

enum TaskValidationError: Error, Equatable, LocalizedError {
    case missingTitle
    case descriptionTooLong(maxLength: Int)
    case duplicateId(String)
    case invalidDueDate
    case taskNotFound(String)
    case versionConflict(expectedVersion: Int, actualVersion: Int)
    case bulkDeletePartialFailure(failedIds: [String])
    case emptyBulkOperation
    case taskNotDeleted(id: String)
    case taskAlreadyDeleted(id: String)
    case categoryLimitExceeded(maxCategories: Int)
    case duplicateCategoryId(String)
    case categoryNotFound(String)
    case invalidColorFormat(String)
    case noTasksFoundForBatchUpdate
    
    var errorDescription: String? {
        switch self {
        case .missingTitle:
            return "Task title cannot be empty"
        case .descriptionTooLong(let maxLength):
            return "Task description exceeds maximum length of \(maxLength) characters"
        case .duplicateId(let id):
            return "A task with ID '\(id)' already exists"
        case .invalidDueDate:
            return "Due date must be in the future"
        case .taskNotFound(let id):
            return "Task with ID '\(id)' not found"
        case .versionConflict(let expectedVersion, let actualVersion):
            return "Version conflict: expected version \(expectedVersion) but found version \(actualVersion)"
        case .bulkDeletePartialFailure(let failedIds):
            return "Failed to delete tasks with IDs: \(failedIds.joined(separator: ", "))"
        case .emptyBulkOperation:
            return "Cannot perform bulk operation with empty list"
        case .taskNotDeleted(let id):
            return "Task '\(id)' is not deleted and cannot be restored"
        case .taskAlreadyDeleted(let id):
            return "Task '\(id)' is already deleted"
        case .categoryLimitExceeded(let maxCategories):
            return "Cannot create more than \(maxCategories) categories"
        case .duplicateCategoryId(let id):
            return "A category with ID '\(id)' already exists"
        case .categoryNotFound(let id):
            return "Category with ID '\(id)' not found"
        case .invalidColorFormat(let color):
            return "Invalid color format '\(color)'. Expected format: #RRGGBB"
        case .noTasksFoundForBatchUpdate:
            return "No tasks found for batch category assignment"
        }
    }
}

// REFACTOR Phase: Enhanced TaskClient with better validation and organization
/// A client responsible for managing task state and processing task-related actions.
/// 
/// This client implements the following features:
/// - CRUD operations for tasks
/// - Soft delete with retention periods
/// - Bulk operations for efficiency
/// - Version conflict detection
/// - Comprehensive validation
actor TaskClient: Client {
    typealias StateType = TaskListState
    typealias ActionType = TaskAction
    
    // MARK: - Properties
    
    private var state: TaskListState
    private let stateStreamContinuation: AsyncStream<TaskListState>.Continuation
    private let _stateStream: AsyncStream<TaskListState>
    
    // Dependencies (for future use)
    private let userId: String
    private let storageCapability: StorageCapability
    private let networkCapability: NetworkCapability
    private let notificationCapability: NotificationCapability
    
    // MARK: - Constants
    
    private let maxDescriptionLength = 500
    private let maxCategoriesPerUser = 20  // RFC requirement
    
    // MARK: - Client Protocol
    
    var stateStream: AsyncStream<TaskListState> {
        _stateStream
    }
    
    var currentState: TaskListState {
        state
    }
    
    init(
        userId: String,
        storageCapability: StorageCapability,
        networkCapability: NetworkCapability,
        notificationCapability: NotificationCapability
    ) {
        self.userId = userId
        self.storageCapability = storageCapability
        self.networkCapability = networkCapability
        self.notificationCapability = notificationCapability
        self.state = TaskListState()
        
        // Create state stream
        (_stateStream, stateStreamContinuation) = AsyncStream<TaskListState>.makeStream()
        
        // Emit initial state
        stateStreamContinuation.yield(state)
    }
    
    func process(_ action: TaskAction) async throws {
        switch action {
        // MARK: - Create/Update Operations
        case .create(let task):
            try await processCreateTask(task)
            
        case .update(let task):
            try await processUpdateTask(task)
            
        // MARK: - Delete Operations
        case .delete(let taskId):
            try await processHardDelete(taskId)
            
        case .deleteMultiple(let taskIds):
            try await processMultipleHardDeletes(taskIds)
            
        case .bulkDelete(let taskIds):
            try await processBulkHardDelete(taskIds)
            
        // MARK: - Soft Delete Operations
        case .softDelete(let taskId):
            try await processSoftDelete(taskId)
            
        case .softDeleteWithRetention(let taskId, let retentionDays):
            try await processSoftDeleteWithRetention(taskId, retentionDays: retentionDays)
            
        case .bulkSoftDeleteWithRetention(let taskIds, let retentionDays):
            try await processBulkSoftDeleteWithRetention(taskIds, retentionDays: retentionDays)
            
        case .undoDelete(let taskId):
            try await processUndoDelete(taskId)
            
        case .permanentDelete(let taskId):
            try await processPermanentDelete(taskId)
            
        // MARK: - Query Operations
        case .search(let query):
            updateState(searchQuery: query)
            
        case .sort(let criteria):
            updateState(sortCriteria: criteria)
            
        case .filterByCategory(let categoryId):
            updateState(selectedCategoryId: categoryId)
            
        // MARK: - Category Management Operations
        case .createCategory(let category):
            try await processCreateCategory(category)
            
        case .updateCategory(let category):
            try await processUpdateCategory(category)
            
        case .deleteCategory(let categoryId):
            try await processDeleteCategory(categoryId)
            
        case .batchAssignCategory(let taskIds, let categoryId):
            try await processBatchAssignCategory(taskIds: taskIds, categoryId: categoryId)
        }
    }
    
    // MARK: - Private Methods
    
    // MARK: - Validation Helpers
    
    private func validateTaskForCreation(_ task: Task) throws {
        try validateTaskContent(task)
        
        // Check for duplicate ID
        if state.tasks.contains(where: { $0.id == task.id }) {
            throw TaskValidationError.duplicateId(task.id)
        }
    }
    
    private func validateTaskForUpdate(_ task: Task) throws {
        try validateTaskContent(task)
    }
    
    /// Validates common task content (title and description)
    private func validateTaskContent(_ task: Task) throws {
        // Validate title
        let trimmedTitle = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw TaskValidationError.missingTitle
        }
        
        // Validate description length
        guard task.description.count <= maxDescriptionLength else {
            throw TaskValidationError.descriptionTooLong(maxLength: maxDescriptionLength)
        }
        
        // Validate due date if needed
        // This is a placeholder for future date validation
    }
    
    // MARK: - Task Index Helpers
    
    /// Finds the index of a task by ID
    private func findTaskIndex(byId taskId: String) -> Int? {
        state.tasks.firstIndex(where: { $0.id == taskId })
    }
    
    /// Finds the index of a non-deleted task by ID
    private func findActiveTaskIndex(byId taskId: String) -> Int? {
        state.tasks.firstIndex(where: { $0.id == taskId && !$0.isDeleted })
    }
    
    // MARK: - Create/Update Operations
    
    private func processCreateTask(_ task: Task) async throws {
        try validateTaskForCreation(task)
        
        // Ensure new tasks have version 1
        let newTask = Task(
            id: task.id,
            title: task.title,
            description: task.description,
            dueDate: task.dueDate,
            categoryId: task.categoryId,
            priority: task.priority,
            isCompleted: task.isCompleted,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            version: 1
        )
        
        var updatedTasks = state.tasks
        updatedTasks.append(newTask)
        updateState(tasks: updatedTasks)
        
        // Schedule notification if due date exists
        if let dueDate = newTask.dueDate {
            await scheduleNotificationForTask(newTask, dueDate: dueDate)
        }
    }
    
    private func processUpdateTask(_ task: Task) async throws {
        try validateTaskForUpdate(task)
        
        var updatedTasks = state.tasks
        guard let index = findTaskIndex(byId: task.id) else {
            throw TaskValidationError.taskNotFound(task.id)
        }
        
        let existingTask = updatedTasks[index]
        
        // Check for version conflict only if version is specified
        if let taskVersion = task.version,
           let existingVersion = existingTask.version,
           taskVersion < existingVersion {
            throw TaskValidationError.versionConflict(
                expectedVersion: taskVersion,
                actualVersion: existingVersion
            )
        }
        
        // Update with incremented version
        let updatedTask = Task(
            id: task.id,
            title: task.title,
            description: task.description,
            dueDate: task.dueDate,
            categoryId: task.categoryId,
            priority: task.priority,
            isCompleted: task.isCompleted,
            createdAt: existingTask.createdAt,
            updatedAt: Date(),
            version: (existingTask.version ?? 0) + 1
        )
        
        updatedTasks[index] = updatedTask
        updateState(tasks: updatedTasks)
        
        // Handle notification updates
        await updateNotificationForTask(existingTask, updatedTask: updatedTask)
    }
    
    // MARK: - Hard Delete Operations
    
    private func processHardDelete(_ taskId: String) async throws {
        guard let taskIndex = findActiveTaskIndex(byId: taskId) else {
            throw TaskValidationError.taskNotFound(taskId)
        }
        
        // Cancel notification if task had a due date
        let task = state.tasks[taskIndex]
        if task.dueDate != nil {
            await cancelNotificationForTask(taskId)
        }
        
        var updatedTasks = state.tasks
        updatedTasks.removeAll { $0.id == taskId }
        updateState(tasks: updatedTasks)
    }
    
    private func processMultipleHardDeletes(_ taskIds: Set<String>) async throws {
        try validateTasksExistForDeletion(taskIds)
        
        var updatedTasks = state.tasks
        updatedTasks.removeAll { taskIds.contains($0.id) }
        updateState(tasks: updatedTasks)
    }
    
    private func processBulkHardDelete(_ taskIds: [String]) async throws {
        guard !taskIds.isEmpty else {
            throw TaskValidationError.emptyBulkOperation
        }
        
        let taskIdSet = Set(taskIds)
        try validateTasksExistForDeletion(taskIdSet)
        
        var updatedTasks = state.tasks
        updatedTasks.removeAll { taskIdSet.contains($0.id) }
        updateState(tasks: updatedTasks)
    }
    
    // MARK: - Soft Delete Operations
    
    /// Soft deletes a task, marking it as deleted without removing it from storage
    /// - Parameter taskId: The ID of the task to soft delete
    /// - Note: Soft-deleted tasks remain in the system and can be restored using `undoDelete`
    private func processSoftDelete(_ taskId: String) async throws {
        var updatedTasks = state.tasks
        guard let index = findTaskIndex(byId: taskId) else {
            throw TaskValidationError.taskNotFound(taskId)
        }
        
        let task = updatedTasks[index]
        if task.isDeleted {
            throw TaskValidationError.taskAlreadyDeleted(id: taskId)
        }
        
        let softDeletedTask = task.updated(
            isDeleted: true,
            deletedAt: Date()
        )
        updatedTasks[index] = softDeletedTask
        updateState(tasks: updatedTasks)
    }
    
    /// Soft deletes a task with a specified retention period
    /// - Parameters:
    ///   - taskId: The ID of the task to soft delete
    ///   - retentionDays: Number of days to retain the soft-deleted task before automatic purge
    /// - Note: The task will be automatically scheduled for permanent deletion after the retention period
    private func processSoftDeleteWithRetention(_ taskId: String, retentionDays: Int) async throws {
        var updatedTasks = state.tasks
        guard let index = findActiveTaskIndex(byId: taskId) else {
            throw TaskValidationError.taskNotFound(taskId)
        }
        
        let task = updatedTasks[index]
        let deletedAt = Date()
        let softDeletedTask = task.updated(
            isDeleted: true,
            deletedAt: deletedAt,
            retentionDays: retentionDays
        )
        updatedTasks[index] = softDeletedTask
        updateState(tasks: updatedTasks)
    }
    
    /// Bulk soft deletes multiple tasks with a retention period
    /// - Parameters:
    ///   - taskIds: Array of task IDs to soft delete
    ///   - retentionDays: Number of days to retain the soft-deleted tasks
    /// - Note: This operation is forgiving - it skips tasks that don't exist rather than failing completely
    private func processBulkSoftDeleteWithRetention(_ taskIds: [String], retentionDays: Int) async throws {
        guard !taskIds.isEmpty else {
            throw TaskValidationError.emptyBulkOperation
        }
        
        var updatedTasks = state.tasks
        let deletedAt = Date()
        
        for taskId in taskIds {
            guard let index = findActiveTaskIndex(byId: taskId) else {
                continue // Skip missing tasks for bulk operations
            }
            
            let task = updatedTasks[index]
            let softDeletedTask = task.updated(
                isDeleted: true,
                deletedAt: deletedAt,
                retentionDays: retentionDays
            )
            updatedTasks[index] = softDeletedTask
        }
        
        updateState(tasks: updatedTasks)
    }
    
    /// Restores a soft-deleted task
    /// - Parameter taskId: The ID of the task to restore
    /// - Note: Only soft-deleted tasks can be restored. This increments the task version.
    private func processUndoDelete(_ taskId: String) async throws {
        var updatedTasks = state.tasks
        guard let index = findTaskIndex(byId: taskId) else {
            throw TaskValidationError.taskNotFound(taskId)
        }
        
        let task = updatedTasks[index]
        guard task.isDeleted else {
            throw TaskValidationError.taskNotDeleted(id: taskId)
        }
        
        let restoredTask = Task(
            id: task.id,
            title: task.title,
            description: task.description,
            dueDate: task.dueDate,
            categoryId: task.categoryId,
            priority: task.priority,
            isCompleted: task.isCompleted,
            createdAt: task.createdAt,
            updatedAt: Date(),
            version: (task.version ?? 0) + 1,
            isDeleted: false,
            deletedAt: nil,
            retentionDays: nil,
            scheduledPurgeDate: nil
        )
        updatedTasks[index] = restoredTask
        updateState(tasks: updatedTasks)
    }
    
    /// Permanently deletes a soft-deleted task
    /// - Parameter taskId: The ID of the task to permanently delete
    /// - Note: Only soft-deleted tasks can be permanently deleted. This action cannot be undone.
    private func processPermanentDelete(_ taskId: String) async throws {
        var updatedTasks = state.tasks
        guard let index = findTaskIndex(byId: taskId) else {
            throw TaskValidationError.taskNotFound(taskId)
        }
        
        let task = updatedTasks[index]
        guard task.isDeleted else {
            throw TaskValidationError.taskNotDeleted(id: taskId)
        }
        
        updatedTasks.remove(at: index)
        updateState(tasks: updatedTasks)
    }
    
    // MARK: - Validation Helpers
    
    /// Validates that all task IDs exist and are not deleted
    private func validateTasksExistForDeletion(_ taskIds: Set<String>) throws {
        let existingIds = Set(state.tasks.filter { !$0.isDeleted }.map { $0.id })
        let missingIds = taskIds.subtracting(existingIds)
        
        guard missingIds.isEmpty else {
            throw TaskValidationError.bulkDeletePartialFailure(failedIds: Array(missingIds))
        }
    }
    
    // MARK: - Category Management Operations
    
    private func processCreateCategory(_ category: Category) async throws {
        // Validate maximum categories limit (20 per RFC)
        guard state.categories.count < maxCategoriesPerUser else {
            throw TaskValidationError.categoryLimitExceeded(maxCategories: maxCategoriesPerUser)
        }
        
        // Validate unique ID
        if state.categories.contains(where: { $0.id == category.id }) {
            throw TaskValidationError.duplicateCategoryId(category.id)
        }
        
        // Validate color format
        try validateColorFormat(category.color)
        
        var updatedCategories = state.categories
        updatedCategories.append(category)
        updateState(categories: updatedCategories)
    }
    
    private func processUpdateCategory(_ category: Category) async throws {
        var updatedCategories = state.categories
        guard let index = updatedCategories.firstIndex(where: { $0.id == category.id }) else {
            throw TaskValidationError.categoryNotFound(category.id)
        }
        
        // Validate color format
        try validateColorFormat(category.color)
        
        updatedCategories[index] = category
        updateState(categories: updatedCategories)
    }
    
    private func processDeleteCategory(_ categoryId: String) async throws {
        var updatedCategories = state.categories
        guard let index = updatedCategories.firstIndex(where: { $0.id == categoryId }) else {
            throw TaskValidationError.categoryNotFound(categoryId)
        }
        
        // Remove category
        updatedCategories.remove(at: index)
        
        // Remove category from all tasks
        var updatedTasks = state.tasks
        for (index, task) in updatedTasks.enumerated() {
            if task.categoryId == categoryId {
                // Use the Task initializer to create a new task with nil categoryId
                let modifiedTask = Task(
                    id: task.id,
                    title: task.title,
                    description: task.description,
                    dueDate: task.dueDate,
                    categoryId: nil,  // Remove category
                    priority: task.priority,
                    isCompleted: task.isCompleted,
                    createdAt: task.createdAt,
                    updatedAt: Date(),
                    version: (task.version ?? 0) + 1,
                    isDeleted: task.isDeleted,
                    deletedAt: task.deletedAt,
                    retentionDays: task.retentionDays,
                    scheduledPurgeDate: task.scheduledPurgeDate
                )
                updatedTasks[index] = modifiedTask
            }
        }
        
        updateState(tasks: updatedTasks, categories: updatedCategories)
    }
    
    private func processBatchAssignCategory(taskIds: Set<String>, categoryId: String?) async throws {
        // If categoryId is provided, validate it exists
        if let categoryId = categoryId {
            guard state.categories.contains(where: { $0.id == categoryId }) else {
                throw TaskValidationError.categoryNotFound(categoryId)
            }
        }
        
        // Update all matching tasks
        var updatedTasks = state.tasks
        var updatedCount = 0
        
        for (index, task) in updatedTasks.enumerated() {
            if taskIds.contains(task.id) {
                // Create a new task with updated categoryId
                let modifiedTask = Task(
                    id: task.id,
                    title: task.title,
                    description: task.description,
                    dueDate: task.dueDate,
                    categoryId: categoryId,  // Assign new category
                    priority: task.priority,
                    isCompleted: task.isCompleted,
                    createdAt: task.createdAt,
                    updatedAt: Date(),
                    version: (task.version ?? 0) + 1,
                    isDeleted: task.isDeleted,
                    deletedAt: task.deletedAt,
                    retentionDays: task.retentionDays,
                    scheduledPurgeDate: task.scheduledPurgeDate
                )
                updatedTasks[index] = modifiedTask
                updatedCount += 1
            }
        }
        
        // Validate that at least some tasks were updated
        guard updatedCount > 0 else {
            throw TaskValidationError.noTasksFoundForBatchUpdate
        }
        
        updateState(tasks: updatedTasks)
    }
    
    private func validateColorFormat(_ color: String) throws {
        // Color must be in format #RRGGBB (6 hex digits preceded by #)
        let colorRegex = #"^#[0-9A-Fa-f]{6}$"#
        let colorPredicate = NSPredicate(format: "SELF MATCHES %@", colorRegex)
        
        guard colorPredicate.evaluate(with: color) else {
            throw TaskValidationError.invalidColorFormat(color)
        }
    }
    
    private func updateState(
        tasks: [Task]? = nil,
        categories: [Category]? = nil,
        searchQuery: String? = nil,
        sortCriteria: SortCriteria? = nil,
        selectedCategoryId: String?? = nil
    ) {
        // Get the tasks to use (new tasks or existing)
        var tasksToSort = tasks ?? state.tasks
        
        // Get the sort criteria to use (new criteria or existing)
        let criteriaToUse = sortCriteria ?? state.sortCriteria
        
        // Apply sorting
        tasksToSort = sortTasks(tasksToSort, by: criteriaToUse)
        
        state = TaskListState(
            tasks: tasksToSort,
            categories: categories ?? state.categories,
            searchQuery: searchQuery ?? state.searchQuery,
            sortCriteria: criteriaToUse,
            selectedCategoryId: selectedCategoryId ?? state.selectedCategoryId
        )
        stateStreamContinuation.yield(state)
    }
    
    /// Sorts tasks according to the specified criteria
    private func sortTasks(_ tasks: [Task], by criteria: SortCriteria) -> [Task] {
        switch criteria {
        case .priority(let ascending):
            // Sort by priority (critical → high → medium → low for ascending)
            // For same priority, maintain stable order by creation date
            return tasks.sorted { task1, task2 in
                if task1.priority != task2.priority {
                    // Priority order: critical (0) < high (1) < medium (2) < low (3)
                    let comparison = priorityValue(task1.priority) < priorityValue(task2.priority)
                    return ascending ? comparison : !comparison
                } else {
                    // Same priority: sort by creation date (older first)
                    return task1.createdAt < task2.createdAt
                }
            }
            
        case .dueDate(let ascending):
            // Sort by due date (earliest first for ascending, nil dates last)
            return tasks.sorted { task1, task2 in
                switch (task1.dueDate, task2.dueDate) {
                case (nil, nil):
                    return task1.createdAt < task2.createdAt
                case (nil, _):
                    return false
                case (_, nil):
                    return true
                case (let date1?, let date2?):
                    let comparison = date1 < date2
                    return ascending ? comparison : !comparison
                }
            }
            
        case .createdDate(let ascending):
            // Sort by creation date
            return tasks.sorted { task1, task2 in
                let comparison = task1.createdAt < task2.createdAt
                return ascending ? comparison : !comparison
            }
            
        case .title(let ascending):
            // Sort alphabetically by title
            return tasks.sorted { task1, task2 in
                let comparison = task1.title.localizedCaseInsensitiveCompare(task2.title) == .orderedAscending
                return ascending ? comparison : !comparison
            }
        }
    }
    
    /// Returns numeric value for priority ordering
    private func priorityValue(_ priority: Priority) -> Int {
        switch priority {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
    
    // MARK: - Notification Management
    
    /// Schedules a notification for a task with a due date
    private func scheduleNotificationForTask(_ task: Task, dueDate: Date) async {
        let notification = LocalNotification(
            id: "task-due-\(task.id)",
            title: "Task Due: \(task.title)",
            body: task.description.isEmpty ? "Task is due now" : task.description,
            scheduledDate: dueDate,
            categoryIdentifier: "TASK_DUE",
            userInfo: ["taskId": task.id]
        )
        
        do {
            try await notificationCapability.schedule(notification)
        } catch {
            // Log error but don't fail the task operation
            print("Failed to schedule notification for task \(task.id): \(error)")
        }
    }
    
    /// Updates notifications when a task is modified
    private func updateNotificationForTask(_ oldTask: Task, updatedTask: Task) async {
        let notificationId = "task-due-\(oldTask.id)"
        
        // If due date was removed, cancel the notification
        if oldTask.dueDate != nil && updatedTask.dueDate == nil {
            await notificationCapability.cancel(notificationId: notificationId)
        }
        // If due date was added or changed, reschedule
        else if let newDueDate = updatedTask.dueDate,
                newDueDate != oldTask.dueDate {
            // Cancel old notification if it existed
            if oldTask.dueDate != nil {
                await notificationCapability.cancel(notificationId: notificationId)
            }
            // Schedule new notification
            await scheduleNotificationForTask(updatedTask, dueDate: newDueDate)
        }
    }
    
    /// Cancels notification for a task being deleted
    private func cancelNotificationForTask(_ taskId: String) async {
        let notificationId = "task-due-\(taskId)"
        await notificationCapability.cancel(notificationId: notificationId)
    }
}