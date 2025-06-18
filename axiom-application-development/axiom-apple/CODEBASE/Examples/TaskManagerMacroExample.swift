import Foundation
import AxiomCore
import AxiomArchitecture
import AxiomMacros

// MARK: - Task Manager Example: Complete Implementation Using All Axiom Macros

/// This file demonstrates a complete Task Manager implementation using all Axiom macros
/// as specified in the Axiom Apple Macro Integration Plan.
/// 
/// Macros demonstrated:
/// - @AxiomState: Automatic state protocol conformance
/// - @AxiomAction: Action pattern generation  
/// - @AxiomClient: Client boilerplate generation
/// - @AxiomContext: Context lifecycle automation
/// - @AxiomCapability: Capability registration
/// - @AxiomErrorRecovery: Error handling automation

// MARK: - Domain Models

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: Priority
    var dueDate: Date?
    var category: Category
    
    init(title: String, description: String = "", priority: Priority = .medium, dueDate: Date? = nil, category: Category = .personal) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.isCompleted = false
        self.priority = priority
        self.dueDate = dueDate
        self.category = category
    }
}

enum Priority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
}

enum Category: String, CaseIterable, Codable {
    case personal = "Personal"
    case work = "Work"
    case shopping = "Shopping"
    case health = "Health"
}

// MARK: - State Management with @AxiomState

/// Task Manager State with automatic AxiomState protocol conformance
@AxiomState(validation: true, optimizeEquality: true, memoryOptimized: true)
struct TaskManagerState {
    let tasks: [Task]
    let selectedTask: Task?
    let filter: TaskFilter
    let isLoading: Bool
    let error: TaskError?
    
    init(tasks: [Task] = [], selectedTask: Task? = nil, filter: TaskFilter = .all, isLoading: Bool = false, error: TaskError? = nil) {
        self.tasks = tasks
        self.selectedTask = selectedTask
        self.filter = filter
        self.isLoading = isLoading
        self.error = error
    }
}

/// Task Filter State
@AxiomState
struct TaskFilter {
    let showCompleted: Bool
    let priority: Priority?
    let category: Category?
    let searchText: String
    
    static let all = TaskFilter(showCompleted: true, priority: nil, category: nil, searchText: "")
}

// MARK: - Actions with @AxiomAction

/// Task Manager Actions with automatic action protocol conformance
@AxiomAction(validation: true, performance: true, retry: false)
enum TaskManagerAction {
    case addTask(Task)
    case updateTask(Task)
    case deleteTask(UUID)
    case toggleTaskCompletion(UUID)
    case selectTask(UUID?)
    case setFilter(TaskFilter)
    case loadTasks
    case searchTasks(String)
    case setError(TaskError?)
    case clearError
}

/// Task Error with automatic action protocol conformance
@AxiomAction
enum TaskError: Error {
    case taskNotFound(UUID)
    case invalidTaskData(String)
    case persistenceError(String)
    case networkError(String)
}

// MARK: - Client with @AxiomClient

