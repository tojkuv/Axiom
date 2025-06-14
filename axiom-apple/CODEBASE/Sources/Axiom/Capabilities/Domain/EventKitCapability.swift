import Foundation
@preconcurrency import EventKit

// MARK: - EventKit Configuration

/// Configuration for EventKit capability
public struct EventKitConfiguration: CapabilityConfiguration {
    public let entityTypes: Set<EKEntityType>
    public let requestTimeout: TimeInterval
    public let enableAutomaticSyncing: Bool
    public let defaultCalendarTitle: String?
    public let defaultReminderList: String?
    
    public init(
        entityTypes: Set<EKEntityType> = [.event],
        requestTimeout: TimeInterval = 30.0,
        enableAutomaticSyncing: Bool = true,
        defaultCalendarTitle: String? = nil,
        defaultReminderList: String? = nil
    ) {
        self.entityTypes = entityTypes
        self.requestTimeout = requestTimeout
        self.enableAutomaticSyncing = enableAutomaticSyncing
        self.defaultCalendarTitle = defaultCalendarTitle
        self.defaultReminderList = defaultReminderList
    }
    
    public var isValid: Bool {
        return requestTimeout > 0 && !entityTypes.isEmpty
    }
    
    public func merged(with other: EventKitConfiguration) -> EventKitConfiguration {
        return EventKitConfiguration(
            entityTypes: entityTypes.union(other.entityTypes),
            requestTimeout: other.requestTimeout,
            enableAutomaticSyncing: other.enableAutomaticSyncing,
            defaultCalendarTitle: other.defaultCalendarTitle ?? defaultCalendarTitle,
            defaultReminderList: other.defaultReminderList ?? defaultReminderList
        )
    }
    
    public func adjusted(for environment: CapabilityEnvironment) -> EventKitConfiguration {
        var adjustedTimeout = requestTimeout
        var adjustedSyncing = enableAutomaticSyncing
        
        if environment.isLowPowerMode {
            adjustedTimeout *= 1.5
            adjustedSyncing = false // Disable automatic syncing to save battery
        }
        
        if environment.isDebug {
            adjustedTimeout *= 2.0
        }
        
        return EventKitConfiguration(
            entityTypes: entityTypes,
            requestTimeout: adjustedTimeout,
            enableAutomaticSyncing: adjustedSyncing,
            defaultCalendarTitle: defaultCalendarTitle,
            defaultReminderList: defaultReminderList
        )
    }
    
    // Common configuration presets
    public static let eventsOnly = EventKitConfiguration(
        entityTypes: [.event]
    )
    
    public static let remindersOnly = EventKitConfiguration(
        entityTypes: [.reminder]
    )
    
    public static let eventsAndReminders = EventKitConfiguration(
        entityTypes: [.event, .reminder]
    )
}

// MARK: - EventKitConfiguration Codable Implementation

extension EventKitConfiguration: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let entityTypeRawValues = try container.decode([UInt].self, forKey: .entityTypes)
        self.entityTypes = Set(entityTypeRawValues.compactMap { EKEntityType(rawValue: $0) })
        
        self.requestTimeout = try container.decode(TimeInterval.self, forKey: .requestTimeout)
        self.enableAutomaticSyncing = try container.decode(Bool.self, forKey: .enableAutomaticSyncing)
        self.defaultCalendarTitle = try container.decodeIfPresent(String.self, forKey: .defaultCalendarTitle)
        self.defaultReminderList = try container.decodeIfPresent(String.self, forKey: .defaultReminderList)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let entityTypeRawValues = entityTypes.map { $0.rawValue }
        try container.encode(entityTypeRawValues, forKey: .entityTypes)
        
        try container.encode(requestTimeout, forKey: .requestTimeout)
        try container.encode(enableAutomaticSyncing, forKey: .enableAutomaticSyncing)
        try container.encodeIfPresent(defaultCalendarTitle, forKey: .defaultCalendarTitle)
        try container.encodeIfPresent(defaultReminderList, forKey: .defaultReminderList)
    }
    
    private enum CodingKeys: String, CodingKey {
        case entityTypes
        case requestTimeout
        case enableAutomaticSyncing
        case defaultCalendarTitle
        case defaultReminderList
    }
}

// MARK: - EventKit Data Types

/// Authorization status for EventKit
public enum EventKitAuthorizationStatus: Sendable, Codable {
    case notDetermined
    case restricted
    case denied
    case authorized
    
