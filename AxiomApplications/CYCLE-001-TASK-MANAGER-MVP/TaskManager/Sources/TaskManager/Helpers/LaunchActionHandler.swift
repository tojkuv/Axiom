import Foundation
import Axiom

@MainActor
final class LaunchActionHandler {
    private let client: TaskClient
    private let navigationService: NavigationService
    private let actionQueue = ActionQueue()
    private var isInitialized = false
    
    init(client: TaskClient, navigationService: NavigationService) {
        self.client = client
        self.navigationService = navigationService
    }
    
    func queueAction(_ action: QuickAction) {
        guard !isInitialized else {
            Task {
                await handleAction(action)
            }
            return
        }
        
        Task {
            await actionQueue.enqueue(action)
        }
    }
    
    func processQueuedActions() async {
        isInitialized = true
        
        let actions = await actionQueue.dequeueAll()
        
        // Process only the last queued action
        if let lastAction = actions.last {
            await handleAction(lastAction)
        }
    }
    
    private func handleAction(_ action: QuickAction) async {
        let urlHandler = TaskURLHandler(
            client: client,
            navigationService: navigationService
        )
        
        switch action {
        case .createTask:
            _ = await urlHandler.handle(URL(string: "taskmanager://create")!)
        case .viewTask(let id):
            _ = await urlHandler.handle(URL(string: "taskmanager://task/\(id.uuidString)")!)
        case .search(let query):
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            _ = await urlHandler.handle(URL(string: "taskmanager://search?query=\(encodedQuery)")!)
        case .highPriority:
            _ = await urlHandler.handle(URL(string: "taskmanager://priority")!)
        }
    }
}

// Actor for thread-safe action queuing
private actor ActionQueue {
    private var actions: [QuickAction] = []
    
    func enqueue(_ action: QuickAction) {
        actions.append(action)
    }
    
    func dequeueAll() -> [QuickAction] {
        let result = actions
        actions.removeAll()
        return result
    }
}