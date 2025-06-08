import Foundation
import SwiftUI
import AxiomCore

// MARK: - Actions
// All actions are defined at the top level and flow implicitly through the hierarchy

enum TaskCreationAction: Equatable {
    // Form field actions
    case updateTitle(String)
    case updateDescription(String)
    case updatePriority(Priority)
    case updateCategory(Category)
    case updateDueDate(Date?)
    
    // Validation actions
    case validateTitle
    case validateForm
    
    // Form submission actions
    case submitForm
    case saveTask
    
    // Navigation actions
    case dismiss
    case showValidationError(String)
    
    // Async actions
    case savingStarted
    case savingCompleted(Task)
    case savingFailed(Error)
}

// MARK: - Root Context (Handles navigation and task persistence)
@MainActor
final class TaskCreationRootContext: ViewContext {
    typealias Action = TaskCreationAction
    
    @Published private(set) var isPresented = true
    @Published private(set) var savedTask: Task?
    
    private let taskClient: TaskClient
    private let navigationService: NavigationService
    
    init(taskClient: TaskClient, navigationService: NavigationService) {
        self.taskClient = taskClient
        self.navigationService = navigationService
    }
    
    // Only handles high-level actions - form management is delegated to child contexts
    func handle(_ action: Action) async {
        switch action {
        case .saveTask:
            // This action is triggered by the form context after validation
            await saveCurrentTask()
            
        case .savingCompleted(let task):
            savedTask = task
            await handle(.dismiss)
            
        case .savingFailed(let error):
            // Error handling at root level
            print("Failed to save task: \(error)")
            
        case .dismiss:
            isPresented = false
            navigationService.dismiss()
            
        default:
            // All other actions flow to child contexts implicitly
            break
        }
    }
    
    private func saveCurrentTask() async {
        // Get form data from child context (would be passed via action in real implementation)
        await handle(.savingStarted)
        
        do {
            // Simulate async save
            try await Task.sleep(nanoseconds: 500_000_000)
            let newTask = Task(
                title: "Example Task",
                description: "Created via implicit action example",
                priority: .medium,
                category: .work
            )
            let saved = try await taskClient.createTask(newTask)
            await handle(.savingCompleted(saved))
        } catch {
            await handle(.savingFailed(error))
        }
    }
}

// MARK: - Form Context (Handles form state and validation)
@MainActor
final class TaskFormContext: ViewContext {
    typealias Action = TaskCreationAction
    
    @Published private(set) var title = ""
    @Published private(set) var description = ""
    @Published private(set) var priority = Priority.medium
    @Published private(set) var category = Category.personal
    @Published private(set) var dueDate: Date?
    
    @Published private(set) var titleError: String?
    @Published private(set) var isValid = false
    @Published private(set) var isSaving = false
    
    // Form context handles all form-related actions
    func handle(_ action: Action) async {
        switch action {
        case .updateTitle(let newTitle):
            title = newTitle
            titleError = nil
            await handle(.validateForm)
            
        case .updateDescription(let newDescription):
            description = newDescription
            
        case .updatePriority(let newPriority):
            priority = newPriority
            
        case .updateCategory(let newCategory):
            category = newCategory
            
        case .updateDueDate(let newDueDate):
            dueDate = newDueDate
            
        case .validateTitle:
            titleError = validateTitle()
            
        case .validateForm:
            isValid = validateTitle() == nil && !title.isEmpty
            
        case .submitForm:
            await handle(.validateForm)
            if isValid {
                // Bubble up to parent for saving
                await handle(.saveTask)
            } else {
                await handle(.showValidationError("Please fix validation errors"))
            }
            
        case .savingStarted:
            isSaving = true
            
        case .savingCompleted:
            isSaving = false
            
        case .savingFailed:
            isSaving = false
            
        default:
            // Actions not handled here flow up implicitly
            break
        }
    }
    
    private func validateTitle() -> String? {
        if title.isEmpty {
            return "Title is required"
        }
        if title.count < 3 {
            return "Title must be at least 3 characters"
        }
        if title.count > 100 {
            return "Title must be less than 100 characters"
        }
        return nil
    }
}

// MARK: - Field Validation Context (Handles real-time validation)
@MainActor
final class FieldValidationContext: ViewContext {
    typealias Action = TaskCreationAction
    
    @Published private(set) var isValidating = false
    @Published private(set) var validationMessage: String?
    
    private var validationTask: Task?
    
    func handle(_ action: Action) async {
        switch action {
        case .updateTitle(let title):
            // Cancel previous validation
            validationTask?.cancel()
            
            if !title.isEmpty {
                isValidating = true
                
                // Debounced validation
                let task = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
                    
                    if !Task.isCancelled {
                        await validateTitleAsync(title)
                    }
                }
                validationTask = task
            } else {
                isValidating = false
                validationMessage = nil
            }
            
        case .showValidationError(let message):
            validationMessage = message
            
        default:
            // Other actions flow through
            break
        }
    }
    
    private func validateTitleAsync(_ title: String) async {
        isValidating = true
        
        // Simulate async validation (e.g., checking for duplicates)
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        if title.lowercased().contains("test") {
            validationMessage = "Title contains reserved word 'test'"
        } else {
            validationMessage = nil
        }
        
        isValidating = false
    }
}

