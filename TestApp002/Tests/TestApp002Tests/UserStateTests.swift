import XCTest
import Axiom
@testable import TestApp002Core

final class UserStateTests: XCTestCase {
    
    // MARK: - Test UserState immutability
    
    func testUserStateImmutability() {
        let preferences = UserPreferences(theme: .dark, notificationsEnabled: false, autoSync: true)
        let profile = UserProfile(id: "user-1", email: "test@example.com", displayName: "Test User")
        let state = UserState(userId: "user-1", profile: profile, preferences: preferences)
        
        // Verify all properties are immutable (let constants)
        XCTAssertEqual(state.userId, "user-1")
        XCTAssertEqual(state.profile?.email, "test@example.com")
        XCTAssertEqual(state.preferences.theme, .dark)
        XCTAssertFalse(state.preferences.notificationsEnabled)
    }
    
    func testUserStateEquatable() {
        let profile1 = UserProfile(id: "1", email: "test@example.com", displayName: "User 1")
        let state1 = UserState(userId: "1", profile: profile1, preferences: UserPreferences())
        
        let profile2 = UserProfile(id: "1", email: "test@example.com", displayName: "User 1")
        let state2 = UserState(userId: "1", profile: profile2, preferences: UserPreferences())
        
        // Same values should be equal
        XCTAssertEqual(state1, state2)
        
        // Different userId should not be equal
        let state3 = UserState(userId: "2", profile: profile1, preferences: UserPreferences())
        XCTAssertNotEqual(state1, state3)
    }
    
    func testUserStateHashable() {
        let profile = UserProfile(id: "1", email: "test@example.com", displayName: "User")
        let state1 = UserState(userId: "1", profile: profile, preferences: UserPreferences())
        let state2 = UserState(userId: "1", profile: profile, preferences: UserPreferences())
        
        // Equal states should have equal hash values
        XCTAssertEqual(state1.hashValue, state2.hashValue)
        
        // Can be used in Sets
        let stateSet: Set<UserState> = [state1, state2]
        XCTAssertEqual(stateSet.count, 1) // Duplicates removed
    }
    
    func testUserProfileCodable() throws {
        let profile = UserProfile(
            id: "test-id",
            email: "user@example.com",
            displayName: "Test User",
            avatarURL: "https://example.com/avatar.png"
        )
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedProfile = try decoder.decode(UserProfile.self, from: data)
        
        XCTAssertEqual(profile, decodedProfile)
    }
    
    func testUserPreferencesCodable() throws {
        let preferences = UserPreferences(
            theme: .dark,
            notificationsEnabled: false,
            autoSync: true
        )
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(preferences)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedPreferences = try decoder.decode(UserPreferences.self, from: data)
        
        XCTAssertEqual(preferences, decodedPreferences)
    }
    
    func testUserStateDefaultValues() {
        let state = UserState()
        
        XCTAssertNil(state.userId)
        XCTAssertNil(state.profile)
        XCTAssertEqual(state.preferences.theme, .system)
        XCTAssertTrue(state.preferences.notificationsEnabled)
        XCTAssertTrue(state.preferences.autoSync)
    }
    
    func testUserStateUpdatePattern() {
        // Test the immutable update pattern
        let originalState = UserState(userId: "1")
        let newProfile = UserProfile(id: "1", email: "new@example.com", displayName: "New User")
        
        // Create new state with updated profile
        let updatedState = UserState(
            userId: originalState.userId,
            profile: newProfile,
            preferences: originalState.preferences
        )
        
        // Original unchanged
        XCTAssertNil(originalState.profile)
        // New state has update
        XCTAssertEqual(updatedState.profile?.email, "new@example.com")
    }
}