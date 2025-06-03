import Foundation
import SwiftUI
@testable import Axiom

// MARK: - Example: Complete Architecture Implementation

// 1. Domain State (owned by client)
struct UserProfileState: Axiom.State {
    var name: String = ""
    var email: String = ""
    var isPremium: Bool = false
    
    init() {}
}

// 2. Client (owns and mutates state)
actor UserProfileClient: Client {
    typealias State = UserProfileState
    
    private(set) var state = UserProfileState()
    
    func updateState(_ transform: (inout UserProfileState) -> Void) async {
        transform(&state)
    }
}

// 3. Context (orchestrates business logic, derives state for presentation)
@MainActor
final class UserProfileContext: BaseContext<UserProfileContext.DerivedState, UserProfileContext.PresentationActions> {
    
    // Derived state for presentation
    struct DerivedState: Axiom.State {
        let displayName: String
        let emailDisplay: String
        let membershipBadge: String
        let canUpgrade: Bool
        
        init() {
            self.displayName = ""
            self.emailDisplay = ""
            self.membershipBadge = ""
            self.canUpgrade = false
        }
        
        init(displayName: String, emailDisplay: String, membershipBadge: String, canUpgrade: Bool) {
            self.displayName = displayName
            self.emailDisplay = emailDisplay
            self.membershipBadge = membershipBadge
            self.canUpgrade = canUpgrade
        }
    }
    
    // Actions available to presentation
    struct PresentationActions {
        let updateName: (String) async -> Void
        let updateEmail: (String) async -> Void
        let upgradeToPremium: () async -> Void
        let refresh: () async -> Void
    }
    
    // Client dependencies (private - not exposed to presentation)
    private let userClient: UserProfileClient
    
    init(userClient: UserProfileClient) {
        self.userClient = userClient
        
        // Build initial actions
        let initialActions = PresentationActions(
            updateName: { _ in },
            updateEmail: { _ in },
            upgradeToPremium: { },
            refresh: { }
        )
        
        super.init(state: DerivedState(), actions: initialActions)
        
        // Set real actions with self reference
        setActions(PresentationActions(
            updateName: { [weak self] name in
                await self?.updateName(name)
            },
            updateEmail: { [weak self] email in
                await self?.updateEmail(email)
            },
            upgradeToPremium: { [weak self] in
                await self?.upgradeToPremium()
            },
            refresh: { [weak self] in
                await self?.refreshDerivedState()
            }
        ))
        
        // Initial state derivation
        Task {
            await refreshDerivedState()
        }
    }
    
    // REDUCERS: Business logic implementation
    
    private func updateName(_ name: String) async {
        await userClient.updateState { $0.name = name }
        await refreshDerivedState()
    }
    
    private func updateEmail(_ email: String) async {
        await userClient.updateState { $0.email = email }
        await refreshDerivedState()
    }
    
    private func upgradeToPremium() async {
        await userClient.updateState { $0.isPremium = true }
        await refreshDerivedState()
    }
    
    // Derive state from clients for presentation
    private func refreshDerivedState() async {
        let userState = await userClient.state
        
        let derivedState = DerivedState(
            displayName: userState.name.isEmpty ? "Guest User" : userState.name,
            emailDisplay: userState.email.isEmpty ? "No email set" : userState.email,
            membershipBadge: userState.isPremium ? "⭐ Premium" : "Free",
            canUpgrade: !userState.isPremium
        )
        
        updateState(derivedState)
    }
}

// 4. Presentation (pure UI - no direct client/state access)
struct UserProfileView: Presentation {
    typealias ContextType = UserProfileContext
    
    let context: UserProfileContext
    
    var body: some View {
        VStack(spacing: 20) {
            // ✅ ALLOWED: Access context's derived state
            Text(context.state.displayName)
                .font(.title)
            
            Text(context.state.emailDisplay)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Membership:")
                Text(context.state.membershipBadge)
                    .bold()
            }
            
            // ✅ ALLOWED: Trigger context actions
            if context.state.canUpgrade {
                Button("Upgrade to Premium") {
                    Task {
                        await context.actions.upgradeToPremium()
                        await context.actions.refresh()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            Button("Refresh") {
                Task {
                    await context.actions.refresh()
                }
            }
            
            // ❌ NOT ALLOWED: Direct client access
            // The following would cause compile errors:
            // Text(context.userClient.state.name)  // ERROR: No userClient property
            // await context.userClient.updateState { ... }  // ERROR: No userClient property
        }
        .padding()
    }
}