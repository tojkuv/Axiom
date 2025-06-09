import XCTest
import SwiftUI
@testable import Axiom
@testable import AxiomTesting

/// Tests for Context-focused test scenarios
final class ContextTestScenarioTests: XCTestCase {
    
    // MARK: - Test Types
    
    struct UserState: State, Equatable {
        var user: User?
        var isAuthenticated: Bool = false
        var authError: String?
    }
    
    struct User: Equatable {
        let id: String
        let name: String
        let email: String
    }
    
    enum UserAction {
        case login(email: String, password: String)
        case logout
        case updateProfile(name: String)
    }
    
    actor UserClient: BaseClient<UserState, UserAction> {
        override func process(_ action: UserAction) async throws {
            var newState = state
            
            switch action {
            case .login(let email, _):
                // Simulate login
                newState.user = User(id: "123", name: "Test User", email: email)
                newState.isAuthenticated = true
                newState.authError = nil
            case .logout:
                newState.user = nil
                newState.isAuthenticated = false
                newState.authError = nil
            case .updateProfile(let name):
                if var user = newState.user {
                    newState.user = User(id: user.id, name: name, email: user.email)
                }
            }
            
            updateState(newState)
        }
    }
    
    @MainActor
    final class UserContext: ClientObservingContext<UserClient> {
        @Published var displayName: String = "Guest"
        @Published var isShowingProfile: Bool = false
        
        private(set) var stateUpdateCount: Int = 0
        private(set) var lifecycleEvents: [String] = []
        
        override func handleStateUpdate(_ state: UserState) async {
            stateUpdateCount += 1
            
            if let user = state.user {
                displayName = user.name
            } else {
                displayName = "Guest"
            }
            
            // Auto-dismiss profile on logout
            if !state.isAuthenticated && isShowingProfile {
                isShowingProfile = false
            }
        }
        
        override func performAppearance() async {
            await super.performAppearance()
            lifecycleEvents.append("appeared")
        }
        
        override func performDisappearance() async {
            await super.performDisappearance()
            lifecycleEvents.append("disappeared")
        }
        
        func showProfile() {
            guard client.state.isAuthenticated else { return }
            isShowingProfile = true
        }
    }
    
    // MARK: - Context Test Scenario Tests
    
    func testContextScenarioBasicUsage() async throws {
        // Test basic context behavior observation
        let scenario = ContextTestScenario(UserContext.self)
            .withClient(UserClient(initialState: UserState()))
            .when { context in
                try await context.client.process(.login(email: "test@example.com", password: "password"))
            }
            .then { context in
                context.displayName == "Test User"
            }
        
        try await scenario.execute()
    }
    
    func testContextLifecycleManagement() async throws {
        // Test context lifecycle events
        let scenario = ContextTestScenario(UserContext.self)
            .withClient(UserClient(initialState: UserState()))
            .onAppear()
            .then { context in
                context.lifecycleEvents.contains("appeared")
            }
            .onDisappear()
            .then { context in
                context.lifecycleEvents == ["appeared", "disappeared"]
            }
        
        try await scenario.execute()
    }
    
    func testContextStateObservation() async throws {
        // Test that context properly observes client state changes
        let scenario = ContextTestScenario(UserContext.self)
            .withClient(UserClient(initialState: UserState()))
            .onAppear()
            .when { context in
                try await context.client.process(.login(email: "test@example.com", password: "pass"))
            }
            .validate { context in
                context.stateUpdateCount == 1 && context.displayName == "Test User"
            }
            .when { context in
                try await context.client.process(.updateProfile(name: "Updated User"))
            }
            .then { context in
                context.stateUpdateCount == 2 && context.displayName == "Updated User"
            }
        
        try await scenario.execute()
    }
    
    func testContextUICoordination() async throws {
        // Test context UI coordination logic
        let scenario = ContextTestScenario(UserContext.self)
            .withClient(UserClient(initialState: UserState(
                user: User(id: "1", name: "Test", email: "test@example.com"),
                isAuthenticated: true
            )))
            .onAppear()
            .when { context in
                context.showProfile()
            }
            .validate { context in
                context.isShowingProfile == true
            }
            .when { context in
                // Logout should auto-dismiss profile
                try await context.client.process(.logout)
            }
            .then { context in
                context.isShowingProfile == false && context.displayName == "Guest"
            }
        
        try await scenario.execute()
    }
    
