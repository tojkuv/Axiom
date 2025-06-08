import SwiftUI
import Axiom

struct EditTaskView: View {
    @StateObject private var context: EditTaskContext
    @FocusState private var titleFocused: Bool
    
    init(task: TaskItem, client: TaskClient, navigationService: NavigationService? = nil) {
        self._context = StateObject(wrappedValue: EditTaskContext(
            client: client,
            task: task,
            navigationService: navigationService ?? DefaultNavigationService.shared
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $context.title)
                        .formFieldStyle(isValid: context.isValid)
                        .focused($titleFocused)
                    
                    TextField("Description", text: $context.description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Toggle("Completed", isOn: $context.isCompleted)
                }
                
                if let error = context.validationError {
                    Section {
                        ValidationErrorView(error: error)
                    }
                }
                
                Section {
                    Button("Delete Task", role: .destructive) {
                        context.confirmDelete()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .formNavigationBar(
                title: "Edit Task",
                cancelAction: {
                    DefaultNavigationService.shared.dismiss()
                },
                saveAction: {
                    await context.submit()
                },
                canSave: context.isValid,
                isSaving: context.isSubmitting
            )
            .confirmationDialog(
                "Delete Task",
                isPresented: $context.showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        await context.performDelete()
                    }
                }
                Button("Cancel", role: .cancel) {
                    context.cancelDelete()
                }
            } message: {
                Text("Are you sure you want to delete this task? This action cannot be undone.")
            }
        }
        .task {
            titleFocused = true
        }
    }
}