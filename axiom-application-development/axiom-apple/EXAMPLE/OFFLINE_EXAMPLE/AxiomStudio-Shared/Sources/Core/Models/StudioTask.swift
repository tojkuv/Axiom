import Foundation
import SwiftUI

public struct StudioTask: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let description: String?
    public let priority: TaskPriority
    public let category: TaskCategory
    public let status: TaskStatus
    public let dueDate: Date?
    public let createdAt: Date
    public let updatedAt: Date
    public let contactId: UUID?
    public let calendarEventId: String?
    public let locationReminder: LocationReminder?
    public let tags: [String]
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        priority: TaskPriority = .medium,
        category: TaskCategory = .general,
        status: TaskStatus = .pending,
        dueDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        contactId: UUID? = nil,
        calendarEventId: String? = nil,
        locationReminder: LocationReminder? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.category = category
        self.status = status
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.contactId = contactId
        self.calendarEventId = calendarEventId
        self.locationReminder = locationReminder
        self.tags = tags
    }
    
    public var isCompleted: Bool {
        return status == .completed
    }
}

public enum TaskPriority: String, CaseIterable, Codable, Hashable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    public var sortOrder: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    public var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

public enum TaskCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case general = "general"
    case work = "work"
    case personal = "personal"
    case health = "health"
    case learning = "learning"
    case travel = "travel"
    case shopping = "shopping"
    case social = "social"
    
    public var displayName: String {
        switch self {
        case .general: return "General"
        case .work: return "Work"
        case .personal: return "Personal"
        case .health: return "Health"
        case .learning: return "Learning"
        case .travel: return "Travel"
        case .shopping: return "Shopping"
        case .social: return "Social"
        }
    }
}

public enum TaskStatus: String, CaseIterable, Codable, Hashable, Sendable {
    case pending = "pending"
    case inProgress = "inProgress"
    case completed = "completed"
    case cancelled = "cancelled"
    case deferred = "deferred"
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .deferred: return "Deferred"
        }
    }
}

public struct LocationReminder: Codable, Equatable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let radius: Double
    public let triggerOnEntry: Bool
    public let triggerOnExit: Bool
    public let locationName: String?
    
    public init(
        latitude: Double,
        longitude: Double,
        radius: Double = 100.0,
        triggerOnEntry: Bool = true,
        triggerOnExit: Bool = false,
        locationName: String? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.triggerOnEntry = triggerOnEntry
        self.triggerOnExit = triggerOnExit
        self.locationName = locationName
    }
}