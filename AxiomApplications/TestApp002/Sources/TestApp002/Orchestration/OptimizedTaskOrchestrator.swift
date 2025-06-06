import Foundation

// REFACTOR Phase: Optimized TaskOrchestrator with performance improvements

/// Optimized orchestrator with performance enhancements for critical paths
actor OptimizedTaskOrchestrator: Orchestrator {
    
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
    
    // REFACTOR: Performance optimizations
    private let actionQueue = ActionQueue()
    private let stateCache = StateCache()
    private let performanceMonitor = PerformanceMonitor()
    private var preloadTasks: Set<_Concurrency.Task<Void, Never>> = []
    
    // MARK: - Initialization
    
    init() {
        self.taskClient = TaskClient()
        self.userClient = UserClient()
        self.syncClient = SyncClient()
    }
    
    func initialize() async throws {
        guard !isInitialized else { return }
        
        let initStartTime = CFAbsoluteTimeGetCurrent()
        
        // REFACTOR: Concurrent initialization
        async let networkInit = initializeNetworkCapability()
        async let storageInit = initializeStorageCapability()
        async let notificationInit = initializeNotificationCapability()
        
        // Wait for all capabilities
        networkCapability = try await networkInit
        storageCapability = try await storageInit
        notificationCapability = try await notificationInit
        
        // REFACTOR: Concurrent client setup
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                guard let self = self else { return }
                await self.taskClient.setStorageCapability(self.storageCapability!)
                await self.taskClient.setNotificationCapability(self.notificationCapability!)
            }
            
            group.addTask { [weak self] in
                guard let self = self else { return }
                await self.syncClient.setNetworkCapability(self.networkCapability!)
                await self.syncClient.setStorageCapability(self.storageCapability!)
            }
        }
        
        // Initialize navigation controllers concurrently
        async let tabNavInit = TabNavigationController()
        async let deepNavInit = DeepNavigationController()
        async let deepLinkInit = DeepLinkNavigationController()
        
        tabNavigationController = await tabNavInit
        deepNavigationController = await deepNavInit
        deepLinkNavigationController = await deepLinkInit
        
        isInitialized = true
        
        let initTime = CFAbsoluteTimeGetCurrent() - initStartTime
        await performanceMonitor.recordMetric("initialization", value: initTime)
    }
    
    // MARK: - Orchestrator Protocol
    
    func handleAction<A>(_ action: A) async throws {
        guard isInitialized else {
            throw OrchestratorError.notInitialized
        }
        
        let actionStartTime = CFAbsoluteTimeGetCurrent()
        
        // REFACTOR: Action batching and coalescing
        if let batchableAction = action as? BatchableAction {
            await actionQueue.enqueue(batchableAction)
            
            // Process batch if threshold reached
            if await actionQueue.shouldProcessBatch() {
                let batch = await actionQueue.dequeueBatch()
                try await processBatch(batch)
            }
            return
        }
        
        // Route actions to appropriate clients
        switch action {
        case let taskAction as TaskAction:
            // REFACTOR: Check cache before processing
            if let cachedResult = await stateCache.getCachedResult(for: taskAction) {
                await performanceMonitor.recordCacheHit("taskAction")
                return
            }
            
            try await taskClient.process(taskAction)
            await stateCache.cacheResult(for: taskAction)
            
            // REFACTOR: Async sync trigger
            if shouldSyncAfterAction(taskAction) {
                Task {
                    try? await syncClient.process(.startSync)
                }
            }
            
        case let userAction as UserAction:
            try await userClient.process(userAction)
            
            // Handle user state changes
            if case .login(let email, _) = userAction {
                activeUserId = email
                // REFACTOR: Preload user data asynchronously
                Task {
                    await self.preloadUserData()
                }
            } else if case .logout = userAction {
                activeUserId = nil
                await clearUserData()
                await stateCache.clear()
            }
            
        case let syncAction as SyncAction:
            try await syncClient.process(syncAction)
            
        default:
            throw OrchestratorError.unsupportedAction
        }
        
        let actionTime = CFAbsoluteTimeGetCurrent() - actionStartTime
        await performanceMonitor.recordMetric("action_\(String(describing: type(of: action)))", value: actionTime)
    }
    
    func navigate(to route: Any) async throws {
        guard isInitialized else {
            throw OrchestratorError.notInitialized
        }
        
        let navStartTime = CFAbsoluteTimeGetCurrent()
        
        // REFACTOR: Preload navigation targets
        if let appRoute = route as? AppRoute {
            await preloadNavigationTarget(appRoute)
            
            // Handle navigation with optimized routing
            switch appRoute {
            case .taskList:
                _ = try? await tabNavigationController?.switchToTab(.tasks)
            case .taskDetail(let taskId):
                // REFACTOR: Preload task data
                await preloadTaskData(taskId: taskId)
                _ = await deepNavigationController?.navigateTo(.taskDetail(taskId: taskId))
            case .taskEdit(let taskId):
                if let taskId = taskId {
                    await preloadTaskData(taskId: taskId)
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
            // Handle deep linking with caching
            let cachedRoute = await stateCache.getCachedRoute(for: url)
            if let cachedRoute = cachedRoute {
                try await navigate(to: cachedRoute)
            } else {
                let result = await deepLinkNavigationController?.handleDeepLink(url)
                if let route = result?.route {
                    await stateCache.cacheRoute(route, for: url)
                }
            }
        }
        
        let navTime = CFAbsoluteTimeGetCurrent() - navStartTime
        await performanceMonitor.recordMetric("navigation", value: navTime)
    }
    
    // MARK: - Optimized End-to-End Flows
    
    /// Optimized task creation journey with preloading
    func completeTaskCreationJourney(task: Task) async throws {
        // Ensure user is logged in
        guard activeUserId != nil else {
            throw OrchestratorError.notAuthenticated
        }
        
        // REFACTOR: Concurrent navigation and modal preparation
        async let navTask = navigate(to: AppRoute.taskList)
        async let modalPrep = prepareTaskCreationModal()
        
        try await navTask
        await modalPrep
        
        // Open task creation modal
        try await navigate(to: AppRoute.taskEdit(taskId: nil))
        
        // Create the task with optimistic UI update
        try await handleAction(TaskAction.create(task))
        
        // Close modal asynchronously
        Task {
            _ = await tabNavigationController?.dismissModal()
        }
        
        // Verify task appears (using cached state)
        let state = await taskClient.currentState
        guard state.tasks.contains(where: { $0.id == task.id }) else {
            throw OrchestratorError.taskNotFound
        }
    }
    
    /// Optimized sharing journey with parallel operations
    func completeSharingJourney(taskId: String, shareWithUserId: String) async throws {
        // Share the task
        try await handleAction(TaskAction.shareTask(
            taskId: taskId,
            userId: shareWithUserId,
            permission: .write
        ))
        
        // REFACTOR: Trigger sync immediately without waiting
        Task {
            try? await handleAction(SyncAction.startSync)
        }
        
        // REFACTOR: Use notification-based sync completion
        await waitForSyncCompletion(timeout: 5.0)
    }
    
    /// Optimized offline-to-online journey with batch sync
    func completeOfflineToOnlineJourney(offlineTasks: [Task]) async throws {
        // Go offline
        try await handleAction(SyncAction.setOfflineMode(true))
        
        // REFACTOR: Batch create offline tasks
        let createActions = offlineTasks.map { TaskAction.create($0) }
        try await processBatch(createActions)
        
        // Come back online
        try await handleAction(SyncAction.setOfflineMode(false))
        
        // REFACTOR: Smart sync with change detection
        let hasChanges = await syncClient.currentState.pendingChanges > 0
        if hasChanges {
            try await handleAction(SyncAction.startSync)
            await waitForSyncCompletion(timeout: 10.0)
        }
        
        // Verify all tasks synced using cached state
        let finalState = await taskClient.currentState
        for task in offlineTasks {
            guard finalState.tasks.contains(where: { $0.id == task.id }) else {
                throw OrchestratorError.taskNotSynced(task.id)
            }
        }
    }
    
    // MARK: - Private Optimization Helpers
    
    private func initializeNetworkCapability() async throws -> NetworkCapability {
        let capability = TestNetworkCapability()
        try await capability.initialize()
        return capability
    }
    
    private func initializeStorageCapability() async throws -> StorageCapability {
        let capability = TestStorageCapability()
        try await capability.initialize()
        return capability
    }
    
    private func initializeNotificationCapability() async throws -> NotificationCapability {
        let capability = TestNotificationCapability()
        try await capability.initialize()
        return capability
    }
    
    private func processBatch(_ actions: [any Sendable]) async throws {
        // Process actions in parallel where possible
        await withTaskGroup(of: Error?.self) { group in
            for action in actions {
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    do {
                        if let taskAction = action as? TaskAction {
                            try await self.taskClient.process(taskAction)
                        }
                        return nil
                    } catch {
                        return error
                    }
                }
            }
            
            // Collect any errors
            for await error in group {
                if let error = error {
                    throw error
                }
            }
        }
    }
    
    private func preloadNavigationTarget(_ route: AppRoute) async {
        // Preload data for navigation target
        let preloadTask = Task {
            switch route {
            case .taskList:
                // Preload recent tasks
                _ = await taskClient.currentState
            case .categoryList:
                // Preload categories
                _ = await taskClient.currentState.categories
            default:
                break
            }
        }
        
        preloadTasks.insert(preloadTask)
        
        // Clean up completed tasks
        preloadTasks = preloadTasks.filter { !$0.isCancelled }
    }
    
    private func preloadTaskData(taskId: String) async {
        // Preload specific task data
        let state = await taskClient.currentState
        _ = state.tasks.first { $0.id == taskId }
    }
    
    private func prepareTaskCreationModal() async {
        // Prepare modal resources
        await tabNavigationController?.enablePreloading(for: [.tasks])
    }
    
    private func preloadUserData() async {
        // Optimized user data loading with pagination
        let pageSize = 100
        var page = 0
        
        while true {
            guard let storedTasks = try? await storageCapability?.loadAll(Task.self) else { break }
            
            let startIndex = page * pageSize
            let endIndex = min(startIndex + pageSize, storedTasks.count)
            
            if startIndex >= storedTasks.count { break }
            
            let pageTasks = Array(storedTasks[startIndex..<endIndex])
            let userTasks = pageTasks.filter { task in
                task.userId == activeUserId || task.sharedWith.contains { share in
                    share.userId == activeUserId
                }
            }
            
            // Process page
            for task in userTasks {
                try? await taskClient.process(.create(task))
            }
            
            page += 1
            
            // Yield to prevent blocking
            await Task.yield()
        }
    }
    
    private func clearUserData() async {
        // Optimized bulk clear
        let currentState = await taskClient.currentState
        let taskIds = Set(currentState.tasks.map { $0.id })
        if !taskIds.isEmpty {
            try? await taskClient.process(.bulkDelete(taskIds: taskIds))
        }
    }
    
    private func waitForSyncCompletion(timeout: TimeInterval) async {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            let syncState = await syncClient.currentState
            if !syncState.isSyncing && syncState.pendingChanges == 0 {
                return
            }
            
            // Use exponential backoff for checking
            let delay = min(0.1 * pow(1.5, Double(Int(Date().timeIntervalSince(startTime)))), 1.0)
            try? await _Concurrency.Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }
    
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
}

