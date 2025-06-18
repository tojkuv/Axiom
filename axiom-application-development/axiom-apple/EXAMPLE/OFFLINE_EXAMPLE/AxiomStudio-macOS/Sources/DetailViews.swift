import SwiftUI
import AxiomStudio_Shared

// MARK: - Personal Info Detail View

struct PersonalInfoDetailView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var selectedTab = 0
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Tasks").tag(0)
                Text("Calendar").tag(1)
                Text("Contacts").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content area
            TabView(selection: $selectedTab) {
                TasksDetailView(searchText: $searchText)
                    .tag(0)
                
                CalendarDetailView()
                    .tag(1)
                
                ContactsDetailView(searchText: $searchText)
                    .tag(2)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                HStack {
                    SearchField(text: $searchText)
                        .frame(width: 200)
                    
                    Button(action: addNewItem) {
                        Image(systemName: "plus")
                    }
                    .help("Add new item")
                }
            }
        }
    }
    
    private func addNewItem() {
        switch selectedTab {
        case 0:
            // Add new task
            break
        case 1:
            // Add new calendar event
            break
        case 2:
            // Add new contact
            break
        default:
            break
        }
    }
}

struct TasksDetailView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @Binding var searchText: String
    @State private var tasks: [StudioTask] = []
    @State private var selectedTask: StudioTask?
    @State private var sortOrder = TaskSortOrder.dueDate
    @State private var filterPriority: TaskPriority?
    @State private var filterCategory: TaskCategory?
    
    var filteredTasks: [StudioTask] {
        var filtered = tasks
        
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        if let priority = filterPriority {
            filtered = filtered.filter { $0.priority == priority }
        }
        
        if let category = filterCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        return filtered.sorted(by: sortOrder.comparator)
    }
    
    var body: some View {
        HSplitView {
            // Task list
            VStack(spacing: 0) {
                // Filters and sort
                HStack {
                    Menu("Priority") {
                        Button("All") { filterPriority = nil }
                        Divider()
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Button(priority.displayName) {
                                filterPriority = priority
                            }
                        }
                    }
                    .menuStyle(.button)
                    .frame(width: 80)
                    
                    Menu("Category") {
                        Button("All") { filterCategory = nil }
                        Divider()
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Button(category.displayName) {
                                filterCategory = category
                            }
                        }
                    }
                    .menuStyle(.button)
                    .frame(width: 80)
                    
                    Spacer()
                    
                    Menu("Sort") {
                        ForEach(TaskSortOrder.allCases, id: \.self) { order in
                            Button(order.displayName) {
                                sortOrder = order
                            }
                        }
                    }
                    .menuStyle(.button)
                    .frame(width: 80)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.controlBackgroundColor))
                
                Divider()
                
                // Task list
                List(filteredTasks, id: \.id, selection: $selectedTask) { task in
                    TaskRowDetailView(task: task)
                        .tag(task)
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 300, maxWidth: 400)
            
            // Task detail
            if let selectedTask = selectedTask {
                TaskDetailPanelView(task: selectedTask) { updatedTask in
                    Task {
                        try? await orchestrator.updateTask(updatedTask)
                        await loadTasks()
                    }
                } onDelete: {
                    Task {
                        try? await orchestrator.deleteTask(selectedTask.id)
                        await loadTasks()
                        self.selectedTask = nil
                    }
                }
            } else {
                VStack {
                    Image(systemName: "checklist")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Select a task to view details")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            Task {
                await loadTasks()
            }
        }
    }
    
    private func loadTasks() async {
        tasks = await orchestrator.getCurrentTasks()
    }
}

enum TaskSortOrder: CaseIterable {
    case title
    case dueDate
    case priority
    case category
    case createdAt
    
    var displayName: String {
        switch self {
        case .title: return "Title"
        case .dueDate: return "Due Date"
        case .priority: return "Priority"
        case .category: return "Category"
        case .createdAt: return "Created"
        }
    }
    
