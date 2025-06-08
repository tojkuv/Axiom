import Foundation
import SwiftUI
import Axiom

/// Context for managing task sorting UI
@MainActor
final class TaskSortContext: ClientObservingContext<TaskClient> {
    // Published sort state
    @Published var currentSortOrder: SortOrder = .dateCreated
    @Published var currentSortDirection: SortDirection = .descending
    @Published var isMultiCriteriaEnabled: Bool = false
    @Published var primarySortOrder: SortOrder = .priority
    @Published var secondarySortOrder: SortOrder = .dateCreated
    
    // Animation state
    @Published var isAnimating: Bool = false
    
    // Validation state
    @Published var hasValidationError: Bool = false
    @Published var validationMessage: String = ""
    
    // Performance feedback
    @Published var isShowingProgressIndicator: Bool = false
    @Published var lastSortDuration: TimeInterval = 0
    @Published var performanceSummary: String = ""
    
    // Available options
    var availableSortOrders: [SortOrder] {
        SortOrder.allCases
    }
    
    var availableSortPresets: [SortPreset] {
        SortPreset.defaultPresets
    }
    
    @Published private(set) var taskCount: Int = 0
    
    // Track if we're applying a local change to avoid state sync conflicts
    private var isApplyingLocalChange = false
    
    var estimatedSortTime: TimeInterval {
        // Estimate based on task count and sort complexity
        let baseTime = Double(taskCount) / 10000.0 // ~1ms per 10k tasks
        let complexityMultiplier = isMultiCriteriaEnabled ? 1.5 : 1.0
        return baseTime * complexityMultiplier
    }
    
    override func handleStateUpdate(_ state: TaskState) async {
        // Update task count for performance estimation
        self.taskCount = state.tasks.count
        
        // Only sync with filter state if we're not applying a local change
        if !isApplyingLocalChange, let filter = state.filter {
            self.currentSortOrder = filter.sortOrder
            self.currentSortDirection = filter.sortDirection
            
            // Check if multi-criteria is enabled
            if let primary = filter.primarySortOrder {
                self.isMultiCriteriaEnabled = true
                self.primarySortOrder = primary
                self.secondarySortOrder = filter.secondarySortOrder ?? .dateCreated
            } else {
                self.isMultiCriteriaEnabled = false
            }
        }
        
        await super.handleStateUpdate(state)
    }
    
    // MARK: - Sort Actions
    
    func selectSortOrder(_ order: SortOrder) {
        let startTime = Date()
        
        // Show progress indicator if needed
        showProgressIndicatorIfNeeded()
        
        isApplyingLocalChange = true
        currentSortOrder = order
        clearValidationError()
        
        Task {
            await client.send(.setSortOrder(order))
            
            // Update performance feedback
            let duration = Date().timeIntervalSince(startTime)
            updatePerformanceFeedback(duration: duration)
            
            // Allow state sync after a delay
            try? await Task.sleep(nanoseconds: 100_000_000)
            isApplyingLocalChange = false
        }
    }
    
