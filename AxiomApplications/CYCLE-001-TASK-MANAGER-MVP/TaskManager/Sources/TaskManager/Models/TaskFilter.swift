import Foundation
import Axiom

/// Filter state for tasks
struct TaskFilter: State {
    let searchQuery: String
    let selectedCategories: Set<UUID>
    let showCompleted: Bool
    let sortOrder: SortOrder
    let sortDirection: SortDirection
    let primarySortOrder: SortOrder?
    let secondarySortOrder: SortOrder?
    let dueDateFilter: DueDateFilter
    
    init(
        searchQuery: String = "",
        selectedCategories: Set<UUID> = [],
        showCompleted: Bool = true,
        sortOrder: SortOrder = .dateCreated,
        sortDirection: SortDirection = .descending,
        primarySortOrder: SortOrder? = nil,
        secondarySortOrder: SortOrder? = nil,
        dueDateFilter: DueDateFilter = .all
    ) {
        self.searchQuery = searchQuery
        self.selectedCategories = selectedCategories
        self.showCompleted = showCompleted
        self.sortOrder = sortOrder
        self.sortDirection = sortDirection
        self.primarySortOrder = primarySortOrder
        self.secondarySortOrder = secondarySortOrder
        self.dueDateFilter = dueDateFilter
    }
}

// MARK: - Default Filter

extension TaskFilter {
    static var `default`: TaskFilter {
        TaskFilter()
    }
}

// MARK: - Computed Properties

extension TaskFilter {
    /// Returns true if no filters are active
    var isShowingAll: Bool {
        searchQuery.isEmpty && 
        selectedCategories.isEmpty && 
        showCompleted &&
        dueDateFilter == .all
    }
}

// MARK: - Helper Methods

extension TaskFilter {
    /// Helper for creating modified copies
    func with(
        searchQuery: String? = nil,
        selectedCategories: Set<UUID>? = nil,
        showCompleted: Bool? = nil,
        sortOrder: SortOrder? = nil,
        sortDirection: SortDirection? = nil,
        primarySortOrder: SortOrder? = nil,
        secondarySortOrder: SortOrder? = nil,
        dueDateFilter: DueDateFilter? = nil
    ) -> TaskFilter {
        TaskFilter(
            searchQuery: searchQuery ?? self.searchQuery,
            selectedCategories: selectedCategories ?? self.selectedCategories,
            showCompleted: showCompleted ?? self.showCompleted,
            sortOrder: sortOrder ?? self.sortOrder,
            sortDirection: sortDirection ?? self.sortDirection,
            primarySortOrder: primarySortOrder ?? self.primarySortOrder,
            secondarySortOrder: secondarySortOrder ?? self.secondarySortOrder,
            dueDateFilter: dueDateFilter ?? self.dueDateFilter
        )
    }
}

// MARK: - Sort Order

enum SortOrder: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case dateCreated = "date_created"
    case dateModified = "date_modified"
    case alphabetical = "alphabetical"
    case priority = "priority"
    case dueDate = "due_date"
    
    var displayName: String {
        switch self {
        case .dateCreated: return "Date Created"
        case .dateModified: return "Date Modified"
        case .alphabetical: return "Alphabetical"
        case .priority: return "Priority"
        case .dueDate: return "Due Date"
        }
    }
}

// MARK: - Sort Direction

public enum SortDirection: String, State, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case ascending = "ascending"
    case descending = "descending"
    
    var displayName: String {
        switch self {
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        }
    }
    
    var icon: String {
        switch self {
        case .ascending: return "arrow.up"
        case .descending: return "arrow.down"
        }
    }
}

// MARK: - Due Date Filter

public enum DueDateFilter: String, State, CaseIterable, Codable {
    case all = "all"
    case overdue = "overdue"
    case today = "today"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case noDueDate = "no_due_date"
    
    var displayName: String {
        switch self {
        case .all: return "All Tasks"
        case .overdue: return "Overdue"
        case .today: return "Due Today"
        case .thisWeek: return "Due This Week"
        case .thisMonth: return "Due This Month"
        case .noDueDate: return "No Due Date"
        }
    }
}

// MARK: - Sort Criteria

struct SortCriteria: State {
    let primary: SortOrder
    let secondary: SortOrder?
    let direction: SortDirection
    
    init(
        primary: SortOrder,
        secondary: SortOrder? = nil,
        direction: SortDirection = .descending
    ) {
        self.primary = primary
        self.secondary = secondary
        self.direction = direction
    }
    
    /// Helper for creating modified copies
    func with(
        primary: SortOrder? = nil,
        secondary: SortOrder? = nil,
        direction: SortDirection? = nil
    ) -> SortCriteria {
        SortCriteria(
            primary: primary ?? self.primary,
            secondary: secondary ?? self.secondary,
            direction: direction ?? self.direction
        )
    }
}

// MARK: - Codable

extension TaskFilter: Codable {
    // Automatic Codable synthesis works with State protocol
}

extension SortCriteria: Codable {
    // Automatic Codable synthesis works with State protocol
}