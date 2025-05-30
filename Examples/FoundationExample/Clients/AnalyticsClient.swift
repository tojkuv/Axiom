import Foundation
import Axiom

// MARK: - Analytics Client

/// Infrastructure client for analytics and tracking
/// Demonstrates cross-cutting concerns and infrastructure client patterns
@Capabilities([.analytics, .network, .storage])
public actor AnalyticsClient: InfrastructureClient {
    public typealias State = AnalyticsClientState
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
        self._state = AnalyticsClientState()
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
    
    // MARK: - Analytics Operations
    
    /// Tracks an event with metadata
    public func trackEvent(_ eventName: String, metadata: [String: Any] = [:]) async {
        try? capabilities.validate(.analytics)
        
        let event = AnalyticsEvent(
            name: eventName,
            metadata: metadata,
            timestamp: Date(),
            sessionId: _state.sessionId,
            userId: _state.currentUserId
        )
        
        await updateState { state in
            state.pendingEvents.append(event)
            state.metrics.totalEvents += 1
            state.metrics.eventsByType[eventName, default: 0] += 1
        }
        
        // Batch send events if we have enough
        if _state.pendingEvents.count >= _state.batchSize {
            await sendPendingEvents()
        }
    }
    
    /// Tracks user behavior with automatic context
    public func trackUserBehavior(_ action: UserAction, context: [String: Any] = [:]) async {
        var metadata = context
        metadata["action_type"] = action.rawValue
        metadata["app_version"] = _state.appVersion
        metadata["platform"] = "iOS"
        
        await trackEvent("user_behavior", metadata: metadata)
    }
    
    /// Tracks performance metrics
    public func trackPerformance(_ operation: String, duration: TimeInterval, metadata: [String: Any] = [:]) async {
        var perfMetadata = metadata
        perfMetadata["operation"] = operation
        perfMetadata["duration_ms"] = duration * 1000
        perfMetadata["performance_category"] = categorizePerformance(duration)
        
        await trackEvent("performance", metadata: perfMetadata)
        
        await updateState { state in
            state.metrics.performanceEvents += 1
            state.metrics.averageOperationTime = 
                (state.metrics.averageOperationTime * Double(state.metrics.performanceEvents - 1) + duration) 
                / Double(state.metrics.performanceEvents)
        }
    }
    
    /// Tracks errors for debugging and improvement
    public func trackError(_ error: Error, context: [String: Any] = [:]) async {
        var errorMetadata = context
        errorMetadata["error_type"] = String(describing: type(of: error))
        errorMetadata["error_description"] = error.localizedDescription
        
        if let axiomError = error as? any AxiomError {
            errorMetadata["axiom_category"] = axiomError.category.rawValue
            errorMetadata["axiom_severity"] = String(axiomError.severity.rawValue)
        }
        
        await trackEvent("error", metadata: errorMetadata)
        
        await updateState { state in
            state.metrics.errorEvents += 1
        }
    }
    
    /// Sets current user for analytics tracking
    public func setCurrentUser(_ userId: User.ID?) async {
        await updateState { state in
            state.currentUserId = userId
        }
        
        if let userId = userId {
            await trackEvent("user_session_start", metadata: ["user_id": userId.description])
        } else {
            await trackEvent("user_session_end")
        }
    }
    
    /// Starts a new analytics session
    public func startSession(appVersion: String) async {
        let sessionId = UUID().uuidString
        
        await updateState { state in
            state.sessionId = sessionId
            state.appVersion = appVersion
            state.sessionStartTime = Date()
        }
        
        await trackEvent("session_start", metadata: [
            "session_id": sessionId,
            "app_version": appVersion
        ])
    }
    
    /// Ends the current analytics session
    public func endSession() async {
        let sessionDuration = Date().timeIntervalSince(_state.sessionStartTime)
        
        await trackEvent("session_end", metadata: [
            "session_duration": sessionDuration,
            "events_in_session": _state.metrics.totalEvents
        ])
        
        // Send any remaining events
        await sendPendingEvents()
        
        await updateState { state in
            state.sessionId = ""
            state.currentUserId = nil
        }
    }
    
    /// Gets analytics metrics
    public func getMetrics() async -> AnalyticsMetrics {
        _state.metrics
    }
    
    /// Gets recent events for debugging
    public func getRecentEvents(limit: Int = 50) async -> [AnalyticsEvent] {
        let allEvents = _state.sentEvents + _state.pendingEvents
        return Array(allEvents.suffix(limit))
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
        await startSession(appVersion: "1.0.0")
    }
    
    public func shutdown() async {
        await endSession()
        await updateState { state in
            state.pendingEvents.removeAll()
            state.sentEvents.removeAll()
        }
        observers.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func sendPendingEvents() async {
        guard !_state.pendingEvents.isEmpty else { return }
        
        try? capabilities.validate(.network)
        
        let eventsToSend = _state.pendingEvents
        
        // Simulate sending to analytics service
        await simulateNetworkSend(events: eventsToSend)
        
        await updateState { state in
            state.sentEvents.append(contentsOf: eventsToSend)
            state.pendingEvents.removeAll()
            state.metrics.eventsSent += eventsToSend.count
            state.lastSyncTime = Date()
            
            // Keep only recent sent events to avoid memory issues
            if state.sentEvents.count > 1000 {
                state.sentEvents = Array(state.sentEvents.suffix(500))
            }
        }
    }
    
    private func simulateNetworkSend(events: [AnalyticsEvent]) async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // In a real implementation, this would send to an analytics service
        print("📊 Analytics: Sent \\(events.count) events")
    }
    
    private func categorizePerformance(_ duration: TimeInterval) -> String {
        switch duration {
        case 0..<0.1:
            return "fast"
        case 0.1..<0.5:
            return "medium"
        case 0.5..<2.0:
            return "slow"
        default:
            return "very_slow"
        }
    }
}