    func selectSortOrderWithAnimation(_ order: SortOrder) {
        startAnimation()
        selectSortOrder(order)
        
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms animation
            stopAnimation()
        }
    }
    
    func toggleSortDirection() {
        isApplyingLocalChange = true
        let newDirection: SortDirection = currentSortDirection == .ascending ? .descending : .ascending
        currentSortDirection = newDirection
        
        Task {
            await client.send(.setSortDirection(newDirection))
            
            // Allow state sync after a delay
            try? await Task.sleep(nanoseconds: 100_000_000)
            isApplyingLocalChange = false
        }
    }
    
    // MARK: - Multi-Criteria Sorting
    
    func enableMultiCriteriaSorting() {
        isApplyingLocalChange = true
        isMultiCriteriaEnabled = true
        validateMultiCriteria()
        
        Task {
            await client.send(.setSortCriteria(
                primarySortOrder,
                secondary: secondarySortOrder,
                direction: currentSortDirection
            ))
            
            // Allow state sync after a delay
            try? await Task.sleep(nanoseconds: 100_000_000)
            isApplyingLocalChange = false
        }
    }
    
    func disableMultiCriteriaSorting() {
        isApplyingLocalChange = true
        isMultiCriteriaEnabled = false
        clearValidationError()
        
        Task {
            await client.send(.setSortOrder(currentSortOrder))
            
            // Allow state sync after a delay
            try? await Task.sleep(nanoseconds: 100_000_000)
            isApplyingLocalChange = false
        }
    }
    
    func setPrimarySortOrder(_ order: SortOrder) {
        primarySortOrder = order
        validateMultiCriteria()
        
        if isMultiCriteriaEnabled {
            Task {
                await client.send(.setSortCriteria(
                    order,
                    secondary: secondarySortOrder,
                    direction: currentSortDirection
                ))
            }
        }
    }
    
    func setSecondarySortOrder(_ order: SortOrder) {
        secondarySortOrder = order
        validateMultiCriteria()
        
        if isMultiCriteriaEnabled {
            Task {
                await client.send(.setSortCriteria(
                    primarySortOrder,
                    secondary: order,
                    direction: currentSortDirection
                ))
            }
        }
    }
    
    // MARK: - Sort Presets
    
    func applySortPreset(_ preset: SortPreset) {
        isApplyingLocalChange = true
        currentSortOrder = preset.sortOrder
        currentSortDirection = preset.direction
        
        if let secondary = preset.secondarySortOrder {
            isMultiCriteriaEnabled = true
            primarySortOrder = preset.sortOrder
            secondarySortOrder = secondary
            
            Task {
                await client.send(.setSortCriteria(
                    preset.sortOrder,
                    secondary: secondary,
                    direction: preset.direction
                ))
                
                // Allow state sync after a delay
                try? await Task.sleep(nanoseconds: 200_000_000)
                isApplyingLocalChange = false
            }
        } else {
            isMultiCriteriaEnabled = false
            
            Task {
                await client.send(.setSortOrder(preset.sortOrder))
                await client.send(.setSortDirection(preset.direction))
                
                // Allow state sync after a delay
                try? await Task.sleep(nanoseconds: 200_000_000)
                isApplyingLocalChange = false
            }
        }
    }
    
    // MARK: - Validation
    
    private func validateMultiCriteria() {
        if primarySortOrder == secondarySortOrder {
            hasValidationError = true
            validationMessage = "Primary and secondary sort criteria cannot be the same"
            
            // Auto-correct by changing secondary
            if primarySortOrder != .dateCreated {
                secondarySortOrder = .dateCreated
            } else {
                secondarySortOrder = .alphabetical
            }
        } else {
            clearValidationError()
        }
    }
    
    private func clearValidationError() {
        hasValidationError = false
        validationMessage = ""
    }
    
    // MARK: - Animation
    
    private func startAnimation() {
        isAnimating = true
    }
    
    private func stopAnimation() {
        isAnimating = false
    }
    
    // MARK: - Performance Feedback
    
    func updatePerformanceFeedback(duration: TimeInterval) {
        lastSortDuration = duration
        
        let milliseconds = duration * 1000
        if duration > 0.1 {
            performanceSummary = String(format: "Sort completed in %.0fms", milliseconds)
        } else {
            performanceSummary = String(format: "Sorted %d tasks in %.1fms", taskCount, milliseconds)
        }
        
        isShowingProgressIndicator = false
    }
    
    func showProgressIndicatorIfNeeded() {
        if estimatedSortTime > 0.1 {
            isShowingProgressIndicator = true
        }
    }
    
    // MARK: - State Persistence
    
    // Using SortUtilities for consistent persistence patterns
    private let persistenceKeys = SortUtilities.Persistence.Keys(prefix: "TaskSortContext")
    
    override func onAppear() async {
        await super.onAppear()
        
        // Restore persisted sort state using utilities
        if let savedOrder = UserDefaults.standard.string(forKey: persistenceKeys.sortOrder),
           let order = SortOrder(rawValue: savedOrder) {
            currentSortOrder = order
        }
        
        if let savedDirection = UserDefaults.standard.string(forKey: persistenceKeys.sortDirection),
           let direction = SortDirection(rawValue: savedDirection) {
            currentSortDirection = direction
        }
        
        isMultiCriteriaEnabled = UserDefaults.standard.bool(forKey: persistenceKeys.isMultiCriteria)
        
        if let savedPrimary = UserDefaults.standard.string(forKey: persistenceKeys.primarySort),
           let primary = SortOrder(rawValue: savedPrimary) {
            primarySortOrder = primary
        }
        
        if let savedSecondary = UserDefaults.standard.string(forKey: persistenceKeys.secondarySort),
           let secondary = SortOrder(rawValue: savedSecondary) {
            secondarySortOrder = secondary
        }
        
        // Apply restored sort state
        if isMultiCriteriaEnabled {
            await client.send(.setSortCriteria(
                primarySortOrder,
                secondary: secondarySortOrder,
                direction: currentSortDirection
            ))
        } else {
            await client.send(.setSortOrder(currentSortOrder))
            await client.send(.setSortDirection(currentSortDirection))
        }
    }
    
    override func onDisappear() async {
        await super.onDisappear()
        
        // Persist current sort state using utilities
        SortUtilities.Persistence.saveSortState(
            keys: persistenceKeys,
            sortOrder: currentSortOrder.rawValue,
            sortDirection: currentSortDirection.rawValue,
            isMultiCriteria: isMultiCriteriaEnabled,
            primarySort: primarySortOrder.rawValue,
            secondarySort: secondarySortOrder.rawValue
        )
    }
}

// MARK: - Sort Preset

struct SortPreset {
    let name: String
    let sortOrder: SortOrder
    let direction: SortDirection
    let secondarySortOrder: SortOrder?
    
    static var defaultPresets: [SortPreset] {
        [
            SortPreset(
                name: "Priority First",
                sortOrder: .priority,
                direction: .descending,
                secondarySortOrder: .dateCreated
            ),
            SortPreset(
                name: "Recently Created",
                sortOrder: .dateCreated,
                direction: .descending,
                secondarySortOrder: nil
            ),
            SortPreset(
                name: "Alphabetical",
                sortOrder: .alphabetical,
                direction: .ascending,
                secondarySortOrder: nil
            ),
            SortPreset(
                name: "Recently Modified",
                sortOrder: .dateModified,
                direction: .descending,
                secondarySortOrder: nil
            )
        ]
    }
}