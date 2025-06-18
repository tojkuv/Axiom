import SwiftUI
import Axiom

// Import shared Task Manager components
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared

// MARK: - Task Manager iOS App

/// Main iOS application entry point for Task Manager
@main
public struct TaskManagerApp: App {
    
    @StateObject private var appCoordinator = AppCoordinator()
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appCoordinator)
                .onAppear {
                    Task {
                        await appCoordinator.initialize()
                    }
                }
                .onDisappear {
                    Task {
                        await appCoordinator.shutdown()
                    }
                }
        }
    }
}

// MARK: - App Coordinator

/// Coordinates the overall iOS app lifecycle and navigation
@MainActor
public final class AppCoordinator: ObservableObject {
    
    // MARK: - Properties
    @Published public private(set) var isInitialized = false
    @Published public private(set) var initializationError: String? = nil
    @Published public private(set) var orchestrator: TaskManagerOrchestrator?
    
    // Navigation state
    @Published public var selectedTab: AppTab = .tasks
    @Published public var navigationPath = NavigationPath()
    @Published public var presentedSheet: PresentedSheet?
    @Published public var presentedFullScreenCover: PresentedFullScreenCover?
    
    // MARK: - Initialization
    
    public func initialize() async {
        do {
            let newOrchestrator = try await TaskManagerOrchestrator()
            orchestrator = newOrchestrator
            isInitialized = true
            initializationError = nil
        } catch {
            initializationError = "Failed to initialize app: \(error.localizedDescription)"
            isInitialized = false
        }
    }
    
    public func shutdown() async {
        await orchestrator?.shutdown()
        orchestrator = nil
        isInitialized = false
    }
    
    // MARK: - Navigation
    
    public func navigate(to route: TaskManagerRoute) async {
        guard let orchestrator = orchestrator else { return }
        
        await orchestrator.navigate(to: route)
        
        switch route {
        case .taskList:
            selectedTab = .tasks
            navigationPath = NavigationPath()
            
        case .taskDetail(let taskId):
            selectedTab = .tasks
            navigationPath.append(route)
            
        case .createTask:
            presentedSheet = .createTask
            
        case .settings:
            presentedSheet = .settings
        }
    }
    
    public func dismissSheet() {
        presentedSheet = nil
    }
    
    public func dismissFullScreenCover() {
        presentedFullScreenCover = nil
    }
}

// MARK: - Content View

