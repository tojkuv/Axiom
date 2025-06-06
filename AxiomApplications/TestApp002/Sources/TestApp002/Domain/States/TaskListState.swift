import Foundation

// RED Phase: TaskListState stub
struct TaskListState: State, Hashable {
    let tasks: [Task]
    let categories: [Category]
    let searchQuery: String
    let sortCriteria: SortCriteria
    let selectedCategoryId: String?
    
    // Sharing properties
    let pendingShares: [PendingShare]
    let collaborationInfo: [CollaborationInfo]
    
    // Performance optimization: cache computed values for fast equality checks
    private let taskCount: Int
    private let lastModified: Date?
    
    // Search optimization: pre-computed search index for large datasets
    private let searchIndex: SearchIndex?
    
    // Large dataset support: lazy loading and pagination
    let isLazyLoadingEnabled: Bool
    let pageSize: Int
    let currentPageIndex: Int
    let visibleTaskRange: Range<Int>?
    
    init(
        tasks: [Task] = [],
        categories: [Category] = [],
        searchQuery: String = "",
        sortCriteria: SortCriteria = .createdDate,
        selectedCategoryId: String? = nil,
        pendingShares: [PendingShare] = [],
        collaborationInfo: [CollaborationInfo] = [],
        pageSize: Int = 1000,
        currentPageIndex: Int = 0,
        visibleTaskRange: Range<Int>? = nil
    ) {
        self.tasks = tasks
        self.categories = categories
        self.searchQuery = searchQuery
        self.sortCriteria = sortCriteria
        self.selectedCategoryId = selectedCategoryId
        self.pendingShares = pendingShares
        self.collaborationInfo = collaborationInfo
        self.pageSize = pageSize
        self.currentPageIndex = currentPageIndex
        self.visibleTaskRange = visibleTaskRange
        
        // Enable lazy loading for large datasets
        self.isLazyLoadingEnabled = tasks.count > 1000
        
        // Cache computed values for performance
        self.taskCount = tasks.count
        self.lastModified = tasks.map(\.updatedAt).max()
        
        // Build search index for large datasets (>1000 tasks)
        if tasks.count > 1000 {
            self.searchIndex = SearchIndex(tasks: tasks)
        } else {
            self.searchIndex = nil
        }
    }
    
    // MARK: - Computed Properties
    
    /// Tasks visible in the current viewport (for lazy loading)
    var visibleTasks: [Task]? {
        guard isLazyLoadingEnabled else { return nil }
        
        if let range = visibleTaskRange {
            let endIndex = min(range.upperBound, tasks.count)
            let safeRange = range.lowerBound..<endIndex
            return Array(tasks[safeRange])
        }
        
        // Default to current page
        let startIndex = currentPageIndex * pageSize
        let endIndex = min(startIndex + pageSize, tasks.count)
        guard startIndex < tasks.count else { return [] }
        
        return Array(tasks[startIndex..<endIndex])
    }
    
    /// Current page data for pagination
    var currentPage: TaskPage? {
        guard isLazyLoadingEnabled else { return nil }
        
        let startIndex = currentPageIndex * pageSize
        let endIndex = min(startIndex + pageSize, tasks.count)
        guard startIndex < tasks.count else { return nil }
        
        let pageTasks = Array(tasks[startIndex..<endIndex])
        return TaskPage(
            tasks: pageTasks,
            pageNumber: currentPageIndex,
            pageSize: pageSize,
            totalTasks: tasks.count
        )
    }
    
    /// Virtual scroll state for rendering optimization
    var virtualScrollState: VirtualScrollState? {
        guard isLazyLoadingEnabled else { return nil }
        
        return VirtualScrollState(
            totalItems: tasks.count,
            renderedItems: visibleTasks ?? [],
            visibleRange: visibleTaskRange ?? (0..<min(pageSize, tasks.count))
        )
    }
    
    /// Tasks filtered by search query and category (case-insensitive search in title and description)
    /// Note: Tasks are already sorted in the main tasks array, so filtered results maintain that order
    var filteredTasks: [Task] {
        var filtered = tasks
        
        // Apply category filter first
        if let categoryId = selectedCategoryId {
            filtered = filtered.filter { $0.categoryId == categoryId }
        }
        
        // Then apply search filter
        if !searchQuery.isEmpty {
            if let index = searchIndex {
                // Use indexed search for large datasets
                let matchingIds = index.search(query: searchQuery)
                let idSet = Set(matchingIds)
                filtered = filtered.filter { idSet.contains($0.id) }
            } else {
                // Use linear search for small datasets
                let lowercasedQuery = searchQuery.lowercased()
                filtered = filtered.filter { task in
                    task.title.lowercased().contains(lowercasedQuery) ||
                    task.description.lowercased().contains(lowercasedQuery)
                }
            }
        }
        
        // Tasks maintain their sort order from the main tasks array
        return filtered
    }
    
    /// Tasks that are shared with other users (owned by current user)
    var sharedTasks: [Task] {
        return tasks.filter { !$0.sharedWith.isEmpty }
    }
    
