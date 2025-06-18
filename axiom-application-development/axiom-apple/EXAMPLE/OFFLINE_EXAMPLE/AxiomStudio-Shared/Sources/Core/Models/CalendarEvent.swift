import Foundation

public struct CalendarEvent: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let description: String?
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let calendarTitle: String
    public let calendarIdentifier: String
    public let attendees: [EventAttendee]
    public let location: String?
    public let recurrenceRule: RecurrenceRule?
    public let alerts: [EventAlert]
    public let taskIds: [UUID]
    
    public init(
        id: String,
        title: String,
        description: String? = nil,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        calendarTitle: String,
        calendarIdentifier: String,
        attendees: [EventAttendee] = [],
        location: String? = nil,
        recurrenceRule: RecurrenceRule? = nil,
        alerts: [EventAlert] = [],
        taskIds: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.calendarTitle = calendarTitle
        self.calendarIdentifier = calendarIdentifier
        self.attendees = attendees
        self.location = location
        self.recurrenceRule = recurrenceRule
        self.alerts = alerts
        self.taskIds = taskIds
    }
}

public struct EventAttendee: Codable, Equatable, Hashable, Sendable {
    public let name: String?
    public let emailAddress: String?
    public let isCurrentUser: Bool
    public let participantStatus: ParticipantStatus
    public let participantRole: ParticipantRole
    
    public init(
        name: String? = nil,
        emailAddress: String? = nil,
        isCurrentUser: Bool = false,
        participantStatus: ParticipantStatus = .unknown,
        participantRole: ParticipantRole = .unknown
    ) {
        self.name = name
        self.emailAddress = emailAddress
        self.isCurrentUser = isCurrentUser
        self.participantStatus = participantStatus
        self.participantRole = participantRole
    }
}

public enum ParticipantStatus: String, Codable, Hashable, Sendable {
    case unknown = "unknown"
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case tentative = "tentative"
    case delegated = "delegated"
    case completed = "completed"
    case inProcess = "inProcess"
}

public enum ParticipantRole: String, Codable, Hashable, Sendable {
    case unknown = "unknown"
    case required = "required"
    case optional = "optional"
    case nonParticipant = "nonParticipant"
    case chair = "chair"
}

public struct RecurrenceRule: Codable, Equatable, Hashable, Sendable {
    public let frequency: RecurrenceFrequency
    public let interval: Int
    public let daysOfTheWeek: [DayOfWeek]
    public let daysOfTheMonth: [Int]
    public let daysOfTheYear: [Int]
    public let weeksOfTheYear: [Int]
    public let monthsOfTheYear: [Int]
    public let setPositions: [Int]
    public let recurrenceEnd: RecurrenceEnd?
    
    public init(
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        daysOfTheWeek: [DayOfWeek] = [],
        daysOfTheMonth: [Int] = [],
        daysOfTheYear: [Int] = [],
        weeksOfTheYear: [Int] = [],
        monthsOfTheYear: [Int] = [],
        setPositions: [Int] = [],
        recurrenceEnd: RecurrenceEnd? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.daysOfTheWeek = daysOfTheWeek
        self.daysOfTheMonth = daysOfTheMonth
        self.daysOfTheYear = daysOfTheYear
        self.weeksOfTheYear = weeksOfTheYear
        self.monthsOfTheYear = monthsOfTheYear
        self.setPositions = setPositions
        self.recurrenceEnd = recurrenceEnd
    }
}

public enum RecurrenceFrequency: String, Codable, Hashable, Sendable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
}

public struct DayOfWeek: Codable, Equatable, Hashable, Sendable {
    public let dayOfTheWeek: Int
    public let weekNumber: Int?
    
    public init(dayOfTheWeek: Int, weekNumber: Int? = nil) {
        self.dayOfTheWeek = dayOfTheWeek
        self.weekNumber = weekNumber
    }
}

public enum RecurrenceEnd: Codable, Equatable, Hashable, Sendable {
    case endDate(Date)
    case occurrenceCount(Int)
}

public struct EventAlert: Codable, Equatable, Hashable, Sendable {
    public let relativeOffset: TimeInterval
    public let absoluteDate: Date?
    public let proximity: AlertProximity?
    
    public init(
        relativeOffset: TimeInterval,
        absoluteDate: Date? = nil,
        proximity: AlertProximity? = nil
    ) {
        self.relativeOffset = relativeOffset
        self.absoluteDate = absoluteDate
        self.proximity = proximity
    }
}

public enum AlertProximity: String, Codable, Hashable, Sendable {
    case enter = "enter"
    case leave = "leave"
}