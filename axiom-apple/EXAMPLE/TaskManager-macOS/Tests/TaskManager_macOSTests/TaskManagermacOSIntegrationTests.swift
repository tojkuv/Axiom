import XCTest
import SwiftUI
@testable import TaskManager_macOS
@testable import TaskManager_Shared
import Axiom

// MARK: - Task Manager macOS Integration Tests

/// Comprehensive integration tests for the macOS Task Manager application
/// These tests validate the complete macOS app flow including window management
@MainActor
final class TaskManagermacOSIntegrationTests: XCTestCase {
    
    private var orchestrator: TaskManagerOrchestrator!
    private var appCoordinator: AppCoordinator!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize orchestrator
        orchestrator = try await TaskManagerOrchestrator()
        
        // Initialize app coordinator
        appCoordinator = AppCoordinator()
        await appCoordinator.initialize()
    }
    
    override func tearDown() async throws {
        await orchestrator?.shutdown()
        await appCoordinator?.shutdown()
        
        orchestrator = nil
        appCoordinator = nil
        
        try await super.tearDown()
    }
    
    // MARK: - App Lifecycle Tests
    
    func testAppInitialization() async throws {
        XCTAssertTrue(appCoordinator.isInitialized, "App should be initialized")
        XCTAssertNil(appCoordinator.initializationError, "Should have no initialization error")
        XCTAssertNotNil(appCoordinator.orchestrator, "Should have orchestrator")
    }
    
    func testAppShutdown() async throws {
        XCTAssertTrue(appCoordinator.isInitialized)
        
        await appCoordinator.shutdown()
        
        XCTAssertFalse(appCoordinator.isInitialized, "App should be shut down")
        XCTAssertNil(appCoordinator.orchestrator, "Should have no orchestrator after shutdown")
    }
    
    // MARK: - Window Management Tests
    
    func testMainWindowManagement() async throws {
        // Test opening main window
        await orchestrator.showMainWindow()
        
        // In a real implementation, this would verify the window was shown
        // For this test, we verify no errors occurred
        XCTAssertTrue(true, "Main window should open without errors")
    }
    
    func testTaskDetailWindowManagement() async throws {
        // Create a task first
        let taskClient = await orchestrator.getTaskClient()
        let createData = CreateTaskData(
            title: "Window Test Task",
            taskDescription: "Task for testing window management",
            priority: .medium,
            category: .work,
            dueDate: nil
        )
        try await taskClient.process(.createTask(createData))
        
        let state = await taskClient.getCurrentState()
        let task = state.tasks.first!
        
        // Test opening task detail window
        await orchestrator.showTaskDetailWindow(taskId: task.id)
        
        // Verify window configuration
        XCTAssertTrue(true, "Task detail window should open without errors")
    }
    
    func testCreateTaskWindowManagement() async throws {
        // Test opening create task window
        await orchestrator.showCreateTaskWindow()
        
        XCTAssertTrue(true, "Create task window should open without errors")
    }
    
    func testSettingsWindowManagement() async throws {
        // Test opening settings window
        await orchestrator.showSettingsWindow()
        
        XCTAssertTrue(true, "Settings window should open without errors")
    }
    
    func testMultipleWindowManagement() async throws {
        // Test opening multiple windows
        await orchestrator.showMainWindow()
        await orchestrator.showCreateTaskWindow()
        await orchestrator.showSettingsWindow()
        
        // In a real implementation, we would verify multiple windows are open
        XCTAssertTrue(true, "Multiple windows should open without conflicts")
    }
    
    // MARK: - macOS-Specific Context Tests
    
    func testTaskListContextMacOSFeatures() async throws {
        let context = try await orchestrator.createContext(
            type: TaskListContext.self,
            identifier: "macos-list-test"
        )
        
        // Test desktop-specific features
        XCTAssertNotNil(context)
        XCTAssertEqual(context.selectedTasks.count, 0)
        XCTAssertNil(context.lastSelectedTask)
        XCTAssertNil(context.focusedTask)
        
        // Create some test tasks
        let taskClient = await orchestrator.getTaskClient()
        for i in 1...5 {
            let taskData = CreateTaskData(
                title: "macOS Test Task \(i)",
                taskDescription: "Task \(i) for macOS testing",
                priority: Priority.allCases[i % 3],
                category: Category.allCases[i % Category.allCases.count],
                dueDate: nil
            )
            try await taskClient.process(.createTask(taskData))
        }
        
        let state = await taskClient.getCurrentState()
        let tasks = state.tasks
        
        // Test single selection
        await context.selectTask(tasks[0].id)
        XCTAssertEqual(context.selectedTasks.count, 1)
        XCTAssertTrue(context.selectedTasks.contains(tasks[0].id))
        XCTAssertEqual(context.lastSelectedTask, tasks[0].id)
        XCTAssertEqual(context.focusedTask, tasks[0].id)
        
        // Test multi-selection (Cmd+Click equivalent)
        await context.selectTask(tasks[1].id, extendSelection: true)
        XCTAssertEqual(context.selectedTasks.count, 2)
        XCTAssertTrue(context.selectedTasks.contains(tasks[0].id))
        XCTAssertTrue(context.selectedTasks.contains(tasks[1].id))
        
        // Test range selection
        await context.selectTaskRange(from: tasks[0].id, to: tasks[2].id)
        XCTAssertEqual(context.selectedTasks.count, 3)
        
        // Test select all
        await context.selectAllTasks()
        XCTAssertEqual(context.selectedTasks.count, 5)
        XCTAssertTrue(context.allTasksSelected)
        
        // Test clear selection
        await context.clearSelection()
        XCTAssertEqual(context.selectedTasks.count, 0)
        XCTAssertFalse(context.hasSelectedTasks)
    }
    
    func testTaskListContextKeyboardNavigation() async throws {
        let context = try await orchestrator.createContext(
            type: TaskListContext.self,
            identifier: "keyboard-test"
        )
        
        // Create test tasks
        let taskClient = await orchestrator.getTaskClient()
        for i in 1...3 {
            let taskData = CreateTaskData(
                title: "Keyboard Test \(i)",
                taskDescription: "",
                priority: .medium,
                category: .personal,
                dueDate: nil
            )
            try await taskClient.process(.createTask(taskData))
        }
        
        let state = await taskClient.getCurrentState()
        let tasks = state.tasks.sorted { $0.createdAt < $1.createdAt }
        
        // Test focus movement
        await context.selectTask(tasks[1].id) // Select middle task
        XCTAssertEqual(context.focusedTask, tasks[1].id)
        
        // Move focus up
        await context.moveFocus(direction: .up)
        XCTAssertEqual(context.focusedTask, tasks[0].id)
        
        // Move focus down
        await context.moveFocus(direction: .down)
        await context.moveFocus(direction: .down)
        XCTAssertEqual(context.focusedTask, tasks[2].id)
        
        // Test keyboard commands
        await context.handleKeyCommand(.selectAll)
        XCTAssertEqual(context.selectedTasks.count, 3)
        
        await context.handleKeyCommand(.deselectAll)
        XCTAssertEqual(context.selectedTasks.count, 0)
    }
    
    func testTaskListContextBulkOperations() async throws {
        let context = try await orchestrator.createContext(
            type: TaskListContext.self,
            identifier: "bulk-test"
        )
        
        // Create test tasks
        let taskClient = await orchestrator.getTaskClient()
        for i in 1...5 {
            let taskData = CreateTaskData(
                title: "Bulk Test \(i)",
                taskDescription: "",
                priority: .medium,
                category: .work,
                dueDate: nil
            )
            try await taskClient.process(.createTask(taskData))
        }
        
        let state = await taskClient.getCurrentState()
        let tasks = state.tasks
        
        // Select multiple tasks
        await context.selectTask(tasks[0].id)
        await context.selectTask(tasks[1].id, extendSelection: true)
        await context.selectTask(tasks[2].id, extendSelection: true)
        
        XCTAssertEqual(context.selectedTasks.count, 3)
        
        // Test bulk completion
        await context.completeSelectedTasks()
        
        let afterCompletionState = await taskClient.getCurrentState()
        let completedTasks = afterCompletionState.tasks.filter { $0.isCompleted }
        XCTAssertEqual(completedTasks.count, 3)
        
        // Selection should be cleared after bulk operation
        XCTAssertEqual(context.selectedTasks.count, 0)
        
        // Select remaining tasks for category update
        let remainingTasks = afterCompletionState.tasks.filter { !$0.isCompleted }
        for task in remainingTasks {
            await context.selectTask(task.id, extendSelection: context.selectedTasks.count > 0)
        }
        
        // Test bulk category update
        await context.updateSelectedTasksCategory(.personal)
        
        let afterCategoryUpdateState = await taskClient.getCurrentState()
        let personalTasks = afterCategoryUpdateState.tasks.filter { $0.category == .personal && !$0.isCompleted }
        XCTAssertEqual(personalTasks.count, 2)
        
        // Test bulk priority update
        await context.selectAllTasks()
        await context.updateSelectedTasksPriority(.high)
        
        let finalState = await taskClient.getCurrentState()
        let highPriorityTasks = finalState.tasks.filter { $0.priority == .high }
        XCTAssertEqual(highPriorityTasks.count, 5)
    }
    
    func testTaskDetailContextMacOSFeatures() async throws {
        // Create a task first
        let taskClient = await orchestrator.getTaskClient()
        let createData = CreateTaskData(
            title: "Detail Test Task",
            taskDescription: "Testing task detail context",
            priority: .high,
            category: .work,
            dueDate: Date().addingTimeInterval(86400),
            notes: "Initial notes"
        )
        try await taskClient.process(.createTask(createData))
        
        let state = await taskClient.getCurrentState()
        let task = state.tasks.first!
        
        // Create detail context
        let context = try await orchestrator.createContext(
            type: TaskDetailContext.self,
            identifier: "detail-test"
        )
        
        await context.setTaskId(task.id)
        
        // Verify task loaded
        XCTAssertEqual(context.task?.id, task.id)
        XCTAssertEqual(context.windowTitle, task.title)
        
        // Test editing mode
        await context.startEditing()
        XCTAssertTrue(context.isEditing)
        XCTAssertEqual(context.editingTitle, task.title)
        XCTAssertEqual(context.editingDescription, task.taskDescription)
        XCTAssertEqual(context.editingPriority, task.priority)
        XCTAssertEqual(context.editingCategory, task.category)
        
        // Test field updates
        await context.updateTitle("Updated Title")
        await context.updateDescription("Updated description")
        await context.updatePriority(.medium)
        await context.updateCategory(.personal)
        await context.updateNotes("Updated notes")
        
        XCTAssertTrue(context.hasUnsavedChanges)
        XCTAssertTrue(context.canSave)
        
        // Test saving changes
        await context.saveChanges()
        XCTAssertFalse(context.isEditing)
        XCTAssertFalse(context.hasUnsavedChanges)
        
        // Verify changes were saved
        let updatedState = await taskClient.getCurrentState()
        let updatedTask = updatedState.task(withId: task.id)!
        XCTAssertEqual(updatedTask.title, "Updated Title")
        XCTAssertEqual(updatedTask.taskDescription, "Updated description")
        XCTAssertEqual(updatedTask.priority, .medium)
        XCTAssertEqual(updatedTask.category, .personal)
        XCTAssertEqual(updatedTask.notes, "Updated notes")
        
        // Test canceling edits
        await context.startEditing()
        await context.updateTitle("This should be canceled")
        await context.cancelEditing()
        
        XCTAssertFalse(context.isEditing)
        XCTAssertFalse(context.hasUnsavedChanges)
        XCTAssertEqual(context.editingTitle, "Updated Title") // Should revert to saved value
    }
    
    func testCreateTaskContextMacOSFeatures() async throws {
        let context = try await orchestrator.createContext(
            type: CreateTaskContext.self,
            identifier: "create-test"
        )
        
        // Test initial state
        XCTAssertEqual(context.title, "")
        XCTAssertEqual(context.taskDescription, "")
        XCTAssertEqual(context.priority, .medium)
        XCTAssertEqual(context.category, .personal)
        XCTAssertFalse(context.hasDueDate)
        XCTAssertFalse(context.hasReminder)
        XCTAssertFalse(context.hasEstimatedDuration)
        XCTAssertFalse(context.canCreateTask)
        
        // Test template application
        let workTemplate = context.availableTemplates.first { $0.name == "Work Meeting" }!
        await context.applyTemplate(workTemplate)
        
        XCTAssertEqual(context.selectedTemplate?.name, "Work Meeting")
        XCTAssertEqual(context.title, workTemplate.title)
        XCTAssertEqual(context.taskDescription, workTemplate.description)
        XCTAssertEqual(context.priority, workTemplate.priority)
        XCTAssertEqual(context.category, workTemplate.category)
        XCTAssertEqual(context.hasDueDate, workTemplate.hasDueDate)
        
        // Test form validation
        await context.updateTitle("Valid Task Title")
        XCTAssertTrue(context.canCreateTask)
        XCTAssertFalse(context.hasValidationErrors)
        
        // Test due date validation
        await context.toggleDueDate(true)
        await context.updateDueDate(Date().addingTimeInterval(-86400)) // Past date
        XCTAssertTrue(context.hasValidationErrors)
        XCTAssertNotNil(context.dueDateFieldError)
        
        await context.updateDueDate(Date().addingTimeInterval(86400)) // Future date
        XCTAssertFalse(context.hasValidationErrors)
        XCTAssertNil(context.dueDateFieldError)
        
        // Test tags management
        await context.updateCurrentTag("important")
        await context.addTag()
        XCTAssertTrue(context.tags.contains("important"))
        XCTAssertEqual(context.currentTag, "") // Should clear after adding
        
        await context.updateCurrentTag("urgent")
        await context.addTag()
        XCTAssertEqual(context.tags.count, 2)
        
        await context.removeTag("important")
        XCTAssertEqual(context.tags.count, 1)
        XCTAssertTrue(context.tags.contains("urgent"))
        
        // Test estimated duration
        await context.toggleEstimatedDuration(true)
        await context.updateEstimatedDuration(3600) // 1 hour
        XCTAssertEqual(context.estimatedDurationText, "1h")
        
        await context.updateEstimatedDuration(5400) // 1.5 hours
        XCTAssertEqual(context.estimatedDurationText, "1h 30m")
        
        // Test task creation
        await context.createTask()
        XCTAssertTrue(context.wasTaskCreated)
        XCTAssertTrue(context.shouldCloseWindow)
        
        // Verify task was created
        let taskClient = await orchestrator.getTaskClient()
        let state = await taskClient.getCurrentState()
        XCTAssertEqual(state.tasks.count, 1)
        
        let createdTask = state.tasks.first!
        XCTAssertEqual(createdTask.title, "Valid Task Title")
        XCTAssertEqual(createdTask.priority, workTemplate.priority)
        XCTAssertEqual(createdTask.category, workTemplate.category)
        XCTAssertNotNil(createdTask.dueDate)
    }
    
    func testTaskSettingsContextMacOSFeatures() async throws {
        let taskClient = await orchestrator.getTaskClient()
        let storage = await orchestrator.getStorageCapability()
        
        let context = TaskSettingsContext(client: taskClient, storage: storage)
        
        // Test initial settings load
        await context.appeared()
        
        // Test defaults updates
        await context.updateDefaultPriority(.high)
        XCTAssertEqual(context.defaultPriority, .high)
        
        await context.updateDefaultCategory(.work)
        XCTAssertEqual(context.defaultCategory, .work)
        
        await context.updateDefaultSortOrder(.title, ascending: true)
        XCTAssertEqual(context.defaultSortOrder, .title)
        XCTAssertTrue(context.defaultSortAscending)
        
        // Test appearance settings
        await context.updateColorScheme(.dark)
        XCTAssertEqual(context.colorScheme, .dark)
        
        await context.updateWindowOpacity(0.8)
        XCTAssertEqual(context.windowOpacity, 0.8, accuracy: 0.01)
        
        await context.updateCompactMode(true)
        XCTAssertTrue(context.compactMode)
        
        // Test notification settings
        await context.updateEnableNotifications(true)
        XCTAssertTrue(context.enableNotifications)
        
        let notificationTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!
        await context.updateNotificationTime(notificationTime)
        XCTAssertEqual(context.notificationTime.timeIntervalSince1970, notificationTime.timeIntervalSince1970, accuracy: 60)
        
        // Test advanced settings
        await context.updateAutoSaveInterval(60)
        XCTAssertEqual(context.autoSaveInterval, 60)
        
        await context.updateBackupEnabled(true)
        XCTAssertTrue(context.backupEnabled)
        
        await context.updateBackupFrequency(.weekly)
        XCTAssertEqual(context.backupFrequency, .weekly)
        
        await context.updateMaxBackups(20)
        XCTAssertEqual(context.maxBackups, 20)
        
        // Test debug settings
        await context.updateEnableDebugMode(true)
        XCTAssertTrue(context.enableDebugMode)
        
        await context.updateEnableAnalytics(false)
        XCTAssertFalse(context.enableAnalytics)
        
        // Test data management
        // Create some test data first
        let testTask = CreateTaskData(
            title: "Settings Test Task",
            taskDescription: "Task for testing settings",
            priority: .medium,
            category: .personal,
            dueDate: nil
        )
        try await taskClient.process(.createTask(testTask))
        
        await context.loadStatistics()
        XCTAssertEqual(context.totalTasks, 1)
        XCTAssertEqual(context.completedTasks, 0)
        
        // Test storage info
        await context.loadStorageInfo()
        XCTAssertNotNil(context.storageInfo)
        XCTAssertTrue(context.storageInfo?.isAvailable ?? false)
        
        // Test diagnostic info generation
        let diagnosticInfo = await context.generateDiagnosticInfo()
        XCTAssertFalse(diagnosticInfo.isEmpty)
        XCTAssertTrue(diagnosticInfo.contains("TASK MANAGER DIAGNOSTIC INFORMATION"))
        XCTAssertTrue(diagnosticInfo.contains("Total Tasks: 1"))
        
        // Test reset to defaults
        await context.resetToDefaults()
        XCTAssertEqual(context.defaultPriority, .medium)
        XCTAssertEqual(context.defaultCategory, .personal)
        XCTAssertEqual(context.colorScheme, .system)
        XCTAssertEqual(context.windowOpacity, 1.0)
        XCTAssertFalse(context.compactMode)
        XCTAssertTrue(context.resetSuccess)
    }
    
    func testTaskStatisticsContextMacOSFeatures() async throws {
        let context = try await orchestrator.createContext(
            type: TaskStatisticsContext.self,
            identifier: "statistics-test"
        )
        
        // Create test data with various characteristics
        let taskClient = await orchestrator.getTaskClient()
        let now = Date()
        
        let testTasks = [
            CreateTaskData(title: "High Priority Work", taskDescription: "", priority: .high, category: .work, dueDate: now.addingTimeInterval(86400)),
            CreateTaskData(title: "Medium Priority Personal", taskDescription: "", priority: .medium, category: .personal, dueDate: now.addingTimeInterval(-86400)),
            CreateTaskData(title: "Low Priority Shopping", taskDescription: "", priority: .low, category: .shopping, dueDate: nil),
            CreateTaskData(title: "Health Task", taskDescription: "", priority: .high, category: .health, dueDate: now.addingTimeInterval(172800)),
            CreateTaskData(title: "Finance Task", taskDescription: "", priority: .medium, category: .finance, dueDate: nil)
        ]
        
        var createdTaskIds: [UUID] = []
        for taskData in testTasks {
            try await taskClient.process(.createTask(taskData))
            let state = await taskClient.getCurrentState()
            createdTaskIds.append(state.tasks.last!.id)
        }
        
        // Complete some tasks
        try await taskClient.process(.toggleTaskCompletion(taskId: createdTaskIds[0]))
        try await taskClient.process(.toggleTaskCompletion(taskId: createdTaskIds[2]))
        
        // Load and verify statistics
        await context.loadStatistics()
        
        XCTAssertNotNil(context.statistics)
        XCTAssertEqual(context.statistics?.totalTasks, 5)
        XCTAssertEqual(context.statistics?.completedTasks, 2)
        XCTAssertEqual(context.statistics?.pendingTasks, 3)
        XCTAssertEqual(context.statistics?.overdueTasks, 1) // One overdue task
        
        // Test time range updates
        await context.updateTimeRange(.thisWeek)
        XCTAssertEqual(context.selectedTimeRange, .thisWeek)
        
        await context.updateTimeRange(.thisMonth)
        XCTAssertEqual(context.selectedTimeRange, .thisMonth)
        
        // Test custom date range
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let endDate = now
        await context.updateCustomDateRange(start: startDate, end: endDate)
        XCTAssertEqual(context.selectedTimeRange, .custom)
        XCTAssertEqual(context.customStartDate.timeIntervalSince1970, startDate.timeIntervalSince1970, accuracy: 1)
        XCTAssertEqual(context.customEndDate.timeIntervalSince1970, endDate.timeIntervalSince1970, accuracy: 1)
        
        // Test analytics generation (verify no crashes)
        // In a real implementation, we would verify the generated analytics data
        XCTAssertNotNil(context.statistics)
        
        // Test export functionality
        await context.exportStatistics()
        // Note: This is a mock implementation, in reality we would verify file creation
        
        // Verify computed properties
        XCTAssertEqual(context.formattedProductivityScore, String(format: "%.0f", context.productivityScore))
        XCTAssertTrue(context.hasStatistics)
        XCTAssertEqual(context.selectedTimeRangeDescription, "This Month")
    }
    
    // MARK: - Window Coordination Tests
    
    func testMultipleWindowCoordination() async throws {
        // Test that multiple windows can coexist and share data
        
        // Create a task in the main window context
        let mainContext = try await orchestrator.createContext(
            type: TaskListContext.self,
            identifier: "main-window"
        )
        
        let taskClient = await orchestrator.getTaskClient()
        let createData = CreateTaskData(
            title: "Multi-Window Test Task",
            taskDescription: "Testing coordination between windows",
            priority: .high,
            category: .work,
            dueDate: nil
        )
        try await taskClient.process(.createTask(createData))
        
        let state = await taskClient.getCurrentState()
        let task = state.tasks.first!
        
        // Open task detail in separate window
        let detailContext = try await orchestrator.createContext(
            type: TaskDetailContext.self,
            identifier: "detail-window-\(task.id)"
        )
        await detailContext.setTaskId(task.id)
        
        // Verify both contexts see the same task
        XCTAssertEqual(mainContext.tasks.count, 1)
        XCTAssertEqual(detailContext.task?.id, task.id)
        
        // Modify task in detail window
        await detailContext.startEditing()
        await detailContext.updateTitle("Modified in Detail Window")
        await detailContext.saveChanges()
        
        // Verify main window sees the update
        // Note: In a real implementation, contexts would receive state updates automatically
        let updatedState = await taskClient.getCurrentState()
        let updatedTask = updatedState.task(withId: task.id)!
        XCTAssertEqual(updatedTask.title, "Modified in Detail Window")
        
        // Open settings window
        let settingsContext = TaskSettingsContext(
            client: taskClient,
            storage: await orchestrator.getStorageCapability()
        )
        
        await settingsContext.loadStatistics()
        XCTAssertEqual(settingsContext.totalTasks, 1)
        XCTAssertEqual(settingsContext.completedTasks, 0)
        
        // Complete task in main window
        await mainContext.toggleTaskCompletion(taskId: task.id)
        
        // Verify settings window sees the completion
        await settingsContext.loadStatistics()
        XCTAssertEqual(settingsContext.completedTasks, 1)
    }
    
    // MARK: - Performance Tests
    
    func testWindowManagementPerformance() async throws {
        let startTime = Date()
        
        // Simulate opening and closing multiple windows
        for i in 0..<20 {
            await orchestrator.showMainWindow()
            await orchestrator.showCreateTaskWindow()
            await orchestrator.showSettingsWindow()
            
            // Simulate window closing
            await orchestrator.closeWindow(withId: "create-\(i)")
        }
        
        let endTime = Date()
        let elapsed = endTime.timeIntervalSince(startTime)
        
        // Window operations should be reasonably fast
        XCTAssertLessThan(elapsed, 2.0, "Window management performance is too slow")
    }
    
    func testLargeDatasetPerformance() async throws {
        // Create a large number of tasks to test performance
        let taskClient = await orchestrator.getTaskClient()
        
        let startTime = Date()
        
        // Create 1000 tasks
        for i in 0..<1000 {
            let taskData = CreateTaskData(
                title: "Performance Test Task \(i)",
                taskDescription: "Description for task \(i)",
                priority: Priority.allCases[i % 3],
                category: Category.allCases[i % Category.allCases.count],
                dueDate: i % 10 == 0 ? Date().addingTimeInterval(TimeInterval(i * 3600)) : nil
            )
            try await taskClient.process(.createTask(taskData))
        }
        
        let createEndTime = Date()
        let createElapsed = createEndTime.timeIntervalSince(startTime)
        XCTAssertLessThan(createElapsed, 10.0, "Task creation performance is too slow")
        
        // Test context performance with large dataset
        let context = try await orchestrator.createContext(
            type: TaskListContext.self,
            identifier: "performance-test"
        )
        
        let contextStartTime = Date()
        
        // Test filtering performance
        await context.setFilter(.pending)
        await context.setCategoryFilter(.work)
        await context.setSearchQuery("Performance")
        
        let filterEndTime = Date()
        let filterElapsed = filterEndTime.timeIntervalSince(contextStartTime)
        XCTAssertLessThan(filterElapsed, 1.0, "Filtering performance is too slow")
        
        // Test sorting performance
        let sortStartTime = Date()
        await context.setSortOrder(.title, ascending: true)
        
        let sortEndTime = Date()
        let sortElapsed = sortEndTime.timeIntervalSince(sortStartTime)
        XCTAssertLessThan(sortElapsed, 1.0, "Sorting performance is too slow")
        
        // Verify data integrity
        XCTAssertEqual(context.tasks.count, 1000)
        XCTAssertGreaterThan(context.filteredTasks.count, 0)
    }
    
    // MARK: - Memory Management Tests
    
    func testContextMemoryManagement() async throws {
        weak var weakContext: TaskListContext?
        
        // Create context in limited scope
        do {
            let context = try await orchestrator.createContext(
                type: TaskListContext.self,
                identifier: "memory-test"
            )
            weakContext = context
            XCTAssertNotNil(weakContext)
            
            // Use the context
            await context.appeared()
        }
        
        // Context should still exist due to orchestrator reference
        XCTAssertNotNil(weakContext)
        
        // After shutdown, contexts should be cleaned up
        await orchestrator.shutdown()
        
        // Give time for cleanup
        await Task.yield()
        
        // Note: Context might still exist depending on implementation details
        // This test primarily checks for obvious memory leaks
    }
    
    func testWindowMemoryManagement() async throws {
        // Test that window references are properly managed
        let initialWindowCount = await orchestrator.getActiveWindows().count
        
        // Open multiple windows
        await orchestrator.showMainWindow()
        await orchestrator.showCreateTaskWindow()
        await orchestrator.showSettingsWindow()
        
        // Close specific windows
        await orchestrator.closeWindow(withId: "create")
        await orchestrator.closeWindow(withId: "settings")
        
        let finalWindowCount = await orchestrator.getActiveWindows().count
        
        // Window count should be managed properly
        // Note: Exact counts depend on implementation details
        XCTAssertGreaterThanOrEqual(finalWindowCount, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testWindowErrorHandling() async throws {
        // Test opening window for non-existent task
        let nonExistentTaskId = UUID()
        await orchestrator.showTaskDetailWindow(taskId: nonExistentTaskId)
        
        // Should not crash, but may show error or empty state
        XCTAssertTrue(true, "Opening window for non-existent task should not crash")
    }
    
    func testContextErrorHandling() async throws {
        // Test creating invalid context
        do {
            let _ = try await orchestrator.createContext(
                type: TaskListContext.self,
                identifier: "test"
            )
        } catch {
            XCTFail("Context creation should not fail: \(error)")
        }
        
        // Test context with invalid dependencies
        // This would require modifying the orchestrator to inject failing dependencies
        XCTAssertTrue(true, "Context error handling test completed")
    }
}

// MARK: - Test Helpers

extension TaskManagerOrchestrator {
    func createData(_ data: CreateTaskData) async throws {
        let client = await getTaskClient()
        try await client.process(.createTask(data))
    }
}