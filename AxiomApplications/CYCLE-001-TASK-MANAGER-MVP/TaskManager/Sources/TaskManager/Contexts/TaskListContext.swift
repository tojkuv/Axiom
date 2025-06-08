import Foundation
import SwiftUI
import Axiom

/// Context for task list view using refactored AutoSyncContext pattern
@MainActor
final class TaskListContext: AutoSyncContext<TaskClient>, DeleteConfirmable {
    // Published state that mirrors client state
    @Published private(set) var state: TaskState = TaskState()
    
    // Delete confirmation state (REFACTOR: Using DeleteConfirmable protocol)
    @Published var itemToDelete: TaskItem?
    @Published var showDeleteConfirmation: Bool = false
    
    // Backward compatibility
    var taskToDelete: TaskItem? {
        get { itemToDelete }
        set { itemToDelete = newValue }
    }
    
    // Optimistic update tracking
    @Published var deletingTaskIds: Set<UUID> = []
    var useOptimisticUpdates: Bool = false
    
    // Optional services
    private let navigationService: NavigationService?
    
    init(client: TaskClient, navigationService: NavigationService? = nil) {
        self.navigationService = navigationService
        super.init(client: client)
    }
    
    // REFACTOR: Using AutoSyncContext pattern
    override func syncInitialState() async {
        self.state = await client.state
    }
    
    // Override to handle state updates from the client
    override func handleStateUpdate(_ state: TaskState) async {
        // Update our published state
        self.state = state
        
        // The base class will call notifyUpdate() for UI updates
        await super.handleStateUpdate(state)
    }
    
    // MARK: - Actions
    
    func addTask(title: String, description: String?) {
        Task {
            await client.send(.addTask(title: title, description: description))
        }
    }
    
    func deleteTask(id: UUID) {
        if useOptimisticUpdates {
            deletingTaskIds.insert(id)
        }
        
        Task {
            await client.send(.deleteTask(id: id))
            
            // Remove from optimistic tracking after completion
            deletingTaskIds.remove(id)
        }
    }
    
    // MARK: - Delete Confirmation (REFACTOR: Using DeleteConfirmable protocol)
    
    func requestDelete(task: TaskItem) {
        requestDelete(item: task)
    }
    
    func performDelete(item: TaskItem) async {
        deleteTask(id: item.id)
    }
    
    // MARK: - Bulk Operations
    
    func deleteTasks(ids: [UUID]) {
        Task {
            for id in ids {
                if useOptimisticUpdates {
                    deletingTaskIds.insert(id)
                }
                await client.send(.deleteTask(id: id))
                deletingTaskIds.remove(id)
            }
        }
    }
    
    func toggleTaskCompletion(id: UUID) {
        Task {
            await client.send(.toggleTaskCompletion(id: id))
        }
    }
    
    func clearError() {
        Task {
            await client.send(.clearError)
        }
    }
    
    // MARK: - Navigation
    
    func showCreateTask() {
        navigationService?.navigate(to: .createTask)
    }
    
    func showEditTask(id: UUID) {
        navigationService?.navigate(to: .editTask(id: id))
    }
    
    func showTaskDetail(id: UUID) {
        navigationService?.navigate(to: .taskDetail(id: id))
    }
}

