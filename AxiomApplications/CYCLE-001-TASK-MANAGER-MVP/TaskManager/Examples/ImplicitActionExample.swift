// COMPREHENSIVE IMPLICIT ACTION SUBSCRIPTION EXAMPLE
// Task Creation Form with Multi-Level Hierarchy and Validation

import SwiftUI
import AxiomFramework

// MARK: - Action Types
// Single action enum for the entire feature
enum TaskCreationAction {
    // Field-level actions
    case titleChanged(String)
    case titleValidation(isValid: Bool, error: String?)
    case descriptionChanged(String)
    case categorySelected(Category?)
    case priorityChanged(Priority)
    case dueDateChanged(Date?)
    
    // Form-level actions
    case validationStateChanged(isValid: Bool, errors: [String])
    case saveRequested
    case cancelRequested
    
    // Root-level actions
    case taskCreated(Task)
    case creationFailed(Error)
    case dismissed
}

// MARK: - View Hierarchy (Enforces DAG Structure)

struct TaskCreationRootView: View {
    @ObservedObject var context: TaskCreationRootContext
    
    var body: some View {
        NavigationView {
            TaskFormView(context: context.formContext) // Embedded child view
                .navigationTitle("New Task")
                .navigationBarItems(
                    leading: Button("Cancel") { context.cancel() },
                    trailing: Button("Save") { context.save() }
                        .disabled(!context.canSave)
                )
        }
        .alert("Error", isPresented: $context.showError) {
            Button("OK") { context.dismissError() }
        } message: {
            Text(context.errorMessage)
        }
    }
}

struct TaskFormView: View {
    @ObservedObject var context: TaskFormContext
    
    var body: some View {
        Form {
            // Title Field Section
            Section {
                TitleFieldView(context: context.titleField) // Embedded
            } header: {
                Text("Title")
            } footer: {
                if let error = context.titleError {
                    Text(error).foregroundColor(.red)
                }
            }
            
            // Description Section
            Section("Description") {
                DescriptionFieldView(context: context.descriptionField) // Embedded
            }
            
            // Metadata Section
            Section("Details") {
                CategoryPickerView(context: context.categoryPicker) // Embedded
                PriorityPickerView(context: context.priorityPicker) // Embedded
                DueDatePickerView(context: context.dueDatePicker) // Embedded
            }
        }
    }
}

struct TitleFieldView: View {
    @ObservedObject var context: TitleFieldContext
    
    var body: some View {
        TextField("Task title", text: $context.title)
            .onChange(of: context.title) { _ in
                context.validateTitle()
            }
    }
}

struct DescriptionFieldView: View {
    @ObservedObject var context: DescriptionFieldContext
    
    var body: some View {
        TextEditor(text: $context.description)
            .frame(minHeight: 100)
    }
}

struct CategoryPickerView: View {
    @ObservedObject var context: CategoryPickerContext
    
    var body: some View {
        Picker("Category", selection: $context.selectedCategory) {
            Text("None").tag(nil as Category?)
            ForEach(context.categories) { category in
                Text(category.name).tag(category as Category?)
            }
        }
    }
}

struct PriorityPickerView: View {
    @ObservedObject var context: PriorityPickerContext
    