/// Task Manager Client with automatic AxiomClient protocol conformance
@Client(state: TaskManagerState.self)
actor TaskManagerClient {
    
    // MARK: - Error Recovery with @AxiomErrorRecovery
    
    @AxiomErrorRecovery(.retry(attempts: 3, delay: 1.0))
    func loadTasks() async throws -> [Task] {
        // Simulate loading tasks from persistence
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Simulate potential failure
        if Bool.random() && Bool.random() { // 25% chance of failure
            throw TaskError.persistenceError("Failed to load tasks from storage")
        }
        
        return [
            Task(title: "Complete project documentation", priority: .high, category: .work),
            Task(title: "Buy groceries", priority: .medium, category: .shopping),
            Task(title: "Exercise for 30 minutes", priority: .low, category: .health),
            Task(title: "Call dentist", priority: .urgent, category: .personal)
        ]
    }
    
    @AxiomErrorRecovery(.circuitBreaker(threshold: 5, timeout: 60.0))
    func saveTasks(_ tasks: [Task]) async throws {
        // Simulate saving tasks to persistence
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Simulate potential failure
        if Bool.random() && Bool.random() && Bool.random() { // 12.5% chance of failure
            throw TaskError.persistenceError("Failed to save tasks to storage")
        }
    }
    
    // MARK: - Business Logic
    
    func addTask(_ task: Task) async {
        let currentState = await getCurrentState()
        var newTasks = currentState.tasks
        newTasks.append(task)
        
        let newState = TaskManagerState(
            tasks: newTasks,
            selectedTask: currentState.selectedTask,
            filter: currentState.filter,
            isLoading: false,
            error: nil
        )
        
        await updateState(newState)
        
        // Persist changes
        do {
            try await saveTasks(newTasks)
        } catch {
            await handleError(TaskError.persistenceError("Failed to save new task"))
        }
    }
    
    func updateTask(_ updatedTask: Task) async {
        let currentState = await getCurrentState()
        var newTasks = currentState.tasks
        
        if let index = newTasks.firstIndex(where: { $0.id == updatedTask.id }) {
            newTasks[index] = updatedTask
            
            let newState = TaskManagerState(
                tasks: newTasks,
                selectedTask: currentState.selectedTask?.id == updatedTask.id ? updatedTask : currentState.selectedTask,
                filter: currentState.filter,
                isLoading: false,
                error: nil
            )
            
            await updateState(newState)
            
            // Persist changes
            do {
                try await saveTasks(newTasks)
            } catch {
                await handleError(TaskError.persistenceError("Failed to update task"))
            }
        } else {
            await handleError(TaskError.taskNotFound(updatedTask.id))
        }
    }
    
    func deleteTask(withId taskId: UUID) async {
        let currentState = await getCurrentState()
        let newTasks = currentState.tasks.filter { $0.id != taskId }
        
        let newState = TaskManagerState(
            tasks: newTasks,
            selectedTask: currentState.selectedTask?.id == taskId ? nil : currentState.selectedTask,
            filter: currentState.filter,
            isLoading: false,
            error: nil
        )
        
        await updateState(newState)
        
        // Persist changes
        do {
            try await saveTasks(newTasks)
        } catch {
            await handleError(TaskError.persistenceError("Failed to delete task"))
        }
    }
    
    func toggleTaskCompletion(taskId: UUID) async {
        let currentState = await getCurrentState()
        var newTasks = currentState.tasks
        
        if let index = newTasks.firstIndex(where: { $0.id == taskId }) {
            newTasks[index].isCompleted.toggle()
            
            let newState = TaskManagerState(
                tasks: newTasks,
                selectedTask: currentState.selectedTask?.id == taskId ? newTasks[index] : currentState.selectedTask,
                filter: currentState.filter,
                isLoading: false,
                error: nil
            )
            
            await updateState(newState)
            
            // Persist changes
            do {
                try await saveTasks(newTasks)
            } catch {
                await handleError(TaskError.persistenceError("Failed to update task completion"))
            }
        } else {
            await handleError(TaskError.taskNotFound(taskId))
        }
    }
    
    private func handleError(_ error: TaskError) async {
        let currentState = await getCurrentState()
        let newState = TaskManagerState(
            tasks: currentState.tasks,
            selectedTask: currentState.selectedTask,
            filter: currentState.filter,
            isLoading: false,
            error: error
        )
        await updateState(newState)
    }
}

// MARK: - Context with @AxiomContext

/// Task List Context with automatic context lifecycle automation
@AxiomContext(isolation: .mainActor, observable: true)
class TaskListContext: ObservableObject {
    @Published var state: TaskManagerState = TaskManagerState()
    @Published var isInitialized: Bool = false
    
    private let client: TaskManagerClient
    
    init(client: TaskManagerClient) {
        self.client = client
    }
    
    // Context lifecycle methods are auto-generated by @AxiomContext macro
    
    func initialize() async {
        await loadTasks()
        isInitialized = true
    }
    
    func loadTasks() async {
        state = TaskManagerState(
            tasks: state.tasks,
            selectedTask: state.selectedTask,
            filter: state.filter,
            isLoading: true,
            error: nil
        )
        
        do {
            let tasks = try await client.loadTasks()
            state = TaskManagerState(
                tasks: tasks,
                selectedTask: state.selectedTask,
                filter: state.filter,
                isLoading: false,
                error: nil
            )
        } catch let error as TaskError {
            state = TaskManagerState(
                tasks: state.tasks,
                selectedTask: state.selectedTask,
                filter: state.filter,
                isLoading: false,
                error: error
            )
        } catch {
            state = TaskManagerState(
                tasks: state.tasks,
                selectedTask: state.selectedTask,
                filter: state.filter,
                isLoading: false,
                error: TaskError.persistenceError(error.localizedDescription)
            )
        }
    }
    
    func addTask(title: String, description: String = "", priority: Priority = .medium, category: Category = .personal) async {
        let newTask = Task(title: title, description: description, priority: priority, category: category)
        await client.addTask(newTask)
        await refreshState()
    }
    
