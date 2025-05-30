import Foundation
import Axiom

// MARK: - Task Management Domain Models

/// Represents a task in our task management system
@DomainModel
public struct Task: Sendable, Codable, Identifiable {
    public let id: Task.ID
    public let title: String
    public let description: String
    public let status: TaskStatus
    public let priority: TaskPriority
    public let createdAt: Date
    public let updatedAt: Date
    public let dueDate: Date?
    public let assigneeId: User.ID?
    public let projectId: Project.ID?
    public let tags: Set<String>
    
    public init(
        id: Task.ID = Task.ID.generate(),
        title: String,
        description: String = "",
        status: TaskStatus = .todo,
        priority: TaskPriority = .medium,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        dueDate: Date? = nil,
        assigneeId: User.ID? = nil,
        projectId: Project.ID? = nil,
        tags: Set<String> = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.dueDate = dueDate
        self.assigneeId = assigneeId
        self.projectId = projectId
        self.tags = tags
    }
    
    // MARK: - Business Rules
    
    @BusinessRule("Title must not be empty and must be reasonable length")
    func validateTitle() -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && title.count <= 200
    }
    
    @BusinessRule("Due date must be in the future if set")
    func validateDueDate() -> Bool {
        guard let dueDate = dueDate else { return true }
        return dueDate > Date()
    }
    
    @BusinessRule("Completed tasks must have reasonable completion time")
    func validateCompletionLogic() -> Bool {
        if status == .completed {
            return updatedAt >= createdAt
        }
        return true
    }
    
    @BusinessRule("High priority tasks should have due dates")
    func validateHighPriorityDueDate() -> Bool {
        if priority == .high {
            return dueDate != nil
        }
        return true
    }
}

// MARK: - Task Supporting Types

public enum TaskStatus: String, CaseIterable, Sendable, Codable {
    case todo = "todo"
    case inProgress = "in_progress"
    case inReview = "in_review"
    case completed = "completed"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .inReview: return "In Review"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    public var isActive: Bool {
        switch self {
        case .todo, .inProgress, .inReview: return true
        case .completed, .cancelled: return false
        }
    }
}

public enum TaskPriority: String, CaseIterable, Sendable, Codable, Comparable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    public static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        let order: [TaskPriority] = [.low, .medium, .high, .urgent]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
    
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
}

// MARK: - User Domain Model

/// Represents a user in the system
@DomainModel
public struct User: Sendable, Codable, Identifiable {
    public let id: User.ID
    public let username: String
    public let email: String
    public let fullName: String
    public let role: UserRole
    public let isActive: Bool
    public let createdAt: Date
    public let lastActiveAt: Date
    
    public init(
        id: User.ID = User.ID.generate(),
        username: String,
        email: String,
        fullName: String,
        role: UserRole = .member,
        isActive: Bool = true,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.fullName = fullName
        self.role = role
        self.isActive = isActive
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
    }
    
    // MARK: - Business Rules
    
    @BusinessRule("Username must be unique and valid format")
    func validateUsername() -> Bool {
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        return username.range(of: usernameRegex, options: .regularExpression) != nil
    }
    
    @BusinessRule("Email must be valid format")
    func validateEmail() -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    @BusinessRule("Full name must not be empty")
    func validateFullName() -> Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

public enum UserRole: String, CaseIterable, Sendable, Codable {
    case admin = "admin"
    case manager = "manager"
    case member = "member"
    case viewer = "viewer"
    
    public var displayName: String {
        switch self {
        case .admin: return "Administrator"
        case .manager: return "Manager"
        case .member: return "Member"
        case .viewer: return "Viewer"
        }
    }
    
    public var canEditTasks: Bool {
        switch self {
        case .admin, .manager, .member: return true
        case .viewer: return false
        }
    }
    
    public var canDeleteTasks: Bool {
        switch self {
        case .admin, .manager: return true
        case .member, .viewer: return false
        }
    }
}

// MARK: - Project Domain Model

/// Represents a project that contains tasks
@DomainModel
public struct Project: Sendable, Codable, Identifiable {
    public let id: Project.ID
    public let name: String
    public let description: String
    public let status: ProjectStatus
    public let ownerId: User.ID
    public let memberIds: Set<User.ID>
    public let createdAt: Date
    public let updatedAt: Date
    public let deadline: Date?
    
    public init(
        id: Project.ID = Project.ID.generate(),
        name: String,
        description: String = "",
        status: ProjectStatus = .active,
        ownerId: User.ID,
        memberIds: Set<User.ID> = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deadline: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.status = status
        self.ownerId = ownerId
        self.memberIds = memberIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deadline = deadline
    }
    
    // MARK: - Business Rules
    
    @BusinessRule("Project name must not be empty")
    func validateName() -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    @BusinessRule("Owner must be included in members")
    func validateOwnerInMembers() -> Bool {
        memberIds.contains(ownerId)
    }
    
    @BusinessRule("Active projects should have deadlines")
    func validateActiveProjectDeadline() -> Bool {
        if status == .active {
            return deadline != nil
        }
        return true
    }
}

public enum ProjectStatus: String, CaseIterable, Sendable, Codable {
    case planning = "planning"
    case active = "active"
    case onHold = "on_hold"
    case completed = "completed"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .planning: return "Planning"
        case .active: return "Active"
        case .onHold: return "On Hold"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    public var isActive: Bool {
        switch self {
        case .planning, .active: return true
        case .onHold, .completed, .cancelled: return false
        }
    }
}

// MARK: - ID Extensions

extension Task {
    public struct ID: Hashable, Sendable, Codable, CustomStringConvertible, ExpressibleByStringLiteral {
        private let value: String
        
        public init(_ value: String) {
            self.value = value
        }
        
        public init(stringLiteral value: String) {
            self.value = value
        }
        
        public static func generate() -> ID {
            ID(UUID().uuidString)
        }
        
        public var description: String { value }
    }
}

extension User {
    public struct ID: Hashable, Sendable, Codable, CustomStringConvertible, ExpressibleByStringLiteral {
        private let value: String
        
        public init(_ value: String) {
            self.value = value
        }
        
        public init(stringLiteral value: String) {
            self.value = value
        }
        
        public static func generate() -> ID {
            ID(UUID().uuidString)
        }
        
        public var description: String { value }
    }
}

extension Project {
    public struct ID: Hashable, Sendable, Codable, CustomStringConvertible, ExpressibleByStringLiteral {
        private let value: String
        
        public init(_ value: String) {
            self.value = value
        }
        
        public init(stringLiteral value: String) {
            self.value = value
        }
        
        public static func generate() -> ID {
            ID(UUID().uuidString)
        }
        
        public var description: String { value }
    }
}