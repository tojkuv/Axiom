import Foundation
import SwiftUI
import Combine
import Axiom

// Import shared Task Manager components
import TaskManager_Shared

// MARK: - Create Task Context (macOS)

/// Context for creating new tasks on macOS with enhanced form capabilities
@MainActor
public final class CreateTaskContext: ClientObservingContext<TaskClient> {
    
    // MARK: - Published Properties
    @Published public var title: String = ""
    @Published public var taskDescription: String = ""
    @Published public var priority: Priority = .medium
    @Published public var category: TaskManager_Shared.Category = .personal
    @Published public var dueDate: Date?
    @Published public var hasDueDate: Bool = false
    @Published public var notes: String = ""
    @Published public var reminderTime: Date?
    @Published public var hasReminder: Bool = false
    
    // State management
    @Published public private(set) var isCreating: Bool = false
    @Published public private(set) var error: String? = nil
    @Published public private(set) var validationErrors: [ValidationError] = []
    @Published public private(set) var shouldCloseWindow: Bool = false
    @Published public private(set) var wasTaskCreated: Bool = false
    
    // Form validation
    @Published public private(set) var isTitleValid: Bool = false
    @Published public private(set) var canCreateTask: Bool = false
    
    // Settings integration
    @Published public private(set) var defaultSettings: CreateTaskDefaults?
    
    // Advanced options
    @Published public var showAdvancedOptions: Bool = false
    @Published public var tags: [String] = []
    @Published public var currentTag: String = ""
    @Published public var estimatedDuration: TimeInterval?
    @Published public var hasEstimatedDuration: Bool = false
    
    // Template support
    @Published public private(set) var availableTemplates: [TaskTemplate] = []
    @Published public var selectedTemplate: TaskTemplate?
    
    // MARK: - Initialization
    
    public required init() {
        fatalError("Use init(client:) instead")
    }
    
    public override init(client: TaskClient) {
        super.init(client: client)
        setupValidation()
        loadDefaultSettings()
        loadTemplates()
    }
    
    // MARK: - Lifecycle
    
    public override func appeared() async {
        await super.appeared()
        await loadDefaults()
        await resetForm()
    }
    
    public override func handleStateUpdate(_ state: TaskManagerState) async {
        // Update validation based on existing tasks if needed
        await MainActor.run {
            updateValidation()
        }
    }
    
    // MARK: - Form Management
    
    private func resetForm() async {
        await MainActor.run {
            title = ""
            taskDescription = ""
            notes = ""
            tags = []
            currentTag = ""
            reminderTime = nil
            hasReminder = false
            estimatedDuration = nil
            hasEstimatedDuration = false
            selectedTemplate = nil
            
            // Apply defaults if available
            if let defaults = defaultSettings {
                priority = defaults.defaultPriority
                category = defaults.defaultCategory
                if defaults.defaultHasDueDate {
                    hasDueDate = true
                    dueDate = defaults.defaultDueDate
                }
            }
            
            error = nil
            validationErrors = []
            wasTaskCreated = false
            shouldCloseWindow = false
            
            updateValidation()
        }
    }
    
    private func loadDefaults() async {
        // In a real implementation, this would load user preferences
        await MainActor.run {
            defaultSettings = CreateTaskDefaults(
                defaultPriority: .medium,
                defaultCategory: .personal,
                defaultHasDueDate: false,
                defaultDueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                defaultHasReminder: false,
                defaultReminderOffset: -3600 // 1 hour before due date
            )
        }
    }
    
    // MARK: - Task Creation
    
    public func createTask() async {
        guard canCreateTask else { return }
        
        await setCreating(true)
        
        let finalDueDate: Date?
        if hasDueDate {
            finalDueDate = dueDate
        } else {
            finalDueDate = nil
        }
        
        let taskData = CreateTaskData(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            taskDescription: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: priority,
            category: category,
            dueDate: finalDueDate,
            tags: Set(tags),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            reminderTime: hasReminder ? reminderTime : nil
        )
        
        do {
            try await client.process(.createTask(taskData))
            
            await MainActor.run {
                wasTaskCreated = true
                shouldCloseWindow = true
            }
            
            // Send notification for external observers
            await MainActor.run {
                NotificationCenter.default.post(name: .taskCreated, object: nil)
            }
            
        } catch {
            await setError("Failed to create task: \(error.localizedDescription)")
        }
        
        await setCreating(false)
    }
    
