import Foundation

/// Navigation routes for the task manager application
enum TaskRoute: Hashable {
    case list
    case createTask
    case editTask(id: UUID)
    case taskDetail(id: UUID)
    case search(query: String?)
    case filteredList(filter: TaskRouteFilter)
}