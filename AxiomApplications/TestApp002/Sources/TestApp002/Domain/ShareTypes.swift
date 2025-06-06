import Foundation

/// Permission levels for task sharing with enhanced access control
enum SharePermission: String, Codable, CaseIterable, Hashable, Sendable {
    case read = "read"           // View only
    case write = "write"         // View and edit task content
    case admin = "admin"         // Full control including sharing management
    
    /// Whether this permission allows task modification
    var canWrite: Bool {
        return self == .write || self == .admin
    }
    
    /// Whether this permission allows sharing management
    var canManageSharing: Bool {
        return self == .admin
    }
    
    /// Whether this permission allows viewing task details
    var canRead: Bool {
        return true // All permission levels allow reading
    }
    
    /// Whether this permission allows deleting tasks
    var canDelete: Bool {
        return self == .admin
    }
    
    /// Whether this permission allows category changes
    var canChangeCategory: Bool {
        return self == .write || self == .admin
    }
    
    /// Whether this permission allows due date changes
    var canChangeDueDate: Bool {
        return self == .write || self == .admin
    }
    
    /// Whether this permission allows priority changes
    var canChangePriority: Bool {
        return self == .write || self == .admin
    }
    
    /// Permission hierarchy for validation (higher number = more permissions)
    var level: Int {
        switch self {
        case .read: return 1
        case .write: return 2
        case .admin: return 3
        }
    }
    
    /// Check if this permission includes all capabilities of another permission
    func includes(_ other: SharePermission) -> Bool {
        return self.level >= other.level
    }
}

/// Represents a task share relationship
struct TaskShare: Equatable, Identifiable, Codable, Hashable, Sendable {
    let id: String
    let taskId: String
    let userId: String
    let permission: SharePermission
    let sharedAt: Date
    let sharedBy: String
    
    init(
        id: String = UUID().uuidString,
        taskId: String,
        userId: String,
        permission: SharePermission,
        sharedAt: Date = Date(),
        sharedBy: String
    ) {
        self.id = id
        self.taskId = taskId
        self.userId = userId
        self.permission = permission
        self.sharedAt = sharedAt
        self.sharedBy = sharedBy
    }
}

/// Represents a pending share operation
struct PendingShare: Equatable, Identifiable, Codable, Hashable, Sendable {
    let id: String
    let taskId: String
    let userId: String
    let permission: SharePermission
    let queuedAt: Date
    let sharedBy: String
    
    init(
        id: String = UUID().uuidString,
        taskId: String,
        userId: String,
        permission: SharePermission,
        queuedAt: Date = Date(),
        sharedBy: String
    ) {
        self.id = id
        self.taskId = taskId
        self.userId = userId
        self.permission = permission
        self.queuedAt = queuedAt
        self.sharedBy = sharedBy
    }
}

/// Represents real-time collaboration state for enhanced sharing
struct CollaborationInfo: Equatable, Codable, Hashable, Sendable {
    let taskId: String
    let activeCollaborators: [ActiveCollaborator]
    let lastCollaborativeEdit: Date?
    let conflictResolutionMode: ConflictResolutionMode
    
    init(
        taskId: String,
        activeCollaborators: [ActiveCollaborator] = [],
        lastCollaborativeEdit: Date? = nil,
        conflictResolutionMode: ConflictResolutionMode = .lastWriteWins
    ) {
        self.taskId = taskId
        self.activeCollaborators = activeCollaborators
        self.lastCollaborativeEdit = lastCollaborativeEdit
        self.conflictResolutionMode = conflictResolutionMode
    }
}

/// Represents an active collaborator on a task
struct ActiveCollaborator: Equatable, Identifiable, Codable, Hashable, Sendable {
    let id: String
    let userId: String
    let userName: String
    let permission: SharePermission
    let lastSeen: Date
    let isCurrentlyEditing: Bool
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        userName: String,
        permission: SharePermission,
        lastSeen: Date = Date(),
        isCurrentlyEditing: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.permission = permission
        self.lastSeen = lastSeen
        self.isCurrentlyEditing = isCurrentlyEditing
    }
}

/// Conflict resolution strategies for collaborative editing
enum ConflictResolutionMode: String, Codable, CaseIterable, Hashable, Sendable {
    case lastWriteWins = "last_write_wins"
    case manualResolution = "manual_resolution"
    case collaborativeWarning = "collaborative_warning"
    
    var description: String {
        switch self {
        case .lastWriteWins:
            return "Automatic resolution using most recent change"
        case .manualResolution:
            return "User must manually resolve conflicts"
        case .collaborativeWarning:
            return "Show warning when multiple users edit simultaneously"
        }
    }
}

/// Permission validation helper
struct PermissionValidator {
    
    /// Validates if a user has permission to perform an action on a task
    static func validatePermission(
        for userId: String,
        on task: Task,
        requiring permission: SharePermission
    ) -> Bool {
        // Task owner has all permissions
        if task.sharedBy == nil || task.sharedBy == userId {
            return true
        }
        
        // Check shared permissions
        guard let userShare = task.sharedWith.first(where: { $0.userId == userId }) else {
            return false
        }
        
        return userShare.permission.includes(permission)
    }
    
    /// Gets the effective permission level for a user on a task
    static func getEffectivePermission(
        for userId: String,
        on task: Task
    ) -> SharePermission? {
        // Task owner has admin permission
        if task.sharedBy == nil || task.sharedBy == userId {
            return .admin
        }
        
        // Return shared permission level
        return task.sharedWith.first(where: { $0.userId == userId })?.permission
    }
    
    /// Validates if a user can modify a specific field
    static func canModifyField(
        _ field: TaskField,
        by userId: String,
        on task: Task
    ) -> Bool {
        guard let permission = getEffectivePermission(for: userId, on: task) else {
            return false
        }
        
        switch field {
        case .title, .description:
            return permission.canWrite
        case .category:
            return permission.canChangeCategory
        case .dueDate:
            return permission.canChangeDueDate
        case .priority:
            return permission.canChangePriority
        case .completion:
            return permission.canWrite
        case .sharing:
            return permission.canManageSharing
        case .deletion:
            return permission.canDelete
        }
    }
}

/// Task fields that can be modified with different permission requirements
enum TaskField {
    case title
    case description
    case category
    case dueDate
    case priority
    case completion
    case sharing
    case deletion
}