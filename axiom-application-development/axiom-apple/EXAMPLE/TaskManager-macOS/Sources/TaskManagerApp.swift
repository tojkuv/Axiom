import SwiftUI
import Axiom

// Import shared Task Manager components
import TaskManager_Shared

// MARK: - Task Manager macOS App

/// Main macOS application entry point for Task Manager with comprehensive window management
@main
public struct TaskManagerApp: App {
    
    @StateObject private var appCoordinator = AppCoordinator()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    public init() {}
    
    public var body: some Scene {
        // Main window
        WindowGroup("Task Manager") {
            MainWindowView()
                .environmentObject(appCoordinator)
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    _Concurrency.Task {
                        await appCoordinator.initialize()
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            appMenuCommands
            fileMenuCommands
            editMenuCommands
            viewMenuCommands
            windowMenuCommands
        }
        
        // Settings window
        Settings {
            SettingsWindowView()
                .environmentObject(appCoordinator)
        }
        
        // Additional windows for task details
        WindowGroup("Task Details", id: "task-detail", for: UUID.self) { $taskId in
            if let taskId = taskId {
                TaskDetailWindowView(taskId: taskId)
                    .environmentObject(appCoordinator)
            } else {
                Text("Invalid task")
            }
        }
        .windowStyle(.titleBar)
        
        // Create task window
        WindowGroup("New Task", id: "create-task") {
            CreateTaskWindowView()
                .environmentObject(appCoordinator)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 600, height: 550)
        
        // Statistics window
        WindowGroup("Statistics", id: "statistics") {
            StatisticsWindowView()
                .environmentObject(appCoordinator)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 800, height: 600)
    }
    
    // MARK: - Menu Commands
    
    private var appMenuCommands: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About Task Manager") {
                // Show about window
            }
        }
    }
    
    private var fileMenuCommands: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Task") {
                _Concurrency.Task {
                    await appCoordinator.openCreateTaskWindow()
                }
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Divider()
            
            Button("Import Tasks...") {
                _Concurrency.Task {
                    await appCoordinator.importTasks()
                }
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])
            
            Button("Export Tasks...") {
                _Concurrency.Task {
                    await appCoordinator.exportTasks()
                }
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
        }
    }
    
    private var editMenuCommands: some Commands {
        CommandGroup(after: .undoRedo) {
            Button("Select All Tasks") {
                _Concurrency.Task {
                    await appCoordinator.selectAllTasks()
                }
            }
            .keyboardShortcut("a", modifiers: .command)
            
            Button("Deselect All") {
                _Concurrency.Task {
                    await appCoordinator.deselectAllTasks()
                }
            }
            .keyboardShortcut("d", modifiers: .command)
            
            Divider()
            
            Button("Complete Selected") {
                _Concurrency.Task {
                    await appCoordinator.completeSelectedTasks()
                }
            }
            .keyboardShortcut(.return, modifiers: .command)
            
            Button("Delete Selected") {
                _Concurrency.Task {
                    await appCoordinator.deleteSelectedTasks()
                }
            }
            .keyboardShortcut(.delete, modifiers: [])
        }
    }
    
    private var viewMenuCommands: some Commands {
        CommandGroup(after: .sidebar) {
            Button("Show Statistics") {
                _Concurrency.Task {
                    await appCoordinator.openStatisticsWindow()
                }
            }
            .keyboardShortcut("s", modifiers: [.command, .option])
            
            Divider()
            
            Menu("View Mode") {
                Button("List View") {
                    _Concurrency.Task {
                        await appCoordinator.setViewMode(.list)
                    }
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Grid View") {
                    _Concurrency.Task {
                        await appCoordinator.setViewMode(.grid)
                    }
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Column View") {
                    _Concurrency.Task {
                        await appCoordinator.setViewMode(.column)
                    }
                }
                .keyboardShortcut("3", modifiers: .command)
            }
            
            Menu("Sort By") {
                Button("Created Date") {
                    _Concurrency.Task {
                        await appCoordinator.setSortOrder(.createdDate)
                    }
                }
                
                Button("Title") {
                    _Concurrency.Task {
                        await appCoordinator.setSortOrder(.title)
                    }
                }
                
                Button("Priority") {
                    _Concurrency.Task {
                        await appCoordinator.setSortOrder(.priority)
                    }
                }
                
                Button("Due Date") {
                    _Concurrency.Task {
                        await appCoordinator.setSortOrder(.dueDate)
                    }
                }
            }
        }
    }
    
    private var windowMenuCommands: some Commands {
        CommandGroup(after: .windowArrangement) {
            Button("Main Window") {
                // Focus main window
            }
            .keyboardShortcut("0", modifiers: .command)
            
            Button("New Task Window") {
                _Concurrency.Task {
                    await appCoordinator.openCreateTaskWindow()
                }
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }
    }
}

// MARK: - App Delegate

public class AppDelegate: NSObject, NSApplicationDelegate {
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure application-level settings
        NSApp.setActivationPolicy(.regular)
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        // Cleanup before termination
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - App Coordinator

/// Coordinates the overall macOS app lifecycle, navigation, and window management
@MainActor
public final class AppCoordinator: ObservableObject {
    
