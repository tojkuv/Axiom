import Foundation
import SwiftUI
import Axiom

// Import shared Task Manager components
import TaskManager_Shared

// MARK: - Task Detail Context (macOS)

/// Context for displaying and editing task details on macOS with desktop-specific features
@MainActor
public final class TaskDetailContext: ClientObservingContext<TaskClient> {
    
    // MARK: - Published Properties
    @Published public private(set) var task: Task?
    @Published public private(set) var originalTask: Task?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var isSaving: Bool = false
    @Published public private(set) var error: String? = nil
    @Published public private(set) var hasUnsavedChanges: Bool = false
    
    // Editing state
    @Published public var editingTitle: String = ""
    @Published public var editingDescription: String = ""
    @Published public var editingPriority: Priority = .medium
    @Published public var editingCategory: TaskManager_Shared.Category = .personal
    @Published public var editingDueDate: Date?
    @Published public var isEditingDueDate: Bool = false
    @Published public var editingNotes: String = ""
    
    // Window management
    @Published public private(set) var windowTitle: String = "Task Details"
    @Published public private(set) var shouldCloseWindow: Bool = false
    
    // View state
    @Published public var isEditing: Bool = false
    @Published public var showingDeleteConfirmation: Bool = false
    
    // MARK: - Private Properties
    private var taskId: UUID?
    private var autoSaveTimer: Timer?
    
    // MARK: - Initialization
    
    public required init() {
        fatalError("Use init(client:) instead")
    }
    
    public override init(client: TaskClient) {
        super.init(client: client)
        setupAutoSave()
    }
    
    // MARK: - Lifecycle
    
    public override func appeared() async {
        await super.appeared()
        if let taskId = taskId {
            await loadTask(taskId: taskId)
        }
    }
    
    public override func disappeared() async {
        await super.disappeared()
        stopAutoSave()
        
        // Save changes if any
        if hasUnsavedChanges {
            await saveChanges()
        }
    }
    
