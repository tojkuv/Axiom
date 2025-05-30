import Foundation
import Axiom

// MARK: - Project Client

/// Domain client responsible for project management
/// Demonstrates project coordination and team management
@Capabilities([.storage, .businessLogic, .stateManagement, .analytics])
public actor ProjectClient: DomainClient {
    public typealias State = ProjectClientState
    public typealias DomainModelType = Project
    
    // MARK: - State
    
    private var _state: State
    private var _stateVersion = StateVersion()
    private var observers: [WeakContextReference] = []
    
    public var stateSnapshot: State {
        _state
    }
    
    // MARK: - Initialization
    
    public init() async throws {
        self._state = ProjectClientState()
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
        for project in _state.projects.values {
            let validation = project.validate()
            if !validation.isValid {
                throw DomainError.validationFailed(validation)
            }
        }
    }
    
    // MARK: - Domain Operations
    
    /// Creates a new project
    public func createProject(
        name: String,
        description: String = "",
        ownerId: User.ID,
        memberIds: Set<User.ID> = [],
        deadline: Date? = nil
    ) async throws -> Project {
        try capabilities.validate(.businessLogic)
        try capabilities.validate(.storage)
        
        // Ensure owner is included in members
        var allMembers = memberIds
        allMembers.insert(ownerId)
        
        let project = Project(
            name: name,
            description: description,
            ownerId: ownerId,
            memberIds: allMembers,
            deadline: deadline
        )
        
        // Validate before adding
        let validation = project.validate()
        guard validation.isValid else {
            throw DomainError.validationFailed(validation)
        }
        
        await updateState { state in
            state.projects[project.id] = project
            state.metrics.totalProjects += 1
            state.lastUpdate = Date()
        }
        
        await trackAnalytics("project_created", metadata: [
            "owner_id": ownerId.description,
            "member_count": String(allMembers.count),
            "has_deadline": String(deadline != nil)
        ])
        
        return project
    }
    
    /// Updates an existing project
    public func updateProject(_ projectId: Project.ID, with updates: ProjectUpdates) async throws -> Project {
        try capabilities.validate(.businessLogic)
        try capabilities.validate(.storage)
        
        guard let existingProject = _state.projects[projectId] else {
            throw DomainError.notFound("Project with id \\(projectId) not found")
        }
        
        let updatedProject = try applyUpdates(to: existingProject, updates: updates)
        
        // Validate updated project
        let validation = updatedProject.validate()
        guard validation.isValid else {
            throw DomainError.validationFailed(validation)
        }
        
        await updateState { state in
            state.projects[projectId] = updatedProject
            state.lastUpdate = Date()
            
            // Update metrics based on status change
            if existingProject.status != updatedProject.status {
                switch updatedProject.status {
                case .completed:
                    state.metrics.completedProjects += 1
                case .cancelled:
                    state.metrics.cancelledProjects += 1
                default:
                    break
                }
            }
        }
        
        await trackAnalytics("project_updated", metadata: [
            "project_id": projectId.description,
            "status_changed": String(existingProject.status != updatedProject.status),
            "new_status": updatedProject.status.rawValue
        ])
        
        return updatedProject
    }
    
    /// Adds a member to a project
    public func addMember(_ userId: User.ID, to projectId: Project.ID) async throws -> Project {
        try capabilities.validate(.businessLogic)
        
        guard let project = _state.projects[projectId] else {
            throw DomainError.notFound("Project with id \\(projectId) not found")
        }
        
        var memberIds = project.memberIds
        memberIds.insert(userId)
        
        let updatedProject = try project.withUpdatedMemberIds(memberIds).get()
        
        await updateState { state in
            state.projects[projectId] = updatedProject
            state.lastUpdate = Date()
        }
        
        await trackAnalytics("project_member_added", metadata: [
            "project_id": projectId.description,
            "user_id": userId.description
        ])
        
        return updatedProject
    }
    
    /// Removes a member from a project
    public func removeMember(_ userId: User.ID, from projectId: Project.ID) async throws -> Project {
        try capabilities.validate(.businessLogic)
        
        guard let project = _state.projects[projectId] else {
            throw DomainError.notFound("Project with id \\(projectId) not found")
        }
        
        // Cannot remove the owner
        guard userId != project.ownerId else {
            throw DomainError.invalidOperation("Cannot remove project owner from project")
        }
        
        var memberIds = project.memberIds
        memberIds.remove(userId)
        
        let updatedProject = try project.withUpdatedMemberIds(memberIds).get()
        
        await updateState { state in
            state.projects[projectId] = updatedProject
            state.lastUpdate = Date()
        }
        
        await trackAnalytics("project_member_removed", metadata: [
            "project_id": projectId.description,
            "user_id": userId.description
        ])
        
        return updatedProject
    }
    
    /// Gets projects with filtering
    public func getProjects(
        status: ProjectStatus? = nil,
        ownerId: User.ID? = nil,
        memberId: User.ID? = nil,
        sortBy: ProjectSortOption = .createdAt,
        ascending: Bool = false
    ) async -> [Project] {
        var projects = Array(_state.projects.values)
        
        // Apply filters
        if let status = status {
            projects = projects.filter { $0.status == status }
        }
        
        if let ownerId = ownerId {
            projects = projects.filter { $0.ownerId == ownerId }
        }
        
        if let memberId = memberId {
            projects = projects.filter { $0.memberIds.contains(memberId) }
        }
        
        // Apply sorting
        projects.sort { first, second in
            let comparison: Bool
            switch sortBy {
            case .name:
                comparison = first.name < second.name
            case .createdAt:
                comparison = first.createdAt < second.createdAt
            case .updatedAt:
                comparison = first.updatedAt < second.updatedAt
            case .deadline:
                let firstDeadline = first.deadline ?? Date.distantFuture
                let secondDeadline = second.deadline ?? Date.distantFuture
                comparison = firstDeadline < secondDeadline
            }
            return ascending ? comparison : !comparison
        }
        
        return projects
    }
    
    /// Gets projects for a specific user (either as owner or member)
    public func getProjectsForUser(_ userId: User.ID) async -> [Project] {
        Array(_state.projects.values.filter { project in
            project.ownerId == userId || project.memberIds.contains(userId)
        })
    }
    
    /// Gets project statistics
    public func getProjectStatistics() async -> ProjectStatistics {
        let projects = Array(_state.projects.values)
        
        let statusCounts = ProjectStatus.allCases.reduce(into: [ProjectStatus: Int]()) { counts, status in
            counts[status] = projects.filter { $0.status == status }.count
        }
        
        let averageMemberCount = projects.isEmpty ? 0 : 
            Double(projects.map { $0.memberIds.count }.reduce(0, +)) / Double(projects.count)
        
        let upcomingDeadlines = projects.compactMap { $0.deadline }
            .filter { $0 > Date() && $0 < Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date() }
            .count
        
        return ProjectStatistics(
            totalProjects: projects.count,
            statusCounts: statusCounts,
            averageMemberCount: averageMemberCount,
            upcomingDeadlines: upcomingDeadlines
        )
    }
    
    /// Gets project metrics
    public func getMetrics() async -> ProjectMetrics {
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
        await updateState { state in
            state.projects.removeAll()
        }
        observers.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func loadSampleData() async {
        // Create sample projects with realistic data
        let sampleProjects = [
            Project(
                name: "Task Manager App",
                description: "A comprehensive task management application with team collaboration features",
                status: .active,
                ownerId: User.ID("admin"),
                memberIds: [User.ID("admin"), User.ID("johndoe"), User.ID("janesmith")],
                deadline: Calendar.current.date(byAdding: .month, value: 3, to: Date())
            ),
            Project(
                name: "Website Redesign",
                description: "Complete overhaul of company website with modern design and improved UX",
                status: .planning,
                ownerId: User.ID("janesmith"),
                memberIds: [User.ID("janesmith"), User.ID("johndoe")],
                deadline: Calendar.current.date(byAdding: .month, value: 2, to: Date())
            )
        ]
        
        await updateState { state in
            for project in sampleProjects {
                state.projects[project.id] = project
            }
            state.metrics.totalProjects = sampleProjects.count
        }
    }
    
    private func applyUpdates(to project: Project, updates: ProjectUpdates) throws -> Project {
        var updatedProject = project
        
        if let name = updates.name {
            updatedProject = try updatedProject.withUpdatedName(name).get()
        }
        
        if let description = updates.description {
            updatedProject = try updatedProject.withUpdatedDescription(description).get()
        }
        
        if let status = updates.status {
            updatedProject = try updatedProject.withUpdatedStatus(status).get()
        }
        
        if let deadline = updates.deadline {
            updatedProject = try updatedProject.withUpdatedDeadline(deadline).get()
        }
        
        // Always update the updatedAt timestamp
        updatedProject = try updatedProject.withUpdatedUpdatedAt(Date()).get()
        
        return updatedProject
    }
    
    private func trackAnalytics(_ event: String, metadata: [String: String] = [:]) async {
        await updateState { state in
            state.metrics.analyticsEvents += 1
        }
    }
}

// MARK: - Supporting Types

/// State managed by ProjectClient
public struct ProjectClientState: Sendable {
    public var projects: [Project.ID: Project] = [:]
    public var metrics: ProjectMetrics = ProjectMetrics()
    public var lastUpdate: Date = Date()
    
    public init() {}
}

/// Metrics for project management
public struct ProjectMetrics: Sendable {
    public var totalProjects: Int = 0
    public var completedProjects: Int = 0
    public var cancelledProjects: Int = 0
    public var analyticsEvents: Int = 0
    
    public var activeProjectsCount: Int {
        totalProjects - completedProjects - cancelledProjects
    }
    
    public var completionRate: Double {
        guard totalProjects > 0 else { return 0 }
        return Double(completedProjects) / Double(totalProjects)
    }
    
    public init() {}
}

/// Project statistics for dashboard display
public struct ProjectStatistics: Sendable {
    public let totalProjects: Int
    public let statusCounts: [ProjectStatus: Int]
    public let averageMemberCount: Double
    public let upcomingDeadlines: Int
    
    public init(
        totalProjects: Int,
        statusCounts: [ProjectStatus: Int],
        averageMemberCount: Double,
        upcomingDeadlines: Int
    ) {
        self.totalProjects = totalProjects
        self.statusCounts = statusCounts
        self.averageMemberCount = averageMemberCount
        self.upcomingDeadlines = upcomingDeadlines
    }
}

/// Updates that can be applied to a project
public struct ProjectUpdates {
    public let name: String?
    public let description: String?
    public let status: ProjectStatus?
    public let deadline: Date??
    
    public init(
        name: String? = nil,
        description: String? = nil,
        status: ProjectStatus? = nil,
        deadline: Date?? = nil
    ) {
        self.name = name
        self.description = description
        self.status = status
        self.deadline = deadline
    }
}

/// Sort options for projects
public enum ProjectSortOption {
    case name
    case createdAt
    case updatedAt
    case deadline
}

/// Domain error extension for invalid operations
extension DomainError {
    static func invalidOperation(_ message: String) -> DomainError {
        .authenticationFailed(message) // Reusing for simplicity
    }
}

/// Weak reference to context for observer pattern
private struct WeakContextReference {
    weak var context: AnyObject?
    
    init<T: AxiomContext>(_ context: T) {
        self.context = context as AnyObject
    }
}