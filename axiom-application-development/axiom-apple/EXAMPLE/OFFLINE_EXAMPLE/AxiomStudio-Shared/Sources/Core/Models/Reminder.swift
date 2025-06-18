import Foundation

public struct Reminder: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let notes: String?
    public let priority: ReminderPriority
    public let list: ReminderList
    public let isCompleted: Bool
    public let completionDate: Date?
    public let dueDate: Date?
    public let creationDate: Date
    public let lastModifiedDate: Date
    public let location: LocationReminder?
    public let alarms: [ReminderAlarm]
    public let recurrenceRule: RecurrenceRule?
    public let associatedTaskIds: [UUID]
    public let associatedContactIds: [UUID]
    
    public init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        priority: ReminderPriority = .none,
        list: ReminderList,
        isCompleted: Bool = false,
        completionDate: Date? = nil,
        dueDate: Date? = nil,
        creationDate: Date = Date(),
        lastModifiedDate: Date = Date(),
        location: LocationReminder? = nil,
        alarms: [ReminderAlarm] = [],
        recurrenceRule: RecurrenceRule? = nil,
        associatedTaskIds: [UUID] = [],
        associatedContactIds: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.priority = priority
        self.list = list
        self.isCompleted = isCompleted
        self.completionDate = completionDate
        self.dueDate = dueDate
        self.creationDate = creationDate
        self.lastModifiedDate = lastModifiedDate
        self.location = location
        self.alarms = alarms
        self.recurrenceRule = recurrenceRule
        self.associatedTaskIds = associatedTaskIds
        self.associatedContactIds = associatedContactIds
    }
}

public enum ReminderPriority: Int, CaseIterable, Codable, Hashable, Sendable {
    case none = 0
    case low = 1
    case medium = 5
    case high = 9
    
    public var displayName: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

public struct ReminderList: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let color: ReminderListColor
    public let isDefault: Bool
    public let creationDate: Date
    public let reminderCount: Int
    public let completedReminderCount: Int
    
    public init(
        id: UUID = UUID(),
        title: String,
        color: ReminderListColor = .blue,
        isDefault: Bool = false,
        creationDate: Date = Date(),
        reminderCount: Int = 0,
        completedReminderCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.color = color
        self.isDefault = isDefault
        self.creationDate = creationDate
        self.reminderCount = reminderCount
        self.completedReminderCount = completedReminderCount
    }
}

public enum ReminderListColor: String, CaseIterable, Codable, Hashable, Sendable {
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case blue = "blue"
    case purple = "purple"
    case brown = "brown"
    case gray = "gray"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

public struct ReminderAlarm: Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let absoluteDate: Date?
    public let relativeOffset: TimeInterval?
    public let proximity: ReminderProximity?
    
    public init(
        id: UUID = UUID(),
        absoluteDate: Date? = nil,
        relativeOffset: TimeInterval? = nil,
        proximity: ReminderProximity? = nil
    ) {
        self.id = id
        self.absoluteDate = absoluteDate
        self.relativeOffset = relativeOffset
        self.proximity = proximity
    }
}

public enum ReminderProximity: String, CaseIterable, Codable, Hashable, Sendable {
    case enter = "enter"
    case leave = "leave"
    
    public var displayName: String {
        switch self {
        case .enter: return "When I arrive"
        case .leave: return "When I leave"
        }
    }
}