    func testContextWithMultipleClients() async throws {
        // Test context managing multiple clients
        @MainActor
        final class MultiClientContext: BaseContext {
            let userClient: UserClient
            let settingsClient: SettingsClient
            
            @Published var combinedState: String = ""
            
            init(userClient: UserClient, settingsClient: SettingsClient) {
                self.userClient = userClient
                self.settingsClient = settingsClient
                super.init()
            }
            
            override func performAppearance() async {
                await super.performAppearance()
                
                // Observe both clients
                Task {
                    for await userState in await userClient.stateStream {
                        await updateCombinedState(user: userState)
                    }
                }
                
                Task {
                    for await settingsState in await settingsClient.stateStream {
                        await updateCombinedState(settings: settingsState)
                    }
                }
            }
            
            func updateCombinedState(user: UserState? = nil, settings: SettingsState? = nil) async {
                let userName = user?.user?.name ?? userClient.state.user?.name ?? "Guest"
                let theme = settings?.theme ?? settingsClient.state.theme
                combinedState = "\(userName) - \(theme)"
                notifyUpdate()
            }
        }
        
        let scenario = ContextTestScenario(MultiClientContext.self)
            .withSetup { _ in
                let userClient = UserClient(initialState: UserState())
                let settingsClient = SettingsClient(initialState: SettingsState())
                return MultiClientContext(userClient: userClient, settingsClient: settingsClient)
            }
            .onAppear()
            .when { context in
                try await context.userClient.process(.login(email: "test@example.com", password: "pass"))
            }
            .when { context in
                try await context.settingsClient.process(.changeTheme("dark"))
            }
            .then { context in
                context.combinedState == "Test User - dark"
            }
        
        try await scenario.execute()
    }
    
    func testContextChildParentCommunication() async throws {
        // Test child-parent context communication
        @MainActor
        final class ParentContext: BaseContext {
            var receivedActions: [String] = []
            
            override func handleChildAction<T>(_ action: T, from child: any Context) {
                if let stringAction = action as? String {
                    receivedActions.append(stringAction)
                    notifyUpdate()
                }
            }
        }
        
        @MainActor
        final class ChildContext: BaseContext {
            func sendMessage(_ message: String) async {
                await sendToParent(message)
            }
        }
        
        let scenario = ContextTestScenario(ParentContext.self)
            .withChild { parent in
                let child = ChildContext()
                parent.addChild(child)
                return child
            }
            .when { context, children in
                let child = children[0] as! ChildContext
                await child.sendMessage("Hello from child")
            }
            .then { context in
                context.receivedActions == ["Hello from child"]
            }
        
        try await scenario.execute()
    }
    
    func testContextMemoryManagement() async throws {
        // Test weak reference management
        let scenario = ContextTestScenario(UserContext.self)
            .withClient(UserClient(initialState: UserState()))
            .measureMemory()
            .when { context in
                // Perform actions that might retain memory
                for i in 0..<100 {
                    try await context.client.process(.updateProfile(name: "User \(i)"))
                }
            }
            .then { context in
                // Memory should be stable
                context.activeChildren.isEmpty // No leaked children
            }
        
        try await scenario.execute()
        
        XCTAssertNotNil(scenario.memoryMetrics)
        XCTAssertTrue(scenario.memoryMetrics!.isStable)
    }
    
    // MARK: - Supporting Types for Tests
    
    struct SettingsState: State, Equatable {
        var theme: String = "light"
        var notifications: Bool = true
    }
    
    enum SettingsAction {
        case changeTheme(String)
        case toggleNotifications
    }
    
    actor SettingsClient: BaseClient<SettingsState, SettingsAction> {
        override func process(_ action: SettingsAction) async throws {
            var newState = state
            
            switch action {
            case .changeTheme(let theme):
                newState.theme = theme
            case .toggleNotifications:
                newState.notifications.toggle()
            }
            
            updateState(newState)
        }
    }
}

// MARK: - Expected API Documentation

/*
ContextTestScenario API:

1. Basic usage:
   ContextTestScenario(ContextType.self)
       .withClient(client)
       .when { context in ... }
       .then { context in Bool }

2. Custom setup:
   .withSetup { parentContext in
       return CustomContext(...)
   }

3. Lifecycle testing:
   .onAppear()
   .onDisappear()

4. Child contexts:
   .withChild { parent in childContext }
   .when { context, children in ... }

5. Memory testing:
   .measureMemory()

6. Multiple clients:
   Context can have multiple clients as properties

7. Validation at each step:
   .validate { context in Bool }
*/