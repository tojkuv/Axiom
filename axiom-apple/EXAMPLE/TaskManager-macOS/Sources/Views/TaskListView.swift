import SwiftUI
import Axiom

// Import shared Task Manager components
import TaskManager_Shared

// MARK: - Task List View (macOS)

/// Main task list view for macOS with comprehensive desktop features
public struct TaskListView: View, PresentationProtocol {
    public typealias ContextType = TaskListContext
    
    @ObservedObject public var context: TaskListContext
    @State private var selectedTaskId: UUID?
    @State private var searchText: String = ""
    @State private var showingCreateTask = false
    @State private var showingFilters = false
    @State private var showingViewOptions = false
    @FocusState private var isSearchFieldFocused: Bool
    
    public init(context: TaskListContext) {
        self.context = context
    }
    
    public var body: some View {
        NavigationSplitView(
            sidebar: {
                sidebarContent
            },
            content: {
                mainContent
            },
            detail: {
                detailContent
            }
        )
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                toolbarContent
            }
        }
        .searchable(text: $searchText, prompt: "Search tasks...")
        .onChange(of: searchText) { newValue in
            _Concurrency.Task {
                await context.setSearchQuery(newValue)
            }
        }
        .focusedSceneValue(\.selectedTaskIds, Array(context.selectedTasks))
        .onAppear {
            _Concurrency.Task { await context.appeared() }
        }
        .sheet(isPresented: $showingCreateTask) {
            CreateTaskSheetView()
        }
        .sheet(isPresented: $showingFilters) {
            FiltersSheetView(context: context)
        }
        .sheet(isPresented: $showingViewOptions) {
            ViewOptionsSheetView(context: context)
        }
        .alert("Error", isPresented: .constant(context.error != nil)) {
            Button("OK") {
                _Concurrency.Task { await context.clearError() }
            }
        } message: {
            if let error = context.error {
                Text(error)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .taskCreated)) { _ in
            showingCreateTask = false
        }
    }
    
    // MARK: - Sidebar Content
    
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // Filter sections
            List(selection: $selectedTaskId) {
                Section("Filters") {
                    FilterRowView(
                        title: "All Tasks",
                        count: context.statistics.totalTasks,
                        systemImage: "list.bullet",
                        isSelected: context.selectedFilter == .all
                    ) {
                        _Concurrency.Task { await context.setFilter(.all) }
                    }
                    
                    FilterRowView(
                        title: "Pending",
                        count: context.statistics.pendingTasks,
                        systemImage: "circle",
                        isSelected: context.selectedFilter == .pending
                    ) {
                        _Concurrency.Task { await context.setFilter(.pending) }
                    }
                    
                    FilterRowView(
                        title: "Completed",
                        count: context.statistics.completedTasks,
                        systemImage: "checkmark.circle",
                        isSelected: context.selectedFilter == .completed
                    ) {
                        _Concurrency.Task { await context.setFilter(.completed) }
                    }
                    
                    FilterRowView(
                        title: "Overdue",
                        count: context.statistics.overdueTasks,
                        systemImage: "exclamationmark.triangle",
                        isSelected: context.selectedFilter == .overdue,
                        color: .red
                    ) {
                        _Concurrency.Task { await context.setFilter(.overdue) }
                    }
                }
                
                Section("Categories") {
                    ForEach(Category.allCases, id: \.self) { category in
                        let count = context.statistics.tasksByCategory[category] ?? 0
                        FilterRowView(
                            title: category.displayName,
                            count: count,
                            systemImage: category.systemImageName,
                            isSelected: context.selectedCategory == category,
                            color: category.color
                        ) {
                            _Concurrency.Task { 
                                await context.setCategoryFilter(
                                    context.selectedCategory == category ? nil : category
                                )
                            }
                        }
                    }
                }
                
                Section("Quick Stats") {
                    VStack(alignment: .leading, spacing: 8) {
                        StatRowView(
                            title: "Due Today",
                            value: "\(context.statistics.dueTodayTasks)",
                            color: .orange
                        )
                        
                        StatRowView(
                            title: "Due This Week",
                            value: "\(context.statistics.dueThisWeekTasks)",
                            color: .blue
                        )
                        
                        if context.statistics.totalTasks > 0 {
                            let completionRate = Int(context.statistics.completionPercentage * 100)
                            StatRowView(
                                title: "Completion Rate",
                                value: "\(completionRate)%",
                                color: .green
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 200)
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Sort and view controls
            HStack {
                Picker("Sort by", selection: Binding(
                    get: { context.sortOrder },
                    set: { newOrder in
                        _Concurrency.Task { await context.setSortOrder(newOrder, ascending: context.isAscending) }
                    }
                )) {
                    ForEach(Task.SortOrder.allCases, id: \.self) { sortOrder in
                        Text(sortOrder.displayName).tag(sortOrder)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                
                Button(action: {
                    _Concurrency.Task { await context.toggleSortDirection() }
                }) {
                    Image(systemName: context.isAscending ? "arrow.up" : "arrow.down")
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // View mode picker
                Picker("View", selection: Binding(
                    get: { context.viewMode },
                    set: { newMode in
                        _Concurrency.Task { await context.setViewMode(newMode) }
                    }
                )) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Label(mode.displayName, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Task list content
            if context.isLoading && context.filteredTasks.isEmpty {
                loadingView
            } else if context.filteredTasks.isEmpty {
                emptyStateView
            } else {
                taskListContent
            }
        }
    }
    
    // MARK: - Detail Content
    
    private var detailContent: some View {
        Group {
            if context.showInspector, let selectedTask = context.selectedTaskObjects.first {
                TaskInspectorView(task: selectedTask, context: context)
            } else if context.selectedTasks.count > 1 {
                MultiSelectionDetailView(selectedTasks: context.selectedTaskObjects)
            } else {
                ContentUnavailableView(
                    "No Task Selected",
                    systemImage: "doc.text",
                    description: Text("Select a task to view its details")
                )
            }
        }
        .frame(minWidth: 300)
    }
    
    // MARK: - Task List Content
    
    private var taskListContent: some View {
        Group {
            switch context.viewMode {
            case .list:
                listView
            case .grid:
                gridView
            case .column:
                columnView
            }
        }
    }
    
    private var listView: some View {
        List(context.filteredTasks, id: \.id, selection: $selectedTaskId) { task in
            TaskRowView(
                task: task,
                isSelected: context.selectedTasks.contains(task.id),
                isFocused: context.focusedTask == task.id
            ) {
                _Concurrency.Task { await context.selectTask(task.id) }
            } onDoubleClick: {
                // Open task detail window
                print("Open task detail for \(task.id)")
            } onToggleComplete: {
                _Concurrency.Task { await context.toggleTaskCompletion(taskId: task.id) }
            } onDelete: {
                _Concurrency.Task { await context.deleteTask(taskId: task.id) }
            }
        }
        .listStyle(.plain)
        .onChange(of: selectedTaskId) { newValue in
            if let taskId = newValue {
                _Concurrency.Task { await context.selectTask(taskId) }
            }
        }
    }
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 250, maximum: 300), spacing: 12)
            ], spacing: 12) {
                ForEach(context.filteredTasks, id: \.id) { task in
                    TaskCardView(
                        task: task,
                        isSelected: context.selectedTasks.contains(task.id)
                    ) {
                        _Concurrency.Task { await context.selectTask(task.id) }
                    } onToggleComplete: {
                        _Concurrency.Task { await context.toggleTaskCompletion(taskId: task.id) }
                    } onDelete: {
                        _Concurrency.Task { await context.deleteTask(taskId: task.id) }
                    }
                }
            }
            .padding()
        }
    }
    
    private var columnView: some View {
        HStack(spacing: 1) {
            ForEach(Priority.allCases, id: \.self) { priority in
                let priorityTasks = context.filteredTasks.filter { $0.priority == priority }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Column header
                    HStack {
                        Label(priority.displayName, systemImage: priority.systemImageName)
                            .font(.headline)
                            .foregroundColor(priority.color)
                        
                        Spacer()
                        
                        Text("\(priorityTasks.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    // Column tasks
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(priorityTasks, id: \.id) { task in
                                TaskCardView(
                                    task: task,
                                    isSelected: context.selectedTasks.contains(task.id),
                                    compact: true
                                ) {
                                    _Concurrency.Task { await context.selectTask(task.id) }
                                } onToggleComplete: {
                                    _Concurrency.Task { await context.toggleTaskCompletion(taskId: task.id) }
                                } onDelete: {
                                    _Concurrency.Task { await context.deleteTask(taskId: task.id) }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.textBackgroundColor))
                .border(Color(NSColor.separatorColor), width: 0.5)
            }
        }
    }
    
    // MARK: - Toolbar Content
    
    private var toolbarContent: some View {
        Group {
            Button(action: {
                showingCreateTask = true
            }) {
                Label("New Task", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
            
            if context.hasSelectedTasks {
                Button(action: {
                    _Concurrency.Task { await context.deleteSelectedTasks() }
                }) {
                    Label("Delete", systemImage: "trash")
                }
                .keyboardShortcut(.delete, modifiers: [])
                
                Button(action: {
                    _Concurrency.Task { await context.completeSelectedTasks() }
                }) {
                    Label("Complete", systemImage: "checkmark.circle")
                }
                .keyboardShortcut("return", modifiers: .command)
            }
            
            Divider()
            
            Button(action: {
                showingFilters = true
            }) {
                Label("Filters", systemImage: "line.horizontal.3.decrease.circle")
            }
            
            Button(action: {
                showingViewOptions = true
            }) {
                Label("View Options", systemImage: "sidebar.right")
            }
            
            Button(action: {
                _Concurrency.Task { await context.toggleInspector() }
            }) {
                Label("Inspector", systemImage: "sidebar.trailing")
            }
            .keyboardShortcut("i", modifiers: [.command, .option])
        }
    }
    
    // MARK: - Supporting Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading tasks...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Tasks", systemImage: "list.bullet")
        } description: {
            Text(emptyStateDescription)
        } actions: {
            Button("Create Task") {
                showingCreateTask = true
            }
            .buttonStyle(.borderedProminent)
            
            if context.selectedFilter != .all || context.selectedCategory != nil {
                Button("Clear Filters") {
                    _Concurrency.Task { await context.clearFilters() }
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var emptyStateDescription: String {
        if context.selectedFilter == .all && context.selectedCategory == nil {
            return "Get started by creating your first task"
        } else {
            return "No tasks match the current filters"
        }
    }
}

// MARK: - Filter Row View

private struct FilterRowView: View {
    let title: String
    let count: Int
    let systemImage: String
    let isSelected: Bool
    var color: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: systemImage)
                    .foregroundColor(isSelected ? .accentColor : color)
                
                Spacer()
                
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(NSColor.quaternaryLabelColor))
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(isSelected ? Color.accentColor.opacity(0.1) : nil)
    }
}

// MARK: - Stat Row View

private struct StatRowView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Sheet Views

private struct CreateTaskSheetView: View {
    var body: some View {
        Text("Create Task")
            .frame(width: 400, height: 500)
    }
}

private struct FiltersSheetView: View {
    let context: TaskListContext
    
    var body: some View {
        VStack {
            Text("Filters")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Filter controls would go here
            
            HStack {
                Button("Clear All") {
                    _Concurrency.Task { await context.clearFilters() }
                }
                
                Spacer()
                
                Button("Done") {
                    // Close sheet
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

private struct ViewOptionsSheetView: View {
    let context: TaskListContext
    
    var body: some View {
        VStack {
            Text("View Options")
                .font(.title2)
                .fontWeight(.semibold)
            
            // View option controls would go here
            
            Button("Done") {
                // Close sheet
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

// MARK: - Focus Extension

struct SelectedTaskIdsKey: FocusedValueKey {
    typealias Value = [UUID]
}

extension FocusedValues {
    var selectedTaskIds: [UUID]? {
        get { self[SelectedTaskIdsKey.self] }
        set { self[SelectedTaskIdsKey.self] = newValue }
    }
}