import Foundation

struct Task: Equatable, Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let description: String
    let dueDate: Date?
    let categoryId: String?
    let priority: Priority
    let isCompleted: Bool
    let createdAt: Date
    let updatedAt: Date
    let version: Int?
    
    // Soft delete properties
    let isDeleted: Bool
    let deletedAt: Date?
    let retentionDays: Int?
    let scheduledPurgeDate: Date?
    
    // Sharing properties
    let sharedWith: [TaskShare]
    let sharedBy: String?
    
    // Ownership
    let createdBy: String?
    
    // Convenience initializer with defaults
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String = "",
        dueDate: Date? = nil,
        categoryId: String? = nil,
        priority: Priority = .medium,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        version: Int? = nil,
        isDeleted: Bool = false,
        deletedAt: Date? = nil,
        retentionDays: Int? = nil,
        scheduledPurgeDate: Date? = nil,
        sharedWith: [TaskShare] = [],
        sharedBy: String? = nil,
        createdBy: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.categoryId = categoryId
        self.priority = priority
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.version = version
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
        self.retentionDays = retentionDays
        self.scheduledPurgeDate = scheduledPurgeDate
        self.sharedWith = sharedWith
        self.sharedBy = sharedBy
        self.createdBy = createdBy
    }
    
    // MARK: - Computed Properties
    
    /// Whether the task is overdue (past its due date and not completed)
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }
    
    /// Whether the task is shared with other users
    var isShared: Bool {
        return !sharedWith.isEmpty || sharedBy != nil
    }
    
    // Helper to create an updated version with incremented version number
    func updated(
        title: String? = nil,
        description: String? = nil,
        dueDate: Date?? = nil,
        categoryId: String?? = nil,
        priority: Priority? = nil,
        isCompleted: Bool? = nil,
        isDeleted: Bool? = nil,
        deletedAt: Date?? = nil,
        retentionDays: Int?? = nil,
        sharedWith: [TaskShare]? = nil,
        sharedBy: String?? = nil,
        createdBy: String?? = nil
    ) -> Task {
        let purgeDate: Date?
        if let deleted = deletedAt ?? self.deletedAt,
           let days = retentionDays ?? self.retentionDays {
            purgeDate = Calendar.current.date(byAdding: .day, value: days, to: deleted)
        } else {
            purgeDate = nil
        }
        
        return Task(
            id: self.id,
            title: title ?? self.title,
            description: description ?? self.description,
            dueDate: dueDate ?? self.dueDate,
            categoryId: categoryId ?? self.categoryId,
            priority: priority ?? self.priority,
            isCompleted: isCompleted ?? self.isCompleted,
            createdAt: self.createdAt,
            updatedAt: Date(),
            version: (self.version ?? 0) + 1,
            isDeleted: isDeleted ?? self.isDeleted,
            deletedAt: deletedAt ?? self.deletedAt,
            retentionDays: retentionDays ?? self.retentionDays,
            scheduledPurgeDate: purgeDate,
            sharedWith: sharedWith ?? self.sharedWith,
            sharedBy: sharedBy ?? self.sharedBy,
            createdBy: createdBy ?? self.createdBy
        )
    }
}

enum Priority: String, Codable, CaseIterable, Hashable, Sendable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
}