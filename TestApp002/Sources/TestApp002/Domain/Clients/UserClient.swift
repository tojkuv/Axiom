import Foundation
import Axiom

// GREEN Phase: UserClient implementation to pass tests
actor UserClient: Client {
    typealias StateType = UserState
    typealias ActionType = UserAction
    
    private var state: UserState
    private let stateStreamContinuation: AsyncStream<UserState>.Continuation
    private let _stateStream: AsyncStream<UserState>
    
    var stateStream: AsyncStream<UserState> {
        _stateStream
    }
    
    init() {
        self.state = UserState()
        
        // Create state stream
        (_stateStream, stateStreamContinuation) = AsyncStream<UserState>.makeStream()
        
        // Emit initial state
        stateStreamContinuation.yield(state)
    }
    
    func process(_ action: UserAction) async throws {
        switch action {
        case .login(let email, let password):
            // Simulate authentication (in real app, would use a capability)
            try await _Concurrency.Task.sleep(nanoseconds: 50_000_000) // 50ms simulated auth
            
            // Create user profile after successful login
            let profile = UserProfile(
                id: UUID().uuidString,
                email: email,
                displayName: email.components(separatedBy: "@").first ?? "User"
            )
            
            state = UserState(
                userId: profile.id,
                profile: profile,
                preferences: state.preferences
            )
            stateStreamContinuation.yield(state)
            
        case .logout:
            state = UserState(
                userId: nil,
                profile: nil,
                preferences: state.preferences
            )
            stateStreamContinuation.yield(state)
            
        case .updateProfile(let newProfile):
            // Only update if user is logged in
            guard state.userId != nil else { return }
            
            state = UserState(
                userId: newProfile.id,
                profile: newProfile,
                preferences: state.preferences
            )
            stateStreamContinuation.yield(state)
            
        case .updatePreferences(let newPreferences):
            state = UserState(
                userId: state.userId,
                profile: state.profile,
                preferences: newPreferences
            )
            stateStreamContinuation.yield(state)
        }
    }
}