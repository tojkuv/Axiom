import SwiftUI
import AxiomStudio_Shared

struct PersonalInfoTabView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var selectedPersonalInfoTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedPersonalInfoTab) {
                TasksView()
                    .tabItem {
                        Image(systemName: "checklist")
                        Text("Tasks")
                    }
                    .tag(0)
                
                CalendarView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Calendar")
                    }
                    .tag(1)
                
                ContactsView()
                    .tabItem {
                        Image(systemName: "person.2")
                        Text("Contacts")
                    }
                    .tag(2)
            }
            .navigationTitle("Personal Info")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Add Task") {
                            Task {
                                try? await orchestrator.navigate(to: .createTask)
                            }
                        }
                        Button("Add Event") {
                            // Navigate to create event
                        }
                        Button("Settings") {
                            Task {
                                try? await orchestrator.navigate(to: .settings)
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
        }
    }
}

struct TasksView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var tasks: [StudioTask] = []
    @State private var showingCreateTask = false
    
    var body: some View {
        VStack {
            if tasks.isEmpty {
                EmptyTasksView()
            } else {
                List {
                    ForEach(tasks) { task in
                        TaskRowView(task: task) {
                            Task {
                                try? await orchestrator.updateTask(task)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                Task {
                                    try? await orchestrator.deleteTask(task.id)
                                }
                            }
                        }
                    }
                }
                .refreshable {
                    await loadTasks()
                }
            }
        }
        .onAppear {
            Task {
                await loadTasks()
            }
        }
        .sheet(isPresented: $showingCreateTask) {
            CreateTaskSheet()
        }
    }
    
    private func loadTasks() async {
        tasks = await orchestrator.getCurrentTasks()
    }
}

struct TaskRowView: View {
    let task: StudioTask
    let onUpdate: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                var updatedTask = task
                updatedTask.isCompleted.toggle()
                onUpdate()
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
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
                    if let dueDate = task.dueDate {
                        Label(dueDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(dueDate < Date() ? .red : .blue)
                    }
                    
                    Spacer()
                    
                    Text(task.priority.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(task.priority.color.opacity(0.2))
                        .foregroundColor(task.priority.color)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Tasks Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Tap the + button to create your first task")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct CreateTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var title = ""
    @State private var description = ""
    @State private var priority = TaskPriority.medium
    @State private var category = TaskCategory.personal
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                
                Section("Due Date") {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveTask()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveTask() async {
        let task = StudioTask(
            title: title,
            description: description.isEmpty ? nil : description,
            isCompleted: false,
            priority: priority,
            category: category,
            dueDate: hasDueDate ? dueDate : nil,
            createdAt: Date(),
            updatedAt: Date(),
            tags: [],
            subtasks: [],
            locationReminder: nil,
            contactIds: []
        )
        
        do {
            try await orchestrator.createTask(task)
            dismiss()
        } catch {
            print("Failed to create task: \(error)")
        }
    }
}

struct CalendarView: View {
    var body: some View {
        VStack {
            Text("Calendar View")
                .font(.title)
                .padding()
            
            Text("Calendar integration will be implemented here")
                .foregroundColor(.secondary)
        }
    }
}

struct ContactsView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var contacts: [Contact] = []
    
    var body: some View {
        VStack {
            if contacts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.2")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No Contacts")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Contacts will appear here once sync is enabled")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List(contacts) { contact in
                    ContactRowView(contact: contact)
                }
            }
        }
        .onAppear {
            Task {
                contacts = await orchestrator.getCurrentContacts()
            }
        }
    }
}

struct ContactRowView: View {
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
            
            VStack(alignment: .leading, spacing: 2) {
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