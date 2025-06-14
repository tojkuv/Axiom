import Foundation
import SwiftUI

// MARK: - Priority Model

/// Represents the priority level of a task
public enum Priority: Int, CaseIterable, Codable, Sendable, Hashable {
    case low = 1
    case medium = 2
    case high = 3
    case urgent = 4
    
    /// Display name for the priority
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    /// Short description of the priority
    public var description: String {
        switch self {
        case .low: return "Low priority task"
        case .medium: return "Medium priority task"
        case .high: return "High priority task"
        case .urgent: return "Urgent priority task"
        }
    }
    
    /// Color associated with the priority for UI display
    public var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    /// System image name for the priority
    public var systemImageName: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        case .urgent: return "exclamationmark.circle"
        }
    }
    
    /// Numeric weight for sorting (higher number = higher priority)
    public var weight: Int {
        return rawValue
    }
    
    /// Returns the next higher priority level (if available)
    public var nextHigher: Priority? {
        Priority(rawValue: rawValue + 1)
    }
    
    /// Returns the next lower priority level (if available)
    public var nextLower: Priority? {
        Priority(rawValue: rawValue - 1)
    }
}

// MARK: - Priority Comparable

extension Priority: Comparable {
    public static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Priority Validation

extension Priority {
    /// Validates that the priority is within acceptable range
    public var isValid: Bool {
        Priority.allCases.contains(self)
    }
    
    /// Creates a priority from a string representation
    public init?(from string: String) {
        let lowercased = string.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch lowercased {
        case "low", "1":
            self = .low
        case "medium", "2":
            self = .medium
        case "high", "3":
            self = .high
        case "urgent", "4":
            self = .urgent
        default:
            return nil
        }
    }
}

// MARK: - Priority Statistics

extension Priority {
    /// Returns the default priority for new tasks
    public static var defaultPriority: Priority {
        .medium
    }
    
    /// Returns priorities ordered by urgency (most urgent first)
    public static var orderedByUrgency: [Priority] {
        allCases.sorted { $0.weight > $1.weight }
    }
    
    /// Returns priorities grouped by urgency level
    public static var groupedByUrgency: (urgent: [Priority], normal: [Priority]) {
        let urgent = allCases.filter { $0.weight >= Priority.high.weight }
        let normal = allCases.filter { $0.weight < Priority.high.weight }
        return (urgent, normal)
    }
}

// MARK: - Priority Localization Support

extension Priority {
    /// Localized display name (would use NSLocalizedString in production)
    public var localizedDisplayName: String {
        // In a real app, this would use NSLocalizedString
        return displayName
    }
    
    /// Localized description (would use NSLocalizedString in production)
    public var localizedDescription: String {
        // In a real app, this would use NSLocalizedString
        return description
    }
}