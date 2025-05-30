import Foundation
import SwiftUI
import Axiom

// MARK: - Dashboard Context

/// Main dashboard context that orchestrates all clients
/// Demonstrates @Client and @CrossCutting macros in action
@CrossCutting([.analytics, .logging, .errorReporting])
public struct DashboardContext: AxiomContext {
    public typealias View = DashboardView
    public typealias Clients = DashboardClients
    
    // MARK: - Client Dependencies (using @Client macro)
    
    @Client public var taskClient: TaskClient
    @Client public var userClient: UserClient
    @Client public var projectClient: ProjectClient
    @Client public var analyticsClient: AnalyticsClient
    @Client public var notificationClient: NotificationClient
    
    // MARK: - State
    
    @Published public var isLoading: Bool = false
    @Published public var lastError: (any AxiomError)?
    @Published public var dashboardData: DashboardData = DashboardData()
    @Published public var selectedTab: DashboardTab = .tasks
    @Published public var showingUserProfile: Bool = false
    
    // MARK: - Intelligence
    
    public let intelligence: AxiomIntelligence
    
    // MARK: - Initialization
    
    public init() async throws {
        // Clients will be injected via @Client macro
        self.intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        
        // Set up automatic data loading
        await setupDataBinding()
    }
    
    // MARK: - Lifecycle
    
    public func onAppear() async {
        await refreshDashboard()
        
        // Track analytics
        await analytics.trackUserBehavior(.viewDashboard)
        
        // Set up notifications for important events
        await setupNotifications()
        
        logger.info("Dashboard appeared", context: "DashboardContext")
    }
    
    public func onDisappear() async {
        logger.info("Dashboard disappeared", context: "DashboardContext")
    }
    
    public func onClientStateChange<T: AxiomClient>(_ client: T) async {
        // Automatically refresh when any client state changes
        await refreshDashboard()
    }
    
    // MARK: - Error Handling
    
    public func handleError(_ error: any AxiomError) async {
        lastError = error
        isLoading = false
        
        await errorReporting.report(error, context: "DashboardContext")
        await notificationClient.showError(error.localizedDescription)
        
        logger.error("Dashboard error: \\(error.localizedDescription)", context: "DashboardContext")
    }
    
    // MARK: - Dashboard Operations
    
    /// Refreshes all dashboard data
    @MainActor
    public func refreshDashboard() async {
        isLoading = true
        
        do {
            async let tasks = taskClient.getTasks(sortBy: .priority, ascending: false)
            async let projects = projectClient.getProjects(sortBy: .updatedAt, ascending: false)
            async let taskMetrics = taskClient.getMetrics()
            async let projectMetrics = projectClient.getMetrics()
            async let currentUser = userClient.getCurrentUser()
            
            let (taskList, projectList, taskStats, projectStats, user) = await (
                tasks, projects, taskMetrics, projectStats, currentUser
            )
            
            dashboardData = DashboardData(
                recentTasks: Array(taskList.prefix(5)),
                recentProjects: Array(projectList.prefix(3)),
                taskSummary: createTaskSummary(from: taskStats, tasks: taskList),
                projectSummary: createProjectSummary(from: projectStats, projects: projectList),
                currentUser: user,
                lastUpdated: Date()
            )
            
            await analytics.trackEvent("dashboard_refreshed", metadata: [
                "task_count": String(taskList.count),
                "project_count": String(projectList.count)
            ])
            
        } catch {
            await handleError(error as? any AxiomError ?? UnknownError(underlying: error))
        }
        
        isLoading = false
    }
    
    /// Creates a new task with validation
    @MainActor
    public func createTask(
        title: String,
        description: String = "",
        priority: TaskPriority = .medium,
        dueDate: Date? = nil
    ) async {
        do {
            let task = try await taskClient.createTask(
                title: title,
                description: description,
                priority: priority,
                dueDate: dueDate
            )
            
            await notificationClient.showTaskNotification(
                task: task,
                event: .created
            )
            
            await analytics.trackUserBehavior(.createTask, context: [
                "priority": priority.rawValue,
                "has_due_date": String(dueDate != nil)
            ])
            
            logger.info("Task created: \\(task.title)", context: "DashboardContext")
            
        } catch {
            await handleError(error as? any AxiomError ?? UnknownError(underlying: error))
        }
    }
    
