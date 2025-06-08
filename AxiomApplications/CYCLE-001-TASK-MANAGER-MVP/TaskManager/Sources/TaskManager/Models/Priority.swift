import Foundation
import Axiom

/// Priority levels for tasks
enum Priority: String, State, CaseIterable, Comparable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    /// Numeric value for comparison
    var numericValue: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .critical: return 3
        }
    }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    /// Color for UI display
    var color: String {
        switch self {
        case .low: return "#4CAF50"      // Green
        case .medium: return "#FF9800"   // Orange
        case .high: return "#FF5722"     // Deep Orange
        case .critical: return "#F44336" // Red
        }
    }
    
    /// SF Symbol icon
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
    
    /// Comparable implementation for sorting
    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.numericValue < rhs.numericValue
    }
}

// MARK: - String-based init for Codable support

extension Priority {
    init(stringValue: String) {
        switch stringValue.lowercased() {
        case "low": self = .low
        case "medium": self = .medium
        case "high": self = .high
        case "critical": self = .critical
        default: self = .medium // Default fallback
        }
    }
    
    var stringValue: String {
        rawValue
    }
}

// MARK: - Codable

extension Priority: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        self.init(stringValue: stringValue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}