    public func createTaskAndNew() async {
        await createTask()
        
        if wasTaskCreated {
            await resetForm()
        }
    }
    
    // MARK: - Field Updates
    
    public func updateTitle(_ newTitle: String) async {
        await MainActor.run {
            title = newTitle
            updateValidation()
        }
    }
    
    public func updateDescription(_ newDescription: String) async {
        await MainActor.run {
            taskDescription = newDescription
        }
    }
    
    public func updatePriority(_ newPriority: Priority) async {
        await MainActor.run {
            priority = newPriority
        }
    }
    
    public func updateCategory(_ newCategory: TaskManager_Shared.Category) async {
        await MainActor.run {
            category = newCategory
        }
    }
    
    public func updateDueDate(_ newDate: Date?) async {
        await MainActor.run {
            dueDate = newDate
            updateValidation()
        }
    }
    
    public func toggleDueDate(_ enabled: Bool) async {
        await MainActor.run {
            hasDueDate = enabled
            if !enabled {
                dueDate = nil
            } else if dueDate == nil {
                dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
            }
            updateValidation()
        }
    }
    
    public func updateNotes(_ newNotes: String) async {
        await MainActor.run {
            notes = newNotes
        }
    }
    
    public func updateReminderTime(_ newTime: Date?) async {
        await MainActor.run {
            reminderTime = newTime
        }
    }
    
    public func toggleReminder(_ enabled: Bool) async {
        await MainActor.run {
            hasReminder = enabled
            if !enabled {
                reminderTime = nil
            }
        }
    }
    
    public func updateEstimatedDuration(_ duration: TimeInterval?) async {
        await MainActor.run {
            estimatedDuration = duration
        }
    }
    
    public func toggleEstimatedDuration(_ enabled: Bool) async {
        await MainActor.run {
            hasEstimatedDuration = enabled
            if !enabled {
                estimatedDuration = nil
            }
        }
    }
    
    // MARK: - Tags Management
    
    public func addTag() async {
        let trimmedTag = currentTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty && !tags.contains(trimmedTag) else { return }
        
        await MainActor.run {
            tags.append(trimmedTag)
            currentTag = ""
        }
    }
    
    public func removeTag(_ tag: String) async {
        await MainActor.run {
            tags.removeAll { $0 == tag }
        }
    }
    
    public func updateCurrentTag(_ newTag: String) async {
        await MainActor.run {
            currentTag = newTag
        }
    }
    
    // MARK: - Template Management
    
    private func loadTemplates() {
        availableTemplates = [
            TaskTemplate(
                name: "Quick Task",
                title: "",
                description: "",
                priority: .medium,
                category: .personal,
                hasDueDate: false
            ),
            TaskTemplate(
                name: "Work Meeting",
                title: "Meeting: ",
                description: "Agenda:\n- \n- \n- ",
                priority: .high,
                category: .work,
                hasDueDate: true
            ),
            TaskTemplate(
                name: "Shopping List",
                title: "Shopping: ",
                description: "Items to buy:\n- \n- \n- ",
                priority: .low,
                category: .shopping,
                hasDueDate: false
            ),
            TaskTemplate(
                name: "Health Appointment",
                title: "Appointment: ",
                description: "Doctor:\nLocation:\nNotes:",
                priority: .high,
                category: .health,
                hasDueDate: true
            )
        ]
    }
    
    public func applyTemplate(_ template: TaskTemplate) async {
        await MainActor.run {
            selectedTemplate = template
            title = template.title
            taskDescription = template.description
            priority = template.priority
            category = template.category
            hasDueDate = template.hasDueDate
            
            if template.hasDueDate && dueDate == nil {
                dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
            }
            
            updateValidation()
        }
    }
    
    public func clearTemplate() async {
        await MainActor.run {
            selectedTemplate = nil
        }
    }
    
    // MARK: - Validation
    
