import Foundation
import Axiom

struct UserState: State, Equatable, Hashable {
    let userId: String?
    let profile: UserProfile?
    let preferences: UserPreferences
    
    init(
        userId: String? = nil,
        profile: UserProfile? = nil,
        preferences: UserPreferences = UserPreferences()
    ) {
        self.userId = userId
        self.profile = profile
        self.preferences = preferences
    }
}

struct UserProfile: Equatable, Hashable, Codable {
    let id: String
    let email: String
    let displayName: String
    let avatarURL: String?
    
    init(
        id: String,
        email: String,
        displayName: String,
        avatarURL: String? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarURL = avatarURL
    }
}

struct UserPreferences: Equatable, Hashable, Codable {
    let theme: Theme
    let notificationsEnabled: Bool
    let autoSync: Bool
    
    init(
        theme: Theme = .system,
        notificationsEnabled: Bool = true,
        autoSync: Bool = true
    ) {
        self.theme = theme
        self.notificationsEnabled = notificationsEnabled
        self.autoSync = autoSync
    }
}

enum Theme: String, Codable, Hashable {
    case light
    case dark
    case system
}