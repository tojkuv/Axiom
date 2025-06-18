import Foundation
import TaskManager

public enum TaskAction: Sendable {
    case createNewTask(CreateTaskRequest)
    case fetchTask(GetTaskRequest)
    case modifyTask(UpdateTaskRequest)
    case removeTask(DeleteTaskRequest)
    case loadAllTasks(ListTasksRequest)
    case searchTasks(SearchTasksRequest)
}

// MARK: - Action Validation
extension TaskAction {
    public var isValid: Bool {
        switch self {
        case .createNewTask(let request):
            return !request.title.isEmpty
        case .fetchTask(let request):
            return !request.id.isEmpty
        case .modifyTask(let request):
            return !request.id.isEmpty
        case .removeTask(let request):
            return !request.id.isEmpty
        case .loadAllTasks:
            return true
        case .searchTasks(let request):
            return !request.query.isEmpty
        }
    }
    
    public var validationErrors: [String] {
        switch self {
        case .createNewTask(let request):
            var errors: [String] = []
            if request.title.isEmpty {
                errors.append("Title cannot be empty")
            }
            if request.title.count > 200 {
                errors.append("Title cannot exceed 200 characters")
            }
            return errors
            
        case .fetchTask(let request):
            return request.id.isEmpty ? ["Task ID cannot be empty"] : []
            
        case .modifyTask(let request):
            var errors: [String] = []
            if request.id.isEmpty {
                errors.append("Task ID cannot be empty")
            }
            if let title = request.title, title.isEmpty {
                errors.append("Title cannot be empty when provided")
            }
            if let title = request.title, title.count > 200 {
                errors.append("Title cannot exceed 200 characters")
            }
            return errors
            
        case .removeTask(let request):
            return request.id.isEmpty ? ["Task ID cannot be empty"] : []
            
        case .loadAllTasks(let request):
            var errors: [String] = []
            if request.pageSize < 0 {
                errors.append("Page size cannot be negative")
            }
            if request.pageSize > 100 {
                errors.append("Page size cannot exceed 100")
            }
            return errors
            
        case .searchTasks(let request):
            var errors: [String] = []
            if request.query.isEmpty {
                errors.append("Search query cannot be empty")
            }
            if request.query.count < 2 {
                errors.append("Search query must be at least 2 characters")
            }
            if request.limit < 0 {
                errors.append("Limit cannot be negative")
            }
            if request.limit > 50 {
                errors.append("Limit cannot exceed 50")
            }
            return errors
        }
    }
}

// MARK: - Action Metadata
extension TaskAction {
    public var requiresNetworkAccess: Bool {
        switch self {
        case .createNewTask, .fetchTask, .modifyTask, .removeTask, .loadAllTasks, .searchTasks:
            return true
        }
    }
    
    public var modifiesState: Bool {
        switch self {
        case .createNewTask, .modifyTask, .removeTask, .loadAllTasks, .searchTasks:
            return true
        case .fetchTask:
            return false
        }
    }
    
    public var actionName: String {
        switch self {
        case .createNewTask:
            return "createNewTask"
        case .fetchTask:
            return "fetchTask"
        case .modifyTask:
            return "modifyTask"
        case .removeTask:
            return "removeTask"
        case .loadAllTasks:
            return "loadAllTasks"
        case .searchTasks:
            return "searchTasks"
        }
    }
    
    public var requiresAuthentication: Bool {
        switch self {
        case .createNewTask, .fetchTask, .modifyTask, .removeTask, .loadAllTasks, .searchTasks:
            return true
        }
    }
    
    public var cachePolicy: CachePolicy {
        switch self {
        case .createNewTask, .modifyTask, .removeTask:
            return .noCache
        case .fetchTask:
            return .cacheFirst
        case .loadAllTasks, .searchTasks:
            return .networkFirst
        }
    }
    
    public var priority: ActionPriority {
        switch self {
        case .createNewTask, .modifyTask, .removeTask:
            return .high
        case .fetchTask, .loadAllTasks:
            return .normal
        case .searchTasks:
            return .low
        }
    }
    
    public var timeout: TimeInterval {
        switch self {
        case .createNewTask, .modifyTask, .removeTask:
            return 30.0
        case .fetchTask:
            return 15.0
        case .loadAllTasks, .searchTasks:
            return 45.0
        }
    }
    
    public var retryPolicy: RetryPolicy {
        switch self {
        case .createNewTask, .modifyTask, .removeTask:
            return .exponentialBackoff(maxRetries: 3)
        case .fetchTask, .loadAllTasks:
            return .linear(maxRetries: 2)
        case .searchTasks:
            return .none
        }
    }
}

// MARK: - Action Analytics
extension TaskAction {
    public var analyticsEventName: String {
        switch self {
        case .createNewTask:
            return "task_created"
        case .fetchTask:
            return "task_fetched"
        case .modifyTask:
            return "task_updated"
        case .removeTask:
            return "task_deleted"
        case .loadAllTasks:
            return "tasks_loaded"
        case .searchTasks:
            return "tasks_searched"
        }
    }
    
    public var analyticsParameters: [String: Any] {
        switch self {
        case .createNewTask(let request):
            return [
                "has_description": !request.description.isEmpty,
                "priority": request.priority.rawValue,
                "has_due_date": request.dueDate != nil,
                "tag_count": request.tags.count
            ]
            
        case .fetchTask(let request):
            return [
                "task_id": request.id
            ]
            
        case .modifyTask(let request):
            return [
                "task_id": request.id,
                "updated_title": request.title != nil,
                "updated_description": request.description != nil,
                "updated_priority": request.priority != nil,
                "updated_completion": request.isCompleted != nil,
                "updated_due_date": request.dueDate != nil,
                "tag_count": request.tags.count
            ]
            
        case .removeTask(let request):
            return [
                "task_id": request.id
            ]
            
        case .loadAllTasks(let request):
            return [
                "page_size": request.pageSize,
                "has_filter": request.filter != nil,
                "has_sort": request.sort != nil
            ]
            
        case .searchTasks(let request):
            return [
                "query_length": request.query.count,
                "has_filter": request.filter != nil,
                "limit": request.limit
            ]
        }
    }
}

// MARK: - Supporting Types
public enum CachePolicy {
    case noCache
    case cacheFirst
    case networkFirst
}

public enum ActionPriority {
    case low
    case normal
    case high
}

public enum RetryPolicy {
    case none
    case linear(maxRetries: Int)
    case exponentialBackoff(maxRetries: Int)
}