    public init(from status: EKAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .authorized, .fullAccess:
            self = .authorized
        case .writeOnly:
            self = .authorized // Treat write-only as authorized for simplicity
        @unknown default:
            self = .notDetermined
        }
    }
}

/// Event wrapper for safe passing across actor boundaries
public struct EventData: Sendable, Codable {
    public let eventIdentifier: String?
    public let title: String
    public let notes: String?
    public let location: String?
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let calendar: String?
    public let url: URL?
    public let hasAlarms: Bool
    public let hasAttendees: Bool
    public let availability: Int
    
    public init(from event: EKEvent) {
        self.eventIdentifier = event.eventIdentifier
        self.title = event.title ?? ""
        self.notes = event.notes
        self.location = event.location
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.isAllDay = event.isAllDay
        self.calendar = event.calendar?.title
        self.url = event.url
        self.hasAlarms = !(event.alarms?.isEmpty ?? true)
        self.hasAttendees = !(event.attendees?.isEmpty ?? true)
        self.availability = event.availability.rawValue
    }
    
    public init(
        eventIdentifier: String? = nil,
        title: String,
        notes: String? = nil,
        location: String? = nil,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        calendar: String? = nil,
        url: URL? = nil,
        hasAlarms: Bool = false,
        hasAttendees: Bool = false,
        availability: Int = 0
    ) {
        self.eventIdentifier = eventIdentifier
        self.title = title
        self.notes = notes
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.calendar = calendar
        self.url = url
        self.hasAlarms = hasAlarms
        self.hasAttendees = hasAttendees
        self.availability = availability
    }
}

/// Reminder wrapper for safe passing across actor boundaries
public struct ReminderData: Sendable, Codable {
    public let calendarItemIdentifier: String?
    public let title: String
    public let notes: String?
    public let priority: Int
    public let isCompleted: Bool
    public let completionDate: Date?
    public let dueDateComponents: DateComponents?
    public let list: String?
    public let url: URL?
    public let hasAlarms: Bool
    
    public init(from reminder: EKReminder) {
        self.calendarItemIdentifier = reminder.calendarItemIdentifier
        self.title = reminder.title ?? ""
        self.notes = reminder.notes
        self.priority = reminder.priority
        self.isCompleted = reminder.isCompleted
        self.completionDate = reminder.completionDate
        self.dueDateComponents = reminder.dueDateComponents
        self.list = reminder.calendar?.title
        self.url = reminder.url
        self.hasAlarms = !(reminder.alarms?.isEmpty ?? true)
    }
    
    public init(
        calendarItemIdentifier: String? = nil,
        title: String,
        notes: String? = nil,
        priority: Int = 0,
        isCompleted: Bool = false,
        completionDate: Date? = nil,
        dueDateComponents: DateComponents? = nil,
        list: String? = nil,
        url: URL? = nil,
        hasAlarms: Bool = false
    ) {
        self.calendarItemIdentifier = calendarItemIdentifier
        self.title = title
        self.notes = notes
        self.priority = priority
        self.isCompleted = isCompleted
        self.completionDate = completionDate
        self.dueDateComponents = dueDateComponents
        self.list = list
        self.url = url
        self.hasAlarms = hasAlarms
    }
}

/// Calendar information
public struct CalendarInfo: Sendable, Codable {
    public let calendarIdentifier: String
    public let title: String
    public let type: Int
    public let allowsContentModifications: Bool
    public let isSubscribed: Bool
    public let source: String?
    
    public init(from calendar: EKCalendar) {
        self.calendarIdentifier = calendar.calendarIdentifier
        self.title = calendar.title
        self.type = calendar.type.rawValue
        self.allowsContentModifications = calendar.allowsContentModifications
        self.isSubscribed = calendar.isSubscribed
        self.source = calendar.source?.title
    }
}

// MARK: - EventKit Resource