    var body: some View {
        Picker("Priority", selection: $context.priority) {
            ForEach(Priority.allCases, id: \.self) { priority in
                Label(priority.displayName, systemImage: priority.icon)
                    .tag(priority)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct DueDatePickerView: View {
    @ObservedObject var context: DueDatePickerContext
    @State private var hasDate = false
    
    var body: some View {
        Toggle("Due Date", isOn: $hasDate)
            .onChange(of: hasDate) { enabled in
                context.setDateEnabled(enabled)
            }
        
        if hasDate {
            DatePicker(
                "Due",
                selection: Binding(
                    get: { context.dueDate ?? Date() },
                    set: { context.updateDate($0) }
                ),
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }
}

// MARK: - Context Hierarchy (Matches View Hierarchy)

// Root context - handles navigation and persistence
class TaskCreationRootContext: ClientObservingContext<TaskClient> {
    @Published var formContext: TaskFormContext
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var canSave = false
    
    override init(client: TaskClient) {
        self.formContext = TaskFormContext()
        super.init(client: client)
    }
    
    // Framework calls this for any child action
    override func handleChildAction<T>(_ action: T, from child: Context) {
        guard let taskAction = action as? TaskCreationAction else { return }
        
        switch taskAction {
        case .validationStateChanged(let isValid, _):
            // React to form validation changes
            canSave = isValid
            
        case .taskCreated(let task):
            // Handle successful creation from form
            Task {
                do {
                    try await client.process(.addTask(
                        title: task.title,
                        description: task.description,
                        categoryId: task.categoryId,
                        priority: task.priority,
                        dueDate: task.dueDate
                    ))
                    await MainActor.run {
                        emit(.dismissed)
                    }
                } catch {
                    await MainActor.run {
                        showError(error)
                    }
                }
            }
            
        case .creationFailed(let error):
            // Handle form-level errors
            showError(error)
            
        case .cancelRequested:
            // Handle cancel from any level
            emit(.dismissed)
            
        default:
            // Ignore field-level actions - let form handle them
            break
        }
    }
    
    func save() {
        emit(.saveRequested) // Will be handled by form
    }
    
    func cancel() {
        emit(.cancelRequested)
    }
    
    private func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
    
    func dismissError() {
        showError = false
        errorMessage = ""
    }
}

// Form context - manages form state and validation
class TaskFormContext: Context {
    @Published var titleField: TitleFieldContext
    @Published var descriptionField: DescriptionFieldContext
    @Published var categoryPicker: CategoryPickerContext
    @Published var priorityPicker: PriorityPickerContext
    @Published var dueDatePicker: DueDatePickerContext
    
    @Published var titleError: String?
    @Published var isValid = false
    private var validationErrors: [String] = []
    
    override init() {
        self.titleField = TitleFieldContext()
        self.descriptionField = DescriptionFieldContext()
        self.categoryPicker = CategoryPickerContext()
        self.priorityPicker = PriorityPickerContext()
        self.dueDatePicker = DueDatePickerContext()
        super.init()
    }
    
    override func handleChildAction<T>(_ action: T, from child: Context) {
        guard let taskAction = action as? TaskCreationAction else { return }
        
        switch taskAction {
        case .titleChanged(let title):
            // Could perform cross-field validation here
            validateForm()
            
        case .titleValidation(let isValid, let error):
            // Handle validation result from title field
            titleError = error
            if !isValid && error != nil {
                validationErrors.append(error!)
            }
            validateForm()
            
        case .descriptionChanged:
            validateForm()
            
        case .categorySelected:
            validateForm()
            
        case .priorityChanged:
            validateForm()
            
        case .dueDateChanged:
            validateForm()
            
        case .saveRequested:
            // Received from parent - create task if valid
            if isValid {
                let task = Task(
                    title: titleField.title,
                    description: descriptionField.description.isEmpty ? nil : descriptionField.description,
                    categoryId: categoryPicker.selectedCategory?.id,
                    priority: priorityPicker.priority,
                    dueDate: dueDatePicker.dueDate
                )
                emit(.taskCreated(task))
            } else {
                emit(.creationFailed(ValidationError.formInvalid(errors: validationErrors)))
            }
            
        default:
            // Let parent handle other actions
            emit(action)
        }
    }
    
    private func validateForm() {
        validationErrors.removeAll()
        
        // Aggregate validation state
        let titleValid = !titleField.title.isEmpty
        let descriptionValid = true // Optional field
        let dueDateValid = dueDatePicker.dueDate == nil || dueDatePicker.dueDate! > Date()
        
        isValid = titleValid && descriptionValid && dueDateValid
        
        if !dueDateValid {
            validationErrors.append("Due date must be in the future")
        }
        
        // Emit validation state change
        emit(.validationStateChanged(isValid: isValid, errors: validationErrors))
    }
}

// Field context with async validation
class TitleFieldContext: Context {
    @Published var title = ""
    private let validator = TitleValidator() // Async validation service
    private var validationTask: Task<Void, Never>?
    
    func validateTitle() {
        emit(.titleChanged(title))
        
        // Cancel previous validation
        validationTask?.cancel()
        
        // Debounced async validation
        validationTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
                
                let result = await validator.validate(title)
                if !Task.isCancelled {
                    emit(.titleValidation(
                        isValid: result.isValid,
                        error: result.error
                    ))
                }
            } catch {
                // Cancelled
            }
        }
    }
}

// Simple field contexts
class DescriptionFieldContext: Context {
    @Published var description = ""
    
    override func didChange() {
        emit(.descriptionChanged(description))
    }
}

class CategoryPickerContext: Context {
    @Published var categories: [Category] = Category.defaults
    @Published var selectedCategory: Category? {
        didSet { emit(.categorySelected(selectedCategory)) }
    }
}

class PriorityPickerContext: Context {
    @Published var priority: Priority = .medium {
        didSet { emit(.priorityChanged(priority)) }
    }
}

class DueDatePickerContext: Context {
    @Published var dueDate: Date? {
        didSet { emit(.dueDateChanged(dueDate)) }
    }
    
    func setDateEnabled(_ enabled: Bool) {
        dueDate = enabled ? Date().addingTimeInterval(3600) : nil
    }
    
    func updateDate(_ date: Date) {
        dueDate = date
    }
}

// MARK: - Error Types
enum ValidationError: LocalizedError {
    case formInvalid(errors: [String])
    
    var errorDescription: String? {
        switch self {
        case .formInvalid(let errors):
            return errors.joined(separator: "\n")
        }
    }
}

// MARK: - Supporting Types
struct TitleValidator {
    func validate(_ title: String) async -> (isValid: Bool, error: String?) {
        // Simulate async validation (e.g., checking uniqueness)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        if title.isEmpty {
            return (false, "Title is required")
        }
        if title.count < 3 {
            return (false, "Title must be at least 3 characters")
        }
        if title.count > 100 {
            return (false, "Title must be less than 100 characters")
        }
        
        // Simulate checking for duplicates
        if title.lowercased() == "test" {
            return (false, "A task with this title already exists")
        }
        
        return (true, nil)
    }
}

// MARK: - Usage Example
struct ContentView: View {
    @StateObject private var client = TaskClient()
    @State private var showingCreate = false
    
    var body: some View {
        TaskListView()
            .sheet(isPresented: $showingCreate) {
                TaskCreationRootView(
                    context: TaskCreationRootContext(client: client)
                )
            }
    }
}