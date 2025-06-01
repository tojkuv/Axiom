import SwiftUI
import Axiom

// MARK: - User Domain Context

/// Sophisticated user context demonstrating advanced context orchestration,
/// cross-cutting concerns, and complex state management for comprehensive framework testing
@MainActor
final class UserContext: ObservableObject, AxiomContext {
    
    // MARK: - AxiomContext Protocol
    
    public typealias View = UserView
    public typealias Clients = UserClients
    
    public var clients: UserClients {
        UserClients(userClient: userClient)
    }
    
    public let intelligence: AxiomIntelligence
    
    // MARK: - Domain Clients
    
    let userClient: UserClient
    
    // MARK: - Published State (Automatically Synchronized)
    
    @Published var currentUser: UserState = UserState()
    @Published var isAuthenticated: Bool = false
    @Published var authenticationInProgress: Bool = false
    @Published var profileUpdateInProgress: Bool = false
    @Published var permissionManagementInProgress: Bool = false
    
    // Authentication UI State
    @Published var loginEmail: String = ""
    @Published var loginPassword: String = ""
    @Published var loginError: String?
    @Published var showingForgotPassword: Bool = false
    
    // Profile Management UI State
    @Published var editedDisplayName: String = ""
    @Published var editedEmail: String = ""
    @Published var showingProfileEditor: Bool = false
    @Published var profileSaveError: String?
    
    // Permission Management UI State
    @Published var availablePermissions: [UserPermission] = UserPermission.allCases
    @Published var pendingPermissionChanges: Set<UserPermission> = []
    @Published var permissionError: String?
    
    // Analytics and Performance
    @Published var userActionHistory: [UserActionRecord] = []
    @Published var performanceMetrics: UserClientMetrics?
    @Published var sessionInfo: SessionDisplayInfo?
    
    // Validation and Error Handling
    @Published var validationErrors: [ValidationError] = []
    @Published var showingValidationAlert: Bool = false
    @Published var lastError: (any AxiomError)?
    
    // Intelligence Integration
    @Published var intelligenceResponse: String = ""
    @Published var intelligenceQuery: String = ""
    @Published var intelligenceInProgress: Bool = false
    
    // MARK: - Advanced Context Features
    
    private let stateBinder = ContextStateBinder()
    private let analyticsTracker = UserAnalyticsTracker()
    private let errorRecoveryManager = ErrorRecoveryManager()
    private let performanceTracker = ContextPerformanceTracker()
    
    // Cross-cutting concerns
    private var backgroundTaskManager: BackgroundTaskManager
    private var notificationManager: NotificationManager
    private var cacheManager: CacheManager
    
    // MARK: - Initialization
    
    init(userClient: UserClient, intelligence: AxiomIntelligence) {
        self.userClient = userClient
        self.intelligence = intelligence
        self.backgroundTaskManager = BackgroundTaskManager()
        self.notificationManager = NotificationManager()
        self.cacheManager = CacheManager()
        
        Task {
            await setupAdvancedContextFeatures()
        }
    }
    
    private func setupAdvancedContextFeatures() async {
        // Add context as observer to user client
        await userClient.addObserver(self)
        
        // Set up automatic state binding with sophisticated synchronization
        await bindClientProperty(
            userClient,
            property: \.id,
            to: \.currentUser.id,
            using: stateBinder
        )
        
        await bindClientProperty(
            userClient,
            property: \.isAuthenticated,
            to: \.isAuthenticated,
            using: stateBinder
        )
        
        await bindClientProperty(
            userClient,
            property: \.validationErrors,
            to: \.validationErrors,
            using: stateBinder
        )
        
        // Set up performance monitoring
        await performanceTracker.startMonitoring(for: self)
        
        // Initialize cross-cutting services
        await backgroundTaskManager.initialize()
        await notificationManager.initialize()
        await cacheManager.initialize()
        
        print("🎯 UserContext: Advanced features initialized with automatic state binding")
    }
    
    // MARK: - AxiomContext Protocol Methods
    