    private func setupValidation() {
        // Set up reactive validation
        $title
            .map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .assign(to: &$isTitleValid)
        
        // Combine validation states
        Publishers.CombineLatest($isTitleValid, $isCreating)
            .map { isTitleValid, isCreating in
                isTitleValid && !isCreating
            }
            .assign(to: &$canCreateTask)
    }
    
    private func updateValidation() {
        validationErrors.removeAll()
        
        // Title validation
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append(ValidationError(field: "title", message: "Title is required"))
        }
        
        // Due date validation
        if hasDueDate, let dueDate = dueDate, dueDate < Date() {
            validationErrors.append(ValidationError(field: "dueDate", message: "Due date cannot be in the past"))
        }
        
        // Reminder validation
        if hasReminder && hasDueDate {
            if let reminderTime = reminderTime, let dueDate = dueDate, reminderTime > dueDate {
                validationErrors.append(ValidationError(field: "reminder", message: "Reminder time cannot be after due date"))
            }
        }
        
        canCreateTask = validationErrors.isEmpty && !isCreating
    }
    
    // MARK: - Window Management
    
    public func cancelCreation() async {
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
    
    private func setCreating(_ creating: Bool) async {
        await MainActor.run {
            isCreating = creating
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
    
    public var hasValidationErrors: Bool {
        !validationErrors.isEmpty
    }
    
    public var titleFieldError: String? {
        validationErrors.first { $0.field == "title" }?.message
    }
    
    public var dueDateFieldError: String? {
        validationErrors.first { $0.field == "dueDate" }?.message
    }
    
    public var reminderFieldError: String? {
        validationErrors.first { $0.field == "reminder" }?.message
    }
    
    public var estimatedDurationText: String {
        guard let duration = estimatedDuration else { return "" }
        
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Keyboard Shortcuts
    
    public func handleKeyboardShortcut(_ shortcut: CreateTaskKeyboardShortcut) async {
        switch shortcut {
        case .create:
            if canCreateTask {
                await createTask()
            }
        case .createAndNew:
            if canCreateTask {
                await createTaskAndNew()
            }
        case .cancel:
            await cancelCreation()
        case .toggleAdvanced:
            await MainActor.run {
                showAdvancedOptions.toggle()
            }
        case .addTag:
            await addTag()
        case .focusTitle:
            // This would focus the title field in the UI
            break
        case .focusDescription:
            // This would focus the description field in the UI
            break
        }
    }
}

// MARK: - Supporting Types

public struct CreateTaskDefaults {
    public let defaultPriority: Priority
    public let defaultCategory: TaskManager_Shared.Category
    public let defaultHasDueDate: Bool
    public let defaultDueDate: Date?
    public let defaultHasReminder: Bool
    public let defaultReminderOffset: TimeInterval
    
    public init(
        defaultPriority: Priority,
        defaultCategory: TaskManager_Shared.Category,
        defaultHasDueDate: Bool,
        defaultDueDate: Date?,
        defaultHasReminder: Bool,
        defaultReminderOffset: TimeInterval
    ) {
        self.defaultPriority = defaultPriority
        self.defaultCategory = defaultCategory
        self.defaultHasDueDate = defaultHasDueDate
        self.defaultDueDate = defaultDueDate
        self.defaultHasReminder = defaultHasReminder
        self.defaultReminderOffset = defaultReminderOffset
    }
}

public struct TaskTemplate: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let title: String
    public let description: String
    public let priority: Priority
    public let category: TaskManager_Shared.Category
    public let hasDueDate: Bool
    
    public init(
        name: String,
        title: String,
        description: String,
        priority: Priority,
        category: TaskManager_Shared.Category,
        hasDueDate: Bool
    ) {
        self.name = name
        self.title = title
        self.description = description
        self.priority = priority
        self.category = category
        self.hasDueDate = hasDueDate
    }
}

public struct ValidationError {
    public let field: String
    public let message: String
    
    public init(field: String, message: String) {
        self.field = field
        self.message = message
    }
}

public enum CreateTaskKeyboardShortcut {
    case create
    case createAndNew
    case cancel
    case toggleAdvanced
    case addTag
    case focusTitle
    case focusDescription
}

// MARK: - Notifications

extension Notification.Name {
    static let taskCreated = Notification.Name("taskCreated")
}