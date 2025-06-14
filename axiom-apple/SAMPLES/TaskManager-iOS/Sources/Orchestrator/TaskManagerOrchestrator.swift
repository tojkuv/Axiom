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

// MARK: - Task Manager Orchestrator (iOS)

/// Main orchestrator for the iOS Task Manager application
public actor TaskManagerOrchestrator: ExtendedOrchestrator {
    
    // MARK: - Properties
    private let taskClient: TaskClient
    private let storageCapability: any TaskStorageCapability
    private var contexts: [String: any Context] = [:]
    private var currentRoute: TaskManagerRoute?
    private var navigationHistory: [TaskManagerRoute] = []
    
    // Dependency injection
    private var clients: [String: any Client] = [:]
    private var capabilities: [String: any Capability] = [:]
    
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
    }
    
    // MARK: - ExtendedOrchestrator Implementation
    
    public func createContext<P: Presentation>(for presentation: P.Type) async -> P.ContextType {
        // This method needs to be implemented based on the specific presentation type
        // For now, we'll use a factory pattern based on presentation type name
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
        
        // Create new context based on type
        let context: T
        
        switch type {
        case is TaskListContext.Type:
            context = TaskListContext(client: taskClient) as! T
            
        case is TaskDetailContext.Type:
            context = TaskDetailContext(client: taskClient) as! T
            
        case is CreateTaskContext.Type:
            context = CreateTaskContext(client: taskClient) as! T
            
        case is TaskSettingsContext.Type:
            context = TaskSettingsContext(client: taskClient, storage: storageCapability) as! T
            
        default:
            throw AxiomError.contextError(.initializationFailed("Unknown context type: \(type)"))
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
        // Convert StandardRoute to TaskManagerRoute if needed
        if let taskRoute = route as? TaskManagerRoute {
            currentRoute = taskRoute
            navigationHistory.append(taskRoute)
        }
    }
    
    // MARK: - Task Manager Specific Navigation
    
    public func navigate(to route: TaskManagerRoute) async {
        currentRoute = route
        navigationHistory.append(route)
        
        // Create or retrieve context for the route
        switch route {
        case .taskList:
            _ = try? await createContext(type: TaskListContext.self, identifier: "main")
            
        case .taskDetail(let taskId):
            let context = try? await createContext(type: TaskDetailContext.self, identifier: "detail-\(taskId)")
            await context?.setTaskId(taskId)
            
        case .createTask:
            _ = try? await createContext(type: CreateTaskContext.self, identifier: "create")
            
        case .settings:
            _ = try? await createContext(type: TaskSettingsContext.self, identifier: "settings")
        }
    }
    
    // MARK: - Data Management
    
    private func registerDefaultDependencies() async {
        // Register the task client
        await registerClient(taskClient, for: "taskClient")
        
        // Register storage capability
        await registerCapability(storageCapability, for: "storage")
    }
    
    private func loadInitialData() async throws {
        // Load tasks from storage
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
    
    // MARK: - Lifecycle Management
    
    public func shutdown() async {
        // Deactivate all contexts
        await deactivateAllContexts()
        
        // Deactivate capabilities
        await storageCapability.deactivate()
        
        // Clear references
        contexts.removeAll()
        clients.removeAll()
        capabilities.removeAll()
    }
}

// MARK: - Task Manager Routes

/// Routes specific to the Task Manager application
public enum TaskManagerRoute: TypeSafeRoute {
    case taskList
    case taskDetail(taskId: UUID)
    case createTask
    case settings
    
    public var pathComponents: String {
        switch self {
        case .taskList:
            return "/tasks"
        case .taskDetail(let taskId):
            return "/tasks/\(taskId)"
        case .createTask:
            return "/tasks/create"
        case .settings:
            return "/settings"
        }
    }
    
    public var queryParameters: [String: String] {
        return [:]
    }
    
    public var routeIdentifier: String {
        switch self {
        case .taskList:
            return "taskList"
        case .taskDetail(let taskId):
            return "taskDetail-\(taskId)"
        case .createTask:
            return "createTask"
        case .settings:
            return "settings"
        }
    }
    
    public var presentation: PresentationStyle {
        switch self {
        case .taskList:
            return .replace
        case .taskDetail:
            return .push
        case .createTask:
            return .present(.sheet)
        case .settings:
            return .present(.sheet)
        }
    }
}

// MARK: - Forward Declarations for Contexts

// These would be implemented in separate files
@MainActor
public class TaskListContext: ClientObservingContext<TaskClient> {
    public required init() {
        fatalError("Use init(client:) instead")
    }
    
    public init(client: TaskClient) {
        super.init(client: client)
    }
}

@MainActor
public class TaskDetailContext: ClientObservingContext<TaskClient> {
    private var taskId: UUID?
    
    public required init() {
        fatalError("Use init(client:) instead")
    }
    
    public init(client: TaskClient) {
        super.init(client: client)
    }
    
    public func setTaskId(_ id: UUID) async {
        taskId = id
        notifyUpdate()
    }
    
    public func getTaskId() async -> UUID? {
        return taskId
    }
}

@MainActor
public class CreateTaskContext: ClientObservingContext<TaskClient> {
    public required init() {
        fatalError("Use init(client:) instead")
    }
    
    public init(client: TaskClient) {
        super.init(client: client)
    }
}

@MainActor
public class TaskSettingsContext: ObservableContext {
    private let client: TaskClient
    private let storage: any TaskStorageCapability
    
    public required init() {
        fatalError("Use init(client:storage:) instead")
    }
    
    public init(client: TaskClient, storage: any TaskStorageCapability) {
        self.client = client
        self.storage = storage
        super.init()
    }
    
    public func getClient() -> TaskClient {
        return client
    }
    
    public func getStorage() -> any TaskStorageCapability {
        return storage
    }
}