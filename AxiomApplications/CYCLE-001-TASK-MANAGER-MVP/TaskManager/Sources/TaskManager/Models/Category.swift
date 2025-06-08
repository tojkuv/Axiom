import Foundation
import Axiom

/// Category model for organizing tasks
struct Category: State {
    let id: UUID
    let name: String
    let color: String // Hex color like "#FF5733"
    let icon: String? // SF Symbol name
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        color: String,
        icon: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Display Properties

extension Category {
    /// Display name for UI (same as name for categories)
    var displayName: String {
        return name
    }
}

// MARK: - Validation

extension Category {
    static func isValidColor(_ color: String) -> Bool {
        // Hex color validation
        let pattern = "^#[0-9A-Fa-f]{6}$"
        return color.range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Default Categories

extension Category {
    static var defaultCategories: [Category] {
        [
            Category(name: "Personal", color: "#FF5733", icon: "person.fill"),
            Category(name: "Work", color: "#3498DB", icon: "briefcase.fill"),
            Category(name: "Shopping", color: "#2ECC71", icon: "cart.fill"),
            Category(name: "Health", color: "#E74C3C", icon: "heart.fill"),
            Category(name: "Finance", color: "#F39C12", icon: "dollarsign.circle.fill")
        ]
    }
}

// MARK: - Codable

extension Category: Codable {
    // Automatic Codable synthesis works with State protocol
}