    /// Creates a new project
    @MainActor
    public func createProject(
        name: String,
        description: String = "",
        deadline: Date? = nil
    ) async {
        guard let currentUser = dashboardData.currentUser else {
            await handleError(AuthenticationError.userNotLoggedIn)
            return
        }
        
        do {
            let project = try await projectClient.createProject(
                name: name,
                description: description,
                ownerId: currentUser.id,
                deadline: deadline
            )
            
            await notificationClient.showProjectNotification(
                project: project,
                event: .created
            )
            
            await analytics.trackUserBehavior(.createProject, context: [
                "has_deadline": String(deadline != nil)
            ])
            
            logger.info("Project created: \\(project.name)", context: "DashboardContext")
            
        } catch {
            await handleError(error as? any AxiomError ?? UnknownError(underlying: error))
        }
    }
    
    /// Switches dashboard tab
    @MainActor
    public func switchTab(_ tab: DashboardTab) async {
        selectedTab = tab
        
        await analytics.trackEvent("dashboard_tab_changed", metadata: [
            "new_tab": tab.rawValue
        ])
    }
    
    /// Shows user profile
    @MainActor
    public func showUserProfile() async {
        showingUserProfile = true
        
        await analytics.trackEvent("user_profile_opened")
    }
    
    /// Gets performance metrics for the dashboard
    public func getPerformanceMetrics() async -> DashboardPerformanceMetrics {
        async let analyticsMetrics = analyticsClient.getMetrics()
        async let taskMetrics = taskClient.getMetrics()
        async let projectMetrics = projectClient.getMetrics()
        
        let (analytics, tasks, projects) = await (analyticsMetrics, taskMetrics, projectMetrics)
        
        return DashboardPerformanceMetrics(
            totalEvents: analytics.totalEvents,
            errorRate: analytics.errorRate,
            taskCompletionRate: tasks.completionRate,
            projectCompletionRate: projects.completionRate,
            averageResponseTime: analytics.averageOperationTime
        )
    }
    
    // MARK: - Private Methods
    
    private func setupDataBinding() async {
        // Set up automatic observers for all clients
        await taskClient.addObserver(self)
        await userClient.addObserver(self)
        await projectClient.addObserver(self)
        await analyticsClient.addObserver(self)
        await notificationClient.addObserver(self)
    }
    
    private func setupNotifications() async {
        // Set up notifications for overdue tasks
        let tasks = await taskClient.getTasks(status: .todo)
        let overdueTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < Date()
        }
        
        for task in overdueTasks {
            await notificationClient.showTaskNotification(
                task: task,
                event: .overdue
            )
        }
    }
    
    private func createTaskSummary(from metrics: TaskMetrics, tasks: [Task]) -> TaskSummary {
        let highPriorityTasks = tasks.filter { $0.priority == .high || $0.priority == .urgent }.count
        let overdueTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < Date() && task.status.isActive
        }.count
        
        return TaskSummary(
            total: metrics.totalTasks,
            completed: metrics.completedTasks,
            active: metrics.activeTasksCount,
            highPriority: highPriorityTasks,
            overdue: overdueTasks,
            completionRate: metrics.completionRate
        )
    }
    
    private func createProjectSummary(from metrics: ProjectMetrics, projects: [Project]) -> ProjectSummary {
        let activeProjects = projects.filter { $0.status.isActive }.count
        let upcomingDeadlines = projects.filter { project in
            guard let deadline = project.deadline else { return false }
            let oneWeekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            return deadline > Date() && deadline <= oneWeekFromNow
        }.count
        
        return ProjectSummary(
            total: metrics.totalProjects,
            active: activeProjects,
            completed: metrics.completedProjects,
            upcomingDeadlines: upcomingDeadlines,
            completionRate: metrics.completionRate
        )
    }
}

// MARK: - Supporting Types