// MARK: - View Hierarchy
struct TaskCreationView: View {
    @StateObject private var rootContext: TaskCreationRootContext
    @StateObject private var formContext = TaskFormContext()
    
    init(taskClient: TaskClient, navigationService: NavigationService) {
        _rootContext = StateObject(wrappedValue: TaskCreationRootContext(
            taskClient: taskClient,
            navigationService: navigationService
        ))
    }
    
    var body: some View {
        // ContextView automatically wires up implicit action flow
        ContextView(rootContext) {
            ContextView(formContext) {
                NavigationStack {
                    TaskFormView()
                        .navigationTitle("New Task")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    rootContext.send(.dismiss)
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    formContext.send(.submitForm)
                                }
                                .disabled(!formContext.isValid || formContext.isSaving)
                            }
                        }
                }
            }
        }
    }
}

struct TaskFormView: View {
    @EnvironmentObject private var formContext: TaskFormContext
    @StateObject private var validationContext = FieldValidationContext()
    
    var body: some View {
        ContextView(validationContext) {
            Form {
                Section {
                    TitleFieldView()
                    DescriptionFieldView()
                }
                
                Section {
                    PriorityPickerView()
                    CategoryPickerView()
                    DueDatePickerView()
                }
            }
            .disabled(formContext.isSaving)
            .overlay {
                if formContext.isSaving {
                    ProgressView("Saving...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Embedded Views (demonstrate action flow)
struct TitleFieldView: View {
    @EnvironmentObject private var formContext: TaskFormContext
    @EnvironmentObject private var validationContext: FieldValidationContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Title", text: Binding(
                get: { formContext.title },
                set: { newValue in
                    // Actions flow up implicitly through the context hierarchy
                    formContext.send(.updateTitle(newValue))
                }
            ))
            .textFieldStyle(.roundedBorder)
            
            if let error = formContext.titleError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            } else if validationContext.isValidating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Validating...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let message = validationContext.validationMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
}

struct DescriptionFieldView: View {
    @EnvironmentObject private var formContext: TaskFormContext
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Description")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextEditor(text: Binding(
                get: { formContext.description },
                set: { formContext.send(.updateDescription($0)) }
            ))
            .frame(minHeight: 100)
        }
    }
}

struct PriorityPickerView: View {
    @EnvironmentObject private var formContext: TaskFormContext
    
    var body: some View {
        Picker("Priority", selection: Binding(
            get: { formContext.priority },
            set: { formContext.send(.updatePriority($0)) }
        )) {
            ForEach(Priority.allCases) { priority in
                Label(priority.displayName, systemImage: priority.symbolName)
                    .tag(priority)
            }
        }
    }
}

struct CategoryPickerView: View {
    @EnvironmentObject private var formContext: TaskFormContext
    
    var body: some View {
        Picker("Category", selection: Binding(
            get: { formContext.category },
            set: { formContext.send(.updateCategory($0)) }
        )) {
            ForEach(Category.allCases) { category in
                Label(category.displayName, systemImage: category.symbolName)
                    .tag(category)
            }
        }
    }
}

struct DueDatePickerView: View {
    @EnvironmentObject private var formContext: TaskFormContext
    @State private var isDatePickerPresented = false
    
    var body: some View {
        HStack {
            Text("Due Date")
            Spacer()
            if let dueDate = formContext.dueDate {
                Text(dueDate, style: .date)
                    .foregroundColor(.secondary)
            } else {
                Text("None")
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isDatePickerPresented.toggle()
        }
        .sheet(isPresented: $isDatePickerPresented) {
            DatePickerSheet(
                date: formContext.dueDate,
                onSave: { date in
                    formContext.send(.updateDueDate(date))
                }
            )
        }
    }
}

struct DatePickerSheet: View {
    let date: Date?
    let onSave: (Date?) -> Void
    
    @State private var selectedDate = Date()
    @State private var hasDate = false
    @Environment(\.dismiss) private var dismiss
    
    init(date: Date?, onSave: @escaping (Date?) -> Void) {
        self.date = date
        self.onSave = onSave
        _selectedDate = State(initialValue: date ?? Date())
        _hasDate = State(initialValue: date != nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Toggle("Set Due Date", isOn: $hasDate)
                
                if hasDate {
                    DatePicker(
                        "Due Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                }
            }
            .navigationTitle("Due Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(hasDate ? selectedDate : nil)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Priority and Category Extensions
extension Priority {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var symbolName: String {
        switch self {
        case .low: return "flag"
        case .medium: return "flag.fill"
        case .high: return "exclamationmark.triangle"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
}

extension Category {
    var displayName: String {
        switch self {
        case .work: return "Work"
        case .personal: return "Personal"
        case .shopping: return "Shopping"
        case .health: return "Health"
        case .finance: return "Finance"
        case .home: return "Home"
        case .education: return "Education"
        case .travel: return "Travel"
        case .other: return "Other"
        }
    }
    
    var symbolName: String {
        switch self {
        case .work: return "briefcase"
        case .personal: return "person"
        case .shopping: return "cart"
        case .health: return "heart"
        case .finance: return "dollarsign.circle"
        case .home: return "house"
        case .education: return "book"
        case .travel: return "airplane"
        case .other: return "folder"
        }
    }
}