    // MARK: - Properties
    @Published public private(set) var isInitialized = false
    @Published public private(set) var initializationError: String? = nil
    @Published public private(set) var orchestrator: TaskManagerOrchestrator?
    
    // Window management
    @Published public private(set) var openWindows: Set<String> = []
    
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
    
    // MARK: - Window Management
    
    public func openCreateTaskWindow() async {
        guard let orchestrator = orchestrator else { return }
        await orchestrator.showCreateTaskWindow()
        openWindows.insert("create-task")
    }
    
    public func openTaskDetailWindow(taskId: UUID) async {
        guard let orchestrator = orchestrator else { return }
        await orchestrator.showTaskDetailWindow(taskId: taskId)
        openWindows.insert("task-detail-\(taskId)")
    }
    
    public func openStatisticsWindow() async {
        guard let orchestrator = orchestrator else { return }
        openWindows.insert("statistics")
        // Open statistics window
    }
    
    public func closeWindow(_ windowId: String) async {
        openWindows.remove(windowId)
        await orchestrator?.closeWindow(withId: windowId)
    }
    
    // MARK: - Task Management Actions
    
    public func selectAllTasks() async {
        // Implement select all for main window
    }
    
    public func deselectAllTasks() async {
        // Implement deselect all for main window
    }
    
    public func completeSelectedTasks() async {
        // Implement complete selected for main window
    }
    
    public func deleteSelectedTasks() async {
        // Implement delete selected for main window
    }
    
    public func setViewMode(_ mode: ViewMode) async {
        // Implement view mode change for main window
    }
    
    public func setSortOrder(_ sortOrder: Task.SortOrder) async {
        // Implement sort order change for main window
    }
    
    // MARK: - Data Management
    
    public func exportTasks() async {
        // Implement export functionality
    }
    
    public func importTasks() async {
        // Implement import functionality
    }
}

// MARK: - Main Window View

public struct MainWindowView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var taskListContext: TaskListContext?
    
    public var body: some View {
        Group {
            if appCoordinator.isInitialized {
                if let context = taskListContext {
                    TaskListView(context: context)
                } else {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if let error = appCoordinator.initializationError {
                errorView(error)
            } else {
                loadingView
            }
        }
        .onAppear {
            _Concurrency.Task {
                if let orchestrator = appCoordinator.orchestrator {
                    taskListContext = try? await orchestrator.createContext(
                        type: TaskListContext.self,
                        identifier: "main"
                    )
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Initializing Task Manager...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                _Concurrency.Task {
                    await appCoordinator.initialize()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Window Views

public struct TaskDetailWindowView: View {
    let taskId: UUID
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var context: TaskDetailContext?
    
    public var body: some View {
        Group {
            if let context = context {
                TaskDetailView(context: context)
            } else {
                ProgressView("Loading task...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            _Concurrency.Task {
                if let orchestrator = appCoordinator.orchestrator {
                    context = try? await orchestrator.createContext(
                        type: TaskDetailContext.self,
                        identifier: "detail-\(taskId)"
                    )
                    await context?.setTaskId(taskId)
                }
            }
        }
    }
}

public struct CreateTaskWindowView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var context: CreateTaskContext?
    
    public var body: some View {
        Group {
            if let context = context {
                CreateTaskView(context: context)
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            _Concurrency.Task {
                if let orchestrator = appCoordinator.orchestrator {
                    context = try? await orchestrator.createContext(
                        type: CreateTaskContext.self,
                        identifier: "create-\(UUID())"
                    )
                }
            }
        }
    }
}

public struct SettingsWindowView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var context: TaskSettingsContext?
    
    public var body: some View {
        Group {
            if let context = context {
                TaskSettingsView(context: context)
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            _Concurrency.Task {
                if let orchestrator = appCoordinator.orchestrator {
                    let client = await orchestrator.getTaskClient()
                    let storage = await orchestrator.getStorageCapability()
                    context = TaskSettingsContext(client: client, storage: storage)
                }
            }
        }
    }
}

public struct StatisticsWindowView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var context: TaskStatisticsContext?
    
    public var body: some View {
        Group {
            if let context = context {
                TaskStatisticsView(context: context)
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            _Concurrency.Task {
                if let orchestrator = appCoordinator.orchestrator {
                    context = try? await orchestrator.createContext(
                        type: TaskStatisticsContext.self,
                        identifier: "statistics"
                    )
                }
            }
        }
    }
}

// MARK: - Statistics View Placeholder

public struct TaskStatisticsView: View {
    let context: TaskStatisticsContext
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Task Statistics")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Comprehensive statistics view coming soon...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Placeholder content
            VStack(spacing: 16) {
                StatCard(title: "Total Tasks", value: "0", color: .blue)
                StatCard(title: "Completed", value: "0", color: .green)
                StatCard(title: "Pending", value: "0", color: .orange)
                StatCard(title: "Overdue", value: "0", color: .red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
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
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}