    public func capabilityManager() async throws -> CapabilityManager {
        return await GlobalCapabilityManager.shared.getManager()
    }
    
    public func performanceMonitor() async throws -> PerformanceMonitor {
        return await GlobalPerformanceMonitor.shared.getMonitor()
    }
    
    public func trackAnalyticsEvent(_ event: String, parameters: [String: Any]) async {
        await analyticsTracker.track(event: event, parameters: parameters, userId: currentUser.id)
        print("📊 UserContext Analytics: \(event) - \(parameters)")
    }
    
    public func onAppear() async {
        await performanceTracker.recordContextAppear()
        await trackAnalyticsEvent("user_context_appeared", parameters: [:])
        
        // Load initial data
        await loadUserMetrics()
        await loadSessionInfo()
        
        // Start background tasks
        await backgroundTaskManager.startPeriodicTasks()
    }
    
    public func onDisappear() async {
        await performanceTracker.recordContextDisappear()
        await trackAnalyticsEvent("user_context_disappeared", parameters: [:])
        
        // Pause non-critical background tasks
        await backgroundTaskManager.pauseNonCriticalTasks()
    }
    
    public func onClientStateChange<T: AxiomClient>(_ client: T) async {
        // Automatic state binding handles synchronization
        await stateBinder.updateAllBindings()
        
        // Update derived state
        await updateDerivedState()
        
        // Track state changes for analytics
        await trackAnalyticsEvent("client_state_changed", parameters: [
            "client_type": String(describing: T.self),
            "user_authenticated": isAuthenticated
        ])
        
        print("🔄 UserContext: Advanced state synchronization complete")
    }
    
    public func handleError(_ error: any AxiomError) async {
        lastError = error
        
        // Advanced error recovery
        let recoveryAction = await errorRecoveryManager.determineRecoveryAction(for: error)
        await executeRecoveryAction(recoveryAction)
        
        await trackAnalyticsEvent("error_handled", parameters: [
            "error_type": String(describing: type(of: error)),
            "recovery_action": recoveryAction.description
        ])
        
        print("❌ UserContext: Error handled with recovery action - \(error)")
    }
    
    // MARK: - Authentication Actions
    
    func authenticateWithEmail() async {
        authenticationInProgress = true
        loginError = nil
        
        await trackAnalyticsEvent("authentication_started", parameters: ["method": "email"])
        
        do {
            let result = try await userClient.authenticateWithEmail(loginEmail, password: loginPassword)
            
            // Clear login form
            loginEmail = ""
            loginPassword = ""
            
            // Update session info
            await updateSessionInfo(from: result)
            
            await trackAnalyticsEvent("authentication_successful", parameters: ["method": "email"])
            
            // Show success notification
            await notificationManager.showNotification("Successfully logged in", type: .success)
            
        } catch {
            loginError = error.localizedDescription
            await handleError(error as? any AxiomError ?? GenericAxiomError(underlying: error))
        }
        
        authenticationInProgress = false
    }
    
    func authenticateWithOAuth(provider: String) async {
        authenticationInProgress = true
        loginError = nil
        
        await trackAnalyticsEvent("oauth_authentication_started", parameters: ["provider": provider])
        
        do {
            // Simulate OAuth token retrieval
            let oauthToken = "mock_oauth_token_\(provider)"
            let result = try await userClient.authenticateWithOAuth(provider: provider, token: oauthToken)
            
            await updateSessionInfo(from: result)
            await trackAnalyticsEvent("oauth_authentication_successful", parameters: ["provider": provider])
            
            await notificationManager.showNotification("Successfully logged in with \(provider)", type: .success)
            
        } catch {
            loginError = error.localizedDescription
            await handleError(error as? any AxiomError ?? GenericAxiomError(underlying: error))
        }
        
        authenticationInProgress = false
    }
    
    func logout() async {
        await trackAnalyticsEvent("logout_started", parameters: [:])
        
        await userClient.logout()
        
        // Clear UI state
        sessionInfo = nil
        userActionHistory.removeAll()
        intelligenceResponse = ""
        
        await trackAnalyticsEvent("logout_completed", parameters: [:])
        await notificationManager.showNotification("Logged out successfully", type: .info)
    }
    
