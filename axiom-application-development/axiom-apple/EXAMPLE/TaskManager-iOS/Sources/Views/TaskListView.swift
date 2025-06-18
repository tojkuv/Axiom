import SwiftUI
import Axiom

// Import shared Task Manager components
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared

// MARK: - Task List View (iOS)

/// Main task list view for iOS displaying all tasks with filtering and sorting
public struct TaskListView: View, PresentationProtocol {
    public typealias ContextType = TaskListContext
    
    @ObservedObject public var context: TaskListContext
    @State private var showingCreateTask = false
    @State private var showingSettings = false
    @State private var showingFilters = false
    @State private var selectedTask: Task?
    
    public init(context: TaskListContext) {
        self.context = context
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                if context.isLoading && context.tasks.isEmpty {
                    loadingView
                } else {
                    mainContent
                }
                
                if let error = context.error {
                    ErrorBanner(message: error) {
                        Task { await context.clearError() }
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarItems(
                leading: leadingNavigationItems,
                trailing: trailingNavigationItems
            )
            .refreshable {
                await context.handlePullToRefresh()
            }
        }
        .sheet(isPresented: $showingCreateTask) {
            // Create task sheet will be presented here
            Text("Create Task View")
        }
        .sheet(isPresented: $showingSettings) {
            // Settings sheet will be presented here
            Text("Settings View")
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(context: context, isPresented: $showingFilters)
        }
        .onAppear {
            Task { await context.appeared() }
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            if context.isSelectionMode {
                selectionToolbar
            }
            
            taskList
        }
    }
    
    // MARK: - Task List
    
    private var taskList: some View {
        Group {
            if context.filteredTasks.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(context.filteredTasks) { task in
                        TaskRowView(
                            task: task,
                            isSelected: context.selectedTasks.contains(task.id),
                            isSelectionMode: context.isSelectionMode,
                            onTap: { await handleTaskTap(task) },
                            onToggleSelection: { await context.toggleTaskSelection(task.id) },
                            onToggleCompletion: { await context.toggleTaskCompletion(taskId: task.id) }
                        )
                        .swipeActions(edge: .leading) {
                            leadingSwipeActions(for: task)
                        }
                        .swipeActions(edge: .trailing) {
                            trailingSwipeActions(for: task)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    // MARK: - Selection Toolbar
    
    private var selectionToolbar: some View {
        HStack {
            Button(context.allTasksSelected ? "Deselect All" : "Select All") {
                Task {
                    if context.allTasksSelected {
                        await context.clearSelection()
                    } else {
                        await context.selectAllTasks()
                    }
                }
            }
            .disabled(context.filteredTasks.isEmpty)
            
            Spacer()
            
            Text("\(context.selectedTasksCount) selected")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Menu("Actions") {
                Button("Complete") {
                    Task { await context.completeSelectedTasks() }
                }
                .disabled(!context.hasSelectedTasks)
                
                Button("Delete", role: .destructive) {
                    Task { await context.deleteSelectedTasks() }
                }
                .disabled(!context.hasSelectedTasks)
                
                Divider()
                
                Menu("Set Category") {
                    ForEach(Category.allCases, id: \.self) { category in
                        Button(category.displayName) {
                            Task { await context.updateSelectedTasksCategory(category) }
                        }
                    }
                }
                .disabled(!context.hasSelectedTasks)
                
                Menu("Set Priority") {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        Button(priority.displayName) {
                            Task { await context.updateSelectedTasksPriority(priority) }
                        }
                    }
                }
                .disabled(!context.hasSelectedTasks)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Navigation Items
    
    private var leadingNavigationItems: some View {
        HStack {
            if context.isSelectionMode {
                Button("Cancel") {
                    Task { await context.clearSelection() }
                }
            } else {
                Button("Select") {
                    Task { await context.toggleSelectionMode() }
                }
                .disabled(context.filteredTasks.isEmpty)
            }
        }
    }
    
    private var trailingNavigationItems: some View {
        HStack {
            Button(action: { showingFilters.toggle() }) {
                Image(systemName: "line.horizontal.3.decrease.circle")
                    .foregroundColor(hasActiveFilters ? .accentColor : .primary)
            }
            
            Button(action: { showingSettings.toggle() }) {
                Image(systemName: "gear")
            }
            
            Button(action: { showingCreateTask.toggle() }) {
                Image(systemName: "plus")
            }
        }
    }
    
    // MARK: - Swipe Actions
    
    private func leadingSwipeActions(for task: Task) -> some View {
        Button {
            Task { await context.toggleTaskCompletion(taskId: task.id) }
        } label: {
            Image(systemName: task.isCompleted ? "circle" : "checkmark.circle.fill")
        }
        .tint(task.isCompleted ? .orange : .green)
    }
    
    private func trailingSwipeActions(for task: Task) -> some View {
        Group {
            Button {
                Task { await context.deleteTask(taskId: task.id) }
            } label: {
                Image(systemName: "trash.fill")
            }
            .tint(.red)
            
            Button {
                Task { await context.duplicateTask(taskId: task.id) }
            } label: {
                Image(systemName: "plus.square.on.square")
            }
            .tint(.blue)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.medium)
            
            Text(emptyStateSubtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Your First Task") {
                showingCreateTask.toggle()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading tasks...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleTaskTap(_ task: Task) async {
        if context.isSelectionMode {
            await context.toggleTaskSelection(task.id)
        } else {
            selectedTask = task
            // Navigate to task detail
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasActiveFilters: Bool {
        context.selectedFilter != .all ||
        context.selectedCategory != nil ||
        !context.searchQuery.isEmpty
    }
    
    private var emptyStateTitle: String {
        if hasActiveFilters {
            return "No Matching Tasks"
        } else if context.tasks.isEmpty {
            return "No Tasks Yet"
        } else {
            return "All Done!"
        }
    }
    
    private var emptyStateSubtitle: String {
        if hasActiveFilters {
            return "Try adjusting your filters to see more tasks."
        } else if context.tasks.isEmpty {
            return "Get started by creating your first task. Stay organized and productive!"
        } else {
            return "You've completed all your tasks. Great job!"
        }
    }
}

// MARK: - Task Row View

private struct TaskRowView: View {
    let task: Task
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () async -> Void
    let onToggleSelection: () async -> Void
    let onToggleCompletion: () async -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            if isSelectionMode {
                Button {
                    Task { await onToggleSelection() }
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Completion button
                Button {
                    Task { await onToggleCompletion() }
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .green : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.body)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                    
                    Spacer()
                    
                    priorityIndicator
                }
                
                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    categoryBadge
                    
                    if let dueDateDescription = task.dueDateDescription {
                        Text(dueDateDescription)
                            .font(.caption2)
                            .foregroundColor(task.isOverdue ? .red : .secondary)
                    }
                    
                    Spacer()
                    
                    if !task.tags.isEmpty {
                        tagIndicator
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            Task { await onTap() }
        }
    }
    
    private var priorityIndicator: some View {
        Circle()
            .fill(task.priority.color)
            .frame(width: 8, height: 8)
    }
    
    private var categoryBadge: some View {
        Text(task.category.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(task.category.color.opacity(0.2))
            .foregroundColor(task.category.color)
            .cornerRadius(4)
    }
    
    private var tagIndicator: some View {
        HStack(spacing: 2) {
            Image(systemName: "tag.fill")
            Text("\(task.tags.count)")
        }
        .font(.caption2)
        .foregroundColor(.secondary)
    }
}

// MARK: - Filter View

private struct FilterView: View {
    @ObservedObject var context: TaskListContext
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section("Status") {
                    ForEach(Task.Filter.allCases, id: \.self) { filter in
                        Button {
                            Task {
                                await context.setFilter(filter)
                                isPresented = false
                            }
                        } label: {
                            HStack {
                                Text(filter.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if context.selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                Section("Category") {
                    Button {
                        Task {
                            await context.setCategoryFilter(nil)
                            isPresented = false
                        }
                    } label: {
                        HStack {
                            Text("All Categories")
                                .foregroundColor(.primary)
                            Spacer()
                            if context.selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    
                    ForEach(Category.allCases, id: \.self) { category in
                        Button {
                            Task {
                                await context.setCategoryFilter(category)
                                isPresented = false
                            }
                        } label: {
                            HStack {
                                Label(category.displayName, systemImage: category.systemImageName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if context.selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                Section("Sort") {
                    ForEach(Task.SortOrder.allCases, id: \.self) { sortOrder in
                        Button {
                            Task {
                                await context.setSortOrder(sortOrder, ascending: context.isAscending)
                                isPresented = false
                            }
                        } label: {
                            HStack {
                                Text(sortOrder.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if context.sortOrder == sortOrder {
                                    Image(systemName: context.isAscending ? "arrow.up" : "arrow.down")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                    
                    Button {
                        Task { await context.toggleSortDirection() }
                    } label: {
                        HStack {
                            Text("Reverse Order")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await context.clearFilters()
                            isPresented = false
                        }
                    } label: {
                        Text("Clear All Filters")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarItems(trailing: Button("Done") { isPresented = false })
        }
    }
}

// MARK: - Error Banner

private struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Dismiss") {
                    onDismiss()
                }
                .font(.caption)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
            
            Spacer()
        }
    }
}