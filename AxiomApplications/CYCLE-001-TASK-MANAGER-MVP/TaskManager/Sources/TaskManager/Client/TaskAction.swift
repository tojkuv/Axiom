import Foundation

/// Actions that can be performed on tasks
enum TaskAction: Sendable {
    // Task CRUD
    case addTask(title: String, description: String?, categoryId: UUID? = nil, priority: Priority = .medium, dueDate: Date? = nil, createdAt: Date? = nil)
    case updateTask(id: UUID, title: String?, description: String?, categoryId: UUID?, priority: Priority?, dueDate: Date?, isCompleted: Bool?)
    case deleteTask(id: UUID)
    case toggleTaskCompletion(id: UUID)
    case loadTasks
    case clearError
    
    // Category Management
    case setCategories([Category])
    case addCategory(name: String, color: String, icon: String?)
    case updateCategory(id: UUID, name: String?, color: String?, icon: String?)
    case deleteCategory(id: UUID)
    
    // Filtering
    case setSearchQuery(String)
    case toggleCategoryFilter(UUID)
    case setSortOrder(SortOrder)
    case setSortDirection(SortDirection)
    case setSortCriteria(SortOrder, secondary: SortOrder?, direction: SortDirection)
    case setShowCompleted(Bool)
    case setDueDateFilter(DueDateFilter)
    case clearFilters
    
    // REQ-010: Subtasks and Dependencies
    case addSubtask(parentId: UUID, title: String, description: String? = nil, priority: Priority = .medium)
    case deleteSubtask(id: UUID)
    case toggleSubtaskCompletion(id: UUID)
    case addDependency(dependentTaskId: UUID, prerequisiteTaskId: UUID)
    case removeDependency(dependentTaskId: UUID, prerequisiteTaskId: UUID)
    
    // REQ-011: Task Templates
    case createTemplate(from: TaskItem, name: String, customizableFields: [String] = [], category: String? = nil)
    case instantiateTemplate(templateId: UUID, customizations: [String: String] = [:])
    case updateTemplate(templateId: UUID, name: String? = nil, taskStructure: TaskItem? = nil, customizableFields: [String]? = nil, category: String? = nil)
    case deleteTemplate(templateId: UUID)
    case searchTemplates(query: String)
    case clearTemplateSearch
    
    // REQ-012: Bulk Operations
    case toggleTaskSelection(id: UUID)
    case selectAllTasks
    case clearAllSelections
    case batchDeleteSelected
    case batchUpdateStatus(isCompleted: Bool)
    case batchUpdateCategory(UUID)
    case batchUpdatePriority(Priority)
    case cancelBatchOperation
    
    // REQ-013: Keyboard Navigation
    case setCreateTaskModalPresented(Bool)
    case setDeleteConfirmationPresented(Bool, taskId: UUID?)
    case setEditingTask(UUID?)
    case setSearchActive(Bool)
    case toggleTaskCompletion(UUID) // Additional overload for UUID
}