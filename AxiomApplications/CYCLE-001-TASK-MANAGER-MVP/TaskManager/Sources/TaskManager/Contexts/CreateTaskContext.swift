import Foundation
import SwiftUI
import Axiom

/// Context for creating new tasks with validation
@MainActor
final class CreateTaskContext: TaskFormContext {
    // Form state
    @Published var title: String = ""
    @Published var description: String?
    
    // MARK: - Validation (REFACTOR: Using TaskFormContext pattern)
    
    override var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    override func validate() -> Bool {
        validateTitle(title)
    }
    
    // MARK: - Actions (REFACTOR: Using submitForm and base helpers)
    
    func submit() async {
        await submitForm {
            // Create the task
            await self.client.send(.addTask(
                title: self.trimmedString(self.title)!,  // Safe force unwrap - validated
                description: self.trimmedString(self.description)
            ))
            
            // Dismiss on success
            self.dismiss()
        }
    }
    
    func cancel() {
        dismiss()
    }
    
    // MARK: - State Updates
    
    override func handleStateUpdate(_ state: TaskState) async {
        // For modal contexts, we typically don't need to observe state changes
        // But we could check for errors here if needed
        await super.handleStateUpdate(state)
    }
}

