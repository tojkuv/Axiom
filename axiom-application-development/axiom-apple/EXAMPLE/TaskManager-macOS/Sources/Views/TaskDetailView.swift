import SwiftUI
import Axiom

// Import shared Task Manager components
import TaskManager_Shared

// MARK: - Task Detail View (macOS)

/// Comprehensive task detail view for macOS with full editing capabilities
public struct TaskDetailView: View, PresentationProtocol {
    public typealias ContextType = TaskDetailContext
    
    @ObservedObject public var context: TaskDetailContext
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteConfirmation = false
    @FocusState private var focusedField: DetailField?
    
    public init(context: TaskDetailContext) {
        self.context = context
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            navigationBar
            
            Divider()
            
            // Main content
            if context.isLoading {
                loadingView
            } else if let task = context.task {
                detailContent(task: task)
            } else {
                errorView
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .onAppear {
            _Concurrency.Task { await context.appeared() }
        }
        .onChange(of: context.shouldCloseWindow) { shouldClose in
            if shouldClose {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .alert("Delete Task", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                _Concurrency.Task { await context.deleteTask() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
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
    }
    
    // MARK: - Navigation Bar
    
    private var navigationBar: some View {
        HStack {
            // Title
            Text(context.windowTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(context.task?.isCompleted == true ? .secondary : .primary)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                if context.isEditing {
                    Button("Cancel") {
                        _Concurrency.Task { await context.cancelEditing() }
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                    
                    Button("Save") {
                        _Concurrency.Task { await context.saveChanges() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!context.canSave)
                    .keyboardShortcut("s", modifiers: .command)
                } else {
                    Button("Edit") {
                        _Concurrency.Task { await context.startEditing() }
                    }
                    .disabled(context.task == nil)
                    .keyboardShortcut("e", modifiers: .command)
                }
                
                Menu {
                    menuContent
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(context.task == nil)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var menuContent: some View {
        Group {
            if let task = context.task {
                Button(task.isCompleted ? "Mark as Pending" : "Mark as Complete") {
                    _Concurrency.Task { await context.toggleTaskCompletion() }
                }
                
                Button("Duplicate") {
                    _Concurrency.Task { await context.duplicateTask() }
                }
                
                Divider()
                
                Button("Delete", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }
        }
    }
    
    // MARK: - Detail Content
    
    private func detailContent(task: Task) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Main task info
                taskInfoSection(task: task)
                
                // Description section
                descriptionSection(task: task)
                
                // Details section
                detailsSection(task: task)
                
                // Notes section
                notesSection(task: task)
                
                // Metadata section
                metadataSection(task: task)
            }
            .padding()
        }
    }
    
    // MARK: - Task Info Section
    
    private func taskInfoSection(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Completion checkbox
                Button(action: {
                    _Concurrency.Task { await context.toggleTaskCompletion() }
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundColor(task.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    if context.isEditing {
                        TextField("Task title", text: Binding(
                            get: { context.editingTitle },
                            set: { newValue in _Concurrency.Task { await context.updateTitle(newValue) } }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.title2)
                        .focused($focusedField, equals: .title)
                    } else {
                        Text(task.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(task.isCompleted ? .secondary : .primary)
                            .strikethrough(task.isCompleted)
                    }
                    
                    // Status indicators
                    HStack(spacing: 12) {
                        // Priority
                        priorityIndicator(task: task)
                        
                        // Category
                        categoryIndicator(task: task)
                        
                        // Due date
                        if let dueDate = task.dueDate {
                            dueDateIndicator(dueDate: dueDate, isCompleted: task.isCompleted)
                        }
                    }
                }
                
                Spacer()
                
                // Priority circle (large)
                Circle()
                    .fill(priorityColor(task.priority))
                    .frame(width: 12, height: 12)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Description Section
    
    private func descriptionSection(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if context.isEditing {
                    Text("\(context.editingDescription.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if context.isEditing {
                TextEditor(text: Binding(
                    get: { context.editingDescription },
                    set: { newValue in _Concurrency.Task { await context.updateDescription(newValue) } }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 100)
                .focused($focusedField, equals: .description)
            } else {
                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("No description")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Details Section
    
    private func detailsSection(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Priority
                HStack {
                    Text("Priority")
                        .frame(width: 80, alignment: .leading)
                        .foregroundColor(.secondary)
                    
                    if context.isEditing {
                        Picker("Priority", selection: Binding(
                            get: { context.editingPriority },
                            set: { newValue in _Concurrency.Task { await context.updatePriority(newValue) } }
                        )) {
                            ForEach(Priority.allCases, id: \.self) { priority in
                                Label(priority.displayName, systemImage: priority.systemImageName)
                                    .tag(priority)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Label(task.priority.displayName, systemImage: task.priority.systemImageName)
                            .foregroundColor(priorityColor(task.priority))
                    }
                    
                    Spacer()
                }
                
                // Category
                HStack {
                    Text("Category")
                        .frame(width: 80, alignment: .leading)
                        .foregroundColor(.secondary)
                    
                    if context.isEditing {
                        Picker("Category", selection: Binding(
                            get: { context.editingCategory },
                            set: { newValue in _Concurrency.Task { await context.updateCategory(newValue) } }
                        )) {
                            ForEach(Category.allCases, id: \.self) { category in
                                Label(category.displayName, systemImage: category.systemImageName)
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Label(task.category.displayName, systemImage: task.category.systemImageName)
                            .foregroundColor(categoryColor(task.category))
                    }
                    
                    Spacer()
                }
                
                // Due date
                HStack {
                    Text("Due Date")
                        .frame(width: 80, alignment: .leading)
                        .foregroundColor(.secondary)
                    
                    if context.isEditing {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Has due date", isOn: Binding(
                                get: { context.isEditingDueDate },
                                set: { newValue in _Concurrency.Task { await context.toggleDueDateEditing(newValue) } }
                            ))
                            
                            if context.isEditingDueDate {
                                DatePicker(
                                    "Due date",
                                    selection: Binding(
                                        get: { context.editingDueDate ?? Date() },
                                        set: { newValue in _Concurrency.Task { await context.updateDueDate(newValue) } }
                                    ),
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.compact)
                            }
                        }
                    } else {
                        if let dueDate = task.dueDate {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(DateFormatter.fullDateTime.string(from: dueDate))
                                    .foregroundColor(dueDateColor(dueDate, isCompleted: task.isCompleted))
                                
                                Text(relativeDateText(dueDate))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("No due date")
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Notes Section
    
    private func notesSection(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Notes")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if context.isEditing {
                    Text("\(context.editingNotes.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if context.isEditing {
                TextEditor(text: Binding(
                    get: { context.editingNotes },
                    set: { newValue in _Concurrency.Task { await context.updateNotes(newValue) } }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 80)
                .focused($focusedField, equals: .notes)
            } else {
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("No notes")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Metadata Section
    
    private func metadataSection(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Information")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                MetadataRow(
                    label: "Created",
                    value: DateFormatter.fullDateTime.string(from: task.createdAt),
                    icon: "calendar.badge.plus"
                )
                
                if task.isCompleted, let completedAt = task.completedAt {
                    MetadataRow(
                        label: "Completed",
                        value: DateFormatter.fullDateTime.string(from: completedAt),
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    let duration = completedAt.timeIntervalSince(task.createdAt)
                    MetadataRow(
                        label: "Duration",
                        value: formatDuration(duration),
                        icon: "clock"
                    )
                }
                
                MetadataRow(
                    label: "ID",
                    value: task.id.uuidString,
                    icon: "number",
                    isMonospace: true
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Supporting Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading task...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Failed to load task")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let error = context.error {
                Text(error)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Close") {
                _Concurrency.Task { await context.requestCloseWindow() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func priorityIndicator(task: Task) -> some View {
        Label(task.priority.displayName, systemImage: task.priority.systemImageName)
            .font(.caption)
            .foregroundColor(priorityColor(task.priority))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor(task.priority).opacity(0.1))
            .cornerRadius(4)
    }
    
    private func categoryIndicator(task: Task) -> some View {
        Label(task.category.displayName, systemImage: task.category.systemImageName)
            .font(.caption)
            .foregroundColor(categoryColor(task.category))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(categoryColor(task.category).opacity(0.1))
            .cornerRadius(4)
    }
    
    private func dueDateIndicator(dueDate: Date, isCompleted: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: dueDateIcon(dueDate, isCompleted: isCompleted))
                .font(.caption)
            
            Text(relativeDateText(dueDate))
                .font(.caption)
        }
        .foregroundColor(dueDateColor(dueDate, isCompleted: isCompleted))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(dueDateColor(dueDate, isCompleted: isCompleted).opacity(0.1))
        .cornerRadius(4)
    }
    
    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
    
    private func categoryColor(_ category: TaskManager_Shared.Category) -> Color {
        switch category {
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
    
    private func dueDateColor(_ dueDate: Date, isCompleted: Bool) -> Color {
        if isCompleted {
            return .green
        } else if dueDate < Date() {
            return .red
        } else if Calendar.current.isDateInToday(dueDate) {
            return .orange
        } else {
            return .secondary
        }
    }
    
    private func dueDateIcon(_ dueDate: Date, isCompleted: Bool) -> String {
        if isCompleted {
            return "calendar.badge.checkmark"
        } else if dueDate < Date() {
            return "calendar.badge.exclamationmark"
        } else if Calendar.current.isDateInToday(dueDate) {
            return "calendar.badge.clock"
        } else {
            return "calendar"
        }
    }
    
    private func relativeDateText(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let days = Int(duration) / 86400
        let hours = (Int(duration) % 86400) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Metadata Row View

private struct MetadataRow: View {
    let label: String
    let value: String
    let icon: String
    var color: Color = .primary
    var isMonospace: Bool = false
    
    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(isMonospace ? .system(.caption, design: .monospaced) : .caption)
                .foregroundColor(color)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}

// MARK: - Detail Field Enum

private enum DetailField: Hashable {
    case title
    case description
    case notes
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
}