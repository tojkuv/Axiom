import Foundation
import SwiftUI
import Axiom

// Import shared Task Manager components
@_implementationOnly import TaskManager_Shared

// MARK: - Task Navigation Service (iOS)

/// Navigation service for managing iOS-specific navigation patterns
@MainActor
public final class TaskNavigationService: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var navigationPath = NavigationPath()
    @Published public var presentedSheet: NavigationSheet?
    @Published public var presentedFullScreenCover: NavigationFullScreenCover?
    @Published public var selectedTab: NavigationTab = .tasks
    @Published public var alertConfiguration: AlertConfiguration?
    
    // MARK: - Private Properties
    private let orchestrator: TaskManagerOrchestrator
    private var navigationHistory: [TaskManagerRoute] = []
    private let routeMatcher = RouteMatcher<TaskManagerRoute>()
    
    // MARK: - Initialization
    
    public init(orchestrator: TaskManagerOrchestrator) {
        self.orchestrator = orchestrator
        setupRouteMatchers()
    }
    
    // MARK: - Route Setup
    
    private func setupRouteMatchers() {
        // Register route patterns for URL-based navigation
        routeMatcher.register(pattern: "/tasks") { _ in
            return .taskList
        }
        
        routeMatcher.register(pattern: "/tasks/:taskId") { parameters in
            guard let taskIdString = parameters["taskId"],
                  let taskId = UUID(uuidString: taskIdString) else {
                return nil
            }
            return .taskDetail(taskId: taskId)
        }
        
        routeMatcher.register(pattern: "/tasks/create") { _ in
            return .createTask
        }
        
        routeMatcher.register(pattern: "/settings") { _ in
            return .settings
        }
    }
    
    // MARK: - Navigation Methods
    
    public func navigate(to route: TaskManagerRoute) async {
        await orchestrator.navigate(to: route)
        
        switch route {
        case .taskList:
            selectedTab = .tasks
            navigationPath = NavigationPath()
            dismissPresentedViews()
            
        case .taskDetail(let taskId):
            selectedTab = .tasks
            if !navigationHistory.contains(route) {
                navigationPath.append(route)
            }
            
        case .createTask:
            presentedSheet = .createTask
            
        case .settings:
            presentedSheet = .settings
        }
        
        navigationHistory.append(route)
    }
    
    public func navigate(to url: URL) async {
        if let route = routeMatcher.match(url: url) {
            await navigate(to: route)
        }
    }
    
    public func navigate(to path: String) async {
        if let route = routeMatcher.match(path: path) {
            await navigate(to: route)
        }
    }
    
    // MARK: - Tab Navigation
    
    public func selectTab(_ tab: NavigationTab) async {
        selectedTab = tab
        
        switch tab {
        case .tasks:
            await navigate(to: .taskList)
        case .statistics:
            // Statistics tab doesn't need route navigation
            break
        }
    }
    
    // MARK: - Modal Presentation
    
    public func presentSheet(_ sheet: NavigationSheet) {
        presentedSheet = sheet
    }
    
    public func presentFullScreenCover(_ cover: NavigationFullScreenCover) {
        presentedFullScreenCover = cover
    }
    
    public func dismissSheet() {
        presentedSheet = nil
    }
    
    public func dismissFullScreenCover() {
        presentedFullScreenCover = nil
    }
    
    public func dismissPresentedViews() {
        presentedSheet = nil
        presentedFullScreenCover = nil
    }
    
    // MARK: - Navigation History
    
    public func goBack() async {
        if navigationPath.count > 0 {
            navigationPath.removeLast()
        } else if navigationHistory.count > 1 {
            // Remove current route and navigate to previous
            navigationHistory.removeLast()
            if let previousRoute = navigationHistory.last {
                await navigate(to: previousRoute)
            }
        }
    }
    
    public func popToRoot() async {
        navigationPath = NavigationPath()
        await navigate(to: .taskList)
    }
    
    public var canGoBack: Bool {
        navigationPath.count > 0 || navigationHistory.count > 1
    }
    
    // MARK: - Deep Linking Support
    
    public func handleDeepLink(_ url: URL) async {
        await navigate(to: url)
    }
    
    public func generateDeepLink(for route: TaskManagerRoute) -> URL? {
        let baseURL = "taskmanager://"
        let path = route.pathComponents
        return URL(string: baseURL + path)
    }
    
    // MARK: - Alert Management
    
    public func showAlert(_ configuration: AlertConfiguration) {
        alertConfiguration = configuration
    }
    
    public func dismissAlert() {
        alertConfiguration = nil
    }
    
    // MARK: - Navigation Validation
    
    public func canNavigate(to route: TaskManagerRoute) async -> Bool {
        // Add navigation guards here if needed
        switch route {
        case .taskDetail(let taskId):
            // Check if task exists
            let client = await orchestrator.getTaskClient()
            let state = await client.getCurrentState()
            return state.task(withId: taskId) != nil
            
        default:
            return true
        }
    }
    
    // MARK: - Context Integration
    
    public func createContext<T: Context>(for type: T.Type, identifier: String? = nil) async throws -> T {
        return try await orchestrator.createContext(type: type, identifier: identifier, dependencies: [])
    }
    
    public func getContext<T: Context>(for identifier: String, as type: T.Type) async -> T? {
        return await orchestrator.getContext(for: identifier, as: type)
    }
}

