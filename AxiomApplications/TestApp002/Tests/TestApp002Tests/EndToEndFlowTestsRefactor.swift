import Testing
import Foundation

@testable import TestApp002Core

@Suite("End-to-End Flow Tests - REFACTOR Phase")
struct EndToEndFlowTestsRefactor {
    
    // MARK: - REFACTOR Phase: Optimized End-to-End Flow Tests
    
    @Test("REFACTOR: Task creation journey should complete in <100ms with optimizations")
    func testOptimizedTaskCreationJourney() async throws {
        // REFACTOR: Test optimized task creation performance
        
        // Initialize optimized orchestrator
        let orchestrator = OptimizedTaskOrchestrator()
        
        let initStartTime = CFAbsoluteTimeGetCurrent()
        try await orchestrator.initialize()
        let initTime = (CFAbsoluteTimeGetCurrent() - initStartTime) * 1000
        
        // Initialization should be fast with concurrent setup
        #expect(initTime < 200, "Initialization should complete in <200ms")
        
        // Login user
        try await orchestrator.handleAction(UserAction.login(email: "test@example.com", password: "password"))
        
        // Measure task creation journey time
        let journeyStartTime = CFAbsoluteTimeGetCurrent()
        
        let task = Task(
            id: "perf-task-1",
            title: "Performance Test Task",
            description: "Created to test optimized performance",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date(),
            createdBy: "test@example.com"
        )
        
        try await orchestrator.completeTaskCreationJourney(task: task)
        
        let journeyTime = (CFAbsoluteTimeGetCurrent() - journeyStartTime) * 1000
        
        // Optimized journey should be fast
        #expect(journeyTime < 100, "Task creation journey should complete in <100ms")
    }
    
    @Test("REFACTOR: Batch operations should process 100 tasks in <500ms")
    func testBatchOperationPerformance() async throws {
        // REFACTOR: Test batch operation optimization
        
        let orchestrator = OptimizedTaskOrchestrator()
        try await orchestrator.initialize()
        
        // Login user
        try await orchestrator.handleAction(UserAction.login(email: "batch@example.com", password: "password"))
        
        // Create 100 tasks using batch operations
        let batchStartTime = CFAbsoluteTimeGetCurrent()
        
        let tasks = (0..<100).map { i in
            Task(
                id: "batch-task-\(i)",
                title: "Batch Task \(i)",
                description: "Task \(i) for batch testing",
                isCompleted: false,
                createdAt: Date(),
                updatedAt: Date(),
                createdBy: "batch@example.com"
            )
        }
        
        // Process as batch
        await withTaskGroup(of: Void.self) { group in
            for task in tasks {
                group.addTask {
                    try? await orchestrator.handleAction(TaskAction.create(task))
                }
            }
        }
        
        let batchTime = (CFAbsoluteTimeGetCurrent() - batchStartTime) * 1000
        
        // Batch operations should be efficient
        #expect(batchTime < 500, "Batch creation of 100 tasks should complete in <500ms")
    }
    
    @Test("REFACTOR: Navigation with preloading should reduce latency by >50%")
    func testNavigationPreloadingPerformance() async throws {
        // REFACTOR: Test navigation optimization with preloading
        
        let orchestrator = OptimizedTaskOrchestrator()
        try await orchestrator.initialize()
        
        // Login and create test data
        try await orchestrator.handleAction(UserAction.login(email: "nav@example.com", password: "password"))
        
        // Create some tasks
        for i in 0..<20 {
            let task = Task(
                id: "nav-task-\(i)",
                title: "Navigation Task \(i)",
                description: "Task for navigation testing",
                isCompleted: false,
                createdAt: Date(),
                updatedAt: Date(),
                createdBy: "nav@example.com"
            )
            try await orchestrator.handleAction(TaskAction.create(task))
        }
        
        // Measure cold navigation (first time)
        let coldNavStartTime = CFAbsoluteTimeGetCurrent()
        try await orchestrator.navigate(to: AppRoute.taskDetail(taskId: "nav-task-0"))
        let coldNavTime = (CFAbsoluteTimeGetCurrent() - coldNavStartTime) * 1000
        
        // Navigate back
        try await orchestrator.navigate(to: AppRoute.taskList)
        
        // Measure warm navigation (with preloading)
        let warmNavStartTime = CFAbsoluteTimeGetCurrent()
        try await orchestrator.navigate(to: AppRoute.taskDetail(taskId: "nav-task-0"))
        let warmNavTime = (CFAbsoluteTimeGetCurrent() - warmNavStartTime) * 1000
        
        // Preloading should significantly reduce navigation time
        let improvement = (coldNavTime - warmNavTime) / coldNavTime * 100
        #expect(improvement > 50, "Navigation preloading should reduce latency by >50%")
    }
    
