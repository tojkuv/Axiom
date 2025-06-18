import Foundation
import Axiom

// MARK: - Task Manager Routes

/// Comprehensive routing system for Task Manager applications
public enum TaskManagerRoute: Hashable, Sendable, TypeSafeRoute {
    case taskList
    case taskDetail(taskId: UUID)
    case createTask
    case editTask(taskId: UUID)
    case settings
    case statistics
    case categoryView(category: Category)
    case priorityView(priority: Priority)
    case dueDateView(date: Date)
    case search(query: String)
    case filters
    case export
    case `import`
    case about
    
    // MARK: - TypeSafeRoute Implementation
    
    public var routeIdentifier: String {
        switch self {
        case .taskList:
            return "task-list"
        case .taskDetail(let taskId):
            return "task-detail-\(taskId.uuidString)"
        case .createTask:
            return "create-task"
        case .editTask(let taskId):
            return "edit-task-\(taskId.uuidString)"
        case .settings:
            return "settings"
        case .statistics:
            return "statistics"
        case .categoryView(let category):
            return "category-\(category.rawValue)"
        case .priorityView(let priority):
            return "priority-\(priority.rawValue)"
        case .dueDateView(let date):
            return "due-date-\(ISO8601DateFormatter().string(from: date))"
        case .search(let query):
            return "search-\(query.replacingOccurrences(of: " ", with: "-"))"
        case .filters:
            return "filters"
        case .export:
            return "export"
        case .import:
            return "import"
        case .about:
            return "about"
        }
    }
    
    public var pathComponents: String {
        switch self {
        case .taskList:
            return "/tasks"
        case .taskDetail(let taskId):
            return "/tasks/\(taskId.uuidString)"
        case .createTask:
            return "/tasks/create"
        case .editTask(let taskId):
            return "/tasks/\(taskId.uuidString)/edit"
        case .settings:
            return "/settings"
        case .statistics:
            return "/statistics"
        case .categoryView(let category):
            return "/category/\(category.rawValue)"
        case .priorityView(let priority):
            return "/priority/\(priority.rawValue)"
        case .dueDateView(let date):
            return "/due-date/\(ISO8601DateFormatter().string(from: date))"
        case .search:
            return "/search"
        case .filters:
            return "/filters"
        case .export:
            return "/export"
        case .import:
            return "/import"
        case .about:
            return "/about"
        }
    }
    
    public var queryParameters: [String: String] {
        switch self {
        case .search(let query):
            return ["q": query]
        default:
            return [:]
        }
    }
    
    // MARK: - Route Properties
    
    /// Display name for the route
    public var displayName: String {
        switch self {
        case .taskList:
            return "Tasks"
        case .taskDetail:
            return "Task Details"
        case .createTask:
            return "Create Task"
        case .editTask:
            return "Edit Task"
        case .settings:
            return "Settings"
        case .statistics:
            return "Statistics"
        case .categoryView(let category):
            return category.displayName
        case .priorityView(let priority):
            return "\(priority.displayName) Priority"
        case .dueDateView:
            return "Due Tasks"
        case .search:
            return "Search Results"
        case .filters:
            return "Filters"
        case .export:
            return "Export"
        case .import:
            return "Import"
        case .about:
            return "About"
        }
    }
    
    /// System image name for the route
    public var systemImageName: String {
        switch self {
        case .taskList:
            return "list.bullet"
        case .taskDetail, .editTask:
            return "doc.text"
        case .createTask:
            return "plus.circle"
        case .settings:
            return "gearshape"
        case .statistics:
            return "chart.pie"
        case .categoryView(let category):
            return category.systemImageName
        case .priorityView(let priority):
            return priority.systemImageName
        case .dueDateView:
            return "calendar"
        case .search:
            return "magnifyingglass"
        case .filters:
            return "line.horizontal.3.decrease.circle"
        case .export:
            return "square.and.arrow.up"
        case .import:
            return "square.and.arrow.down"
        case .about:
            return "info.circle"
        }
    }
    
    /// Whether this route requires a task to exist
    public var requiresTask: Bool {
        switch self {
        case .taskDetail, .editTask:
            return true
        default:
            return false
        }
    }
    
    /// Whether this route can be bookmarked/shared
    public var isBookmarkable: Bool {
        switch self {
        case .taskList, .categoryView, .priorityView, .statistics, .about:
            return true
        case .taskDetail:
            return true // With privacy considerations
        default:
            return false
        }
    }
    
