import SwiftUI
import Axiom

/// View for creating a new task
struct CreateTaskView: View {
    @ObservedObject var context: CreateTaskContext
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title
        case description
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $context.title)
                        .focused($focusedField, equals: .title)
                        .formFieldStyle(isValid: context.validationError == nil)
                    
                    TextField("Description", text: descriptionBinding)
                        .focused($focusedField, equals: .description)
                }
                
                // REFACTOR: Using ValidationErrorView component
                Section {
                    ValidationErrorView(error: context.validationError)
                }
            }
            // REFACTOR: Using formNavigationBar modifier
            .formNavigationBar(
                title: "New Task",
                cancelAction: context.cancel,
                saveAction: context.submit,
                canSave: context.isValid,
                isSaving: context.isSubmitting
            )
        }
        .contextLifecycle(context)
        .onAppear {
            focusedField = .title
        }
    }
    
    // MARK: - Bindings
    
    private var descriptionBinding: Binding<String> {
        Binding(
            get: { context.description ?? "" },
            set: { newValue in
                context.description = newValue.isEmpty ? nil : newValue
            }
        )
    }
}

// MARK: - Previews

struct CreateTaskView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default state
            CreateTaskView(context: makePreviewContext())
                .previewDisplayName("Default")
            
            // With validation error
            CreateTaskView(context: makePreviewContext(validationError: "Title is required"))
                .previewDisplayName("Validation Error")
            
            // Submitting state
            CreateTaskView(context: makePreviewContext(isSubmitting: true))
                .previewDisplayName("Submitting")
        }
    }
    
    @MainActor
    static func makePreviewContext(
        validationError: String? = nil,
        isSubmitting: Bool = false
    ) -> CreateTaskContext {
        let client = TaskClient()
        let context = CreateTaskContext(client: client)
        context.validationError = validationError
        context.isSubmitting = isSubmitting
        return context
    }
}