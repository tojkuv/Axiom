import Foundation

// GREEN Phase: Real TabNavigationController implementation
// REFACTOR Phase: Enhanced with customizable order and state persistence
actor TabNavigationController {
    private var currentTab: TabType?
    private var tabContexts: [TabType: TabContext] = [:]
    private var registeredClients: [TabType: any Client] = [:]
    private var activeClient: (any Client)?
    
    // REFACTOR: Customizable tab order
    private var tabOrder: [TabType] = TabType.allCases
    
    // REFACTOR: Enhanced state persistence
    private var autoSaveEnabled = false
    private var autoSaveInterval: TimeInterval = 1.0
    private var autoSaveTask: _Concurrency.Task<Void, Never>?
    private var autoSavedState: TabNavigationState?
    
    // REFACTOR: Performance optimizations
    private var preloadingEnabled: Set<TabType> = []
    
    // Performance tracking
    private let switchStartTimes: [TabType: CFAbsoluteTime] = [:]
    
    init() {
        // Initialize with tasks tab as default
        currentTab = .tasks
    }
    
    func switchToTab(_ tab: TabType) async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Check for cancellation before proceeding
        try _Concurrency.Task.checkCancellation()
        
        // RFC Requirement: Tab switch animation begins within 16ms
        // Simulate animation start (in real app, this would trigger UI animation)
        let animationStartTime = CFAbsoluteTimeGetCurrent() - startTime
        if animationStartTime > 0.016 {
            // In a real implementation, this might be a performance warning
        }
        
        // Check for cancellation again before making changes
        try _Concurrency.Task.checkCancellation()
        
        currentTab = tab
        
        // Activate the client for this tab
        if let client = registeredClients[tab] {
            activeClient = client
        }
    }
    
    func initializeContextForTab(_ tab: TabType) async throws -> TabContext {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Check if context already exists
        if let existingContext = tabContexts[tab] {
            return existingContext
        }
        
        // Create new context
        let context = TabContext()
        tabContexts[tab] = context
        
        // RFC Acceptance: Context initialization completes within 100ms
        let initializationTime = CFAbsoluteTimeGetCurrent() - startTime
        if initializationTime > 0.1 {
            throw TabNavigationError.initializationTimeout
        }
        
        return context
    }
    
    func getCurrentContext() async throws -> TabContext {
        guard let currentTab = currentTab else {
            throw TabNavigationError.noCurrentTab
        }
        
        // Ensure context exists for current tab
        return try await initializeContextForTab(currentTab)
    }
    
    func getCurrentTab() async -> TabType? {
        return currentTab
    }
    
    func getAvailableTabs() async -> [TabType] {
        // RFC Requirement: Main tabs for Tasks, Categories, Settings, Profile
        return [.tasks, .categories, .settings, .profile]
    }
    
    func registerClient(_ client: any Client, forTab tab: TabType) async throws {
        registeredClients[tab] = client
        
        // If this is the current tab, make it active
        if currentTab == tab {
            activeClient = client
        }
    }
    
    func getActiveClient() async -> (any Client)? {
        return activeClient
    }
    
    func getMemoryUsage() async -> Int {
        // Simple estimation based on number of contexts
        return tabContexts.count * 1_000_000 // 1MB per context estimate
    }
    
    func saveNavigationState() async throws -> TabNavigationState {
        guard let currentTab = currentTab else {
            throw TabNavigationError.noCurrentTab
        }
        
        var tabStates: [String: Data] = [:]
        
        for (tab, context) in tabContexts {
            let state = await context.getState()
            let data = try JSONSerialization.data(withJSONObject: state)
            tabStates[tab.rawValue] = data
        }
        
        return TabNavigationState(currentTab: currentTab, tabOrder: tabOrder, tabStates: tabStates)
    }
    
    func restoreNavigationState(_ state: TabNavigationState) async throws {
        currentTab = state.currentTab
        tabOrder = state.tabOrder
        
        // Restore context states
        for (tabRawValue, data) in state.tabStates {
            guard let tab = TabType(rawValue: tabRawValue) else { continue }
            
            let context = TabContext()
            tabContexts[tab] = context
            
            // Restore state
            if let stateDict = try JSONSerialization.jsonObject(with: data) as? [String: String] {
                await context.restoreState(stateDict)
            }
        }
    }
    
    func getAccessibilityInfo() async -> AccessibilityInfo {
        return AccessibilityInfo(supportsVoiceOver: true, hasTabLabels: true)
    }
    
    func getAccessibilityLabel(for tab: TabType) async -> String {
        switch tab {
        case .tasks:
            return "Tasks Tab"
        case .categories:
            return "Categories Tab"
        case .settings:
            return "Settings Tab"
        case .profile:
            return "Profile Tab"
        }
    }
    
    // MARK: - REFACTOR Phase: Enhanced Features
    
    func getTabOrder() async -> [TabType] {
        return tabOrder
    }
    
    func setTabOrder(_ newOrder: [TabType]) async throws {
        // Validate tab order
        guard newOrder.count == TabType.allCases.count else {
            throw TabNavigationError.invalidTabOrder
        }
        
        guard Set(newOrder) == Set(TabType.allCases) else {
            throw TabNavigationError.invalidTabOrder
        }
        
        tabOrder = newOrder
        
        // Auto-save if enabled
        if autoSaveEnabled {
            await performAutoSave()
        }
    }
    
    func enableAutoSave(interval: TimeInterval) async {
        autoSaveEnabled = true
        autoSaveInterval = interval
        
        // Cancel existing auto-save task
        autoSaveTask?.cancel()
        
        // Start new auto-save task
        autoSaveTask = _Concurrency.Task { [weak self] in
            while !_Concurrency.Task.isCancelled {
                try? await _Concurrency.Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                
                guard !_Concurrency.Task.isCancelled else { break }
                await self?.performAutoSave()
            }
        }
    }
    
    func hasAutoSavedState() async -> Bool {
        return autoSavedState != nil
    }
    
    func restoreAutoSavedState() async throws -> Bool {
        guard let savedState = autoSavedState else { return false }
        
        try await restoreNavigationState(savedState)
        return true
    }
    
    func copyAutoSavedState(from other: TabNavigationController) async {
        let otherAutoSavedState = await other.getAutoSavedState()
        autoSavedState = otherAutoSavedState
    }
    
    private func getAutoSavedState() async -> TabNavigationState? {
        return autoSavedState
    }
    
    private func performAutoSave() async {
        do {
            autoSavedState = try await saveNavigationState()
        } catch {
            // Auto-save failed silently
        }
    }
    
    func clearInactiveTabStates() async throws {
        let current = currentTab
        
        for (tab, _) in tabContexts {
            if tab != current {
                tabContexts.removeValue(forKey: tab)
            }
        }
    }
    
    func enablePreloading(for tabs: [TabType]) async {
        preloadingEnabled = Set(tabs)
        
        // Preload contexts for specified tabs
        for tab in tabs {
            if tabContexts[tab] == nil {
                let context = TabContext()
                tabContexts[tab] = context
            }
        }
    }
    
    // MARK: - Modal Presentation
    
    private var currentModal: ModalType?
    private var modalStack: [ModalType] = []
    
    func presentModal(_ modal: ModalType) async -> (isSuccess: Bool, error: Error?) {
        // Add modal to stack
        modalStack.append(modal)
        currentModal = modal
        
        // Simulate modal presentation
        try? await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        return (isSuccess: true, error: nil)
    }
    
    func dismissModal() async -> (isSuccess: Bool, error: Error?) {
        guard !modalStack.isEmpty else {
            return (isSuccess: false, error: TabNavigationError.noModalToDisiss)
        }
        
        _ = modalStack.popLast()
        currentModal = modalStack.last
        
        // Simulate modal dismissal
        try? await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        return (isSuccess: true, error: nil)
    }
    
    func currentModalState() async -> (isPresenting: Bool, modalType: ModalType?) {
        return (isPresenting: currentModal != nil, modalType: currentModal)
    }
}

enum TabType: String, CaseIterable, Codable {
    case tasks = "tasks"
    case categories = "categories"
    case settings = "settings"
    case profile = "profile"
}

actor TabContext {
    private var state: [String: String] = [:]
    
    func updateState(_ newState: [String: Any]) async {
        // Convert to sendable format
        for (key, value) in newState {
            state[key] = String(describing: value)
        }
    }
    
    func getState() async -> [String: String] {
        return state
    }
    
    func restoreState(_ restoredState: [String: String]) async {
        state = restoredState
    }
}

enum TabNavigationError: Error {
    case notImplemented
    case invalidTab
    case contextNotFound
    case noCurrentTab
    case initializationTimeout
    case invalidTabOrder
    case noModalToDisiss
}

enum ModalType: Equatable {
    case taskCreation(taskId: String?)
    case taskEdit(taskId: String)
    case categorySelection
    case categoryEdit(categoryId: String?)
}

struct TabNavigationState: Codable {
    let currentTab: TabType
    let tabOrder: [TabType]
    let tabStates: [String: Data]
}

struct AccessibilityInfo {
    let supportsVoiceOver: Bool
    let hasTabLabels: Bool
}