    /// Whether this route should be tracked in analytics
    public var shouldTrackAnalytics: Bool {
        switch self {
        case .taskList, .createTask, .settings, .statistics:
            return true
        case .taskDetail, .editTask:
            return false // Privacy
        default:
            return true
        }
    }
    
    /// Whether this route requires authentication (future use)
    public var requiresAuthentication: Bool {
        return false // All routes are currently accessible
    }
    
    /// Navigation depth level for breadcrumb generation
    public var navigationLevel: Int {
        switch self {
        case .taskList, .statistics, .settings, .about:
            return 0
        case .categoryView, .priorityView, .dueDateView, .search, .filters:
            return 1
        case .taskDetail, .createTask, .editTask, .export, .import:
            return 2
        }
    }
    
    /// Parent route for navigation hierarchy
    public var parentRoute: TaskManagerRoute? {
        switch self {
        case .taskDetail, .createTask, .editTask:
            return .taskList
        case .categoryView, .priorityView, .dueDateView, .search, .filters:
            return .taskList
        case .export, .import:
            return .settings
        default:
            return nil
        }
    }
    
    /// Child routes accessible from this route
    public var childRoutes: [TaskManagerRoute] {
        switch self {
        case .taskList:
            return [.createTask, .filters, .search(query: "")]
        case .settings:
            return [.export, .import]
        default:
            return []
        }
    }
    
    // MARK: - URL Generation
    
    /// Generate a shareable URL for this route
    public func shareableURL(baseURL: String = "https://taskmanager.app") -> URL? {
        guard isBookmarkable else { return nil }
        return URL(string: baseURL + pathComponents)
    }
    
    /// Generate a deep link URL for this route
    public func deepLinkURL(scheme: String = "taskmanager") -> URL? {
        return URL(string: scheme + "://" + pathComponents.dropFirst()) // Remove leading /
    }
    
    // MARK: - Route Matching
    
    /// Create a route from a URL path
    public static func from(path: String) -> TaskManagerRoute? {
        let components = path.components(separatedBy: "/").filter { !$0.isEmpty }
        
        guard !components.isEmpty else { return .taskList }
        
        switch components[0] {
        case "tasks":
            if components.count == 1 {
                return .taskList
            } else if components.count == 2 {
                if components[1] == "create" {
                    return .createTask
                } else if let taskId = UUID(uuidString: components[1]) {
                    return .taskDetail(taskId: taskId)
                }
            } else if components.count == 3 {
                if let taskId = UUID(uuidString: components[1]), components[2] == "edit" {
                    return .editTask(taskId: taskId)
                }
            }
            
        case "settings":
            return .settings
            
        case "statistics":
            return .statistics
            
        case "category":
            if components.count == 2, let category = Category(rawValue: components[1]) {
                return .categoryView(category: category)
            }
            
        case "priority":
            if components.count == 2, let priorityInt = Int(components[1]), let priority = Priority(rawValue: priorityInt) {
                return .priorityView(priority: priority)
            }
            
        case "due-date":
            if components.count == 2, let date = ISO8601DateFormatter().date(from: components[1]) {
                return .dueDateView(date: date)
            }
            
        case "search":
            // Handle query parameter
            let queryItems = URLComponents(string: path)?.queryItems
            let query = queryItems?.first(where: { $0.name == "q" })?.value ?? ""
            return .search(query: query)
            
        case "filters":
            return .filters
            
        case "export":
            return .export
            
        case "import":
            return .import
            
        case "about":
            return .about
            
        default:
            break
        }
        
        return nil
    }
    
    /// Create a route from URL components
    public static func from(url: URL) -> TaskManagerRoute? {
        let path = url.path
        return from(path: path)
    }
    
    // MARK: - Breadcrumb Generation
    
    /// Generate breadcrumb trail for this route
    public var breadcrumbs: [TaskManagerRoute] {
        var crumbs: [TaskManagerRoute] = []
        var currentRoute: TaskManagerRoute? = self
        
        while let route = currentRoute {
            crumbs.insert(route, at: 0)
            currentRoute = route.parentRoute
        }
        
        return crumbs
    }
    
    /// Generate breadcrumb display names
    public var breadcrumbNames: [String] {
        return breadcrumbs.map { $0.displayName }
    }
    
    // MARK: - Navigation Validation
    
    /// Check if navigation to this route is valid from the current route
    public func canNavigateFrom(_ currentRoute: TaskManagerRoute) -> Bool {
        // Basic validation - can be extended with business logic
        switch self {
        case .editTask(let taskId), .taskDetail(let taskId):
            // Would need to check if task exists in real implementation
            return taskId != UUID()
        default:
            return true
        }
    }
    
