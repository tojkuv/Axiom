import Foundation

/// Utilities for sorting collections with multi-criteria support
/// Framework insight: These utilities should be part of the Axiom framework
public enum SortUtilities {
    
    /// Performs a stable multi-criteria sort on a collection
    /// - Parameters:
    ///   - items: The collection to sort
    ///   - primary: Primary sort criteria
    ///   - secondary: Optional secondary sort criteria for tie-breaking
    ///   - direction: Sort direction (ascending/descending)
    /// - Returns: Sorted array maintaining stability for equal elements
    public static func multiCriteriaSort<T>(
        _ items: [T],
        primary: (T, T) -> ComparisonResult,
        secondary: ((T, T) -> ComparisonResult)? = nil,
        direction: SortDirection = .ascending
    ) -> [T] {
        return items.sorted { item1, item2 in
            let primaryResult = primary(item1, item2)
            
            // If primary comparison is equal and we have secondary criteria
            if primaryResult == .orderedSame, let secondary = secondary {
                let secondaryResult = secondary(item1, item2)
                return direction == .ascending ?
                    secondaryResult == .orderedAscending :
                    secondaryResult == .orderedDescending
            }
            
            // Use primary comparison result
            return direction == .ascending ?
                primaryResult == .orderedAscending :
                primaryResult == .orderedDescending
        }
    }
    
    /// Common comparison functions for reuse
    public struct Comparisons {
        /// Compare by date (nil dates sort last)
        public static func byDate<T>(_ keyPath: KeyPath<T, Date?>) -> (T, T) -> ComparisonResult {
            return { item1, item2 in
                let date1 = item1[keyPath: keyPath]
                let date2 = item2[keyPath: keyPath]
                
                switch (date1, date2) {
                case (nil, nil):
                    return .orderedSame
                case (nil, _):
                    return .orderedDescending
                case (_, nil):
                    return .orderedAscending
                case let (d1?, d2?):
                    return d1.compare(d2)
                }
            }
        }
        
        /// Compare by string (case-insensitive)
        public static func byString<T>(_ keyPath: KeyPath<T, String>) -> (T, T) -> ComparisonResult {
            return { item1, item2 in
                let string1 = item1[keyPath: keyPath]
                let string2 = item2[keyPath: keyPath]
                return string1.localizedCaseInsensitiveCompare(string2)
            }
        }
        
        /// Compare by numeric value
        public static func byNumber<T, N: Comparable>(_ keyPath: KeyPath<T, N>) -> (T, T) -> ComparisonResult {
            return { item1, item2 in
                let num1 = item1[keyPath: keyPath]
                let num2 = item2[keyPath: keyPath]
                
                if num1 < num2 {
                    return .orderedAscending
                } else if num1 > num2 {
                    return .orderedDescending
                } else {
                    return .orderedSame
                }
            }
        }
    }
    
    /// Performance monitoring for sort operations
    public struct PerformanceMonitor {
        /// Measures and returns the duration of a sort operation
        public static func measureSort<T>(_ sortOperation: () throws -> T) rethrows -> (result: T, duration: TimeInterval) {
            let startTime = Date()
            let result = try sortOperation()
            let duration = Date().timeIntervalSince(startTime)
            return (result, duration)
        }
        
        /// Checks if a sort duration is within acceptable limits
        public static func isPerformanceAcceptable(
            duration: TimeInterval,
            itemCount: Int,
            targetMillisecondsPerThousand: Double = 5.0
        ) -> Bool {
            let expectedDuration = (Double(itemCount) / 1000.0) * (targetMillisecondsPerThousand / 1000.0)
            return duration <= expectedDuration
        }
    }
    
    /// State persistence utilities
    public struct Persistence {
        /// Keys for sort state persistence
        public struct Keys {
            public let sortOrder: String
            public let sortDirection: String
            public let isMultiCriteria: String
            public let primarySort: String
            public let secondarySort: String
            
            public init(prefix: String) {
                self.sortOrder = "\(prefix).sortOrder"
                self.sortDirection = "\(prefix).sortDirection"
                self.isMultiCriteria = "\(prefix).isMultiCriteria"
                self.primarySort = "\(prefix).primarySort"
                self.secondarySort = "\(prefix).secondarySort"
            }
        }
        
        /// Save sort state to UserDefaults
        public static func saveSortState(
            keys: Keys,
            sortOrder: String,
            sortDirection: String,
            isMultiCriteria: Bool,
            primarySort: String? = nil,
            secondarySort: String? = nil
        ) {
            UserDefaults.standard.set(sortOrder, forKey: keys.sortOrder)
            UserDefaults.standard.set(sortDirection, forKey: keys.sortDirection)
            UserDefaults.standard.set(isMultiCriteria, forKey: keys.isMultiCriteria)
            
            if let primary = primarySort {
                UserDefaults.standard.set(primary, forKey: keys.primarySort)
            }
            if let secondary = secondarySort {
                UserDefaults.standard.set(secondary, forKey: keys.secondarySort)
            }
        }
        
        /// Clear sort state from UserDefaults
        public static func clearSortState(keys: Keys) {
            UserDefaults.standard.removeObject(forKey: keys.sortOrder)
            UserDefaults.standard.removeObject(forKey: keys.sortDirection)
            UserDefaults.standard.removeObject(forKey: keys.isMultiCriteria)
            UserDefaults.standard.removeObject(forKey: keys.primarySort)
            UserDefaults.standard.removeObject(forKey: keys.secondarySort)
        }
    }
}

/// Extension to make SortDirection more useful
extension SortDirection {
    /// Inverts the sort direction
    public var inverted: SortDirection {
        self == .ascending ? .descending : .ascending
    }
    
    /// Applies direction to a comparison result
    public func apply(to result: ComparisonResult) -> Bool {
        switch self {
        case .ascending:
            return result == .orderedAscending
        case .descending:
            return result == .orderedDescending
        }
    }
}