import Foundation
import AxiomCore
import AxiomArchitecture
import TaskManager

@globalActor
public actor TaskClient: AxiomClient {
    public typealias StateType = TaskState
    public typealias ActionType = TaskAction
    
    private var _state: TaskState
    private let apiClient: TaskServiceClient
    private var streamContinuations: [UUID: AsyncStream<TaskState>.Continuation] = [:]
    
    public init(apiClient: TaskServiceClient, initialState: TaskState = TaskState()) {
        self._state = initialState
        self.apiClient = apiClient
    }
    
    public var stateStream: AsyncStream<TaskState> {
        AsyncStream { [weak self] continuation in
            let id = UUID()
            Task { [weak self] in
                await self?.addContinuation(continuation, id: id)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
                continuation.onTermination = { [weak self, id] _ in
                    Task { await self?.removeContinuation(id: id) }
                }
            }
        }
    }
    
    public func process(_ action: TaskAction) async throws {
        let oldState = _state
        
        let newState = try await processAction(action, currentState: _state)
        
        guard newState != oldState else { return }
        
        await stateWillUpdate(from: oldState, to: newState)
        _state = newState
        
        // Notify observers
        for (_, continuation) in streamContinuations {
            continuation.yield(newState)
        }
        
        await stateDidUpdate(from: oldState, to: newState)
    }
    
    private func processAction(_ action: TaskAction, currentState: TaskState) async throws -> TaskState {
        switch action {
        case .createNewTask(let request):
            let response = try await apiClient.createTask(request)
            return currentState.addingTask(response.task)
            
        case .fetchTask(let request):
            let task = try await apiClient.getTask(request)
            return currentState.replacingTask(task)
            
        case .modifyTask(let request):
            let updatedTask = try await apiClient.updateTask(request)
            return currentState.updatingTask(updatedTask)
            
        case .removeTask(let request):
            let response = try await apiClient.deleteTask(request)
            if response.success {
                return currentState.removingTask(withId: request.id)
            } else {
                return currentState.withError(TaskError.deletionFailed(response.message))
            }
            
        case .loadAllTasks(let request):
            let response = try await apiClient.listTasks(request)
            return currentState.withTasks(response.tasks)
                .withPageToken(response.nextPageToken)
                .withTotalCount(response.totalCount)
            
        case .searchTasks(let request):
            let response = try await apiClient.searchTasks(request)
            return currentState.withSearchResults(response.tasks)
                .withSearchSuggestions(response.suggestions)
        }
    }
    
    public func getCurrentState() async -> TaskState {
        return _state
    }
    
    public func rollbackToState(_ state: TaskState) async {
        _state = state
        for (_, continuation) in streamContinuations {
            continuation.yield(state)
        }
    }
    
    private func addContinuation(_ continuation: AsyncStream<TaskState>.Continuation, id: UUID) {
        streamContinuations[id] = continuation
    }
    
    private func removeContinuation(id: UUID) {
        streamContinuations.removeValue(forKey: id)
    }
}

// MARK: - Lifecycle Hooks
extension TaskClient {
    public func stateWillUpdate(from oldState: TaskState, to newState: TaskState) async {
        // Override in subclasses if needed
    }
    
    public func stateDidUpdate(from oldState: TaskState, to newState: TaskState) async {
        // Override in subclasses if needed
    }
}

// MARK: - Error Types
public enum TaskError: Error, LocalizedError {
    case deletionFailed(String)
    case validationError(String)
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .deletionFailed(let message):
            return "Task deletion failed: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}