// MARK: - Supporting Types

/// State managed by AnalyticsClient
public struct AnalyticsClientState: Sendable {
    public var pendingEvents: [AnalyticsEvent] = []
    public var sentEvents: [AnalyticsEvent] = []
    public var sessionId: String = ""
    public var currentUserId: User.ID?
    public var appVersion: String = ""
    public var sessionStartTime: Date = Date()
    public var lastSyncTime: Date?
    public var metrics: AnalyticsMetrics = AnalyticsMetrics()
    public var batchSize: Int = 10
    
    public init() {}
}

/// Analytics event data structure
public struct AnalyticsEvent: Sendable, Identifiable {
    public let id = UUID()
    public let name: String
    public let metadata: [String: Any]
    public let timestamp: Date
    public let sessionId: String
    public let userId: User.ID?
    
    public init(
        name: String,
        metadata: [String: Any],
        timestamp: Date,
        sessionId: String,
        userId: User.ID?
    ) {
        self.name = name
        self.metadata = metadata
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.userId = userId
    }
}

/// User action types for tracking
public enum UserAction: String, CaseIterable {
    case login = "login"
    case logout = "logout"
    case createTask = "create_task"
    case updateTask = "update_task"
    case deleteTask = "delete_task"
    case createProject = "create_project"
    case joinProject = "join_project"
    case leaveProject = "leave_project"
    case viewDashboard = "view_dashboard"
    case searchTasks = "search_tasks"
    case filterTasks = "filter_tasks"
    case exportData = "export_data"
}

/// Analytics metrics
public struct AnalyticsMetrics: Sendable {
    public var totalEvents: Int = 0
    public var eventsSent: Int = 0
    public var errorEvents: Int = 0
    public var performanceEvents: Int = 0
    public var averageOperationTime: TimeInterval = 0
    public var eventsByType: [String: Int] = [:]
    
    public var pendingEventsCount: Int {
        totalEvents - eventsSent
    }
    
    public var errorRate: Double {
        guard totalEvents > 0 else { return 0 }
        return Double(errorEvents) / Double(totalEvents)
    }
    
    public init() {}
}

/// Weak reference to context for observer pattern
private struct WeakContextReference {
    weak var context: AnyObject?
    
    init<T: AxiomContext>(_ context: T) {
        self.context = context as AnyObject
    }
}