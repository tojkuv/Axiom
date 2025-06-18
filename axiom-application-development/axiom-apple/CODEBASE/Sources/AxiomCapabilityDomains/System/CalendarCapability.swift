import Foundation
import EventKit
import AxiomCore
import AxiomCapabilities

// MARK: - Calendar Capability Configuration

/// Configuration for Calendar capability
public struct CalendarCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableCalendarAccess: Bool
    public let enableEventCreation: Bool
    public let enableEventModification: Bool
    public let enableEventDeletion: Bool
    public let enableReminderAccess: Bool
    public let enableAlarmSupport: Bool
    public let enableRecurrenceSupport: Bool
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableSync: Bool
    public let syncInterval: TimeInterval
    public let maxEventsPerQuery: Int
    public let cacheEvents: Bool
    
    public init(
        enableCalendarAccess: Bool = true,
        enableEventCreation: Bool = true,
        enableEventModification: Bool = true,
        enableEventDeletion: Bool = true,
        enableReminderAccess: Bool = true,
        enableAlarmSupport: Bool = true,
        enableRecurrenceSupport: Bool = true,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableSync: Bool = true,
        syncInterval: TimeInterval = 300.0, // 5 minutes
        maxEventsPerQuery: Int = 1000,
        cacheEvents: Bool = true
    ) {
        self.enableCalendarAccess = enableCalendarAccess
        self.enableEventCreation = enableEventCreation
        self.enableEventModification = enableEventModification
        self.enableEventDeletion = enableEventDeletion
        self.enableReminderAccess = enableReminderAccess
        self.enableAlarmSupport = enableAlarmSupport
        self.enableRecurrenceSupport = enableRecurrenceSupport
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableSync = enableSync
        self.syncInterval = syncInterval
        self.maxEventsPerQuery = maxEventsPerQuery
        self.cacheEvents = cacheEvents
    }
    
    public var isValid: Bool {
        syncInterval > 0 && maxEventsPerQuery > 0
    }
    
    public func merged(with other: CalendarCapabilityConfiguration) -> CalendarCapabilityConfiguration {
        CalendarCapabilityConfiguration(
            enableCalendarAccess: other.enableCalendarAccess,
            enableEventCreation: other.enableEventCreation,
            enableEventModification: other.enableEventModification,
            enableEventDeletion: other.enableEventDeletion,
            enableReminderAccess: other.enableReminderAccess,
            enableAlarmSupport: other.enableAlarmSupport,
            enableRecurrenceSupport: other.enableRecurrenceSupport,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableSync: other.enableSync,
            syncInterval: other.syncInterval,
            maxEventsPerQuery: other.maxEventsPerQuery,
            cacheEvents: other.cacheEvents
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> CalendarCapabilityConfiguration {
        var adjustedInterval = syncInterval
        var adjustedLogging = enableLogging
        var adjustedSync = enableSync
        var adjustedMaxEvents = maxEventsPerQuery
        
        if environment.isLowPowerMode {
            adjustedInterval = max(syncInterval, 900.0) // Increase to 15 minutes minimum
            adjustedSync = false
            adjustedMaxEvents = min(maxEventsPerQuery, 100)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return CalendarCapabilityConfiguration(
            enableCalendarAccess: enableCalendarAccess,
            enableEventCreation: enableEventCreation,
            enableEventModification: enableEventModification,
            enableEventDeletion: enableEventDeletion,
            enableReminderAccess: enableReminderAccess,
            enableAlarmSupport: enableAlarmSupport,
            enableRecurrenceSupport: enableRecurrenceSupport,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableSync: adjustedSync,
            syncInterval: adjustedInterval,
            maxEventsPerQuery: adjustedMaxEvents,
            cacheEvents: cacheEvents
        )
    }
}

// MARK: - Calendar Types

/// Calendar event information
public struct CalendarEvent: Sendable, Identifiable, Codable {
    public let id: UUID
    public let eventIdentifier: String?
    public let title: String
    public let notes: String?
    public let location: String?
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let calendarIdentifier: String?
    public let url: URL?
    public let availability: EventAvailability
    public let priority: EventPriority
    public let status: EventStatus
    public let attendees: [EventAttendee]
    public let organizer: EventOrganizer?
    public let alarms: [EventAlarm]
    public let recurrenceRules: [RecurrenceRule]
    public let creationDate: Date
    public let lastModifiedDate: Date?
    public let timeZone: TimeZone?
    
    public enum EventAvailability: String, Sendable, Codable, CaseIterable {
        case notSupported = "not-supported"
        case busy = "busy"
        case free = "free"
        case tentative = "tentative"
        case unavailable = "unavailable"
    }
    
    public enum EventPriority: Int, Sendable, Codable, CaseIterable {
        case none = 0
        case high = 1
        case medium = 5
        case low = 9
    }
    
    public enum EventStatus: String, Sendable, Codable, CaseIterable {
        case none = "none"
        case confirmed = "confirmed"
        case tentative = "tentative"
        case cancelled = "cancelled"
    }
    
    public struct EventAttendee: Sendable, Codable {
        public let name: String?
        public let email: String?
        public let role: AttendeeRole
        public let status: AttendeeStatus
        public let type: AttendeeType
        
        public enum AttendeeRole: String, Sendable, Codable, CaseIterable {
            case unknown = "unknown"
            case required = "required"
            case optional = "optional"
            case chair = "chair"
            case nonParticipant = "non-participant"
        }
        
        public enum AttendeeStatus: String, Sendable, Codable, CaseIterable {
            case unknown = "unknown"
            case pending = "pending"
            case accepted = "accepted"
            case declined = "declined"
            case tentative = "tentative"
            case delegated = "delegated"
            case completed = "completed"
            case inProcess = "in-process"
        }
        
        public enum AttendeeType: String, Sendable, Codable, CaseIterable {
            case unknown = "unknown"
            case person = "person"
            case room = "room"
            case resource = "resource"
            case group = "group"
        }
        
        public init(name: String?, email: String?, role: AttendeeRole, status: AttendeeStatus, type: AttendeeType) {
            self.name = name
            self.email = email
            self.role = role
            self.status = status
            self.type = type
        }
    }
    
    public struct EventOrganizer: Sendable, Codable {
        public let name: String?
        public let email: String?
        
        public init(name: String?, email: String?) {
            self.name = name
            self.email = email
        }
    }
    
    public struct EventAlarm: Sendable, Codable {
        public let type: AlarmType
        public let relativeOffset: TimeInterval?
        public let absoluteDate: Date?
        public let soundName: String?
        public let emailAddress: String?
        public let url: URL?
        
        public enum AlarmType: String, Sendable, Codable, CaseIterable {
            case display = "display"
            case audio = "audio"
            case procedure = "procedure"
            case email = "email"
        }
        
        public init(type: AlarmType, relativeOffset: TimeInterval? = nil, absoluteDate: Date? = nil, soundName: String? = nil, emailAddress: String? = nil, url: URL? = nil) {
            self.type = type
            self.relativeOffset = relativeOffset
            self.absoluteDate = absoluteDate
            self.soundName = soundName
            self.emailAddress = emailAddress
            self.url = url
        }
    }
    
    public struct RecurrenceRule: Sendable, Codable {
        public let frequency: RecurrenceFrequency
        public let interval: Int
        public let endDate: Date?
        public let occurrenceCount: Int?
        public let daysOfWeek: [DayOfWeek]
        public let daysOfMonth: [Int]
        public let monthsOfYear: [Int]
        public let weeksOfYear: [Int]
        public let daysOfYear: [Int]
        public let setPositions: [Int]
        
        public enum RecurrenceFrequency: String, Sendable, Codable, CaseIterable {
            case daily = "daily"
            case weekly = "weekly"
            case monthly = "monthly"
            case yearly = "yearly"
        }
        
        public enum DayOfWeek: Int, Sendable, Codable, CaseIterable {
            case sunday = 1
            case monday = 2
            case tuesday = 3
            case wednesday = 4
            case thursday = 5
            case friday = 6
            case saturday = 7
        }
        
        public init(frequency: RecurrenceFrequency, interval: Int = 1, endDate: Date? = nil, occurrenceCount: Int? = nil, daysOfWeek: [DayOfWeek] = [], daysOfMonth: [Int] = [], monthsOfYear: [Int] = [], weeksOfYear: [Int] = [], daysOfYear: [Int] = [], setPositions: [Int] = []) {
            self.frequency = frequency
            self.interval = interval
            self.endDate = endDate
            self.occurrenceCount = occurrenceCount
            self.daysOfWeek = daysOfWeek
            self.daysOfMonth = daysOfMonth
            self.monthsOfYear = monthsOfYear
            self.weeksOfYear = weeksOfYear
            self.daysOfYear = daysOfYear
            self.setPositions = setPositions
        }
    }
    
    public init(
        eventIdentifier: String? = nil,
        title: String,
        notes: String? = nil,
        location: String? = nil,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        calendarIdentifier: String? = nil,
        url: URL? = nil,
        availability: EventAvailability = .busy,
        priority: EventPriority = .none,
        status: EventStatus = .none,
        attendees: [EventAttendee] = [],
        organizer: EventOrganizer? = nil,
        alarms: [EventAlarm] = [],
        recurrenceRules: [RecurrenceRule] = [],
        timeZone: TimeZone? = nil
    ) {
        self.id = UUID()
        self.eventIdentifier = eventIdentifier
        self.title = title
        self.notes = notes
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.calendarIdentifier = calendarIdentifier
        self.url = url
        self.availability = availability
        self.priority = priority
        self.status = status
        self.attendees = attendees
        self.organizer = organizer
        self.alarms = alarms
        self.recurrenceRules = recurrenceRules
        self.creationDate = Date()
        self.lastModifiedDate = nil
        self.timeZone = timeZone
    }
    
    public var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    public var isRecurring: Bool {
        !recurrenceRules.isEmpty
    }
    
    public var hasAlarms: Bool {
        !alarms.isEmpty
    }
}

/// Calendar information
public struct Calendar: Sendable, Identifiable, Codable {
    public let id: UUID
    public let calendarIdentifier: String
    public let title: String
    public let type: CalendarType
    public let color: String? // Hex color
    public let isSubscribed: Bool
    public let isImmutable: Bool
    public let allowsContentModifications: Bool
    public let supportedEventAvailabilities: [CalendarEvent.EventAvailability]
    
    public enum CalendarType: String, Sendable, Codable, CaseIterable {
        case local = "local"
        case calDAV = "caldav"
        case exchange = "exchange"
        case subscription = "subscription"
        case birthday = "birthday"
    }
    
    public init(
        calendarIdentifier: String,
        title: String,
        type: CalendarType,
        color: String? = nil,
        isSubscribed: Bool = false,
        isImmutable: Bool = false,
        allowsContentModifications: Bool = true,
        supportedEventAvailabilities: [CalendarEvent.EventAvailability] = []
    ) {
        self.id = UUID()
        self.calendarIdentifier = calendarIdentifier
        self.title = title
        self.type = type
        self.color = color
        self.isSubscribed = isSubscribed
        self.isImmutable = isImmutable
        self.allowsContentModifications = allowsContentModifications
        self.supportedEventAvailabilities = supportedEventAvailabilities
    }
}

/// Calendar metrics
public struct CalendarMetrics: Sendable {
    public let totalEvents: Int
    public let eventsCreated: Int
    public let eventsModified: Int
    public let eventsDeleted: Int
    public let upcomingEvents: Int
    public let eventsByCalendar: [String: Int]
    public let eventsByType: [String: Int]
    public let averageEventDuration: TimeInterval
    public let busyTimePercentage: Double
    public let recurringEventsCount: Int
    public let eventsWithAlarmsCount: Int
    public let syncSuccessRate: Double
    
    public init(
        totalEvents: Int = 0,
        eventsCreated: Int = 0,
        eventsModified: Int = 0,
        eventsDeleted: Int = 0,
        upcomingEvents: Int = 0,
        eventsByCalendar: [String: Int] = [:],
        eventsByType: [String: Int] = [:],
        averageEventDuration: TimeInterval = 0,
        busyTimePercentage: Double = 0,
        recurringEventsCount: Int = 0,
        eventsWithAlarmsCount: Int = 0,
        syncSuccessRate: Double = 0
    ) {
        self.totalEvents = totalEvents
        self.eventsCreated = eventsCreated
        self.eventsModified = eventsModified
        self.eventsDeleted = eventsDeleted
        self.upcomingEvents = upcomingEvents
        self.eventsByCalendar = eventsByCalendar
        self.eventsByType = eventsByType
        self.averageEventDuration = averageEventDuration
        self.busyTimePercentage = busyTimePercentage
        self.recurringEventsCount = recurringEventsCount
        self.eventsWithAlarmsCount = eventsWithAlarmsCount
        self.syncSuccessRate = syncSuccessRate
    }
}

// MARK: - Calendar Resource

/// Calendar resource management
public actor CalendarCapabilityResource: AxiomCapabilityResource {
    private let configuration: CalendarCapabilityConfiguration
    private var eventStore: EKEventStore?
    private var cachedEvents: [String: CalendarEvent] = [:]
    private var cachedCalendars: [String: Calendar] = [:]
    private var metrics: CalendarMetrics = CalendarMetrics()
    private var eventStreamContinuation: AsyncStream<CalendarEvent>.Continuation?
    private var calendarStreamContinuation: AsyncStream<Calendar>.Continuation?
    private var syncTimer: Timer?
    private var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    public init(configuration: CalendarCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 12_000_000, // 12MB for calendar data
            cpu: 1.0, // Calendar processing and sync
            bandwidth: 0,
            storage: 5_000_000 // 5MB for cached events
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let eventMemory = cachedEvents.count * 2_000
            let calendarMemory = cachedCalendars.count * 500
            
            return ResourceUsage(
                memory: eventMemory + calendarMemory + 1_000_000,
                cpu: syncTimer != nil ? 0.5 : 0.1,
                bandwidth: 0,
                storage: cachedEvents.count * 1_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        authorizationStatus == .authorized
    }
    
    public func release() async {
        eventStore = nil
        cachedEvents.removeAll()
        cachedCalendars.removeAll()
        
        syncTimer?.invalidate()
        syncTimer = nil
        
        eventStreamContinuation?.finish()
        calendarStreamContinuation?.finish()
        
        metrics = CalendarMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize event store
        eventStore = EKEventStore()
        
        // Check and request authorization
        await requestCalendarAccess()
        
        // Load calendars
        await loadCalendars()
        
        // Setup sync if enabled
        if configuration.enableSync {
            await setupSync()
        }
        
        // Setup change notifications
        await setupChangeNotifications()
    }
    
    internal func updateConfiguration(_ configuration: CalendarCapabilityConfiguration) async throws {
        // Update sync interval if changed
        if configuration.syncInterval != self.configuration.syncInterval {
            await setupSync()
        }
    }
    
    // MARK: - Event Streams
    
    public var eventStream: AsyncStream<CalendarEvent> {
        AsyncStream { continuation in
            self.eventStreamContinuation = continuation
        }
    }
    
    public var calendarStream: AsyncStream<Calendar> {
        AsyncStream { continuation in
            self.calendarStreamContinuation = continuation
        }
    }
    
    // MARK: - Authorization
    
    public func requestCalendarAccess() async -> Bool {
        guard let eventStore = eventStore else { return false }
        
        do {
            let granted = try await eventStore.requestAccess(to: .event)
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            
            if configuration.enableLogging {
                print("[Calendar] 🔐 Calendar access: \(granted ? "granted" : "denied")")
            }
            
            return granted
        } catch {
            if configuration.enableLogging {
                print("[Calendar] ⚠️ Calendar access request failed: \(error)")
            }
            return false
        }
    }
    
    public func getAuthorizationStatus() async -> EKAuthorizationStatus {
        return authorizationStatus
    }
    
    // MARK: - Calendar Management
    
    public func getCalendars() async -> [Calendar] {
        guard let eventStore = eventStore else { return [] }
        
        let ekCalendars = eventStore.calendars(for: .event)
        let calendars = ekCalendars.map { ekCalendar in
            convertEKCalendarToCalendar(ekCalendar)
        }
        
        // Update cache
        for calendar in calendars {
            cachedCalendars[calendar.calendarIdentifier] = calendar
            calendarStreamContinuation?.yield(calendar)
        }
        
        return calendars
    }
    
    public func getCalendar(by identifier: String) async -> Calendar? {
        // Check cache first
        if let cachedCalendar = cachedCalendars[identifier] {
            return cachedCalendar
        }
        
        guard let eventStore = eventStore else { return nil }
        guard let ekCalendar = eventStore.calendar(withIdentifier: identifier) else { return nil }
        
        let calendar = convertEKCalendarToCalendar(ekCalendar)
        cachedCalendars[identifier] = calendar
        
        return calendar
    }
    
    public func getDefaultCalendar() async -> Calendar? {
        guard let eventStore = eventStore else { return nil }
        guard let defaultCalendar = eventStore.defaultCalendarForNewEvents else { return nil }
        
        return convertEKCalendarToCalendar(defaultCalendar)
    }
    
    // MARK: - Event Management
    
    public func createEvent(_ event: CalendarEvent) async throws -> CalendarEvent {
        guard configuration.enableEventCreation else {
            throw CalendarError.eventCreationDisabled
        }
        
        guard let eventStore = eventStore else {
            throw CalendarError.eventStoreNotAvailable
        }
        
        let ekEvent = EKEvent(eventStore: eventStore)
        try await configureEKEvent(ekEvent, from: event)
        
        try eventStore.save(ekEvent, span: .thisEvent)
        
        let createdEvent = convertEKEventToCalendarEvent(ekEvent)
        
        // Update cache
        if configuration.cacheEvents {
            cachedEvents[ekEvent.eventIdentifier] = createdEvent
        }
        
        eventStreamContinuation?.yield(createdEvent)
        await updateCreationMetrics(createdEvent)
        
        if configuration.enableLogging {
            await logEvent(createdEvent, action: "Created")
        }
        
        return createdEvent
    }
    
    public func updateEvent(_ event: CalendarEvent) async throws -> CalendarEvent {
        guard configuration.enableEventModification else {
            throw CalendarError.eventModificationDisabled
        }
        
        guard let eventStore = eventStore else {
            throw CalendarError.eventStoreNotAvailable
        }
        
        guard let eventIdentifier = event.eventIdentifier else {
            throw CalendarError.invalidEventIdentifier
        }
        
        guard let ekEvent = eventStore.event(withIdentifier: eventIdentifier) else {
            throw CalendarError.eventNotFound(eventIdentifier)
        }
        
        try await configureEKEvent(ekEvent, from: event)
        
        try eventStore.save(ekEvent, span: .thisEvent)
        
        let updatedEvent = convertEKEventToCalendarEvent(ekEvent)
        
        // Update cache
        if configuration.cacheEvents {
            cachedEvents[eventIdentifier] = updatedEvent
        }
        
        eventStreamContinuation?.yield(updatedEvent)
        await updateModificationMetrics(updatedEvent)
        
        if configuration.enableLogging {
            await logEvent(updatedEvent, action: "Updated")
        }
        
        return updatedEvent
    }
    
    public func deleteEvent(_ eventIdentifier: String) async throws {
        guard configuration.enableEventDeletion else {
            throw CalendarError.eventDeletionDisabled
        }
        
        guard let eventStore = eventStore else {
            throw CalendarError.eventStoreNotAvailable
        }
        
        guard let ekEvent = eventStore.event(withIdentifier: eventIdentifier) else {
            throw CalendarError.eventNotFound(eventIdentifier)
        }
        
        try eventStore.remove(ekEvent, span: .thisEvent)
        
        // Remove from cache
        cachedEvents.removeValue(forKey: eventIdentifier)
        
        await updateDeletionMetrics()
        
        if configuration.enableLogging {
            print("[Calendar] 🗑️ Deleted event: \(eventIdentifier)")
        }
    }
    
    public func getEvent(by identifier: String) async -> CalendarEvent? {
        // Check cache first
        if let cachedEvent = cachedEvents[identifier] {
            return cachedEvent
        }
        
        guard let eventStore = eventStore else { return nil }
        guard let ekEvent = eventStore.event(withIdentifier: identifier) else { return nil }
        
        let event = convertEKEventToCalendarEvent(ekEvent)
        
        if configuration.cacheEvents {
            cachedEvents[identifier] = event
        }
        
        return event
    }
    
    public func getEvents(in dateRange: DateInterval, calendars: [String]? = nil) async -> [CalendarEvent] {
        guard let eventStore = eventStore else { return [] }
        
        let predicate = eventStore.predicateForEvents(
            withStart: dateRange.start,
            end: dateRange.end,
            calendars: calendars?.compactMap { eventStore.calendar(withIdentifier: $0) }
        )
        
        let ekEvents = eventStore.events(matching: predicate)
        let events = ekEvents.prefix(configuration.maxEventsPerQuery).map { ekEvent in
            convertEKEventToCalendarEvent(ekEvent)
        }
        
        // Update cache
        if configuration.cacheEvents {
            for event in events {
                if let identifier = event.eventIdentifier {
                    cachedEvents[identifier] = event
                }
            }
        }
        
        return Array(events)
    }
    
    public func getUpcomingEvents(limit: Int = 10) async -> [CalendarEvent] {
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: now) ?? now
        let dateRange = DateInterval(start: now, end: endDate)
        
        let events = await getEvents(in: dateRange)
        return Array(events.prefix(limit))
    }
    
    public func searchEvents(query: String, limit: Int = 50) async -> [CalendarEvent] {
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: now) ?? now
        let dateRange = DateInterval(start: now, end: endDate)
        
        let allEvents = await getEvents(in: dateRange)
        let filteredEvents = allEvents.filter { event in
            event.title.localizedCaseInsensitiveContains(query) ||
            event.notes?.localizedCaseInsensitiveContains(query) == true ||
            event.location?.localizedCaseInsensitiveContains(query) == true
        }
        
        return Array(filteredEvents.prefix(limit))
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> CalendarMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = CalendarMetrics()
    }
    
    // MARK: - Private Methods
    
    private func setupSync() async {
        syncTimer?.invalidate()
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: configuration.syncInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.performSync()
            }
        }
    }
    
    private func setupChangeNotifications() async {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.handleEventStoreChanged()
            }
        }
    }
    
    private func loadCalendars() async {
        let calendars = await getCalendars()
        
        if configuration.enableLogging {
            print("[Calendar] 📅 Loaded \(calendars.count) calendars")
        }
    }
    
    private func performSync() async {
        guard let eventStore = eventStore else { return }
        
        // Refresh event store
        eventStore.refreshSourcesIfNecessary()
        
        // Clear cache to force reload
        if configuration.cacheEvents {
            cachedEvents.removeAll()
        }
        
        if configuration.enableLogging {
            print("[Calendar] 🔄 Performed calendar sync")
        }
    }
    
    private func handleEventStoreChanged() async {
        // Clear cache and reload calendars
        cachedEvents.removeAll()
        cachedCalendars.removeAll()
        
        await loadCalendars()
        
        if configuration.enableLogging {
            print("[Calendar] 🔄 Event store changed, refreshed cache")
        }
    }
    
    private func convertEKCalendarToCalendar(_ ekCalendar: EKCalendar) -> Calendar {
        let type: Calendar.CalendarType = switch ekCalendar.type {
        case .local: .local
        case .calDAV: .calDAV
        case .exchange: .exchange
        case .subscription: .subscription
        case .birthday: .birthday
        @unknown default: .local
        }
        
        return Calendar(
            calendarIdentifier: ekCalendar.calendarIdentifier,
            title: ekCalendar.title,
            type: type,
            color: ekCalendar.cgColor?.components?.compactMap { String(format: "%02X", Int($0 * 255)) }.joined(),
            isSubscribed: ekCalendar.isSubscribed,
            isImmutable: ekCalendar.isImmutable,
            allowsContentModifications: ekCalendar.allowsContentModifications,
            supportedEventAvailabilities: ekCalendar.supportedEventAvailabilities.map { availability in
                switch availability {
                case .notSupported: .notSupported
                case .busy: .busy
                case .free: .free
                case .tentative: .tentative
                case .unavailable: .unavailable
                @unknown default: .notSupported
                }
            }
        )
    }
    
    private func convertEKEventToCalendarEvent(_ ekEvent: EKEvent) -> CalendarEvent {
        let attendees = ekEvent.attendees?.map { participant in
            CalendarEvent.EventAttendee(
                name: participant.name,
                email: participant.emailAddress,
                role: convertEKParticipantRole(participant.participantRole),
                status: convertEKParticipantStatus(participant.participantStatus),
                type: convertEKParticipantType(participant.participantType)
            )
        } ?? []
        
        let organizer = ekEvent.organizer.map { participant in
            CalendarEvent.EventOrganizer(
                name: participant.name,
                email: participant.emailAddress
            )
        }
        
        let alarms = ekEvent.alarms?.map { alarm in
            CalendarEvent.EventAlarm(
                type: .display, // Simplified for this implementation
                relativeOffset: alarm.relativeOffset,
                absoluteDate: alarm.absoluteDate,
                soundName: alarm.soundName
            )
        } ?? []
        
        let recurrenceRules = ekEvent.recurrenceRules?.map { rule in
            CalendarEvent.RecurrenceRule(
                frequency: convertEKRecurrenceFrequency(rule.frequency),
                interval: rule.interval,
                endDate: rule.recurrenceEnd?.endDate,
                occurrenceCount: rule.recurrenceEnd?.occurrenceCount
            )
        } ?? []
        
        return CalendarEvent(
            eventIdentifier: ekEvent.eventIdentifier,
            title: ekEvent.title,
            notes: ekEvent.notes,
            location: ekEvent.location,
            startDate: ekEvent.startDate,
            endDate: ekEvent.endDate,
            isAllDay: ekEvent.isAllDay,
            calendarIdentifier: ekEvent.calendar.calendarIdentifier,
            url: ekEvent.url,
            availability: convertEKEventAvailability(ekEvent.availability),
            priority: CalendarEvent.EventPriority(rawValue: ekEvent.priority) ?? .none,
            status: convertEKEventStatus(ekEvent.status),
            attendees: attendees,
            organizer: organizer,
            alarms: alarms,
            recurrenceRules: recurrenceRules,
            timeZone: ekEvent.timeZone
        )
    }
    
    private func configureEKEvent(_ ekEvent: EKEvent, from event: CalendarEvent) async throws {
        ekEvent.title = event.title
        ekEvent.notes = event.notes
        ekEvent.location = event.location
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate
        ekEvent.isAllDay = event.isAllDay
        ekEvent.url = event.url
        ekEvent.availability = convertToEKEventAvailability(event.availability)
        ekEvent.priority = event.priority.rawValue
        ekEvent.timeZone = event.timeZone
        
        // Set calendar if specified
        if let calendarIdentifier = event.calendarIdentifier,
           let eventStore = eventStore,
           let calendar = eventStore.calendar(withIdentifier: calendarIdentifier) {
            ekEvent.calendar = calendar
        }
        
        // Add alarms if enabled
        if configuration.enableAlarmSupport && !event.alarms.isEmpty {
            ekEvent.alarms = event.alarms.compactMap { alarm in
                if let relativeOffset = alarm.relativeOffset {
                    return EKAlarm(relativeOffset: relativeOffset)
                } else if let absoluteDate = alarm.absoluteDate {
                    return EKAlarm(absoluteDate: absoluteDate)
                }
                return nil
            }
        }
        
        // Add recurrence rules if enabled
        if configuration.enableRecurrenceSupport && !event.recurrenceRules.isEmpty {
            ekEvent.recurrenceRules = event.recurrenceRules.compactMap { rule in
                convertToEKRecurrenceRule(rule)
            }
        }
    }
    
    private func convertEKParticipantRole(_ role: EKParticipantRole) -> CalendarEvent.EventAttendee.AttendeeRole {
        switch role {
        case .unknown: return .unknown
        case .required: return .required
        case .optional: return .optional
        case .chair: return .chair
        case .nonParticipant: return .nonParticipant
        @unknown default: return .unknown
        }
    }
    
    private func convertEKParticipantStatus(_ status: EKParticipantStatus) -> CalendarEvent.EventAttendee.AttendeeStatus {
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
    
    private func convertEKParticipantType(_ type: EKParticipantType) -> CalendarEvent.EventAttendee.AttendeeType {
        switch type {
        case .unknown: return .unknown
        case .person: return .person
        case .room: return .room
        case .resource: return .resource
        case .group: return .group
        @unknown default: return .unknown
        }
    }
    
    private func convertEKRecurrenceFrequency(_ frequency: EKRecurrenceFrequency) -> CalendarEvent.RecurrenceRule.RecurrenceFrequency {
        switch frequency {
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        case .yearly: return .yearly
        @unknown default: return .daily
        }
    }
    
    private func convertEKEventAvailability(_ availability: EKEventAvailability) -> CalendarEvent.EventAvailability {
        switch availability {
        case .notSupported: return .notSupported
        case .busy: return .busy
        case .free: return .free
        case .tentative: return .tentative
        case .unavailable: return .unavailable
        @unknown default: return .notSupported
        }
    }
    
    private func convertEKEventStatus(_ status: EKEventStatus) -> CalendarEvent.EventStatus {
        switch status {
        case .none: return .none
        case .confirmed: return .confirmed
        case .tentative: return .tentative
        case .canceled: return .cancelled
        @unknown default: return .none
        }
    }
    
    private func convertToEKEventAvailability(_ availability: CalendarEvent.EventAvailability) -> EKEventAvailability {
        switch availability {
        case .notSupported: return .notSupported
        case .busy: return .busy
        case .free: return .free
        case .tentative: return .tentative
        case .unavailable: return .unavailable
        }
    }
    
    private func convertToEKRecurrenceRule(_ rule: CalendarEvent.RecurrenceRule) -> EKRecurrenceRule {
        let frequency: EKRecurrenceFrequency = switch rule.frequency {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
        
        let recurrenceEnd: EKRecurrenceEnd?
        if let endDate = rule.endDate {
            recurrenceEnd = EKRecurrenceEnd(end: endDate)
        } else if let occurrenceCount = rule.occurrenceCount {
            recurrenceEnd = EKRecurrenceEnd(occurrenceCount: occurrenceCount)
        } else {
            recurrenceEnd = nil
        }
        
        return EKRecurrenceRule(
            recurrenceWith: frequency,
            interval: rule.interval,
            end: recurrenceEnd
        )
    }
    
    private func updateCreationMetrics(_ event: CalendarEvent) async {
        let eventsCreated = metrics.eventsCreated + 1
        let totalEvents = metrics.totalEvents + 1
        
        var eventsByCalendar = metrics.eventsByCalendar
        if let calendarId = event.calendarIdentifier {
            eventsByCalendar[calendarId, default: 0] += 1
        }
        
        metrics = CalendarMetrics(
            totalEvents: totalEvents,
            eventsCreated: eventsCreated,
            eventsModified: metrics.eventsModified,
            eventsDeleted: metrics.eventsDeleted,
            upcomingEvents: metrics.upcomingEvents,
            eventsByCalendar: eventsByCalendar,
            eventsByType: metrics.eventsByType,
            averageEventDuration: metrics.averageEventDuration,
            busyTimePercentage: metrics.busyTimePercentage,
            recurringEventsCount: metrics.recurringEventsCount + (event.isRecurring ? 1 : 0),
            eventsWithAlarmsCount: metrics.eventsWithAlarmsCount + (event.hasAlarms ? 1 : 0),
            syncSuccessRate: metrics.syncSuccessRate
        )
    }
    
    private func updateModificationMetrics(_ event: CalendarEvent) async {
        let eventsModified = metrics.eventsModified + 1
        
        metrics = CalendarMetrics(
            totalEvents: metrics.totalEvents,
            eventsCreated: metrics.eventsCreated,
            eventsModified: eventsModified,
            eventsDeleted: metrics.eventsDeleted,
            upcomingEvents: metrics.upcomingEvents,
            eventsByCalendar: metrics.eventsByCalendar,
            eventsByType: metrics.eventsByType,
            averageEventDuration: metrics.averageEventDuration,
            busyTimePercentage: metrics.busyTimePercentage,
            recurringEventsCount: metrics.recurringEventsCount,
            eventsWithAlarmsCount: metrics.eventsWithAlarmsCount,
            syncSuccessRate: metrics.syncSuccessRate
        )
    }
    
    private func updateDeletionMetrics() async {
        let eventsDeleted = metrics.eventsDeleted + 1
        let totalEvents = max(0, metrics.totalEvents - 1)
        
        metrics = CalendarMetrics(
            totalEvents: totalEvents,
            eventsCreated: metrics.eventsCreated,
            eventsModified: metrics.eventsModified,
            eventsDeleted: eventsDeleted,
            upcomingEvents: metrics.upcomingEvents,
            eventsByCalendar: metrics.eventsByCalendar,
            eventsByType: metrics.eventsByType,
            averageEventDuration: metrics.averageEventDuration,
            busyTimePercentage: metrics.busyTimePercentage,
            recurringEventsCount: metrics.recurringEventsCount,
            eventsWithAlarmsCount: metrics.eventsWithAlarmsCount,
            syncSuccessRate: metrics.syncSuccessRate
        )
    }
    
    private func logEvent(_ event: CalendarEvent, action: String) async {
        let typeIcon = event.isAllDay ? "📅" : "🕐"
        let alarmIcon = event.hasAlarms ? "⏰" : ""
        let recurringIcon = event.isRecurring ? "🔄" : ""
        
        print("[Calendar] \(typeIcon)\(alarmIcon)\(recurringIcon) \(action): \(event.title)")
    }
}

// MARK: - Calendar Capability Implementation

/// Calendar capability providing comprehensive calendar and event management
public actor CalendarCapability: DomainCapability {
    public typealias ConfigurationType = CalendarCapabilityConfiguration
    public typealias ResourceType = CalendarCapabilityResource
    
    private var _configuration: CalendarCapabilityConfiguration
    private var _resources: CalendarCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "calendar-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: CalendarCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: CalendarCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: CalendarCapabilityConfiguration = CalendarCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = CalendarCapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: CalendarCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Calendar configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        // Calendar access is supported on all platforms
        return true
    }
    
    public func requestPermission() async throws {
        let granted = await _resources.requestCalendarAccess()
        if !granted {
            throw CalendarError.accessDenied
        }
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Calendar Operations
    
    /// Get authorization status
    public func getAuthorizationStatus() async throws -> EKAuthorizationStatus {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Calendar capability not available")
        }
        
        return await _resources.getAuthorizationStatus()
    }
    
    /// Get calendars
    public func getCalendars() async throws -> [Calendar] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Calendar capability not available")
        }
        
        return await _resources.getCalendars()
    }
    
    /// Get calendar stream
    public func getCalendarStream() async throws -> AsyncStream<Calendar> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Calendar capability not available")
        }
        
        return await _resources.calendarStream
    }
    
    /// Get specific calendar
    public func getCalendar(by identifier: String) async throws -> Calendar? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Calendar capability not available")
        }
        
        return await _resources.getCalendar(by: identifier)
    }
    
    /// Get default calendar
    public func getDefaultCalendar() async throws -> Calendar? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Calendar capability not available")
        }
        
        return await _resources.getDefaultCalendar()
    }
    
    // MARK: - Event Operations
    
    /// Create event
    public func createEvent(_ event: CalendarEvent) async throws -> CalendarEvent {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Calendar capability not available")
        }
        
        return try await _resources.createEvent(event)
    }
    
    /// Update event
    public func updateEvent(_ event: CalendarEvent) async throws -> CalendarEvent {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Calendar capability not available")
        }
        
        return try await _resources.updateEvent(event)
    }
    
    /// Delete event
    public func deleteEvent(_ eventIdentifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Calendar capability not available")
        }
        
        try await _resources.deleteEvent(eventIdentifier)
    }
    
    /// Get event stream
    public func getEventStream() async throws -> AsyncStream<CalendarEvent> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Calendar capability not available")
        }
        
        return await _resources.eventStream
    }
    
    /// Get specific event
    public func getEvent(by identifier: String) async throws -> CalendarEvent? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Calendar capability not available")
        }
        
        return await _resources.getEvent(by: identifier)
    }
    
    /// Get events in date range
    public func getEvents(in dateRange: DateInterval, calendars: [String]? = nil) async throws -> [CalendarEvent] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Calendar capability not available")
        }
        
        return await _resources.getEvents(in: dateRange, calendars: calendars)
    }
    
    /// Get upcoming events
    public func getUpcomingEvents(limit: Int = 10) async throws -> [CalendarEvent] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Calendar capability not available")
        }
        
        return await _resources.getUpcomingEvents(limit: limit)
    }
    
    /// Search events
    public func searchEvents(query: String, limit: Int = 50) async throws -> [CalendarEvent] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Calendar capability not available")
        }
        
        return await _resources.searchEvents(query: query, limit: limit)
    }
    
    /// Get calendar metrics
    public func getMetrics() async throws -> CalendarMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Calendar capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Calendar capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Create simple event
    public func createSimpleEvent(title: String, startDate: Date, endDate: Date, calendar: String? = nil) async throws -> CalendarEvent {
        let event = CalendarEvent(
            title: title,
            startDate: startDate,
            endDate: endDate,
            calendarIdentifier: calendar
        )
        
        return try await createEvent(event)
    }
    
    /// Check if events exist today
    public func hasEventsToday() async throws -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        let todayRange = DateInterval(start: today, end: tomorrow)
        
        let events = try await getEvents(in: todayRange)
        return !events.isEmpty
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Calendar specific errors
public enum CalendarError: Error, LocalizedError {
    case accessDenied
    case eventStoreNotAvailable
    case eventCreationDisabled
    case eventModificationDisabled
    case eventDeletionDisabled
    case eventNotFound(String)
    case calendarNotFound(String)
    case invalidEventIdentifier
    case saveFailed(String)
    case deleteFailed(String)
    case authorizationFailed
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access denied"
        case .eventStoreNotAvailable:
            return "Event store not available"
        case .eventCreationDisabled:
            return "Event creation is disabled"
        case .eventModificationDisabled:
            return "Event modification is disabled"
        case .eventDeletionDisabled:
            return "Event deletion is disabled"
        case .eventNotFound(let identifier):
            return "Event not found: \(identifier)"
        case .calendarNotFound(let identifier):
            return "Calendar not found: \(identifier)"
        case .invalidEventIdentifier:
            return "Invalid event identifier"
        case .saveFailed(let reason):
            return "Failed to save event: \(reason)"
        case .deleteFailed(let reason):
            return "Failed to delete event: \(reason)"
        case .authorizationFailed:
            return "Calendar authorization failed"
        case .configurationError(let reason):
            return "Calendar configuration error: \(reason)"
        }
    }
}