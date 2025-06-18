import Foundation
import SwiftUI
import Axiom

// Import shared Task Manager components
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared

// MARK: - Task List Context (iOS)

/// Context for the task list view on iOS
@MainActor
public final class TaskListContext: AxiomClientObservingContext<TaskClient> {
    
    // MARK: - Published Properties
    @Published public private(set) var tasks: [Task] = []
    @Published public private(set) var filteredTasks: [Task] = []
    @Published public private(set) var selectedFilter: Task.Filter = .all
    @Published public private(set) var selectedCategory: Category? = nil
    @Published public private(set) var searchQuery: String = ""
    @Published public private(set) var sortOrder: Task.SortOrder = .createdDate
    @Published public private(set) var isAscending: Bool = false
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var error: String? = nil
    
    // Selection state
    @Published public private(set) var selectedTasks: Set<UUID> = []
    @Published public private(set) var isSelectionMode: Bool = false
    
    // Statistics
    @Published public private(set) var statistics: TaskStatistics = TaskStatistics(
        totalTasks: 0, completedTasks: 0, pendingTasks: 0, overdueTasks: 0,
        dueTodayTasks: 0, dueThisWeekTasks: 0, filteredTasksCount: 0,
        tasksByCategory: [:], tasksByPriority: [:]
    )
    
    // MARK: - Initialization
    
    public required init() {
        fatalError("Use init(client:) instead")
    }
    
    public init(client: TaskClient) {
        super.init(client: client)
    }
    
    // MARK: - Lifecycle
    
    public override func appeared() async {
        await super.appeared()
        await loadTasks()
    }
    
    public override func handleStateUpdate(_ state: TaskManagerState) async {
        await MainActor.run {
            self.tasks = state.tasks
            self.filteredTasks = state.filteredAndSortedTasks
            self.selectedFilter = state.selectedFilter
            self.selectedCategory = state.selectedCategory
            self.searchQuery = state.searchQuery
            self.sortOrder = state.sortOrder
            self.isAscending = state.isAscending
            self.statistics = state.statistics
            self.error = nil
        }
    }
    
    // MARK: - Task Management Actions
    
    public func loadTasks() async {
        await setLoading(true)
        
        do {
            try await client.process(.loadTasks)
        } catch {
            await setError("Failed to load tasks: \(error.localizedDescription)")
        }
        
        await setLoading(false)
    }
    
    public func createTask(title: String, description: String = "", priority: Priority = .medium, category: Category = .personal, dueDate: Date? = nil) async {
        let taskData = CreateTaskData(
            title: title,
            taskDescription: description,
            priority: priority,
            category: category,
            dueDate: dueDate
        )
        
        do {
            try await client.process(.createTask(taskData))
        } catch {
            await setError("Failed to create task: \(error.localizedDescription)")
        }
    }
    
    public func toggleTaskCompletion(taskId: UUID) async {
        do {
            try await client.process(.toggleTaskCompletion(taskId: taskId))
        } catch {
            await setError("Failed to toggle task completion: \(error.localizedDescription)")
        }
    }
    
    public func deleteTask(taskId: UUID) async {
        do {
            try await client.process(.deleteTask(taskId: taskId))
        } catch {
            await setError("Failed to delete task: \(error.localizedDescription)")
        }
    }
    
