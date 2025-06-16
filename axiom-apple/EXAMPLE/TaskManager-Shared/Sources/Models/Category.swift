import Foundation
import SwiftUI

// MARK: - Category Model

/// Represents a category for organizing tasks
public enum Category: String, CaseIterable, Codable, Sendable, Hashable {
    case personal = "personal"
    case work = "work"
    case shopping = "shopping"
    case health = "health"
    case finance = "finance"
    case education = "education"
    case travel = "travel"
    case home = "home"
    case social = "social"
    case hobby = "hobby"
    case other = "other"
    
    /// Display name for the category
    public var displayName: String {
        switch self {
        case .personal: return "Personal"
        case .work: return "Work"
        case .shopping: return "Shopping"
        case .health: return "Health"
        case .finance: return "Finance"
        case .education: return "Education"
        case .travel: return "Travel"
        case .home: return "Home"
        case .social: return "Social"
        case .hobby: return "Hobby"
        case .other: return "Other"
        }
    }
    
    /// Description of the category
    public var description: String {
        switch self {
        case .personal: return "Personal tasks and goals"
        case .work: return "Work-related tasks"
        case .shopping: return "Shopping lists and purchases"
        case .health: return "Health and fitness tasks"
        case .finance: return "Financial planning and tasks"
        case .education: return "Learning and educational tasks"
        case .travel: return "Travel planning and tasks"
        case .home: return "Home maintenance and improvement"
        case .social: return "Social events and relationships"
        case .hobby: return "Hobbies and recreational activities"
        case .other: return "Miscellaneous tasks"
        }
    }
    
    /// Color associated with the category for UI display
    public var color: Color {
        switch self {
        case .personal: return .blue
        case .work: return .purple
        case .shopping: return .green
        case .health: return .red
        case .finance: return .orange
        case .education: return .indigo
        case .travel: return .teal
        case .home: return .brown
        case .social: return .pink
        case .hobby: return .mint
        case .other: return .gray
        }
    }
    
    /// System image name for the category
    public var systemImageName: String {
        switch self {
        case .personal: return "person.circle"
        case .work: return "briefcase"
        case .shopping: return "cart"
        case .health: return "heart.circle"
        case .finance: return "dollarsign.circle"
        case .education: return "book.circle"
        case .travel: return "airplane.circle"
        case .home: return "house.circle"
        case .social: return "person.2.circle"
        case .hobby: return "gamecontroller"
        case .other: return "circle"
        }
    }
    
    /// Emoji representation for the category
    public var emoji: String {
        switch self {
        case .personal: return "👤"
        case .work: return "💼"
        case .shopping: return "🛒"
        case .health: return "❤️"
        case .finance: return "💰"
        case .education: return "📚"
        case .travel: return "✈️"
        case .home: return "🏠"
        case .social: return "👥"
        case .hobby: return "🎮"
        case .other: return "📋"
        }
    }
}

// MARK: - Category Validation

extension Category {
    /// Creates a category from a string representation
    public init?(from string: String) {
        let lowercased = string.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try exact match first
        if let category = Category(rawValue: lowercased) {
            self = category
            return
        }
        
        // Try display name match
        for category in Category.allCases {
            if category.displayName.lowercased() == lowercased {
                self = category
                return
            }
        }
        
        return nil
    }
    
    /// Validates that the category is valid
    public var isValid: Bool {
        Category.allCases.contains(self)
    }
}

// MARK: - Category Grouping

extension Category {
    /// Returns the default category for new tasks
    public static var defaultCategory: Category {
        .personal
    }
    
    /// Returns categories grouped by type
    public static var groupedCategories: (work: [Category], personal: [Category], lifestyle: [Category]) {
        let work: [Category] = [.work, .finance, .education]
        let personal: [Category] = [.personal, .health, .social]
        let lifestyle: [Category] = [.shopping, .travel, .home, .hobby, .other]
        
        return (work, personal, lifestyle)
    }
    
    /// Returns commonly used categories
    public static var commonCategories: [Category] {
        [.personal, .work, .shopping, .health, .home]
    }
    
    /// Returns categories ordered by typical usage frequency
    public static var orderedByUsage: [Category] {
        [.personal, .work, .shopping, .health, .home, .finance, .social, .education, .travel, .hobby, .other]
    }
}

// MARK: - Category Search and Matching

extension Category {
    /// Check if the category matches a search query
    public func matches(searchQuery: String) -> Bool {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return true
        }
        
        let query = searchQuery.lowercased()
        
        return displayName.lowercased().contains(query) ||
               rawValue.lowercased().contains(query) ||
               description.lowercased().contains(query)
    }
}

// MARK: - Category Statistics

extension Category {
    /// Priority weight for category-based sorting (higher number = higher priority in display)
    public var displayPriority: Int {
        switch self {
        case .personal: return 10
        case .work: return 9
        case .health: return 8
        case .shopping: return 7
        case .home: return 6
        case .finance: return 5
        case .education: return 4
        case .social: return 3
        case .travel: return 2
        case .hobby: return 1
        case .other: return 0
        }
    }
}

// MARK: - Category Comparable

extension Category: Comparable {
    public static func < (lhs: Category, rhs: Category) -> Bool {
        lhs.displayPriority > rhs.displayPriority
    }
}

// MARK: - Category Localization Support

extension Category {
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