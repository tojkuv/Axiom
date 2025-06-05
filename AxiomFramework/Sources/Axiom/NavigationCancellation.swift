import Foundation

// MARK: - REFACTOR: Complete Navigation Cancellation Implementation

/// Navigation state for cancellable navigation
public struct CancellableNavigationState<RouteType: Equatable & Sendable>: Sendable {
    public var currentRoute: RouteType?
    public var pendingRoute: RouteType?
    
    public init(currentRoute: RouteType? = nil, pendingRoute: RouteType? = nil) {
        self.currentRoute = currentRoute
        self.pendingRoute = pendingRoute
    }
}

/// Cancellable navigation service with full cancellation support
public actor CancellableNavigationService<RouteType: Equatable & Sendable> {
    private var _currentState = CancellableNavigationState<RouteType>()
    private var activeNavigationTask: Task<Void, Error>?
    
    public init() {}
    
    public var currentState: CancellableNavigationState<RouteType> {
        _currentState
    }
    
    /// Navigate to a route with automatic cancellation of previous navigation
    public func navigate(to route: RouteType) async throws {
        // Cancel any active navigation
        activeNavigationTask?.cancel()
        await Task.yield() // Allow cancellation to propagate
        
        // Create new navigation task
        let navigationTask = Task { [weak self] in
            guard let self = self else { return }
            
            // Check cancellation at start
            try Task.checkCancellation()
            
            // Update state atomically
            await self.updateState { state in
                state.currentRoute = route
                state.pendingRoute = nil
            }
        }
        
        activeNavigationTask = navigationTask
        
        do {
            try await navigationTask.value
        } catch is CancellationError {
            // Don't propagate cancellation as error for simple navigation
            return
        } catch {
            throw error
        }
    }
    
    /// Navigate with configurable delay and completion callback
    public func navigateWithDelay(
        to route: RouteType,
        delay: TimeInterval,
        onCompletion: ((RouteType) -> Void)? = nil
    ) async throws {
        // Cancel any active navigation
        activeNavigationTask?.cancel()
        await Task.yield() // Allow cancellation to propagate
        
        let navigationTask = Task { [weak self] in
            guard let self = self else { return }
            
            // Set pending route
            await self.updateState { state in
                state.pendingRoute = route
            }
            
            // Check cancellation before delay
            try Task.checkCancellation()
            
            // Simulate navigation delay
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Check cancellation after delay
            try Task.checkCancellation()
            
            // Update state only if not cancelled
            await self.updateState { state in
                state.currentRoute = route
                state.pendingRoute = nil
            }
            
            // Call completion handler only if not cancelled
            if !Task.isCancelled {
                onCompletion?(route)
            }
        }
        
        activeNavigationTask = navigationTask
        
        do {
            try await navigationTask.value
        } catch is CancellationError {
            // Clear pending route on cancellation
            await updateState { state in
                state.pendingRoute = nil
            }
            throw NavigationCancellationError.navigationCancelled
        } catch {
            // Clear pending route on any error
            await updateState { state in
                state.pendingRoute = nil
            }
            throw error
        }
    }
    
    /// Navigate with child tasks that are automatically cancelled
    public func navigateWithChildTasks(
        to route: RouteType,
        childTasksBuilder: @escaping ((@escaping () async throws -> Void) -> Void) -> Void
    ) async throws {
        // Cancel any active navigation
        activeNavigationTask?.cancel()
        await Task.yield() // Allow cancellation to propagate
        
        let navigationTask = Task { [weak self] in
            guard let self = self else { return }
            
            try Task.checkCancellation()
            
            // Track child tasks and cancellation handle
            var childTasks: [Task<Void, Error>] = []
            let taskGroup = TaskGroup()
            
            let createChildTask: (@escaping () async throws -> Void) -> Void = { work in
                let task = Task {
                    // Register with task group
                    await taskGroup.addTask()
                    defer { Task { await taskGroup.removeTask() } }
                    
                    try Task.checkCancellation()
                    try await work()
                }
                childTasks.append(task)
            }
            
            // Build child tasks
            childTasksBuilder(createChildTask)
            
            // Wait for all child tasks with cancellation support
            do {
                for task in childTasks {
                    try await task.value
                }
                
                // Update navigation state only if all tasks complete
                try Task.checkCancellation()
                await self.updateState { state in
                    state.currentRoute = route
                }
            } catch {
                // Cancel all remaining tasks on error
                for task in childTasks {
                    task.cancel()
                }
                // Wait for cancellation to complete
                await taskGroup.waitForAll()
                throw error
            }
        }
        
        activeNavigationTask = navigationTask
        try await navigationTask.value
    }
    
    private func updateState(_ update: (inout CancellableNavigationState<RouteType>) -> Void) {
        update(&_currentState)
    }
}

/// Task group for managing child task cancellation
private actor TaskGroup {
    private var activeTasks = 0
    
    func addTask() {
        activeTasks += 1
    }
    
    func removeTask() {
        activeTasks = max(0, activeTasks - 1)
    }
    
    func waitForAll() async {
        while activeTasks > 0 {
            await Task.yield()
        }
    }
}

/// Navigation-specific cancellation error
public enum NavigationCancellationError: Error {
    case navigationCancelled
    case operationCancelled(String)
}