    @Test("REFACTOR: State cache should achieve >80% hit rate for repeated actions")
    func testStateCacheEffectiveness() async throws {
        // REFACTOR: Test state caching optimization
        
        let orchestrator = OptimizedTaskOrchestrator()
        try await orchestrator.initialize()
        
        // Login user
        try await orchestrator.handleAction(UserAction.login(email: "cache@example.com", password: "password"))
        
        // Create test task
        let task = Task(
            id: "cache-task-1",
            title: "Cache Test Task",
            description: "Task for cache testing",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date(),
            createdBy: "cache@example.com"
        )
        try await orchestrator.handleAction(TaskAction.create(task))
        
        // Perform repeated searches (should hit cache)
        let searchAction = TaskAction.search(query: "Cache")
        
        // First search (cache miss)
        let firstSearchTime = CFAbsoluteTimeGetCurrent()
        try await orchestrator.handleAction(searchAction)
        let firstSearchDuration = (CFAbsoluteTimeGetCurrent() - firstSearchTime) * 1000
        
        // Repeated searches (should hit cache)
        var cachedSearchTimes: [Double] = []
        for _ in 0..<10 {
            let searchTime = CFAbsoluteTimeGetCurrent()
            try await orchestrator.handleAction(searchAction)
            let duration = (CFAbsoluteTimeGetCurrent() - searchTime) * 1000
            cachedSearchTimes.append(duration)
        }
        
        // Calculate average cached search time
        let avgCachedTime = cachedSearchTimes.reduce(0, +) / Double(cachedSearchTimes.count)
        
        // Cached searches should be much faster
        let cacheSpeedup = firstSearchDuration / avgCachedTime
        #expect(cacheSpeedup > 5, "Cached searches should be >5x faster")
    }
    
    @Test("REFACTOR: Concurrent sync operations should not block UI operations")
    func testConcurrentSyncNonBlocking() async throws {
        // REFACTOR: Test async sync optimization
        
        let orchestrator = OptimizedTaskOrchestrator()
        try await orchestrator.initialize()
        
        // Login user
        try await orchestrator.handleAction(UserAction.login(email: "concurrent@example.com", password: "password"))
        
        // Create tasks that will trigger sync
        for i in 0..<5 {
            let task = Task(
                id: "sync-task-\(i)",
                title: "Sync Task \(i)",
                description: "Task that triggers sync",
                isCompleted: false,
                createdAt: Date(),
                updatedAt: Date(),
                createdBy: "concurrent@example.com"
            )
            try await orchestrator.handleAction(TaskAction.create(task))
        }
        
        // Start a long sync operation
        Task {
            try? await orchestrator.handleAction(SyncAction.startSync)
        }
        
        // UI operations should not be blocked
        let uiOperationTime = CFAbsoluteTimeGetCurrent()
        
        // Perform UI operations while sync is running
        try await orchestrator.navigate(to: AppRoute.taskList)
        try await orchestrator.handleAction(TaskAction.search(query: "test"))
        try await orchestrator.navigate(to: AppRoute.categoryList)
        
        let uiDuration = (CFAbsoluteTimeGetCurrent() - uiOperationTime) * 1000
        
        // UI operations should remain responsive
        #expect(uiDuration < 100, "UI operations should complete in <100ms even during sync")
    }
    
    @Test("REFACTOR: Memory usage should remain <50MB with 1000 tasks")
    func testMemoryOptimization() async throws {
        // REFACTOR: Test memory optimization with large datasets
        
        let orchestrator = OptimizedTaskOrchestrator()
        try await orchestrator.initialize()
        
        // Login user
        try await orchestrator.handleAction(UserAction.login(email: "memory@example.com", password: "password"))
        
        // Record initial memory
        let initialMemory = getCurrentMemoryUsage()
        
        // Create 1000 tasks
        for i in 0..<1000 {
            let task = Task(
                id: "mem-task-\(i)",
                title: "Memory Test Task \(i)",
                description: "Task \(i) for memory testing with a longer description to increase memory usage",
                isCompleted: i % 2 == 0,
                createdAt: Date(),
                updatedAt: Date(),
                priority: Priority.allCases[i % 4],
                createdBy: "memory@example.com"
            )
            try await orchestrator.handleAction(TaskAction.create(task))
            
            // Yield periodically to allow memory management
            if i % 100 == 0 {
                await Task.yield()
            }
        }
        
        // Record final memory
        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        let memoryIncreaseMB = Double(memoryIncrease) / (1024 * 1024)
        
        // Memory usage should be optimized
        #expect(memoryIncreaseMB < 50, "Memory increase should be <50MB for 1000 tasks")
    }
    
