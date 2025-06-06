import Foundation

// GREEN Phase: TaskOrchestrator to coordinate End-to-End flows

/// Orchestrates interactions between multiple clients, ensuring proper isolation and coordination
actor TaskOrchestrator: Orchestrator {
    
    // MARK: - Properties
    
    private let taskClient: TaskClient
    private let userClient: UserClient
    private let syncClient: SyncClient
    
    // Capability references
    private var networkCapability: NetworkCapability?
    private var storageCapability: StorageCapability?
    private var notificationCapability: NotificationCapability?
    
    // Navigation controllers
    private var tabNavigationController: TabNavigationController?
    private var deepNavigationController: DeepNavigationController?
    private var deepLinkNavigationController: DeepLinkNavigationController?
    
    // State management
    private var isInitialized = false
    private var activeUserId: String?
    
    // MARK: - Initialization
    
    init() {
        self.taskClient = TaskClient()
        self.userClient = UserClient()
        self.syncClient = SyncClient()
    }
    
    func initialize() async throws {
        guard !isInitialized else { return }
        
        // Initialize capabilities
        networkCapability = TestNetworkCapability()
        storageCapability = TestStorageCapability()
        notificationCapability = TestNotificationCapability()
        
        try await networkCapability?.initialize()
        try await storageCapability?.initialize()
        try await notificationCapability?.initialize()
        
        // Set capabilities on clients
        await taskClient.setStorageCapability(storageCapability!)
        await taskClient.setNotificationCapability(notificationCapability!)
        await syncClient.setNetworkCapability(networkCapability!)
        await syncClient.setStorageCapability(storageCapability!)
        
        // Initialize navigation controllers
        tabNavigationController = TabNavigationController()
        deepNavigationController = DeepNavigationController()
        deepLinkNavigationController = DeepLinkNavigationController()
        
        isInitialized = true
    }
    
    // MARK: - Orchestrator Protocol
    
    func handleAction<A>(_ action: A) async throws {
        guard isInitialized else {
            throw OrchestratorError.notInitialized
        }
        
        // Route actions to appropriate clients based on type
        switch action {
        case let taskAction as TaskAction:
            try await taskClient.process(taskAction)
            // Trigger sync after task changes
            if shouldSyncAfterAction(taskAction) {
                try? await syncClient.process(.startSync)
            }
            
        case let userAction as UserAction:
            try await userClient.process(userAction)
            // Handle user state changes
            if case .login(let email, _) = userAction {
                activeUserId = email
                // Initialize user-specific data
                await loadUserData()
            } else if case .logout = userAction {
                activeUserId = nil
                // Clear user data
                await clearUserData()
            }
            
        case let syncAction as SyncAction:
            try await syncClient.process(syncAction)
            
        default:
            throw OrchestratorError.unsupportedAction
        }
    }
    
    func navigate(to route: Any) async throws {
        guard isInitialized else {
            throw OrchestratorError.notInitialized
        }
        
        if let appRoute = route as? AppRoute {
            // Handle deep navigation
            switch appRoute {
            case .taskList:
                _ = try? await tabNavigationController?.switchToTab(.tasks)
            case .taskDetail(let taskId):
                _ = await deepNavigationController?.navigateTo(.taskDetail(taskId: taskId))
            case .taskEdit(let taskId):
                if let taskId = taskId {
                    _ = await tabNavigationController?.presentModal(.taskEdit(taskId: taskId))
                } else {
                    _ = await tabNavigationController?.presentModal(.taskCreation(taskId: nil))
                }
            case .categoryList:
                _ = try? await tabNavigationController?.switchToTab(.categories)
            case .settings:
                _ = try? await tabNavigationController?.switchToTab(.settings)
            case .profile:
                _ = try? await tabNavigationController?.switchToTab(.profile)
            default:
                break
            }
        } else if let url = route as? URL {
            // Handle deep linking
            _ = await deepLinkNavigationController?.handleDeepLink(url)
        }
    }
    
    // MARK: - End-to-End Flow Support
    
    /// Completes a full task creation journey
    func completeTaskCreationJourney(task: Task) async throws {
        // 1. Ensure user is logged in
        guard activeUserId != nil else {
            throw OrchestratorError.notAuthenticated
        }
        
        // 2. Navigate to tasks tab
        try await navigate(to: AppRoute.taskList)
        
        // 3. Open task creation modal
        try await navigate(to: AppRoute.taskEdit(taskId: nil))
        
        // 4. Create the task
        try await handleAction(TaskAction.create(task))
        
        // 5. Close modal
        _ = await tabNavigationController?.dismissModal()
        
        // 6. Ensure task appears in list (state propagation)
        let state = await taskClient.currentState
        guard state.tasks.contains(where: { $0.id == task.id }) else {
            throw OrchestratorError.taskNotFound
        }
    }
    
    /// Completes a full task editing journey
    func completeTaskEditingJourney(taskId: String, updates: (Task) -> Task) async throws {
        // 1. Navigate to task detail
        try await navigate(to: AppRoute.taskDetail(taskId: taskId))
        
        // 2. Navigate to edit screen
        try await navigate(to: AppRoute.taskEdit(taskId: taskId))
        
        // 3. Apply updates
        let currentState = await taskClient.currentState
        guard let originalTask = currentState.tasks.first(where: { $0.id == taskId }) else {
            throw OrchestratorError.taskNotFound
        }
        let updatedTask = updates(originalTask)
        try await handleAction(TaskAction.update(updatedTask))
        
        // 4. Navigate back
        _ = await deepNavigationController?.navigateBack()
        
        // 5. Verify changes persisted
        let finalState = await taskClient.currentState
        guard let finalTask = finalState.tasks.first(where: { $0.id == taskId }),
              finalTask.updatedAt > originalTask.updatedAt else {
            throw OrchestratorError.updateFailed
        }
    }
    
    /// Completes a sharing journey between users
    func completeSharingJourney(taskId: String, shareWithUserId: String) async throws {
        // 1. Share the task
        try await handleAction(TaskAction.shareTask(
            taskId: taskId,
            userId: shareWithUserId,
            permission: .write
        ))
        
        // 2. Trigger sync to propagate share
        try await handleAction(SyncAction.startSync)
        
        // 3. Wait for sync completion
        var syncCompleted = false
        for _ in 0..<50 {
            let syncState = await syncClient.currentState
            if !syncState.isSyncing && syncState.pendingChanges == 0 {
                syncCompleted = true
                break
            }
            try await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        guard syncCompleted else {
            throw OrchestratorError.syncTimeout
        }
    }
    
    /// Completes offline-to-online sync journey
    func completeOfflineToOnlineJourney(offlineTasks: [Task]) async throws {
        // 1. Go offline
        try await handleAction(SyncAction.setOfflineMode(true))
        
        // 2. Create tasks while offline
        for task in offlineTasks {
            try await handleAction(TaskAction.create(task))
        }
        
        // 3. Come back online
        try await handleAction(SyncAction.setOfflineMode(false))
        
        // 4. Trigger sync
        try await handleAction(SyncAction.startSync)
        
        // 5. Wait for sync completion
        var syncCompleted = false
        for _ in 0..<100 {
            let syncState = await syncClient.currentState
            if !syncState.isSyncing && syncState.pendingChanges == 0 {
                syncCompleted = true
                break
            }
            try await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        guard syncCompleted else {
            throw OrchestratorError.syncTimeout
        }
        
        // 6. Verify all tasks synced
        let finalState = await taskClient.currentState
        for task in offlineTasks {
            guard finalState.tasks.contains(where: { $0.id == task.id }) else {
                throw OrchestratorError.taskNotSynced(task.id)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func shouldSyncAfterAction(_ action: TaskAction) -> Bool {
        switch action {
        case .create, .update, .delete, .deleteMultiple,
             .bulkDelete, .softDelete, .undoDelete, .permanentDelete,
             .softDeleteWithRetention, .bulkSoftDeleteWithRetention:
            return true
        case .search, .sort, .filterByCategory:
            return false
        case .shareTask, .shareTaskList, .unshareTask, .updateSharePermission:
            return true
        case .createCategory, .updateCategory, .deleteCategory, .batchAssignCategory:
            return true
        case .loadPage, .setVisibleRange, .scrollToOffset, .scrollToPosition, .setViewport:
            return false
        }
    }
    
    private func loadUserData() async {
        // Load user-specific tasks from storage
        if let storedTasks = try? await storageCapability?.loadAll(Task.self) {
            // Filter tasks for current user
            let userTasks = storedTasks.filter { task in
                task.userId == activeUserId || task.sharedWith.contains { share in
                    share.userId == activeUserId
                }
            }
            // Update task client state
            for task in userTasks {
                try? await taskClient.process(.create(task))
            }
        }
    }
    
    private func clearUserData() async {
        // Clear all tasks from memory (not storage)
        let currentState = await taskClient.currentState
        let taskIds = Set(currentState.tasks.map { $0.id })
        if !taskIds.isEmpty {
            try? await taskClient.process(.deleteMultiple(taskIds: taskIds))
        }
    }
}

// MARK: - Supporting Types

enum OrchestratorError: Error, LocalizedError {
    case notInitialized
    case unsupportedAction
    case notAuthenticated
    case taskNotFound
    case updateFailed
    case syncTimeout
    case taskNotSynced(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Orchestrator not initialized"
        case .unsupportedAction:
            return "Action type not supported"
        case .notAuthenticated:
            return "User not authenticated"
        case .taskNotFound:
            return "Task not found"
        case .updateFailed:
            return "Update failed to persist"
        case .syncTimeout:
            return "Sync operation timed out"
        case .taskNotSynced(let taskId):
            return "Task \(taskId) was not synced"
        }
    }
}

// Extension to make Task support userId for multi-user scenarios
extension Task {
    var userId: String? {
        // In a real app, this would be a stored property
        // For testing, we'll use the createdBy field if available
        return self.createdBy
    }
}