    /// Tasks that are shared with the current user (owned by others)
    var tasksSharedWithMe: [Task] {
        return tasks.filter { $0.sharedBy != nil }
    }
    
    /// Tasks that have active collaborators
    var collaborativeTasks: [Task] {
        let collaborativeTaskIds = Set(collaborationInfo.map { $0.taskId })
        return tasks.filter { collaborativeTaskIds.contains($0.id) }
    }
    
    /// Tasks with active editing sessions
    var activelyEditedTasks: [Task] {
        let activeTaskIds = Set(collaborationInfo.compactMap { info in
            info.activeCollaborators.contains { $0.isCurrentlyEditing } ? info.taskId : nil
        })
        return tasks.filter { activeTaskIds.contains($0.id) }
    }
    
    /// Get collaboration info for a specific task
    func collaborationInfo(for taskId: String) -> CollaborationInfo? {
        return collaborationInfo.first { $0.taskId == taskId }
    }
    
    /// Tasks that are overdue (past their due date)
    var overdueTasks: [Task] {
        let now = Date()
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < now && !task.isCompleted
        }
    }
}

// MARK: - Custom Equatable Implementation
// RFC Requirement: Custom Equatable that compares task count and last modification timestamp
// instead of full array comparison for performance with large datasets
extension TaskListState: Equatable {
    static func == (lhs: TaskListState, rhs: TaskListState) -> Bool {
        // Fast path: compare cached values first
        guard lhs.taskCount == rhs.taskCount,
              lhs.lastModified == rhs.lastModified,
              lhs.searchQuery == rhs.searchQuery,
              lhs.sortCriteria == rhs.sortCriteria,
              lhs.selectedCategoryId == rhs.selectedCategoryId,
              lhs.categories == rhs.categories,
              lhs.pendingShares == rhs.pendingShares,
              lhs.collaborationInfo == rhs.collaborationInfo,
              lhs.searchIndex == rhs.searchIndex,
              lhs.pageSize == rhs.pageSize,
              lhs.currentPageIndex == rhs.currentPageIndex,
              lhs.visibleTaskRange == rhs.visibleTaskRange else {
            return false
        }
        
        // If cached values match, states are considered equal
        // This avoids expensive array comparison for large task lists
        return true
    }
}

struct Category: Equatable, Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let color: String
}

// MARK: - Search Index for Performance Optimization

/// Pre-computed search index for efficient text searching in large datasets
struct SearchIndex: Hashable {
    // Map of lowercased tokens to task IDs that contain them
    private let tokenToTaskIds: [String: Set<String>]
    
    init(tasks: [Task]) {
        var index: [String: Set<String>] = [:]
        
        for task in tasks {
            // Extract and normalize tokens from title and description
            let titleTokens = Self.tokenize(task.title)
            let descriptionTokens = Self.tokenize(task.description)
            let allTokens = titleTokens.union(descriptionTokens)
            
            // Add task ID to each token's set
            for token in allTokens {
                index[token, default: []].insert(task.id)
            }
        }
        
        self.tokenToTaskIds = index
    }
    
    /// Search for tasks containing the query
    func search(query: String) -> [String] {
        let queryTokens = Self.tokenize(query)
        guard !queryTokens.isEmpty else { return [] }
        
        // Find task IDs that contain all query tokens
        var matchingIds: Set<String>?
        
        for token in queryTokens {
            // Check if token exists as prefix in any indexed token
            let matchingTaskIds = tokenToTaskIds
                .filter { $0.key.hasPrefix(token) }
                .flatMap { $0.value }
            
            let tokenMatches = Set(matchingTaskIds)
            
            if let existing = matchingIds {
                // Intersect with previous matches (AND operation)
                matchingIds = existing.intersection(tokenMatches)
            } else {
                matchingIds = tokenMatches
            }
            
            // Early exit if no matches
            if matchingIds?.isEmpty ?? true {
                return []
            }
        }
        
        return Array(matchingIds ?? [])
    }
    
    /// Tokenize text into lowercase words for indexing
    private static func tokenize(_ text: String) -> Set<String> {
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .flatMap { $0.components(separatedBy: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        return Set(words)
    }
}

// MARK: - Supporting Types for Large Dataset Optimization

/// Represents a page of tasks for pagination
struct TaskPage: Equatable {
    let tasks: [Task]
    let pageNumber: Int
    let pageSize: Int
    let totalTasks: Int
    
    var hasNextPage: Bool {
        return (pageNumber + 1) * pageSize < totalTasks
    }
    
    var hasPreviousPage: Bool {
        return pageNumber > 0
    }
}

/// Represents the state of virtual scrolling for rendering optimization
struct VirtualScrollState: Equatable {
    let totalItems: Int
    let renderedItems: [Task]
    let visibleRange: Range<Int>
    
    var startIndex: Int {
        return visibleRange.lowerBound
    }
    
    var endIndex: Int {
        return visibleRange.upperBound
    }
    
    var itemCount: Int {
        return visibleRange.count
    }
}