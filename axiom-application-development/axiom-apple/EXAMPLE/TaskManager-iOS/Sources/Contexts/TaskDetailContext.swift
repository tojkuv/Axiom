import Foundation
import SwiftUI
import Axiom

// Import shared Task Manager components
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared

// MARK: - Task Detail Context (iOS)

/// Context for viewing and editing a single task on iOS
@MainActor
public final class TaskDetailContext: AxiomClientObservingContext<TaskClient> {
    
    // MARK: - Published Properties
    @Published public private(set) var task: Task?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var error: String? = nil
    @Published public private(set) var isEditing: Bool = false
    
    // Edit form state
    @Published public var editTitle: String = ""
    @Published public var editDescription: String = ""
    @Published public var editPriority: Priority = .medium
    @Published public var editCategory: Category = .personal
    @Published public var editDueDate: Date? = nil
    @Published public var editTags: Set<String> = []
    @Published public var hasUnsavedChanges: Bool = false
    
    // Private state
    private var taskId: UUID?
    private var originalTask: Task?
    
    // MARK: - Initialization
    
    public required init() {
        fatalError("Use init(client:) instead")
    }
    
    public init(client: TaskClient) {
        super.init(client: client)
    }
    
    // MARK: - Lifecycle
    
    public override func appeared() async {
        await super.appeared()
        if let taskId = taskId {
            await loadTask(taskId: taskId)
        }
    }
    
    public override func handleStateUpdate(_ state: TaskManagerState) async {
        await MainActor.run {
            if let taskId = self.taskId,
               let updatedTask = state.task(withId: taskId) {
                self.task = updatedTask
                
                // Update edit form if not currently editing or no unsaved changes
                if !isEditing || !hasUnsavedChanges {
                    self.populateEditForm(from: updatedTask)
                }
            }
            self.error = nil
        }
    }
    
    // MARK: - Task Management
    
    public func setTaskId(_ id: UUID) async {
        await MainActor.run {
            taskId = id
        }
        await loadTask(taskId: id)
    }
    
    public func getTaskId() async -> UUID? {
        return taskId
    }
    
    private func loadTask(taskId: UUID) async {
        await setLoading(true)
        
        // Get current task from state
        let currentState = await client.getCurrentState()
        await MainActor.run {
            task = currentState.task(withId: taskId)
            if let task = self.task {
                populateEditForm(from: task)
                originalTask = task
            }
        }
        
        await setLoading(false)
    }
    
    // MARK: - Task Actions
    
    public func toggleCompletion() async {
        guard let taskId = taskId else { return }
        
        do {
            try await client.process(.toggleTaskCompletion(taskId: taskId))
        } catch {
            await setError("Failed to toggle completion: \(error.localizedDescription)")
        }
    }
    
    public func deleteTask() async {
        guard let taskId = taskId else { return }
        
        do {
            try await client.process(.deleteTask(taskId: taskId))
        } catch {
            await setError("Failed to delete task: \(error.localizedDescription)")
        }
    }
    
