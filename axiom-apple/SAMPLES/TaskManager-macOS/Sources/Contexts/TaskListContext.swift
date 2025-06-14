import Foundation
import SwiftUI
import Axiom

// Import shared Task Manager components
import TaskManager_Shared

// MARK: - Task List Context (macOS)

/// Context for the task list view on macOS with enhanced desktop features
@MainActor
public final class TaskListContext: ClientObservingContext<TaskClient> {
    
    // MARK: - Published Properties
    @Published public private(set) var tasks: [Task] = []
    @Published public private(set) var filteredTasks: [Task] = []
    @Published public private(set) var selectedFilter: Task.Filter = .all
    @Published public private(set) var selectedCategory: TaskManager_Shared.Category? = nil
    @Published public private(set) var searchQuery: String = ""
    @Published public private(set) var sortOrder: Task.SortOrder = .createdDate
    @Published public private(set) var isAscending: Bool = false
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var error: String? = nil
    
    // macOS-specific selection state
    @Published public private(set) var selectedTasks: Set<UUID> = []
    @Published public private(set) var lastSelectedTask: UUID? = nil
    @Published public private(set) var focusedTask: UUID? = nil
    
    // View configuration
    @Published public var viewMode: ViewMode = .list
    @Published public var showSidebar: Bool = true
    @Published public var showInspector: Bool = false
    @Published public var sidebarWidth: CGFloat = 200
    @Published public var inspectorWidth: CGFloat = 300
    
    // Toolbar state
    @Published public private(set) var toolbarItems: [ToolbarItemConfiguration] = []
    
    // Statistics for sidebar
    @Published public private(set) var statistics: TaskStatistics = TaskStatistics(
        totalTasks: 0, completedTasks: 0, pendingTasks: 0, overdueTasks: 0,
        dueTodayTasks: 0, dueThisWeekTasks: 0, filteredTasksCount: 0,
        tasksByCategory: [:], tasksByPriority: [:]
    )
    
    // MARK: - Initialization
    
    public required init() {
        fatalError("Use init(client:) instead")
    }
    
