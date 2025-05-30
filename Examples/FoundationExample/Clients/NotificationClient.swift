import Foundation
import Axiom

// MARK: - Notification Client

/// Infrastructure client for notifications and alerts
/// Demonstrates infrastructure client patterns and cross-cutting notifications
@Capabilities([.notifications, .analytics, .userDefaults])
public actor NotificationClient: InfrastructureClient {
    public typealias State = NotificationClientState
    public typealias DomainModelType = EmptyDomain
    
    // MARK: - State
    
    private var _state: State
    private var _stateVersion = StateVersion()
    private var observers: [WeakContextReference] = []
    
    public var stateSnapshot: State {
        _state
    }
    
    // MARK: - Initialization
    
    public init() async throws {
        self._state = NotificationClientState()
    }
    
    // MARK: - State Management
    
    public func updateState<T>(_ update: @Sendable (inout State) throws -> T) async rethrows -> T {
        let result = try update(&_state)
        _stateVersion = _stateVersion.incrementMinor()
        await notifyObservers()
        return result
    }
    
    public func validateState() async throws {
        // Infrastructure clients typically have minimal validation
    }
    
    // MARK: - Notification Operations
    
    /// Shows an in-app notification
    public func showNotification(
        title: String,
        message: String,
        type: NotificationType = .info,
        duration: TimeInterval = 3.0,
        actionTitle: String? = nil,
        action: (() async -> Void)? = nil
    ) async {
        try? capabilities.validate(.notifications)
        
        let notification = AppNotification(
            title: title,
            message: message,
            type: type,
            duration: duration,
            actionTitle: actionTitle,
            action: action
        )
        
        await updateState { state in
            state.activeNotifications.append(notification)
            state.notificationHistory.append(notification)
            state.metrics.totalNotifications += 1
            state.metrics.notificationsByType[type, default: 0] += 1
        }
        
        // Auto-dismiss after duration
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            await dismissNotification(notification.id)
        }
    }
    
    /// Shows a success notification
    public func showSuccess(_ message: String, duration: TimeInterval = 2.0) async {
        await showNotification(
            title: "Success",
            message: message,
            type: .success,
            duration: duration
        )
    }
    
    /// Shows an error notification
    public func showError(_ message: String, duration: TimeInterval = 5.0) async {
        await showNotification(
            title: "Error",
            message: message,
            type: .error,
            duration: duration
        )
    }
    
    /// Shows a warning notification
    public func showWarning(_ message: String, duration: TimeInterval = 4.0) async {
        await showNotification(
            title: "Warning",
            message: message,
            type: .warning,
            duration: duration
        )
    }
    
    /// Shows an info notification
    public func showInfo(_ message: String, duration: TimeInterval = 3.0) async {
        await showNotification(
            title: "Info",
            message: message,
            type: .info,
            duration: duration
        )
    }
    
    /// Shows a task-related notification
    public func showTaskNotification(
        task: Task,
        event: TaskNotificationEvent,
        actionTitle: String? = nil,
        action: (() async -> Void)? = nil
    ) async {
        let (title, message, type) = formatTaskNotification(task: task, event: event)
        
        await showNotification(
            title: title,
            message: message,
            type: type,
            actionTitle: actionTitle,
            action: action
        )
    }
    
    /// Shows a project-related notification
    public func showProjectNotification(
        project: Project,
        event: ProjectNotificationEvent
    ) async {
        let (title, message, type) = formatProjectNotification(project: project, event: event)
        
        await showNotification(
            title: title,
            message: message,
            type: type
        )
    }
    
    /// Dismisses a specific notification
    public func dismissNotification(_ notificationId: UUID) async {
        await updateState { state in
            state.activeNotifications.removeAll { $0.id == notificationId }
        }
    }
    
    /// Dismisses all notifications
    public func dismissAllNotifications() async {
        await updateState { state in
            state.activeNotifications.removeAll()
        }
    }
    
    /// Schedules a local notification (simplified for demo)
    public func scheduleLocalNotification(
        title: String,
        message: String,
        scheduledDate: Date,
        identifier: String? = nil
    ) async {
        try? capabilities.validate(.notifications)
        
        let notification = ScheduledNotification(
            title: title,
            message: message,
            scheduledDate: scheduledDate,
            identifier: identifier ?? UUID().uuidString
        )
        
        await updateState { state in
            state.scheduledNotifications.append(notification)
            state.metrics.scheduledNotifications += 1
        }
        
        // In a real app, this would schedule with UNUserNotificationCenter
        print("📅 Scheduled notification: \\(title) for \\(scheduledDate)")
    }
    
    /// Cancels a scheduled notification
    public func cancelScheduledNotification(_ identifier: String) async {
        await updateState { state in
            state.scheduledNotifications.removeAll { $0.identifier == identifier }
        }
    }
    
    /// Gets notification preferences
    public func getNotificationPreferences() async -> NotificationPreferences {
        _state.preferences
    }
    
    /// Updates notification preferences
    public func updateNotificationPreferences(_ preferences: NotificationPreferences) async {
        try? capabilities.validate(.userDefaults)
        
        await updateState { state in
            state.preferences = preferences
        }
    }
    
    /// Gets active notifications
    public func getActiveNotifications() async -> [AppNotification] {
        _state.activeNotifications
    }
    
    /// Gets notification metrics
    public func getMetrics() async -> NotificationMetrics {
        _state.metrics
    }
    
    // MARK: - Observer Pattern
    
    public func addObserver<T: AxiomContext>(_ context: T) async {
        let reference = WeakContextReference(context)
        observers.append(reference)
        observers.removeAll { $0.context == nil }
    }
    
    public func removeObserver<T: AxiomContext>(_ context: T) async {
        observers.removeAll { $0.context === context as AnyObject }
    }
    
    public func notifyObservers() async {
        for observer in observers {
            if let context = observer.context {
                await context.onClientStateChange(self)
            }
        }
        observers.removeAll { $0.context == nil }
    }
    
    // MARK: - Lifecycle
    
    public func initialize() async throws {
        try await validateState()
    }
    
    public func shutdown() async {
        await dismissAllNotifications()
        await updateState { state in
            state.scheduledNotifications.removeAll()
            state.notificationHistory.removeAll()
        }
        observers.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func formatTaskNotification(
        task: Task,
        event: TaskNotificationEvent
    ) -> (title: String, message: String, type: NotificationType) {
        switch event {
        case .created:
            return ("Task Created", "New task: \\(task.title)", .success)
        case .updated:
            return ("Task Updated", "\\(task.title) has been updated", .info)
        case .completed:
            return ("Task Completed", "✅ \\(task.title) is now complete!", .success)
        case .overdue:
            return ("Task Overdue", "⚠️ \\(task.title) is past its due date", .warning)
        case .assigned:
            return ("Task Assigned", "You've been assigned: \\(task.title)", .info)
        case .dueSoon:
            return ("Task Due Soon", "📅 \\(task.title) is due soon", .warning)
        }
    }
    
    private func formatProjectNotification(
        project: Project,
        event: ProjectNotificationEvent
    ) -> (title: String, message: String, type: NotificationType) {
        switch event {
        case .created:
            return ("Project Created", "New project: \\(project.name)", .success)
        case .memberAdded:
            return ("Added to Project", "You've been added to \\(project.name)", .info)
        case .memberRemoved:
            return ("Removed from Project", "You've been removed from \\(project.name)", .warning)
        case .statusChanged:
            return ("Project Status Changed", "\\(project.name) is now \\(project.status.displayName)", .info)
        case .deadlineApproaching:
            return ("Project Deadline", "📅 \\(project.name) deadline is approaching", .warning)
        }
    }
}

