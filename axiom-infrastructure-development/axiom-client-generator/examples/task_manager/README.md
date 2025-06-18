# Task Manager Example - Axiom Swift Client Generator

This example demonstrates a complete task management application using the Axiom Swift Client Generator. It showcases all major features including state management, validation, pagination, search, and error handling.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Proto Schema](#proto-schema)
3. [Generated Code](#generated-code)
4. [Step-by-Step Tutorial](#step-by-step-tutorial)
5. [Advanced Features](#advanced-features)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

## Overview

The Task Manager example includes:
- **Comprehensive Task Management**: Create, read, update, delete tasks
- **Category Organization**: Organize tasks into categories
- **Search and Filtering**: Advanced search with filters
- **Pagination**: Handle large datasets efficiently
- **Real-time Updates**: Reactive state management
- **Validation**: Client-side validation with detailed error messages
- **Performance Optimization**: Smart caching and state updates

### Features Demonstrated

- ✅ **Actor-based Architecture**: Thread-safe client operations
- ✅ **Immutable State Management**: Functional state updates
- ✅ **Type-safe Actions**: Validated action processing
- ✅ **Reactive Streams**: AsyncStream-based observation
- ✅ **Error Handling**: Comprehensive error types
- ✅ **Performance**: Optimized for large datasets
- ✅ **Axiom Integration**: Perfect framework compatibility

## Proto Schema

The example uses a comprehensive proto schema that defines:

### Services
- `TaskService` - Main task management operations
- Axiom-specific options for state management
- Collection definitions for tasks and categories
- Caching and offline support configuration

### Core Entities
- **Task**: Main entity with full CRUD operations
- **Category**: Organizational structure
- **TaskComment**: Collaboration features
- **TaskAttachment**: File management

### Request/Response Types
- Comprehensive filtering and pagination
- Search capabilities with highlighting
- Statistics and analytics
- Batch operations

## Generated Code

When you run the generator on this proto, it creates:

```
generated/swift/
├── Clients/
│   ├── TaskManagerClient.swift      # Main actor client
│   ├── TaskManagerAction.swift      # Action enum
│   ├── TaskManagerState.swift       # State container
│   └── AxiomErrors.swift           # Error types
├── Contracts/
│   ├── TaskService.swift           # Proto contracts
│   ├── TaskModels.swift            # Message types
│   └── TaskEnums.swift             # Proto enums
├── Tests/
│   └── TaskManagerClientTests.swift # Unit tests
└── Documentation/
    ├── README.md                   # Overview
    ├── APIReference.md             # Complete API docs
    ├── IntegrationGuide.md         # Integration help
    ├── UsageExamples.md            # Code examples
    └── Troubleshooting.md          # Common issues
```

## Step-by-Step Tutorial

### Step 1: Generate the Swift Clients

```bash
# Navigate to the project root
cd axiom-client-generator

# Generate Swift clients from the proto file
axiom-client-generator generate \
  --proto-path examples/task_manager/proto/task_service.proto \
  --output-path examples/task_manager/generated \
  --languages swift \
  --validate \
  --verbose
```

### Step 2: Set Up Your iOS/macOS Project

1. **Create a new Xcode project** or open an existing one
2. **Add framework dependencies** to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/axiom/axiom-core", from: "1.0.0"),
    .package(url: "https://github.com/axiom/axiom-architecture", from: "1.0.0")
]
```

3. **Copy generated files** to your Xcode project
4. **Add to your target** in Xcode

### Step 3: Initialize the Client

```swift
import SwiftUI
import AxiomCore
import AxiomArchitecture

@main
struct TaskManagerApp: App {
    var body: some Scene {
        WindowGroup {
            TaskManagerView()
        }
    }
}

struct TaskManagerView: View {
    @StateObject private var viewModel = TaskManagerViewModel()
    
    var body: some View {
        NavigationView {
            TaskListView()
                .environmentObject(viewModel)
        }
    }
}
```

### Step 4: Create the View Model

```swift
@MainActor
class TaskManagerViewModel: ObservableObject {
    private let client = TaskManagerClient()
    
    @Published var tasks: [Task] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var stateObserver: Task<Void, Never>?
    
    init() {
        observeState()
        loadInitialData()
    }
    
    private func observeState() {
        stateObserver = Task {
            for await state in client.stateStream {
                self.tasks = state.tasks
                self.categories = state.categories
                self.isLoading = state.isLoading
                self.error = state.error?.localizedDescription
            }
        }
    }
    
    func loadInitialData() {
        Task {
            do {
                // Load categories first
                try await client.process(.getCategories(.init()))
                // Then load tasks
                try await client.process(.getTasks(.init(limit: 50)))
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    deinit {
        stateObserver?.cancel()
    }
}
```

### Step 5: Create the Task List View

```swift
struct TaskListView: View {
    @EnvironmentObject var viewModel: TaskManagerViewModel
    @State private var showingCreateTask = false
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading tasks...")
            } else {
                List(viewModel.tasks, id: \.id) { task in
                    TaskRowView(task: task)
                        .onTapGesture {
                            toggleTask(task)
                        }
                }
            }
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add Task") {
                    showingCreateTask = true
                }
            }
        }
        .sheet(isPresented: $showingCreateTask) {
            CreateTaskView()
                .environmentObject(viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error ?? "")
        }
    }
    
    private func toggleTask(_ task: Task) {
        Task {
            do {
                try await viewModel.client.process(
                    .toggleTaskCompletion(.init(taskId: task.id))
                )
            } catch {
                viewModel.error = error.localizedDescription
            }
        }
    }
}
```

### Step 6: Create Task Row View

```swift
struct TaskRowView: View {
    let task: Task
    
    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    PriorityBadge(priority: task.priority)
                    
                    if let dueDate = task.dueDate {
                        Text("Due: \\(dueDate, style: .date)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct PriorityBadge: View {
    let priority: TaskPriority
    
    var body: some View {
        Text(priorityText)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(priorityColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var priorityText: String {
        switch priority {
        case .low: return "Low"
        case .medium: return "Med"
        case .high: return "High"
        case .urgent: return "Urgent"
        default: return "None"
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        default: return .gray
        }
    }
}
```

### Step 7: Create Task Creation View

```swift
struct CreateTaskView: View {
    @EnvironmentObject var viewModel: TaskManagerViewModel
    @Environment(\\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .medium
    @State private var selectedCategory: Category?
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        Text("Low").tag(TaskPriority.low)
                        Text("Medium").tag(TaskPriority.medium)
                        Text("High").tag(TaskPriority.high)
                        Text("Urgent").tag(TaskPriority.urgent)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(viewModel.categories, id: \\.id) { category in
                            Text(category.name).tag(category as Category?)
                        }
                    }
                }
                
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
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
                    Button("Create") {
                        createTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func createTask() {
        let request = CreateTaskRequest(
            title: title,
            description: description,
            priority: priority,
            dueDate: hasDueDate ? dueDate.toTimestamp() : nil,
            categoryId: selectedCategory?.id ?? ""
        )
        
        Task {
            do {
                try await viewModel.client.process(.createTask(request))
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    viewModel.error = error.localizedDescription
                }
            }
        }
    }
}
```

## Advanced Features

### Search and Filtering

```swift
extension TaskManagerViewModel {
    func searchTasks(query: String) {
        guard !query.isEmpty else {
            loadInitialData()
            return
        }
        
        Task {
            do {
                let request = SearchTasksRequest(
                    query: query,
                    limit: 50,
                    scope: .all
                )
                try await client.process(.searchTasks(request))
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func filterTasks(by category: Category?, priority: TaskPriority?) {
        Task {
            do {
                var request = GetTasksRequest(limit: 50)
                if let category = category {
                    request.categoryId = category.id
                }
                if let priority = priority {
                    request.priority = priority
                }
                try await client.process(.getTasks(request))
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
```

### Batch Operations

```swift
extension TaskManagerViewModel {
    func deleteCompletedTasks() {
        Task {
            let completedTasks = tasks.filter { $0.isCompleted }
            
            for task in completedTasks {
                do {
                    try await client.process(.deleteTask(.init(taskId: task.id)))
                } catch {
                    print("Failed to delete task \\(task.id): \\(error)")
                }
            }
        }
    }
    
    func markAllAsCompleted(in category: Category) {
        Task {
            let categoryTasks = tasks.filter { $0.categoryId == category.id && !$0.isCompleted }
            
            for task in categoryTasks {
                do {
                    try await client.process(.toggleTaskCompletion(.init(taskId: task.id)))
                } catch {
                    print("Failed to complete task \\(task.id): \\(error)")
                }
            }
        }
    }
}
```

## Testing

The generated code includes comprehensive tests. Here's how to add your own:

```swift
import XCTest
@testable import TaskManager

class TaskManagerTests: XCTestCase {
    var client: TaskManagerClient!
    
    override func setUp() {
        super.setUp()
        client = TaskManagerClient()
    }
    
    func testCreateTask() async throws {
        let request = CreateTaskRequest(
            title: "Test Task",
            description: "Test Description",
            priority: .medium
        )
        
        let action = TaskManagerAction.createTask(request)
        XCTAssertTrue(action.isValid)
        XCTAssertTrue(action.validationErrors.isEmpty)
        
        try await client.process(action)
        
        let state = await client.getCurrentState()
        XCTAssertFalse(state.tasks.isEmpty)
        XCTAssertEqual(state.tasks.first?.title, "Test Task")
    }
    
    func testValidation() {
        let invalidRequest = CreateTaskRequest(
            title: "", // Empty title should fail validation
            description: "Test",
            priority: .medium
        )
        
        let action = TaskManagerAction.createTask(invalidRequest)
        XCTAssertFalse(action.isValid)
        XCTAssertFalse(action.validationErrors.isEmpty)
    }
}
```

## Troubleshooting

### Common Issues

1. **Import Errors**: Ensure AxiomCore and AxiomArchitecture are properly added to your project
2. **Actor Isolation**: Always use `await` when calling client methods
3. **State Not Updating**: Make sure you're observing the state stream correctly
4. **Validation Failures**: Check action validation before processing

### Performance Tips

1. **Pagination**: Use pagination for large datasets
2. **Caching**: Leverage built-in caching strategies
3. **Background Processing**: Use Task.detached for heavy operations
4. **Memory Management**: Properly cancel observation tasks

### Getting Help

1. Check the generated documentation in the `Documentation/` folder
2. Run `axiom-client-generator doctor` for system diagnostics
3. Use `--validate` flag when generating to catch issues early
4. Enable verbose logging with `--verbose` flag

---

## 🎉 Congratulations!

You've successfully implemented a complete task management application using the Axiom Swift Client Generator. This example demonstrates all the key features and best practices for building robust, scalable iOS/macOS applications with the Axiom framework.

### Next Steps

- Explore the generated documentation for detailed API reference
- Try the user service example for authentication patterns
- Customize the proto schema for your specific needs
- Add your own business logic and UI enhancements

Happy coding! 🚀