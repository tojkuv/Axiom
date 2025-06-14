import Foundation
import Axiom

// MARK: - Task Client

/// Actor-based client for managing task state and processing task actions
public actor TaskClient: Client {
    public typealias StateType = TaskManagerState
    public typealias ActionType = TaskAction
    
    // MARK: - Private Properties
    private var _state: TaskManagerState
    private let storage: any TaskStorageCapability
    private var stateStreamContinuation: AsyncStream<TaskManagerState>.Continuation?
    
    // Undo/Redo support
    private var stateHistory: [TaskManagerState] = []
    private var currentHistoryIndex: Int = -1
    private let maxHistorySize: Int = 50
    
    // Performance tracking
    private var actionCount: Int = 0
    private var lastActionTime: Date?
    
    // MARK: - Initialization
    
    public init(storage: any TaskStorageCapability, initialState: TaskManagerState = TaskManagerState()) {
        self._state = initialState
        self.storage = storage
        
        // Save initial state to history
        self.stateHistory = [initialState]
        self.currentHistoryIndex = 0
    }
    
    // MARK: - Client Protocol Implementation
    
    public var stateStream: AsyncStream<TaskManagerState> {
        AsyncStream { continuation in
            self.stateStreamContinuation = continuation
            
            // Emit current state immediately
            continuation.yield(self._state)
            
            // Handle stream termination
            continuation.onTermination = { _ in
                _Concurrency.Task { [weak self] in
                    await self?.setStreamContinuation(nil)
                }
            }
        }
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<TaskManagerState>.Continuation?) {
        self.stateStreamContinuation = continuation
    }
    
    public func process(_ action: ActionType) async throws {
        // Validate action
        guard action.isValid else {
            let errors = action.validationErrors
            throw AxiomError.clientError(.invalidAction("Action validation failed: \(errors.joined(separator: ", "))"))
        }
        
        // Track performance
        actionCount += 1
        lastActionTime = Date()
        
        // Get old state for lifecycle hooks
        let oldState = _state
        
        // Process the action
        let newState = try await processAction(action, currentState: _state)
        
        // Only update if state actually changed
        guard newState != oldState else { return }
        
        // Call lifecycle hooks
        await stateWillUpdate(from: oldState, to: newState)
        
        // Update state
        _state = newState
        
        // Save to history for undo/redo (except for undo/redo actions themselves)
        if !isUndoRedoAction(action) {
            saveStateToHistory(newState)
        }
        
        // Notify observers
        stateStreamContinuation?.yield(newState)
        
        // Call lifecycle hooks
        await stateDidUpdate(from: oldState, to: newState)
        
        // Auto-save if needed
        if shouldAutoSave(action) {
            try await autoSave()
        }
    }
    
    public func getCurrentState() async -> TaskManagerState {
        return _state
    }
    
    public func rollbackToState(_ state: TaskManagerState) async {
        let oldState = _state
        _state = state
        stateStreamContinuation?.yield(state)
        
        // Don't save rollback to history
        await stateDidUpdate(from: oldState, to: state)
    }
    
    // MARK: - Action Processing
    
    private func processAction(_ action: TaskAction, currentState: TaskManagerState) async throws -> TaskManagerState {
        switch action {
        // MARK: - Task CRUD Operations
        case .createTask(let data):
            return try await createTask(data, in: currentState)
            
        case .updateTask(let taskId, let updates):
            return try await updateTask(taskId: taskId, updates: updates, in: currentState)
            
        case .deleteTask(let taskId):
            return try await deleteTask(taskId: taskId, in: currentState)
            
        case .toggleTaskCompletion(let taskId):
            return try await toggleTaskCompletion(taskId: taskId, in: currentState)
            
        case .duplicateTask(let taskId):
            return try await duplicateTask(taskId: taskId, in: currentState)
            
        // MARK: - Bulk Operations
        case .createMultipleTasks(let taskDataArray):
            return try await createMultipleTasks(taskDataArray, in: currentState)
            
        case .deleteTasks(let taskIds):
            return try await deleteTasks(taskIds: taskIds, in: currentState)
            
        case .completeAllTasks:
            return try await completeAllTasks(in: currentState)
            
        case .deleteCompletedTasks:
            return try await deleteCompletedTasks(in: currentState)
            
        case .markTasksAsCompleted(let taskIds):
            return try await markTasksAsCompleted(taskIds: taskIds, in: currentState)
            
        case .updateTasksCategory(let taskIds, let category):
            return try await updateTasksCategory(taskIds: taskIds, category: category, in: currentState)
            
        case .updateTasksPriority(let taskIds, let priority):
            return try await updateTasksPriority(taskIds: taskIds, priority: priority, in: currentState)
            
        // MARK: - Filtering and Sorting
        case .setFilter(let filter):
            return currentState.withFilter(filter)
            
        case .setCategoryFilter(let category):
            return currentState.withCategoryFilter(category)
            
        case .setSortOrder(let sortOrder, let ascending):
            return currentState.withSortOrder(sortOrder, ascending: ascending)
            
        case .setSearchQuery(let query):
            return currentState.withSearchQuery(query)
            
        case .clearFilters:
            return try await clearFilters(in: currentState)
            
        case .toggleSortDirection:
            return currentState.withToggledSortDirection()
            
        // MARK: - Data Management
        case .loadTasks:
            return try await loadTasks(in: currentState)
            
        case .saveTasks:
            try await saveTasks(currentState)
            return currentState
            
        case .importTasks(let tasks):
            return try await importTasks(tasks, in: currentState)
            
        case .exportTasks:
            try await exportTasks(currentState)
            return currentState
            
        case .syncTasks:
            return try await syncTasks(in: currentState)
            
        case .clearAllTasks:
            return try await clearAllTasks(in: currentState)
            
        // MARK: - Undo/Redo Support
        case .undo:
            return try await undoState()
            
        case .redo:
            return try await redoState()
            
        case .saveStateSnapshot:
            saveStateToHistory(currentState)
            return currentState
        }
    }
    
    // MARK: - Task CRUD Implementation
    
    private func createTask(_ data: CreateTaskData, in state: TaskManagerState) async throws -> TaskManagerState {
        let newTask = data.toTask()
        
        // Validate the new task
        guard newTask.isValid else {
            throw AxiomError.validationError(.invalidInput("task", "Invalid task data"))
        }
        
        return state.addingTask(newTask)
    }
    
    private func updateTask(taskId: UUID, updates: TaskUpdate, in state: TaskManagerState) async throws -> TaskManagerState {
        guard let existingTask = state.task(withId: taskId) else {
            throw AxiomError.clientError(.invalidAction("Task with ID \(taskId) not found"))
        }
        
        let updatedTask = updates.apply(to: existingTask)
        
        // Validate the updated task
        guard updatedTask.isValid else {
            throw AxiomError.validationError(.invalidInput("task", "Invalid updated task data"))
        }
        
        return state.updatingTask(updatedTask)
    }
    
    private func deleteTask(taskId: UUID, in state: TaskManagerState) async throws -> TaskManagerState {
        guard state.task(withId: taskId) != nil else {
            throw AxiomError.clientError(.invalidAction("Task with ID \(taskId) not found"))
        }
        
        return state.removingTask(withId: taskId)
    }
    
    private func toggleTaskCompletion(taskId: UUID, in state: TaskManagerState) async throws -> TaskManagerState {
        guard let existingTask = state.task(withId: taskId) else {
            throw AxiomError.clientError(.invalidAction("Task with ID \(taskId) not found"))
        }
        
        let updatedTask = existingTask.withCompletion(!existingTask.isCompleted)
        return state.updatingTask(updatedTask)
    }
    
    private func duplicateTask(taskId: UUID, in state: TaskManagerState) async throws -> TaskManagerState {
        guard let existingTask = state.task(withId: taskId) else {
            throw AxiomError.clientError(.invalidAction("Task with ID \(taskId) not found"))
        }
        
        let duplicatedTask = Task(
            title: "\(existingTask.title) (Copy)",
            taskDescription: existingTask.taskDescription,
            priority: existingTask.priority,
            category: existingTask.category,
            isCompleted: false,
            dueDate: existingTask.dueDate,
            tags: existingTask.tags
        )
        
        return state.addingTask(duplicatedTask)
    }
    
    // MARK: - Bulk Operations Implementation
    
    private func createMultipleTasks(_ taskDataArray: [CreateTaskData], in state: TaskManagerState) async throws -> TaskManagerState {
        var newState = state
        
        for data in taskDataArray {
            let task = data.toTask()
            guard task.isValid else {
                throw AxiomError.validationError(.invalidInput("task", "Invalid task data in batch"))
            }
            newState = newState.addingTask(task)
        }
        
        return newState
    }
    
    private func deleteTasks(taskIds: [UUID], in state: TaskManagerState) async throws -> TaskManagerState {
        var newState = state
        
        for taskId in taskIds {
            guard state.task(withId: taskId) != nil else {
                throw AxiomError.clientError(.invalidAction("Task with ID \(taskId) not found"))
            }
            newState = newState.removingTask(withId: taskId)
        }
        
        return newState
    }
    
    private func completeAllTasks(in state: TaskManagerState) async throws -> TaskManagerState {
        let completedTasks = state.tasks.map { $0.withCompletion(true) }
        return state.withTasks(completedTasks)
    }
    
    private func deleteCompletedTasks(in state: TaskManagerState) async throws -> TaskManagerState {
        let pendingTasks = state.tasks.filter { !$0.isCompleted }
        return state.withTasks(pendingTasks)
    }
    
    private func markTasksAsCompleted(taskIds: [UUID], in state: TaskManagerState) async throws -> TaskManagerState {
        var newState = state
        
        for taskId in taskIds {
            guard let task = state.task(withId: taskId) else {
                throw AxiomError.clientError(.invalidAction("Task with ID \(taskId) not found"))
            }
            let completedTask = task.withCompletion(true)
            newState = newState.updatingTask(completedTask)
        }
        
        return newState
    }
    
    private func updateTasksCategory(taskIds: [UUID], category: Category, in state: TaskManagerState) async throws -> TaskManagerState {
        var newState = state
        
        for taskId in taskIds {
            guard let task = state.task(withId: taskId) else {
                throw AxiomError.clientError(.invalidAction("Task with ID \(taskId) not found"))
            }
            let updatedTask = task.withCategory(category)
            newState = newState.updatingTask(updatedTask)
        }
        
        return newState
    }
    
    private func updateTasksPriority(taskIds: [UUID], priority: Priority, in state: TaskManagerState) async throws -> TaskManagerState {
        var newState = state
        
        for taskId in taskIds {
            guard let task = state.task(withId: taskId) else {
                throw AxiomError.clientError(.invalidAction("Task with ID \(taskId) not found"))
            }
            let updatedTask = task.withPriority(priority)
            newState = newState.updatingTask(updatedTask)
        }
        
        return newState
    }
    
    // MARK: - Filter Operations Implementation
    
    private func clearFilters(in state: TaskManagerState) async throws -> TaskManagerState {
        return TaskManagerState(
            tasks: state.tasks,
            selectedFilter: .all,
            selectedCategory: nil,
            sortOrder: .createdDate,
            searchQuery: "",
            isAscending: false,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Data Management Implementation
    
    private func loadTasks(in state: TaskManagerState) async throws -> TaskManagerState {
        let loadedTasks = try await storage.loadTasks()
        return state.withTasks(loadedTasks)
    }
    
    private func saveTasks(_ state: TaskManagerState) async throws {
        try await storage.saveTasks(state.tasks)
    }
    
    private func importTasks(_ tasks: [Task], in state: TaskManagerState) async throws -> TaskManagerState {
        // Validate all tasks before importing
        for task in tasks {
            guard task.isValid else {
                throw AxiomError.validationError(.invalidInput("task", "Invalid task in import data"))
            }
        }
        
        // Merge with existing tasks, avoiding duplicates
        var mergedTasks = state.tasks
        let existingIds = Set(state.tasks.map { $0.id })
        
        for task in tasks {
            if !existingIds.contains(task.id) {
                mergedTasks.append(task)
            }
        }
        
        return state.withTasks(mergedTasks)
    }
    
    private func exportTasks(_ state: TaskManagerState) async throws {
        try await storage.exportTasks(state.tasks)
    }
    
    private func syncTasks(in state: TaskManagerState) async throws -> TaskManagerState {
        // In a real app, this would sync with a remote service
        return state
    }
    
    private func clearAllTasks(in state: TaskManagerState) async throws -> TaskManagerState {
        return state.withTasks([])
    }
    
    // MARK: - Undo/Redo Implementation
    
    private func undoState() async throws -> TaskManagerState {
        guard currentHistoryIndex > 0 else {
            throw AxiomError.clientError(.invalidAction("Nothing to undo"))
        }
        
        currentHistoryIndex -= 1
        return stateHistory[currentHistoryIndex]
    }
    
    private func redoState() async throws -> TaskManagerState {
        guard currentHistoryIndex < stateHistory.count - 1 else {
            throw AxiomError.clientError(.invalidAction("Nothing to redo"))
        }
        
        currentHistoryIndex += 1
        return stateHistory[currentHistoryIndex]
    }
    
    private func saveStateToHistory(_ state: TaskManagerState) {
        // Remove any future states if we're not at the end
        if currentHistoryIndex < stateHistory.count - 1 {
            stateHistory.removeSubrange((currentHistoryIndex + 1)...)
        }
        
        // Add new state
        stateHistory.append(state)
        currentHistoryIndex += 1
        
        // Maintain max history size
        if stateHistory.count > maxHistorySize {
            stateHistory.removeFirst()
            currentHistoryIndex -= 1
        }
    }
    
    // MARK: - Helper Methods
    
    private func isUndoRedoAction(_ action: TaskAction) -> Bool {
        switch action {
        case .undo, .redo:
            return true
        default:
            return false
        }
    }
    
    private func shouldAutoSave(_ action: TaskAction) -> Bool {
        switch action {
        case .createTask, .updateTask, .deleteTask, .toggleTaskCompletion,
             .createMultipleTasks, .deleteTasks, .completeAllTasks,
             .deleteCompletedTasks, .markTasksAsCompleted,
             .updateTasksCategory, .updateTasksPriority,
             .importTasks, .clearAllTasks:
            return true
        default:
            return false
        }
    }
    
    private func autoSave() async throws {
        try await saveTasks(_state)
    }
    
    // MARK: - Public Query Methods
    
    /// Get current statistics
    public func getStatistics() async -> TaskStatistics {
        return _state.statistics
    }
    
    /// Check if undo is available
    public func canUndo() async -> Bool {
        return currentHistoryIndex > 0
    }
    
    /// Check if redo is available
    public func canRedo() async -> Bool {
        return currentHistoryIndex < stateHistory.count - 1
    }
    
    /// Get performance metrics
    public func getPerformanceMetrics() async -> TaskClientMetrics {
        TaskClientMetrics(
            actionCount: actionCount,
            lastActionTime: lastActionTime,
            stateHistorySize: stateHistory.count,
            currentHistoryIndex: currentHistoryIndex
        )
    }
}

// MARK: - Performance Metrics

/// Performance metrics for the TaskClient
public struct TaskClientMetrics: Sendable, Equatable {
    public let actionCount: Int
    public let lastActionTime: Date?
    public let stateHistorySize: Int
    public let currentHistoryIndex: Int
    
    public init(actionCount: Int, lastActionTime: Date?, stateHistorySize: Int, currentHistoryIndex: Int) {
        self.actionCount = actionCount
        self.lastActionTime = lastActionTime
        self.stateHistorySize = stateHistorySize
        self.currentHistoryIndex = currentHistoryIndex
    }
}