import Foundation
import Axiom

// MARK: - Task Client

/// Domain client responsible for task management
/// Demonstrates @Capabilities macro and domain client patterns
@Capabilities([.storage, .businessLogic, .stateManagement, .analytics])
public actor TaskClient: DomainClient {
    public typealias State = TaskClientState
    public typealias DomainModelType = Task
    
    // MARK: - State
    
    private var _state: State
    private var _stateVersion = StateVersion()
    private var observers: [WeakContextReference] = []
    
    public var stateSnapshot: State {
        _state
    }
    
    // MARK: - Initialization
    
    public init() async throws {
        self._state = TaskClientState()
        
        // Initialize with sample data for demonstration
        await loadSampleData()
    }
    
    // MARK: - State Management
    
    public func updateState<T>(_ update: @Sendable (inout State) throws -> T) async rethrows -> T {
        let result = try update(&_state)
        _stateVersion = _stateVersion.incrementMinor()
        await notifyObservers()
        return result
    }
    
    public func validateState() async throws {
        for task in _state.tasks.values {
            let validation = task.validate()
            if !validation.isValid {
                throw DomainError.validationFailed(validation)
            }
        }
    }
    
    // MARK: - Domain Operations
    
    /// Creates a new task
    public func createTask(
        title: String,
        description: String = "",
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        assigneeId: User.ID? = nil,
        projectId: Project.ID? = nil
    ) async throws -> Task {
        try capabilities.validate(.businessLogic)
        try capabilities.validate(.storage)
        
        let task = Task(
            title: title,
            description: description,
            priority: priority,
            dueDate: dueDate,
            assigneeId: assigneeId,
            projectId: projectId
        )
        
        // Validate before adding
        let validation = task.validate()
        guard validation.isValid else {
            throw DomainError.validationFailed(validation)
        }
        
        await updateState { state in
            state.tasks[task.id] = task
            state.metrics.totalTasks += 1
            state.lastUpdate = Date()
        }
        
        // Track analytics
        await trackAnalytics("task_created", metadata: [
            "priority": priority.rawValue,
            "has_due_date": String(dueDate != nil),
            "has_assignee": String(assigneeId != nil)
        ])
        
        return task
    }
    
    /// Updates an existing task
    public func updateTask(_ taskId: Task.ID, with updates: TaskUpdates) async throws -> Task {
        try capabilities.validate(.businessLogic)
        try capabilities.validate(.storage)
        
        guard let existingTask = _state.tasks[taskId] else {
            throw DomainError.notFound("Task with id \\(taskId) not found")
        }
        
        let updatedTask = try applyUpdates(to: existingTask, updates: updates)
        
        // Validate updated task
        let validation = updatedTask.validate()
        guard validation.isValid else {
            throw DomainError.validationFailed(validation)
        }
        
        await updateState { state in
            state.tasks[taskId] = updatedTask
            state.lastUpdate = Date()
            
            // Update metrics based on status change
            if existingTask.status != updatedTask.status {
                switch updatedTask.status {
                case .completed:
                    state.metrics.completedTasks += 1
                case .cancelled:
                    state.metrics.cancelledTasks += 1
                default:
                    break
                }
            }
        }
        
        // Track analytics
        await trackAnalytics("task_updated", metadata: [
            "task_id": taskId.description,
            "status_changed": String(existingTask.status != updatedTask.status),
            "new_status": updatedTask.status.rawValue
        ])
        
        return updatedTask
    }
    
    /// Deletes a task
    public func deleteTask(_ taskId: Task.ID) async throws {
        try capabilities.validate(.businessLogic)
        try capabilities.validate(.storage)
        
        guard _state.tasks[taskId] != nil else {
            throw DomainError.notFound("Task with id \\(taskId) not found")
        }
        
        await updateState { state in
            state.tasks.removeValue(forKey: taskId)
            state.lastUpdate = Date()
        }
        
        await trackAnalytics("task_deleted", metadata: ["task_id": taskId.description])
    }
    
    /// Gets tasks with filtering and sorting
    public func getTasks(
        status: TaskStatus? = nil,
        priority: TaskPriority? = nil,
        assigneeId: User.ID? = nil,
        projectId: Project.ID? = nil,
        sortBy: TaskSortOption = .createdAt,
        ascending: Bool = false
    ) async -> [Task] {
        var tasks = Array(_state.tasks.values)
        
        // Apply filters
        if let status = status {
            tasks = tasks.filter { $0.status == status }
        }
        
        if let priority = priority {
            tasks = tasks.filter { $0.priority == priority }
        }
        
        if let assigneeId = assigneeId {
            tasks = tasks.filter { $0.assigneeId == assigneeId }
        }
        
        if let projectId = projectId {
            tasks = tasks.filter { $0.projectId == projectId }
        }
        
        // Apply sorting
        tasks.sort { first, second in
            let comparison: Bool
            switch sortBy {
            case .createdAt:
                comparison = first.createdAt < second.createdAt
            case .updatedAt:
                comparison = first.updatedAt < second.updatedAt
            case .dueDate:
                let firstDue = first.dueDate ?? Date.distantFuture
                let secondDue = second.dueDate ?? Date.distantFuture
                comparison = firstDue < secondDue
            case .priority:
                comparison = first.priority < second.priority
            case .title:
                comparison = first.title < second.title
            }
            return ascending ? comparison : !comparison
        }
        
        return tasks
    }
    
    /// Gets task metrics
    public func getMetrics() async -> TaskMetrics {
        _state.metrics
    }
    
    // MARK: - Observer Pattern
    
    public func addObserver<T: AxiomContext>(_ context: T) async {
        let reference = WeakContextReference(context)
        observers.append(reference)
        observers.removeAll { $0.context == nil } // Cleanup
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
        observers.removeAll { $0.context == nil } // Cleanup
    }
    
    // MARK: - Lifecycle
    
    public func initialize() async throws {
        try await validateState()
    }
    
    public func shutdown() async {
        await updateState { state in
            state.tasks.removeAll()
        }
        observers.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func loadSampleData() async {
        let sampleTasks = [
            Task(
                title: "Implement user authentication",
                description: "Add login and registration functionality",
                priority: .high,
                dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
            ),
            Task(
                title: "Design dashboard UI",
                description: "Create wireframes and mockups for the main dashboard",
                priority: .medium,
                status: .inProgress
            ),
            Task(
                title: "Set up CI/CD pipeline",
                description: "Configure automated testing and deployment",
                priority: .low,
                dueDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())
            )
        ]
        
        await updateState { state in
            for task in sampleTasks {
                state.tasks[task.id] = task
            }
            state.metrics.totalTasks = sampleTasks.count
        }
    }
    
    private func applyUpdates(to task: Task, updates: TaskUpdates) throws -> Task {
        var updatedTask = task
        
        if let title = updates.title {
            updatedTask = try updatedTask.withUpdatedTitle(title).get()
        }
        
        if let description = updates.description {
            updatedTask = try updatedTask.withUpdatedDescription(description).get()
        }
        
        if let status = updates.status {
            updatedTask = try updatedTask.withUpdatedStatus(status).get()
        }
        
        if let priority = updates.priority {
            updatedTask = try updatedTask.withUpdatedPriority(priority).get()
        }
        
        if let dueDate = updates.dueDate {
            updatedTask = try updatedTask.withUpdatedDueDate(dueDate).get()
        }
        
        if let assigneeId = updates.assigneeId {
            updatedTask = try updatedTask.withUpdatedAssigneeId(assigneeId).get()
        }
        
        if let projectId = updates.projectId {
            updatedTask = try updatedTask.withUpdatedProjectId(projectId).get()
        }
        
        // Always update the updatedAt timestamp
        updatedTask = try updatedTask.withUpdatedUpdatedAt(Date()).get()
        
        return updatedTask
    }
    
    private func trackAnalytics(_ event: String, metadata: [String: String] = [:]) async {
        // In a real implementation, this would send to analytics client
        // For now, just track locally
        await updateState { state in
            state.metrics.analyticsEvents += 1
        }
    }
}