    public func duplicateTask(taskId: UUID) async {
        do {
            try await client.process(.duplicateTask(taskId: taskId))
        } catch {
            await setError("Failed to duplicate task: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Bulk Operations
    
    public func deleteSelectedTasks() async {
        guard !selectedTasks.isEmpty else { return }
        
        do {
            try await client.process(.deleteTasks(taskIds: Array(selectedTasks)))
            await clearSelection()
        } catch {
            await setError("Failed to delete selected tasks: \(error.localizedDescription)")
        }
    }
    
    public func completeSelectedTasks() async {
        guard !selectedTasks.isEmpty else { return }
        
        do {
            try await client.process(.markTasksAsCompleted(taskIds: Array(selectedTasks)))
            await clearSelection()
        } catch {
            await setError("Failed to complete selected tasks: \(error.localizedDescription)")
        }
    }
    
    public func updateSelectedTasksCategory(_ category: Category) async {
        guard !selectedTasks.isEmpty else { return }
        
        do {
            try await client.process(.updateTasksCategory(taskIds: Array(selectedTasks), category: category))
            await clearSelection()
        } catch {
            await setError("Failed to update category: \(error.localizedDescription)")
        }
    }
    
    public func updateSelectedTasksPriority(_ priority: Priority) async {
        guard !selectedTasks.isEmpty else { return }
        
        do {
            try await client.process(.updateTasksPriority(taskIds: Array(selectedTasks), priority: priority))
            await clearSelection()
        } catch {
            await setError("Failed to update priority: \(error.localizedDescription)")
        }
    }
    
    public func completeAllTasks() async {
        do {
            try await client.process(.completeAllTasks)
        } catch {
            await setError("Failed to complete all tasks: \(error.localizedDescription)")
        }
    }
    
    public func deleteCompletedTasks() async {
        do {
            try await client.process(.deleteCompletedTasks)
        } catch {
            await setError("Failed to delete completed tasks: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Filtering and Sorting
    
    public func setFilter(_ filter: Task.Filter) async {
        do {
            try await client.process(.setFilter(filter))
        } catch {
            await setError("Failed to set filter: \(error.localizedDescription)")
        }
    }
    
    public func setCategoryFilter(_ category: Category?) async {
        do {
            try await client.process(.setCategoryFilter(category))
        } catch {
            await setError("Failed to set category filter: \(error.localizedDescription)")
        }
    }
    
    public func setSearchQuery(_ query: String) async {
        do {
            try await client.process(.setSearchQuery(query))
        } catch {
            await setError("Failed to set search query: \(error.localizedDescription)")
        }
    }
    
    public func setSortOrder(_ sortOrder: Task.SortOrder, ascending: Bool) async {
        do {
            try await client.process(.setSortOrder(sortOrder, ascending: ascending))
        } catch {
            await setError("Failed to set sort order: \(error.localizedDescription)")
        }
    }
    
    public func toggleSortDirection() async {
        do {
            try await client.process(.toggleSortDirection)
        } catch {
            await setError("Failed to toggle sort direction: \(error.localizedDescription)")
        }
    }
    
    public func clearFilters() async {
        do {
            try await client.process(.clearFilters)
        } catch {
            await setError("Failed to clear filters: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Selection Management
    
    public func toggleSelectionMode() async {
        await MainActor.run {
            isSelectionMode.toggle()
            if !isSelectionMode {
                selectedTasks.removeAll()
            }
        }
    }
    
    public func toggleTaskSelection(_ taskId: UUID) async {
        await MainActor.run {
            if selectedTasks.contains(taskId) {
                selectedTasks.remove(taskId)
            } else {
                selectedTasks.insert(taskId)
            }
        }
    }
    
    public func selectAllTasks() async {
        await MainActor.run {
            selectedTasks = Set(filteredTasks.map { $0.id })
        }
    }
    
    public func clearSelection() async {
        await MainActor.run {
            selectedTasks.removeAll()
            isSelectionMode = false
        }
    }
    
    // MARK: - Helper Methods
    
    private func setLoading(_ loading: Bool) async {
        await MainActor.run {
            isLoading = loading
        }
    }
    
    private func setError(_ errorMessage: String) async {
        await MainActor.run {
            error = errorMessage
        }
    }
    
    public func clearError() async {
        await MainActor.run {
            error = nil
        }
    }
    
    // MARK: - Computed Properties
    
    public var hasSelectedTasks: Bool {
        !selectedTasks.isEmpty
    }
    
    public var selectedTasksCount: Int {
        selectedTasks.count
    }
    
    public var canSelectAll: Bool {
        isSelectionMode && selectedTasks.count < filteredTasks.count
    }
    
    public var allTasksSelected: Bool {
        isSelectionMode && !filteredTasks.isEmpty && selectedTasks.count == filteredTasks.count
    }
    
    // MARK: - Task Retrieval
    
    public func task(withId id: UUID) -> Task? {
        tasks.first { $0.id == id }
    }
    
    public func taskIndex(withId id: UUID) -> Int? {
        filteredTasks.firstIndex { $0.id == id }
    }
    
    // MARK: - iOS-Specific Features
    
    public func refreshTasks() async {
        await loadTasks()
    }
    
    public func handlePullToRefresh() async {
        await refreshTasks()
    }
    
    // MARK: - Quick Actions (iOS)
    
    public func quickCompleteTask(_ taskId: UUID) async {
        await toggleTaskCompletion(taskId: taskId)
    }
    
    public func quickDeleteTask(_ taskId: UUID) async {
        await deleteTask(taskId: taskId)
    }
    
    // MARK: - Swipe Actions Support
    
    public func getLeadingSwipeActions(for taskId: UUID) -> [SwipeAction] {
        guard let task = task(withId: taskId) else { return [] }
        
        let completeAction = SwipeAction(
            title: task.isCompleted ? "Incomplete" : "Complete",
            systemImage: task.isCompleted ? "circle" : "checkmark.circle.fill",
            backgroundColor: task.isCompleted ? .orange : .green,
            action: { await self.toggleTaskCompletion(taskId: taskId) }
        )
        
        return [completeAction]
    }
    
    public func getTrailingSwipeActions(for taskId: UUID) -> [SwipeAction] {
        let deleteAction = SwipeAction(
            title: "Delete",
            systemImage: "trash.fill",
            backgroundColor: .red,
            isDestructive: true,
            action: { await self.deleteTask(taskId: taskId) }
        )
        
        let duplicateAction = SwipeAction(
            title: "Duplicate",
            systemImage: "plus.square.on.square",
            backgroundColor: .blue,
            action: { await self.duplicateTask(taskId: taskId) }
        )
        
        return [deleteAction, duplicateAction]
    }
}

// MARK: - Swipe Action Helper

public struct SwipeAction {
    public let title: String
    public let systemImage: String
    public let backgroundColor: Color
    public let isDestructive: Bool
    public let action: () async -> Void
    
    public init(
        title: String,
        systemImage: String,
        backgroundColor: Color,
        isDestructive: Bool = false,
        action: @escaping () async -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.backgroundColor = backgroundColor
        self.isDestructive = isDestructive
        self.action = action
    }
}