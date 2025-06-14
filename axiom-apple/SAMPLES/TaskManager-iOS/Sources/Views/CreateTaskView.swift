import SwiftUI
import Axiom

// Import shared Task Manager components
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared

// MARK: - Create Task View (iOS)

/// View for creating new tasks on iOS with templates and validation
public struct CreateTaskView: View, PresentationProtocol {
    public typealias ContextType = CreateTaskContext
    
    @ObservedObject public var context: CreateTaskContext
    @Environment(\.presentationMode) var presentationMode
    @State private var showingTemplates = false
    @FocusState private var titleFieldFocused: Bool
    
    public init(context: CreateTaskContext) {
        self.context = context
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                Form {
                    basicInformationSection
                    organizationSection
                    dueDateSection
                    tagsSection
                    
                    if !context.formValidationErrors.isEmpty {
                        validationErrorsSection
                    }
                }
                .navigationTitle("New Task")
                .navigationBarItems(
                    leading: cancelButton,
                    trailing: actionButtons
                )
                .onAppear {
                    Task { 
                        await context.appeared()
                        titleFieldFocused = true
                    }
                }
                
                if let error = context.error {
                    ErrorBanner(message: error) {
                        Task { await context.clearError() }
                    }
                }
                
                if context.isCreated {
                    SuccessBanner(message: "Task created successfully!") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingTemplates) {
            TemplateSelectionView(context: context, isPresented: $showingTemplates)
        }
    }
    
    // MARK: - Form Sections
    
    private var basicInformationSection: some View {
        Section("Task Details") {
            TextField("Task title", text: Binding(
                get: { context.title },
                set: { newValue in Task { await context.updateTitle(newValue) } }
            ))
            .focused($titleFieldFocused)
            
            TextField("Description (optional)", text: Binding(
                get: { context.taskDescription },
                set: { newValue in Task { await context.updateDescription(newValue) } }
            ), axis: .vertical)
            .lineLimit(2...5)
        }
    }
    
    private var organizationSection: some View {
        Section("Organization") {
            Picker("Priority", selection: Binding(
                get: { context.priority },
                set: { newValue in Task { await context.updatePriority(newValue) } }
            )) {
                ForEach(Priority.allCases, id: \.self) { priority in
                    Label {
                        Text(priority.displayName)
                    } icon: {
                        Image(systemName: priority.systemImageName)
                            .foregroundColor(priority.color)
                    }
                    .tag(priority)
                }
            }
            
            Picker("Category", selection: Binding(
                get: { context.category },
                set: { newValue in Task { await context.updateCategory(newValue) } }
            )) {
                ForEach(Category.allCases, id: \.self) { category in
                    Label {
                        Text(category.displayName)
                    } icon: {
                        Text(category.emoji)
                    }
                    .tag(category)
                }
            }
            
            if context.selectedTemplate != nil {
                HStack {
                    Text("Template")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(context.selectedTemplate?.name ?? "")
                        .foregroundColor(.blue)
                    Button("Clear") {
                        Task { await context.clearTemplate() }
                    }
                    .font(.caption)
                }
            }
        }
    }
    
    private var dueDateSection: some View {
        Section {
            Toggle("Set due date", isOn: Binding(
                get: { context.hasDueDate },
                set: { _ in Task { await context.toggleHasDueDate() } }
            ))
            
            if context.hasDueDate {
                DatePicker(
                    "Due date",
                    selection: Binding(
                        get: { context.dueDate ?? Date() },
                        set: { newValue in Task { await context.updateDueDate(newValue) } }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
                
                // Quick date options
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(QuickDueDateOption.allCases, id: \.self) { option in
                        Button(option.displayName) {
                            Task { await context.setQuickDueDate(option) }
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
            }
        } header: {
            Text("Due Date")
        }
    }
    
    private var tagsSection: some View {
        Section("Tags") {
            // Existing tags
            if !context.tagsArray.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.adaptive(minimum: 80)), count: 1), spacing: 8) {
                    ForEach(context.tagsArray, id: \.self) { tag in
                        HStack {
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            Button {
                                Task { await context.removeTag(tag) }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            
            // Add new tag
            HStack {
                TextField("Add tag", text: Binding(
                    get: { context.newTag },
                    set: { newValue in Task { await context.updateNewTag(newValue) } }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Add") {
                    Task { await context.addTag() }
                }
                .disabled(context.newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private var validationErrorsSection: some View {
        Section {
            ForEach(context.formValidationErrors, id: \.self) { error in
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    // MARK: - Navigation Items
    
    private var cancelButton: some View {
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private var actionButtons: some View {
        HStack {
            Button("Templates") {
                showingTemplates = true
            }
            .disabled(context.isLoading)
            
            Menu {
                Button("Create & Add Another") {
                    Task { await context.createTaskAndAddAnother() }
                }
                .disabled(!context.canCreate)
                
                Button("Create Task") {
                    Task { 
                        await context.createTask()
                        if context.isCreated {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .disabled(!context.canCreate)
            } label: {
                if context.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Create")
                        .fontWeight(.semibold)
                }
            }
            .disabled(!context.canCreate || context.isLoading)
        }
    }
}

// MARK: - Template Selection View

private struct TemplateSelectionView: View {
    @ObservedObject var context: CreateTaskContext
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(context.availableTemplates) { template in
                        TemplateRowView(template: template) {
                            Task {
                                await context.applyTemplate(template)
                                isPresented = false
                            }
                        }
                    }
                } header: {
                    Text("Choose a template to get started quickly")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button("Start from scratch") {
                        Task { await context.clearTemplate() }
                        isPresented = false
                    }
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Templates")
            .navigationBarItems(trailing: Button("Cancel") { isPresented = false })
        }
    }
}

private struct TemplateRowView: View {
    let template: TaskTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(template.priority.color)
                            .frame(width: 8, height: 8)
                        
                        Text(template.category.emoji)
                            .font(.caption)
                    }
                }
                
                Text(template.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                if !template.tags.isEmpty {
                    HStack {
                        ForEach(Array(template.tags).prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        if template.tags.count > 3 {
                            Text("+\(template.tags.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let defaultDueDate = template.defaultDueDate {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Default due: \(RelativeDateTimeFormatter().localizedString(for: defaultDueDate, relativeTo: Date()))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Error and Success Banners

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

private struct SuccessBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("OK") {
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