    // MARK: - Profile Management Actions
    
    func startEditingProfile() {
        editedDisplayName = currentUser.displayName
        editedEmail = currentUser.email
        showingProfileEditor = true
        
        Task {
            await trackAnalyticsEvent("profile_editing_started", parameters: [:])
        }
    }
    
    func saveProfileChanges() async {
        profileUpdateInProgress = true
        profileSaveError = nil
        
        await trackAnalyticsEvent("profile_save_started", parameters: [
            "display_name_changed": editedDisplayName != currentUser.displayName,
            "email_changed": editedEmail != currentUser.email
        ])
        
        do {
            try await userClient.updateProfile(
                displayName: editedDisplayName.isEmpty ? nil : editedDisplayName,
                email: editedEmail.isEmpty ? nil : editedEmail
            )
            
            showingProfileEditor = false
            await trackAnalyticsEvent("profile_save_successful", parameters: [:])
            await notificationManager.showNotification("Profile updated successfully", type: .success)
            
        } catch {
            profileSaveError = error.localizedDescription
            await handleError(error as? any AxiomError ?? GenericAxiomError(underlying: error))
        }
        
        profileUpdateInProgress = false
    }
    
    func updateUserPreferences(_ preferences: UserPreferences) async {
        await trackAnalyticsEvent("preferences_update_started", parameters: [
            "theme": preferences.theme,
            "font_size": preferences.fontSize
        ])
        
        do {
            try await userClient.updatePreferences(preferences)
            await trackAnalyticsEvent("preferences_update_successful", parameters: [:])
            await notificationManager.showNotification("Preferences updated", type: .success)
            
        } catch {
            await handleError(error as? any AxiomError ?? GenericAxiomError(underlying: error))
        }
    }
    
    // MARK: - Permission Management Actions
    
    func grantPermission(_ permission: UserPermission) async {
        permissionManagementInProgress = true
        permissionError = nil
        
        await trackAnalyticsEvent("permission_grant_started", parameters: ["permission": permission.rawValue])
        
        do {
            try await userClient.grantPermission(permission)
            pendingPermissionChanges.remove(permission)
            
            await trackAnalyticsEvent("permission_grant_successful", parameters: ["permission": permission.rawValue])
            await notificationManager.showNotification("Permission granted: \(permission.rawValue)", type: .success)
            
        } catch {
            permissionError = error.localizedDescription
            await handleError(error as? any AxiomError ?? GenericAxiomError(underlying: error))
        }
        
        permissionManagementInProgress = false
    }
    
    func revokePermission(_ permission: UserPermission) async {
        permissionManagementInProgress = true
        permissionError = nil
        
        await trackAnalyticsEvent("permission_revoke_started", parameters: ["permission": permission.rawValue])
        
        do {
            try await userClient.revokePermission(permission)
            pendingPermissionChanges.remove(permission)
            
            await trackAnalyticsEvent("permission_revoke_successful", parameters: ["permission": permission.rawValue])
            await notificationManager.showNotification("Permission revoked: \(permission.rawValue)", type: .success)
            
        } catch {
            permissionError = error.localizedDescription
            await handleError(error as? any AxiomError ?? GenericAxiomError(underlying: error))
        }
        
        permissionManagementInProgress = false
    }
    
    // MARK: - Intelligence Integration Actions
    
    func askIntelligenceAboutUser() async {
        intelligenceInProgress = true
        intelligenceResponse = ""
        
        let query = intelligenceQuery.isEmpty ? "What insights can you provide about this user's profile and activity?" : intelligenceQuery
        
        await trackAnalyticsEvent("intelligence_query_started", parameters: ["query_type": "user_analysis"])
        
        do {
            let response = try await intelligence.processQuery(query)
            intelligenceResponse = response.answer
            
            await trackAnalyticsEvent("intelligence_query_successful", parameters: [
                "confidence": response.confidence,
                "query_type": "user_analysis"
            ])
            
        } catch {
            intelligenceResponse = "Error: \(error.localizedDescription)"
            await handleError(error as? any AxiomError ?? GenericAxiomError(underlying: error))
        }
        
        intelligenceInProgress = false
    }
    
