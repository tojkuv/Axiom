import SwiftUI
import Axiom
import Combine

/// Context for managing search functionality with debouncing
@MainActor
final class SearchContext: AutoSyncContext<TaskClient> {
    // Published state that mirrors client state
    @Published private(set) var state: TaskState = TaskState()
    
    // Search-specific state
    @Published var searchQuery: String = ""
    @Published var isSearching: Bool = false
    @Published var searchResults: [TaskItem] = []
    
    private let debouncer = AsyncDebouncer(delay: 0.3)
    private var searchCancellable: AnyCancellable?
    
    var resultCount: Int {
        searchResults.count
    }
    
    var hasNoResults: Bool {
        isSearching && searchResults.isEmpty
    }
    
    override init(client: TaskClient) {
        super.init(client: client)
        
        // Set up search query observation with debouncing
        searchCancellable = $searchQuery
            .sink { [weak self] query in
                Task { @MainActor in
                    await self?.performSearch(query: query)
                }
            }
    }
    
    // Override to sync initial state
    override func syncInitialState() async {
        self.state = await client.state
        updateResults()
    }
    
    // Override to handle state updates from the client
    override func handleStateUpdate(_ state: TaskState) async {
        self.state = state
        // Update search query from state to stay in sync
        if self.searchQuery != state.searchQuery {
            self.searchQuery = state.searchQuery
        }
        updateResults()
        await super.handleStateUpdate(state)
    }
    
    private func performSearch(query: String) async {
        _ = await debouncer.debounce { @MainActor in
            await self.client.send(.setSearchQuery(query))
            self.isSearching = !query.isEmpty
        }
    }
    
    private func updateResults() {
        searchResults = state.filteredTasks
    }
    
    func clearSearch() {
        searchQuery = ""
        isSearching = false
        Task {
            await client.send(.setSearchQuery(""))
        }
    }
    
    /// Wait for any pending search operation to complete (for testing)
    func waitForSearchCompletion() async {
        await debouncer.waitForPendingOperation()
    }
}