// MARK: - Navigation Types

public enum NavigationTab: String, CaseIterable {
    case tasks = "tasks"
    case statistics = "statistics"
    
    public var title: String {
        switch self {
        case .tasks: return "Tasks"
        case .statistics: return "Statistics"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .tasks: return "list.bullet"
        case .statistics: return "chart.pie"
        }
    }
}

public enum NavigationSheet: String, Identifiable {
    case createTask = "createTask"
    case settings = "settings"
    case taskDetail = "taskDetail"
    case filters = "filters"
    
    public var id: String { rawValue }
}

public enum NavigationFullScreenCover: String, Identifiable {
    case onboarding = "onboarding"
    case tutorial = "tutorial"
    
    public var id: String { rawValue }
}

// MARK: - Alert Configuration

public struct AlertConfiguration: Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String?
    public let primaryButton: AlertButton?
    public let secondaryButton: AlertButton?
    
    public init(
        title: String,
        message: String? = nil,
        primaryButton: AlertButton? = nil,
        secondaryButton: AlertButton? = nil
    ) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
}

public struct AlertButton {
    public let title: String
    public let style: ButtonStyle
    public let action: () -> Void
    
    public enum ButtonStyle {
        case `default`
        case destructive
        case cancel
    }
    
    public init(title: String, style: ButtonStyle = .default, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
}

// MARK: - Navigation View Modifier

public struct NavigationConfigured: ViewModifier {
    @ObservedObject private var navigationService: TaskNavigationService
    
    public init(navigationService: TaskNavigationService) {
        self.navigationService = navigationService
    }
    
    public func body(content: Content) -> some View {
        content
            .sheet(item: $navigationService.presentedSheet) { sheet in
                sheetContent(for: sheet)
            }
            .fullScreenCover(item: $navigationService.presentedFullScreenCover) { cover in
                fullScreenCoverContent(for: cover)
            }
            .alert(item: $navigationService.alertConfiguration) { config in
                Alert(
                    title: Text(config.title),
                    message: config.message.map(Text.init),
                    primaryButton: config.primaryButton.map { button in
                        switch button.style {
                        case .default:
                            return .default(Text(button.title), action: button.action)
                        case .destructive:
                            return .destructive(Text(button.title), action: button.action)
                        case .cancel:
                            return .cancel(Text(button.title), action: button.action)
                        }
                    },
                    secondaryButton: config.secondaryButton.map { button in
                        switch button.style {
                        case .default:
                            return .default(Text(button.title), action: button.action)
                        case .destructive:
                            return .destructive(Text(button.title), action: button.action)
                        case .cancel:
                            return .cancel(Text(button.title), action: button.action)
                        }
                    }
                )
            }
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: NavigationSheet) -> some View {
        // Sheet content would be provided by the navigation service
        Text("Sheet: \(sheet.rawValue)")
    }
    
    @ViewBuilder
    private func fullScreenCoverContent(for cover: NavigationFullScreenCover) -> some View {
        // Full screen cover content would be provided by the navigation service
        Text("Cover: \(cover.rawValue)")
    }
}

extension View {
    public func navigationConfigured(with service: TaskNavigationService) -> some View {
        modifier(NavigationConfigured(navigationService: service))
    }
}

// MARK: - Route Extensions

extension TaskManagerRoute {
    /// Generate a shareable URL for this route
    public func shareableURL() -> URL? {
        let baseURL = "https://taskmanager.example.com"
        return URL(string: baseURL + pathComponents)
    }
    
    /// Check if this route requires authentication
    public var requiresAuthentication: Bool {
        // All routes in this simple app are accessible
        return false
    }
    
    /// Check if this route should be tracked in analytics
    public var shouldTrack: Bool {
        switch self {
        case .taskList, .createTask, .settings:
            return true
        case .taskDetail:
            return false // Don't track individual task views for privacy
        }
    }
}

// MARK: - Navigation Performance Monitoring

public struct NavigationMetrics {
    public let totalNavigations: Int
    public let averageNavigationTime: TimeInterval
    public let mostUsedRoutes: [TaskManagerRoute: Int]
    public let navigationErrors: Int
    
    public init(
        totalNavigations: Int = 0,
        averageNavigationTime: TimeInterval = 0,
        mostUsedRoutes: [TaskManagerRoute: Int] = [:],
        navigationErrors: Int = 0
    ) {
        self.totalNavigations = totalNavigations
        self.averageNavigationTime = averageNavigationTime
        self.mostUsedRoutes = mostUsedRoutes
        self.navigationErrors = navigationErrors
    }
}

extension TaskNavigationService {
    public func getNavigationMetrics() -> NavigationMetrics {
        // In a real implementation, this would track navigation performance
        return NavigationMetrics(
            totalNavigations: navigationHistory.count,
            averageNavigationTime: 0.1,
            mostUsedRoutes: Dictionary(grouping: navigationHistory) { $0 }.mapValues { $0.count },
            navigationErrors: 0
        )
    }
}