// MARK: - Supporting Optimization Types

protocol BatchableAction: Sendable {
    var canBatch: Bool { get }
    var batchKey: String { get }
}

actor ActionQueue {
    private var queue: [any BatchableAction] = []
    private let batchThreshold = 10
    
    func enqueue(_ action: any BatchableAction) {
        queue.append(action)
    }
    
    func shouldProcessBatch() -> Bool {
        return queue.count >= batchThreshold
    }
    
    func dequeueBatch() -> [any Sendable] {
        let batch = Array(queue.prefix(batchThreshold))
        queue.removeFirst(min(batchThreshold, queue.count))
        return batch
    }
}

actor StateCache {
    private var actionCache: [String: Date] = [:]
    private var routeCache: [URL: AppRoute] = [:]
    private let cacheExpiration: TimeInterval = 60.0 // 1 minute
    
    func getCachedResult(for action: TaskAction) -> Bool? {
        let key = String(describing: action)
        if let cachedDate = actionCache[key],
           Date().timeIntervalSince(cachedDate) < cacheExpiration {
            return true
        }
        return nil
    }
    
    func cacheResult(for action: TaskAction) {
        let key = String(describing: action)
        actionCache[key] = Date()
    }
    
    func getCachedRoute(for url: URL) -> AppRoute? {
        return routeCache[url]
    }
    
    func cacheRoute(_ route: AppRoute, for url: URL) {
        routeCache[url] = route
    }
    
    func clear() {
        actionCache.removeAll()
        routeCache.removeAll()
    }
}

actor PerformanceMonitor {
    private var metrics: [String: [Double]] = [:]
    private var cacheHits: [String: Int] = [:]
    
    func recordMetric(_ name: String, value: Double) {
        var values = metrics[name, default: []]
        values.append(value)
        
        // Keep only last 100 values
        if values.count > 100 {
            values.removeFirst(values.count - 100)
        }
        
        metrics[name] = values
    }
    
    func recordCacheHit(_ type: String) {
        cacheHits[type, default: 0] += 1
    }
    
    func getAverageMetric(_ name: String) -> Double? {
        guard let values = metrics[name], !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
    
    func getCacheHitRate(_ type: String) -> Double {
        let hits = Double(cacheHits[type] ?? 0)
        let total = metrics.values.flatMap { $0 }.count
        return total > 0 ? hits / Double(total) : 0
    }
}