    func askIntelligenceAboutSecurity() async {
        intelligenceInProgress = true
        
        let query = "Analyze the security aspects of this user's account and suggest improvements."
        
        await trackAnalyticsEvent("intelligence_security_query_started", parameters: [:])
        
        do {
            let response = try await intelligence.processQuery(query)
            intelligenceResponse = response.answer
            
            await trackAnalyticsEvent("intelligence_security_query_successful", parameters: [
                "confidence": response.confidence
            ])
            
        } catch {
            intelligenceResponse = "Security analysis error: \(error.localizedDescription)"
            await handleError(error as? any AxiomError ?? GenericAxiomError(underlying: error))
        }
        
        intelligenceInProgress = false
    }
    
    // MARK: - Account Management Actions
    
    func unlockAccount() async {
        await trackAnalyticsEvent("account_unlock_started", parameters: [:])
        
        do {
            try await userClient.unlockAccount()
            await trackAnalyticsEvent("account_unlock_successful", parameters: [:])
            await notificationManager.showNotification("Account unlocked successfully", type: .success)
            
        } catch {
            await handleError(error as? any AxiomError ?? GenericAxiomError(underlying: error))
        }
    }
    
    func refreshSession() async {
        await trackAnalyticsEvent("session_refresh_started", parameters: [:])
        
        do {
            try await userClient.refreshSession()
            await loadSessionInfo()
            
            await trackAnalyticsEvent("session_refresh_successful", parameters: [:])
            await notificationManager.showNotification("Session refreshed", type: .info)
            
        } catch {
            await handleError(error as? any AxiomError ?? GenericAxiomError(underlying: error))
        }
    }
    
    // MARK: - Analytics and Performance
    
    func loadUserMetrics() async {
        performanceMetrics = await userClient.getPerformanceMetrics()
        
        await trackAnalyticsEvent("metrics_loaded", parameters: [
            "total_operations": performanceMetrics?.totalOperations ?? 0,
            "average_response_time": performanceMetrics?.averageResponseTime ?? 0
        ])
    }
    
