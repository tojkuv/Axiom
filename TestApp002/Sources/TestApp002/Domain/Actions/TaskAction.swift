import Foundation

enum TaskAction {
    case create(Task)
    case update(Task)
    case delete(taskId: String)
    case deleteMultiple(taskIds: Set<String>)
    case search(query: String)
    case sort(by: SortCriteria)
    case filterByCategory(categoryId: String?)
    
    // Soft delete actions
    case bulkDelete([String])
    case softDelete(String)
    case undoDelete(String)
    case permanentDelete(String)
    case softDeleteWithRetention(String, retentionDays: Int)
    case bulkSoftDeleteWithRetention([String], retentionDays: Int)
    
    // Category management actions
    case createCategory(Category)
    case updateCategory(Category)
    case deleteCategory(categoryId: String)
    case batchAssignCategory(taskIds: Set<String>, categoryId: String?)
    
    // Sharing actions
    case shareTask(taskId: String, userId: String, permission: SharePermission)
    case shareTaskList(userId: String, permission: SharePermission)
    case unshareTask(taskId: String, userId: String)
    case updateSharePermission(taskId: String, userId: String, permission: SharePermission)
}

enum SortCriteria: Hashable {
    case dueDate(ascending: Bool = true)
    case priority(ascending: Bool = true)
    case createdDate(ascending: Bool = true)
    case title(ascending: Bool = true)
    
    // Convenience static properties for default ascending sort
    static let dueDate = SortCriteria.dueDate(ascending: true)
    static let priority = SortCriteria.priority(ascending: true)
    static let createdDate = SortCriteria.createdDate(ascending: true)
    static let title = SortCriteria.title(ascending: true)
}