import Foundation
import Axiom

// Protocol for shortcut items to enable testing
protocol ShortcutItemProtocol {
    var type: String { get }
    var localizedTitle: String { get }
    var localizedSubtitle: String? { get }
    var userInfo: [String: Any]? { get }
}

// Quick action types
enum QuickAction: Equatable {
    case createTask
    case viewTask(id: UUID)
    case search(query: String)
    case highPriority
}

// Mock shortcut item for development/testing
struct MockShortcutItem: ShortcutItemProtocol {
    let type: String
    let localizedTitle: String
    var localizedSubtitle: String?
    var userInfo: [String: Any]?
}

@MainActor
final class ShortcutManager {
    private let client: TaskClient
    private var lastUpdateTime: Date?
    private var cachedShortcuts: [ShortcutItemProtocol] = []
    
    // Navigation service can be injected for testing
    var navigationService: NavigationService?
    
    init(client: TaskClient) {
        self.client = client
    }
    
    func updateShortcuts() async -> [ShortcutItemProtocol] {
        var shortcuts: [ShortcutItemProtocol] = []
        
        // Static shortcuts
        shortcuts.append(createShortcut(
            type: "com.app.create-task",
            title: "Create Task",
            subtitle: "Add a new task",
            iconName: "plus.circle"
        ))
        
        shortcuts.append(createShortcut(
            type: "com.app.search",
            title: "Search Tasks",
            subtitle: "Find your tasks",
            iconName: "magnifyingglass"
        ))
        
        shortcuts.append(createShortcut(
            type: "com.app.high-priority",
            title: "High Priority",
            subtitle: "View urgent tasks",
            iconName: "exclamationmark.circle"
        ))
        
        // Dynamic shortcuts for recent high-priority tasks
        let recentTasks = await client.state.tasks
            .filter { $0.priority == .high && !$0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(3)
        
        for task in recentTasks {
            shortcuts.append(createShortcut(
                type: "com.app.task.\(task.id)",
                title: task.title,
                subtitle: "High Priority",
                iconName: "star.fill",
                userInfo: ["taskId": task.id.uuidString]
            ))
        }
        
        lastUpdateTime = Date()
        cachedShortcuts = shortcuts
        return shortcuts
    }
    
    func updateShortcutsIfNeeded() async -> [ShortcutItemProtocol] {
        // Only update if more than 5 minutes have passed
        if let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < 300 {
            return cachedShortcuts
        }
        
        return await updateShortcuts()
    }
    
    func handleShortcut(_ shortcut: ShortcutItemProtocol) async -> Bool {
        guard let navigationService = navigationService else { return false }
        
        switch shortcut.type {
        case "com.app.create-task":
            navigationService.navigate(to: TaskRoute.createTask)
            return true
            
        case "com.app.search":
            navigationService.navigate(to: TaskRoute.search(query: nil))
            return true
            
        case "com.app.high-priority":
            navigationService.navigate(to: TaskRoute.filteredList(filter: .priority(.high)))
            return true
            
        case let type where type.hasPrefix("com.app.task."):
            if let taskIdString = shortcut.userInfo?["taskId"] as? String,
               let taskId = UUID(uuidString: taskIdString) {
                navigationService.navigate(to: TaskRoute.editTask(id: taskId))
                return true
            }
            
        default:
            break
        }
        
        return false
    }
    
    private func createShortcut(
        type: String,
        title: String,
        subtitle: String,
        iconName: String,
        userInfo: [String: Any]? = nil
    ) -> ShortcutItemProtocol {
        return MockShortcutItem(
            type: type,
            localizedTitle: title,
            localizedSubtitle: subtitle,
            userInfo: userInfo
        )
    }
}