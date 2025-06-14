import Foundation
import SwiftUI
import Axiom

// Import shared Task Manager components
import TaskManager_Shared

// MARK: - Task Manager Orchestrator (macOS)

/// Main orchestrator for the macOS Task Manager application with window management
public actor TaskManagerOrchestrator: ExtendedOrchestrator {
    
    // MARK: - Properties
    private let taskClient: TaskClient
    private let storageCapability: any TaskStorageCapability
    private var contexts: [String: any Context] = [:]
    private var windows: [String: WindowConfiguration] = [:]
    private var currentRoute: TaskManagerRoute?
    private var navigationHistory: [TaskManagerRoute] = []
    
    // Dependency injection
    private var clients: [String: any Client] = [:]
    private var capabilities: [String: any Capability] = [:]
    
    // Window management
    private var windowControllers: [String: NSWindowController] = [:]
    
    // MARK: - Initialization
    
    public init() async throws {
        // Initialize storage capability
        self.storageCapability = try LocalTaskStorageCapability()
        
        // Initialize task client with storage
        self.taskClient = TaskClient(storage: storageCapability)
        
        // Activate storage capability
        try await storageCapability.activate()
        
        // Register default dependencies
        await self.registerDefaultDependencies()
        
        // Load initial data
        try await self.loadInitialData()
        
        // Setup default windows
        await self.setupDefaultWindows()
    }
    
    // MARK: - ExtendedOrchestrator Implementation
    
    public func createContext<P: Presentation>(for presentation: P.Type) async -> P.ContextType {
        let typeName = String(describing: presentation)
        
        switch typeName {
        case "TaskListView":
            let context = TaskListContext(client: taskClient)
            await storeContext(context, for: "TaskListContext")
            return context as! P.ContextType
            
        case "TaskDetailView":
            let context = TaskDetailContext(client: taskClient)
            await storeContext(context, for: "TaskDetailContext")
            return context as! P.ContextType
            
        case "CreateTaskView":
            let context = CreateTaskContext(client: taskClient)
            await storeContext(context, for: "CreateTaskContext")
            return context as! P.ContextType
            
        case "TaskSettingsView":
            let context = TaskSettingsContext(client: taskClient, storage: storageCapability)
            await storeContext(context, for: "TaskSettingsContext")
            return context as! P.ContextType
            
        case "TaskStatisticsView":
            let context = TaskStatisticsContext(client: taskClient)
            await storeContext(context, for: "TaskStatisticsContext")
            return context as! P.ContextType
            
        default:
            fatalError("Unknown presentation type: \(typeName)")
        }
    }
    
    public func createContext<T: Context & Sendable>(
        type: T.Type,
        identifier: String? = nil,
        dependencies: [String] = []
    ) async throws -> T {
        let contextId = identifier ?? UUID().uuidString
        
        // Check if context already exists
        if let existingContext = contexts[contextId] as? T {
            return existingContext
        }
        
        // Create new context based on type (must run on MainActor for SwiftUI contexts)
        let context: T = await MainActor.run {
            switch type {
            case is TaskListContext.Type:
                return TaskListContext(client: taskClient) as! T
                
            case is TaskDetailContext.Type:
                return TaskDetailContext(client: taskClient) as! T
                
            case is CreateTaskContext.Type:
                return CreateTaskContext(client: taskClient) as! T
                
            case is TaskSettingsContext.Type:
                return TaskSettingsContext(client: taskClient, storage: storageCapability) as! T
                
            case is TaskStatisticsContext.Type:
                return TaskStatisticsContext(client: taskClient) as! T
                
            default:
                fatalError("Unknown context type: \(type)")
            }
        }
        
        // Store and activate context
        contexts[contextId] = context
        try await context.activate()
        
        return context
    }
    
    public func registerClient<C: Client>(_ client: C, for key: String) async {
        clients[key] = client
    }
    
    public func registerCapability<C: Capability>(_ capability: C, for key: String) async {
        capabilities[key] = capability
    }
    
    public func isCapabilityAvailable(_ key: String) async -> Bool {
        guard let capability = capabilities[key] else { return false }
        return await capability.isAvailable
    }
    
    public func contextBuilder<T: Context>(for type: T.Type) async -> OrchestratorContextBuilder<T> {
        OrchestratorContextBuilder(orchestrator: self, contextType: type)
    }
    
    public func navigate(to route: StandardRoute) async {
        if let taskRoute = route as? TaskManagerRoute {
            await navigate(to: taskRoute)
        }
    }
    
    // MARK: - macOS-Specific Navigation
    
    public func navigate(to route: TaskManagerRoute, in windowId: String = "main") async {
        currentRoute = route
        navigationHistory.append(route)
        
        // Handle window-specific navigation
        switch route {
        case .taskList:
            await showMainWindow()
            
        case .taskDetail(let taskId):
            await showTaskDetailWindow(taskId: taskId)
            
        case .createTask:
            await showCreateTaskWindow()
            
        case .settings:
            await showSettingsWindow()
            
        default:
            // Handle other routes with default main window
            await showMainWindow()
        }
    }
    
    // MARK: - Window Management
    
    private func setupDefaultWindows() async {
        // Define default window configurations
        let mainWindow = WindowConfiguration(
            id: "main",
            title: "Task Manager",
            contentSize: CGSize(width: 1000, height: 700),
            minSize: CGSize(width: 600, height: 400),
            windowType: .main
        )
        
        let detailWindow = WindowConfiguration(
            id: "detail",
            title: "Task Details",
            contentSize: CGSize(width: 600, height: 500),
            minSize: CGSize(width: 400, height: 300),
            windowType: .detail
        )
        
        let createWindow = WindowConfiguration(
            id: "create",
            title: "New Task",
            contentSize: CGSize(width: 500, height: 600),
            minSize: CGSize(width: 400, height: 500),
            windowType: .modal
        )
        
        let settingsWindow = WindowConfiguration(
            id: "settings",
            title: "Settings",
            contentSize: CGSize(width: 600, height: 500),
            minSize: CGSize(width: 500, height: 400),
            windowType: .settings
        )
        
        windows["main"] = mainWindow
        windows["detail"] = detailWindow
        windows["create"] = createWindow
        windows["settings"] = settingsWindow
    }
    
    public func showMainWindow() async {
        guard let windowConfig = windows["main"] else { return }
        await showWindow(with: windowConfig)
    }
    
    public func showTaskDetailWindow(taskId: UUID) async {
        guard let windowConfig = windows["detail"] else { return }
        
        // Create context for this specific task
        let context = try? await createContext(type: TaskDetailContext.self, identifier: "detail-\(taskId)")
        await context?.setTaskId(taskId)
        
        var modifiedConfig = windowConfig
        modifiedConfig.title = "Task Details"
        modifiedConfig.id = "detail-\(taskId)"
        
        await showWindow(with: modifiedConfig)
    }
    
    public func showCreateTaskWindow() async {
        guard let windowConfig = windows["create"] else { return }
        
        // Create fresh context for new task
        let context = try? await createContext(type: CreateTaskContext.self, identifier: "create-\(UUID())")
        
        await showWindow(with: windowConfig)
    }
    
    public func showSettingsWindow() async {
        guard let windowConfig = windows["settings"] else { return }
        await showWindow(with: windowConfig)
    }
    
    private func showWindow(with configuration: WindowConfiguration) async {
        // In a real macOS app, this would create/show NSWindow instances
        // For this sample, we'll track window state
        print("Showing window: \(configuration.title) (\(configuration.id))")
    }
    
    public func closeWindow(withId windowId: String) async {
        windowControllers.removeValue(forKey: windowId)
    }
    
    public func getActiveWindows() async -> [String] {
        return Array(windowControllers.keys)
    }
    
    // MARK: - Data Management
    
    private func registerDefaultDependencies() async {
        await registerClient(taskClient, for: "taskClient")
        await registerCapability(storageCapability, for: "storage")
    }
    
    private func loadInitialData() async throws {
        try await taskClient.process(.loadTasks)
    }
    
    public func storeContext(_ context: any Context, for identifier: String) async {
        contexts[identifier] = context
    }
    
    // MARK: - Context Management
    
    public func getContext<T: Context>(for identifier: String, as type: T.Type) async -> T? {
        return contexts[identifier] as? T
    }
    
    public func activateAllContexts() async {
        for context in contexts.values {
            try? await context.activate()
        }
    }
    
    public func deactivateAllContexts() async {
        for context in contexts.values {
            await context.deactivate()
        }
    }
    
    // MARK: - Public Access Methods
    
    public func getTaskClient() async -> TaskClient {
        return taskClient
    }
    
    public func getStorageCapability() async -> any TaskStorageCapability {
        return storageCapability
    }
    
    public func getCurrentRoute() async -> TaskManagerRoute? {
        return currentRoute
    }
    
    public func getNavigationHistory() async -> [TaskManagerRoute] {
        return navigationHistory
    }
    
    // MARK: - Menu Management (macOS-specific)
    
    public func updateMenus() async {
        // In a real macOS app, this would update menu items based on current state
        let state = await taskClient.getCurrentState()
        
        // Enable/disable menu items based on state
        let hasTask = !state.tasks.isEmpty
        let hasSelection = false // Would be determined by current view state
        
        await updateMenuItemStates(hasTask: hasTask, hasSelection: hasSelection)
    }
    
    private func updateMenuItemStates(hasTask: Bool, hasSelection: Bool) async {
        // Update menu item states
        print("Updating menu states - Has tasks: \(hasTask), Has selection: \(hasSelection)")
    }
    
    // MARK: - Lifecycle Management
    
    public func shutdown() async {
        // Close all windows
        for windowId in windowControllers.keys {
            await closeWindow(withId: windowId)
        }
        
        // Deactivate all contexts
        await deactivateAllContexts()
        
        // Deactivate capabilities
        await storageCapability.deactivate()
        
        // Clear references
        contexts.removeAll()
        clients.removeAll()
        capabilities.removeAll()
        windows.removeAll()
        windowControllers.removeAll()
    }
}

