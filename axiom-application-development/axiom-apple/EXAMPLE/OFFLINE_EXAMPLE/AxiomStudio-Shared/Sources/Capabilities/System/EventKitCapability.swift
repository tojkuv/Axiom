import Foundation
import EventKit
import AxiomCore

// MARK: - EventKit Sendable Conformance
// EventKit types don't conform to Sendable by default, but are safe to use across concurrency boundaries
// when used in read-only scenarios as we do here
extension EKReminder: @unchecked Sendable {}
extension EKEvent: @unchecked Sendable {}
extension EKCalendar: @unchecked Sendable {}
import AxiomCapabilities

public actor EventKitCapability: AxiomCapability {
    public let id = UUID()
    public let name = "EventKit"
    public let version = "1.0.0"
    
    private let eventStore = EKEventStore()
    private var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    public init() {}
    
    public func activate() async throws {
        #if os(iOS)
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        #else
        // On macOS, we need to request access differently
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        #endif
        
        if authorizationStatus == .notDetermined {
            try await requestAccess()
        } else if authorizationStatus != .fullAccess {
            throw EventKitError.accessDenied
        }
    }
    
    public func deactivate() async {
        // EventKit doesn't require explicit deactivation
    }
    
    public var isAvailable: Bool {
        return authorizationStatus == .fullAccess
    }
    
    private func requestAccess() async throws {
        #if os(iOS)
        return try await withCheckedThrowingContinuation { continuation in
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if granted {
                    Task { [weak self] in
                        await self?.updateAuthorizationStatus(.fullAccess)
                    }
                    continuation.resume()
                } else {
                    Task { [weak self] in
                        await self?.updateAuthorizationStatus(.denied)
                    }
                    continuation.resume(throwing: EventKitError.accessDenied)
                }
            }
        }
        #else
        // macOS implementation
        return try await withCheckedThrowingContinuation { continuation in
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if granted {
                    Task { [weak self] in
                        await self?.updateAuthorizationStatus(.fullAccess)
                    }
                    continuation.resume()
                } else {
                    Task { [weak self] in
                        await self?.updateAuthorizationStatus(.denied)
                    }
                    continuation.resume(throwing: EventKitError.accessDenied)
                }
            }
        }
        #endif
    }
    
    // MARK: - Calendar Operations
    
    public func getCalendars() async throws -> [EKCalendar] {
        guard isAvailable else {
            throw EventKitError.accessDenied
        }
        
        return eventStore.calendars(for: .event)
    }
    
    public func getDefaultCalendar() async throws -> EKCalendar? {
        guard isAvailable else {
            throw EventKitError.accessDenied
        }
        
        return eventStore.defaultCalendarForNewEvents
    }
    
    // MARK: - Event Operations
    
    public func getEvents(from startDate: Date, to endDate: Date, calendars: [EKCalendar]? = nil) async throws -> [EKEvent] {
        guard isAvailable else {
            throw EventKitError.accessDenied
        }
        
        let calendarsToSearch = calendars ?? eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendarsToSearch)
        
        return eventStore.events(matching: predicate)
    }
    
    public func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        calendar: EKCalendar? = nil,
        notes: String? = nil,
        location: String? = nil,
        isAllDay: Bool = false
    ) async throws -> EKEvent {
        guard isAvailable else {
            throw EventKitError.accessDenied
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.location = location
        event.isAllDay = isAllDay
        event.calendar = calendar ?? eventStore.defaultCalendarForNewEvents
        
        try eventStore.save(event, span: .thisEvent)
        return event
    }
    
    public func updateEvent(_ event: EKEvent) async throws {
        guard isAvailable else {
            throw EventKitError.accessDenied
        }
        
        try eventStore.save(event, span: .thisEvent)
    }
    
    public func deleteEvent(_ event: EKEvent) async throws {
        guard isAvailable else {
            throw EventKitError.accessDenied
        }
        
        try eventStore.remove(event, span: .thisEvent)
    }
    
    // MARK: - Reminder Operations
    
    public func getReminders(from startDate: Date, to endDate: Date, calendars: [EKCalendar]? = nil) async throws -> [EKReminder] {
        guard isAvailable else {
            throw EventKitError.accessDenied
        }
        
        // Use @Sendable closure to satisfy Swift 6 concurrency requirements
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[EKReminder], Error>) in
            let calendarsToSearch = calendars ?? eventStore.calendars(for: .reminder)
            let predicate = eventStore.predicateForReminders(in: calendarsToSearch)
            
            eventStore.fetchReminders(matching: predicate) { @Sendable reminders in
                if let reminders = reminders {
                    let filteredReminders = reminders.filter { reminder in
                        guard let dueDate = reminder.dueDateComponents?.date else { return false }
                        return dueDate >= startDate && dueDate <= endDate
                    }
                    // EventKit types now have @unchecked Sendable conformance added above
                    continuation.resume(returning: filteredReminders)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    public func createReminder(
        title: String,
        dueDate: Date? = nil,
        calendar: EKCalendar? = nil,
        notes: String? = nil,
        priority: Int = 0
    ) async throws -> EKReminder {
        guard isAvailable else {
            throw EventKitError.accessDenied
        }
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.priority = priority
        reminder.calendar = calendar ?? eventStore.defaultCalendarForNewReminders()
        
        if let dueDate = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        }
        
        try eventStore.save(reminder, commit: true)
        return reminder
    }
    
    public func updateReminder(_ reminder: EKReminder) async throws {
        guard isAvailable else {
            throw EventKitError.accessDenied
        }
        
        try eventStore.save(reminder, commit: true)
    }
    
    public func deleteReminder(_ reminder: EKReminder) async throws {
        guard isAvailable else {
            throw EventKitError.accessDenied
        }
        
        try eventStore.remove(reminder, commit: true)
    }
    
    // MARK: - Conversion Methods
    
    public func convertToCalendarEvent(_ ekEvent: EKEvent) -> CalendarEvent {
        let attendees = ekEvent.attendees?.map { attendee in
            EventAttendee(
                name: attendee.name,
                emailAddress: attendee.url.absoluteString,
                isCurrentUser: attendee.isCurrentUser,
                participantStatus: convertParticipantStatus(attendee.participantStatus),
                participantRole: convertParticipantRole(attendee.participantRole)
            )
        } ?? []
        
        let alerts = ekEvent.alarms?.map { alarm in
            EventAlert(
                relativeOffset: alarm.relativeOffset,
                absoluteDate: alarm.absoluteDate,
                proximity: convertAlarmProximity(alarm.proximity)
            )
        } ?? []
        
        return CalendarEvent(
            id: ekEvent.eventIdentifier ?? UUID().uuidString,
            title: ekEvent.title ?? "",
            description: ekEvent.notes,
            startDate: ekEvent.startDate,
            endDate: ekEvent.endDate,
            isAllDay: ekEvent.isAllDay,
            calendarTitle: ekEvent.calendar?.title ?? "",
            calendarIdentifier: ekEvent.calendar?.calendarIdentifier ?? "",
            attendees: attendees,
            location: ekEvent.location,
            alerts: alerts
        )
    }
    
    public func convertToReminder(_ ekReminder: EKReminder) -> Reminder {
        let list = ReminderList(
            title: ekReminder.calendar?.title ?? "Default",
            color: .blue,
            isDefault: ekReminder.calendar?.isEqual(eventStore.defaultCalendarForNewReminders()) ?? false
        )
        
        let alarms = ekReminder.alarms?.map { alarm in
            ReminderAlarm(
                absoluteDate: alarm.absoluteDate,
                relativeOffset: alarm.relativeOffset != 0 ? alarm.relativeOffset : nil,
                proximity: convertAlarmProximityToReminderProximity(alarm.proximity)
            )
        } ?? []
        
        return Reminder(
            title: ekReminder.title ?? "",
            notes: ekReminder.notes,
            priority: convertPriority(ekReminder.priority),
            list: list,
            isCompleted: ekReminder.isCompleted,
            completionDate: ekReminder.completionDate,
            dueDate: ekReminder.dueDateComponents?.date,
            creationDate: ekReminder.creationDate ?? Date(),
            lastModifiedDate: ekReminder.lastModifiedDate ?? Date(),
            alarms: alarms
        )
    }
    
    // MARK: - Helper Methods
    
    private func convertParticipantStatus(_ status: EKParticipantStatus) -> ParticipantStatus {
        switch status {
        case .unknown: return .unknown
        case .pending: return .pending
        case .accepted: return .accepted
        case .declined: return .declined
        case .tentative: return .tentative
        case .delegated: return .delegated
        case .completed: return .completed
        case .inProcess: return .inProcess
        @unknown default: return .unknown
        }
    }
    
    private func convertParticipantRole(_ role: EKParticipantRole) -> ParticipantRole {
        switch role {
        case .unknown: return .unknown
        case .required: return .required
        case .optional: return .optional
        case .nonParticipant: return .nonParticipant
        case .chair: return .chair
        @unknown default: return .unknown
        }
    }
    
    private func convertAlarmProximity(_ proximity: EKAlarmProximity) -> AlertProximity? {
        switch proximity {
        case .enter: return .enter
        case .leave: return .leave
        case .none: return nil
        @unknown default: return nil
        }
    }
    
    private func convertAlarmProximityToReminderProximity(_ proximity: EKAlarmProximity) -> ReminderProximity? {
        switch proximity {
        case .enter: return .enter
        case .leave: return .leave
        case .none: return nil
        @unknown default: return nil
        }
    }
    
    private func convertPriority(_ priority: Int) -> ReminderPriority {
        switch priority {
        case 0: return .none
        case 1...3: return .low
        case 4...6: return .medium
        case 7...9: return .high
        default: return .none
        }
    }
    
    // MARK: - Batch Operations
    
    public func getEventsAsCalendarEvents(from startDate: Date, to endDate: Date, calendars: [EKCalendar]? = nil) async throws -> [CalendarEvent] {
        let events = try await getEvents(from: startDate, to: endDate, calendars: calendars)
        return events.map { convertToCalendarEvent($0) }
    }
    
    public func getRemindersAsReminders(from startDate: Date, to endDate: Date, calendars: [EKCalendar]? = nil) async throws -> [Reminder] {
        let reminders = try await getReminders(from: startDate, to: endDate, calendars: calendars)
        return reminders.map { convertToReminder($0) }
    }
    
    // MARK: - Helper Methods
    
    private func updateAuthorizationStatus(_ status: EKAuthorizationStatus) {
        authorizationStatus = status
    }
}

public enum EventKitError: Error, LocalizedError {
    case accessDenied
    case eventNotFound
    case reminderNotFound
    case invalidCalendar
    case saveFailed(Error)
    case deleteFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access to calendar and reminders was denied"
        case .eventNotFound:
            return "Event not found"
        case .reminderNotFound:
            return "Reminder not found"
        case .invalidCalendar:
            return "Invalid calendar specified"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete: \(error.localizedDescription)"
        }
    }
}