    func recordUserAction(_ action: UserAction, metadata: [String: Any] = [:]) async {
        // Record action with user client
        await userClient.trackUserAction(action, metadata: metadata)
        
        // Add to local history for UI display
        let record = UserActionRecord(
            action: action,
            timestamp: Date(),
            metadata: metadata
        )
        userActionHistory.append(record)
        
        // Keep only last 50 actions for UI performance
        if userActionHistory.count > 50 {
            userActionHistory.removeFirst()
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func updateDerivedState() async {
        // Update derived state based on current user
        if currentUser.isAuthenticated != isAuthenticated {
            isAuthenticated = currentUser.isAuthenticated
        }
        
        // Update validation state
        validationErrors = currentUser.validationErrors
        showingValidationAlert = !validationErrors.isEmpty
    }
    
    private func updateSessionInfo(from authResult: AuthenticationResult) async {
        sessionInfo = SessionDisplayInfo(
            token: String(authResult.token.prefix(8)) + "...",
            expiry: authResult.expiry,
            isActive: true,
            lastActivity: Date()
        )
    }
    
    private func loadSessionInfo() async {
        if currentUser.isAuthenticated,
           let token = currentUser.sessionToken,
           let expiry = currentUser.sessionExpiry {
            sessionInfo = SessionDisplayInfo(
                token: String(token.prefix(8)) + "...",
                expiry: expiry,
                isActive: currentUser.isSessionValid(),
                lastActivity: currentUser.lastActivity ?? Date()
            )
        } else {
            sessionInfo = nil
        }
    }
    
    private func executeRecoveryAction(_ action: RecoveryAction) async {
        switch action.type {
        case .retry:
            // Implement retry logic
            break
        case .resetState:
            // Reset relevant UI state
            authenticationInProgress = false
            profileUpdateInProgress = false
            permissionManagementInProgress = false
        case .showError:
            // Error is already shown through published properties
            break
        case .logout:
            await logout()
        }
    }
}

// MARK: - Supporting Types

public struct UserActionRecord {
    public let action: UserAction
    public let timestamp: Date
    public let metadata: [String: Any]
}

public struct SessionDisplayInfo {
    public let token: String
    public let expiry: Date
    public let isActive: Bool
    public let lastActivity: Date
    
    public var timeUntilExpiry: TimeInterval {
        expiry.timeIntervalSinceNow
    }
    
    public var isExpiringSoon: Bool {
        timeUntilExpiry < 300 // 5 minutes
    }
}

// MARK: - Client Dependencies

public struct UserClients: ClientDependencies {
    public let userClient: UserClient
}

// MARK: - Cross-Cutting Concern Services

private actor UserAnalyticsTracker {
    private var events: [AnalyticsEvent] = []
    
    func track(event: String, parameters: [String: Any], userId: String?) async {
        let analyticsEvent = AnalyticsEvent(
            name: event,
            parameters: parameters,
            userId: userId,
            timestamp: Date()
        )
        events.append(analyticsEvent)
        
        // In production, would send to analytics service
    }
}

private actor ErrorRecoveryManager {
    func determineRecoveryAction(for error: any AxiomError) async -> RecoveryAction {
        switch error.severity {
        case .warning:
            return RecoveryAction(type: .showError, description: "Show warning to user")
        case .error:
            return RecoveryAction(type: .retry, description: "Allow user to retry")
        case .critical:
            return RecoveryAction(type: .logout, description: "Force logout for security")
        }
    }
}

private actor ContextPerformanceTracker {
    private var appearanceTime: Date?
    private var metrics: [String: Double] = [:]
    
    func startMonitoring(for context: UserContext) async {
        // Initialize performance tracking
    }
    
    func recordContextAppear() async {
        appearanceTime = Date()
    }
    
    func recordContextDisappear() async {
        if let appearanceTime = appearanceTime {
            let sessionDuration = Date().timeIntervalSince(appearanceTime)
            metrics["session_duration"] = sessionDuration
        }
    }
}

private actor BackgroundTaskManager {
    private var periodicTasks: [String: Task<Void, Never>] = [:]
    
    func initialize() async {
        // Initialize background task management
    }
    
    func startPeriodicTasks() async {
        // Start session refresh checks
        periodicTasks["session_refresh"] = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes
                // Check if session needs refresh
            }
        }
    }
    
    func pauseNonCriticalTasks() async {
        // Pause non-critical background tasks to save resources
    }
}

private actor NotificationManager {
    func initialize() async {
        // Initialize notification system
    }
    
    func showNotification(_ message: String, type: NotificationType) async {
        // In production, would show actual notifications
        print("📢 NOTIFICATION [\(type.rawValue)]: \(message)")
    }
}

private enum NotificationType: String {
    case success = "SUCCESS"
    case error = "ERROR"
    case warning = "WARNING"
    case info = "INFO"
}

private actor CacheManager {
    private var cache: [String: Any] = [:]
    
    func initialize() async {
        // Initialize caching system
    }
}

private struct AnalyticsEvent {
    let name: String
    let parameters: [String: Any]
    let userId: String?
    let timestamp: Date
}

private struct RecoveryAction {
    let type: RecoveryActionType
    let description: String
}

private enum RecoveryActionType {
    case retry
    case resetState
    case showError
    case logout
}

// MARK: - Generic Error Type

private struct GenericAxiomError: AxiomError {
    let id = UUID()
    let underlying: Error
    
    var category: ErrorCategory { .architectural }
    var severity: ErrorSeverity { .error }
    var context: ErrorContext {
        ErrorContext(component: ComponentID("UserContext"), timestamp: Date(), additionalInfo: [:])
    }
    var recoveryActions: [RecoveryAction] { [] }
    var userMessage: String { underlying.localizedDescription }
    
    var errorDescription: String? {
        underlying.localizedDescription
    }
}