// MARK: - macOS Window Configuration

public struct WindowConfiguration {
    public var id: String
    public var title: String
    public var contentSize: CGSize
    public var minSize: CGSize
    public var maxSize: CGSize?
    public var windowType: WindowType
    public var isResizable: Bool
    public var hasTitleBar: Bool
    public var hasCloseButton: Bool
    public var hasMinimizeButton: Bool
    public var hasZoomButton: Bool
    
    public enum WindowType {
        case main
        case detail
        case modal
        case settings
        case inspector
        case palette
    }
    
    public init(
        id: String,
        title: String,
        contentSize: CGSize,
        minSize: CGSize,
        maxSize: CGSize? = nil,
        windowType: WindowType = .main,
        isResizable: Bool = true,
        hasTitleBar: Bool = true,
        hasCloseButton: Bool = true,
        hasMinimizeButton: Bool = true,
        hasZoomButton: Bool = true
    ) {
        self.id = id
        self.title = title
        self.contentSize = contentSize
        self.minSize = minSize
        self.maxSize = maxSize
        self.windowType = windowType
        self.isResizable = isResizable
        self.hasTitleBar = hasTitleBar
        self.hasCloseButton = hasCloseButton
        self.hasMinimizeButton = hasMinimizeButton
        self.hasZoomButton = hasZoomButton
    }
}

// MARK: - Task Manager Routes (macOS-specific extensions)

extension TaskManagerRoute {
    /// Returns the preferred window type for this route
    public var preferredWindowType: WindowConfiguration.WindowType {
        switch self {
        case .taskList:
            return .main
        case .taskDetail:
            return .detail
        case .createTask:
            return .modal
        case .settings:
            return .settings
        default:
            return .main
        }
    }
    
    /// Returns whether this route should open in a new window
    public var shouldOpenInNewWindow: Bool {
        switch self {
        case .taskList:
            return false
        case .taskDetail:
            return true
        case .createTask:
            return true
        case .settings:
            return true
        default:
            return false
        }
    }
}

