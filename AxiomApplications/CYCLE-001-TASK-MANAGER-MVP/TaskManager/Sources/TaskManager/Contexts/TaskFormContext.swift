import Foundation
import SwiftUI
import Axiom

/// Base context for task forms with common validation and navigation
@MainActor
class TaskFormContext: FormContext<TaskClient> {
    // Services
    let navigationService: NavigationService?
    
    init(client: TaskClient, navigationService: NavigationService? = nil) {
        self.navigationService = navigationService
        super.init(client: client)
    }
    
    // MARK: - Common Validation
    
    func validateTitle(_ title: String) -> Bool {
        validationError = nil
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            validationError = "Title is required"
            return false
        }
        
        return true
    }
    
    // MARK: - Common Helpers
    
    func trimmedString(_ string: String?) -> String? {
        guard let string = string else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    func dismiss() {
        navigationService?.dismiss()
    }
}