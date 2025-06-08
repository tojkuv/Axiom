import Foundation
import Axiom

@MainActor
final class TaskURLHandler {
    private let client: TaskClient
    private let navigationService: NavigationService
    
    init(client: TaskClient, navigationService: NavigationService) {
        self.client = client
        self.navigationService = navigationService
    }
    
    func parseAction(from url: URL) -> QuickAction? {
        guard url.scheme == "taskmanager" else { return nil }
        
        switch url.host {
        case "create":
            return .createTask
            
        case "task":
            if let taskIdString = url.pathComponents.dropFirst().first,
               let taskId = UUID(uuidString: taskIdString) {
                return .viewTask(id: taskId)
            }
            
        case "search":
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let query = components.queryItems?.first(where: { $0.name == "query" })?.value {
                return .search(query: query)
            }
            
        case "priority":
            return .highPriority
            
        default:
            break
        }
        
        return nil
    }
    
    func handle(_ url: URL) async -> Bool {
        guard let action = parseAction(from: url) else { return false }
        
        switch action {
        case .createTask:
            navigationService.navigate(to: TaskRoute.createTask)
            
        case .viewTask(let id):
            // Check if task exists
            let state = await client.state
            if state.tasks.contains(where: { $0.id == id }) {
                navigationService.navigate(to: TaskRoute.editTask(id: id))
            } else {
                // Fallback to task list
                navigationService.navigate(to: TaskRoute.list)
            }
            
        case .search(let query):
            navigationService.navigate(to: TaskRoute.search(query: query))
            
        case .highPriority:
            navigationService.navigate(to: TaskRoute.filteredList(filter: .priority(.high)))
        }
        
        return true
    }
}