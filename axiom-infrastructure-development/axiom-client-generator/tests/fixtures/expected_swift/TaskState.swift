import Foundation
import AxiomCore
import TaskManager

public struct TaskState: AxiomState {
    public let tasks: [Task]
    public let isLoading: Bool
    public let error: Error?
    public let lastUpdated: Date
    public let pageToken: String?
    public let totalCount: Int
    public let searchResults: [Task]
    public let searchSuggestions: [String]
    
    public init(
        tasks: [Task] = [],
        isLoading: Bool = false,
        error: Error? = nil,
        lastUpdated: Date = Date(),
        pageToken: String? = nil,
        totalCount: Int = 0,
        searchResults: [Task] = [],
        searchSuggestions: [String] = []
    ) {
        self.tasks = tasks
        self.isLoading = isLoading
        self.error = error
        self.lastUpdated = lastUpdated
        self.pageToken = pageToken
        self.totalCount = totalCount
        self.searchResults = searchResults
        self.searchSuggestions = searchSuggestions
    }
    
    // MARK: - Task Management
    
    public func addingTask(_ task: Task) -> TaskState {
        var updatedTasks = tasks
        updatedTasks.append(task)
        
        return TaskState(
            tasks: updatedTasks,
            isLoading: false,
            error: nil,
            lastUpdated: Date(),
            pageToken: pageToken,
            totalCount: totalCount + 1,
            searchResults: searchResults,
            searchSuggestions: searchSuggestions
        )
    }
    
    public func replacingTask(_ task: Task) -> TaskState {
        let updatedTasks = tasks.map { existingTask in
            existingTask.id == task.id ? task : existingTask
        }
        
        return TaskState(
            tasks: updatedTasks,
            isLoading: false,
            error: nil,
            lastUpdated: Date(),
            pageToken: pageToken,
            totalCount: totalCount,
            searchResults: searchResults,
            searchSuggestions: searchSuggestions
        )
    }
    
    public func updatingTask(_ updatedTask: Task) -> TaskState {
        let updatedTasks = tasks.map { task in
            task.id == updatedTask.id ? updatedTask : task
        }
        
        return TaskState(
            tasks: updatedTasks,
            isLoading: false,
            error: nil,
            lastUpdated: Date(),
            pageToken: pageToken,
            totalCount: totalCount,
            searchResults: searchResults,
            searchSuggestions: searchSuggestions
        )
    }
    
    public func removingTask(withId taskId: String) -> TaskState {
        let filteredTasks = tasks.filter { $0.id != taskId }
        
        return TaskState(
            tasks: filteredTasks,
            isLoading: false,
            error: nil,
            lastUpdated: Date(),
            pageToken: pageToken,
            totalCount: max(0, totalCount - 1),
            searchResults: searchResults.filter { $0.id != taskId },
            searchSuggestions: searchSuggestions
        )
    }
    
    public func withTasks(_ newTasks: [Task]) -> TaskState {
        TaskState(
            tasks: newTasks,
            isLoading: false,
            error: nil,
            lastUpdated: Date(),
            pageToken: pageToken,
            totalCount: newTasks.count,
            searchResults: searchResults,
            searchSuggestions: searchSuggestions
        )
    }
    
    // MARK: - State Management
    
    public func withLoading(_ loading: Bool) -> TaskState {
        TaskState(
            tasks: tasks,
            isLoading: loading,
            error: error,
            lastUpdated: lastUpdated,
            pageToken: pageToken,
            totalCount: totalCount,
            searchResults: searchResults,
            searchSuggestions: searchSuggestions
        )
    }
    
    public func withError(_ error: Error?) -> TaskState {
        TaskState(
            tasks: tasks,
            isLoading: false,
            error: error,
            lastUpdated: Date(),
            pageToken: pageToken,
            totalCount: totalCount,
            searchResults: searchResults,
            searchSuggestions: searchSuggestions
        )
    }
    
    public func withPageToken(_ token: String?) -> TaskState {
        TaskState(
            tasks: tasks,
            isLoading: isLoading,
            error: error,
            lastUpdated: lastUpdated,
            pageToken: token,
            totalCount: totalCount,
            searchResults: searchResults,
            searchSuggestions: searchSuggestions
        )
    }
    
    public func withTotalCount(_ count: Int) -> TaskState {
        TaskState(
            tasks: tasks,
            isLoading: isLoading,
            error: error,
            lastUpdated: lastUpdated,
            pageToken: pageToken,
            totalCount: count,
            searchResults: searchResults,
            searchSuggestions: searchSuggestions
        )
    }
    
    public func withSearchResults(_ results: [Task]) -> TaskState {
        TaskState(
            tasks: tasks,
            isLoading: isLoading,
            error: error,
            lastUpdated: lastUpdated,
            pageToken: pageToken,
            totalCount: totalCount,
            searchResults: results,
            searchSuggestions: searchSuggestions
        )
    }
    
    public func withSearchSuggestions(_ suggestions: [String]) -> TaskState {
        TaskState(
            tasks: tasks,
            isLoading: isLoading,
            error: error,
            lastUpdated: lastUpdated,
            pageToken: pageToken,
            totalCount: totalCount,
            searchResults: searchResults,
            searchSuggestions: suggestions
        )
    }
    
    // MARK: - Computed Properties
    
    public var completedTasks: [Task] {
        tasks.filter { $0.isCompleted }
    }
    
    public var pendingTasks: [Task] {
        tasks.filter { !$0.isCompleted }
    }
    
    public var taskCount: Int {
        tasks.count
    }
    
    public var completedTaskCount: Int {
        completedTasks.count
    }
    
    public var pendingTaskCount: Int {
        pendingTasks.count
    }
    
    public var hasError: Bool {
        error != nil
    }
    
    public var hasMorePages: Bool {
        pageToken != nil && !pageToken!.isEmpty
    }
    
    public var highPriorityTasks: [Task] {
        tasks.filter { $0.priority == .priorityHigh || $0.priority == .priorityCritical }
    }
    
    public var overdueTasks: [Task] {
        let now = Date()
        return tasks.filter { task in
            if let dueDate = task.dueDate?.date {
                return dueDate < now && !task.isCompleted
            }
            return false
        }
    }
    
    public var tasksByCategory: [String: [Task]] {
        Dictionary(grouping: tasks) { $0.categoryId }
    }
    
    public var allTags: Set<String> {
        Set(tasks.flatMap { $0.tags })
    }
}

// MARK: - Equatable & Hashable
extension TaskState: Equatable {
    public static func == (lhs: TaskState, rhs: TaskState) -> Bool {
        return lhs.tasks == rhs.tasks &&
               lhs.isLoading == rhs.isLoading &&
               lhs.hasError == rhs.hasError &&
               lhs.pageToken == rhs.pageToken &&
               lhs.totalCount == rhs.totalCount &&
               lhs.searchResults == rhs.searchResults &&
               lhs.searchSuggestions == rhs.searchSuggestions
    }
}

extension TaskState: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(tasks)
        hasher.combine(isLoading)
        hasher.combine(hasError)
        hasher.combine(pageToken)
        hasher.combine(totalCount)
        hasher.combine(searchResults)
        hasher.combine(searchSuggestions)
    }
}