    public override init(client: TaskClient) {
        super.init(client: client)
        setupToolbar()
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
            
            // Update toolbar state
            updateToolbarState()
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
    
    public func createTask(title: String, description: String = "", priority: Priority = .medium, category: TaskManager_Shared.Category = .personal, dueDate: Date? = nil) async {
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
            
            // Remove from selection if it was selected
            await MainActor.run {
                selectedTasks.remove(taskId)
                if lastSelectedTask == taskId {
                    lastSelectedTask = nil
                }
                if focusedTask == taskId {
                    focusedTask = nil
                }
            }
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
    
    // MARK: - macOS-Specific Selection Management
    
    public func selectTask(_ taskId: UUID, extendSelection: Bool = false) async {
        await MainActor.run {
            if extendSelection {
                // Cmd+Click behavior
                if selectedTasks.contains(taskId) {
                    selectedTasks.remove(taskId)
                } else {
                    selectedTasks.insert(taskId)
                }
            } else {
                // Regular click
                selectedTasks = [taskId]
            }
            
            lastSelectedTask = taskId
            focusedTask = taskId
        }
    }
    
    public func selectTaskRange(from startId: UUID, to endId: UUID) async {
        guard let startIndex = filteredTasks.firstIndex(where: { $0.id == startId }),
              let endIndex = filteredTasks.firstIndex(where: { $0.id == endId }) else {
            return
        }
        
        let range = min(startIndex, endIndex)...max(startIndex, endIndex)
        let tasksInRange = Array(filteredTasks[range])
        
        await MainActor.run {
            selectedTasks = Set(tasksInRange.map { $0.id })
            lastSelectedTask = endId
            focusedTask = endId
        }
    }
    
    public func selectAllTasks() async {
        await MainActor.run {
            selectedTasks = Set(filteredTasks.map { $0.id })
            if let firstTask = filteredTasks.first {
                lastSelectedTask = firstTask.id
                focusedTask = firstTask.id
            }
        }
    }
    
    public func clearSelection() async {
        await MainActor.run {
            selectedTasks.removeAll()
            lastSelectedTask = nil
            focusedTask = nil
        }
    }
    
    public func moveFocus(direction: FocusDirection) async {
        guard let currentFocus = focusedTask,
              let currentIndex = filteredTasks.firstIndex(where: { $0.id == currentFocus }) else {
            // No current focus, focus on first task
            if let firstTask = filteredTasks.first {
                await MainActor.run {
                    focusedTask = firstTask.id
                }
            }
            return
        }
        
        let newIndex: Int
        switch direction {
        case .up:
            newIndex = max(0, currentIndex - 1)
        case .down:
            newIndex = min(filteredTasks.count - 1, currentIndex + 1)
        }
        
        if newIndex != currentIndex && newIndex < filteredTasks.count {
            let newFocusedTask = filteredTasks[newIndex]
            await MainActor.run {
                focusedTask = newFocusedTask.id
            }
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
    
    public func updateSelectedTasksCategory(_ category: TaskManager_Shared.Category) async {
        guard !selectedTasks.isEmpty else { return }
        
        do {
            try await client.process(.updateTasksCategory(taskIds: Array(selectedTasks), category: category))
        } catch {
            await setError("Failed to update category: \(error.localizedDescription)")
        }
    }
    
    public func updateSelectedTasksPriority(_ priority: Priority) async {
        guard !selectedTasks.isEmpty else { return }
        
        do {
            try await client.process(.updateTasksPriority(taskIds: Array(selectedTasks), priority: priority))
        } catch {
            await setError("Failed to update priority: \(error.localizedDescription)")
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
    
    public func setCategoryFilter(_ category: TaskManager_Shared.Category?) async {
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
    
    // MARK: - View Configuration
    
    public func setViewMode(_ mode: ViewMode) async {
        await MainActor.run {
            viewMode = mode
        }
    }
    
    public func toggleSidebar() async {
        await MainActor.run {
            showSidebar.toggle()
        }
    }
    
    public func toggleInspector() async {
        await MainActor.run {
            showInspector.toggle()
        }
    }
    
    public func setSidebarWidth(_ width: CGFloat) async {
        await MainActor.run {
            sidebarWidth = max(150, min(400, width))
        }
    }
    
    public func setInspectorWidth(_ width: CGFloat) async {
        await MainActor.run {
            inspectorWidth = max(200, min(500, width))
        }
    }
    
    // MARK: - Toolbar Management
    
    private func setupToolbar() {
        toolbarItems = [
            ToolbarItemConfiguration(
                id: "add",
                title: "Add Task",
                systemImage: "plus",
                action: { await self.showCreateTask() }
            ),
            ToolbarItemConfiguration(
                id: "delete",
                title: "Delete",
                systemImage: "trash",
                action: { await self.deleteSelectedTasks() },
                isEnabled: { !self.selectedTasks.isEmpty }
            ),
            ToolbarItemConfiguration(
                id: "complete",
                title: "Complete",
                systemImage: "checkmark.circle",
                action: { await self.completeSelectedTasks() },
                isEnabled: { !self.selectedTasks.isEmpty }
            ),
            ToolbarItemConfiguration(
                id: "search",
                title: "Search",
                systemImage: "magnifyingglass",
                action: { await self.focusSearchField() }
            ),
            ToolbarItemConfiguration(
                id: "filter",
                title: "Filter",
                systemImage: "line.horizontal.3.decrease.circle",
                action: { await self.showFilterPopover() }
            ),
            ToolbarItemConfiguration(
                id: "view",
                title: "View Options",
                systemImage: "rectangle.grid.1x2",
                action: { await self.showViewOptions() }
            )
        ]
    }
    
    private func updateToolbarState() {
        // Toolbar items will be updated based on current selection state
        // This is handled automatically by the isEnabled closures
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
    
    // MARK: - macOS-Specific Actions
    
    private func showCreateTask() async {
        // This would trigger showing the create task window
        print("Show create task window")
    }
    
    private func focusSearchField() async {
        // This would focus the search field in the UI
        print("Focus search field")
    }
    
    private func showFilterPopover() async {
        // This would show filter options in a popover
        print("Show filter popover")
    }
    
    private func showViewOptions() async {
        // This would show view option controls
        print("Show view options")
    }
    
    // MARK: - Keyboard Handling
    
    public func handleKeyCommand(_ command: KeyCommand) async {
        switch command {
        case .delete:
            if !selectedTasks.isEmpty {
                await deleteSelectedTasks()
            }
        case .duplicate:
            if let taskId = lastSelectedTask {
                await duplicateTask(taskId: taskId)
            }
        case .toggleComplete:
            if let taskId = lastSelectedTask {
                await toggleTaskCompletion(taskId: taskId)
            }
        case .selectAll:
            await selectAllTasks()
        case .deselectAll:
            await clearSelection()
        case .focusUp:
            await moveFocus(direction: .up)
        case .focusDown:
            await moveFocus(direction: .down)
        case .newTask:
            await showCreateTask()
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
        selectedTasks.count < filteredTasks.count
    }
    
    public var allTasksSelected: Bool {
        !filteredTasks.isEmpty && selectedTasks.count == filteredTasks.count
    }
    
    // MARK: - Task Retrieval
    
    public func task(withId id: UUID) -> Task? {
        tasks.first { $0.id == id }
    }
    
    public func taskIndex(withId id: UUID) -> Int? {
        filteredTasks.firstIndex { $0.id == id }
    }
    
    public var selectedTaskObjects: [Task] {
        selectedTasks.compactMap { id in
            task(withId: id)
        }
    }
    
    public var focusedTaskObject: Task? {
        guard let focusedId = focusedTask else { return nil }
        return task(withId: focusedId)
    }
}

// MARK: - Supporting Types

public enum ViewMode: String, CaseIterable {
    case list = "list"
    case grid = "grid"
    case column = "column"
    
    public var displayName: String {
        switch self {
        case .list: return "List"
        case .grid: return "Grid"
        case .column: return "Columns"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .list: return "list.bullet"
        case .grid: return "rectangle.grid.2x2"
        case .column: return "rectangle.grid.1x2"
        }
    }
}

public enum FocusDirection {
    case up
    case down
}

public enum KeyCommand {
    case delete
    case duplicate
    case toggleComplete
    case selectAll
    case deselectAll
    case focusUp
    case focusDown
    case newTask
}

public struct ToolbarItemConfiguration: Identifiable {
    public let id: String
    public let title: String
    public let systemImage: String
    public let action: () async -> Void
    public let isEnabled: (() -> Bool)?
    
    public init(
        id: String,
        title: String,
        systemImage: String,
        action: @escaping () async -> Void,
        isEnabled: (() -> Bool)? = nil
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.action = action
        self.isEnabled = isEnabled
    }
    
    public var enabled: Bool {
        isEnabled?() ?? true
    }
}