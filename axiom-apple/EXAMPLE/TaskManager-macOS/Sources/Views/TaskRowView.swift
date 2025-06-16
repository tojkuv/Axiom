import SwiftUI
import Axiom

// Import shared Task Manager components
import TaskManager_Shared

// MARK: - Task Row View (macOS)

/// Individual task row view for macOS list display with desktop-specific interactions
public struct TaskRowView: View {
    let task: Task
    let isSelected: Bool
    let isFocused: Bool
    let onSelect: () -> Void
    let onDoubleClick: () -> Void
    let onToggleComplete: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var showingContextMenu = false
    
    public init(
        task: Task,
        isSelected: Bool = false,
        isFocused: Bool = false,
        onSelect: @escaping () -> Void,
        onDoubleClick: @escaping () -> Void,
        onToggleComplete: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.task = task
        self.isSelected = isSelected
        self.isFocused = isFocused
        self.onSelect = onSelect
        self.onDoubleClick = onDoubleClick
        self.onToggleComplete = onToggleComplete
        self.onDelete = onDelete
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Completion checkbox
            Button(action: onToggleComplete) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
            
            // Priority indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
                .opacity(task.priority == .low ? 0.6 : 1.0)
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Due date indicator
                    if let dueDate = task.dueDate {
                        dueDateView(dueDate)
                    }
                }
                
                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Tags and metadata
                HStack(spacing: 8) {
                    // Category badge
                    categoryBadge
                    
                    if task.hasNotes {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if task.hasReminder {
                        Image(systemName: "bell")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    // Creation/completion date
                    timeMetadata
                }
            }
            
            // Hover actions
            if isHovered || isSelected {
                HStack(spacing: 4) {
                    Button(action: onToggleComplete) {
                        Image(systemName: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help(task.isCompleted ? "Mark as pending" : "Mark as complete")
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete task")
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(rowBackgroundColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(focusBorderColor, lineWidth: isFocused ? 2 : 0)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onTapGesture(count: 2) {
            onDoubleClick()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            contextMenuContent
        }
        .help(task.title)
    }
    
    // MARK: - Supporting Views
    
    private var priorityColor: Color {
        switch task.priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
    
    private var rowBackgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.15)
        } else if isHovered {
            return Color(NSColor.controlAccentColor).opacity(0.05)
        } else {
            return Color.clear
        }
    }
    
    private var focusBorderColor: Color {
        return Color.accentColor
    }
    
    private func dueDateView(_ dueDate: Date) -> some View {
        HStack(spacing: 4) {
            Image(systemName: dueDateIcon)
                .font(.caption)
                .foregroundColor(dueDateColor)
            
            Text(dueDateText(dueDate))
                .font(.caption)
                .foregroundColor(dueDateColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(dueDateColor.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var dueDateIcon: String {
        guard let dueDate = task.dueDate else { return "calendar" }
        
        if task.isCompleted {
            return "calendar.badge.checkmark"
        } else if dueDate < Date() {
            return "calendar.badge.exclamationmark"
        } else if Calendar.current.isDateInToday(dueDate) {
            return "calendar.badge.clock"
        } else {
            return "calendar"
        }
    }
    
    private var dueDateColor: Color {
        guard let dueDate = task.dueDate else { return .secondary }
        
        if task.isCompleted {
            return .green
        } else if dueDate < Date() {
            return .red
        } else if Calendar.current.isDateInToday(dueDate) {
            return .orange
        } else if Calendar.current.isDateInTomorrow(dueDate) {
            return .blue
        } else {
            return .secondary
        }
    }
    
    private func dueDateText(_ dueDate: Date) -> String {
        if Calendar.current.isDateInToday(dueDate) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(dueDate) {
            return "Tomorrow"
        } else if Calendar.current.isDateInYesterday(dueDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: dueDate)
        }
    }
    
    private var categoryBadge: some View {
        Text(task.category.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(categoryTextColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(categoryBackgroundColor)
            .cornerRadius(3)
    }
    
    private var categoryTextColor: Color {
        switch task.category {
        case .work:
            return .blue
        case .personal:
            return .green
        case .shopping:
            return .purple
        case .health:
            return .red
        case .finance:
            return .orange
        }
    }
    
    private var categoryBackgroundColor: Color {
        categoryTextColor.opacity(0.15)
    }
    
    private var timeMetadata: some View {
        Group {
            if task.isCompleted, let completedAt = task.completedAt {
                HStack(spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    
                    Text("Completed \(RelativeDateTimeFormatter().localizedString(for: completedAt, relativeTo: Date()))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Created \(RelativeDateTimeFormatter().localizedString(for: task.createdAt, relativeTo: Date()))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var contextMenuContent: some View {
        Group {
            Button(task.isCompleted ? "Mark as Pending" : "Mark as Complete") {
                onToggleComplete()
            }
            
            Divider()
            
            Button("Open in New Window") {
                onDoubleClick()
            }
            
            Button("Duplicate") {
                // Handle duplicate
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
}

// MARK: - Task Card View (for grid/column layouts)

public struct TaskCardView: View {
    let task: Task
    let isSelected: Bool
    let compact: Bool
    let onSelect: () -> Void
    let onToggleComplete: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    public init(
        task: Task,
        isSelected: Bool = false,
        compact: Bool = false,
        onSelect: @escaping () -> Void,
        onToggleComplete: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.task = task
        self.isSelected = isSelected
        self.compact = compact
        self.onSelect = onSelect
        self.onToggleComplete = onToggleComplete
        self.onDelete = onDelete
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 8) {
            // Header with priority and completion
            HStack {
                // Priority indicator
                Circle()
                    .fill(priorityColor)
                    .frame(width: compact ? 6 : 8, height: compact ? 6 : 8)
                
                Spacer()
                
                // Completion button
                Button(action: onToggleComplete) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(compact ? .caption : .body)
                        .foregroundColor(task.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Title
            Text(task.title)
                .font(compact ? .caption : .body)
                .fontWeight(.medium)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
                .strikethrough(task.isCompleted)
                .lineLimit(compact ? 1 : 2)
                .multilineTextAlignment(.leading)
            
            // Description (if not compact)
            if !compact && !task.taskDescription.isEmpty {
                Text(task.taskDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Footer with category and due date
            VStack(alignment: .leading, spacing: 4) {
                // Category
                categoryBadge
                
                // Due date
                if let dueDate = task.dueDate {
                    dueDateView(dueDate)
                }
                
                // Metadata icons
                if !compact {
                    HStack(spacing: 6) {
                        if task.hasNotes {
                            Image(systemName: "note.text")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if task.hasReminder {
                            Image(systemName: "bell")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(compact ? 8 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: compact ? 80 : 120)
        .background(cardBackgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(borderColor, lineWidth: isSelected ? 2 : 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(color: Color.black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 4 : 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            contextMenuContent
        }
    }
    
    // MARK: - Supporting Views
    
    private var priorityColor: Color {
        switch task.priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
    
    private var cardBackgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.1)
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.accentColor
        } else {
            return Color(NSColor.separatorColor)
        }
    }
    
    private var categoryBadge: some View {
        Text(task.category.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(categoryTextColor)
            .padding(.horizontal, compact ? 4 : 6)
            .padding(.vertical, 2)
            .background(categoryBackgroundColor)
            .cornerRadius(3)
    }
    
    private var categoryTextColor: Color {
        switch task.category {
        case .work:
            return .blue
        case .personal:
            return .green
        case .shopping:
            return .purple
        case .health:
            return .red
        case .finance:
            return .orange
        }
    }
    
    private var categoryBackgroundColor: Color {
        categoryTextColor.opacity(0.15)
    }
    
    private func dueDateView(_ dueDate: Date) -> some View {
        HStack(spacing: 2) {
            Image(systemName: dueDateIcon)
                .font(.caption2)
                .foregroundColor(dueDateColor)
            
            Text(dueDateText(dueDate))
                .font(.caption2)
                .foregroundColor(dueDateColor)
        }
    }
    
    private var dueDateIcon: String {
        guard let dueDate = task.dueDate else { return "calendar" }
        
        if task.isCompleted {
            return "calendar.badge.checkmark"
        } else if dueDate < Date() {
            return "calendar.badge.exclamationmark"
        } else if Calendar.current.isDateInToday(dueDate) {
            return "calendar.badge.clock"
        } else {
            return "calendar"
        }
    }
    
    private var dueDateColor: Color {
        guard let dueDate = task.dueDate else { return .secondary }
        
        if task.isCompleted {
            return .green
        } else if dueDate < Date() {
            return .red
        } else if Calendar.current.isDateInToday(dueDate) {
            return .orange
        } else if Calendar.current.isDateInTomorrow(dueDate) {
            return .blue
        } else {
            return .secondary
        }
    }
    
    private func dueDateText(_ dueDate: Date) -> String {
        if Calendar.current.isDateInToday(dueDate) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(dueDate) {
            return "Tomorrow"
        } else if Calendar.current.isDateInYesterday(dueDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: dueDate)
        }
    }
    
    private var contextMenuContent: some View {
        Group {
            Button(task.isCompleted ? "Mark as Pending" : "Mark as Complete") {
                onToggleComplete()
            }
            
            Button("Open in New Window") {
                // Handle open in new window
            }
            
            Button("Duplicate") {
                // Handle duplicate
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
}

// MARK: - Task Inspector View

public struct TaskInspectorView: View {
    let task: Task
    let context: TaskListContext
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Task Details")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    _Concurrency.Task { await context.toggleInspector() }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Task info
            VStack(alignment: .leading, spacing: 12) {
                // Title
                HStack {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .green : .secondary)
                    
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.isCompleted)
                }
                
                // Description
                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(title: "Priority", value: task.priority.displayName, color: priorityColor)
                    InfoRow(title: "Category", value: task.category.displayName, color: categoryColor)
                    
                    if let dueDate = task.dueDate {
                        InfoRow(title: "Due Date", value: DateFormatter.long.string(from: dueDate))
                    }
                    
                    InfoRow(title: "Created", value: DateFormatter.long.string(from: task.createdAt))
                    
                    if task.isCompleted, let completedAt = task.completedAt {
                        InfoRow(title: "Completed", value: DateFormatter.long.string(from: completedAt))
                    }
                }
                
                // Notes
                if !task.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(task.notes)
                            .font(.body)
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: 8) {
                Button(task.isCompleted ? "Mark as Pending" : "Mark as Complete") {
                    _Concurrency.Task { await context.toggleTaskCompletion(taskId: task.id) }
                }
                .buttonStyle(.borderedProminent)
                
                HStack {
                    Button("Edit") {
                        // Handle edit
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Duplicate") {
                        _Concurrency.Task { await context.duplicateTask(taskId: task.id) }
                    }
                    .buttonStyle(.bordered)
                }
                
                Button("Delete", role: .destructive) {
                    _Concurrency.Task { await context.deleteTask(taskId: task.id) }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
    
    private var categoryColor: Color {
        switch task.category {
        case .work: return .blue
        case .personal: return .green
        case .shopping: return .purple
        case .health: return .red
        case .finance: return .orange
        }
    }
}

// MARK: - Multi-Selection Detail View

public struct MultiSelectionDetailView: View {
    let selectedTasks: [Task]
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("\(selectedTasks.count) Tasks Selected")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Categories:")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(uniqueCategoriesText)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Priorities:")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(uniquePrioritiesText)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Completed:")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(completedCount)/\(selectedTasks.count)")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
    }
    
    private var uniqueCategoriesText: String {
        let categories = Set(selectedTasks.map { $0.category })
        return categories.map { $0.displayName }.sorted().joined(separator: ", ")
    }
    
    private var uniquePrioritiesText: String {
        let priorities = Set(selectedTasks.map { $0.priority })
        return priorities.map { $0.displayName }.sorted().joined(separator: ", ")
    }
    
    private var completedCount: Int {
        selectedTasks.filter { $0.isCompleted }.count
    }
}

// MARK: - Info Row View

private struct InfoRow: View {
    let title: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.body)
                .foregroundColor(color)
            
            Spacer()
        }
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let long: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
}