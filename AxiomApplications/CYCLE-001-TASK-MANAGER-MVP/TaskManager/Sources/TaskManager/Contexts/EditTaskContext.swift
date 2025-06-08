import Foundation
import SwiftUI
import Axiom

@MainActor
final class EditTaskContext: TaskFormContext {
    // MARK: - Properties
    
    private let task: TaskItem
    
    // Form fields
    @Published var title: String
    @Published var description: String
    @Published var isCompleted: Bool
    
    // Confirmation dialog state
    @Published var showDeleteConfirmation: Bool = false
    
    // Read-only properties
    var taskId: UUID {
        task.id
    }
    
    // MARK: - Initialization
    
    init(client: TaskClient, task: TaskItem, navigationService: NavigationService? = nil) {
        self.task = task
        
        // Initialize form fields with task data
        self.title = task.title
        self.description = task.description ?? ""
        self.isCompleted = task.isCompleted
        
        super.init(client: client, navigationService: navigationService)
    }
    
    // MARK: - FormContext Overrides (REFACTOR: Using TaskFormContext validation)
    
    override var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    override func validate() -> Bool {
        validateTitle(title)
    }
    
    // MARK: - Actions (REFACTOR: Using base class helpers)
    
    func submit() async {
        await submitForm { [weak self] in
            guard let self = self else { return }
            
            let action = TaskAction.updateTask(
                id: self.task.id,
                title: self.trimmedString(self.title)!,  // Safe - validated
                description: self.trimmedString(self.description),
                categoryId: self.task.categoryId,  // Keep existing category for now
                priority: nil,  // Keep existing priority for now
                dueDate: nil,  // Keep existing due date for now
                isCompleted: self.isCompleted
            )
            
            // Use sendAndWait in tests for proper state propagation
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                await self.client.sendAndWait(action)
            } else {
                try await self.client.process(action)
            }
            #else
            try await self.client.process(action)
            #endif
            
            // Dismiss the view
            self.dismiss()
        }
    }
    
    func deleteTask() async {
        do {
            let action = TaskAction.deleteTask(id: task.id)
            
            // Use sendAndWait in tests for proper state propagation
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                await client.sendAndWait(action)
            } else {
                try await client.process(action)
            }
            #else
            try await client.process(action)
            #endif
            
            // Dismiss the view
            dismiss()
        } catch {
            validationError = error.localizedDescription
        }
    }
    
    // MARK: - Confirmation Dialog
    
    func confirmDelete() {
        showDeleteConfirmation = true
    }
    
    func cancelDelete() {
        showDeleteConfirmation = false
    }
    
    func performDelete() async {
        showDeleteConfirmation = false
        await deleteTask()
    }
}