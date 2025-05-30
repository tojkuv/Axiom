import SwiftUI
import Axiom

// MARK: - Dashboard View

/// Main dashboard view demonstrating AxiomView protocol
/// Shows 1:1 View-Context relationship with reactive updates
public struct DashboardView: AxiomView {
    public typealias Context = DashboardContext
    
    // MARK: - Context Binding
    
    @ObservedObject public var context: DashboardContext
    
    // MARK: - Local State
    
    @State private var showingCreateTask = false
    @State private var showingCreateProject = false
    @State private var refreshTrigger = UUID()
    
    // MARK: - Initialization
    
    public init(context: DashboardContext) {
        self.context = context
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationView {
            TabView(selection: Binding(
                get: { context.selectedTab },
                set: { newTab in
                    Task { await context.switchTab(newTab) }
                }
            )) {
                // Tasks Tab
                TasksTabView(context: context)
                    .tabItem {
                        Label("Tasks", systemImage: "checklist")
                    }
                    .tag(DashboardTab.tasks)
                
                // Projects Tab
                ProjectsTabView(context: context)
                    .tabItem {
                        Label("Projects", systemImage: "folder")
                    }
                    .tag(DashboardTab.projects)
                
                // Analytics Tab
                AnalyticsTabView(context: context)
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar")
                    }
                    .tag(DashboardTab.analytics)
                
                // Profile Tab
                ProfileTabView(context: context)
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                    .tag(DashboardTab.profile)
            }
            .navigationTitle("Task Manager")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    refreshButton
                    addButton
                }
            }
        }
        .overlay {
            if context.isLoading {
                LoadingOverlay()
            }
        }
        .overlay(alignment: .top) {
            NotificationOverlay(context: context)
        }
        .sheet(isPresented: $showingCreateTask) {
            CreateTaskView(context: context)
        }
        .sheet(isPresented: $showingCreateProject) {
            CreateProjectView(context: context)
        }
        .sheet(isPresented: Binding(
            get: { context.showingUserProfile },
            set: { _ in
                Task { @MainActor in
                    context.showingUserProfile = false
                }
            }
        )) {
            UserProfileView(context: context)
        }
        .onAppear {
            Task {
                await context.onAppear()
            }
        }
        .onDisappear {
            Task {
                await context.onDisappear()
            }
        }
        .refreshable {
            await context.refreshDashboard()
        }
        .id(refreshTrigger)
    }
    
    // MARK: - Toolbar Items
    
    private var refreshButton: some View {
        Button(action: {
            Task {
                await context.refreshDashboard()
                refreshTrigger = UUID()
            }
        }) {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(context.isLoading)
    }
    
    private var addButton: some View {
        Menu {
            Button("New Task", systemImage: "plus.circle") {
                showingCreateTask = true
            }
            
            Button("New Project", systemImage: "folder.badge.plus") {
                showingCreateProject = true
            }
        } label: {
            Image(systemName: "plus")
        }
        .disabled(context.isLoading)
    }
}

// MARK: - Tab Views

struct TasksTabView: View {
    @ObservedObject var context: DashboardContext
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Task Summary Cards
                TaskSummarySection(summary: context.dashboardData.taskSummary)
                
                // Recent Tasks
                RecentTasksSection(tasks: context.dashboardData.recentTasks)
            }
            .padding()
        }
    }
}

struct ProjectsTabView: View {
    @ObservedObject var context: DashboardContext
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Project Summary Cards
                ProjectSummarySection(summary: context.dashboardData.projectSummary)
                
                // Recent Projects
                RecentProjectsSection(projects: context.dashboardData.recentProjects)
            }
            .padding()
        }
    }
}

struct AnalyticsTabView: View {
    @ObservedObject var context: DashboardContext
    @State private var performanceMetrics: DashboardPerformanceMetrics?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let metrics = performanceMetrics {
                    PerformanceMetricsSection(metrics: metrics)
                } else {
                    ProgressView("Loading analytics...")
                }
            }
            .padding()
        }
        .onAppear {
            Task {
                performanceMetrics = await context.getPerformanceMetrics()
            }
        }
    }
}

struct ProfileTabView: View {
    @ObservedObject var context: DashboardContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let user = context.dashboardData.currentUser {
                    UserProfileCard(user: user)
                    
                    Button("Edit Profile") {
                        Task {
                            await context.showUserProfile()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text("No user logged in")
                        .foregroundColor(.secondary)
                }
                
                LastUpdatedView(date: context.dashboardData.lastUpdated)
            }
            .padding()
        }
    }
}

// MARK: - Section Views

struct TaskSummarySection: View {
    let summary: TaskSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Overview")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Total",
                    value: "\\(summary.total)",
                    color: .blue
                )
                
                MetricCard(
                    title: "Active",
                    value: "\\(summary.active)",
                    color: .orange
                )
                
                MetricCard(
                    title: "Completed",
                    value: "\\(summary.completed)",
                    color: .green
                )
                
                MetricCard(
                    title: "High Priority",
                    value: "\\(summary.highPriority)",
                    color: .red
                )
            }
            
            if summary.overdue > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("\\(summary.overdue) tasks are overdue")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .padding(.top, 4)
            }
        }
    }
}

