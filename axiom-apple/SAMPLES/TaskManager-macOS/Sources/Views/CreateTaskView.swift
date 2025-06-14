import SwiftUI
import Axiom

// Import shared Task Manager components
import TaskManager_Shared

// MARK: - Create Task View (macOS)

/// Comprehensive task creation view for macOS with advanced features
public struct CreateTaskView: View, PresentationProtocol {
    public typealias ContextType = CreateTaskContext
    
    @ObservedObject public var context: CreateTaskContext
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var focusedField: CreateField?
    @State private var showingTemplates = false
    @State private var selectedTabIndex = 0
    
    public init(context: CreateTaskContext) {
        self.context = context
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Main content
            TabView(selection: $selectedTabIndex) {
                basicInfoTab
                    .tabItem {
                        Label("Basic", systemImage: "doc.text")
                    }
                    .tag(0)
                
                advancedTab
                    .tabItem {
                        Label("Advanced", systemImage: "gearshape")
                    }
                    .tag(1)
            }
            .frame(minHeight: 400)
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 600, height: 550)
        .onAppear {
            _Concurrency.Task { await context.appeared() }
            focusedField = .title
        }
        .onChange(of: context.shouldCloseWindow) { shouldClose in
            if shouldClose {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .alert("Validation Error", isPresented: .constant(context.hasValidationErrors)) {
            Button("OK") { }
        } message: {
            if let titleError = context.titleFieldError {
                Text(titleError)
            }
        }
        .alert("Error", isPresented: .constant(context.error != nil)) {
            Button("OK") {
                _Concurrency.Task { await context.clearError() }
            }
        } message: {
            if let error = context.error {
                Text(error)
            }
        }
        .sheet(isPresented: $showingTemplates) {
            TemplatePickerView(context: context, isPresented: $showingTemplates)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Create New Task")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let template = context.selectedTemplate {
                    Text("Using template: \(template.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Header actions
            HStack(spacing: 8) {
                Button("Templates") {
                    showingTemplates = true
                }
                .buttonStyle(.bordered)
                
                Button("Cancel") {
                    _Concurrency.Task { await context.cancelCreation() }
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Basic Info Tab
    
    private var basicInfoTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Title")
                            .font(.headline)
                        
                        Text("*")
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        if !context.title.isEmpty {
                            Text("\(context.title.count) characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    TextField("Enter task title", text: Binding(
                        get: { context.title },
                        set: { newValue in _Concurrency.Task { await context.updateTitle(newValue) } }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .title)
                    
                    if let titleError = context.titleFieldError {
                        Text(titleError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Description")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(context.taskDescription.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    TextEditor(text: Binding(
                        get: { context.taskDescription },
                        set: { newValue in _Concurrency.Task { await context.updateDescription(newValue) } }
                    ))
                    .frame(minHeight: 80)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(4)
                    .focused($focusedField, equals: .description)
                }
                
                // Priority and Category
                HStack(spacing: 20) {
                    // Priority
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.headline)
                        
                        Picker("Priority", selection: Binding(
                            get: { context.priority },
                            set: { newValue in _Concurrency.Task { await context.updatePriority(newValue) } }
                        )) {
                            ForEach(Priority.allCases, id: \.self) { priority in
                                Label(priority.displayName, systemImage: priority.systemImageName)
                                    .tag(priority)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                        
                        Picker("Category", selection: Binding(
                            get: { context.category },
                            set: { newValue in _Concurrency.Task { await context.updateCategory(newValue) } }
                        )) {
                            ForEach(TaskManager_Shared.Category.allCases, id: \.self) { category in
                                Label(category.displayName, systemImage: category.systemImageName)
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // Due Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Due Date")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Set due date", isOn: Binding(
                            get: { context.hasDueDate },
                            set: { newValue in _Concurrency.Task { await context.toggleDueDate(newValue) } }
                        ))
                        
                        if context.hasDueDate {
                            DatePicker(
                                "Due date",
                                selection: Binding(
                                    get: { context.dueDate ?? Date() },
                                    set: { newValue in _Concurrency.Task { await context.updateDueDate(newValue) } }
                                ),
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            
                            if let dueDateError = context.dueDateFieldError {
                                Text(dueDateError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Advanced Tab
    
    private var advancedTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Notes")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(context.notes.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    TextEditor(text: Binding(
                        get: { context.notes },
                        set: { newValue in _Concurrency.Task { await context.updateNotes(newValue) } }
                    ))
                    .frame(minHeight: 100)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(4)
                    .focused($focusedField, equals: .notes)
                }
                
                // Tags
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Tag input
                        HStack {
                            TextField("Add tag", text: Binding(
                                get: { context.currentTag },
                                set: { newValue in _Concurrency.Task { await context.updateCurrentTag(newValue) } }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                _Concurrency.Task { await context.addTag() }
                            }
                            
                            Button("Add") {
                                _Concurrency.Task { await context.addTag() }
                            }
                            .disabled(context.currentTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        
                        // Tag list
                        if !context.tags.isEmpty {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 80), spacing: 8)
                            ], spacing: 8) {
                                ForEach(context.tags, id: \.self) { tag in
                                    TagView(tag: tag) {
                                        _Concurrency.Task { await context.removeTag(tag) }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                // Reminders
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reminders")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Set reminder", isOn: Binding(
                            get: { context.hasReminder },
                            set: { newValue in _Concurrency.Task { await context.toggleReminder(newValue) } }
                        ))
                        
                        if context.hasReminder {
                            DatePicker(
                                "Reminder time",
                                selection: Binding(
                                    get: { context.reminderTime ?? Date() },
                                    set: { newValue in _Concurrency.Task { await context.updateReminderTime(newValue) } }
                                ),
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            
                            if let reminderError = context.reminderFieldError {
                                Text(reminderError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                // Estimated Duration
                VStack(alignment: .leading, spacing: 8) {
                    Text("Estimated Duration")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Set estimated duration", isOn: Binding(
                            get: { context.hasEstimatedDuration },
                            set: { newValue in _Concurrency.Task { await context.toggleEstimatedDuration(newValue) } }
                        ))
                        
                        if context.hasEstimatedDuration {
                            HStack {
                                Stepper(
                                    "Hours: \(Int((context.estimatedDuration ?? 0) / 3600))",
                                    value: Binding(
                                        get: { Int((context.estimatedDuration ?? 0) / 3600) },
                                        set: { newHours in
                                            let minutes = Int((context.estimatedDuration ?? 0).truncatingRemainder(dividingBy: 3600)) / 60
                                            let newDuration = TimeInterval(newHours * 3600 + minutes * 60)
                                            _Concurrency.Task { await context.updateEstimatedDuration(newDuration) }
                                        }
                                    ),
                                    in: 0...24
                                )
                                
                                Stepper(
                                    "Minutes: \(Int((context.estimatedDuration ?? 0).truncatingRemainder(dividingBy: 3600)) / 60)",
                                    value: Binding(
                                        get: { Int((context.estimatedDuration ?? 0).truncatingRemainder(dividingBy: 3600)) / 60 },
                                        set: { newMinutes in
                                            let hours = Int((context.estimatedDuration ?? 0) / 3600)
                                            let newDuration = TimeInterval(hours * 3600 + newMinutes * 60)
                                            _Concurrency.Task { await context.updateEstimatedDuration(newDuration) }
                                        }
                                    ),
                                    in: 0...59
                                )
                            }
                            
                            if let duration = context.estimatedDuration, duration > 0 {
                                Text("Total: \(context.estimatedDurationText)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Footer View
    
    private var footerView: some View {
        HStack {
            // Validation status
            if context.hasValidationErrors {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text("Please fix validation errors")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else if context.canCreateTask {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Ready to create")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Create & New") {
                    _Concurrency.Task { await context.createTaskAndNew() }
                }
                .disabled(!context.canCreateTask)
                .keyboardShortcut("n", modifiers: [.command, .shift])
                
                Button("Create Task") {
                    _Concurrency.Task { await context.createTask() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!context.canCreateTask || context.isCreating)
                .keyboardShortcut(.return, modifiers: .command)
                
                if context.isCreating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Tag View

private struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .foregroundColor(.primary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Template Picker View

private struct TemplatePickerView: View {
    let context: CreateTaskContext
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Choose a Template")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Close") {
                    isPresented = false
                }
            }
            
            // Template list
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 200), spacing: 16)
                ], spacing: 16) {
                    ForEach(context.availableTemplates, id: \.id) { template in
                        TemplateCardView(template: template) {
                            _Concurrency.Task {
                                await context.applyTemplate(template)
                                isPresented = false
                            }
                        }
                    }
                }
                .padding()
            }
            
            // Footer
            HStack {
                if context.selectedTemplate != nil {
                    Button("Clear Template") {
                        _Concurrency.Task { await context.clearTemplate() }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

// MARK: - Template Card View

struct TemplateCardView: View {
    let template: TaskTemplate
    let onSelect: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(template.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                priorityIndicator
            }
            
            // Content preview
            VStack(alignment: .leading, spacing: 8) {
                if !template.title.isEmpty {
                    Text("Title: \(template.title)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if !template.description.isEmpty {
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                // Metadata
                HStack {
                    categoryBadge
                    
                    if template.hasDueDate {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // Action
            Button("Use Template") {
                onSelect()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(height: 150)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(NSColor.separatorColor), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private var priorityIndicator: some View {
        Circle()
            .fill(priorityColor)
            .frame(width: 8, height: 8)
    }
    
    private var priorityColor: Color {
        switch template.priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
    
    private var categoryBadge: some View {
        Text(template.category.displayName)
            .font(.caption2)
            .foregroundColor(categoryColor)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(categoryColor.opacity(0.1))
            .cornerRadius(3)
    }
    
    private var categoryColor: Color {
        switch template.category {
        case .work: return .blue
        case .personal: return .green
        case .shopping: return .purple
        case .health: return .red
        case .finance: return .orange
        case .education: return .indigo
        case .travel: return .teal
        case .home: return .brown
        case .social: return .pink
        case .hobby: return .mint
        case .other: return .gray
        }
    }
}

// MARK: - Create Field Enum

private enum CreateField: Hashable {
    case title
    case description
    case notes
}