/// Resource management for EventKit
public actor EventKitResource: CapabilityResource {
    private var activeQueries: Set<UUID> = []
    private var _isAvailable: Bool = true
    private let configuration: EventKitConfiguration
    
    public init(configuration: EventKitConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 15_000_000, // 15MB max for calendar/reminder data
            cpu: 10.0, // 10% CPU max
            bandwidth: 1_000, // 1KB/s for calendar sync
            storage: 100_000_000 // 100MB for cached calendar data
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let queryCount = activeQueries.count
            let baseCPU = Double(queryCount * 3) // 3% CPU per active query
            let baseMemory = queryCount * 2_000_000 // 2MB per query
            
            return ResourceUsage(
                memory: baseMemory,
                cpu: baseCPU,
                bandwidth: queryCount * 200, // 200 bytes/s per query
                storage: queryCount * 10_000_000 // 10MB storage per query
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        return _isAvailable
    }
    
    public func release() async {
        activeQueries.removeAll()
    }
    
    public func addQuery(_ queryId: UUID) async throws {
        guard await isAvailable() else {
            throw CapabilityError.resourceAllocationFailed("EventKit resources not available")
        }
        activeQueries.insert(queryId)
    }
    
    public func removeQuery(_ queryId: UUID) async {
        activeQueries.remove(queryId)
    }
    
    public func setAvailable(_ available: Bool) async {
        _isAvailable = available
    }
}

// MARK: - EventKit Capability

/// EventKit capability providing calendar and reminder access
public actor EventKitCapability: DomainCapability {
    public typealias ConfigurationType = EventKitConfiguration
    public typealias ResourceType = EventKitResource
    
    private var _configuration: EventKitConfiguration
    private var _resources: EventKitResource
    private var _environment: CapabilityEnvironment
    private var _state: CapabilityState = .unknown
    private var _activationTimeout: Duration = .milliseconds(10)
    
    private var eventStore: EKEventStore?
    private var stateStreamContinuation: AsyncStream<CapabilityState>.Continuation?
    private var eventStreamContinuation: AsyncStream<EventData>.Continuation?
    private var reminderStreamContinuation: AsyncStream<ReminderData>.Continuation?
    
    public nonisolated var id: String { "eventkit-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: CapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStateStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: EventKitConfiguration {
        get async { _configuration }
    }
    
    public var resources: EventKitResource {
        get async { _resources }
    }
    
    public var environment: CapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: EventKitConfiguration = EventKitConfiguration(),
        environment: CapabilityEnvironment = CapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = EventKitResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStateStreamContinuation(_ continuation: AsyncStream<CapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    private func setEventStreamContinuation(_ continuation: AsyncStream<EventData>.Continuation) {
        self.eventStreamContinuation = continuation
    }
    
    private func setReminderStreamContinuation(_ continuation: AsyncStream<ReminderData>.Continuation) {
        self.reminderStreamContinuation = continuation
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: EventKitConfiguration) async throws {
        guard configuration.isValid else {
            throw CapabilityError.initializationFailed("Invalid EventKit configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
    }
    
    public func handleEnvironmentChange(_ environment: CapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    // MARK: - ExtendedCapability Protocol
    
    public func isSupported() async -> Bool {
        return true // EventKit is available on all iOS devices
    }
    
    public func requestPermission() async throws {
        guard let store = eventStore else {
            throw CapabilityError.notAvailable("EventKit store not initialized")
        }
        
        for entityType in _configuration.entityTypes {
            let status = EKEventStore.authorizationStatus(for: entityType)
            
            if status == .notDetermined {
                if #available(macOS 14.0, iOS 17.0, *) {
                    let granted = switch entityType {
                    case .event:
                        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                            store.requestFullAccessToEvents { granted, error in
                                if let error = error {
                                    continuation.resume(throwing: error)
                                } else {
                                    continuation.resume(returning: granted)
                                }
                            }
                        }
                    case .reminder:
                        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                            store.requestFullAccessToReminders { granted, error in
                                if let error = error {
                                    continuation.resume(throwing: error)
                                } else {
                                    continuation.resume(returning: granted)
                                }
                            }
                        }
                    @unknown default:
                        false
                    }
                    if !granted {
                        throw CapabilityError.permissionRequired("EventKit access denied for \(entityType)")
                    }
                } else {
                    let granted = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                        store.requestAccess(to: entityType) { granted, error in
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume(returning: granted)
                            }
                        }
                    }
                    if !granted {
                        throw CapabilityError.permissionRequired("EventKit access denied for \(entityType)")
                    }
                }
            } else if #available(macOS 14.0, iOS 17.0, *) {
                if status != .fullAccess && status != .writeOnly {
                    throw CapabilityError.permissionRequired("EventKit access not authorized for \(entityType)")
                }
            } else if status != .authorized {
                throw CapabilityError.permissionRequired("EventKit access not authorized for \(entityType)")
            }
        }
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Capability Protocol
    
    public func activate() async throws {
        guard await _resources.isAvailable() else {
            throw CapabilityError.initializationFailed("EventKit resources not available")
        }
        
        eventStore = EKEventStore()
        
        try await requestPermission()
        
        await transitionTo(.available)
    }
    
    public func deactivate() async {
        await transitionTo(.unavailable)
        await _resources.release()
        
        eventStore = nil
        stateStreamContinuation?.finish()
        eventStreamContinuation?.finish()
        reminderStreamContinuation?.finish()
    }
    
    private func transitionTo(_ newState: CapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
    
    // MARK: - Event Management API
    
    /// Get events in date range
    public func getEvents(
        from startDate: Date,
        to endDate: Date,
        calendars: [EKCalendar]? = nil
    ) async throws -> [EventData] {
        guard _state == .available else {
            throw CapabilityError.notAvailable("EventKit capability not available")
        }
        
        guard let store = eventStore else {
            throw CapabilityError.notAvailable("EventKit store not initialized")
        }
        
        let queryId = UUID()
        try await _resources.addQuery(queryId)
        defer {
            Task {
                await _resources.removeQuery(queryId)
            }
        }
        
        let predicate = store.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )
        
        let events = store.events(matching: predicate)
        return events.map { EventData(from: $0) }
    }
    
    /// Create new event
    public func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        calendar: EKCalendar? = nil,
        notes: String? = nil,
        location: String? = nil,
        isAllDay: Bool = false,
        url: URL? = nil
    ) async throws -> EventData {
        guard _state == .available else {
            throw CapabilityError.notAvailable("EventKit capability not available")
        }
        
        guard let store = eventStore else {
            throw CapabilityError.notAvailable("EventKit store not initialized")
        }
        
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.location = location
        event.isAllDay = isAllDay
        event.url = url
        
        // Use provided calendar or default calendar
        if let calendar = calendar {
            event.calendar = calendar
        } else if let defaultCalendar = getDefaultCalendar() {
            event.calendar = defaultCalendar
        } else {
            throw CapabilityError.initializationFailed("No calendar available for event creation")
        }
        
        try store.save(event, span: .thisEvent)
        
        let eventData = EventData(from: event)
        eventStreamContinuation?.yield(eventData)
        
        return eventData
    }
    
    /// Update existing event
    public func updateEvent(
        eventIdentifier: String,
        title: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        notes: String? = nil,
        location: String? = nil
    ) async throws -> EventData {
        guard _state == .available else {
            throw CapabilityError.notAvailable("EventKit capability not available")
        }
        
        guard let store = eventStore else {
            throw CapabilityError.notAvailable("EventKit store not initialized")
        }
        
        guard let event = store.event(withIdentifier: eventIdentifier) else {
            throw CapabilityError.notAvailable("Event not found: \(eventIdentifier)")
        }
        
        if let title = title { event.title = title }
        if let startDate = startDate { event.startDate = startDate }
        if let endDate = endDate { event.endDate = endDate }
        if let notes = notes { event.notes = notes }
        if let location = location { event.location = location }
        
        try store.save(event, span: .thisEvent)
        
        let eventData = EventData(from: event)
        eventStreamContinuation?.yield(eventData)
        
        return eventData
    }
    
    /// Delete event
    public func deleteEvent(eventIdentifier: String) async throws {
        guard _state == .available else {
            throw CapabilityError.notAvailable("EventKit capability not available")
        }
        
        guard let store = eventStore else {
            throw CapabilityError.notAvailable("EventKit store not initialized")
        }
        
        guard let event = store.event(withIdentifier: eventIdentifier) else {
            throw CapabilityError.notAvailable("Event not found: \(eventIdentifier)")
        }
        
        try store.remove(event, span: .thisEvent)
    }
    
    // MARK: - Reminder Management API
    
    /// Get reminders with predicate
    public func getReminders(predicate: NSPredicate? = nil) async throws -> [ReminderData] {
        guard _state == .available else {
            throw CapabilityError.notAvailable("EventKit capability not available")
        }
        
        guard let store = eventStore else {
            throw CapabilityError.notAvailable("EventKit store not initialized")
        }
        
        guard _configuration.entityTypes.contains(.reminder) else {
            throw CapabilityError.notAvailable("Reminder access not configured")
        }
        
        let queryId = UUID()
        try await _resources.addQuery(queryId)
        defer {
            Task {
                await _resources.removeQuery(queryId)
            }
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            store.fetchReminders(matching: predicate ?? NSPredicate(value: true)) { reminders in
                if let reminders = reminders {
                    let reminderData = reminders.map { ReminderData(from: $0) }
                    continuation.resume(returning: reminderData)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    /// Create new reminder
    public func createReminder(
        title: String,
        notes: String? = nil,
        priority: Int = 0,
        dueDateComponents: DateComponents? = nil,
        list: EKCalendar? = nil
    ) async throws -> ReminderData {
        guard _state == .available else {
            throw CapabilityError.notAvailable("EventKit capability not available")
        }
        
        guard let store = eventStore else {
            throw CapabilityError.notAvailable("EventKit store not initialized")
        }
        
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes
        reminder.priority = priority
        reminder.dueDateComponents = dueDateComponents
        
        // Use provided list or default list
        if let list = list {
            reminder.calendar = list
        } else if let defaultList = getDefaultReminderList() {
            reminder.calendar = defaultList
        } else {
            throw CapabilityError.initializationFailed("No reminder list available")
        }
        
        try store.save(reminder, commit: true)
        
        let reminderData = ReminderData(from: reminder)
        reminderStreamContinuation?.yield(reminderData)
        
        return reminderData
    }
    
    /// Complete reminder
    public func completeReminder(calendarItemIdentifier: String) async throws {
        guard _state == .available else {
            throw CapabilityError.notAvailable("EventKit capability not available")
        }
        
        guard let store = eventStore else {
            throw CapabilityError.notAvailable("EventKit store not initialized")
        }
        
        guard let reminder = store.calendarItem(withIdentifier: calendarItemIdentifier) as? EKReminder else {
            throw CapabilityError.notAvailable("Reminder not found: \(calendarItemIdentifier)")
        }
        
        reminder.isCompleted = true
        reminder.completionDate = Date()
        
        try store.save(reminder, commit: true)
        
        let reminderData = ReminderData(from: reminder)
        reminderStreamContinuation?.yield(reminderData)
    }
    
    // MARK: - Calendar Management API
    
    /// Get available calendars
    public func getCalendars(for entityType: EKEntityType) async throws -> [CalendarInfo] {
        guard _state == .available else {
            throw CapabilityError.notAvailable("EventKit capability not available")
        }
        
        guard let store = eventStore else {
            throw CapabilityError.notAvailable("EventKit store not initialized")
        }
        
        let calendars = store.calendars(for: entityType)
        return calendars.map { CalendarInfo(from: $0) }
    }
    
    /// Get default calendar
    public func getDefaultCalendar() -> EKCalendar? {
        return eventStore?.defaultCalendarForNewEvents
    }
    
    /// Get default reminder list
    public func getDefaultReminderList() -> EKCalendar? {
        return eventStore?.defaultCalendarForNewReminders()
    }
    
    /// Get authorization status for entity type
    public func getAuthorizationStatus(for entityType: EKEntityType) async -> EventKitAuthorizationStatus {
        let status = EKEventStore.authorizationStatus(for: entityType)
        return EventKitAuthorizationStatus(from: status)
    }
    
    /// Stream of event updates
    public var eventUpdatesStream: AsyncStream<EventData> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setEventStreamContinuation(continuation)
            }
        }
    }
    
    /// Stream of reminder updates
    public var reminderUpdatesStream: AsyncStream<ReminderData> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setReminderStreamContinuation(continuation)
            }
        }
    }
}

// MARK: - Registration Extension

extension CapabilityRegistry {
    /// Register EventKit capability
    public func registerEventKit() async throws {
        let capability = EventKitCapability()
        try await register(
            capability,
            requirements: [
                CapabilityDiscoveryService.Requirement(
                    type: .systemFeature("EventKit"),
                    isMandatory: true
                ),
                CapabilityDiscoveryService.Requirement(
                    type: .permission("NSCalendarsUsageDescription"),
                    isMandatory: false
                ),
                CapabilityDiscoveryService.Requirement(
                    type: .permission("NSRemindersUsageDescription"),
                    isMandatory: false
                )
            ],
            category: "productivity",
            metadata: CapabilityMetadata(
                name: "EventKit",
                description: "Calendar and reminder management capability",
                version: "1.0.0",
                documentation: "Provides access to calendar events and reminders",
                supportedPlatforms: ["iOS", "macOS"],
                minimumOSVersion: "14.0",
                tags: ["calendar", "events", "reminders", "productivity"],
                dependencies: ["EventKit"]
            )
        )
    }
}