import SwiftUI
import Axiom

/// Main task list view
struct TaskListView: View {
    @ObservedObject var context: TaskListContext
    
    var body: some View {
        Group {
            if context.state.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if context.state.tasks.isEmpty {
                emptyStateView
            } else {
                taskListView
            }
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: context.showCreateTask) {
                    Image(systemName: "plus")
                }
            }
        }
        // REFACTOR: Using new contextLifecycle modifier
        .contextLifecycle(context)
        // REFACTOR: Using new errorBanner modifier
        .errorBanner(error: .constant(context.state.error)) {
            context.clearError()
        }
        // REFACTOR: Using deleteConfirmation pattern
        .deleteConfirmation(
            isPresented: $context.showDeleteConfirmation,
            item: context.taskToDelete,
            itemName: { $0.title },
            confirmAction: context.confirmDelete,
            cancelAction: context.cancelDelete
        )
    }
    
    private var taskListView: some View {
        List {
            ForEach(context.state.tasks, id: \.id) { task in
                TaskRowView(
                    task: task,
                    onTap: { context.showTaskDetail(id: task.id) },
                    onToggleComplete: { context.toggleTaskCompletion(id: task.id) },
                    onDelete: { context.requestDelete(task: task) }
                )
                .opacity(context.deletingTaskIds.contains(task.id) ? 0.5 : 1.0)
                .disabled(context.deletingTaskIds.contains(task.id))
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let task = context.state.tasks[index]
                    context.requestDelete(task: task)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        // REFACTOR: Using reusable EmptyStateView
        EmptyStateView(
            icon: "checklist",
            title: "No Tasks",
            message: "Tap the + button to create your first task",
            actionTitle: "Create Task",
            action: context.showCreateTask
        )
    }
}

// MARK: - Previews

struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Empty state
            NavigationView {
                TaskListView(context: makePreviewContext(tasks: []))
            }
            .previewDisplayName("Empty State")
            
            // With tasks
            NavigationView {
                TaskListView(context: makePreviewContext(tasks: [
                    TaskItem(title: "Buy groceries", isCompleted: false),
                    TaskItem(title: "Call mom", isCompleted: true),
                    TaskItem(title: "Finish project", description: "Due by Friday", isCompleted: false)
                ]))
            }
            .previewDisplayName("With Tasks")
            
            // Loading state
            NavigationView {
                TaskListView(context: makePreviewContext(isLoading: true))
            }
            .previewDisplayName("Loading")
        }
    }
    
    @MainActor
    static func makePreviewContext(
        tasks: [TaskItem] = [],
        isLoading: Bool = false
    ) -> TaskListContext {
        let client = TaskClient()
        return TaskListContext(client: client)
    }
}