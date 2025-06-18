import Foundation
import AxiomCore
import AxiomArchitecture

public actor PersonalInfoClient: AxiomClient {
    public typealias StateType = PersonalInfoState
    public typealias ActionType = PersonalInfoAction
    
    private var _state: PersonalInfoState
    private let storageCapability: LocalFileStorageCapability
    private var stateStreamContinuation: AsyncStream<PersonalInfoState>.Continuation?
    
    private var stateHistory: [PersonalInfoState] = []
    private var currentHistoryIndex: Int = -1
    private let maxHistorySize: Int = 50
    
    private var actionCount: Int = 0
    private var lastActionTime: Date?
    
    public init(
        storageCapability: LocalFileStorageCapability,
        initialState: PersonalInfoState = PersonalInfoState()
    ) {
        self._state = initialState
        self.storageCapability = storageCapability
        
        self.stateHistory = [initialState]
        self.currentHistoryIndex = 0
    }
    
    public var stateStream: AsyncStream<PersonalInfoState> {
        AsyncStream { continuation in
            self.stateStreamContinuation = continuation
            continuation.yield(self._state)
            
            continuation.onTermination = { _ in
                Task { [weak self] in
                    await self?.setStreamContinuation(nil)
                }
            }
        }
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<PersonalInfoState>.Continuation?) {
        self.stateStreamContinuation = continuation
    }
    
    public func process(_ action: PersonalInfoAction) async throws {
        actionCount += 1
        lastActionTime = Date()
        
        let oldState = _state
        let newState = try await processAction(action, currentState: _state)
        
        guard newState != oldState else { return }
        
        await stateWillUpdate(from: oldState, to: newState)
        
        _state = newState
        
        if !isUndoRedoAction(action) {
            saveStateToHistory(newState)
        }
        
        stateStreamContinuation?.yield(newState)
        await stateDidUpdate(from: oldState, to: newState)
        
        if shouldAutoSave(action) {
            try await autoSave()
        }
    }
    
    public func getCurrentState() async -> PersonalInfoState {
        return _state
    }
    
    public func rollbackToState(_ state: PersonalInfoState) async {
        let oldState = _state
        _state = state
        stateStreamContinuation?.yield(state)
        await stateDidUpdate(from: oldState, to: state)
    }
    
    private func processAction(_ action: PersonalInfoAction, currentState: PersonalInfoState) async throws -> PersonalInfoState {
        switch action {
        case .loadTasks:
            return try await loadTasks(in: currentState)
            
        case .createTask(let task):
            return createTask(task, in: currentState)
            
        case .updateTask(let task):
            return try await updateTask(task, in: currentState)
            
        case .deleteTask(let taskId):
            return try await deleteTask(taskId: taskId, in: currentState)
            
        case .toggleTaskComplete(let taskId):
            return try await toggleTaskComplete(taskId: taskId, in: currentState)
            
        case .loadCalendarEvents:
            return try await loadCalendarEvents(in: currentState)
            
        case .createCalendarEvent(let event):
            return createCalendarEvent(event, in: currentState)
            
        case .loadContacts:
            return try await loadContacts(in: currentState)
            
        case .createContact(let contact):
            return createContact(contact, in: currentState)
            
        case .updateContact(let contact):
            return try await updateContact(contact, in: currentState)
            
        case .linkTaskToContact(let taskId, let contactId):
            return try await linkTaskToContact(taskId: taskId, contactId: contactId, in: currentState)
            
        case .linkTaskToEvent(let taskId, let eventId):
            return try await linkTaskToEvent(taskId: taskId, eventId: eventId, in: currentState)
            
        case .setError(let error):
            return PersonalInfoState(
                tasks: currentState.tasks,
                calendarEvents: currentState.calendarEvents,
                contacts: currentState.contacts,
                reminders: currentState.reminders,
                isLoading: currentState.isLoading,
                error: error
            )
            
        case .setLoading(let isLoading):
            return PersonalInfoState(
                tasks: currentState.tasks,
                calendarEvents: currentState.calendarEvents,
                contacts: currentState.contacts,
                reminders: currentState.reminders,
                isLoading: isLoading,
                error: currentState.error
            )
        }
    }
    
    // MARK: - Task Operations
    
    private func loadTasks(in state: PersonalInfoState) async throws -> PersonalInfoState {
        do {
            let tasks = try await storageCapability.loadArray(StudioTask.self, from: "tasks/tasks.json")
            return PersonalInfoState(
                tasks: tasks,
                calendarEvents: state.calendarEvents,
                contacts: state.contacts,
                reminders: state.reminders,
                isLoading: false,
                error: nil
            )
        } catch {
            return PersonalInfoState(
                tasks: state.tasks,
                calendarEvents: state.calendarEvents,
                contacts: state.contacts,
                reminders: state.reminders,
                isLoading: false,
                error: .storageError(error.localizedDescription)
            )
        }
    }
    
    private func createTask(_ task: StudioTask, in state: PersonalInfoState) -> PersonalInfoState {
        var newTasks = state.tasks
        newTasks.append(task)
        
        return PersonalInfoState(
            tasks: newTasks,
            calendarEvents: state.calendarEvents,
            contacts: state.contacts,
            reminders: state.reminders,
            isLoading: state.isLoading,
            error: nil
        )
    }
    
    private func updateTask(_ task: StudioTask, in state: PersonalInfoState) async throws -> PersonalInfoState {
        guard let index = state.tasks.firstIndex(where: { $0.id == task.id }) else {
            throw PersonalInfoError.taskNotFound(task.id)
        }
        
        var newTasks = state.tasks
        newTasks[index] = task
        
        return PersonalInfoState(
            tasks: newTasks,
            calendarEvents: state.calendarEvents,
            contacts: state.contacts,
            reminders: state.reminders,
            isLoading: state.isLoading,
            error: nil
        )
    }
    
    private func deleteTask(taskId: UUID, in state: PersonalInfoState) async throws -> PersonalInfoState {
        guard state.tasks.contains(where: { $0.id == taskId }) else {
            throw PersonalInfoError.taskNotFound(taskId)
        }
        
        let newTasks = state.tasks.filter { $0.id != taskId }
        
        return PersonalInfoState(
            tasks: newTasks,
            calendarEvents: state.calendarEvents,
            contacts: state.contacts,
            reminders: state.reminders,
            isLoading: state.isLoading,
            error: nil
        )
    }
    
    private func toggleTaskComplete(taskId: UUID, in state: PersonalInfoState) async throws -> PersonalInfoState {
        guard let index = state.tasks.firstIndex(where: { $0.id == taskId }) else {
            throw PersonalInfoError.taskNotFound(taskId)
        }
        
        var newTasks = state.tasks
        let currentTask = newTasks[index]
        let newStatus: TaskStatus = currentTask.status == .completed ? .pending : .completed
        
        newTasks[index] = StudioTask(
            id: currentTask.id,
            title: currentTask.title,
            description: currentTask.description,
            priority: currentTask.priority,
            category: currentTask.category,
            status: newStatus,
            dueDate: currentTask.dueDate,
            createdAt: currentTask.createdAt,
            updatedAt: Date(),
            contactId: currentTask.contactId,
            calendarEventId: currentTask.calendarEventId,
            locationReminder: currentTask.locationReminder,
            tags: currentTask.tags
        )
        
        return PersonalInfoState(
            tasks: newTasks,
            calendarEvents: state.calendarEvents,
            contacts: state.contacts,
            reminders: state.reminders,
            isLoading: state.isLoading,
            error: nil
        )
    }
    
    // MARK: - Calendar Operations
    
    private func loadCalendarEvents(in state: PersonalInfoState) async throws -> PersonalInfoState {
        do {
            let events = try await storageCapability.loadArray(CalendarEvent.self, from: "calendar/events.json")
            return PersonalInfoState(
                tasks: state.tasks,
                calendarEvents: events,
                contacts: state.contacts,
                reminders: state.reminders,
                isLoading: false,
                error: nil
            )
        } catch {
            return PersonalInfoState(
                tasks: state.tasks,
                calendarEvents: state.calendarEvents,
                contacts: state.contacts,
                reminders: state.reminders,
                isLoading: false,
                error: .storageError(error.localizedDescription)
            )
        }
    }
    
    private func createCalendarEvent(_ event: CalendarEvent, in state: PersonalInfoState) -> PersonalInfoState {
        var newEvents = state.calendarEvents
        newEvents.append(event)
        
        return PersonalInfoState(
            tasks: state.tasks,
            calendarEvents: newEvents,
            contacts: state.contacts,
            reminders: state.reminders,
            isLoading: state.isLoading,
            error: nil
        )
    }
    
    // MARK: - Contact Operations
    
    private func loadContacts(in state: PersonalInfoState) async throws -> PersonalInfoState {
        do {
            let contacts = try await storageCapability.loadArray(Contact.self, from: "contacts/contacts.json")
            return PersonalInfoState(
                tasks: state.tasks,
                calendarEvents: state.calendarEvents,
                contacts: contacts,
                reminders: state.reminders,
                isLoading: false,
                error: nil
            )
        } catch {
            return PersonalInfoState(
                tasks: state.tasks,
                calendarEvents: state.calendarEvents,
                contacts: state.contacts,
                reminders: state.reminders,
                isLoading: false,
                error: .storageError(error.localizedDescription)
            )
        }
    }
    
    private func createContact(_ contact: Contact, in state: PersonalInfoState) -> PersonalInfoState {
        var newContacts = state.contacts
        newContacts.append(contact)
        
        return PersonalInfoState(
            tasks: state.tasks,
            calendarEvents: state.calendarEvents,
            contacts: newContacts,
            reminders: state.reminders,
            isLoading: state.isLoading,
            error: nil
        )
    }
    
    private func updateContact(_ contact: Contact, in state: PersonalInfoState) async throws -> PersonalInfoState {
        guard let index = state.contacts.firstIndex(where: { $0.id == contact.id }) else {
            throw PersonalInfoError.unknown("Contact not found")
        }
        
        var newContacts = state.contacts
        newContacts[index] = contact
        
        return PersonalInfoState(
            tasks: state.tasks,
            calendarEvents: state.calendarEvents,
            contacts: newContacts,
            reminders: state.reminders,
            isLoading: state.isLoading,
            error: nil
        )
    }
    
    // MARK: - Link Operations
    
    private func linkTaskToContact(taskId: UUID, contactId: UUID, in state: PersonalInfoState) async throws -> PersonalInfoState {
        guard let taskIndex = state.tasks.firstIndex(where: { $0.id == taskId }) else {
            throw PersonalInfoError.taskNotFound(taskId)
        }
        
        guard state.contacts.contains(where: { $0.id == contactId }) else {
            throw PersonalInfoError.unknown("Contact not found")
        }
        
        var newTasks = state.tasks
        let currentTask = newTasks[taskIndex]
        
        newTasks[taskIndex] = StudioTask(
            id: currentTask.id,
            title: currentTask.title,
            description: currentTask.description,
            priority: currentTask.priority,
            category: currentTask.category,
            status: currentTask.status,
            dueDate: currentTask.dueDate,
            createdAt: currentTask.createdAt,
            updatedAt: Date(),
            contactId: contactId,
            calendarEventId: currentTask.calendarEventId,
            locationReminder: currentTask.locationReminder,
            tags: currentTask.tags
        )
        
        return PersonalInfoState(
            tasks: newTasks,
            calendarEvents: state.calendarEvents,
            contacts: state.contacts,
            reminders: state.reminders,
            isLoading: state.isLoading,
            error: nil
        )
    }
    
    private func linkTaskToEvent(taskId: UUID, eventId: String, in state: PersonalInfoState) async throws -> PersonalInfoState {
        guard let taskIndex = state.tasks.firstIndex(where: { $0.id == taskId }) else {
            throw PersonalInfoError.taskNotFound(taskId)
        }
        
        guard state.calendarEvents.contains(where: { $0.id == eventId }) else {
            throw PersonalInfoError.unknown("Calendar event not found")
        }
        
        var newTasks = state.tasks
        let currentTask = newTasks[taskIndex]
        
        newTasks[taskIndex] = StudioTask(
            id: currentTask.id,
            title: currentTask.title,
            description: currentTask.description,
            priority: currentTask.priority,
            category: currentTask.category,
            status: currentTask.status,
            dueDate: currentTask.dueDate,
            createdAt: currentTask.createdAt,
            updatedAt: Date(),
            contactId: currentTask.contactId,
            calendarEventId: eventId,
            locationReminder: currentTask.locationReminder,
            tags: currentTask.tags
        )
        
        return PersonalInfoState(
            tasks: newTasks,
            calendarEvents: state.calendarEvents,
            contacts: state.contacts,
            reminders: state.reminders,
            isLoading: state.isLoading,
            error: nil
        )
    }
    
    // MARK: - Helper Methods
    
    private func isUndoRedoAction(_ action: PersonalInfoAction) -> Bool {
        return false
    }
    
    private func shouldAutoSave(_ action: PersonalInfoAction) -> Bool {
        switch action {
        case .createTask, .updateTask, .deleteTask, .toggleTaskComplete,
             .createCalendarEvent, .createContact, .updateContact,
             .linkTaskToContact, .linkTaskToEvent:
            return true
        default:
            return false
        }
    }
    
    private func autoSave() async throws {
        try await storageCapability.saveArray(_state.tasks, to: "tasks/tasks.json")
        try await storageCapability.saveArray(_state.calendarEvents, to: "calendar/events.json")
        try await storageCapability.saveArray(_state.contacts, to: "contacts/contacts.json")
        try await storageCapability.saveArray(_state.reminders, to: "reminders/reminders.json")
    }
    
    private func saveStateToHistory(_ state: PersonalInfoState) {
        if currentHistoryIndex < stateHistory.count - 1 {
            stateHistory.removeSubrange((currentHistoryIndex + 1)...)
        }
        
        stateHistory.append(state)
        currentHistoryIndex += 1
        
        if stateHistory.count > maxHistorySize {
            stateHistory.removeFirst()
            currentHistoryIndex -= 1
        }
    }
    
    // MARK: - Public Query Methods
    
    public func getTasksForContact(_ contactId: UUID) async -> [StudioTask] {
        return _state.tasks.filter { $0.contactId == contactId }
    }
    
    public func getTasksForEvent(_ eventId: String) async -> [StudioTask] {
        return _state.tasks.filter { $0.calendarEventId == eventId }
    }
    
    public func getUpcomingTasks(within timeInterval: TimeInterval) async -> [StudioTask] {
        let cutoffDate = Date().addingTimeInterval(timeInterval)
        return _state.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate <= cutoffDate && task.status != .completed
        }
    }
    
    public func getTasksByCategory(_ category: TaskCategory) async -> [StudioTask] {
        return _state.tasks.filter { $0.category == category }
    }
    
    public func getTasksByPriority(_ priority: TaskPriority) async -> [StudioTask] {
        return _state.tasks.filter { $0.priority == priority }
    }
    
    public func searchTasks(query: String) async -> [StudioTask] {
        let lowercaseQuery = query.lowercased()
        return _state.tasks.filter { task in
            task.title.lowercased().contains(lowercaseQuery) ||
            task.description?.lowercased().contains(lowercaseQuery) == true ||
            task.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
    
    public func getPerformanceMetrics() async -> PersonalInfoClientMetrics {
        return PersonalInfoClientMetrics(
            actionCount: actionCount,
            lastActionTime: lastActionTime,
            stateHistorySize: stateHistory.count,
            currentHistoryIndex: currentHistoryIndex,
            taskCount: _state.tasks.count,
            contactCount: _state.contacts.count,
            calendarEventCount: _state.calendarEvents.count
        )
    }
}

public struct PersonalInfoClientMetrics: Sendable, Equatable {
    public let actionCount: Int
    public let lastActionTime: Date?
    public let stateHistorySize: Int
    public let currentHistoryIndex: Int
    public let taskCount: Int
    public let contactCount: Int
    public let calendarEventCount: Int
    
    public init(
        actionCount: Int,
        lastActionTime: Date?,
        stateHistorySize: Int,
        currentHistoryIndex: Int,
        taskCount: Int,
        contactCount: Int,
        calendarEventCount: Int
    ) {
        self.actionCount = actionCount
        self.lastActionTime = lastActionTime
        self.stateHistorySize = stateHistorySize
        self.currentHistoryIndex = currentHistoryIndex
        self.taskCount = taskCount
        self.contactCount = contactCount
        self.calendarEventCount = calendarEventCount
    }
}