/// Test navigation coordinator with operation support
public actor TestNavigationCoordinator<RouteType: Equatable & Sendable> {
    private var _currentState = CancellableNavigationState<RouteType>()
    private var operations: [String: (CheckCancellation) async throws -> Void] = [:]
    private var activeNavigationTask: Task<Void, Error>?
    
    public typealias CheckCancellation = () async -> Bool
    
    public init() {}
    
    public var currentState: CancellableNavigationState<RouteType> {
        _currentState
    }
    
    /// Configure navigation operations
    public func configureOperations(_ ops: [String: (CheckCancellation) async throws -> Void]) {
        operations = ops
    }
    
    /// Navigate with all configured operations
    public func navigateWithOperations(to route: RouteType) async throws {
        // Cancel previous navigation
        activeNavigationTask?.cancel()
        await Task.yield() // Allow cancellation to propagate
        
        let navigationTask = Task { [weak self] in
            guard let self = self else { return }
            
            // Create cancellation check
            let isCancelled: CheckCancellation = {
                Task.isCancelled
            }
            
            // Run all operations concurrently with cancellation support
            try await withThrowingTaskGroup(of: Void.self) { group in
                for (name, operation) in await self.operations {
                    group.addTask {
                        do {
                            try await operation(isCancelled)
                        } catch is CancellationError {
                            throw NavigationCancellationError.operationCancelled(name)
                        }
                    }
                }
                
                // Wait for all operations with cancellation check
                try await group.waitForAll()
            }
            
            // Update state only if not cancelled
            try Task.checkCancellation()
            await self.updateState { state in
                state.currentRoute = route
            }
        }
        
        activeNavigationTask = navigationTask
        try await navigationTask.value
    }
    
    private func updateState(_ update: (inout CancellableNavigationState<RouteType>) -> Void) {
        update(&_currentState)
    }
}

/// Transactional navigation service
public actor TransactionalNavigationService<RouteType: Equatable & Sendable> {
    private var _currentState = CancellableNavigationState<RouteType>()
    private var activeTransaction: NavigationTransaction<RouteType>?
    
    public init() {}
    
    public var currentState: CancellableNavigationState<RouteType> {
        _currentState
    }
    
    /// Navigate to a route
    public func navigate(to route: RouteType) async throws {
        _currentState.currentRoute = route
    }
    
    /// Begin a navigation transaction
    public func beginTransaction() -> NavigationTransaction<RouteType> {
        let transaction = NavigationTransaction(
            initialState: _currentState,
            service: self
        )
        activeTransaction = transaction
        return transaction
    }
    
    /// Apply transaction changes
    func applyTransaction(_ state: CancellableNavigationState<RouteType>) {
        _currentState = state
    }
    
    /// Rollback to initial state
    func rollbackTransaction(_ initialState: CancellableNavigationState<RouteType>) {
        _currentState = initialState
        activeTransaction = nil
    }
}

/// Actor for managing transaction state safely
public actor TransactionStateManager {
    public enum State {
        case active
        case committed
        case rolledBack
    }
    
    private var state = State.active
    
    public func getState() -> State {
        state
    }
    
    public func setState(_ newState: State) {
        state = newState
    }
    
    public func checkActive() throws {
        guard state == .active else {
            throw NavigationCancellationError.navigationCancelled
        }
    }
}

/// Navigation transaction for atomic operations with cancellation support
public class NavigationTransaction<RouteType: Equatable & Sendable>: @unchecked Sendable {
    private let initialState: CancellableNavigationState<RouteType>
    private var transactionState: CancellableNavigationState<RouteType>
    private let service: TransactionalNavigationService<RouteType>
    private let stateManager = TransactionStateManager()
    private let cancellationHandle = CancellationHandle()
    
    public var state: TransactionStateManager.State {
        get async {
            await stateManager.getState()
        }
    }
    
    init(initialState: CancellableNavigationState<RouteType>, service: TransactionalNavigationService<RouteType>) {
        self.initialState = initialState
        self.transactionState = initialState
        self.service = service
        
        // Monitor task cancellation
        Task { [weak self] in
            while await self?.stateManager.getState() == .active {
                if Task.isCancelled {
                    await self?.handleCancellation()
                    break
                }
                await Task.yield()
            }
        }
    }
    
    /// Navigate within transaction
    public func navigate(to route: RouteType) async throws {
        try await stateManager.checkActive()
        
        // Check if cancelled
        if await cancellationHandle.isCancelled() || Task.isCancelled {
            await rollback()
            throw CancellationError()
        }
        
        transactionState.currentRoute = route
    }
    
    /// Commit transaction changes
    public func commit() async throws {
        try await stateManager.checkActive()
        
        // Check if cancelled before commit
        if await cancellationHandle.isCancelled() || Task.isCancelled {
            await rollback()
            throw CancellationError()
        }
        
        await service.applyTransaction(transactionState)
        await stateManager.setState(.committed)
    }
    
    /// Rollback transaction
    public func rollback() async {
        let currentState = await stateManager.getState()
        guard currentState == .active else {
            return
        }
        await stateManager.setState(.rolledBack)
        await service.rollbackTransaction(initialState)
    }
    
    private func handleCancellation() async {
        await cancellationHandle.markCancelled()
        await rollback()
    }
}

/// Cancellation handle for transaction
private actor CancellationHandle {
    private var cancelled = false
    
    func markCancelled() {
        cancelled = true
    }
    
    func isCancelled() -> Bool {
        cancelled
    }
}

// MARK: - Orchestrator Navigation Extension

public extension Orchestrator {
    /// Navigate with cancellation support
    func navigateWithCancellation(to route: Route) async throws {
        // Create cancellable task
        let navigationTask = Task {
            try Task.checkCancellation()
            await self.navigate(to: route)
        }
        
        // Handle cancellation
        do {
            try await navigationTask.value
        } catch is CancellationError {
            // Navigation was cancelled
            throw NavigationCancellationError.navigationCancelled
        }
    }
}