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

// MARK: - Create Task Context (iOS)

/// Context for creating new tasks on iOS
@MainActor
public final class CreateTaskContext: ClientObservingContext<TaskClient> {
    
    // MARK: - Published Properties
    @Published public var title: String = ""
    @Published public var taskDescription: String = ""
    @Published public var priority: Priority = .medium
    @Published public var category: Category = .personal
    @Published public var dueDate: Date? = nil
    @Published public var hasDueDate: Bool = false
    @Published public var tags: Set<String> = []
    @Published public var newTag: String = ""
    
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var error: String? = nil
    @Published public private(set) var isCreated: Bool = false
    
    // Template support
    @Published public private(set) var availableTemplates: [TaskTemplate] = []
    @Published public private(set) var selectedTemplate: TaskTemplate? = nil
    
    // MARK: - Initialization
    
    public required init() {
        fatalError("Use init(client:) instead")
    }
    
    public init(client: TaskClient) {
        super.init(client: client)
        setupDefaultTemplates()
    }
    
    // MARK: - Lifecycle
    
    public override func appeared() async {
        await super.appeared()
        await resetForm()
    }
    
    public override func handleStateUpdate(_ state: TaskManagerState) async {
        await MainActor.run {
            error = nil
        }
    }
    
    // MARK: - Task Creation
    
    public func createTask() async {
        guard isFormValid else { return }
        
        await setLoading(true)
        
        let taskData = CreateTaskData(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            taskDescription: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: priority,
            category: category,
            dueDate: hasDueDate ? dueDate : nil,
            tags: tags
        )
        
        do {
            try await client.process(.createTask(taskData))
            await MainActor.run {
                isCreated = true
            }
            await resetForm()
        } catch {
            await setError("Failed to create task: \(error.localizedDescription)")
        }
        
        await setLoading(false)
    }
    
    public func createTaskAndAddAnother() async {
        await createTask()
        
        // Reset creation state but keep some form values
        await MainActor.run {
            isCreated = false
            title = ""
            taskDescription = ""
            // Keep priority, category, and due date settings for convenience
        }
    }
    
    // MARK: - Form Management
    
    public func resetForm() async {
        await MainActor.run {
            title = ""
            taskDescription = ""
            priority = .medium
            category = .personal
            dueDate = nil
            hasDueDate = false
            tags.removeAll()
            newTag = ""
            error = nil
            isCreated = false
            selectedTemplate = nil
        }
    }
    
    public func updateTitle(_ newTitle: String) async {
        await MainActor.run {
            title = newTitle
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
    
    public func updateCategory(_ newCategory: Category) async {
        await MainActor.run {
            category = newCategory
        }
    }
    
    public func updateDueDate(_ newDueDate: Date?) async {
        await MainActor.run {
            dueDate = newDueDate
        }
    }
    
    public func toggleHasDueDate() async {
        await MainActor.run {
            hasDueDate.toggle()
            if !hasDueDate {
                dueDate = nil
            } else if dueDate == nil {
                dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
            }
        }
    }
    
    // MARK: - Tag Management
    
    public func addTag() async {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty && !tags.contains(trimmedTag) else { return }
        
        await MainActor.run {
            tags.insert(trimmedTag)
            newTag = ""
        }
    }
    
    public func addTag(_ tag: String) async {
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty && !tags.contains(trimmedTag) else { return }
        
        await MainActor.run {
            tags.insert(trimmedTag)
        }
    }
    
    public func removeTag(_ tag: String) async {
        await MainActor.run {
            tags.remove(tag)
        }
    }
    
    public func updateNewTag(_ tag: String) async {
        await MainActor.run {
            newTag = tag
        }
    }
    
    // MARK: - Template Management
    
    private func setupDefaultTemplates() {
        availableTemplates = [
            TaskTemplate(
                name: "Personal Task",
                description: "Simple personal task",
                priority: .medium,
                category: .personal,
                defaultDueDate: nil,
                tags: []
            ),
            TaskTemplate(
                name: "Work Project",
                description: "Work-related project task",
                priority: .high,
                category: .work,
                defaultDueDate: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()),
                tags: ["project", "work"]
            ),
            TaskTemplate(
                name: "Shopping Item",
                description: "Item to purchase",
                priority: .low,
                category: .shopping,
                defaultDueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                tags: ["shopping"]
            ),
            TaskTemplate(
                name: "Health Goal",
                description: "Health and fitness related task",
                priority: .medium,
                category: .health,
                defaultDueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                tags: ["health", "goal"]
            ),
            TaskTemplate(
                name: "Learning",
                description: "Educational or skill development task",
                priority: .medium,
                category: .education,
                defaultDueDate: Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date()),
                tags: ["learning", "skill"]
            )
        ]
    }
    
    public func applyTemplate(_ template: TaskTemplate) async {
        await MainActor.run {
            selectedTemplate = template
            priority = template.priority
            category = template.category
            
            if let defaultDueDate = template.defaultDueDate {
                dueDate = defaultDueDate
                hasDueDate = true
            }
            
            tags = template.tags
            
            // Pre-fill description if it's empty
            if taskDescription.isEmpty {
                taskDescription = template.description
            }
        }
    }
    
    public func clearTemplate() async {
        await MainActor.run {
            selectedTemplate = nil
        }
    }
    
    // MARK: - Quick Actions
    
    public func setQuickDueDate(_ option: QuickDueDateOption) async {
        let newDate: Date?
        
        switch option {
        case .today:
            newDate = Calendar.current.startOfDay(for: Date())
        case .tomorrow:
            newDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case .nextWeek:
            newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
        case .nextMonth:
            newDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        case .none:
            newDate = nil
        }
        
        await MainActor.run {
            dueDate = newDate
            hasDueDate = newDate != nil
        }
    }
    
    // MARK: - Validation
    
    public var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var formValidationErrors: [String] {
        var errors: [String] = []
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Title is required")
        }
        
        if let dueDate = dueDate, hasDueDate, dueDate < Date() {
            errors.append("Due date cannot be in the past")
        }
        
        return errors
    }
    
    public var canCreate: Bool {
        isFormValid && !isLoading
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
    
    public var hasContent: Bool {
        !title.isEmpty || !taskDescription.isEmpty || !tags.isEmpty
    }
    
    public var characterCount: Int {
        title.count + taskDescription.count
    }
    
    public var tagsArray: [String] {
        Array(tags).sorted()
    }
}

// MARK: - Supporting Types

public struct TaskTemplate: Identifiable, Equatable, Hashable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let priority: Priority
    public let category: Category
    public let defaultDueDate: Date?
    public let tags: Set<String>
    
    public init(
        name: String,
        description: String,
        priority: Priority,
        category: Category,
        defaultDueDate: Date? = nil,
        tags: Set<String> = []
    ) {
        self.name = name
        self.description = description
        self.priority = priority
        self.category = category
        self.defaultDueDate = defaultDueDate
        self.tags = tags
    }
}

public enum QuickDueDateOption: String, CaseIterable {
    case today = "Today"
    case tomorrow = "Tomorrow"
    case nextWeek = "Next Week"
    case nextMonth = "Next Month"
    case none = "No Due Date"
    
    public var displayName: String {
        return rawValue
    }
}