struct ProjectSummarySection: View {
    let summary: ProjectSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Overview")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Total",
                    value: "\\(summary.total)",
                    color: .blue
                )
                
                MetricCard(
                    title: "Active",
                    value: "\\(summary.active)",
                    color: .orange
                )
                
                MetricCard(
                    title: "Completed",
                    value: "\\(summary.completed)",
                    color: .green
                )
                
                MetricCard(
                    title: "Deadlines",
                    value: "\\(summary.upcomingDeadlines)",
                    color: .yellow
                )
            }
        }
    }
}

struct RecentTasksSection: View {
    let tasks: [Task]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Tasks")
                .font(.headline)
                .foregroundColor(.primary)
            
            if tasks.isEmpty {
                EmptyStateView(
                    icon: "checklist",
                    title: "No tasks yet",
                    message: "Create your first task to get started"
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(tasks) { task in
                        TaskRowView(task: task)
                    }
                }
            }
        }
    }
}

struct RecentProjectsSection: View {
    let projects: [Project]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Projects")
                .font(.headline)
                .foregroundColor(.primary)
            
            if projects.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: "No projects yet",
                    message: "Create your first project to organize tasks"
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(projects) { project in
                        ProjectRowView(project: project)
                    }
                }
            }
        }
    }
}

struct PerformanceMetricsSection: View {
    let metrics: DashboardPerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Events",
                    value: "\\(metrics.totalEvents)",
                    color: .blue
                )
                
                MetricCard(
                    title: "Error Rate",
                    value: "\\(String(format: "%.1f", metrics.errorRate * 100))%",
                    color: metrics.errorRate > 0.05 ? .red : .green
                )
                
                MetricCard(
                    title: "Task Completion",
                    value: "\\(String(format: "%.1f", metrics.taskCompletionRate * 100))%",
                    color: .green
                )
                
                MetricCard(
                    title: "Response Time",
                    value: "\\(String(format: "%.0f", metrics.averageResponseTime * 1000))ms",
                    color: metrics.averageResponseTime < 0.1 ? .green : .yellow
                )
            }
        }
    }
}

// MARK: - Component Views

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct TaskRowView: View {
    let task: Task
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(task.status.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(task.priority.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(priorityColor(task.priority))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                
                if let dueDate = task.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

struct ProjectRowView: View {
    let project: Project
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\\(project.memberIds.count) members")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(project.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor(project.status))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                
                if let deadline = project.deadline {
                    Text(deadline, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    private func statusColor(_ status: ProjectStatus) -> Color {
        switch status {
        case .planning: return .gray
        case .active: return .blue
        case .onHold: return .yellow
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

struct UserProfileCard: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text(user.fullName)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(user.role.displayName)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

struct LastUpdatedView: View {
    let date: Date
    
    var body: some View {
        Text("Last updated: \\(date, style: .relative)")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Loading...")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 8)
        }
    }
}

struct NotificationOverlay: View {
    @ObservedObject var context: DashboardContext
    @State private var notifications: [AppNotification] = []
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(notifications) { notification in
                NotificationBanner(notification: notification) {
                    Task {
                        await context.notificationClient.dismissNotification(notification.id)
                        notifications.removeAll { $0.id == notification.id }
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .onReceive(context.$dashboardData) { _ in
            Task {
                notifications = await context.notificationClient.getActiveNotifications()
            }
        }
    }
}

struct NotificationBanner: View {
    let notification: AppNotification
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Text(notification.type.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(backgroundColor(for: notification.type))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
    
    private func backgroundColor(for type: NotificationType) -> Color {
        switch type {
        case .success: return .green.opacity(0.1)
        case .error: return .red.opacity(0.1)
        case .warning: return .yellow.opacity(0.1)
        case .info: return .blue.opacity(0.1)
        }
    }
}

// MARK: - Create Views (Simplified)

struct CreateTaskView: View {
    @ObservedObject var context: DashboardContext
    @Environment(\\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority = TaskPriority.medium
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \\.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    
                    Toggle("Has due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due date", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            await context.createTask(
                                title: title,
                                description: description,
                                priority: priority,
                                dueDate: hasDueDate ? dueDate : nil
                            )
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct CreateProjectView: View {
    @ObservedObject var context: DashboardContext
    @Environment(\\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var deadline: Date?
    @State private var hasDeadline = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Project Details") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                    
                    Toggle("Has deadline", isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker("Deadline", selection: Binding(
                            get: { deadline ?? Date() },
                            set: { deadline = $0 }
                        ), displayedComponents: [.date])
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            await context.createProject(
                                name: name,
                                description: description,
                                deadline: hasDeadline ? deadline : nil
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct UserProfileView: View {
    @ObservedObject var context: DashboardContext
    @Environment(\\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if let user = context.dashboardData.currentUser {
                    UserProfileCard(user: user)
                    
                    Text("Profile editing would be implemented here")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Text("No user data available")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}