// MARK: - Supporting Types

/// State managed by TaskClient
public struct TaskClientState: Sendable {
    public var tasks: [Task.ID: Task] = [:]
    public var metrics: TaskMetrics = TaskMetrics()
    public var lastUpdate: Date = Date()
    
    public init() {}
}

/// Metrics for task management
public struct TaskMetrics: Sendable {
    public var totalTasks: Int = 0
    public var completedTasks: Int = 0
    public var cancelledTasks: Int = 0
    public var analyticsEvents: Int = 0
    
    public var activeTasksCount: Int {
        totalTasks - completedTasks - cancelledTasks
    }
    
    public var completionRate: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    public init() {}
}

/// Updates that can be applied to a task
public struct TaskUpdates {
    public let title: String?
    public let description: String?
    public let status: TaskStatus?
    public let priority: TaskPriority?
    public let dueDate: Date??  // Double optional to distinguish between nil (no update) and nil value
    public let assigneeId: User.ID??
    public let projectId: Project.ID??
    
    public init(
        title: String? = nil,
        description: String? = nil,
        status: TaskStatus? = nil,
        priority: TaskPriority? = nil,
        dueDate: Date?? = nil,
        assigneeId: User.ID?? = nil,
        projectId: Project.ID?? = nil
    ) {
        self.title = title
        self.description = description
        self.status = status
        self.priority = priority
        self.dueDate = dueDate
        self.assigneeId = assigneeId
        self.projectId = projectId
    }
}

/// Sort options for tasks
public enum TaskSortOption {
    case createdAt
    case updatedAt
    case dueDate
    case priority
    case title
}

/// Weak reference to context for observer pattern
private struct WeakContextReference {
    weak var context: AnyObject?
    
    init<T: AxiomContext>(_ context: T) {
        self.context = context as AnyObject
    }
}