// MARK: - Supporting Types

/// State managed by NotificationClient
public struct NotificationClientState: Sendable {
    public var activeNotifications: [AppNotification] = []
    public var notificationHistory: [AppNotification] = []
    public var scheduledNotifications: [ScheduledNotification] = []
    public var preferences: NotificationPreferences = NotificationPreferences()
    public var metrics: NotificationMetrics = NotificationMetrics()
    
    public init() {}
}

/// In-app notification
public struct AppNotification: Sendable, Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let type: NotificationType
    public let timestamp: Date
    public let duration: TimeInterval
    public let actionTitle: String?
    public let action: (() async -> Void)?
    
    public init(
        title: String,
        message: String,
        type: NotificationType,
        duration: TimeInterval = 3.0,
        actionTitle: String? = nil,
        action: (() async -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.type = type
        self.timestamp = Date()
        self.duration = duration
        self.actionTitle = actionTitle
        self.action = action
    }
}

/// Scheduled notification
public struct ScheduledNotification: Sendable, Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let scheduledDate: Date
    public let identifier: String
    
    public init(
        title: String,
        message: String,
        scheduledDate: Date,
        identifier: String
    ) {
        self.title = title
        self.message = message
        self.scheduledDate = scheduledDate
        self.identifier = identifier
    }
}

/// Notification type with visual styling
public enum NotificationType: String, CaseIterable, Sendable {
    case success = "success"
    case error = "error"
    case warning = "warning"
    case info = "info"
    
    public var emoji: String {
        switch self {
        case .success: return "✅"
        case .error: return "❌"
        case .warning: return "⚠️"
        case .info: return "ℹ️"
        }
    }
}

/// Task notification events
public enum TaskNotificationEvent {
    case created
    case updated
    case completed
    case overdue
    case assigned
    case dueSoon
}

/// Project notification events
public enum ProjectNotificationEvent {
    case created
    case memberAdded
    case memberRemoved
    case statusChanged
    case deadlineApproaching
}

/// User notification preferences
public struct NotificationPreferences: Sendable {
    public var enableInAppNotifications: Bool = true
    public var enableLocalNotifications: Bool = true
    public var enableTaskNotifications: Bool = true
    public var enableProjectNotifications: Bool = true
    public var enableErrorNotifications: Bool = true
    public var notificationDuration: TimeInterval = 3.0
    
    public init() {}
}

/// Notification metrics
public struct NotificationMetrics: Sendable {
    public var totalNotifications: Int = 0
    public var scheduledNotifications: Int = 0
    public var notificationsByType: [NotificationType: Int] = [:]
    
    public init() {}
}

/// Weak reference to context for observer pattern
private struct WeakContextReference {
    weak var context: AnyObject?
    
    init<T: AxiomContext>(_ context: T) {
        self.context = context as AnyObject
    }
}