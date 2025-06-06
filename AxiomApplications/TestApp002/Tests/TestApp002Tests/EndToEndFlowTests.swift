import Testing
import Foundation

@testable import TestApp002Core

@Suite("End-to-End Flow Tests - RED Phase")
struct EndToEndFlowTests {
    
    // MARK: - RED Phase: Complete User Journey Tests (Expecting Failures)
    
    @Test("RED: Complete task creation journey should fail without end-to-end orchestration")
    func testCompleteTaskCreationJourney() async throws {
        // RED: Test the complete flow from user login to task creation to seeing it in the list
        // This should fail because we don't have end-to-end orchestration yet
        
        // Step 1: User authentication
        let userClient = UserClient()
        let authResult = try await userClient.process(.login(email: "test@example.com", password: "password"))
        
        // Step 2: Navigate to task creation
        let tabNavigator = TabNavigationController()
        let navigationResult = await tabNavigator.switchToTab(.tasks)
        #expect(navigationResult.isSuccess, "Tab navigation should work")
        
        // Step 3: Open task creation modal
        let modalResult = await tabNavigator.presentModal(.taskCreation(taskId: nil))
        #expect(modalResult.isSuccess, "Modal presentation should work")
        
        // Step 4: Create task through TaskClient
        let taskClient = TaskClient()
        let task = Task(
            id: "journey-task-1",
            title: "Journey Test Task",
            description: "Created through complete user journey",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await taskClient.process(.create(task))
        
        // Step 5: Verify task appears in list immediately (16ms requirement)
        let startTime = Date()
        let currentState = await taskClient.currentState
        let endTime = Date()
        let latency = endTime.timeIntervalSince(startTime) * 1000 // Convert to ms
        
        #expect(latency < 16.0, "Task should appear in list within 16ms")
        #expect(currentState.tasks.contains { $0.id == task.id }, "Created task should be in the list")
        
        // Step 6: Close modal and verify navigation state
        let dismissResult = await tabNavigator.dismissModal()
        #expect(dismissResult.isSuccess, "Modal dismissal should work")
        
        // RED: This test expects the end-to-end flow to fail due to lack of orchestration
        #expect(false, "RED: End-to-end orchestration not implemented yet")
    }
    
    @Test("RED: Complete task editing journey should fail without proper state coordination")
    func testCompleteTaskEditingJourney() async throws {
        // RED: Test editing an existing task through the complete UI flow
        
        // Setup: Create initial task
        let taskClient = TaskClient()
        let originalTask = Task(
            id: "journey-edit-task",
            title: "Original Title",
            description: "Original Description",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await taskClient.process(.create(originalTask))
        
        // Step 1: Navigate to task list
        let tabNavigator = TabNavigationController()
        let tabResult = await tabNavigator.switchToTab(.tasks)
        #expect(tabResult.isSuccess, "Should navigate to tasks tab")
        
        // Step 2: Navigate to task detail
        let deepNavigator = DeepNavigationController()
        let detailResult = await deepNavigator.navigateTo(.taskDetail(taskId: originalTask.id))
        #expect(detailResult.navigationTime < 500, "Navigation should complete in <500ms")
        
        // Step 3: Navigate to edit screen
        let editResult = await deepNavigator.navigateTo(.taskEdit(taskId: originalTask.id))
        #expect(editResult.navigationTime < 500, "Edit navigation should complete in <500ms")
        
        // Step 4: Make changes to the task
        let updatedTask = Task(
            id: originalTask.id,
            title: "Updated Title",
            description: "Updated Description",
            isCompleted: true,
            createdAt: originalTask.createdAt,
            updatedAt: Date()
        )
        try await taskClient.process(.update(updatedTask))
        
        // Step 5: Navigate back and verify changes are reflected
        let backResult = await deepNavigator.navigateBack()
        #expect(backResult.success, "Back navigation should work")
        
        // Step 6: Verify state consistency across navigation
        let finalState = await taskClient.currentState
        let updatedTaskInList = finalState.tasks.first { $0.id == originalTask.id }
        #expect(updatedTaskInList?.title == "Updated Title", "Changes should persist across navigation")
        
        // RED: This test expects the complete editing flow to fail due to state coordination issues
        #expect(false, "RED: Complete editing journey not properly coordinated yet")
    }
    
    @Test("RED: Complete sharing and collaboration journey should fail without workflow orchestration")
    func testCompleteSharingJourney() async throws {
        // RED: Test the complete sharing workflow across multiple users
        
        // Setup: Two users and their clients
        let userClient1 = UserClient()
        let userClient2 = UserClient()
        let taskClient1 = TaskClient()
        let taskClient2 = TaskClient()
        
        // Step 1: User 1 logs in and creates a task
        try await userClient1.process(.login(email: "user1@example.com", password: "password"))
        let sharedTask = Task(
            id: "shared-journey-task",
            title: "Shared Task",
            description: "Task to be shared in journey test",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await taskClient1.process(.create(sharedTask))
        
        // Step 2: User 1 shares the task
        try await taskClient1.process(.shareTask(
            taskId: sharedTask.id,
            withUserId: "user2@example.com",
            permission: .write
        ))
        
        // Step 3: Verify share is queued immediately
        let shareState1 = await taskClient1.currentState
        #expect(!shareState1.pendingShares.isEmpty, "Share should be queued immediately")
        
        // Step 4: User 2 logs in and should see shared task
        try await userClient2.process(.login(email: "user2@example.com", password: "password"))
        
        // Step 5: Sync should propagate shared task to User 2
        let syncClient2 = SyncClient()
        try await syncClient2.process(.startSync)
        
        // Wait for sync completion
        var syncCompleted = false
        var attempts = 0
        while !syncCompleted && attempts < 50 {
            let syncState = await syncClient2.currentState
            syncCompleted = !syncState.isSyncing
            if !syncCompleted {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                attempts += 1
            }
        }
        
        // Step 6: User 2 should see the shared task
        let shareState2 = await taskClient2.currentState
        let sharedTaskInUser2List = shareState2.tasks.first { $0.id == sharedTask.id }
        #expect(sharedTaskInUser2List != nil, "Shared task should appear in User 2's list")
        
        // Step 7: User 2 edits the shared task
        let editedTask = Task(
            id: sharedTask.id,
            title: "Edited by User 2",
            description: sharedTask.description,
            isCompleted: true,
            createdAt: sharedTask.createdAt,
            updatedAt: Date()
        )
        try await taskClient2.process(.update(editedTask))
        
        // Step 8: Changes should sync back to User 1
        let syncClient1 = SyncClient()
        try await syncClient1.process(.startSync)
        
        // Step 9: User 1 should see User 2's changes
        let finalState1 = await taskClient1.currentState
        let finalTaskInUser1List = finalState1.tasks.first { $0.id == sharedTask.id }
        #expect(finalTaskInUser1List?.title == "Edited by User 2", "User 1 should see User 2's edits")
        
        // RED: This test expects the complete sharing journey to fail due to missing workflow orchestration
        #expect(false, "RED: Complete sharing workflow not orchestrated yet")
    }
    
    @Test("RED: Complete offline-to-online sync journey should fail without proper state management")
    func testCompleteOfflineToOnlineJourney() async throws {
        // RED: Test the complete flow of working offline then syncing when online
        
        let taskClient = TaskClient()
        let syncClient = SyncClient()
        let networkCapability = MockNetworkCapability()
        
        // Step 1: Start online and create initial tasks
        await networkCapability.setOnline(true)
        let onlineTask = Task(
            id: "online-task",
            title: "Created Online",
            description: "Task created while online",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await taskClient.process(.create(onlineTask))
        
        // Step 2: Sync initial state
        try await syncClient.process(.startSync)
        
        // Step 3: Go offline
        await networkCapability.setOnline(false)
        try await syncClient.process(.setOfflineMode(true))
        
        // Step 4: Create tasks while offline
        let offlineTask1 = Task(
            id: "offline-task-1",
            title: "Created Offline 1",
            description: "Task created while offline",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        let offlineTask2 = Task(
            id: "offline-task-2",
            title: "Created Offline 2", 
            description: "Another offline task",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await taskClient.process(.create(offlineTask1))
        try await taskClient.process(.create(offlineTask2))
        
        // Step 5: Edit existing task while offline
        let editedOnlineTask = Task(
            id: onlineTask.id,
            title: "Edited Offline",
            description: onlineTask.description,
            isCompleted: true,
            createdAt: onlineTask.createdAt,
            updatedAt: Date()
        )
        try await taskClient.process(.update(editedOnlineTask))
        
        // Step 6: Verify offline changes are stored locally
        let offlineState = await taskClient.currentState
        #expect(offlineState.tasks.count == 3, "Should have 3 tasks stored locally")
        #expect(offlineState.tasks.contains { $0.id == "offline-task-1" }, "Offline task 1 should be stored")
        #expect(offlineState.tasks.contains { $0.id == "offline-task-2" }, "Offline task 2 should be stored")
        
        // Step 7: Come back online
        await networkCapability.setOnline(true)
        try await syncClient.process(.setOfflineMode(false))
        
        // Step 8: Trigger sync
        try await syncClient.process(.startSync)
        
        // Step 9: Wait for sync completion
        var syncCompleted = false
        var attempts = 0
        while !syncCompleted && attempts < 100 {
            let syncState = await syncClient.currentState
            syncCompleted = !syncState.isSyncing && syncState.pendingChanges == 0
            if !syncCompleted {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                attempts += 1
            }
        }
        
        // Step 10: Verify all changes are synced and consistent
        let onlineState = await taskClient.currentState
        #expect(onlineState.tasks.count == 3, "All tasks should be synced")
        
        let syncedOfflineTask1 = onlineState.tasks.first { $0.id == "offline-task-1" }
        let syncedOfflineTask2 = onlineState.tasks.first { $0.id == "offline-task-2" }
        let syncedEditedTask = onlineState.tasks.first { $0.id == onlineTask.id }
        
        #expect(syncedOfflineTask1 != nil, "Offline task 1 should be synced")
        #expect(syncedOfflineTask2 != nil, "Offline task 2 should be synced")
        #expect(syncedEditedTask?.title == "Edited Offline", "Edited task should be synced")
        
        // RED: This test expects the offline-to-online journey to fail due to incomplete state management
        #expect(false, "RED: Complete offline-to-online journey not properly managed yet")
    }
    
    @Test("RED: Complete search and organization journey should fail without integrated workflow")
    func testCompleteSearchAndOrganizationJourney() async throws {
        // RED: Test the complete flow of creating, searching, categorizing, and filtering tasks
        
        let taskClient = TaskClient()
        let tabNavigator = TabNavigationController()
        
        // Step 1: Navigate to tasks tab
        let tabResult = await tabNavigator.switchToTab(.tasks)
        #expect(tabResult.isSuccess, "Should navigate to tasks tab")
        
        // Step 2: Create multiple tasks with different categories
        let workCategory = Category(id: "work", name: "Work", color: "#FF0000")
        let personalCategory = Category(id: "personal", name: "Personal", color: "#00FF00")
        
        try await taskClient.process(.createCategory(workCategory))
        try await taskClient.process(.createCategory(personalCategory))
        
        let tasks = [
            Task(id: "work-task-1", title: "Work Task 1", description: "Important work task", isCompleted: false, createdAt: Date(), updatedAt: Date(), categoryId: "work", priority: .high),
            Task(id: "work-task-2", title: "Work Task 2", description: "Another work task", isCompleted: false, createdAt: Date(), updatedAt: Date(), categoryId: "work", priority: .medium),
            Task(id: "personal-task-1", title: "Personal Task 1", description: "Personal errand", isCompleted: false, createdAt: Date(), updatedAt: Date(), categoryId: "personal", priority: .low),
            Task(id: "personal-task-2", title: "Personal Task 2", description: "Another personal task", isCompleted: true, createdAt: Date(), updatedAt: Date(), categoryId: "personal", priority: .medium),
            Task(id: "urgent-task", title: "Urgent Task", description: "Very urgent task", isCompleted: false, createdAt: Date(), updatedAt: Date(), priority: .critical)
        ]
        
        for task in tasks {
            try await taskClient.process(.create(task))
        }
        
        // Step 3: Test real-time search
        let searchStartTime = Date()
        try await taskClient.process(.search(query: "work"))
        let searchState = await taskClient.currentState
        let searchEndTime = Date()
        let searchLatency = searchEndTime.timeIntervalSince(searchStartTime) * 1000
        
        #expect(searchLatency < 16.0, "Search should complete within 16ms")
        #expect(searchState.filteredTasks.count == 2, "Should find 2 work tasks")
        
        // Step 4: Test category filtering
        try await taskClient.process(.filterByCategory(categoryId: "personal"))
        let categoryState = await taskClient.currentState
        #expect(categoryState.filteredTasks.count == 2, "Should find 2 personal tasks")
        
        // Step 5: Test priority sorting
        try await taskClient.process(.sort(by: SortCriteria(type: .priority, ascending: false)))
        let sortedState = await taskClient.currentState
        let sortedTasks = sortedState.filteredTasks
        
        // Verify tasks are sorted by priority (critical > high > medium > low)
        if sortedTasks.count >= 2 {
            let firstTaskPriority = sortedTasks[0].priority?.rawValue ?? 0
            let secondTaskPriority = sortedTasks[1].priority?.rawValue ?? 0
            #expect(firstTaskPriority >= secondTaskPriority, "Tasks should be sorted by priority")
        }
        
        // Step 6: Clear filters and verify all tasks are visible
        try await taskClient.process(.search(query: ""))
        try await taskClient.process(.filterByCategory(categoryId: nil))
        let allTasksState = await taskClient.currentState
        #expect(allTasksState.filteredTasks.count == 5, "All tasks should be visible when filters are cleared")
        
        // Step 7: Test bulk category assignment
        let taskIds = Set(tasks.prefix(3).map { $0.id })
        try await taskClient.process(.batchAssignCategory(taskIds: taskIds, categoryId: "work"))
        
        let batchState = await taskClient.currentState
        let reassignedTasks = batchState.tasks.filter { taskIds.contains($0.id) }
        #expect(reassignedTasks.allSatisfy { $0.categoryId == "work" }, "All selected tasks should be assigned to work category")
        
        // RED: This test expects the complete search and organization journey to fail due to missing workflow integration
        #expect(false, "RED: Complete search and organization workflow not integrated yet")
    }
    
    @Test("RED: Complete error recovery journey should fail without end-to-end error handling")
    func testCompleteErrorRecoveryJourney() async throws {
        // RED: Test error recovery across the complete user journey
        
        let taskClient = TaskClient()
        let syncClient = SyncClient()
        let userClient = UserClient()
        let networkCapability = EndToEndMockFailingNetworkCapability()
        let storageCapability = EndToEndMockFailingStorageCapability()
        
        // Step 1: Start with a functioning system
        let initialTask = Task(
            id: "error-recovery-task",
            title: "Test Task",
            description: "Task for error recovery testing",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await taskClient.process(.create(initialTask))
        
        // Step 2: Simulate network failure during sync
        await networkCapability.setShouldFail(true)
        do {
            try await syncClient.process(.startSync)
            #expect(false, "Sync should fail with network error")
        } catch {
            // Expected network failure
            #expect(error is NetworkError, "Should receive network error")
        }
        
        // Step 3: System should gracefully handle network failure
        let networkFailureState = await syncClient.currentState
        #expect(networkFailureState.isOffline, "System should detect offline state")
        
        // Step 4: Continue working offline
        let offlineTask = Task(
            id: "offline-during-error",
            title: "Created During Network Error",
            description: "Task created while network is failing",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await taskClient.process(.create(offlineTask))
        
        // Step 5: Simulate storage failure
        await storageCapability.setShouldFail(true)
        let storageFailTask = Task(
            id: "storage-fail-task",
            title: "Storage Fail Task",
            description: "Task that should trigger storage failure",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Storage failure should be handled gracefully
        do {
            try await taskClient.process(.create(storageFailTask))
            // Task should still be created in memory even if storage fails
            let memoryState = await taskClient.currentState
            #expect(memoryState.tasks.contains { $0.id == "storage-fail-task" }, "Task should exist in memory despite storage failure")
        } catch {
            // Storage errors should be handled gracefully
            #expect(error is StorageError, "Should receive storage error")
        }
        
        // Step 6: Recover from network failure
        await networkCapability.setShouldFail(false)
        try await syncClient.process(.setOfflineMode(false))
        
        // Step 7: Recover from storage failure
        await storageCapability.setShouldFail(false)
        
        // Step 8: System should automatically retry and recover
        try await syncClient.process(.startSync)
        
        // Wait for recovery
        var recovered = false
        var attempts = 0
        while !recovered && attempts < 50 {
            let recoveryState = await syncClient.currentState
            recovered = !recoveryState.isSyncing && !recoveryState.isOffline
            if !recovered {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                attempts += 1
            }
        }
        
        // Step 9: Verify system has fully recovered
        let finalState = await taskClient.currentState
        #expect(finalState.tasks.count >= 2, "Should have recovered all tasks")
        #expect(finalState.tasks.contains { $0.id == "error-recovery-task" }, "Original task should be recovered")
        #expect(finalState.tasks.contains { $0.id == "offline-during-error" }, "Offline task should be recovered")
        
        // RED: This test expects the complete error recovery journey to fail due to incomplete end-to-end error handling
        #expect(false, "RED: Complete error recovery journey not properly handled yet")
    }
    
    @Test("RED: Complete deep linking to specific task journey should fail without integrated navigation")
    func testCompleteDeepLinkingJourney() async throws {
        // RED: Test the complete flow from deep link to specific task and navigation
        
        let taskClient = TaskClient()
        let userClient = UserClient()
        let deepLinkNavigator = DeepLinkNavigationController()
        let tabNavigator = TabNavigationController()
        let deepNavigator = DeepNavigationController()
        
        // Step 1: Setup - Create a task to deep link to
        try await userClient.process(.login(email: "deeplink@example.com", password: "password"))
        let targetTask = Task(
            id: "deep-link-target",
            title: "Deep Link Target Task",
            description: "Task that will be accessed via deep link",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await taskClient.process(.create(targetTask))
        
        // Step 2: Simulate app opening from deep link
        let deepLinkURL = URL(string: "task://taskId/deep-link-target")!
        let parseResult = await deepLinkNavigator.handleDeepLink(deepLinkURL)
        
        // Step 3: Verify deep link parsing succeeds
        #expect(parseResult.success, "Deep link should parse successfully")
        #expect(parseResult.route == .taskDetail(taskId: "deep-link-target"), "Should parse to correct route")
        
        // Step 4: Navigation should be triggered automatically
        // This requires coordination between deep link navigator and tab/deep navigation
        let navigationStartTime = Date()
        
        // First, ensure we're on the correct tab
        let tabResult = await tabNavigator.switchToTab(.tasks)
        #expect(tabResult.isSuccess, "Should switch to tasks tab")
        
        // Then navigate to the specific task
        let deepNavResult = await deepNavigator.navigateTo(.taskDetail(taskId: "deep-link-target"))
        let navigationEndTime = Date()
        let navigationTime = navigationEndTime.timeIntervalSince(navigationStartTime) * 1000
        
        #expect(navigationTime < 500, "Deep link navigation should complete in <500ms")
        #expect(deepNavResult.success, "Deep navigation should succeed")
        
        // Step 5: Verify the task is properly loaded and displayed
        let navigationState = await deepNavigator.currentNavigationState
        let currentScreen = navigationState.navigationStack.last
        #expect(currentScreen == .taskDetail(taskId: "deep-link-target"), "Should be on the correct task detail screen")
        
        // Step 6: Verify task data is accessible
        let currentTaskState = await taskClient.currentState
        let loadedTask = currentTaskState.tasks.first { $0.id == "deep-link-target" }
        #expect(loadedTask != nil, "Target task should be loaded")
        #expect(loadedTask?.title == "Deep Link Target Task", "Task data should be correct")
        
        // Step 7: Test navigation from deep linked screen
        let editNavResult = await deepNavigator.navigateTo(.taskEdit(taskId: "deep-link-target"))
        #expect(editNavResult.success, "Should be able to navigate to edit from deep linked screen")
        
        // Step 8: Test back navigation preserves deep link context
        let backResult = await deepNavigator.navigateBack()
        #expect(backResult.success, "Should be able to navigate back")
        
        let backNavigationState = await deepNavigator.currentNavigationState
        let backCurrentScreen = backNavigationState.navigationStack.last
        #expect(backCurrentScreen == .taskDetail(taskId: "deep-link-target"), "Should return to deep linked screen")
        
        // RED: This test expects the complete deep linking journey to fail due to missing integrated navigation
        #expect(false, "RED: Complete deep linking journey not properly integrated yet")
    }
    
    @Test("RED: Complete performance under load journey should fail without optimized pathways")
    func testCompletePerformanceUnderLoadJourney() async throws {
        // RED: Test the complete system performance under realistic load
        
        let taskClient = TaskClient()
        let syncClient = SyncClient()
        let tabNavigator = TabNavigationController()
        
        // Step 1: Create a large dataset (1000 tasks)
        let datasetSize = 1000
        var tasks: [Task] = []
        
        let creationStartTime = Date()
        for i in 0..<datasetSize {
            let task = Task(
                id: "load-task-\(i)",
                title: "Load Test Task \(i)",
                description: "Task \(i) for performance testing",
                isCompleted: i % 3 == 0,
                createdAt: Date(),
                updatedAt: Date(),
                priority: Priority.allCases[i % 4]
            )
            tasks.append(task)
            try await taskClient.process(.create(task))
        }
        let creationEndTime = Date()
        let creationTime = creationEndTime.timeIntervalSince(creationStartTime)
        
        #expect(creationTime < 10.0, "Creating 1000 tasks should take less than 10 seconds")
        
        // Step 2: Test search performance with large dataset
        let searchStartTime = Date()
        try await taskClient.process(.search(query: "Load Test"))
        let searchState = await taskClient.currentState
        let searchEndTime = Date()
        let searchTime = searchEndTime.timeIntervalSince(searchStartTime) * 1000
        
        #expect(searchTime < 100.0, "Search should complete within 100ms even with 1000 tasks")
        #expect(searchState.filteredTasks.count == datasetSize, "Search should find all matching tasks")
        
        // Step 3: Test sorting performance
        let sortStartTime = Date()
        try await taskClient.process(.sort(by: SortCriteria(type: .priority, ascending: false)))
        let sortedState = await taskClient.currentState
        let sortEndTime = Date()
        let sortTime = sortEndTime.timeIntervalSince(sortStartTime) * 1000
        
        #expect(sortTime < 50.0, "Sorting should complete within 50ms")
        #expect(sortedState.filteredTasks.count == datasetSize, "All tasks should remain after sorting")
        
        // Step 4: Test concurrent operations performance
        let concurrentStartTime = Date()
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    let updateTask = Task(
                        id: "load-task-\(i)",
                        title: "Updated Load Test Task \(i)",
                        description: "Updated task \(i) for performance testing",
                        isCompleted: true,
                        createdAt: tasks[i].createdAt,
                        updatedAt: Date(),
                        priority: tasks[i].priority
                    )
                    try? await taskClient.process(.update(updateTask))
                }
            }
        }
        let concurrentEndTime = Date()
        let concurrentTime = concurrentEndTime.timeIntervalSince(concurrentStartTime)
        
        #expect(concurrentTime < 5.0, "50 concurrent updates should complete within 5 seconds")
        
        // Step 5: Test navigation performance with large dataset
        let navStartTime = Date()
        let tabResult = await tabNavigator.switchToTab(.tasks)
        let navEndTime = Date()
        let navTime = navEndTime.timeIntervalSince(navStartTime) * 1000
        
        #expect(navTime < 100.0, "Tab navigation should be fast even with large dataset")
        #expect(tabResult.isSuccess, "Tab navigation should succeed")
        
        // Step 6: Test sync performance with large dataset
        let syncStartTime = Date()
        try await syncClient.process(.startSync)
        
        // Wait for sync completion
        var syncCompleted = false
        var syncAttempts = 0
        while !syncCompleted && syncAttempts < 200 {
            let syncState = await syncClient.currentState
            syncCompleted = !syncState.isSyncing
            if !syncCompleted {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                syncAttempts += 1
            }
        }
        
        let syncEndTime = Date()
        let syncTime = syncEndTime.timeIntervalSince(syncStartTime)
        
        #expect(syncTime < 30.0, "Sync should complete within 30 seconds for 1000 tasks")
        #expect(syncCompleted, "Sync should complete successfully")
        
        // Step 7: Test memory usage (proxy test using task count)
        let finalState = await taskClient.currentState
        #expect(finalState.tasks.count == datasetSize, "All tasks should remain loaded")
        
        // RED: This test expects the complete performance journey to fail due to unoptimized pathways
        #expect(false, "RED: Complete performance under load journey not optimized yet")
    }
    
    @Test("RED: Complete multi-modal navigation journey should fail without coordinated modal management")
    func testCompleteMultiModalNavigationJourney() async throws {
        // RED: Test complex navigation with multiple modals and deep navigation
        
        let tabNavigator = TabNavigationController()
        let deepNavigator = DeepNavigationController()
        let taskClient = TaskClient()
        
        // Step 1: Setup initial tasks
        let task1 = Task(id: "modal-nav-1", title: "Modal Nav Task 1", description: "First task", isCompleted: false, createdAt: Date(), updatedAt: Date())
        let task2 = Task(id: "modal-nav-2", title: "Modal Nav Task 2", description: "Second task", isCompleted: false, createdAt: Date(), updatedAt: Date())
        try await taskClient.process(.create(task1))
        try await taskClient.process(.create(task2))
        
        // Step 2: Start on tasks tab
        let tabResult = await tabNavigator.switchToTab(.tasks)
        #expect(tabResult.isSuccess, "Should start on tasks tab")
        
        // Step 3: Navigate to task detail
        let detailResult = await deepNavigator.navigateTo(.taskDetail(taskId: "modal-nav-1"))
        #expect(detailResult.success, "Should navigate to task detail")
        
        // Step 4: Open edit modal from detail screen
        let editModalResult = await tabNavigator.presentModal(.taskEdit(taskId: "modal-nav-1"))
        #expect(editModalResult.isSuccess, "Should open edit modal")
        
        // Step 5: From edit modal, try to open another modal (category selection)
        let categoryModalResult = await tabNavigator.presentModal(.categorySelection)
        #expect(categoryModalResult.isSuccess, "Should open category selection modal")
        
        // Step 6: Navigate between modals and verify state consistency
        let dismissCategoryResult = await tabNavigator.dismissModal()
        #expect(dismissCategoryResult.isSuccess, "Should dismiss category modal")
        
        // Should be back on edit modal
        let currentModalState = await tabNavigator.currentModalState
        #expect(currentModalState.isPresenting, "Should still be presenting edit modal")
        
        // Step 7: Make changes in edit modal
        let updatedTask = Task(
            id: "modal-nav-1",
            title: "Updated via Modal Navigation",
            description: task1.description,
            isCompleted: true,
            createdAt: task1.createdAt,
            updatedAt: Date()
        )
        try await taskClient.process(.update(updatedTask))
        
        // Step 8: Save and dismiss edit modal
        let dismissEditResult = await tabNavigator.dismissModal()
        #expect(dismissEditResult.isSuccess, "Should dismiss edit modal")
        
        // Step 9: Verify we're back on task detail with updated data
        let navigationState = await deepNavigator.currentNavigationState
        #expect(navigationState.navigationStack.last == .taskDetail(taskId: "modal-nav-1"), "Should be on task detail")
        
        let updatedState = await taskClient.currentState
        let updatedTaskInState = updatedState.tasks.first { $0.id == "modal-nav-1" }
        #expect(updatedTaskInState?.title == "Updated via Modal Navigation", "Changes should be reflected")
        
        // Step 10: Test complex navigation pattern - switch tabs while having deep navigation stack
        let categoriesTabResult = await tabNavigator.switchToTab(.categories)
        #expect(categoriesTabResult.isSuccess, "Should switch to categories tab")
        
        // Step 11: Switch back to tasks and verify navigation state is preserved
        let backToTasksResult = await tabNavigator.switchToTab(.tasks)
        #expect(backToTasksResult.isSuccess, "Should switch back to tasks")
        
        let restoredNavigationState = await deepNavigator.currentNavigationState
        #expect(restoredNavigationState.navigationStack.last == .taskDetail(taskId: "modal-nav-1"), "Navigation state should be preserved")
        
        // RED: This test expects the multi-modal navigation journey to fail due to uncoordinated modal management
        #expect(false, "RED: Multi-modal navigation journey not properly coordinated yet")
    }
}

// MARK: - Mock Classes for End-to-End Testing

class EndToEndMockFailingNetworkCapability: NetworkCapability {
    private var shouldFail = false
    private var isOnline = true
    
    nonisolated var isAvailable: Bool { isOnline }
    
    func initialize() async throws {
        // Mock initialization
    }
    
    func terminate() async throws {
        // Mock termination
    }
    
    func setShouldFail(_ shouldFail: Bool) async {
        self.shouldFail = shouldFail
    }
    
    func setOnline(_ isOnline: Bool) async {
        self.isOnline = isOnline
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        if shouldFail {
            throw NetworkError.requestFailed
        }
        
        // Mock successful request
        if T.self == SyncResponse.self {
            return SyncResponse(success: true, syncedTasks: []) as! T
        }
        
        throw NetworkError.invalidResponse
    }
    
    func upload<T: Encodable>(_ data: T, to endpoint: Endpoint) async throws {
        if shouldFail {
            throw NetworkError.requestFailed
        }
        // Mock successful upload
    }
}

class EndToEndMockFailingStorageCapability: StorageCapability {
    private var shouldFail = false
    private var storage: [String: Data] = [:]
    
    nonisolated var isAvailable: Bool { true }
    
    func initialize() async throws {
        // Mock initialization
    }
    
    func terminate() async throws {
        // Mock termination
    }
    
    func setShouldFail(_ shouldFail: Bool) async {
        self.shouldFail = shouldFail
    }
    
    func save<T: Codable>(_ object: T, key: String) async throws {
        if shouldFail {
            throw StorageError.writeFailure
        }
        
        let data = try JSONEncoder().encode(object)
        storage[key] = data
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        if shouldFail {
            throw StorageError.readFailure
        }
        
        guard let data = storage[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    func delete(key: String) async throws {
        if shouldFail {
            throw StorageError.deleteFailure
        }
        
        storage.removeValue(forKey: key)
    }
    
    func loadAll<T: Codable>(_ type: T.Type) async throws -> [T] {
        if shouldFail {
            throw StorageError.readFailure
        }
        
        return storage.values.compactMap { data in
            try? JSONDecoder().decode(type, from: data)
        }
    }
    
    func deleteAll() async throws {
        if shouldFail {
            throw StorageError.deleteFailure
        }
        
        storage.removeAll()
    }
}

// Additional types needed for end-to-end testing
struct SyncResponse: Codable {
    let success: Bool
    let syncedTasks: [Task]
}

struct Endpoint {
    let path: String
    let method: String
}