/// Main content view with tab-based navigation
public struct ContentView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    public var body: some View {
        Group {
            if appCoordinator.isInitialized {
                mainContent
            } else if let error = appCoordinator.initializationError {
                errorView(error)
            } else {
                loadingView
            }
        }
    }
    
    private var mainContent: some View {
        TabView(selection: $appCoordinator.selectedTab) {
            tasksTab
                .tabItem {
                    Label("Tasks", systemImage: "list.bullet")
                }
                .tag(AppTab.tasks)
            
            statisticsTab
                .tabItem {
                    Label("Statistics", systemImage: "chart.pie")
                }
                .tag(AppTab.statistics)
        }
        .sheet(item: $appCoordinator.presentedSheet) { sheet in
            sheetContent(for: sheet)
        }
        .fullScreenCover(item: $appCoordinator.presentedFullScreenCover) { cover in
            fullScreenCoverContent(for: cover)
        }
    }
    
    private var tasksTab: some View {
        NavigationStack(path: $appCoordinator.navigationPath) {
            Group {
                if let orchestrator = appCoordinator.orchestrator {
                    TaskListNavigationView(orchestrator: orchestrator)
                } else {
                    Text("Loading...")
                }
            }
            .navigationDestination(for: TaskManagerRoute.self) { route in
                destinationView(for: route)
            }
        }
    }
    
    private var statisticsTab: some View {
        NavigationStack {
            Group {
                if let orchestrator = appCoordinator.orchestrator {
                    StatisticsView(orchestrator: orchestrator)
                } else {
                    Text("Loading...")
                }
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: TaskManagerRoute) -> some View {
        if let orchestrator = appCoordinator.orchestrator {
            switch route {
            case .taskDetail(let taskId):
                TaskDetailNavigationView(orchestrator: orchestrator, taskId: taskId)
            default:
                Text("Unknown route")
            }
        } else {
            Text("Loading...")
        }
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: PresentedSheet) -> some View {
        if let orchestrator = appCoordinator.orchestrator {
            switch sheet {
            case .createTask:
                CreateTaskNavigationView(orchestrator: orchestrator) {
                    appCoordinator.dismissSheet()
                }
            case .settings:
                TaskSettingsNavigationView(orchestrator: orchestrator) {
                    appCoordinator.dismissSheet()
                }
            }
        } else {
            Text("Loading...")
        }
    }
    
    @ViewBuilder
    private func fullScreenCoverContent(for cover: PresentedFullScreenCover) -> some View {
        Text("Full screen content") // Placeholder for future full-screen views
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Initializing Task Manager...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Initialization Failed")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                Task {
                    await appCoordinator.initialize()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Navigation Wrapper Views

/// Wrapper view for task list with proper context management
public struct TaskListNavigationView: View {
    let orchestrator: TaskManagerOrchestrator
    @State private var context: TaskListContext?
    
    public init(orchestrator: TaskManagerOrchestrator) {
        self.orchestrator = orchestrator
    }
    
    public var body: some View {
        Group {
            if let context = context {
                TaskListView(context: context)
            } else {
                ProgressView("Loading tasks...")
            }
        }
        .onAppear {
            Task {
                if context == nil {
                    context = try? await orchestrator.createContext(type: TaskListContext.self, identifier: "main")
                }
            }
        }
    }
}

/// Wrapper view for task detail with proper context management
public struct TaskDetailNavigationView: View {
    let orchestrator: TaskManagerOrchestrator
    let taskId: UUID
    @State private var context: TaskDetailContext?
    
    public init(orchestrator: TaskManagerOrchestrator, taskId: UUID) {
        self.orchestrator = orchestrator
        self.taskId = taskId
    }
    
    public var body: some View {
        Group {
            if let context = context {
                TaskDetailView(context: context)
            } else {
                ProgressView("Loading task...")
            }
        }
        .onAppear {
            Task {
                if context == nil {
                    context = try? await orchestrator.createContext(type: TaskDetailContext.self, identifier: "detail-\(taskId)")
                    await context?.setTaskId(taskId)
                }
            }
        }
    }
}

/// Wrapper view for create task with proper context management
public struct CreateTaskNavigationView: View {
    let orchestrator: TaskManagerOrchestrator
    let onDismiss: () -> Void
    @State private var context: CreateTaskContext?
    
    public init(orchestrator: TaskManagerOrchestrator, onDismiss: @escaping () -> Void) {
        self.orchestrator = orchestrator
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        Group {
            if let context = context {
                CreateTaskView(context: context)
                    .onReceive(NotificationCenter.default.publisher(for: .taskCreated)) { _ in
                        onDismiss()
                    }
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            Task {
                if context == nil {
                    context = try? await orchestrator.createContext(type: CreateTaskContext.self, identifier: "create")
                }
            }
        }
    }
}

/// Wrapper view for settings with proper context management
public struct TaskSettingsNavigationView: View {
    let orchestrator: TaskManagerOrchestrator
    let onDismiss: () -> Void
    @State private var context: TaskSettingsContext?
    
    public init(orchestrator: TaskManagerOrchestrator, onDismiss: @escaping () -> Void) {
        self.orchestrator = orchestrator
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        Group {
            if let context = context {
                TaskSettingsView(context: context)
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            Task {
                if context == nil {
                    let client = await orchestrator.getTaskClient()
                    let storage = await orchestrator.getStorageCapability()
                    context = TaskSettingsContext(client: client, storage: storage)
                }
            }
        }
    }
}

/// Simple statistics view
public struct StatisticsView: View {
    let orchestrator: TaskManagerOrchestrator
    @State private var statistics: TaskStatistics?
    
    public init(orchestrator: TaskManagerOrchestrator) {
        self.orchestrator = orchestrator
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            if let stats = statistics {
                VStack(spacing: 16) {
                    Text("Task Statistics")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    StatisticCard(title: "Total Tasks", value: "\(stats.totalTasks)", color: .blue)
                    StatisticCard(title: "Completed", value: "\(stats.completedTasks)", color: .green)
                    StatisticCard(title: "Pending", value: "\(stats.pendingTasks)", color: .orange)
                    StatisticCard(title: "Overdue", value: "\(stats.overdueTasks)", color: .red)
                    
                    if stats.totalTasks > 0 {
                        VStack(spacing: 8) {
                            Text("Completion Rate")
                                .font(.headline)
                            
                            ProgressView(value: stats.completionPercentage)
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                            
                            Text("\(Int(stats.completionPercentage * 100))%")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            } else {
                ProgressView("Loading statistics...")
            }
        }
        .navigationTitle("Statistics")
        .onAppear {
            Task {
                let client = await orchestrator.getTaskClient()
                statistics = await client.getStatistics()
            }
        }
        .refreshable {
            Task {
                let client = await orchestrator.getTaskClient()
                statistics = await client.getStatistics()
            }
        }
    }
}

private struct StatisticCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Types

public enum AppTab: String, CaseIterable {
    case tasks = "tasks"
    case statistics = "statistics"
}

public enum PresentedSheet: String, Identifiable {
    case createTask = "createTask"
    case settings = "settings"
    
    public var id: String { rawValue }
}

public enum PresentedFullScreenCover: String, Identifiable {
    case onboarding = "onboarding"
    
    public var id: String { rawValue }
}

// MARK: - Notifications

extension Notification.Name {
    static let taskCreated = Notification.Name("taskCreated")
    static let taskUpdated = Notification.Name("taskUpdated")
    static let taskDeleted = Notification.Name("taskDeleted")
}