    public override func handleStateUpdate(_ state: TaskManagerState) async {
        await MainActor.run {
            // Update task if it exists in the state
            if let taskId = self.taskId,
               let updatedTask = state.task(withId: taskId) {
                self.task = updatedTask
                
                // Update window title
                self.windowTitle = updatedTask.title.isEmpty ? "Task Details" : updatedTask.title
                
                // Clear error state
                self.error = nil
            } else if let taskId = self.taskId {
                // Task was deleted
                self.task = nil
                self.shouldCloseWindow = true
            }
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
        
        do {
            let state = await client.getCurrentState()
            
            await MainActor.run {
                if let foundTask = state.task(withId: taskId) {
                    self.task = foundTask
                    self.originalTask = foundTask
                    self.setupEditingState(from: foundTask)
                    self.windowTitle = foundTask.title.isEmpty ? "Task Details" : foundTask.title
                } else {
                    self.error = "Task not found"
                    self.shouldCloseWindow = true
                }
            }
        } catch {
            await setError("Failed to load task: \(error.localizedDescription)")
        }
        
        await setLoading(false)
    }
    
    private func setupEditingState(from task: Task) {
        editingTitle = task.title
        editingDescription = task.taskDescription
        editingPriority = task.priority
        editingCategory = task.category
        editingDueDate = task.dueDate
        isEditingDueDate = task.dueDate != nil
        editingNotes = task.notes
        hasUnsavedChanges = false
    }
    
    // MARK: - Editing Actions
    
    public func startEditing() async {
        await MainActor.run {
            isEditing = true
            // Reset editing state to current task values
            if let task = task {
                setupEditingState(from: task)
            }
        }
    }
    
    public func cancelEditing() async {
        await MainActor.run {
            isEditing = false
            hasUnsavedChanges = false
            
            // Reset editing state to original values
            if let task = task {
                setupEditingState(from: task)
            }
        }
    }
    
    public func saveChanges() async {
        guard let taskId = taskId, hasUnsavedChanges else { return }
        
        await setSaving(true)
        
        do {
            // Update task with edited values
            try await client.process(.updateTask(
                taskId: taskId,
                title: editingTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: editingDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                priority: editingPriority,
                category: editingCategory,
                dueDate: isEditingDueDate ? editingDueDate : nil,
                notes: editingNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
            
            await MainActor.run {
                isEditing = false
                hasUnsavedChanges = false
            }
            
        } catch {
            await setError("Failed to save changes: \(error.localizedDescription)")
        }
        
        await setSaving(false)
    }
    
    public func deleteTask() async {
        guard let taskId = taskId else { return }
        
        do {
            try await client.process(.deleteTask(taskId: taskId))
            
            await MainActor.run {
                shouldCloseWindow = true
            }
        } catch {
            await setError("Failed to delete task: \(error.localizedDescription)")
        }
    }
    
    public func toggleTaskCompletion() async {
        guard let taskId = taskId else { return }
        
        do {
            try await client.process(.toggleTaskCompletion(taskId: taskId))
        } catch {
            await setError("Failed to toggle task completion: \(error.localizedDescription)")
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
    
    // MARK: - Field Updates
    
    public func updateTitle(_ newTitle: String) async {
        await MainActor.run {
            editingTitle = newTitle
            updateHasUnsavedChanges()
        }
    }
    
    public func updateDescription(_ newDescription: String) async {
        await MainActor.run {
            editingDescription = newDescription
            updateHasUnsavedChanges()
        }
    }
    
    public func updatePriority(_ newPriority: Priority) async {
        await MainActor.run {
            editingPriority = newPriority
            updateHasUnsavedChanges()
        }
    }
    
    public func updateCategory(_ newCategory: TaskManager_Shared.Category) async {
        await MainActor.run {
            editingCategory = newCategory
            updateHasUnsavedChanges()
        }
    }
    
    public func updateDueDate(_ newDate: Date?) async {
        await MainActor.run {
            editingDueDate = newDate
            updateHasUnsavedChanges()
        }
    }
    
    public func toggleDueDateEditing(_ enabled: Bool) async {
        await MainActor.run {
            isEditingDueDate = enabled
            if !enabled {
                editingDueDate = nil
            }
            updateHasUnsavedChanges()
        }
    }
    
    public func updateNotes(_ newNotes: String) async {
        await MainActor.run {
            editingNotes = newNotes
            updateHasUnsavedChanges()
        }
    }
    
    private func updateHasUnsavedChanges() {
        guard let originalTask = originalTask else {
            hasUnsavedChanges = false
            return
        }
        
        let titleChanged = editingTitle != originalTask.title
        let descriptionChanged = editingDescription != originalTask.taskDescription
        let priorityChanged = editingPriority != originalTask.priority
        let categoryChanged = editingCategory != originalTask.category
        let dueDateChanged = editingDueDate != originalTask.dueDate
        let notesChanged = editingNotes != originalTask.notes
        
        hasUnsavedChanges = titleChanged || descriptionChanged || priorityChanged || 
                           categoryChanged || dueDateChanged || notesChanged
    }
    
    // MARK: - Auto-Save
    
    private func setupAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                await self?.autoSave()
            }
        }
    }
    
    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    private func autoSave() async {
        guard isEditing && hasUnsavedChanges && !isSaving else { return }
        await saveChanges()
    }
    
    // MARK: - Window Management
    
    public func requestCloseWindow() async {
        if hasUnsavedChanges {
            // In a real implementation, this would show a confirmation dialog
            // For now, we'll auto-save
            await saveChanges()
        }
        
        await MainActor.run {
            shouldCloseWindow = true
        }
    }
    
    public func resetCloseRequest() async {
        await MainActor.run {
            shouldCloseWindow = false
        }
    }
    
    // MARK: - Helper Methods
    
    private func setLoading(_ loading: Bool) async {
        await MainActor.run {
            isLoading = loading
        }
    }
    
    private func setSaving(_ saving: Bool) async {
        await MainActor.run {
            isSaving = saving
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
    
    public var canSave: Bool {
        !editingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        hasUnsavedChanges && !isSaving
    }
    
    public var isOverdue: Bool {
        guard let task = task,
              let dueDate = task.dueDate else { return false }
        return !task.isCompleted && dueDate < Date()
    }
    
    public var formattedDueDate: String? {
        guard let dueDate = task?.dueDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }
    
    public var priorityColor: Color {
        guard let task = task else { return .secondary }
        
        switch task.priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
    
    public var categoryColor: Color {
        guard let task = task else { return .secondary }
        
        switch task.category {
        case .work:
            return .blue
        case .personal:
            return .green
        case .shopping:
            return .purple
        case .health:
            return .red
        case .finance:
            return .orange
        }
    }
    
    // MARK: - Keyboard Shortcuts
    
    public func handleKeyboardShortcut(_ shortcut: KeyboardShortcut) async {
        switch shortcut {
        case .save:
            if canSave {
                await saveChanges()
            }
        case .edit:
            if !isEditing {
                await startEditing()
            }
        case .cancel:
            if isEditing {
                await cancelEditing()
            }
        case .delete:
            await MainActor.run {
                showingDeleteConfirmation = true
            }
        case .duplicate:
            await duplicateTask()
        case .toggleComplete:
            await toggleTaskCompletion()
        }
    }
}

// MARK: - Supporting Types

public enum KeyboardShortcut {
    case save
    case edit
    case cancel
    case delete
    case duplicate
    case toggleComplete
}