    var comparator: (StudioTask, StudioTask) -> Bool {
        switch self {
        case .title:
            return { $0.title < $1.title }
        case .dueDate:
            return { task1, task2 in
                switch (task1.dueDate, task2.dueDate) {
                case (.none, .none): return false
                case (.some, .none): return true
                case (.none, .some): return false
                case (.some(let date1), .some(let date2)): return date1 < date2
                }
            }
        case .priority:
            return { $0.priority.sortOrder < $1.priority.sortOrder }
        case .category:
            return { $0.category.displayName < $1.category.displayName }
        case .createdAt:
            return { $0.createdAt > $1.createdAt }
        }
    }
}

struct TaskRowDetailView: View {
    let task: StudioTask
    
    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(task.priority.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(task.priority.color.opacity(0.2))
                        .foregroundColor(task.priority.color)
                        .cornerRadius(4)
                    
                    if let dueDate = task.dueDate {
                        Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(dueDate < Date() ? .red : .blue)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct TaskDetailPanelView: View {
    @State var task: StudioTask
    @State private var editedTitle: String
    @State private var editedDescription: String
    @State private var editedPriority: TaskPriority
    @State private var editedCategory: TaskCategory
    @State private var editedDueDate: Date?
    @State private var editedIsCompleted: Bool
    
    let onSave: (StudioTask) -> Void
    let onDelete: () -> Void
    
    init(task: StudioTask, onSave: @escaping (StudioTask) -> Void, onDelete: @escaping () -> Void) {
        self.task = task
        self.onSave = onSave
        self.onDelete = onDelete
        self._editedTitle = State(initialValue: task.title)
        self._editedDescription = State(initialValue: task.description ?? "")
        self._editedPriority = State(initialValue: task.priority)
        self._editedCategory = State(initialValue: task.category)
        self._editedDueDate = State(initialValue: task.dueDate)
        self._editedIsCompleted = State(initialValue: task.isCompleted)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title and completion
                HStack {
                    TextField("Task title", text: $editedTitle)
                        .font(.title2)
                        .textFieldStyle(.roundedBorder)
                    
                    Toggle("Completed", isOn: $editedIsCompleted)
                        .toggleStyle(.switch)
                }
                
                Divider()
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    
                    TextEditor(text: $editedDescription)
                    .frame(minHeight: 100)
                    .border(Color.gray.opacity(0.3))
                }
                
                // Priority and Category
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.headline)
                        
                        Picker("Priority", selection: $editedPriority) {
                            ForEach(TaskPriority.allCases, id: \.self) { priority in
                                Text(priority.displayName).tag(priority)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                        
                        Picker("Category", selection: $editedCategory) {
                            ForEach(TaskCategory.allCases, id: \.self) { category in
                                Text(category.displayName).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // Due date
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Due Date")
                            .font(.headline)
                        
                        Spacer()
                        
                        Toggle("Set due date", isOn: Binding(
                            get: { editedDueDate != nil },
                            set: { hasDueDate in
                                if hasDueDate && editedDueDate == nil {
                                    editedDueDate = Date()
                                } else if !hasDueDate {
                                    editedDueDate = nil
                                }
                            }
                        ))
                    }
                    
                    if editedDueDate != nil {
                        DatePicker(
                            "Due Date",
                            selection: Binding(
                                get: { editedDueDate ?? Date() },
                                set: { editedDueDate = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                    }
                }
                
                // Tags
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                    
                    // Simple tag display for now
                    if !task.tags.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                            ForEach(task.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                    } else {
                        Text("No tags")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Actions
                HStack {
                    Button("Save Changes") {
                        let updatedTask = StudioTask(
                            id: task.id,
                            title: editedTitle,
                            description: editedDescription.isEmpty ? nil : editedDescription,
                            priority: editedPriority,
                            category: editedCategory,
                            status: editedIsCompleted ? .completed : .pending,
                            dueDate: editedDueDate,
                            createdAt: task.createdAt,
                            updatedAt: Date(),
                            contactId: task.contactId,
                            calendarEventId: task.calendarEventId,
                            locationReminder: task.locationReminder,
                            tags: task.tags
                        )
                        onSave(updatedTask)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    
                    Button("Delete Task", role: .destructive) {
                        onDelete()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .frame(minWidth: 400)
    }
}

struct CalendarDetailView: View {
    var body: some View {
        VStack {
            Text("Calendar View")
                .font(.title)
            
            Text("Calendar integration will be implemented here")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContactsDetailView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @Binding var searchText: String
    @State private var contacts: [Contact] = []
    @State private var selectedContact: Contact?
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        } else {
            return contacts.filter { contact in
                contact.displayName.localizedCaseInsensitiveContains(searchText) ||
                contact.emailAddresses.contains { $0.value.localizedCaseInsensitiveContains(searchText) } ||
                (contact.organizationName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        HSplitView {
            // Contact list
            VStack(spacing: 0) {
                List(filteredContacts, id: \.id, selection: $selectedContact) { contact in
                    ContactRowDetailView(contact: contact)
                        .tag(contact)
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 300, maxWidth: 400)
            
            // Contact detail
            if let selectedContact = selectedContact {
                ContactDetailPanelView(contact: selectedContact)
            } else {
                VStack {
                    Image(systemName: "person.2")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Select a contact to view details")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            Task {
                contacts = await orchestrator.getCurrentContacts()
            }
        }
    }
}

struct ContactRowDetailView: View {
    let contact: Contact
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(contact.initials)
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.displayName)
                    .font(.headline)
                
                if let organizationName = contact.organizationName, !organizationName.isEmpty {
                    Text(organizationName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let primaryEmail = contact.emailAddresses.first {
                    Text(primaryEmail.value)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ContactDetailPanelView: View {
    let contact: Contact
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Contact header
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(contact.initials)
                                .font(.title)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contact.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if let organizationName = contact.organizationName, !organizationName.isEmpty {
                            Text(organizationName)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let jobTitle = contact.jobTitle, !jobTitle.isEmpty {
                            Text(jobTitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Contact information
                VStack(alignment: .leading, spacing: 16) {
                    if !contact.phoneNumbers.isEmpty {
                        ContactSectionView(title: "Phone Numbers") {
                            ForEach(contact.phoneNumbers, id: \.id) { phone in
                                ContactInfoRow(
                                    label: phone.label,
                                    value: phone.value,
                                    icon: "phone.fill"
                                )
                            }
                        }
                    }
                    
                    if !contact.emailAddresses.isEmpty {
                        ContactSectionView(title: "Email Addresses") {
                            ForEach(contact.emailAddresses, id: \.id) { email in
                                ContactInfoRow(
                                    label: email.label,
                                    value: email.value,
                                    icon: "envelope.fill"
                                )
                            }
                        }
                    }
                    
                    if !contact.postalAddresses.isEmpty {
                        ContactSectionView(title: "Addresses") {
                            ForEach(contact.postalAddresses, id: \.id) { address in
                                ContactInfoRow(
                                    label: address.label,
                                    value: address.formattedAddress,
                                    icon: "location.fill"
                                )
                            }
                        }
                    }
                    
                    if let note = contact.note, !note.isEmpty {
                        ContactSectionView(title: "Notes") {
                            Text(note)
                                .font(.body)
                                .padding()
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 400)
    }
}

struct ContactSectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
    }
}

struct ContactInfoRow: View {
    let label: String?
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.body)
                
                Text(label ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                // Handle action (call, email, etc.)
            }) {
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Search Field

struct SearchField: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search...", text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Other Detail Views (Placeholder implementations)

struct HealthLocationDetailView: View {
    var body: some View {
        Text("Health & Location Detail View")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentProcessorDetailView: View {
    var body: some View {
        Text("AI Content Processor Detail View")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MediaHubDetailView: View {
    var body: some View {
        Text("Media Hub Detail View")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PerformanceDetailView: View {
    var body: some View {
        Text("Performance Detail View")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}