    func updateTask(_ task: Task) async {
        await client.updateTask(task)
        await refreshState()
    }
    
    func deleteTask(_ task: Task) async {
        await client.deleteTask(withId: task.id)
        await refreshState()
    }
    
    func toggleTaskCompletion(_ task: Task) async {
        await client.toggleTaskCompletion(taskId: task.id)
        await refreshState()
    }
    
    private func refreshState() async {
        // Observe client state changes
        // This would typically use the client's state stream
        state = await client.getCurrentState()
    }
}

// MARK: - Capabilities with @AxiomCapability

/// Task Persistence Capability
@AxiomCapability(
    identifier: "task.persistence",
    dependencies: ["storage.local"],
    priority: .high
)
struct TaskPersistenceCapability {
    func saveTasks(_ tasks: [Task]) async throws {
        // Implementation for saving tasks to local storage
        let encoder = JSONEncoder()
        let data = try encoder.encode(tasks)
        
        // Save to UserDefaults for simple persistence
        UserDefaults.standard.set(data, forKey: "saved_tasks")
    }
    
    func loadTasks() async throws -> [Task] {
        // Implementation for loading tasks from local storage
        guard let data = UserDefaults.standard.data(forKey: "saved_tasks") else {
            return []
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([Task].self, from: data)
    }
}

/// Task Notification Capability
@AxiomCapability(
    identifier: "task.notifications",
    dependencies: ["notification.local"],
    priority: .medium
)
struct TaskNotificationCapability {
    func scheduleTaskReminder(task: Task) async throws {
        guard let dueDate = task.dueDate else { return }
        
        // Schedule local notification for task due date
        // Implementation would use UserNotifications framework
        print("Scheduling notification for task: \(task.title) at \(dueDate)")
    }
    
    func cancelTaskReminder(taskId: UUID) async throws {
        // Cancel scheduled notification
        print("Cancelling notification for task: \(taskId)")
    }
}

/// Task Sync Capability
@AxiomCapability(
    identifier: "task.sync",
    dependencies: ["network.http", "auth.user"],
    priority: .low
)
struct TaskSyncCapability {
    func syncTasksToCloud(_ tasks: [Task]) async throws {
        // Implementation for syncing tasks to cloud service
        print("Syncing \(tasks.count) tasks to cloud")
        
        // Simulate network request
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
    
    func syncTasksFromCloud() async throws -> [Task] {
        // Implementation for syncing tasks from cloud service
        print("Syncing tasks from cloud")
        
        // Simulate network request
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        return []
    }
}

// MARK: - Usage Example

/// Example usage demonstrating all macros working together
@MainActor
class TaskManagerApp {
    private let client: TaskManagerClient
    private let context: TaskListContext
    private let persistenceCapability: TaskPersistenceCapability
    private let notificationCapability: TaskNotificationCapability
    private let syncCapability: TaskSyncCapability
    
    init() {
        self.client = TaskManagerClient()
        self.context = TaskListContext(client: client)
        self.persistenceCapability = TaskPersistenceCapability()
        self.notificationCapability = TaskNotificationCapability()
        self.syncCapability = TaskSyncCapability()
    }
    
    func launch() async {
        print("🚀 Task Manager App launching...")
        
        // Initialize context (macro-generated lifecycle)
        await context.initialize()
        
        print("✅ Task Manager App initialized with \(context.state.tasks.count) tasks")
        
        // Demonstrate usage
        await demonstrateFeatures()
    }
    
    private func demonstrateFeatures() async {
        print("\n📝 Demonstrating Task Manager Features:")
        
        // Add a new task
        print("• Adding new task...")
        await context.addTask(
            title: "Review Axiom Macro Implementation", 
            description: "Complete comprehensive review of all macro implementations",
            priority: .high,
            category: .work
        )
        
        // Toggle task completion
        if let firstTask = context.state.tasks.first {
            print("• Toggling task completion...")
            await context.toggleTaskCompletion(firstTask)
        }
        
        // Demonstrate capability usage
        print("• Testing capabilities...")
        do {
            try await persistenceCapability.saveTasks(context.state.tasks)
            try await syncCapability.syncTasksToCloud(context.state.tasks)
            print("✅ All capabilities working correctly")
        } catch {
            print("❌ Capability error: \(error)")
        }
        
        print("\n🎉 Task Manager Demo Complete!")
        print("📊 Final state: \(context.state.tasks.count) tasks")
    }
}

// MARK: - Demo Entry Point

/// Run the Task Manager demo
func runTaskManagerDemo() async {
    let app = TaskManagerApp()
    await app.launch()
}