import Foundation
import SwiftUI
import Axiom

/// Context for managing task filtering UI
@MainActor
final class TaskFilterContext: ClientObservingContext<TaskClient> {
    // Published filter state
    @Published var searchQuery: String = ""
    @Published var selectedCategories: Set<UUID> = []
    @Published var showCompleted: Bool = true
    @Published var sortOrder: SortOrder = .dateCreated
    
    // Available categories from state
    @Published private(set) var availableCategories: [Category] = []
    
    // Debounce timer for search
    private var searchDebounceTask: Task<Void, Never>?
    
    override func handleStateUpdate(_ state: TaskState) async {
        // Update available categories
        self.availableCategories = state.categories
        
        // Sync filter state
        if let filter = state.filter {
            self.searchQuery = filter.searchQuery
            self.selectedCategories = filter.selectedCategories
            self.showCompleted = filter.showCompleted
            self.sortOrder = filter.sortOrder
        }
        
        await super.handleStateUpdate(state)
    }
    
    // MARK: - Actions
    
    func updateSearchQuery(_ query: String) {
        searchQuery = query
        
        // Cancel previous debounce
        searchDebounceTask?.cancel()
        
        // Debounce search updates
        searchDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            
            guard !Task.isCancelled else { return }
            
            await client.send(.setSearchQuery(query))
        }
    }
    
    func toggleCategory(_ categoryId: UUID) {
        if selectedCategories.contains(categoryId) {
            selectedCategories.remove(categoryId)
        } else {
            selectedCategories.insert(categoryId)
        }
        
        Task {
            await client.send(.toggleCategoryFilter(categoryId))
        }
    }
    
    func isCategorySelected(_ categoryId: UUID) -> Bool {
        selectedCategories.contains(categoryId)
    }
    
    func updateSortOrder(_ order: SortOrder) {
        sortOrder = order
        
        Task {
            await client.send(.setSortOrder(order))
        }
    }
    
    func updateShowCompleted(_ show: Bool) {
        showCompleted = show
        
        Task {
            await client.send(.setShowCompleted(show))
        }
    }
    
    func clearAllFilters() {
        searchQuery = ""
        selectedCategories = []
        showCompleted = true
        sortOrder = .dateCreated
        
        searchDebounceTask?.cancel()
        
        Task {
            await client.send(.clearFilters)
        }
    }
    
    // MARK: - Computed Properties
    
    var filterSummary: String {
        var parts: [String] = []
        
        if !searchQuery.isEmpty {
            parts.append("'\(searchQuery)'")
        }
        
        if !selectedCategories.isEmpty {
            let categoryNames = availableCategories
                .filter { selectedCategories.contains($0.id) }
                .map { $0.name }
            if !categoryNames.isEmpty {
                parts.append("in \(categoryNames.joined(separator: ", "))")
            }
        }
        
        if !showCompleted {
            parts.append("active only")
        }
        
        return parts.isEmpty ? "All tasks" : parts.joined(separator: ", ")
    }
    
    var hasActiveFilters: Bool {
        !searchQuery.isEmpty || !selectedCategories.isEmpty || !showCompleted
    }
}