    public func duplicateTask() async {
        guard let taskId = taskId else { return }
        
        do {
            try await client.process(.duplicateTask(taskId: taskId))
        } catch {
            await setError("Failed to duplicate task: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Edit Mode Management
    
    public func startEditing() async {
        await MainActor.run {
            isEditing = true
            if let task = self.task {
                populateEditForm(from: task)
                originalTask = task
            }
        }
    }
    
    public func cancelEditing() async {
        await MainActor.run {
            isEditing = false
            hasUnsavedChanges = false
            if let originalTask = self.originalTask {
                populateEditForm(from: originalTask)
            }
        }
    }
    
    public func saveChanges() async {
        guard let taskId = taskId, hasUnsavedChanges else { return }
        
        await setLoading(true)
        
        let updates = TaskUpdate(
            title: editTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editTitle,
            taskDescription: editDescription,
            priority: editPriority,
            category: editCategory,
            dueDate: editDueDate,
            tags: editTags
        )
        
        do {
            try await client.process(.updateTask(taskId: taskId, updates: updates))
            await MainActor.run {
                isEditing = false
                hasUnsavedChanges = false
            }
        } catch {
            await setError("Failed to save changes: \(error.localizedDescription)")
        }
        
        await setLoading(false)
    }
    
    // MARK: - Form Management
    
    private func populateEditForm(from task: Task) {
        editTitle = task.title
        editDescription = task.taskDescription
        editPriority = task.priority
        editCategory = task.category
        editDueDate = task.dueDate
        editTags = task.tags
        hasUnsavedChanges = false
    }
    
    public func updateEditTitle(_ title: String) async {
        await MainActor.run {
            editTitle = title
            checkForUnsavedChanges()
        }
    }
    
    public func updateEditDescription(_ description: String) async {
        await MainActor.run {
            editDescription = description
            checkForUnsavedChanges()
        }
    }
    
    public func updateEditPriority(_ priority: Priority) async {
        await MainActor.run {
            editPriority = priority
            checkForUnsavedChanges()
        }
    }
    
    public func updateEditCategory(_ category: Category) async {
        await MainActor.run {
            editCategory = category
            checkForUnsavedChanges()
        }
    }
    
    public func updateEditDueDate(_ dueDate: Date?) async {
        await MainActor.run {
            editDueDate = dueDate
            checkForUnsavedChanges()
        }
    }
    
    public func addEditTag(_ tag: String) async {
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty else { return }
        
        await MainActor.run {
            editTags.insert(trimmedTag)
            checkForUnsavedChanges()
        }
    }
    
    public func removeEditTag(_ tag: String) async {
        await MainActor.run {
            editTags.remove(tag)
            checkForUnsavedChanges()
        }
    }
    
    private func checkForUnsavedChanges() {
        guard let originalTask = originalTask else {
            hasUnsavedChanges = false
            return
        }
        
        let hasChanges = editTitle != originalTask.title ||
                        editDescription != originalTask.taskDescription ||
                        editPriority != originalTask.priority ||
                        editCategory != originalTask.category ||
                        editDueDate != originalTask.dueDate ||
                        editTags != originalTask.tags
        
        hasUnsavedChanges = hasChanges
    }
    
    // MARK: - Validation
    
    public var canSave: Bool {
        !editTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasUnsavedChanges
    }
    
    public var formValidationErrors: [String] {
        var errors: [String] = []
        
        if editTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Title cannot be empty")
        }
        
        if let dueDate = editDueDate, dueDate < Date() {
            errors.append("Due date cannot be in the past")
        }
        
        return errors
    }
    
    // MARK: - Quick Actions
    
    public func quickSetPriority(_ priority: Priority) async {
        guard let taskId = taskId else { return }
        
        let updates = TaskUpdate(priority: priority)
        
        do {
            try await client.process(.updateTask(taskId: taskId, updates: updates))
        } catch {
            await setError("Failed to update priority: \(error.localizedDescription)")
        }
    }
    
    public func quickSetCategory(_ category: Category) async {
        guard let taskId = taskId else { return }
        
        let updates = TaskUpdate(category: category)
        
        do {
            try await client.process(.updateTask(taskId: taskId, updates: updates))
        } catch {
            await setError("Failed to update category: \(error.localizedDescription)")
        }
    }
    
    public func quickSetDueDate(_ dueDate: Date?) async {
        guard let taskId = taskId else { return }
        
        let updates = TaskUpdate(dueDate: dueDate)
        
        do {
            try await client.process(.updateTask(taskId: taskId, updates: updates))
        } catch {
            await setError("Failed to update due date: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func setLoading(_ loading: Bool) async {
        await MainActor.run {
            isLoading = loading
        }
    }
    
    private func setError(_ errorMessage: String) async {
        await MainActor.run {
            error = errorMessage
        }
    }
    
    public func clearError() async {
        await MainActor.run {
            error = nil
        }
    }
    
    // MARK: - Computed Properties
    
    public var hasTask: Bool {
        task != nil
    }
    
    public var taskExists: Bool {
        task != nil
    }
    
    public var isTaskCompleted: Bool {
        task?.isCompleted ?? false
    }
    
    public var isTaskOverdue: Bool {
        task?.isOverdue ?? false
    }
    
    public var taskDueDateDescription: String? {
        task?.dueDateDescription
    }
    
    // MARK: - Navigation Support
    
    public func canNavigateAway() async -> Bool {
        return !hasUnsavedChanges
    }
    
    public func handleNavigationAttempt() async -> Bool {
        if hasUnsavedChanges {
            // In a real app, this would show a confirmation dialog
            return false
        }
        return true
    }
}