    @Test("REFACTOR: Deep link resolution should complete in <50ms with caching")
    func testDeepLinkCachingPerformance() async throws {
        // REFACTOR: Test deep link optimization
        
        let orchestrator = OptimizedTaskOrchestrator()
        try await orchestrator.initialize()
        
        // Login user
        try await orchestrator.handleAction(UserAction.login(email: "deeplink@example.com", password: "password"))
        
        // Create target task
        let task = Task(
            id: "deep-link-cached",
            title: "Deep Link Cached Task",
            description: "Task for deep link cache testing",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date(),
            createdBy: "deeplink@example.com"
        )
        try await orchestrator.handleAction(TaskAction.create(task))
        
        let deepLinkURL = URL(string: "task://taskId/deep-link-cached")!
        
        // First deep link (no cache)
        let firstLinkTime = CFAbsoluteTimeGetCurrent()
        try await orchestrator.navigate(to: deepLinkURL)
        let firstLinkDuration = (CFAbsoluteTimeGetCurrent() - firstLinkTime) * 1000
        
        // Navigate away
        try await orchestrator.navigate(to: AppRoute.taskList)
        
        // Second deep link (should hit cache)
        let secondLinkTime = CFAbsoluteTimeGetCurrent()
        try await orchestrator.navigate(to: deepLinkURL)
        let secondLinkDuration = (CFAbsoluteTimeGetCurrent() - secondLinkTime) * 1000
        
        // Cached deep link should be fast
        #expect(secondLinkDuration < 50, "Cached deep link should resolve in <50ms")
        
        // Cache should provide significant speedup
        let cacheImprovement = firstLinkDuration / secondLinkDuration
        #expect(cacheImprovement > 2, "Cached deep link should be >2x faster")
    }
    
    @Test("REFACTOR: Offline-to-online sync should use smart change detection")
    func testSmartSyncOptimization() async throws {
        // REFACTOR: Test optimized sync with change detection
        
        let orchestrator = OptimizedTaskOrchestrator()
        try await orchestrator.initialize()
        
        // Login user
        try await orchestrator.handleAction(UserAction.login(email: "smartsync@example.com", password: "password"))
        
        // Create initial tasks
        for i in 0..<10 {
            let task = Task(
                id: "sync-opt-task-\(i)",
                title: "Sync Optimization Task \(i)",
                description: "Task for sync optimization testing",
                isCompleted: false,
                createdAt: Date(),
                updatedAt: Date(),
                createdBy: "smartsync@example.com"
            )
            try await orchestrator.handleAction(TaskAction.create(task))
        }
        
        // Sync to establish baseline
        try await orchestrator.handleAction(SyncAction.startSync)
        
        // Go offline
        try await orchestrator.handleAction(SyncAction.setOfflineMode(true))
        
        // Make minimal changes
        let updatedTask = Task(
            id: "sync-opt-task-0",
            title: "Updated Sync Task 0",
            description: "Updated description",
            isCompleted: true,
            createdAt: Date(),
            updatedAt: Date(),
            createdBy: "smartsync@example.com"
        )
        try await orchestrator.handleAction(TaskAction.update(updatedTask))
        
        // Come back online
        try await orchestrator.handleAction(SyncAction.setOfflineMode(false))
        
        // Measure sync time (should be fast for minimal changes)
        let syncStartTime = CFAbsoluteTimeGetCurrent()
        
        try await orchestrator.completeOfflineToOnlineJourney(offlineTasks: [])
        
        let syncDuration = (CFAbsoluteTimeGetCurrent() - syncStartTime) * 1000
        
        // Smart sync should be fast for minimal changes
        #expect(syncDuration < 200, "Smart sync should complete in <200ms for minimal changes")
    }
}

// MARK: - Helper Functions

private func getCurrentMemoryUsage() -> Int64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
    
    let result = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_,
                     task_flavor_t(MACH_TASK_BASIC_INFO),
                     $0,
                     &count)
        }
    }
    
    return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
}