/// Dashboard data structure
public struct DashboardData: Sendable {
    public var recentTasks: [Task] = []
    public var recentProjects: [Project] = []
    public var taskSummary: TaskSummary = TaskSummary()
    public var projectSummary: ProjectSummary = ProjectSummary()
    public var currentUser: User?
    public var lastUpdated: Date = Date()
    
    public init() {}
    
    public init(
        recentTasks: [Task],
        recentProjects: [Project],
        taskSummary: TaskSummary,
        projectSummary: ProjectSummary,
        currentUser: User?,
        lastUpdated: Date
    ) {
        self.recentTasks = recentTasks
        self.recentProjects = recentProjects
        self.taskSummary = taskSummary
        self.projectSummary = projectSummary
        self.currentUser = currentUser
        self.lastUpdated = lastUpdated
    }
}

/// Task summary for dashboard
public struct TaskSummary: Sendable {
    public var total: Int = 0
    public var completed: Int = 0
    public var active: Int = 0
    public var highPriority: Int = 0
    public var overdue: Int = 0
    public var completionRate: Double = 0.0
    
    public init() {}
}

/// Project summary for dashboard
public struct ProjectSummary: Sendable {
    public var total: Int = 0
    public var active: Int = 0
    public var completed: Int = 0
    public var upcomingDeadlines: Int = 0
    public var completionRate: Double = 0.0
    
    public init() {}
}

/// Dashboard tabs
public enum DashboardTab: String, CaseIterable {
    case tasks = "tasks"
    case projects = "projects"
    case analytics = "analytics"
    case profile = "profile"
    
    public var displayName: String {
        switch self {
        case .tasks: return "Tasks"
        case .projects: return "Projects"
        case .analytics: return "Analytics"
        case .profile: return "Profile"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .tasks: return "checklist"
        case .projects: return "folder"
        case .analytics: return "chart.bar"
        case .profile: return "person"
        }
    }
}

/// Dashboard performance metrics
public struct DashboardPerformanceMetrics: Sendable {
    public let totalEvents: Int
    public let errorRate: Double
    public let taskCompletionRate: Double
    public let projectCompletionRate: Double
    public let averageResponseTime: TimeInterval
    
    public init(
        totalEvents: Int,
        errorRate: Double,
        taskCompletionRate: Double,
        projectCompletionRate: Double,
        averageResponseTime: TimeInterval
    ) {
        self.totalEvents = totalEvents
        self.errorRate = errorRate
        self.taskCompletionRate = taskCompletionRate
        self.projectCompletionRate = projectCompletionRate
        self.averageResponseTime = averageResponseTime
    }
}

/// Client dependencies for DashboardContext
public struct DashboardClients: ClientDependencies {
    public let taskClient: TaskClient
    public let userClient: UserClient
    public let projectClient: ProjectClient
    public let analyticsClient: AnalyticsClient
    public let notificationClient: NotificationClient
    
    public init() async throws {
        // In a real implementation with dependency injection, these would be injected
        // For the example, we create them directly
        self.taskClient = try await TaskClient()
        self.userClient = try await UserClient()
        self.projectClient = try await ProjectClient()
        self.analyticsClient = try await AnalyticsClient()
        self.notificationClient = try await NotificationClient()
    }
}

/// Authentication errors
enum AuthenticationError: Error, AxiomError {
    case userNotLoggedIn
    
    var category: ErrorCategory { .domain }
    var severity: ErrorSeverity { .error }
    var context: ErrorContext {
        ErrorContext(component: ComponentID("DashboardContext"), timestamp: Date(), additionalInfo: [:])
    }
    var recoveryActions: [RecoveryAction] { [] }
    
    var errorDescription: String? {
        switch self {
        case .userNotLoggedIn:
            return "User must be logged in to perform this action"
        }
    }
}

/// Unknown error wrapper
struct UnknownError: AxiomError {
    let underlying: Error
    
    var category: ErrorCategory { .architectural }
    var severity: ErrorSeverity { .error }
    var context: ErrorContext {
        ErrorContext(component: ComponentID("DashboardContext"), timestamp: Date(), additionalInfo: [:])
    }
    var recoveryActions: [RecoveryAction] { [] }
    
    var errorDescription: String? {
        underlying.localizedDescription
    }
}