import Foundation

enum UserAction {
    case login(email: String, password: String)
    case logout
    case updateProfile(UserProfile)
    case updatePreferences(UserPreferences)
}