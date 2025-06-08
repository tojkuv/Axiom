import Foundation

/// Reusable patterns for bulk operations following TDD best practices
/// Extracted during REFACTOR phase of REQ-012 implementation

// MARK: - Bulk Operation Pattern

/// A pattern for implementing bulk operations with progress tracking and error handling
struct BulkOperationPattern {
    
    /// Executes a bulk operation with proper progress tracking and error handling
    /// 
    /// - Parameters:
    ///   - selectedItems: Set of IDs for items to operate on
    ///   - operation: The operation to perform on each item
    ///   - progressCallback: Called with progress updates (0.0 to 1.0)
    ///   - completionCallback: Called when operation completes
    /// - Returns: Result of the operation
    /// - Throws: BulkOperationError for various failure scenarios
    static func execute<ItemType, ResultType>(
        selectedItems: Set<UUID>,
        operation: @escaping (ItemType) async throws -> ItemType,
        progressCallback: @escaping (Double) async -> Void,
        completionCallback: @escaping ([ItemType]) async -> ResultType
    ) async throws -> ResultType where ItemType: Identifiable, ItemType.ID == UUID {
        
        guard !selectedItems.isEmpty else {
            throw BulkOperationError.noItemsSelected
        }
        
        let totalItems = selectedItems.count
        var processedItems = 0
        var results: [ItemType] = []
        
        // Start progress tracking
        await progressCallback(0.0)
        
        // Process items with progress updates
        for itemId in selectedItems {
            // Note: In real implementation, would need to fetch the item
            // This is a pattern template - actual implementation would be in the client
            processedItems += 1
            let progress = Double(processedItems) / Double(totalItems)
            
            await progressCallback(progress)
            
            // Framework Performance: Batch processing optimization
            if processedItems % 50 == 0 {
                // Allow other operations to run, maintaining 60fps
                try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
            }
        }
        
        // Complete operation
        await progressCallback(1.0)
        return await completionCallback(results)
    }
    
    /// Validates that a bulk operation can proceed
    /// - Parameters:
    ///   - selectedItems: Items selected for the operation
    ///   - isOperationInProgress: Whether another operation is running
    /// - Throws: BulkOperationError if operation cannot proceed
    static func validateCanProceed(selectedItems: Set<UUID>, isOperationInProgress: Bool) throws {
        guard !selectedItems.isEmpty else {
            throw BulkOperationError.noItemsSelected
        }
        
        guard !isOperationInProgress else {
            throw BulkOperationError.operationInProgress
        }
    }
}

// MARK: - Bulk Selection Utilities

/// Utilities for managing multi-select state
struct BulkSelectionUtilities {
    
    /// Toggles selection state for an item
    /// - Parameters:
    ///   - itemId: ID of item to toggle
    ///   - currentSelection: Current selection set
    /// - Returns: Updated selection set
    static func toggleSelection(itemId: UUID, currentSelection: Set<UUID>) -> Set<UUID> {
        var updatedSelection = currentSelection
        
        if updatedSelection.contains(itemId) {
            updatedSelection.remove(itemId)
        } else {
            updatedSelection.insert(itemId)
        }
        
        return updatedSelection
    }
    
    /// Selects all items from a list
    /// - Parameter items: Items to select
    /// - Returns: Set of all item IDs
    static func selectAll<T: Identifiable>(items: [T]) -> Set<UUID> where T.ID == UUID {
        Set(items.map { $0.id })
    }
    
    /// Clears all selections
    /// - Returns: Empty set
    static func clearAll() -> Set<UUID> {
        Set<UUID>()
    }
    
    /// Checks if multi-select mode is active
    /// - Parameter selection: Current selection
    /// - Returns: True if any items are selected
    static func isMultiSelectMode(selection: Set<UUID>) -> Bool {
        !selection.isEmpty
    }
    
    /// Gets selected items from a collection
    /// - Parameters:
    ///   - items: Collection of items
    ///   - selection: Set of selected IDs
    /// - Returns: Array of selected items
    static func getSelectedItems<T: Identifiable>(
        from items: [T], 
        selection: Set<UUID>
    ) -> [T] where T.ID == UUID {
        items.filter { selection.contains($0.id) }
    }
}

// MARK: - Progress Tracking Utilities

/// Utilities for tracking progress in long-running operations
struct ProgressTrackingUtilities {
    
    /// Calculates progress as a percentage
    /// - Parameters:
    ///   - completed: Number of completed items
    ///   - total: Total number of items
    /// - Returns: Progress as Double (0.0 to 1.0)
    static func calculateProgress(completed: Int, total: Int) -> Double {
        guard total > 0 else { return 1.0 }
        return Double(completed) / Double(total)
    }
    
    /// Determines if progress update should be throttled for performance
    /// - Parameters:
    ///   - itemIndex: Current item being processed
    ///   - throttleInterval: How often to allow updates (e.g., every 10 items)
    /// - Returns: True if update should be sent
    static func shouldUpdateProgress(itemIndex: Int, throttleInterval: Int = 10) -> Bool {
        itemIndex % throttleInterval == 0
    }
    
    /// Creates a progress update closure that maintains 60fps
    /// - Parameter callback: The actual progress callback
    /// - Returns: Throttled progress callback
    static func createThrottledProgressCallback(
        _ callback: @escaping (Double) async -> Void
    ) -> (Double) async -> Void {
        var lastUpdateTime: DispatchTime = .now()
        let minimumInterval = DispatchTimeInterval.nanoseconds(16_666_666) // ~60fps
        
        return { progress in
            let now = DispatchTime.now()
            if now > lastUpdateTime + minimumInterval || progress >= 1.0 {
                await callback(progress)
                lastUpdateTime = now
            }
        }
    }
}

// MARK: - Error Definitions

/// Errors that can occur during bulk operations
enum BulkOperationError: Error, Equatable {
    case noItemsSelected
    case operationInProgress
    case operationCancelled
    case partialFailure(succeeded: Int, failed: Int)
    
    var localizedDescription: String {
        switch self {
        case .noItemsSelected:
            return "No items selected for bulk operation"
        case .operationInProgress:
            return "Another bulk operation is already in progress"
        case .operationCancelled:
            return "Bulk operation was cancelled"
        case .partialFailure(let succeeded, let failed):
            return "Bulk operation partially failed: \(succeeded) succeeded, \(failed) failed"
        }
    }
}

// MARK: - Framework Insights from Implementation

/// Documentation of framework insights discovered during REQ-012 implementation
/// 
/// PAIN POINTS IDENTIFIED:
/// 1. No built-in bulk operation patterns - had to create custom implementation
/// 2. Progress tracking requires manual throttling to maintain 60fps
/// 3. Actor isolation makes batch processing complex
/// 4. No framework utilities for multi-select state management
/// 
/// SUCCESSFUL PATTERNS:
/// 1. Actor-based state isolation prevents race conditions in bulk operations
/// 2. Immutable state with COW semantics scales well to bulk operations
/// 3. AsyncStream provides excellent progress tracking capabilities
/// 4. Error boundary pattern works well with bulk operation failures
/// 
/// RECOMMENDED FRAMEWORK IMPROVEMENTS:
/// 1. Built-in BulkOperationPattern with progress tracking
/// 2. Multi-select state management utilities
/// 3. Performance-optimized batch processing APIs
/// 4. Standard error types for bulk operations