    /// Get transition animation type for navigation
    public func transitionAnimation(from currentRoute: TaskManagerRoute) -> NavigationTransition {
        let currentLevel = currentRoute.navigationLevel
        let newLevel = self.navigationLevel
        
        if newLevel > currentLevel {
            return .push
        } else if newLevel < currentLevel {
            return .pop
        } else {
            return .replace
        }
    }
    
    // MARK: - Context Requirements
    
    /// Get the required context type for this route
    public var requiredContextType: String {
        switch self {
        case .taskList, .categoryView, .priorityView, .dueDateView, .search, .filters:
            return "TaskListContext"
        case .taskDetail, .editTask:
            return "TaskDetailContext"
        case .createTask:
            return "CreateTaskContext"
        case .settings, .export, .import:
            return "TaskSettingsContext"
        case .statistics:
            return "TaskStatisticsContext"
        case .about:
            return "AboutContext"
        }
    }
    
    /// Get additional context parameters
    public var contextParameters: [String: Any] {
        switch self {
        case .taskDetail(let taskId), .editTask(let taskId):
            return ["taskId": taskId]
        case .categoryView(let category):
            return ["category": category]
        case .priorityView(let priority):
            return ["priority": priority]
        case .dueDateView(let date):
            return ["date": date]
        case .search(let query):
            return ["query": query]
        default:
            return [:]
        }
    }
}

// MARK: - Supporting Types

/// Navigation transition animations
public enum NavigationTransition {
    case push
    case pop
    case replace
    case modal
    case none
}

/// Route matching utility
public struct RouteMatcher<Route: TypeSafeRoute> {
    private var patterns: [(pattern: String, handler: ([String: String]) -> Route?)] = []
    
    public init() {}
    
    public mutating func register(pattern: String, handler: @escaping ([String: String]) -> Route?) {
        patterns.append((pattern: pattern, handler: handler))
    }
    
    public func match(path: String) -> Route? {
        for (pattern, handler) in patterns {
            if let parameters = matchPattern(pattern, against: path) {
                return handler(parameters)
            }
        }
        return nil
    }
    
    public func match(url: URL) -> Route? {
        return match(path: url.path)
    }
    
    private func matchPattern(_ pattern: String, against path: String) -> [String: String]? {
        let patternComponents = pattern.components(separatedBy: "/").filter { !$0.isEmpty }
        let pathComponents = path.components(separatedBy: "/").filter { !$0.isEmpty }
        
        guard patternComponents.count == pathComponents.count else { return nil }
        
        var parameters: [String: String] = [:]
        
        for (patternComponent, pathComponent) in zip(patternComponents, pathComponents) {
            if patternComponent.hasPrefix(":") {
                let parameterName = String(patternComponent.dropFirst())
                parameters[parameterName] = pathComponent
            } else if patternComponent != pathComponent {
                return nil
            }
        }
        
        return parameters
    }
}

// MARK: - Route History Management

/// Navigation history manager
public class RouteHistory: ObservableObject {
    @Published public private(set) var history: [TaskManagerRoute] = []
    @Published public private(set) var currentIndex: Int = -1
    
    public var currentRoute: TaskManagerRoute? {
        guard currentIndex >= 0 && currentIndex < history.count else { return nil }
        return history[currentIndex]
    }
    
    public var canGoBack: Bool {
        return currentIndex > 0
    }
    
    public var canGoForward: Bool {
        return currentIndex < history.count - 1
    }
    
    public func push(_ route: TaskManagerRoute) {
        // Remove any forward history
        if currentIndex < history.count - 1 {
            history.removeSubrange((currentIndex + 1)...)
        }
        
        // Add new route
        history.append(route)
        currentIndex += 1
        
        // Limit history size
        if history.count > 50 {
            history.removeFirst()
            currentIndex -= 1
        }
    }
    
    public func goBack() -> TaskManagerRoute? {
        guard canGoBack else { return nil }
        currentIndex -= 1
        return currentRoute
    }
    
    public func goForward() -> TaskManagerRoute? {
        guard canGoForward else { return nil }
        currentIndex += 1
        return currentRoute
    }
    
    public func clear() {
        history.removeAll()
        currentIndex = -1
    }
}

// MARK: - Extensions

extension TaskManagerRoute: CustomStringConvertible {
    public var description: String {
        return "\(routeIdentifier): \(displayName)"
    }
}

extension TaskManagerRoute: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "TaskManagerRoute(\(routeIdentifier)) - \(pathComponents)"
    }
}