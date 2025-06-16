import SwiftUI
import Axiom

// Import shared Task Manager components
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared

// MARK: - Task Detail View (iOS)

/// Detailed view for viewing and editing a single task on iOS
public struct TaskDetailView: View, PresentationProtocol {
    public typealias ContextType = TaskDetailContext
    
    @ObservedObject public var context: TaskDetailContext
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteConfirmation = false
    @State private var showingUnsavedChangesAlert = false
    
    public init(context: TaskDetailContext) {
        self.context = context
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                if context.isLoading && !context.hasTask {
                    loadingView
                } else if let task = context.task {
                    taskDetailContent(task: task)
                } else {
                    notFoundView
                }
                
                if let error = context.error {
                    ErrorBanner(message: error) {
                        Task { await context.clearError() }
                    }
                }
            }
            .navigationTitle(context.task?.title ?? "Task")
            .navigationBarItems(
                leading: leadingNavigationItems,
                trailing: trailingNavigationItems
            )
        }
        .onAppear {
            Task { await context.appeared() }
        }
        .alert("Delete Task", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await context.deleteTask()
                    presentationMode.wrappedValue.dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
        .alert("Unsaved Changes", isPresented: $showingUnsavedChangesAlert) {
            Button("Save") {
                Task { await context.saveChanges() }
            }
            Button("Discard", role: .destructive) {
                Task { await context.cancelEditing() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. What would you like to do?")
        }
    }
    
    // MARK: - Task Detail Content
    
    @ViewBuilder
    private func taskDetailContent(task: Task) -> some View {
        if context.isEditing {
            editingView
        } else {
            readOnlyView(task: task)
        }
    }
    
    // MARK: - Read-Only View
    
    private func readOnlyView(task: Task) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Task header
                taskHeader(task: task)
                
                // Task details
                taskDetails(task: task)
                
                // Task metadata
                taskMetadata(task: task)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func taskHeader(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    Task { await context.toggleCompletion() }
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundColor(task.isCompleted ? .green : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                    
                    HStack {
                        priorityBadge(task.priority)
                        categoryBadge(task.category)
                        Spacer()
                    }
                }
                
                Spacer()
            }
            
            if let dueDateDescription = task.dueDateDescription {
                Label(dueDateDescription, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(task.isOverdue ? .red : .secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func taskDetails(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if !task.taskDescription.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    
                    Text(task.taskDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            if !task.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], alignment: .leading, spacing: 8) {
                        ForEach(Array(task.tags).sorted(), id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
    
    private func taskMetadata(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Information")
                .font(.headline)
            
            VStack(spacing: 8) {
                metadataRow(label: "Created", value: DateFormatter.localizedString(from: task.createdAt, dateStyle: .medium, timeStyle: .short))
                
                if let completedAt = task.completedAt {
                    metadataRow(label: "Completed", value: DateFormatter.localizedString(from: completedAt, dateStyle: .medium, timeStyle: .short))
                }
                
                if let dueDate = task.dueDate {
                    metadataRow(label: "Due Date", value: DateFormatter.localizedString(from: dueDate, dateStyle: .medium, timeStyle: .none))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }
    
    // MARK: - Editing View
    
    private var editingView: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Title", text: Binding(
                        get: { context.editTitle },
                        set: { newValue in Task { await context.updateEditTitle(newValue) } }
                    ))
                    
                    TextField("Description", text: Binding(
                        get: { context.editDescription },
                        set: { newValue in Task { await context.updateEditDescription(newValue) } }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                }
                
                Section("Organization") {
                    Picker("Priority", selection: Binding(
                        get: { context.editPriority },
                        set: { newValue in Task { await context.updateEditPriority(newValue) } }
                    )) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Label(priority.displayName, systemImage: priority.systemImageName)
                                .tag(priority)
                        }
                    }
                    
                    Picker("Category", selection: Binding(
                        get: { context.editCategory },
                        set: { newValue in Task { await context.updateEditCategory(newValue) } }
                    )) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.systemImageName)
                                .tag(category)
                        }
                    }
                }
                
                Section("Due Date") {
                    DatePicker(
                        "Due Date",
                        selection: Binding(
                            get: { context.editDueDate ?? Date() },
                            set: { newValue in Task { await context.updateEditDueDate(newValue) } }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .disabled(context.editDueDate == nil)
                    
                    Toggle("Has Due Date", isOn: Binding(
                        get: { context.editDueDate != nil },
                        set: { hasDate in
                            Task {
                                if hasDate {
                                    await context.updateEditDueDate(Date())
                                } else {
                                    await context.updateEditDueDate(nil)
                                }
                            }
                        }
                    ))
                }
                
                Section("Tags") {
                    ForEach(Array(context.editTags).sorted(), id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            Button("Remove") {
                                Task { await context.removeEditTag(tag) }
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        TextField("Add tag", text: $newTagText)
                        Button("Add") {
                            Task {
                                await context.addEditTag(newTagText)
                                newTagText = ""
                            }
                        }
                        .disabled(newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                if !context.formValidationErrors.isEmpty {
                    Section {
                        ForEach(context.formValidationErrors, id: \.self) { error in
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    if context.hasUnsavedChanges {
                        showingUnsavedChangesAlert = true
                    } else {
                        Task { await context.cancelEditing() }
                    }
                },
                trailing: Button("Save") {
                    Task { await context.saveChanges() }
                }
                .disabled(!context.canSave)
            )
        }
    }
    
    @State private var newTagText = ""
    
    // MARK: - Navigation Items
    
    private var leadingNavigationItems: some View {
        Button("Back") {
            if context.hasUnsavedChanges {
                showingUnsavedChangesAlert = true
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private var trailingNavigationItems: some View {
        HStack {
            if !context.isEditing {
                Menu {
                    Button("Edit") {
                        Task { await context.startEditing() }
                    }
                    
                    Button("Duplicate") {
                        Task { await context.duplicateTask() }
                    }
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading task...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var notFoundView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Task Not Found")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("The task you're looking for doesn't exist or may have been deleted.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Go Back") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func priorityBadge(_ priority: Priority) -> some View {
        Label(priority.displayName, systemImage: priority.systemImageName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priority.color.opacity(0.2))
            .foregroundColor(priority.color)
            .cornerRadius(8)
    }
    
    private func categoryBadge(_ category: Category) -> some View {
        Label(category.displayName, systemImage: category.systemImageName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(category.color.opacity(0.2))
            .foregroundColor(category.color)
            .cornerRadius(8)
    }
}

// MARK: - Error Banner

private struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Dismiss") {
                    onDismiss()
                }
                .font(.caption)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
            
            Spacer()
        }
    }
}